# Oracle records for inner `sliding_window()`, `sliding_index()` and
# `sliding_period()` designs under an outer `rolling_origin()` (M119).
# DESIGN Conventions: oracles are recorded in the test file that asserts them.
# The fixtures are TS_INNER_DESIGNS in helper-orchestration.R.
#
# O1 -- type "live" (reference implementation). Source: the tidymodels pipeline
#   itself, recomputed at test time by reference_nested_loop() in
#   helper-orchestration.R, written from the documented seed contract rather
#   than from the driver. Pinned by the three "nested_tune_grid() on an inner
#   ... design matches a hand-rolled reference loop" tests. Satisfies M119
#   AC1.
#
# O2 -- type "live" (reference implementation). Source: rsample::nested_cv(),
#   recomputed at test time. Every outer and inner analysis and assessment set
#   `nested_resamples()` builds must match it row for row. Pinned by the three
#   "inner ... splits match rsample::nested_cv()" tests. Satisfies M119 AC2.
#
# O3 -- type "live" (reference implementation). Source: tune::tune_grid(),
#   tune::select_best() and fit() run by hand under the final fit's
#   `tuning_seed` and `fit_seed`, on an inner design built on the full data
#   from the fixture's literal inner call. Pinned by the three "the final fit
#   on an inner ... design matches a hand-rolled reference" tests. Satisfies
#   M119 AC3.

skip_heavy_on_cran()

TS_INNER_LEAN_CALLS <- list(
  "sliding-window" = function(d) {
    nested_resamples(
      d,
      outside = rsample::rolling_origin(initial = 60, assess = 1, skip = 9),
      inside = rsample::sliding_window(lookback = 39, assess_stop = 1, step = 5)
    )
  },
  "sliding-index" = function(d) {
    nested_resamples(
      d,
      outside = rsample::rolling_origin(initial = 60, assess = 1, skip = 9),
      inside = rsample::sliding_index(
        index = date,
        lookback = 39,
        assess_stop = 1,
        step = 5
      )
    )
  },
  "sliding-period" = function(d) {
    nested_resamples(
      d,
      outside = rsample::rolling_origin(initial = 60, assess = 1, skip = 9),
      inside = rsample::sliding_period(
        index = date,
        period = "week",
        lookback = 5
      )
    )
  }
)

for (design in names(TS_INNER_DESIGNS)) {
  spec <- TS_INNER_DESIGNS[[design]]
  lean_of <- TS_INNER_LEAN_CALLS[[design]]

  test_that(
    sprintf(
      "nested_tune_grid() on an inner %s design matches a hand-rolled reference loop",
      design
    ),
    {
      skip_if_no_engines()
      d <- spec$data()
      wf <- det_workflow(d)
      ms <- ts_metrics()
      grid <- det_grid()
      folds <- spec$build(d)
      expect_s3_class(folds$splits[[1]], "rof_split")
      expect_s3_class(
        folds$inner_resamples[[1]]$splits[[1]],
        spec$split_class
      )

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

  test_that(sprintf("inner %s splits match rsample::nested_cv()", design), {
    d <- spec$data()

    ref <- spec$build(d)
    lean <- lean_of(d)

    expect_s3_class(lean, "nested_resamples")
    expect_s3_class(lean$splits[[1]], "rof_split")
    expect_s3_class(lean$inner_resamples[[1]]$splits[[1]], spec$split_class)
    expect_outer_identical(lean, ref)
    expect_inner_identical(lean, ref)
  })

  test_that(
    sprintf(
      "the final fit on an inner %s design matches a hand-rolled reference",
      design
    ),
    {
      skip_if_no_engines()
      d <- spec$data()
      final <- expect_final_matches_reference(
        d,
        spec$build(d),
        inner = spec$inner
      )
      # The final fit rebuilt the inner design the fixture names, not a
      # default.
      expect_s3_class(final$tuning$splits[[1]], spec$split_class)
    }
  )
}

# M120 AC4: the sliding-index fixture runs on dates with weekend gaps, so its
# tests reach splits the sliding-window fixture does not build. Both share the
# outer rolling-origin splits, which index rows and not dates.
test_that("the inner sliding-index fixture builds splits sliding-window does not", {
  window <- TS_INNER_DESIGNS[["sliding-window"]]
  index <- TS_INNER_DESIGNS[["sliding-index"]]
  w <- window$build(window$data())
  x <- index$build(index$data())

  expect_identical(
    lapply(x$splits, function(s) s$in_id),
    lapply(w$splits, function(s) s$in_id)
  )
  inner_ids <- function(folds, i) {
    lapply(folds$inner_resamples[[i]]$splits, function(s) s$in_id)
  }
  differs <- vapply(
    seq_len(nrow(x)),
    function(i) !identical(inner_ids(x, i), inner_ids(w, i)),
    logical(1)
  )
  expect_true(any(differs))
})
