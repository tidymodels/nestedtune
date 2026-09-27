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
  for (pair in list(c("NOT_CRAN", not_cran), c("NESTEDTUNE_FULL_SUITE", full_suite))) {
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
  expect_match(conditionMessage(cnd), "NESTEDTUNE_FULL_SUITE=true", fixed = TRUE)
})

test_that("skip_heavy_on_cran() skips when a switch reads anything but \"true\"", {
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

test_that("skip_heavy_on_cran() runs the block when NESTEDTUNE_FULL_SUITE is \"true\"", {
  out <- with_switches(
    NA,
    "true",
    tryCatch(skip_heavy_on_cran(), skip = identity)
  )
  expect_true(out)
})
