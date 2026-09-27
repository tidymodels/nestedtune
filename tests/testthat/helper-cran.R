# Which tests CRAN runs.
#
# CRAN checks with `NOT_CRAN` unset and gives each package a few minutes of
# CPU. The whole suite takes far more than that, so the tests outside a small
# smoke layer call `skip_heavy_on_cran()`. The smoke layer is the input
# refusals, the readers, one end-to-end run per exported `nested_*` function,
# and any other file that took under 2 s at the branch point; the M118
# milestone record lists it file by file.
#
# `NOT_CRAN` set to true runs every test. `devtools::test()` sets it, and so
# does `r-lib/actions/setup-r` in every CI job, so both run the full suite.
# `NESTEDTUNE_FULL_SUITE=true` runs these tests with `NOT_CRAN` unset, for
# example in a hand-run `R CMD check` that should still skip the tests
# `skip_on_cran()` guards. Either variable counts when `as.logical()` reads it
# as TRUE, so "true", "TRUE" and "T" all work.
skip_heavy_on_cran <- function() {
  if (
    isTRUE(as.logical(Sys.getenv("NOT_CRAN"))) ||
      isTRUE(as.logical(Sys.getenv("NESTEDTUNE_FULL_SUITE")))
  ) {
    return(invisible(TRUE))
  }
  testthat::skip(
    "Outside the CRAN smoke layer; set NESTEDTUNE_FULL_SUITE=true to run it"
  )
}
