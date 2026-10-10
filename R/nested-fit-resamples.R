#' Score a workflow with nothing to tune on a nested design
#'
#' @description
#' `nested_fit_resamples()` scores a workflow with nothing to tune on a
#' nested design. Each outer fold fits the workflow on its analysis set and
#' scores it on the rows it held out.
#'
#' @details
#' Use it for a baseline to compare with a tuned workflow. On the same
#' design, the two runs score the same outer folds, so their per-fold metrics
#' join by fold label. [tune::fit_resamples()] does the same job on a plain
#' set of folds. [nested_tune_grid()] documents what the loop functions
#' share, such as the design, the seeds, failed folds and parallel execution.
#'
#' A workflow with a [tune::tune()] marker is an error here, and a workflow
#' with none is an error in the tuning functions.
#'
#' Fold `i` is [tune::last_fit()] of `object` on `resamples$splits[[i]]`,
#' under the seed in `res$.outer_fit_seed[[i]]`. Each fold also draws a
#' tuning seed that nothing uses, so the outer-fit seeds match those of a
#' tuned run on the same design.
#'
#' [collect_selections()], [collect_inner_metrics()] and [agreement()]
#' return zero rows, and `autoplot(type = "parameters")` is an error.
#' [nested_final_fit()] fits the workflow on all the data.
#'
#' @inheritParams nested_tune_grid
#' @inheritParams tune::fit_resamples
#' @param metrics A [yardstick::metric_set()], or `NULL` for tune's default
#'   set. Every metric is scored on the outer folds.
#' @param object A [workflows::workflow()] with no parameter marked with
#'   [tune::tune()], or a parsnip model specification given with
#'   `preprocessor`.
#' @templateVar CONSTRUCTOR tune::control_resamples()
#' @templateVar PKG tune
#' @template param-control-dots
#' @templateVar SCOPE It applies to the outer scoring fit.
#' @template param-event-level
#' @templateVar REFUSED Times that are not numeric, empty, missing, negative or not finite are an error.
#' @template param-eval-time
#'
#' @return A `nested_results`, as [nested_tune_grid()] describes.
#'   `.selected` is a zero-column tibble on each completed fold, and
#'   `.inner_metrics` has zero rows. There is no `grid` attribute.
#'
#' @section Differences from calling tune directly:
#'
#' A [tune::control_resamples()] passed through `...` as `control` is kept
#' as `extract_procedure(res)$control`. The one tune call a fold makes is
#' the outer fit, which runs under its own [tune::control_last_fit()]. tune
#' gives [tune::control_grid()] and `control_last_fit()` the same class, so
#' both are accepted too.
#'
#' **Forced: `allow_par`.** The outer fit runs with `allow_par = FALSE`,
#' because the outer folds carry the parallelism.
#'
#' **Settable as its own argument: `event_level`.** Set the level with the
#' `event_level` argument. A control that names another level is an error.
#' `eval_time` is an argument too.
#'
#' @templateVar OTHER control_bayes()
#' @template differences-refused
#' @section Differences from calling tune directly:
#' **Passed through: none.** There is no inner tuning call.
#'
#' **Kept from the outer fit: `save_pred`, `extract`.** With
#' `save_pred = TRUE`, the result has a `.predictions` column. With an
#' `extract` function, it has an `.extracts` column. Without them, the outer
#' fit's predictions and extracts are still discarded.
#'
#' **Not returned: none.** There is no inner run.
#'
#' **Inert: `verbose`, `pkgs`, `save_workflow`, `parallel_over`,
#' `backend_options`, `workflow_size`.** Each one sets an inner tuning call
#' that this function never makes.
#'
#' @template example-setup
#' @examplesIf rlang::is_installed(c("recipes", "yardstick"))
#' # A fixed workflow: no tune() marker anywhere.
#' fixed <- workflows::workflow(mpg ~ ., parsnip::linear_reg())
#'
#' set.seed(2)
#' res <- nested_fit_resamples(fixed, folds)
#' collect_metrics(res)
#'
#' # The record says no tuning ran.
#' extract_procedure(res)$tuner
#' res$.selected[[1]]
#'
#' @templateVar LINKS [tune::fit_resamples()]
#' @template seealso-orchestrator
#' @export
nested_fit_resamples <- function(object, ...) {
  UseMethod("nested_fit_resamples")
}

#' @rdname nested_fit_resamples
#' @export
nested_fit_resamples.default <- function(object, ...) {
  abort_bad_object(object)
}

# The model-spec door, as `nested_tune_grid.model_spec()` describes it.
#' @rdname nested_fit_resamples
#' @export
nested_fit_resamples.model_spec <- function(
  object,
  preprocessor,
  resamples,
  ...,
  metrics = NULL,
  event_level = "first",
  eval_time = NULL
) {
  check_preprocessor(preprocessor)
  rlang::check_required(resamples)
  with_user_call(nested_fit_resamples(
    workflows::workflow(preprocessor, object),
    resamples,
    ...,
    metrics = metrics,
    event_level = event_level,
    eval_time = eval_time
  ))
}

#' @rdname nested_fit_resamples
#' @export
nested_fit_resamples.workflow <- function(
  object,
  resamples,
  ...,
  metrics = NULL,
  event_level = "first",
  eval_time = NULL
) {
  dots <- capture_dots(...)
  check_no_preprocessor(dots, resamples)
  rlang::check_required(resamples)
  control <- check_dots_control(dots)
  check_workflow(object)
  # The door this function is (D-057): a marked workflow goes to the five,
  # refused here before the design is judged.
  check_tuned_workflow(object)
  check_nested(resamples)
  check_metrics(metrics)
  check_event_level(event_level)
  check_eval_time(eval_time)
  control <- check_control(control, "fit_resamples", event_level)

  # No parameter set, no grid and no rule: the description says the tuner
  # selects nothing, and the loop's fold skips the inner stage on that word
  # (`nested_fold_fit()`, R/nested-tune-grid.R). `select` is NULL rather than
  # a default rule so the record cannot carry one (`new_procedure()`).
  nested_loop(
    object,
    resamples,
    tuner = tuner_fit_resamples(),
    metrics = metrics,
    param_info = NULL,
    event_level = event_level,
    eval_time = eval_time,
    select = NULL,
    control = control,
    grid = NULL,
    call = rlang::current_env()
  )
}
