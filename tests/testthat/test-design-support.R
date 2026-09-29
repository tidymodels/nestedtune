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
