# The seed contract on the plain resampling path, on the stochastic fixture:
# ranger draws its own seed from R's stream, so a fold's fit is reproducible
# exactly when the outer-fit seed is applied as the contract says. The identity
# is between two direct calls, never through `memoised()`. The ambient-RNG and
# caller's-RNG blocks live in test-nested-tune-grid-rng.R: the fold seeding and
# the restore are one shared site in `nested_fold_fit()` / `nested_loop()`, so
# that file covers them.

skip_heavy_on_cran()

test_that("the same seed gives identical results across two direct calls", {
  skip_if_no_engines(stochastic = TRUE)

  d <- make_reg_data()
  wf <- fixed_stoch_workflow(d)
  ms <- reg_metrics()
  folds <- det_nested(d)

  set.seed(77)
  first <- nested_fit_resamples(wf, folds, metrics = ms)
  set.seed(77)
  second <- nested_fit_resamples(wf, folds, metrics = ms)

  expect_true(all(first$.completed))
  expect_identical(first, second)

  # Without this the identity above would pass for a driver that ignored the
  # seed entirely: a different seed is a different forest.
  set.seed(78)
  other <- nested_fit_resamples(wf, folds, metrics = ms)
  expect_false(identical(first$.outer_fit_seed, other$.outer_fit_seed))
  expect_false(identical(first$.metrics, other$.metrics))
})
