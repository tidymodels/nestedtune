# The Differences sections of the four tuner pages render each run-in
# heading's paragraph whole. The bayes, race and sim-anneal sections hold one
# list each, and the grid section holds none (M97, AC1 to AC3).
#
# A rendering is what `tools::Rd2txt()` prints for the page under the
# options below. A paragraph is a run of consecutive non-blank lines, joined
# with single spaces. Anchors carry no backticks, because `\code{}` renders
# as plain single quotes. The pages come from `tools::Rd_db()`: the installed
# database under `R CMD check`, where `man/` is not on disk, and the source
# tree's otherwise.

help_db <- local({
  db <- NULL
  function() {
    if (is.null(db)) {
      root <- test_path("..", "..")
      db <<- if (file.exists(file.path(root, "man"))) {
        tools::Rd_db(dir = root)
      } else {
        tools::Rd_db("nestedtune")
      }
    }
    db
  }
})

structure_rd <- function(topic) {
  rd <- help_db()[[paste0(topic, ".Rd")]]
  if (is.null(rd)) {
    rlang::abort(paste0("no page '", topic, ".Rd' in the Rd database"))
  }
  rd
}

structure_tag <- function(x) attr(x, "Rd_tag")

structure_text <- function(x) {
  if (is.character(x)) {
    return(paste(x, collapse = ""))
  }
  paste(vapply(x, structure_text, character(1)), collapse = "")
}

DIFFERENCES_TITLE <- c(
  nested_tune_grid = "Differences from calling tune directly",
  nested_tune_bayes = "Differences from calling tune directly",
  nested_tune_race = "Differences from calling finetune directly",
  nested_tune_sim_anneal = "Differences from calling finetune directly"
)

# The parsed body of the page's Differences section.
differences_body <- function(topic) {
  title <- DIFFERENCES_TITLE[[topic]]
  for (node in structure_rd(topic)) {
    if (
      identical(structure_tag(node), "\\section") &&
        identical(trimws(structure_text(node[[1L]])), title)
    ) {
      return(node[[2L]])
    }
  }
  rlang::abort(paste0("no '", title, "' section on ", topic))
}

# The `\itemize` elements directly under the section body.
section_lists <- function(body) {
  Filter(function(n) identical(structure_tag(n), "\\itemize"), body)
}

# The rendered lines of the page's Differences section: from the line after
# its title line to the line before the next section title. A title sits at
# column 0; the body is indented.
rendered_differences <- function(topic) {
  title <- DIFFERENCES_TITLE[[topic]]
  lines <- rlang::with_options(
    utils::capture.output(tools::Rd2txt(
      structure_rd(topic),
      options = list(underline_titles = FALSE)
    )),
    useFancyQuotes = FALSE
  )
  start <- which(lines == paste0(title, ":"))
  if (length(start) != 1L) {
    rlang::abort(paste0("section title found ", length(start), " times"))
  }
  rest <- lines[-seq_len(start)]
  ends <- which(grepl("^[^[:space:]]", rest))
  if (length(ends)) {
    rest <- rest[seq_len(ends[[1L]] - 1L)]
  }
  rest
}

# The rendered paragraphs, each joined with single spaces, named by the
# line number their first line sits on.
rendered_paragraphs <- function(lines) {
  blank <- !nzchar(trimws(lines))
  runs <- split(which(!blank), cumsum(blank)[!blank])
  out <- vapply(
    runs,
    function(run) paste(trimws(lines[run]), collapse = " "),
    character(1),
    USE.NAMES = FALSE
  )
  names(out) <- vapply(runs, function(run) run[[1L]], integer(1))
  out
}

# The one paragraph that contains `anchor`, its first line number as name.
paragraph_with <- function(paragraphs, anchor) {
  hits <- paragraphs[grepl(anchor, paragraphs, fixed = TRUE)]
  expect_length(hits, 1L)
  hits
}

BULLET <- "^[[:space:]]*•"

test_that("the grid page's forced paragraph carries the contention sentence", {
  paragraphs <- rendered_paragraphs(rendered_differences("nested_tune_grid"))
  forced <- paragraph_with(paragraphs, "Forced:")
  expect_match(
    forced,
    "Leaving parallelism to a caller puts two pools in contention.",
    fixed = TRUE
  )
})

SETTABLE_ANCHOR <- c(
  nested_tune_bayes = "are arguments of 'tune_bayes()'",
  nested_tune_race = "'grid' and 'eval_time' are the racing functions' own arguments",
  nested_tune_sim_anneal = "are arguments of 'tune_sim_anneal()'"
)

for (topic in names(SETTABLE_ANCHOR)) {
  test_that(paste("the settable paragraph carries its tail on", topic), {
    paragraphs <- rendered_paragraphs(rendered_differences(topic))
    settable <- paragraph_with(paragraphs, "Settable as its own argument:")
    expect_match(settable, SETTABLE_ANCHOR[[topic]], fixed = TRUE)
  })

  test_that(paste("the Differences section holds one list on", topic), {
    lists <- section_lists(differences_body(topic))
    expect_length(lists, 1L)
    expect_false(grepl(
      "behave as the grid page describes",
      structure_text(lists[[1L]]),
      fixed = TRUE
    ))

    lines <- rendered_differences(topic)
    bullets <- grep(BULLET, lines)
    expect_gt(length(bullets), 0L)
    shared <- paragraph_with(
      rendered_paragraphs(lines),
      "behave as the grid page describes"
    )
    expect_gt(as.integer(names(shared)), max(bullets))
  })
}

test_that("the grid page's Differences section holds no list", {
  expect_length(section_lists(differences_body("nested_tune_grid")), 0L)
})
