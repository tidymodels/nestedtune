# The "fold results do not depend on the order folds are run in", "fold
# results do not depend on the ambient RNG state or kind", "the caller's RNG
# state and kind survive the call untouched", and "a session with no RNG
# state is left with a valid one" blocks were pinned here until M113. The
# success-path RNG restore and the fold seeding are one shared site in
# `nested_loop()` / `set_fold_seed()`, so test-nested-tune-grid-rng.R covers
# them (D-079).
# IP2 for the racing path (M50 AC4). Of the properties
# test-nested-tune-grid-rng.R holds the grid path to, the same-seed,
# different-seed, and error-restore properties are asserted here on both
# racing exports; the rest are covered once, in test-nested-tune-grid-rng.R
# (D-079). Every test that could pass vacuously under a deterministic engine
# uses ranger, whose fits draw from R's RNG; the race itself draws too,
# shuffling the inner resamples before the burn-in, which is why even the
# deterministic fixture's record depends on the seed.

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
# itself (M74): the seed-77 run is built once by the same-seed test and read
# back by the different-seed test. `first` in the same-seed test is the
# build and `second` a direct call, so that identity is between two
# executions, never two reads of one cache entry (the M42 lesson).
race_run_cached <- function(fn, wf, folds, ms, ctrl = race_control()) {
  g <- stoch_grid()
  switch(
    fn,
    tune_race_anova = memoised(nested_tune_race_anova(
      wf,
      folds,
      grid = g,
      metrics = ms,
      control = ctrl
    )),
    tune_race_win_loss = memoised(nested_tune_race_win_loss(
      wf,
      folds,
      grid = g,
      metrics = ms,
      control = ctrl
    ))
  )
}

test_that("the same seed produces the same result", {
  skip_if_no_race_fixture(stochastic = TRUE)

  d <- make_reg_data()
  wf <- stoch_workflow(d)
  ms <- reg_metrics()

  set.seed(3)
  folds <- nested_resamples(
    d,
    outside = rsample::vfold_cv(v = 3),
    inside = rsample::vfold_cv(v = 3)
  )

  for (fn in RACERS) {
    set.seed(77)
    first <- race_run_cached(fn, wf, folds, ms)
    set.seed(77)
    second <- race_run(fn, wf, folds, ms)

    expect_identical(first$.metrics, second$.metrics)
    expect_identical(first$.selected, second$.selected)
    expect_identical(first$.inner_metrics, second$.inner_metrics)
    expect_identical(first$.tuning_seed, second$.tuning_seed)
    expect_identical(first, second)
  }
})

test_that("a different seed produces different inner tables", {
  skip_if_no_race_fixture(stochastic = TRUE)

  d <- make_reg_data()
  wf <- stoch_workflow(d)
  ms <- reg_metrics()

  set.seed(3)
  folds <- nested_resamples(
    d,
    outside = rsample::vfold_cv(v = 3),
    inside = rsample::vfold_cv(v = 3)
  )

  for (fn in RACERS) {
    set.seed(77)
    first <- race_run_cached(fn, wf, folds, ms)
    set.seed(78)
    other <- race_run(fn, wf, folds, ms)

    # Without this the same-seed test above would pass for a driver that
    # ignored the seed entirely.
    expect_false(identical(first$.tuning_seed, other$.tuning_seed))
    expect_false(identical(first$.inner_metrics, other$.inner_metrics))
    expect_false(identical(first$.metrics, other$.metrics))
  }
})

test_that("the RNG state is restored when the call itself errors", {
  skip_if_no_race_fixture()

  d <- make_reg_data()
  wf <- det_workflow(d)
  folds <- det_nested(d)
  ctrl <- race_control()

  # The worker is stubbed to throw, so the error escapes the loop rather
  # than being recorded -- the only remaining way out of the call after the
  # seeds have been drawn, and the case on.exit() exists for.
  testthat::local_mocked_bindings(
    nested_fold_fit = function(...) stop("engineered worker failure")
  )

  for (fn in RACERS) {
    set.seed(505)
    before_seed <- .Random.seed
    before_kind <- RNGkind()

    expect_error(
      race_call_by_name(fn, wf, folds, grid = det_grid(), control = ctrl),
      "engineered worker failure"
    )

    expect_identical(.Random.seed, before_seed)
    expect_identical(RNGkind(), before_kind)
  }
})
