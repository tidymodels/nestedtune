# M106 AC3: `metric` and `eval_time` on autoplot(type = "performance").
#
# The reference for a filtered plot is the unfiltered one: its panels for the
# named metrics (and times), drawn with the same points. A panel belongs to a
# metric when its label is that metric's name, alone or followed by the
# qualifiers the view adds (" at time ...", " (from ...").

panels_of <- function(p) {
  unique(panel_labels(ggplot2::ggplot_build(p)))
}

panel_metric <- function(labels, metrics) {
  pattern <- paste0("^(", paste(metrics, collapse = "|"), ")( |$)")
  grepl(pattern, labels)
}

srv_single <- function() {
  data <- srv_data()
  nested <- srv_nested(data)
  workflow <- srv_workflow(data)
  set.seed(9)
  suppressWarnings(memoised(nested_tune_grid(
    workflow,
    nested,
    grid = srv_grid(),
    metrics = srv_set_metrics(),
    eval_time = srv_eval_times()
  )))
}

cls_single <- function() {
  d <- cls_data()
  set.seed(5)
  memoised(nested_tune_grid(
    cls_workflow(d),
    cls_nested(d),
    grid = cls_grid(),
    metrics = cls_metrics()
  ))
}

test_that("`metric` draws the named metrics' panels and no others", {
  skip_if_no_engines()

  res <- cls_single()
  all <- autoplot(res, type = "performance")
  some <- autoplot(res, type = "performance", metric = c("sens", "roc_auc"))

  want <- panels_of(all)[panel_metric(panels_of(all), c("sens", "roc_auc"))]
  expect_length(want, 2L)
  expect_setequal(panels_of(some), want)

  # The points in the kept panels are the unfiltered plot's.
  kept <- plot_points(all)
  kept <- kept[kept$panel %in% want, ]
  drawn <- plot_points(some)
  expect_equal(
    drawn[order(drawn$panel, drawn$fold), ],
    kept[order(kept$panel, kept$fold), ],
    ignore_attr = TRUE
  )

  # NULL is every metric.
  expect_setequal(
    panels_of(autoplot(res, type = "performance", metric = NULL)),
    panels_of(all)
  )
})

test_that("`eval_time` draws the named times and keeps a static metric", {
  skip_if_no_censored()

  res <- srv_single()
  all <- autoplot(res, type = "performance")
  t <- srv_eval_times()[[1L]]
  at_t <- autoplot(res, type = "performance", eval_time = t)

  labels <- panels_of(all)
  timed <- grepl(" at time ", labels)
  # The panels timed at `t`, read off the unfiltered plot by rendering `t`
  # as the view does, plus the static metric's untimed panel.
  at_label <- grepl(paste0(" at time ", t, "( |$)"), labels)
  expect_true(any(at_label))
  expect_setequal(panels_of(at_t), labels[!timed | at_label])

  both <- autoplot(
    res,
    type = "performance",
    metric = "brier_survival",
    eval_time = t
  )
  expect_setequal(
    panels_of(both),
    labels[at_label & panel_metric(labels, "brier_survival")]
  )
})

test_that("a set's view filters over every workflow", {
  skip_if_no_wset_fixture()
  skip_if_no_censored()

  res <- srv_set_results()
  all <- autoplot(res, type = "performance")
  some <- autoplot(res, type = "performance", metric = "concordance_survival")
  labels <- panels_of(all)
  expect_setequal(
    panels_of(some),
    labels[panel_metric(labels, "concordance_survival")]
  )

  t <- srv_eval_times()[[2L]]
  at_t <- autoplot(res, type = "performance", eval_time = t)
  timed <- grepl(" at time ", labels)
  at_label <- grepl(paste0(" at time ", t, "( |$)"), labels)
  expect_true(any(at_label))
  expect_setequal(panels_of(at_t), labels[!timed | at_label])
})

test_that("a metric or time the run did not score is refused", {
  skip_if_no_censored()

  res <- srv_single()
  expect_error(
    autoplot(res, type = "performance", metric = "rmse"),
    class = "nestedtune_bad_plot_filter"
  )
  expect_error(
    autoplot(res, type = "performance", eval_time = 3),
    class = "nestedtune_bad_plot_filter"
  )
  expect_snapshot(error = TRUE, {
    autoplot(res, type = "performance", metric = c("rmse", "brier_survival"))
    autoplot(res, type = "performance", eval_time = 3)
  })
})

test_that("a time on a run scored at none is refused", {
  skip_if_no_engines()

  expect_error(
    autoplot(cls_single(), type = "performance", eval_time = 1),
    class = "nestedtune_bad_plot_filter"
  )
})

test_that("a set refuses a metric no workflow scored", {
  skip_if_no_wset_fixture()
  skip_if_no_censored()

  res <- srv_set_results()
  expect_error(
    autoplot(res, type = "performance", metric = "rmse"),
    class = "nestedtune_bad_plot_filter"
  )
  expect_error(
    autoplot(res, type = "performance", eval_time = 3),
    class = "nestedtune_bad_plot_filter"
  )
})

test_that("either argument with the parameters view is refused", {
  skip_if_no_engines()

  res <- cls_single()
  expect_error(
    autoplot(res, metric = "sens"),
    class = "nestedtune_bad_plot_filter"
  )
  expect_error(
    autoplot(res, type = "parameters", eval_time = 1),
    class = "nestedtune_bad_plot_filter"
  )
  expect_snapshot(error = TRUE, {
    autoplot(res, metric = "sens", eval_time = 1)
  })
  # A malformed value is refused before the run is read.
  expect_error(
    autoplot(res, type = "performance", metric = 1),
    class = "nestedtune_bad_plot_filter"
  )
  expect_error(
    autoplot(res, type = "performance", eval_time = "1"),
    class = "nestedtune_bad_plot_filter"
  )
})

test_that("a set refuses either argument with the parameters view", {
  skip_if_no_wset_fixture()
  skip_if_no_censored()

  expect_error(
    autoplot(srv_set_results(), metric = "brier_survival"),
    class = "nestedtune_bad_plot_filter"
  )
})

test_that("a filtered performance view looks the way it reads", {
  skip_if_not_installed("vdiffr")
  skip_if_no_censored()

  res <- srv_single()
  vdiffr::expect_doppelganger(
    "performance, one metric at one time",
    autoplot(
      res,
      type = "performance",
      metric = "brier_survival",
      eval_time = srv_eval_times()[[1L]]
    )
  )
})

# M106 review F1: the time is judged by what the run scored, not by what the
# named metrics scored. The static metric has no time, so filtering to it
# alone would once leave no timed row and refuse a time the run did score.
test_that("a time the run scored is accepted beside a static metric", {
  skip_if_no_censored()

  res <- srv_single()
  t <- srv_eval_times()[[1L]]
  p <- autoplot(
    res,
    type = "performance",
    metric = "concordance_survival",
    eval_time = t
  )
  labels <- panels_of(autoplot(res, type = "performance"))
  expect_setequal(
    panels_of(p),
    labels[panel_metric(labels, "concordance_survival")]
  )
})

# M106 review F7: on a set, the filter reads the stacked rows, so a metric
# one workflow scored is kept for that workflow and refused only when no
# workflow scored it. The set fixtures share one metric set, so the stacked
# table is written here with a metric only workflow `b` scored.
test_that("a set keeps a metric only one workflow scored", {
  stacked <- tibble::tibble(
    wflow_id = c("a", "a", "b", "b", "b"),
    id = c("Fold1", "Fold2", "Fold1", "Fold2", "Fold2"),
    .metric = c("rmse", "rmse", "rmse", "rmse", "mae"),
    .estimator = "standard",
    .estimate = c(1, 2, 3, 4, 5)
  )
  kept <- filter_plot_rows(stacked, "mae", NULL)
  expect_identical(kept$wflow_id, "b")
  expect_identical(kept$.estimate, 5)

  expect_error(
    filter_plot_rows(stacked, "rsq", NULL),
    class = "nestedtune_bad_plot_filter"
  )
})
