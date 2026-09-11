# The named door onto the `procedure` record.
#
# Every orchestrator stores the record of what ran as the `procedure`
# attribute of its `nested_results`, and `nested_final_fit()` carries the
# record it re-ran as a list slot. Until M67 the help pages and the tuners
# vignette told the reader to reach both by hand. A generic on the shape D-023
# fixed for the `extract_` family gives the record one name on both objects;
# a `procedure()` function would collide with the variable the tuners
# vignette binds and leave the `extract_` idiom.

#' Extract the record of what ran
#'
#' Returns the `procedure` record a nested result carries, the tune, select
#' and fit steps as they were set. It says which tuner ran, that tuner's
#' own arguments, the control as it took effect, and the workflow the run
#' was given. A [nested_final_fit()] carries the record it re-ran.
#'
#' Reading this record is how you see what a final fit will do before you
#' ask for one. A final fit built from a results object re-runs exactly
#' what the record describes.
#'
#' @param x A `nested_results` object from [nested_tune_grid()] or one of its
#'   siblings, or a `nested_final_fit` object from [nested_final_fit()].
#' @inheritParams print.nested_final_fit
#'
#' @return The stored record, unchanged: a named list with `tuner`,
#'   that tuner's own arguments, the arguments every loop function shares,
#'   `control` as it took effect, and the `workflow` identity. The section
#'   below says what each holds.
#'
#' @section What the record holds:
#'
#' `tuner` names the tune or finetune function that ran, with that tuner's
#' own arguments beside it:
#'
#' - `"tune_grid"`, with `grid`
#' - `"tune_race_anova"` or `"tune_race_win_loss"`, also with `grid`
#' - `"tune_bayes"`, with `iter`, `initial` and `objective`
#' - `"tune_sim_anneal"`, with `iter` and `initial`
#' - `"fit_resamples"`, for a run with nothing to tune, with none
#'
#' `select` is the [selection_rule()] each fold selected by. `param_info`,
#' `event_level` and `eval_time` are as they were given. `control` is the
#' control object the run was given, or tune's default when none was, with
#' the slots this package forces already applied. On a Bayesian result
#' `seed` is left out. A `"fit_resamples"` record carries no `param_info`
#' and no `select`, since no parameter set was read and no rule applied.
#' See "Differences from calling tune directly" on each loop function's
#' help page for what those slots are.
#'
#' `workflow` is the identity of the model specification and the
#' preprocessor the run was given: the model's type, engine, mode and
#' arguments, and the preprocessor, each in deparsed form. A formula or a
#' variables selection is held as written. A recipe is held as its steps
#' in order, with each step's selectors and settings, and its random step
#' ids left out. Case weights and a postprocessor are not held. The
#' workflow object itself is not stored, and no data rows are. A model
#' argument is held as written, so a name bound outside the workflow is
#' held as that name and not as its value. [nested_final_fit()] compares
#' the workflow it is handed against this entry and refuses one that
#' differs, with class `nestedtune_workflow_mismatch`.
#'
#' On a `nested_results` the record travels as an attribute of the object.
#' On a `nested_final_fit` it is the record the fit re-ran, which is the
#' record of the results object it was built from.
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
#' @seealso [nested_final_fit()], [extract_tune_results()],
#'   [nested_tune_grid()]
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
