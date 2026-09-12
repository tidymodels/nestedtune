# Coverage traces from daemons go to a sidecar directory, not covr's own.
#
# covr installs an instrumented copy of the package whose namespace carries an
# exit finalizer: at process exit it writes a `covr_trace_*` file into the
# install directory, or into `COVERAGE_DIR` when that variable is set. Every R
# process that loads the instrumented package writes one, so the daemons the
# parallel tests start write them too. Nothing waits for a daemon to finish
# that write: `mirai::daemons(0)` only asks the daemons to exit, and when the
# testthat parent shuts a worker down at the end of the run, processx kills
# the worker's child processes with it. A daemon killed inside its finalizer
# leaves a truncated file, and `covr::package_coverage()` then dies reading it
# (`Error in readRDS(f): error reading from connection`), after every test
# passed. The failed runs' artifacts showed exactly that: whole worker files,
# three daemon files cut at a page boundary.
#
# So under covr this helper points `COVERAGE_DIR` at a sidecar directory next
# to the install directory. Daemons inherit the variable and write there, and
# so does the worker itself; covr's merge never sees any of them.
# `test-coverage.yaml` merges the sidecar afterwards, skipping any file that
# cannot be read, so a killed daemon costs its own counts and nothing else.
# The directory name is shared with that workflow; change both together.
#
# covr sets `R_COVR` in the environment of the process that runs the tests,
# and nothing else does, so outside covr this is a no-op. An explicit
# `COVERAGE_DIR` is respected as the caller's choice.
DAEMON_TRACE_SUBDIR <- "daemon-traces"

divert_covr_traces <- function(
  lib = dirname(system.file(package = "nestedtune"))
) {
  if (!identical(Sys.getenv("R_COVR"), "true")) {
    return(invisible(NULL))
  }
  if (nzchar(Sys.getenv("COVERAGE_DIR"))) {
    return(invisible(NULL))
  }
  dir <- file.path(lib, DAEMON_TRACE_SUBDIR)
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  Sys.setenv(COVERAGE_DIR = dir)
  invisible(dir)
}

divert_covr_traces()
