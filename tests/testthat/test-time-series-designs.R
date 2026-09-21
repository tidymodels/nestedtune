# Oracle records for rolling-origin and sliding-window outer designs (M108).
# DESIGN Conventions: oracles are recorded in the test file that asserts them.
#
# O1 -- type "live" (reference implementation). Source: the tidymodels pipeline
#   itself, recomputed at test time by reference_nested_loop() in
#   helper-orchestration.R, written from the documented seed contract rather
#   than from the driver. Run here on designs built by rsample::nested_cv()
#   with `rolling_origin()` and `sliding_window()` outer resamples. Pinned by
#   the two "match a hand-rolled reference loop" tests. Satisfies AC1/AC2.

expect_matches_reference <- function(res, ref) {
  expect_identical(res$.tuning_seed, ref_field(ref, "tuning_seed"))
  expect_identical(res$.outer_fit_seed, ref_field(ref, "outer_fit_seed"))
  for (i in seq_len(nrow(res))) {
    expect_identical(res$.metrics[[i]], ref[[i]]$metrics)
    expect_identical(res$.selected[[i]], ref[[i]]$selected)
  }
}

test_that("a rolling-origin design matches a hand-rolled reference loop", {
  skip_if_no_engines()

  d <- make_reg_data()
  wf <- det_workflow(d)
  ms <- ts_metrics()
  grid <- det_grid()
  folds <- ts_rolling_nested(d)
  expect_s3_class(folds$splits[[1]], "rof_split")

  set.seed(20)
  res <- nested_tune_grid(wf, folds, grid = grid, metrics = ms)
  ref <- memoised(reference_nested_loop(
    wf,
    folds,
    grid,
    ms,
    seed = 20,
    metric_name = "rmse"
  ))

  expect_true(all(res$.completed))
  expect_matches_reference(res, ref)
})

test_that("a sliding-window design matches a hand-rolled reference loop", {
  skip_if_no_engines()

  d <- make_reg_data()
  wf <- det_workflow(d)
  ms <- ts_metrics()
  grid <- det_grid()
  folds <- ts_sliding_nested(d)
  expect_s3_class(folds$splits[[1]], "sliding_window_split")

  set.seed(21)
  res <- nested_tune_grid(wf, folds, grid = grid, metrics = ms)
  ref <- memoised(reference_nested_loop(
    wf,
    folds,
    grid,
    ms,
    seed = 21,
    metric_name = "rmse"
  ))

  expect_true(all(res$.completed))
  expect_matches_reference(res, ref)
})
