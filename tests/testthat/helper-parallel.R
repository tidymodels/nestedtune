# Daemon fixtures for the parallel tests.
#
# Daemons are separate R processes and load nestedtune from an installed
# library. Under devtools/pkgload there may be no installed copy at all -- and
# worse, there may be a *stale* one, in which case daemons quietly run old code
# while the host runs the code under test (RR03 Q5). Priming the daemons with
# pkgload closes both holes; under R CMD check the package is installed and the
# daemons inherit the library through the environment, so priming is a no-op.

# The suite's wait bounds, named rather than scattered as literals.
#
# `helper-time-budget.R` reads these to total each file's declared worst case,
# so a bound cut here moves the ledger with it and the two cannot drift (M16 T2).
# Every one of them is a worst case, not an expectation: the daemon files
# typically finish in seconds and only a degraded runner approaches these.
COLLECT_BOUNDED_DEFAULT_S <- 60
PRIME_DAEMONS_BOUND_S <- 60
WARM_DAEMONS_BOUND_S <- 60
PREFLIGHT_TEST_TIMEOUT_MS <- 120000L
MIXED_DAEMONS_BOUND_S <- 60
DAEMON_SNAPSHOT_BOUND_S <- 30

# Collect a mirai, or a whole mirai_map, with a deadline -- never open-endedly.
#
# A bare `[` collect blocks until every element resolves, so one wedged daemon
# hangs the suite -- the failure AC4 exists to make impossible. Polling to a
# deadline and then reading `$data` (which yields `unresolvedValue` rather than
# waiting) cannot block at all. Same shape as the production probe in
# R/parallel.R, for the same reason.
#
# It takes both shapes because the suite has both, and one bounded idiom is
# what `test-suite-hygiene.R` can check for mechanically: a single mirai reads
# its own `$data`, a map reads one element at a time. `unresolved()` and
# `stop_mirai()` accept either, so only the read differs (M14 T2).
collect_bounded <- function(map, seconds = COLLECT_BOUNDED_DEFAULT_S) {
  deadline <- Sys.time() + seconds
  while (mirai::unresolved(map) && Sys.time() < deadline) {
    Sys.sleep(0.05)
  }
  if (mirai::unresolved(map)) {
    mirai::stop_mirai(map)
  }
  if (inherits(map, "mirai")) {
    return(map$data)
  }
  lapply(seq_along(map), function(i) map[[i]]$data)
}

prime_daemons <- function() {
  if (!requireNamespace("pkgload", quietly = TRUE)) {
    return(invisible(FALSE))
  }
  if (!isTRUE(pkgload::is_dev_package("nestedtune"))) {
    return(invisible(FALSE))
  }
  path <- pkgload::pkg_path()
  # Collected, not fired and forgotten. load_all() in a cold daemon is slow, and
  # returning before it finishes leaves the daemons still priming: the pre-flight
  # probe then queues behind it on every daemon and can ride out its whole bound.
  # M07's probe hid this by asking a single daemon, so whichever one was free
  # answered; asking all of them is what surfaced it.
  collect_bounded(
    mirai::everywhere(
      pkgload::load_all(path, quiet = TRUE),
      .args = list(path = path)
    ),
    seconds = PRIME_DAEMONS_BOUND_S
  )
  invisible(TRUE)
}

# Take the cold load out of the measurement.
#
# Under `R CMD check` the package is installed rather than primed, so the first
# pre-flight probe is what pays to load nestedtune and its whole dependency
# stack on every daemon at once -- tune alone measured 6.5 s cold (RR03). M07's
# probe never saw that bill because a single task went to whichever daemon was
# free; asking every daemon means the slowest cold load sets the time, and on a
# loaded check machine that exceeded the 30 s default.
#
# That is a real property of the fix, documented in the roxygen and settable
# through the option. Warming here keeps tests about dispatch from failing over
# it, and the bound below covers the case where warming itself is slow.
warm_daemons <- function() {
  collect_bounded(
    mirai::everywhere(requireNamespace("nestedtune", quietly = TRUE)),
    seconds = WARM_DAEMONS_BOUND_S
  )
  invisible(TRUE)
}

# The suite runs on machines under load, where `R CMD check` is doing everything
# else at the same time. The pre-flight bound is infrastructure, never anything
# statistical, so the tests that merely need dispatch to get going are given
# room. The tests that exercise the bound itself pass an explicit `timeout` or
# set the option locally, so none of them reads this value.
options(nestedtune.preflight_timeout = PREFLIGHT_TEST_TIMEOUT_MS)

# Start `n` primed daemons from a clean pool. Callers pair this with
# `on.exit(mirai::daemons(0), add = TRUE)`; cleanup is left to the caller rather
# than deferred here so the helpers need no dependency beyond mirai itself.
#
# Always starts from zero: daemons persist session state between tasks, so a
# pool left over from an earlier test is not a fresh measurement -- the trap
# that made an early probe read one answer off another's residue.
start_daemons <- function(n) {
  mirai::daemons(0)
  mirai::daemons(n)
  prime_daemons()
  warm_daemons()
  invisible(n)
}

# Daemon probe answers, as preflight_outcome() receives them.
#
# The probe returns one record per daemon, so a test asserting the ladder builds
# records rather than the bare logicals the pre-M24 probe returned. TRUE is a
# daemon that loaded the package with nothing missing, FALSE one that could not
# load it, NA a daemon that never answered -- a non-record, which is what a
# stopped or dead daemon actually yields.
#
# `missing =` names the symbols a loaded daemon lacks, keyed by position, so a
# mixed pool is written in one call: reports(TRUE, FALSE, missing = list(NULL,
# NULL)) is a load failure beside a healthy daemon.
#
# `missing_pkgs =` names the workflow's or the tuner's packages a daemon
# cannot load, keyed by position the same way (M58); a daemon that cannot
# load the package still answers it, as the real probe does.
reports <- function(..., missing = NULL, missing_pkgs = NULL) {
  loaded <- c(...)
  lapply(seq_along(loaded), function(i) {
    if (is.na(loaded[[i]])) {
      return(structure(20L, class = c("errorValue", "try-error")))
    }
    absent <- if (is.null(missing)) NULL else missing[[i]]
    lacking <- if (is.null(missing_pkgs)) NULL else missing_pkgs[[i]]
    list(
      loaded = loaded[[i]],
      missing = if (is.null(absent)) character() else absent,
      missing_pkgs = if (is.null(lacking)) character() else lacking
    )
  })
}

# The same pool, minus the dispatcher that makes cancellation possible (M24).
#
# `mirai::daemons(n)` starts a dispatcher; `daemons(n, dispatcher = FALSE)` does
# not, and use_parallel() admits both because it counts connections, which read
# alike. Primed and warmed exactly as start_daemons() does, so the two differ in
# the one property under test and in nothing else.
#
# A named helper rather than the three calls inline, so its waits are one
# BUDGETED_WAIT_CALLS entry the time-budget ledger can see -- prime_daemons()
# and warm_daemons() are not names that guard recognises, and spelled out at a
# call site they would each wait 60 s invisibly to it.
start_daemons_undispatched <- function(n) {
  mirai::daemons(0)
  mirai::daemons(n, dispatcher = FALSE)
  prime_daemons()
  warm_daemons()
  invisible(n)
}

# A pool shared across the blocks of one file (M74).
#
# test-parallel-identity.R once restarted its pool in every block -- 26 starts,
# each priming and warming every daemon -- where all but two blocks need only
# a primed pool of a given size. A pool is now started once per section by a
# visible `start_daemons(n)` call (so the time-budget ledger counts the start
# where it happens) and registered here with `share_daemons(n)`, which takes
# the snapshot below; every block that reuses it opens with
# `shared_daemons(n)`, which asks the pool for the same snapshot and compares
# it with the one taken at the start (see `shared_daemons()` for which
# fields are compared exactly and which as supersets). What a fold could
# observe of a daemon's state and the package reads -- the loaded namespaces,
# the one option the package consults, `search()`, the library variables and
# `.libPaths()` -- has therefore not moved between blocks except by the
# package's own attach step, which is the evidence M12 asked for before
# sharing a pool. What the snapshot does not
# hold is deliberate: a daemon's RNG kind changes on its first fold, since the
# pin sets Mersenne-Twister there and the worker does not restore it, so it
# cannot be an equality field; `daemon_rng_kinds()` reads it for the one
# block that needs it (BC2, the M07 lesson).
#
# A private pool -- BC3, which kills a daemon -- is started with
# `start_daemons()` as before, and replaces the shared pool: mirai holds one
# pool at a time, so the file orders its blocks by pool and the last shared
# block of a section is the one that may leave its daemons dirty (BC9).
shared_pool <- new.env(parent = emptyenv())

# What each daemon is asked for. Built from text, for the reason
# `daemon_probe_expr()` in R/parallel.R gives: `everywhere()` serializes the
# host's copy of a live expression, and under covr that copy carries
# `covr:::count()` calls the daemons cannot evaluate (the M10 lesson).
daemon_snapshot_expr <- function() {
  str2lang(paste0(
    "list(",
    "pid = Sys.getpid(), ",
    "namespaces = sort(loadedNamespaces()), ",
    "options = options('nestedtune.preflight_timeout'), ",
    "search = search(), ",
    "env = as.list(Sys.getenv(c('R_LIBS', 'R_LIBS_USER', 'R_LIBS_SITE'), ",
    "names = TRUE)), ",
    "libpaths = .libPaths()",
    ")"
  ))
}

# One record per daemon, named by the daemon's pid and sorted by it, so that
# a reuse compares each daemon with ITSELF at the start: the order daemons
# answer in is fixed by nothing between two round trips, and a daemon that
# died and was replaced answers under a pid the start never saw.
daemon_state_snapshot <- function() {
  snapshot_expr <- daemon_snapshot_expr()
  answers <- collect_bounded(
    mirai::everywhere(snapshot_expr),
    seconds = DAEMON_SNAPSHOT_BOUND_S
  )
  name_by_pid(answers)
}

# Order a set of daemon answers by pid and name each by the pid IT holds.
#
# One permutation does both, so the name on a record cannot be the pid of a
# different record. `sort(pids)` cannot stand in for `pids[order(pids)]` here:
# an answer carrying no integer `pid` reads as `NA`, which `order()` keeps and
# `sort()` drops, so the name vector comes back short and `names<-` pads it.
# Today that padding lands the NA exactly where `order()` put it and the names
# come out right anyway -- three unrelated defaults cancelling. Were
# `order()`'s `na.last` ever `FALSE`, the same pair would hang the sorted pids
# on the records one slot along and leave the last record unnamed (M79).
name_by_pid <- function(answers) {
  pids <- vapply(
    answers,
    function(x) if (is.list(x) && is.integer(x$pid)) x$pid else NA_integer_,
    integer(1)
  )
  ord <- order(pids)
  answers <- answers[ord]
  names(answers) <- as.character(pids[ord])
  answers
}

# The kind each daemon's generator is on, by daemon.
daemon_rng_kinds <- function() {
  kind_expr <- str2lang("RNGkind()[[1L]]")
  answers <- collect_bounded(
    mirai::everywhere(kind_expr),
    seconds = DAEMON_SNAPSHOT_BOUND_S
  )
  vapply(answers, function(x) if (is.character(x)) x else NA_character_, "")
}

# Register the pool `start_daemons(n)` just started as the file's shared pool
# of size `n`, and take the snapshot every reuse is compared against.
share_daemons <- function(n) {
  snapshot <- daemon_state_snapshot()
  testthat::expect_length(snapshot, n)
  for (record in snapshot) {
    testthat::expect_named(
      record,
      c("pid", "namespaces", "options", "search", "env", "libpaths")
    )
  }
  shared_pool$n <- as.integer(n)
  shared_pool$snapshot <- snapshot
  invisible(n)
}

# Reuse the shared pool of size `n`: it is up, and its daemons' state reads as
# it did when the pool started -- the option, the library variables and
# `.libPaths()` exactly, the loaded namespaces and `search()` as supersets.
# The last two grow on a daemon's first fold and keep growing through a
# section, by the package's own attach step (`attach_daemon_pkgs()`, which
# attaches the workflow's and the tuner's packages in every daemon) and by
# what those packages load lazily: measured 2026-09-07 on a 2-daemon pool,
# one grid run on the ranger fixture attached workflows, ranger and parsnip
# and loaded tailor, sparsevctrs and eleven more, and a race added lme4,
# Matrix, finetune and tune to the search path. That is the package doing on
# a shared pool what it does on a fresh one, so the probe asks that nothing
# the pool started with has been unloaded or detached, and that nothing else
# about the daemons has moved.
shared_daemons <- function(n) {
  testthat::expect_identical(shared_pool$n, as.integer(n))
  testthat::expect_identical(mirai::status()$connections, as.integer(n))
  now <- daemon_state_snapshot()
  was <- shared_pool$snapshot
  # The same daemons, by pid: a replaced daemon is a difference, not a
  # record that happens to sort into the same slot.
  testthat::expect_identical(names(now), names(was))
  for (i in seq_along(was)) {
    for (field in c("options", "env", "libpaths")) {
      testthat::expect_identical(now[[i]][[field]], was[[i]][[field]])
    }
    for (field in c("namespaces", "search")) {
      testthat::expect_identical(
        setdiff(was[[i]][[field]], now[[i]][[field]]),
        character(0)
      )
    }
  }
  invisible(n)
}

# The shared pool is gone; nothing registered here describes a pool any more.
unshare_daemons <- function() {
  mirai::daemons(0)
  shared_pool$n <- NULL
  shared_pool$snapshot <- NULL
  invisible(NULL)
}

# A serial run while a pool is up (M74). The orchestrator takes the serial
# branch when it counts fewer than two connected daemons (`use_parallel()`,
# D-018); with a shared pool live for the whole section, a block builds its
# serial reference by having that count read zero, exactly as
# test-parallel-classify.R fabricates a pool by having it read two. Nothing on
# the serial path consults the pool, so the branch runs as it would with no
# daemons at all; callers still assert `last_dispatch()` is "serial".
serial_run <- function(expr) {
  testthat::with_mocked_bindings(expr, mirai_workers = function() 0L)
}

skip_if_no_daemons <- function() {
  testthat::skip_if_not_installed("mirai")
  testthat::skip_on_cran()
}

# A library a daemon can start from but cannot load much out of.
#
# The trap RR03 named and M07 paid for: strip a daemon's library outright and it
# cannot load *mirai* either, so it dies at startup, is still counted as a
# connection, and hangs the very probe under test -- 39 minutes of `R CMD
# check`. So the scratch library keeps mirai and nanonext, and drops everything
# else.
lean_library <- function(keep = c("mirai", "nanonext")) {
  lib <- tempfile("nestedtune-lean-")
  dir.create(lib, recursive = TRUE, showWarnings = FALSE)
  linked <- vapply(
    keep,
    function(pkg) {
      src <- system.file(package = pkg)
      nzchar(src) && isTRUE(file.symlink(src, file.path(lib, pkg)))
    },
    logical(1)
  )
  if (!all(linked)) NULL else lib
}

# Two daemons that genuinely differ in what they can load (M10 T5, AC1).
#
# RR03 Q5 recorded the mechanism as `R_LIBS`; M10 T1 verified that insufficient
# wherever packages live in the SITE library, because R_LIBS only prepends --
# the target stayed reachable and both daemons answered TRUE. Setting
# R_LIBS_SITE *and* R_LIBS_USER does restrict it, leaving `.libPaths()` at the
# scratch library plus base R's own.
#
# The daemons are spawned by hand against a host URL rather than by daemons(n),
# because the environment has to differ per daemon and daemons(n) launches them
# all alike. Returns the connection count actually reached.
start_mixed_daemons <- function(lean_lib, timeout = MIXED_DAEMONS_BOUND_S) {
  mirai::daemons(0)
  mirai::daemons(n = 0, url = "tcp://127.0.0.1:0", dispatcher = TRUE)
  url <- mirai::status()$daemons

  # --vanilla so no user .Rprofile or .Renviron can put a library back that the
  # env vars below deliberately withhold, and all three library variables
  # because R_LIBS alone only PREPENDS -- it cannot take the site library away.
  spawn <- function(env) {
    system2(
      file.path(R.home("bin"), "Rscript"),
      c("--vanilla", "-e", shQuote(sprintf('mirai::daemon("%s")', url))),
      env = env,
      wait = FALSE,
      stdout = FALSE,
      stderr = FALSE
    )
  }
  spawn(character(0)) # the full library
  spawn(sprintf(c("R_LIBS=%s", "R_LIBS_SITE=%s", "R_LIBS_USER=%s"), lean_lib))

  deadline <- Sys.time() + timeout
  while (mirai::status()$connections < 2 && Sys.time() < deadline) {
    Sys.sleep(0.1)
  }
  mirai::status()$connections
}

# Muffle the one warning that is an artifact of testing under pkgload, and
# nothing else.
#
# Serializing a task from a session where load_all() has attached
# `package:nestedtune` makes R warn that the package "may not be available when
# loading" -- once per fold. Verified absent when the package is installed,
# which is how users and R CMD check run it. A blanket suppressWarnings() here
# would also hide the failed-fold warnings these tests exist to check, so the
# filter is by message.
without_pkgload_warning <- function(expr) {
  withCallingHandlers(
    expr,
    warning = function(w) {
      if (grepl("may not be available when loading", conditionMessage(w))) {
        invokeRestart("muffleWarning")
      }
    }
  )
}
