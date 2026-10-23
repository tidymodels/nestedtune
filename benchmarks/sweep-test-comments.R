# The id sweep over the test files: tracking ids, dates and run numbers in
# the comments, in the notes of the time-budget ledger and in the test names.
#
# Files: every `test-*.R`, `helper-*.R` and `teardown-*.R` under
# `tests/testthat/`, and `tests/testthat.R`. The script lists them with
# `list.files()` and stops unless that list equals `Sys.glob()` of the same
# patterns and is not empty. A comment is a `COMMENT` token of
# `getParseData()`. A ledger note is the `note` argument of a `tb_row()`
# call in `helper-time-budget.R`, matched against `tb_row()`'s own formals,
# which the script reads from that file.
#
# The pattern (`id_pattern` below) matches, as whole words:
#   milestone   `M` and two or three digits (`M07`, `M155`)
#   decision    `D-` and digits, or `D` and one or two digits (`M10-D1`)
#   review      `RR` or `RB` and digits; a finding, oracle, task or question
#               id: one of `B F O P Q R S T` and one or two digits, less the
#               class systems `S3`, `S4`, `S7` and `R6`
#   criterion   `AC` or `BC` and digits
#   principle   `IP` or `GP` and digits
#   date        `YYYY-MM-DD`
#   run         `run` and five or more digits, or an `actions/runs/` URL
#   PR          `PR #N` or `PR N`. A bare `#N` is an issue citation and passes
#   oracle type `-- type "`, the header label of the oracle files
#
# Modes (run from the package root):
#   Rscript benchmarks/sweep-test-comments.R
#       every comment and ledger note matching the pattern, as
#       `file:line: <match>: <text>`; exits 1 on any hit
#   Rscript benchmarks/sweep-test-comments.R --counts
#       the number of matching comments and notes per file, files with none
#       left out; exits 0
#   Rscript benchmarks/sweep-test-comments.R --names blocks.csv
#       every value of the `test` column of a `benchmarks/test-blocks.R`
#       table that matches the pattern, and every name used twice in one
#       file, as `file: <reason>: <name>`; exits 1 on any hit
#
# Each mode first runs the planted cases: the pattern must match a
# milestone id and stay silent on an issue number, or the script stops.

id_pattern <- paste0(
  "\\b(",
  "M[0-9]{2,3}",
  "|D-[0-9]+|D[0-9]{1,2}",
  "|R[RB][0-9]+",
  "|(?!S3\\b|S4\\b|S7\\b|R6\\b)[BFOPQRST][0-9]{1,2}",
  "|AC[0-9]+|BC[0-9]+",
  "|IP[0-9]+|GP[0-9]+",
  "|[0-9]{4}-[0-9]{2}-[0-9]{2}",
  "|run [0-9]{5,}|actions/runs/[0-9]+",
  "|PR #?[0-9]+",
  ")\\b",
  "|-- type \""
)

id_match <- function(text) {
  m <- regmatches(text, regexpr(id_pattern, text, perl = TRUE))
  out <- rep(NA_character_, length(text))
  out[grepl(id_pattern, text, perl = TRUE)] <- m
  out
}

planted_hit <- "# The refusal covers both loops (M155)."
planted_quiet <- c(
  "# The refusal covers both loops (#123).",
  "# S3 dispatch finds the method; R6 members are locked."
)
if (is.na(id_match(planted_hit)) || any(!is.na(id_match(planted_quiet)))) {
  stop("the pattern failed its planted cases", call. = FALSE)
}

args <- commandArgs(trailingOnly = TRUE)
mode <- if (length(args)) args[1L] else ""

if (identical(mode, "--names")) {
  blocks <- utils::read.csv(args[2L], stringsAsFactors = FALSE)
  stopifnot(nrow(blocks) > 0L)
  hit <- id_match(blocks$test)
  dup <- duplicated(blocks[c("file", "test")])
  for (i in which(!is.na(hit))) {
    cat(sprintf("%s: %s: %s\n", blocks$file[i], hit[i], blocks$test[i]))
  }
  for (i in which(dup)) {
    cat(sprintf("%s: duplicate: %s\n", blocks$file[i], blocks$test[i]))
  }
  quit(status = as.integer(any(!is.na(hit)) || any(dup)))
}

dir <- "tests/testthat"
files <- c(
  file.path(dir, list.files(dir, "^(test|helper|teardown)-.*\\.R$")),
  "tests/testthat.R"
)
glob <- c(
  Sys.glob(file.path(dir, c("test-*.R", "helper-*.R", "teardown-*.R"))),
  "tests/testthat.R"
)
stopifnot(length(files) > 1L, setequal(files, glob))

comments <- do.call(
  rbind,
  lapply(files, function(f) {
    pd <- utils::getParseData(parse(f, keep.source = TRUE))
    pd <- pd[pd$token == "COMMENT", ]
    data.frame(file = rep(f, nrow(pd)), line = pd$line1, text = pd$text)
  })
)

# The ledger notes. `tb_row()`'s formals come from its definition in the
# helper, so a note passed by position is found as well as one passed by name.
ledger <- file.path(dir, "helper-time-budget.R")
exprs <- parse(ledger, keep.source = TRUE)
def <- Filter(
  function(e) is.call(e) && identical(e[[2L]], quote(tb_row)),
  as.list(exprs)
)
stopifnot(length(def) == 1L)
tb_def <- eval(def[[1L]][[3L]], baseenv())
srcref <- attr(exprs, "srcref")
notes <- list()
walk <- function(e, line) {
  # An empty argument, as in `x[, 1]`, arrives missing.
  if (missing(e) || !is.call(e)) {
    return(invisible())
  }
  if (identical(e[[1L]], quote(tb_row))) {
    note <- match.call(tb_def, e)$note
    if (!is.null(note)) {
      if (!is.character(note)) {
        stop("a `tb_row()` note is not a string literal", call. = FALSE)
      }
      notes[[length(notes) + 1L]] <<- data.frame(
        file = ledger,
        line = line,
        text = note
      )
    }
  }
  for (a in as.list(e)[-1L]) {
    walk(a, line)
  }
}
for (i in seq_along(exprs)) {
  walk(exprs[[i]], srcref[[i]][1L])
}
notes <- do.call(rbind, notes)
stopifnot(nrow(notes) > 0L)

all <- rbind(comments, notes)
all$match <- id_match(all$text)
hits <- all[!is.na(all$match), ]

if (identical(mode, "--counts")) {
  counts <- table(factor(hits$file, levels = files))
  counts <- counts[counts > 0L]
  for (f in names(counts)) {
    cat(sprintf("%5d  %s\n", counts[[f]], f))
  }
  cat(sprintf(
    "%d matches in %d of %d files (%d comments, %d ledger notes read)\n",
    nrow(hits),
    length(counts),
    length(files),
    nrow(comments),
    nrow(notes)
  ))
  quit(status = 0L)
}

for (i in seq_len(nrow(hits))) {
  cat(sprintf(
    "%s:%d: %s: %s\n",
    hits$file[i],
    hits$line[i],
    hits$match[i],
    trimws(hits$text[i])
  ))
}
quit(status = as.integer(nrow(hits) > 0L))
