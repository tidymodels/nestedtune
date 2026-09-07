# The `nested_results_set` surface (M71, D-058): one `nested_results` per
# workflow, and readers that stack each element's table under its id. The
# class adds no statistics of its own -- every number comes from an
# element's own reader -- and it registers none of the ranking or
# best-workflow methods the `workflow_set` class would bring: a choice among
# the set's workflows by their nested estimates is a selection the outer loop
# did not nest (IP3; `vignette("estimate")`).

#' Stack each workflow's table of a workflow-set run under its id
#'
#' @description
#' The six readers of a `nested_results` answer on a `nested_results_set`,
#' what [nested_workflow_map()] returns: each calls its single-workflow
#' method on every element and binds the tables in the set's order, with a
#' `wflow_id` column first. `collect_metrics()` gives one row per workflow
#' and metric summarized, or per workflow, outer fold and metric with
#' `summarize = FALSE`, where `wflow_id` stands ahead of the fold label
#' columns; `collect_selections()`, `collect_inner_metrics()`,
#' `collect_notes()`, `collect_predictions()` and `collect_extracts()` stack
#' their per-fold tables the same way.
#'
#' @param x A `nested_results_set` from [nested_workflow_map()].
#' @param ... Not used; must be empty. An argument passed here is an error
#'   rather than silently ignored.
#' @param summarize Whether to average each workflow's per-fold metrics
#'   (`TRUE`, the default) or return them one row per outer fold (`FALSE`),
#'   as on [collect_metrics.nested_results()].
#'
#' @return A tibble: `wflow_id` first, then the columns the single-workflow
#'   reader returns for each element, bound in the set's order over the
#'   union of the elements' columns, `NA` where an element lacks one (`NULL`
#'   in a list column). An element whose table has no rows contributes none.
#'
#' @details
#' Five of the readers read the folds that completed, as they do on one
#' workflow. A workflow in which no outer fold completed is left out of
#' their tables while another workflow completed one, with one warning of
#' class `nestedtune_partial_summary` naming it; a workflow in which some
#' folds failed contributes the folds that ran, with that reader's own
#' partial-run warning raised once for it, the workflow's id at the front of
#' the message; and a set in which no workflow completed a fold is refused
#' with class `nestedtune_no_completed_folds`. `collect_predictions()` and
#' `collect_extracts()` then refuse a set in which a workflow that would
#' contribute rows did not keep the column, with class
#' `nestedtune_column_not_saved` naming it: on a set a control reaches each
#' workflow through the call's `...` or its own `option` entry, so one
#' workflow can have kept what another did not. `collect_notes()` reads
#' every workflow, those in which no fold completed included, and refuses
#' nothing: a failed workflow's notes are the reason to ask.
#'
#' An element's table already carrying a `wflow_id` column -- a parameter
#' given that id -- is refused with class
#' `nestedtune_collect_name_collision`.
#'
#' @examplesIf rlang::is_installed(c("recipes", "yardstick", "workflowsets"))
#' data(mtcars)
#'
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
#' res <- nested_workflow_map(wset, resamples = folds, grid = data.frame(num_comp = 1:3))
#'
#' collect_metrics(res)
#' collect_metrics(res, summarize = FALSE)
#' collect_selections(res)
#' collect_notes(res)
#'
#' @seealso [nested_workflow_map()], [collect_metrics.nested_results()],
#'   [collect_selections()], [collect_predictions.nested_results()],
#'   [summary.nested_results_set()] for the set's `summary()`, `autoplot()`
#'   and `agreement()`
#' @name collect_metrics.nested_results_set
NULL

#' @rdname collect_metrics.nested_results_set
#' @export
collect_metrics.nested_results_set <- function(x, ..., summarize = TRUE) {
  rlang::check_dots_empty()
  stack_set(
    x,
    function(r) collect_metrics(r, summarize = summarize),
    call = rlang::current_env()
  )
}

#' @rdname collect_metrics.nested_results_set
#' @export
collect_selections.nested_results_set <- function(x, ...) {
  rlang::check_dots_empty()
  stack_set(x, collect_selections, call = rlang::current_env())
}

#' @rdname collect_metrics.nested_results_set
#' @export
collect_inner_metrics.nested_results_set <- function(x, ...) {
  rlang::check_dots_empty()
  stack_set(x, collect_inner_metrics, call = rlang::current_env())
}

#' @rdname collect_metrics.nested_results_set
#' @export
collect_notes.nested_results_set <- function(x, ...) {
  rlang::check_dots_empty()
  stack_set(
    x,
    collect_notes,
    call = rlang::current_env(),
    completed_only = FALSE
  )
}

#' @rdname collect_metrics.nested_results_set
#' @export
collect_predictions.nested_results_set <- function(x, ...) {
  rlang::check_dots_empty()
  stack_set(x, collect_predictions, call = rlang::current_env())
}

#' @rdname collect_metrics.nested_results_set
#' @export
collect_extracts.nested_results_set <- function(x, ...) {
  rlang::check_dots_empty()
  stack_set(x, collect_extracts, call = rlang::current_env())
}

# One reader mapped over the elements and bound under `wflow_id`.
#
# The element rule is the single-workflow rule applied per element: a
# reader that reads completed folds is given the elements with one, a
# workflow with none is left out with a warning naming it, and a set with
# none is refused under the class every summary door refuses with
# (`check_any_completed()`). Everything the element's reader raises --
# its partial-run warning, its refusal of a column the run did not keep --
# is re-signalled naming the workflow (`resignal_for_workflow()`,
# R/nested-workflow-map.R), so the set's conditions say which workflow they
# are about. The bind is vctrs', as `stack_fold_column()` binds folds.
#
# `action` and `noun` are the words the two refusals say -- "collect" and
# "table" for the readers, "plot" and "figure" for the set's `autoplot()`
# views, which stack their per-workflow frames through here (M72) so the
# fold-state rules are one code path.
stack_set <- function(
  x,
  reader,
  call,
  completed_only = TRUE,
  action = "collect",
  noun = "table"
) {
  ids <- x$wflow_id
  results <- x$result
  which <- seq_along(ids)
  if (completed_only) {
    completed <- vapply(results, function(r) any(r$.completed), logical(1))
    if (!any(completed)) {
      n <- length(ids)
      cli::cli_abort(
        c(
          "No outer fold of any workflow completed, so there is nothing \\
           to {action}.",
          x = "All {n} workflow{?s} failed on every outer fold.",
          i = "Call {.fn collect_notes} on the set, or {.fn summary} on \\
               each {.code x$result[[i]]}, for the stage each fold failed at."
        ),
        class = "nestedtune_no_completed_folds",
        call = call
      )
    }
    for (i in which(!completed)) {
      cli::cli_warn(
        c(
          "!" = "Workflow {.val {ids[[i]]}}: no outer fold completed, so \\
                 this {noun} leaves it out.",
          i = "Its {.code .notes} say what went wrong."
        ),
        class = "nestedtune_partial_summary",
        call = call
      )
    }
    which <- which(completed)
  }
  tables <- lapply(which, function(i) {
    tbl <- for_workflow(ids[[i]], call, reader(results[[i]]))
    if ("wflow_id" %in% names(tbl)) {
      cli::cli_abort(
        c(
          "Cannot stack workflow {.val {ids[[i]]}}: its table carries a \\
           column named {.val wflow_id}, the column the set names each \\
           workflow by.",
          i = "Give the parameter another id in {.fn tune::tune}."
        ),
        class = "nestedtune_collect_name_collision",
        call = call
      )
    }
    vctrs::new_data_frame(c(
      list(wflow_id = rep(ids[[i]], nrow(tbl))),
      as.list(tbl)
    ))
  })
  new_tbl(as.list(vctrs::vec_rbind(!!!tables)))
}

#' Summarize, plot and tabulate a workflow-set run
#'
#' @description
#' The three readers of one workflow's run answer on a `nested_results_set`,
#' what [nested_workflow_map()] returns, each workflow's view keyed by its
#' `wflow_id`. `summary()` summarizes every workflow; `autoplot()` draws
#' the two views of [autoplot.nested_results()] across the workflows; and
#' [agreement()] stacks each workflow's selection table under its id.
#'
#' @param x,object A `nested_results_set` from [nested_workflow_map()]; for
#'   the print method, the `summary.nested_results_set` that `summary()`
#'   returns.
#' @param type Which view to draw: `"parameters"` (the default) or
#'   `"performance"`, as on [autoplot.nested_results()].
#' @param ... Not used; must be empty. An argument passed here is an error
#'   rather than silently ignored.
#'
#' @return
#' `summary()` returns a `summary.nested_results_set`: a list of one
#' [summary.nested_results()] object per workflow, named by `wflow_id` in
#' the set's order, each the summary of that workflow's run called alone,
#' with the orchestrator's name as the list's `fn` attribute. Its print
#' shows the orchestrator and the workflow count, then one section per
#' workflow holding that run's design, failed folds, selected parameters
#' and estimate, and the note on what a nested estimate describes once at
#' the end.
#'
#' `autoplot()` returns a `ggplot` object. Under `type = "performance"`
#' the workflows stand along the x axis inside one panel per metric, one
#' point per completed outer fold's score and a dashed rule at each
#' workflow's nested estimate, the value [collect_metrics()] reports for it
#' on the set; the panels are named as the single view names them. Under
#' `type = "parameters"` there is one panel per workflow and tuned
#' parameter, in the set's order, labelled by the id and then the single
#' view's label for that parameter, with the outer folds along the x axis,
#' so each panel asks the single view's question of one workflow. The
#' selected-value axis is decided over every workflow's values at once:
#' numeric when all are numbers, discrete otherwise. A workflow with
#' nothing to tune contributes no panel.
#'
#' `agreement()` returns a tibble: `wflow_id`, then one column per
#' parameter any workflow's completed fold selected, then `n` and `prop`,
#' with each workflow's rows as [agreement()] on that run alone gives them,
#' in the set's order, `NA` in a column that workflow's run does not
#' tune; inside a workflow's own rows `NA` keeps the meaning [agreement()]
#' gives it there, a fold that recorded no value for the parameter. A
#' workflow with nothing to tune contributes no row.
#'
#' @details
#' The three readers follow the fold-state rules of the set's
#' [collect_metrics()][collect_metrics.nested_results_set]. A workflow in
#' which some outer folds failed is read over the folds that ran, with one
#' warning of class `nestedtune_partial_summary` naming it. A workflow in
#' which no fold completed is still summarized by `summary()`, which
#' describes a failed run rather than refusing; the performance view keeps
#' its slot on the x axis and draws nothing for it, the parameters view
#' draws no panel for it, and `agreement()` leaves it out, each warning
#' once naming it. A set in which
#' no workflow completed a fold is refused by the plots and by
#' `agreement()` with class `nestedtune_no_completed_folds`. A set in which
#' no workflow's completed fold recorded a selected parameter is refused
#' under `type = "parameters"` with class `nestedtune_no_tuned_parameters`.
#'
#' The performance view's subtitle names the workflow and fold counts and,
#' when any workflow has a failed fold, how many do; `summary()` names the
#' folds. A tuned parameter whose id is `wflow_id` cannot be tabulated
#' beside the set's own column and is refused with class
#' `nestedtune_collect_name_collision`; one whose id is `n` or `prop` is
#' refused as [agreement()] refuses it, the workflow named in front.
#'
#' @examplesIf rlang::is_installed(c("recipes", "yardstick", "workflowsets"))
#' data(mtcars)
#'
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
#' res <- nested_workflow_map(wset, resamples = folds, grid = data.frame(num_comp = 1:3))
#'
#' summary(res)
#' agreement(res)
#' autoplot(res)
#' autoplot(res, type = "performance")
#'
#' @seealso [collect_metrics.nested_results_set()], [summary.nested_results()],
#'   [autoplot.nested_results()], [agreement()], [nested_workflow_map()]
#' @name summary.nested_results_set
NULL

#' Print a workflow-set run
#'
#' Shows the orchestrator the set ran through, how many workflows it holds,
#' and for each workflow its id with how many of its outer folds completed
#' and the procedure that ran for it.
#'
#' @param x A `nested_results_set` from [nested_workflow_map()].
#' @param ... Not used; must be empty.
#'
#' @return `x`, invisibly.
#' @seealso [nested_workflow_map()], [collect_metrics.nested_results_set()]
#' @export
print.nested_results_set <- function(x, ...) {
  rlang::check_dots_empty()
  cli::cli_h1("Nested cross-validation results for a workflow set")
  fn <- attr(x, "fn")
  if (rlang::is_string(fn)) {
    cli::cli_text("Orchestrator: {.fn {fn}} ({orchestrator_label(fn)})")
  }
  n <- nrow(x)
  cli::cli_text("Workflows: {n}")
  bullets <- vapply(
    seq_len(n),
    function(i) {
      r <- x$result[[i]]
      completed <- sum(r$.completed)
      total <- nrow(r)
      label <- orchestrator_label(attr(r, "procedure")$tuner)
      cli::format_inline(
        "{.val {x$wflow_id[[i]]}}: {completed} of {total} outer \\
         fold{?s} completed ({label})"
      )
    },
    character(1)
  )
  status <- vapply(
    x$result,
    function(r) if (all(r$.completed)) "v" else "x",
    character(1)
  )
  cli::cli_bullets(stats::setNames(bullets, status))
  cli::cli_bullets(c(
    i = "Use {.fn collect_metrics} for every workflow's estimate under its \\
         id, and {.code x$result[[i]]} for one workflow's run."
  ))
  invisible(x)
}

# The registry's label for an orchestrator or a tuner name: the map records
# the orchestrator's name (`fn`), each element's procedure the tuner's.
orchestrator_label <- function(name) {
  key <- sub("^nested_", "", name)
  if (rlang::is_string(key) && key %in% names(tuner_registry)) {
    tuner_registry[[key]]$label
  } else {
    "unknown"
  }
}

#' Extract one workflow of a workflow-set run
#'
#' @param x A `nested_results_set` from [nested_workflow_map()].
#' @param id The `wflow_id` of the workflow to return, one of `x$wflow_id`.
#' @param ... Not used; must be empty.
#'
#' @return The workflow, untrained, as the set held it. An `id` naming no
#'   row of the set is refused with class `nestedtune_unknown_id`.
#'
#' @examplesIf rlang::is_installed(c("recipes", "yardstick", "workflowsets"))
#' data(mtcars)
#' rec <- recipes::recipe(mpg ~ ., data = mtcars)
#' wset <- workflowsets::workflow_set(
#'   preproc = list(none = rec),
#'   models = list(lm = parsnip::linear_reg())
#' )
#' set.seed(1)
#' folds <- nested_resamples(
#'   mtcars,
#'   outside = rsample::vfold_cv(v = 3),
#'   inside = rsample::vfold_cv(v = 3)
#' )
#' set.seed(2)
#' res <- nested_workflow_map(wset, resamples = folds)
#' extract_workflow(res, "none_lm")
#'
#' @seealso [nested_workflow_map()], [nested_final_fit()]
#' @export
extract_workflow.nested_results_set <- function(x, id, ...) {
  rlang::check_dots_empty()
  x$workflow[[match_set_id(x, id)]]
}

# The row `id` names, or a refusal naming the ids the set holds.
match_set_id <- function(x, id, call = rlang::caller_env()) {
  ids <- x$wflow_id
  if (missing(id) || !rlang::is_string(id) || !id %in% ids) {
    cli::cli_abort(
      c(
        "{.arg id} must name one workflow of the set: {.val {ids}}.",
        x = if (missing(id)) {
          "No {.arg id} was given."
        } else if (rlang::is_string(id)) {
          "Got {.val {id}}."
        } else {
          "Got {.obj_type_friendly {id}}."
        }
      ),
      class = "nestedtune_unknown_id",
      call = call
    )
  }
  match(id, ids)
}

# What an operation may and may not do to a `nested_results_set` (M73,
# D-059).
#
# The set's record is per row. Each row's `nested_results` describes its own
# run whole, so a row dropped or reordered leaves every row in hand still
# true of itself, and the class stays on -- where the single class sheds it
# (D-031), because a fold table's record describes one design and fewer
# rows than the design's cannot answer for it. What the set cannot vouch
# for is a row that is not one of the run's own: repeated, added from
# elsewhere, or with its `result` swapped for another row's. Those, a
# record column gone or renamed, a name duplicated over a record column,
# and a set with no row left come back a bare tibble, the orchestrator
# attribute gone with the class (IP4).
#
# Five doors route to the one rule, as the single class's do
# (R/nested-results.R): `dplyr_reconstruct()` for the verbs, `[`,
# `vec_restore()` for `vec_slice()` and the combinations, base `rbind()`,
# and `names<-` for `dplyr::rename()`. No `vec_ptype2()`/`vec_cast()`
# lattice is registered: vctrs' same-class fallback carries the class into
# `vec_restore()` for a combination of two sets, where the rule sheds it, a
# set combined with a bare table finalizes to a bare tibble before the rule
# is asked, and so does a direct `vctrs::vec_cbind()` (measured 2026-09-07;
# a candidate ROADMAP row). `$<-` and `[[<-` on a record column keep the
# class without consulting the rule, the blind spot `R/nested-results.R`
# records for the single class.

# The template's record: the three columns the constructor writes.
set_record_columns <- function() {
  c("wflow_id", "workflow", "result")
}

# Whether `data` may wear `template`'s class: the three record columns
# present under their names with none repeated, at least one row, no id
# repeated, and every row's three values identical to the template's row of
# that id. The template is the first data-frame argument of the operation,
# so a combination of two subsets, or of two map runs, is not a set
# (D-059). A template that is not itself a set vouches for nothing.
can_reconstruct_set <- function(data, template) {
  cols <- set_record_columns()
  if (
    !is.data.frame(data) ||
      !inherits(template, "nested_results_set") ||
      !all(cols %in% names(template)) ||
      !all(cols %in% names(data)) ||
      duplicated_record_names(names(data), cols) ||
      nrow(data) == 0L
  ) {
    return(FALSE)
  }
  ids <- data[["wflow_id"]]
  if (!is.character(ids) || anyDuplicated(ids) > 0L) {
    return(FALSE)
  }
  rows <- match(ids, template[["wflow_id"]])
  if (anyNA(rows)) {
    return(FALSE)
  }
  for (nm in cols) {
    if (!identical(data[[nm]], template[[nm]][rows])) {
      return(FALSE)
    }
  }
  TRUE
}

# The rule. The orchestrator name comes from the template; the rows in hand
# describe themselves.
reconstruct_set <- function(data, template) {
  if (!can_reconstruct_set(data, template)) {
    return(bare_set(data))
  }
  out <- as_results_tbl(data)
  if (!inherits(out, "nested_results_set")) {
    class(out) <- c("nested_results_set", class(out))
  }
  attr(out, "fn") <- attr(template, "fn")
  out
}

# Shedding the class sheds the orchestrator attribute with it: a bare tibble
# still naming the orchestrator would leave the stale claim readable.
bare_set <- function(data) {
  attr(data, "fn") <- NULL
  class(data) <- setdiff(class(data), "nested_results_set")
  as_results_tbl(data)
}

#' @export
dplyr_reconstruct.nested_results_set <- function(data, template) {
  reconstruct_set(data, template)
}

#' @export
`[.nested_results_set` <- function(x, i, j, ...) {
  out <- NextMethod()
  if (!is.data.frame(out)) {
    return(out)
  }
  reconstruct_set(out, x)
}

# `vec_slice()` hands the original as `to`; a combination hands a zero-row
# prototype, whose rows match none of the rows in hand, and `vec_cbind()`
# one with no columns, which the rule refuses for lacking the record.
#' @export
vec_restore.nested_results_set <- function(x, to, ...) {
  reconstruct_set(x, to)
}

# Base `rbind()` reaches no generic either package dispatches on. The
# arguments go in stripped so the `rbind()` inside is base R's data-frame
# method, and the result is put through the rule against the first
# argument.
#' @export
rbind.nested_results_set <- function(..., deparse.level = 1) {
  args <- list(...)
  parts <- lapply(args, function(a) {
    if (is.data.frame(a)) bare_set(a) else a
  })
  out <- do.call(base::rbind, c(parts, list(deparse.level = deparse.level)))
  if (!is.data.frame(out)) {
    return(out)
  }
  reconstruct_set(out, args[[1L]])
}

# `dplyr::rename()` is `set_names()`, reaching the class through `names<-`
# alone. Renaming moves no value, so the rule's comparison passes exactly
# when each record column still answers to its name and no other column has
# taken one.
#' @export
`names<-.nested_results_set` <- function(x, value) {
  out <- NextMethod()
  if (!is.data.frame(out)) {
    return(out)
  }
  reconstruct_set(out, x)
}
