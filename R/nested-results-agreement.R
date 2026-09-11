# How often each candidate was selected across the outer folds.
#
# summary() prints the selections one parameter at a time and autoplot() draws
# them; this is the same fact as a table, keyed by the whole selected
# combination rather than by one parameter (M44, issue #36). Nothing here ranks
# the folds or names a winner: the most frequent row is a description of the
# procedure's choices, and the final model's parameters come from
# nested_final_fit() running the same procedure on the whole data (D-014).

#' Tabulate how often each parameter setting was selected across the outer folds
#'
#' @description
#' `agreement()` tells you how often the outer folds agreed on what to
#' select. Each outer fold tunes on its own inner resamples and selects one
#' candidate, one parameter setting. `agreement()` counts those selections:
#' one row per distinct combination of selected parameter values, most
#' frequent first.
#'
#' The most frequent combination is not the final model's parameters. The
#' tuning procedure is tune then select, and the folds say how stable its
#' choice is. The model to deploy comes from [nested_final_fit()], which
#' runs the procedure once more on the whole dataset and selects for
#' itself.
#'
#' @inheritParams collect_metrics.nested_results
#' @return A tibble with one column per parameter any completed fold selected,
#'   then `n`, the number of completed folds that chose that combination, and
#'   `prop`, `n` over the number of completed folds. Rows run from the largest
#'   `n` down, ties in the order the combination first appears.
#'
#' @section How the folds are counted:
#'
#' Every completed fold is counted once, so `sum(n)` is the number of completed
#' folds whenever the table has rows. A run with some folds failed is
#' tabulated over the rest, with a warning saying so. A run in which none
#' completed is an error of class `nestedtune_no_completed_folds`, as it is
#' for [collect_metrics()], [autoplot()][autoplot.nested_results] and
#' [nested_final_fit()].
#'
#' tune's `.config` is not a column here: it labels a candidate inside one
#' fold's own tuning run, and folds can search different grids.
#'
#' @section Missing and colliding values:
#'
#' A completed fold whose selection carries no value for a parameter is counted
#' under `NA` for it, in the same row as a fold that selected `NA`.
#' [summary.nested_results()] tells the two apart. A workflow with nothing to
#' tune gives columns `n` and `prop` and no rows. A parameter whose id is `n`
#' or `prop` would collide with the counts and is an error.
#'
#' @template example-setup
#' @template example-run
#' @examplesIf rlang::is_installed(c("recipes", "yardstick"))
#' agreement(res)
#'
#' @seealso [summary.nested_results()], [autoplot.nested_results()],
#'   [nested_final_fit()], [summary.nested_results_set()] for a workflow-set
#'   run
#' @export
agreement <- function(x, ...) {
  UseMethod("agreement")
}

#' @export
agreement.default <- function(x, ...) {
  rlang::check_dots_empty()
  # `current_env()` and not `caller_env()`: inside a method reached by
  # UseMethod() the former renders the generic's own call -- `agreement(x)` --
  # while the latter renders the call one frame further out, naming whatever
  # function the user happened to be inside.
  abort_no_agreement_method(x, call = rlang::current_env())
}

#' @export
agreement.nested_results <- function(x, ...) {
  rlang::check_dots_empty()
  check_any_completed(x, action = "tabulate")
  warn_partial_summary(x, noun = "table")

  selected <- x$.selected[x$.completed]
  completed <- length(selected)
  params <- selection_params(selected)
  clash <- intersect(params, c("n", "prop"))
  if (length(clash) > 0L) {
    cli::cli_abort(
      c(
        "{.fn agreement} cannot tabulate a parameter with id {.val {clash}}.",
        i = "The table's count columns are {.code n} and {.code prop}; give \\
             the parameter another id in {.fn tune::tune}."
      ),
      class = "nestedtune_agreement_name_collision"
    )
  }
  if (length(params) == 0L) {
    return(new_tbl(list(n = integer(), prop = double())))
  }

  # One row per completed fold, in fold order, over the union of the parameters
  # any fold chose. A fold with no value for a parameter holds NA there, so it
  # still counts as a fold and its combination stays distinct from the folds
  # that chose a value. Stacked through vctrs rather than `$` on the column
  # (M06): the selections are tune's tibbles, and a fold's missing column is
  # filled by the common type, never by whichever fold happened to come first.
  rows <- lapply(selected, function(s) {
    cols <- lapply(params, function(p) if (p %in% names(s)) s[[p]] else NA)
    names(cols) <- params
    vctrs::new_data_frame(cols)
  })
  stacked <- vctrs::vec_rbind(!!!rows)

  # `sort = "location"` keeps first appearance; order() is stable, so ties in
  # `n` keep it after the sort. NA is one value here: two folds that both
  # recorded no value for a parameter chose the same thing, and vec_count()
  # groups them together as it does any other equal keys.
  counts <- vctrs::vec_count(stacked, sort = "location")
  counts <- counts[order(-counts$count), , drop = FALSE]

  out <- as.list(counts$key)
  out$n <- counts$count
  out$prop <- counts$count / completed
  new_tbl(out)
}

#' @name summary.nested_results_set
#' @rdname summary.nested_results_set
#' @export
agreement.nested_results_set <- function(x, ...) {
  rlang::check_dots_empty()
  # Each element's table, the id in front, bound in set order over the
  # union of the elements' parameter columns; a parameter named `n` or
  # `prop` is refused by the element's own method, and `wflow_id` by the
  # stacking, each naming the workflow (R/nested-results-set.R). The bind
  # puts a later element's parameter after the first element's counts, so
  # the columns are put back in the single table's order: the parameters,
  # then the counts.
  out <- stack_set(x, agreement, call = rlang::current_env())
  counts <- c("n", "prop")
  params <- setdiff(names(out), c("wflow_id", counts))
  new_tbl(as.list(out)[c("wflow_id", params, counts)])
}

# The refusal for every object this generic has no method for, shaped like
# abort_no_extract_method() so the two families cannot drift apart in what
# they say. Classed, so a caller can catch it as this package's own rather than
# by matching the message.
abort_no_agreement_method <- function(x, call = rlang::caller_env()) {
  cli::cli_abort(
    c(
      "{.fn agreement} has no method for {.obj_type_friendly {x}}.",
      i = "It answers for a {.cls nested_results} object, from \\
           {.fn nested_tune_grid} or one of its siblings."
    ),
    class = "nestedtune_no_agreement_method",
    call = call
  )
}
