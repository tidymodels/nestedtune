#' @section Differences from calling <%= PKG %> directly:
#' **Forced: `allow_par`.** The <%= INNER %> and the outer fit run with
#' `allow_par = FALSE`, because the outer folds carry the parallelism.
#' <%= if (exists("FORCED_TAIL", inherits = FALSE)) FORCED_TAIL else "" %>
