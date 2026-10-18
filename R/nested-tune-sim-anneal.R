#' Nested cross-validation with simulated annealing inside
#'
#' @description
#' `nested_tune_sim_anneal()` estimates how well a model tuned with
#' [finetune::tune_sim_anneal()] performs on new data. It runs the loop of
#' [nested_tune_grid()], with simulated annealing on each outer fold's inner
#' resamples.
#'
#' @details
#' Each outer fold scores `initial` candidates from a space-filling design.
#' For `iter` iterations, it then changes the current candidate a little and
#' keeps the new one or goes back, by finetune's annealing rule.
#' [nested_tune_grid()] documents what the loop functions share, such as the
#' design, what the estimate describes, the seeds, failed folds and parallel
#' execution.
#'
#' finetune must be installed, on each parallel daemon as well.
#'
#' @inheritParams nested_tune_grid
#' @inheritParams finetune::tune_sim_anneal
#' @templateVar CONSTRUCTOR finetune::control_sim_anneal()
#' @templateVar PKG finetune
#' @template param-control-dots
#' @param iter The number of search iterations, a whole number of at least 1.
#'   `0` is an error, because finetune 1.3.0 runs two iterations there and
#'   not none.
#' @param initial The number of candidates each fold scores before the first
#'   iteration, a whole number of at least 1. A `tune_results` object is an
#'   error, because one tuning run cannot serve every outer fold.
#'
#' @return A `nested_results`, as [nested_tune_grid()] describes. Each fold's
#'   `.inner_metrics` has an `.iter` column. It is `0` for the initial
#'   candidates and `i` for the candidate the `i`-th iteration scored. There
#'   is no `grid` attribute.
#'
#' @section Differences from calling finetune directly:
#'
#' A [finetune::control_sim_anneal()] passed through `...` as `control`
#' reaches the inner search in every fold, and [nested_final_fit()] runs
#' again with it. Its settings differ from a direct call as follows.
#'
#' @templateVar INNER inner search
#' @templateVar SETTABLE_TAIL `iter`, `initial` and `eval_time` are arguments of `tune_sim_anneal()`, not control settings.
#' @template differences-forced
#' @template differences-settable
#' @template differences-refused-plain
#' @section Differences from calling finetune directly:
#' **Passed through: `no_improve`, `restart`, `radius`, `flip`,
#' `cooling_coef`, `time_limit`, `verbose`, `verbose_iter`, `pkgs`,
#' `parallel_over`, `workflow_size`.** Each reaches `tune_sim_anneal()` as
#' given:
#'
#' - `no_improve` and `restart` set when a search stops or starts again.
#'   `radius`, `flip` and `cooling_coef` set how it moves. All five act on
#'   each fold's search as in a direct call.
#' - `time_limit` is a wall-clock stop, and a wall-clock stop makes the
#'   candidate set depend on the machine. Two runs with the same seed can
#'   stop at different iterations.
#' - `verbose_iter`, `TRUE` by default, prints the annealing log from every
#'   fold of a serial run. Pass
#'   `control = control_sim_anneal(verbose_iter = FALSE)` for a quiet run.
#'   `verbose` prints from each fold as well.
#' @template differences-passed-shared
#' @templateVar VERSION_CTRL control_sim_anneal()
#' @template differences-finetune-version
#' @template differences-kept
#' @section Differences from calling finetune directly:
#' **Not returned: `save_workflow`, `save_history`.** The nested run does not
#' keep the inner tuning results, so `save_workflow` returns nothing there.
#' [nested_final_fit()] keeps its own tuning run as `$tuning`. `save_history`
#' writes finetune's search history to a file in the temporary directory of
#' the process that tuned, and each fold overwrites the one before.
#'
#' @template differences-inert
#'
#' @template example-setup
#' @examplesIf rlang::is_installed(c("finetune", "recipes", "yardstick"))
#' set.seed(2)
#' res <- nested_tune_sim_anneal(
#'   wf,
#'   folds,
#'   iter = 3,
#'   initial = 2,
#'   control = finetune::control_sim_anneal(verbose_iter = FALSE)
#' )
#' collect_metrics(res)
#'
#' # What the first fold searched: the initial candidates at `.iter` 0,
#' # then one perturbation per iteration.
#' res$.inner_metrics[[1]]
#'
#' @templateVar LINKS [nested_tune_bayes()], [finetune::tune_sim_anneal()]
#' @template seealso-orchestrator
#' @export
nested_tune_sim_anneal <- function(object, ...) {
  UseMethod("nested_tune_sim_anneal")
}

#' @rdname nested_tune_sim_anneal
#' @export
nested_tune_sim_anneal.default <- function(object, ...) {
  abort_bad_object(object)
}

# The model-spec door, as `nested_tune_grid.model_spec()` describes it.
#' @rdname nested_tune_sim_anneal
#' @export
nested_tune_sim_anneal.model_spec <- function(
  object,
  preprocessor,
  resamples,
  ...,
  iter = 10,
  param_info = NULL,
  metrics = NULL,
  event_level = "first",
  eval_time = NULL,
  initial = 1,
  select = selection_rule()
) {
  # finetune first, as the workflow method does.
  check_tuner_installed("tune_sim_anneal")
  check_preprocessor(preprocessor)
  rlang::check_required(resamples)
  with_user_call(nested_tune_sim_anneal(
    workflows::workflow(preprocessor, object),
    resamples,
    ...,
    iter = iter,
    param_info = param_info,
    metrics = metrics,
    initial = initial,
    event_level = event_level,
    eval_time = eval_time,
    select = select
  ))
}

#' @rdname nested_tune_sim_anneal
#' @export
nested_tune_sim_anneal.workflow <- function(
  object,
  resamples,
  ...,
  iter = 10,
  param_info = NULL,
  metrics = NULL,
  event_level = "first",
  eval_time = NULL,
  initial = 1,
  select = selection_rule()
) {
  # finetune first, before anything is judged that could not run anyway
  # (D-044, GP3) -- ahead of the dots, so a `control = finetune::...()` in
  # the call is refused for the missing package rather than erroring while
  # the dots are forced, where the racers force theirs first; then the
  # Bayesian sibling's checks in its order, with the two floors that are
  # this sibling's own (D-046).
  check_tuner_installed("tune_sim_anneal")
  dots <- capture_dots(...)
  check_no_preprocessor(dots, resamples)
  rlang::check_required(resamples)
  control <- check_dots_control(dots)
  check_workflow(object)
  check_untuned_workflow(object)
  check_nested(resamples)
  check_iter(iter, floor = 1)
  check_initial(initial, floor = 1)
  check_metrics(metrics)
  check_param_info(param_info)
  check_event_level(event_level)
  check_eval_time(eval_time)
  check_selection_rule(select, object, "tune_sim_anneal", metrics)
  control <- check_control(control, "tune_sim_anneal", event_level)

  nested_loop(
    object,
    resamples,
    tuner = tuner_anneal(iter = iter, initial = initial),
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
