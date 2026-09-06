# The seed contract on the plain resampling path (M70, AC6; IP2), on the
# stochastic fixture: ranger draws its own seed from R's stream, so a fold's
# fit is reproducible exactly when the outer-fit seed is applied as the
# contract says. Every identity below is between two direct calls, never
# through `memoised()` (the M42 lesson).

test_that("AC6: the same seed gives identical results across two direct calls", {
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

test_that("a fold's result does not depend on the ambient RNG state or kind", {
  skip_if_no_engines(stochastic = TRUE)

  d <- make_reg_data()
  wf <- fixed_stoch_workflow(d)
  ms <- reg_metrics()
  folds <- det_nested(d)
  seeds <- c(101L, 202L)
  entry_kind <- RNGkind()
  on.exit(
    RNGkind(entry_kind[[1]], entry_kind[[2]], entry_kind[[3]]),
    add = TRUE
  )

  run_one <- function() {
    nested_fold_fit(
      split = folds$splits[[1]],
      inner = folds$inner_resamples[[1]],
      seeds = seeds,
      object = wf,
      tuner = tuner_fit_resamples(),
      metrics = ms,
      select = NULL
    )
  }

  set.seed(1)
  from_default <- run_one()

  # A third kind, neither the default nor L'Ecuyer-CMRG: mirai's daemons run
  # on the latter, so it has no power to catch a missing pin (the M07
  # lesson); Wichmann-Hill does.
  RNGkind("Wichmann-Hill")
  set.seed(9999)
  from_wichmann <- run_one()

  RNGkind(entry_kind[[1]], entry_kind[[2]], entry_kind[[3]])
  set.seed(31337)
  invisible(runif(17))
  from_midstream <- run_one()

  expect_true(from_default$completed)
  expect_identical(from_wichmann, from_default)
  expect_identical(from_midstream, from_default)
  # The fold's record: nothing selected, no inner rows.
  expect_identical(dim(from_default$selected), c(0L, 0L))
  expect_identical(nrow(from_default$inner_metrics), 0L)
})

test_that("the caller's RNG state and kind survive the call untouched", {
  skip_if_no_engines(stochastic = TRUE)

  d <- make_reg_data()
  wf <- fixed_stoch_workflow(d)
  folds <- det_nested(d)
  entry_kind <- RNGkind()
  on.exit(
    RNGkind(entry_kind[[1]], entry_kind[[2]], entry_kind[[3]]),
    add = TRUE
  )

  RNGkind("Wichmann-Hill")
  set.seed(42)
  before <- .Random.seed
  invisible(nested_fit_resamples(wf, folds, metrics = reg_metrics()))
  expect_identical(.Random.seed, before)
  expect_identical(RNGkind()[[1L]], "Wichmann-Hill")
})
