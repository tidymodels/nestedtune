# The coverage job once failed after every test passed: a daemon killed while
# writing its covr trace left a truncated file for covr's merge to choke on.
# helper-covr.R diverts those traces to a sidecar directory under covr and
# leaves everything alone otherwise; these tests pin that contract.

# Run `expr` with `R_COVR` and `COVERAGE_DIR` set as given (NA = unset), and
# restore both afterwards. No withr: it is deliberately not a dependency.
with_covr_env <- function(r_covr, coverage_dir, expr) {
  old <- Sys.getenv(c("R_COVR", "COVERAGE_DIR"), unset = NA)
  on.exit(
    {
      for (name in names(old)) {
        if (is.na(old[[name]])) {
          Sys.unsetenv(name)
        } else {
          do.call(Sys.setenv, as.list(old[name]))
        }
      }
    },
    add = TRUE
  )
  Sys.unsetenv(c("R_COVR", "COVERAGE_DIR"))
  if (!is.na(r_covr)) {
    Sys.setenv(R_COVR = r_covr)
  }
  if (!is.na(coverage_dir)) {
    Sys.setenv(COVERAGE_DIR = coverage_dir)
  }
  force(expr)
}

test_that("under covr, traces are diverted to a sidecar the merge never reads", {
  lib <- tempfile("lib")
  dir.create(lib)
  on.exit(unlink(lib, recursive = TRUE), add = TRUE)

  with_covr_env("true", NA, {
    got <- divert_covr_traces(lib)

    expect_identical(got, file.path(lib, DAEMON_TRACE_SUBDIR))
    expect_true(dir.exists(got))
    expect_identical(Sys.getenv("COVERAGE_DIR"), got)

    # A child R process -- the shape of a daemon -- inherits the diversion,
    # which is the whole point: the daemon's exit finalizer reads this
    # variable, and nothing in this process can reach that finalizer directly.
    child <- system2(
      file.path(R.home("bin"), "Rscript"),
      c("--vanilla", "-e", shQuote("cat(Sys.getenv('COVERAGE_DIR'))")),
      stdout = TRUE
    )
    expect_identical(child, got)
  })
})

test_that("outside covr nothing is diverted", {
  lib <- tempfile("lib")
  dir.create(lib)
  on.exit(unlink(lib, recursive = TRUE), add = TRUE)

  with_covr_env(NA, NA, {
    expect_null(divert_covr_traces(lib))
    expect_identical(Sys.getenv("COVERAGE_DIR"), "")
    expect_false(dir.exists(file.path(lib, DAEMON_TRACE_SUBDIR)))
  })
})

test_that("an explicit COVERAGE_DIR is respected under covr", {
  lib <- tempfile("lib")
  dir.create(lib)
  on.exit(unlink(lib, recursive = TRUE), add = TRUE)

  with_covr_env("true", "/elsewhere", {
    expect_null(divert_covr_traces(lib))
    expect_identical(Sys.getenv("COVERAGE_DIR"), "/elsewhere")
    expect_false(dir.exists(file.path(lib, DAEMON_TRACE_SUBDIR)))
  })
})
