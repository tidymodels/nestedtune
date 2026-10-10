#' Nested cross-validation with Bayesian optimization inside
#'
#' @description
#' `nested_tune_bayes()` estimates how well a model tuned with
#' [tune::tune_bayes()] performs on new data. It runs the loop of
#' [nested_tune_grid()], with a Bayesian search on each outer fold's inner
#' resamples.
#'
#' @details
#' Each outer fold scores `initial` candidates from a space-filling design. A
#' Gaussian process then proposes `iter` more candidates, one at a time. The
#' fold picks a candidate with `select`, fits it on its analysis set and
#' scores it on the rows it held out. [nested_tune_grid()] documents what the
#' loop functions share, such as the design, what the estimate describes, the
#' seeds, failed folds and parallel execution.
#'
#' `iter = 0` scores the initial candidates and proposes nothing. tune stops a
#' fold's search early when no new candidate remains, or after `no_improve`
#' iterations in a row without improvement (ten by default). The fold then
#' keeps the candidates it scored.
#'
#' [tune::tune_bayes()] does not accept a parameter range that depends on the
#' data, such as `mtry()`. Set its range in `param_info` before the call, or
#' every fold fails.
#'
#' @inheritParams nested_tune_grid
#' @inheritParams tune::tune_bayes
#' @templateVar CONSTRUCTOR tune::control_bayes()
#' @templateVar PKG tune
#' @template param-control-dots
#' @param initial The number of candidates each fold scores before the first
#'   iteration, a whole number of at least 2. A `tune_results` object is an
#'   error, because one tuning run cannot serve every outer fold.
#' @param objective An acquisition function from tune. It decides which
#'   candidate the Gaussian process proposes next: [tune::exp_improve()] (the
#'   default), [tune::prob_improve()] or [tune::conf_bound()].
#'
#' @return A `nested_results`, as [nested_tune_grid()] describes. Each fold's
#'   `.inner_metrics` has an `.iter` column. It is `0` for the initial
#'   candidates and `i` for the candidate the `i`-th iteration proposed.
#'   There is no `grid` attribute.
#'
#' @section Differences from calling tune directly:
#'
#' A [tune::control_bayes()] passed through `...` as `control` reaches the
#' inner `tune_bayes()` in every fold, and [nested_final_fit()] runs again
#' with it. For example, `control = control_bayes(no_improve = 5)` stops each
#' search sooner. The result keeps the control that ran, without `seed`, as
#' `extract_procedure(res)$control`. Its settings differ from a direct call as
#' follows.
#'
#' **Forced: `allow_par`, `seed`.** `allow_par` is `FALSE`, because the outer
#' folds carry the parallelism. `seed` is set to the fold's tuning seed. Left
#' to tune, it is drawn from the random stream, so the proposals depend on
#' how much of the stream tune used before it.
#'
#' @templateVar INNER inner search
#' @templateVar SETTABLE_TAIL `iter`, `initial`, `objective` and `eval_time` are arguments of `tune_bayes()`, not control settings.
#' @template differences-settable
#' @template differences-refused-plain
#' @section Differences from calling tune directly:
#' **Passed through: `no_improve`, `uncertain`, `time_limit`, `verbose`,
#' `verbose_iter`, `save_gp_scoring`, `pkgs`, `parallel_over`,
#' `workflow_size`.** Each reaches `tune_bayes()` as given:
#'
#' - `no_improve` and `uncertain` act on each fold's search as in a direct
#'   call.
#' - `time_limit` stops a search by the clock, so two runs with the same
#'   seed can differ from one machine to another.
#' - `verbose` and `verbose_iter` print from each fold, and only a serial
#'   run shows the output.
#' - `save_gp_scoring` writes its files to the temporary directory of the
#'   process that tuned the fold.
#' @template differences-passed-shared
#' @template differences-kept
#' @template differences-not-returned
#' @template differences-inert
#'
#' @template example-setup
#' @examplesIf rlang::is_installed(c("recipes", "yardstick"))
#' set.seed(2)
#' res <- nested_tune_bayes(wf, folds, iter = 2, initial = 2)
#' collect_metrics(res)
#'
#' # What the first fold searched: the initial candidates at `.iter` 0,
#' # then one proposal per iteration.
#' res$.inner_metrics[[1]]
#'
#' @templateVar LINKS [tune::tune_bayes()]
#' @template seealso-orchestrator
#' @export
nested_tune_bayes <- function(object, ...) {
  UseMethod("nested_tune_bayes")
}

#' @rdname nested_tune_bayes
#' @export
nested_tune_bayes.default <- function(object, ...) {
  abort_bad_object(object)
}

# The model-spec door, as `nested_tune_grid.model_spec()` describes it.
#' @rdname nested_tune_bayes
#' @export
nested_tune_bayes.model_spec <- function(
  object,
  preprocessor,
  resamples,
  ...,
  iter = 10,
  param_info = NULL,
  metrics = NULL,
  initial = 5,
  objective = tune::exp_improve(),
  event_level = "first",
  eval_time = NULL,
  select = selection_rule()
) {
  check_preprocessor(preprocessor)
  rlang::check_required(resamples)
  with_user_call(nested_tune_bayes(
    workflows::workflow(preprocessor, object),
    resamples,
    ...,
    iter = iter,
    param_info = param_info,
    metrics = metrics,
    initial = initial,
    objective = objective,
    event_level = event_level,
    eval_time = eval_time,
    select = select
  ))
}

#' @rdname nested_tune_bayes
#' @export
nested_tune_bayes.workflow <- function(
  object,
  resamples,
  ...,
  iter = 10,
  param_info = NULL,
  metrics = NULL,
  initial = 5,
  objective = tune::exp_improve(),
  event_level = "first",
  eval_time = NULL,
  select = selection_rule()
) {
  dots <- capture_dots(...)
  check_no_preprocessor(dots, resamples)
  rlang::check_required(resamples)
  control <- check_dots_control(dots)
  check_workflow(object)
  check_untuned_workflow(object)
  check_nested(resamples)
  check_iter(iter)
  check_initial(initial)
  check_objective(objective)
  check_metrics(metrics)
  check_param_info(param_info)
  check_event_level(event_level)
  check_eval_time(eval_time)
  check_selection_rule(select, object, "tune_bayes", metrics)
  control <- check_control(control, "tune_bayes", event_level)

  nested_loop(
    object,
    resamples,
    tuner = tuner_bayes(iter = iter, initial = initial, objective = objective),
    metrics = metrics,
    param_info = param_info,
    event_level = event_level,
    eval_time = eval_time,
    select = select,
    control = control,
    grid = NULL,
    call = rlang::current_env()
  )
}
