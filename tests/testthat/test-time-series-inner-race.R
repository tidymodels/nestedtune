# The two racing tuners on the three inner sliding designs under an outer
# `rolling_origin()` (M120), and their final fits on the sliding-period
# design. The fixtures are TS_INNER_DESIGNS in helper-orchestration.R, each
# with at least three inner resamples in every fold, which a racer at
# `burn_in = 2` needs. DESIGN Conventions: oracles are recorded in the test
# file that asserts them.
#
# O1 -- type "live" (reference implementation). Source:
#   reference_nested_race_loop() in helper-orchestration.R, written from the
#   seed contract rather than from the driver. Unlike the outer design, the
#   inner design reaches the racer: each fold hands it that fold's inner
#   resamples. Pinned by the "<racer> matches its reference loop on an inner
#   ... design" tests. Satisfies M120 AC1 for these tuners.
#
# O2 -- type "live" (reference implementation). Source:
#   reference_race_final_fit() in helper-orchestration.R, handed the fixture's
#   literal inner `sliding_period()` call as `inner_design`, so the reference
#   builds the inner design on the full data from its own spelling of the
#   call. Pinned by "the <racer> final fit on an inner sliding-period result
#   matches its reference". Satisfies M120 AC2 for these tuners.
#
# O1 and O2 check that the orchestrators give what finetune gives when run by
# hand. The estimate itself adds nothing new for these designs, so no second
# oracle type is asked of them here.

skip_heavy_on_cran()

ts_inner_race_run <- function(fn, wf, folds, g, ms, ctrl) {
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

for (design in names(TS_INNER_DESIGNS)) {
  spec <- TS_INNER_DESIGNS[[design]]

  for (fn in RACERS) {
    test_that(
      sprintf(
        "%s matches its reference loop on an inner %s design",
        fn,
        design
      ),
      {
        skip_if_no_race_fixture(fn)
        d <- spec$data()
        wf <- det_workflow(d)
        folds <- spec$build(d)
        expect_s3_class(
          folds$inner_resamples[[1]]$splits[[1]],
          spec$split_class
        )
        ms <- ts_metrics()
        g <- det_grid()
        ctrl <- race_control()

        res <- ts_inner_race_run(fn, wf, folds, g, ms, ctrl)
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
      "the %s final fit on an inner sliding-period result matches its reference",
      fn
    ),
    {
      skip_if_no_race_fixture(fn)
      spec <- TS_INNER_DESIGNS[["sliding-period"]]
      d <- spec$data()
      wf <- det_workflow(d)
      folds <- spec$build(d)
      ms <- ts_metrics()
      g <- det_grid()
      ctrl <- race_control()

      res <- ts_inner_race_run(fn, wf, folds, g, ms, ctrl)
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
        inner_design = spec$inner
      )
      expect_ts_final_matches(final, ref, d, split_class = spec$split_class)
    }
  )
}
