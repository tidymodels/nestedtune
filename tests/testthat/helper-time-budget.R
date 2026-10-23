# What the daemon tests are allowed to wait for, declared.
#
# The problem this exists to make visible. `test-parallel-classify.R` typically
# runs in 12.0 s (benchmarks/test-timing-baseline.md), while its declared waits
# can permit far more. A wedge and a file running its own worst case are
# indistinguishable from the outside -- so the worst case is written down
# here, and kept smaller than the CI cap.
#
# THE SUMMING CONVENTION, which is a decision and not an accident: each wait
# contributes ITS OWN declared seconds. An enclosing `setTimeLimit()` never
# caps that contribution, because `setTimeLimit()` does not interrupt a
# blocked mirai wait (established by execution) -- it
# is not a bound on the path that actually stalls, and crediting it would
# flatter every total here exactly where the flattery is unsafe. Those calls get
# rows carrying 0 seconds so the guard can see they were classified, never
# because they are free.
#
# A call that does no waiting also gets a 0-second row rather than no row:
# `check_daemons_can_load(status)` on a fabricated `preflight_outcome()`
# classifies an answer already in hand and dispatches nothing. Recording it is
# what makes `test-suite-hygiene.R`'s guard able to insist that EVERY wait-shaped
# call is accounted for -- a new one cannot land silently by looking like the
# many harmless ones.
#
# HOW A ROW'S SECONDS ARE KEPT HONEST, which is two different mechanisms.
#
# Rows whose bound lives in helper-parallel.R read the constant itself --
# COLLECT_BOUNDED_DEFAULT_S, START_DAEMONS_BOUND_S(), MIXED_DAEMONS_BOUND_S --
# so cutting a bound there moves the ledger with it and those cannot drift.
#
# The rest carry a literal copied from an explicit argument at the call site
# (`daemons_load_status(timeout = 1000L)` and friends), and a copy can drift:
# raising the real argument while leaving the row alone would leave every guard
# green and the printed total unchanged. So `test-suite-hygiene.R` re-reads each
# such argument from the source and fails when the row disagrees.
#
# What that cross-check cannot reach is declared here rather than left
# implicit. Three kinds escape it: a bound read from a named constant, which
# cannot drift and needs no re-read; a bound set through the OPTION at one line
# and spent at another (in classify's "the probe reads its bound from the
# option, not from the constant", `options()` sets it and
# `daemons_load_status()` spends it); and a wait that
# is no function call at all (the deadline poll in interrupt). None carries an
# explicit bound argument in the call itself, which is exactly how the
# cross-check recognises them.
#
# Those exemptions are DECLARED and asserted, not merely described here.
# `test-suite-hygiene.R` keeps the list as DECLARED_UNCHECKABLE_BOUNDS and fails
# when the set of rows it could not re-read differs from it -- so a fourth
# exemption has to be argued for rather than acquired by writing a call the
# regex cannot parse.

# One site's worst case: what it waits for, times the number of times the
# surrounding code runs it. `times` is 1 unless a loop says otherwise -- the
# shared_daemons() call in test-parallel-identity.R's "both racing paths match
# serial at two daemons" sits inside `for (fn in RACERS)` and is therefore paid
# twice. It is the ledger's only row carrying a `times` above 1;
# `grep -n 'times = [0-9]' tests/testthat/helper-time-budget.R` lists every row
# that sets the argument, `tb_row()`'s own default included, so a row added at
# any other count shows up there rather than going unread.
#
# A row names its site by `file`, `payer` and `at`, and by no line number.
# `payer` is the exact description of the `test_that()` block that holds the
# call, or the name of the top-level function for the helper-parallel.R rows.
# `at` is the call's place among the wait calls of that unit, counted in source
# order. It is NA for a row whose `call` is not one of the wait calls that
# `test-suite-hygiene.R` finds, which matches rows to calls on all three.
tb_row <- function(file, at, call, seconds, payer, times = 1L, note = "") {
  data.frame(
    file = file,
    at = at,
    call = call,
    seconds = seconds * times,
    times = times,
    payer = payer,
    note = note,
    stringsAsFactors = FALSE
  )
}

# start_daemons() waits twice over: once priming the daemons and once warming
# them. Neither is visible at the call site, so a reader of a test file cannot
# see either wait there.
START_DAEMONS_BOUND_S <- function() PRIME_DAEMONS_BOUND_S + WARM_DAEMONS_BOUND_S

# The suite-wide option (PREFLIGHT_TEST_TIMEOUT_MS) is charged to no file below,
# because every probe in these files passes an explicit `timeout` or sets the
# option itself. It remains as the backstop a future call would inherit, which
# hides that call's wait from its file, so a new call relying on it must be
# charged here.

time_budget_ledger <- function() {
  rbind(
    # --- test-parallel-classify.R -------------------------------------------
    tb_row(
      "test-parallel-classify.R",
      1L,
      "collect_bounded",
      COLLECT_BOUNDED_DEFAULT_S,
      "a miraiError becomes a recorded worker failure, not an abort"
    ),
    tb_row(
      "test-parallel-classify.R",
      1L,
      "setTimeLimit",
      0,
      "a connected daemon that cannot answer in time is bounded",
      note = "not a bound on a blocked mirai wait"
    ),
    tb_row(
      "test-parallel-classify.R",
      2L,
      "setTimeLimit",
      0,
      "a connected daemon that cannot answer in time is bounded",
      note = "restore"
    ),
    tb_row(
      "test-parallel-classify.R",
      3L,
      "daemons_load_status",
      1,
      "a connected daemon that cannot answer in time is bounded",
      note = "explicit timeout = 1000L"
    ),
    tb_row(
      "test-parallel-classify.R",
      1L,
      "setTimeLimit",
      0,
      "a pool with no daemon at all is a non-response, not a load failure",
      note = "not a bound on a blocked mirai wait"
    ),
    tb_row(
      "test-parallel-classify.R",
      2L,
      "setTimeLimit",
      0,
      "a pool with no daemon at all is a non-response, not a load failure",
      note = "restore"
    ),
    tb_row(
      "test-parallel-classify.R",
      3L,
      "daemons_load_status",
      2,
      "a pool with no daemon at all is a non-response, not a load failure",
      note = "explicit timeout = 2000L"
    ),
    tb_row(
      "test-parallel-classify.R",
      4L,
      "check_daemons_can_load",
      0,
      "a pool with no daemon at all is a non-response, not a load failure",
      note = "status already in hand"
    ),
    tb_row(
      "test-parallel-classify.R",
      1L,
      "check_daemons_can_load",
      0,
      "a pool where every daemon loaded passes",
      note = "fabricated status"
    ),
    tb_row(
      "test-parallel-classify.R",
      1L,
      "check_daemons_can_load",
      0,
      "one loadable daemon no longer passes the check for the whole pool",
      note = "fabricated status"
    ),
    tb_row(
      "test-parallel-classify.R",
      1L,
      "check_daemons_can_load",
      0,
      "a load failure keeps the install and prime remedies",
      note = "fabricated status"
    ),
    tb_row(
      "test-parallel-classify.R",
      1L,
      "check_daemons_can_load",
      0,
      "a timeout is not reported as a package that cannot be loaded",
      note = "fabricated status"
    ),
    tb_row(
      "test-parallel-classify.R",
      1L,
      "check_daemons_can_load",
      0,
      "the timeout message points at the option that raises the bound",
      note = "fabricated status"
    ),
    tb_row(
      "test-parallel-classify.R",
      1L,
      "check_daemons_can_load",
      0,
      "a raised bound is reported as a number, not in scientific notation",
      note = "fabricated status"
    ),
    tb_row(
      "test-parallel-classify.R",
      1L,
      "check_daemons_can_load",
      0,
      "a pool failing both ways names both facts",
      note = "fabricated status"
    ),
    tb_row(
      "test-parallel-classify.R",
      1L,
      "check_daemons_can_load",
      0,
      "a pool that cannot load AND holds an old build names both fixes",
      note = "fabricated status"
    ),
    tb_row(
      "test-parallel-classify.R",
      2L,
      "check_daemons_can_load",
      0,
      "a pool that cannot load AND holds an old build names both fixes",
      note = "fabricated status; the bullet's absence"
    ),
    tb_row(
      "test-parallel-classify.R",
      1L,
      "check_daemons_can_load",
      0,
      "the both-fault bullet counts and pluralises on the affected daemons",
      note = "fabricated status"
    ),
    tb_row(
      "test-parallel-classify.R",
      1L,
      "check_daemons_can_load",
      0,
      "both causes answer to one shared class",
      note = "fabricated status"
    ),
    tb_row(
      "test-parallel-classify.R",
      1L,
      "check_daemons_can_load",
      0,
      "the incompatible abort names the symbols, the count, and the restart",
      note = "fabricated status; classifies, never dispatches"
    ),
    tb_row(
      "test-parallel-classify.R",
      1L,
      "check_daemons_can_load",
      0,
      "the incompatible abort renders at one symbol, two, five, and a mixed pool",
      note = "fabricated status; snapshot, one symbol"
    ),
    tb_row(
      "test-parallel-classify.R",
      2L,
      "check_daemons_can_load",
      0,
      "the incompatible abort renders at one symbol, two, five, and a mixed pool",
      note = "fabricated status; snapshot, two symbols"
    ),
    tb_row(
      "test-parallel-classify.R",
      3L,
      "check_daemons_can_load",
      0,
      "the incompatible abort renders at one symbol, two, five, and a mixed pool",
      note = "fabricated status; snapshot, truncated case"
    ),
    tb_row(
      "test-parallel-classify.R",
      4L,
      "check_daemons_can_load",
      0,
      "the incompatible abort renders at one symbol, two, five, and a mixed pool",
      note = "fabricated status; snapshot, mixed pool"
    ),
    tb_row(
      "test-parallel-classify.R",
      1L,
      "check_daemons_can_load",
      0,
      "an incompatible pool answers to the shared unusable class",
      note = "fabricated status"
    ),
    tb_row(
      "test-parallel-classify.R",
      1L,
      "check_daemons_can_load",
      0,
      "an incompatible pool still reports daemons that said nothing",
      note = "fabricated status"
    ),
    tb_row(
      "test-parallel-classify.R",
      1L,
      "start_daemons",
      START_DAEMONS_BOUND_S(),
      "the probe reads its bound from the option, not from the constant"
    ),
    tb_row(
      "test-parallel-classify.R",
      2L,
      "setTimeLimit",
      0,
      "the probe reads its bound from the option, not from the constant",
      note = "not a bound on a blocked mirai wait"
    ),
    tb_row(
      "test-parallel-classify.R",
      3L,
      "setTimeLimit",
      0,
      "the probe reads its bound from the option, not from the constant",
      note = "restore"
    ),
    tb_row(
      "test-parallel-classify.R",
      4L,
      "daemons_load_status",
      45.678,
      "the probe reads its bound from the option, not from the constant",
      note = "the test sets the option to 45678 ms before the call"
    ),
    tb_row(
      "test-parallel-classify.R",
      1L,
      "daemons_load_status",
      0,
      "a bad bound is refused before any daemon is asked",
      note = "the option is invalid, so it aborts before dispatching"
    ),
    tb_row(
      "test-parallel-classify.R",
      1L,
      "check_daemons_can_load",
      0,
      "a probe that reached no daemon at all is not a pass",
      note = "fabricated status"
    ),
    tb_row(
      "test-parallel-classify.R",
      1L,
      "check_daemons_can_load",
      0,
      "the abort names the package actually probed",
      note = "fabricated status"
    ),

    # --- test-parallel-classify.R, the package rung --------------------------
    #
    # Every check_daemons_can_load() below classifies a fabricated
    # preflight_outcome() already in hand and dispatches nothing; the two
    # daemons_load_status() calls carry an explicit bound.
    tb_row(
      "test-parallel-classify.R",
      1L,
      "check_daemons_can_load",
      0,
      "the missing-package abort names the count, the packages, and the install-then-restart remedy",
      note = "status already in hand"
    ),
    tb_row(
      "test-parallel-classify.R",
      1L,
      "check_daemons_can_load",
      0,
      "a missing package beside a daemon that cannot load is named by the load abort",
      note = "status already in hand"
    ),
    tb_row(
      "test-parallel-classify.R",
      2L,
      "check_daemons_can_load",
      0,
      "a missing package beside a daemon that cannot load is named by the load abort",
      note = "status already in hand"
    ),
    tb_row(
      "test-parallel-classify.R",
      1L,
      "check_daemons_can_load",
      0,
      "a missing package beside an incompatible build is named by the package abort",
      note = "status already in hand"
    ),
    tb_row(
      "test-parallel-classify.R",
      1L,
      "check_daemons_can_load",
      0,
      "a missing package beside a silent daemon is named by the package abort",
      note = "status already in hand"
    ),
    tb_row(
      "test-parallel-classify.R",
      1L,
      "check_daemons_can_load",
      0,
      "the package abort pluralises on the daemon count and the package count separately",
      note = "status already in hand"
    ),
    tb_row(
      "test-parallel-classify.R",
      2L,
      "check_daemons_can_load",
      0,
      "the package abort pluralises on the daemon count and the package count separately",
      note = "status already in hand"
    ),
    # --- test-parallel-detection.R, the package rung ------------------------
    tb_row(
      "test-parallel-detection.R",
      1L,
      "start_daemons",
      START_DAEMONS_BOUND_S(),
      "the probe sends the package list, and a daemon that has them all reports none"
    ),
    tb_row(
      "test-parallel-detection.R",
      2L,
      "daemons_load_status",
      30,
      "the probe sends the package list, and a daemon that has them all reports none",
      note = "explicit timeout = 30000"
    ),
    tb_row(
      "test-parallel-detection.R",
      3L,
      "daemons_load_status",
      30,
      "the probe sends the package list, and a daemon that has them all reports none",
      note = "explicit timeout = 30000"
    ),
    tb_row(
      "test-parallel-detection.R",
      1L,
      "setTimeLimit",
      0,
      "a heterogeneous pool names the daemon that lacks a needed package",
      note = "not a bound on a blocked mirai wait"
    ),
    tb_row(
      "test-parallel-detection.R",
      2L,
      "setTimeLimit",
      0,
      "a heterogeneous pool names the daemon that lacks a needed package",
      note = "restore"
    ),
    tb_row(
      "test-parallel-detection.R",
      3L,
      "start_mixed_daemons",
      60,
      "a heterogeneous pool names the daemon that lacks a needed package",
      note = "its own `timeout` default"
    ),
    tb_row(
      "test-parallel-detection.R",
      4L,
      "daemons_load_status",
      30,
      "a heterogeneous pool names the daemon that lacks a needed package",
      note = "explicit timeout = 30000"
    ),
    tb_row(
      "test-parallel-detection.R",
      5L,
      "check_daemons_can_load",
      0,
      "a heterogeneous pool names the daemon that lacks a needed package",
      note = "status already in hand"
    ),
    # --- test-parallel-detection.R ------------------------------------------
    tb_row(
      "test-parallel-detection.R",
      1L,
      "setTimeLimit",
      0,
      "the probe reaches every daemon, not just a loadable one",
      note = "not a bound on a blocked mirai wait"
    ),
    tb_row(
      "test-parallel-detection.R",
      2L,
      "setTimeLimit",
      0,
      "the probe reaches every daemon, not just a loadable one",
      note = "restore"
    ),
    tb_row(
      "test-parallel-detection.R",
      3L,
      "start_mixed_daemons",
      60,
      "the probe reaches every daemon, not just a loadable one",
      note = "its own `timeout` default"
    ),
    tb_row(
      "test-parallel-detection.R",
      4L,
      "collect_bounded",
      30,
      "the probe reaches every daemon, not just a loadable one"
    ),
    tb_row(
      "test-parallel-detection.R",
      5L,
      "daemons_load_status",
      30,
      "the probe reaches every daemon, not just a loadable one",
      note = "explicit timeout = 30000"
    ),
    tb_row(
      "test-parallel-detection.R",
      6L,
      "check_daemons_can_load",
      0,
      "the probe reaches every daemon, not just a loadable one",
      note = "status already in hand"
    ),
    tb_row(
      "test-parallel-detection.R",
      1L,
      "start_daemons_undispatched",
      START_DAEMONS_BOUND_S(),
      "a run on an uncancellable pool warns exactly once"
    ),
    tb_row(
      "test-parallel-detection.R",
      1L,
      "start_daemons",
      START_DAEMONS_BOUND_S(),
      "a dispatcher-backed run warns not at all"
    ),
    tb_row(
      "test-parallel-detection.R",
      1L,
      "start_daemons",
      START_DAEMONS_BOUND_S(),
      "a symbol no build defines is reported by every daemon that loaded"
    ),
    tb_row(
      "test-parallel-detection.R",
      2L,
      "daemons_load_status",
      30,
      "a symbol no build defines is reported by every daemon that loaded",
      note = "explicit timeout = 30000"
    ),
    tb_row(
      "test-parallel-detection.R",
      3L,
      "check_daemons_can_load",
      0,
      "a symbol no build defines is reported by every daemon that loaded",
      note = "status already in hand"
    ),
    # The one test that starts its pools with bare `mirai::daemons()` rather
    # than through a budgeted helper, because it compares the two POOL KINDS and
    # priming is orthogonal to the property under test -- routing it through
    # start_daemons() would buy nothing and charge this file two more prime and
    # warm bounds. `daemons` is not among BUDGETED_WAIT_CALLS, so the guard
    # cannot see the two pool starts below, nor the three `daemons(0)` calls
    # beside them (the `on.exit()` teardown and two resets between kinds);
    # the starts are rowed here so the file's account is complete rather than
    # complete-looking, which is the same disclosure the test-parallel-metrics.R
    # block below makes for its own `daemons(0)` calls.
    #
    # 0 seconds, and measured rather than assumed (mirai 2.7.2):
    # `daemons(2)` returned in 0.635 s, `daemons(2, dispatcher = FALSE)` in
    # 0.224 s, `daemons(0)` in 0.205 s, with `status()$connections` already
    # reading 2. None waits on a mirai result, so none has a bound to declare.
    tb_row(
      "test-parallel-detection.R",
      NA_integer_,
      "daemons",
      0,
      "the two pool kinds are distinguishable, and the count cannot do it",
      note = "bare mirai::daemons(2); returns without waiting, measured 0.635 s"
    ),
    tb_row(
      "test-parallel-detection.R",
      NA_integer_,
      "daemons",
      0,
      "the two pool kinds are distinguishable, and the count cannot do it",
      note = "bare mirai::daemons(2, dispatcher = FALSE), measured 0.224 s"
    ),

    # --- test-parallel-identity.R -------------------------------------------
    # Three pool starts per run: the shared 2-daemon pool, the shared 3-daemon
    # pool, and a private one for the block that kills a daemon. Every other
    # block but the one whose worker count is fabricated reuses a shared pool
    # through `shared_daemons()`, whose one wait is the snapshot round trip it
    # compares against the start (DAEMON_SNAPSHOT_BOUND_S, read from the
    # constant); `share_daemons()` takes the start snapshot on the same bound,
    # and the RNG-kind block's `daemon_rng_kinds()` is one more round trip.
    tb_row(
      "test-parallel-identity.R",
      1L,
      "start_daemons",
      START_DAEMONS_BOUND_S(),
      "the shared 2-daemon pool starts primed"
    ),
    tb_row(
      "test-parallel-identity.R",
      2L,
      "share_daemons",
      DAEMON_SNAPSHOT_BOUND_S,
      "the shared 2-daemon pool starts primed"
    ),
    tb_row(
      "test-parallel-identity.R",
      1L,
      "shared_daemons",
      DAEMON_SNAPSHOT_BOUND_S,
      "parallel matches serial at two daemons"
    ),
    tb_row(
      "test-parallel-identity.R",
      1L,
      "shared_daemons",
      DAEMON_SNAPSHOT_BOUND_S,
      "identity holds under a caller kind that is neither MT nor L'Ecuyer"
    ),
    tb_row(
      "test-parallel-identity.R",
      2L,
      "daemon_rng_kinds",
      DAEMON_SNAPSHOT_BOUND_S,
      "identity holds under a caller kind that is neither MT nor L'Ecuyer"
    ),
    tb_row(
      "test-parallel-identity.R",
      1L,
      "shared_daemons",
      DAEMON_SNAPSHOT_BOUND_S,
      "the caller's RNG state and kind survive a parallel run"
    ),
    tb_row(
      "test-parallel-identity.R",
      1L,
      "shared_daemons",
      DAEMON_SNAPSHOT_BOUND_S,
      "a cancelled parallel run returns nothing and restores the RNG state"
    ),
    tb_row(
      "test-parallel-identity.R",
      2L,
      "setTimeLimit",
      0,
      "a cancelled parallel run returns nothing and restores the RNG state",
      note = "not a bound on a blocked mirai wait"
    ),
    tb_row(
      "test-parallel-identity.R",
      3L,
      "setTimeLimit",
      0,
      "a cancelled parallel run returns nothing and restores the RNG state",
      note = "restore"
    ),
    tb_row(
      "test-parallel-identity.R",
      1L,
      "shared_daemons",
      DAEMON_SNAPSHOT_BOUND_S,
      "a failed fold matches serially in every field but its traces"
    ),
    tb_row(
      "test-parallel-identity.R",
      1L,
      "shared_daemons",
      DAEMON_SNAPSHOT_BOUND_S,
      "the identity holds with a two-class fixture at event_level = \"second\""
    ),
    tb_row(
      "test-parallel-identity.R",
      1L,
      "shared_daemons",
      DAEMON_SNAPSHOT_BOUND_S,
      "the identity holds with a censored fixture at a named eval_time"
    ),
    tb_row(
      "test-parallel-identity.R",
      1L,
      "shared_daemons",
      DAEMON_SNAPSHOT_BOUND_S,
      "the Bayesian path matches serial at two daemons"
    ),
    tb_row(
      "test-parallel-identity.R",
      1L,
      "shared_daemons",
      DAEMON_SNAPSHOT_BOUND_S,
      "param_info, control and select reach the folds on two daemons as serially"
    ),
    tb_row(
      "test-parallel-identity.R",
      1L,
      "shared_daemons",
      DAEMON_SNAPSHOT_BOUND_S,
      "both racing paths match serial at two daemons",
      times = 2L,
      note = "inside for (fn in RACERS)"
    ),
    tb_row(
      "test-parallel-identity.R",
      1L,
      "shared_daemons",
      DAEMON_SNAPSHOT_BOUND_S,
      "the annealing path matches serial at two daemons"
    ),
    tb_row(
      "test-parallel-identity.R",
      1L,
      "shared_daemons",
      DAEMON_SNAPSHOT_BOUND_S,
      "the outer fit's predictions and extracts match serially and on two daemons"
    ),
    tb_row(
      "test-parallel-identity.R",
      1L,
      "shared_daemons",
      DAEMON_SNAPSHOT_BOUND_S,
      "the plain resampling path matches serial on two daemons"
    ),
    tb_row(
      "test-parallel-identity.R",
      1L,
      "shared_daemons",
      DAEMON_SNAPSHOT_BOUND_S,
      "the workflow-set map matches serial on two daemons"
    ),
    tb_row(
      "test-parallel-identity.R",
      1L,
      "shared_daemons",
      DAEMON_SNAPSHOT_BOUND_S,
      "a fold is immune to whatever a daemon ran before it",
      note = "pollutes the shared pool in place; last block on it"
    ),
    tb_row(
      "test-parallel-identity.R",
      1L,
      "start_daemons",
      START_DAEMONS_BOUND_S(),
      "the shared 3-daemon pool starts primed"
    ),
    tb_row(
      "test-parallel-identity.R",
      2L,
      "share_daemons",
      DAEMON_SNAPSHOT_BOUND_S,
      "the shared 3-daemon pool starts primed"
    ),
    tb_row(
      "test-parallel-identity.R",
      1L,
      "shared_daemons",
      DAEMON_SNAPSHOT_BOUND_S,
      "parallel matches serial at three daemons"
    ),
    tb_row(
      "test-parallel-identity.R",
      1L,
      "start_daemons",
      START_DAEMONS_BOUND_S(),
      "a daemon killed mid-run yields a recorded failure, not an abort",
      note = "a private pool: the block kills one of its daemons"
    ),

    # --- test-parallel-metrics.R --------------------------------------------
    # One pool start, and that is the whole file's declared waiting. The two
    # `mirai::daemons(0)` calls beside it (the `on.exit()` teardown and the
    # reset before the serial reference) are not among BUDGETED_WAIT_CALLS and get no row:
    # `daemons(0)` measured returning in ~0.2 s with a live task outstanding --
    # it orphans rather than blocks -- so there is no bound to declare. They are
    # named here because the guard cannot see them, which is the same
    # disclosure the option/deadline-poll gap above makes.
    tb_row(
      "test-parallel-metrics.R",
      1L,
      "start_daemons",
      START_DAEMONS_BOUND_S(),
      "the metric set the caller gave reaches folds running on a worker"
    ),
    tb_row(
      "test-parallel-payload.R",
      1L,
      "start_daemons",
      START_DAEMONS_BOUND_S(),
      "a daemon receives the payload the serial branch would have passed"
    ),

    # --- test-parallel-required-pkgs.R --------------------------------------
    # One pool start and one bounded read, the read charged once even though the
    # test calls `attached()` twice: both calls are the same `collect_bounded()`
    # site, and the ledger rows sites rather than executions -- the same
    # convention every helper-side row above follows. The file's
    # `mirai::daemons(0)` teardowns get no row for the reason the metrics block
    # states.
    tb_row(
      "test-parallel-required-pkgs.R",
      1L,
      "start_daemons",
      START_DAEMONS_BOUND_S(),
      "a recipe selector the caller left unqualified resolves on a daemon"
    ),
    tb_row(
      "test-parallel-required-pkgs.R",
      2L,
      "collect_bounded",
      30,
      "a recipe selector the caller left unqualified resolves on a daemon",
      note = "explicit seconds = 30; one site, called twice"
    ),
    tb_row(
      "test-parallel-required-pkgs.R",
      1L,
      "start_daemons",
      START_DAEMONS_BOUND_S(),
      "a racing run attaches finetune and the race's model package in every daemon"
    ),
    tb_row(
      "test-parallel-required-pkgs.R",
      2L,
      "collect_bounded",
      30,
      "a racing run attaches finetune and the race's model package in every daemon",
      note = "explicit seconds = 30; one site, called twice"
    ),

    # --- test-parallel-interrupt.R ------------------------------------------
    tb_row(
      "test-parallel-interrupt.R",
      1L,
      "start_daemons",
      START_DAEMONS_BOUND_S(),
      "an interrupted run leaves no fold executing"
    ),
    tb_row(
      "test-parallel-interrupt.R",
      NA_integer_,
      "deadline poll",
      15,
      "an interrupted run leaves no fold executing",
      note = "while (executing() > 0L && Sys.time() < deadline)"
    ),
    tb_row(
      "test-parallel-interrupt.R",
      1L,
      "start_daemons",
      START_DAEMONS_BOUND_S(),
      "a run that finished normally is unharmed by the cancel on the way out"
    ),

    # --- helper-parallel.R --------------------------------------------------
    # The two waits inside start_daemons(), carried at 0 here because they are
    # already counted at every start_daemons() CALL SITE above -- charging them
    # again here would double-count. They get rows anyway so the guard sees them
    # classified rather than absent, which is the whole discipline: a wait is
    # either budgeted somewhere or it is a finding.
    tb_row(
      "helper-parallel.R",
      1L,
      "collect_bounded",
      0,
      "prime_daemons()",
      note = "PRIME_DAEMONS_BOUND_S, counted at each start_daemons() site"
    ),
    tb_row(
      "helper-parallel.R",
      1L,
      "collect_bounded",
      0,
      "warm_daemons()",
      note = "WARM_DAEMONS_BOUND_S, counted at each start_daemons() site"
    ),
    tb_row(
      "helper-parallel.R",
      1L,
      "collect_bounded",
      0,
      "daemon_state_snapshot()",
      note = "DAEMON_SNAPSHOT_BOUND_S, counted at each share_daemons() and shared_daemons() site"
    ),
    tb_row(
      "helper-parallel.R",
      1L,
      "collect_bounded",
      0,
      "daemon_rng_kinds()",
      note = "DAEMON_SNAPSHOT_BOUND_S, counted at its call site"
    )
  )
}

time_budget_totals <- function(ledger = time_budget_ledger()) {
  totals <- stats::aggregate(seconds ~ file, data = ledger, FUN = sum)
  totals[order(-totals$seconds), , drop = FALSE]
}

# The ceiling on test-parallel-classify.R, the one file a CI stall has been
# traced to. The other three daemon files are recorded without one.
CLASSIFY_BUDGET_CEILING_S <- 480

# What the same ledger totalled before its waits were first cut, so the
# reduction is a measured figure rather than a remembered one.
# benchmarks/test-time-budget.R prints it beside the current total.
CLASSIFY_BUDGET_BEFORE_CUT_S <- 1008.678

# The ceiling on test-parallel-metrics.R, set at the file's one pool start plus
# a margin. A new file is cheaper to hold to a bound from the start than to cut
# back later, and 30 s of headroom is one more bounded
# wait before the guard asks whether it belongs.
METRICS_BUDGET_CEILING_S <- 150
