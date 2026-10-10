#' @section Reproducibility:
#'
#' Call `set.seed()` before the function, as elsewhere in tidymodels. Each
#' fold takes its seeds from that one seed by its position, so the result is
#' the same serially and in parallel. The seeds are kept as `.tuning_seed`
#' and `.outer_fit_seed`. Engines that draw random numbers outside R, such
#' as kernlab's SVMs, are not covered.
