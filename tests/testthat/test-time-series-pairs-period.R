# The three pairs of an outer `sliding_period()` design and an inner sliding
# design (M121). The fixtures are TS_SLIDING_PAIRS in helper-orchestration.R,
# and the tests for the other two outer designs sit in
# test-time-series-pairs-window.R and test-time-series-pairs-index.R. DESIGN
# Conventions: oracles are recorded in the test file that asserts them.
#
# O1 -- type "live" (reference implementation). Source: rsample::nested_cv(),
#   recomputed at test time on the pair's own arguments by
#   ts_pair_reference(). Every outer and inner analysis and assessment set
#   `nested_resamples()` builds must match it row for row. Pinned by the
#   "... splits match rsample::nested_cv()" tests. Satisfies M121 AC1.
#
# O2 -- type "live" (reference implementation). Source: the tidymodels
#   pipeline itself, recomputed at test time by reference_nested_loop() in
#   helper-orchestration.R, written from the documented seed contract rather
#   than from the driver. Pinned by the "nested_tune_grid() on the ... pair
#   matches a hand-rolled reference loop" tests. Satisfies M121 AC2.

skip_heavy_on_cran()

for (pair in names(ts_pairs_with_outer("sliding-period"))) {
  spec <- TS_SLIDING_PAIRS[[pair]]

  test_that(sprintf("%s splits match rsample::nested_cv()", pair), {
    d <- make_ts_weekday_data()

    lean <- spec$build(d)
    ref <- ts_pair_reference(spec, d)

    expect_s3_class(lean, "nested_resamples")
    expect_s3_class(lean$splits[[1]], spec$outer_class)
    expect_s3_class(lean$inner_resamples[[1]]$splits[[1]], spec$inner_class)
    expect_outer_identical(lean, ref)
    expect_inner_identical(lean, ref)
  })

  test_that(
    sprintf(
      "nested_tune_grid() on the %s pair matches a hand-rolled reference loop",
      pair
    ),
    {
      skip_if_no_engines()
      d <- make_ts_weekday_data()
      wf <- det_workflow(d)
      ms <- ts_metrics()
      grid <- det_grid()
      folds <- spec$build(d)
      expect_s3_class(folds$splits[[1]], spec$outer_class)
      expect_s3_class(folds$inner_resamples[[1]]$splits[[1]], spec$inner_class)

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
}
