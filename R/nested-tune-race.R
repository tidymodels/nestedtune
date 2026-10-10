#' Nested cross-validation with racing inside
#'
#' @description
#' `nested_tune_race_anova()` and `nested_tune_race_win_loss()` estimate how
#' well a model tuned with finetune's racing functions performs on new data.
#' They run the loop of [nested_tune_grid()], with a race on each outer
#' fold's inner resamples.
#'
#' @details
#' Each outer fold scores every candidate in `grid` on the first `burn_in`
#' inner resamples. It then drops the candidates that are clearly worse than
#' the best, by a repeated-measures ANOVA or by a model of pairwise wins and
#' losses. The rest are scored on the remaining resamples. [nested_tune_grid()]
#' documents what the loop functions share, such as the design, what the
#' estimate describes, the seeds, failed folds and parallel execution.
#'
#' Both functions need finetune, on each parallel daemon as well.
#' `nested_tune_race_anova()` also needs lme4, and
#' `nested_tune_race_win_loss()` needs BradleyTerry2.
#'
#' Each fold's `.inner_metrics` holds every candidate its race scored,
#' including the ones it dropped. In that table, `n` is the number of inner
#' resamples each candidate was scored on, so a dropped candidate has a
#' smaller `n`. A candidate that failed on every inner resample is missing,
#' and its failure is in `.notes`. The recorded grid, `attr(res, "grid")`,
#' is the design the race was offered, exactly as given.
#'
#' An inner design with an apparent split, such as the one
#' `bootstraps(apparent = TRUE)` makes, is an error here, though finetune
#' runs it. A race drops candidates on the score of each split, and an
#' apparent split is scored on the rows the model trained on. The other
#' tuners accept the split, because tune leaves it out of its estimates.
#' [nested_workflow_map()] checks for it before its first workflow runs.
#'
#' @inheritParams nested_tune_grid
#' @inheritParams finetune::tune_race_anova
#' @templateVar CONSTRUCTOR finetune::control_race()
#' @templateVar PKG finetune
#' @template param-control-dots
#'
#' @return A `nested_results`, as [nested_tune_grid()] describes.
#'
#' @section Differences from calling finetune directly:
#'
#' A [finetune::control_race()] passed through `...` as `control` reaches the
#' inner race in every fold, and [nested_final_fit()] runs again with it.
#' Its settings differ from a direct call as follows.
#'
#' @templateVar INNER inner race
#' @templateVar SETTABLE_TAIL `grid` and `eval_time` are the racing functions' own arguments, not control settings.
#' @template differences-forced
#' @template differences-settable
#' @section Differences from calling finetune directly:
#' **Refused: none.** No setting is refused on its own. A control of another
#' class is an error, even a `control_grid()` that finetune accepts.
#'
#' **Passed through: `burn_in`, `alpha`, `num_ties`, `randomize`,
#' `verbose_elim`, `verbose`, `pkgs`, `parallel_over`, `workflow_size`.**
#' Each reaches the race as given:
#'
#' - `burn_in`, `alpha`, `num_ties` and `randomize` act on each fold's race
#'   as in a direct call. With `randomize = TRUE`, the default, the fold's
#'   tuning seed sets which resamples the burn-in uses.
#' - A `burn_in` that is not smaller than some fold's number of inner
#'   resamples is an error before any fold runs. The default `burn_in` is 3,
#'   so a design with three inner resamples needs a `burn_in` of 2 or fewer.
#' - `verbose` and `verbose_elim` print from each fold, and only a serial
#'   run shows the output.
#' @template differences-passed-shared
#' @templateVar VERSION_CTRL control_race()
#' @template differences-finetune-version
#' @template differences-kept
#' @template differences-not-returned
#' @template differences-inert
#'
#' @examplesIf rlang::is_installed(c("finetune", "lme4", "recipes", "yardstick"))
#' data(mtcars)
#'
#' rec <- recipes::recipe(mpg ~ ., data = mtcars) |>
#'   recipes::step_pca(recipes::all_predictors(), num_comp = tune::tune())
#' wf <- workflows::workflow(rec, parsnip::linear_reg())
#'
#' # A race needs more inner resamples than its burn-in, so five inner folds.
#' set.seed(1)
#' folds5 <- nested_resamples(
#'   mtcars,
#'   outside = rsample::vfold_cv(v = 2),
#'   inside = rsample::vfold_cv(v = 5)
#' )
#'
#' set.seed(2)
#' res <- nested_tune_race_anova(
#'   wf,
#'   folds5,
#'   grid = data.frame(num_comp = 1:4),
#'   control = finetune::control_race(burn_in = 2, verbose_elim = FALSE)
#' )
#' collect_metrics(res)
#'
#' # Every candidate the first fold's race scored, and on how many inner
#' # resamples: `n` below 5 is a candidate the race eliminated.
#' res$.inner_metrics[[1]]
#'
#' @templateVar LINKS [nested_tune_bayes()], [finetune::tune_race_anova()], [finetune::tune_race_win_loss()]
#' @template seealso-orchestrator
#' @name nested_tune_race
NULL

#' @rdname nested_tune_race
#' @export
nested_tune_race_anova <- function(object, ...) {
  UseMethod("nested_tune_race_anova")
}

#' @rdname nested_tune_race
#' @export
nested_tune_race_anova.default <- function(object, ...) {
  abort_bad_object(object)
}

# The model-spec door, as `nested_tune_grid.model_spec()` describes it, for
# both racers.
#' @rdname nested_tune_race
#' @export
nested_tune_race_anova.model_spec <- function(
  object,
  preprocessor,
  resamples,
  ...,
  param_info = NULL,
  grid = 10,
  metrics = NULL,
  event_level = "first",
  eval_time = NULL,
  select = selection_rule()
) {
  # finetune first, as the workflow method does.
  check_tuner_installed("tune_race_anova")
  check_preprocessor(preprocessor)
  rlang::check_required(resamples)
  with_user_call(nested_tune_race_anova(
    workflows::workflow(preprocessor, object),
    resamples,
    ...,
    param_info = param_info,
    grid = grid,
    metrics = metrics,
    event_level = event_level,
    eval_time = eval_time,
    select = select
  ))
}

#' @rdname nested_tune_race
#' @export
nested_tune_race_anova.workflow <- function(
  object,
  resamples,
  ...,
  param_info = NULL,
  grid = 10,
  metrics = NULL,
  event_level = "first",
  eval_time = NULL,
  select = selection_rule()
) {
  nested_tune_race(
    "tune_race_anova",
    object,
    resamples,
    dots = capture_dots(...),
    param_info = param_info,
    grid = grid,
    metrics = metrics,
    event_level = event_level,
    eval_time = eval_time,
    select = select,
    call = rlang::current_env()
  )
}

#' @rdname nested_tune_race
#' @export
nested_tune_race_win_loss <- function(object, ...) {
  UseMethod("nested_tune_race_win_loss")
}

#' @rdname nested_tune_race
#' @export
nested_tune_race_win_loss.default <- function(object, ...) {
  abort_bad_object(object)
}

#' @rdname nested_tune_race
#' @export
nested_tune_race_win_loss.model_spec <- function(
  object,
  preprocessor,
  resamples,
  ...,
  param_info = NULL,
  grid = 10,
  metrics = NULL,
  event_level = "first",
  eval_time = NULL,
  select = selection_rule()
) {
  check_tuner_installed("tune_race_win_loss")
  check_preprocessor(preprocessor)
  rlang::check_required(resamples)
  with_user_call(nested_tune_race_win_loss(
    workflows::workflow(preprocessor, object),
    resamples,
    ...,
    param_info = param_info,
    grid = grid,
    metrics = metrics,
    event_level = event_level,
    eval_time = eval_time,
    select = select
  ))
}

#' @rdname nested_tune_race
#' @export
nested_tune_race_win_loss.workflow <- function(
  object,
  resamples,
  ...,
  param_info = NULL,
  grid = 10,
  metrics = NULL,
  event_level = "first",
  eval_time = NULL,
  select = selection_rule()
) {
  nested_tune_race(
    "tune_race_win_loss",
    object,
    resamples,
    dots = capture_dots(...),
    param_info = param_info,
    grid = grid,
    metrics = metrics,
    event_level = event_level,
    eval_time = eval_time,
    select = select,
    call = rlang::current_env()
  )
}

# The one body behind the two racing exports (M50). The exports differ in
# nothing but the registry key, so the checks and the loop are written once;
# `call` is the export's frame, so every refusal and the run's warnings name
# the function the user called. The checks run in the grid orchestrator's
# order, with the two that are racing's own -- the packages the race needs,
# and the burn-in against every fold's inner design -- at the two ends: the
# packages first, before anything is judged that could not run anyway, and
# the burn-in last, once the control is effective and the design is known to
# be a design (GP3).
nested_tune_race <- function(
  fn,
  object,
  resamples,
  dots,
  param_info,
  grid,
  metrics,
  event_level,
  eval_time,
  select,
  call
) {
  check_tuner_installed(fn, call = call)
  check_no_preprocessor(dots, resamples, call = call)
  rlang::check_required(resamples, call = call)
  control <- check_dots_control(dots, call = call)
  check_workflow(object, call = call)
  check_untuned_workflow(object, call = call)
  check_nested(resamples, call = call)
  check_race_apparent(resamples, call = call)
  check_grid(grid, call = call)
  check_grid_params(object, grid, call = call)
  check_metrics(metrics, call = call)
  check_param_info(param_info, call = call)
  check_event_level(event_level, call = call)
  check_eval_time(eval_time, call = call)
  check_selection_rule(select, object, fn, metrics, call = call)
  control <- check_control(control, fn, event_level, call = call)
  check_race_burn_in(resamples, control, call = call)

  nested_loop(
    object,
    resamples,
    tuner = tuner_race(fn, grid),
    metrics = metrics,
    param_info = param_info,
    event_level = event_level,
    eval_time = eval_time,
    select = select,
    control = control,
    grid = grid,
    call = call
  )
}
