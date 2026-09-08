# IP2 across workers, on the shared 3-daemon pool (M76).
#
# The second daemon count BC1, BC10, BC12 and BC13 compare at. The two-daemon
# blocks, the oracle note that governs all of them, and the shared serial
# reference builders are in test-parallel-identity.R and
# helper-parallel-identity.R; this file exists because mirai holds one pool at
# a time, so a second count is a second file rather than a second section
# (M74 made it a section, M76 a file).
#
# Each block rebuilds its serial reference, so it depends on nothing an
# earlier block computed. The closing block is the suite's one assertion that
# a shared pool is gone when its file is done; the other two identity files
# tear their pools down with a bare call.

test_that("the shared 3-daemon pool starts primed (M74)", {
  skip_if_no_daemons()
  start_daemons(3)
  share_daemons(3)
})

test_that("BC1: parallel matches serial at three daemons", {
  skip_if_no_daemons()
  skip_if_not_installed("ranger")

  data <- make_reg_data()
  nested <- det_nested(data)
  wf <- stoch_workflow(data)

  serial <- serial_reference(wf, nested, stoch_grid(), reg_metrics())

  shared_daemons(3)
  set.seed(2026L)
  parallel <- without_pkgload_warning(
    nested_tune_grid(wf, nested, grid = stoch_grid(), metrics = reg_metrics())
  )

  expect_identical(last_dispatch(), "parallel")
  expect_identical(parallel, serial)
})

test_that("BC10: the Bayesian path matches serial at three daemons (M45, AC4)", {
  skip_if_no_daemons()
  skip_if_not_installed("ranger")
  skip_if_not_installed("dials")

  data <- make_reg_data()
  nested <- det_nested(data)
  wf <- stoch_workflow(data)
  p <- bayes_stoch_param_info(wf)

  serial <- bayes_serial_reference(wf, nested, p)

  shared_daemons(3)
  set.seed(2026L)
  parallel <- without_pkgload_warning(
    nested_tune_bayes(
      wf,
      nested,
      iter = 2,
      initial = 3,
      param_info = p,
      metrics = reg_metrics()
    )
  )

  expect_identical(last_dispatch(), "parallel")
  expect_identical(parallel, serial)
})

test_that("BC12: both racing paths match serial at three daemons (M50, AC4)", {
  skip_if_no_daemons()
  skip_if_no_race_fixture(stochastic = TRUE)

  data <- make_reg_data()
  nested <- det_nested(data)
  wf <- stoch_workflow(data)
  ms <- reg_metrics()
  ctrl <- race_control()

  for (fn in RACERS) {
    serial <- race_serial_reference(fn, wf, nested, ms, ctrl)

    shared_daemons(3)
    set.seed(2026L)
    parallel <- without_pkgload_warning(race_call_by_name(
      fn,
      wf,
      nested,
      grid = stoch_grid(),
      metrics = ms,
      control = ctrl
    ))
    expect_identical(last_dispatch(), "parallel")
    for (col in c(
      ".metrics",
      ".selected",
      ".inner_metrics",
      ".tuning_seed",
      ".outer_fit_seed"
    )) {
      expect_identical(parallel[[col]], serial[[col]], info = paste(fn, col))
    }
    expect_identical(parallel, serial)
  }
})

test_that("BC13: the annealing path matches serial at three daemons (M51, AC4)", {
  skip_if_no_daemons()
  skip_if_no_anneal_fixture(stochastic = TRUE)

  data <- make_reg_data()
  nested <- det_nested(data)
  wf <- stoch_workflow(data)
  p <- bayes_stoch_param_info(wf)
  ms <- reg_metrics()
  ctrl <- anneal_control()

  serial <- anneal_serial_reference(wf, nested, p, ms, ctrl)

  shared_daemons(3)
  set.seed(2026L)
  parallel <- without_pkgload_warning(nested_tune_sim_anneal(
    wf,
    nested,
    iter = 2,
    initial = 3,
    param_info = p,
    metrics = ms,
    control = ctrl
  ))
  expect_identical(last_dispatch(), "parallel")
  for (col in c(
    ".metrics",
    ".selected",
    ".inner_metrics",
    ".tuning_seed",
    ".outer_fit_seed"
  )) {
    expect_identical(parallel[[col]], serial[[col]], info = col)
  }
  expect_identical(parallel, serial)
})

test_that("no shared pool outlives its section (M74)", {
  skip_if_no_daemons()
  unshare_daemons()
  expect_identical(mirai::status()$connections, 0L)
})
