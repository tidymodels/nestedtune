# compute_metrics() on a nested run (M92).
#
# Oracle provenance. AC1's oracle is `collect_metrics()` on the same run,
# which reads the `.metrics` tune::last_fit() wrote for each outer fold, so
# a rescoring that differs from tune's own scoring in any number, metric
# order or column fails it. AC2's oracle is yardstick called metric by
# metric on each fold's rows of `collect_predictions()`, and the summary
# computed by hand from those per-fold numbers, never from the method.

# The runs, each served from the fixture cache. The two repeated fixtures
# build their design inline. The others take it from the `*_nested()` helpers.
saved_reg_run <- function() {
  d <- make_reg_data()
  set.seed(2)
  memoised(nested_tune_grid(
    det_workflow(d),
    det_nested(d),
    grid = det_grid(),
    metrics = reg_metrics(),
    control = tune::control_grid(save_pred = TRUE)
  ))
}

saved_cls_run <- function(event_level = "second", metrics = cls_metrics()) {
  d <- cls_data()
  set.seed(3)
  memoised(nested_tune_grid(
    cls_workflow(d),
    cls_nested(d),
    grid = cls_grid(),
    metrics = metrics,
    event_level = event_level,
    control = tune::control_grid(save_pred = TRUE)
  ))
}

saved_srv_run <- function() {
  d <- srv_data()
  set.seed(4)
  suppressWarnings(memoised(nested_tune_grid(
    srv_workflow(d),
    srv_nested(d),
    grid = srv_grid(),
    metrics = srv_metrics(),
    eval_time = srv_eval_times(),
    control = tune::control_grid(save_pred = TRUE)
  )))
}

# The repeated designs AC2 reads: v = 3 repeated twice, six outer folds.
repeated_reg_run <- function() {
  d <- make_reg_data()
  set.seed(12)
  folds <- nested_resamples(
    d,
    outside = rsample::vfold_cv(v = 3, repeats = 2),
    inside = rsample::vfold_cv(v = 3)
  )
  set.seed(13)
  memoised(nested_tune_grid(
    det_workflow(d),
    folds,
    grid = det_grid(),
    metrics = reg_metrics(),
    control = tune::control_grid(save_pred = TRUE)
  ))
}

repeated_cls_run <- function() {
  d <- cls_data()
  set.seed(14)
  folds <- nested_resamples(
    d,
    outside = rsample::vfold_cv(v = 3, repeats = 2, strata = y),
    inside = rsample::vfold_cv(v = 3, strata = y)
  )
  set.seed(15)
  memoised(nested_tune_grid(
    cls_workflow(d),
    folds,
    grid = cls_grid(),
    metrics = cls_metrics(),
    control = tune::control_grid(save_pred = TRUE)
  ))
}

# Fold 4's prediction columns emptied to NA. yardstick drops missing values
# before scoring, so every metric on that fold has no rows to score and
# returns NaN, which is.na() counts as missing: the NA fold AC2 asks for,
# reached through yardstick's own path.
with_na_fold <- function(x, fold = 4L) {
  preds <- x$.predictions[[fold]]
  for (nm in grep("^\\.pred", names(preds), value = TRUE)) {
    preds[[nm]][seq_len(nrow(preds))] <- NA
  }
  x$.predictions[[fold]] <- preds
  x
}

# One fold's rows of collect_predictions(), matched on every label column.
fold_rows <- function(preds, x, i) {
  keep <- rep(TRUE, nrow(preds))
  for (nm in attr(x, "id_columns")) {
    keep <- keep & preds[[nm]] == x[[nm]][[i]]
  }
  preds[keep, ]
}

# The per-fold estimates by hand: each metric called on its own, in the
# order given, for every fold of `x`.
hand_per_fold <- function(x, score) {
  preds <- collect_predictions(x)
  rows <- lapply(seq_len(nrow(x)), function(i) {
    # brier_class() warns while it scores the NA fold's empty set of rows.
    out <- suppressWarnings(score(fold_rows(preds, x, i)))
    out$fold <- i
    out
  })
  dplyr::bind_rows(!!!rows)
}

# The summary by hand, one metric at a time, NA folds dropped.
hand_summary <- function(per_fold, metric) {
  vals <- per_fold$.estimate[per_fold$.metric == metric]
  vals <- vals[!is.na(vals)]
  list(
    mean = mean(vals),
    n = length(vals),
    std_err = stats::sd(vals) / sqrt(length(vals))
  )
}

# ---- AC1: the run's own metric set gives collect_metrics() back ------------

test_that("with the run's metric set, compute_metrics() is collect_metrics() on a regression run", {
  skip_if_no_engines()
  res <- saved_reg_run()
  level <- extract_procedure(res)$event_level

  for (summarize in c(TRUE, FALSE)) {
    expect_identical(
      compute_metrics(
        res,
        reg_metrics(),
        summarize = summarize,
        event_level = level
      ),
      collect_metrics(res, summarize = summarize)
    )
  }
})

test_that("with the run's metric set and level, compute_metrics() is collect_metrics() on a classification run at event_level = \"second\"", {
  skip_if_no_engines(stochastic = TRUE)
  res <- saved_cls_run()
  expect_identical(extract_procedure(res)$event_level, "second")

  for (summarize in c(TRUE, FALSE)) {
    expect_identical(
      compute_metrics(
        res,
        cls_metrics(),
        summarize = summarize,
        event_level = "second"
      ),
      collect_metrics(res, summarize = summarize)
    )
  }
})

test_that("event_level defaults to the level the run recorded, not to \"first\"", {
  skip_if_no_engines(stochastic = TRUE)
  res <- saved_cls_run()

  expect_identical(
    compute_metrics(res, cls_metrics()),
    collect_metrics(res)
  )
  # The control: at the other level sensitivity and specificity trade places,
  # so a default that read "first" would give a different table.
  first <- compute_metrics(res, cls_metrics(), event_level = "first")
  second <- compute_metrics(res, cls_metrics())
  expect_false(identical(first$mean, second$mean))
  expect_identical(
    first$mean[first$.metric == "sens"],
    second$mean[second$.metric == "spec"]
  )
})

test_that("with the run's metric set, compute_metrics() is collect_metrics() on a censored-regression run", {
  skip_if_no_censored()
  res <- saved_srv_run()
  expect_true(".eval_time" %in% names(collect_metrics(res)))

  for (summarize in c(TRUE, FALSE)) {
    expect_identical(
      compute_metrics(res, srv_metrics(), summarize = summarize),
      collect_metrics(res, summarize = summarize)
    )
  }
})

# ---- AC2: a new metric set, scored by hand with yardstick ------------------

test_that("a numeric metric set the run did not use is yardstick on each fold's rows, NA fold left out of the summary", {
  skip_if_no_engines()
  res <- with_na_fold(repeated_reg_run())
  expect_identical(attr(res, "id_columns"), c("id", "id2"))
  ms <- yardstick::metric_set(yardstick::mae, yardstick::rsq_trad)
  expect_length(
    intersect(names(attr(ms, "metrics")), c("rmse", "rsq")),
    0L
  )

  by_hand <- hand_per_fold(res, function(rows) {
    dplyr::bind_rows(
      yardstick::mae(rows, y, .pred),
      yardstick::rsq_trad(rows, y, .pred)
    )
  })
  per_fold <- suppressWarnings(compute_metrics(res, ms, summarize = FALSE))
  expect_identical(per_fold$id, fold_ids(res)[by_hand$fold])
  expect_identical(per_fold$.metric, by_hand$.metric)
  expect_identical(per_fold$.estimate, by_hand$.estimate)
  # The NA fold scored NA on both metrics, and only it did.
  expect_identical(which(is.na(per_fold$.estimate)), c(7L, 8L))

  summary <- suppressWarnings(compute_metrics(res, ms))
  for (m in c("mae", "rsq_trad")) {
    want <- hand_summary(by_hand, m)
    row <- summary[summary$.metric == m, ]
    expect_identical(row$mean, want$mean)
    expect_identical(row$n, want$n)
    expect_identical(row$std_err, want$std_err)
    expect_identical(row$n, 5L)
  }
})

test_that("a class-probability metric set the run did not use is yardstick on each fold's rows, NA fold left out of the summary", {
  skip_if_no_engines(stochastic = TRUE)
  res <- with_na_fold(repeated_cls_run())
  ms <- yardstick::metric_set(yardstick::mn_log_loss, yardstick::brier_class)
  expect_length(
    intersect(names(attr(ms, "metrics")), c("roc_auc", "sens", "spec")),
    0L
  )

  by_hand <- hand_per_fold(res, function(rows) {
    dplyr::bind_rows(
      yardstick::mn_log_loss(rows, y, .pred_event),
      yardstick::brier_class(rows, y, .pred_event)
    )
  })
  per_fold <- suppressWarnings(compute_metrics(res, ms, summarize = FALSE))
  expect_identical(per_fold$.metric, by_hand$.metric)
  expect_identical(per_fold$.estimate, by_hand$.estimate)
  expect_identical(which(is.na(per_fold$.estimate)), c(7L, 8L))

  summary <- suppressWarnings(compute_metrics(res, ms))
  for (m in c("mn_log_loss", "brier_class")) {
    want <- hand_summary(by_hand, m)
    row <- summary[summary$.metric == m, ]
    expect_identical(row$mean, want$mean)
    expect_identical(row$n, want$n)
    expect_identical(row$std_err, want$std_err)
    expect_identical(row$n, 5L)
  }
})

test_that("a new class-probability metric set is scored at the event_level given, not the run's", {
  skip_if_no_engines(stochastic = TRUE)
  res <- repeated_cls_run()
  expect_identical(extract_procedure(res)$event_level, "first")
  ms <- yardstick::metric_set(yardstick::mn_log_loss, yardstick::brier_class)

  # At the second level the probability of that level is `.pred_other`.
  by_hand <- hand_per_fold(res, function(rows) {
    dplyr::bind_rows(
      yardstick::mn_log_loss(rows, y, .pred_other, event_level = "second"),
      yardstick::brier_class(rows, y, .pred_other, event_level = "second")
    )
  })
  second <- compute_metrics(
    res,
    ms,
    summarize = FALSE,
    event_level = "second"
  )
  expect_identical(second$.metric, by_hand$.metric)
  expect_identical(second$.estimate, by_hand$.estimate)
  # The control: scored at the recorded level, the log loss differs.
  first <- compute_metrics(res, ms, summarize = FALSE)
  loss <- first$.metric == "mn_log_loss"
  expect_false(identical(first$.estimate[loss], second$.estimate[loss]))
})

# ---- AC3: refusals ---------------------------------------------------------

test_that("a run without saved predictions is refused with nestedtune_column_not_saved", {
  skip_if_no_engines()
  d <- make_reg_data()
  set.seed(2)
  res <- memoised(nested_tune_grid(
    det_workflow(d),
    det_nested(d),
    grid = det_grid(),
    metrics = reg_metrics()
  ))
  expect_false(".predictions" %in% names(res))

  cnd <- rlang::catch_cnd(compute_metrics(res, reg_metrics()), "error")
  expect_s3_class(cnd, "nestedtune_column_not_saved")
  expect_match(conditionMessage(cnd), "save_pred", fixed = TRUE)
  expect_identical(conditionCall(cnd)[[1L]], as.name("compute_metrics"))
})

test_that("a `metrics` that is not a metric set is refused with nestedtune_bad_metrics", {
  skip_if_no_engines()
  res <- saved_reg_run()
  for (bad in list("rmse", yardstick::rmse, NULL)) {
    cnd <- rlang::catch_cnd(compute_metrics(res, bad), "error")
    expect_s3_class(cnd, "nestedtune_bad_metrics")
    expect_identical(conditionCall(cnd)[[1L]], as.name("compute_metrics"))
  }
})

test_that("a metric set needing a prediction the run did not save is refused with nestedtune_metric_type_not_saved", {
  skip_if_no_engines(stochastic = TRUE)
  res <- saved_cls_run(
    event_level = "first",
    metrics = yardstick::metric_set(yardstick::roc_auc)
  )
  preds <- collect_predictions(res)
  expect_false(".pred_class" %in% names(preds))
  expect_true(all(c(".pred_event", ".pred_other") %in% names(preds)))

  cnd <- rlang::catch_cnd(
    compute_metrics(res, yardstick::metric_set(yardstick::accuracy)),
    "error"
  )
  expect_s3_class(cnd, "nestedtune_metric_type_not_saved")
  expect_match(conditionMessage(cnd), ".pred_class", fixed = TRUE)
  expect_identical(conditionCall(cnd)[[1L]], as.name("compute_metrics"))
  # The control: a probability metric the run did save is scored.
  expect_no_error(
    compute_metrics(res, yardstick::metric_set(yardstick::mn_log_loss))
  )
})

test_that("a survival metric on a regression run is refused, the `.pred` column being numeric", {
  skip_if_no_engines()
  skip_if_no_censored()
  res <- saved_reg_run()
  cnd <- rlang::catch_cnd(
    compute_metrics(res, srv_metrics()),
    "error"
  )
  expect_s3_class(cnd, "nestedtune_metric_type_not_saved")
})

test_that("non-empty `...` is refused", {
  skip_if_no_engines()
  res <- saved_reg_run()
  expect_error(
    compute_metrics(res, reg_metrics(), foo = 1),
    class = "rlib_error_dots_nonempty"
  )
})

test_that("an `event_level` naming no level is refused", {
  skip_if_no_engines()
  res <- saved_reg_run()
  cnd <- rlang::catch_cnd(
    compute_metrics(res, reg_metrics(), event_level = "third"),
    "error"
  )
  expect_match(conditionMessage(cnd), "event_level", fixed = TRUE)
  expect_identical(conditionCall(cnd)[[1L]], as.name("compute_metrics"))
})

test_that("a run with a failed fold warns with nestedtune_partial_summary and scores the rest", {
  skip_if_no_engines()
  d <- make_reg_data()
  set.seed(2)
  res <- suppressWarnings(memoised(nested_tune_grid(
    det_workflow(d),
    break_fold(det_nested(d), 2L, "inner tuning"),
    grid = det_grid(),
    metrics = reg_metrics(),
    control = tune::control_grid(save_pred = TRUE)
  )))
  expect_identical(res$.completed, c(TRUE, FALSE, TRUE))

  cnd <- rlang::catch_cnd(
    compute_metrics(res, reg_metrics()),
    "nestedtune_partial_summary"
  )
  expect_s3_class(cnd, "nestedtune_partial_summary")
  expect_identical(
    suppressWarnings(compute_metrics(res, reg_metrics())),
    suppressWarnings(collect_metrics(res))
  )
})

test_that("a run with no completed fold is refused with nestedtune_no_completed_folds", {
  skip_if_no_engines()
  d <- make_reg_data()
  set.seed(2)
  res <- suppressWarnings(memoised(nested_tune_grid(
    det_workflow(d),
    break_every_fold(det_nested(d)),
    grid = det_grid(),
    metrics = reg_metrics(),
    control = tune::control_grid(save_pred = TRUE)
  )))
  expect_false(any(res$.completed))

  cnd <- rlang::catch_cnd(compute_metrics(res, reg_metrics()), "error")
  expect_s3_class(cnd, "nestedtune_no_completed_folds")
})
