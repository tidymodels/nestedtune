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
# The M110 oracles for the Bayesian, racing and annealing tuners are recorded
# in test-time-series-bayes.R, test-time-series-race.R and
# test-time-series-anneal.R, beside the tests that assert them.
#
# O5 -- type "live" (reference implementation), M110. Source:
#   tune::fit_resamples() run by hand on the outer splits, rebuilt here from
#   the fixture's literal outer call rather than read off the nested object,
#   as test-nested-fit-resamples-oracles.R does for `vfold_cv()`. Pinned by
#   the "nested_fit_resamples() matches fit_resamples() on a ... design"
#   tests. Satisfies M110 AC2.
#
# O7 -- type "live" (reference implementation), M110. Source: hand_call() in
#   helper-orchestration.R, the orchestrator each workflow of a set routes
#   to, called by hand under the same seed, as
#   test-nested-workflow-map-oracles.R uses it. Pinned by "a workflow set on a
#   rolling-origin design matches the hand calls". Satisfies M110 AC5.
#
# O5 and O7 each check that an orchestrator gives what tune gives when run by
# hand. The estimate itself adds nothing new for these designs, so no
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

# ---- Index-based and period-based designs (M111) -----------------------------
#
# The O1, O2 and O3 oracles above, run on `sliding_index()` and
# `sliding_period()` outer designs over `make_ts_data()`. The Bayesian,
# racing, annealing and fit_resamples reference-loop tests, and the
# fit_resamples final-fit test, reach these designs through TS_DESIGNS.

TS_NEW_OUTER_CALLS <- list(
  "sliding-index" = function(d) {
    nested_resamples(
      d,
      outside = rsample::sliding_index(
        index = date,
        lookback = 59,
        assess_stop = 1,
        step = 10
      ),
      inside = rsample::rolling_origin(initial = 40, assess = 1, skip = 4)
    )
  },
  "sliding-period" = function(d) {
    nested_resamples(
      d,
      outside = rsample::sliding_period(
        index = date,
        period = "week",
        lookback = 8
      ),
      inside = rsample::rolling_origin(initial = 40, assess = 1, skip = 4)
    )
  }
)

for (design in names(TS_NEW_OUTER_CALLS)) {
  build <- TS_DESIGNS[[design]]
  lean_of <- TS_NEW_OUTER_CALLS[[design]]

  test_that(
    sprintf("a %s design matches a hand-rolled reference loop", design),
    {
      skip_if_no_engines()
      d <- make_ts_data()
      wf <- det_workflow(d)
      ms <- ts_metrics()
      grid <- det_grid()
      folds <- build(d)
      expect_s3_class(folds$splits[[1]], TS_SPLIT_CLASS[[design]])

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

      expect_ts_matches_reference(res, ref)
    }
  )

  test_that(sprintf("%s splits match rsample::nested_cv()", design), {
    d <- make_ts_data()

    ref <- build(d)
    lean <- lean_of(d)

    expect_s3_class(lean, "nested_resamples")
    expect_s3_class(lean$splits[[1]], TS_SPLIT_CLASS[[design]])
    expect_outer_identical(lean, ref)
    expect_inner_identical(lean, ref)
  })

  test_that(
    sprintf(
      "the final fit on a %s design matches a hand-rolled reference",
      design
    ),
    {
      skip_if_no_engines()
      d <- make_ts_data()
      folds <- build(d)
      expect_s3_class(folds$splits[[1]], TS_SPLIT_CLASS[[design]])
      expect_final_matches_reference(d, folds)
    }
  )
}

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

# Two outer slices whose eleven-row assessment sets share row 71 (M111).
ts_overlap_nested <- function(data) {
  rsample::nested_cv(
    data,
    outside = rsample::sliding_window(
      lookback = 59,
      assess_stop = 11,
      step = 10
    ),
    inside = rsample::rolling_origin(initial = 40, assess = 1, skip = 4)
  )
}

test_that("augment() on an overlapping sliding-window result counts both kinds of row", {
  skip_if_no_engines()
  d <- make_reg_data()
  res <- ts_pred_run(d, ts_overlap_nested)
  expect_s3_class(res$splits[[1]], "sliding_window_split")
  counts <- tabulate(
    unlist(lapply(res$splits, rsample::complement)),
    nbins = nrow(d)
  )
  expect_identical(c(sum(counts == 0L), sum(counts > 1L)), c(69L, 1L))

  cnd <- rlang::catch_cnd(augment(res), "error")
  expect_s3_class(cnd, "nestedtune_augment_rows")
  expect_identical(conditionCall(cnd)[[1L]], as.name("augment"))
  # cli wraps the message at the console width.
  msg <- gsub("\\s+", " ", cli::ansi_strip(conditionMessage(cnd)))
  expect_match(
    msg,
    "holds out 69 rows never and 1 row more than once.",
    fixed = TRUE
  )
  expect_match(msg, "time-series design", fixed = TRUE)
  expect_no_match(msg, "repeated", ignore.case = TRUE)
  expect_no_match(msg, "Monte Carlo", fixed = TRUE)
})

# ---- The other orchestrators (M110) ------------------------------------------
#
# The Bayesian, racing and annealing tuners have their own files,
# test-time-series-bayes.R, test-time-series-race.R and
# test-time-series-anneal.R, so no one file runs alone for long under parallel
# test files. TS_DESIGNS and TS_SPLIT_CLASS are in helper-orchestration.R.

TS_OUTER <- list(
  "rolling-origin" = function(d) {
    rsample::rolling_origin(d, initial = 60, assess = 1, skip = 9)
  },
  "sliding-window" = function(d) {
    rsample::sliding_window(d, lookback = 59, assess_stop = 1, step = 10)
  },
  "sliding-index" = function(d) {
    rsample::sliding_index(
      d,
      index = date,
      lookback = 59,
      assess_stop = 1,
      step = 10
    )
  },
  "sliding-period" = function(d) {
    rsample::sliding_period(d, index = date, period = "week", lookback = 8)
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
      d <- TS_DATA[[design]]()
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

# The final fit on a fit_resamples() result tunes nothing (M110 AC4): no
# tuning run, an empty selection, and the plain fit on every row under the
# recorded fit seed. Run on every design in TS_DESIGNS, so the help's
# "tested on all four" holds for this result too.
for (design in names(TS_DESIGNS)) {
  build <- TS_DESIGNS[[design]]

  test_that(
    sprintf(
      "the final fit on a %s fit_resamples() result fits every row",
      design
    ),
    {
      skip_if_no_engines()
      d <- TS_DATA[[design]]()
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
