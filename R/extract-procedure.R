# The named door onto the `procedure` record.
#
# Every orchestrator stores the record of what ran as the `procedure`
# attribute of its `nested_results`, and `nested_final_fit()` carries the
# record it re-ran as a list slot. Until M67 the help pages and the tuners
# vignette told the reader to reach both by hand. A generic on the shape D-023
# fixed for the `extract_` family gives the record one name on both objects;
# a `procedure()` function would collide with the variable the tuners
# vignette binds and leave the `extract_` idiom.

#' Extract the procedure a nested run used
#'
#' @description
#' `extract_procedure()` returns what a nested run recorded about its
#' procedure: the tuner and its arguments, the selection rule, the control
#' and the workflow. [nested_final_fit()] runs this procedure again.
#'
#' @details
#' `tuner` names the tune or finetune function that ran, with its own
#' arguments beside it:
#'
#' - `"tune_grid"`, with `grid`
#' - `"tune_race_anova"` or `"tune_race_win_loss"`, also with `grid`
#' - `"tune_bayes"`, with `iter`, `initial` and `objective`
#' - `"tune_sim_anneal"`, with `iter` and `initial`
#' - `"fit_resamples"`, with none
#'
#' `select` is the [selection_rule()], and `first_metric` is the first
#' metric of the set, as tune resolves it. `param_info`, `event_level` and
#' `eval_time` are as given. `control` is the control that took effect,
#' with the settings this package forces applied. A `"fit_resamples"`
#' record has no `param_info`, `select` or `first_metric`.
#'
#' `workflow` describes the model and the preprocessor as text, so that
#' [nested_final_fit()] can check that it gets the same workflow. A model
#' argument is stored as written, so a variable's name is stored and not
#' its value. The workflow object and the data are not stored.
#'
#' @param x A `nested_results` from [nested_tune_grid()] or a related
#'   function, or a `nested_final_fit`.
#' @inheritParams print.nested_final_fit
#'
#' @return A named list: `tuner`, the tuner's own arguments, the arguments
#'   that every nested function shares, `control` and `workflow`.
#'
#' @template example-setup
#' @template example-run
#' @template example-final
#' @examplesIf rlang::is_installed(c("recipes", "yardstick"))
#' procedure <- extract_procedure(res)
#' procedure$tuner
#' procedure$control$allow_par
#'
#' identical(extract_procedure(final)$tuner, procedure$tuner)
#'
#' @seealso [nested_final_fit()], [selection_rule()],
#'   [extract_tune_results()], [nested_tune_grid()] and the other loop
#'   functions for what the forced control settings are
#' @export
extract_procedure <- function(x, ...) {
  UseMethod("extract_procedure")
}

#' @export
extract_procedure.default <- function(x, ...) {
  # No dots check before the refusal, for the reason the other defaults give.
  abort_no_extract_method(
    "extract_procedure",
    x,
    classes = c("nested_results", "nested_final_fit"),
    call = rlang::current_env()
  )
}

#' @export
extract_procedure.nested_results <- function(x, ...) {
  rlang::check_dots_empty()
  attr(x, "procedure")
}

#' @export
extract_procedure.nested_final_fit <- function(x, ...) {
  rlang::check_dots_empty()
  x$procedure
}
