# Draft: issue for tidymodels/recipes

Status: draft. Nothing is posted before the user approves this text at the review gate of the milestone that drafted it.
A search on 2026-09-23 for `find_tune_id` and `tune_args` in tidymodels/recipes issues found #1506 and #1296. Both report wrong results, not cost.

---

**Title:** `tune_args()` on a step with a bare-name selector spends most of its time formatting a discarded error

`find_tune_id()` evaluates each quosure in a step's `terms` with `try(purrr::map(x, rlang::eval_tidy), silent = TRUE)`. A bare column name such as `x1` has no binding outside a selection context, so the evaluation fails. `try()` then calls `conditionMessage()` on the error, and the message goes through cli formatting. The message is thrown away. A string selector such as `"x1"` evaluates to itself, and nothing fails.

The per-call difference is about 10 to 12 times:

``` r
d <- data.frame(y = rnorm(20), x1 = rnorm(20))
rec <- recipes::recipe(y ~ x1, data = d)
steps <- list(
  bare = recipes::step_ns(rec, x1, deg_free = tune::tune())$steps[[1]],
  string = recipes::step_ns(rec, "x1", deg_free = tune::tune())$steps[[1]]
)
ms_per_call <- function(step) {
  times <- replicate(20, system.time(for (i in 1:10) generics::tune_args(step))[["elapsed"]])
  100 * median(times)
}
sapply(steps, ms_per_call)
#>   bare string
#>    6.4    0.6
```

A longer run of the same measurement used 200 calls per spelling. It gave these figures, with recipes 1.4.0, purrr 1.2.2, cli 3.6.6 and R 4.6.1 on macOS:

| selector | ms per call |
|---|---:|
| `step_ns(x1)` | 7.40 |
| `step_ns("x1")` | 0.60 |

An `Rprof()` of 300 calls on the bare-name step put 94% of the time inside `try()`. It put 76% inside `conditionMessage()` and cli's formatting.

tune calls `tune_args()` often during a search. In our package's tests, two Bayesian-search fixtures changed from bare names to strings. Two test files that use them went from 57.6 s and 59.9 s to 17.9 s and 20.3 s (medians of three serial runs). The whole test suite went from 762.5 s to 549.1 s.

One possible fix skips the evaluation when the quosure's expression is a bare symbol. Another uses `tryCatch()` with a handler that does not read the message. We did not test either change.
