#' Score a workflow with nothing to tune on the outer folds of a nested design
#'
#' `nested_fit_resamples()` runs the outer loop of a nested design for a
#' workflow whose parameters are all fixed: for each outer fold it fits the
#' workflow on the fold's analysis set and scores it on the assessment set
#' with [tune::last_fit()], and it skips the inner stage entirely, since there
#' is nothing to search. It is [nested_tune_grid()] with the inner tuner
#' removed, and the sixth member of that family: the loop, the seeds, the
#' results object and its methods are the same, so a fixed workflow and a
#' tuned one score on identical outer folds and their per-fold metrics join by
#' fold label. The grid function's help page is the reference for everything
#' the orchestrators share -- what a failed fold records, how the folds run in
#' parallel, and what an operation on the result may do.
#'
#' Use it for the baseline a tuned procedure is compared against. A plain
#' `rset` of outer folds is what [tune::fit_resamples()] already serves; what
#' this function adds is the same *nested* design, so the two runs' folds are
#' the same rows. The record says no tuning ran: the `procedure` record names
#' the tuner `"fit_resamples"` and carries no `grid`, `param_info` or
#' `select`, and every completed fold's `.selected` is an empty table.
#'
#' A workflow that still carries a [tune::tune()] marker is refused at entry,
#' with condition class `nestedtune_tuned_workflow`, naming the five
#' orchestrators that tune; and each of those refuses a workflow with no
#' marker, with class `nestedtune_untuned_workflow`, naming this one. One
#' path for a fixed model, one for a tuned one.
#'
#' @inheritParams nested_tune_grid
#' @param object A [workflows::workflow()] with no parameter marked for tuning
#'   with [tune::tune()]: every value fixed, as [tune::fit_resamples()] takes
#'   it. A workflow carrying a marker is refused at entry.
#' @param ... A control object as `control` -- what
#'   [tune::control_resamples()] returns -- and nothing else. Two of its
#'   slots reach the outer fit, `save_pred` and `extract`; the section on
#'   differences from tune says what becomes of each slot. Any other name is
#'   an error, as is an unnamed value.
#' @param metrics A [yardstick::metric_set()], or `NULL` to use tune's
#'   defaults for the model's mode. There is no inner run to select on, so
#'   the set's order carries no weight here.
#' @param event_level `"first"` (the default) or `"second"`, naming which
#'   level of a two-class outcome factor is the event, as on
#'   [nested_tune_grid()]. It reaches the one tune call a fold makes, the
#'   outer scoring fit, where it decides what the reported metrics mean.
#'
#' @return An object of class `nested_results`, one row per outer fold, with
#'   the columns [nested_tune_grid()] documents and three of them holding
#'   what no tuning leaves. `.selected` is a zero-row, zero-column tibble on
#'   every completed fold and `NULL` on a failed one: nothing was chosen, and
#'   no row is written to say so. `.inner_metrics` is a zero-row table with
#'   tune's summary columns (`.metric`, `.estimator`, `mean`, `n`, `std_err`,
#'   `.config`, and `.eval_time` for a dynamic survival metric) and no
#'   parameter column: no inner run scored anything. `.tuning_seed` holds the
#'   seed the loop drew for the fold's tuning step, consumed by nothing (the
#'   reproducibility section says why it is kept). `.metrics`, `.notes`,
#'   `.completed` and `.outer_fit_seed` are as on every orchestrator, and
#'   `.predictions` and `.extracts` are present exactly when the control asked
#'   for them.
#'
#'   There is no `grid` attribute. The `procedure` record, which
#'   [extract_procedure()] returns, names the tuner (`"fit_resamples"`) and
#'   holds `event_level`, `eval_time` and the effective control, with no
#'   `grid`, `param_info` or `select` entry: no parameter set was read and no
#'   rule applied. `attr(x, "metrics")` holds the `metrics` argument, absent
#'   when none was given.
#'
#'   Every reader of a `nested_results` answers on the result.
#'   [collect_metrics()], `summary()`, `print()`, [collect_notes()],
#'   [collect_predictions()][collect_predictions.nested_results] and
#'   [collect_extracts()][collect_predictions.nested_results] read what the
#'   outer fits produced; [collect_selections()], [collect_inner_metrics()]
#'   and [agreement()] return zero rows; and `autoplot(type = "performance")`
#'   draws the fold scores, where `autoplot(type = "parameters")` refuses with
#'   class `nestedtune_no_tuned_parameters`, there being nothing to draw.
#'   [nested_final_fit()] accepts the result and fits the workflow on every
#'   row, with no tuning run.
#'
#' @section Reproducibility:
#'
#' The seed contract is [nested_tune_grid()]'s: seed the session before the
#' call, there is no `seed` argument, `2 * n` seeds are drawn in one
#' `sample.int(.Machine$integer.max, 2 * n)` call on entry, and fold `i` is
#' assigned element `2 * i - 1` as its tuning seed and element `2 * i` as its
#' outer-fit seed. The same draw is made as on a tuned run, so a tuned run
#' under the same session seed on the same design shares each fold's
#' outer-fit seed with this one, and the record keeps one layout across the
#' six orchestrators. The tuning seed is drawn and consumed by nothing: there
#' is no inner stage for it to seed, and it is recorded as drawn rather than
#' as `NA` so the two seed columns read the same on every result. Fold `i`
#' is exactly:
#'
#' ```
#' set.seed(res$.outer_fit_seed[[i]], kind = "Mersenne-Twister",
#'          normal.kind = "Inversion", sample.kind = "Rejection")
#' last_fit(object, resamples$splits[[i]], metrics = metrics,
#'          eval_time = eval_time,
#'          control = control_last_fit(event_level = event_level))
#' ```
#'
#' and `res$.tuning_seed[[i]]` appears in no line of it.
#'
#' The caller's RNG state and generator kind are restored on exit, including
#' when the call errors. The same seed gives the same result serially and in
#' parallel, at any number of daemons.
#'
#' @section Differences from calling tune directly:
#'
#' There is no `control` formal, but a [tune::control_resamples()] passed
#' through `...` as `control` is recorded, and two of its slots reach the
#' outer fit. What is recorded is the control passed, or tune's default when
#' none is, with the slots this package forces overwritten, as
#' `extract_procedure(res)$control`. tune gives `control_resamples()` and
#' [tune::control_grid()] one class, so either is accepted here as the same
#' object. Every slot of `control_resamples()` falls under one of seven
#' headings; most fall under the last, because the one tune call a fold makes
#' here is the outer scoring fit, whose own control this package builds.
#'
#' **Forced: `allow_par`.** The outer fit runs at `allow_par = FALSE`,
#' whatever the control carries. Parallelism belongs over the outer folds,
#' and leaving that to a caller would put two pools in contention.
#'
#' **Settable as its own argument: `event_level`.** As on
#' [nested_tune_grid()]: the argument is the one place the level is set, a
#' control left at tune's default takes it, and a control naming a level that
#' is neither tune's default nor the argument's is refused at entry, naming
#' both. `eval_time` is offered the same way.
#'
#' **Refused: none.** No slot is refused on its own. What is refused at entry
#' is a control of another class -- a `control_bayes()` -- and the
#' `event_level` conflict above. The class is the contract: tune gives
#' `control_resamples()`, [tune::control_grid()] and [tune::control_last_fit()]
#' one class, so any of the three is accepted as what `control_resamples()`
#' returns, its slots read under these headings.
#'
#' **Passed through: none.** There is no inner tuning call for a slot to be
#' passed through to.
#'
#' **Kept from the outer fit: `save_pred`, `extract`.** As on
#' [nested_tune_grid()]: with `save_pred = TRUE` the result carries a
#' `.predictions` list column, each completed fold's predictions on its
#' assessment rows as [tune::last_fit()] returns them; with `extract` a
#' function, an `.extracts` list column, the function's value on each
#' completed fold's fitted workflow. Here there is no inner run whose
#' predictions and extracts are discarded; the outer fit's are the only ones,
#' and they are still discarded on a run that did not ask.
#'
#' **Not returned: none.** Nothing an inner run would have saved exists to be
#' withheld.
#'
#' **Inert: `verbose`, `pkgs`, `save_workflow`, `parallel_over`,
#' `backend_options`, `workflow_size`.** Each governs an inner tuning call
#' this function never makes. The outer fit runs under
#' [tune::control_last_fit()] at the level and parallelism above, which
#' reads none of these; the workflow's packages are required at entry, and
#' the fitted workflow is reached through `extract`. Nothing that changes a
#' reported number is left to a slot listed here.
#'
#' @examplesIf rlang::is_installed(c("recipes", "yardstick"))
#' data(mtcars)
#'
#' # A fixed workflow: two components, no tune() marker.
#' rec <- recipes::step_pca(
#'   recipes::recipe(mpg ~ ., data = mtcars),
#'   recipes::all_predictors(),
#'   num_comp = 2L
#' )
#' wf <- workflows::workflow(rec, parsnip::linear_reg())
#'
#' set.seed(1)
#' folds <- nested_resamples(
#'   mtcars,
#'   outside = rsample::vfold_cv(v = 3),
#'   inside = rsample::vfold_cv(v = 3)
#' )
#'
#' set.seed(2)
#' res <- nested_fit_resamples(wf, folds)
#' collect_metrics(res)
#'
#' # The record says no tuning ran.
#' extract_procedure(res)$tuner
#' res$.selected[[1]]
#'
#' @seealso [nested_tune_grid()], [nested_resamples()], [nested_final_fit()],
#'   [tune::fit_resamples()]
#' @export
nested_fit_resamples <- function(
  object,
  resamples,
  ...,
  metrics = NULL,
  event_level = "first",
  eval_time = NULL
) {
  control <- check_dots_control(capture_dots(...))
  check_workflow(object)
  # The door this function is (D-057): a marked workflow goes to the five,
  # refused here before the design is judged.
  check_tuned_workflow(object)
  check_nested(resamples)
  check_metrics(metrics)
  check_event_level(event_level)
  check_eval_time(eval_time)
  control <- check_control(control, "fit_resamples", event_level)

  # No parameter set, no grid and no rule: the description says the tuner
  # selects nothing, and the loop's fold skips the inner stage on that word
  # (`nested_fold_fit()`, R/nested-tune-grid.R). `select` is NULL rather than
  # a default rule so the record cannot carry one (`new_procedure()`).
  nested_loop(
    object,
    resamples,
    tuner = tuner_fit_resamples(),
    metrics = metrics,
    param_info = NULL,
    event_level = event_level,
    eval_time = eval_time,
    select = NULL,
    control = control,
    grid = NULL,
    call = rlang::current_env()
  )
}
