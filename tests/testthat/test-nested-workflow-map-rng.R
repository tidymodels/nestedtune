# The seed envelope of nested_workflow_map() (M71, AC2; IP2, D-011). The
# map reinstates one entry state before every workflow and leaves the
# caller's state as it found it, including a session that had never drawn.
# Every identity is between direct calls, never through `memoised()` (the
# M42 lesson), and every fixture is built before the state is read: a recipe
# draws its step id from the stream.

test_that("AC2: the caller's RNG state and kind survive the call untouched", {
  skip_if_no_wset_fixture()
  d <- make_reg_data()
  set.seed(31)
  wset <- wset_two(d)
  folds <- final_nested(d)
  ms <- reg_metrics()
  entry_kind <- RNGkind()
  on.exit(
    RNGkind(entry_kind[[1]], entry_kind[[2]], entry_kind[[3]]),
    add = TRUE
  )

  RNGkind("Wichmann-Hill")
  set.seed(42)
  before <- .Random.seed
  invisible(nested_workflow_map(
    wset,
    resamples = folds,
    grid = det_grid(),
    metrics = ms
  ))
  expect_identical(.Random.seed, before)
  expect_identical(RNGkind()[[1L]], "Wichmann-Hill")
})

test_that("AC2: a session that never drew is left with no RNG state", {
  skip_if_no_wset_fixture()
  d <- make_reg_data()
  set.seed(31)
  wset <- wset_two(d)
  folds <- final_nested(d)
  ms <- reg_metrics()
  entry_kind <- RNGkind()

  saved <- .Random.seed
  on.exit(assign(".Random.seed", saved, envir = globalenv()), add = TRUE)
  rm(".Random.seed", envir = globalenv())
  expect_false(exists(".Random.seed", envir = globalenv(), inherits = FALSE))

  res <- nested_workflow_map(
    wset,
    resamples = folds,
    grid = det_grid(),
    metrics = ms
  )
  # Unlike an orchestrator on its own, which keeps the state it created,
  # the map removes it: the session is as it was found (AC2). The kind is
  # as it was found too, and the next draw works.
  expect_false(exists(".Random.seed", envir = globalenv(), inherits = FALSE))
  expect_identical(RNGkind(), entry_kind)
  expect_no_error(runif(1))
  # And the workflows still shared their seeds: the state the map
  # initialized was reinstated before each.
  expect_identical(res$result[[2L]]$.tuning_seed, res$result[[1L]]$.tuning_seed)
  expect_identical(
    res$result[[2L]]$.outer_fit_seed,
    res$result[[1L]]$.outer_fit_seed
  )
})

test_that("AC2: the same seed gives identical sets across two direct calls, and a different seed does not", {
  skip_if_no_wset_fixture(stochastic = TRUE)
  d <- make_reg_data()
  # ranger on both rows, so the outer fits draw from the stream.
  wset <- workflowsets::as_workflow_set(
    tuned = stoch_workflow(d),
    fixed = fixed_stoch_workflow(d)
  )
  folds <- det_nested(d)
  ms <- reg_metrics()

  set.seed(77)
  first <- nested_workflow_map(
    wset,
    resamples = folds,
    grid = stoch_grid(),
    metrics = ms
  )
  set.seed(77)
  second <- nested_workflow_map(
    wset,
    resamples = folds,
    grid = stoch_grid(),
    metrics = ms
  )
  expect_true(all(first$result[[1L]]$.completed))
  expect_true(all(first$result[[2L]]$.completed))
  expect_identical(first, second)

  set.seed(78)
  other <- nested_workflow_map(
    wset,
    resamples = folds,
    grid = stoch_grid(),
    metrics = ms
  )
  expect_false(identical(
    first$result[[1L]]$.metrics,
    other$result[[1L]]$.metrics
  ))
  expect_false(identical(
    first$result[[2L]]$.metrics,
    other$result[[2L]]$.metrics
  ))
})

test_that("AC2: an error partway through the set still restores the caller's state", {
  skip_if_no_wset_fixture()
  d <- make_reg_data()
  set.seed(31)
  wset <- wset_three(d)
  wset$option[[3L]] <- structure(
    list(),
    class = c("workflow_set_options", "list")
  )
  folds <- final_nested(d)

  set.seed(5)
  before <- .Random.seed
  expect_error(nested_workflow_map(wset, resamples = folds, grid = det_grid()))
  expect_identical(.Random.seed, before)
})
