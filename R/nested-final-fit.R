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
#' `nested_final_fit()` builds the model you deploy after a nested run. It
#' runs the recorded procedure, tune, select and fit, once more with the
#' whole dataset in hand. That means rebuilding the inner resamples on every
#' row, tuning with the recorded tuner, selecting by the recorded
#' [selection_rule()], and fitting the finalized workflow on all the data.
#'
#' What comes back is the model to deploy. It carries no performance number
#' of its own. The number to report is [collect_metrics()] on the results
#' object you passed in, for the reason the section on what to report gives.
#'
#' @param object The [workflows::workflow()] the nested run was built around,
#'   or a `nested_results_set` from [nested_workflow_map()] with `id` naming
#'   the workflow to fit. A workflow is checked against the record before
#'   anything is fitted.
#' @param results The `nested_results` object from [nested_tune_grid()] or one
#'   of its siblings whose estimate you will report for this model. Everything
#'   the re-run needs is read from it.
#' @param ... Not used; must be empty. Everything the re-run needs, the grid
#'   and the metrics included, now comes from `results`, so passing an
#'   argument here is an error.
#' @param id For a `nested_results_set` as `object`, the `wflow_id` of the
#'   workflow to fit; `results` is then left missing. `NULL`, the default, for
#'   a plain workflow.
#'
#' @return An object of class `nested_final_fit`. Its elements are:
#'
#'   - `workflow`, the trained workflow. The object answers
#'     [predict()][predict.nested_final_fit] and `augment()` directly, and
#'     [extract_workflow()] returns the workflow itself.
#'   - `selected`, the parameters chosen, and `tuning`, the tuning run they
#'     were chosen from.
#'   - `tuning_seed` and `fit_seed`, the two seeds that reproduce it.
#'   - `procedure`, the record re-run, as `results` carried it.
#'
#'   Where nothing was tuned, `selected` is an empty table and `tuning` is
#'   `NULL`. [extract_tune_results()] and [extract_scored_candidates()] then
#'   refuse the object with class `nestedtune_no_tuning_run`, and its print
#'   says no tuning ran.
#'
#' @details
#' The procedure a nested estimate describes is "resample this dataset by
#' the inner specification, tune, select, fit". The dataset that procedure
#' is meant for is all of yours. So the final model comes from running it
#' again with nothing held out: the same convention as cross-validating a
#' model and then refitting on everything, one level up.
#'
#' The outer folds play no part here. Their selections belong to the
#' estimate, which describes the procedure across the instability those
#' selections reveal. They are not pooled or voted on to build this model.
#'
#' @section The results object:
#'
#' `results` supplies the inner resampling specification the design stored,
#' the data every split references, the `procedure` record, and the metric
#' set as `attr(results, "metrics")`. The record names the tuner and that
#' tuner's own arguments, the grid or the iteration counts. It also holds
#' `param_info`, `event_level`, `eval_time` and `select`, the
#' [selection_rule()] the folds selected by. [extract_procedure()] shows
#' you the record.
#'
#' A `param_info` parameter whose range is unknown until the data is seen
#' is finalized here on the full data, since every row is this model's
#' training data. Each outer fold of the nested run finalized it on that
#' fold's analysis rows alone, so this model's candidate range can be wider
#' than any fold's.
#'
#' A run in which some folds failed is still fitted. Its estimate is
#' [collect_metrics()]'s, with that function's partial-run warning.
#'
#' @section Fitting one workflow of a set:
#'
#' [nested_workflow_map()] returns a `nested_results_set` holding each
#' workflow beside its own results. Pass the set as `object`, name the row
#' with `id`, and leave `results` missing. The fit is then
#' `nested_final_fit(extract_workflow(object, id), object$result[[i]])`: the
#' workflow and its record are read off one row, so the two cannot be
#' mispaired.
#'
#' @section What is refused:
#'
#' A workflow other than the one the estimate was built around is refused
#' here where the record names a tuner that takes a grid. `object` is then
#' judged against the recorded grid as [nested_tune_grid()] judged it,
#' rather than by tune a whole tuning run later. Where nothing was tuned (see
#' [nested_fit_resamples()]), the workflow must carry no [tune::tune()]
#' marker, and one that does is refused with class
#' `nestedtune_tuned_workflow`.
#'
#' Three shapes of `results` are refused before any fitting, with condition
#' class `nestedtune_bad_results`. One carries no record: it was built by an
#' earlier version of nestedtune, or from a design assembled by hand rather
#' than by [nested_resamples()] or [rsample::nested_cv()]. One is no longer
#' a `nested_results`, because an operation that added or removed rows
#' returned a plain tibble. And one has no rows.
#'
#' A results object in which no outer fold completed is refused next, with class
#' `nestedtune_no_completed_folds`. There is no estimate to report the model
#' with, and `summary()` lists the stage each fold failed at. That is the
#' class [collect_metrics()], [autoplot()][autoplot.nested_results] and
#' [agreement()] refuse it with.
#'
#' An `id` naming no row of a set is refused with class
#' `nestedtune_unknown_id`. A set given with `results` supplied, a set given
#' with no `id`, and an `id` given beside a plain workflow are each refused
#' with class `nestedtune_bad_final_fit_args`.
#'
#' @section What to report:
#'
#' Report the estimate [collect_metrics()] returns from the results object
#' you handed over. It describes the whole tune-and-fit procedure that
#' produced this model, measured on rows no part of that procedure ever
#' saw. It is the number to report for this model. The model has no
#' performance number of its own. That includes the metrics inside the
#' tuning run stored on it. They were computed on the resamples that chose
#' the candidate, so they are selection-time quantities, optimistically
#' biased as a claim about this model. `collect_metrics()` on `x$tuning`
#' hands them over without saying so.
#'
#' Expect the nested estimate to run slightly pessimistic instead, since
#' each outer fold trained on its analysis rows alone. Varma and Simon
#' (2006) measured a 4.2-point overshoot at n = 40, and Wilimitis and Walsh
#' (2023) about 1 to 2 percent of AUROC on 41,121 records. That offset
#' shrinks with fold size and is not a correction to apply.
#'
#' Two things the estimate does not say. It is marginal over selection: it
#' averages over what each fold's tuning chose, rather than being
#' conditional on the parameters this model happens to carry. So it makes
#' no claim about this configuration in particular. And it describes new
#' data drawn like your training data, not a different population, and not
#' a model retrained at another size.
#'
#' If the outer folds disagreed about the best parameters, report that too.
#'
#' @section Reproducibility:
#'
#' Seed the session before the call; there is no `seed` argument. Two seeds
#' are drawn on entry and applied with the generator kind pinned: the first
#' builds the inner resamples and tunes, the second fits. Both are kept on
#' the object, and the caller's generator state is put back on the way out.
#' So two calls with no `set.seed()` between them give the same model, as
#' repeated `tune::tune_grid()` calls do. `?nested_tune_grid` covers the
#' rest, including what an R-side seed cannot pin.
#'
#' You can redo the run by hand from those two seeds and the record
#' [extract_procedure()] returns. Every value below comes from that record,
#' except `metrics`, which is `attr(results, "metrics")`. Only the tuning
#' line changes with the tuner. `control` is the record's own: the control
#' the run was given or tune's default, with the slots this package forces
#' already applied.
#'
#' ```
#' set.seed(fit$tuning_seed, kind = "Mersenne-Twister",
#'          normal.kind = "Inversion", sample.kind = "Rejection")
#' inner <- <the design's `inside` specification>(data)
#' control <- extract_procedure(fit)$control
#' # A grid search takes the recorded control untouched. So does a race,
#' # ANOVA or win/loss: its own draws, the resample order under `randomize`,
#' # come from the stream the tuning seed set.
#' tuned <- tune_grid(object, inner, grid = grid, param_info = param_info,
#'   metrics = metrics, eval_time = eval_time, control = control)
#' tuned <- tune_race_anova(object, inner, grid = grid, param_info = param_info,
#'   metrics = metrics, eval_time = eval_time, control = control)
#' tuned <- tune_race_win_loss(object, inner, grid = grid, param_info = param_info,
#'   metrics = metrics, eval_time = eval_time, control = control)
#' # Annealing draws its perturbations from that stream too, and
#' # `control_sim_anneal()` has no seed slot, so again nothing is set.
#' tuned <- tune_sim_anneal(object, inner, iter = iter, initial = initial,
#'   param_info = param_info, metrics = metrics, eval_time = eval_time,
#'   control = control)
#' # Bayesian optimization is the one branch that sets a slot: its Gaussian
#' # process takes the tuning seed, the rule every outer fold used, and the
#' # recorded control carries no seed of its own.
#' control$seed <- fit$tuning_seed
#' tuned <- tune_bayes(object, inner, iter = iter, initial = initial,
#'   objective = objective, param_info = param_info, metrics = metrics,
#'   eval_time = eval_time, control = control)
#' final <- finalize_workflow(object, select_best(tuned, metric = <first metric>))
#'   # Under the recorded default rule; select_by_one_std_err() or
#'   # select_by_pct_loss() with the recorded orderings and limit otherwise.
#' set.seed(fit$fit_seed, kind = "Mersenne-Twister",
#'          normal.kind = "Inversion", sample.kind = "Rejection")
#' fit(final, data)
#' ```
#'
#' Where nothing was tuned there is no such line to redo. Both seeds are
#' still drawn, so the object's seed layout is the one above. But the first
#' is consumed by nothing and the inner specification is left unevaluated.
#' The whole recipe is `fit(object, data)` under the second seed.
#'
#' Building the resamples sits inside the first seed's scope rather than
#' before it. Constructing an `rset` draws from the generator. A version
#' that built them earlier would still be reproducible from the session
#' seed, but no longer from the two seeds above.
#'
#' @section The inner specification is re-evaluated:
#'
#' A nested design stores its `inside` argument as an unevaluated call, and
#' the nested run records it on its result. This function evaluates it
#' again, against the whole dataset, in the environment you call from
#' rather than the one the design was built in.
#'
#' Write it with literal arguments. `inside = vfold_cv(v = 5)` is
#' re-evaluated identically anywhere. `inside = vfold_cv(v = k)` is not. If
#' `k` is gone by the time you call this you get an error naming the
#' specification, and if some other `k` is in scope you silently get a
#' different design. Building a design inside a function that parameterizes
#' its resampling is the common way to meet this.
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
#' @references
#' Varma, S., & Simon, R. (2006). Bias in error estimation when using
#' cross-validation for model selection. *BMC Bioinformatics*, 7, 91.
#'
#' Wilimitis, D., & Walsh, C. G. (2023). Practical considerations and applied
#' examples of cross-validation for model development and evaluation in health
#' care: Tutorial. *JMIR AI*, 2, e49023.
#'
#' @seealso [nested_tune_grid()], [nested_tune_bayes()],
#'   [predict.nested_final_fit()], [extract_workflow()]
#' @export
nested_final_fit <- function(object, results, ..., id = NULL) {
  rlang::check_dots_empty()
  # A workflow-set run (M71): `object` is the set, `id` names the row, and
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
  # The grid is judged against the workflow as the orchestrator judged it,
  # so a workflow other than the one the estimate was built around is refused
  # here rather than by tune, one full tuning run later (GP3).
  # Every tuner that takes a grid -- `tune_grid()` and finetune's racers -- is
  # held to it; the iterative tuners record none (R/tuner.R).
  if (tuner_takes_grid(procedure$tuner)) {
    check_grid_params(object, procedure$grid, recorded = TRUE)
  }
  # A record that selected nothing (M70) takes a workflow with nothing to
  # tune, as `nested_fit_resamples()` took it: a marked parameter would reach
  # `fit()` unfinalized, and the refusal names the five that tune.
  if (!tuner_selects(procedure$tuner)) {
    check_tuned_workflow(object)
  }
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
# draw above reads the caller's stream and that draw is itself kind-dependent
# (M05, deviating from RR02's BC6 as literally written).
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
  # A tuner that selects nothing (M70): no inner rset, no run, no rule. The
  # workflow is fitted as given on every row under the second seed; the
  # first is drawn with it so the object's seed layout matches a tuned fit's,
  # and is consumed by nothing. The design's inner specification is not
  # evaluated, since nothing on this path reads it (a milestone-local
  # decision, M70). `tuning` is NULL, and the two accessors say so.
  if (!tuner_selects(tuner$tuner)) {
    set_fold_seed(seeds[[2L]])
    fitted <- parsnip::fit(object, data = data)
    procedure <- new_procedure(
      tuner,
      param_info = NULL,
      event_level = event_level,
      eval_time = eval_time,
      select = NULL,
      control = control
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
  # The recorded rule (M69), applied as every fold applied it. `eval_time` is
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
    control = control
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
# than answer, exactly as they do for `nested_results` (D-010, RR02 Q7).
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
