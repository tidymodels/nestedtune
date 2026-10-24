# Leaving dispatch_folds() without returning stops the folds it dispatched.
#
# The defect: dispatch_folds() sends a mirai_map and then blocks in
# collect_mirai(). Interrupting there unwinds the host, but says nothing to the
# daemons -- so the pool the user reuses next is still computing folds whose
# results nobody will ever read. Established by execution against mirai 2.7.2
# before the fix: a real SIGINT during the collect left
# `mirai::status()$mirai` reporting `executing = 2`.
#
# The folds here are stand-ins that mark themselves started and then sleep. A
# real fit would make the window the interrupt has to land in depend on how
# fast the machine fits, and what is under test is the fate of dispatched work,
# not fitting. The stand-in is installed by mocking the package's own
# `fold_task`, which dispatch_folds() looks up by name -- so everything from
# `mirai_map()` to the return is the production path.

# A fold record's shape, built inline rather than by calling a helper: the task
# is serialized to a daemon with its environment stripped to the global one, so
# its body can reach nothing this file defines.
completed_fold_task <- function(
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
  list(
    completed = TRUE,
    metrics = data.frame(.metric = "rmse", .estimate = payload$value),
    selected = data.frame(mtry = 1L),
    inner_metrics = data.frame(mtry = 1L, .config = "pre0_mod1_post0"),
    notes = data.frame(
      location = character(0),
      type = character(0),
      note = character(0)
    )
  )
}

test_that("an interrupted run leaves no fold executing", {
  skip_if_no_daemons()
  # A genuine console interrupt is the contract under test, and a POSIX signal
  # is the only way to raise one without a console. setTimeLimit() is not a
  # substitute -- it does not fire inside a blocked collect_mirai().
  skip_on_os("windows")
  skip_if(!nzchar(Sys.which("sh")), "no POSIX shell to signal from")

  on.exit(mirai::daemons(0), add = TRUE)
  start_daemons(2)

  markers <- file.path(tempdir(), paste0("m15-fold-", 1:2))
  # `ack` is written by the host when the interrupt reaches it, and `sent` is
  # where the shell records each signal it sends and that it has finished.
  ack <- file.path(tempdir(), "m15-ack")
  sent <- file.path(tempdir(), "m15-sent")
  unlink(c(markers, ack, sent))
  on.exit(unlink(c(markers, ack, sent)), add = TRUE)

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
      file.create(payload$marker)
      Sys.sleep(60)
      NULL
    }
  )

  # The signal is sent only once BOTH folds have marked themselves started, so
  # the host is necessarily inside the collect when it lands -- a fixed delay
  # would race the pre-flight probe on a loaded machine and interrupt something
  # else. The wait is bounded at 20 s and the folds sleep for 60, so the signal
  # can never arrive after the collect has returned, where it would land
  # outside the handler below and take the suite down with it.
  #
  # A wait that times out sends nothing. If the folds never start -- the
  # pre-flight check aborting is the realistic way -- this test has already
  # failed on its own error, and a signal fired anyway would land in whichever
  # test was running twenty seconds later, aborting the run under `R CMD check`
  # with nothing to connect it to its cause.
  #
  # One signal is not always enough. On a loaded machine a SIGINT sent while
  # the host is inside the collect can be lost before R raises it: the shell
  # sent it, both folds were running, and the collect still ran its full 60 s
  # (observed with two suites run side by side on mirai 2.7.2 and nanonext
  # 1.10.2). The package's collect handles no interrupt itself, so the loss is
  # below it. The shell therefore sends up to three signals, 3 s apart, and
  # stops as soon as the host has written `ack`. The last one goes out about
  # 10 s after the folds start, well inside their 60 s sleep.
  script <- sprintf(
    paste(
      'i=0; while [ $i -lt 200 ]; do [ -f "%1$s" ] && [ -f "%2$s" ] && break;',
      "sleep 0.1; i=$((i+1)); done;",
      'if [ -f "%1$s" ] && [ -f "%2$s" ]; then sleep 0.5; n=0;',
      'while [ $n -lt 3 ] && [ ! -f "%3$s" ]; do',
      'kill -INT %5$d; echo sent >> "%4$s"; n=$((n+1)); j=0;',
      'while [ $j -lt 30 ] && [ ! -f "%3$s" ]; do sleep 0.1; j=$((j+1)); done;',
      'done; fi; echo done >> "%4$s"'
    ),
    markers[[1]],
    markers[[2]],
    ack,
    sent,
    Sys.getpid()
  )
  system2("sh", c("-c", shQuote(script)), wait = FALSE)

  payloads <- list(list(marker = markers[[1]]), list(marker = markers[[2]]))
  interrupted <- FALSE
  tryCatch(
    without_pkgload_warning(
      dispatch_folds(payloads, object = NULL, tuner = NULL, metrics = NULL)
    ),
    interrupt = function(cnd) {
      file.create(ack)
      interrupted <<- TRUE
    }
  )

  # Bounded, because the daemons report the cancellation back asynchronously --
  # the pool is idle within a moment of the unwind, not within the same
  # instruction. The same wait lets the shell finish, and a signal it sent just
  # before `ack` appeared is caught here rather than in a later test.
  sent_lines <- function() if (file.exists(sent)) readLines(sent) else ""
  executing <- function() mirai::status()$mirai[["executing"]]
  deadline <- Sys.time() + 15
  repeat {
    waiting <- tryCatch(
      (executing() > 0L || !"done" %in% sent_lines()) &&
        Sys.time() < deadline,
      interrupt = function(cnd) TRUE
    )
    if (!waiting) {
      break
    }
    tryCatch(Sys.sleep(0.1), interrupt = function(cnd) NULL)
  }

  n_sent <- sum(sent_lines() == "sent")
  expect(
    n_sent > 0L,
    "The shell sent no interrupt: the two folds did not both mark themselves started within its 20 s wait."
  )
  if (n_sent > 0L) {
    expect(
      interrupted,
      sprintf(
        "The shell sent %d interrupt(s) and none reached the host.",
        n_sent
      )
    )
  }
  # Not a vacuous pass: both folds really were executing when the signal landed.
  # Without this an interrupt delivered before dispatch would report an idle
  # pool and read as a fix.
  expect_true(all(file.exists(markers)))
  expect_identical(executing(), 0L)
})

test_that("a run that finished normally is unharmed by the cancel on the way out", {
  skip_if_no_daemons()

  # The normal-exit half of the cancel. The cancel is unconditional -- no flag
  # decides whether the run was abandoned -- so the normal exit path calls
  # stop_mirai() too, on a map whose every element has already resolved.
  # Verified harmless by execution (it returns FALSE per element and touches
  # nothing), and pinned here so a change that made it destructive would be
  # caught by results going missing rather than by reasoning.
  on.exit(mirai::daemons(0), add = TRUE)
  start_daemons(2)

  local_mocked_bindings(fold_task = completed_fold_task)

  out <- without_pkgload_warning(
    dispatch_folds(
      list(list(value = 1), list(value = 2)),
      object = NULL,
      tuner = NULL,
      metrics = NULL
    )
  )

  expect_length(out, 2L)
  expect_true(all(vapply(out, function(x) isTRUE(x$completed), logical(1))))
  expect_identical(
    vapply(out, function(x) x$metrics$.estimate, numeric(1)),
    c(1, 2)
  )
  expect_identical(mirai::status()$mirai[["executing"]], 0L)
})
