# nested_tune_bayes() on the rolling-origin time-series design (M110, cut to
# one design at M113 under D-079), and its final fit on the rolling-origin
# and sliding-window designs.
# DESIGN Conventions: oracles are recorded in the test file that asserts them.
# The M110 tests sit in four files, test-time-series-*.R, so no one file runs
# alone for long under parallel test files.
#
# O1 -- type "live" (reference implementation). Source:
#   reference_nested_bayes_loop() in helper-orchestration.R, written from the
#   seed contract rather than from the driver, run here on the rolling-origin
#   design alone (M113): the outer design never reaches tuner code, and
#   test-time-series-designs.R runs the grid and fit_resamples paths on every
#   design in TS_DESIGNS. Pinned by the
#   "nested_tune_bayes() matches its reference loop on a ... design" test.
#   Satisfies M110 AC1 for this tuner.
#
# O2 -- type "live" (reference implementation). Source:
#   reference_bayes_final_fit() in helper-orchestration.R, handed the
#   fixtures' literal inner `rolling_origin()` call as `inner_design`, so the
#   reference builds the inner design on the full data from its own spelling
#   of the call and selects with `select_best()` itself. Pinned by "the
#   Bayesian final fit on a ... result matches its reference". Satisfies M110
#   AC3 for this tuner.
#
# Both fixtures share the data, the inner call and the tuner's arguments, and
# the final fit never reads the outer split indices, so a sliding-window
# result gives the same final fit as a rolling-origin one. The sliding-window
# final-fit test checks it once, against the same reference.
#
# O1 and O2 check that the orchestrator gives what tune gives when run by
# hand. The estimate itself adds nothing new for these designs, so no second
# oracle type is asked of them here.

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

  # The reference loop runs on the rolling-origin design alone (M113); the
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

  # The final fit reads the data and the recorded procedure, never the
  # outer split indices, so the two M110 designs stand for the M111 ones and
  # the suite does not pay for two more final fits (M111). The sliding-window
  # test is what evidences that claim (D-075), so it stays under M113.
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
