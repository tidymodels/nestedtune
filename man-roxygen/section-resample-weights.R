#' @section Weighting the outer folds:
#'
#' Weights set on the design with [tune::add_resample_weights()] reach the
#' outer average. `collect_metrics()`, `summary()`, `autoplot()` and
#' `compute_metrics()` then report the weighted mean of the folds'
#' estimates. Their `std_err` is the weighted standard deviation over the
#' square root of the effective sample size, as tune computes both. The
#' per-fold table from `collect_metrics(summarize = FALSE)` carries each
#' fold's weight in a `.weight` column. tune stores the weights scaled to
#' sum to one, and stores none when they are equal, so equal weights give
#' the unweighted average.
#'
#' A fold that fails, or that scores `NA` on a metric, is left out of that
#' average and the remaining weights are scaled up to sum to one. `n` counts
#' the folds that scored. The weights on a design's inner resamples are read
#' by tune itself.
