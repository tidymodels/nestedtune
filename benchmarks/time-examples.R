# Where the help-page examples spend their time, per page (M74, AC6).
#
# Usage, from the package root:
#
#   Rscript benchmarks/time-examples.R [runs]
#
# Method. Every `man/*.Rd` page's `\examples` section is extracted with
# `tools::Rd2ex()` twice -- once with `\donttest{}` blocks commented out,
# which is what `R CMD check` runs by default, and once with them kept,
# which is what `R CMD check --run-donttest` and CRAN's incoming checks run
# -- and each extraction is sourced in THIS process, in a fresh environment,
# with the package loaded once by `pkgload::load_all()` ahead of every page
# (the same one-process condition `benchmarks/profile-tests.R` measures the
# test suite under, so the two scripts' figures are comparable in kind: a
# page pays for nothing but its own code). `\dontrun{}` blocks are always
# commented out, as the checker does. A page with no examples contributes
# 0 s and is listed as such. Each page is timed by `proc.time()` elapsed
# around the `source()`, and its printed output is captured so that only
# messages, warnings and the figures below reach the console. Errors are
# caught per page and reported, never raised: a page that errors is the
# finding, and the totals still print.
#
# The whole set is run `runs` times (default 3); every figure printed is the
# median over the runs, and the totals are sums of per-page medians. The
# figures move with the machine and its load, so a comparison is always
# between two runs of this script under the same conditions -- the way
# AC6 reads the branch point against the branch head.

runs <- {
  a <- commandArgs(trailingOnly = TRUE)
  if (length(a) >= 1L) as.integer(a[[1L]]) else 3L
}
stopifnot(!is.na(runs), runs >= 1L)

suppressMessages(pkgload::load_all(".", quiet = TRUE))
# Plots draw to a null device rather than an Rplots.pdf in the working tree.
grDevices::pdf(NULL)

pages <- list.files("man", pattern = "\\.Rd$", full.names = TRUE)
names(pages) <- basename(pages)

# The example code of one page as `R CMD check` would run it: NULL when the
# page has no `\examples` section.
example_code <- function(rd, keep_donttest) {
  out <- tempfile(fileext = ".R")
  on.exit(unlink(out), add = TRUE)
  tools::Rd2ex(
    rd,
    out,
    commentDontrun = TRUE,
    commentDonttest = !keep_donttest
  )
  if (!file.exists(out)) {
    return(NULL)
  }
  readLines(out)
}

# One page, one mode: seconds elapsed, and the error's message when it
# raised one.
time_page <- function(code) {
  if (is.null(code)) {
    return(list(seconds = 0, error = NA_character_))
  }
  src <- tempfile(fileext = ".R")
  on.exit(unlink(src), add = TRUE)
  writeLines(code, src)
  env <- new.env(parent = globalenv())
  started <- proc.time()[["elapsed"]]
  error <- tryCatch(
    {
      invisible(utils::capture.output(
        source(src, local = env, echo = FALSE),
        type = "output"
      ))
      NA_character_
    },
    error = function(e) conditionMessage(e)
  )
  list(seconds = proc.time()[["elapsed"]] - started, error = error)
}

one_run <- function(keep_donttest) {
  timings <- lapply(pages, function(rd) {
    time_page(example_code(rd, keep_donttest))
  })
  list(
    seconds = vapply(timings, function(t) t$seconds, numeric(1)),
    errors = vapply(timings, function(t) t$error, character(1))
  )
}

modes <- c(without_donttest = FALSE, with_donttest = TRUE)
passes <- lapply(seq_len(runs), function(i) {
  cat(sprintf("run %d/%d ...\n", i, runs))
  lapply(modes, one_run)
})

cat("\n")
cat(sprintf("R:        %s\n", R.version.string))
cat(sprintf("OS:       %s\n", sessionInfo()$running))
cat(sprintf(
  "commit:   %s\n",
  system("git rev-parse --short HEAD", intern = TRUE)
))
cat("loading:  package loaded once for all pages (pkgload::load_all)\n")
cat(sprintf("pages:    %d under man/\n", length(pages)))
cat(sprintf("runs:     %d (all figures are medians)\n\n", runs))

median_seconds <- function(mode) {
  vapply(
    names(pages),
    function(p) {
      stats::median(vapply(
        passes,
        function(run) run[[mode]]$seconds[[p]],
        numeric(1)
      ))
    },
    numeric(1)
  )
}

without <- median_seconds("without_donttest")
with <- median_seconds("with_donttest")
ord <- order(with, decreasing = TRUE)

cat(sprintf("%-42s %10s %10s\n", "page", "no donttest", "donttest"))
for (p in names(pages)[ord]) {
  cat(sprintf("%-42s %10.2f %10.2f\n", p, without[[p]], with[[p]]))
}
cat(sprintf(
  "%-42s %10.1f %10.1f\n",
  "TOTAL (sum of page medians)",
  sum(without),
  sum(with)
))

# Errors: any page, any run, either mode.
failed <- character()
for (run in passes) {
  for (mode in names(modes)) {
    errs <- run[[mode]]$errors
    bad <- names(errs)[!is.na(errs)]
    for (p in bad) {
      failed <- c(failed, sprintf("%s (%s): %s", p, mode, errs[[p]]))
    }
  }
}
failed <- unique(failed)
if (length(failed) == 0L) {
  cat("\nerrors: none\n")
} else {
  cat(sprintf("\nerrors: %d\n", length(failed)))
  cat(paste0("  ", failed, "\n"), sep = "")
}
