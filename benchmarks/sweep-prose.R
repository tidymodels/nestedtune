# The prose sweep over the user-facing pages: a sentence cap and a first-use
# locator for the package's own words.
#
# Pages: the four guides and the parallel article under `vignettes/`, and
# `README.Rmd`. Prose is what is left after the YAML header (everything
# between the first two `---` lines), fenced chunks, HTML comment lines,
# heading lines and list-item lines are dropped and backtick spans (inline
# `r` spans included) are removed. Sentences split at `.`, `?` or `!`
# followed by whitespace or the end of the text, with `et al.`, `e.g.`,
# `i.e.` and `vs.` joined first; a word is a whitespace-separated token.
#
# Modes (run from the package root):
#   Rscript benchmarks/sweep-prose.R
#       every prose sentence over 30 words, as `file:line: <n> words: <text>`,
#       `line` the line the sentence starts on; exits 1 on any hit
#   Rscript benchmarks/sweep-prose.R --terms
#       each page's first prose sentence containing `procedure`,
#       `orchestrator` or `candidate` (whole word, any case, plural included),
#       and `reader` on results.Rmd, as `file:line: <word>: <text>`; exits 0
#   Rscript benchmarks/sweep-prose.R --roxygen [--terms]
#       the same two checks over roxygen prose in `R/*.R` and
#       `man-roxygen/*.R`: the bodies of `@title`, `@description`,
#       `@details`, `@param`, `@return` and `@section` and the untagged lines
#       belonging to them, every other tag and every `@examples` block
#       excluded; `[link]` targets and `\code{}` spans removed as well. With
#       `--terms`, first occurrences are per roxygen block, `reader` read on
#       every file.

args <- commandArgs(trailingOnly = TRUE)
roxygen <- "--roxygen" %in% args
terms <- "--terms" %in% args
cap <- 30L
words <- c("procedure", "orchestrator", "candidate")

pages <- c(
  "vignettes/nested-cv.Rmd",
  "vignettes/estimate.Rmd",
  "vignettes/tuners.Rmd",
  "vignettes/results.Rmd",
  "vignettes/articles/parallel.Rmd",
  "README.Rmd"
)

strip_spans <- function(text) {
  text <- gsub("`[^`]*`", "", text, perl = TRUE)
  if (roxygen) {
    text <- gsub("\\\\code\\{[^}]*\\}", "", text, perl = TRUE)
    text <- gsub("\\\\[a-zA-Z]+\\{([^}]*)\\}", "\\1", text, perl = TRUE)
    text <- gsub("\\[([^]]*)\\]\\([^)]*\\)", "\\1", text, perl = TRUE)
    text <- gsub("\\[([^]]*)\\]\\[[^]]*\\]", "\\1", text, perl = TRUE)
    text <- gsub("\\[[^]]*\\]", "", text, perl = TRUE)
  }
  text
}

# Prose paragraphs of one .Rmd page: a list, one element per paragraph,
# each a data frame of (line, text) for the lines it holds.
rmd_paragraphs <- function(path) {
  lines <- readLines(path, warn = FALSE)
  keep <- rep(TRUE, length(lines))
  yaml <- which(grepl("^---$", lines))
  if (length(yaml) >= 2L) {
    keep[yaml[1]:yaml[2]] <- FALSE
  }
  fenced <- FALSE
  for (i in seq_along(lines)) {
    if (grepl("^```", lines[i])) {
      fenced <- !fenced
      keep[i] <- FALSE
    } else if (fenced) {
      keep[i] <- FALSE
    }
  }
  keep[grepl("^\\s*<!--", lines)] <- FALSE
  keep[grepl("^#", lines)] <- FALSE
  keep[grepl("^\\s*[-*] ", lines)] <- FALSE
  keep[!nzchar(trimws(lines))] <- FALSE
  split_runs(lines, keep, seq_along(lines))
}

# Roxygen prose paragraphs of one .R file, grouped as above; a `block`
# column carries the block's first line for the per-block term locator.
roxygen_paragraphs <- function(path) {
  lines <- readLines(path, warn = FALSE)
  is_rox <- grepl("^\\s*#'", lines)
  body <- sub("^\\s*#'\\s?", "", lines)
  keep <- rep(FALSE, length(lines))
  block <- rep(NA_integer_, length(lines))
  included <- c("title", "description", "details", "param", "return", "section")
  in_block <- FALSE
  tag <- "description"
  start <- NA_integer_
  for (i in seq_along(lines)) {
    if (!is_rox[i]) {
      in_block <- FALSE
      next
    }
    if (!in_block) {
      in_block <- TRUE
      tag <- "description"
      start <- i
    }
    block[i] <- start
    m <- regmatches(body[i], regexpr("^@[a-zA-Z]+", body[i]))
    if (length(m)) {
      tag <- sub("^@", "", m)
      body[i] <- sub("^@[a-zA-Z]+\\s*", "", body[i])
      if (tag == "param") {
        body[i] <- sub("^\\S+\\s*", "", body[i])
      } else if (tag == "section") {
        body[i] <- sub("^[^:]*:\\s*", "", body[i])
      }
    }
    keep[i] <- tag %in% included && nzchar(trimws(body[i]))
  }
  paras <- split_runs(body, keep, seq_along(lines), block)
  # a list item starts its own paragraph
  out <- list()
  for (p in paras) {
    starts <- which(grepl("^\\s*[-*] ", p$text))
    cut <- sort(unique(c(1L, starts)))
    ends <- c(cut[-1] - 1L, nrow(p))
    for (k in seq_along(cut)) {
      out[[length(out) + 1L]] <- p[cut[k]:ends[k], , drop = FALSE]
    }
  }
  out
}

split_runs <- function(text, keep, line, block = NULL) {
  paras <- list()
  run <- integer()
  flush <- function() {
    if (length(run)) {
      p <- data.frame(line = line[run], text = text[run])
      if (!is.null(block)) {
        p$block <- block[run]
      }
      paras[[length(paras) + 1L]] <<- p
    }
    run <<- integer()
  }
  for (i in seq_along(text)) {
    if (keep[i]) {
      run <- c(run, i)
    } else {
      flush()
    }
  }
  flush()
  paras
}

# Sentences of one paragraph: a data frame of (line, n, text), `line` the
# line the sentence's first word sits on.
sentences <- function(para) {
  # spans are stripped over the joined paragraph, since one can cross a
  # line break; a line swallowed that way lends its words to the line above
  pieces <- strsplit(strip_spans(paste(para$text, collapse = "\n")), "\n")[[1]]
  tokens <- character()
  at <- integer()
  for (k in seq_along(pieces)) {
    t <- strsplit(trimws(pieces[k]), "\\s+")[[1]]
    t <- t[nzchar(t)]
    tokens <- c(tokens, t)
    at <- c(at, rep(para$line[min(k, nrow(para))], length(t)))
  }
  if (!length(tokens)) {
    return(NULL)
  }
  ends <- grepl("[.?!][\"')*]*$", tokens)
  low <- tolower(tokens)
  abbrev <- low %in% c("e.g.", "i.e.", "vs.") |
    (low == "al." & c("", low[-length(low)]) == "et")
  ends <- ends & !abbrev
  ends[length(tokens)] <- TRUE
  stop_at <- which(ends)
  start_at <- c(1L, stop_at[-length(stop_at)] + 1L)
  data.frame(
    line = at[start_at],
    n = stop_at - start_at + 1L,
    text = vapply(
      seq_along(start_at),
      function(j) paste(tokens[start_at[j]:stop_at[j]], collapse = " "),
      character(1)
    ),
    block = if ("block" %in% names(para)) para$block[1] else NA_integer_
  )
}

files <- if (roxygen) {
  c(list.files("R", "\\.R$", full.names = TRUE),
    list.files("man-roxygen", "\\.R$", full.names = TRUE))
} else {
  pages
}

hits <- 0L
for (f in files) {
  paras <- if (roxygen) roxygen_paragraphs(f) else rmd_paragraphs(f)
  sents <- do.call(rbind, lapply(paras, sentences))
  if (is.null(sents) || !nrow(sents)) {
    next
  }
  if (terms) {
    look <- words
    if (roxygen || basename(f) == "results.Rmd") {
      look <- c(look, "reader")
    }
    groups <- if (roxygen) split(sents, sents$block) else list(sents)
    for (g in groups) {
      for (w in look) {
        i <- which(grepl(sprintf("\\b%ss?\\b", w), g$text, ignore.case = TRUE))
        if (length(i)) {
          cat(sprintf("%s:%d: %s: %s\n", f, g$line[i[1]], w, g$text[i[1]]))
        }
      }
    }
  } else {
    over <- which(sents$n > cap)
    for (i in over) {
      cat(sprintf("%s:%d: %d words: %s\n", f, sents$line[i], sents$n[i], sents$text[i]))
    }
    hits <- hits + length(over)
  }
}

if (!terms) {
  cat(if (hits == 0L) "clean\n" else sprintf("%d hit(s)\n", hits))
  quit(status = as.integer(hits > 0L))
}
