#' Score a workflow with nothing to tune on a nested design
#'
#' @description
#' `nested_fit_resamples()` gives you the score of a workflow with nothing
#' to tune on the same outer folds a tuned workflow scores on. It runs the
#' outer loop of a nested design with the inner stage skipped, since there
#' is nothing to search. For each outer fold it fits the workflow on the
#' fold's analysis set and scores it on the assessment set with
#' [tune::last_fit()]. It is [nested_tune_grid()] with the inner tuner
#' removed. So a fixed workflow and a tuned one score on identical outer
#' folds, and their per-fold metrics join by fold label. That page is the
#' reference for everything the orchestrators share.
#'
#' Use it for the baseline a tuned procedure is compared against. A plain
#' `rset` of outer folds is what
#' [tune::fit_resamples()] already serves; what this function adds is the
#' same nested design, so the two runs' folds are the same rows.
#'
#' @inheritParams nested_tune_grid
#' @param object A [workflows::workflow()] with no parameter marked for tuning
#'   with [tune::tune()], every value fixed as [tune::fit_resamples()] takes
#'   it. A workflow carrying a marker is refused at entry.
#' @param ... A control object from [tune::control_resamples()], as
#'   `control`, and nothing else; every argument after `...` is matched by
#'   name. The section on differences from tune says what becomes of each
#'   slot.
#' @param metrics A [yardstick::metric_set()], or `NULL` to use tune's
#'   defaults for the model's mode. There is no inner run to select on, so
#'   the set's order carries no weight here.
#' @param event_level `"first"` (the default) or `"second"`, naming which
#'   level of a two-class outcome is the event in the one tune call a fold
#'   makes, the outer scoring fit.
#' @param eval_time A numeric vector of evaluation times for a censored
#'   regression model, or `NULL` (the default) to leave the choice to tune.
#'   Anything not numeric, an empty vector, or an element that is missing,
#'   negative or not finite is refused at entry.
#'
#' @return A `nested_results` with one row per outer fold and the columns
#'   [nested_tune_grid()] documents, three of them holding what no tuning
#'   leaves. `.selected` is a zero-row, zero-column tibble on every
#'   completed fold and `NULL` on a failed one. `.inner_metrics` is a
#'   zero-row table with tune's summary columns and no parameter column.
#'   `.tuning_seed` holds the seed the loop drew for the fold's tuning
#'   step, consumed by nothing. There is no `grid` attribute. The
#'   `procedure` record names the tuner `"fit_resamples"`, and holds no
#'   grid, parameter set or selection rule.
#'
#' @section One door for a fixed workflow, one for a tuned one:
#'
#' A workflow that still carries a [tune::tune()] marker is refused at
#' entry with condition class `nestedtune_tuned_workflow`, naming the five
#' orchestrators that tune. Each of those refuses a workflow with no
#' marker, with class `nestedtune_untuned_workflow`, naming this one.
#'
#' @section What the reading functions answer:
#'
#' Every function that reads a `nested_results` answers on the result.
#' [collect_metrics()], `summary()`, `print()`, [collect_notes()],
#' [collect_predictions()][collect_predictions.nested_results] and
#' [collect_extracts()][collect_predictions.nested_results] read what the
#' outer fits produced. [collect_selections()], [collect_inner_metrics()]
#' and [agreement()] return zero rows. `autoplot(type = "performance")`
#' draws the fold scores, where `autoplot(type = "parameters")` refuses
#' with class `nestedtune_no_tuned_parameters`, there being nothing to
#' draw. [nested_final_fit()] accepts the result and fits the workflow on
#' every row, with no tuning run.
#'
#' @inheritSection nested_tune_grid Nested designs
#'
#' @template section-reproducibility
#'
#' @section The two seeds on a run with no tuning:
#'
#' The same `2 * n` seeds are drawn as on a tuned run. So a tuned run under
#' the same session seed on the same design shares each fold's outer-fit
#' seed with this one. The record keeps one layout across the six
#' orchestrators. The tuning seed is drawn and consumed by nothing. It is
#' recorded as drawn rather than as `NA`, so the two seed columns read the
#' same on every result. Fold `i` is exactly [tune::last_fit()] of `object`
#' on `resamples$splits[[i]]` under `res$.outer_fit_seed[[i]]`, with no
#' tuning line before it. The seed is applied as the grid page shows.
#'
#' @section Differences from calling tune directly:
#'
#' There is no `control` formal. A [tune::control_resamples()] passed
#' through `...` as `control` is recorded, and two of its slots reach the
#' outer fit. What is recorded is the control passed, or tune's default
#' when none is, with the slots this package forces overwritten, as
#' `extract_procedure(res)$control`. tune gives `control_resamples()`,
#' [tune::control_grid()] and [tune::control_last_fit()] one class, so any
#' of the three is accepted here as the same object.
#'
#' Every slot of `control_resamples()` falls under one of seven headings,
#' most under the last. The one tune call a fold makes here is the outer
#' scoring fit, whose own control this package builds.
#'
#' **Forced: `allow_par`.** The outer fit runs at `allow_par = FALSE`
#' whatever the control carries, since parallelism belongs over the outer
#' folds.
#'
#' **Settable as its own argument: `event_level`.** The argument is the one
#' place the level is set. A control at tune's default takes it. A control
#' naming another level is refused at entry, and the refusal names both
#' levels. `eval_time` is offered the same way, for the same reason.
#'
#' **Refused: none.** No slot is refused on its own. A control of another
#' class, such as a `control_bayes()`, is refused at entry, as is the
#' `event_level` conflict above.
#'
#' **Passed through: none.** There is no inner tuning call for a slot to be
#' passed through to.
#'
#' **Kept from the outer fit: `save_pred`, `extract`.** With
#' `save_pred = TRUE` the result carries a `.predictions` list column: each
#' completed fold's predictions on its assessment rows, as
#' [tune::last_fit()] returns them. With `extract` a function, it carries
#' an `.extracts` list column holding the function's value on each
#' completed fold's fitted workflow. Here there is no inner run whose
#' predictions and extracts are discarded. The outer fit's are the only
#' ones, and they are still discarded on a run that did not ask.
#'
#' **Not returned: none.** Nothing an inner run would have saved exists to be
#' withheld.
#'
#' **Inert: `verbose`, `pkgs`, `save_workflow`, `parallel_over`,
#' `backend_options`, `workflow_size`.** Each governs an inner tuning call
#' this function never makes. The outer fit runs
#' under [tune::control_last_fit()] at the level and parallelism above,
#' which reads none of these. The workflow's packages are required at
#' entry, and the fitted workflow is reached through `extract`.
#'
#' @template example-setup
#' @examplesIf rlang::is_installed(c("recipes", "yardstick"))
#' # A fixed workflow: no tune() marker anywhere.
#' fixed <- workflows::workflow(mpg ~ ., parsnip::linear_reg())
#'
#' set.seed(2)
#' res <- nested_fit_resamples(fixed, folds)
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
