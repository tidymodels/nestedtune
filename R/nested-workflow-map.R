# The workflow-set orchestrator (M71, D-058): one call runs every workflow
# of a `workflow_set` through one nested design and hands back the results
# side by side, one `nested_results` per workflow. Nothing statistical is
# new here. Each workflow runs through the orchestrator it would have run
# through by hand, under the same entry state, so each element is that hand
# call's result; what the set adds is the pairing on folds and seeds, and a
# reader surface that keeps the workflow's id beside every row.

#' Run every workflow of a workflow set through one nested design
#'
#' @description
#' `nested_workflow_map()` runs every workflow of a
#' [workflowsets::workflow_set()] through one nested design, so you can
#' compare models on the same outer folds.
#'
#' @details
#' The function works like [workflowsets::workflow_map()]. `fn` names the
#' nested function to run, and its arguments come through `...`. An entry in
#' the set's `option` column overrides an argument of the same name for that
#' workflow alone. The workflows run in the set's order.
#'
#' A workflow with no [tune::tune()] marker runs through
#' [nested_fit_resamples()], whatever `fn` names, so a baseline can sit
#' beside the tuned models. Each workflow gets only the arguments its
#' function takes. So a `grid` reaches the tuned workflows and not the fixed
#' one, and the fixed one runs under tune's default control unless its
#' `option` entry names one.
#'
#' Each workflow starts from the same random state, so fold `i` of every
#' workflow runs under the same two seeds. Each result is identical to a
#' call by hand on that workflow, with the same arguments, after the same
#' `set.seed()`.
#'
#' An error from one workflow names that workflow at the front of its
#' message and keeps its class. So does a warning about failed folds. After
#' an error, the workflows before it have already run.
#'
#' [collect_metrics()] and the other `collect_*()` functions stack each
#' workflow's table under a `wflow_id` column. [nested_final_fit()] with an
#' `id` fits one workflow. `dplyr::filter()`, `dplyr::arrange()`,
#' `dplyr::mutate()` and `x[i, ]` keep the class while the three columns keep
#' their values. An operation that empties the set, repeats a `wflow_id`,
#' changes or drops one of the three columns, or brings in a row from
#' elsewhere returns a plain tibble.
#'
#' @inheritParams workflowsets::workflow_map
#' @param fn The name of the function to run each workflow through. The
#'   default is `"nested_tune_grid"`. The others are `"nested_tune_bayes"`,
#'   `"nested_tune_race_anova"`, `"nested_tune_race_win_loss"` and
#'   `"nested_tune_sim_anneal"`. With `"nested_fit_resamples"`, no workflow
#'   can have a parameter to tune.
#' @param ... The arguments of `fn`, each one named. `resamples`, the nested
#'   design, is required, and a `control` goes here as well. A name that `fn`
#'   does not take is an error. A `metrics` set reaches every workflow, and
#'   one that does not suit a workflow's model is an error before any
#'   workflow runs.
#'
#' @return A `nested_results_set`, a tibble with one row per workflow. Its
#'   columns are `wflow_id`, `workflow`, and `result`, the workflow's
#'   `nested_results`. It is not a `workflow_set`, so
#'   [workflowsets::rank_results()] and [tune::fit_best()] do not accept it.
#'   Choosing the best workflow by its nested estimate is a selection that
#'   the outer loop did not nest.
#'
#' @template example-setup
#' @template example-set
#' @examplesIf rlang::is_installed(c("recipes", "yardstick", "workflowsets"))
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
  # workflow: the shared checks, under the plain resampling orchestrator the
  # door it keeps (D-057), and under every route the metric set (D-082).
  for (i in seq_along(ids)) {
    for_workflow(ids[[i]], call, {
      check_workflow(workflows[[i]], call = call)
      if (identical(routes[[i]], "nested_fit_resamples")) {
        check_tuned_workflow(workflows[[i]], call = call)
      }
      # The metric set this workflow's run would get, resolved as the run
      # resolves it (M116). A `metrics` that is not a metric set is left to
      # the orchestrator's own check.
      metrics <- map_args(dots, object$option[[i]], routes[[i]], fn)$metrics
      if (is.null(metrics) || inherits(metrics, "metric_set")) {
        check_metrics_mode(metrics, workflows[[i]], call = call)
      }
    })
  }
  # A race misreads a bootstrap's apparent split, which the other routes
  # accept (D-100). The design comes from the call alone, so it is read once,
  # before an earlier workflow on another route runs on it.
  racers <- paste0("nested_", racer_tuners)
  if (any(routes %in% racers)) {
    check_race_apparent(dots[["resamples"]], call = call)
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
# The original condition object travels whole (M73): its class vector, its
# `parent` and the cause chain that prints under it, its bullets, its
# format flag and every data field a handler reads, with the workflow's id
# written in front of the first line of its header and the caller's call
# in place of the element's. A rebuilt condition -- `rlang::abort()` on the
# formatted text, what M71 did -- kept the class and the text and lost the
# rest. `cnd_signal()` raises the object as it is: a warning is raised with
# `warning()`, an error through rlang's own signaller, which adds a trace
# to one that has none.
resignal_for_workflow <- function(cnd, id, call) {
  # A condition built with no message text -- `character(0)`, or no
  # `message` element at all -- gets the prefix as its whole first line;
  # sub-assigning into it would index past the end or make a list.
  message <- cnd$message
  if (length(message) == 0L) {
    message <- ""
  }
  message[[1L]] <- paste0(
    cli::format_inline("Workflow {.val {id}}: "),
    message[[1L]]
  )
  cnd$message <- message
  # The callers hand their frame as `call`, which `rlang::abort()` would
  # resolve to the frame's call; assigned directly it needs the same step.
  cnd$call <- rlang::error_call(call)
  rlang::cnd_signal(cnd)
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
