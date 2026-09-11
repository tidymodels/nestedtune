# The readers that stack a per-fold list column with the fold labels beside
# it (M65, D-052). Each is one call in place of an apply loop that hardcodes
# `id`, which is wrong on a repeated design: the labels come from the object's
# record (D-036), through stack_fold_column() in R/nested-results.R.
#
# collect_notes() is a method on tune's generic, because the generic exists
# and its shape -- label columns, then `location`, `type`, `note`, `trace` --
# is the shape wanted. collect_selections() and collect_inner_metrics() are
# this package's own generics, on the pattern agreement() and the extract
# accessors set (D-023, D-039): a default that refuses as a classed
# condition, and one method.

#' Stack a per-fold column of a nested resampling run across the outer folds
#'
#' @description
#' `collect_notes()`, `collect_selections()` and `collect_inner_metrics()`
#' each give you one of a run's per-fold records as a single table. A
#' `nested_results` keeps three such records as one table per outer fold,
#' in list columns. They are what went wrong (`.notes`), what the fold's
#' inner tuning selected (`.selected`), and everything that tuning scored
#' (`.inner_metrics`). Each function stacks one column across the folds,
#' the design's fold labels first, so every row says which fold it came
#' from.
#'
#' * `collect_notes()` stacks `.notes` over every outer fold, failed folds
#'   included. A completed fold can carry an error note too, from an `extract`
#'   that failed on it (see
#'   [`collect_extracts()`][collect_predictions.nested_results]).
#' * `collect_selections()` stacks `.selected`: one row per completed fold. A
#'   [nested_fit_resamples()] result gives no rows, since no fold selected
#'   anything.
#' * `collect_inner_metrics()` stacks `.inner_metrics`: one row per
#'   candidate, a parameter setting, and metric that a completed fold's
#'   inner tuning scored, and per iteration where the tuner iterates.
#'
#' @inheritParams collect_metrics.nested_results
#'
#' @return A tibble whose first columns are the design's fold labels and whose
#'   remaining columns come from the stacked tables. See What the columns are.
#'
#' @section What the columns are:
#'
#' The first columns are the design's fold labels: `id` on a plain v-fold
#' design, `id` and `id2` on a repeated one, read from the object's record
#' rather than recognized by name.
#' Then come the stacked tables' own columns, over the union of what any
#' stacked fold carries. A fold lacking one holds `NA` there, exactly as a fold
#' whose recorded value is `NA` does, so the two cannot be told apart.
#'
#' `collect_notes()` stacks tune's four note columns, from `location` to
#' `trace`. A run that recorded no note gives no rows with those columns. A
#' stacked table carrying a column named like a label column, say a
#' parameter whose id is `id`, is refused with class
#' `nestedtune_collect_name_collision`.
#'
#' @section Which folds are read:
#'
#' `collect_selections()` and `collect_inner_metrics()` read the folds that
#' completed, as [collect_metrics()] and [agreement()] do. A run with some
#' folds failed is stacked over the rest, with one warning of class
#' `nestedtune_partial_summary` naming the missing folds. A run in which no
#' fold completed is an error of class `nestedtune_no_completed_folds`.
#' `collect_notes()` reads every fold and warns about none.
#'
#' @section Reading `.config`:
#'
#' The `.config` of a selection or an inner-metrics row is kept as the fold
#' recorded it. It labels a candidate inside that one fold's tuning run. So
#' a selected row's `.config` is found among the same fold's rows in
#' `collect_inner_metrics()`. Since folds can search different candidates, it
#' identifies nothing across them, which is why [agreement()] leaves it out.
#'
#' @template example-setup
#' @template example-run
#' @examplesIf rlang::is_installed(c("recipes", "yardstick"))
#' collect_selections(res)
#' collect_inner_metrics(res)
#' collect_notes(res)
#'
#' @seealso [collect_metrics()], [agreement()], [summary.nested_results()],
#'   [collect_metrics.nested_results_set()] for the same functions on a
#'   workflow-set run
#' @name collect_selections
#' @export
collect_selections <- function(x, ...) {
  UseMethod("collect_selections")
}

#' @export
collect_selections.default <- function(x, ...) {
  rlang::check_dots_empty()
  # `current_env()` rather than `caller_env()`, for agreement.default()'s
  # reason: inside a method reached by UseMethod() it renders the generic's
  # own call.
  abort_no_collect_method("collect_selections", x, call = rlang::current_env())
}

#' @rdname collect_selections
#' @export
collect_selections.nested_results <- function(x, ...) {
  rlang::check_dots_empty()
  check_any_completed(x, action = "collect")
  warn_partial_summary(x, noun = "table")
  stack_fold_column(
    x,
    ".selected",
    completed_only = TRUE,
    call = rlang::current_env()
  )
}

#' @rdname collect_selections
#' @export
collect_inner_metrics <- function(x, ...) {
  UseMethod("collect_inner_metrics")
}

#' @export
collect_inner_metrics.default <- function(x, ...) {
  rlang::check_dots_empty()
  abort_no_collect_method(
    "collect_inner_metrics",
    x,
    call = rlang::current_env()
  )
}

#' @rdname collect_selections
#' @export
collect_inner_metrics.nested_results <- function(x, ...) {
  rlang::check_dots_empty()
  check_any_completed(x, action = "collect")
  warn_partial_summary(x, noun = "table")
  stack_fold_column(
    x,
    ".inner_metrics",
    completed_only = TRUE,
    call = rlang::current_env()
  )
}

#' @rdname collect_selections
#' @export
collect_notes.nested_results <- function(x, ...) {
  rlang::check_dots_empty()
  stack_fold_column(
    x,
    ".notes",
    completed_only = FALSE,
    call = rlang::current_env()
  )
}

# The refusal for every object the two owned generics have no method for,
# shaped like abort_no_agreement_method() so the families cannot drift apart
# in what they say. Classed, so a caller can catch it as this package's own.
abort_no_collect_method <- function(fn, x, call = rlang::caller_env()) {
  cli::cli_abort(
    c(
      "{.fn {fn}} has no method for {.obj_type_friendly {x}}.",
      i = "It answers for a {.cls nested_results} object, from \\
           {.fn nested_tune_grid} or one of its siblings."
    ),
    class = "nestedtune_no_collect_method",
    call = call
  )
}

# The two readers over what the outer fit kept (M68). Both are methods on
# tune's generics, re-exported beside collect_notes(): the names exist and
# their shapes are the shapes wanted. A run that did not ask for a column is
# refused by name, so a caller learns which control slot to set rather than
# reading an absent column as an empty one.

#' Stack the outer fit's predictions or extracts across the outer folds
#'
#' @description
#' `collect_predictions()` and `collect_extracts()` give you the outer
#' fit's predictions or extracts as one table across the folds. A run whose
#' control asked for them keeps two more records per outer fold.
#' `.predictions`, under `save_pred = TRUE`, holds the predictions the
#' fold's finalized model made on its assessment rows. `.extracts` holds
#' whatever the control's `extract` function returned for the fold's fitted
#' workflow. These two methods on tune's generics stack one such column
#' into a single table, the design's fold labels first.
#'
#' * `collect_predictions()` gives one row per assessment row of every
#'   completed fold, with the columns `tune::last_fit()` produced: the
#'   outcome, the prediction columns, `.row` and `.config`.
#' * `collect_extracts()` gives one row per completed fold, the fold's value in
#'   an `.extracts` list column. A completed fold whose extract function
#'   errored holds `NULL` there, and its `.notes` say why.
#'
#' @param x A `nested_results` run with a control that asked for the column.
#'   See [collect_metrics.nested_results()] for what the object is.
#' @param ... Not used; must be empty. tune's `summarize` and `parameters`
#'   arguments are not offered here.
#'
#' @return A tibble: the design's fold labels (`id`, and `id2` on a repeated
#'   design), then the stacked prediction columns, or the `.extracts` list
#'   column.
#'
#' @section Folds that failed, and columns not saved:
#'
#' Both take the folds that completed, as [collect_selections()] does. They
#' warn once with class `nestedtune_partial_summary` on a partial run and
#' error with class `nestedtune_no_completed_folds` when no fold completed.
#'
#' An object whose recorded control did not ask for the column, or that no
#' longer carries it, is refused with class `nestedtune_column_not_saved`.
#' The message names the control slot to set. A prediction table carrying a
#' column named like a fold label column is refused with class
#' `nestedtune_collect_name_collision`.
#'
#' @section Which predictions these are:
#'
#' Will a row appear twice? On a v-fold outer design each row appears once
#' per repeat. On a Monte Carlo design it appears as often as it was held
#' out. These are the outer fit's predictions on the assessment rows.
#' The inner tuning run's own predictions and extracts, which the same two
#' control slots save inside tune, are not kept.
#'
#' @template example-setup
#' @examplesIf rlang::is_installed(c("recipes", "yardstick"))
#' # Ask the control to keep the predictions and a coefficient extract.
#' set.seed(2)
#' res <- nested_tune_grid(
#'   wf,
#'   folds,
#'   grid = data.frame(num_comp = 1:2),
#'   control = tune::control_grid(
#'     save_pred = TRUE,
#'     extract = function(x) coef(workflows::extract_fit_engine(x))
#'   )
#' )
#'
#' collect_predictions(res)
#' collect_extracts(res)
#'
#' @seealso [collect_selections()], [collect_metrics()], [nested_tune_grid()],
#'   [collect_metrics.nested_results_set()] for the same functions on a
#'   workflow-set run
#' @name collect_predictions.nested_results
NULL

#' @rdname collect_predictions.nested_results
#' @export
collect_predictions.nested_results <- function(x, ...) {
  rlang::check_dots_empty()
  check_any_completed(x, action = "collect")
  check_column_saved(x, ".predictions", call = rlang::current_env())
  warn_partial_summary(x, noun = "table")
  stack_fold_column(
    x,
    ".predictions",
    completed_only = TRUE,
    call = rlang::current_env()
  )
}

#' @rdname collect_predictions.nested_results
#' @export
collect_extracts.nested_results <- function(x, ...) {
  rlang::check_dots_empty()
  check_any_completed(x, action = "collect")
  check_column_saved(x, ".extracts", call = rlang::current_env())
  warn_partial_summary(x, noun = "table")
  # A fold's extract is one value of whatever kind the function returned,
  # so each becomes a one-row table holding it in a list column, tune's own
  # shape; a NULL (the function errored on that fold) is a row too, so the
  # table has one row per completed fold and a missing value is seen rather
  # than dropped (IP4).
  tables <- lapply(x$.extracts, function(v) new_tbl(list(.extracts = list(v))))
  stack_fold_column(
    x,
    ".extracts",
    completed_only = TRUE,
    call = rlang::current_env(),
    tables = tables
  )
}

# The refusal for an object whose run did not keep the column asked for. The
# record the readers trust is the recorded procedure's control: it says
# whether the run asked, so a column a caller added by hand to a run that
# never saved one is not read back as the outer fit's, even though
# `record_columns()` admits it to the class invariant, which vouches for a
# column's consistency across verbs and not for where it came from. The
# object's names say whether the column is still there. Either failing
# refuses, the first naming the control slot and the control function the
# recorded procedure says the run took. A results object carries no `procedure` only
# if it was built before M46, and then the column's presence is all there is
# to read and the slot alone is named.
check_column_saved <- function(x, column, call = rlang::caller_env()) {
  control <- attr(x, "procedure")$control
  present <- column %in% names(x)
  asked <- if (is.null(control)) {
    present
  } else {
    switch(
      column,
      .predictions = isTRUE(control$save_pred),
      .extracts = is.function(control$extract)
    )
  }
  if (asked && present) {
    return(invisible(x))
  }
  slot <- switch(column, .predictions = "save_pred", .extracts = "extract")
  if (asked) {
    cli::cli_abort(
      c(
        "This object no longer carries {.code {column}}, though its run's \\
         control set {.arg {slot}}.",
        i = "Read the column from the object the run returned."
      ),
      class = "nestedtune_column_not_saved",
      call = call
    )
  }
  setting <- switch(
    column,
    .predictions = "save_pred = TRUE",
    .extracts = "extract = <a function>"
  )
  tuner <- attr(x, "procedure")$tuner
  control_fn <- if (is.null(tuner)) {
    "the control passed through {.arg ...}"
  } else {
    paste0(
      "{.fn ",
      tuner_entry(tuner)$package,
      "::",
      control_class(tuner),
      "} passed through {.arg ...}"
    )
  }
  cli::cli_abort(
    c(
      "This run did not keep {.code {column}}: its control did not set \\
       {.arg {slot}}.",
      i = paste0("Run it again with {.code ", setting, "} in ", control_fn, ".")
    ),
    class = "nestedtune_column_not_saved",
    call = call
  )
}
