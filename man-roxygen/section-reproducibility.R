#' @section Reproducibility:
#'
#' Call `set.seed()` before the function, as elsewhere in tidymodels. Each
#' fold takes its seeds from that one seed by its position, so the result is
#' the same serially and in parallel. The seeds are kept as `.tuning_seed`
#' and `.outer_fit_seed`. The function restores your random state on exit,
#' even after an error. So two calls with no `set.seed()` between them give
#' the same result, as repeated [tune::tune_grid()] calls do.
#'
#' This covers randomness that flows through R's generator. Engines that
#' randomize outside it (kernlab's SVMs, the deep-learning engines) cannot be
#' pinned by any R-side scheme, here or in tune.
