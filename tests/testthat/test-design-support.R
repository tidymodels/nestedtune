# The designs the README's resampling table marks, one role at a time (M127).
#
# A `Yes` cell is a design that runs through nested_tune_grid() with a v-fold
# partner in the other role and completes every outer fold. A `Refused` cell
# is a refusal nestedtune writes: the bootstrap refusal, and the refusals of
# `loo_cv()`, `apparent()` and `permutations()` in either role (M128). The one
# `No` cell, an inner `validation_set()`, is pinned by the behavior the README
# gives as its reason. Cells whose backing test lives elsewhere (v-fold, the
# outer bootstrap, the time-series designs) are not repeated here.

skip_heavy_on_cran()

support_data <- function(n = 90) {
  d <- make_reg_data(n = n)
  d$g <- factor(rep(seq_len(15), length.out = n))
  d
}

# The run under test, with a fixed seed for the design and the tuning.
support_run <- function(d, outside, inside, control = tune::control_grid()) {
  set.seed(51)
  folds <- eval(bquote(
    nested_resamples(d, outside = .(outside), inside = .(inside))
  ))
  set.seed(52)
  res <- memoised(nested_tune_grid(
    det_workflow(d),
    folds,
    grid = det_grid(),
    metrics = reg_metrics(),
    control = control
  ))
  list(folds = folds, res = res)
}

V3 <- quote(rsample::vfold_cv(v = 3))

# Each design, with the class its rset carries so the test can show the
# design it names is the one that ran.
SUPPORTED <- list(
  outer = list(
    mc_cv = quote(rsample::mc_cv(times = 3)),
    group_vfold_cv = quote(rsample::group_vfold_cv(group = g, v = 3)),
    group_mc_cv = quote(rsample::group_mc_cv(group = g, times = 3)),
    clustering_cv = quote(rsample::clustering_cv(vars = c(x1, x2), v = 3))
  ),
  inner = list(
    mc_cv = quote(rsample::mc_cv(times = 3)),
    group_vfold_cv = quote(rsample::group_vfold_cv(group = g, v = 3)),
    group_mc_cv = quote(rsample::group_mc_cv(group = g, times = 3)),
    clustering_cv = quote(rsample::clustering_cv(vars = c(x1, x2), v = 3)),
    bootstraps = quote(rsample::bootstraps(times = 3)),
    group_bootstraps = quote(rsample::group_bootstraps(group = g, times = 3))
  )
)

for (design in names(SUPPORTED$outer)) {
  local({
    design <- design
    test_that(sprintf("an outer %s design completes every fold", design), {
      skip_if_no_engines()
      run <- support_run(support_data(), SUPPORTED$outer[[design]], V3)
      expect_s3_class(run$folds, design)
      expect_identical(nrow(run$res), nrow(run$folds))
      expect_true(all(run$res$.completed))
    })
  })
}

for (design in names(SUPPORTED$inner)) {
  local({
    design <- design
    test_that(sprintf("an inner %s design completes every fold", design), {
      skip_if_no_engines()
      run <- support_run(support_data(), V3, SUPPORTED$inner[[design]])
      expect_s3_class(run$folds, "vfold_cv")
      for (inner in run$folds$inner_resamples) {
        expect_s3_class(inner, design)
      }
      expect_identical(nrow(run$res), nrow(run$folds))
      expect_true(all(run$res$.completed))
    })
  })
}

test_that("an outer group bootstrap is refused, as a call and as an object", {
  d <- support_data()
  expect_error(
    nested_resamples(
      d,
      outside = rsample::group_bootstraps(group = g, times = 3),
      inside = rsample::vfold_cv(v = 3)
    ),
    "cannot be a bootstrap",
    class = "nestedtune_bad_design"
  )
  set.seed(1)
  boots <- rsample::group_bootstraps(d, group = g, times = 3)
  expect_error(
    nested_resamples(d, outside = boots, inside = rsample::vfold_cv(v = 3)),
    "cannot be a bootstrap",
    class = "nestedtune_bad_design"
  )
})

# The three designs refused in either role (M128). Each name is the class
# the design's rset carries and the function the refusal must name.
REFUSED <- list(
  loo_cv = quote(rsample::loo_cv()),
  apparent = quote(rsample::apparent()),
  permutations = quote(rsample::permutations(permute = y, times = 3))
)

expect_refused <- function(expr, design) {
  cnd <- expect_error(expr, class = "nestedtune_bad_design")
  expect_match(conditionMessage(cnd), paste0(design, "()"), fixed = TRUE)
}

for (design in names(REFUSED)) {
  local({
    design <- design
    spec <- REFUSED[[design]]

    test_that(
      sprintf(
        "an outer %s design is refused, as a call and as an object",
        design
      ),
      {
        d <- support_data()
        expect_refused(
          eval(bquote(nested_resamples(d, outside = .(spec), inside = .(V3)))),
          design
        )
        set.seed(1)
        built <- eval(rlang::call_modify(spec, data = quote(d)))
        expect_s3_class(built, design)
        expect_refused(
          nested_resamples(
            d,
            outside = built,
            inside = rsample::vfold_cv(v = 3)
          ),
          design
        )
      }
    )

    test_that(sprintf("an inner %s design is refused", design), {
      d <- support_data()
      expect_refused(
        eval(bquote(nested_resamples(d, outside = .(V3), inside = .(spec)))),
        design
      )
    })
  })
}

# The entry check refuses the same six designs in a design built elsewhere,
# since rsample::nested_cv() builds all six (M128). A stand-in for the fold
# dispatch makes a design that got past the check fail with its own class,
# so a passing test shows the refusal fired before any fold ran.
entry_refusal <- function(expr) {
  sentinel <- function(...) {
    rlang::abort("fitting began", class = "nestedtune_sentinel")
  }
  testthat::local_mocked_bindings(dispatch_folds = sentinel)
  tryCatch(expr, error = function(cnd) cnd)
}

expect_entry_refused <- function(cnd, design) {
  expect_s3_class(cnd, "nestedtune_bad_design")
  expect_match(conditionMessage(cnd), paste0(design, "()"), fixed = TRUE)
}

nested_cv_design <- function(d, outside, inside) {
  set.seed(1)
  eval(bquote(rsample::nested_cv(d, outside = .(outside), inside = .(inside))))
}

test_that("the entry check refuses the six designs rsample::nested_cv() builds", {
  skip_if_no_engines()
  d <- support_data(n = 30)
  wf <- det_workflow(d)
  for (design in names(REFUSED)) {
    outer <- nested_cv_design(d, REFUSED[[design]], V3)
    expect_s3_class(outer, design)
    cnd <- entry_refusal(nested_tune_grid(wf, outer, grid = det_grid()))
    expect_entry_refused(cnd, design)
    expect_identical(rlang::call_name(conditionCall(cnd)), "nested_tune_grid")

    inner <- nested_cv_design(d, V3, REFUSED[[design]])
    for (rset in inner$inner_resamples) {
      expect_s3_class(rset, design)
    }
    cnd <- entry_refusal(nested_tune_grid(wf, inner, grid = det_grid()))
    expect_entry_refused(cnd, design)
    expect_identical(rlang::call_name(conditionCall(cnd)), "nested_tune_grid")
    expect_match(conditionMessage(cnd), "Elements 1, 2, and 3", fixed = TRUE)
  }
})

test_that("the entry check names the one outer fold whose inner design is refused", {
  skip_if_no_engines()
  d <- support_data()
  wf <- det_workflow(d)
  folds <- det_nested(d)
  folds$inner_resamples[[2]] <-
    rsample::apparent(rsample::analysis(folds$splits[[2]]))
  cnd <- entry_refusal(nested_tune_grid(wf, folds, grid = det_grid()))
  expect_entry_refused(cnd, "apparent")
  expect_match(conditionMessage(cnd), "Element 2 of", fixed = TRUE)
  expect_no_match(conditionMessage(cnd), "Elements", fixed = TRUE)
})

test_that("every other orchestrator refuses an outer leave-one-out design at entry", {
  skip_if_no_engines()
  d <- support_data(n = 30)
  wf <- det_workflow(d)
  outer <- nested_cv_design(d, quote(rsample::loo_cv()), V3)
  calls <- list(
    nested_tune_bayes = quote(nested_tune_bayes(wf, outer)),
    nested_tune_race_anova = quote(
      nested_tune_race_anova(wf, outer, grid = det_grid())
    ),
    nested_tune_race_win_loss = quote(
      nested_tune_race_win_loss(wf, outer, grid = det_grid())
    ),
    nested_tune_sim_anneal = quote(nested_tune_sim_anneal(wf, outer)),
    nested_fit_resamples = quote(nested_fit_resamples(fixed_workflow(d), outer))
  )
  for (fn in names(calls)) {
    # The racers and the annealer refuse a missing finetune first.
    if (!tuner_ready(fn)) {
      next
    }
    cnd <- entry_refusal(eval(calls[[fn]]))
    expect_entry_refused(cnd, "loo_cv")
    expect_identical(rlang::call_name(conditionCall(cnd)), fn)
  }
  # The map re-signals the orchestrator's refusal with its class kept.
  skip_if_no_wset_fixture()
  cnd <- entry_refusal(
    nested_workflow_map(wset_two(d), resamples = outer, grid = det_grid())
  )
  expect_entry_refused(cnd, "loo_cv")
})

test_that("an outer validation set built beforehand completes its one fold", {
  skip_if_no_engines()
  set.seed(53)
  split <- rsample::initial_validation_split(support_data())
  vs <- rsample::validation_set(split)
  d <- rbind(rsample::training(split), rsample::validation(split))
  run <- support_run(d, vs, V3)
  expect_s3_class(run$folds$splits[[1]], "val_split")
  expect_identical(nrow(run$res), 1L)
  expect_true(all(run$res$.completed))
  # the fold holds out the validation rows, apart from the rows it trains on
  outer <- run$res$splits[[1]]
  expect_identical(
    nrow(rsample::assessment(outer)),
    nrow(rsample::validation(split))
  )
  expect_length(intersect(outer$in_id, outer$out_id), 0L)
})

test_that("a validation_set() call cannot be built in either role", {
  d <- support_data()
  outer <- expect_error(
    nested_resamples(
      d,
      outside = rsample::validation_set(),
      inside = rsample::vfold_cv(v = 3)
    ),
    "`outside` could not be evaluated"
  )
  inner <- expect_error(
    nested_resamples(
      d,
      outside = rsample::vfold_cv(v = 3),
      inside = rsample::validation_set()
    ),
    "`inside` could not be evaluated"
  )
  # The cause is validation_set() having no `data` argument: it takes a
  # split, so the `data` nestedtune passes lands in `...`, which must be empty.
  expect_match(conditionMessage(outer$parent), "must be empty")
  expect_match(conditionMessage(inner$parent), "must be empty")
})

# A row subset or a manual_rset() rebuild of a refused design loses the class
# its rset carries, but each split keeps its own (M129). The entry check
# reads the split classes, so these designs are refused as the plain ones are.
REFUSED_OUTER <- list(
  loo_cv = quote(rsample::loo_cv()),
  permutations = quote(rsample::permutations(permute = y, times = 3)),
  bootstraps = quote(rsample::bootstraps(times = 3)),
  group_bootstraps = quote(rsample::group_bootstraps(group = g, times = 3))
)

ROW_CUTS <- list(
  bracket = function(x, i) x[i, ],
  slice = function(x, i) dplyr::slice(x, i),
  vec_slice = function(x, i) vctrs::vec_slice(x, i)
)

# rsample::nested_cv() can warn for an outer bootstrap (a bare bootstraps()
# call or a bootstraps rset), which is not under test.
quiet_nested_cv <- function(d, outside, inside) {
  suppressWarnings(nested_cv_design(d, outside, inside))
}

# The refusal names the function in full, since `bootstraps()` alone would
# also match inside `group_bootstraps()`.
expect_names_design <- function(cnd, design) {
  expect_s3_class(cnd, "nestedtune_bad_design")
  expect_match(
    conditionMessage(cnd),
    paste0("rsample::", design, "()"),
    fixed = TRUE
  )
}

# The rebuild keeps the splits and their ids and nothing else of the design.
rebuilt <- function(rset) {
  rsample::manual_rset(rset$splits, rset$id)
}

for (design in names(REFUSED_OUTER)) {
  local({
    design <- design
    test_that(
      sprintf("a row subset of an outer %s design is refused", design),
      {
        skip_if_no_engines()
        d <- support_data(n = 30)
        wf <- det_workflow(d)
        whole <- quiet_nested_cv(d, REFUSED_OUTER[[design]], V3)
        for (cut in names(ROW_CUTS)) {
          part <- ROW_CUTS[[cut]](whole, 1:2)
          expect_false(inherits(part, "rset"))
          cnd <- entry_refusal(nested_tune_grid(wf, part, grid = det_grid()))
          expect_names_design(cnd, design)
          expect_match(conditionMessage(cnd), "Rows 1 and 2", fixed = TRUE)
          expect_identical(
            rlang::call_name(conditionCall(cnd)),
            "nested_tune_grid"
          )
        }
      }
    )
  })
}

test_that("an outer manual_rset() rebuilt from refused splits is refused at entry", {
  skip_if_no_engines()
  d <- support_data(n = 30)
  wf <- det_workflow(d)
  outer <- c(REFUSED_OUTER, apparent = quote(rsample::apparent()))
  for (design in names(outer)) {
    set.seed(1)
    rset <- eval(rlang::call_modify(outer[[design]], data = quote(d)))
    again <- rebuilt(rset)
    expect_s3_class(again, "manual_rset")
    folds <- quiet_nested_cv(d, again, V3)
    cnd <- entry_refusal(nested_tune_grid(wf, folds, grid = det_grid()))
    expect_names_design(cnd, design)
  }

  # A bootstrap's apparent split is named as part of the bootstrap.
  set.seed(1)
  again <- rebuilt(rsample::bootstraps(d, times = 3, apparent = TRUE))
  folds <- quiet_nested_cv(d, again, V3)
  cnd <- entry_refusal(nested_tune_grid(wf, folds, grid = det_grid()))
  expect_names_design(cnd, "bootstraps")
  expect_match(conditionMessage(cnd), "Rows 1, 2, 3, and 4", fixed = TRUE)
  expect_no_match(conditionMessage(cnd), "apparent()", fixed = TRUE)
})

test_that("one outer split from a refused design refuses the whole design", {
  skip_if_no_engines()
  d <- support_data(n = 30)
  wf <- det_workflow(d)
  set.seed(1)
  folds <- rsample::vfold_cv(d, v = 3)$splits
  with_one <- function(extra) {
    outer <- rsample::manual_rset(c(folds, extra), paste0("Fold", 1:4))
    quiet_nested_cv(d, outer, V3)
  }

  cnd <- entry_refusal(nested_tune_grid(
    wf,
    with_one(rsample::loo_cv(d)$splits[1]),
    grid = det_grid()
  ))
  expect_names_design(cnd, "loo_cv")
  expect_match(conditionMessage(cnd), "Row 4 of", fixed = TRUE)

  cnd <- entry_refusal(nested_tune_grid(
    wf,
    with_one(rsample::apparent(d)$splits),
    grid = det_grid()
  ))
  expect_names_design(cnd, "apparent")
  expect_match(conditionMessage(cnd), "Row 4 of", fixed = TRUE)

  # The last row of a bootstrap with its apparent split is that split alone,
  # which scores its fold on the rows it trained on.
  boots <- quiet_nested_cv(
    d,
    quote(rsample::bootstraps(times = 3, apparent = TRUE)),
    V3
  )
  last <- boots[4, ]
  expect_s3_class(last$splits[[1]], "apparent_split")
  cnd <- entry_refusal(nested_tune_grid(wf, last, grid = det_grid()))
  expect_names_design(cnd, "apparent")
  expect_no_match(conditionMessage(cnd), "bootstraps()", fixed = TRUE)
})

test_that("the entry check still admits a subset or rebuild of a v-fold design", {
  skip_if_no_engines()
  d <- support_data(n = 30)
  wf <- det_workflow(d)
  whole <- nested_cv_design(d, V3, V3)
  cnd <- entry_refusal(nested_tune_grid(wf, whole[1:2, ], grid = det_grid()))
  expect_s3_class(cnd, "nestedtune_sentinel")

  set.seed(1)
  again <- rebuilt(rsample::vfold_cv(d, v = 3))
  folds <- quiet_nested_cv(d, again, V3)
  cnd <- entry_refusal(nested_tune_grid(wf, folds, grid = det_grid()))
  expect_s3_class(cnd, "nestedtune_sentinel")
})

# The inner loop refuses the three designs, and a row subset of an inner
# design loses its rset class too. The refusal names the design rather than
# only calling the column malformed.
REFUSED_INNER <- list(
  loo_cv = quote(rsample::loo_cv()),
  permutations = quote(rsample::permutations(permute = y, times = 3))
)

for (design in names(REFUSED_INNER)) {
  local({
    design <- design
    test_that(
      sprintf("a row subset of an inner %s design is refused", design),
      {
        skip_if_no_engines()
        d <- support_data(n = 30)
        wf <- det_workflow(d)
        whole <- nested_cv_design(d, V3, REFUSED_INNER[[design]])
        for (cut in names(ROW_CUTS)) {
          folds <- whole
          folds$inner_resamples <- lapply(
            folds$inner_resamples,
            ROW_CUTS[[cut]],
            i = 1:2
          )
          expect_false(inherits(folds$inner_resamples[[1]], "rset"))
          cnd <- entry_refusal(nested_tune_grid(wf, folds, grid = det_grid()))
          expect_names_design(cnd, design)
          expect_match(
            conditionMessage(cnd),
            "Elements 1, 2, and 3",
            fixed = TRUE
          )
          expect_no_match(conditionMessage(cnd), "malformed", fixed = TRUE)
        }
      }
    )
  })
}

test_that("a row subset of one fold's inner design names that fold alone", {
  skip_if_no_engines()
  d <- support_data(n = 30)
  wf <- det_workflow(d)
  folds <- nested_cv_design(d, V3, REFUSED_INNER$loo_cv)
  folds$inner_resamples[[2]] <- folds$inner_resamples[[2]][1:2, ]
  folds$inner_resamples[c(1, 3)] <- nested_cv_design(d, V3, V3)$inner_resamples[
    c(1, 3)
  ]
  cnd <- entry_refusal(nested_tune_grid(wf, folds, grid = det_grid()))
  expect_names_design(cnd, "loo_cv")
  expect_match(conditionMessage(cnd), "Element 2 of", fixed = TRUE)
  expect_no_match(conditionMessage(cnd), "Elements", fixed = TRUE)
})

test_that("an inner manual_rset() rebuilt from refused splits is refused at entry", {
  skip_if_no_engines()
  d <- support_data(n = 30)
  wf <- det_workflow(d)
  inner <- c(REFUSED_INNER, apparent = quote(rsample::apparent()))
  for (design in names(inner)) {
    folds <- nested_cv_design(d, V3, inner[[design]])
    folds$inner_resamples <- lapply(folds$inner_resamples, rebuilt)
    expect_s3_class(folds$inner_resamples[[1]], "manual_rset")
    cnd <- entry_refusal(nested_tune_grid(wf, folds, grid = det_grid()))
    expect_names_design(cnd, design)
    expect_match(conditionMessage(cnd), "Elements 1, 2, and 3", fixed = TRUE)
  }
})

test_that("one inner split from a refused design refuses its fold", {
  skip_if_no_engines()
  d <- support_data(n = 30)
  wf <- det_workflow(d)
  folds <- nested_cv_design(d, V3, V3)
  inner <- folds$inner_resamples[[2]]
  one_loo <- rsample::loo_cv(rsample::analysis(folds$splits[[2]]))$splits[1]
  folds$inner_resamples[[2]] <- rsample::manual_rset(
    c(inner$splits, one_loo),
    paste0("Fold", 1:4)
  )
  cnd <- entry_refusal(nested_tune_grid(wf, folds, grid = det_grid()))
  expect_names_design(cnd, "loo_cv")
  expect_match(conditionMessage(cnd), "Element 2 of", fixed = TRUE)
  expect_no_match(conditionMessage(cnd), "Elements", fixed = TRUE)
})

test_that("an inner bootstrap with its apparent split still reaches the folds", {
  skip_if_no_engines()
  d <- support_data(n = 30)
  wf <- det_workflow(d)
  boots <- list(
    bootstraps = quote(rsample::bootstraps(times = 3, apparent = TRUE)),
    group_bootstraps = quote(
      rsample::group_bootstraps(group = g, times = 3, apparent = TRUE)
    )
  )
  for (design in names(boots)) {
    folds <- nested_cv_design(d, V3, boots[[design]])
    expect_s3_class(
      folds$inner_resamples[[1]]$splits[[4]],
      "apparent_split"
    )
    cnd <- entry_refusal(nested_tune_grid(wf, folds, grid = det_grid()))
    expect_s3_class(cnd, "nestedtune_sentinel")

    folds$inner_resamples <- lapply(folds$inner_resamples, rebuilt)
    cnd <- entry_refusal(nested_tune_grid(wf, folds, grid = det_grid()))
    expect_s3_class(cnd, "nestedtune_sentinel")
  }
})

test_that("an inner element that is not a data frame is still malformed", {
  skip_if_no_engines()
  d <- support_data(n = 30)
  wf <- det_workflow(d)
  folds <- nested_cv_design(d, V3, V3)
  folds$inner_resamples[[2]] <- "not a design"
  cnd <- entry_refusal(nested_tune_grid(wf, folds, grid = det_grid()))
  expect_s3_class(cnd, "nestedtune_bad_design")
  expect_match(conditionMessage(cnd), "malformed", fixed = TRUE)
})

# nested_resamples() reads the split classes of the rset it is handed as
# `outside`, and of each inner rset its `inside` call returns (M129).
test_that("nested_resamples() refuses an outside rebuilt from refused splits", {
  d <- support_data(n = 30)
  outer <- c(REFUSED_OUTER, apparent = quote(rsample::apparent()))
  for (design in names(outer)) {
    set.seed(1)
    again <- rebuilt(eval(rlang::call_modify(outer[[design]], data = quote(d))))
    cnd <- expect_error(
      nested_resamples(d, outside = again, inside = rsample::vfold_cv(v = 3)),
      class = "nestedtune_bad_design"
    )
    expect_names_design(cnd, design)
  }
  # One refused split among valid ones is enough.
  set.seed(1)
  mixed <- rsample::manual_rset(
    c(rsample::vfold_cv(d, v = 3)$splits, rsample::loo_cv(d)$splits[1]),
    paste0("Fold", 1:4)
  )
  cnd <- expect_error(
    nested_resamples(d, outside = mixed, inside = rsample::vfold_cv(v = 3)),
    class = "nestedtune_bad_design"
  )
  expect_names_design(cnd, "loo_cv")
  expect_match(conditionMessage(cnd), "Row 4 of", fixed = TRUE)
})

test_that("nested_resamples() refuses an inside that returns refused splits", {
  d <- support_data(n = 30)
  rebuilt_loo <- function(data) rebuilt(rsample::loo_cv(data))
  cnd <- expect_error(
    nested_resamples(
      d,
      outside = rsample::vfold_cv(v = 3),
      inside = rebuilt_loo()
    ),
    class = "nestedtune_bad_design"
  )
  expect_names_design(cnd, "loo_cv")
})

test_that("nested_resamples() still builds a bootstrap inside and a rebuilt v-fold outside", {
  d <- support_data(n = 30)
  set.seed(1)
  folds <- nested_resamples(
    d,
    outside = rsample::vfold_cv(v = 3),
    inside = rsample::bootstraps(times = 3, apparent = TRUE)
  )
  expect_s3_class(folds$inner_resamples[[1]]$splits[[4]], "apparent_split")

  set.seed(1)
  again <- rebuilt(rsample::vfold_cv(d, v = 3))
  folds <- nested_resamples(
    d,
    outside = again,
    inside = rsample::vfold_cv(v = 3)
  )
  expect_s3_class(folds, "manual_rset")
  expect_identical(nrow(folds), 3L)
})

test_that("the plain outer bootstrap refusals name the function", {
  skip_if_no_engines()
  d <- support_data(n = 30)
  wf <- det_workflow(d)
  boots <- list(
    bootstraps = quote(rsample::bootstraps(times = 3)),
    group_bootstraps = quote(rsample::group_bootstraps(group = g, times = 3))
  )
  for (design in names(boots)) {
    set.seed(1)
    rset <- eval(rlang::call_modify(boots[[design]], data = quote(d)))
    expect_s3_class(rset, design)
    cnd <- expect_error(
      nested_resamples(d, outside = rset, inside = rsample::vfold_cv(v = 3)),
      class = "nestedtune_bad_design"
    )
    expect_names_design(cnd, design)

    folds <- quiet_nested_cv(d, boots[[design]], V3)
    expect_s3_class(folds, design)
    cnd <- entry_refusal(nested_tune_grid(wf, folds, grid = det_grid()))
    expect_names_design(cnd, design)
    # The entry check serves seven functions, so its hint names none.
    expect_match(conditionMessage(cnd), "nestedtune refuses", fixed = TRUE)
    expect_no_match(conditionMessage(cnd), "nested_tune_grid()", fixed = TRUE)
  }
})

# tune refuses an inner loo_cv() or permutations() design by its rset class,
# so a design found by its split classes would run in tune. Its refusal gives
# the design's own flaw, the reason the outer loop gives, instead.
test_that("an inner design found by its splits is refused for its own flaw", {
  skip_if_no_engines()
  d <- support_data(n = 30)
  wf <- det_workflow(d)
  folds <- nested_cv_design(d, V3, REFUSED_INNER$loo_cv)
  cnd <- entry_refusal(nested_tune_grid(wf, folds, grid = det_grid()))
  expect_match(conditionMessage(cnd), "tune refuses", fixed = TRUE)

  folds$inner_resamples <- lapply(folds$inner_resamples, rebuilt)
  cnd <- entry_refusal(nested_tune_grid(wf, folds, grid = det_grid()))
  expect_names_design(cnd, "loo_cv")
  expect_match(conditionMessage(cnd), "one row per fold", fixed = TRUE)
  expect_no_match(conditionMessage(cnd), "tune refuses", fixed = TRUE)

  # Elements refused for different reasons get one line each.
  whole <- nested_cv_design(d, V3, REFUSED_INNER$loo_cv)
  folds$inner_resamples[[3]] <- whole$inner_resamples[[3]]
  cnd <- entry_refusal(nested_tune_grid(wf, folds, grid = det_grid()))
  expect_match(conditionMessage(cnd), "Elements 1 and 2 of", fixed = TRUE)
  expect_match(conditionMessage(cnd), "Element 3 of", fixed = TRUE)
  expect_match(conditionMessage(cnd), "tune refuses", fixed = TRUE)
  expect_match(conditionMessage(cnd), "one row per fold", fixed = TRUE)
})

test_that("nested_resamples() names the outer fold whose inner splits it refuses", {
  d <- support_data(n = 30)
  mixed_in <- function(data) {
    folds <- rsample::vfold_cv(data, v = 3)
    rsample::manual_rset(
      c(folds$splits, rsample::apparent(data)$splits),
      paste0("Fold", 1:4)
    )
  }
  cnd <- expect_error(
    nested_resamples(
      d,
      outside = rsample::vfold_cv(v = 3),
      inside = mixed_in()
    ),
    class = "nestedtune_bad_design"
  )
  expect_names_design(cnd, "apparent")
  expect_match(conditionMessage(cnd), "splits for outer fold 1", fixed = TRUE)
  expect_match(conditionMessage(cnd), "rows it trained on", fixed = TRUE)
  expect_no_match(conditionMessage(cnd), "cannot be an", fixed = TRUE)
  expect_no_match(conditionMessage(cnd), "tune reports", fixed = TRUE)
})

# An apparent split beside bootstrap splits joins the bootstrap only under
# the id "Apparent", the one split tune leaves out of its estimates. Any other
# id is scored on the rows the split trained on, so it counts as apparent()
# (M131, D-099). Each design is built with manual_rset() directly, because
# rebuilt() keeps the ids a design already has.
APPARENT_HINT <- paste(
  'tune leaves out an apparent split whose id is "Apparent", so a bootstrap',
  "keeps its apparent split only under that id."
)
# Its opening words, so a message holding any part of the hint is caught.
APPARENT_HINT_HEAD <- "tune leaves out an apparent split"

# The message on one line, so a sentence that cli wrapped is matched whole.
flat_message <- function(cnd) {
  gsub("\\s+", " ", cli::ansi_strip(conditionMessage(cnd)))
}

# The host's splits, then one apparent split whose id is `id`.
with_apparent <- function(data, host, id) {
  hosts <- list(
    bootstraps = function() {
      splits <- rsample::bootstraps(data, times = 3)$splits
      list(splits = splits, ids = paste0("Bootstrap", 1:3))
    },
    group_bootstraps = function() {
      splits <- rsample::group_bootstraps(data, group = g, times = 3)$splits
      list(splits = splits, ids = paste0("Bootstrap", 1:3))
    },
    mixed = function() {
      splits <- c(
        rsample::vfold_cv(data, v = 2)$splits,
        rsample::bootstraps(data, times = 2)$splits
      )
      list(
        splits = splits,
        ids = c("Fold1", "Fold2", "Bootstrap1", "Bootstrap2")
      )
    }
  )
  built <- hosts[[host]]()
  # c() would turn a factor into its integer code, so join the labels.
  ids <- c(built$ids, as.character(id))
  if (is.factor(id)) {
    ids <- factor(ids)
  }
  rsample::manual_rset(c(built$splits, rsample::apparent(data)$splits), ids)
}

# A bootstraps() rset whose apparent split was renamed in place keeps its
# rset class.
renamed_bootstraps <- function(data) {
  boots <- rsample::bootstraps(data, times = 3, apparent = TRUE)
  boots$id[[4]] <- "A"
  boots
}

# The same inner design, built on each outer fold's analysis set.
with_inner <- function(folds, build) {
  folds$inner_resamples <- lapply(
    folds$splits,
    function(split) build(rsample::analysis(split))
  )
  folds
}

APPARENT_HOSTS <- c("bootstraps", "group_bootstraps", "mixed")

test_that("an inner apparent split under another id is refused beside bootstrap splits", {
  skip_if_no_engines()
  d <- support_data(n = 30)
  wf <- det_workflow(d)
  builds <- list(renamed = renamed_bootstraps)
  for (host in APPARENT_HOSTS) {
    for (id in c("apparent", "Bootstrap4")) {
      builds[[paste(host, id)]] <- local({
        host <- host
        id <- id
        function(data) with_apparent(data, host, id)
      })
    }
  }
  expect_length(builds, 7L)
  expect_s3_class(renamed_bootstraps(d), "bootstraps")

  for (name in names(builds)) {
    build <- builds[[name]]
    folds <- with_inner(nested_cv_design(d, V3, V3), build)
    cnd <- entry_refusal(nested_tune_grid(wf, folds, grid = det_grid()))
    expect_names_design(cnd, "apparent")
    expect_match(conditionMessage(cnd), "Elements 1, 2, and 3", fixed = TRUE)
    expect_no_match(conditionMessage(cnd), "bootstraps()", fixed = TRUE)
    expect_match(flat_message(cnd), APPARENT_HINT, fixed = TRUE)

    cnd <- expect_error(
      nested_resamples(d, outside = rsample::vfold_cv(v = 3), inside = build()),
      class = "nestedtune_bad_design"
    )
    expect_names_design(cnd, "apparent")
    expect_match(conditionMessage(cnd), "splits for outer fold 1", fixed = TRUE)
    expect_no_match(conditionMessage(cnd), "bootstraps()", fixed = TRUE)
    expect_match(flat_message(cnd), APPARENT_HINT, fixed = TRUE)
  }
})

test_that("an inner apparent split beside v-fold splits alone gets no id hint", {
  skip_if_no_engines()
  d <- support_data(n = 30)
  wf <- det_workflow(d)
  build <- function(data) {
    rsample::manual_rset(
      c(rsample::vfold_cv(data, v = 3)$splits, rsample::apparent(data)$splits),
      c(paste0("Fold", 1:3), "Apparent")
    )
  }
  folds <- with_inner(nested_cv_design(d, V3, V3), build)
  cnd <- entry_refusal(nested_tune_grid(wf, folds, grid = det_grid()))
  expect_names_design(cnd, "apparent")
  expect_no_match(flat_message(cnd), APPARENT_HINT_HEAD, fixed = TRUE)

  cnd <- expect_error(
    nested_resamples(d, outside = rsample::vfold_cv(v = 3), inside = build()),
    class = "nestedtune_bad_design"
  )
  expect_names_design(cnd, "apparent")
  expect_no_match(flat_message(cnd), APPARENT_HINT_HEAD, fixed = TRUE)
})

test_that("an inner apparent split with an NA id is refused beside bootstrap splits", {
  skip_if_no_engines()
  d <- support_data(n = 30)
  wf <- det_workflow(d)
  for (id in list(NA_character_, factor(NA_character_))) {
    build <- function(data) with_apparent(data, "bootstraps", id)
    folds <- with_inner(nested_cv_design(d, V3, V3), build)
    inner_id <- folds$inner_resamples[[1]]$id
    expect_identical(is.factor(inner_id), is.factor(id))
    expect_true(is.na(inner_id[[length(inner_id)]]))
    cnd <- entry_refusal(nested_tune_grid(wf, folds, grid = det_grid()))
    expect_names_design(cnd, "apparent")
    expect_match(flat_message(cnd), APPARENT_HINT, fixed = TRUE)

    cnd <- expect_error(
      nested_resamples(d, outside = rsample::vfold_cv(v = 3), inside = build()),
      class = "nestedtune_bad_design"
    )
    expect_names_design(cnd, "apparent")
    expect_match(flat_message(cnd), APPARENT_HINT, fixed = TRUE)
  }
})

test_that("an apparent split joins no bootstrap in a table with no id column", {
  d <- support_data(n = 30)
  splits <- c(
    rsample::bootstraps(d, times = 2)$splits,
    rsample::apparent(d)$splits
  )
  expect_identical(
    split_designs(tibble::tibble(splits = splits)),
    c("bootstraps", "bootstraps", "apparent")
  )
  # The control: the same splits under the id "Apparent" join the bootstrap.
  expect_identical(
    split_designs(tibble::tibble(
      splits = splits,
      id = c("Bootstrap1", "Bootstrap2", "Apparent")
    )),
    c("bootstraps", "bootstraps", "bootstraps")
  )
})

test_that("a refusal that names another design gets no id hint", {
  skip_if_no_engines()
  d <- support_data(n = 30)
  wf <- det_workflow(d)
  # The loo_cv() split comes first, so the refusal names loo_cv(), although a
  # renamed apparent split sits beside the bootstrap splits.
  build <- function(data) {
    rsample::manual_rset(
      c(
        rsample::loo_cv(data)$splits[1],
        rsample::bootstraps(data, times = 2)$splits,
        rsample::apparent(data)$splits
      ),
      c("Resample1", "Bootstrap1", "Bootstrap2", "A")
    )
  }
  folds <- with_inner(nested_cv_design(d, V3, V3), build)
  cnd <- entry_refusal(nested_tune_grid(wf, folds, grid = det_grid()))
  expect_names_design(cnd, "loo_cv")
  expect_no_match(flat_message(cnd), APPARENT_HINT_HEAD, fixed = TRUE)

  cnd <- expect_error(
    nested_resamples(d, outside = rsample::vfold_cv(v = 3), inside = build()),
    class = "nestedtune_bad_design"
  )
  expect_names_design(cnd, "loo_cv")
  expect_no_match(flat_message(cnd), APPARENT_HINT_HEAD, fixed = TRUE)
})

test_that("an inner apparent split named Apparent still joins its bootstrap", {
  skip_if_no_engines()
  d <- support_data(n = 30)
  wf <- det_workflow(d)
  for (host in APPARENT_HOSTS) {
    for (id in list("Apparent", factor("Apparent"))) {
      build <- function(data) with_apparent(data, host, id)
      folds <- with_inner(nested_cv_design(d, V3, V3), build)
      inner_id <- folds$inner_resamples[[1]]$id
      expect_identical(is.factor(inner_id), is.factor(id))
      expect_identical(as.character(inner_id[[length(inner_id)]]), "Apparent")
      cnd <- entry_refusal(nested_tune_grid(wf, folds, grid = det_grid()))
      expect_s3_class(cnd, "nestedtune_sentinel")

      built <- nested_resamples(
        d,
        outside = rsample::vfold_cv(v = 3),
        inside = build()
      )
      last <- nrow(built$inner_resamples[[1]])
      expect_s3_class(
        built$inner_resamples[[1]]$splits[[last]],
        "apparent_split"
      )
    }
  }
})

# The outer loop refuses both designs, so only the naming is under test: each
# bullet is matched whole, which ties the rows to the function named.

test_that("an outer apparent split under another id is named as apparent()", {
  skip_if_no_engines()
  d <- support_data(n = 30)
  wf <- det_workflow(d)
  set.seed(1)
  hosts <- list(
    bootstraps = rsample::bootstraps(d, times = 3)$splits,
    permutations = rsample::permutations(d, permute = y, times = 3)$splits
  )
  outer_with <- function(host, id) {
    rsample::manual_rset(
      c(
        rsample::vfold_cv(d, v = 2)$splits,
        hosts[[host]],
        rsample::apparent(d)$splits
      ),
      c("Fold1", "Fold2", paste0("Resample", 1:3), id)
    )
  }
  both_entries <- function(outer) {
    folds <- quiet_nested_cv(d, outer, V3)
    list(
      resamples = entry_refusal(nested_tune_grid(wf, folds, grid = det_grid())),
      outside = expect_error(
        nested_resamples(d, outside = outer, inside = rsample::vfold_cv(v = 3)),
        class = "nestedtune_bad_design"
      )
    )
  }

  for (host in names(hosts)) {
    cnds <- both_entries(outer_with(host, "A"))
    for (arg in names(cnds)) {
      cnd <- cnds[[arg]]
      expect_s3_class(cnd, "nestedtune_bad_design")
      msg <- flat_message(cnd)
      expect_match(
        msg,
        sprintf("Row 6 of `%s` holds a `rsample::apparent()` split.", arg),
        fixed = TRUE
      )
      expect_match(
        msg,
        sprintf(
          "Rows 3, 4, and 5 of `%s` hold `rsample::%s()` splits.",
          arg,
          host
        ),
        fixed = TRUE
      )
    }
  }

  # Under the id "Apparent" the split cannot be told from the bootstrap's own.
  cnds <- both_entries(outer_with("bootstraps", "Apparent"))
  for (arg in names(cnds)) {
    msg <- flat_message(cnds[[arg]])
    expect_match(
      msg,
      sprintf(
        "Rows 3, 4, 5, and 6 of `%s` hold `rsample::bootstraps()` splits.",
        arg
      ),
      fixed = TRUE
    )
    expect_no_match(msg, "apparent()", fixed = TRUE)
  }
})

# tune leaves every split whose id is "Apparent" out of its estimates, so any
# split but a bootstrap's own apparent split would drop out of inner tuning
# with nothing said (M132, D-100). The ids are relabelled in place, which
# keeps the rset class.
relabel_first <- function(build, factor_id = FALSE) {
  function(data) {
    rset <- build(data)
    ids <- as.character(rset$id)
    ids[[1]] <- "Apparent"
    rset$id <- if (factor_id) factor(ids) else ids
    rset
  }
}

RELABELLED <- list(
  "v-fold" = relabel_first(function(data) rsample::vfold_cv(data, v = 3)),
  "v-fold, factor id" = relabel_first(
    function(data) rsample::vfold_cv(data, v = 3),
    factor_id = TRUE
  ),
  bootstrap = relabel_first(function(data) rsample::bootstraps(data, times = 3))
)

APPARENT_ID_REASON <- "tune leaves every split whose id is \"Apparent\" out"

test_that("an inner split relabelled Apparent is refused", {
  skip_if_no_engines()
  d <- support_data(n = 30)
  wf <- det_workflow(d)
  for (name in names(RELABELLED)) {
    build <- RELABELLED[[name]]
    inner <- build(d)
    expect_s3_class(inner, "rset")
    expect_identical(is.factor(inner$id), grepl("factor", name))
    expect_identical(as.character(inner$id[[1]]), "Apparent")
    expect_false(inherits(inner$splits[[1]], "apparent_split"))

    folds <- with_inner(nested_cv_design(d, V3, V3), build)
    cnd <- entry_refusal(nested_tune_grid(wf, folds, grid = det_grid()))
    expect_s3_class(cnd, "nestedtune_bad_design")
    expect_match(flat_message(cnd), APPARENT_ID_REASON, fixed = TRUE)
    expect_match(conditionMessage(cnd), "Elements 1, 2, and 3", fixed = TRUE)
    expect_identical(rlang::call_name(conditionCall(cnd)), "nested_tune_grid")

    cnd <- expect_error(
      nested_resamples(d, outside = rsample::vfold_cv(v = 3), inside = build()),
      class = "nestedtune_bad_design"
    )
    expect_match(flat_message(cnd), APPARENT_ID_REASON, fixed = TRUE)
    expect_match(conditionMessage(cnd), "outer fold 1", fixed = TRUE)
  }
})

test_that("a bootstrap's own apparent split still reaches the folds", {
  skip_if_no_engines()
  d <- support_data(n = 30)
  wf <- det_workflow(d)
  folds <- nested_cv_design(
    d,
    V3,
    quote(rsample::bootstraps(times = 3, apparent = TRUE))
  )
  expect_identical(folds$inner_resamples[[1]]$id[[4]], "Apparent")
  cnd <- entry_refusal(nested_tune_grid(wf, folds, grid = det_grid()))
  expect_s3_class(cnd, "nestedtune_sentinel")
})

# tune drops a split whose id is NA from its estimate and adds an empty metric
# row, and it miscounts the resamples of a design whose ids repeat (M133,
# D-102). The ids are edited in place, which keeps the rset class.
edit_ids <- function(build, edit) {
  function(data) edit(build(data))
}

vfold3 <- function(data) rsample::vfold_cv(data, v = 3)
vfold3x2 <- function(data) rsample::vfold_cv(data, v = 3, repeats = 2)

first_id_missing <- function(as_id) {
  function(rset) {
    ids <- as.character(rset$id)
    ids[[1]] <- NA
    rset$id <- as_id(ids)
    rset
  }
}

MISSING_ID <- list(
  character = edit_ids(vfold3, first_id_missing(identity)),
  factor = edit_ids(vfold3, first_id_missing(factor)),
  "factor NA level" = edit_ids(
    vfold3,
    first_id_missing(function(ids) addNA(factor(ids)))
  )
)

REPEATED_ID <- list(
  id = edit_ids(vfold3, function(rset) {
    rset$id[[2]] <- rset$id[[1]]
    rset
  }),
  "id and id2" = edit_ids(vfold3x2, function(rset) {
    rset$id2[[2]] <- rset$id2[[1]]
    rset
  }),
  "missing id2" = edit_ids(vfold3x2, function(rset) {
    rset$id2[1:2] <- NA
    rset
  })
)

MISSING_ID_REASON <- "tune leaves a split with a missing id out of its estimates"
REPEATED_ID_REASON <- "tune miscounts the resamples of a design whose ids repeat"

expect_id_refusals <- function(builds, reason, d, wf) {
  for (name in names(builds)) {
    build <- builds[[name]]
    folds <- with_inner(nested_cv_design(d, V3, V3), build)
    cnd <- entry_refusal(nested_tune_grid(wf, folds, grid = det_grid()))
    expect_s3_class(cnd, "nestedtune_bad_design")
    expect_match(flat_message(cnd), reason, fixed = TRUE)
    expect_match(conditionMessage(cnd), "Elements 1, 2, and 3", fixed = TRUE)
    expect_identical(rlang::call_name(conditionCall(cnd)), "nested_tune_grid")

    cnd <- expect_error(
      nested_resamples(d, outside = rsample::vfold_cv(v = 3), inside = build()),
      class = "nestedtune_bad_design"
    )
    expect_match(flat_message(cnd), reason, fixed = TRUE)
    expect_match(conditionMessage(cnd), "outer fold 1", fixed = TRUE)
  }
}

test_that("an inner split with a missing id is refused", {
  skip_if_no_engines()
  d <- support_data(n = 30)
  wf <- det_workflow(d)
  # The NA level reads as a missing label, although is.na() does not see it.
  level <- MISSING_ID[["factor NA level"]](d)
  expect_false(anyNA(level$id))
  expect_true(is.na(as.character(level$id[[1]])))
  expect_id_refusals(MISSING_ID, MISSING_ID_REASON, d, wf)
})

test_that("a missing inner id in one outer fold names that element alone", {
  skip_if_no_engines()
  d <- support_data(n = 30)
  wf <- det_workflow(d)
  folds <- nested_cv_design(d, V3, V3)
  folds$inner_resamples[[2]]$id[[1]] <- NA
  cnd <- entry_refusal(nested_tune_grid(wf, folds, grid = det_grid()))
  expect_s3_class(cnd, "nestedtune_bad_design")
  expect_match(flat_message(cnd), MISSING_ID_REASON, fixed = TRUE)
  expect_match(conditionMessage(cnd), "Element 2 of", fixed = TRUE)
})

test_that("an inner design whose ids repeat is refused", {
  skip_if_no_engines()
  d <- support_data(n = 30)
  wf <- det_workflow(d)
  expect_id_refusals(REPEATED_ID, REPEATED_ID_REASON, d, wf)
})

test_that("repeated v-fold ids and a missing id2 still reach the folds", {
  skip_if_no_engines()
  d <- support_data(n = 30)
  wf <- det_workflow(d)
  one_missing_id2 <- edit_ids(vfold3x2, function(rset) {
    rset$id2[[1]] <- NA
    rset
  })
  # The id column repeats across id2 in a repeated design, so only the pair
  # of the two columns tells the splits apart.
  expect_true(anyDuplicated(vfold3x2(d)$id) > 0L)
  for (build in list(vfold3x2, one_missing_id2)) {
    folds <- with_inner(nested_cv_design(d, V3, V3), build)
    cnd <- entry_refusal(nested_tune_grid(wf, folds, grid = det_grid()))
    expect_s3_class(cnd, "nestedtune_sentinel")
  }
})

# finetune's race eliminates candidates on unsummarized metrics, which keep
# a bootstrap's apparent split, so the two racers refuse that split (M132,
# D-100). The other tuners read tune's summarized estimate, which leaves it
# out, and keep accepting it.
RACE_APPARENT_REASON <- c(
  "eliminates candidates on the score",
  "rows the model trained on"
)

expect_race_refused <- function(cnd) {
  expect_s3_class(cnd, "nestedtune_bad_design")
  for (reason in RACE_APPARENT_REASON) {
    expect_match(flat_message(cnd), reason, fixed = TRUE)
  }
}

# The exports, where the helpers' RACERS names the tuners.
RACE_EXPORTS <- c("nested_tune_race_anova", "nested_tune_race_win_loss")

race_call <- function(fn, wf, folds) {
  switch(
    fn,
    nested_tune_race_anova = nested_tune_race_anova(
      wf,
      folds,
      grid = det_grid()
    ),
    nested_tune_race_win_loss = nested_tune_race_win_loss(
      wf,
      folds,
      grid = det_grid()
    )
  )
}

# One test per racer, so a racer that is not ready reports its own skip.
for (fn in RACE_EXPORTS) {
  test_that(paste(fn, "refuses a bootstrap's apparent split at entry"), {
    skip_if_no_engines()
    skip_if_not(tuner_ready(fn))
    d <- support_data(n = 30)
    folds <- nested_cv_design(
      d,
      V3,
      quote(rsample::bootstraps(times = 3, apparent = TRUE))
    )
    cnd <- entry_refusal(race_call(fn, det_workflow(d), folds))
    expect_race_refused(cnd)
    expect_identical(rlang::call_name(conditionCall(cnd)), fn)
  })
}

test_that("a race refuses the apparent split of rebuilt and grouped bootstraps", {
  skip_if_no_engines()
  skip_if_not(tuner_ready("nested_tune_race_anova"))
  d <- support_data(n = 30)
  wf <- det_workflow(d)
  boots <- quote(rsample::bootstraps(times = 3, apparent = TRUE))
  # A group bootstrap, a manual_rset() rebuild and a factor id, under one race.
  designs <- list(
    group_bootstraps = function() {
      nested_cv_design(
        d,
        V3,
        quote(rsample::group_bootstraps(group = g, times = 3, apparent = TRUE))
      )
    },
    rebuilt = function() {
      folds <- nested_cv_design(d, V3, boots)
      folds$inner_resamples <- lapply(folds$inner_resamples, rebuilt)
      expect_s3_class(folds$inner_resamples[[1]], "manual_rset")
      folds
    },
    factor_id = function() {
      with_inner(
        nested_cv_design(d, V3, V3),
        function(data) with_apparent(data, "bootstraps", factor("Apparent"))
      )
    }
  )
  for (name in names(designs)) {
    folds <- designs[[name]]()
    inner <- folds$inner_resamples[[1]]
    last <- nrow(inner)
    expect_s3_class(inner$splits[[last]], "apparent_split")
    expect_identical(as.character(inner$id[[last]]), "Apparent")
    cnd <- entry_refusal(
      nested_tune_race_anova(wf, folds, grid = det_grid())
    )
    expect_race_refused(cnd)
  }
})

test_that("a race still reaches the folds on a bootstrap without its apparent split", {
  skip_if_no_engines()
  skip_if_not(tuner_ready("nested_tune_race_anova"))
  d <- support_data(n = 30)
  wf <- det_workflow(d)
  folds <- nested_cv_design(
    d,
    V3,
    quote(rsample::bootstraps(times = 4, apparent = FALSE))
  )
  cnd <- entry_refusal(nested_tune_race_anova(wf, folds, grid = det_grid()))
  expect_s3_class(cnd, "nestedtune_sentinel")
})

for (fn in RACE_EXPORTS) {
  test_that(
    paste("the map under", fn, "refuses a bootstrap's apparent split first"),
    {
      skip_if_no_engines()
      skip_if_no_wset_fixture(fn)
      d <- support_data(n = 30)
      folds <- nested_cv_design(
        d,
        V3,
        quote(rsample::bootstraps(times = 3, apparent = TRUE))
      )
      # The unmarked workflow comes first and routes to
      # nested_fit_resamples(), which accepts the design. The sentinel stands
      # in for the fold dispatch, so the bad-design class shows that none of
      # its folds ran.
      set <- workflowsets::as_workflow_set(
        fixed = fixed_workflow(d),
        tuned = det_workflow(d)
      )
      cnd <- entry_refusal(
        nested_workflow_map(set, fn = fn, resamples = folds, grid = det_grid())
      )
      expect_race_refused(cnd)
    }
  )
}
