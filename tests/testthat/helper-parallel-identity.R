# The serial references the identity blocks compare against (M76).
#
# Each of these builds one serial run with the shared fixtures and asserts it
# took the serial branch, so a block's own body is the parallel run and the
# comparison. They live in a helper rather than in a test file because
# `test-parallel-identity.R` was split at its daemon-pool boundaries (M76) and
# the two-daemon and three-daemon files both build the same references; a
# function defined in a test file is visible only inside it.
#
# `serial_run()` (helper-parallel.R) is what makes a serial run possible while
# a pool is up: it has the orchestrator count zero daemons.

serial_reference <- function(wf, nested, grid, metrics, seed = 2026L) {
  set.seed(seed)
  out <- serial_run(
    nested_tune_grid(wf, nested, grid = grid, metrics = metrics)
  )
  testthat::expect_identical(last_dispatch(), "serial")
  out
}
# BC10's serial reference (M45, AC4): the stochastic fixture, so the
# Gaussian-process proposals and the ranger fits both draw -- a deterministic
# engine would leave only tune's own `set.seed(control$seed + i)` calls to
# differ, and those are the seed rule under test on both sides of the
# identity. Shared by the two-daemon block here and the three-daemon one
# below (M74).
bayes_serial_reference <- function(wf, nested, p) {
  set.seed(2026L)
  serial <- serial_run(nested_tune_bayes(
    wf,
    nested,
    iter = 2,
    initial = 3,
    param_info = p,
    metrics = reg_metrics()
  ))
  expect_identical(last_dispatch(), "serial")
  expect_true(all(serial$.completed))
  serial
}

# BC12 (M50, AC4), for both racers: the stochastic fixture, so the race's
# resample shuffle and the ranger fits both draw; and the daemons' library
# holds finetune, which the loop attaches in every daemon before the first
# fold is sent. The serial race is shared by the two-daemon block here and
# the three-daemon one below (M74).
race_serial_reference <- function(fn, wf, nested, ms, ctrl) {
  set.seed(2026L)
  serial <- serial_run(race_call_by_name(
    fn,
    wf,
    nested,
    grid = stoch_grid(),
    metrics = ms,
    control = ctrl
  ))
  expect_identical(last_dispatch(), "serial")
  expect_true(all(serial$.completed))
  serial
}

# BC13 (M51, AC4): the stochastic fixture, so the search's initial design and
# perturbations and the ranger fits all draw; and the daemons' library holds
# finetune, which the loop attaches in every daemon before the first fold is
# sent. `time_limit` is left unset (`NA`), as AC4 requires: a wall-clock stop
# is the one slot that could make the two sides differ. The serial search is
# shared by the two-daemon block here and the three-daemon one below (M74).
anneal_serial_reference <- function(wf, nested, p, ms, ctrl) {
  expect_true(is.na(ctrl$time_limit))
  set.seed(2026L)
  serial <- serial_run(nested_tune_sim_anneal(
    wf,
    nested,
    iter = 2,
    initial = 3,
    param_info = p,
    metrics = ms,
    control = ctrl
  ))
  expect_identical(last_dispatch(), "serial")
  expect_true(all(serial$.completed))
  serial
}
