# The two racing tuners on the rolling-origin time-series design (M110, cut
# to one design at M113 under D-079), and their final fits on the same
# design. DESIGN Conventions: oracles are recorded in the test file that
# asserts them. The M110 tests sit in four files, test-time-series-*.R, so
# no one file runs alone for long under parallel test files.
#
# O1 -- type "live" (reference implementation). Source:
#   reference_nested_race_loop() in helper-orchestration.R, written from the
#   seed contract rather than from the driver, run here for each racer on
#   the rolling-origin design alone (M113): the outer design never reaches
#   tuner code, every fixture's inner call is the same `rolling_origin()`,
#   and test-time-series-designs.R runs the grid and fit_resamples paths on
#   every design in TS_DESIGNS. Pinned by the "<racer> matches its reference
#   loop on a rolling-origin design" tests. Satisfies M110 AC1 for these
#   tuners.
#
# O2 -- type "live" (reference implementation). Source:
#   reference_race_final_fit() in helper-orchestration.R, handed the
#   fixtures' literal inner `rolling_origin()` call as `inner_design`, so the
#   reference builds the inner design on the full data from its own spelling
#   of the call and selects with `select_best()` itself. Pinned by "the
#   <racer> final fit on a rolling-origin result matches its reference".
#   Satisfies M110 AC3 for these tuners.
#
# O1 and O2 check that the orchestrators give what finetune gives when run by
# hand. The estimate itself adds nothing new for these designs, so no second
# oracle type is asked of them here.

ts_race_run <- function(fn, wf, folds, g, ms, ctrl) {
  set.seed(23)
  memoised(race_call_by_name(
    fn,
    wf,
    folds,
    grid = g,
    metrics = ms,
    control = ctrl
  ))
}

for (design in "rolling-origin") {
  build <- TS_DESIGNS[[design]]

  for (fn in RACERS) {
    test_that(
      sprintf("%s matches its reference loop on a %s design", fn, design),
      {
        skip_if_no_race_fixture(fn)
        d <- TS_DATA[[design]]()
        wf <- det_workflow(d)
        folds <- build(d)
        expect_s3_class(folds$splits[[1]], TS_SPLIT_CLASS[[design]])
        ms <- ts_metrics()
        g <- det_grid()
        ctrl <- race_control()

        res <- ts_race_run(fn, wf, folds, g, ms, ctrl)
        ref <- memoised(reference_nested_race_loop(
          fn,
          wf,
          folds,
          grid = g,
          metrics = ms,
          seed = 23,
          metric_name = "rmse",
          control = ctrl
        ))

        expect_ts_matches_reference(res, ref)
      }
    )
  }
}

for (fn in RACERS) {
  test_that(
    sprintf(
      "the %s final fit on a rolling-origin result matches its reference",
      fn
    ),
    {
      skip_if_no_race_fixture(fn)
      d <- make_reg_data()
      wf <- det_workflow(d)
      folds <- ts_rolling_nested(d)
      ms <- ts_metrics()
      g <- det_grid()
      ctrl <- race_control()

      res <- ts_race_run(fn, wf, folds, g, ms, ctrl)
      set.seed(42)
      final <- nested_final_fit(wf, res)
      ref <- reference_race_final_fit(
        fn,
        wf,
        d,
        grid = g,
        metrics = ms,
        seed = 42,
        metric_name = "rmse",
        control = ctrl,
        inner_design = ts_inner
      )
      expect_ts_final_matches(final, ref, d)
    }
  )
}
