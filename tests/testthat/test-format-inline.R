# A string written across two source lines with a trailing backslash is joined
# into one line by `cli_abort()`, `cli_warn()`, `cli_bullets()` and
# `cli_text()`, but not by `cli::format_inline()`. There it keeps the newline
# and the indent, and with glue braces in the string it keeps the backslash
# too, so the sentence reached the reader broken across two lines.

test_that("a rendered identity difference carries no continuation artefact", {
  base <- list(
    model = list(
      class = "linear_reg",
      engine = "lm",
      mode = "regression",
      args = list(a = "1", b = "2"),
      eng_args = list()
    ),
    preprocessor = list(kind = "formula", formula = "y ~ x")
  )
  reordered <- base
  reordered$model$args <- list(b = "2", a = "1")

  message <- identity_difference(base, reordered)
  expect_match(
    message,
    "recorded in the order \"a\" and \"b\", given in the order \"b\" and \"a\".",
    fixed = TRUE
  )
  expect_no_match(message, "\\", fixed = TRUE)
  expect_no_match(message, "\n", fixed = TRUE)
})

test_that("no string with a backslash continuation reaches format_inline()", {
  src <- test_path("..", "..", "R")
  skip_if_not(dir.exists(src), "R/ not in the source tree")

  # Parse data, not a text search, so a continuation in a comment or in a
  # string bound for `cli_abort()` is told apart from one this bug reaches.
  # A string counts when it sits anywhere inside a `format_inline()` call,
  # so one wrapped in `paste0()` first is found as well.
  offending <- character()
  for (file in list.files(src, pattern = "[.]R$", full.names = TRUE)) {
    pd <- utils::getParseData(parse(file, keep.source = TRUE))
    calls <- pd$parent[
      pd$token == "SYMBOL_FUNCTION_CALL" & pd$text == "format_inline"
    ]
    # The call expression is the parent of the parent of the function name.
    roots <- pd$parent[match(calls, pd$id)]
    for (root in roots) {
      inside <- root
      frontier <- root
      while (length(frontier) > 0L) {
        frontier <- pd$id[pd$parent %in% frontier]
        inside <- c(inside, frontier)
      }
      strs <- pd[pd$id %in% inside & pd$token == "STR_CONST", ]
      hit <- strs[grepl("\\\\\n", strs$text), ]
      offending <- c(
        offending,
        sprintf("%s:%d", basename(file), hit$line1)
      )
    }
  }
  expect_identical(offending, character())
})
