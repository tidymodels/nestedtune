# The prose sweep over the user-facing pages: a sentence cap, a span cap, a
# first-use locator for the package's own words, each page's opening
# sentence and its paragraph partition; the Modes block below names each.
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
#   Rscript benchmarks/sweep-prose.R --spans
#       every prose sentence naming more than 4 backtick spans, inline `r`
#       spans excluded, as `file:line: <k> spans: <text>` with each span
#       shown as `•`; exits 1 on any hit
#   Rscript benchmarks/sweep-prose.R --openings
#       the first prose sentence of each page, badge lines (`[![`) dropped
#       first, as `file:line: <text>`; exits 0
#   Rscript benchmarks/sweep-prose.R --paragraphs
#       every prose paragraph of each page, as `file:first-last: <opening
#       words>`, `first` and `last` the lines of the paragraph's extent;
#       exits 0
#   Rscript benchmarks/sweep-prose.R --plain
#       every prose sentence matching a plain clause, as
#       `file:line: <clause name>: <text>`, one line per clause matched,
#       `line` the line the sentence starts on; exits 1 on any hit. The
#       clauses, each matching whole words in any case, with a backtick
#       span never part of a match:
#         semicolon    a `;`
#         contraction  a word ending `n't`, `'re`, `'ll`, `'ve`, `'d` or
#                      `'m` (a straight or a curly apostrophe)
#         has been     `has been` or `have been`
#         modal        `should`, `may`, `might`, `could` or `would`
#         comma-ing    a comma, one space, then a word ending `ing` that is
#                      not on the exclusion list: including, during,
#                      according, regarding, nothing, something, anything,
#                      everything
#         slop         a phrase on the slop list, reported as
#                      `slop (<phrase>)`; the list is the left column of
#                      the SimpleEnglish skill's `references/word-swaps.md`
#                      with parenthetical qualifiers dropped and
#                      `/`-separated alternatives split into their own
#                      phrases (the `slop` vector below holds it)
#   Rscript benchmarks/sweep-prose.R --pages <path>...
#       the paths after `--pages`, up to the next `--` option, replace the
#       page list above for any mode; a page is read with or without a
#       YAML header
#   Rscript benchmarks/sweep-prose.R --roxygen [--terms|--spans|--openings|--paragraphs]
#       the same checks over roxygen prose in `R/*.R` and
#       `man-roxygen/*.R`: the bodies of `@title`, `@description`,
#       `@details`, `@param`, `@return` and `@section` and the untagged lines
#       belonging to them, every other tag and every `@examples` block
#       excluded, and fenced code and pipe-table lines inside those bodies
#       dropped, as is the bold run-in heading of each paragraph in a
#       section titled `Differences from calling ... directly` (the
#       classification index `test-control-slots.R` parses); `[link]`
#       targets and `\code{}` spans removed as well. With
#       `--terms`, first occurrences are per roxygen block, `reader` read on
#       every file. With `--openings`, one sentence per block in `R/*.R`
#       that has a description paragraph after its title paragraph: the
#       first sentence of the earliest such paragraph, a description
#       paragraph being one tagged `description` that is not the block's
#       title (a block opening with an explicit `@description` has no
#       title, so its first paragraph counts). With `--paragraphs`, every
#       roxygen prose paragraph, a list item its own paragraph.

args <- commandArgs(trailingOnly = TRUE)
roxygen <- "--roxygen" %in% args
terms <- "--terms" %in% args
spans <- "--spans" %in% args
openings <- "--openings" %in% args
paragraphs <- "--paragraphs" %in% args
plain <- "--plain" %in% args
cap <- 30L
span_cap <- 4L
mark <- "•"
words <- c("procedure", "orchestrator", "candidate")

pages <- c(
  "vignettes/nested-cv.Rmd",
  "vignettes/estimate.Rmd",
  "vignettes/tuners.Rmd",
  "vignettes/results.Rmd",
  "vignettes/articles/parallel.Rmd",
  "README.Rmd"
)
if ("--pages" %in% args) {
  from <- match("--pages", args) + 1L
  rest <- args[seq.int(from, length.out = max(0L, length(args) - from + 1L))]
  stop_at <- which(startsWith(rest, "--"))
  if (length(stop_at)) {
    rest <- rest[seq_len(stop_at[1] - 1L)]
  }
  pages <- rest
}

ing_exclusions <- c(
  "including", "during", "according", "regarding",
  "nothing", "something", "anything", "everything"
)
slop <- c(
  "leverage", "utilize", "in order to", "prior to", "ensure",
  "it is worth noting that", "it's important to",
  "simply", "just", "easily", "seamless", "seamlessly", "effortlessly",
  "robust", "powerful", "comprehensive", "performant", "functionality",
  "enables you to", "allows you to", "is designed to", "aims to",
  "facilitate", "dive into", "delve into", "when it comes to",
  "in the event that", "due to the fact that", "as needed", "as necessary",
  "and/or", "e.g.", "i.e.", "etc.", "gracefully handles", "out of the box",
  "under the hood", "blazingly fast", "streamline", "plethora", "myriad",
  "addresses the issue", "tackles", "pivotal", "crucial", "crucially",
  "paramount", "tapestry", "testament", "synergy", "interplay", "intricate",
  "vibrant", "nuanced", "multifaceted", "realm", "landscape",
  "groundbreaking", "cutting-edge", "state-of-the-art", "innovative",
  "unprecedented", "transformative", "game-changer", "revolutionize",
  "showcase", "underscore", "emphasize", "foster", "empower", "bolster",
  "harness", "enhance", "elevate", "furthermore", "moreover",
  "in conclusion", "in summary", "at the end of the day", "embark",
  "endeavor", "meticulous", "meticulously", "holistic", "paradigm",
  "navigate", "boasts", "nestled", "in the heart of", "bustling",
  "that being said", "notwithstanding", "I hope this helps", "let's dive in"
)

# The plain clauses one sentence matches, by name, in the order above; a
# slop hit carries its phrase.
plain_clauses <- function(text) {
  out <- character()
  if (grepl(";", text, fixed = TRUE)) {
    out <- c(out, "semicolon")
  }
  if (grepl("(?<=\\w)(n['\u2019]t|['\u2019](re|ll|ve|d|m))(?!\\w)", text, perl = TRUE, ignore.case = TRUE)) {
    out <- c(out, "contraction")
  }
  if (grepl("(?<!\\w)(has|have) been(?!\\w)", text, perl = TRUE, ignore.case = TRUE)) {
    out <- c(out, "has been")
  }
  if (grepl("(?<!\\w)(should|may|might|could|would)(?!\\w)", text, perl = TRUE, ignore.case = TRUE)) {
    out <- c(out, "modal")
  }
  m <- regmatches(text, gregexpr(", (\\w+ing)(?!\\w)", text, perl = TRUE))[[1]]
  m <- tolower(sub("^, ", "", m))
  if (any(!m %in% ing_exclusions)) {
    out <- c(out, "comma-ing")
  }
  for (phrase in slop) {
    pat <- paste0("(?<!\\w)", gsub("([.\\/])", "\\\\\\1", phrase), "(?!\\w)")
    if (grepl(pat, text, perl = TRUE, ignore.case = TRUE)) {
      out <- c(out, sprintf("slop (%s)", phrase))
    }
  }
  out
}

strip_spans <- function(text, count = FALSE) {
  # a backtick span is replaced by the line breaks it contains, so a span
  # crossing a line break leaves the line count, and every later
  # sentence's reported line, unchanged; with `count`, a span that is not
  # an inline `r` span leaves one mark behind as well, so the spans a
  # sentence names can be counted after splitting
  m <- gregexpr("`[^`]*`", text, perl = TRUE)
  regmatches(text, m) <- lapply(
    regmatches(text, m),
    function(s) {
      kept <- gsub("[^\n]", "", s)
      if (count) {
        named <- !grepl("^`r\\s", s)
        kept[named] <- paste0(mark, kept[named])
      }
      kept
    }
  )
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
rmd_paragraphs <- function(path, badges = TRUE) {
  lines <- readLines(path, warn = FALSE)
  keep <- rep(TRUE, length(lines))
  if (!badges) {
    keep[grepl("^\\[!\\[", lines)] <- FALSE
  }
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
# column carries the block's first line for the per-block term locator, a
# `tag` column the roxygen tag the paragraph belongs to, and `titled`
# whether the block opened with an untagged title line.
roxygen_paragraphs <- function(path) {
  lines <- readLines(path, warn = FALSE)
  is_rox <- grepl("^\\s*#'", lines)
  body <- sub("^\\s*#'\\s?", "", lines)
  keep <- rep(FALSE, length(lines))
  block <- rep(NA_integer_, length(lines))
  tags <- rep(NA_character_, length(lines))
  titled <- rep(NA, length(lines))
  included <- c("title", "description", "details", "param", "return", "section")
  differences <- rep(FALSE, length(lines))
  in_block <- FALSE
  fenced <- FALSE
  tag <- "description"
  start <- NA_integer_
  has_title <- FALSE
  in_differences <- FALSE
  for (i in seq_along(lines)) {
    if (!is_rox[i]) {
      in_block <- FALSE
      fenced <- FALSE
      in_differences <- FALSE
      next
    }
    if (!in_block) {
      in_block <- TRUE
      tag <- "description"
      start <- i
      has_title <- !grepl("^@", body[i])
    }
    block[i] <- start
    titled[i] <- has_title
    m <- regmatches(body[i], regexpr("^@[a-zA-Z]+", body[i]))
    if (length(m)) {
      tag <- sub("^@", "", m)
      fenced <- FALSE
      body[i] <- sub("^@[a-zA-Z]+\\s*", "", body[i])
      if (tag == "param") {
        body[i] <- sub("^\\S+\\s*", "", body[i])
      } else if (tag == "section") {
        in_differences <- grepl("^Differences from calling", body[i])
        body[i] <- sub("^[^:]*:\\s*", "", body[i])
      } else {
        in_differences <- FALSE
      }
    }
    tags[i] <- tag
    differences[i] <- in_differences
    # fenced code and pipe-table lines inside a prose body are not prose
    if (grepl("^\\s*```", body[i])) {
      fenced <- !fenced
      next
    }
    if (fenced || grepl("^\\s*\\|", body[i])) {
      next
    }
    keep[i] <- tag %in% included && nzchar(trimws(body[i]))
  }
  paras <- split_runs(body, keep, seq_along(lines), block, tags, titled)
  # a list item starts its own paragraph
  out <- list()
  for (p in paras) {
    starts <- which(grepl("^\\s*[-*] ", p$text))
    cut <- sort(unique(c(1L, starts)))
    ends <- c(cut[-1] - 1L, nrow(p))
    for (k in seq_along(cut)) {
      q <- p[cut[k]:ends[k], , drop = FALSE]
      if (differences[q$line[1]]) {
        q$text <- drop_run_in_heading(q$text)
      }
      out[[length(out) + 1L]] <- q
    }
  }
  out
}

# The bold run-in heading a Differences paragraph opens with, removed with
# its line breaks kept, so the paragraph's line count and every later
# sentence's reported line stay as they were.
drop_run_in_heading <- function(text) {
  joined <- paste(text, collapse = "\n")
  m <- regexpr("^\\s*\\*\\*[^*]+\\*\\*", joined, perl = TRUE)
  if (m > 0) {
    regmatches(joined, m) <- gsub("[^\n]", "", regmatches(joined, m))
  }
  pieces <- strsplit(joined, "\n")[[1]]
  c(pieces, rep("", length(text) - length(pieces)))
}

# The opening sentence of each roxygen block in `R/*.R` with a description
# paragraph after its title paragraph: a data frame of (block, line, text),
# one row per such block, or NULL where a file has none.
roxygen_openings <- function(paras) {
  if (!length(paras)) {
    return(NULL)
  }
  blocks <- vapply(paras, function(p) p$block[1], integer(1))
  out <- NULL
  for (b in unique(blocks)) {
    in_block <- paras[blocks == b]
    is_desc <- vapply(
      in_block,
      function(p) identical(p$tag[1], "description"),
      logical(1)
    )
    # the title paragraph is the block's first when the block opened with
    # an untagged line; a block opening on `@description` has none
    if (in_block[[1]]$titled[1]) {
      is_desc[1] <- FALSE
    }
    k <- which(is_desc)
    if (!length(k)) {
      next
    }
    s <- sentences(in_block[[k[1]]])
    if (is.null(s)) {
      next
    }
    out <- rbind(out, data.frame(block = b, line = s$line[1], text = s$text[1]))
  }
  out
}

split_runs <- function(
  text,
  keep,
  line,
  block = NULL,
  tag = NULL,
  titled = NULL
) {
  paras <- list()
  run <- integer()
  flush <- function() {
    if (length(run)) {
      p <- data.frame(line = line[run], text = text[run])
      if (!is.null(block)) {
        p$block <- block[run]
      }
      if (!is.null(tag)) {
        p$tag <- tag[run]
      }
      if (!is.null(titled)) {
        p$titled <- titled[run]
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
sentences <- function(para, count = FALSE) {
  # spans are stripped over the joined paragraph, since one can cross a
  # line break; strip_spans() keeps the breaks, so pieces and lines align
  joined <- strip_spans(paste(para$text, collapse = "\n"), count = count)
  pieces <- strsplit(joined, "\n")[[1]]
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
  abbrev <- low %in%
    c("e.g.", "i.e.", "vs.") |
    (low == "al." & c("", low[-length(low)]) == "et")
  ends <- ends & !abbrev
  ends[length(tokens)] <- TRUE
  stop_at <- which(ends)
  start_at <- c(1L, stop_at[-length(stop_at)] + 1L)
  text <- vapply(
    seq_along(start_at),
    function(j) paste(tokens[start_at[j]:stop_at[j]], collapse = " "),
    character(1)
  )
  data.frame(
    line = at[start_at],
    n = stop_at - start_at + 1L,
    spans = lengths(regmatches(text, gregexpr(mark, text, fixed = TRUE))),
    text = text,
    block = if ("block" %in% names(para)) para$block[1] else NA_integer_
  )
}

files <- if (roxygen) {
  c(
    list.files("R", "\\.R$", full.names = TRUE),
    list.files("man-roxygen", "\\.R$", full.names = TRUE)
  )
} else {
  pages
}

hits <- 0L
for (f in files) {
  paras <- if (roxygen) {
    roxygen_paragraphs(f)
  } else {
    rmd_paragraphs(f, badges = !openings)
  }
  if (paragraphs) {
    for (p in paras) {
      opening <- strsplit(trimws(p$text[1]), "\\s+")[[1]]
      opening <- paste(
        opening[seq_len(min(8L, length(opening)))],
        collapse = " "
      )
      cat(sprintf("%s:%d-%d: %s\n", f, p$line[1], p$line[nrow(p)], opening))
    }
    next
  }
  if (openings && roxygen) {
    if (!startsWith(f, "R/")) {
      next
    }
    op <- roxygen_openings(paras)
    for (i in seq_len(NROW(op))) {
      cat(sprintf("%s:%d: %s\n", f, op$line[i], op$text[i]))
    }
    next
  }
  sents <- do.call(rbind, lapply(paras, sentences, count = spans))
  if (is.null(sents) || !nrow(sents)) {
    next
  }
  if (openings) {
    cat(sprintf("%s:%d: %s\n", f, sents$line[1], sents$text[1]))
  } else if (spans) {
    over <- which(sents$spans > span_cap)
    for (i in over) {
      cat(sprintf(
        "%s:%d: %d spans: %s\n",
        f,
        sents$line[i],
        sents$spans[i],
        sents$text[i]
      ))
    }
    hits <- hits + length(over)
  } else if (plain) {
    for (i in seq_len(nrow(sents))) {
      found <- plain_clauses(sents$text[i])
      for (name in found) {
        cat(sprintf("%s:%d: %s: %s\n", f, sents$line[i], name, sents$text[i]))
      }
      hits <- hits + length(found)
    }
  } else if (terms) {
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
      cat(sprintf(
        "%s:%d: %d words: %s\n",
        f,
        sents$line[i],
        sents$n[i],
        sents$text[i]
      ))
    }
    hits <- hits + length(over)
  }
}

if (!terms && !openings && !paragraphs) {
  cat(if (hits == 0L) "clean\n" else sprintf("%d hit(s)\n", hits))
  quit(status = as.integer(hits > 0L))
}
