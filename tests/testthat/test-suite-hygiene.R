# Hygiene checks on the test suite's own source and helpers.
#
# The file checks four things:
#   * Every wait on a mirai result goes through `collect_bounded()`.
#   * Every wait-shaped call in the daemon files has a row in the time-budget
#     ledger (helper-time-budget.R), no row is left for a call that is gone,
#     and a row copied from an explicit bound still matches that bound.
#   * The declared worst cases of test-parallel-classify.R and
#     test-parallel-metrics.R stay under their ceilings.
#   * `daemon_state_snapshot()` names each daemon's record by the pid that
#     record holds, which is what `shared_daemons()` compares.
#
# The first rule exists because breaking it costs twenty minutes of silence
# rather than a red test: every wait on a mirai result in this suite goes
# through `collect_bounded()` (helper-parallel.R), which polls to a deadline and
# then reads `$data`. Everything else mirai offers for getting a value out
# blocks until it resolves and cannot be interrupted from R at all --
# `setTimeLimit(elapsed=)` does not fire inside any of them, established by
# running them.
#
# Three shapes are matched, and the list is the enumeration this check is only
# as good as:
#   * `collect_mirai(x)` -- collects a whole map.
#   * `call_mirai(x)` -- mirai's canonical blocking wait; `x[]` is sugar for it.
#   * a `[` collect, empty (`mirai(...)[]`, `map[]`) or carrying one of mirai's
#     collect options (`map[.flat]`, `map[.progress]`, `map[.stop]`), which
#     block just as hard as the empty form.
#
# Checked over parse tokens rather than by grepping text, so a `[]` inside a
# string and the several comments that discuss `map[]` and `collect_mirai()` by
# name are not findings. A comment describing the trap is the opposite of the
# trap.

# mirai's collect options, as of 2.7.2. A new one added upstream is invisible
# to this check until it is named here -- which is the honest limit of an
# allowlist, and preferable to flagging every `x[.anything]` in the suite.
MIRAI_COLLECT_OPTIONS <- c(".flat", ".progress", ".progress_data", ".stop")

blocking_collect_sites <- function(path) {
  data <- utils::getParseData(parse(path, keep.source = TRUE))
  data <- data[data$token != "COMMENT", , drop = FALSE]
  data <- data[order(data$line1, data$col1), , drop = FALSE]

  named <- data$token == "SYMBOL_FUNCTION_CALL" &
    data$text %in% c("collect_mirai", "call_mirai")

  # A blocking `[` collect is an opening bracket whose next token either closes
  # it immediately or is one of mirai's collect options. `x[[i]]` tokenises as
  # `'[['`, so it cannot reach here, and `df[, 1]` has a `','` next.
  opens <- which(data$token == "'['")
  opens <- opens[opens < nrow(data)]
  nxt_token <- data$token[opens + 1L]
  nxt_text <- data$text[opens + 1L]
  blocking <- opens[
    nxt_token == "']'" |
      (nxt_token == "SYMBOL" & nxt_text %in% MIRAI_COLLECT_OPTIONS)
  ]

  sort(unique(c(data$line1[named], data$line1[blocking])))
}

# The second rule: every wait-shaped call in the daemon files is
# accounted for in the time budget. `collect_bounded()` made the waits bounded;
# this makes the SUM of those bounds visible, which is the part that killed a CI
# job -- 1008.7 s of legal waiting in a file that normally takes 12.0 s, against
# a 20-minute cap.
#
# Accounted for is not the same as small. A call that waits for nothing carries a
# 0-second row saying why, and that is the point: adding a new call forces a
# conscious classification instead of letting it hide among the harmless ones.
BUDGETED_WAIT_CALLS <- c(
  "collect_bounded",
  "daemons_load_status",
  "setTimeLimit",
  "check_daemons_can_load",
  "start_daemons",
  "start_mixed_daemons",
  "start_daemons_undispatched",
  "share_daemons",
  "shared_daemons",
  "daemon_rng_kinds"
)

BUDGETED_FILES <- c(
  "test-parallel-classify.R",
  "test-parallel-detection.R",
  "test-parallel-identity.R",
  "test-parallel-interrupt.R",
  "test-parallel-metrics.R",
  "test-parallel-payload.R",
  "test-parallel-required-pkgs.R",
  "helper-parallel.R"
)

# The key a ledger row and a wait call meet on: the file, the unit the call
# sits in, and the call's place among the wait calls of that unit, counted in
# source order. No line number enters it, so a line added above a call changes
# no key. Swapping two different wait calls inside one unit does, and fails
# the guards; adding or removing one renumbers the calls after it.
wait_call_key <- function(file, payer, at, call) {
  paste0(file, " :: ", payer, " :: #", at, " ", call)
}

# The unit is the description of the innermost `test_that()` around the call,
# called bare with a string literal first. Outside any test it is the name of
# the outermost function assigned with `<-` that holds the call, as for the
# helper-parallel.R rows, and "(top level)" when there is none.
enclosing_unit <- function(data, id) {
  unit <- "(top level)"
  repeat {
    parent <- data$parent[data$id == id]
    if (!length(parent) || parent <= 0) {
      return(unit)
    }
    kids <- data[data$parent == parent, , drop = FALSE]
    kids <- kids[order(kids$line1, kids$col1), , drop = FALSE]
    exprs <- kids$id[kids$token == "expr"]
    head <- data[data$parent %in% exprs[1], , drop = FALSE]
    if (
      length(exprs) >= 2L &&
        nrow(head) == 1L &&
        head$token == "SYMBOL_FUNCTION_CALL" &&
        head$text == "test_that"
    ) {
      desc <- data[
        data$parent == exprs[[2]] & data$token == "STR_CONST",
        ,
        drop = FALSE
      ]
      if (nrow(desc) == 1L) {
        return(str2lang(desc$text))
      }
      return(utils::getParseText(data, exprs[[2]]))
    }
    is_function <- length(exprs) == 2L &&
      any(kids$token == "LEFT_ASSIGN") &&
      any(data$parent == exprs[[2]] & data$token == "FUNCTION")
    if (is_function) {
      name <- data$text[data$parent == exprs[[1]] & data$token == "SYMBOL"]
      if (length(name) == 1L) {
        unit <- paste0(name, "()")
      }
    }
    id <- parent
  }
}

# Every wait call in a file, with its key and the source text of the whole call.
wait_calls <- function(path) {
  data <- utils::getParseData(parse(path, keep.source = TRUE))
  calls <- data[
    data$token == "SYMBOL_FUNCTION_CALL" &
      data$text %in% BUDGETED_WAIT_CALLS,
    ,
    drop = FALSE
  ]
  calls <- calls[order(calls$line1, calls$col1), , drop = FALSE]
  if (!nrow(calls)) {
    return(data.frame(key = character(0), text = character(0)))
  }
  payer <- vapply(calls$id, function(id) enclosing_unit(data, id), character(1))
  at <- stats::ave(seq_along(payer), payer, FUN = seq_along)
  # The name token sits inside an `expr` holding the function position, whose
  # own parent is the call, so the call is the grandparent.
  text <- vapply(
    calls$id,
    function(id) {
      fn <- data$parent[data$id == id]
      utils::getParseText(data, data$parent[data$id == fn])
    },
    character(1)
  )
  data.frame(
    key = wait_call_key(basename(path), payer, at, calls$text),
    text = text,
    stringsAsFactors = FALSE
  )
}

wait_call_sites <- function(path) {
  wait_calls(path)$key
}

ledger_keys <- function(ledger) {
  wait_call_key(ledger$file, ledger$payer, ledger$at, ledger$call)
}

test_that("every wait-shaped call in the daemon files carries a budget row", {
  ledger <- time_budget_ledger()
  budgeted <- ledger_keys(ledger)

  found <- unlist(
    lapply(BUDGETED_FILES, function(f) {
      wait_call_sites(test_path(f))
    }),
    use.names = FALSE
  )

  # The check is only as good as its reaching the files at all -- a typo in a
  # name would otherwise pass by finding nothing, and a run that tested nothing
  # would report clean.
  expect_gt(length(found), 20L)

  unbudgeted <- setdiff(found, budgeted)
  expect_identical(
    unbudgeted,
    character(0),
    info = paste0(
      "wait-shaped call with no row in helper-time-budget.R at: ",
      paste(unbudgeted, collapse = ", "),
      " -- add a row giving its worst-case seconds, or 0 with a note saying ",
      "why it waits for nothing."
    )
  )
})

test_that("the budget ledger has no rows for calls that are gone", {
  # The other direction: a row whose key no longer names a wait call is stale,
  # and a stale row adds seconds to the totals for a call that is gone.
  ledger <- time_budget_ledger()
  # Scoped to rows describing an actual call. The ledger may also carry a wait
  # that is not a function call at all -- the `while (... && Sys.time() <
  # deadline)` poll in test-parallel-interrupt.R -- which is real budget but has
  # no token to match, so it is exempt from this direction only.
  ledger <- ledger[ledger$call %in% BUDGETED_WAIT_CALLS, , drop = FALSE]
  budgeted <- ledger_keys(ledger)

  found <- unlist(
    lapply(BUDGETED_FILES, function(f) {
      wait_call_sites(test_path(f))
    }),
    use.names = FALSE
  )

  stale <- setdiff(budgeted, found)
  expect_identical(
    stale,
    character(0),
    info = paste0(
      "budget row naming no wait call (call removed, renamed or reordered?): ",
      paste(stale, collapse = ", ")
    )
  )
})

# Re-read a bound from the call site itself, in seconds.
#
# A ledger row whose seconds were COPIED from an explicit argument can drift from
# that argument silently -- raising `timeout = 60000` to `600000` would leave both
# accounting guards green and the printed total unchanged, while the real worst
# case would grow by nine minutes. Rows whose bound comes from a named
# constant in helper-parallel.R cannot drift that way and need no check.
#
# NA means the call carries no explicit bound of its own: a bound read from a
# named constant, the option-set-elsewhere case, and the deadline poll. Which
# rows those are is declared below rather than left to whatever the regex
# happens to miss.
#
# Read from the whole CALL, which `wait_calls()` gives as parsed text. An
# argument list wrapped across lines puts the bound on a later line than the
# function name, and a read of one line would find nothing there and skip the
# row in silence.
#
# The keyword is chosen by the call rather than tried in turn, because the
# whole call brings any nested call's arguments into view with it --
# `collect_bounded(mirai::everywhere(...), seconds = 30)` is the shape already
# in the suite. Each call has exactly one bound argument, and the first match
# in the call's text is read. So the read goes wrong only where that text puts
# another `seconds =` or `timeout =` first: a wait call of the same kind nested
# in the arguments, or a comment inside the call. The suite has neither.
call_site_bound_s <- function(txt, call) {
  keyword <- if (identical(call, "collect_bounded")) "seconds" else "timeout"
  hit <- regmatches(
    txt,
    regexpr(paste0(keyword, "[[:space:]]*=[[:space:]]*[0-9.]+"), txt)
  )
  if (!length(hit)) {
    return(NA_real_)
  }
  value <- as.numeric(sub(".*=[[:space:]]*", "", hit))
  if (identical(keyword, "timeout")) value / 1000 else value
}

# The rows whose bound this cross-check cannot re-read, named so a new one
# cannot join them in silence -- which is the failure this list exists to
# prevent. Keyed as the ledger rows are, so a stale entry cannot quietly excuse
# a different row.
DECLARED_UNCHECKABLE_BOUNDS <- c(
  # Bound comes from COLLECT_BOUNDED_DEFAULT_S, which the row reads directly.
  wait_call_key(
    "test-parallel-classify.R",
    "a miraiError becomes a recorded worker failure, not an abort",
    1L,
    "collect_bounded"
  ),
  # Bound is set through the option at one line and spent at another.
  wait_call_key(
    "test-parallel-classify.R",
    "the probe reads its bound from the option, not from the constant",
    4L,
    "daemons_load_status"
  )
)

test_that("a copied bound still matches the argument it was copied from", {
  ledger <- time_budget_ledger()
  # Only rows that actually declare a wait, and only the two calls that take an
  # explicit bound. A `check_daemons_can_load()` row carrying a fabricated
  # `preflight_outcome(..., timeout = 300000)` on its line waits for nothing --
  # its number is message content, not budget.
  ledger <- ledger[
    ledger$call %in%
      c("daemons_load_status", "collect_bounded") &
      ledger$seconds > 0,
    ,
    drop = FALSE
  ]

  sites <- do.call(
    rbind,
    lapply(BUDGETED_FILES, function(f) wait_calls(test_path(f)))
  )
  keys <- ledger_keys(ledger)

  checked <- 0L
  unreadable <- character(0)
  for (i in seq_len(nrow(ledger))) {
    txt <- sites$text[sites$key == keys[[i]]]
    at <- if (length(txt) == 1L) {
      call_site_bound_s(txt, ledger$call[[i]])
    } else {
      NA_real_
    }
    if (is.na(at)) {
      unreadable <- c(unreadable, keys[[i]])
      next
    }
    checked <- checked + 1L
    expect_equal(
      ledger$seconds[[i]],
      at * ledger$times[[i]],
      info = paste0(
        keys[[i]],
        " declares ",
        ledger$seconds[[i]],
        " s but the call site says ",
        at * ledger$times[[i]],
        " s"
      )
    )
  }
  # A skipped row is the failure mode, not an accident of it: a row declared a
  # copied bound, was never re-read, and nothing said so. Asserting the skipped
  # set EQUALS the declared one -- rather than counting the checked rows -- is
  # what makes a fourth unreadable row fail here instead of passing quietly.
  expect_identical(
    sort(unique(unreadable)),
    sort(DECLARED_UNCHECKABLE_BOUNDS),
    info = paste0(
      "a ledger row declaring a copied bound that this check cannot re-read: ",
      paste(
        setdiff(unique(unreadable), DECLARED_UNCHECKABLE_BOUNDS),
        collapse = ", "
      ),
      " -- give the call an explicit bound, or declare why it has none."
    )
  )
  # Without this the test passes by checking nothing the moment the filter or the
  # regex stops matching: a harness that reports clean having asserted nothing.
  expect_gt(checked, 4L)
})

test_that("the localized file's declared worst case fits the CI budget", {
  # What test-parallel-classify.R is ALLOWED to wait for, held under its
  # ceiling, in a file that typically runs 12.0 s.
  totals <- time_budget_totals()
  classify <- totals$seconds[totals$file == "test-parallel-classify.R"]

  expect_length(classify, 1L)
  expect_lt(classify, CLASSIFY_BUDGET_CEILING_S)
})

test_that("the metrics-delivery file stays inside its own ceiling", {
  # The file was born with a ceiling rather than given one later,
  # which is the difference between holding a bound and measuring a regression.
  totals <- time_budget_totals()
  metrics <- totals$seconds[totals$file == "test-parallel-metrics.R"]

  expect_length(metrics, 1L)
  expect_lt(metrics, METRICS_BUDGET_CEILING_S)
})

test_that("no test waits on a mirai result outside collect_bounded()", {
  # Everything under tests/, not just this directory: `tests/testthat.R` is R
  # code that could acquire a wait too.
  # `.r` as well as `.R`, since R does not care about the case. Deliberately
  # NOT the repo root: `dispatch_folds()` in `R/parallel.R` holds the
  # production `collect_mirai()`, which is there on purpose, and this rule is
  # about the suite.
  files <- list.files(
    test_path(".."),
    pattern = "\\.[Rr]$",
    full.names = TRUE,
    recursive = TRUE
  )
  files <- files[!grepl("/_snaps/", files)]
  expect_gt(length(files), 0L)

  found <- lapply(files, function(path) {
    lines <- blocking_collect_sites(path)
    if (!length(lines)) NULL else paste0(basename(path), ":", lines)
  })
  found <- unlist(found, use.names = FALSE)

  expect_identical(
    found,
    NULL,
    info = paste0(
      "blocking mirai collect outside collect_bounded() at: ",
      paste(found, collapse = ", ")
    )
  )
})

# The probe in `shared_daemons()` compares `names(now)` against `names(was)` to
# say "the same daemons, by pid", so a name that belongs to a different record
# turns a replaced daemon into a silent pass. The snapshot is taken here over
# fabricated answers rather than a live pool: the round trip is replaced, and
# everything after it is the helper `shared_daemons()` calls. The case that
# tells a right naming from a near miss is an answer carrying no integer `pid`
# -- what the helper's own `NA_integer_` fallback is written for -- and
# fabricating that is cheaper and surer than breaking a pool into producing
# one.
test_that("a daemon snapshot names each record by the pid it holds", {
  answer <- function(pid) list(pid = pid, namespaces = character(0))
  snapshot_of <- function(answers) {
    # `collect_bounded()` never forces its first argument here, so no
    # `mirai::everywhere()` call is made and no pool is needed. The helper is
    # not in the namespace, which `local_mocked_bindings()` searches, so it is
    # rebound where the helpers live.
    rlang::local_bindings(
      collect_bounded = function(map, seconds) answers,
      .env = environment(daemon_state_snapshot)
    )
    daemon_state_snapshot()
  }

  # Named in true pid order, whichever order the daemons answered in.
  shuffled <- list(a = answer(30L), b = answer(10L), c = answer(20L))
  named <- snapshot_of(shuffled)
  expect_identical(names(named), c("10", "20", "30"))
  expect_identical(
    vapply(named, function(x) x$pid, integer(1)),
    c(
      "10" = 10L,
      "20" = 20L,
      "30" = 30L
    )
  )

  # An answer that is not a list, or whose `pid` is not an integer, holds no
  # pid: it sorts last and its name is missing, not another record's pid.
  with_gap <- list(
    a = answer(30L),
    b = "the daemon died before it answered",
    c = answer(10L),
    d = answer(NULL)
  )
  gapped <- snapshot_of(with_gap)
  expect_identical(names(gapped), c("10", "30", NA, NA))
  expect_identical(gapped[[1L]]$pid, 10L)
  expect_identical(gapped[[2L]]$pid, 30L)
  expect_identical(gapped[[3L]], "the daemon died before it answered")

  # The property in one line, over both fixtures: every record's name is the
  # pid it carries, read back off the record itself.
  for (fixture in list(shuffled, with_gap)) {
    out <- snapshot_of(fixture)
    carried <- vapply(
      out,
      function(x) {
        if (is.list(x) && is.integer(x$pid)) {
          as.character(x$pid)
        } else {
          NA_character_
        }
      },
      character(1),
      USE.NAMES = FALSE
    )
    expect_identical(names(out), carried)
  }
})
