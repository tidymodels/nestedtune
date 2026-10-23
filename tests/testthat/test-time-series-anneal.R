# nested_tune_sim_anneal() on the rolling-origin time-series design, and its
# final fit on the same design. DESIGN Conventions: oracles are recorded in
# the test file that asserts them. The time-series tests are split across the
# test-time-series-*.R files, so no one file runs alone for long under
# parallel test files.
#
# Source:
#   reference_nested_anneal_loop() in helper-orchestration.R, written from the
#   seed contract rather than from the driver, run here on the rolling-origin
#   design alone: the outer design never reaches tuner code, and
#   test-time-series-designs.R runs the grid reference loop and the
#   fit_resamples paths on every design in TS_DESIGNS. Pinned by the
#   "nested_tune_sim_anneal() matches its reference loop on a rolling-origin
#   design" test.
#
# Source:
#   reference_anneal_final_fit() in helper-orchestration.R, handed the
#   fixtures' literal inner `rolling_origin()` call as `inner_design`, so the
#   reference builds the inner design on the full data from its own spelling
#   of the call and selects with `select_best()` itself. Pinned by "the
#   annealing final fit on a rolling-origin result matches its reference".
#
# Both check that the orchestrator gives what finetune gives when run by hand.

skip_heavy_on_cran()

ts_anneal_run <- function(wf, folds, ms, ctrl) {
  set.seed(24)
  memoised(nested_tune_sim_anneal(
    wf,
    folds,
    iter = 2,
    initial = 3,
    metrics = ms,
    control = ctrl
  ))
}

for (design in "rolling-origin") {
  build <- TS_DESIGNS[[design]]

  test_that(
    sprintf(
      "nested_tune_sim_anneal() matches its reference loop on a %s design",
      design
    ),
    {
      skip_if_no_anneal_fixture()
      d <- TS_DATA[[design]]()
      wf <- det_workflow(d)
      folds <- build(d)
      expect_s3_class(folds$splits[[1]], TS_SPLIT_CLASS[[design]])
      ms <- ts_metrics()
      ctrl <- anneal_control()

      res <- ts_anneal_run(wf, folds, ms, ctrl)
      ref <- memoised(reference_nested_anneal_loop(
        wf,
        folds,
        iter = 2,
        initial = 3,
        metrics = ms,
        seed = 24,
        metric_name = "rmse",
        control = ctrl
      ))

      expect_ts_matches_reference(res, ref)
    }
  )
}

test_that("the annealing final fit on a rolling-origin result matches its reference", {
  skip_if_no_anneal_fixture()
  d <- make_reg_data()
  wf <- det_workflow(d)
  folds <- ts_rolling_nested(d)
  ms <- ts_metrics()
  ctrl <- anneal_control()

  res <- ts_anneal_run(wf, folds, ms, ctrl)
  set.seed(43)
  final <- nested_final_fit(wf, res)
  ref <- reference_anneal_final_fit(
    wf,
    d,
    iter = 2,
    initial = 3,
    metrics = ms,
    seed = 43,
    metric_name = "rmse",
    control = ctrl,
    inner_design = ts_inner
  )
  expect_ts_final_matches(final, ref, d)
})
