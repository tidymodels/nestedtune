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

#' Collect each outer fold's selections, inner metrics or notes
#'
#' @description
#' `collect_selections()`, `collect_inner_metrics()` and `collect_notes()`
#' return what each outer fold's inner tuning selected, scored or noted, in
#' one table with the fold labels first.
#'
#' @details
#' * `collect_selections()` gives the tuned parameter values and `.config`
#'   of the candidate each completed fold selected, one row per fold. A
#'   [nested_fit_resamples()] result gives no rows.
#' * `collect_inner_metrics()` gives the columns of
#'   [tune::collect_metrics()] for every candidate that each completed
#'   fold's inner tuning scored.
#' * `collect_notes()` gives the notes of every fold, the failed ones
#'   included.
#'
#' The first two read only the folds that completed, with a warning if some
#' failed. If no fold completed, they give an error.
#'
#' A `.config` value labels a candidate inside one fold's tuning run, so it
#' does not identify a candidate across folds.
#'
#' @inheritParams collect_metrics.nested_results
#' @param type For `collect_inner_metrics()`, `"long"` (the default), one row
#'   per candidate and metric, or `"wide"`, one column per metric that holds
#'   its `mean`. The wide shape drops `.estimator`, `n` and `std_err`. It
#'   gives an error for a metric named like another column, such as a tuning
#'   parameter.
#'
#' @return A tibble with the fold labels first (`id`, and `id2` on a
#'   repeated design), then the stacked columns. A fold that lacks a column
#'   holds `NA` there. `collect_notes()` gives tune's note columns, from
#'   `location` to `trace`.
#'
#' @template example-setup
#' @template example-run
#' @examplesIf rlang::is_installed(c("recipes", "yardstick"))
#' collect_selections(res)
#' collect_inner_metrics(res)
#' collect_notes(res)
#'
#' @templateVar LINKS [collect_metrics()][collect_metrics.nested_results], [agreement()], [summary.nested_results()]
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
collect_inner_metrics.nested_results <- function(
  x,
  ...,
  type = c("long", "wide")
) {
  rlang::check_dots_empty()
  type <- check_metrics_type(type)
  check_any_completed(x, action = "collect")
  warn_partial_summary(x, noun = "table")
  out <- stack_fold_column(
    x,
    ".inner_metrics",
    completed_only = TRUE,
    call = rlang::current_env()
  )
  # The wide shape is collect_metrics()'s (M149): the inner table holds
  # tune's summarized columns, so the pivot keeps the fold labels, the
  # parameters, `.config` and any `.iter` or `.eval_time` as keys, which on
  # one fold's rows is the key set tune's own pivot uses (GP1).
  if (identical(type, "wide")) {
    out <- pivot_metrics_wide(out, call = rlang::current_env())
  }
  out
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

#' Collect the predictions or extracts of a nested run's outer fits
#'
#' @description
#' `collect_predictions()` and `collect_extracts()` return what each outer
#' fold's fit saved, stacked across the folds with the fold labels first.
#'
#' @details
#' The run's control must ask for the column: `save_pred = TRUE` for
#' predictions, or an `extract` function for extracts. Otherwise the
#' function gives an error that names the setting.
#'
#' The predictions are the outer fits' predictions on the rows each fold held
#' out. The inner tuning runs' own predictions and extracts are not kept.
#' Only the folds that completed are read, with a warning if some failed.
#'
#' `collect_extracts()` gives one row per completed fold, with the value in
#' an `.extracts` list column. If the extract function failed on a fold, the
#' value is `NULL` and the fold's `.notes` say why.
#'
#' @section Averaging across the folds:
#'
#' A repeated or Monte Carlo design can hold a data row out more than once.
#' `summarize = TRUE` averages each row's predictions over the completed
#' folds that held it out, by the rules of [tune::collect_predictions()].
#' The saved columns decide which rule applies. A `.pred_class` saved beside
#' class probabilities is recomputed from the averaged probabilities,
#' whatever a postprocessor set. A `NULL` entry in a censored `.pred` is left
#' out of its row's average. The rules differ from tune's in three ways:
#'
#' * Each fold selected its own candidate, so the average spans the selected
#'   candidates, and the fold labels and `.config` are dropped.
#' * A row whose averaged class probabilities are missing gets a missing
#'   class, where tune gives it the first level.
#' * Quantile predictions are not averaged, and they give an error.
#'
#' A metric computed on these averages describes an average of several
#' fitted models, so it is not the nested estimate.
#' [collect_metrics()][collect_metrics.nested_results] gives that estimate.
#'
#' @param x A `nested_results` from a run with `save_pred = TRUE`, or with
#'   an `extract` function for `collect_extracts()`.
#' @param ... Not used, and must be empty. tune's `parameters` argument is
#'   not offered, because each fold predicted with the parameters it
#'   selected.
#' @param summarize For `collect_predictions()`, whether to average the
#'   predictions for each data row (`TRUE`) or return them per fold
#'   (`FALSE`, the default).
#'
#' @return A tibble with the fold labels first (`id`, and `id2` on a
#'   repeated design). For `collect_predictions()`, the columns
#'   [tune::last_fit()] saved follow: the outcome, the predictions, `.row`
#'   and `.config`. That `.config` labels the outer fit, not the selected
#'   candidate. Averaged, the table has one row per data row that a
#'   completed fold held out, in `.row` order. It has no fold labels and no
#'   `.config`.
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
#' @templateVar LINKS [collect_selections()], [collect_metrics()][collect_metrics.nested_results], [nested_tune_grid()]
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
    out <- average_fold_predictions(
      out,
      drop = c(id_columns(x), ".config"),
      verb = "collect_predictions",
      call = rlang::current_env()
    )
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
# `verb` and `call` name the reader in the refusal of a table the rules
# would misread (M126), `check_average_columns()`.
average_fold_predictions <- function(
  preds,
  drop,
  verb,
  call = rlang::caller_env()
) {
  preds <- preds[setdiff(names(preds), drop)]
  check_average_columns(preds, verb = verb, call = call)
  rows <- sort(unique(preds$.row))
  group <- match(preds$.row, rows)
  first <- match(rows, preds$.row)
  n <- length(rows)

  nms <- names(preds)
  # A factor outcome names the probability columns, one per level, so a
  # level named like `time` is never read as a censored column.
  outcome <- factor_outcomes(preds)
  prob_cols <- if (length(outcome) == 1L) {
    intersect(paste0(".pred_", levels(preds[[outcome]])), nms)
  } else {
    character(0)
  }
  if (length(prob_cols) > 0L) {
    probs <- mean_by(
      matrix(
        unlist(lapply(prob_cols, function(nm) as.double(preds[[nm]]))),
        ncol = length(prob_cols)
      ),
      group,
      n
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
      return(class_by_vote(v, group, n))
    }
    if (nm == ".pred_time") {
      return(median_by(v, group, n))
    }
    if (nm == ".pred" && is.list(v)) {
      return(average_survival(v, group, n))
    }
    if (startsWith(nm, ".pred") && is.numeric(v)) {
      return(mean_by(v, group, n))
    }
    vctrs::vec_slice(v, first)
  })
  names(cols) <- nms
  new_tbl(cols)
}

# Grouped statistics over `v`, one per group `1:n` of the integer `group`.
# They are written with grouped sums and one sort rather than a call per
# group (M126: the benchmark's 100,002-row probability table took 0.8 s
# that way, `benchmarks/averaging-speed.R`).
# The mean ignores missing values, and a group with none left, or with no
# rows, gives `NaN`, as `mean(na.rm = TRUE)` does. Like `mean()`, it adds a
# second pass: the mean of each value's distance from the first estimate,
# skipped where that estimate is not finite. Without it, two groups with the
# same true mean can round one step apart, and a probability tie goes to
# the wrong level. Where `long double` is `double`, as on aarch64 macOS, the
# result equals `mean()`'s (2,000 random groups with missing values, R 4.6.1,
# 2026-09-28). Where `long double` is wider, `mean()` sums in it, so the two
# can differ in the last bits; that case was not run.
#
# `v` can be a matrix, averaged column by column in one pass, which gives a
# matrix; a vector gives a vector.
mean_by <- function(v, group, n) {
  if (!is.matrix(v)) {
    return(as.vector(mean_by(matrix(as.double(v)), group, n)))
  }
  seen <- !is.na(v)
  v[!seen] <- 0
  counts <- rowsum(seen + 0, group, reorder = TRUE)
  est <- rowsum(v, group, reorder = TRUE) / counts
  dev <- v - est[match(group, as.integer(rownames(est))), , drop = FALSE]
  dev[!seen] <- 0
  refine <- rowsum(dev, group, reorder = TRUE) / counts
  finite <- is.finite(est)
  est[finite] <- est[finite] + refine[finite]
  out <- matrix(NaN, n, ncol(v))
  out[as.integer(rownames(est)), ] <- est
  out
}

# The median, missing when any value in the group is, as `stats::median()`
# is by default. Every group `1:n` must hold a row. For an even group it halves the sum of the middle two,
# where `stats::median()` calls `mean()`, so the two can differ in the last
# bit.
median_by <- function(v, group, n) {
  v <- as.double(v)
  size <- tabulate(group, n)
  o <- order(group, v)
  sorted <- v[o]
  start <- cumsum(size) - size
  lo <- sorted[start + (size + 1L) %/% 2L]
  hi <- sorted[start + size %/% 2L + 1L]
  out <- (lo + hi) / 2
  out[tabulate(group[is.na(v)], n) > 0L] <- NA_real_
  out
}

# The factor columns among a prediction table's outcome columns: those that
# are not predictions and not a column tune adds beside them, as in
# `outcome_column()`.
factor_outcomes <- function(preds) {
  nms <- names(preds)
  others <- setdiff(
    nms[!startsWith(nms, ".pred")],
    c(".row", ".config", ".case_weights", ".iter", ".eval_time")
  )
  Filter(function(nm) is.factor(preds[[nm]]), others)
}

# Three shapes the averaging rules would misread (M126). With two factor
# outcomes, which one names the probability columns is unknown. A saved
# class beside no factor outcome leaves the probability columns unnamed, so
# they would be averaged without renormalizing and the class voted. A
# censored `.pred` entry without `.eval_time` has no time to average at.
# tune 2.1.0 writes none of these, so each means the object was edited. Read
# after the fold labels and `.config` are dropped.
check_average_columns <- function(preds, verb, call = rlang::caller_env()) {
  verb <- rlang::arg_match(verb, c("collect_predictions", "augment"))
  factors <- factor_outcomes(preds)
  problem <- if (length(factors) >= 2L) {
    "The saved predictions carry {length(factors)} factor outcome columns, \\
     {.field {factors}}, where the average reads one."
  } else if (length(factors) == 0L && ".pred_class" %in% names(preds)) {
    "The saved predictions carry a {.field .pred_class} column but no \\
     factor outcome column."
  } else if (is.list(preds[[".pred"]]) && !all(has_eval_time(preds$.pred))) {
    "A saved {.field .pred} entry has no {.field .eval_time} column."
  }
  if (is.null(problem)) {
    return(invisible(preds))
  }
  msg <- switch(
    verb,
    collect_predictions = c(
      "{.code summarize = TRUE} cannot average the saved predictions.",
      x = problem
    ),
    augment = c(
      "{.fn augment} cannot average the saved predictions.",
      x = problem,
      i = "The outer design holds some data rows out more than once, so \\
           {.fn augment} averages their predictions."
    )
  )
  cli::cli_abort(
    c(
      msg,
      i = "A saved prediction table must keep the columns the run returned."
    ),
    class = "nestedtune_summarize_columns",
    call = call
  )
}

# Whether each censored `.pred` entry is NULL or carries `.eval_time`.
has_eval_time <- function(entries) {
  vapply(
    entries,
    function(t) is.null(t) || ".eval_time" %in% names(t),
    logical(1)
  )
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

# The class at the largest averaged probability. `max.col(ties.method =
# "first")` returns the first of tied maxima, comparing exactly, and
# `prob_cols` is in factor order. A row holding a missing probability is
# missing throughout, because renormalizing divides it by a missing sum, and
# `max.col()` gives it a missing class. Orderedness follows the outcome, as
# in tune's `prob_summarize()`, not the saved class.
class_from_probs <- function(probs, prob_cols, saved, outcome) {
  idx <- max.col(probs, ties.method = "first")
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
# "first")` takes the first level among tied counts. `group` numbers the
# rows `1:n`.
class_by_vote <- function(v, group, n = max(as.integer(group))) {
  group <- factor(as.integer(group), levels = seq_len(n))
  counts <- unclass(table(group, addNA(v, ifany = FALSE)))
  idx <- max.col(counts, ties.method = "first")
  idx[idx > nlevels(v)] <- NA_integer_
  factor(levels(v)[idx], levels = levels(v), ordered = is.ordered(v))
}

# The censored `.pred` list column: per row and `.eval_time`, the mean of
# every other column with missing values ignored, in the order the times
# first appear. A NULL entry is left out, and a row whose every entry is
# NULL holds NULL (M126), the value `augment()` gives a list column's row
# that no completed fold held out. `group` numbers the rows `1:n`.
average_survival <- function(v, group, n) {
  sizes <- vctrs::list_sizes(v)
  out <- vector("list", n)
  if (sum(sizes) == 0L) {
    return(out)
  }
  long <- vctrs::list_unchop(v)
  long_group <- rep(group, sizes)
  key <- vctrs::vec_group_id(
    vctrs::new_data_frame(list(g = long_group, t = long$.eval_time))
  )
  n_key <- attr(key, "n")
  first <- match(seq_len(n_key), key)
  averaged <- lapply(names(long), function(nm) {
    if (nm == ".eval_time") {
      return(long$.eval_time[first])
    }
    mean_by(long[[nm]], key, n_key)
  })
  names(averaged) <- names(long)
  averaged <- new_tbl(averaged)
  entries <- split(
    seq_len(n_key),
    factor(long_group[first], levels = seq_len(n))
  )
  filled <- lengths(entries) > 0L
  out[filled] <- vctrs::vec_chop(averaged, indices = unname(entries[filled]))
  out
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
#' `compute_metrics()` scores the predictions a nested run saved with a new
#' metric set, and returns a table shaped like [collect_metrics()][collect_metrics.nested_results]. The
#' nested loop does not run again.
#'
#' @details
#' Each completed outer fold's saved predictions are scored on their own, and
#' the per-fold scores are averaged as in [collect_metrics()][collect_metrics.nested_results]. Each repeat of
#' a repeated design counts as its own fold. A fold that scores `NA` is left
#' out of the mean.
#'
#' Each fold keeps the candidate it selected. To select with a metric, pass
#' it in the `metrics` argument of [nested_tune_grid()] or the other nested
#' function.
#'
#' The run needs `save_pred = TRUE` in its control, and a metric that reads a
#' kind of prediction the run did not save is an error. So is an edited
#' `.predictions` column whose `.row` values do not match the rows each fold
#' held out.
#'
#' @inheritParams collect_metrics.nested_results
#' @param x A `nested_results` from a run with `save_pred = TRUE` in its
#'   control.
#' @param metrics A [yardstick::metric_set()].
#' @param ... Not used, and must be empty.
#' @param event_level For a two-class outcome, `"first"` or `"second"`. The
#'   default, `NULL`, takes the level the run used, where tune's method
#'   takes `"first"`.
#'
#' @return A tibble in the long shape of [collect_metrics()][collect_metrics.nested_results]. With the run's
#'   own metric set and event level, it equals
#'   `collect_metrics(x, summarize = summarize)`.
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
#' `augment()` returns the data a nested run was given, with each row's
#' predictions from the outer folds that held it out. A model that never saw
#' the row made each prediction.
#'
#' @details
#' These are the outer fits' predictions, not the final model's.
#' [nested_final_fit()] fits that model on all the rows, and its own
#' `augment()` method predicts new data.
#'
#' The outer design must hold out every data row at least once. A Monte
#' Carlo design can miss rows, and a time-series design misses the rows
#' before its first assessment set. For those, use [collect_predictions()].
#'
#' On a design that holds out some row more than once, every row gets the
#' average that `collect_predictions(summarize = TRUE)` gives. So a
#' `.pred_class` saved beside class probabilities is recomputed from the
#' averaged probabilities, whatever a postprocessor set. A metric computed
#' on averaged predictions is not the nested estimate.
#'
#' A row held out only by failed folds gets missing predictions, with a
#' warning. The run needs `save_pred = TRUE` in its control.
#'
#' @inheritParams compute_metrics.nested_results
#' @param ... Not used, and must be empty. tune's `parameters` argument is
#'   not offered, because each fold predicted with the parameters it
#'   selected.
#'
#' @return A tibble with the data's rows in the data's order: the outcome,
#'   then the prediction columns, whose names start with `.pred`, then the
#'   other data columns. For a censored outcome, the prediction columns come
#'   first. Unlike tune's `augment()`, it adds no `.resid` column.
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
  # The collision is read off the saved tables' names, before any refusal
  # the average raises (M126): averaging keeps every `.pred` column's name.
  pred_cols <- unique(unlist(lapply(
    x$.predictions[x$.completed],
    function(p) grep("^\\.pred", names(p), value = TRUE)
  )))
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
    preds <- average_fold_predictions(
      preds,
      drop = c(id_columns(x), ".config"),
      verb = "augment",
      call = call
    )
  }
  pred_cols <- grep("^\\.pred", names(preds), value = TRUE)
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
  msg <- c(
    "{.fn {verb}} needs each fold's saved predictions to hold exactly \\
     the rows that fold held out, each once.",
    x = "The saved predictions of fold{?s} {.val {labels}} do not match \\
         {?its/their} held-out rows.",
    i = "A saved prediction table must keep its {.field .row} column as \\
         the run returned it."
  )
  if (verb == "collect_predictions") {
    msg[[1L]] <- "{.code summarize = TRUE} needs each fold's saved \\
                  predictions to hold exactly the rows that fold held out, \\
                  each once."
    msg <- c(
      msg,
      i = "Call {.fn collect_predictions} with {.code summarize = FALSE} \\
           for the per-fold predictions."
    )
  }
  cli::cli_abort(
    msg,
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
