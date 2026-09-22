# Oracle records for rolling-origin and sliding-window outer designs (M108).
# DESIGN Conventions: oracles are recorded in the test file that asserts them.
#
# O1 -- type "live" (reference implementation). Source: the tidymodels pipeline
#   itself, recomputed at test time by reference_nested_loop() in
#   helper-orchestration.R, written from the documented seed contract rather
#   than from the driver. Run here on designs built by rsample::nested_cv()
#   with `rolling_origin()` and `sliding_window()` outer resamples. Pinned by
#   the two "match a hand-rolled reference loop" tests. Satisfies AC1/AC2.
#
# O2 -- type "live" (reference implementation). Source: rsample::nested_cv(),
#   recomputed at test time. Every outer and inner analysis and assessment set
#   `nested_resamples()` builds must match it row for row. Pinned by the two
#   "splits match rsample::nested_cv()" tests. Satisfies AC3.
#
# O3 -- type "live" (reference implementation). Source: tune::tune_grid(),
#   tune::select_best() and fit() run by hand under the final fit's
#   `tuning_seed` and `fit_seed`, on an inner design built on the full data
#   from the fixture's literal `rolling_origin()` call. Pinned by the two
#   "the final fit on a ... design matches a hand-rolled reference" tests,
#   one per outer design. Satisfies AC4, and the sliding-window test backs
#   the help's claim for `nested_final_fit()` on that design.
#
# O4 -- type "live" (reference implementation), M110. Source: each tuner's own
#   reference loop in helper-orchestration.R -- reference_nested_bayes_loop(),
#   reference_nested_race_loop() and reference_nested_anneal_loop() -- written
#   from the seed contract rather than from the driver, and run here on the
#   two time-series designs. Pinned by the "matches its reference loop on a
#   ... design" tests. Satisfies M110 AC1.
#
# O5 -- type "live" (reference implementation), M110. Source:
#   tune::fit_resamples() run by hand on the outer splits, rebuilt here from
#   the fixture's literal outer call rather than read off the nested object,
#   as test-nested-fit-resamples-oracles.R does for `vfold_cv()`. Pinned by
#   the "nested_fit_resamples() matches fit_resamples() on a ... design"
#   tests. Satisfies M110 AC2.
#
# O6 -- type "live" (reference implementation), M110. Source: each tuner's
#   reference final fit in helper-orchestration.R --
#   reference_bayes_final_fit(), reference_race_final_fit() and
#   reference_anneal_final_fit() -- handed the fixtures' literal inner
#   `rolling_origin()` call as `inner_design`, so the reference builds the
#   inner design on the full data from its own spelling of the call and
#   selects with `select_best()` itself. Pinned by the "the final fit ...
#   matches its reference" tests. Satisfies M110 AC3.
#
# O7 -- type "live" (reference implementation), M110. Source: hand_call() in
#   helper-orchestration.R, the orchestrator each workflow of a set routes
#   to, called by hand under the same seed, as
#   test-nested-workflow-map-oracles.R uses it. Pinned by "a workflow set on a
#   rolling-origin design matches the hand calls". Satisfies M110 AC5.
#
# O4-O7 each check that an orchestrator gives what tune or finetune gives when
# run by hand. The estimate itself adds nothing new for these designs, so no
# second oracle type is asked of them here.

expect_matches_reference <- function(res, ref) {
  expect_identical(res$.tuning_seed, ref_field(ref, "tuning_seed"))
  expect_identical(res$.outer_fit_seed, ref_field(ref, "outer_fit_seed"))
  for (i in seq_len(nrow(res))) {
    expect_identical(res$.metrics[[i]], ref[[i]]$metrics)
    expect_identical(res$.selected[[i]], ref[[i]]$selected)
  }
}

test_that("a rolling-origin design matches a hand-rolled reference loop", {
  skip_if_no_engines()

  d <- make_reg_data()
  wf <- det_workflow(d)
  ms <- ts_metrics()
  grid <- det_grid()
  folds <- ts_rolling_nested(d)
  expect_s3_class(folds$splits[[1]], "rof_split")

  set.seed(20)
  res <- memoised(nested_tune_grid(wf, folds, grid = grid, metrics = ms))
  ref <- memoised(reference_nested_loop(
    wf,
    folds,
    grid,
    ms,
    seed = 20,
    metric_name = "rmse"
  ))

  expect_true(all(res$.completed))
  expect_matches_reference(res, ref)
})

test_that("a sliding-window design matches a hand-rolled reference loop", {
  skip_if_no_engines()

  d <- make_reg_data()
  wf <- det_workflow(d)
  ms <- ts_metrics()
  grid <- det_grid()
  folds <- ts_sliding_nested(d)
  expect_s3_class(folds$splits[[1]], "sliding_window_split")

  set.seed(21)
  res <- memoised(nested_tune_grid(wf, folds, grid = grid, metrics = ms))
  ref <- memoised(reference_nested_loop(
    wf,
    folds,
    grid,
    ms,
    seed = 21,
    metric_name = "rmse"
  ))

  expect_true(all(res$.completed))
  expect_matches_reference(res, ref)
})

test_that("rolling-origin splits match rsample::nested_cv()", {
  d <- make_reg_data()

  ref <- ts_rolling_nested(d)
  lean <- nested_resamples(
    d,
    outside = rsample::rolling_origin(initial = 60, assess = 1, skip = 9),
    inside = rsample::rolling_origin(initial = 40, assess = 1, skip = 4)
  )

  expect_s3_class(lean, "nested_resamples")
  expect_s3_class(lean$splits[[1]], "rof_split")
  expect_outer_identical(lean, ref)
  expect_inner_identical(lean, ref)
})

test_that("sliding-window splits match rsample::nested_cv()", {
  d <- make_reg_data()

  ref <- ts_sliding_nested(d)
  lean <- nested_resamples(
    d,
    outside = rsample::sliding_window(
      lookback = 59,
      assess_stop = 1,
      step = 10
    ),
    inside = rsample::rolling_origin(initial = 40, assess = 1, skip = 4)
  )

  expect_s3_class(lean, "nested_resamples")
  expect_s3_class(lean$splits[[1]], "sliding_window_split")
  expect_outer_identical(lean, ref)
  expect_inner_identical(lean, ref)
})

expect_final_matches_reference <- function(d, folds) {
  wf <- det_workflow(d)
  ms <- ts_metrics()
  grid <- det_grid()

  set.seed(20)
  res <- memoised(nested_tune_grid(wf, folds, grid = grid, metrics = ms))
  set.seed(31)
  final <- nested_final_fit(wf, res)

  # The reference runs under the final fit's own two seeds, with the kind
  # pinned, and builds its inner design from the fixture's literal call on
  # the full data.
  set.seed(
    final$tuning_seed,
    kind = "Mersenne-Twister",
    normal.kind = "Inversion",
    sample.kind = "Rejection"
  )
  inner <- rsample::rolling_origin(d, initial = 40, assess = 1, skip = 4)
  tuned <- tune::tune_grid(
    wf,
    resamples = inner,
    grid = grid,
    metrics = ms,
    control = tune::control_grid(allow_par = FALSE)
  )
  best <- tune::select_best(tuned, metric = "rmse")
  set.seed(
    final$fit_seed,
    kind = "Mersenne-Twister",
    normal.kind = "Inversion",
    sample.kind = "Rejection"
  )
  ref <- parsnip::fit(tune::finalize_workflow(wf, best), data = d)

  expect_identical(
    lapply(final$tuning$splits, function(s) s$in_id),
    lapply(inner$splits, function(s) s$in_id)
  )
  expect_identical(final$selected, best)
  expect_identical(
    predict(final, new_data = d),
    predict(ref, new_data = d)
  )
}

test_that("the final fit on a rolling-origin design matches a hand-rolled reference", {
  skip_if_no_engines()
  d <- make_reg_data()
  expect_final_matches_reference(d, ts_rolling_nested(d))
})

test_that("the final fit on a sliding-window design matches a hand-rolled reference", {
  skip_if_no_engines()
  d <- make_reg_data()
  expect_final_matches_reference(d, ts_sliding_nested(d))
})

# ---- AC5: predictions and augment() -----------------------------------------

ts_pred_run <- function(data, design = ts_rolling_nested) {
  set.seed(20)
  memoised(nested_tune_grid(
    det_workflow(data),
    design(data),
    grid = det_grid(),
    metrics = ts_metrics(),
    control = tune::control_grid(save_pred = TRUE)
  ))
}

test_that("collect_predictions() returns each outer-assessment row once per fold", {
  skip_if_no_engines()
  d <- make_reg_data()
  res <- ts_pred_run(d)

  preds <- collect_predictions(res)
  held <- lapply(res$splits, rsample::complement)
  expect_identical(nrow(preds), length(unlist(held)))
  for (i in seq_len(nrow(res))) {
    expect_identical(
      as.integer(preds$.row[preds$id == res$id[[i]]]),
      held[[i]]
    )
  }
})

expect_augment_names_never_held <- function(res, d) {
  never <- setdiff(
    seq_len(nrow(d)),
    unlist(lapply(res$splits, rsample::complement))
  )
  expect_length(never, 87L)

  cnd <- rlang::catch_cnd(augment(res), "error")
  expect_s3_class(cnd, "nestedtune_augment_rows")
  expect_identical(conditionCall(cnd)[[1L]], as.name("augment"))
  msg <- cli::ansi_strip(conditionMessage(cnd))
  # cli shortens the row list to its first three and last two.
  expect_identical(c(head(never, 3L), tail(never, 2L)), c(1:3, 89:90))
  expect_match(msg, "87 rows: 1, 2, 3, ", fixed = TRUE)
  expect_match(msg, "89, and 90.", fixed = TRUE)
  expect_no_match(msg, "repeated", ignore.case = TRUE)
  expect_no_match(msg, "Monte Carlo", fixed = TRUE)
}

test_that("augment() refuses a rolling-origin result and names the rows never held out", {
  skip_if_no_engines()
  d <- make_reg_data()
  expect_augment_names_never_held(ts_pred_run(d), d)
})

test_that("augment() refuses a sliding-window result and names the rows never held out", {
  skip_if_no_engines()
  d <- make_reg_data()
  res <- ts_pred_run(d, ts_sliding_nested)
  expect_s3_class(res$splits[[1]], "sliding_window_split")
  expect_augment_names_never_held(res, d)
})

# ---- The other orchestrators (M110; oracles O4-O7 in the header) -------------

TS_DESIGNS <- list(
  "rolling-origin" = ts_rolling_nested,
  "sliding-window" = ts_sliding_nested
)

# The outer split class each design builds, so a test shows it ran on the
# design its name claims.
TS_SPLIT_CLASS <- list(
  "rolling-origin" = "rof_split",
  "sliding-window" = "sliding_window_split"
)

for (design in names(TS_DESIGNS)) {
  build <- TS_DESIGNS[[design]]

  test_that(
    sprintf(
      "nested_tune_bayes() matches its reference loop on a %s design",
      design
    ),
    {
      skip_if_no_bayes_fixture()
      d <- make_reg_data()
      wf <- bayes_workflow(d)
      folds <- build(d)
      expect_s3_class(folds$splits[[1]], TS_SPLIT_CLASS[[design]])
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

      expect_true(all(res$.completed))
      expect_matches_reference(res, ref)
    }
  )

  for (fn in RACERS) {
    test_that(
      sprintf("%s matches its reference loop on a %s design", fn, design),
      {
        skip_if_no_race_fixture(fn)
        d <- make_reg_data()
        wf <- det_workflow(d)
        folds <- build(d)
        expect_s3_class(folds$splits[[1]], TS_SPLIT_CLASS[[design]])
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

        expect_true(all(res$.completed))
        expect_matches_reference(res, ref)
      }
    )
  }

  test_that(
    sprintf(
      "nested_tune_sim_anneal() matches its reference loop on a %s design",
      design
    ),
    {
      skip_if_no_anneal_fixture()
      d <- make_reg_data()
      wf <- det_workflow(d)
      folds <- build(d)
      expect_s3_class(folds$splits[[1]], TS_SPLIT_CLASS[[design]])
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

      expect_true(all(res$.completed))
      expect_matches_reference(res, ref)
    }
  )
}

TS_OUTER <- list(
  "rolling-origin" = function(d) {
    rsample::rolling_origin(d, initial = 60, assess = 1, skip = 9)
  },
  "sliding-window" = function(d) {
    rsample::sliding_window(d, lookback = 59, assess_stop = 1, step = 10)
  }
)

for (design in names(TS_DESIGNS)) {
  build <- TS_DESIGNS[[design]]
  outer_of <- TS_OUTER[[design]]

  test_that(
    sprintf(
      "nested_fit_resamples() matches fit_resamples() on a %s design",
      design
    ),
    {
      skip_if_no_engines()
      d <- make_reg_data()
      wf <- fixed_workflow(d)
      ms <- ts_metrics()
      outer <- outer_of(d)

      folds <- build(d)
      expect_s3_class(folds$splits[[1]], TS_SPLIT_CLASS[[design]])
      set.seed(25)
      res <- nested_fit_resamples(wf, folds, metrics = ms)
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
}

# Both fixtures share the data, the inner call and the tuner's arguments, and
# the final fit never reads the outer splits, so a sliding-window result gives
# the same final fit as a rolling-origin one. The Bayesian sliding-window test
# checks it once, against the same reference.

ts_inner <- function(data) {
  rsample::rolling_origin(data, initial = 40, assess = 1, skip = 4)
}

expect_final_matches <- function(final, ref, d) {
  expect_identical(c(final$tuning_seed, final$fit_seed), ref$seeds)
  expect_identical(
    lapply(final$tuning$splits, function(s) s$in_id),
    lapply(ref$tuned$splits, function(s) s$in_id)
  )
  # The reference's inner design is the literal call's, not a default.
  expect_s3_class(ref$tuned$splits[[1]], "rof_split")
  expect_identical(final$selected, ref$selected)
  expect_identical(
    predict(extract_workflow(final), new_data = d),
    predict(ref$workflow, new_data = d)
  )
}

for (design in names(TS_DESIGNS)) {
  build <- TS_DESIGNS[[design]]

  test_that(
    sprintf(
      "the Bayesian final fit on a %s result matches its reference",
      design
    ),
    {
      skip_if_no_bayes_fixture()
      d <- make_reg_data()
      wf <- bayes_workflow(d)
      folds <- build(d)
      expect_s3_class(folds$splits[[1]], TS_SPLIT_CLASS[[design]])
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
      expect_final_matches(final, ref, d)
    }
  )
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

      set.seed(23)
      res <- memoised(race_call_by_name(
        fn,
        wf,
        folds,
        grid = g,
        metrics = ms,
        control = ctrl
      ))
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
      expect_final_matches(final, ref, d)
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

  set.seed(24)
  res <- memoised(nested_tune_sim_anneal(
    wf,
    folds,
    iter = 2,
    initial = 3,
    metrics = ms,
    control = ctrl
  ))
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
  expect_final_matches(final, ref, d)
})

# The final fit on a fit_resamples() result tunes nothing (M110 AC4): no
# tuning run, an empty selection, and the plain fit on every row under the
# recorded fit seed. Run on both designs, so the help's "tested on both"
# holds for this result too.
for (design in names(TS_DESIGNS)) {
  build <- TS_DESIGNS[[design]]

  test_that(
    sprintf(
      "the final fit on a %s fit_resamples() result fits every row",
      design
    ),
    {
      skip_if_no_engines()
      d <- make_reg_data()
      wf <- fixed_workflow(d)
      folds <- build(d)
      expect_s3_class(folds$splits[[1]], TS_SPLIT_CLASS[[design]])

      set.seed(25)
      res <- nested_fit_resamples(wf, folds, metrics = ts_metrics())
      set.seed(44)
      final <- nested_final_fit(wf, res)

      expect_null(final$tuning)
      expect_identical(dim(final$selected), c(0L, 0L))
      set.seed(
        final$fit_seed,
        kind = "Mersenne-Twister",
        normal.kind = "Inversion",
        sample.kind = "Rejection"
      )
      plain <- parsnip::fit(wf, data = d)
      expect_identical(
        predict(final, new_data = d),
        predict(plain, new_data = d)
      )
    }
  )
}

test_that("a workflow set on a rolling-origin design matches the hand calls", {
  skip_if_no_wset_fixture()
  d <- make_reg_data()
  wset <- wset_two(d)
  folds <- ts_rolling_nested(d)
  ms <- ts_metrics()

  set.seed(26)
  res <- nested_workflow_map(
    wset,
    resamples = folds,
    grid = det_grid(),
    metrics = ms
  )

  expect_identical(res$wflow_id, c("tuned", "fixed"))
  tuners <- vapply(
    res$result,
    function(r) extract_procedure(r)$tuner,
    character(1)
  )
  expect_identical(tuners, c("tune_grid", "fit_resamples"))
  for (i in seq_len(nrow(wset))) {
    wf <- wset$info[[i]]$workflow[[1L]]
    hand <- hand_call("nested_tune_grid", wf, folds, ms, seed = 26)
    expect_true(all(hand$.completed))
    expect_identical(res$result[[i]]$.tuning_seed, hand$.tuning_seed)
    expect_identical(res$result[[i]]$.outer_fit_seed, hand$.outer_fit_seed)
    expect_identical(res$result[[i]]$.metrics, hand$.metrics)
    expect_identical(res$result[[i]]$.selected, hand$.selected)
  }
})
