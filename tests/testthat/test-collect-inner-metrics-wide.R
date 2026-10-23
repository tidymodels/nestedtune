# `collect_inner_metrics(type = "wide")`. The oracle is tune's own wide table
# on fold 1's inner run, rebuilt by hand from the documented seed contract
# (`reference_nested_loop()`). The grid names every candidate and no range
# depends on the data, so the rebuilt run can tune on `inner_resamples[[1]]`
# itself. An oracle file, so it skips on CRAN as the others do.

skip_heavy_on_cran()

grid_inner_run <- function(d, seed = 41) {
  wf <- det_workflow(d)
  folds <- det_nested(d)
  ms <- reg_metrics()
  set.seed(seed)
  memoised(nested_tune_grid(wf, folds, grid = det_grid(), metrics = ms))
}

# A workflow whose tuned parameter has the id `rmse`, the name of a metric
# in `reg_metrics()`: the wide table would overwrite the parameter's column.
clash_workflow <- function(data) {
  rec <- recipes::step_pca(
    recipes::recipe(y ~ x1 + x2 + x3 + x4, data = data),
    recipes::all_predictors(),
    num_comp = tune::tune("rmse")
  )
  workflows::workflow(rec, parsnip::linear_reg())
}

test_that("type = \"long\" returns the table the call without type returns", {
  skip_if_no_engines()
  d <- make_reg_data()
  res <- grid_inner_run(d)
  expect_identical(
    collect_inner_metrics(res, type = "long"),
    collect_inner_metrics(res)
  )
})

test_that("fold 1's wide rows equal tune's wide table on fold 1's inner run", {
  skip_if_no_engines()
  d <- make_reg_data()
  # Built first, from the stream state make_reg_data() leaves, so the
  # recipe's step id and so the cache key are the other block's.
  res <- grid_inner_run(d)
  wf <- det_workflow(d)
  folds <- det_nested(d)
  ref <- memoised(reference_nested_loop(
    wf,
    folds,
    grid = det_grid(),
    metrics = reg_metrics(),
    seed = 41,
    metric_name = "rmse"
  ))

  wide <- collect_inner_metrics(res, type = "wide")
  expect_named(wide, c("id", "num_comp", ".config", "rmse", "rsq"))
  fold1 <- wide[wide$id == res$id[[1L]], setdiff(names(wide), "id")]
  expect_identical(fold1, tune::collect_metrics(ref[[1L]]$tuned, type = "wide"))
  # Each cell is the long table's mean for that fold, candidate and metric.
  long <- collect_inner_metrics(res)
  at <- long$id == res$id[[2L]] &
    long$.config == wide$.config[[4L]] &
    long$.metric == "rsq"
  expect_identical(wide$id[[4L]], res$id[[2L]])
  expect_identical(wide$rsq[[4L]], long$mean[at])
})

test_that(".iter stays a key column on a Bayesian run", {
  skip_if_no_bayes_fixture()
  res <- bayes_results()
  long <- collect_inner_metrics(res)
  wide <- collect_inner_metrics(res, type = "wide")
  expect_true(".iter" %in% names(wide))
  expect_false(any(
    c(".metric", ".estimator", "mean", "n", "std_err") %in% names(wide)
  ))
  # One row per fold and candidate: the long table has one row per metric
  # for each.
  metrics <- unique(long$.metric)
  expect_identical(nrow(wide), nrow(long) %/% length(metrics))
  expect_identical(
    wide$.iter,
    long$.iter[long$.metric == metrics[[1L]]]
  )
})

test_that("the set's wide table is keyed on wflow_id", {
  skip_if_no_wset_fixture()
  d <- make_reg_data()
  set.seed(41)
  res <- memoised(nested_workflow_map(
    wset_two(d),
    resamples = det_nested(d),
    grid = det_grid(),
    metrics = reg_metrics()
  ))
  expect_identical(
    collect_inner_metrics(res, type = "long"),
    collect_inner_metrics(res)
  )
  wide <- collect_inner_metrics(res, type = "wide")
  expect_identical(names(wide)[[1L]], "wflow_id")
  # The fixed workflow scored no inner candidates, so every row is the
  # tuned workflow's, and they equal its own wide table.
  expect_identical(unique(wide$wflow_id), "tuned")
  expect_identical(
    wide[setdiff(names(wide), "wflow_id")],
    collect_inner_metrics(res$result[[1L]], type = "wide")
  )
})

expect_wide_refusals <- function(x) {
  cnd <- expect_error(
    collect_inner_metrics(x, type = "wide"),
    class = "nestedtune_wide_collision"
  )
  expect_match(conditionMessage(cnd), "rmse", fixed = TRUE)
  expect_error(
    collect_inner_metrics(x, type = "tall"),
    class = "nestedtune_bad_type"
  )
}

test_that("a metric named like a key column and a bad type are refused on a run", {
  skip_if_no_engines()
  d <- make_reg_data()
  folds <- det_nested(d)
  set.seed(41)
  res <- memoised(nested_tune_grid(
    clash_workflow(d),
    folds,
    grid = data.frame(rmse = 1:3),
    metrics = reg_metrics()
  ))
  expect_wide_refusals(res)
})

test_that("a metric named like a key column and a bad type are refused on a set", {
  skip_if_no_wset_fixture()
  d <- make_reg_data()
  folds <- det_nested(d)
  set.seed(41)
  set <- memoised(nested_workflow_map(
    workflowsets::as_workflow_set(clash = clash_workflow(d)),
    resamples = folds,
    grid = data.frame(rmse = 1:3),
    metrics = reg_metrics()
  ))
  expect_wide_refusals(set)
})
