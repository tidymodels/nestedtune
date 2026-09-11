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
  for (name in c(
    "semicolon",
    "contraction",
    "has been",
    "modal",
    "comma-ing"
  )) {
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

# The six gating modes over the real pages and roxygen sources. Under
# `R CMD check` the tests run from the built tarball, which `.Rbuildignore`
# strips `benchmarks/` from, so this block skips there; the source tree and
# `.github/workflows/prose-sweep.yaml` are where it runs.

test_that("the six gating sweeps are clean over the real sources", {
  script <- testthat::test_path("..", "..", "benchmarks", "sweep-prose.R")
  skip_if_not(file.exists(script), "sweep-prose.R not in the source tree")
  script <- normalizePath(script)
  root <- normalizePath(testthat::test_path("..", ".."))

  sweep <- function(...) {
    out <- suppressWarnings(system2(
      "Rscript",
      c(script, ...),
      stdout = TRUE,
      stderr = TRUE
    ))
    list(status = attr(out, "status"), lines = out)
  }
  # `system2()` runs from the working directory, and the script reads its
  # page list relative to the package root. The `on.exit()` restores it on
  # every exit, which matters under parallel files: a worker runs several
  # files in one process, and `test-suite-hygiene.R` resolves `test_path()`
  # against the working directory.
  old <- setwd(root)
  on.exit(setwd(old), add = TRUE)

  # the domain is non-empty: every page and the roxygen source list at
  # least one paragraph, so a clean sweep below is a sweep over prose
  pages <- c(
    "README.Rmd",
    "vignettes/articles/parallel.Rmd",
    "vignettes/estimate.Rmd",
    "vignettes/nested-cv.Rmd",
    "vignettes/results.Rmd",
    "vignettes/tuners.Rmd"
  )
  paragraphs <- sweep("--paragraphs")
  expect_null(paragraphs$status)
  for (page in pages) {
    expect_true(
      any(startsWith(paragraphs$lines, paste0(page, ":"))),
      label = sprintf("`--paragraphs` lists a paragraph for %s", page)
    )
  }
  roxygen <- sweep("--roxygen", "--paragraphs")
  expect_null(roxygen$status)
  expect_true(any(startsWith(roxygen$lines, "R/nested-tune-grid.R:")))

  modes <- list(
    character(),
    "--spans",
    "--plain",
    "--roxygen",
    c("--roxygen", "--spans"),
    c("--roxygen", "--plain")
  )
  for (mode in modes) {
    result <- sweep(mode)
    label <- paste(c("sweep-prose.R", mode), collapse = " ")
    expect_null(result$status, label = label)
    expect_identical(result$lines, "clean", label = label)
  }
})
