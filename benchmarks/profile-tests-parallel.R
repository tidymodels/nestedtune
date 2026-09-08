# What the test suite's WALL CLOCK is, with the files running in parallel.
#
# The sibling script `benchmarks/profile-tests.R` pins itself serial and reports
# per-file seconds; this one is the other measurement mode. Usage, from the
# package root:
#
#   Rscript benchmarks/profile-tests-parallel.R [runs] [workers]
#
# Why a second script rather than a flag on the first. `profile-tests.R` states
# in its own header that its per-file seconds are measured with the suite
# serial, because figures taken while four files share the machine are
# contention figures; its baseline (`benchmarks/test-timing-baseline.md`) was
# measured under those conditions. The two modes cannot both be true of one
# script's output, so they are two scripts.
#
# What this one is for. The suite runs its files in parallel
# (`Config/testthat/parallel: true`), so the run is bounded by the critical
# path through the worker queue, not by the sum of the file times.
# `Config/testthat/start-first` in DESCRIPTION orders that queue, and splitting
# a long file into shorter ones changes what the queue can pack -- neither
# lever moves any per-file cost, so neither is visible to the serial script.
# Wall clock is the figure both levers are priced on.
#
# Workers. Default 4, the count the three check workflows set in their job
# `env:` for the ubuntu and windows runners (`TESTTHAT_CPUS`, per the
# test-doctrine slot of `cairn/PROFILE.md`). Measuring at this machine's own
# core count would put every file in its own worker at once, where the queue
# order cannot matter; the runners are the condition the levers must pay off
# in. Pass a second argument to measure at another count.
#
# NOT_CRAN is set to "true" for the same reason devtools does: tests that skip
# on CRAN are part of what a developer waits for.

args <- commandArgs(trailingOnly = TRUE)
runs <- if (length(args) >= 1L) as.integer(args[[1L]]) else 3L
workers <- if (length(args) >= 2L) as.integer(args[[2L]]) else 4L
stopifnot(!is.na(runs), runs >= 1L, !is.na(workers), workers >= 1L)

Sys.setenv(NOT_CRAN = "true")
Sys.setenv(TESTTHAT_PARALLEL = "TRUE")
Sys.setenv(TESTTHAT_CPUS = as.character(workers))

# Where the per-file figures come from. Under parallel files the `real` column
# of a testthat result is 0 for every test -- verified by running this script
# against it -- because the timing is taken in the parent, which does no work.
# The suite already carries a reporter that timestamps each file's start and
# end to unbuffered stderr (`tests/testthat/helper-hang-trace.R`, written for
# the hang hunt), and in parallel mode it runs in the parent in live-update
# mode, one pair per file. Those two timestamps ARE the file's wall clock in
# the queue, so the profiler reads them rather than inventing a second
# mechanism.
suppressMessages(library(testthat))
source("tests/testthat/helper-hang-trace.R")

profiling_reporter <- function() {
  reporter <- MultiReporter$new(
    reporters = list(SilentReporter$new(), HangTraceReporter$new())
  )
  reporter$capabilities$parallel_updates <- TRUE
  reporter
}

# `[hang-trace] <ISO timestamp> start|end <target>`; file-level targets carry
# no " :: ", which is how the block-level lines are dropped.
parse_trace <- function(path) {
  lines <- grep("^\\[hang-trace\\] ", readLines(path), value = TRUE)
  parts <- strsplit(trimws(sub("^\\[hang-trace\\] ", "", lines)), " +")
  stamps <- as.POSIXct(
    vapply(parts, `[[`, character(1), 1L),
    format = "%Y-%m-%dT%H:%M:%OS",
    tz = "UTC"
  )
  event <- vapply(parts, `[[`, character(1), 2L)
  target <- vapply(parts, function(p) paste(p[-(1:2)], collapse = " "), "")
  keep <- !grepl(" :: ", target, fixed = TRUE)
  stamps <- stamps[keep]
  event <- event[keep]
  target <- target[keep]
  files <- unique(target)
  secs <- vapply(
    files,
    function(f) {
      s <- stamps[target == f & event == "start"]
      e <- stamps[target == f & event == "end"]
      if (!length(s) || !length(e)) {
        return(NA_real_)
      }
      as.numeric(difftime(max(e), min(s), units = "secs"))
    },
    numeric(1)
  )
  stats::setNames(secs, files)
}

# `load_package = "source"` because each parallel worker is its own R process
# and has to load the package itself; there is no parent load to inherit.
one_run <- function() {
  trace <- tempfile(fileext = ".log")
  con <- file(trace, open = "wt")
  sink(con, type = "message")
  started <- proc.time()[["elapsed"]]
  res <- try(
    testthat::test_dir(
      "tests/testthat",
      package = "nestedtune",
      load_package = "source",
      reporter = profiling_reporter(),
      stop_on_failure = FALSE
    ),
    silent = TRUE
  )
  wall <- proc.time()[["elapsed"]] - started
  sink(type = "message")
  close(con)
  if (inherits(res, "try-error")) {
    stop(res)
  }
  df <- as.data.frame(res)
  list(
    per_file = parse_trace(trace),
    counts = c(
      pass = sum(df$nb) - sum(df$failed) - sum(df$skipped) - sum(df$error),
      fail = sum(df$failed) + sum(df$error),
      skip = sum(df$skipped)
    ),
    wall = wall
  )
}

passes <- vector("list", runs)
for (i in seq_len(runs)) {
  cat(sprintf("run %d/%d ...\n", i, runs))
  passes[[i]] <- one_run()
  # Every run reports its own counts: a comparison between two refs reads the
  # pass floor and the fail/skip zeros off each run, not off the first one.
  cat(sprintf(
    "run %d/%d: pass %d | fail %d | skip %d | WALL %.1f s\n",
    i,
    runs,
    passes[[i]]$counts[["pass"]],
    passes[[i]]$counts[["fail"]],
    passes[[i]]$counts[["skip"]],
    passes[[i]]$wall
  ))
}

files <- sort(unique(unlist(lapply(passes, function(p) names(p$per_file)))))
med <- function(f) {
  stats::median(
    vapply(
      passes,
      # Single-bracket, deliberately: `[[` on a name `per_file` does not carry
      # raises "subscript out of bounds" rather than returning NA -- so a run
      # whose file set differs from the union above (a file that never
      # finished, a file added between runs) would kill the profiler after it
      # had already paid for every run.
      function(p) unname(p$per_file[f]),
      numeric(1)
    ),
    na.rm = TRUE
  )
}
elapsed <- vapply(files, med, numeric(1))
ord <- order(elapsed, decreasing = TRUE)

wall <- stats::median(vapply(passes, function(p) p$wall, numeric(1)))

cat("\n")
cat(sprintf("R:        %s\n", R.version.string))
cat(sprintf("OS:       %s\n", sessionInfo()$running))
cat(sprintf("cores:    %d (parallel::detectCores)\n", parallel::detectCores()))
cat(sprintf("testthat: %s\n", as.character(utils::packageVersion("testthat"))))
cat(sprintf(
  "commit:   %s\n",
  system("git rev-parse --short HEAD", intern = TRUE)
))
cat(sprintf("NOT_CRAN: %s\n", Sys.getenv("NOT_CRAN")))
cat(sprintf("workers:  %d (TESTTHAT_CPUS)\n", workers))
cat(sprintf("loading:  each worker loads the package itself (source)\n"))
cat(sprintf("runs:     %d (all figures are medians)\n\n", runs))

cat(sprintf("%-46s %8s\n", "file (wall clock in the worker queue)", "seconds"))
for (f in files[ord]) {
  cat(sprintf("%-46s %8.1f\n", f, elapsed[[f]]))
}
cat(sprintf("%-46s %8.1f\n", "LONGEST SINGLE FILE", max(elapsed)))
cat(sprintf("%-46s %8.1f\n", "WALL CLOCK (the figure that is priced)", wall))

cat("\n")
for (i in seq_len(runs)) {
  counts <- passes[[i]]$counts
  cat(sprintf(
    "run %d/%d: pass %d | fail %d | skip %d | wall %.1f s\n",
    i,
    runs,
    counts[["pass"]],
    counts[["fail"]],
    counts[["skip"]],
    passes[[i]]$wall
  ))
}
