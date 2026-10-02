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
#   It shows only that the design is accepted, because nested_fit_resamples()
#   checks the inner design but fits nothing on it.
#
# O3 -- type "live" (reference implementation). Source: hand_call() in
#   helper-orchestration.R, which runs each workflow of the set through its
#   own orchestrator by hand under the same seed. Pinned by "a workflow set on
#   the ... pair matches the hand calls". Satisfies M140 AC3 for
#   nested_workflow_map().
#
# O4 -- type "live" (reference implementation). Source: reference_final_fit()
#   in helper-orchestration.R, handed TS_INNER_DESIGNS' sliding-window inner
#   call as `inner_design`. Its arguments match the pair's `inside` call.
#   Pinned by "the grid final fit on the ... pair matches its reference".
#   Satisfies M140 AC3 for nested_final_fit().
#
# O1 to O4 check that the functions give what tune and finetune give when run
# by hand. The estimate itself adds nothing new for this pair, so no second
# oracle type is asked of them here.
#
# One test on this pair reaches the step that re-points each fold's inner
# splits at its outer analysis frame, which the tests above cannot see: a
# fixed grid scores the same rows on either frame. Its `min_n` range is
# finalized from the frame's row count, so it differs between the frames.
# Pinned by "a range finalized from the data on the ... pair is finalized on
# each fold's analysis rows". Satisfies M140 AC4 with two oracle types:
#
# O5 -- type "analytic" (closed form). Source: dials::get_n_frac_range(), whose
#   finalized range is `floor(nrow(x) * frac)` of the frame it is handed (the
#   O1 record in test-nested-tune-finalize.R). Every candidate a fold searched
#   lies inside `floor(n * FINALIZE_FRAC)`, `n` being the row count of that
#   fold's outer analysis set: 6 to 30 on its 60 rows, where the 90-row frame
#   gives 9 to 45.
#
# O6 -- type "live" (reference implementation). Source: rsample::nested_cv()
#   on the pair's own call, rebuilt by ts_pair_reference(). Its inner splits
#   carry each outer fold's analysis set as their frame, so tune finalizes on
#   it by construction.

skip_heavy_on_cran()

pair <- "sliding-window / sliding-window"
pair_spec <- TS_SLIDING_PAIRS[[pair]]

# The pair's outer design, built on its own from the same call.
pair_outer <- function(data) {
  rsample::sliding_window(data, lookback = 59, assess_stop = 1, step = 10)
}

# An inner call whose arguments match the pair's `inside` call, for a
# reference final fit on the full data.
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

test_that(
  sprintf(
    "a range finalized from the data on the %s pair is finalized on each fold's analysis rows",
    pair
  ),
  {
    skip_if_no_engines(stochastic = TRUE)
    skip_if_not_installed("dials")
    d <- make_ts_weekday_data()
    wf <- stoch_workflow(d)
    ms <- ts_metrics()
    lean <- pair_folds(d)
    ref <- ts_pair_reference(pair_spec, d)
    # The precondition for O6: the two designs hold the same inner rows.
    expect_inner_identical(lean, ref)

    # Two direct calls, never memoised() (the M42 lesson).
    set.seed(3)
    lean_res <- suppressMessages(nested_tune_grid(
      wf,
      lean,
      param_info = frac_param_info(wf),
      grid = 5,
      metrics = ms
    ))
    set.seed(3)
    ref_res <- suppressMessages(nested_tune_grid(
      wf,
      ref,
      param_info = frac_param_info(wf),
      grid = 5,
      metrics = ms
    ))
    expect_true(all(lean_res$.completed))

    # O5.
    full_upper <- floor(nrow(d) * FINALIZE_FRAC[[2L]])
    for (i in seq_len(nrow(lean))) {
      n <- nrow(rsample::analysis(lean$splits[[i]]))
      bounds <- floor(n * FINALIZE_FRAC)
      # What makes the assertion discriminating: a range read off the whole
      # frame reaches past the fold's own upper bound.
      expect_gt(full_upper, bounds[[2L]])
      candidates <- unique(lean_res$.inner_metrics[[i]]$min_n)
      expect_gt(length(candidates), 1L)
      outside <- candidates[
        candidates < bounds[[1L]] | candidates > bounds[[2L]]
      ]
      expect_identical(
        outside,
        candidates[0],
        label = sprintf(
          "fold %d candidates outside [%d, %d]",
          i,
          bounds[[1L]],
          bounds[[2L]]
        )
      )
    }

    # O6.
    expect_identical(lean_res$.inner_metrics, ref_res$.inner_metrics)
    expect_identical(lean_res$.metrics, ref_res$.metrics)
    expect_identical(lean_res$.selected, ref_res$.selected)
  }
)
