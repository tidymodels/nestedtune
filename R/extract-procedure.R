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
#' Returns the `procedure` record a [nested_tune_grid()], [nested_tune_bayes()],
#' [nested_tune_race_anova()], [nested_tune_race_win_loss()] or
#' [nested_tune_sim_anneal()] result carries, or the one a [nested_final_fit()]
#' re-ran: which tuner ran, that tuner's own arguments, and the control as it
#' took effect. A final fit built from a results object re-runs exactly what
#' this record describes.
#'
#' @param x A `nested_results` object from one of the orchestrators, or a
#'   `nested_final_fit` object from [nested_final_fit()].
#' @param ... Not used; must be empty. An argument passed here is an error
#'   rather than silently ignored.
#'
#' @return The stored record, unchanged: a flat named list with `tuner`, the
#'   name of the tune or finetune function that ran (`"tune_grid"`,
#'   `"tune_bayes"`, `"tune_race_anova"`, `"tune_race_win_loss"`,
#'   `"tune_sim_anneal"`, or `"fit_resamples"` from [nested_fit_resamples()]);
#'   that tuner's own arguments (`grid` for the grid and
#'   racing tuners; `iter`, `initial` and `objective` for the Bayesian tuner;
#'   `iter` and `initial` for simulated annealing; none for the plain fit);
#'   the arguments every orchestrator shares, `param_info`, `event_level`,
#'   `eval_time` and `select`, the [selection_rule()] each fold selected by,
#'   as they were given; and `control`, the control object the run was given,
#'   or tune's default when none was, with the slots this package forces
#'   already applied, and on a Bayesian result with `seed` left out. A
#'   `"fit_resamples"` record carries no `param_info` and no `select`: no
#'   parameter set was read and no rule applied. See "Differences from
#'   calling tune directly" on each orchestrator's help page for what those
#'   slots are.
#'
#'   On a `nested_results` the record travels as an attribute of the object;
#'   on a `nested_final_fit` it is the record the fit re-ran, which is the
#'   record of the results object it was built from.
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
#' procedure <- extract_procedure(res)
#' procedure$tuner
#' procedure$control$allow_par
#'
#' set.seed(3)
#' final <- nested_final_fit(wf, res)
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
