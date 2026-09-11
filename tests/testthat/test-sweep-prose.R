# The plain sweep of benchmarks/sweep-prose.R over a hand-authored fixture:
# each clause is named once, a wrapped sentence at its first line, and a
# sentence whose markers sit in backtick spans or near a clause is silent.

test_that("--plain names each clause once and stays silent on spans and near-misses", {
  script <- testthat::test_path("..", "..", "benchmarks", "sweep-prose.R")
  skip_if_not(file.exists(script), "sweep-prose.R not in the source tree")
  fixture <- testthat::test_path("fixtures", "sweep-prose-plain.Rmd")

  out <- suppressWarnings(system2(
    "Rscript",
    c(script, "--plain", "--pages", fixture),
    stdout = TRUE,
    stderr = TRUE
  ))
  status <- attr(out, "status")
  expect_identical(status, 1L)

  lines <- readLines(fixture)
  hits <- grep(sprintf("^%s:", fixture), out, value = TRUE, fixed = FALSE)

  clause_lines <- function(name) {
    grep(sprintf("^%s:[0-9]+: %s", fixture, name), hits, value = TRUE)
  }
  for (name in c("semicolon", "contraction", "has been", "modal", "comma-ing")) {
    expect_length(clause_lines(paste0(name, ": ")), 1L)
  }
  expect_length(clause_lines("slop \\(just\\): "), 1L)
  expect_length(hits, 6L)

  # the mixed-case modal sentence wraps across two lines and is reported at
  # the line its first word sits on
  first <- grep("^The score MAY look", lines)
  expect_length(first, 1L)
  expect_match(clause_lines("modal: "), sprintf("^%s:%d: ", fixture, first))

  expect_false(any(grepl("are code", hits, fixed = TRUE)))
  expect_false(any(grepl("shouldering", hits, fixed = TRUE)))
  expect_identical(tail(out, 1), "6 hit(s)")
})
