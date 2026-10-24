#' Nested cross-validation with a grid search inside
#'
#' @description
#' `nested_tune_grid()` estimates how well a model tuned with
#' [tune::tune_grid()] performs on new data. Each outer fold tunes on its own
#' inner resamples, fits the chosen candidate on its analysis set, and scores
#' it on the rows it held out.
#'
#' @details
#' For each outer fold, the function calls [tune::tune_grid()] on the fold's
#' inner resamples and picks a candidate with `select`. It finalizes the
#' workflow with that candidate. Then [tune::last_fit()] fits the workflow on
#' the fold's analysis set and scores it on the assessment set.
#'
#' The estimate from [collect_metrics()] describes this whole procedure (tune,
#' select, fit) and not one fitted model. To get a model to
#' deploy, call [nested_final_fit()], which runs the same procedure on all
#' the data. The nested estimate is the number to report for that model,
#' because the model comes from the same procedure.
#'
#' [nested_tune_bayes()], [nested_tune_race_anova()],
#' [nested_tune_race_win_loss()] and [nested_tune_sim_anneal()] run the same
#' loop with another search. [nested_fit_resamples()] runs it for a workflow
#' with nothing to tune. This page documents what they share.
#'
#' `object` can also be a parsnip model specification, given with a
#' `preprocessor`, as in `nested_tune_grid(spec, preprocessor, resamples)`.
#'
#' @inheritParams tune::tune_grid
#' @param object A [workflows::workflow()] with at least one parameter marked
#'   with [tune::tune()], or a parsnip model specification.
#' @param preprocessor A formula or recipe, when `object` is a model
#'   specification.
#' @param resamples A nested resampling design from [nested_resamples()] or
#'   [rsample::nested_cv()].
#' @param metrics A [yardstick::metric_set()], or `NULL` for tune's default
#'   set. Under every rule but `"desirability"`, the first metric selects
#'   each fold's candidate, so put the metric you report first. The Bayes,
#'   race and annealing searches also steer on it. Every metric is scored on
#'   the outer folds.
#' @templateVar CONSTRUCTOR tune::control_grid()
#' @templateVar PKG tune
#' @template param-control-dots
#' @templateVar SCOPE It applies to the inner tuning run and the outer scoring fit alike.
#' @template param-event-level
#' @templateVar REFUSED Times that are not numeric, empty, missing, negative or not finite are an error. Zero, repeated and unordered times are passed on to tune.
#' @template param-eval-time
#' @param select A [selection_rule()] that each outer fold uses to pick its
#'   candidate. The default is [tune::select_best()] on the first metric.
#'
#' @return A tibble of class `nested_results` with one row per outer fold.
#'   Beside the fold's split and labels, each row holds:
#'
#'   - `.metrics`, the metrics scored on the fold's assessment set.
#'   - `.selected`, the candidate the fold's inner tuning chose.
#'   - `.inner_metrics`, the inner run's metrics for every candidate that
#'     scored. A fold that scored no candidate holds a zero-row table, never
#'     `NULL`. tune can reach fewer candidates than a `grid` size asks for,
#'     so `attr(res, "grid")`, the argument as given, can differ from these
#'     rows.
#'   - `.completed`, whether the fold finished, and `.notes`, what went
#'     wrong.
#'   - `.tuning_seed` and `.outer_fit_seed`, the fold's two seeds.
#'
#'   Use [collect_metrics()] for the estimate. `summary()`,
#'   [collect_selections()], [agreement()] and
#'   [autoplot()][autoplot.nested_results] show it in other ways.
#'
#'   `arrange()`, `mutate()` adding a column, and a join that matches one row
#'   per fold keep the class. Removing a fold or a column above
#'   returns a plain tibble, because the result no longer describes the
#'   design that ran. So do `slice()`, `bind_rows()` of two results, and
#'   `vctrs::vec_rbind(x)` alone. `bind_cols()` keeps the class only with the
#'   result as its first argument. `group_by()`, `rowwise()` and
#'   `tibble::as_tibble()` return their own classes and keep the attributes.
#'   A column you add is read as a fold label only when the design itself
#'   carries a column of that name.
#'
#' @section Nested designs:
#'
#' `resamples` has one row per outer fold: a `splits` column of outer splits,
#' an `inner_resamples` column of inner rsets, and id columns. The function
#' checks the design before it fits anything. An outer bootstrap is an
#' error, and so are [rsample::loo_cv()], [rsample::apparent()] and
#' [rsample::permutations()] in either loop. An inner split that reaches a
#' row its outer fold holds out is an error too. Each error names the design,
#' or the rows, splits or folds at fault.
#'
#' Time-series designs work as well. `nested_tune_grid()` is tested with an
#' outer [rsample::rolling_origin()], [rsample::sliding_window()],
#' [rsample::sliding_index()] or [rsample::sliding_period()] design and an
#' inner design of any of those four kinds. Leave the `lag` of
#' [rsample::rolling_origin()] at 0, because a larger `lag` is an error.
#' [nested_resamples()] says which of these designs the other functions are
#' tested on.
#'
#' @section Finalizing a parameter range:
#'
#' A range that depends on the data, such as `mtry()`, is finalized on each
#' outer fold's analysis set, never on the rows that fold holds out.
#' [nested_tune_bayes()] is the exception: [tune::tune_bayes()] does not
#' finalize such a range, so set it in `param_info`, or every fold fails.
#' [nested_final_fit()] finalizes it on all the data. A range set in
#' `param_info` applies to every fold.
#'
#' @section Evaluation times:
#'
#' The inner tuning and the outer scoring both use the times in `eval_time`.
#' If the metric set has no dynamic or integrated survival metric, tune
#' ignores the times with a warning. Each fold selects at the first of these
#' times.
#'
#' @template section-resample-weights
#'
#' @template section-reproducibility
#'
#' @section Reproducing one fold:
#'
#' Fold `i` runs the code below. On a [nested_resamples()] design, `inner`
#' is the fold's inner rset re-pointed at
#' `rsample::analysis(resamples$splits[[i]])`. Under another `select`, the
#' selection line uses [tune::select_by_one_std_err()] or
#' [tune::select_by_pct_loss()]. A Bayesian fold also sets `control$seed` to
#' the fold's tuning seed.
#'
#' ```
#' set.seed(res$.tuning_seed[[i]], kind = "Mersenne-Twister",
#'          normal.kind = "Inversion", sample.kind = "Rejection")
#' tuned <- tune_grid(object, inner, grid = grid,
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
#' @section When a fold fails:
#'
#' A fold that fails does not stop the run. Its `.completed` is `FALSE` and
#' its `.notes` says which stage failed and why. The run warns at the end,
#' and [collect_metrics()] summarizes only the folds that completed. If no
#' fold completed, [collect_metrics()] gives an error.
#'
#' @section Parallel execution:
#'
#' The outer folds run in parallel when two or more mirai daemons are
#' running, and serially otherwise. Inner tuning always runs serially.
#'
#' ```
#' mirai::daemons(4)
#' res <- nested_tune_grid(wf, folds, grid = grid)
#' mirai::daemons(0)
#' ```
#'
#' The daemons load nestedtune from an installed library, and they do not
#' inherit your session's options. Set what a fold needs with
#' [mirai::everywhere()]. Under `devtools::load_all()`, the daemons cannot
#' see your development code, so run
#' `mirai::everywhere(pkgload::load_all("<path>"))` first. A running daemon
#' keeps the version it loaded, so restart the pool after you reinstall.
#'
#' Before it sends the folds out, the function checks that every daemon can
#' load the packages the run needs. The check waits up to 30 seconds, and
#' `options(nestedtune.preflight_timeout = <ms>)` changes that limit. The
#' folds themselves have no time limit. If every daemon dies after dispatch,
#' the call waits until you interrupt it.
#'
#' Each fold is sent one copy of the data. A workflow built inside a
#' function carries that function's environment to every fold, so build it
#' at the top level. On a pool with mirai's default dispatcher, an interrupt
#' cancels the folds that are still running. A pool started with
#' `dispatcher = FALSE` cannot be cancelled, and the call warns about that.
#'
#' @section Differences from calling tune directly:
#'
#' A [tune::control_grid()] passed through `...` as `control` reaches the
#' inner `tune_grid()` in every fold. The outer fit runs under its own
#' `control_last_fit()`, and takes only `event_level`, `save_pred` and
#' `extract` from the control. The result keeps the control that ran as
#' `extract_procedure(res)$control`, and [nested_final_fit()] runs again
#' with it. Its settings differ from a direct `tune_grid()` call as
#' follows.
#'
#' @templateVar INNER inner tuning run
#' @template differences-forced
#' @section Differences from calling tune directly:
#' **Settable as its own argument: `event_level`.** Set the level with the
#' `event_level` argument, which reaches the inner run and the outer fit. A
#' control that names a level other than tune's default or the argument's is
#' an error. `eval_time` is an argument of `tune_grid()` too, not a control
#' setting.
#'
#' @templateVar OTHER control_bayes()
#' @template differences-refused
#' @section Differences from calling tune directly:
#' tune gives [tune::control_resamples()] and [tune::control_last_fit()] the
#' `control_grid` class, so both are accepted here.
#'
#' **Passed through: `verbose`, `pkgs`, `parallel_over`, `workflow_size`.**
#' Each reaches `tune_grid()` as given. `parallel_over` still sets the seed
#' each model fit starts from, so a stochastic engine's numbers depend on
#' it.
#'
#' **Kept from the outer fit: `save_pred`, `extract`.** With
#' `save_pred = TRUE`, the result has a `.predictions` column of each
#' fold's outer predictions. With an `extract` function, it has an
#' `.extracts` column. The inner run's predictions and extracts are still
#' discarded.
#' [`collect_predictions()`][collect_predictions.nested_results] and
#' [`collect_extracts()`][collect_predictions.nested_results] read the two
#' columns.
#'
#' **Not returned: `save_workflow`.** The inner tuning results are not kept,
#' so this setting returns nothing. Use `extract = function(x) x` to keep
#' each fold's fitted workflow.
#'
#' @template differences-inert
#'
#' @template example-setup
#' @template example-run
#' @examplesIf rlang::is_installed(c("recipes", "yardstick"))
#' collect_metrics(res)
#'
#' # What each fold chose. Folds that disagree show the choice is unstable.
#' res$.selected
#'
#' @seealso [nested_tune_bayes()], [nested_resamples()], [nested_final_fit()],
#'   [tune::tune_grid()]
#' @export
nested_tune_grid <- function(object, ...) {
  UseMethod("nested_tune_grid")
}

#' @rdname nested_tune_grid
#' @export
nested_tune_grid.default <- function(object, ...) {
  abort_bad_object(object)
}

# The model-spec door (D-069): the spec and its preprocessor become the
# workflow tune's own method would build, and the call goes through the
# generic again, so every later refusal names the function the user called.
# The named arguments are the workflow method's, with its defaults, and are
# passed on as given.
#' @rdname nested_tune_grid
#' @export
nested_tune_grid.model_spec <- function(
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
  check_preprocessor(preprocessor)
  rlang::check_required(resamples)
  with_user_call(nested_tune_grid(
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

#' @rdname nested_tune_grid
#' @export
nested_tune_grid.workflow <- function(
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
  dots <- capture_dots(...)
  check_no_preprocessor(dots, resamples)
  rlang::check_required(resamples)
  control <- check_dots_control(dots)
  check_workflow(object)
  check_untuned_workflow(object)
  check_nested(resamples)
  check_grid(grid)
  check_grid_params(object, grid)
  check_metrics(metrics)
  check_param_info(param_info)
  check_event_level(event_level)
  check_eval_time(eval_time)
  check_selection_rule(select, object, "tune_grid", metrics)
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
  # Resolved before any fold runs and before the seed draw, so a metric
  # set tune cannot resolve for the workflow is refused at entry rather than
  # after every fold has failed on it. Every tuner is checked, the plain
  # resampling one included (D-082); only a tuner that selects keeps the name.
  first_metric <- check_metrics_mode(metrics, object, call = call)
  if (!tuner_selects(tuner$tuner)) {
    first_metric <- NULL
  }

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
    workflow = workflow_identity(object),
    first_metric = first_metric
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
  # The zero-row inner table a fold that scores nothing records. Built
  # here, before anything can fail, from the workflow rather than from a run:
  # a fold whose tuning raised has no run to read columns off, and one whose
  # every candidate failed has a run `collect_metrics()` raises on.
  prototype <- empty_inner_metrics(object, tuner, metrics, param_info)

  # `tuned` is assigned inside the tryCatch expression, which evaluates in this
  # frame -- so when select_best() is what errors, tune's own notes explaining
  # why every model failed are still in hand to record.
  tuned <- NULL
  # A tuner that selects nothing (`tuner_selects()`) skips the inner
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
        # The inner rset tune reads is framed on this fold's analysis rows:
        # tune finalizes an unknown parameter range on the frame the
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
        # The searches steer on the same metric: tune's `tune_bayes_workflow()`
        # and finetune's `tune_race_anova_workflow()`,
        # `tune_race_win_loss_workflow()` and `tune_sim_anneal_workflow()` each
        # set `opt_metric <- first_metric(metrics)` (tune 2.1.0, finetune 1.3.0,
        # read 2026-09-24). The `metrics` help says so.
        metric_name <- tune::.get_tune_metric_names(tuned)[[1L]]
        # The recorded rule, one of tune's three selectors behind
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
      # given, its parameters already fixed.
      final_wf <- if (tuner_selects(tuner$tuner)) {
        tune::finalize_workflow(object, selected)
      } else {
        object
      }
      set_fold_seed(seeds[[2L]])
      # The outer fit's control carries `event_level`, so its metrics are
      # computed at the event level the inner run was told -- the one place
      # the setting has to reach for a reported number to move.
      # `allow_par = FALSE` is stated rather than left to
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

  # The outer fit's assessment-set predictions, kept when the control asks.
  # `last_fit()` always computes them, so `save_pred` decides only
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
  # slot would replace the workflow. An extract that errors is a
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

# The inner run's metrics, as tune summarizes them (IP4).
#
# `tune::collect_metrics()` of the tuning run, verbatim: one row per candidate
# and metric, with the mean, the resample count `n` and its standard error,
# tune's `.config` label, and the `.iter` a Bayesian run scored it in. A
# candidate that scored on some inner resamples and failed on others is a row
# with `n` below the resample count; one that failed on every resample left no
# metric row anywhere and is absent -- present in the fold's notes instead.
#
# A run in which nothing scored gets the prototype rather than a call:
# `collect_metrics()` raises on such a run, and this runs
# inside the failure paths too, where `tuned` is whatever tune handed back
# before giving up and may be NULL. The tryCatch is insurance against a shape
# not thought of, since the two failures cost unequally: an empty table
# understates one fold, a raise discards every other fold's completed work.
inner_metrics <- function(tuned, prototype) {
  if (!scored_anything(tuned)) {
    return(prototype)
  }
  tryCatch(inner_metrics_table(tuned), error = function(cnd) prototype)
}

# The one `collect_metrics()` call behind every reader of an inner run (D-043):
# tune's summary, and on a race every candidate the race scored --
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

# The name of the first metric in the set, resolved as tune resolves it for
# the workflow, so a run given `metrics = NULL` records the first metric of
# tune's default set for the workflow's mode. Each fold's run resolves
# the same name through `tune::.get_tune_metric_names()`; this reads it once,
# before any fold runs, so the record names it when no fold completes.
first_metric_name <- function(metrics, object, call = rlang::caller_env()) {
  set <- tune::check_metrics_arg(metrics, object, call = call)
  names(attr(set, "metrics"))[[1L]]
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
# renders rows before ordering them.
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
# record.
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
  # raises on conditionMessage().
  if (is.null(message)) {
    message <- if (is.null(cnd)) {
      "The outer fit produced no metrics."
    } else {
      conditionMessage(cnd)
    }
  }
  # A fold that did not finish has no outer fit to have kept predictions or
  # an extract from; each element is NULL whether or not the control asked.
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
