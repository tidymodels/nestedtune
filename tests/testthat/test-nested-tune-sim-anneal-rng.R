# The "fold results do not depend on the order folds are run in", "fold
# results do not depend on the ambient RNG state or kind", "the caller's RNG
# state and kind survive the call untouched", and "a session with no RNG
# state is left with a valid one" blocks were pinned here until M113. The
# success-path RNG restore and the fold seeding are one shared site in
# `nested_loop()` / `set_fold_seed()`, so test-nested-tune-grid-rng.R covers
# them (D-079).
# IP2 for the annealing path (M51 AC4). Of the properties
# test-nested-tune-grid-rng.R holds the grid path to, the same-seed,
# different-seed, and error-restore properties are asserted here on
# nested_tune_sim_anneal(); the rest are covered once, in
# test-nested-tune-grid-rng.R (D-079). Every test that could pass vacuously
# under a deterministic engine uses ranger, whose fits draw from R's RNG; the
# search itself draws too -- the initial design and every perturbation come
# from the stream the fold's tuning seed started -- which is why even the
# deterministic fixture's record depends on the seed.

anneal_run <- function(wf, folds, p, ms, ctrl = anneal_control()) {
  nested_tune_sim_anneal(
    wf,
    folds,
    iter = 2,
    initial = 3,
    param_info = p,
    metrics = ms,
    control = ctrl
  )
}

# The seed-77 run is built once and read back by the different-seed test
# below (M74): `first` is the build, `second` a direct call, so the identity
# is between two executions and never two reads of one cache entry (the M42
# lesson). Spelled out rather than through anneal_run() so the cache keys the
# package call itself.
test_that("the same seed produces the same result", {
  skip_if_no_anneal_fixture(stochastic = TRUE)

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
  first <- memoised(nested_tune_sim_anneal(
    wf,
    folds,
    iter = 2,
    initial = 3,
    param_info = p,
    metrics = ms,
    control = anneal_control()
  ))
  set.seed(77)
  second <- anneal_run(wf, folds, p, ms)

  expect_identical(first$.metrics, second$.metrics)
  expect_identical(first$.selected, second$.selected)
  expect_identical(first$.inner_metrics, second$.inner_metrics)
  expect_identical(first$.tuning_seed, second$.tuning_seed)
  expect_identical(first, second)
})

test_that("a different seed produces different inner tables", {
  skip_if_no_anneal_fixture(stochastic = TRUE)

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
  first <- memoised(nested_tune_sim_anneal(
    wf,
    folds,
    iter = 2,
    initial = 3,
    param_info = p,
    metrics = ms,
    control = anneal_control()
  ))
  set.seed(78)
  other <- anneal_run(wf, folds, p, ms)

  # Without this the same-seed test above would pass for a driver that
  # ignored the seed entirely.
  expect_false(identical(first$.tuning_seed, other$.tuning_seed))
  expect_false(identical(first$.inner_metrics, other$.inner_metrics))
  expect_false(identical(first$.metrics, other$.metrics))
})

test_that("the RNG state is restored when the call itself errors", {
  skip_if_no_anneal_fixture()

  d <- make_reg_data()
  wf <- det_workflow(d)
  folds <- det_nested(d)
  ctrl <- anneal_control()

  # The worker is stubbed to throw, so the error escapes the loop rather than
  # being recorded -- the only remaining way out of the call after the seeds
  # have been drawn, and the case on.exit() exists for.
  testthat::local_mocked_bindings(
    nested_fold_fit = function(...) stop("engineered worker failure")
  )

  set.seed(505)
  before_seed <- .Random.seed
  before_kind <- RNGkind()

  expect_error(
    nested_tune_sim_anneal(wf, folds, iter = 2, initial = 3, control = ctrl),
    "engineered worker failure"
  )

  expect_identical(.Random.seed, before_seed)
  expect_identical(RNGkind(), before_kind)
})
