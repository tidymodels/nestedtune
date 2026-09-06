# The workflow-set orchestrator (M71, D-058): one call runs every workflow
# of a `workflow_set` through one nested design and hands back the results
# side by side, one `nested_results` per workflow. Nothing statistical is
# new here. Each workflow runs through the orchestrator it would have run
# through by hand, under the same entry state, so each element is that hand
# call's result; what the set adds is the pairing on folds and seeds, and a
# reader surface that keeps the workflow's id beside every row.

#' Run every workflow of a workflow set through one nested design
#'
#' `nested_workflow_map()` takes a [workflowsets::workflow_set()] and the name
#' of one of the six orchestrators, and runs each workflow of the set, in the
#' set's order, through that orchestrator on one nested design. It is shaped
#' like [workflowsets::workflow_map()]: the orchestrator's arguments come
#' through `...`, and an entry in the set's `option` column overrides the
#' same-named argument for that workflow alone. It returns a
#' `nested_results_set`, a tibble with one row per workflow holding its id,
#' the workflow and its `nested_results`, so the comparison a user makes
#' across model families reads off one object with the workflow id beside
#' the fold labels.
#'
#' @section Routing:
#'
#' A workflow with no parameter marked by [tune::tune()] runs through
#' [nested_fit_resamples()] whatever `fn` names, since the five tuning
#' orchestrators refuse it at entry: a baseline beside tuned models on the
#' same folds is the comparison a set exists for, and each element's record
#' names the procedure that ran. Every other workflow runs through `fn`. For
#' each workflow the merged arguments are narrowed to what its orchestrator
#' accepts -- its formals other than `object`, and, for a workflow that runs
#' through `fn`, the `control` in `...` -- so a `grid` in `...` reaches the
#' tuned workflows and not the fixed one. A control's class is `fn`'s own,
#' and [nested_fit_resamples()] refuses a racing, Bayesian or annealing
#' control by that class, so a fixed workflow routed there does not take the
#' `control` in `...`: it runs under tune's default
#' [tune::control_resamples()] unless its `option` entry names one, which is
#' where a `save_pred` or `extract` for the baseline goes. A name that the
#' orchestrator `fn` names does not take
#' is refused at entry (a typo would otherwise be narrowed away for every
#' workflow); a name in a workflow's `option` entry that the orchestrator it
#' routes to does not take is refused naming the workflow. Under
#' `fn = "nested_fit_resamples"` every workflow must be fixed: one carrying
#' a marker is refused at entry, naming it, as that orchestrator refuses it.
#'
#' @section Seeds:
#'
#' Seed the session before the call, as before any orchestrator. The
#' generator state the call holds once its entry checks have run is
#' reinstated before each workflow, so every workflow's fold `i` runs under
#' the same two seeds and each element is `identical()` to the orchestrator
#' called by hand on that workflow, with the same arguments, after the same
#' `set.seed()`. Under a stochastic engine the workflows are therefore
#' paired on seeds as well as on folds. The caller's state is put back on
#' exit, and a session that had never drawn is left with no state, as it
#' was found. Each element runs its folds in parallel exactly as its
#' orchestrator does: a running mirai pool is used for every workflow's
#' folds, one round of folds per workflow.
#'
#' @section Warnings from one workflow:
#'
#' An orchestrator warns when some of its outer folds failed, and a reader
#' warns when it summarizes a partial run. Inside a set those warnings are
#' raised with the workflow's id at the front of the message, under the same
#' condition class, so a user who never calls a reader still learns which
#' workflow lost folds. An error an orchestrator raises for one workflow --
#' a `grid` that names a parameter that workflow does not tune, a control of
#' the wrong class -- is raised the same way, when that workflow's turn
#' comes; the workflows before it have run by then.
#'
#' @param object A [workflowsets::workflow_set()]: one workflow per row,
#'   untrained, with `wflow_id`, `info`, `option` and `result` columns as
#'   [workflowsets::workflow_set()] and [workflowsets::as_workflow_set()]
#'   build them. The `result` column is not read: this function returns its
#'   results as its own object rather than filling the set's column.
#' @param fn The name of the orchestrator to run each workflow through, one
#'   of `"nested_tune_grid"` (the default), `"nested_tune_bayes"`,
#'   `"nested_tune_race_anova"`, `"nested_tune_race_win_loss"`,
#'   `"nested_tune_sim_anneal"` or `"nested_fit_resamples"`. The package's
#'   own names, not tune's.
#' @param ... The orchestrator's arguments, every one named: the nested
#'   design as `resamples` (required), and any of that orchestrator's other
#'   arguments -- `grid`, `param_info`, `metrics`, `event_level`,
#'   `eval_time`, `select`, `iter`, `initial`, `objective` -- and a
#'   `control` as it takes one through its own `...`. An entry of the set's
#'   `option` column overrides the same-named argument for its workflow. A
#'   name the orchestrator `fn` names does not take is refused, as is an
#'   unnamed argument and a call with no `resamples`.
#'
#' @return A `nested_results_set`: a tibble of class
#'   `c("nested_results_set", "tbl_df", "tbl", "data.frame")` with one row
#'   per workflow in the set's order and three columns, `wflow_id` (the
#'   set's id), `workflow` (the workflow, as the set held it) and `result`
#'   (its `nested_results`, as the orchestrator that ran returned it), with
#'   `fn` kept as an attribute. It does not carry the `workflow_set` class,
#'   so [workflowsets::rank_results()] and [tune::fit_best()] refuse it: a
#'   ranking of the set's workflows by their nested estimates, and a fit of
#'   the best, would be a selection the outer loop did not nest (see
#'   `vignette("estimate")`). What it answers: [collect_metrics()],
#'   [collect_selections()], [collect_inner_metrics()], [collect_notes()],
#'   [collect_predictions()][collect_predictions.nested_results] and
#'   [collect_extracts()][collect_predictions.nested_results] stack each
#'   workflow's table under a `wflow_id` column; [extract_workflow()] with an
#'   `id` returns one workflow; [nested_final_fit()] with an `id` fits one
#'   workflow by its own record; and `print()` shows the orchestrator and
#'   each workflow's completed fold count.
#'
#' @examplesIf rlang::is_installed(c("recipes", "yardstick", "workflowsets"))
#' data(mtcars)
#'
#' # One tuned workflow and one baseline, on the same nested design.
#' rec <- recipes::recipe(mpg ~ ., data = mtcars)
#' tuned <- recipes::step_pca(rec, recipes::all_predictors(), num_comp = tune::tune())
#' wset <- workflowsets::workflow_set(
#'   preproc = list(pca = tuned, none = rec),
#'   models = list(lm = parsnip::linear_reg())
#' )
#'
#' set.seed(1)
#' folds <- nested_resamples(
#'   mtcars,
#'   outside = rsample::vfold_cv(v = 3),
#'   inside = rsample::vfold_cv(v = 3)
#' )
#'
#' set.seed(2)
#' res <- nested_workflow_map(
#'   wset,
#'   resamples = folds,
#'   grid = data.frame(num_comp = 1:3)
#' )
#' res
#' collect_metrics(res)
#'
#' # The baseline ran through nested_fit_resamples(), whatever fn named.
#' extract_procedure(res$result[[2]])$tuner
#'
#' @seealso [nested_tune_grid()], [nested_fit_resamples()],
#'   [collect_metrics.nested_results_set()], [nested_final_fit()],
#'   [workflowsets::workflow_map()]
#' @export
nested_workflow_map <- function(object, fn = "nested_tune_grid", ...) {
  dots <- capture_dots(...)
  check_workflow_set(object)
  check_map_fn(fn)
  check_map_dots(dots, fn)
  call <- rlang::current_env()

  ids <- object$wflow_id
  workflows <- lapply(object$info, function(info) info$workflow[[1L]])
  routes <- vapply(workflows, route_workflow, character(1), fn = fn)
  check_map_options(object, routes)
  # Every workflow judged before any runs (GP3), each refusal naming the
  # workflow: the shared checks, and under the plain resampling orchestrator
  # the door it keeps (D-057).
  for (i in seq_along(ids)) {
    for_workflow(ids[[i]], call, {
      check_workflow(workflows[[i]], call = call)
      if (identical(routes[[i]], "nested_fit_resamples")) {
        check_tuned_workflow(workflows[[i]], call = call)
      }
    })
  }

  # The seed envelope. Each orchestrator puts the caller's state back on
  # exit (D-011), so a session that had drawn would hand every workflow the
  # same entry state with no help; a session that never drew would not --
  # `restore_rng()` keeps the state the first run created, and the second
  # workflow would start from it. So the state is fixed here: initialized
  # when there is none, reinstated before every workflow, and on exit put
  # back or, where there was none, removed with the kind restored, as
  # `capture_dots()` leaves such a session (AC2). The `RNGkind()` query
  # draws nothing and initializes nothing (measured 2026-09-06).
  had_seed <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  old_kind <- RNGkind()
  if (!had_seed) {
    invisible(stats::runif(1L))
  }
  entry_seed <- get(".Random.seed", envir = globalenv())
  on.exit(restore_map_rng(had_seed, old_kind, entry_seed), add = TRUE)

  results <- vector("list", length(ids))
  for (i in seq_along(ids)) {
    assign(".Random.seed", entry_seed, envir = globalenv())
    args <- map_args(dots, object$option[[i]], routes[[i]], fn)
    results[[i]] <- for_workflow(
      ids[[i]],
      call,
      run_orchestrator(routes[[i]], workflows[[i]], args)
    )
  }
  new_nested_results_set(ids, workflows, results, fn)
}

# The arguments one workflow's orchestrator gets: the call's `...` with the
# workflow's `option` entry written over the same names, narrowed to what
# the routed orchestrator accepts. A `control` in `...` is `fn`'s own -- its
# class is the contract (D-042), and `nested_fit_resamples()` refuses a
# racing, Bayesian or annealing control by that class (measured 2026-09-06)
# -- so a workflow routed elsewhere does not take it, and gets a control
# from its `option` entry alone (M71 gate). `option` is a
# `workflow_set_options` list; the entry checks have already held its names
# to the route.
map_args <- function(dots, option, route, fn) {
  args <- dots
  if (!identical(route, fn)) {
    args[["control"]] <- NULL
  }
  option <- unclass(option)
  for (nm in names(option)) {
    args[[nm]] <- option[[nm]]
  }
  args[intersect(names(args), orchestrator_args(route))]
}

# One orchestrator call, built as a call in an environment that binds the
# workflow and every argument to a name (the M05 lesson: a value inlined
# into a call is deparsed into every condition raised beneath it, and a
# workflow or an rset deparses to thousands of lines). The environment's
# parent is the namespace, where the orchestrator's name resolves.
run_orchestrator <- function(fn, workflow, args) {
  env <- rlang::new_environment(
    c(list(.workflow = workflow), args),
    parent = asNamespace("nestedtune")
  )
  syms <- rlang::syms(names(args))
  names(syms) <- names(args)
  expr <- rlang::call2(fn, quote(.workflow), !!!syms)
  eval(expr, env)
}

# Conditions raised for one workflow, re-signalled naming it (M71 gate): the
# failed-fold warning an orchestrator raises, the partial-run warning a
# reader raises, and any error either raises keep their class and their
# text, gain the workflow's id at the front, and name the caller as their
# call, so a user learns which workflow the message is about. A warning of
# another class -- a package that will not attach in a daemon, tune's own --
# is left as it is: it is not about one workflow. Shared with the set's
# readers (R/nested-results-set.R).
for_workflow <- function(id, call, expr) {
  resignal <- function(cnd) {
    resignal_for_workflow(cnd, id, call)
    invokeRestart("muffleWarning")
  }
  withCallingHandlers(
    rlang::try_fetch(
      expr,
      error = function(cnd) resignal_for_workflow(cnd, id, call)
    ),
    nestedtune_failed_folds = resignal,
    nestedtune_partial_summary = resignal
  )
}

# The re-signal itself, shared with the set's readers (R/nested-results-set.R).
# The whole formatted message travels, with cli's leading bullet glyph on
# the first line dropped so the id reads as the head of the sentence; the
# package's own classes travel, rlang's and base R's are re-added by the
# signaller.
resignal_for_workflow <- function(cnd, id, call) {
  own <- setdiff(
    class(cnd),
    c("rlang_error", "rlang_warning", "error", "warning", "condition")
  )
  message <- sub("^[!] ", "", conditionMessage(cnd))
  message <- paste0(cli::format_inline("Workflow {.val {id}}: "), message)
  if (inherits(cnd, "warning")) {
    rlang::warn(message, class = own, call = call)
  } else {
    rlang::abort(message, class = own, call = call)
  }
}

# The map's counterpart of `restore_rng()`: the caller's state goes back
# where there was one; where there was none, the kind is restored first --
# setting a kind writes a state, so the removal comes after it -- and the
# state the map created is removed, so a session that never drew is left
# with none (AC2).
restore_map_rng <- function(had_seed, kind, seed) {
  if (had_seed) {
    assign(".Random.seed", seed, envir = globalenv())
  } else {
    RNGkind(kind[[1L]], kind[[2L]], kind[[3L]])
    if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) {
      rm(".Random.seed", envir = globalenv())
    }
  }
  invisible(NULL)
}

# The set of results: one row per workflow, the orchestrator name kept as an
# attribute. A tibble subclass with no `workflow_set` class (D-010's
# standalone rule): the methods that class would bring -- a ranking, a fit
# of the best -- answer a question the outer loop did not nest.
new_nested_results_set <- function(ids, workflows, results, fn) {
  out <- new_tbl(list(
    wflow_id = ids,
    workflow = workflows,
    result = results
  ))
  attr(out, "fn") <- fn
  class(out) <- c("nested_results_set", class(out))
  out
}
