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
#   from the fixture's literal `rolling_origin()` call. Pinned by "the final
#   fit on a rolling-origin design matches a hand-rolled reference".
#   Satisfies AC4.

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
  res <- nested_tune_grid(wf, folds, grid = grid, metrics = ms)
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
  res <- nested_tune_grid(wf, folds, grid = grid, metrics = ms)
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
    outside = rsample::sliding_window(lookback = 59, assess_stop = 1, step = 10),
    inside = rsample::rolling_origin(initial = 40, assess = 1, skip = 4)
  )

  expect_s3_class(lean, "nested_resamples")
  expect_s3_class(lean$splits[[1]], "sliding_window_split")
  expect_outer_identical(lean, ref)
  expect_inner_identical(lean, ref)
})

test_that("the final fit on a rolling-origin design matches a hand-rolled reference", {
  skip_if_no_engines()

  d <- make_reg_data()
  wf <- det_workflow(d)
  ms <- ts_metrics()
  grid <- det_grid()

  set.seed(20)
  res <- nested_tune_grid(wf, ts_rolling_nested(d), grid = grid, metrics = ms)
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
})
