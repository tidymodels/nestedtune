#' Nested cross-validation with racing inside
#'
#' @description
#' `nested_tune_race_anova()` and `nested_tune_race_win_loss()` give you an
#' honest score for a model you tune with finetune's two racing tuners,
#' [finetune::tune_race_anova()] and [finetune::tune_race_win_loss()]. Each
#' is [nested_tune_grid()] with the inner tuner swapped, and that page is
#' the reference for everything the racers share with the other
#' orchestrators. For each outer fold the race scores every candidate in
#' `grid` on the first `burn_in` inner resamples. It then drops the
#' candidates that are already clearly worse than the best, by a
#' repeated-measures ANOVA or by a Bradley-Terry model of pairwise wins and
#' losses. The survivors are scored on the remaining resamples, and the
#' fold then selects, finalizes, fits and scores on the outer split as the
#' grid page describes.
#'
#' The estimate describes the race-and-fit procedure as a whole. The model
#' to deploy comes from [nested_final_fit()], which races the same grid once
#' more on all the data, and the estimate is the number to report for that
#' model.
#'
#' @details
#' Both functions need finetune installed. `nested_tune_race_anova()` also
#' needs lme4, which fits the ANOVA, and `nested_tune_race_win_loss()`
#' BradleyTerry2, which fits the win/loss model. A missing package is refused
#' at entry, before any fold runs.
#'
#' `grid` is the design the race is offered. A data frame must have one
#' column per tuned parameter and no other column.
#'
#' @template details-param-info
#' @inheritParams nested_tune_grid
#' @inheritParams finetune::tune_race_anova
#' @templateVar CONSTRUCTOR finetune::control_race()
#' @templateVar PKG finetune
#' @template param-control-dots
#'
#' @return A `nested_results` with one row per outer fold and the columns
#'   [nested_tune_grid()] documents. The `procedure` record names the tuner,
#'   `"tune_race_anova"` or `"tune_race_win_loss"`, and holds the `grid`
#'   beside the arguments every orchestrator records. The section below
#'   says what `.inner_metrics` and the recorded grid mean on a race.
#'
#' @section What a race records:
#'
#' Each fold's `.inner_metrics` holds every candidate its race scored,
#' eliminated candidates included: `tune::collect_metrics(<the race>,
#' all_configs = TRUE)`, where finetune's own default keeps the survivors
#' alone. In that table `n` is the number of inner resamples each candidate
#' was scored on. A candidate that survived to the end has the full inner
#' resample count, and one eliminated along the way has fewer. The recorded
#' `grid`, in the `procedure` record and as `attr(x, "grid")`, is the
#' design the race was offered, exactly as given. What each candidate ran
#' is `n`. A candidate that failed on every inner resample is absent, and
#' its failure is in `.notes`.
#'
#' A race draws from the generator even with a deterministic engine. With
#' `randomize = TRUE`, finetune's default, the inner resamples are shuffled
#' before the burn-in. So which resamples the burn-in uses, and with it
#' which candidates are eliminated when, comes from the fold's tuning seed.
#' On the parallel path every daemon's library must hold finetune. The loop
#' attaches it in each daemon before the first fold is sent, and warns
#' where it cannot.
#'
#' @inheritSection nested_tune_grid Nested designs
#' @inheritSection nested_tune_grid Finalizing a parameter range
#' @inheritSection nested_tune_grid Evaluation times
#'
#' @template section-resample-weights
#'
#' @template section-reproducibility
#'
#' @section Differences from calling finetune directly:
#'
#' There is no `control` formal. A [finetune::control_race()] passed
#' through `...` as `control` reaches the inner race in every fold and the
#' final fit that re-runs the result. `control = control_race(burn_in =
#' 2)`, say, fits a design with three inner resamples. What runs is the
#' control passed, or finetune's default when none is, with the slots this
#' package forces overwritten. The result records that effective control
#' as `extract_procedure(res)$control`. Every slot of `control_race()`
#' falls under one of seven headings.
#'
#' @templateVar INNER inner race
#' @templateVar SETTABLE_TAIL `grid` and `eval_time` are the racing functions' own arguments rather than control slots, offered here as arguments and reaching them unchanged.
#' @template differences-forced
#' @template differences-settable
#' @section Differences from calling finetune directly:
#' **Refused: none.** No slot is refused on its own. Three things are
#' refused at entry. The first is a control of another class, such as a
#' `control_grid()` that finetune itself accepts here. The second is
#' the `event_level` conflict above, and the third a `burn_in` no fold's
#' inner design can meet. finetune refuses
#' a race whose resample count is not greater than `burn_in`. This package
#' refuses the whole call before any fold runs when any outer fold's inner
#' `rset` meets that condition, and the refusal names the count and the
#' burn-in.
#' `control_race()` defaults `burn_in` to 3, so a design with three inner
#' resamples needs `control = control_race(burn_in = 2)` or fewer.
#'
#' **Passed through: `burn_in`, `alpha`, `num_ties`, `randomize`,
#' `verbose_elim`, `verbose`, `pkgs`, `parallel_over`, `workflow_size`.**
#' Each reaches the race as given:
#'
#' - `burn_in`, `alpha`, `num_ties` and `randomize` govern each fold's race
#'   as they do in a direct call. `burn_in` is how many resamples every
#'   candidate is scored on before elimination starts. `alpha` is the
#'   significance level an elimination needs. `num_ties` is how many rounds
#'   two tied survivors are given before one is dropped. `randomize` is
#'   whether the resamples are shuffled first.
#' - `verbose_elim` prints finetune's elimination log from a serial run,
#'   once per fold, and from a mirai daemon where nothing shows it.
#'   `verbose` likewise.
#' @template differences-passed-shared
#' @templateVar VERSION_CTRL control_race()
#' @template differences-finetune-version
#' @template differences-kept
#' @template differences-not-returned
#' @template differences-inert
#'
#' @template example-setup
#' @examplesIf rlang::is_installed(c("finetune", "lme4", "recipes", "yardstick"))
#' # A race needs more inner resamples than its burn-in, so five inner folds.
#' set.seed(1)
#' folds5 <- nested_resamples(mtcars, outside = rsample::vfold_cv(v = 2),
#'                            inside = rsample::vfold_cv(v = 5))
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
