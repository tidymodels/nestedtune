# The readers that stack a per-fold list column with the fold labels beside
# it (M65, D-052). Each is one call in place of an apply loop that hardcodes
# `id`, which is wrong on a repeated design: the labels come from the object's
# record (D-036), through stack_fold_column() in R/nested-results.R.
#
# collect_notes() is a method on tune's generic, because the generic exists
# and its shape -- label columns, then `location`, `type`, `note`, `trace` --
# is the shape wanted. collect_selections() and collect_inner_metrics() are
# this package's own generics, on the pattern agreement() and the extract
# accessors set (D-023, D-039): a default that refuses as a classed
# condition, and one method.

#' Stack a per-fold column of a nested resampling run across the outer folds
#'
#' @description
#' `collect_notes()`, `collect_selections()` and `collect_inner_metrics()`
#' each give you one of a run's per-fold records as a single table. A
#' `nested_results` keeps three such records as one table per outer fold,
#' in list columns. They are what went wrong (`.notes`), what the fold's
#' inner tuning selected (`.selected`), and everything that tuning scored
#' (`.inner_metrics`). Each function stacks one column across the folds,
#' the design's fold labels first, so every row says which fold it came
#' from.
#'
#' * `collect_notes()` stacks `.notes` over every outer fold, failed folds
#'   included. A completed fold can carry an error note too, from an `extract`
#'   that failed on it (see
#'   [`collect_extracts()`][collect_predictions.nested_results]).
#' * `collect_selections()` stacks `.selected`: one row per completed fold. A
#'   [nested_fit_resamples()] result gives no rows, because no fold selected
#'   anything.
#' * `collect_inner_metrics()` stacks `.inner_metrics`: one row per
#'   candidate, a parameter setting, and metric that a completed fold's
#'   inner tuning scored, and per iteration where the tuner iterates.
#'
#' @inheritParams collect_metrics.nested_results
#'
#' @return A tibble whose first columns are the design's fold labels and whose
#'   remaining columns come from the stacked tables. See What the columns are.
#'
#' @section What the columns are:
#'
#' The first columns are the design's fold labels: `id` on a plain v-fold
#' design, `id` and `id2` on a repeated one, read from the object's record
#' rather than recognized by name.
#' Then come the stacked tables' own columns, over the union of what any
#' stacked fold carries. A fold lacking one holds `NA` there, exactly as a fold
#' whose recorded value is `NA` does, so the two cannot be told apart.
#'
#' `collect_notes()` stacks tune's four note columns, from `location` to
#' `trace`. A run that recorded no note gives no rows with those columns. A
#' stacked table carrying a column named like a label column, say a
#' parameter whose id is `id`, is refused with class
#' `nestedtune_collect_name_collision`.
#'
#' @section Which folds are read:
#'
#' `collect_selections()` and `collect_inner_metrics()` read the folds that
#' completed, as [collect_metrics()] and [agreement()] do. A run with some
#' folds failed is stacked over the rest, with one warning of class
#' `nestedtune_partial_summary` naming the missing folds. A run in which no
#' fold completed is an error of class `nestedtune_no_completed_folds`.
#' `collect_notes()` reads every fold and warns about none.
#'
#' @section Reading `.config`:
#'
#' The `.config` of a selection or an inner-metrics row is kept as the fold
#' recorded it. It labels a candidate inside that one fold's tuning run. So
#' a selected row's `.config` is found among the same fold's rows in
#' `collect_inner_metrics()`. Because folds can search different candidates, it
#' identifies nothing across them, which is why [agreement()] leaves it out.
#'
#' @template example-setup
#' @template example-run
#' @examplesIf rlang::is_installed(c("recipes", "yardstick"))
#' collect_selections(res)
#' collect_inner_metrics(res)
#' collect_notes(res)
#'
#' @templateVar LINKS [collect_metrics()], [agreement()], [summary.nested_results()]
#' @templateVar WHAT functions
#' @template seealso-reader
#' @name collect_selections
#' @export
collect_selections <- function(x, ...) {
  UseMethod("collect_selections")
}

#' @export
collect_selections.default <- function(x, ...) {
  rlang::check_dots_empty()
  # `current_env()` rather than `caller_env()`, for agreement.default()'s
  # reason: inside a method reached by UseMethod() it renders the generic's
  # own call.
  abort_no_collect_method("collect_selections", x, call = rlang::current_env())
}

#' @rdname collect_selections
#' @export
collect_selections.nested_results <- function(x, ...) {
  rlang::check_dots_empty()
  check_any_completed(x, action = "collect")
  warn_partial_summary(x, noun = "table")
  stack_fold_column(
    x,
    ".selected",
    completed_only = TRUE,
    call = rlang::current_env()
  )
}

#' @rdname collect_selections
#' @export
collect_inner_metrics <- function(x, ...) {
  UseMethod("collect_inner_metrics")
}

#' @export
collect_inner_metrics.default <- function(x, ...) {
  rlang::check_dots_empty()
  abort_no_collect_method(
    "collect_inner_metrics",
    x,
    call = rlang::current_env()
  )
}

#' @rdname collect_selections
#' @export
collect_inner_metrics.nested_results <- function(x, ...) {
  rlang::check_dots_empty()
  check_any_completed(x, action = "collect")
  warn_partial_summary(x, noun = "table")
  stack_fold_column(
    x,
    ".inner_metrics",
    completed_only = TRUE,
    call = rlang::current_env()
  )
}

#' @rdname collect_selections
#' @export
collect_notes.nested_results <- function(x, ...) {
  rlang::check_dots_empty()
  stack_fold_column(
    x,
    ".notes",
    completed_only = FALSE,
    call = rlang::current_env()
  )
}

# The refusal for every object the two owned generics have no method for,
# shaped like abort_no_agreement_method() so the families cannot drift apart
# in what they say. Classed, so a caller can catch it as this package's own.
abort_no_collect_method <- function(fn, x, call = rlang::caller_env()) {
  cli::cli_abort(
    c(
      "{.fn {fn}} has no method for {.obj_type_friendly {x}}.",
      i = "It answers for a {.cls nested_results} object, from \\
           {.fn nested_tune_grid} or one of its siblings."
    ),
    class = "nestedtune_no_collect_method",
    call = call
  )
}

# The two readers over what the outer fit kept (M68). Both are methods on
# tune's generics, re-exported beside collect_notes(): the names exist and
# their shapes are the shapes wanted. A run that did not ask for a column is
# refused by name, so a caller learns which control slot to set rather than
# reading an absent column as an empty one.

#' Stack the outer fit's predictions or extracts across the outer folds
#'
#' @description
#' `collect_predictions()` and `collect_extracts()` give you the outer
#' fit's predictions or extracts as one table across the folds. A run whose
#' control asked for them keeps two more records per outer fold.
#' `.predictions`, under `save_pred = TRUE`, holds the predictions the
#' fold's finalized model made on its assessment rows. `.extracts` holds
#' whatever the control's `extract` function returned for the fold's fitted
#' workflow. These two methods on tune's generics stack one such column
#' into a single table, the design's fold labels first.
#'
#' * `collect_predictions()` gives one row per assessment row of every
#'   completed fold, with the columns `tune::last_fit()` produced: the
#'   outcome, the prediction columns, `.row` and `.config`. With
#'   `summarize = TRUE` it gives one averaged row per data row instead. See
#'   Averaging across the folds.
#' * `collect_extracts()` gives one row per completed fold, the fold's value in
#'   an `.extracts` list column. A completed fold whose extract function
#'   errored holds `NULL` there, and its `.notes` say why.
#'
#' @param x A `nested_results` run with a control that asked for the column.
#'   See [collect_metrics.nested_results()] for what the object is.
#' @param ... Not used. It must be empty. tune's `parameters` argument is not
#'   offered here, because each fold predicted with the parameters it
#'   selected.
#' @param summarize For `collect_predictions()`, whether to average the
#'   predictions per data row (`TRUE`) or return them per fold (`FALSE`, the
#'   default). See Averaging across the folds.
#'
#' @return A tibble: the design's fold labels (`id`, and `id2` on a repeated
#'   design), then the stacked prediction columns, or the `.extracts` list
#'   column. With `summarize = TRUE`, the columns of the per-fold table in
#'   the same order, less the fold labels and `.config`, with one row per
#'   `.row` in `.row` order.
#'
#' @section Folds that failed, and columns not saved:
#'
#' Both take the folds that completed, as [collect_selections()] does. They
#' warn once with class `nestedtune_partial_summary` on a partial run and
#' error with class `nestedtune_no_completed_folds` when no fold completed.
#'
#' An object whose recorded control did not ask for the column, or that no
#' longer carries it, is refused with class `nestedtune_column_not_saved`.
#' The message names the control slot to set. A prediction table carrying a
#' column named like a fold label column is refused with class
#' `nestedtune_collect_name_collision`.
#'
#' @section Which predictions these are:
#'
#' Will a row appear twice? On a v-fold outer design each row appears once
#' per repeat. On a Monte Carlo design it appears as often as it was held
#' out. These are the outer fit's predictions on the assessment rows.
#' The inner tuning run's own predictions and extracts, which the same two
#' control slots save inside tune, are not kept.
#'
#' @section Averaging across the folds:
#'
#' `summarize = TRUE` averages, for each data row, the predictions of every
#' completed fold that held the row out. A row that no completed fold held
#' out is left out, and a partial run warns once, as above. The rules are
#' tune's for `summarize = TRUE`, except where a rule below says otherwise.
#' The columns the run saved decide which rule applies.
#'
#' * A numeric prediction, such as a regression's `.pred`, is its mean with
#'   missing values ignored.
#' * Class probabilities are each averaged the same way, then divided by the
#'   row's sum of those averages. A `.pred_class` saved beside them is
#'   recomputed as the class with the largest averaged probability. It is
#'   recomputed whatever a postprocessor set in the saved predictions. A row
#'   whose averaged probabilities are missing gets a missing class, where
#'   tune gives it the first level.
#' * A `.pred_class` saved without probabilities is the most frequent class.
#'   A missing vote counts as a class of its own, as in tune, so the class
#'   is missing only when missing votes outnumber every level.
#' * A censored run takes the median `.pred_time`, which is missing if any
#'   fold's value is. The survival probabilities in `.pred` take, per
#'   `.eval_time`, the mean `.pred_survival` and `.weight_censored` with
#'   missing values ignored.
#'
#' A tie, between votes or between averaged probabilities, goes to the first
#' of the tied levels in the factor's level order.
#'
#' tune's own average groups the rows by candidate. Here each fold selected
#' its own candidate, so the average spans the candidates the folds
#' selected, and the fold labels and `.config` are dropped. Quantile
#' predictions are not averaged: a run whose saved predictions carry a
#' `.pred_quantile` column is refused with class
#' `nestedtune_summarize_quantile`.
#'
#' @template example-setup
#' @examplesIf rlang::is_installed(c("recipes", "yardstick"))
#' # Ask the control to keep the predictions and a coefficient extract.
#' set.seed(2)
#' res <- nested_tune_grid(
#'   wf,
#'   folds,
#'   grid = data.frame(num_comp = 1:2),
#'   control = tune::control_grid(
#'     save_pred = TRUE,
#'     extract = function(x) coef(workflows::extract_fit_engine(x))
#'   )
#' )
#'
#' collect_predictions(res)
#' collect_extracts(res)
#'
#' # A repeated design holds each row out once per repeat. The average
#' # gives one prediction per row.
#' set.seed(3)
#' repeated <- nested_resamples(
#'   mtcars,
#'   outside = rsample::vfold_cv(v = 2, repeats = 2),
#'   inside = rsample::vfold_cv(v = 2)
#' )
#' res_rep <- nested_tune_grid(
#'   wf,
#'   repeated,
#'   grid = data.frame(num_comp = 1:2),
#'   control = tune::control_grid(save_pred = TRUE)
#' )
#' collect_predictions(res_rep, summarize = TRUE)
#'
#' @templateVar LINKS [collect_selections()], [collect_metrics()], [nested_tune_grid()]
#' @templateVar WHAT functions
#' @template seealso-reader
#' @name collect_predictions.nested_results
NULL

#' @rdname collect_predictions.nested_results
#' @export
collect_predictions.nested_results <- function(x, ..., summarize = FALSE) {
  rlang::check_dots_empty()
  check_any_completed(x, action = "collect")
  check_column_saved(x, ".predictions", call = rlang::current_env())
  if (summarize) {
    check_predictions_rows(
      x,
      verb = "collect_predictions",
      call = rlang::current_env()
    )
    check_no_quantile(
      x,
      verb = "collect_predictions",
      call = rlang::current_env()
    )
  }
  warn_partial_summary(x, noun = "table")
  out <- stack_fold_column(
    x,
    ".predictions",
    completed_only = TRUE,
    call = rlang::current_env()
  )
  if (summarize) {
    out <- average_fold_predictions(out, drop = c(id_columns(x), ".config"))
  }
  out
}

# One averaged prediction per data row (M124). The average spans every
# completed fold that held the row out, whatever candidate each fold
# selected, so the fold labels and `.config` are dropped: neither names
# anything a row's average shares. The rule for each column is read from
# the columns the run saved, which tune picked from the metric types. The
# run's metric set is not read, because a run on tune's default metrics
# records none. The rules are tune 2.1.0's (`prob_summarize()`,
# `class_summarize()`, `numeric_summarize()` and `surv_summarize()`, read
# 2026-09-28), written here rather than called, because tune's internals
# carry no stability promise (M28). Ties go to the first level in factor
# order. One departure: a row whose averaged probabilities are missing gets
# a missing class, where `prob_summarize()` gives it the first level.
average_fold_predictions <- function(preds, drop) {
  preds <- preds[setdiff(names(preds), drop)]
  rows <- sort(unique(preds$.row))
  group <- factor(match(preds$.row, rows), levels = seq_along(rows))
  first <- match(rows, preds$.row)
  per_row <- function(v, fn) {
    vapply(split(v, group), fn, numeric(1), USE.NAMES = FALSE)
  }
  mean_na_rm <- function(v) mean(v, na.rm = TRUE)

  nms <- names(preds)
  # A factor outcome names the probability columns, one per level, so a
  # level named like `time` is never read as a censored column.
  others <- nms[!startsWith(nms, ".pred") & nms != ".row"]
  outcome <- Filter(function(nm) is.factor(preds[[nm]]), others)
  prob_cols <- if (length(outcome) == 1L) {
    intersect(paste0(".pred_", levels(preds[[outcome]])), nms)
  } else {
    character(0)
  }
  if (length(prob_cols) > 0L) {
    probs <- matrix(
      unlist(lapply(prob_cols, function(nm) per_row(preds[[nm]], mean_na_rm))),
      ncol = length(prob_cols)
    )
    probs <- probs / rowSums(probs)
  }

  cols <- lapply(nms, function(nm) {
    v <- preds[[nm]]
    if (nm %in% prob_cols) {
      return(probs[, match(nm, prob_cols)])
    }
    if (nm == ".pred_class" && length(prob_cols) > 0L) {
      return(class_from_probs(probs, prob_cols, v, preds[[outcome]]))
    }
    if (nm == ".pred_class") {
      return(class_by_vote(v, group))
    }
    if (nm == ".pred_time") {
      return(per_row(v, stats::median))
    }
    if (nm == ".pred" && is.list(v)) {
      return(average_survival(v, group))
    }
    if (startsWith(nm, ".pred") && is.numeric(v)) {
      return(per_row(v, mean_na_rm))
    }
    vctrs::vec_slice(v, first)
  })
  names(cols) <- nms
  new_tbl(cols)
}

# Quantile predictions are not averaged (M124). tune 2.1.0 refuses a
# quantile metric set passed to `fit_resamples()`, but it runs a quantile
# model on its default metric and averages those predictions with
# `quantile_summarize()`. That rule is not ported, because checking a port
# against it needs a quantile engine in Suggests. Read per fold before
# stacking, so the refusal is this one and not whatever binding a quantile
# column with the other folds raises. `augment()` averages on a design that
# holds a row out more than once, and refuses under the same class there
# (M125).
check_no_quantile <- function(x, verb, call = rlang::caller_env()) {
  verb <- rlang::arg_match(verb, c("collect_predictions", "augment"))
  has <- vapply(
    x$.predictions[x$.completed],
    function(p) ".pred_quantile" %in% names(p),
    logical(1)
  )
  if (!any(has)) {
    return(invisible(x))
  }
  msg <- switch(
    verb,
    collect_predictions = c(
      "{.code summarize = TRUE} cannot average quantile predictions.",
      x = "The saved predictions carry a {.field .pred_quantile} column.",
      i = "Call {.fn collect_predictions} with {.code summarize = FALSE} \\
           for the per-fold predictions."
    ),
    augment = c(
      "{.fn augment} cannot average quantile predictions.",
      x = "The outer design holds some data rows out more than once, and \\
           the saved predictions carry a {.field .pred_quantile} column.",
      i = "Read the per-fold predictions with {.fn collect_predictions}."
    )
  )
  cli::cli_abort(msg, class = "nestedtune_summarize_quantile", call = call)
}

# The class at the largest averaged probability. `which.max()` returns the
# first of tied maxima, and `prob_cols` is in factor order. Orderedness
# follows the outcome, as in tune's `prob_summarize()`, not the saved class.
class_from_probs <- function(probs, prob_cols, saved, outcome) {
  idx <- apply(probs, 1L, function(r) {
    if (all(is.na(r))) NA_integer_ else which.max(r)
  })
  labels <- substring(prob_cols, nchar(".pred_") + 1L)
  factor(
    labels[idx],
    levels = levels(saved),
    ordered = is.ordered(outcome)
  )
}

# The most frequent class per row. A missing vote is counted as a class of
# its own, placed after the levels, as tune's `dplyr::count()` counts it, so
# it wins only when it outnumbers every level. `max.col(ties.method =
# "first")` takes the first level among tied counts.
class_by_vote <- function(v, group) {
  counts <- unclass(table(group, addNA(v, ifany = FALSE)))
  idx <- max.col(counts, ties.method = "first")
  idx[idx > nlevels(v)] <- NA_integer_
  factor(levels(v)[idx], levels = levels(v), ordered = is.ordered(v))
}

# The censored `.pred` list column: per row and `.eval_time`, the mean of
# every other column with missing values ignored, in the order the times
# first appear.
average_survival <- function(v, group) {
  sizes <- vapply(v, function(t) if (is.null(t)) 0L else nrow(t), integer(1))
  long <- vctrs::vec_rbind(!!!v)
  long_group <- rep(as.integer(group), sizes)
  key <- vctrs::vec_group_id(
    vctrs::new_data_frame(list(g = long_group, t = long$.eval_time))
  )
  first <- match(seq_len(attr(key, "n")), key)
  averaged <- lapply(names(long), function(nm) {
    if (nm == ".eval_time") {
      return(long$.eval_time[first])
    }
    vapply(
      split(long[[nm]], factor(key, levels = seq_along(first))),
      function(x) mean(x, na.rm = TRUE),
      numeric(1),
      USE.NAMES = FALSE
    )
  })
  names(averaged) <- names(long)
  averaged <- new_tbl(averaged)
  owner <- factor(long_group[first], levels = seq_len(nlevels(group)))
  unname(lapply(split(seq_along(first), owner), function(i) {
    vctrs::vec_slice(averaged, i)
  }))
}

#' @rdname collect_predictions.nested_results
#' @export
collect_extracts.nested_results <- function(x, ...) {
  rlang::check_dots_empty()
  check_any_completed(x, action = "collect")
  check_column_saved(x, ".extracts", call = rlang::current_env())
  warn_partial_summary(x, noun = "table")
  # A fold's extract is one value of whatever kind the function returned,
  # so each becomes a one-row table holding it in a list column, tune's own
  # shape; a NULL (the function errored on that fold) is a row too, so the
  # table has one row per completed fold and a missing value is seen rather
  # than dropped (IP4).
  tables <- lapply(x$.extracts, function(v) new_tbl(list(.extracts = list(v))))
  stack_fold_column(
    x,
    ".extracts",
    completed_only = TRUE,
    call = rlang::current_env(),
    tables = tables
  )
}

# Scoring the saved predictions again (M92). A method on tune's generic, for
# the reason collect_predictions() is one. Each completed row of `x` is scored
# on its own, so a repeated design's folds stay apart: tune's own method
# groups the stacked predictions by `id` alone, which on a repeated design is
# the repeat, so it pools each repeat's folds into one score. The
# per-fold tables then go through per_fold_metrics() and summarize_folds(),
# the code collect_metrics() reads, so the two readers cannot disagree about
# shape, fold labels or the handling of an NA fold. The metric set is called
# as tune calls it inside `last_fit()` (`tune:::.estimate_metrics()` and its
# `estimate_*()` helpers, tune 2.1.0, read 2026-09-13), not through those
# internals, which carry no stability promise (M28).

#' Score the saved predictions of a nested run with a metric set
#'
#' @description
#' `compute_metrics()` scores the predictions a run kept under
#' `save_pred = TRUE` with a metric set you give it. The table it returns
#' has the shape and the averaging of [collect_metrics()]. You get a metric
#' the run did not compute without running the nested loop again.
#'
#' @inheritParams collect_metrics.nested_results
#' @param x A `nested_results` from [nested_tune_grid()] or one of its
#'   siblings, run with `save_pred = TRUE` in its control.
#' @param metrics A [yardstick::metric_set()].
#' @param ... Not used. It must be empty.
#' @param event_level For a two-class outcome, which level is the event:
#'   `"first"` or `"second"`. The default, `NULL`, takes the level the run
#'   recorded. tune's own method defaults to `"first"` instead.
#'
#' @return A tibble, summarized or per fold as [collect_metrics()] returns
#'   it in the long shape. Given
#'   the metric set and the event level the run used, it is identical to
#'   `collect_metrics(x, summarize = summarize)`. Per fold, the first
#'   columns are the design's fold labels, each in its own column: `id`,
#'   and `id2` on a repeated design.
#'
#' @section What is scored again, and what is not:
#'
#' Each outer fold kept the predictions its outer fit made on the fold's
#' assessment rows. Those rows are scored again, fold by fold, and the
#' per-fold scores are averaged as [collect_metrics()] averages them. A
#' fold that scores `NA` is left out of the mean, and `n` counts the folds
#' behind each row.
#'
#' The inner selection is not run again. Every fold keeps the parameters it
#' selected under the metrics of the run, and only the scoring of its outer
#' fit changes. A metric that is to choose the parameters has to be given
#' to the run itself.
#'
#' On a repeated design each repeat of a fold is scored as its own fold.
#'
#' @templateVar TITLE Refusals
#' @template refusals-saved-run
#' @section Refusals:
#' A `metrics` that is not a metric set is refused with class
#' `nestedtune_bad_metrics`. A metric that reads a kind of prediction the
#' run did not save is refused with class
#' `nestedtune_metric_type_not_saved`. An example is a class metric such as
#' `accuracy` on a run whose metrics read only class probabilities.
#'
#' A completed fold whose saved predictions do not match the rows it held
#' out is refused with class `nestedtune_compute_metrics_predictions`,
#' before any fold is scored. Its `.row` column must hold each of those
#' rows once and no other row. Five shapes this refuses are a missing row,
#' a repeated `.row`, an `NA` `.row`, a row the fold did not hold out, and
#' no `.row` column. A `.row` that is not a whole number is refused too.
#' The message names each fold that fails. [augment()] refuses the same
#' shapes.
#'
#' A run with some failed folds is scored over the rest, with a warning of
#' class `nestedtune_partial_summary`.
#'
#' @template example-setup
#' @examplesIf rlang::is_installed(c("recipes", "yardstick"))
#' set.seed(2)
#' res <- nested_tune_grid(
#'   wf,
#'   folds,
#'   grid = data.frame(num_comp = 1:2),
#'   control = tune::control_grid(save_pred = TRUE)
#' )
#'
#' # The run scored rmse and rsq. Score its predictions with mae as well.
#' compute_metrics(res, yardstick::metric_set(yardstick::mae))
#' compute_metrics(res, yardstick::metric_set(yardstick::mae), summarize = FALSE)
#'
#' @templateVar LINKS [collect_metrics.nested_results()], [collect_predictions.nested_results()], [augment.nested_results()]
#' @templateVar WHAT function
#' @template seealso-reader
#' @export
compute_metrics.nested_results <- function(
  x,
  metrics,
  ...,
  summarize = TRUE,
  event_level = NULL
) {
  rlang::check_dots_empty()
  call <- rlang::current_env()
  check_score_metrics(metrics, call = call)
  if (is.null(event_level)) {
    # A run built before the procedure was recorded (M46) takes tune's default.
    event_level <- attr(x, "procedure")$event_level
    if (is.null(event_level)) event_level <- "first"
  }
  check_event_level(event_level, call = call)
  check_any_completed(x, action = "score")
  check_column_saved(x, ".predictions", call = call)
  check_predictions_rows(x, verb = "compute_metrics", call = call)

  completed <- which(x$.completed)
  classes <- metric_classes(metrics)
  check_metric_types_saved(
    x$.predictions[[completed[[1L]]]],
    classes,
    call = call
  )
  warn_partial_summary(x)

  frames <- lapply(seq_len(nrow(x)), function(i) {
    if (!x$.completed[[i]]) {
      return(new_tbl(list(.metric = character(0))))
    }
    score_fold(x$.predictions[[i]], metrics, classes, event_level)
  })
  per_fold <- per_fold_metrics(x, frames)
  if (!summarize) {
    return(per_fold)
  }
  summarize_folds(per_fold)
}

check_score_metrics <- function(metrics, call = rlang::caller_env()) {
  if (inherits(metrics, "metric_set")) {
    return(invisible(metrics))
  }
  cli::cli_abort(
    c(
      "{.arg metrics} must be a {.fn yardstick::metric_set}.",
      x = "Got {.obj_type_friendly {metrics}}."
    ),
    class = "nestedtune_bad_metrics",
    call = call
  )
}

# Each metric's yardstick class, in the order of the set. The class names the
# kind of prediction the metric reads, which is what tune's `pred_type()`
# maps (tune 2.1.0).
metric_classes <- function(metrics) {
  vapply(
    attr(metrics, "metrics"),
    function(m) setdiff(class(m), "function")[[1L]],
    character(1)
  )
}

# The prediction columns scoring needs, read against the columns the run
# saved rather than against the metric set it recorded: a run on tune's
# default metric set records none, and the columns are what scoring reads.
# `.pred` is numeric for a regression and a list column for a survival
# prediction, so each kind asks for the one it reads.
check_metric_types_saved <- function(
  preds,
  classes,
  call = rlang::caller_env()
) {
  outcome <- outcome_column(preds)
  levels <- levels(preds[[outcome]])
  numeric_pred <- is.numeric(preds[[".pred"]])
  list_pred <- is.list(preds[[".pred"]])
  lacking <- lapply(unique(classes), function(cls) {
    switch(
      cls,
      numeric_metric = if (numeric_pred) character(0) else ".pred",
      class_metric = setdiff(".pred_class", names(preds)),
      prob_metric = ,
      ordered_prob_metric = if (is.null(levels)) {
        ".pred_<level>"
      } else {
        setdiff(paste0(".pred_", levels), names(preds))
      },
      dynamic_survival_metric = ,
      integrated_survival_metric = if (list_pred) character(0) else ".pred",
      static_survival_metric = setdiff(".pred_time", names(preds)),
      linear_pred_survival_metric = setdiff(".pred_linear_pred", names(preds)),
      quantile_metric = setdiff(".pred_quantile", names(preds)),
      # A metric class tune does not score is a prediction no run saves.
      paste0("<", cls, ">")
    )
  })
  lacking <- unique(unlist(lacking))
  if (length(lacking) == 0L) {
    return(invisible(preds))
  }
  saved <- setdiff(names(preds), c(outcome, ".row", ".config"))
  cli::cli_abort(
    c(
      "{.arg metrics} needs predictions this run did not save.",
      x = "Not saved in the form needed: {.val {lacking}}.",
      i = "The run saved {.val {saved}}. To score another kind of \\
           prediction, run it again with a metric of that kind in \\
           {.arg metrics}."
    ),
    class = "nestedtune_metric_type_not_saved",
    call = call
  )
}

# The outcome column of a saved prediction table: the one column that is
# neither a prediction nor one of the columns tune adds beside them.
outcome_column <- function(preds) {
  nms <- names(preds)
  nms <- nms[!grepl("^\\.pred", nms)]
  setdiff(nms, c(".row", ".config", ".case_weights", ".iter", ".eval_time"))[[
    1L
  ]]
}

# One fold's metrics, the metric set called with the arguments tune gives it
# for each kind of metric.
score_fold <- function(preds, metrics, classes, event_level) {
  truth <- rlang::sym(outcome_column(preds))
  weights <- if (".case_weights" %in% names(preds)) {
    rlang::sym(".case_weights")
  }
  survival <- c(
    "dynamic_survival_metric",
    "integrated_survival_metric",
    "static_survival_metric",
    "linear_pred_survival_metric"
  )
  class_prob <- c("class_metric", "prob_metric", "ordered_prob_metric")

  if (all(classes %in% class_prob)) {
    estimate <- if (any(classes == "class_metric")) rlang::sym(".pred_class")
    probs <- NULL
    if (any(classes %in% c("prob_metric", "ordered_prob_metric"))) {
      probs <- paste0(".pred_", levels(preds[[as.character(truth)]]))
      if (length(probs) == 2L) {
        probs <- probs[[if (identical(event_level, "first")) 1L else 2L]]
      }
      probs <- rlang::syms(probs)
    }
    return(metrics(
      preds,
      truth = !!truth,
      estimate = !!estimate,
      !!!probs,
      case_weights = !!weights,
      event_level = event_level
    ))
  }
  if (all(classes %in% survival)) {
    static <- any(classes == "static_survival_metric")
    linear <- any(classes == "linear_pred_survival_metric")
    estimate <- if (static && linear) {
      quote(c(static = .pred_time, linear_pred = .pred_linear_pred))
    } else if (static) {
      rlang::sym(".pred_time")
    } else if (linear) {
      rlang::sym(".pred_linear_pred")
    }
    dynamic <- if (
      any(
        classes %in% c("dynamic_survival_metric", "integrated_survival_metric")
      )
    ) {
      rlang::sym(".pred")
    }
    return(metrics(
      preds,
      truth = !!truth,
      estimate = !!estimate,
      case_weights = !!weights,
      !!dynamic
    ))
  }
  estimate <- if (all(classes == "quantile_metric")) {
    rlang::sym(".pred_quantile")
  } else {
    rlang::sym(".pred")
  }
  metrics(
    preds,
    truth = !!truth,
    estimate = !!estimate,
    case_weights = !!weights
  )
}

# The saved predictions joined onto the data rows (M92). On a design that
# holds some row out more than once, every row joins its entry in
# `collect_predictions(summarize = TRUE)`'s average (M125), the rows held out
# once included, so one design never mixes averaged and saved values. A
# design that holds each row out once joins the saved predictions as they
# are. The hold-out counts are read from the splits of every fold, the
# failed ones included, so a failed fold never makes a repeated design look
# like a single hold-out. The columns joined are tune's `merge_pred()`
# columns, those starting `.pred` (tune 2.1.0, read 2026-09-13), placed after
# the outcome the way tune's `reorder_pred_cols()` places them; no `.resid`
# is added (implement gate, 2026-09-13).

#' Join the held-out predictions of a nested run onto its data
#'
#' @description
#' `augment()` returns the data a nested run was given, one row per data
#' row, with the predictions made for that row when an outer fold held it
#' out. On a design that holds a row out more than once, those predictions
#' are averaged. You can plot or inspect every row's out-of-fold prediction
#' beside its predictors.
#'
#' @inheritParams compute_metrics.nested_results
#' @param ... Not used. It must be empty. tune's `parameters` argument is
#'   not offered here, because each fold made its predictions with the
#'   parameters it selected.
#'
#' @return A tibble with the data's rows in the data's order. The outcome
#'   column comes first, then the prediction columns, whose names start
#'   with `.pred`, then the rest of the data's columns. A censored outcome
#'   is saved under its `Surv()` call, which names no data column, so there
#'   the prediction columns come first. The fold labels, `.row` and
#'   `.config` are not joined, and no `.resid` column is added.
#'
#' @section Which predictions these are:
#'
#' The predictions come from the outer fits. Each outer fold tuned on its
#' analysis rows, fitted the parameters it selected, and predicted its
#' held-out assessment rows. So a row's prediction was made by a model
#' that never saw that row.
#'
#' They are not predictions from the final model. That model is fitted
#' on all the rows by [nested_final_fit()], and its own `augment()` method
#' predicts new data with it.
#'
#' @section Designs accepted, and averaged predictions:
#'
#' The outer design must hold out every data row at least once.
#'
#' A v-fold or grouped v-fold design without repeats holds out each row
#' once. There, each row joins the predictions that its one outer fold
#' saved, as they are.
#'
#' A repeated v-fold design holds out each row once per repeat, and a
#' Monte Carlo design can hold out a row several times. On a design that
#' holds out some row more than once, every row joins its averaged
#' prediction, the rows held out once included. The count of times a row
#' is held out reads every outer fold, the failed ones included. The average is the one
#' `collect_predictions(summarize = TRUE)` gives, and
#' [collect_predictions.nested_results()] states its rules. For example, a
#' `.pred_class` saved beside class probabilities is recomputed from the
#' averaged probabilities, whatever class a postprocessor set.
#'
#' @section Designs and folds refused:
#'
#' A design that leaves some data row out of every assessment set is
#' refused with class `nestedtune_augment_rows`. The message names the
#' first five of those rows, or all of them when there are five or fewer.
#' A Monte Carlo design can leave rows out. A [rsample::rolling_origin()],
#' [rsample::sliding_window()], [rsample::sliding_index()] or
#' [rsample::sliding_period()] design leaves out at least the rows before
#' its first assessment set. Read the predictions such a design has with
#' [collect_predictions()].
#'
#' On a design that holds out some row more than once, saved quantile
#' predictions are refused with class `nestedtune_summarize_quantile`,
#' because `collect_predictions(summarize = TRUE)` does not average them.
#'
#' @templateVar TITLE Designs and folds refused
#' @template refusals-saved-run
#' @section Designs and folds refused:
#' A completed fold
#' whose saved predictions do not match the rows it held out is refused
#' with class `nestedtune_augment_predictions`. Its `.row` column must hold
#' each of those rows once and no other row. On a run with some failed
#' folds, a row that only failed folds held out holds a missing value in
#' every prediction column, with a warning of class
#' `nestedtune_partial_summary`. A row that a completed fold also held out
#' takes the average over the completed folds. A missing value is `NA`, or
#' `NULL` in a list column such as the `.pred` of a censored-regression run.
#' A data column whose name is also a prediction column's name is refused
#' with class `nestedtune_collect_name_collision`.
#'
#' @template example-setup
#' @examplesIf rlang::is_installed(c("recipes", "yardstick"))
#' set.seed(2)
#' res <- nested_tune_grid(
#'   wf,
#'   folds,
#'   grid = data.frame(num_comp = 1:2),
#'   control = tune::control_grid(save_pred = TRUE)
#' )
#'
#' augment(res)
#'
#' @templateVar LINKS [collect_predictions.nested_results()], [compute_metrics.nested_results()], [nested_final_fit()]
#' @templateVar WHAT function
#' @template seealso-reader
#' @export
augment.nested_results <- function(x, ...) {
  rlang::check_dots_empty()
  call <- rlang::current_env()
  check_any_completed(x, action = "augment")
  check_column_saved(x, ".predictions", call = call)
  data <- x$splits[[1L]]$data
  repeated <- check_held_out(x, nrow(data), call = call)
  check_predictions_rows(x, verb = "augment", call = call)
  if (repeated) {
    check_no_quantile(x, verb = "augment", call = call)
  }
  preds <- stack_fold_column(
    x,
    ".predictions",
    completed_only = TRUE,
    call = call
  )
  if (repeated) {
    preds <- average_fold_predictions(preds, drop = c(id_columns(x), ".config"))
  }
  pred_cols <- grep("^\\.pred", names(preds), value = TRUE)
  clash <- intersect(pred_cols, names(data))
  if (length(clash) > 0L) {
    cli::cli_abort(
      c(
        "Cannot join the predictions: the data carries a column named \\
         {.val {clash}}, which is a prediction column.",
        i = "Rename that column in the data the run was given."
      ),
      class = "nestedtune_collect_name_collision",
      call = call
    )
  }
  warn_partial_summary(x, noun = "table")

  joined <- lapply(pred_cols, function(nm) {
    vctrs::vec_assign(
      vctrs::vec_init(preds[[nm]], nrow(data)),
      preds$.row,
      preds[[nm]]
    )
  })
  names(joined) <- pred_cols
  data <- as.list(data)
  # A survival outcome is saved under its `Surv()` expression, which names
  # no data column, and is then left where the data has it.
  first <- x$.predictions[[which(x$.completed)[[1L]]]]
  outcome <- intersect(outcome_column(first), names(data))
  new_tbl(c(data[outcome], joined, data[setdiff(names(data), outcome)]))
}

# Each data row's count of outer assessment sets holding it, over every fold.
# A row no set holds is refused, naming the first five such rows (M108,
# M125). The message names no design type: a Monte Carlo, rolling-origin or
# overlapping sliding-window design can each leave rows out (M111). Returns
# whether some row is held out more than once, which is when `augment()`
# averages.
check_held_out <- function(x, n, call = rlang::caller_env()) {
  held <- unlist(lapply(x$splits, rsample::complement), use.names = FALSE)
  counts <- tabulate(held, nbins = n)
  rows <- which(counts == 0L)
  if (length(rows) == 0L) {
    return(any(counts > 1L))
  }
  never <- length(rows)
  shown <- utils::head(rows, 5L)
  listed <- if (never > 5L) {
    "No outer fold holds out {never} rows. The first five are {shown}."
  } else {
    "No outer fold holds out {cli::qty(never)}row{?s} {shown}."
  }
  cli::cli_abort(
    c(
      "{.fn augment} needs an outer design that holds out every data row \\
       at least once.",
      x = listed,
      i = "A design whose assessment sets do not cover the data has no \\
           prediction for {cli::qty(never)}{?that row/those rows}. Read the \\
           predictions it has with {.fn collect_predictions}."
    ),
    class = "nestedtune_augment_rows",
    call = call
  )
}

# Each completed fold's saved `.row` against the rows its split held out
# (M93). `augment()` joins by `.row`, so a held-out row with no entry would
# be left missing without a word, and a repeated one would overwrite another.
# `compute_metrics()` scores the rows as they are, so a repeated row would
# count twice and a foreign one would be scored against a row the fold
# analysed (M100). `collect_predictions(summarize = TRUE)` averages by
# `.row`, so a repeated row would weigh twice in its average (M126); the
# per-fold table is not checked, as it only shows what was saved. tune 2.1.0
# has no path to any of these short of an edit to the object, so any
# mismatch refuses, under the class of the reader that found it:
# `nestedtune_<verb>_predictions`. The values are compared as whole numbers:
# a double `.row` holding the same values is accepted.
check_predictions_rows <- function(x, verb, call = rlang::caller_env()) {
  verb <- rlang::arg_match(
    verb,
    c("augment", "compute_metrics", "collect_predictions")
  )
  bad <- vapply(
    which(x$.completed),
    function(i) !predictions_match_rows(x$.predictions[[i]], x$splits[[i]]),
    logical(1L)
  )
  bad <- which(x$.completed)[bad]
  if (length(bad) == 0L) {
    return(invisible(x))
  }
  labels <- fold_ids(x)[bad]
  cli::cli_abort(
    c(
      "{.fn {verb}} needs each fold's saved predictions to hold exactly \\
       the rows that fold held out, each once.",
      x = "The saved predictions of fold{?s} {.val {labels}} do not match \\
           {?its/their} held-out rows.",
      i = "A saved prediction table must keep its {.field .row} column as \\
           the run returned it."
    ),
    class = paste0("nestedtune_", verb, "_predictions"),
    call = call
  )
}

predictions_match_rows <- function(preds, split) {
  rows <- if (is.data.frame(preds)) preds[[".row"]]
  if (!is.numeric(rows) || anyNA(rows)) {
    return(FALSE)
  }
  held <- rsample::complement(split)
  !anyDuplicated(rows) &&
    all(rows %in% held) &&
    all(held %in% rows)
}

# The refusal for an object whose run did not keep the column asked for. The
# record the readers trust is the recorded procedure's control: it says
# whether the run asked, so a column a caller added by hand to a run that
# never saved one is not read back as the outer fit's, even though
# `record_columns()` admits it to the class invariant, which vouches for a
# column's consistency across verbs and not for where it came from. The
# object's names say whether the column is still there. Either failing
# refuses, the first naming the control slot and the control function the
# recorded procedure says the run took. A results object carries no `procedure` only
# if it was built before M46, and then the column's presence is all there is
# to read and the slot alone is named.
check_column_saved <- function(x, column, call = rlang::caller_env()) {
  control <- attr(x, "procedure")$control
  present <- column %in% names(x)
  asked <- if (is.null(control)) {
    present
  } else {
    switch(
      column,
      .predictions = isTRUE(control$save_pred),
      .extracts = is.function(control$extract)
    )
  }
  if (asked && present) {
    return(invisible(x))
  }
  slot <- switch(column, .predictions = "save_pred", .extracts = "extract")
  if (asked) {
    cli::cli_abort(
      c(
        "This object no longer carries {.code {column}}, though its run's \\
         control set {.arg {slot}}.",
        i = "Read the column from the object the run returned."
      ),
      class = "nestedtune_column_not_saved",
      call = call
    )
  }
  setting <- switch(
    column,
    .predictions = "save_pred = TRUE",
    .extracts = "extract = <a function>"
  )
  tuner <- attr(x, "procedure")$tuner
  control_fn <- if (is.null(tuner)) {
    "the control passed through {.arg ...}"
  } else {
    paste0(
      "{.fn ",
      tuner_entry(tuner)$package,
      "::",
      control_class(tuner),
      "} passed through {.arg ...}"
    )
  }
  cli::cli_abort(
    c(
      "This run did not keep {.code {column}}: its control did not set \\
       {.arg {slot}}.",
      i = paste0("Run it again with {.code ", setting, "} in ", control_fn, ".")
    ),
    class = "nestedtune_column_not_saved",
    call = call
  )
}
