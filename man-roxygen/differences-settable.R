#' @section Differences from calling <%= PKG %> directly:
#' **Settable as its own argument: `event_level`.** Set the level with the
#' `event_level` argument, as on [nested_tune_grid()]. A control left at the
#' default level, `"first"`, takes the argument's level. A control set to
#' another level than the argument's is an error.
#' <%= if (exists("SETTABLE_TAIL", inherits = FALSE)) SETTABLE_TAIL else "" %>
