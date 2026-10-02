# nested_fit_resamples() and nested_workflow_map() on the three inner sliding
# designs under an outer `rolling_origin()` (M120). The fixtures are
# TS_INNER_DESIGNS in helper-orchestration.R. DESIGN Conventions: oracles are
# recorded in the test file that asserts them.
#
# O1 -- type "live" (reference implementation). Source: tune::fit_resamples()
#   run by hand on the fixture's outer `rolling_origin()` design, built on
#   its own from the same call. Pinned by the
#   "nested_fit_resamples() matches fit_resamples() on an inner ... design"
#   tests. Satisfies M120 AC3 for nested_fit_resamples(). It shows only that
#   the design is accepted, because nested_fit_resamples() checks the inner
#   design but fits nothing on it.
#
# O2 -- type "live" (reference implementation). Source: hand_call() in
#   helper-orchestration.R, which runs each workflow of the set through its
#   own orchestrator by hand under the same seed. Pinned by the "a workflow
#   set on an inner ... design matches the hand calls" tests. Satisfies M120
#   AC3 for nested_workflow_map(). The same oracle pins "a workflow set run
#   with fn = ... on an inner sliding-period design matches the hand calls",
#   one test for each tuner other than grid. Satisfies M140 AC2.

skip_heavy_on_cran()

# The outer design every inner fixture shares, built on its own.
ts_inner_outer <- function(data) {
  rsample::rolling_origin(data, initial = 60, assess = 1, skip = 9)
}

for (design in names(TS_INNER_DESIGNS)) {
  spec <- TS_INNER_DESIGNS[[design]]

  test_that(
    sprintf(
      "nested_fit_resamples() matches fit_resamples() on an inner %s design",
      design
    ),
    {
      skip_if_no_engines()
      d <- spec$data()
      wf <- fixed_workflow(d)
      ms <- ts_metrics()
      outer <- ts_inner_outer(d)

      folds <- spec$build(d)
      expect_s3_class(
        folds$inner_resamples[[1]]$splits[[1]],
        spec$split_class
      )
      set.seed(25)
      res <- memoised(nested_fit_resamples(wf, folds, metrics = ms))
      plain <- tune::fit_resamples(
        wf,
        resamples = outer,
        metrics = ms,
        control = tune::control_resamples(allow_par = FALSE)
      )
      plain_metrics <- tune::collect_metrics(plain, summarize = FALSE)

      expect_identical(res$id, outer$id)
      expect_true(all(res$.completed))
      for (i in seq_len(nrow(res))) {
        fold_ref <- plain_metrics[plain_metrics$id == outer$id[[i]], ]
        # The reference must hold both rows, or the loop below asserts nothing.
        expect_identical(nrow(fold_ref), 2L)
        fold_res <- res$.metrics[[i]]
        expect_setequal(fold_res$.metric, c("rmse", "mae"))
        for (m in fold_ref$.metric) {
          expect_identical(
            fold_res$.estimate[fold_res$.metric == m],
            fold_ref$.estimate[fold_ref$.metric == m]
          )
        }
      }
    }
  )

  test_that(
    sprintf(
      "a workflow set on an inner %s design matches the hand calls",
      design
    ),
    {
      skip_if_no_wset_fixture()
      d <- spec$data()
      wset <- wset_two(d)
      folds <- spec$build(d)
      expect_s3_class(
        folds$inner_resamples[[1]]$splits[[1]],
        spec$split_class
      )
      ms <- ts_metrics()

      set.seed(26)
      res <- nested_workflow_map(
        wset,
        resamples = folds,
        grid = det_grid(),
        metrics = ms
      )

      expect_identical(res$wflow_id, c("tuned", "fixed"))
      for (i in seq_len(nrow(wset))) {
        wf <- wset$info[[i]]$workflow[[1L]]
        hand <- hand_call("nested_tune_grid", wf, folds, ms, seed = 26)
        expect_true(all(hand$.completed))
        expect_identical(res$result[[i]]$.tuning_seed, hand$.tuning_seed)
        expect_identical(
          res$result[[i]]$.outer_fit_seed,
          hand$.outer_fit_seed
        )
        expect_identical(res$result[[i]]$.metrics, hand$.metrics)
        expect_identical(res$result[[i]]$.selected, hand$.selected)
      }
    }
  )
}

# The map with each tuner other than grid, on the inner sliding-period design
# alone (M140). Each tuner's own run is tested on all three inner designs in
# test-time-series-inner-bayes-anneal.R and test-time-series-inner-race.R.
for (fn in c(
  "nested_tune_bayes",
  "nested_tune_race_anova",
  "nested_tune_race_win_loss",
  "nested_tune_sim_anneal"
)) {
  test_that(
    sprintf(
      "a workflow set run with fn = %s on an inner sliding-period design matches the hand calls",
      fn
    ),
    {
      skip_if_no_wset_fixture(fn)
      spec <- TS_INNER_DESIGNS[["sliding-period"]]
      d <- spec$data()
      wset <- wset_two(d)
      folds <- spec$build(d)
      expect_s3_class(
        folds$inner_resamples[[1]]$splits[[1]],
        spec$split_class
      )
      ms <- ts_metrics()

      set.seed(27)
      res <- rlang::inject(nested_workflow_map(
        wset,
        fn = fn,
        resamples = folds,
        metrics = ms,
        !!!wset_map_args(fn)
      ))

      expect_identical(res$wflow_id, c("tuned", "fixed"))
      for (i in seq_len(nrow(wset))) {
        wf <- wset$info[[i]]$workflow[[1L]]
        hand <- hand_call(fn, wf, folds, ms, seed = 27)
        expect_true(all(hand$.completed))
        # A race that drops no candidate scores as grid does on this fixture,
        # so the tuner that ran is compared as well.
        expect_identical(
          attr(res$result[[i]], "procedure")$tuner,
          attr(hand, "procedure")$tuner
        )
        expect_identical(res$result[[i]]$.tuning_seed, hand$.tuning_seed)
        expect_identical(
          res$result[[i]]$.outer_fit_seed,
          hand$.outer_fit_seed
        )
        expect_identical(res$result[[i]]$.metrics, hand$.metrics)
        expect_identical(res$result[[i]]$.selected, hand$.selected)
      }
    }
  )
}
