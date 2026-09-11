#' Nested cross-validation with simulated annealing inside
#'
#' @description
#' `nested_tune_sim_anneal()` gives you an honest score for a model you
#' tune with [finetune::tune_sim_anneal()]. It is [nested_tune_grid()] with
#' the inner tuner swapped, and that page is the reference for everything
#' the orchestrators share; [nested_tune_bayes()] is this function's
#' nearest sibling. For each outer fold it scores `initial` candidates on
#' that fold's inner resamples. Then for `iter` iterations it perturbs the
#' current candidate, scores the perturbation, and keeps it or falls back
#' by finetune's annealing rule. The fold then selects, finalizes, fits and
#' scores on the outer split as the grid page describes.
#'
#' The estimate describes the annealing-and-fit procedure as a whole and is
#' reported for it. The model to deploy comes from [nested_final_fit()],
#' which runs the recorded search once more on all the data.
#'
#' @details
#' finetune must be installed; a missing package is refused at entry, before
#' any fold runs.
#'
#' @inheritParams nested_tune_grid
#' @inheritParams finetune::tune_sim_anneal
#' @param ... A control object from [finetune::control_sim_anneal()] as
#'   `control` and nothing else, matched by name. The section on differences
#'   from finetune says what becomes of each slot.
#' @param iter The number of search iterations, a whole number of at least 1;
#'   the section on the iterations says why `0` is refused.
#' @param initial The number of candidates each fold scores before the first
#'   iteration, a whole number of at least 1 (finetune's default); a
#'   `tune_results` object, which finetune also accepts here, is refused.
#'
#' @return A `nested_results` shaped as [nested_tune_grid()] documents, one
#'   row per outer fold. Each fold's `.inner_metrics` carries an `.iter`
#'   column after `.config`. It is `0` for the initial candidates, whose
#'   `.config` finetune prefixes `initial_`. It is `i` for the candidate the
#'   `i`-th iteration scored, labelled `Iter<i>`. There is no `grid`
#'   attribute. The `procedure` record names the tuner `"tune_sim_anneal"`
#'   and holds `iter` and `initial` beside the arguments every orchestrator
#'   records.
#'
#' @section The initial candidates and the iterations:
#'
#' Each fold draws its own space-filling set of `initial` candidates with
#' [dials::grid_space_filling()] and scores it with [tune::tune_grid()]
#' under its tuning seed, as [nested_tune_bayes()] does. A `tune_results`
#' object is refused as `initial` for the reason that page gives. Each
#' iteration then perturbs the current candidate and scores the result on
#' the fold's inner resamples.
#'
#' `iter = 0` is refused. finetune 1.3.0 iterates over
#' `(existing_iter + 1):iter`, which at `iter = 0` is `1:0`, so it runs two
#' iterations rather than none. [tune::tune_bayes()] at `iter = 0` proposes
#' nothing. finetune stops a fold's search early after
#' `no_improve` consecutive iterations without improvement, or when
#' `time_limit` is reached. `no_improve` is `Inf` by default, so never,
#' unless the control sets it. The fold completes with the candidates
#' scored so far, and nothing about the early stop reaches `.notes`.
#'
#' Annealing draws from the generator even with a deterministic engine.
#' The initial candidates are a space-filling design drawn under the fold's
#' tuning seed, and each perturbation is drawn from the stream that seed
#' started. [finetune::control_sim_anneal()] has no seed slot, so nothing
#' is injected into the control. On the parallel path every daemon's
#' library must hold finetune, which the loop attaches in each daemon
#' before the first fold is sent, warning where it cannot.
#'
#' @inheritSection nested_tune_grid Nested designs
#' @inheritSection nested_tune_grid Finalizing a parameter range
#' @inheritSection nested_tune_grid Evaluation times
#'
#' @template section-reproducibility
#'
#' @section Differences from calling finetune directly:
#'
#' There is no `control` formal. A [finetune::control_sim_anneal()] passed
#' through `...` as `control` reaches the inner search in every fold and
#' the final fit that re-runs the result. `control = control_sim_anneal(
#' no_improve = 5, verbose_iter = FALSE)`, say, stops a fold's search
#' sooner and keeps the console quiet. What runs is the control passed, or
#' finetune's default when none is, with the slots this package forces
#' overwritten. The result records that effective control as
#' `extract_procedure(res)$control`. Every slot of `control_sim_anneal()`
#' falls under one of seven headings.
#'
#' **Forced: `allow_par`.** The inner search and the outer scoring fit both
#' run at `allow_par = FALSE`, whatever the control carries; parallelism
#' belongs over the outer folds.
#'
#' **Settable as its own argument: `event_level`.** Set through the
#' argument alone, as on the grid page. A control at finetune's default
#' takes the argument's level, and one naming a different level is refused
#' at entry. `iter`, `initial` and `eval_time` are arguments of
#' `tune_sim_anneal()` rather than control slots, offered here as arguments
#' and reaching it unchanged.
#'
#' **Refused: none.** No slot is refused on its own. What is refused at
#' entry is a control of another class, such as a `control_bayes()` that
#' finetune itself would run under, and the `event_level` conflict above.
#'
#' **Passed through: `no_improve`, `restart`, `radius`, `flip`,
#' `cooling_coef`, `time_limit`, `verbose`, `verbose_iter`, `pkgs`,
#' `parallel_over`, `workflow_size`.** Each reaches `tune_sim_anneal()` as
#' given:
#'
#' - `no_improve` and `restart` set when a search stops or restarts from
#'   its best candidate. `radius` and `flip` set how far and how a
#'   perturbation moves, and `cooling_coef` how the acceptance probability
#'   cools. All five govern each fold's search as they would a direct call.
#' - `time_limit` is a wall-clock stop, and a wall-clock stop makes the
#'   candidate set depend on the machine. Two runs under the same seed can
#'   stop at different iterations, which is outside what the seeds can
#'   promise.
#' - `verbose_iter`, `TRUE` in finetune's default, prints the annealing log
#'   from every fold of a serial run, one log per fold, and from a mirai
#'   daemon where nothing shows it. Pass
#'   `control = control_sim_anneal(verbose_iter = FALSE)` for a quiet run.
#'   `verbose` likewise.
#' - `pkgs`, `parallel_over` and `workflow_size` behave as on the grid
#'   page, `parallel_over` included.
#'
#' The classification above was read on finetune 1.3.0. The version that
#' added `workflow_size` to `control_sim_anneal()` is not named in finetune's
#' NEWS, and the `>= 1.0.1` floor this package declares does not require
#' it.
#'
#' **Kept from the outer fit: `save_pred`, `extract`.** Both reach the
#' outer fit, whose predictions and extracts come back as `.predictions`
#' and `.extracts`; the grid page has the shape. The inner search's are
#' still discarded.
#'
#' **Not returned: `save_workflow`, `save_history`.** `save_workflow` lands
#' on the inner `tune_results` a fold record discards, so setting it costs
#' the work and returns nothing. The final fit keeps its tuning run as
#' `$tuning`, where what it saved is reachable. `save_history` writes
#' finetune's search history to `sa_history.RData` in the temporary
#' directory of the process that tuned, a daemon's own on the parallel
#' path. Every fold overwrites the last one's, and nothing of it reaches
#' the result.
#'
#' **Inert: `backend_options`.** A parallel backend's options, and there is
#' no backend to reach at `allow_par = FALSE`.
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
#' @seealso [nested_tune_grid()], [nested_tune_bayes()], [nested_resamples()],
#'   [nested_final_fit()], [finetune::tune_sim_anneal()]
#' @export
nested_tune_sim_anneal <- function(
  object,
  resamples,
  ...,
  iter = 10,
  param_info = NULL,
  metrics = NULL,
  initial = 1,
  event_level = "first",
  eval_time = NULL,
  select = selection_rule()
) {
  # finetune first, before anything is judged that could not run anyway
  # (D-044, GP3) -- ahead of the dots, so a `control = finetune::...()` in
  # the call is refused for the missing package rather than erroring while
  # the dots are forced, where the racers force theirs first; then the
  # Bayesian sibling's checks in its order, with the two floors that are
  # this sibling's own (D-046).
  check_tuner_installed("tune_sim_anneal")
  control <- check_dots_control(capture_dots(...))
  check_workflow(object)
  check_untuned_workflow(object)
  check_nested(resamples)
  check_iter(iter, floor = 1)
  check_initial(initial, floor = 1)
  check_metrics(metrics)
  check_param_info(param_info)
  check_event_level(event_level)
  check_eval_time(eval_time)
  check_selection_rule(select, object)
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
