# Per-line coverage of `R/`, keyed so two trees can be compared (M113, AC2).
#
# Usage, from any directory:
#
#   Rscript benchmarks/coverage-lines.R <package-dir> <out.csv>
#
# Runs `covr::package_coverage()` on <package-dir> the way
# `.github/workflows/test-coverage.yaml` does: the daemons' trace files go to
# the `daemon-traces` sidecar `tests/testthat/helper-covr.R` points at, and are
# merged back with covr's own `merge_coverage()`, skipping any file that
# cannot be read. Two differences from the workflow, both deliberate: the
# tests run serially (`TESTTHAT_PARALLEL=FALSE`), and `NOT_CRAN=true` is set
# so no test skips.
#
# The output has one row per line covr tallies: `file` (relative to `R/`),
# `line` (the line number in that tree), `pos` (the line's position among the
# file's lines that do not open with `#'`, after trimming leading blanks) and
# `hits`. Two trees that differ only in roxygen comments share `pos` for every
# code line, which is what AC2 compares on; `line` is kept for reading back.

args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 2L)
pkg <- normalizePath(args[[1L]], mustWork = TRUE)
out <- args[[2L]]

Sys.setenv(NOT_CRAN = "true", TESTTHAT_PARALLEL = "FALSE")
install_path <- tempfile("nestedtune-covr-")
dir.create(install_path)

cov <- covr::package_coverage(
  path = pkg,
  quiet = FALSE,
  clean = FALSE,
  install_path = install_path
)
sidecar <- list.files(
  file.path(install_path, "daemon-traces"),
  pattern = "^covr_trace_",
  full.names = TRUE
)
traces <- lapply(sidecar, function(f) {
  tryCatch(as.list(readRDS(f)), error = function(e) NULL)
})
skipped <- sidecar[vapply(traces, is.null, logical(1))]
if (length(skipped)) {
  message(
    "skipped unreadable trace file(s): ",
    paste(basename(skipped), collapse = ", ")
  )
}
message(length(sidecar) - length(skipped), " sidecar trace file(s) merged")
cov <- covr:::merge_coverage(c(list(cov), Filter(Negate(is.null), traces)))
print(cov)

tally <- covr::tally_coverage(cov, by = "line")
tally$file <- sub("^R/", "", tally$filename)
tally <- tally[grepl("^R/", tally$filename), ]

pos_of <- function(file) {
  lines <- readLines(file.path(pkg, "R", file), warn = FALSE)
  code <- !startsWith(trimws(lines, which = "left"), "#'")
  p <- cumsum(code)
  p[!code] <- NA_integer_
  p
}
positions <- lapply(unique(tally$file), pos_of)
names(positions) <- unique(tally$file)
tally$pos <- mapply(
  function(f, l) positions[[f]][[l]],
  tally$file,
  tally$line
)

res <- data.frame(
  file = tally$file,
  line = tally$line,
  pos = tally$pos,
  hits = tally$value,
  stringsAsFactors = FALSE
)
res <- res[order(res$file, res$line), ]
write.csv(res, out, row.names = FALSE)
message(nrow(res), " lines written to ", out)
