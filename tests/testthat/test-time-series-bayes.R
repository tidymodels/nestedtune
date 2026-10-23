# nested_tune_bayes() on the rolling-origin time-series design, and its final
# fit on the rolling-origin and sliding-window designs.
# DESIGN Conventions: oracles are recorded in the test file that asserts them.
# The time-series tests are split across the test-time-series-*.R files, so no
# one file runs alone for long under parallel test files.
#
# Source:
#   reference_nested_bayes_loop() in helper-orchestration.R, written from the
#   seed contract rather than from the driver, run here on the rolling-origin
#   design alone: the outer design never reaches tuner code, and
#   test-time-series-designs.R runs the grid reference loop and the
#   fit_resamples paths on every design in TS_DESIGNS. Pinned by the
#   "nested_tune_bayes() matches its reference loop on a ... design" test.
#
# Source:
#   reference_bayes_final_fit() in helper-orchestration.R, handed the
#   fixtures' literal inner `rolling_origin()` call as `inner_design`, so the
#   reference builds the inner design on the full data from its own spelling
#   of the call and selects with `select_best()` itself. Pinned by "the
#   Bayesian final fit on a ... result matches its reference".
#
# Both fixtures share the data, the inner call and the tuner's arguments, and
# the final fit never reads the outer split indices, so a sliding-window
# result gives the same final fit as a rolling-origin one. The sliding-window
# final-fit test checks it once, against the same reference.
#
# Both check that the orchestrator gives what tune gives when run by hand.

skip_heavy_on_cran()

ts_bayes_run <- function(wf, folds, p, ms) {
  set.seed(22)
  memoised(nested_tune_bayes(
    wf,
    folds,
    iter = 2,
    initial = 3,
    param_info = p,
    metrics = ms
  ))
}

for (design in c("rolling-origin", "sliding-window")) {
  build <- TS_DESIGNS[[design]]

  # The reference loop runs on the rolling-origin design alone; the
  # sliding-window run below serves only its final-fit test.
  if (design == "rolling-origin") {
    test_that(
      sprintf(
        "nested_tune_bayes() matches its reference loop on a %s design",
        design
      ),
      {
        skip_if_no_bayes_fixture()
        d <- TS_DATA[[design]]()
        wf <- bayes_workflow(d)
        folds <- build(d)
        expect_s3_class(folds$splits[[1]], TS_SPLIT_CLASS[[design]])
        p <- bayes_param_info(wf)
        ms <- ts_metrics()

        res <- ts_bayes_run(wf, folds, p, ms)
        ref <- memoised(reference_nested_bayes_loop(
          wf,
          folds,
          iter = 2,
          initial = 3,
          objective = tune::exp_improve(),
          param_info = p,
          metrics = ms,
          seed = 22,
          metric_name = "rmse"
        ))

        expect_ts_matches_reference(res, ref)
      }
    )
  }

  # The final fit reads the data and the recorded procedure, never the outer
  # split indices, so the two designs here stand for the sliding-index and
  # sliding-period designs, and the suite does not pay for two more final fits.
  # The sliding-window test is what evidences that claim.
  test_that(
    sprintf(
      "the Bayesian final fit on a %s result matches its reference",
      design
    ),
    {
      skip_if_no_bayes_fixture()
      d <- TS_DATA[[design]]()
      wf <- bayes_workflow(d)
      folds <- build(d)
      expect_s3_class(folds$splits[[1]], TS_SPLIT_CLASS[[design]])
      p <- bayes_param_info(wf)
      ms <- ts_metrics()

      res <- ts_bayes_run(wf, folds, p, ms)
      set.seed(41)
      final <- nested_final_fit(wf, res)
      ref <- reference_bayes_final_fit(
        wf,
        d,
        iter = 2,
        initial = 3,
        objective = tune::exp_improve(),
        param_info = p,
        metrics = ms,
        seed = 41,
        metric_name = "rmse",
        inner_design = ts_inner
      )
      expect_ts_final_matches(final, ref, d)
    }
  )
}
