#' @section Differences from calling <%= PKG %> directly:
#' **Kept from the outer fit: `save_pred`, `extract`.** As on
#' [nested_tune_grid()], the outer fit's predictions and extracts are kept as
#' `.predictions` and `.extracts` when you ask for them. The <%= INNER %>'s
#' own are still discarded.
