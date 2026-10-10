# A size and voice profile of the help pages and the guides, for comparing
# them with tune's. It reports and never gates: it exits 0 whatever it finds.
#
# Help pages: every `man/*.Rd` (or every `.Rd` in the directory after
# `--man`), and with `--tune` the installed tune and finetune help as well.
# Prose is the text of `\description`, `\details`, `\value`, every
# `\section` body, `\seealso`, and each argument's text in `\arguments`
# without its label. `\references`, `\usage` and `\examples` are not prose.
# Markup is flattened to its text, except that a `\code{}`, `\verb{}`,
# `\preformatted{}`, `\eqn{}`, `\deqn{}` or `\Sexpr{}` node becomes one
# mark, so it counts as one word, or as part of the word it touches with no
# space between. A word is a whitespace-separated token. Sentences split as
# in `sweep-prose.R`.
#
# Guide pages: the page list `sweep-prose.R` declares, or the paths after
# `--pages`. Prose, paragraphs and sentences follow `sweep-prose.R`'s Rmd
# reader, so a table line and a list item are not prose, and a blockquote's
# `>` marker is dropped. `\if{}` and `\out{}` on a help page are not prose
# either. Every backtick span
# counts as one word.
#
# A coined term is a whole-word match of
# `\b([Rr]ecord(s|ed|ing)?|[Rr]efus\w*|orchestrators?|siblings?)\b` in the
# prose, a backtick or `\code{}` span never part of a match. A "You" opener
# is a prose sentence whose first token is `You` or `Your`, matched case
# sensitively and with no punctuation before it.
#
# Columns:
#   help:   page, prose, desc, args, arg_med, arg_max, sections, sent_mean,
#           coined
#   guides: page, prose, paras, para_mean, sent_mean, coined, coined_1k, you
#
# Usage, from the package root:
#   Rscript benchmarks/doc-profile.R [--tune] [--man <dir>] [--pages <path>...]

args <- commandArgs(trailingOnly = TRUE)
with_tune <- "--tune" %in% args

# The Rmd reader and the sentence splitter come from sweep-prose.R itself, so
# the two scripts cannot disagree on what a paragraph or a sentence is.
sweep_env <- new.env()
sweep_env$roxygen <- FALSE
sweep_env$mark <- "•"
local({
  # The script's own folder, read from Rscript's `--file=`, which encodes a
  # space as `~+~`; under `source()` there is none, so fall back to the
  # folder the package root keeps it in.
  file_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  here <- if (length(file_arg)) {
    dirname(gsub("~+~", " ", sub("^--file=", "", file_arg[1]), fixed = TRUE))
  } else {
    "benchmarks"
  }
  exprs <- parse(file.path(here, "sweep-prose.R"), keep.source = FALSE)
  wanted <- c("strip_spans", "rmd_paragraphs", "split_runs", "sentences")
  for (e in exprs) {
    if (
      is.call(e) &&
        identical(e[[1]], as.name("<-")) &&
        is.name(e[[2]]) &&
        as.character(e[[2]]) %in% wanted
    ) {
      eval(e, sweep_env)
    }
  }
  missing <- setdiff(wanted, ls(sweep_env))
  if (length(missing)) {
    stop("sweep-prose.R defines no ", paste(missing, collapse = ", "))
  }
  pages <- eval(
    Find(
      function(e) {
        is.call(e) &&
          identical(e[[1]], as.name("<-")) &&
          identical(e[[2]], as.name("pages"))
      },
      exprs
    )[[3]]
  )
  assign("default_pages", pages, envir = globalenv())
})

# The paths after an option, up to the next `--` option.
option_paths <- function(option) {
  from <- match(option, args) + 1L
  rest <- args[seq.int(from, length.out = max(0L, length(args) - from + 1L))]
  stop_at <- which(startsWith(rest, "--"))
  if (length(stop_at)) {
    rest <- rest[seq_len(stop_at[1] - 1L)]
  }
  if (!length(rest)) {
    stop(option, " names no path", call. = FALSE)
  }
  rest
}

guide_pages <- if ("--pages" %in% args) {
  option_paths("--pages")
} else {
  default_pages
}
man_dir <- if ("--man" %in% args) option_paths("--man") else "man"
if (length(man_dir) != 1L || !dir.exists(man_dir)) {
  stop("--man takes one existing directory", call. = FALSE)
}

# Base R has `%||%` only from 4.4.0, and DESCRIPTION declares an older R.
`%||%` <- function(x, y) if (is.null(x)) y else x

coined_pattern <- "\\b([Rr]ecord(s|ed|ing)?|[Rr]efus\\w*|orchestrators?|siblings?)\\b"
one_word <- "•"

count_coined <- function(text) {
  sum(lengths(regmatches(text, gregexpr(coined_pattern, text, perl = TRUE))))
}

# Sentences of a flattened text, through sweep-prose.R's splitter.
split_sentences <- function(text) {
  text <- gsub("\\s+", " ", trimws(text))
  if (!nzchar(text)) {
    return(data.frame(n = integer(), text = character()))
  }
  sweep_env$sentences(data.frame(line = 1L, text = text))
}

# ---- Help pages -------------------------------------------------------

atomic_tags <- c(
  "\\code",
  "\\verb",
  "\\preformatted",
  "\\eqn",
  "\\deqn",
  "\\Sexpr"
)

flatten_rd <- function(x) {
  tag <- attr(x, "Rd_tag")
  if (is.character(x)) {
    if (identical(tag, "COMMENT")) {
      return("")
    }
    return(paste(x, collapse = ""))
  }
  if (!is.null(tag) && tag %in% atomic_tags) {
    return(one_word)
  }
  # roxygen wraps a code block in `\if{html}{\out{<div ...>}}`, markup that
  # is not prose
  if (!is.null(tag) && tag %in% c("\\if", "\\out")) {
    return("")
  }
  if (identical(tag, "\\href")) {
    return(flatten_rd(x[[2]]))
  }
  if (identical(tag, "\\cr")) {
    return(" ")
  }
  if (identical(tag, "\\item") && length(x) == 0L) {
    return("\n\n")
  }
  paste(vapply(x, flatten_rd, character(1)), collapse = "")
}

rd_words <- function(text) {
  t <- strsplit(trimws(gsub("\\s+", " ", text)), " ")[[1]]
  sum(nzchar(t))
}

profile_rd <- function(rd, page) {
  tags <- vapply(rd, function(n) attr(n, "Rd_tag") %||% "", character(1))
  pick <- function(tag) rd[tags == tag]
  desc <- paste(
    vapply(pick("\\description"), flatten_rd, character(1)),
    collapse = " "
  )
  details <- paste(
    vapply(pick("\\details"), flatten_rd, character(1)),
    collapse = " "
  )
  value <- paste(
    vapply(pick("\\value"), flatten_rd, character(1)),
    collapse = " "
  )
  seealso <- paste(
    vapply(pick("\\seealso"), flatten_rd, character(1)),
    collapse = " "
  )
  sections <- pick("\\section")
  section_text <- vapply(sections, function(s) flatten_rd(s[[2]]), character(1))
  arg_text <- character()
  for (a in pick("\\arguments")) {
    for (item in a) {
      if (identical(attr(item, "Rd_tag"), "\\item") && length(item) == 2L) {
        arg_text <- c(arg_text, flatten_rd(item[[2]]))
      }
    }
  }
  arg_words <- vapply(arg_text, rd_words, integer(1), USE.NAMES = FALSE)
  all_text <- c(desc, details, value, section_text, seealso, arg_text)
  prose <- sum(vapply(all_text, rd_words, integer(1)))
  sents <- do.call(rbind, lapply(all_text, split_sentences))
  data.frame(
    page = page,
    prose = prose,
    desc = rd_words(desc),
    args = length(arg_words),
    arg_med = if (length(arg_words)) stats::median(arg_words) else NA,
    arg_max = if (length(arg_words)) max(arg_words) else NA,
    sections = length(sections),
    sent_mean = if (NROW(sents)) round(mean(sents$n), 1) else NA,
    coined = count_coined(paste(all_text, collapse = " "))
  )
}

help_rows <- lapply(
  sort(list.files(man_dir, "\\.Rd$", full.names = TRUE)),
  function(f) {
    profile_rd(tools::parse_Rd(f, permissive = TRUE), basename(f))
  }
)
if (with_tune) {
  for (pkg in c("tune", "finetune")) {
    db <- tools::Rd_db(pkg)
    for (nm in sort(names(db))) {
      help_rows[[length(help_rows) + 1L]] <- profile_rd(
        db[[nm]],
        paste0(pkg, "::", nm)
      )
    }
  }
}
help <- do.call(rbind, help_rows)

# ---- Guide pages ------------------------------------------------------

profile_page <- function(path) {
  paras <- sweep_env$rmd_paragraphs(path)
  # a blockquote's `>` marker is not a word
  paras <- lapply(paras, function(p) {
    p$text <- sub("^\\s*>\\s?", "", p$text)
    p
  })
  para_sents <- lapply(paras, sweep_env$sentences, all = TRUE)
  para_words <- vapply(
    para_sents,
    function(s) if (is.null(s)) 0L else sum(s$n),
    integer(1)
  )
  sents <- do.call(rbind, para_sents)
  prose <- sum(para_words)
  coined <- if (NROW(sents)) {
    count_coined(paste(sents$text, collapse = " "))
  } else {
    0L
  }
  you <- if (NROW(sents)) {
    sum(grepl("^(You|Your)\\b", sents$text, perl = TRUE))
  } else {
    0L
  }
  data.frame(
    page = path,
    prose = prose,
    paras = length(paras),
    para_mean = if (length(paras)) round(prose / length(paras), 1) else NA,
    sent_mean = if (NROW(sents)) round(mean(sents$n), 1) else NA,
    coined = coined,
    coined_1k = if (prose) round(1000 * coined / prose, 1) else NA,
    you = you
  )
}

guides <- do.call(rbind, lapply(guide_pages, profile_page))

options(width = 200)
cat("help pages\n")
print(help, row.names = FALSE)
cat("\nguide pages\n")
print(guides, row.names = FALSE)
