# The named door onto the `procedure` record.
#
# Every orchestrator stores the record of what ran as the `procedure`
# attribute of its `nested_results`, and `nested_final_fit()` carries the
# record it re-ran as a list slot. Until M67 the help pages and the tuners
# vignette told the reader to reach both by hand. A generic on the shape D-023
# fixed for the `extract_` family gives the record one name on both objects;
# a `procedure()` function would collide with the variable the tuners
# vignette binds and leave the `extract_` idiom.

#' Extract the record of the procedure that ran
#'
#' Returns the `procedure` record a nested result carries, or the one a
#' [nested_final_fit()] re-ran: which tuner ran, that tuner's own arguments,
#' and the control as it took effect.
#'
#' A final fit built from a results object re-runs exactly what this record
#' describes, so reading it is how you see what a fit will do before you ask
#' for one.
#'
#' @param x A `nested_results` object from [nested_tune_grid()] or one of its
#'   siblings, or a `nested_final_fit` object from [nested_final_fit()].
#' @inheritParams print.nested_final_fit
#'
#' @return The stored record, unchanged: a flat named list with `tuner`, that
#'   tuner's own arguments, the arguments every orchestrator shares
#'   (`param_info`, `event_level`, `eval_time` and `select`) as they were
#'   given, and `control` as it took effect. The section below says what each
#'   holds.
#'
#' @section What the record holds:
#'
#' `tuner` names the tune or finetune function that ran: `"tune_grid"`,
#' `"tune_bayes"`, `"tune_race_anova"`, `"tune_race_win_loss"`,
#' `"tune_sim_anneal"`, or `"fit_resamples"` for a run with nothing to tune.
#' Beside it sit that tuner's own arguments: `grid` for the grid and racing
#' tuners; `iter`, `initial` and `objective` for the Bayesian one; `iter` and
#' `initial` for simulated annealing; none for the plain fit.
#'
#' `select` is the [selection_rule()] each fold selected by. `control` is the
#' control object the run was given, or tune's default when none was, with the
#' slots this package forces already applied, and with `seed` left out on a
#' Bayesian result. A `"fit_resamples"` record carries no `param_info` and no
#' `select`, since no parameter set was read and no rule applied. See
#' "Differences from calling tune directly" on each orchestrator's help page
#' for what those slots are.
#'
#' On a `nested_results` the record travels as an attribute of the object. On
#' a `nested_final_fit` it is the record the fit re-ran, which is the record of
#' the results object it was built from.
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
