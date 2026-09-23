# nested_tune_bayes() and its final fit on the time-series designs (M110,
# M111).
# DESIGN Conventions: oracles are recorded in the test file that asserts them.
# The M110 tests sit in four files, test-time-series-*.R, so no one file runs
# alone for long under parallel test files.
#
# O1 -- type "live" (reference implementation). Source:
#   reference_nested_bayes_loop() in helper-orchestration.R, written from the
#   seed contract rather than from the driver, run here on every design in
#   TS_DESIGNS (M110, M111). Pinned by the
#   "nested_tune_bayes() matches its reference loop on a ... design" tests.
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
# the final fit never reads the outer splits, so a sliding-window result gives
# the same final fit as a rolling-origin one. The sliding-window final-fit
# test checks it once, against the same reference.
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

for (design in names(TS_DESIGNS)) {
  build <- TS_DESIGNS[[design]]

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

  # The final fit reads the data and the recorded procedure, never the
  # outer splits, so the two M110 designs stand for the M111 ones here and
  # the suite does not pay for two more final fits (M111).
  if (!design %in% c("rolling-origin", "sliding-window")) {
    next
  }

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
