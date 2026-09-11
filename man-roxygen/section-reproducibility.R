#' @section Reproducibility:
#'
#' Seed the session before the call, as elsewhere in tidymodels. There is no
#' `seed` argument. On entry the function draws `2 * n` seeds in a single
#' `sample.int(.Machine$integer.max, 2 * n)` call, where `n` is the number of
#' outer folds. Fold `i` uses element `2 * i - 1` for its tuning step and
#' element `2 * i` for its outer fit, each applied with the generator kind
#' pinned. A fold's seed depends on its position, not on the order the folds
#' run in. So the same seed gives the same result serially and in parallel,
#' at any number of daemons. The two seeds are kept on the result as
#' `.tuning_seed` and `.outer_fit_seed`, and `?nested_tune_grid` shows how to
#' reproduce one fold by hand from them.
#'
#' The caller's RNG state and generator kind are restored on exit, including
#' when the call errors, so a seeded script that draws afterwards is
#' unaffected. One consequence: two consecutive calls with no `set.seed()`
#' between them return identical results, exactly as repeated
#' [tune::tune_grid()] calls do.
#'
#' This binds randomness that flows through R's generator. Engines that
#' randomize outside it (kernlab's SVMs, the deep-learning engines) cannot be
#' pinned by any R-side scheme, here or in tune.
