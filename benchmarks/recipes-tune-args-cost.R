# What a bare-name step selector costs each time tune reads a recipe's tuning
# arguments.
#
# `generics::tune_args()` on a recipe step calls recipes' internal
# `find_tune_id()` on every field of the step. For the `terms` field, a list of
# quosures, it first tries `purrr::map(x, rlang::eval_tidy)` inside `try()`.
# A bare column name such as `x1` has no binding outside a selection context,
# so that evaluation fails, and purrr and cli build a full error message that
# `try()` then discards. A string such as `"x1"` evaluates to itself and
# nothing fails. What the difference did to two Bayesian test files is in the
# M114 section of `benchmarks/test-timing-baseline.md`. Usage, from the
# package root:
#
#   Rscript benchmarks/recipes-tune-args-cost.R [calls]
#
# It prints the median per-call time, in milliseconds, of `tune_args()` on the
# same one-step recipe written both ways, and their ratio.

calls <- {
  a <- commandArgs(trailingOnly = TRUE)
  if (length(a) >= 1L) as.integer(a[[1L]]) else 200L
}
stopifnot(!is.na(calls), calls >= 1L)

data <- data.frame(y = rnorm(20), x1 = rnorm(20))
base <- recipes::recipe(y ~ x1, data = data)
steps <- list(
  bare = recipes::step_ns(base, x1, deg_free = tune::tune())$steps[[1L]],
  string = recipes::step_ns(base, "x1", deg_free = tune::tune())$steps[[1L]]
)

# Both spellings must name the same tuning argument, or the timing compares
# two different amounts of work.
ids <- lapply(steps, function(s) generics::tune_args(s)$id)
stopifnot(identical(ids$bare, ids$string), "deg_free" %in% ids$bare)

# A single call is near the timer's resolution, so each figure is the median
# of batches of ten calls, divided by ten.
batch_ms <- function(step) {
  generics::tune_args(step)
  times <- vapply(
    seq_len(ceiling(calls / 10)),
    function(i) {
      t0 <- proc.time()[["elapsed"]]
      for (j in 1:10) {
        generics::tune_args(step)
      }
      proc.time()[["elapsed"]] - t0
    },
    numeric(1)
  )
  100 * stats::median(times)
}

ms <- vapply(steps, batch_ms, numeric(1))

cat(sprintf("recipes:  %s\n", utils::packageVersion("recipes")))
cat(sprintf("purrr:    %s\n", utils::packageVersion("purrr")))
cat(sprintf("cli:      %s\n", utils::packageVersion("cli")))
cat(sprintf("R:        %s\n", R.version.string))
cat(sprintf(
  "calls:    %d per spelling, timed in batches of 10\n\n",
  10L * as.integer(ceiling(calls / 10))
))
cat(sprintf("step_ns(x1)    %6.2f ms per call\n", ms[["bare"]]))
cat(sprintf("step_ns(\"x1\")  %6.2f ms per call\n", ms[["string"]]))
cat(sprintf("ratio          %6.1f\n", ms[["bare"]] / ms[["string"]]))
