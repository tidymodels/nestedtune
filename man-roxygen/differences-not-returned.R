#' @section Differences from calling <%= PKG %> directly:
#' **Not returned: `save_workflow`.** It lands on the inner `tune_results`
#' a fold record discards, so setting it costs the work and returns
#' nothing. The final fit keeps its own tuning run as `$tuning`, where what
#' it saved is reachable.
