# One row per test block, for comparing two trees block by block.
#
# `profile-tests.R` answers where the suite spends its time. This script
# answers whether a change lost a test: it runs one serial pass and writes
# testthat's results table, one row per `test_that()` block, keyed by file
# and test name. Two trees' tables joined on those keys show any block whose
# expectation count moved, and any block that failed, errored or skipped.
# Usage, from the root of the tree being measured:
#
#   Rscript benchmarks/test-blocks.R out.csv
#
# The script can live in another checkout: it reads the tests and the package
# from the working directory, so a branch point without this file is measured
# by running this copy from inside it. The load conditions are those of
# `profile-tests.R`: one `load_all()`, helpers sourced once, NOT_CRAN on,
# files run serially.

out <- commandArgs(trailingOnly = TRUE)[1L]
stopifnot(!is.na(out))

Sys.setenv(NOT_CRAN = "true", TESTTHAT_PARALLEL = "FALSE")
suppressMessages(pkgload::load_all(".", quiet = TRUE))

res <- testthat::test_dir(
  "tests/testthat",
  package = "nestedtune",
  load_package = "none",
  reporter = "silent",
  stop_on_failure = FALSE
)
df <- as.data.frame(res)
blocks <- data.frame(
  file = df$file,
  test = df$test,
  expectations = df$nb,
  failed = df$failed,
  skipped = df$skipped,
  error = df$error
)
blocks <- blocks[order(blocks$file, blocks$test), ]
utils::write.csv(blocks, out, row.names = FALSE)

cat(sprintf(
  "%s: %d blocks in %d files | %d expectations | blocks failed %d, skipped %d, errored %d\n",
  system("git rev-parse --short HEAD", intern = TRUE),
  nrow(blocks),
  length(unique(blocks$file)),
  sum(blocks$expectations),
  sum(blocks$failed > 0),
  sum(blocks$skipped > 0),
  sum(blocks$error > 0)
))
