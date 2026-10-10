# Prediction on the final fit.
#
# Both methods hand the call to the trained workflow the object carries, so
# what comes back is what `extract_workflow(x)` would give -- the object gains
# no prediction behavior of its own. What it deliberately still lacks is any
# generic that would produce a performance number (D-014, IP3): augmenting the
# training rows yields residuals, and the help page below says what those are
# not.
#
# The two treat `...` differently, on purpose (GP1). `predict()` forwards it,
# because parsnip's `check_pred_type_dots()` refuses any name outside its own
# short list of predict arguments on the way through, so an unknown argument
# is an error there rather than a silent no-op here (a listed name the model
# cannot use, `level` without `type = "conf_int"` say, is passed on and may be
# ignored -- parsnip's behavior, not this method's). `augment()` fences it, because
# `workflows::augment.workflow()` passes its dots on unread and parsnip's
# `augment()` methods ignore them, so a fence here is the only place the
# argument would be refused at all (both verified 2026-09-02, workflows 1.3.0,
# parsnip 1.6.0).

#' Predict with the final model
#'
#' @description
#' `predict()` and `augment()` on a `nested_final_fit` call the trained
#' workflow's own methods. Each returns what the same call on
#' [extract_workflow()]`(x)` returns.
#'
#' @details
#' Residuals on the rows the model was fit on are in-sample, so they do not
#' measure performance. Report the nested estimate from [collect_metrics()]
#' on the nested run the fit was built from.
#'
#' @param object,x A `nested_final_fit` from [nested_final_fit()].
#' @param new_data A data frame of new observations to predict.
#' @param type,opts Passed to [workflows::predict.workflow()] unchanged.
#'   `type` selects the prediction type, such as `"numeric"`, `"prob"` or
#'   `"survival"`.
#' @param eval_time For censored regression, the times at which to evaluate
#'   survival probabilities in `augment()`. Ignored otherwise.
#' @param ... For `predict()`, arguments for the model's predict method,
#'   such as `level` with `type = "conf_int"`. parsnip gives an error for a
#'   name outside its list of predict arguments. For `augment()`, not used,
#'   and must be empty.
#'
#' @return `predict()` returns the workflow's tibble of predictions.
#'   `augment()` returns the prediction columns, then the columns of
#'   `new_data`, with a `.resid` column for a regression model when the
#'   outcome is present.
#'
#' @template example-setup
#' @template example-run
#' @template example-final
#' @examplesIf rlang::is_installed(c("recipes", "yardstick"))
#' predict(final, new_data = mtcars[1:3, ])
#' predict(final, new_data = mtcars[1:3, ], type = "conf_int", level = 0.9)
#' augment(final, new_data = mtcars[1:3, ])
#'
#' @seealso [nested_final_fit()], [extract_workflow()],
#'   [workflows::predict.workflow()], [workflows::augment.workflow()]
#' @name predict.nested_final_fit
#' @export
predict.nested_final_fit <- function(
  object,
  new_data,
  type = NULL,
  opts = list(),
  ...
) {
  stats::predict(
    object$workflow,
    new_data = new_data,
    type = type,
    opts = opts,
    ...
  )
}

#' @rdname predict.nested_final_fit
#' @importFrom tune augment
#' @export
augment.nested_final_fit <- function(x, new_data, eval_time = NULL, ...) {
  rlang::check_dots_empty()
  augment(x$workflow, new_data = new_data, eval_time = eval_time)
}
