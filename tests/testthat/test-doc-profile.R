# benchmarks/doc-profile.R over two hand-counted fixtures. Each expected
# figure below was counted by hand from the fixture, not read off the script.
# The fixtures also plant what must not count: a `\references` section, a
# `\code{}` span holding a coined word and the `\if{html}{\out{}}` wrappers
# of a code block on the help page, and a table, a list item, a chunk, a
# blockquote marker and a "Young" opener on the guide page.

profile_tables <- function(out) {
  at_help <- match("help pages", out)
  at_guides <- match("guide pages", out)
  read <- function(lines) {
    utils::read.table(text = lines, header = TRUE, stringsAsFactors = FALSE)
  }
  list(
    help = read(out[(at_help + 1L):(at_guides - 2L)]),
    guides = read(out[(at_guides + 1L):length(out)])
  )
}

test_that("doc-profile.R counts each measure on the planted pages", {
  script <- testthat::test_path("..", "..", "benchmarks", "doc-profile.R")
  skip_if_not(file.exists(script), "doc-profile.R not in the source tree")

  out <- system2(
    "Rscript",
    c(
      script,
      "--man",
      testthat::test_path("fixtures", "doc-profile-man"),
      "--pages",
      testthat::test_path("fixtures", "doc-profile.Rmd")
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  expect_null(attr(out, "status"))
  tables <- profile_tables(out)

  help <- tables$help
  expect_identical(help$page, "plant.Rd")
  # 5 description + 8 details + 4 value + 4 section + 2 see-also + 3 + 5
  # argument words; the references section is left out, the section's
  # `\code{x},` is one word with its comma, and the details' code block is
  # one word with its `\if{html}{\out{...}}` wrappers counting nothing
  expect_identical(help$prose, 31L)
  expect_identical(help$desc, 5L)
  expect_identical(help$args, 2L)
  expect_equal(help$arg_med, 4)
  expect_identical(help$arg_max, 5L)
  expect_identical(help$sections, 1L)
  # 31 words over 9 sentences
  expect_equal(help$sent_mean, 3.4)
  # "record" and "refuse"; the `\code{refused}` span and the references
  # section do not count
  expect_identical(help$coined, 2L)

  guides <- tables$guides
  # 10 + 8 + 9 + 3 words over four paragraphs; the table, list item and
  # chunk are not prose, each backtick span is one word, and the blockquote's
  # `>` is not a word
  expect_identical(guides$prose, 30L)
  expect_identical(guides$paras, 4L)
  expect_equal(guides$para_mean, 7.5)
  expect_equal(guides$sent_mean, 5)
  # "records" only; "refused" and "refuses" sit outside the prose
  expect_identical(guides$coined, 1L)
  expect_equal(guides$coined_1k, 33.3)
  # "You", "Your" and the blockquoted "You" open sentences; "Young" does not
  expect_identical(guides$you, 3L)
})
