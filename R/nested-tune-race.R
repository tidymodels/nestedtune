#' Nested cross-validation with racing inside
#'
#' @description
#' `nested_tune_race_anova()` and `nested_tune_race_win_loss()` run the outer
#' loop of nested cross-validation with finetune's two racing tuners,
#' [finetune::tune_race_anova()] and [finetune::tune_race_win_loss()], as the
#' inner tuner. For each outer fold the race scores every candidate in `grid`
#' on the first `burn_in` inner resamples, drops the candidates that are
#' already clearly worse than the best (by a repeated-measures ANOVA, or by a
#' Bradley-Terry model of pairwise wins and losses), scores the survivors on
#' the remaining resamples, and then selects, finalizes, fits and scores on
#' the outer split as [nested_tune_grid()] does. That page is the reference
#' for everything the racers share with the other orchestrators.
#'
#' The estimate describes the race-and-fit procedure as a whole and is
#' reported for it; the model to deploy comes from [nested_final_fit()],
#' which races the same grid once more on all the data.
#'
#' @details
#' Both functions need finetune installed; `nested_tune_race_anova()` also
#' needs lme4, which fits the ANOVA, and `nested_tune_race_win_loss()`
#' BradleyTerry2, which fits the win/loss model. A missing package is refused
#' at entry, before any fold runs.
#'
#' @inheritParams nested_tune_grid
#' @param ... A control object from [finetune::control_race()], as
#'   `control`, and nothing else; every argument after `...` is matched by
#'   name. The section on differences from finetune says what becomes of each
#'   slot.
#' @param grid A data frame of candidate parameter values, or a positive whole
#'   number giving the size of a grid to generate, the design the race is
#'   offered; a data frame must have one column per tuned parameter and no
#'   other column.
#'
#' @return A `nested_results` with one row per outer fold and the columns
#'   [nested_tune_grid()] documents. The `procedure` record names the tuner
#'   (`"tune_race_anova"` or `"tune_race_win_loss"`) and holds the `grid`
#'   beside the arguments every orchestrator records; the section below says
#'   what `.inner_metrics` and the recorded grid mean on a race.
#'
#' @section What a race records:
#'
#' Each fold's `.inner_metrics` holds every candidate its race scored,
#' eliminated candidates included: `tune::collect_metrics(<the race>,
#' all_configs = TRUE)`, where finetune's own default keeps the survivors
#' alone. In that table `n` is the number of inner resamples each candidate
#' was scored on, the full inner resample count for a candidate that survived
#' to the end and fewer for one eliminated along the way. The recorded
#' `grid`, in the `procedure` record and as `attr(x, "grid")`, is the design
#' the race was offered, exactly as given; what each candidate ran is `n`. A
#' candidate that failed on every inner resample is absent, and its failure
#' is in `.notes`.
#'
#' A race draws from the generator even with a deterministic engine: with
#' `randomize = TRUE` (finetune's default) the inner resamples are shuffled
#' before the burn-in, so which resamples the burn-in uses, and with it which
#' candidates are eliminated when, comes from the fold's tuning seed. On the
#' parallel path every daemon's library must hold finetune, which the loop
#' attaches in each daemon before the first fold is sent, warning where it
#' cannot.
#'
#' @inheritSection nested_tune_grid Nested designs
#' @inheritSection nested_tune_grid Finalizing a parameter range
#' @inheritSection nested_tune_grid Evaluation times
#'
#' @template section-reproducibility
#'
#' @section Differences from calling finetune directly:
#'
#' There is no `control` formal, but a [finetune::control_race()] passed
#' through `...` as `control` reaches the inner race in every fold and the
#' final fit that re-runs the result: `control = control_race(burn_in = 2)`,
#' say, on a design with three inner resamples. What runs is the control
#' passed, or finetune's default when none is, with the slots this package
#' forces overwritten; the result records that effective control as
#' `extract_procedure(res)$control`. Every slot of `control_race()` falls
#' under one of seven headings.
#'
#' **Forced: `allow_par`.** The inner race and the outer scoring fit both run
#' at `allow_par = FALSE`, whatever the control carries, because parallelism
#' belongs over the outer folds.
#'
#' **Settable as its own argument: `event_level`.** The argument is the one
#' place the level is set, as on the grid page: a control at finetune's
#' default takes it, and a control naming another level is refused at entry,
#' naming both. `grid` and `eval_time` are the racing functions' own
#' arguments rather than control slots, offered here as arguments and
#' reaching them unchanged.
#'
#' **Refused: none.** No slot is refused on its own. What is refused at entry
#' is a control of another class (a `control_grid()`, which finetune itself
#' would accept here), the `event_level` conflict above, and a `burn_in` no
#' fold's inner design can meet: finetune refuses a race whose resample count
#' is not greater than `burn_in`, and this package refuses the whole call
#' before any fold runs when any outer fold's inner `rset` would be, naming
#' the count and the burn-in. `control_race()` defaults `burn_in` to 3, so a
#' design with three inner resamples needs `control = control_race(burn_in =
#' 2)` or fewer.
#'
#' **Passed through: `burn_in`, `alpha`, `num_ties`, `randomize`,
#' `verbose_elim`, `verbose`, `pkgs`, `parallel_over`, `workflow_size`.**
#' Each reaches the race as given. `burn_in`, `alpha`, `num_ties` and
#' `randomize` govern each fold's race as they would a direct call: how many
#' resamples every candidate is scored on before elimination starts, the
#' significance level an elimination needs, how many rounds two tied
#' survivors are given before one is dropped, and whether the resamples are
#' shuffled first. `verbose_elim` prints finetune's elimination log from a
#' serial run, once per fold, and from a mirai daemon where nothing shows it;
#' `verbose` likewise. `pkgs`, `parallel_over` and `workflow_size` behave as
#' the grid page describes, `parallel_over` included. This classification was
#' read on finetune 1.3.0; the version that added `workflow_size` to
#' `control_race()` is not named in finetune's NEWS, and the `>= 1.0.1` floor
#' this package declares does not require it.
#'
#' **Kept from the outer fit: `save_pred`, `extract`.** Each reaches the
#' outer fit as well as the race, and the outer fit's predictions and
#' extracts are kept as `.predictions` and `.extracts` in the shape the grid
#' page describes; the race's own are still discarded.
#'
#' **Not returned: `save_workflow`.** It lands on the inner race result a fold
#' record discards, so setting it costs the work and returns nothing; the
#' final fit keeps its race as `$tuning`, where what it saved is reachable.
#'
#' **Inert: `backend_options`.** Backend options with no parallel backend to
#' reach, since `allow_par` is forced off.
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
#' @seealso [nested_tune_grid()], [nested_tune_bayes()], [nested_resamples()],
#'   [nested_final_fit()], [finetune::tune_race_anova()],
#'   [finetune::tune_race_win_loss()]
#' @name nested_tune_race
NULL

#' @rdname nested_tune_race
#' @export
nested_tune_race_anova <- function(
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
nested_tune_race_win_loss <- function(
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
  check_selection_rule(select, object, call = call)
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
