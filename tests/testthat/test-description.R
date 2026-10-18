# CRAN asks that package names in a DESCRIPTION's Title and Description sit
# in single quotes. The names checked are the package's own and every package
# its Depends, Imports and Suggests fields declare, R excepted. A word is a
# maximal run of letters, digits and dots, matched without regard to case.
# Trailing dots are also dropped before matching, since a package name never
# ends in one and a name that ends a sentence would otherwise be missed.
#
# The source tree's DESCRIPTION is read when the suite runs from it. Under
# `R CMD check` the tests run from a copy with no DESCRIPTION above them, so
# the installed package's is read there.

description_fields <- function() {
  path <- test_path("..", "..", "DESCRIPTION")
  if (!file.exists(path)) {
    path <- system.file("DESCRIPTION", package = "nestedtune")
  }
  read.dcf(path)
}

declared_names <- function(dcf) {
  fields <- intersect(c("Depends", "Imports", "Suggests"), colnames(dcf))
  entries <- unlist(strsplit(dcf[1L, fields], ","), use.names = FALSE)
  names <- trimws(sub("\\(.*$", "", entries))
  names <- names[nzchar(names) & names != "R"]
  unique(c(dcf[1L, "Package"], names))
}

# The declared names that occur in `text` as a word not enclosed in single
# quotes, in the order they occur.
unquoted_names <- function(text, names) {
  text <- gsub("[[:space:]]+", " ", text)
  hits <- gregexpr("[A-Za-z0-9.]+", text)[[1L]]
  if (hits[[1L]] == -1L) {
    return(character())
  }
  words <- regmatches(text, list(hits))[[1L]]
  ends <- hits + attr(hits, "match.length") - 1L
  before <- substring(text, hits - 1L, hits - 1L)
  after <- substring(text, ends + 1L, ends + 1L)
  key <- tolower(words)
  stripped <- sub("[.]+$", "", key)
  named <- key %in% tolower(names) | stripped %in% tolower(names)
  quoted <- before == "'" & after == "'"
  words[named & !quoted]
}

test_that("the checker finds an unquoted name and passes a quoted one", {
  names <- c("nestedtune", "tune", "mirai")
  expect_identical(unquoted_names("Tunes with tune.", names), "tune.")
  expect_identical(unquoted_names("Runs on Mirai daemons", names), "Mirai")
  expect_identical(
    unquoted_names("Runs with 'mirai' and 'tune'.", names),
    character()
  )
  # A longer word that holds a name is not the name.
  expect_identical(unquoted_names("finetune tuned", names), character())
})

test_that("every declared package name in Title and Description is quoted", {
  dcf <- description_fields()
  names <- declared_names(dcf)
  expect_true(all(c("tune", "rsample", "workflows") %in% names))
  for (field in c("Title", "Description")) {
    expect_identical(
      unquoted_names(dcf[1L, field], names),
      character(),
      label = paste("unquoted package names in", field)
    )
  }
})
