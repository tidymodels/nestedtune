# nested_tune_bayes() and nested_tune_sim_anneal() on the three inner sliding
# designs under an outer `rolling_origin()` (M120), and their final fits on
# the three designs (M120, M140). The fixtures are TS_INNER_DESIGNS in
# helper-orchestration.R. DESIGN Conventions: oracles are recorded in the test
# file that asserts them.
#
# O1 -- type "live" (reference implementation). Source:
#   reference_nested_bayes_loop() and reference_nested_anneal_loop() in
#   helper-orchestration.R, written from the seed contract rather than from
#   the driver. Unlike the outer design, the inner design reaches the tuner:
#   each fold hands it that fold's inner resamples. Pinned by the
#   "<tuner> matches its reference loop on an inner ... design" tests.
#   Satisfies M120 AC1 for these tuners.
#
# O2 -- type "live" (reference implementation). Source:
#   reference_bayes_final_fit() and reference_anneal_final_fit() in
#   helper-orchestration.R, handed the fixture's literal inner call as
#   `inner_design`, so the reference builds the inner design on the full data
#   from its own spelling of the call. Pinned by "the <tuner> final fit on an
#   inner ... result matches its reference". Satisfies M120 AC2 for these
#   tuners on the sliding-period design, and M140 AC1 on the sliding-window
#   and sliding-index designs. Each run comes from the fixture cache that the
#   O1 test filled.
#
# O1 and O2 check that the orchestrators give what tune and finetune give when
# run by hand. The estimate itself adds nothing new for these designs, so no
# second oracle type is asked of them here.

skip_heavy_on_cran()

ts_inner_bayes_run <- function(wf, folds, p, ms) {
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

ts_inner_anneal_run <- function(wf, folds, ms, ctrl) {
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

for (design in names(TS_INNER_DESIGNS)) {
  spec <- TS_INNER_DESIGNS[[design]]

  test_that(
    sprintf(
      "nested_tune_bayes() matches its reference loop on an inner %s design",
      design
    ),
    {
      skip_if_no_bayes_fixture()
      d <- spec$data()
      wf <- bayes_workflow(d)
      folds <- spec$build(d)
      expect_s3_class(
        folds$inner_resamples[[1]]$splits[[1]],
        spec$split_class
      )
      p <- bayes_param_info(wf)
      ms <- ts_metrics()

      res <- ts_inner_bayes_run(wf, folds, p, ms)
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

  test_that(
    sprintf(
      "nested_tune_sim_anneal() matches its reference loop on an inner %s design",
      design
    ),
    {
      skip_if_no_anneal_fixture()
      d <- spec$data()
      wf <- det_workflow(d)
      folds <- spec$build(d)
      expect_s3_class(
        folds$inner_resamples[[1]]$splits[[1]],
        spec$split_class
      )
      ms <- ts_metrics()
      ctrl <- anneal_control()

      res <- ts_inner_anneal_run(wf, folds, ms, ctrl)
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

for (design in names(TS_INNER_DESIGNS)) {
  spec <- TS_INNER_DESIGNS[[design]]

  test_that(
    sprintf(
      "the Bayesian final fit on an inner %s result matches its reference",
      design
    ),
    {
      skip_if_no_bayes_fixture()
      d <- spec$data()
      wf <- bayes_workflow(d)
      folds <- spec$build(d)
      p <- bayes_param_info(wf)
      ms <- ts_metrics()

      res <- ts_inner_bayes_run(wf, folds, p, ms)
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
        inner_design = spec$inner
      )
      expect_ts_final_matches(final, ref, d, split_class = spec$split_class)
    }
  )

  test_that(
    sprintf(
      "the annealing final fit on an inner %s result matches its reference",
      design
    ),
    {
      skip_if_no_anneal_fixture()
      d <- spec$data()
      wf <- det_workflow(d)
      folds <- spec$build(d)
      ms <- ts_metrics()
      ctrl <- anneal_control()

      res <- ts_inner_anneal_run(wf, folds, ms, ctrl)
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
        inner_design = spec$inner
      )
      expect_ts_final_matches(final, ref, d, split_class = spec$split_class)
    }
  )
}
