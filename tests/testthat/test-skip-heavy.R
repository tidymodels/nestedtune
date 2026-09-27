# `skip_heavy_on_cran()` decides which tests CRAN runs (helper-cran.R), so
# both of its arms are pinned here: it skips with both switches unset, and it
# lets the block run when either one reads "true".

# Set the two switches for one call, then put back whatever was there.
with_switches <- function(not_cran, full_suite, code) {
  old <- Sys.getenv(c("NOT_CRAN", "NESTEDTUNE_FULL_SUITE"), unset = NA)
  on.exit({
    for (name in names(old)) {
      if (is.na(old[[name]])) {
        Sys.unsetenv(name)
      } else {
        do.call(Sys.setenv, stats::setNames(list(old[[name]]), name))
      }
    }
  })
  pairs <- list(
    c("NOT_CRAN", not_cran),
    c("NESTEDTUNE_FULL_SUITE", full_suite)
  )
  for (pair in pairs) {
    if (is.na(pair[[2]])) {
      Sys.unsetenv(pair[[1]])
    } else {
      do.call(Sys.setenv, stats::setNames(list(pair[[2]]), pair[[1]]))
    }
  }
  code
}

test_that("skip_heavy_on_cran() skips when neither switch is set", {
  cnd <- with_switches(NA, NA, tryCatch(skip_heavy_on_cran(), skip = identity))
  expect_s3_class(cnd, "skip")
  expect_match(
    conditionMessage(cnd),
    "NESTEDTUNE_FULL_SUITE=true",
    fixed = TRUE
  )
})

test_that("skip_heavy_on_cran() skips when neither switch reads as true", {
  cnd <- with_switches(
    "false",
    "1",
    tryCatch(skip_heavy_on_cran(), skip = identity)
  )
  expect_s3_class(cnd, "skip")
})

test_that("skip_heavy_on_cran() runs the block when NOT_CRAN is \"true\"", {
  out <- with_switches(
    "true",
    NA,
    tryCatch(skip_heavy_on_cran(), skip = identity)
  )
  expect_true(out)
})

test_that("skip_heavy_on_cran() reads \"TRUE\" and \"T\" as true, as testthat does", {
  expect_true(with_switches("TRUE", NA, skip_heavy_on_cran()))
  expect_true(with_switches(NA, "T", skip_heavy_on_cran()))
})

test_that("skip_heavy_on_cran() runs the block when NESTEDTUNE_FULL_SUITE is \"true\"", {
  out <- with_switches(
    NA,
    "true",
    tryCatch(skip_heavy_on_cran(), skip = identity)
  )
  expect_true(out)
})
