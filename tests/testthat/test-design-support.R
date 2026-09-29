# The designs the README's resampling table marks, one role at a time (M127).
#
# A `Yes` cell is a design that runs through nested_tune_grid() with a v-fold
# partner in the other role and completes every outer fold. A `Refused` cell
# is the bootstrap refusal. A `No` cell is pinned by the behavior the README
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
      expect_s3_class(run$folds$inner_resamples[[1]], design)
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
    "cannot be a bootstrap"
  )
  set.seed(1)
  boots <- rsample::group_bootstraps(d, group = g, times = 3)
  expect_error(
    nested_resamples(d, outside = boots, inside = rsample::vfold_cv(v = 3)),
    "cannot be a bootstrap"
  )
})

# Every outer fold failed, each with a note naming why.
expect_every_fold_fails <- function(res, pattern) {
  expect_false(any(res$.completed))
  for (notes in res$.notes) {
    expect_true(any(grepl(pattern, notes$note)))
  }
}

test_that("an outer leave-one-out design scores one row per fold", {
  skip_if_no_engines()
  run <- suppressWarnings(support_run(
    support_data(n = 30),
    quote(rsample::loo_cv()),
    V3,
    control = tune::control_grid(save_pred = TRUE)
  ))
  held <- vapply(
    run$res$splits,
    function(s) nrow(rsample::assessment(s)),
    integer(1)
  )
  expect_true(all(held == 1L))
  expect_true(all(run$res$.completed))
  m <- collect_metrics(run$res)
  expect_true(is.na(m$mean[m$.metric == "rsq"]))
  # RMSE over one row is that row's absolute error, so their mean is the
  # mean absolute error.
  p <- collect_predictions(run$res)
  expect_equal(m$mean[m$.metric == "rmse"], mean(abs(p$.pred - p$y)))
})

test_that("an inner leave-one-out design fails every fold in tune", {
  skip_if_no_engines()
  expect_warning(
    run <- support_run(support_data(n = 30), V3, quote(rsample::loo_cv())),
    class = "nestedtune_failed_folds"
  )
  expect_every_fold_fails(
    run$res,
    "Leave-one-out cross-validation is not currently supported"
  )
})

test_that("an outer apparent design scores the rows it trained on", {
  skip_if_no_engines()
  run <- support_run(support_data(), quote(rsample::apparent()), V3)
  expect_identical(nrow(run$res), 1L)
  expect_true(run$res$.completed)
  split <- run$res$splits[[1]]
  expect_identical(rsample::assessment(split), rsample::analysis(split))
})

test_that("an inner apparent design fails every fold in tune", {
  skip_if_no_engines()
  expect_warning(
    run <- support_run(support_data(), V3, quote(rsample::apparent())),
    class = "nestedtune_failed_folds"
  )
  expect_every_fold_fails(run$res, "No results are available")
})

test_that("validation_set() cannot be built in either role", {
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

test_that("an outer permutation design fails every fold for want of an assessment set", {
  skip_if_no_engines()
  expect_warning(
    run <- support_run(
      support_data(),
      quote(rsample::permutations(permute = y, times = 3)),
      V3
    ),
    class = "nestedtune_failed_folds"
  )
  expect_every_fold_fails(run$res, "no assessment data set")
})

test_that("an inner permutation design fails every fold in tune", {
  skip_if_no_engines()
  expect_warning(
    run <- support_run(
      support_data(),
      V3,
      quote(rsample::permutations(permute = y, times = 3))
    ),
    class = "nestedtune_failed_folds"
  )
  expect_every_fold_fails(
    run$res,
    "Permutation samples are not suitable for tuning"
  )
})
