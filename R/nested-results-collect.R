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
#' A `nested_results` object keeps three of its records as one table per outer
#' fold, in list columns: what went wrong (`.notes`), what the fold's inner
#' tuning selected (`.selected`), and everything that tuning scored
#' (`.inner_metrics`). These three readers stack one such column into a single
#' table, with the columns the design labelled its folds with placed first, so
#' the rows of every fold are read at once and each row says which fold it
#' came from.
#'
#' * `collect_notes()` stacks `.notes` over every outer fold, failed folds
#'   included -- a failed fold's notes are the reason to ask.
#' * `collect_selections()` stacks `.selected` over the folds that completed:
#'   one row per completed fold.
#' * `collect_inner_metrics()` stacks `.inner_metrics` over the folds that
#'   completed: one row per candidate (and per metric, and per iteration
#'   where the tuner iterates) that each fold's inner tuning scored.
#'
#' @param x A `nested_results` object from [nested_tune_grid()] or one of its
#'   siblings.
#' @param ... Not used; must be empty. An argument passed here is an error
#'   rather than silently ignored.
#'
#' @return A tibble. The first columns are the design's fold labels, read from
#'   the object's record rather than recognized by name: `id` on a plain
#'   v-fold design, `id` and `id2` on a repeated one. Then the columns of the
#'   stacked tables, as the list column holds them, over the union of the
#'   columns any stacked fold carries; a fold lacking one of them holds `NA`
#'   there, in the same way as a fold whose recorded value is `NA`, so the
#'   two are not told apart. For `collect_notes()` those are tune's
#'   `location`, `type`, `note` and `trace`, and a run that recorded no note
#'   gives zero rows with the same columns. A stacked table carrying a column
#'   named like a fold label column (a parameter given the id `id`) is
#'   refused with condition class `nestedtune_collect_name_collision`.
#'
#' @details
#' `collect_selections()` and `collect_inner_metrics()` read the folds that
#' completed, the rule [collect_metrics()] and [agreement()] follow. A run in
#' which some outer folds failed is stacked over the folds that completed,
#' with one warning of class `nestedtune_partial_summary` saying which folds
#' are missing; a run in which no fold completed is an error with condition
#' class `nestedtune_no_completed_folds`, the class every summary of such an
#' object refuses with. `collect_notes()` reads every fold and warns about
#' none of them.
#'
#' The `.config` column of a selection or an inner-metrics row is kept as the
#' fold recorded it. It labels a candidate within *that fold's own* inner
#' tuning run -- a selected row's `.config` is found among the same fold's
#' rows in `collect_inner_metrics()` -- and is not an identity across folds,
#' which can search different candidate sets. That is why [agreement()]
#' leaves it out and these readers keep it.
#'
#' A user of tune will recognize `collect_notes()`: it is tune's generic, and
#' this method answers for a `nested_results` the way tune's answers for a
#' `tune_results`.
#'
#' @examplesIf rlang::is_installed(c("recipes", "yardstick"))
#' data(mtcars)
#'
#' rec <- recipes::step_pca(
#'   recipes::recipe(mpg ~ ., data = mtcars),
#'   recipes::all_predictors(),
#'   num_comp = tune::tune()
#' )
#' wf <- workflows::workflow(rec, parsnip::linear_reg())
#'
#' set.seed(1)
#' folds <- nested_resamples(
#'   mtcars,
#'   outside = rsample::vfold_cv(v = 3),
#'   inside = rsample::vfold_cv(v = 3)
#' )
#'
#' set.seed(2)
#' res <- nested_tune_grid(wf, folds, grid = data.frame(num_comp = 1:3))
#'
#' collect_selections(res)
#' collect_inner_metrics(res)
#' collect_notes(res)
#'
#' @seealso [collect_metrics()], [agreement()], [summary.nested_results()]
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
#' A run whose control asked for them keeps, per outer fold, the predictions
#' its finalized model made on the fold's assessment rows (`.predictions`,
#' under `save_pred = TRUE`) and the value the control's `extract` function
#' returned for the fold's fitted workflow (`.extracts`). These two readers,
#' methods on tune's generics, stack one such column into a single table with
#' the columns the design labelled its folds with placed first.
#'
#' * `collect_predictions()` stacks `.predictions` over the folds that
#'   completed: one row per assessment row of every completed fold, the
#'   columns as `tune::last_fit()` produced them (the outcome, `.pred` or the
#'   class columns, `.row` and `.config`).
#' * `collect_extracts()` gives one row per completed fold, the fold's value
#'   in an `.extracts` list column. A completed fold whose extract function
#'   errored holds `NULL` there, and its `.notes` say why.
#'
#' @param x A `nested_results` object from [nested_tune_grid()] or one of its
#'   siblings, run with a control that asked for the column.
#' @param ... Not used; must be empty. An argument passed here is an error
#'   rather than silently ignored. tune's `summarize` and `parameters`
#'   arguments are not offered.
#'
#' @return A tibble. The first columns are the design's fold labels, read from
#'   the object's record: `id` on a plain v-fold design, `id` and `id2` on a
#'   repeated one. Then, for `collect_predictions()`, the columns of the
#'   stacked prediction tables over the union of the columns any fold
#'   carries, `NA` where a fold lacks one; for `collect_extracts()`, the
#'   `.extracts` list column. A prediction table carrying a column named like
#'   a fold label column is refused with condition class
#'   `nestedtune_collect_name_collision`.
#'
#' @details
#' Both read the folds that completed, the rule [collect_selections()] and
#' [collect_metrics()] follow: a partial run is stacked over the completed
#' folds with one warning of class `nestedtune_partial_summary`, and a run in
#' which no fold completed is an error of class
#' `nestedtune_no_completed_folds`. An object that carries no `.predictions`
#' or `.extracts` column, because its run's control did not ask for it, is
#' refused with condition class `nestedtune_column_not_saved`, the message
#' naming the slot to set.
#'
#' The predictions are the outer fit's, one held-out row each, so every row
#' of the data appears once per repeat of the design in
#' `collect_predictions()`'s table. The inner tuning run's predictions and
#' extracts, which the same two slots also save inside tune, are not kept.
#'
#' @examplesIf rlang::is_installed(c("recipes", "yardstick"))
#' data(mtcars)
#'
#' rec <- recipes::step_pca(
#'   recipes::recipe(mpg ~ ., data = mtcars),
#'   recipes::all_predictors(),
#'   num_comp = tune::tune()
#' )
#' wf <- workflows::workflow(rec, parsnip::linear_reg())
#'
#' set.seed(1)
#' folds <- nested_resamples(
#'   mtcars,
#'   outside = rsample::vfold_cv(v = 3),
#'   inside = rsample::vfold_cv(v = 3)
#' )
#'
#' set.seed(2)
#' res <- nested_tune_grid(
#'   wf,
#'   folds,
#'   grid = data.frame(num_comp = 1:3),
#'   control = tune::control_grid(
#'     save_pred = TRUE,
#'     extract = function(x) coef(workflows::extract_fit_engine(x))
#'   )
#' )
#'
#' collect_predictions(res)
#' collect_extracts(res)
#'
#' @seealso [collect_selections()], [collect_metrics()], [nested_tune_grid()]
#' @name collect_predictions
NULL

#' @rdname collect_predictions
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

#' @rdname collect_predictions
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

# The refusal for an object whose run did not keep the column asked for,
# naming the control slot and the control function the recorded procedure
# says the run took. A results object carries no `procedure` only if it was
# built before M46, and then the slot alone is named.
check_column_saved <- function(x, column, call = rlang::caller_env()) {
  if (column %in% names(x)) {
    return(invisible(x))
  }
  slot <- switch(column, .predictions = "save_pred", .extracts = "extract")
  setting <- switch(
    column,
    .predictions = "save_pred = TRUE",
    .extracts = "extract = <a function>"
  )
  tuner <- attr(x, "procedure")$tuner
  control <- if (is.null(tuner)) {
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
      i = paste0("Run it again with {.code ", setting, "} in ", control, ".")
    ),
    class = "nestedtune_column_not_saved",
    call = call
  )
}
