#' Nested cross-validation with a grid search inside
#'
#' @description
#' `nested_tune_grid()` gives you an honest score for a model you tune with
#' [tune::tune_grid()]. It runs the outer loop of nested cross-validation.
#' For each outer fold it tunes on that fold's inner resamples and selects a
#' candidate, one row of the grid, by the rule `select` names. It finalizes
#' the workflow with that candidate, fits it on the fold's analysis rows,
#' and scores it on the assessment rows with [tune::last_fit()]. Every step
#' is tune's; what this function adds is the loop, the seeds, and a result
#' that keeps what each fold chose.
#'
#' Tune, select, fit and score, taken together, are the procedure this
#' function scores. The estimate [collect_metrics()] returns describes that
#' whole procedure, not any one fitted model, and it is the number to
#' report. No model is returned here. [nested_final_fit()] builds the model
#' to deploy by running the recorded procedure once more on all the data,
#' and that model has no performance number of its own.
#'
#' @details
#' The same outer loop runs with other searches inside. Four siblings run
#' it with another search:
#' [nested_tune_bayes()], [nested_tune_race_anova()],
#' [nested_tune_race_win_loss()] and [nested_tune_sim_anneal()]. A fifth,
#' [nested_fit_resamples()], runs it for a workflow with nothing to tune.
#' With this function they are the package's orchestrators: each runs the
#' outer loop and hands the inner tuning to tune or finetune. Their pages
#' say what differs; this page is the reference for what the six share.
#'
#' @inheritParams tune::tune_grid
#' @param object A [workflows::workflow()] with at least one parameter marked
#'   for tuning with [tune::tune()]. A workflow with no marker is refused;
#'   [nested_fit_resamples()] scores one on the same design.
#' @param resamples A nested resampling design from [nested_resamples()] or
#'   [rsample::nested_cv()], one row per outer fold. The section on nested
#'   designs says what the design must hold.
#' @param ... A control object from [tune::control_grid()], passed as
#'   `control`, and nothing else; every argument after `...` is matched by
#'   name. The section on differences from tune says what becomes of each
#'   control slot.
#' @param param_info A [dials::parameters()] object, or `NULL` to let tune
#'   derive one from the workflow. The section on finalizing a parameter
#'   range says where a range that depends on the data is finalized.
#' @param grid A data frame of candidate parameter values, or a positive whole
#'   number for the size of a grid tune generates. A data frame has one
#'   column per tuned parameter and no other column.
#' @param event_level `"first"` (the default) or `"second"`, naming which
#'   level of a two-class outcome is the event. It applies to the inner
#'   tuning run and the outer scoring fit alike.
#' @param eval_time A numeric vector of evaluation times for a censored
#'   regression model, or `NULL` (the default) to leave the choice to tune.
#'   The section on evaluation times says what this package refuses.
#' @param select A [selection_rule()] naming which of tune's selectors each
#'   outer fold picks its candidate with, on its own inner run and the first
#'   metric. The default is [tune::select_best()].
#'
#' @return A tibble of class `nested_results` with one row per outer fold.
#'   Beside the fold's split and labels, each row holds:
#'
#'   - `.metrics`, the metrics scored on the fold's assessment set;
#'   - `.selected`, the candidate the fold's inner tuning chose;
#'   - `.inner_metrics`, the inner run's own metrics;
#'   - `.completed`, whether the fold finished, and `.notes`, what went
#'     wrong;
#'   - `.tuning_seed` and `.outer_fit_seed`, the two seeds that reproduce
#'     it.
#'
#'   [collect_metrics()] summarizes the result. `summary()`,
#'   [collect_selections()], [agreement()] and
#'   [autoplot()][autoplot.nested_results] read it in other ways.
#'
#' @section Nested designs:
#'
#' `resamples` is a data frame with one row per outer fold. Its `splits`
#' column holds that fold's `rsplit`, its `inner_resamples` column holds an
#' `rset` with at least one row, and every other column labels the fold. A
#' label column is named `id`, or `id` followed by a digit from 1 to 9, and
#' holds character or factor values. Together the label columns give every
#' outer fold a distinct label with no `NA`.
#'
#' Inside each inner `rset`, every element of `splits` is an `rsplit`. All
#' of a fold's inner splits carry one data frame: either the outer split's
#' own frame, as [nested_resamples()] builds, or that split's analysis set,
#' as [rsample::nested_cv()] builds. An inner split carrying the outer frame
#' may index only rows the outer split's `in_id` holds, in its `in_id` and
#' any non-`NA` `out_id`. So no inner analysis or assessment set reaches a
#' row the outer fold holds out.
#'
#' A design breaking any of this, or using a bootstrap for the outer loop, is
#' refused before anything is fitted. The error has condition class
#' `nestedtune_bad_design` and names every offending row, column, inner
#' split or index. The checks exist because [rsample::nested_cv()] builds a
#' design whatever its `inside` argument returned, and because a design
#' assembled by hand can index rows its outer fold never sees.
#'
#' @section Finalizing a parameter range:
#'
#' `param_info` is passed unchanged to the inner tuning call on every outer
#' fold, so a restricted range restricts what every fold searches. Some
#' ranges are unknown until the data is seen: `mtry()`, or a `min_n()`
#' finalized by row count. tune finalizes such a range on the outer fold's
#' analysis rows, never on the rows that fold holds out. On a
#' [nested_resamples()] design the inner call therefore receives the fold's
#' inner resamples re-pointed at its analysis set, not the design's own
#' `inner_resamples` element, which indexes the whole data. A design from
#' [rsample::nested_cv()] already carries the analysis set and is passed as
#' it is. So is the design's element under an outer split that repeats a
#' row, an evaluated [rsample::manual_rset()], where the re-pointing is
#' ambiguous. [nested_final_fit()] finalizes on the full data.
#'
#' @section Evaluation times:
#'
#' `eval_time` reaches every tune call whose answer depends on it. So a
#' dynamic or integrated survival metric, `brier_survival()`,
#' `roc_auc_survival()` and their relatives, is measured at the times you
#' name. When the metric set has no metric that reads it, tune ignores it
#' with a warning; tune keys that warning on the metrics, not on the
#' model's mode.
#'
#' Refused here, ahead of tune: anything that is not numeric, an empty
#' vector, and any element that is missing, negative or not finite. tune
#' treats those unevenly, and only once a metric reads the
#' times, so they are refused at entry, before a whole run is paid for.
#' Zero, repeated times and times out of order are accepted and passed on
#' untouched, since tune normalizes those itself. A repeated time draws
#' tune's warning that 0 inappropriate evaluation time points were removed,
#' once per tune call.
#'
#' The selection rule is applied without `eval_time`. Left unset, it
#' selects at the first of the evaluation times the tuning run was built
#' with, which are the ones named here. Passing them again would change no
#' choice, and would repeat tune's message about which time it took.
#'
#' @section Selecting a candidate:
#'
#' tune leaves the choice of candidate to a call you make on the tuning
#' result. Here the choice is made inside every fold, so the rule is an
#' argument. `select` takes what [selection_rule()] returns:
#' [tune::select_best()] by default, or [tune::select_by_one_std_err()] or
#' [tune::select_by_pct_loss()] with the orderings and limit the rule
#' carries. Each fold applies the rule to its own inner run, with `metric`
#' the first metric in `metrics`. Every name an ordering uses must be a
#' parameter `object` tunes, and anything but a `selection_rule()` is
#' refused at entry. The result records the rule as
#' `extract_procedure(res)$select`, and [nested_final_fit()] selects by it
#' too.
#'
#' @section What the result records:
#'
#' Two records describe the grid, and they answer different questions.
#' `attr(x, "grid")` holds the `grid` argument as it was given: a positive
#' whole number, not a table of candidates, whenever a size was passed. The
#' `.inner_metrics` column holds what each outer fold's inner tuning
#' scored, [tune::collect_metrics()] of that fold's tuning run, one table
#' per fold. Each table has a column per tuned parameter and one row per
#' candidate and metric. Beside them sit the summary columns
#' [tune::collect_metrics()] writes, with `.eval_time` among them when a
#' dynamic survival metric was scored. The candidates a fold searched are
#' the table's distinct parameter rows.
#'
#' The two diverge routinely. tune expands a size and may reach fewer
#' candidates than were asked for: a request for 20 on a parameter with
#' four reachable values evaluates four. A candidate that fails scores
#' nothing. Folds can also differ from each other. Expanding a size draws
#' from the generator, and each fold tunes under its own seed, so a
#' continuous parameter gives every fold its own candidates. Printing says
#' so when it happens. A candidate that failed on every inner resample has
#' no row in `.inner_metrics`; `.notes` is where its failure is recorded. A
#' fold that scored no candidate at all carries a zero-row table with a
#' completed fold's columns, never `NULL`.
#'
#' `attr(x, "metrics")` holds the `metrics` argument, and is absent when
#' none was supplied.
#'
#' The `procedure` record, which [extract_procedure()]
#' returns, names the tuner (`"tune_grid"` here) and that tuner's own
#' arguments (`grid` here). It also holds `param_info`, `event_level`,
#' `eval_time`, `select` and the effective control, on the result of every
#' orchestrator.
#'
#' @section Operations on the result:
#'
#' You can reorder rows and add or reorder columns, and the result stays a
#' `nested_results`. Those are the rules tune states for its own results
#' objects. Rows are never added or removed. Every column named under Value
#' must still be present, holding the values it held.
#'
#' The fold-label columns are the ones the resampling design named, and
#' `nested_tune_grid()` records them when it builds the result. So a column
#' you add afterwards is read as a fold label only when the design itself
#' carries a column of that name: `id`, and `id2` for a repeated design.
#' Adding `id2` to a result from a plain v-fold design leaves the class,
#' the record and the fold labels alone, exactly as adding `extra` does.
#'
#' An operation that stays inside those rules returns a `nested_results`
#' with the call's record intact: `arrange()`, `mutate()` adding a column,
#' a join that matches one row apiece. Anything else returns a bare tibble,
#' with the record removed along with the class: `slice()`, a `filter()`
#' that drops a fold, `bind_rows()`, `x[1, ]`, dropping one of the columns
#' above. A three-row object cannot describe itself as the ten-fold design
#' it was cut from, so it stops describing itself and hands back the data.
#'
#' One rule covers every verb that subsets or combines a result. dplyr's
#' verbs and `[` reach it through a `dplyr_reconstruct()` method. vctrs'
#' own verbs, `vec_slice()`, `vec_rbind()`, `vec_c()` and the others, reach
#' it through `vec_restore()`. And `rbind()` and `rename()`, which reach
#' neither generic, have methods of their own. Two cases differ.
#' `vctrs::vec_rbind(x)` and `vctrs::vec_c(x)` hand back a bare tibble even
#' with nothing to combine with, where `dplyr::bind_rows(x)` keeps the
#' class. And `bind_cols()` and `vec_cbind()` build their answer on the
#' first argument's type. So `bind_cols(x, extra)` keeps the class while
#' `bind_cols(extra, x)` is a plain tibble holding the same columns.
#' `group_by()`, `rowwise()` and `tibble::as_tibble()` return a grouped, a
#' rowwise and a plain tibble, each still carrying the attributes.
#'
#' @template section-reproducibility
#'
#' @section Reproducing one fold by hand:
#'
#' Fold `i` is exactly the code below. On a [nested_resamples()] design,
#' `resamples$inner_resamples[[i]]` stands for that inner rset re-pointed at
#' `analysis(resamples$splits[[i]])`, as the section on finalizing a
#' parameter range describes. Under a `select` other than the default, the
#' selection line is [tune::select_by_one_std_err()] or
#' [tune::select_by_pct_loss()] with the rule's orderings and limit.
#'
#' ```
#' set.seed(res$.tuning_seed[[i]], kind = "Mersenne-Twister",
#'          normal.kind = "Inversion", sample.kind = "Rejection")
#' tuned <- tune_grid(object, resamples$inner_resamples[[i]], grid = grid,
#'                    param_info = param_info, metrics = metrics,
#'                    eval_time = eval_time,
#'                    control = extract_procedure(res)$control)
#' final <- finalize_workflow(object, select_best(tuned, metric = <first metric>))
#' set.seed(res$.outer_fit_seed[[i]], kind = "Mersenne-Twister",
#'          normal.kind = "Inversion", sample.kind = "Rejection")
#' last_fit(final, resamples$splits[[i]], metrics = metrics,
#'          eval_time = eval_time,
#'          control = control_last_fit(event_level = event_level))
#' ```
#'
#' The siblings differ only in the tuning line. [tune::tune_bayes()] takes
#' `iter`, `initial` and `objective`, and finetune's racers take `grid`.
#' [finetune::tune_sim_anneal()] takes `iter` and `initial`; each runs with
#' the recorded control. [nested_fit_resamples()] has no tuning line at all.
#' A Bayesian fold also gives that control the fold's tuning seed before the
#' call, `control$seed <- res$.tuning_seed[[i]]`. [tune::control_bayes()]
#' otherwise draws the seed for its Gaussian process proposals from the
#' stream, and the recorded control carries none.
#'
#' @section When a fold fails:
#'
#' A fold that fails does not end the run. The remaining folds still run,
#' and the failed fold is recorded rather than discarded. Its `.completed`
#' is `FALSE` and its `.notes` holds what went wrong, in the shape tune
#' uses. That is one row naming the stage that failed, `"inner tuning"` or
#' `"outer fit"`, followed by tune's own notes about the cause. The number
#' of folds attempted and the number completed are stored as the
#' `folds_attempted` and `folds_completed` attributes.
#'
#' Both stages can fail quietly. Inner tuning raises only once every
#' candidate has failed, and the outer fit does not raise at all: it hands
#' back a result with no metrics. Both are recorded as failures here. A fold
#' can also complete and carry notes. When only some of a fold's inner
#' resamples fail, tuning still returns a candidate and the fold finishes.
#' It finished on less of the inner design than was asked for, and the
#' notes say so.
#'
#' A failed fold still records the candidates it got as far as scoring. A
#' fold that died at the outer fit had already tuned, so its
#' `.inner_metrics` holds the full table. Only a fold that never reached a
#' scored candidate holds a zero-row table. No fold is reported as having
#' searched a grid it did not.
#'
#' The run warns when it finishes with any fold unfinished.
#' [collect_metrics()] warns again, summarizing only the folds that ran and
#' reporting how many those were. It refuses outright when no fold
#' completed: an estimate is never reported for a design that did not
#' execute.
#'
#' @section Parallel execution:
#'
#' The outer folds run in parallel when you have started mirai daemons, and
#' serially otherwise. There is no argument for this: start daemons before
#' the call and the loop uses them.
#'
#' ```
#' mirai::daemons(4)
#' res <- nested_tune_grid(wf, folds, grid = grid)
#' mirai::daemons(0)
#' ```
#'
#' Two or more daemons are needed before the loop dispatches; below that it
#' stays serial, the threshold tune applies. Inner tuning always runs
#' serially whatever you set, because nested parallelism oversubscribes
#' cores. Results do not depend on how the loop ran. Each fold's seeds are
#' drawn up front and assigned by position, so the same seed gives the same
#' result serially and in parallel. The one difference carries no numbers:
#' a fold that failed on a daemon records that daemon's call stack in
#' `.notes` rather than yours.
#'
#' Each fold is sent one copy of the data, not one per inner split. A
#' resampling split carries the whole frame it indexes, and serializing a
#' fold for a daemon would not preserve the single copy the design shares.
#' So each fold's splits are emptied before dispatch and refilled on the
#' worker. On a [nested_resamples()] design that is one copy per fold. A
#' design from [rsample::nested_cv()] holds an analysis frame per outer
#' fold, so each fold also carries its own, still once rather than once per
#' inner split.
#'
#' A recipe keeps a copy of the data it was created with, and
#' a formula carries the environment it was written in. So a workflow built
#' inside a function that holds a large object sends that object with every
#' fold; building the workflow at the top level avoids that.
#'
#' Daemons are separate R processes, which has consequences worth knowing:
#'
#' - They do not inherit your session's options, `.libPaths()` changes, or
#'   environment variables you set after launching them. Set what a fold
#'   needs with [mirai::everywhere()], or start the daemons after setting it.
#' - They load nestedtune from an installed library. Under
#'   `devtools::load_all()` the daemons cannot see it, and the call stops
#'   rather than failing every fold with the same note. During development,
#'   prime them with `mirai::everywhere(pkgload::load_all("<path>"))`.
#' - Before dispatching, the call checks every connected daemon. It asks
#'   whether the daemon can load this package and each package the workflow
#'   and the tuner need. It also asks whether the daemon's copy defines each
#'   internal function this session's copy defines. If any daemon cannot,
#'   the call stops, naming how many are affected and what is missing. A
#'   daemon holding an older install loads the package and then fails every
#'   fold. The remedy is to reinstall and restart the pool, since a running
#'   daemon keeps the namespace it has already loaded.
#' - A daemon that does not answer is reported as a non-response, not as a
#'   missing package. The check waits 30 seconds by default; set
#'   `options(nestedtune.preflight_timeout = <milliseconds>)` to a single
#'   positive, finite number to change that. The first parallel call after
#'   starting daemons is the slow one, because the check makes every daemon
#'   load the tidymodels stack; later calls reuse what they loaded.
#' - That check is bounded; the folds themselves are not. If every daemon
#'   dies after folds are dispatched, the call blocks waiting for results
#'   that never arrive, and you interrupt it. No per-fold timeout is imposed,
#'   because a slow fold and a dead one would be indistinguishable.
#'
#' A fold whose worker dies is recorded as a failed fold, like any other
#' failure. The run finishes, the other folds keep their results, and
#' `.notes` names the worker as the stage. Calling `mirai::daemons(0)` while
#' folds are outstanding produces exactly what a daemon dying mid-fold
#' produces, so it is recorded as fold failures rather than as a
#' cancellation.
#'
#' Stopping a run is not a fold failure. Stopping the dispatched tasks
#' aborts the call and returns nothing, raising a `nestedtune_cancelled`
#' condition. That class inherits from `nestedtune_interrupted`, the class a
#' task interrupted on its own daemon raises. An interrupt at your own
#' console unwinds the blocking wait before any worker's value is
#' classified, so an ordinary interrupt propagates with no nestedtune class
#' attached. Either way the caller's RNG state is restored. The outstanding
#' folds are cancelled on the way out, so the pool goes idle rather than
#' computing folds nobody will read.
#'
#' Cancelling needs mirai's dispatcher,
#' which `mirai::daemons(n)` starts by default. A pool started with
#' `dispatcher = FALSE` cannot be stopped this way, and you are told so at
#' dispatch by a warning of class `nestedtune_pool_not_cancellable`, once
#' per call. Stopping is a request rather than a guarantee: a fold inside a
#' compiled fitting routine may not be interruptible, and one that has
#' nearly finished may simply finish.
#'
#' @section Differences from calling tune directly:
#'
#' There is no `control` formal. A [tune::control_grid()] passed through
#' `...` as `control` reaches the inner `tune_grid()` in every fold, and the
#' final fit that re-runs the result. What runs is the control passed, or
#' tune's default when none is, with the slots this package forces
#' overwritten. The result records that effective control as
#' `extract_procedure(res)$control`. Every slot of `control_grid()` falls
#' under one of seven headings.
#'
#' **Forced: `allow_par`.** Both tune calls a fold makes, the inner tuning
#' run and the outer scoring fit, run at `allow_par = FALSE`, whatever the
#' control carries. Parallelism belongs over the outer folds, as above, and
#' leaving it to a caller would put two pools in contention.
#'
#' **Settable as its own argument: `event_level`.** The argument reaches
#' the inner `control_grid()` and the outer `control_last_fit()` alike, and
#' is the one place the level is set. A control left at tune's default takes
#' the argument's level. A control naming a level that is neither tune's
#' default nor the argument's is refused at entry, naming both. `eval_time`
#' is offered the same way, for the same reason: it changes a number the
#' caller is shown. It is an argument of `tune_grid()` and `last_fit()`
#' rather than a control slot.
#'
#' **Refused: none.** No slot is refused on its own. What is refused at
#' entry is a control of another class, such as a `control_bayes()` that
#' tune itself would accept here, and the `event_level` conflict above.
#' tune gives [tune::control_resamples()] and [tune::control_last_fit()]
#' the `control_grid` class, so either is accepted as what `control_grid()`
#' returns, its slots read under these headings.
#'
#' **Passed through: `verbose`, `pkgs`, `parallel_over`, `workflow_size`.**
#' Each reaches `tune_grid()` as given. `verbose` prints from a serial run,
#' beside the progress the outer loop reports, and from a mirai daemon
#' where nothing shows it. `pkgs` is required before fitting on the serial
#' path as on the parallel one. `parallel_over` is not inert at
#' `allow_par = FALSE`. It still chooses how tune loops over resamples and
#' candidates, and with it the seed each model fit starts from. So a
#' stochastic engine's numbers differ between `"resamples"` and
#' `"everything"`. `workflow_size` is the size past which tune remarks on a
#' workflow `save_workflow` keeps.
#'
#' **Kept from the outer fit: `save_pred`, `extract`.** Each reaches the
#' outer scoring fit as well as the inner run. With `save_pred = TRUE` the
#' result carries a `.predictions` list column: each completed fold's
#' predictions on its assessment rows, as [tune::last_fit()] returns them.
#' With `extract` a function, it carries an `.extracts` list column: the
#' function's value on each completed fold's fitted workflow. A failed fold
#' holds `NULL` in each. A fold whose extract errored stays completed with
#' `NULL` there and a note at location `"outer extract"`.
#' [`collect_predictions()`][collect_predictions.nested_results] and
#' [`collect_extracts()`][collect_predictions.nested_results] stack the two
#' columns with the fold labels. What is kept is the outer fit's; the inner
#' run's predictions and extracts are still discarded with that run.
#'
#' **Not returned: `save_workflow`.** It lands on the inner `tune_results`,
#' which a fold record discards once the fold succeeds. So on a nested run
#' setting it costs the work and returns nothing; `extract = function(x) x`
#' keeps a fold's fitted workflow instead. [nested_final_fit()] keeps its
#' own tuning run as `$tuning`, where [extract_tune_results()] reaches what
#' it saved.
#'
#' **Inert: `backend_options`.** Options for a parallel backend, with no
#' backend to reach at `allow_par = FALSE`.
#'
#' @template example-setup
#' @template example-run
#' @examplesIf rlang::is_installed(c("recipes", "yardstick"))
#' collect_metrics(res)
#'
#' # What each fold chose. Disagreement here is selection instability, and
#' # it is information, not noise.
#' res$.selected
#'
#' @seealso [nested_tune_bayes()], [nested_resamples()], [nested_final_fit()],
#'   [tune::tune_grid()]
#' @export
nested_tune_grid <- function(
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
  control <- check_dots_control(capture_dots(...))
  check_workflow(object)
  check_untuned_workflow(object)
  check_nested(resamples)
  check_grid(grid)
  check_grid_params(object, grid)
  check_metrics(metrics)
  check_param_info(param_info)
  check_event_level(event_level)
  check_eval_time(eval_time)
  check_selection_rule(select, object)
  control <- check_control(control, "tune_grid", event_level)

  nested_loop(
    object,
    resamples,
    tuner = tuner_grid(grid),
    metrics = metrics,
    param_info = param_info,
    event_level = event_level,
    eval_time = eval_time,
    select = select,
    control = control,
    grid = grid,
    call = rlang::current_env()
  )
}

# The outer loop, shared by both orchestrators (D-040): what differs between
# them is the tuner description and the entry checks, and both of those are
# settled before this is reached. Every argument has been forced by the
# caller's `check_*()` calls, so the RNG snapshot below is taken after the
# caller's own evaluation is complete and nothing lazy can draw inside it. The
# one argument whose evaluation may draw and whose draw is thrown away -- an
# inline `control_bayes()` -- is forced under `capture_dots()`'s own
# snapshot, so its draw is undone before this one is taken.
#
# `call` is the orchestrator's frame, so the run's warnings and the daemon
# pre-flight's refusals name the function the user called rather than this one.
# `control` is the effective control `check_control()` returned, shared by
# every fold and recorded as it is. `grid` is recorded on the object as it was
# given, for the grid path alone; the Bayesian path passes NULL and carries no
# such attribute.
nested_loop <- function(
  object,
  resamples,
  tuner,
  metrics,
  param_info,
  event_level,
  eval_time,
  select,
  control,
  grid,
  call
) {
  n <- nrow(resamples)

  # Snapshot before drawing, so what is restored is the caller's state on
  # entry rather than its state after our own draw. `.Random.seed` does not
  # exist until something draws, so a fresh session has nothing to snapshot;
  # sample.int() below initializes it, and we leave that valid state alone.
  had_seed <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  old_kind <- RNGkind()
  old_seed <- if (had_seed) get(".Random.seed", envir = globalenv())
  on.exit(restore_rng(had_seed, old_kind, old_seed), add = TRUE)

  seeds <- sample.int(.Machine$integer.max, 2L * n)

  # One self-contained payload per fold. Each carries only what that fold needs,
  # so a worker is never sent the rest of the design.
  payloads <- lapply(seq_len(n), function(i) {
    list(
      split = resamples$splits[[i]],
      inner = resamples$inner_resamples[[i]],
      seeds = seeds[c(2L * i - 1L, 2L * i)]
    )
  })

  folds <- dispatch_folds(
    payloads,
    object = object,
    tuner = tuner,
    metrics = metrics,
    param_info = param_info,
    event_level = event_level,
    eval_time = eval_time,
    select = select,
    control = control,
    call = call
  )

  procedure <- new_procedure(
    tuner,
    param_info = param_info,
    event_level = event_level,
    eval_time = eval_time,
    select = select,
    control = control,
    workflow = workflow_identity(object)
  )
  out <- new_nested_results(resamples, folds, seeds, grid, metrics, procedure)
  warn_failed_folds(out, call = call)
  out
}

# One outer fold, start to finish.
#
# Everything this needs is an argument: the split, the inner resamples, the two
# seeds, the tuner description and the static inputs. Nothing is read from the
# enclosing loop and
# nothing is drawn here, so the fold's result depends on its position in the
# design and not on when or where it runs -- which is what makes the loop safe
# to reorder or, later, to parallelize (IP2).
nested_fold_fit <- function(
  split,
  inner,
  seeds,
  object,
  tuner,
  metrics,
  param_info = NULL,
  event_level = "first",
  eval_time = NULL,
  select = selection_rule(),
  control = NULL
) {
  # The zero-row inner table a fold that scores nothing records (M49). Built
  # here, before anything can fail, from the workflow rather than from a run:
  # a fold whose tuning raised has no run to read columns off, and one whose
  # every candidate failed has a run `collect_metrics()` raises on (M03).
  prototype <- empty_inner_metrics(object, tuner, metrics, param_info)

  # `tuned` is assigned inside the tryCatch expression, which evaluates in this
  # frame -- so when select_best() is what errors, tune's own notes explaining
  # why every model failed are still in hand to record.
  tuned <- NULL
  # A tuner that selects nothing (M70, `tuner_selects()`) skips the inner
  # stage whole: no framed inner rset, no tuner call, no rule. The fold's
  # tuning seed was drawn with the others so the record keeps one layout, and
  # is consumed by nothing here; the outer fit below runs under the second
  # seed as on every other path. `selected` is the zero-row, zero-column
  # table `empty_candidates()` builds, so `.selected` holds a table on every
  # completed fold and NULL on a failed one, as it does for the five.
  selected <- if (!tuner_selects(tuner$tuner)) {
    empty_candidates()
  } else {
    set_fold_seed(seeds[[1L]])
    tryCatch(
      {
        # The inner rset tune reads is framed on this fold's analysis rows
        # (M54): tune finalizes an unknown parameter range on the frame the
        # first inner split carries, and a `nested_resamples()` design's
        # splits carry the whole data. Inside the seed's scope so the fold
        # stays reproducible from its seeds alone; it draws nothing.
        framed <- analysis_framed_inner(inner, split)
        # The tuner's own call -- `tune_grid()` or `tune_bayes()` -- assembled
        # from the description the orchestrator built (R/tuner.R). The fold's
        # tuning seed goes in with it, because `control_bayes()` is seeded from
        # it and has to be built inside this seed's scope.
        tuned <- run_tuner(
          tuner,
          object = object,
          resamples = framed,
          param_info = param_info,
          metrics = metrics,
          eval_time = eval_time,
          event_level = event_level,
          control = control,
          seed = seeds[[1L]]
        )
        # Resolved from the tuned object rather than from `metrics`, so the same
        # code answers whether the caller supplied a metric set or let tune pick.
        metric_name <- tune::.get_tune_metric_names(tuned)[[1L]]
        # The recorded rule (M69), one of tune's three selectors behind
        # `apply_selection_rule()` (R/selection-rule.R). `eval_time` is
        # deliberately not passed on (D-038). Left NULL,
        # `tune:::choose_eval_time()` reads the evaluation times off `tuned` --
        # which are the ones this run was tuned at, because the argument reached
        # `tune_grid()` above -- and `tune:::first_eval_time()` takes element one
        # of them, the same element passing the argument would name. Selection is
        # therefore identical either way, and passing it would repeat tune's
        # "First evaluation time" message once per fold.
        apply_selection_rule(tuned, select, metric_name)
      },
      error = function(cnd) cnd
    )
  }
  if (inherits(selected, "condition")) {
    return(failed_fold(
      "inner tuning",
      selected,
      tuned,
      tuned = tuned,
      prototype = prototype
    ))
  }

  # Finalizing and seeding sit inside the guard rather than between the two
  # guarded regions. An error anywhere between selection and the fit is still
  # this fold's failure, and leaving them outside left a path that could abort
  # the whole run -- the one outcome this function exists to prevent.
  fitted <- tryCatch(
    {
      # Nothing to finalize where nothing was selected: the workflow runs as
      # given, its parameters already fixed (M70).
      final_wf <- if (tuner_selects(tuner$tuner)) {
        tune::finalize_workflow(object, selected)
      } else {
        object
      }
      set_fold_seed(seeds[[2L]])
      # The outer fit had no control object at all until M35, so its metrics
      # were computed at tune's default event level whatever the inner run had
      # been told -- the one place the setting had to reach for a reported
      # number to move. `allow_par = FALSE` is stated rather than left to
      # tune, whose `control_last_fit()` defaults it off today: the outer fit
      # runs inside a mirai daemon on the parallel path, and "keep tune serial
      # within the outer loop" is this package's convention to hold, not an
      # upstream default's to keep.
      tune::last_fit(
        final_wf,
        split = split,
        metrics = metrics,
        eval_time = eval_time,
        control = tune::control_last_fit(
          event_level = event_level,
          allow_par = FALSE
        )
      )
    },
    error = function(cnd) cnd
  )
  if (inherits(fitted, "condition")) {
    return(failed_fold(
      "outer fit",
      fitted,
      NULL,
      tuned = tuned,
      prototype = prototype
    ))
  }

  # last_fit() does not raise when the fit fails: it returns NULL metrics and
  # files the reason in its notes. Catching only thrown errors would record
  # this fold as a success carrying nothing.
  fold_metrics <- tryCatch(
    tune::collect_metrics(fitted),
    error = function(cnd) NULL
  )
  if (is.null(fold_metrics) || nrow(fold_metrics) == 0L) {
    return(failed_fold(
      "outer fit",
      NULL,
      fitted,
      tuned = tuned,
      prototype = prototype
    ))
  }

  # The outer fit's assessment-set predictions, kept when the control asks
  # (M68). `last_fit()` always computes them, so `save_pred` decides only
  # whether the fold record carries them home: on a daemon the table travels
  # back with the fold, and a caller who did not ask pays neither the wire
  # nor the object for it (GP4). The inner run's predictions, which the same
  # slot saves on `tuned`, are discarded with that run as before. Read
  # through `[[` on the column so a result lacking it gives NULL rather than
  # an error: `control_last_fit()` forces `save_pred`, so the column is
  # there today, and this fold's estimate does not depend on it staying so.
  predictions <- if (isTRUE(control$save_pred)) {
    fitted[[".predictions"]][[1L]]
  }

  # The control's `extract`, applied to the outer fit's workflow after the
  # fit rather than passed to `control_last_fit()`: tune moves its own
  # identity extract into `.workflow` there, and a caller's function in that
  # slot would replace the workflow (M68). An extract that errors is a
  # reporting failure and not a fold failure (IP4): the fold keeps its
  # metrics, its element is NULL, and the error is a note under its own
  # stage, so a NULL is never read as a value without the notes saying why.
  extracts <- NULL
  extract_notes <- empty_notes()
  if (is.function(control$extract)) {
    extracts <- tryCatch(
      control$extract(fitted[[".workflow"]][[1L]]),
      error = function(cnd) {
        extract_notes <<- own_note("outer extract", conditionMessage(cnd))
        NULL
      }
    )
  }

  # A fold can complete and still have had trouble: tune_grid() returns a usable
  # result when only some inner splits fail, and select_best() then chooses from
  # the survivors. Discarding those notes would report a selection made on a
  # truncated inner design as though the whole design had run (IP4), and would
  # drop notes tune itself kept (GP1).
  list(
    completed = TRUE,
    metrics = fold_metrics,
    selected = selected,
    inner_metrics = inner_metrics(tuned, prototype),
    predictions = predictions,
    extracts = extracts,
    notes = bind_notes(
      bind_notes(
        tune_notes(tuned, "inner tuning"),
        tune_notes(fitted, "outer fit")
      ),
      extract_notes
    )
  )
}

# The inner run's metrics, as tune summarizes them (M49, IP4).
#
# `tune::collect_metrics()` of the tuning run, verbatim: one row per candidate
# and metric, with the mean, the resample count `n` and its standard error,
# tune's `.config` label, and the `.iter` a Bayesian run scored it in. A
# candidate that scored on some inner resamples and failed on others is a row
# with `n` below the resample count; one that failed on every resample left no
# metric row anywhere and is absent -- present in the fold's notes instead.
#
# A run in which nothing scored gets the prototype rather than a call:
# `collect_metrics()` raises on such a run (the M03 lesson), and this runs
# inside the failure paths too, where `tuned` is whatever tune handed back
# before giving up and may be NULL. The tryCatch is insurance against a shape
# not thought of, on the same asymmetry M21 recorded: an empty table
# understates one fold, a raise discards every other fold's completed work.
inner_metrics <- function(tuned, prototype) {
  if (!scored_anything(tuned)) {
    return(prototype)
  }
  tryCatch(inner_metrics_table(tuned), error = function(cnd) prototype)
}

# The one `collect_metrics()` call behind every reader of an inner run (M50,
# D-043): tune's summary, and on a race every candidate the race scored --
# `all_configs = TRUE` -- where finetune's default keeps the survivors alone.
# IP4 records what ran, and an eliminated candidate ran on `n` resamples.
inner_metrics_table <- function(tuned) {
  if (inherits(tuned, "tune_race")) {
    return(tune::collect_metrics(tuned, all_configs = TRUE))
  }
  tune::collect_metrics(tuned)
}

# Whether at least one candidate scored on at least one inner resample, read
# off the per-resample metric frames a `tune_results` carries. Anything that
# is not that shape scored nothing.
scored_anything <- function(tuned) {
  metrics <- if (is.list(tuned)) tuned[[".metrics"]] else NULL
  is.list(metrics) &&
    any(vapply(
      metrics,
      function(m) is.data.frame(m) && nrow(m) > 0L,
      logical(1)
    ))
}

# The zero-row table a fold that scored nothing records: a completed fold's
# columns, name for name and type for type, so stacking the folds' tables
# never meets one whose columns differ. Each column is typed from what tune
# types it from. A parameter column takes the grid data frame's type when one
# was given -- tune passes a grid's columns through as typed, a double grid
# over an integer parameter scoring as double -- else the dials object
# `param_info` supplies, else the workflow's own; an engine parameter with no
# dials object reaches the last and is typed by the grid alone. The summary
# columns are the ones `collect_metrics()` writes; `.eval_time` is among them
# for a dynamic survival metric only -- an `eval_time` given beside a static
# or an integrated metric draws tune's warning and no column -- and `.iter`
# only on the iterating tuners, the registry's `iterates` (each measured
# 2026-09-02, tune 2.1.0; finetune 1.3.0 for `tune_sim_anneal()`).
empty_inner_metrics <- function(
  object,
  tuner,
  metrics = NULL,
  param_info = NULL
) {
  cols <- empty_param_columns(object, tuner, param_info)
  cols[[".metric"]] <- character(0)
  cols[[".estimator"]] <- character(0)
  if (has_dynamic_metric(object, metrics)) {
    cols[[".eval_time"]] <- numeric(0)
  }
  cols[["mean"]] <- numeric(0)
  cols[["n"]] <- integer(0)
  cols[["std_err"]] <- numeric(0)
  cols[[".config"]] <- character(0)
  if (!is.null(tuner) && tuner_iterates(tuner$tuner)) {
    cols[[".iter"]] <- integer(0)
  }
  new_tbl(cols)
}

# One zero-length column per tuned parameter, in the workflow's order. The
# workflow names the parameters; the grid data frame, then `param_info`, then
# the workflow's dials set type them.
empty_param_columns <- function(object, tuner, param_info) {
  params <- tryCatch(
    tune::extract_parameter_set_dials(object),
    error = function(cnd) NULL
  )
  # The grid, where the tuner takes one: the raced tuners' description holds
  # a `grid` exactly as `tune_grid()`'s does (R/tuner.R).
  grid <- if (!is.null(tuner) && tuner_takes_grid(tuner$tuner)) {
    tuner$args$grid
  }
  ids <- if (is.data.frame(params)) {
    params$id
  } else if (is.data.frame(grid)) {
    names(grid)
  } else {
    character(0)
  }
  cols <- list()
  for (id in ids) {
    cols[[id]] <- if (is.data.frame(grid) && id %in% names(grid)) {
      grid[[id]][0L]
    } else {
      dials_object <- param_object(id, param_info)
      if (is.null(dials_object)) {
        dials_object <- param_object(id, params)
      }
      empty_param_column(dials_object)
    }
  }
  cols
}

# The dials object a parameter set holds for `id`, or NULL: a set records a
# parameter with no object as a bare NA in its `object` column.
param_object <- function(id, params) {
  if (!is.data.frame(params) || !id %in% params$id) {
    return(NULL)
  }
  object <- params$object[[match(id, params$id)]]
  if (is.list(object)) object else NULL
}

# Whether the inner run's metrics table carries `.eval_time`: the metric set
# holds a dynamic survival metric, or none was given and the workflow's mode
# is censored regression, where tune's default is the dynamic Brier score
# (`tune:::check_metrics_arg()`, tune 2.1.0, read 2026-09-02) and every other
# mode's default is static.
has_dynamic_metric <- function(object, metrics) {
  if (is.null(metrics)) {
    mode <- tryCatch(
      workflows::extract_spec_parsnip(object)$mode,
      error = function(cnd) NULL
    )
    return(identical(mode, "censored regression"))
  }
  any(vapply(
    attr(metrics, "metrics"),
    inherits,
    logical(1),
    what = "dynamic_survival_metric"
  ))
}

empty_param_column <- function(param) {
  type <- if (is.list(param)) param[["type"]] else NULL
  switch(
    if (is.character(type) && length(type) == 1L) type else "",
    double = numeric(0),
    integer = integer(0),
    character = character(0),
    logical = logical(0),
    logical(0)
  )
}

# The candidates a tuning run actually scored (IP4's "the grid actually
# evaluated"), on the final fit's own run: the candidate set derived from its
# `collect_metrics()` table, the same derivation the fold readers apply to
# each fold's `.inner_metrics` (D-043).
#
# Total by construction, because of where it is called from: the accessor sits
# outside every tryCatch, so anything raised here would abort a call that has
# a fitted model to hand back. `collect_metrics()` raises on a run in which
# every candidate failed, and that run scored no candidate -- the empty record
# is the true answer, not a fallback.
scored_candidates <- function(tuned) {
  tryCatch(
    candidate_set(inner_metrics_table(tuned)),
    error = function(cnd) empty_candidates()
  )
}

# The candidate set a metrics table describes: one row per candidate scored,
# with a column per tuned parameter, tune's `.config` label and, on a Bayesian
# table, the `.iter` it was proposed in. Everything `collect_metrics()` adds
# per metric goes, and the rows are made distinct on `.config`, one label per
# candidate.
#
# Ordered by `.iter` first, so an iterating run's initial candidates come
# before the proposals and the proposals follow in the order they were made
# -- tune labels a Bayesian run's `iter1`, `iter2`, ... and finetune an
# annealing run's `Iter1`, `Iter2`, ..., neither padded, and the iteration
# number is what puts the tenth after the ninth -- then by the label, which
# tune zero-pads past nine candidates, so ordering it lexically is ordering
# it numerically. A grid table carries no `.iter`, and its order is the
# label's alone. The ordering never touches a parameter column: `order()` raises on a
# list-valued one, which is why `candidate_key()` in nested-results-print.R
# renders rows before ordering them (M21 review F1).
candidate_set <- function(metrics) {
  if (!is.data.frame(metrics)) {
    return(empty_candidates())
  }
  keep <- setdiff(
    names(metrics),
    c(".metric", ".estimator", ".eval_time", "mean", "n", "std_err")
  )
  if (length(keep) == 0L) {
    return(empty_candidates())
  }
  candidates <- as.data.frame(metrics)[, keep, drop = FALSE]

  # `.config` is one label per candidate, so it is the key. Falling back to the
  # parameter values themselves keeps this working on a shape that carries no
  # such column rather than returning every metric's row as a candidate.
  key <- if (".config" %in% keep) {
    candidates[[".config"]]
  } else {
    do.call(paste, c(unname(as.list(candidates)), list(sep = "\r")))
  }
  first <- !duplicated(key)
  kept <- candidates[first, , drop = FALSE]
  ordered <- if (".iter" %in% keep) {
    order(kept[[".iter"]], key[first])
  } else {
    order(key[first])
  }
  new_tbl(lapply(kept, function(col) col[ordered]))
}

# A candidate set holding nothing. Bare rather than typed: the final fit's
# run may have raised before recording a parameter name, and deriving names
# from the workflow would be machinery whose only job is to furnish an empty
# record (M21 plan gate).
empty_candidates <- function() {
  structure(
    list(),
    names = character(0),
    class = c("tbl_df", "tbl", "data.frame"),
    row.names = integer(0)
  )
}

# A fold that did not finish. `result` is whatever tune handed back before
# giving up, which is where the actual cause lives -- our own note names the
# stage, tune's notes say what happened (GP1).
#
# `tuned` is separate from `result` because on the outer-fit path they are
# different objects -- `result` is the last_fit() result whose notes explain the
# failure, while the tuning run that chose the candidate is still in hand. A
# fold that failed there DID evaluate a grid, and recording it as having
# evaluated none would be the same IP4 error in the other direction.
# `prototype` is the zero-row inner table for a fold that scored nothing; the
# default is for the worker-failure path, which has no workflow in hand.
failed_fold <- function(
  stage,
  cnd,
  result,
  message = NULL,
  tuned = NULL,
  prototype = empty_inner_metrics(NULL, NULL)
) {
  # `message` is supplied only by the worker-failure path, where there is no
  # condition to read: mirai's failure values are not conditions and one of them
  # raises on conditionMessage() (M07-D2).
  if (is.null(message)) {
    message <- if (is.null(cnd)) {
      "The outer fit produced no metrics."
    } else {
      conditionMessage(cnd)
    }
  }
  # A fold that did not finish has no outer fit to have kept predictions or
  # an extract from; each element is NULL whether or not the control asked
  # (M68).
  list(
    completed = FALSE,
    metrics = empty_metrics(),
    selected = NULL,
    inner_metrics = inner_metrics(tuned, prototype),
    predictions = NULL,
    extracts = NULL,
    notes = bind_notes(own_note(stage, message), tune_notes(result, stage))
  )
}

own_note <- function(stage, message) {
  new_tbl(list(
    location = stage,
    type = "error",
    note = message,
    trace = list(NULL)
  ))
}

# tune's notes, verbatim, relabelled with the stage they came from. The `id`
# column is present for a tune_grid() result and absent for a last_fit() one,
# so it is folded into the location rather than assumed.
tune_notes <- function(result, stage) {
  notes <- tryCatch(tune::collect_notes(result), error = function(cnd) NULL)
  if (is.null(notes) || nrow(notes) == 0L) {
    return(empty_notes())
  }
  inner_id <- if ("id" %in% names(notes)) paste0(" (", notes$id, ")") else ""
  new_tbl(list(
    location = paste0(stage, inner_id, ": ", notes$location),
    type = notes$type,
    note = notes$note,
    trace = notes$trace
  ))
}

bind_notes <- function(a, b) {
  new_tbl(list(
    location = c(a$location, b$location),
    type = c(a$type, b$type),
    note = c(a$note, b$note),
    trace = c(a$trace, b$trace)
  ))
}

empty_notes <- function() {
  new_tbl(list(
    location = character(0),
    type = character(0),
    note = character(0),
    trace = list()
  ))
}

# A failed fold contributes no rows rather than a NULL, so every downstream
# assembly over `.metrics` keeps working without a special case.
empty_metrics <- function() {
  new_tbl(list(
    .metric = character(0),
    .estimator = character(0),
    .estimate = numeric(0),
    .config = character(0)
  ))
}

# tune warns at the end of a run that had issues; so does this (GP1). A user
# who never calls collect_metrics() still hears about it.
warn_failed_folds <- function(x, call = rlang::caller_env()) {
  failed <- fold_ids(x)[!x$.completed]
  if (length(failed) == 0L) {
    return(invisible(x))
  }
  n <- attr(x, "folds_attempted")
  cli::cli_warn(
    c(
      "!" = "{length(failed)} of {n} outer fold{?s} failed.",
      x = "Failed: {.val {failed}}.",
      i = "See {.code x$.notes} for what went wrong."
    ),
    class = "nestedtune_failed_folds",
    call = call
  )
  invisible(x)
}

# The generator kind is pinned, not just the seed. set.seed() seeds whichever
# kind happens to be active, so a caller who has selected a non-default kind
# would get one set of numbers serially and another from a fresh parallel
# worker that starts on the default -- the same seed, different results.
set_fold_seed <- function(seed) {
  set.seed(
    seed,
    kind = "Mersenne-Twister",
    normal.kind = "Inversion",
    sample.kind = "Rejection"
  )
}

# Assigning `.Random.seed` restores the generator kind with it: the kind triple
# is encoded in its first element. The other branch is a session that had no
# RNG state when we were called -- there is nothing to restore, and removing
# the state we created would leave the session worse than we found it, so only
# the kind goes back.
restore_rng <- function(had_seed, kind, seed) {
  if (had_seed) {
    assign(".Random.seed", seed, envir = globalenv())
  } else {
    RNGkind(kind[[1L]], kind[[2L]], kind[[3L]])
  }
  invisible(NULL)
}
