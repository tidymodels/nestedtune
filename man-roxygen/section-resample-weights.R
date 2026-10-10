#' @section Weighting the outer folds:
#'
#' Weights set on the design with [tune::add_resample_weights()] give a
#' weighted average of the outer folds' estimates, as tune computes it. A
#' fold that fails or scores `NA` is left out, and the other weights are
#' scaled to sum to one.
