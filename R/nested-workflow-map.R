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
#' `nested_workflow_map()` gives you nested estimates for every workflow of
#' a [workflowsets::workflow_set()] on one nested design, so you can
#' compare model families on the same folds. It takes the set and the name
#' of one of the six orchestrators, the loop functions [nested_tune_grid()]
#' lists. It runs each workflow of the set through that orchestrator, in
#' the set's order. It is shaped like [workflowsets::workflow_map()]: the
#' orchestrator's arguments come through `...`, and an entry in the set's
#' `option` column overrides the same-named argument for that workflow
#' alone.
#'
#' It returns a `nested_results_set`, a tibble with one row per workflow
#' holding its id, the workflow and its `nested_results`. A comparison
#' across model families then reads off one object, with the workflow id
#' beside the fold labels.
#'
#' @inheritParams workflowsets::workflow_map
#' @param fn The name of the orchestrator to run each workflow through:
#'   `"nested_tune_grid"` (the default), `"nested_tune_bayes"`,
#'   `"nested_tune_race_anova"` or `"nested_tune_race_win_loss"`.
#'   `"nested_tune_sim_anneal"` and `"nested_fit_resamples"` are the other
#'   two.
#' @param ... The orchestrator's arguments, every one named: the nested design
#'   as `resamples` (required), any of its other arguments, and a `control`
#'   as it takes one through its own `...`. A name the orchestrator `fn`
#'   names does not take is refused, as is an unnamed argument or a call with
#'   no `resamples`.
#'
#' @return A `nested_results_set`: a tibble of class
#'   `c("nested_results_set", "tbl_df", "tbl", "data.frame")` with one row
#'   per workflow in the set's order and three columns. `wflow_id` is the
#'   set's id, `workflow` the workflow as the set held it, and `result` its
#'   `nested_results` as the orchestrator that ran returned it. `fn` is
#'   kept as an attribute. It does not carry the `workflow_set` class, so
#'   [workflowsets::rank_results()] and [tune::fit_best()] refuse it. A
#'   ranking of the set's workflows by their nested estimates, and a fit of
#'   the best, makes a selection the outer loop did not nest (see
#'   `vignette("estimate")`).
#'
#' @section What the set answers:
#'
#' Six reading functions stack each workflow's table under a `wflow_id`
#' column: [collect_metrics()], [collect_selections()],
#' [collect_inner_metrics()], [collect_notes()],
#' [collect_predictions()][collect_predictions.nested_results] and
#' [collect_extracts()][collect_predictions.nested_results].
#' [extract_workflow()] with an `id` returns one workflow, and
#' [nested_final_fit()] with an `id` fits one workflow by its own record.
#' `print()` shows the orchestrator and each workflow's completed fold
#' count. The `result` column of the set given as `object` is not read:
#' this function returns its results as its own object rather than filling
#' that column.
#'
#' @section Routing:
#'
#' A workflow with no parameter marked by [tune::tune()] runs through
#' [nested_fit_resamples()] whatever `fn` names, since the five tuning
#' orchestrators refuse it at entry. A baseline beside tuned models on the
#' same folds is the comparison a set exists for, and each element's record
#' names the procedure that ran. Every other workflow runs through `fn`.
#'
#' For each workflow the merged arguments are narrowed to what its
#' orchestrator accepts: its formals other than `object`, and, for a
#' workflow that runs through `fn`, the `control` in `...`. So a `grid` in
#' `...` reaches the tuned workflows and not the fixed one. A control's
#' class is `fn`'s own, and [nested_fit_resamples()] refuses a racing,
#' Bayesian or annealing control by that class. So a fixed workflow routed
#' there does not take the `control` in `...`. It runs under tune's default
#' [tune::control_resamples()] unless its `option` entry names one, which
#' is where a `save_pred` or `extract` for the baseline goes.
#'
#' A name that the orchestrator `fn` names does not take is refused at
#' entry, because narrowing otherwise drops a misspelled name for every
#' workflow without a message.
#' A name in a workflow's `option` entry that the orchestrator it routes to
#' does not take is refused naming the workflow. Under
#' `fn = "nested_fit_resamples"` every workflow must be fixed. One carrying
#' a marker is refused at entry by name, as that orchestrator refuses
#' it.
#'
#' @section Seeds:
#'
#' Seed the session before the call, as before any orchestrator. The
#' generator state the call holds once its entry checks have run is
#' reinstated before each workflow. So every workflow's fold `i` runs
#' under the same two seeds. Each element is `identical()` to the
#' orchestrator called by hand on that workflow, with the same arguments,
#' after the same `set.seed()`. Under a stochastic engine the workflows are
#' therefore paired on seeds as well as on folds. The caller's state is put
#' back on exit, and a session that had never drawn is left with no state,
#' as it was found. Each element runs its folds in parallel exactly as its
#' orchestrator does: a running mirai pool is used for every workflow's
#' folds, one round of folds per workflow.
#'
#' @section Warnings and errors from one workflow:
#'
#' An orchestrator warns when some of its outer folds failed, and a
#' reading function warns when it summarizes a partial run. Inside a set
#' those warnings are raised with the workflow's id at the front of the
#' message, under the same condition class. So a user who never calls a
#' reading function still learns which workflow lost folds.
#'
#' An error an
#' orchestrator raises for one workflow is raised the same way, when that
#' workflow's turn comes. A `grid` that names a parameter that workflow
#' does not tune is one such error, and a control of the wrong class is
#' another. The workflows before it have run by then. What is raised is
#' the original condition
#' object, with `Workflow "<id>": ` written in front of the first line of
#' its message and this function, or the reading function, as its call.
#' Its class vector, its `parent` and the cause chain, its bullets and
#' every field a handler reads are unchanged.
#'
#' @section Subsetting:
#'
#' You can take a subset of the set and it still answers for the workflows
#' it holds, since each row's `nested_results` describes its own run whole.
#' An operation keeps the class and the `fn` attribute when its result:
#'
#' - holds the three columns under those names, none repeated.
#' - has at least one row, with no `wflow_id` repeated.
#' - has each row's three values identical to the row of that id in the
#'   operation's first data-frame argument.
#'
#' So rows dropped or reordered and columns added keep the
#' class. `dplyr::filter()`, `dplyr::arrange()` and `dplyr::mutate()` do,
#' and so does `dplyr::bind_cols()` with the set first. So do `x[i, ]` and
#' `vctrs::vec_slice()` on a kept subset. What they hand back is a set
#' whose reading functions, `summary()`, `print()`, `extract_workflow()`
#' and [nested_final_fit()] answer for the rows in hand alone.
#'
#' Anything else comes back a plain tibble without the attribute. That
#' covers a record column dropped or renamed, no row left, and a
#' `wflow_id` repeated, as by `x[c(1, 1), ]`, `rbind(x, x)` or
#' `dplyr::bind_rows(x, x)`. It also covers a row that is not the run's
#' own, whether a `result` replaced or a row bound in from another set or
#' a bare table. And it covers `dplyr::bind_cols()` with a table first, and
#' a direct `vctrs::vec_cbind()`, which finalizes to a tibble before the
#' rule is asked. Replacing a value under the class with `$<-` or `[[<-` is
#' not checked, as it is not on a `nested_results`. `dplyr::group_by()`,
#' `dplyr::rowwise()` and `tibble::as_tibble()` return a grouped, a rowwise
#' and a plain tibble that is not a set and still carries the `fn`
#' attribute.
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
