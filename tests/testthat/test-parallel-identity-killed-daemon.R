# BC3: a daemon killed mid-run yields a recorded failure, not an abort (M76).
#
# Its own file because it kills one of its daemons, so no other block may
# share them; mirai holds one pool at a time, so the pool it starts is the
# only one this file has. The rest of the identity suite -- the oracle note
# that governs it, and the shared serial reference builders -- is in
# test-parallel-identity.R and helper-parallel-identity.R (M74 made this a
# trailing section, M76 a file).

test_that("BC3: a daemon killed mid-run yields a recorded failure, not an abort", {
  skip_if_no_daemons()
  skip_if_not_installed("ranger")

  # This drives the REAL nested_tune_grid() -> dispatch_folds() path. An earlier
  # version hand-rolled mirai_map/collect_mirai/classify_fold_result instead, on
  # the belief that production code had no injection point; review disproved
  # that by execution. Because dispatch_folds() looks `fold_task` up by name and
  # serializes it, a mocked binding reaches the daemon, so the kill happens
  # inside a genuine dispatch. The old shape left AC5 unpinned: switching the
  # collect to `.stop = TRUE` kept every test green.
  #
  # The mock communicates through environment variables, not captured locals:
  # dispatch strips the task's environment before sending it, and daemons
  # inherit environment variables set before they start.
  ledger <- tempfile()
  dir.create(ledger)

  data <- make_reg_data()
  nested <- det_nested(data)
  wf <- stoch_workflow(data)

  # Fold 2's tuning seed, derived the way the documented contract says the
  # driver derives it, so the mock can recognise that fold wherever it lands.
  set.seed(2026L)
  seeds <- sample.int(.Machine$integer.max, 2L * nrow(nested))
  kill_seed <- seeds[[2L * 2L - 1L]]

  old <- Sys.getenv(
    c("NESTEDTUNE_LEDGER", "NESTEDTUNE_KILL_SEED"),
    names = TRUE
  )
  Sys.setenv(NESTEDTUNE_LEDGER = ledger, NESTEDTUNE_KILL_SEED = kill_seed)
  on.exit(do.call(Sys.setenv, as.list(old)), add = TRUE)
  on.exit(mirai::daemons(0), add = TRUE)

  mirai::daemons(0)
  set.seed(2026L)
  serial <- nested_tune_grid(
    wf,
    nested,
    grid = stoch_grid(),
    metrics = reg_metrics()
  )

  start_daemons(2)
  local_mocked_bindings(
    fold_task = function(
      payload,
      object,
      tuner,
      metrics,
      param_info,
      event_level,
      eval_time,
      select,
      control
    ) {
      seed <- payload$seeds[[1L]]
      file.create(file.path(
        Sys.getenv("NESTEDTUNE_LEDGER"),
        paste0(seed, "-", Sys.getpid())
      ))
      if (identical(as.character(seed), Sys.getenv("NESTEDTUNE_KILL_SEED"))) {
        tools::pskill(Sys.getpid())
        Sys.sleep(30)
      }
      asNamespace("nestedtune")$nested_fold_fit(
        split = payload$split,
        inner = payload$inner,
        seeds = payload$seeds,
        object = object,
        tuner = tuner,
        metrics = metrics,
        param_info = param_info,
        event_level = event_level,
        eval_time = eval_time,
        select = select,
        control = control
      )
    }
  )

  set.seed(2026L)
  parallel <- suppressWarnings(
    without_pkgload_warning(
      nested_tune_grid(wf, nested, grid = stoch_grid(), metrics = reg_metrics())
    )
  )

  # The run returned rather than aborting -- the whole point (M03, IP4).
  expect_identical(last_dispatch(), "parallel")
  expect_identical(nrow(parallel), nrow(serial))

  expect_false(parallel$.completed[[2L]])
  expect_identical(parallel$.notes[[2L]]$location, "worker")

  # Every surviving fold matches its serial counterpart exactly.
  for (i in setdiff(seq_len(nrow(serial)), 2L)) {
    expect_true(parallel$.completed[[i]])
    expect_identical(parallel$.metrics[[i]], serial$.metrics[[i]])
    expect_identical(parallel$.selected[[i]], serial$.selected[[i]])
  }

  # One file per fold, and exactly one: a retried fold would leave two, since
  # the replacement daemon has a different pid.
  ran <- sub("-.*$", "", list.files(ledger))
  expect_identical(
    sort(as.numeric(ran)),
    sort(as.numeric(seeds[c(TRUE, FALSE)]))
  )
  expect_identical(anyDuplicated(ran), 0L)
})

# mirai holds one pool at a time and the worker that ran this file goes on to
# another one, so the pool does not outlive the file. A bare call rather than
# a `test_that()` block: testthat evaluates a file's top-level code as it
# sources it, so this runs after every block above, and the split that made
# this file (M76) moves no test claim. The one block that asserts the
# teardown is in test-parallel-identity-three-daemons.R, where it has sat
# since M74.
if (requireNamespace("mirai", quietly = TRUE)) {
  unshare_daemons()
}
