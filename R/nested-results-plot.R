# Plotting a nested_results.
#
# Both views derive every fact from the columns at plot time rather than from the
# counts stamped at construction, exactly as printing does: a subset's rows are
# their own run (IP4).
#
# Two properties are structural rather than cosmetic. Every *attempted* fold
# keeps its slot on the x axis and a fold that contributed nothing draws no
# point, so a figure lifted out of its console session still shows that the
# design fell short. And the marked estimate is read off the same
# `summarize_folds()` that `collect_metrics()` uses, never recomputed, so the
# plot and the summary cannot disagree about the number.

#' Plot a nested cross-validation result
#'
#' @description
#' Two views of a `nested_results` object, both drawing one point per outer
#' fold with the folds in design order.
#'
#' `type = "parameters"`, the default, shows what each outer fold's inner
#' tuning selected. A flat row of points means the folds agreed; points at
#' different heights mean they disagreed, and the tuning procedure is unstable
#' on this data, which averaging the metrics hides. This is the view nothing
#' else in the ecosystem offers.
#'
#' `type = "performance"` shows each outer fold's score on its held-out
#' assessment set, with a rule at the nested estimate: the same value
#' [collect_metrics()] reports.
#'
#' @param object A `nested_results` object from [nested_tune_grid()] or one
#'   of its siblings, [nested_fit_resamples()] included.
#' @param type Which view to draw: `"parameters"` (the default) or
#'   `"performance"`.
#' @param ... Not used; must be empty. An argument passed here is an error
#'   rather than silently ignored.
#'
#' @return A `ggplot` object.
#'
#' @details
#' An outer fold that failed keeps its place on the x axis and draws no point,
#' as does a fold that completed without recording a value for a parameter.
#' Neither is imputed and neither is dropped from the axis, so the shortfall is
#' visible in the figure itself. A run in which no fold completed is refused
#' with condition class `nestedtune_no_completed_folds`, as
#' [collect_metrics()], [agreement()] and [nested_final_fit()] refuse it. A
#' run in which no completed fold recorded a selected parameter -- a
#' [nested_fit_resamples()] result -- is refused under `type = "parameters"`
#' with condition class `nestedtune_no_tuned_parameters`, and
#' `type = "performance"` draws it.
#'
#' The subtitle states how much of the requested design ran. Contribution is
#' counted per panel instead, because it differs between them: a panel says so
#' when fewer folds contributed to it than completed, as in `mtry (2 of 3
#' chose)` or `rmse (from 2 folds)`; an unqualified panel means every
#' completed fold contributed. A requested metric that no completed fold
#' could score keeps an empty panel rather than disappearing.
#'
#' The selected-value axis is numeric when every value drawn is a number, and
#' discrete otherwise: a single axis cannot be both, and character-valued
#' tuning parameters are ordinary. A fold that selected `NA` is a value on that
#' discrete axis rather than an absent point.
#'
#' @examplesIf rlang::is_installed(c("recipes", "yardstick"))
#' data(mtcars)
#'
#' rec <- recipes::step_pca(
#'   recipes::recipe(mpg ~ ., data = mtcars),
#'   recipes::all_predictors(),
#'   num_comp = tune::tune()
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
#' res <- nested_tune_grid(wf, folds, grid = data.frame(num_comp = 1:3))
#'
#' autoplot(res)
#' autoplot(res, type = "performance")
#'
#' @seealso [nested_tune_grid()], [print.nested_results()],
#'   [collect_metrics()], [summary.nested_results_set()] for the same two
#'   views of a workflow-set run
#' @importFrom rlang .data
#' @export
autoplot.nested_results <- function(
  object,
  type = c("parameters", "performance"),
  ...
) {
  rlang::check_dots_empty()
  type <- check_plot_type(type)
  check_any_completed(object, action = "plot")

  switch(
    type,
    parameters = plot_selection(object),
    performance = plot_performance(object)
  )
}

plot_selection <- function(x, call = rlang::caller_env()) {
  frame <- selection_frame(x)
  if (is.null(frame)) {
    # Classed since M70: a `nested_fit_resamples()` result reaches this on
    # every call, so a caller can catch it as the refusal it is.
    cli::cli_abort(
      c(
        "There are no tuned parameters to plot.",
        x = "No completed outer fold recorded a selected parameter.",
        i = "{.code autoplot(x, type = \"performance\")} draws the outer-fold \\
             scores instead."
      ),
      class = "nestedtune_no_tuned_parameters",
      call = call
    )
  }

  ggplot2::ggplot(frame, ggplot2::aes(x = .data$fold, y = .data$value)) +
    ggplot2::geom_point(size = 2.5) +
    ggplot2::scale_x_discrete(drop = FALSE) +
    value_scale(frame$value, frame$parameter) +
    ggplot2::facet_wrap(ggplot2::vars(.data$parameter), scales = "free_y") +
    ggplot2::labs(
      title = "Inner-loop selections across outer folds",
      # Two lines, because one does not fit a 7-inch device: a subtitle is not
      # wrapped for you, and a clipped caveat is worse than a short one.
      subtitle = paste0(
        design_line(x),
        "\nPoints at different heights in a panel mean the folds disagreed."
      ),
      x = "Outer fold",
      y = "Selected value"
    )
}

# The selected-value scale.
#
# A tuning parameter that only takes whole numbers -- `mtry`, `num_comp`,
# `min_n`, `trees`, most of the grid a user tunes over -- must not be given
# fractional breaks: unanimity collapses the range to nothing, and the default
# breaks then label a flat row of identical choices 2.950, 2.975, 3.000, which
# reads as disagreement at the third decimal place. Whole-number breaks label it
# 3, which is what happened.
#
# The decision is per panel and never over the pooled column. `facet_wrap(scales
# = "free_y")` trains one scale per panel but shares a single breaks function,
# calling it with each panel's own limits -- so one continuous parameter judged
# globally put every *other* panel back on fractional breaks, which is how the
# defect this exists to fix came back for any grid mixing an integer parameter
# with a continuous one (M08 review F3).
value_scale <- function(values, parameter) {
  if (!is.numeric(values)) {
    return(NULL)
  }
  by_param <- split(values, parameter)
  whole <- vapply(
    by_param,
    function(v) length(v) > 0L && all(v == trunc(v)),
    logical(1)
  )
  if (!any(whole)) {
    return(NULL)
  }
  ggplot2::scale_y_continuous(breaks = panel_breaks(by_param))
}

panel_breaks <- function(by_param) {
  function(limits) {
    owner <- panel_owner(by_param, limits)
    if (is.null(owner) || !all(owner == trunc(owner))) {
      # `pretty()` rather than ggplot2's own default, which lives in `scales` and
      # would be an undeclared namespace to reach for. The two agree closely, and
      # this branch is only reached by a continuous parameter sharing a figure
      # with a whole-number one.
      return(pretty(limits))
    }
    whole_number_breaks(limits)
  }
}

# Which parameter's panel this is, recovered from the limits alone.
#
# A shared breaks function is told the limits and nothing else, so it has to work
# out whose panel it is -- and the limits are the answer, because `free_y` trains
# them on one parameter's values. The owner is the parameter whose own range sits
# inside the limits and fills most of them.
#
# Asking instead which *pooled* values fall inside the limits is not the same
# question, and answering it that way is what let a continuous parameter
# overlapping an integer one put fractional ticks back on the integer panel: a
# comment here once claimed the two were equivalent, and the M08 re-review
# disproved it with `num_comp` 2/3/4 beside a parameter valued 2.5/2.7/3.5.
#
# Two parameters with the same range are genuinely ambiguous and the first wins.
# That is a tick label on one axis, not a claim about any fold, so it is left as
# the known limit of a cheap identification rather than engineered away.
panel_owner <- function(by_param, limits) {
  span <- diff(limits)
  best <- NULL
  best_fill <- -Inf
  for (values in by_param) {
    if (length(values) == 0L) {
      next
    }
    own <- range(values)
    if (own[[1L]] < limits[[1L]] || own[[2L]] > limits[[2L]]) {
      next
    }
    fill <- if (span == 0) 1 else diff(own) / span
    if (fill > best_fill) {
      best_fill <- fill
      best <- values
    }
  }
  best
}

whole_number_breaks <- function(limits) {
  candidates <- unique(round(pretty(limits)))
  candidates[
    candidates >= floor(limits[[1L]]) &
      candidates <= ceiling(limits[[2L]])
  ]
}

plot_performance <- function(x) {
  per_fold <- per_fold_metrics(x)
  summarized <- summarize_folds(per_fold)
  # A metric measured at several evaluation times is one estimate per time
  # (M41), so the time joins the panel name before the estimator question is
  # asked; a summary keyed on time alone would give two panels one label and
  # the level factor below would abort on the duplicate (M41 review F1).
  timed_rows <- timed_metric(summarized)
  timed_points <- timed_metric(per_fold)
  ambiguous <- ambiguous_metrics(timed_rows)
  bases <- metric_panel(timed_rows, summarized$.estimator, ambiguous)
  # The qualifier goes on the panel, exactly where print puts it: a metric
  # averaged over fewer folds than completed says so on its own line, "where the
  # heading would be wrong for it alone" (R/nested-results-print.R:229). One
  # figure-level count cannot be true of every panel, and claiming otherwise is
  # what made the subtitle assert a three-fold estimate for a two-fold number
  # (M08 review F1).
  panels <- qualify_panels(bases, summarized$n, sum(x$.completed), from_folds)

  # A fold can complete and still score NA on one metric while scoring the
  # others -- an outer assessment set with one class gives roc_auc = NA. It
  # contributed nothing to that metric, so it draws no point there, and the
  # metric's own rule already averages only the folds that did contribute.
  scored <- !is.na(per_fold$.estimate)
  scored_panels <- panels[match(
    metric_panel(
      timed_points[scored],
      per_fold$.estimator[scored],
      ambiguous
    ),
    bases
  )]
  points <- new_tbl(list(
    fold = factor(per_fold$id[scored], levels = fold_ids(x)),
    score = per_fold$.estimate[scored],
    metric = factor(scored_panels, levels = panels)
  ))

  estimated <- !is.na(summarized$mean)
  rules <- new_tbl(list(
    metric = factor(panels[estimated], levels = panels),
    mean = summarized$mean[estimated]
  ))

  ggplot2::ggplot(points, ggplot2::aes(x = .data$fold, y = .data$score)) +
    ggplot2::geom_hline(
      data = rules,
      mapping = ggplot2::aes(yintercept = .data$mean),
      linetype = "dashed"
    ) +
    ggplot2::geom_point(size = 2.5) +
    ggplot2::scale_x_discrete(drop = FALSE) +
    # `drop = FALSE` for the same reason the fold axis carries it: a metric that
    # was requested keeps its panel even when no completed fold could score it,
    # rather than vanishing with no trace that it had been asked for. It also
    # makes the nothing-scored-anywhere figure build instead of failing inside
    # ggplot2 on an empty faceting variable (M08 review F4).
    ggplot2::facet_wrap(
      ggplot2::vars(.data$metric),
      scales = "free_y",
      drop = FALSE
    ) +
    ggplot2::labs(
      title = "Nested cross-validation estimate",
      # IP3, and the reason this line is in the subtitle rather than in the help
      # page: ggplot2 renders a subtitle into the image, so the caveat survives
      # the figure being exported into a slide or a paper, where the console
      # session and the documentation do not travel with it.
      subtitle = paste0(
        design_line(x),
        " The line marks the nested estimate.\nIt describes the tune-and-fit ",
        "procedure, not a model you can deploy."
      ),
      x = "Outer fold",
      y = "Score on the held-out outer fold"
    )
}

# How much of the requested design ran. Derived from the columns, as printing
# derives it, so a subset says what is true of the rows in hand (IP4).
#
# It deliberately claims nothing about what contributed to any one panel: that
# count differs per metric and per parameter, and a figure-level sentence
# asserting it was wrong whenever they differed. The panels carry it instead.
design_line <- function(x) {
  requested <- nrow(x)
  paste0(
    requested,
    " outer fold",
    if (requested == 1L) "" else "s",
    " requested, ",
    sum(x$.completed),
    " completed."
  )
}

# A panel label, qualified only when that panel drew fewer folds than the run
# completed. An unqualified label therefore means "all of them", and the usual
# figure -- where nothing was lost -- carries no qualifier at all.
qualify_panels <- function(bases, contributed, completed, qualifier) {
  short <- contributed != completed
  out <- bases
  out[short] <- paste0(
    bases[short],
    " (",
    qualifier(contributed[short], completed),
    ")"
  )
  out
}

# The two views phrase the qualifier differently because they are counting
# different things: how many folds a metric's estimate came from, and how many
# folds chose a value for a parameter at all.
from_folds <- function(k, completed) {
  paste0("from ", k, " fold", ifelse(k == 1L, "", "s"))
}

chose_value <- function(k, completed) {
  paste0(k, " of ", completed, " chose")
}

# The metric name a row is drawn under: the metric alone, or "<metric> at time
# <t>" where the row carries an evaluation time, as the summary print puts it
# (R/nested-results-print.R). A row with no time -- a static metric beside a
# dynamic one, or any run that named none -- keeps the bare name.
timed_metric <- function(rows) {
  metric <- rows$.metric
  if (!".eval_time" %in% names(rows)) {
    return(metric)
  }
  at <- rows$.eval_time
  timed <- !is.na(at)
  metric[timed] <- paste0(metric[timed], " at time ", render_times(at[timed]))
  metric
}

# Each time formatted on its own -- `format()` over the vector would pad them
# to a common width and decimal count, "10.0" beside "0.5" -- at 15 significant
# digits, which renders a typed time as typed. Two distinct times that read
# alike at 15 (0.1 + 0.2 beside 0.3) are two summary rows and must be two
# panels, not one duplicated factor level, so those alone are re-rendered at
# 17, where every double is distinct.
render_times <- function(at) {
  each <- function(x, digits) {
    vapply(x, format, character(1), digits = digits)
  }
  out <- each(at, 15L)
  for (label in unique(out)) {
    hit <- out == label
    if (length(unique(at[hit])) > 1L) {
      out[hit] <- each(at[hit], 17L)
    }
  }
  out
}

# The panel a metric's scores sit in. Two estimators for the same metric would
# otherwise share a panel and be marked with two rules; the estimator joins the
# label exactly when it has to, so the usual plot is not cluttered by it.
# `metric` is the timed name, so the estimator question is asked per time.
metric_panel <- function(metric, estimator, ambiguous) {
  ifelse(
    metric %in% ambiguous,
    paste0(metric, " (", estimator, ")"),
    metric
  )
}

ambiguous_metrics <- function(metric) {
  counts <- table(metric)
  names(counts)[counts > 1L]
}

# The tidy frame behind the parameters view: one row per fold-and-parameter the
# design actually produced a value for.
#
# Fold labels are a factor over every *attempted* fold in design order, so the
# scale keeps a slot for one that drew no point. Parameters come from the union
# across completed folds, as printing takes them, so a parameter only some folds
# carry is still shown.
selection_frame <- function(x) {
  rows <- selection_rows(x)
  if (is.null(rows)) {
    return(NULL)
  }
  new_tbl(list(
    fold = factor(rows$fold, levels = rows$fold_levels),
    parameter = factor(rows$parameter, levels = rows$panels),
    value = selection_axis(rows$values)
  ))
}

# The frame's rows before the axis is decided: the fold and qualified panel
# label per drawn value, the values themselves as a list, and the levels of
# each. Split from `selection_frame()` so the set's view (M72) can pool
# every workflow's values before `selection_axis()` decides one axis for
# every panel, where a decision per workflow could put a numeric panel
# beside a discrete one.
selection_rows <- function(x) {
  ids <- fold_ids(x)
  params <- selection_params(x$.selected[x$.completed])
  if (length(params) == 0L) {
    return(NULL)
  }

  fold <- character(0)
  parameter <- character(0)
  values <- list()
  chose <- integer(0)
  for (param in params) {
    raw <- selection_raw(x$.selected, param)
    present <- !vapply(raw, is.null, logical(1))
    fold <- c(fold, ids[present])
    parameter <- c(parameter, rep(param, sum(present)))
    values <- c(values, unname(raw[present]))
    chose <- c(chose, sum(present))
  }
  if (length(values) == 0L) {
    return(NULL)
  }

  # A parameter that only some completed folds chose a value for says so on its
  # own panel. Without it a flat row of two agreeing folds, under a figure-level
  # sentence counting three, read as three folds agreeing -- the false-agreement
  # mirror of the false-instability flag print treats as its worst output
  # (M08 review F2).
  panels <- qualify_panels(params, chose, sum(x$.completed), chose_value)

  list(
    fold = fold,
    fold_levels = ids,
    parameter = panels[match(parameter, params)],
    panels = panels,
    values = values
  )
}

# One fold's value for a parameter, or NULL where it has none.
#
# `.selected` is a list column of one-row tibbles, so a value is reached through
# the element and never with `$` on the column: `x$.selected$num_comp` answers
# NULL rather than erroring, and a caller that believed it rendered "0 distinct
# values" and built perfectly cleanly (M06).
#
# A fold that failed carries NULL, and a completed fold's selection may simply
# have no such column. Both are "no value", and neither may be drawn.
selection_raw <- function(selected, param) {
  lapply(selected, function(s) {
    if (is.null(s) || !param %in% names(s)) {
      return(NULL)
    }
    value <- s[[param]][[1L]]
    if (length(value) != 1L) {
      return(paste(format(value), collapse = ", "))
    }
    value
  })
}

# The y aesthetic for the parameters view.
#
# One column carries one type and a facetted panel cannot mix a numeric axis
# with a discrete one, so the axis is numeric only when every value drawn is a
# number. Anything else -- a character-valued parameter, or a fold that selected
# NA, which printing treats as a value rather than an absence -- puts every
# panel on a discrete axis. Its levels are ordered numerically where the strings
# are numbers, so a discrete fallback does not sort 10 before 3.
selection_axis <- function(values) {
  numeric_only <- vapply(
    values,
    function(v) is.numeric(v) && length(v) == 1L && !is.na(v),
    logical(1)
  )
  if (all(numeric_only)) {
    return(vapply(values, as.numeric, numeric(1)))
  }

  labels <- vapply(
    values,
    function(v) paste(format(v), collapse = ", "),
    character(1)
  )
  unique_labels <- unique(labels)
  as_number <- suppressWarnings(as.numeric(unique_labels))
  factor(
    labels,
    levels = unique_labels[order(as_number, unique_labels, na.last = TRUE)]
  )
}

#' @rdname summary.nested_results_set
#' @export
autoplot.nested_results_set <- function(
  object,
  type = c("parameters", "performance"),
  ...
) {
  rlang::check_dots_empty()
  type <- check_plot_type(type)
  call <- rlang::current_env()
  switch(
    type,
    parameters = plot_set_selection(object, call = call),
    performance = plot_set_performance(object, call = call)
  )
}

# The set's performance view: the workflows on the x axis inside one panel
# per metric, so the estimates are read across one axis, each marked by a
# rule at that workflow's nested estimate -- the same `summarize_folds()`
# `collect_metrics()` reads, never recomputed. Every workflow keeps its slot
# on the axis, an all-failed one included (IP4, as a failed fold keeps its
# slot in the single view), and a fold that scored nothing draws no point.
plot_set_performance <- function(x, call) {
  ids <- x$wflow_id
  # The per-fold rows, stacked under the readers' fold-state rules: a
  # workflow with a failed fold warns naming it, an all-failed one
  # contributes no row, a set with no completed fold is refused.
  per_fold <- stack_set(
    x,
    function(r) {
      warn_partial_summary(r, noun = "figure")
      per_fold_metrics(r)
    },
    call = call,
    action = "plot",
    noun = "figure"
  )

  # The panel names, decided over the distinct (metric, estimator, time)
  # keys of the whole set rather than per workflow, so a metric two
  # estimators scored gets a panel each and one every workflow scored
  # once gets one panel, not one per workflow.
  keys <- distinct_metric_keys(per_fold)
  timed_keys <- timed_metric(keys)
  ambiguous <- ambiguous_metrics(timed_keys)
  panels <- metric_panel(timed_keys, keys$.estimator, ambiguous)

  scored <- !is.na(per_fold$.estimate)
  points <- new_tbl(list(
    wflow_id = factor(per_fold$wflow_id[scored], levels = ids),
    score = per_fold$.estimate[scored],
    metric = factor(
      metric_panel(
        timed_metric(per_fold)[scored],
        per_fold$.estimator[scored],
        ambiguous
      ),
      levels = panels
    )
  ))

  # One rule per workflow and panel, each workflow's rows summarized on
  # their own through the function the readers share.
  rules <- lapply(unique(per_fold$wflow_id), function(id) {
    own <- summarize_folds(take_rows(per_fold, per_fold$wflow_id == id))
    estimated <- !is.na(own$mean)
    new_tbl(list(
      wflow_id = rep(id, sum(estimated)),
      metric = metric_panel(
        timed_metric(own)[estimated],
        own$.estimator[estimated],
        ambiguous
      ),
      mean = own$mean[estimated]
    ))
  })
  rules <- new_tbl(as.list(vctrs::vec_rbind(!!!rules)))
  rules$wflow_id <- factor(rules$wflow_id, levels = ids)
  rules$metric <- factor(rules$metric, levels = panels)

  ggplot2::ggplot(points, ggplot2::aes(x = .data$wflow_id, y = .data$score)) +
    # A rule with no height, under the points as the single view's line is.
    ggplot2::geom_errorbar(
      data = rules,
      mapping = ggplot2::aes(
        x = .data$wflow_id,
        ymin = .data$mean,
        ymax = .data$mean
      ),
      inherit.aes = FALSE,
      width = 0.6,
      linetype = "dashed"
    ) +
    ggplot2::geom_point(size = 2.5) +
    ggplot2::scale_x_discrete(drop = FALSE) +
    ggplot2::facet_wrap(
      ggplot2::vars(.data$metric),
      scales = "free_y",
      drop = FALSE
    ) +
    ggplot2::labs(
      title = "Nested cross-validation estimates across workflows",
      # Two or three lines, each short enough for a 7-inch device: the
      # shortfall sentence, when there is one, takes a line of its own.
      subtitle = paste0(
        set_design_line(x),
        " Each line marks a workflow's nested estimate.",
        set_shortfall_line(x),
        "\nIt describes the tune-and-fit procedure, not a model you can deploy."
      ),
      x = "Workflow",
      y = "Score on the held-out outer fold"
    )
}

# The set's design, for the subtitle: the workflow and fold counts. Every
# workflow ran the one design, so the fold count is any element's.
set_design_line <- function(x) {
  k <- nrow(x)
  n <- nrow(x$result[[1L]])
  paste0(
    k,
    " workflow",
    if (k == 1L) "" else "s",
    ", ",
    n,
    " outer fold",
    if (n == 1L) "" else "s",
    " each."
  )
}

# A line of its own when any workflow has a failed fold: how many do, and
# where to read which. The per-panel qualifier of the single view is not
# repeated here -- "completed" is per workflow in a set, and `summary()`
# names each workflow's failed folds. Empty on a set that ran whole.
set_shortfall_line <- function(x) {
  k <- nrow(x)
  short <- sum(vapply(x$result, function(r) !all(r$.completed), logical(1)))
  if (short == 0L) {
    return("")
  }
  paste0(
    "\n",
    short,
    " of ",
    k,
    " workflow",
    if (k == 1L) "" else "s",
    " ha",
    if (short == 1L) "s" else "ve",
    " a failed fold; see summary()."
  )
}

# The distinct (metric, estimator, time) keys of a stacked per-fold table,
# in first-appearance order, keyed as `summarize_folds()` keys them.
distinct_metric_keys <- function(per_fold) {
  cols <- intersect(c(".metric", ".estimator", ".eval_time"), names(per_fold))
  rendered <- lapply(cols, function(nm) {
    if (nm == ".eval_time") {
      sprintf("%.17g", per_fold[[nm]])
    } else {
      per_fold[[nm]]
    }
  })
  first <- !duplicated(do.call(paste, c(rendered, sep = "\r")))
  take_rows(per_fold[cols], first)
}

# The rows of a plain-column table, as a tibble.
take_rows <- function(tbl, rows) {
  new_tbl(lapply(as.list(tbl), function(col) col[rows]))
}

# The set's parameters view: one panel per workflow and tuned parameter,
# in set order, labelled by the workflow's id and then the single view's
# qualified label for that parameter, so a parameter two workflows tune
# is two panels and a panel some folds did not choose says so as it does
# for one workflow. The fold labels stay on the x axis: within a workflow
# the question is the single view's -- did the folds agree? -- asked once
# per workflow.
plot_set_selection <- function(x, call) {
  ids <- x$wflow_id
  rows <- stack_set(
    x,
    function(r) {
      warn_partial_summary(r, noun = "figure")
      own <- selection_rows(r)
      if (is.null(own)) {
        # A workflow with nothing to tune, or whose completed folds recorded
        # no selection, contributes no panel.
        return(new_tbl(list(
          fold = character(),
          parameter = character(),
          value = list()
        )))
      }
      new_tbl(list(
        fold = own$fold,
        parameter = own$parameter,
        value = own$values
      ))
    },
    call = call,
    action = "plot",
    noun = "figure"
  )
  if (nrow(rows) == 0L) {
    cli::cli_abort(
      c(
        "There are no tuned parameters to plot.",
        x = "No completed outer fold of any workflow recorded a selected \\
             parameter.",
        i = "{.code autoplot(x, type = \"performance\")} draws the outer-fold \\
             scores instead."
      ),
      class = "nestedtune_no_tuned_parameters",
      call = call
    )
  }

  # Panels in set order, then the workflow's parameter order, which is the
  # order the rows were stacked in; the fold levels are the design's, the
  # same for every workflow.
  panels <- unique(paste0(rows$wflow_id, ": ", rows$parameter))
  frame <- new_tbl(list(
    fold = factor(rows$fold, levels = fold_ids(x$result[[1L]])),
    parameter = factor(
      paste0(rows$wflow_id, ": ", rows$parameter),
      levels = panels
    ),
    value = selection_axis(rows$value)
  ))

  ggplot2::ggplot(frame, ggplot2::aes(x = .data$fold, y = .data$value)) +
    ggplot2::geom_point(size = 2.5) +
    ggplot2::scale_x_discrete(drop = FALSE) +
    value_scale(frame$value, frame$parameter) +
    ggplot2::facet_wrap(ggplot2::vars(.data$parameter), scales = "free_y") +
    ggplot2::labs(
      title = "Inner-loop selections across outer folds, by workflow",
      subtitle = paste0(
        set_design_line(x),
        set_shortfall_line(x),
        "\nPoints at different heights in a panel mean the folds disagreed."
      ),
      x = "Outer fold",
      y = "Selected value"
    )
}
