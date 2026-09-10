#' Nested cross-validation with Bayesian optimization inside
#'
#' @description
#' `nested_tune_bayes()` runs the outer loop of nested cross-validation with
#' [tune::tune_bayes()] as the inner tuner. For each outer fold it scores
#' `initial` candidates on that fold's inner resamples, lets a Gaussian
#' process propose `iter` more one at a time, selects by `select`, finalizes
#' the workflow, and fits and scores it on the outer split. It is
#' [nested_tune_grid()] with the inner tuner swapped, and that page is the
#' reference for everything the two share: the design, the seeds, failed
#' folds, parallel execution and what an operation on the result may do.
#'
#' The estimate describes the whole search-and-fit procedure rather than any
#' one model, and is reported for the procedure; the model to deploy comes
#' from [nested_final_fit()], which runs the recorded search once more on all
#' the data.
#'
#' @inheritParams nested_tune_grid
#' @inheritParams tune::tune_bayes
#' @param ... A control object from [tune::control_bayes()], as `control`,
#'   and nothing else; every argument after `...` is matched by name. The
#'   section on differences from tune says what becomes of each slot.
#' @param param_info A [dials::parameters()] object, or `NULL` to let tune
#'   derive one from the workflow; a range that is unknown until the data is
#'   seen must be finalized first with [dials::finalize()], since
#'   [tune::tune_bayes()] refuses it.
#' @param initial The number of candidates each fold scores before the first
#'   iteration, a whole number of at least 2; a `tune_results` object, which
#'   tune also accepts here, is refused.
#' @param objective An acquisition function from tune, deciding which
#'   candidate the Gaussian process proposes next: [tune::exp_improve()] (the
#'   default), [tune::prob_improve()] or [tune::conf_bound()].
#'
#' @return A `nested_results` with one row per outer fold and the columns
#'   [nested_tune_grid()] documents. Each fold's `.inner_metrics` carries an
#'   `.iter` column after `.config`, `0` for the initial candidates and `i`
#'   for the candidate the `i`-th iteration proposed, so a fold's search
#'   trajectory can be read from it. There is no `grid` attribute; the
#'   `procedure` record names the tuner `"tune_bayes"` and holds `iter`,
#'   `initial` and `objective` beside the arguments every orchestrator
#'   records.
#'
#' @section The initial candidates and the iterations:
#'
#' Each fold generates its own space-filling set of `initial` candidates from
#' the parameter ranges with [dials::grid_space_filling()] and scores it with
#' [tune::tune_grid()], under the fold's own tuning seed. A `tune_results`
#' object is refused as `initial` because one tuning run cannot serve every
#' outer fold: its candidates were scored on resamples that may hold a fold's
#' assessment rows.
#'
#' Each iteration proposes one candidate and scores it on the fold's inner
#' resamples. `iter = 0` scores the initial candidates and proposes nothing,
#' which makes the run [nested_tune_grid()] on the space-filling grid those
#' candidates form. tune stops a fold's search early when no unscored
#' candidate remains, saying so on the console, and after ten consecutive
#' iterations without improvement (its `no_improve` default, settable through
#' the control). The fold then completes with the candidates scored so far,
#' and nothing about the early stop reaches `.notes`.
#'
#' Where [nested_tune_grid()] and the finetune tuners finalize a parameter
#' range that depends on the data on the outer fold's analysis rows,
#' [tune::tune_bayes()] refuses such a range before any frame is read, and
#' every outer fold records that refusal as its failure. Finalize the range
#' on the data first.
#'
#' @inheritSection nested_tune_grid Nested designs
#' @inheritSection nested_tune_grid Finalizing a parameter range
#'
#' @template section-reproducibility
#'
#' @section Differences from calling tune directly:
#'
#' There is no `control` formal, but a [tune::control_bayes()] passed through
#' `...` as `control` reaches the inner `tune_bayes()` in every fold and the
#' final fit that re-runs the result: `control = control_bayes(no_improve =
#' 5, uncertain = 3)`, say, to stop a fold's search sooner. What runs is the
#' control passed, or tune's default when none is, with the slots this
#' package forces overwritten; the result records that effective control,
#' `seed` left out, as `extract_procedure(res)$control`. Every slot of
#' `control_bayes()` falls under one of seven headings.
#'
#' **Forced: `allow_par`, `seed`.** `allow_par = FALSE` on both tune calls a
#' fold makes, because parallelism belongs over the outer folds. `seed` is
#' the slot that drives the Gaussian process's proposals, and tune draws it
#' from the stream when it is not given, so left alone a fold's proposals
#' would depend on how much of the stream tune had consumed before reaching
#' it. Here the control is given the fold's own tuning seed, the number
#' `.tuning_seed` reports, whatever the control carried.
#'
#' **Settable as its own argument: `event_level`.** The argument is the one
#' place the level is set, as on the grid page: a control at tune's default
#' takes it, and a control naming another level is refused at entry, naming
#' both. `iter`, `initial`, `objective` and `eval_time` are arguments of
#' `tune_bayes()` rather than control slots, offered here as arguments and
#' reaching it unchanged.
#'
#' **Refused: none.** No slot is refused on its own; what is refused at entry
#' is a control of another class (a `control_grid()`, which tune itself would
#' accept here) and the `event_level` conflict above.
#'
#' **Passed through: `no_improve`, `uncertain`, `time_limit`, `verbose`,
#' `verbose_iter`, `save_gp_scoring`, `pkgs`, `parallel_over`,
#' `workflow_size`.** Each reaches `tune_bayes()` as given. `no_improve` and
#' `uncertain` govern each fold's search as they would a direct call, so a
#' fold may stop short of `iter`, and its `.inner_metrics` records how far it
#' went. `time_limit` stops a search by the clock, so two runs under the same
#' seed can stop at different iterations on different machines, which is
#' outside what the seeds can promise. `verbose` and `verbose_iter` print from
#' a serial run, and from a mirai daemon where nothing shows it.
#' `save_gp_scoring` writes its files to the temporary directory of the
#' process that tuned, a daemon's own on the parallel path. `pkgs`,
#' `parallel_over` and `workflow_size` behave as the grid page describes,
#' `parallel_over` included: it changes the numbers a stochastic engine
#' produces even at `allow_par = FALSE`.
#'
#' **Kept from the outer fit: `save_pred`, `extract`.** The outer fit's
#' predictions and extracts are kept as `.predictions` and `.extracts`, as
#' the grid page describes, and the inner search's are still discarded.
#'
#' **Not returned: `save_workflow`.** It lands on the inner `tune_results` a
#' fold record discards, so setting it costs the work and returns nothing;
#' the final fit keeps its own tuning run as `$tuning`, where what it saved
#' is reachable.
#'
#' **Inert: `backend_options`.** Options for a backend the forced
#' `allow_par = FALSE` never reaches.
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
#' @seealso [nested_tune_grid()], [nested_resamples()], [nested_final_fit()],
#'   [tune::tune_bayes()]
#' @export
nested_tune_bayes <- function(
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
  control <- check_dots_control(capture_dots(...))
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
  check_selection_rule(select, object)
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
