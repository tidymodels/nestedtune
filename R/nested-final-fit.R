# The final-fit path.
#
# What the nested estimate describes is a procedure: given a dataset, resample
# it by the inner specification, tune, select, fit. The deployment target of
# that procedure is the whole dataset, so the final model is produced by running
# the procedure again with every row in hand -- the refit step, one level up
# from the ordinary "cross-validate, then refit on everything" convention
# (RR02 Q1).
#
# It is a separate function returning a separate object because the estimate
# characterizes the procedure and never the model (IP3). Nothing here computes
# a performance number, and the object deliberately answers no generic that
# would produce one.

#' Fit the final model after nested cross-validation
#'
#' @description
#' `nested_final_fit()` fits the model to deploy after a nested run. It runs
#' the same procedure (tune, select, fit) once more on all the data.
#'
#' @param object The [workflows::workflow()] the nested run used, or a
#'   `nested_results_set` from [nested_workflow_map()] with `id` naming the
#'   workflow to fit. After a run on a model specification, pass
#'   `workflows::workflow(preprocessor, spec)`.
#' @param results The `nested_results` from [nested_tune_grid()], another
#'   nested tuning function or [nested_fit_resamples()]. The tuner and its
#'   arguments, the metrics, `eval_time` and the selection rule are read from
#'   it.
#' @param ... Not used, and must be empty.
#' @param id For a `nested_results_set`, the `wflow_id` of the workflow to
#'   fit. Leave `results` missing then.
#'
#' @return An object of class `nested_final_fit` with these elements:
#'
#'   - `workflow`, the trained workflow. The object answers
#'     [predict()][predict.nested_final_fit] and `augment()` directly.
#'   - `selected`, the parameters chosen, and `tuning`, the tuning run they
#'     were chosen from.
#'   - `tuning_seed` and `fit_seed`, the two seeds that reproduce it.
#'   - `procedure`, the settings of the run, as `results` holds them.
#'
#'   Where nothing was tuned, `selected` is an empty table and `tuning` is
#'   `NULL`.
#'
#' @details
#' The function rebuilds the inner resamples on all the rows from the
#' design's `inside` specification. It tunes with the same tuner and
#' settings, picks a candidate with the same [selection_rule()], and fits
#' the finalized workflow on all the data. A parameter range that depends on
#' the data is finalized on all the rows. The outer folds and their choices
#' play no part. Where nothing was tuned, the function only fits the workflow
#' on all the data.
#'
#' The design keeps `inside` as a call, and this function evaluates it again
#' in the environment you call from. Write it with literal arguments, such
#' as `vfold_cv(v = 5)`. With `vfold_cv(v = k)`, another `k` in scope gives
#' another design.
#'
#' A workflow whose model or preprocessor differs from the one the nested run
#' used is an error, and the message names the first part that differs.
#' Model arguments and recipe functions are compared as written. So a name
#' bound to another value is not caught, and neither is a function with the
#' same body that uses other values. A run in which some folds
#' failed is still fitted. To fit one workflow of a set, pass the set as
#' `object`, name the workflow with `id`, and leave `results` missing.
#'
#' @section What to report:
#'
#' The nested estimate describes the procedure that produced this model, not
#' this model itself. Report [collect_metrics()] on `results` as the estimate
#' for this model, because the model comes from the same procedure. It
#' averages over what each fold chose, so it says nothing about the setting
#' this model carries. It describes new data drawn like your training data.
#' If the outer folds chose different parameters, report that too.
#'
#' For a workflow from a set, report that workflow's rows only if you chose
#' the workflow before you saw the set's estimates. A choice made from those
#' estimates is a selection the outer loop did not nest.
#'
#' Do not report the metrics in the `tuning` element. They come from the
#' resamples that chose the candidate, so they are optimistic on average. The
#' nested estimate tends to be slightly pessimistic instead, because each
#' outer fold trained on fewer rows. `vignette("estimate")` gives the sizes
#' measured in two studies.
#'
#' @section Reproducibility:
#'
#' Call `set.seed()` before the function. It draws two seeds: the first
#' builds the inner resamples and tunes, and the second fits. Both are kept
#' on the object, and your random state is restored on exit. So two calls
#' with no `set.seed()` between them give the same model, as repeated
#' [tune::tune_grid()] calls do. [nested_tune_grid()] says what an R-side
#' seed cannot pin.
#'
#' The code below redoes the fit by hand. The values come from
#' [extract_procedure()], except `metrics`, which is
#' `attr(results, "metrics")`, and `data`, the data the design was built on.
#' Only the tuning line changes with the tuner.
#'
#' ```
#' set.seed(fit$tuning_seed, kind = "Mersenne-Twister",
#'          normal.kind = "Inversion", sample.kind = "Rejection")
#' inner <- <the design's `inside` specification>(data)
#' control <- extract_procedure(fit)$control
#' # Run the one tuning line for the recorded tuner.
#' # Grid search and the races use the control as it is.
#' tuned <- tune_grid(object, inner, grid = grid, param_info = param_info,
#'   metrics = metrics, eval_time = eval_time, control = control)
#' tuned <- tune_race_anova(object, inner, grid = grid, param_info = param_info,
#'   metrics = metrics, eval_time = eval_time, control = control)
#' tuned <- tune_race_win_loss(object, inner, grid = grid, param_info = param_info,
#'   metrics = metrics, eval_time = eval_time, control = control)
#' # So does annealing.
#' tuned <- tune_sim_anneal(object, inner, iter = iter, initial = initial,
#'   param_info = param_info, metrics = metrics, eval_time = eval_time,
#'   control = control)
#' # A Bayesian search also sets the control's seed.
#' control$seed <- fit$tuning_seed
#' tuned <- tune_bayes(object, inner, iter = iter, initial = initial,
#'   objective = objective, param_info = param_info, metrics = metrics,
#'   eval_time = eval_time, control = control)
#' final <- finalize_workflow(object, select_best(tuned, metric = <first metric>))
#'   # Or select_by_one_std_err() or select_by_pct_loss(), as `select` says.
#' set.seed(fit$fit_seed, kind = "Mersenne-Twister",
#'          normal.kind = "Inversion", sample.kind = "Rejection")
#' fit(final, data)
#' ```
#'
#' Where nothing was tuned, the code is `fit(object, data)` under the second
#' seed.
#'
#' @template example-setup
#' @template example-run
#' @template example-final
#' @examplesIf rlang::is_installed(c("recipes", "yardstick"))
#' # The estimate: what the procedure achieves, and the number to report.
#' collect_metrics(res)
#'
#' # The model: what you deploy.
#' final
#'
#' predict(final, new_data = mtcars[1:3, ])
#'
#' @seealso [nested_tune_grid()], [nested_tune_bayes()],
#'   [nested_workflow_map()], [predict.nested_final_fit()],
#'   [extract_workflow()]
#' @export
nested_final_fit <- function(object, results, ..., id = NULL) {
  rlang::check_dots_empty()
  # A workflow-set run: `object` is the set, `id` names the row, and
  # the workflow and its record are read together off that row, so the
  # wrong pairing cannot happen. The rest of the path is the single
  # workflow's, on what the row holds.
  if (inherits(object, "nested_results_set")) {
    check_final_fit_set_args(object, !missing(results), id)
    i <- match_set_id(object, id)
    results <- object$result[[i]]
    object <- object$workflow[[i]]
  } else if (!is.null(id)) {
    check_final_fit_set_args(object, !missing(results), id)
  }
  check_workflow(object)
  check_results_record(results)
  check_completed_folds(results)

  procedure <- attr(results, "procedure")
  # The packages the recorded tuner needs are asked for here as the racing
  # exports ask at entry (D-044), so a racing result loaded where finetune or
  # its model-fitting package is absent is refused before the inner rset is
  # built rather than inside the race.
  check_tuner_installed(procedure$tuner)
  # And desirability2 for a recorded desirability rule (D-072), which a
  # result built where it was installed can carry to where it is not.
  if (
    is_selection_rule(procedure$select) &&
      identical(procedure$select$rule, "desirability")
  ) {
    check_desirability_installed()
  }
  # The grid is judged against the workflow as the orchestrator judged it,
  # so a workflow other than the one the estimate was built around is refused
  # here rather than by tune, one full tuning run later (GP3).
  # Every tuner that takes a grid -- `tune_grid()` and finetune's racers -- is
  # held to it; the iterative tuners record none (R/tuner.R).
  if (tuner_takes_grid(procedure$tuner)) {
    check_grid_params(object, procedure$grid, recorded = TRUE)
  }
  # A record that selected nothing takes a workflow with nothing to
  # tune, as `nested_fit_resamples()` took it: a marked parameter would reach
  # `fit()` unfinalized, and the refusal names the five that tune.
  if (!tuner_selects(procedure$tuner)) {
    check_tuned_workflow(object)
  }
  # The workflow itself, against the identity the run recorded: the
  # grid and marker checks above catch a workflow tuning different names
  # and name the exact column or marker, so they run first; this catches
  # every other difference. It runs before the seeds below are drawn, so a
  # session with no generator state still has none after a refusal here.
  # A session that had one would get it back from `restore_rng()` even if
  # this check came after the draw.
  check_workflow_identity(object, procedure$workflow)
  inside <- attr(results, "inside")
  # Absent rather than NULL when the run was given none; either way tune picks.
  metrics <- attr(results, "metrics")

  env <- rlang::caller_env()
  data <- split_data(results)

  # The same snapshot-and-restore contract the loop gives (D-011): what is put
  # back is the caller's state on entry, and `sample.int()` below initializes a
  # fresh session's state, which is left valid rather than removed.
  had_seed <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  old_kind <- RNGkind()
  old_seed <- if (had_seed) get(".Random.seed", envir = globalenv())
  on.exit(restore_rng(had_seed, old_kind, old_seed), add = TRUE)

  seeds <- sample.int(.Machine$integer.max, 2L)

  final_fit_worker(
    inside,
    data,
    env,
    seeds,
    object,
    procedure_tuner(procedure),
    metrics,
    param_info = procedure$param_info,
    event_level = procedure$event_level,
    eval_time = procedure$eval_time,
    select = procedure$select,
    control = procedure$control,
    call = rlang::current_env()
  )
}

# The final fit itself, once the seeds exist.
#
# Split from the entry point for the same reason `nested_fold_fit()` is:
# everything it needs is an argument, so what it produces depends on the two
# seeds and on nothing ambient. That is what makes the kind-independence
# property testable -- from a user-visible seed it is not, because the entry
# draw above reads the caller's stream and that draw is itself kind-dependent.
# This departs from RR02's recommendation as literally written.
# `call` is threaded through rather than defaulted at the abort site: the
# specification is re-evaluated here, two frames below the function the user
# called, so an abort left to name its own caller named this worker -- an
# internal frame -- where every other check on this path names their call.
final_fit_worker <- function(
  inside,
  data,
  env,
  seeds,
  object,
  tuner,
  metrics,
  param_info = NULL,
  event_level = "first",
  eval_time = NULL,
  select = selection_rule(),
  control = NULL,
  call = rlang::caller_env()
) {
  # Made effective before anything runs, so the record below and the call
  # `run_tuner()` makes are one object (D-042); a worker driven without one
  # runs and records tune's default, as the orchestrator would have.
  control <- effective_control(tuner$tuner, control, event_level)
  # A tuner that selects nothing: no inner rset, no run, no rule. The
  # workflow is fitted as given on every row under the second seed; the
  # first is drawn with it so the object's seed layout matches a tuned fit's,
  # and is consumed by nothing. The design's inner specification is not
  # evaluated, since nothing on this path reads it. `tuning` is NULL, and the
  # two accessors say so.
  if (!tuner_selects(tuner$tuner)) {
    set_fold_seed(seeds[[2L]])
    fitted <- parsnip::fit(object, data = data)
    procedure <- new_procedure(
      tuner,
      param_info = NULL,
      event_level = event_level,
      eval_time = eval_time,
      select = NULL,
      control = control,
      workflow = workflow_identity(object)
    )
    return(new_nested_final_fit(
      fitted,
      empty_candidates(),
      NULL,
      seeds,
      procedure
    ))
  }
  # D-016: the tuning seed's scope is "construct the resamples and tune", so
  # the specification is evaluated *after* the seed is set. Building an rset
  # draws from the RNG, and a draw made outside this scope would leave the run
  # reproducible from the entry state but not from the two seeds -- the
  # property the seeds exist to provide -- while every same-seed test went on
  # passing.
  set_fold_seed(seeds[[1L]])
  inner <- eval_inside_spec(inside, data, env, call = call)
  check_final_inner(inner, tuner$tuner, call = call)
  tuned <- run_tuner(
    tuner,
    object = object,
    resamples = inner,
    param_info = param_info,
    metrics = metrics,
    eval_time = eval_time,
    event_level = event_level,
    control = control,
    seed = seeds[[1L]]
  )
  # Resolved from the tuned object rather than from `metrics`, so the same code
  # answers whether the caller supplied a metric set or let tune pick.
  metric_name <- tune::.get_tune_metric_names(tuned)[[1L]]
  # The recorded rule, applied as every fold applied it. `eval_time` is
  # not passed on, for the reason `nested_fold_fit()` gives at the same call
  # (D-038): left NULL, tune reads the evaluation times off `tuned` -- the ones
  # this run was tuned at -- and selects at the first of them either way.
  selected <- apply_selection_rule(tuned, select, metric_name)
  final_wf <- tune::finalize_workflow(object, selected)

  set_fold_seed(seeds[[2L]])
  fitted <- parsnip::fit(final_wf, data = data)

  # The same record the results object carries, rebuilt from what this worker
  # was handed, so the object names the procedure it ran (IP4) and the print
  # method has the requested counts to show beside the scored ones.
  procedure <- new_procedure(
    tuner,
    param_info = param_info,
    event_level = event_level,
    eval_time = eval_time,
    select = select,
    control = control,
    workflow = workflow_identity(object),
    # The name this fit selected on, resolved above from its own run, so a
    # results object built before the entry was recorded still yields a fit
    # that names it.
    first_metric = metric_name
  )
  new_nested_final_fit(fitted, selected, tuned, seeds, procedure)
}

# The final-fit object.
#
# A plain list, not a tibble: there is one model here, not one row per fold.
# It carries the tuning run it came from because that run is the record of what
# selection saw -- the analog of `nested_results` keeping `.selected` -- and
# because the package's own oracle reads it. What it deliberately does not
# carry is any method that would turn that run into a performance claim: tune's
# ranking and collecting generics are left unregistered, so they error rather
# than answer, exactly as they do for `nested_results` (D-010, RR02 Q7). The
# extractors below reach parts of the trained workflow and make no such
# claim (D-068).
new_nested_final_fit <- function(workflow, selected, tuning, seeds, procedure) {
  structure(
    list(
      workflow = workflow,
      selected = selected,
      tuning = tuning,
      tuning_seed = seeds[[1L]],
      fit_seed = seeds[[2L]],
      procedure = procedure
    ),
    class = "nested_final_fit"
  )
}

#' @importFrom tune extract_workflow
#' @export
extract_workflow.nested_final_fit <- function(x, ...) {
  rlang::check_dots_empty()
  x$workflow
}

#' Extract the parts of a final fit's workflow
#'
#' @description
#' These methods return the fitted model, its specification, the
#' preprocessor, the mold, the outcome names and the parameter set of the
#' workflow that [nested_final_fit()] trained.
#'
#' @details
#' Each one except `extract_parameter_set_dials()` returns what the same
#' call on [extract_workflow()]'s output returns.
#'
#' `extract_parameter_set_dials()` reads the parameter set that tune stored
#' for the final fit's tuning run, because the trained workflow holds no
#' `tune()` placeholder. When tune built the candidates itself, as for a
#' numeric `grid` or for [nested_tune_sim_anneal()], it finalized any
#' unknown range on the predictors. With a data-frame `grid`, the set can
#' keep an unknown range, such as the upper bound of `mtry`, so finalize it
#' before use. A fit from [nested_fit_resamples()] ran no tuning and gives
#' an error.
#'
#' @param x A `nested_final_fit` from [nested_final_fit()].
#' @param ... Not used, and must be empty.
#' @param estimated For `extract_recipe()`, whether to return the trained
#'   recipe (`TRUE`, the default) or the recipe as it was given.
#' @return What the same call returns for the trained workflow. For
#'   `extract_parameter_set_dials()`, a dials `parameters` object, the set
#'   the tuning run stored.
#' @seealso [extract_workflow()], [extract_tune_results()]
#' @name extract-nested_final_fit
#' @template example-setup
#' @template example-run
#' @template example-final
#' @examplesIf rlang::is_installed(c("recipes", "yardstick"))
#' extract_fit_parsnip(final)
#' extract_recipe(final)
#' outcome_names(final)
#' extract_parameter_set_dials(final)
NULL

#' @rdname extract-nested_final_fit
#' @importFrom tune extract_fit_parsnip
#' @export
extract_fit_parsnip.nested_final_fit <- function(x, ...) {
  rlang::check_dots_empty()
  extract_fit_parsnip(x$workflow)
}

#' @rdname extract-nested_final_fit
#' @importFrom tune extract_fit_engine
#' @export
extract_fit_engine.nested_final_fit <- function(x, ...) {
  rlang::check_dots_empty()
  extract_fit_engine(x$workflow)
}

#' @rdname extract-nested_final_fit
#' @importFrom tune extract_recipe
#' @export
extract_recipe.nested_final_fit <- function(x, ..., estimated = TRUE) {
  rlang::check_dots_empty()
  extract_recipe(x$workflow, estimated = estimated)
}

#' @rdname extract-nested_final_fit
#' @importFrom tune extract_mold
#' @export
extract_mold.nested_final_fit <- function(x, ...) {
  rlang::check_dots_empty()
  extract_mold(x$workflow)
}

#' @rdname extract-nested_final_fit
#' @importFrom tune extract_preprocessor
#' @export
extract_preprocessor.nested_final_fit <- function(x, ...) {
  rlang::check_dots_empty()
  extract_preprocessor(x$workflow)
}

#' @rdname extract-nested_final_fit
#' @importFrom tune extract_spec_parsnip
#' @export
extract_spec_parsnip.nested_final_fit <- function(x, ...) {
  rlang::check_dots_empty()
  extract_spec_parsnip(x$workflow)
}

#' @rdname extract-nested_final_fit
#' @importFrom tune outcome_names
#' @export
outcome_names.nested_final_fit <- function(x, ...) {
  rlang::check_dots_empty()
  outcome_names(x$workflow)
}

# Read off the tuning run, not the trained workflow: finalizing replaced each
# `tune()` placeholder, so the workflow's own method returns an empty set.
#' @rdname extract-nested_final_fit
#' @importFrom tune extract_parameter_set_dials
#' @export
extract_parameter_set_dials.nested_final_fit <- function(x, ...) {
  rlang::check_dots_empty()
  check_tuning_run(
    x,
    "extract_parameter_set_dials",
    call = rlang::current_env()
  )
  attr(x$tuning, "parameters")
}
