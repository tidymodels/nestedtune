# The fold-order, ambient-RNG, caller's-RNG, no-RNG-state and error-restore
# blocks are covered by test-nested-tune-grid-rng.R: the RNG restore on both
# exits and the fold seeding are one shared site in `nested_loop()` /
# `set_fold_seed()`. The same-seed and different-seed properties that
# test-nested-tune-grid-rng.R holds the grid path to are asserted here on the
# ANOVA racer, since the two racing exports share one body,
# `nested_tune_race()`. Both tests use ranger, whose fits draw from R's RNG;
# the race itself draws too, shuffling the inner resamples before the burn-in,
# which is why even the deterministic fixture's record depends on the seed.

skip_heavy_on_cran()

race_run <- function(fn, wf, folds, ms, ctrl = race_control()) {
  race_call_by_name(
    fn,
    wf,
    folds,
    grid = stoch_grid(),
    metrics = ms,
    control = ctrl
  )
}

# The same run served from the fixture cache, keyed on the package call
# itself: the seed-77 run is built once by the same-seed test and read
# back by the different-seed test. `first` in the same-seed test is the
# build and `second` a direct call, so that identity is between two
# executions, never two reads of one cache entry.
race_run_cached <- function(wf, folds, ms, ctrl = race_control()) {
  g <- stoch_grid()
  memoised(nested_tune_race_anova(
    wf,
    folds,
    grid = g,
    metrics = ms,
    control = ctrl
  ))
}

test_that("the same seed produces the same result", {
  fn <- "tune_race_anova"
  skip_if_no_race_fixture(fn, stochastic = TRUE)

  d <- make_reg_data()
  wf <- stoch_workflow(d)
  ms <- reg_metrics()

  set.seed(3)
  folds <- nested_resamples(
    d,
    outside = rsample::vfold_cv(v = 3),
    inside = rsample::vfold_cv(v = 3)
  )

  set.seed(77)
  first <- race_run_cached(wf, folds, ms)
  set.seed(77)
  second <- race_run(fn, wf, folds, ms)

  expect_identical(first$.metrics, second$.metrics)
  expect_identical(first$.selected, second$.selected)
  expect_identical(first$.inner_metrics, second$.inner_metrics)
  expect_identical(first$.tuning_seed, second$.tuning_seed)
  expect_identical(first, second)
})

test_that("a different seed produces different inner tables", {
  fn <- "tune_race_anova"
  skip_if_no_race_fixture(fn, stochastic = TRUE)

  d <- make_reg_data()
  wf <- stoch_workflow(d)
  ms <- reg_metrics()

  set.seed(3)
  folds <- nested_resamples(
    d,
    outside = rsample::vfold_cv(v = 3),
    inside = rsample::vfold_cv(v = 3)
  )

  set.seed(77)
  first <- race_run_cached(wf, folds, ms)
  set.seed(78)
  other <- race_run(fn, wf, folds, ms)

  # Without this the same-seed test above would pass for a driver that
  # ignored the seed entirely.
  expect_false(identical(first$.tuning_seed, other$.tuning_seed))
  expect_false(identical(first$.inner_metrics, other$.inner_metrics))
  expect_false(identical(first$.metrics, other$.metrics))
})
