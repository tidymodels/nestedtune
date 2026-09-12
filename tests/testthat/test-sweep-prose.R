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

# The parse over a second hand-authored fixture: one planted leak per class
# of line the prose definition excludes, and one sentence whose clause marker
# sits across a backtick span, which the sweep must still report.

test_that("the parse drops every planted leak and keeps the prose beside it", {
  script <- testthat::test_path("..", "..", "benchmarks", "sweep-prose.R")
  skip_if_not(file.exists(script), "sweep-prose.R not in the source tree")
  fixture <- testthat::test_path("fixtures", "sweep-prose-parse.Rmd")
  lines <- readLines(fixture)

  sweep <- function(...) {
    out <- suppressWarnings(system2(
      "Rscript",
      c(script, ..., "--pages", fixture),
      stdout = TRUE,
      stderr = TRUE
    ))
    list(status = attr(out, "status"), lines = out)
  }

  # the line a plant sits on, found by a string only that plant carries
  at <- function(text) {
    i <- grep(text, lines, fixed = TRUE)
    expect_length(i, 1L)
    i
  }
  plants <- list(
    badge = at("[![R-CMD-check]"),
    `comment body` = at("This middle line would be read"),
    `indented fence` = at("an indented fence whose body"),
    `bulleted wrap` = at("should be read as the procedure's error"),
    `numbered item` = at("reports it as ordinary prose with far more")
  )
  straddle <- at("The reader takes the")
  closing <- at("The page ends on a short prose line.")

  paragraphs <- sweep("--paragraphs")
  expect_null(paragraphs$status)
  extents <- regmatches(
    paragraphs$lines,
    regexec("^.*:([0-9]+)-([0-9]+): ", paragraphs$lines)
  )
  covered <- unlist(lapply(extents, function(m) {
    seq.int(as.integer(m[2]), as.integer(m[3]))
  }))
  for (name in names(plants)) {
    expect_false(
      plants[[name]] %in% covered,
      label = sprintf("a paragraph's extent holds the %s plant", name)
    )
  }
  # the domain is non-empty, and the two prose paragraphs are the only ones
  expect_true(straddle %in% covered)
  expect_true(closing %in% covered)
  expect_length(paragraphs$lines, 2L)

  # the marker across the backtick span is still reported, and it is the
  # only clause the page yields
  plain <- sweep("--plain")
  expect_identical(plain$status, 1L)
  expect_length(plain$lines, 2L)
  expect_match(plain$lines[1], sprintf("^%s:%d: modal: ", fixture, straddle))
  expect_match(plain$lines[1], "should read every fold from them\\.$")
  expect_identical(plain$lines[2], "1 hit(s)")

  # the numbered item's over-cap sentence is the only one past the cap, and
  # it is gone with the item
  bare <- sweep()
  expect_null(bare$status)
  expect_identical(bare$lines, "clean")
})

# A dropped line never takes prose with it: the two shapes where the parse
# could go quiet over a page rather than leak into it, each on a written page
# rather than the committed fixture, which the block above counts paragraphs
# on.

test_that("an unclosed comment and a dropped item-shaped line take no prose", {
  script <- testthat::test_path("..", "..", "benchmarks", "sweep-prose.R")
  skip_if_not(file.exists(script), "sweep-prose.R not in the source tree")

  # base R rather than withr, which is deliberately not a dependency here
  pages <- character()
  on.exit(unlink(pages), add = TRUE)
  plain <- function(text) {
    page <- tempfile(fileext = ".Rmd")
    pages <<- c(pages, page)
    writeLines(text, page)
    out <- suppressWarnings(system2(
      "Rscript",
      c(script, "--plain", "--pages", page),
      stdout = TRUE,
      stderr = TRUE
    ))
    as.character(sub("^.*:([0-9]+): ", "\\1: ", out))
  }

  # an opener with no `-->` under it closes nothing, so the prose below it is
  # still read; a closed comment still takes its whole body
  expect_identical(
    plain(c("<!-- an opener with no closer", "", "It should be read.")),
    c("3: modal: It should be read.", "1 hit(s)")
  )
  expect_identical(
    plain(c("<!-- an opener", "It should not be read.", "-->")),
    "clean"
  )

  # an item-shaped line the parser already dropped opens no run: it is read
  # neither in the YAML header nor inside a fenced chunk
  expect_identical(
    plain(c("---", "author:", "  - Someone", "---", "It should be read.")),
    c("5: modal: It should be read.", "1 hit(s)")
  )
  expect_identical(
    plain(c("```yaml", "- an item shaped line", "```", "It should be read.")),
    c("4: modal: It should be read.", "1 hit(s)")
  )
  # a real list item still takes the lines it wraps onto
  expect_identical(
    plain(c("- An item", "  it should not be read.")),
    "clean"
  )
})

# The gating modes over the real pages and roxygen sources. The script owns
# both lists and this block names neither: `--list-pages` gives the pages and
# `--list-gating` gives the invocations. What is stated here instead of read
# off the script is their shape, so a list that emptied or lost a mode is
# still a failure. Under `R CMD check` the tests run from the built tarball,
# which `.Rbuildignore` strips `benchmarks/` from, so this block skips there;
# the source tree and `.github/workflows/prose-sweep.yaml` are where it runs.

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

  # the page list comes from the script; its shape is stated here
  listed <- sweep("--list-pages")
  expect_null(listed$status)
  pages <- listed$lines
  expect_length(pages, 6L)
  expect_true(all(file.exists(pages)))

  # so do the gating invocations, each the script call and its flags
  listed <- sweep("--list-gating")
  expect_null(listed$status)
  expect_length(listed$lines, 6L)
  expect_true(all(
    startsWith(listed$lines, "Rscript benchmarks/sweep-prose.R")
  ))
  flags <- sub("^Rscript benchmarks/sweep-prose\\.R *", "", listed$lines)
  modes <- lapply(flags, function(f) {
    if (nzchar(f)) strsplit(f, " +")[[1]] else character()
  })
  # one sweep carries no flag, and three of the six read the roxygen sources
  expect_length(Filter(function(m) !length(m), modes), 1L)
  expect_length(Filter(function(m) "--roxygen" %in% m, modes), 3L)

  # the domain is non-empty: every page and the roxygen source list at
  # least one paragraph, so a clean sweep below is a sweep over prose
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

  for (mode in modes) {
    result <- sweep(mode)
    label <- paste(c("sweep-prose.R", mode), collapse = " ")
    expect_null(result$status, label = label)
    expect_identical(result$lines, "clean", label = label)
  }
})
