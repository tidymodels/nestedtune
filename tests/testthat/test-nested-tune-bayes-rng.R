# The "the caller's RNG state and kind survive the call untouched" and "a
# session with no RNG state is left with a valid one" blocks were pinned here
# until M113, and the fold-order, ambient-RNG and error-restore blocks until
# M152. The RNG restore and the fold seeding are one shared site in
# `nested_loop()` / `nested_fold_fit()`, so test-nested-tune-grid-rng.R covers
# them (D-079).
#
# IP2 for the Bayesian path (M45 AC4). Two of the eight properties
# test-nested-tune-grid-rng.R holds the grid path to, same seed and different
# seed, are asserted here on nested_tune_bayes(). Plus the one rule
# that is this path's own: the Gaussian-process seed is the fold's tuning
# seed, and the control carrying it is built inside that seed's scope. Every
# test that could pass vacuously under a deterministic engine uses ranger,
# whose fits draw from R's RNG; the proposals themselves draw too, through
# tune's own `set.seed(control$seed + i)` calls, which is what the seed rule
# fixes.

skip_heavy_on_cran()

bayes_tuner <- function() tuner_bayes(2, 3, tune::exp_improve())

# The seed-77 run is built once and read back by the different-seed test
# below (M74). The identity here is still between two executions: `first`
# is the build, `second` a direct call, never two reads of one cache entry
# (the M42 lesson).
test_that("the same seed produces the same result", {
  skip_if_no_bayes_fixture(stochastic = TRUE)

  d <- make_reg_data()
  wf <- stoch_workflow(d)
  p <- bayes_stoch_param_info(wf)
  ms <- reg_metrics()

  set.seed(3)
  folds <- nested_resamples(
    d,
    outside = rsample::vfold_cv(v = 3),
    inside = rsample::vfold_cv(v = 3)
  )

  set.seed(77)
  first <- memoised(nested_tune_bayes(
    wf,
    folds,
    iter = 2,
    initial = 3,
    param_info = p,
    metrics = ms
  ))
  set.seed(77)
  second <- nested_tune_bayes(
    wf,
    folds,
    iter = 2,
    initial = 3,
    param_info = p,
    metrics = ms
  )

  expect_identical(first$.metrics, second$.metrics)
  expect_identical(first$.selected, second$.selected)
  expect_identical(first$.inner_metrics, second$.inner_metrics)
  expect_identical(first$.tuning_seed, second$.tuning_seed)
})

test_that("a different seed produces different numbers", {
  skip_if_no_bayes_fixture(stochastic = TRUE)

  d <- make_reg_data()
  wf <- stoch_workflow(d)
  p <- bayes_stoch_param_info(wf)
  ms <- reg_metrics()

  set.seed(3)
  folds <- nested_resamples(
    d,
    outside = rsample::vfold_cv(v = 3),
    inside = rsample::vfold_cv(v = 3)
  )

  set.seed(77)
  first <- memoised(nested_tune_bayes(
    wf,
    folds,
    iter = 2,
    initial = 3,
    param_info = p,
    metrics = ms
  ))
  set.seed(78)
  other <- nested_tune_bayes(
    wf,
    folds,
    iter = 2,
    initial = 3,
    param_info = p,
    metrics = ms
  )

  # Without this the same-seed test above would pass for a driver that ignored
  # the seed entirely.
  expect_false(identical(first$.tuning_seed, other$.tuning_seed))
  expect_false(identical(first$.metrics, other$.metrics))
})

test_that("the Gaussian-process seed is the fold's tuning seed, set inside its scope", {
  skip_if_no_bayes_fixture()

  d <- make_reg_data()
  wf <- bayes_workflow(d)
  p <- bayes_param_info(wf)

  set.seed(6)
  folds <- nested_resamples(
    d,
    outside = rsample::vfold_cv(v = 2),
    inside = rsample::vfold_cv(v = 3)
  )
  seeds <- c(4321L, 8765L)

  # The control's construction is observed where it happens, through the
  # package's own seam: what seed it was handed, and what the generator's state
  # was at that moment.
  seen <- new.env(parent = emptyenv())
  real <- tuner_control
  local_mocked_bindings(
    tuner_control = function(tuner, control, event_level, seed) {
      seen$seed <- seed
      seen$state <- get(".Random.seed", envir = globalenv())
      real(tuner, control = control, event_level = event_level, seed = seed)
    }
  )

  fold <- nested_fold_fit(
    split = folds$splits[[1]],
    inner = folds$inner_resamples[[1]],
    seeds = seeds,
    object = wf,
    tuner = bayes_tuner(),
    metrics = reg_metrics(),
    param_info = p
  )
  expect_true(fold$completed)

  # The seed handed to control_bayes() is the fold's tuning seed ...
  expect_identical(seen$seed, seeds[[1L]])

  # ... and the control was built with the generator exactly where
  # `set_fold_seed()` on that seed leaves it: nothing was drawn in between, so
  # the control sits inside the seed's scope rather than after some of it.
  set_fold_seed(seeds[[1L]])
  expect_identical(seen$state, get(".Random.seed", envir = globalenv()))
})
