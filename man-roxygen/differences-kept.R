#' @section Differences from calling <%= PKG %> directly:
#' **Kept from the outer fit: `save_pred`, `extract`.** Each reaches the
#' outer fit as well as the <%= INNER %>. The outer fit's
#' predictions and extracts are kept as `.predictions` and `.extracts`, as
#' the grid page describes, and the <%= INNER %>'s own are still discarded.
