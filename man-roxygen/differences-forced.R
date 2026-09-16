#' @section Differences from calling <%= PKG %> directly:
#' **Forced: `allow_par`.** The <%= INNER %> and the outer scoring fit both
#' run at `allow_par = FALSE`, whatever the control carries, because
#' parallelism belongs over the outer folds.
