# The functions other than nested_tune_grid() on the "sliding-window /
# sliding-window" pair of TS_SLIDING_PAIRS (M140). The other eight pairs are
# tested under nested_resamples() and nested_tune_grid() alone, in
# test-time-series-pairs-{window,index,period}.R (M121). DESIGN Conventions:
# oracles are recorded in the test file that asserts them.
#
# O1 -- type "live" (reference implementation). Source:
#   reference_nested_bayes_loop(), reference_nested_race_loop() and
#   reference_nested_anneal_loop() in helper-orchestration.R, written from the
#   seed contract rather than from the driver. Pinned by "<tuner> on the
#   sliding-window / sliding-window pair matches its reference loop".
#   Satisfies M140 AC3 for the four tuners.
#
# O2 -- type "live" (reference implementation). Source: tune::fit_resamples()
#   run by hand on the pair's outer `sliding_window()` design, built on its
#   own from the same call. Pinned by "nested_fit_resamples() on the ... pair
#   matches fit_resamples()". Satisfies M140 AC3 for nested_fit_resamples().
#
# O3 -- type "live" (reference implementation). Source: hand_call() in
#   helper-orchestration.R, which runs each workflow of the set through its
#   own orchestrator by hand under the same seed. Pinned by "a workflow set on
#   the ... pair matches the hand calls". Satisfies M140 AC3 for
#   nested_workflow_map().
#
# O4 -- type "live" (reference implementation). Source: reference_final_fit()
#   in helper-orchestration.R, handed the pair's literal inner
#   `sliding_window()` call as `inner_design`. Pinned by "the grid final fit on
#   the ... pair matches its reference". Satisfies M140 AC3 for
#   nested_final_fit().
#
# O1 to O4 check that the functions give what tune and finetune give when run
# by hand. The estimate itself adds nothing new for this pair, so no second
# oracle type is asked of them here.

skip_heavy_on_cran()

pair <- "sliding-window / sliding-window"
pair_spec <- TS_SLIDING_PAIRS[[pair]]

# The pair's outer design, built on its own from the same call.
pair_outer <- function(data) {
  rsample::sliding_window(data, lookback = 59, assess_stop = 1, step = 10)
}

# The pair's literal inner call, for a reference final fit on the full data.
pair_inner <- TS_INNER_DESIGNS[["sliding-window"]]$inner

pair_folds <- function(d) {
  folds <- pair_spec$build(d)
  expect_s3_class(folds$splits[[1]], pair_spec$outer_class)
  expect_s3_class(folds$inner_resamples[[1]]$splits[[1]], pair_spec$inner_class)
  folds
}

test_that(
  sprintf(
    "nested_tune_bayes() on the %s pair matches its reference loop",
    pair
  ),
  {
    skip_if_no_bayes_fixture()
    d <- make_ts_weekday_data()
    wf <- bayes_workflow(d)
    folds <- pair_folds(d)
    p <- bayes_param_info(wf)
    ms <- ts_metrics()

    set.seed(22)
    res <- memoised(nested_tune_bayes(
      wf,
      folds,
      iter = 2,
      initial = 3,
      param_info = p,
      metrics = ms
    ))
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

for (fn in RACERS) {
  test_that(
    sprintf("%s on the %s pair matches its reference loop", fn, pair),
    {
      skip_if_no_race_fixture(fn)
      d <- make_ts_weekday_data()
      wf <- det_workflow(d)
      folds <- pair_folds(d)
      ms <- ts_metrics()
      g <- det_grid()
      ctrl <- race_control()

      set.seed(23)
      res <- memoised(race_call_by_name(
        fn,
        wf,
        folds,
        grid = g,
        metrics = ms,
        control = ctrl
      ))
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

test_that(
  sprintf(
    "nested_tune_sim_anneal() on the %s pair matches its reference loop",
    pair
  ),
  {
    skip_if_no_anneal_fixture()
    d <- make_ts_weekday_data()
    wf <- det_workflow(d)
    folds <- pair_folds(d)
    ms <- ts_metrics()
    ctrl <- anneal_control()

    set.seed(24)
    res <- memoised(nested_tune_sim_anneal(
      wf,
      folds,
      iter = 2,
      initial = 3,
      metrics = ms,
      control = ctrl
    ))
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

test_that(
  sprintf(
    "nested_fit_resamples() on the %s pair matches fit_resamples()",
    pair
  ),
  {
    skip_if_no_engines()
    d <- make_ts_weekday_data()
    wf <- fixed_workflow(d)
    ms <- ts_metrics()
    folds <- pair_folds(d)
    outer <- pair_outer(d)

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
  sprintf("a workflow set on the %s pair matches the hand calls", pair),
  {
    skip_if_no_wset_fixture()
    d <- make_ts_weekday_data()
    wset <- wset_two(d)
    folds <- pair_folds(d)
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
      expect_identical(res$result[[i]]$.outer_fit_seed, hand$.outer_fit_seed)
      expect_identical(res$result[[i]]$.metrics, hand$.metrics)
      expect_identical(res$result[[i]]$.selected, hand$.selected)
    }
  }
)

test_that(
  sprintf("the grid final fit on the %s pair matches its reference", pair),
  {
    skip_if_no_engines()
    d <- make_ts_weekday_data()
    wf <- det_workflow(d)
    folds <- pair_folds(d)
    ms <- ts_metrics()
    g <- det_grid()

    set.seed(20)
    res <- memoised(nested_tune_grid(wf, folds, grid = g, metrics = ms))
    set.seed(31)
    final <- nested_final_fit(wf, res)
    ref <- reference_final_fit(
      wf,
      d,
      grid = g,
      metrics = ms,
      seed = 31,
      metric_name = "rmse",
      inner_design = pair_inner
    )
    expect_ts_final_matches(final, ref, d, split_class = pair_spec$inner_class)
  }
)
