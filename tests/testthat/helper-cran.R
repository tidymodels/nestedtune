# Which tests CRAN runs.
#
# CRAN checks with `NOT_CRAN` unset and gives each package a few minutes of
# CPU. The whole suite takes far more than that, so the tests outside a small
# smoke layer call `skip_heavy_on_cran()`. The smoke layer is the input
# refusals, the readers, and one end-to-end run per exported `nested_*`
# function.
#
# `NOT_CRAN` alone cannot be the switch. The `R-CMD-check.yaml` matrix runs
# with it unset, as CRAN does, and setting it there would also start the mirai
# daemon tests that `skip_if_no_daemons()` keeps off those legs. So a second
# variable, `NESTEDTUNE_FULL_SUITE`, runs these tests without touching the
# daemon tests. `devtools::test()` sets `NOT_CRAN`, so a local run keeps
# every test.
skip_heavy_on_cran <- function() {
  if (
    identical(Sys.getenv("NOT_CRAN"), "true") ||
      identical(Sys.getenv("NESTEDTUNE_FULL_SUITE"), "true")
  ) {
    return(invisible(TRUE))
  }
  testthat::skip(
    "Outside the CRAN smoke layer; set NESTEDTUNE_FULL_SUITE=true to run it"
  )
}
