#' @section Differences from calling <%= PKG %> directly:
#' **Not returned: `save_workflow`.** The nested run does not keep the inner
#' tuning results, so this setting returns nothing there.
#' [nested_final_fit()] keeps its own tuning run as `$tuning`, which holds
#' what the setting saved.
