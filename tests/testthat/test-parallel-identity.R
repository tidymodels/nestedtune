# IP2 across workers: the identity that makes parallel dispatch legitimate,
# on the shared 2-daemon pool.
#
# Oracle note (DESIGN "Oracle records"): these tests are *mode-independence*
# assertions, not absolute-correctness ones. A defect present identically in the
# serial and parallel paths preserves every identity here while breaking the
# documented contract, which is why RR03 (BC7) requires the contract-derived
# reference-loop oracle in test-nested-tune-grid-oracles.R to stay green
# alongside them. Neither replaces the other: that one anchors what the numbers
# are, these anchor that the numbers do not depend on how the loop was run.
#
# Every test uses the ranger workflow. With a deterministic engine these pass
# vacuously -- RR03 re-confirmed M02's lesson by executing a wrong dispatcher
# against the PCA/lm workflow and watching it pass.
#
# Pools. mirai holds one pool at a time, so a file holds exactly one (M76).
# This file holds the shared 2-daemon pool: every block that needs only a
# primed pool of two, started once below and probed before each reuse by
# `shared_daemons(2)` (helper-parallel.R). BC9, which pollutes its daemons, is
# the last block on it. The three-daemon blocks are in
# test-parallel-identity-three-daemons.R, and BC3, which kills a daemon, in
# test-parallel-identity-killed-daemon.R. M74 ordered those three as sections
# of one file; M76 made them files, so the suite can run them on separate
# workers.
#
# A block's serial reference is built while the pool is up through
# `serial_run()`, which has the orchestrator count zero daemons; the four
# reference builders are in helper-parallel-identity.R, shared with the
# three-daemon file.

test_that("the shared 2-daemon pool starts primed (M74)", {
  skip_if_no_daemons()
  start_daemons(2)
  share_daemons(2)
})

# Both daemon counts BC1 compares at are >= 2, the threshold D-018 inherited
# from tune. A one-daemon run would take the serial branch and the "identity"
# would be serial vs serial -- the vacuity RR03 flagged as B1. The two counts
# are two blocks, one per shared pool (M74); the three-daemon one is below.

test_that("BC1: parallel matches serial at two daemons", {
  skip_if_no_daemons()
  skip_if_not_installed("ranger")

  data <- make_reg_data()
  nested <- det_nested(data)
  wf <- stoch_workflow(data)

  serial <- serial_reference(wf, nested, stoch_grid(), reg_metrics())

  shared_daemons(2)
  set.seed(2026L)
  parallel <- without_pkgload_warning(
    nested_tune_grid(wf, nested, grid = stoch_grid(), metrics = reg_metrics())
  )

  # BC1's second half: prove the parallel branch actually ran. The evidence is
  # out-of-band precisely so that asserting it cannot disturb the identity.
  expect_identical(last_dispatch(), "parallel")
  expect_identical(parallel, serial)
})

test_that("BC2: identity holds under a caller kind that is neither MT nor L'Ecuyer", {
  skip_if_no_daemons()
  skip_if_not_installed("ranger")

  # Why Wichmann-Hill and not the obvious L'Ecuyer-CMRG: mirai starts its
  # daemons on L'Ecuyer-CMRG. A caller who has selected that same kind therefore
  # matches the daemons' ambient generator exactly, and an implementation with
  # NO kind pin at all reproduces serial results perfectly -- RR03 verified this
  # by execution. L'Ecuyer-CMRG is the one non-default kind with zero detection
  # power here, so the test that exists to catch a missing pin must avoid it.
  old_kind <- RNGkind()
  on.exit(RNGkind(old_kind[[1L]], old_kind[[2L]], old_kind[[3L]]), add = TRUE)
  RNGkind("Wichmann-Hill")

  data <- make_reg_data()
  nested <- det_nested(data)
  wf <- stoch_workflow(data)

  serial <- serial_reference(wf, nested, stoch_grid(), reg_metrics())

  shared_daemons(2)
  # The detection power rests on the daemons NOT being on the host's kind: a
  # shared pool's daemons are on mirai's L'Ecuyer-CMRG until their first fold
  # and on the pin's Mersenne-Twister after it, and neither is Wichmann-Hill,
  # so a missing pin would still fail here (M74, the M07 lesson).
  expect_false("Wichmann-Hill" %in% daemon_rng_kinds())
  set.seed(2026L)
  parallel <- without_pkgload_warning(
    nested_tune_grid(wf, nested, grid = stoch_grid(), metrics = reg_metrics())
  )
  expect_identical(last_dispatch(), "parallel")
  expect_identical(parallel, serial)
})

test_that("BC1: the caller's RNG state and kind survive a parallel run", {
  skip_if_no_daemons()
  skip_if_not_installed("ranger")

  data <- make_reg_data()
  nested <- det_nested(data)
  wf <- stoch_workflow(data)
  shared_daemons(2)

  set.seed(99L)
  before_seed <- .Random.seed
  before_kind <- RNGkind()
  without_pkgload_warning(
    nested_tune_grid(wf, nested, grid = stoch_grid(), metrics = reg_metrics())
  )

  expect_identical(.Random.seed, before_seed)
  expect_identical(RNGkind(), before_kind)
})

test_that("BC4: an aborted parallel run still restores the caller's RNG state", {
  skip_if_no_daemons()

  # An interrupt unwinds through the same on.exit() the pre-flight abort does,
  # so this pins the exit contract BC4 depends on. The interrupt value itself is
  # classified in test-parallel-classify.R, where it can be constructed exactly.
  #
  # The abort is induced by mocking the probe, not by breaking the library path:
  # real daemons with no library cannot load mirai either, so they die at
  # startup and the probe hangs (M07-D6).
  local_mocked_bindings(daemons_load_status = function(...) {
    preflight_outcome(reports(FALSE))
  })
  shared_daemons(2)

  data <- make_reg_data()
  nested <- det_nested(data)
  wf <- det_workflow(data)

  set.seed(5L)
  before_seed <- .Random.seed
  before_kind <- RNGkind()
  expect_error(
    nested_tune_grid(wf, nested, grid = det_grid(), metrics = reg_metrics()),
    class = "nestedtune_daemons_cannot_load"
  )
  expect_identical(.Random.seed, before_seed)
  expect_identical(RNGkind(), before_kind)
})

test_that("a cancelled parallel run returns nothing and restores the RNG state", {
  skip_if_no_daemons()

  # Cancellation needs an actor outside the host, because the host is blocked
  # in collect_mirai() for the whole window in which it can happen. What is
  # substituted here is only that actor: the map is really dispatched to real
  # daemons and really stopped, and everything the milestone is about --
  # collect_mirai() resolving to errorValue 20, classify_fold_result() seeing
  # it, the abort, the on.exit() unwind -- is the production path, unmocked.
  # Hand-rolling the collect instead would pin nothing (M07).
  real_map <- mirai::mirai_map
  local_mocked_bindings(
    mirai_map = function(...) {
      map <- real_map(...)
      mirai::stop_mirai(map)
      map
    },
    .package = "mirai"
  )
  shared_daemons(2)

  data <- make_reg_data()
  nested <- det_nested(data)
  wf <- det_workflow(data)

  set.seed(5L)
  before_seed <- .Random.seed
  before_kind <- RNGkind()

  # A real bound, not a measurement after the fact: a stopped map resolves at
  # once, so if this call ever blocks, the run must end as an error rather than
  # wedge `R CMD check` the way M07-D6 records. It rests on the collect being
  # interruptible, which is the same property a user's Ctrl-C rests on.
  setTimeLimit(elapsed = 60, transient = TRUE)
  on.exit(setTimeLimit(cpu = Inf, elapsed = Inf, transient = FALSE), add = TRUE)

  result <- NULL
  # `error =`, deliberately not `condition =`: the pre-milestone code returns
  # normally here while signalling a failed-folds *warning*, and a condition
  # handler would catch that warning, unwind before the assignment completed,
  # and leave `result` NULL either way -- making the AC4 assertion below pass
  # against the very behaviour this test exists to reject.
  cnd <- tryCatch(
    without_pkgload_warning(
      result <- nested_tune_grid(
        wf,
        nested,
        grid = det_grid(),
        metrics = reg_metrics()
      )
    ),
    error = identity
  )

  expect_s3_class(cnd, "nestedtune_cancelled")
  expect_s3_class(cnd, "nestedtune_interrupted")
  # AC4: nothing partial escapes -- no results object is built from the folds
  # that happened to finish before the stop landed.
  expect_null(result)
  expect_identical(.Random.seed, before_seed)
  expect_identical(RNGkind(), before_kind)
})

test_that("BC6: a failed fold matches serially in every field but its traces", {
  skip_if_no_daemons()
  skip_if_not_installed("ranger")

  data <- make_reg_data()
  nested <- break_fold(det_nested(data), fold = 2L, stage = "inner tuning")
  wf <- stoch_workflow(data)

  # expect_warning() hands back the *condition*, never the expression's value
  # (M03 lesson) -- so the object is taken by assigning inside the expectation
  # rather than by running the fit a second time to fetch it. Muffling a warning
  # does not abort the expression, so `serial` is bound either way.
  set.seed(2026L)
  # tune raises its own "All models failed" warning alongside ours; catching
  # only the outer one leaves it to surface as an uncaught warning in the run.
  suppressWarnings(
    expect_warning(
      serial <- serial_run(nested_tune_grid(
        wf,
        nested,
        grid = stoch_grid(),
        metrics = reg_metrics()
      )),
      class = "nestedtune_failed_folds"
    )
  )
  expect_identical(last_dispatch(), "serial")

  shared_daemons(2)
  set.seed(2026L)
  parallel <- suppressWarnings(
    without_pkgload_warning(
      nested_tune_grid(wf, nested, grid = stoch_grid(), metrics = reg_metrics())
    )
  )
  expect_identical(last_dispatch(), "parallel")

  # Traces are rlang backtraces: a daemon's call stack is rooted in
  # mirai::daemon() and can never equal the host's, so they are outside the IP2
  # identity claim (M07-D3). Everything a user reads -- text, location, type --
  # is inside it.
  expect_identical(parallel$.completed, serial$.completed)
  expect_identical(parallel$.metrics, serial$.metrics)
  expect_identical(parallel$.selected, serial$.selected)
  expect_identical(parallel$.tuning_seed, serial$.tuning_seed)
  expect_identical(parallel$.outer_fit_seed, serial$.outer_fit_seed)

  # Note TEXT is compared with whitespace normalized, which departs from BC6's
  # literal "identical()" -- see the "Deviations from RR03" row in the milestone
  # file. cli hard-wraps a message to the console width of the process that
  # formats it, and a daemon's width is its own, so the same note arrives
  # wrapped at 80 columns in parallel and at the host's width serially. The
  # words are identical; only the line breaks differ. RR03 verified the text
  # matched, but its probe formatted both sides at the same width. cli's
  # bullet glyphs are the same kind of difference: a daemon has no UTF-8
  # console, so the info bullet tune's note carries arrives as `i` where the
  # host writes the glyph (the M59 fixture's zero-row note is the first with
  # one), and both spellings are read as the ASCII one.
  unwrap <- function(x) {
    gsub("[[:space:]]+", " ", gsub("\u2139", "i", x, fixed = TRUE))
  }
  for (i in seq_len(nrow(serial))) {
    s_notes <- serial$.notes[[i]]
    p_notes <- parallel$.notes[[i]]
    expect_identical(p_notes$location, s_notes$location)
    expect_identical(p_notes$type, s_notes$type)
    expect_identical(unwrap(p_notes$note), unwrap(s_notes$note))
  }
  expect_false(serial$.completed[[2L]])
})

test_that("BC6: the identity holds with param_info supplied (M34, AC4)", {
  skip_if_no_daemons()
  skip_if_not_installed("ranger")
  skip_if_not_installed("dials")

  data <- make_reg_data()
  nested <- det_nested(data)
  wf <- stoch_workflow(data)

  # An integer grid, so `param_info` is what the candidates are generated from.
  # With `stoch_grid()` the candidates travel in the grid itself and
  # `param_info` would ride along inert -- an identity that held whether or not
  # the argument reached a daemon at all.
  narrow <- update(
    tune::extract_parameter_set_dials(wf),
    min_n = dials::min_n(c(2L, 8L))
  )

  set.seed(2026L)
  serial <- serial_run(nested_tune_grid(
    wf,
    nested,
    param_info = narrow,
    grid = 3,
    metrics = reg_metrics()
  ))
  expect_identical(last_dispatch(), "serial")

  shared_daemons(2)
  set.seed(2026L)
  parallel <- without_pkgload_warning(
    nested_tune_grid(
      wf,
      nested,
      param_info = narrow,
      grid = 3,
      metrics = reg_metrics()
    )
  )

  expect_identical(last_dispatch(), "parallel")
  expect_identical(parallel, serial)

  # The restriction really is the one being carried across the boundary: a
  # `param_info` the daemons never saw would leave them generating candidates
  # from the default range, which reaches 40.
  expect_true(all(
    vapply(parallel$.selected, function(x) x$min_n, integer(1)) <= 8L
  ))
})

# AC5 (M35). The event level is the first setting the identity has to carry
# that changes a *reported metric value* rather than the candidate chosen:
# `.metrics` is fed by the `control_last_fit()` the outer scoring fit now
# receives, so a level dropped on the daemon path alone -- threaded into
# `fold_task()` but never reaching the worker -- shows up here. What this does
# not establish is which level is which: a level dropped on both paths
# preserves the identity exactly, and test-event-level.R is the anchor for
# that.

test_that("BC7: the identity holds with a two-class fixture at event_level = \"second\" (M35, AC5)", {
  skip_if_no_daemons()
  skip_if_not_installed("ranger")
  skip_if_no_engines(stochastic = TRUE)

  data <- cls_data()
  nested <- cls_nested(data)
  wf <- cls_workflow(data)

  set.seed(2026L)
  serial <- serial_run(nested_tune_grid(
    wf,
    nested,
    grid = cls_grid(),
    metrics = cls_metrics(),
    event_level = "second"
  ))
  expect_identical(last_dispatch(), "serial")

  shared_daemons(2)
  set.seed(2026L)
  parallel <- without_pkgload_warning(
    nested_tune_grid(
      wf,
      nested,
      grid = cls_grid(),
      metrics = cls_metrics(),
      event_level = "second"
    )
  )

  expect_identical(last_dispatch(), "parallel")
  # Every fold completed, so the identity below is between two runs that
  # produced metrics rather than two matching sets of failures.
  expect_true(all(serial$.completed))
  expect_true(all(parallel$.completed))
  expect_identical(parallel, serial)
})

# BC8 mirrors BC7 for the other argument this package forwards to tune: the
# evaluation time a censored-regression metric is measured at. What it adds
# beyond BC7 is the payload -- `eval_time` rides in `.args` alongside
# `event_level`, so a run whose wrapper dropped it would still complete and
# would still return a number, just tune's default one.

test_that("BC8: the identity holds with a censored fixture at a named eval_time (M41, AC5)", {
  skip_if_no_daemons()
  skip_if_no_censored()

  data <- srv_data()
  nested <- srv_nested(data)
  wf <- srv_workflow(data)
  eval_time <- srv_eval_times()[[2L]]

  set.seed(2026L)
  serial <- serial_run(nested_tune_grid(
    wf,
    nested,
    grid = srv_grid(),
    metrics = srv_metrics(),
    eval_time = eval_time
  ))
  expect_identical(last_dispatch(), "serial")

  shared_daemons(2)
  set.seed(2026L)
  parallel <- without_pkgload_warning(
    nested_tune_grid(
      wf,
      nested,
      grid = srv_grid(),
      metrics = srv_metrics(),
      eval_time = eval_time
    )
  )

  expect_identical(last_dispatch(), "parallel")
  expect_true(all(serial$.completed))
  expect_true(all(parallel$.completed))

  # The evaluation time survived the wire, not merely some evaluation time:
  # a dropped argument would leave tune to pick its own and these would be a
  # different number on both sides.
  for (i in seq_len(nrow(nested))) {
    expect_identical(serial$.metrics[[i]]$.eval_time, eval_time)
  }
  expect_identical(parallel, serial)
})
test_that("BC10: the Bayesian path matches serial at two daemons (M45, AC4)", {
  skip_if_no_daemons()
  skip_if_not_installed("ranger")
  skip_if_not_installed("dials")

  data <- make_reg_data()
  nested <- det_nested(data)
  wf <- stoch_workflow(data)
  p <- bayes_stoch_param_info(wf)

  serial <- bayes_serial_reference(wf, nested, p)

  shared_daemons(2)
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

test_that("BC11: the control reaches every fold on the parallel path as on the serial one (M48, AC2)", {
  skip_if_no_daemons()
  skip_if_not_installed("dials")

  # The AC1 run: a control whose `no_improve = 2` stops folds short of `iter`,
  # so a daemon that ran under tune's default would record more candidates
  # than the serial fold did. The deterministic fixture, as the AC1 oracle.
  data <- make_reg_data()
  nested <- det_nested(data)
  wf <- bayes_workflow(data)
  p <- bayes_param_info(wf)
  ctrl <- ac1_control()

  set.seed(2026L)
  serial <- serial_run(nested_tune_bayes(
    wf,
    nested,
    iter = 4,
    initial = 3,
    param_info = p,
    metrics = reg_metrics(),
    control = ctrl
  ))
  expect_identical(last_dispatch(), "serial")
  expect_true(all(serial$.completed))
  # The control is in force: some fold stopped early.
  expect_true(any(vapply(candidate_sets(serial), nrow, integer(1)) < 7L))

  shared_daemons(2)
  set.seed(2026L)
  parallel <- without_pkgload_warning(
    nested_tune_bayes(
      wf,
      nested,
      iter = 4,
      initial = 3,
      param_info = p,
      metrics = reg_metrics(),
      control = ctrl
    )
  )
  expect_identical(last_dispatch(), "parallel")

  # The fold records the criterion names, one by one, and then the object.
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
test_that("BC12: both racing paths match serial at two daemons (M50, AC4)", {
  skip_if_no_daemons()
  skip_if_no_race_fixture(stochastic = TRUE)

  data <- make_reg_data()
  nested <- det_nested(data)
  wf <- stoch_workflow(data)
  ms <- reg_metrics()
  ctrl <- race_control()

  for (fn in RACERS) {
    serial <- race_serial_reference(fn, wf, nested, ms, ctrl)

    shared_daemons(2)
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


test_that("BC13: the annealing path matches serial at two daemons (M51, AC4)", {
  skip_if_no_daemons()
  skip_if_no_anneal_fixture(stochastic = TRUE)

  data <- make_reg_data()
  nested <- det_nested(data)
  wf <- stoch_workflow(data)
  p <- bayes_stoch_param_info(wf)
  ms <- reg_metrics()
  ctrl <- anneal_control()

  serial <- anneal_serial_reference(wf, nested, p, ms, ctrl)

  shared_daemons(2)
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


# BC14 (M68, AC4): the two columns the outer fit keeps under `save_pred` and
# `extract` are identical between a serial run and a parallel one. The
# extract reads ranger's out-of-bag prediction error, a number the fold's
# seed decides, so the `.extracts` identity has a value to fail on. AC2's
# coefficient extract is not usable here: `coef()` of a ranger fit is NULL,
# and tune's inner run errors on a NULL extract ("attempt to set an attribute
# on NULL", tune 2.1.0, measured 2026-09-06), so every fold would fail before
# the outer fit.

test_that("BC14: the outer fit's predictions and extracts match serially and on two daemons (M68, AC4)", {
  skip_if_no_daemons()
  skip_if_not_installed("ranger")

  data <- make_reg_data()
  nested <- det_nested(data)
  wf <- stoch_workflow(data)

  # Over `baseenv()`, for coef_extract()'s reason.
  oob_extract <- rlang::new_function(
    rlang::pairlist2(x = ),
    quote(workflows::extract_fit_engine(x)$prediction.error),
    env = baseenv()
  )
  ctrl <- tune::control_grid(save_pred = TRUE, extract = oob_extract)

  set.seed(2026L)
  serial <- serial_run(nested_tune_grid(
    wf,
    nested,
    grid = stoch_grid(),
    metrics = reg_metrics(),
    control = ctrl
  ))
  expect_identical(last_dispatch(), "serial")
  expect_true(all(serial$.completed))
  expect_true(all(vapply(serial$.extracts, is.numeric, logical(1))))
  expect_true(all(vapply(serial$.predictions, is.data.frame, logical(1))))

  shared_daemons(2)
  set.seed(2026L)
  parallel <- without_pkgload_warning(nested_tune_grid(
    wf,
    nested,
    grid = stoch_grid(),
    metrics = reg_metrics(),
    control = ctrl
  ))

  expect_identical(last_dispatch(), "parallel")
  expect_true(all(parallel$.completed))
  expect_identical(parallel$.predictions, serial$.predictions)
  expect_identical(parallel$.extracts, serial$.extracts)
  expect_identical(parallel, serial)
})


# BC15 (M69, AC5): the selection rule reaches every fold on the parallel path
# as on the serial one. The percent-loss rule with a non-default limit and a
# two-term ordering with desc(), on the two-parameter fixture, so the rule has
# something to order and the wire carries orderings and a limit rather than
# the default object; on this fixture the rule picks a candidate the default
# does not in a fold (test-nested-tune-grid-oracles.R, O5), so a daemon that
# fell back to the default rule would differ.

test_that("BC15: the selection rule reaches the folds on two daemons as serially (M69, AC5)", {
  skip_if_no_daemons()
  skip_if_not_installed("dials")

  data <- make_reg_data()
  nested <- det_nested(data)
  wf <- bayes_workflow(data)
  p <- bayes_param_info(wf)
  g <- expand.grid(df1 = c(2L, 5L, 8L), df2 = c(2L, 5L, 8L))
  rule <- selection_rule("pct_loss", desc(df1), df2, limit = 5)

  set.seed(2026L)
  serial <- serial_run(nested_tune_grid(
    wf,
    nested,
    grid = g,
    metrics = reg_metrics(),
    param_info = p,
    select = rule
  ))
  expect_identical(last_dispatch(), "serial")
  expect_true(all(serial$.completed))
  expect_identical(extract_procedure(serial)$select, rule)

  shared_daemons(2)
  set.seed(2026L)
  parallel <- without_pkgload_warning(nested_tune_grid(
    wf,
    nested,
    grid = g,
    metrics = reg_metrics(),
    param_info = p,
    select = rule
  ))

  expect_identical(last_dispatch(), "parallel")
  expect_true(all(parallel$.completed))
  expect_identical(parallel$.selected, serial$.selected)
  expect_identical(parallel, serial)
})

# BC16 (M70, AC6): the plain resampling path matches serial on two daemons.
# ranger with every parameter fixed, so the outer fit draws from the stream
# and a daemon that ran the fold under another seed, or ran an inner stage
# at all, would differ; the tuner needs no package beyond tune, which every
# daemon already holds through the namespace load.

test_that("BC16: the plain resampling path matches serial on two daemons (M70, AC6)", {
  skip_if_no_daemons()
  skip_if_not_installed("ranger")

  data <- make_reg_data()
  nested <- det_nested(data)
  wf <- fixed_stoch_workflow(data)
  ms <- reg_metrics()

  set.seed(2026L)
  serial <- serial_run(nested_fit_resamples(wf, nested, metrics = ms))
  expect_identical(last_dispatch(), "serial")
  expect_true(all(serial$.completed))
  expect_identical(extract_procedure(serial)$tuner, "fit_resamples")

  shared_daemons(2)
  set.seed(2026L)
  parallel <- without_pkgload_warning(
    nested_fit_resamples(wf, nested, metrics = ms)
  )

  expect_identical(last_dispatch(), "parallel")
  expect_true(all(parallel$.completed))
  expect_identical(parallel$.metrics, serial$.metrics)
  expect_identical(parallel$.selected, serial$.selected)
  expect_identical(parallel, serial)
})

# BC17 (M71, AC2): the workflow-set map matches serial on two daemons. The
# grid orchestrator on the mixed two-workflow fixture, every fold completing,
# so each element's folds ran one parallel round per workflow under the
# entry state the map reinstated; a daemon that ran a workflow's fold under
# another seed, or the map handing the second workflow a state the first
# had advanced, would differ.

test_that("BC17: the workflow-set map matches serial on two daemons (M71, AC2)", {
  skip_if_no_daemons()
  skip_if_not_installed("workflowsets")
  skip_if_no_engines()

  data <- make_reg_data()
  set.seed(31)
  wset <- wset_two(data)
  nested <- det_nested(data)
  ms <- reg_metrics()

  set.seed(2026L)
  serial <- serial_run(nested_workflow_map(
    wset,
    resamples = nested,
    grid = det_grid(),
    metrics = ms
  ))
  expect_identical(last_dispatch(), "serial")
  for (r in serial$result) {
    expect_true(all(r$.completed))
  }

  shared_daemons(2)
  set.seed(2026L)
  parallel <- without_pkgload_warning(
    nested_workflow_map(
      wset,
      resamples = nested,
      grid = det_grid(),
      metrics = ms
    )
  )

  expect_identical(last_dispatch(), "parallel")
  for (i in seq_along(parallel$result)) {
    expect_true(all(parallel$result[[i]]$.completed))
    expect_identical(parallel$result[[i]]$.metrics, serial$result[[i]]$.metrics)
  }
  expect_identical(parallel, serial)
})

# BC9 is the last block on the shared 2-daemon pool (M74): it dirties every
# daemon on purpose, and the pool is replaced by the 3-daemon one below
# before any other block runs.

test_that("BC9: a fold is immune to whatever a daemon ran before it", {
  skip_if_no_daemons()
  skip_if_not_installed("ranger")

  data <- make_reg_data()
  nested <- det_nested(data)
  wf <- stoch_workflow(data)

  shared_daemons(2)
  set.seed(2026L)
  fresh <- without_pkgload_warning(
    nested_tune_grid(wf, nested, grid = stoch_grid(), metrics = reg_metrics())
  )

  # Pollute every daemon -- the same daemons that just ran `fresh`: a
  # different generator triple including the legacy Rounding sample kind,
  # consumed draws, and global scribbles shadowing the names the worker uses.
  # The pin covers all three kind components, and mirai_map() passes
  # arguments rather than globals, so none of it can reach a fold's numbers.
  mirai::everywhere({
    RNGkind("Knuth-TAOCP-2002", "Box-Muller", "Rounding")
    set.seed(1234)
    invisible(runif(10000))
    object <- "scribble"
    payload <- "scribble"
    seeds <- "scribble"
  })

  set.seed(2026L)
  polluted <- without_pkgload_warning(
    nested_tune_grid(wf, nested, grid = stoch_grid(), metrics = reg_metrics())
  )
  expect_identical(last_dispatch(), "parallel")
  expect_identical(polluted, fresh)
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
