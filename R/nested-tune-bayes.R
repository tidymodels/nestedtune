#' Nested cross-validation with Bayesian optimization inside
#'
#' @description
#' `nested_tune_bayes()` gives you an honest score for a model you tune
#' with [tune::tune_bayes()]. It is [nested_tune_grid()] with the inner
#' tuner swapped. For each outer fold it scores `initial` candidates on
#' that fold's inner resamples and lets a Gaussian process propose `iter`
#' more, one at a time. It then selects by `select`, finalizes the
#' workflow, and fits and scores it on the outer split. The grid page is
#' the reference for everything the two share: the design, the seeds,
#' failed folds, parallel execution and what an operation on the result
#' does.
#'
#' The estimate describes the whole search-and-fit procedure rather than
#' any one model. The model to deploy comes from [nested_final_fit()],
#' which runs the recorded search once more on all the data, and the
#' estimate is the number to report for that model.
#'
#' @details
#' `iter` reaches [tune::tune_bayes()] as given, and tune stops early when
#' the search stalls. The number of search iterations, a non-negative whole
#' number. The section on the iterations says what `0` does.
#'
#' @template details-param-info
#' @inheritParams nested_tune_grid
#' @inheritParams tune::tune_bayes
#' @templateVar CONSTRUCTOR tune::control_bayes()
#' @templateVar PKG tune
#' @template param-control-dots
#' @param initial The number of candidates each fold scores before the first
#'   iteration, a whole number of at least 2. A `tune_results` object, which
#'   tune also accepts here, is refused.
#' @param objective An acquisition function from tune. It decides which
#'   candidate the Gaussian process proposes next: [tune::exp_improve()] (the
#'   default), [tune::prob_improve()] or [tune::conf_bound()].
#'
#' @return A `nested_results` with one row per outer fold, the columns the
#'   grid page documents. Each fold's `.inner_metrics` carries an `.iter`
#'   column after `.config`. It is `0` for the initial candidates and `i`
#'   for the candidate the `i`-th iteration proposed, so a fold's search
#'   trajectory can be read from it. There is no `grid` attribute. The
#'   `procedure` record names the tuner `"tune_bayes"`. It holds `iter`,
#'   `initial` and `objective` beside the arguments every orchestrator
#'   records.
#'
#' @section The initial candidates and the iterations:
#'
#' Each fold generates its own space-filling set of `initial` candidates
#' from the parameter ranges with [dials::grid_space_filling()], and scores
#' it with [tune::tune_grid()] under the fold's own tuning seed. A
#' `tune_results` object is refused as `initial` because one tuning run
#' cannot serve every outer fold: its candidates were scored on resamples
#' that can hold a fold's assessment rows.
#'
#' Each iteration proposes one candidate and scores it on the fold's inner
#' resamples. `iter = 0` scores the initial candidates and proposes
#' nothing. The run is then [nested_tune_grid()] on the space-filling grid
#' those candidates form. tune stops a fold's search early when no
#' unscored candidate remains, and says so on the console. It also stops
#' after ten consecutive iterations without improvement, its `no_improve`
#' default, settable through the control. The fold then completes with the
#' candidates scored so far, and nothing about the early stop reaches
#' `.notes`.
#'
#' A parameter range that depends on the data is a case apart.
#' [nested_tune_grid()] and the finetune tuners finalize such a range on
#' the outer fold's analysis rows. [tune::tune_bayes()] refuses it before
#' any frame is read, and every outer fold records that refusal as its
#' failure. Finalize the range on the data first.
#'
#' @inheritSection nested_tune_grid Nested designs
#' @inheritSection nested_tune_grid Finalizing a parameter range
#' @inheritSection nested_tune_grid Evaluation times
#'
#' @template section-resample-weights
#'
#' @template section-reproducibility
#'
#' @section Differences from calling tune directly:
#'
#' There is no `control` formal. A [tune::control_bayes()] passed through
#' `...` as `control` reaches the inner `tune_bayes()` in every fold and
#' the final fit that re-runs the result. `control = control_bayes(no_improve
#' = 5, uncertain = 3)`, say, stops a fold's search sooner. What runs is the
#' control passed, or tune's default when none is, with the slots this
#' package forces overwritten. The result records that effective control,
#' `seed` left out, as `extract_procedure(res)$control`. Every slot of
#' `control_bayes()` falls under one of seven headings.
#'
#' **Forced: `allow_par`, `seed`.** `allow_par = FALSE` on both tune calls a
#' fold makes, because parallelism belongs over the outer folds. `seed` is
#' the slot that drives the Gaussian process's proposals. tune draws it
#' from the stream when it is not given. Were the slot left alone, a fold's
#' proposals depend on how much of the stream tune consumed before
#' reaching it. Here the control is given the fold's own tuning seed, the number
#' `.tuning_seed` reports, whatever the control carried.
#'
#' @templateVar INNER inner search
#' @templateVar SETTABLE_TAIL `iter`, `initial` and `objective` are arguments of `tune_bayes()` rather than control slots, offered here as arguments and reaching it unchanged. So is `eval_time`.
#' @template differences-settable
#' @template differences-refused-plain
#' @section Differences from calling tune directly:
#' **Passed through: `no_improve`, `uncertain`, `time_limit`, `verbose`,
#' `verbose_iter`, `save_gp_scoring`, `pkgs`, `parallel_over`,
#' `workflow_size`.** Each reaches `tune_bayes()` as given:
#'
#' - `no_improve` and `uncertain` govern each fold's search as they do in a
#'   direct call, so a fold sometimes stops short of `iter`. Its
#'   `.inner_metrics` records how far it went.
#' - `time_limit` stops a search by the clock. Two runs under the same seed
#'   can then stop at different iterations on different machines, which is
#'   outside what the seeds can promise.
#' - `verbose` and `verbose_iter` print from a serial run, and from a mirai
#'   daemon where nothing shows it.
#' - `save_gp_scoring` writes its files to the temporary directory of the
#'   process that tuned, a daemon's own on the parallel path.
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
#' @inherit nested_tune_grid references
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
