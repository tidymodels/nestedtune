# Plotting a nested_results object (M08).
#
# No oracle is recorded here, deliberately. The plot produces no numeric result
# of its own: every number it draws was computed and oracle-verified upstream
# (M02's estimate, M04's selections), and what these tests pin is that the plot
# reproduces those numbers without distorting or inventing them -- an internal
# consistency check, not a claim about the world. The one equality that could be
# mistaken for an oracle, the marked estimate against collect_metrics(), is
# asserted for exactly that reason: the two must never be able to disagree.

test_that("the parameters view draws one point per completed fold", {
  skip_if_no_engines()
  d <- make_reg_data()

  set.seed(2)
  res <- memoised(nested_tune_grid(
    det_workflow(d),
    det_nested(d),
    grid = det_grid(),
    metrics = reg_metrics()
  ))
  pts <- plot_points(autoplot(res, type = "parameters"))

  selected <- as.numeric(vapply(
    res$.selected,
    function(s) s$num_comp,
    integer(1)
  ))

  expect_identical(pts$fold, c("Fold1", "Fold2", "Fold3"))
  expect_identical(unique(pts$panel), "num_comp")
  expect_identical(pts$y, selected)
  # This fixture's folds agree, so agreement is a flat row: one value, three
  # points. The disagreement case below is the same assertion with scatter.
  expect_length(unique(pts$y), 1L)
})

test_that("folds that disagree are drawn at their own values, keyed by fold", {
  skip_if_no_engines()
  u <- unstable_data()

  set.seed(2)
  res <- memoised(nested_tune_grid(
    unstable_workflow(u),
    det_nested(u, v = 4),
    grid = unstable_grid(),
    metrics = reg_metrics()
  ))
  pts <- plot_points(autoplot(res))

  # The fixture's folds land on 4, 4, 4, 3 (the same disagreement M04's print
  # tests read). Position identifies the fold, so the values are asserted in
  # fold order -- a plot that drew the right four values in the wrong order
  # would pass a set comparison and fail this.
  expect_identical(pts$fold, c("Fold1", "Fold2", "Fold3", "Fold4"))
  expect_identical(pts$y, c(4, 4, 4, 3))
})

test_that("a failed fold keeps its place on the axis and draws no point", {
  skip_if_no_engines()
  d <- make_reg_data()

  set.seed(2)
  res <- suppressWarnings(memoised(nested_tune_grid(
    det_workflow(d),
    break_fold(det_nested(d), 2L, "outer fit"),
    grid = det_grid(),
    metrics = reg_metrics()
  )))
  p <- autoplot(res)

  # IP4: the fold that did not run is on the axis, so the shortfall is visible
  # in the figure itself and not only in the count -- but it contributes no
  # point, so nothing is imputed for it.
  expect_identical(axis_labels(p), c("Fold1", "Fold2", "Fold3"))
  expect_identical(plot_points(p)$fold, c("Fold1", "Fold3"))
})

test_that("a completed fold with no value for a parameter is not imputed", {
  skip_if_no_engines()
  d <- make_reg_data()

  set.seed(2)
  res <- drop_selection(memoised(nested_tune_grid(
    det_workflow(d),
    det_nested(d),
    grid = det_grid(),
    metrics = reg_metrics()
  )))
  p <- autoplot(res)

  # Distinct from the failed fold above: this one ran. It still draws no point,
  # because a point at any height would be a selection it never made.
  expect_identical(axis_labels(p), c("Fold1", "Fold2", "Fold3"))
  expect_identical(plot_points(p)$fold, c("Fold1", "Fold3"))
})

test_that("the parameters view states how much of the design ran", {
  skip_if_no_engines()
  d <- make_reg_data()

  set.seed(2)
  whole <- memoised(nested_tune_grid(
    det_workflow(d),
    det_nested(d),
    grid = det_grid(),
    metrics = reg_metrics()
  ))
  set.seed(2)
  partial <- suppressWarnings(memoised(nested_tune_grid(
    det_workflow(d),
    break_fold(det_nested(d), 2L, "outer fit"),
    grid = det_grid(),
    metrics = reg_metrics()
  )))

  # A design fact, true of the whole figure however its panels differ: the
  # subtitle claims nothing about per-panel contribution, which is what it got
  # wrong before (F1/F2).
  expect_match(
    plot_label(autoplot(whole), "subtitle"),
    "3 outer folds requested, 3 completed"
  )
  expect_match(
    plot_label(autoplot(partial), "subtitle"),
    "3 outer folds requested, 2 completed"
  )
})

test_that("a panel says so when fewer folds contributed to it than completed", {
  skip_if_no_engines()
  d <- make_reg_data()

  set.seed(2)
  res <- memoised(nested_tune_grid(
    det_workflow(d),
    det_nested(d),
    grid = det_grid(),
    metrics = reg_metrics()
  ))

  # Every completed fold chose, so nothing is qualified: the common plot stays
  # uncluttered and a bare label means "all of them".
  expect_identical(strip_labels(autoplot(res)), "num_comp")
  expect_identical(
    strip_labels(autoplot(res, type = "performance")),
    c("rmse", "rsq")
  )

  # A completed fold that recorded no value for the parameter. Two folds chose,
  # and they agree -- so the flat row must not be readable as three agreeing.
  # print says "all 2 folds that chose it agree; 1 recorded no value"; the panel
  # is where the plot can say the same thing (F2).
  expect_identical(
    strip_labels(autoplot(drop_selection(res))),
    "num_comp (2 of 3 chose)"
  )

  # A fold that completed but scored NA on one metric only. print puts
  # "(from 2 folds)" on that metric's own line; so does the panel (F1).
  one_na <- res
  rmse_row <- one_na$.metrics[[2L]]$.metric == "rmse"
  one_na$.metrics[[2L]]$.estimate[rmse_row] <- NA_real_
  expect_identical(
    strip_labels(autoplot(one_na, type = "performance")),
    c("rmse (from 2 folds)", "rsq")
  )
})

test_that("each panel decides its own breaks", {
  skip_if_no_engines()
  d <- make_reg_data()

  set.seed(2)
  res <- memoised(nested_tune_grid(
    det_workflow(d),
    det_nested(d),
    grid = det_grid(),
    metrics = reg_metrics()
  ))
  # A whole-number parameter beside a continuous one, which is what glmnet,
  # xgboost and svm_rbf all look like. Deciding over the pooled column put the
  # integer panel back on 2.950/2.975/3.000 -- the defect the single-parameter
  # fix claimed to have closed (F3).
  mixed <- res
  for (i in seq_len(nrow(mixed))) {
    mixed$.selected[[i]]$penalty <- c(0.001, 0.02, 0.3)[[i]]
  }
  p <- autoplot(mixed)

  expect_identical(strip_labels(p), c("num_comp", "penalty"))
  expect_identical(axis_labels(p, "y", panel = 1L), "3")
  expect_true(any(grepl(".", axis_labels(p, "y", panel = 2L), fixed = TRUE)))

  # The harder case, and the one the disjoint fixture above cannot see: the
  # continuous parameter's values fall *inside* the integer parameter's range, so
  # "which pooled values are in these limits" no longer identifies the panel.
  # Asking that question rather than which parameter owns the panel put
  # 2.0/2.5/3.0/3.5/4.0 back on an axis whose only values are 2, 3 and 4.
  overlapping <- res
  for (i in seq_len(nrow(overlapping))) {
    overlapping$.selected[[i]]$num_comp <- c(2L, 3L, 4L)[[i]]
    overlapping$.selected[[i]]$degree <- c(2.5, 2.7, 3.5)[[i]]
  }
  q <- autoplot(overlapping)

  expect_identical(strip_labels(q), c("num_comp", "degree"))
  expect_identical(axis_labels(q, "y", panel = 1L), c("2", "3", "4"))
  expect_true(any(grepl(".", axis_labels(q, "y", panel = 2L), fixed = TRUE)))
})

test_that("a metric no fold could score keeps its panel", {
  skip_if_no_engines()
  d <- make_reg_data()

  set.seed(2)
  res <- memoised(nested_tune_grid(
    det_workflow(d),
    det_nested(d),
    grid = det_grid(),
    metrics = reg_metrics()
  ))

  # roc_auc on a one-class assessment set reaches this routinely. The metric was
  # requested, so it keeps its panel as a failed fold keeps its axis slot --
  # dropping it left no trace that it had been asked for (F4).
  none <- res
  for (i in seq_len(nrow(none))) {
    rmse_row <- none$.metrics[[i]]$.metric == "rmse"
    none$.metrics[[i]]$.estimate[rmse_row] <- NA_real_
  }
  p <- autoplot(none, type = "performance")

  expect_identical(strip_labels(p), c("rmse (from 0 folds)", "rsq"))
  expect_identical(plot_points(p)$panel, rep("rsq", 3L))

  # And with nothing scored anywhere, the figure builds AND draws: it used to
  # return a ggplot that errored from inside ggplot2 when printed, which is
  # neither our own condition nor near the call that caused it.
  nothing <- res
  for (i in seq_len(nrow(nothing))) {
    nothing$.metrics[[i]]$.estimate <- NA_real_
  }
  empty <- autoplot(nothing, type = "performance")
  expect_s3_class(empty, "ggplot")
  # Laying the figure out is where it used to fail, so the assertion has to go
  # that far -- onto a null device, since letting one open by default writes an
  # Rplots.pdf at the package root and R CMD check NOTEs it.
  expect_no_error(on_null_device(ggplot2::ggplot_gtable(ggplot2::ggplot_build(
    empty
  ))))
})

test_that("two estimators for one metric get a panel each", {
  skip_if_no_engines()
  d <- make_reg_data()

  set.seed(2)
  res <- memoised(nested_tune_grid(
    det_workflow(d),
    det_nested(d),
    grid = det_grid(),
    metrics = reg_metrics()
  ))
  # Rare, but a metric reported under two estimators would otherwise share one
  # panel and be marked with two rules -- one of them wrong for every point
  # beside it.
  for (i in seq_len(nrow(res))) {
    m <- res$.metrics[[i]]
    extra <- m[m$.metric == "rsq", ]
    extra$.estimator <- "trad"
    extra$.estimate <- extra$.estimate / 2
    res$.metrics[[i]] <- rbind(m, extra)
  }
  p <- autoplot(res, type = "performance")

  expect_identical(
    strip_labels(p),
    c("rmse", "rsq (standard)", "rsq (trad)")
  )
  expect_identical(nrow(plot_rules(p)), 3L)
  expect_identical(plot_rules(p)$yintercept, collect_metrics(res)$mean)
})

test_that("a metric measured at several evaluation times gets a panel per time", {
  skip_if_no_engines()
  d <- make_reg_data()

  set.seed(2)
  res <- memoised(nested_tune_grid(
    det_workflow(d),
    det_nested(d),
    grid = det_grid(),
    metrics = reg_metrics()
  ))
  # The shape tune's last_fit() records for a metric set mixing a dynamic
  # survival metric with a static one (measured on tune 2.1.0, 2026-09-01): a
  # `.eval_time` column, NA on the static metric's row. Hand-built on the
  # regression fixture so the case costs no censored fit. Before the panel
  # carried the time, two rows for one metric read as one ambiguous metric,
  # both panels got the same label, and the level factor aborted on the
  # duplicate (M41 review F1).
  for (i in seq_len(nrow(res))) {
    res$.metrics[[i]] <- new_tbl(list(
      .metric = c("brier_survival", "brier_survival", "concordance_survival"),
      .estimator = rep("standard", 3L),
      .eval_time = c(0.5, 10, NA),
      .estimate = c(0.25, 0.22, 0.7) + i / 100,
      .config = rep("Preprocessor1_Model1", 3L)
    ))
  }
  p <- autoplot(res, type = "performance")

  expect_identical(
    strip_labels(p),
    c(
      "brier_survival at time 0.5",
      "brier_survival at time 10",
      "concordance_survival"
    )
  )
  points <- plot_points(p)
  expect_identical(nrow(points), 3L * nrow(res))
  expect_identical(
    points$y[points$panel == "brier_survival at time 10"],
    0.22 + seq_len(nrow(res)) / 100
  )
  expect_identical(nrow(plot_rules(p)), 3L)
  expect_identical(plot_rules(p)$yintercept, collect_metrics(res)$mean)

  # Two times differing below print precision are two panels, as they are two
  # summary rows; a label read at the default 7 digits would duplicate here.
  close <- res
  for (i in seq_len(nrow(close))) {
    close$.metrics[[i]]$.eval_time <- c(0.1 + 0.2, 0.3, NA)
  }
  expect_identical(nrow(plot_rules(autoplot(close, type = "performance"))), 3L)
})

test_that("a censored run at several evaluation times plots", {
  skip_if_no_censored()

  data <- srv_data()
  nested <- srv_nested(data)
  times <- srv_eval_times()

  set.seed(9)
  res <- suppressWarnings(memoised(nested_tune_grid(
    srv_workflow(data),
    nested,
    grid = srv_grid(),
    metrics = srv_metrics(),
    eval_time = times
  )))
  p <- autoplot(res, type = "performance")
  expect_identical(
    strip_labels(p),
    c("brier_survival at time 0.5", "brier_survival at time 10")
  )
  expect_identical(plot_rules(p)$yintercept, collect_metrics(res)$mean)
})

test_that("the parameters view is the default and both views are ggplots", {
  skip_if_no_engines()
  d <- make_reg_data()

  set.seed(2)
  res <- memoised(nested_tune_grid(
    det_workflow(d),
    det_nested(d),
    grid = det_grid(),
    metrics = reg_metrics()
  ))

  # A bare autoplot() dispatches: the generic is re-exported, so a user who has
  # loaded only nestedtune reaches the method without namespacing it.
  expect_s3_class(autoplot(res), "ggplot")
  expect_s3_class(autoplot(res, type = "performance"), "ggplot")
  expect_identical(
    plot_points(autoplot(res)),
    plot_points(autoplot(res, type = "parameters"))
  )
})

test_that("the performance view draws one point per fold and metric", {
  skip_if_no_engines()
  d <- make_reg_data()

  set.seed(2)
  res <- memoised(nested_tune_grid(
    det_workflow(d),
    det_nested(d),
    grid = det_grid(),
    metrics = reg_metrics()
  ))
  pts <- plot_points(autoplot(res, type = "performance"))

  expect_identical(sort(unique(pts$panel)), c("rmse", "rsq"))
  expect_identical(
    pts$fold,
    rep(c("Fold1", "Fold2", "Fold3"), each = 2L)
  )
  expect_identical(pts$y, collect_metrics(res, summarize = FALSE)$.estimate)
})

test_that("the marked estimate is the number collect_metrics reports", {
  skip_if_no_engines()
  d <- make_reg_data()

  set.seed(2)
  res <- memoised(nested_tune_grid(
    det_workflow(d),
    det_nested(d),
    grid = det_grid(),
    metrics = reg_metrics()
  ))
  rules <- plot_rules(autoplot(res, type = "performance"))
  summary <- collect_metrics(res)

  # Exact, not approximate: the rule is read off the same summarize_folds() the
  # summary uses, so any difference at all means one of them recomputed it.
  expect_identical(rules$panel, summary$.metric)
  expect_identical(rules$yintercept, summary$mean)
})

test_that("the performance view says the estimate is not a model's score", {
  skip_if_no_engines()
  d <- make_reg_data()

  set.seed(2)
  res <- memoised(nested_tune_grid(
    det_workflow(d),
    det_nested(d),
    grid = det_grid(),
    metrics = reg_metrics()
  ))
  p <- autoplot(res, type = "performance")

  # IP3, in the subtitle rather than only in the help page: ggplot2 renders a
  # subtitle into the image, so the caveat travels with a figure that has been
  # exported out of the session that produced it.
  subtitle <- plot_label(p, "subtitle")
  expect_match(subtitle, "3 outer folds requested, 3 completed")
  expect_match(subtitle, "nested estimate")
  expect_match(subtitle, "not a model you can deploy", fixed = TRUE)
  expect_match(plot_label(p, "y"), "held-out outer fold")
})

test_that("a failed fold keeps its slot and contributes no score", {
  skip_if_no_engines()
  d <- make_reg_data()

  set.seed(2)
  res <- suppressWarnings(memoised(nested_tune_grid(
    det_workflow(d),
    break_fold(det_nested(d), 2L, "outer fit"),
    grid = det_grid(),
    metrics = reg_metrics()
  )))
  p <- autoplot(res, type = "performance")
  rules <- plot_rules(p)

  expect_identical(axis_labels(p), c("Fold1", "Fold2", "Fold3"))
  expect_identical(plot_points(p)$fold, rep(c("Fold1", "Fold3"), each = 2L))
  expect_match(
    plot_label(p, "subtitle"),
    "3 outer folds requested, 2 completed"
  )
  # The rule averages the folds that ran, which is what the summary reports for
  # the same object -- neither claims the design that was requested (IP4).
  expect_identical(
    rules$yintercept,
    suppressWarnings(collect_metrics(res))$mean
  )
})

test_that("a fold scoring NA on one metric still scores the others", {
  skip_if_no_engines()
  d <- make_reg_data()

  set.seed(2)
  res <- memoised(nested_tune_grid(
    det_workflow(d),
    det_nested(d),
    grid = det_grid(),
    metrics = reg_metrics()
  ))
  # An outer assessment set with one class gives roc_auc = NA, so a fold can
  # complete and score on some metrics but not all. Staged here rather than
  # engineered, because a fixture that reaches it naturally would have to be a
  # classification design built for this one row.
  rmse_row <- res$.metrics[[2L]]$.metric == "rmse"
  res$.metrics[[2L]]$.estimate[rmse_row] <- NA_real_

  p <- autoplot(res, type = "performance")
  pts <- plot_points(p)

  # The rmse panel carries its own count, since two folds contributed to it
  # where three completed; rsq is unqualified because all three did.
  expect_identical(
    pts$fold[pts$panel == "rmse (from 2 folds)"],
    c("Fold1", "Fold3")
  )
  expect_identical(pts$fold[pts$panel == "rsq"], c("Fold1", "Fold2", "Fold3"))
  expect_identical(plot_rules(p)$yintercept, collect_metrics(res)$mean)
})

test_that("a run where no fold completed is refused, in plotting's own words", {
  skip_if_no_engines()
  d <- make_reg_data()

  set.seed(2)
  res <- suppressWarnings(memoised(nested_tune_grid(
    det_workflow(d),
    break_every_fold(det_nested(d)),
    grid = det_grid(),
    metrics = reg_metrics()
  )))

  # Printing describes such an object without complaint (M04); plotting is a
  # request for a figure of a design that did not run, so it refuses as
  # collect_metrics() does -- and says "plot", not "summarize", about the same
  # object.
  expect_error(autoplot(res), "nothing to plot")
  expect_error(autoplot(res, type = "performance"), "nothing to plot")
  expect_error(collect_metrics(res), "nothing to summarize")
  # Under one class, each view, as nested_final_fit() refuses the object.
  for (type in c("parameters", "performance")) {
    cnd <- rlang::catch_cnd(autoplot(res, type = type), "error")
    expect_s3_class(cnd, "nestedtune_no_completed_folds")
    expect_match(
      conditionMessage(cnd),
      "no outer fold completed",
      fixed = TRUE
    )
  }
})

test_that("a design with no tuned parameters points at the other view", {
  skip_if_no_engines()
  d <- make_reg_data()

  set.seed(2)
  res <- memoised(nested_tune_grid(
    det_workflow(d),
    det_nested(d),
    grid = det_grid(),
    metrics = reg_metrics()
  ))
  for (i in seq_len(nrow(res))) {
    res$.selected[[i]] <- res$.selected[[i]][, ".config", drop = FALSE]
  }

  expect_error(autoplot(res), "no tuned parameters")
  expect_error(autoplot(res), "type = \"performance\"", fixed = TRUE)
  # The scores are still there, so the view it points at must actually work.
  expect_s3_class(autoplot(res, type = "performance"), "ggplot")
})

test_that("an unrecognized type is refused by name", {
  skip_if_no_engines()
  d <- make_reg_data()

  set.seed(2)
  res <- memoised(nested_tune_grid(
    det_workflow(d),
    det_nested(d),
    grid = det_grid(),
    metrics = reg_metrics()
  ))

  expect_error(autoplot(res, type = "parameter"), "must be one of")
  expect_error(autoplot(res, type = "parameter"), "performance")
  expect_error(autoplot(res, type = c("performance", "parameters")), "one of")
  expect_error(autoplot(res, type = 1), "must be one of")
  expect_error(autoplot(res, type = NA_character_), "must be one of")
})

test_that("a whole-number parameter is not given fractional breaks", {
  skip_if_no_engines()
  d <- make_reg_data()

  set.seed(2)
  res <- memoised(nested_tune_grid(
    det_workflow(d),
    det_nested(d),
    grid = det_grid(),
    metrics = reg_metrics()
  ))

  # This fixture's folds are unanimous, which collapses the value range to
  # nothing. The default breaks then label a flat row of identical integer
  # choices 2.950, 2.975, 3.000 -- a plot about disagreement inventing some.
  expect_identical(axis_labels(autoplot(res), "y"), "3")

  # A genuinely continuous parameter keeps the default breaks, because rounding
  # one would collapse every candidate of, say, `penalty` onto zero.
  continuous <- res
  for (i in seq_len(nrow(continuous))) {
    continuous$.selected[[i]]$num_comp <- continuous$.selected[[i]]$num_comp / 8
  }
  labels <- axis_labels(autoplot(continuous), "y")
  expect_true(any(grepl(".", labels, fixed = TRUE)))
})

# The pictures.
#
# Everything above asserts on the built plot, which is blind to the part a
# reader actually meets: where the labels sit, whether the caveat fits, what a
# gap looks like. These pin that, on the same deterministic fixtures. vdiffr
# skips itself on CRAN and wherever its rendering stack differs, so a failure
# here is a change in the figure and never a change in the machine.
test_that("both views look the way they read", {
  skip_if_not_installed("vdiffr")
  skip_if_no_engines()
  d <- make_reg_data()
  u <- unstable_data()

  set.seed(2)
  agreed <- memoised(nested_tune_grid(
    det_workflow(d),
    det_nested(d),
    grid = det_grid(),
    metrics = reg_metrics()
  ))
  set.seed(2)
  split <- memoised(nested_tune_grid(
    unstable_workflow(u),
    det_nested(u, v = 4),
    grid = unstable_grid(),
    metrics = reg_metrics()
  ))
  set.seed(2)
  partial <- suppressWarnings(memoised(nested_tune_grid(
    det_workflow(d),
    break_fold(det_nested(d), 2L, "outer fit"),
    grid = det_grid(),
    metrics = reg_metrics()
  )))

  vdiffr::expect_doppelganger("parameters, folds agree", autoplot(agreed))
  vdiffr::expect_doppelganger("parameters, folds disagree", autoplot(split))
  # The gap where Fold2 sits is the whole point of keeping it on the axis, and
  # it is the one thing no assertion on the built data can see.
  vdiffr::expect_doppelganger("parameters, a fold failed", autoplot(partial))
  vdiffr::expect_doppelganger(
    "performance, folds agree",
    autoplot(agreed, type = "performance")
  )
})

test_that("a non-numeric selection is drawn on a discrete axis", {
  skip_if_no_engines()
  d <- make_reg_data()

  set.seed(2)
  res <- memoised(nested_tune_grid(
    det_workflow(d),
    det_nested(d),
    grid = det_grid(),
    metrics = reg_metrics()
  ))
  # A character-valued parameter is ordinary in the ecosystem (`weight_func`,
  # `activation`), and one panel cannot mix a numeric axis with a discrete one.
  # Every selected value in the plot being numeric is what earns the numeric
  # axis; anything else falls back to a discrete one for all panels.
  for (i in seq_len(nrow(res))) {
    res$.selected[[i]]$num_comp <- paste0("c", res$.selected[[i]]$num_comp)
  }
  p <- autoplot(res)

  expect_s3_class(p, "ggplot")
  expect_identical(plot_points(p)$fold, c("Fold1", "Fold2", "Fold3"))
  expect_identical(axis_labels(p, "y"), "c3")
})

# ---- the set views (M72) ------------------------------------------------------
#
# Asserted on the built plot as above, against the set readers: the points
# are `collect_metrics(x, summarize = FALSE)`'s scored rows and the rules
# are `collect_metrics(x)`'s means, so the figure and the tables cannot
# disagree about a number.

test_that("AC2: the set's performance view puts the workflows on x inside one panel per metric", {
  skip_if_no_wset_fixture()
  res <- wset_three_results()
  p <- expect_no_warning(autoplot(res, type = "performance"))
  expect_s3_class(p, "ggplot")

  # The panel names are the single view's, the x axis the ids in set order.
  expect_identical(strip_labels(p), c("rmse", "rsq"))
  expect_identical(axis_labels(p, "x"), res$wflow_id)
  expect_false(identical(res$wflow_id, sort(res$wflow_id)))

  # One point per scored fold, at the unsummarized reader's value.
  folds_tbl <- as.data.frame(collect_metrics(res, summarize = FALSE))
  scored <- folds_tbl[!is.na(folds_tbl$.estimate), ]
  pts <- plot_points(p)
  expect_identical(nrow(pts), nrow(scored))
  for (m in c("rmse", "rsq")) {
    rows <- scored$.metric == m
    expect_identical(pts$fold[pts$panel == m], scored$wflow_id[rows])
    expect_identical(pts$y[pts$panel == m], scored$.estimate[rows])
  }

  # One rule per workflow and panel, both ends at the summarized mean.
  seg <- plot_segments(p)
  means <- as.data.frame(collect_metrics(res))
  expect_identical(nrow(seg), nrow(means))
  for (i in seq_len(nrow(means))) {
    hit <- seg$x == means$wflow_id[[i]] & seg$panel == means$.metric[[i]]
    expect_identical(sum(hit), 1L)
    expect_identical(seg$ymin[hit], means$mean[[i]])
    expect_identical(seg$ymax[hit], means$mean[[i]])
  }

  subtitle <- plot_label(p, "subtitle")
  expect_match(subtitle, "3 workflows, 2 outer folds each.", fixed = TRUE)
  expect_no_match(subtitle, "summary()", fixed = TRUE)
  expect_match(
    subtitle,
    "It describes the tune-and-fit procedure, not a model you can deploy.",
    fixed = TRUE
  )
  expect_identical(plot_label(p, "x"), "Workflow")
})

test_that("AC2: an all-failed workflow keeps an empty slot on the x axis, and the subtitle counts it", {
  skip_if_no_wset_fixture()
  beside <- broken_set_results()
  warnings <- partial_warnings(p <- autoplot(beside, type = "performance"))
  expect_length(warnings, 1L)
  expect_match(
    conditionMessage(warnings[[1L]]),
    'Workflow "broken": no outer fold completed',
    fixed = TRUE
  )

  # On the axis, in set order, with nothing drawn at it.
  expect_identical(axis_labels(p, "x"), c("tuned", "broken"))
  pts <- plot_points(p)
  expect_identical(unique(pts$fold), "tuned")
  expect_identical(nrow(pts), 4L)
  seg <- plot_segments(p)
  expect_identical(unique(seg$x), "tuned")
  expect_identical(nrow(seg), 2L)
  expect_identical(
    seg$ymin[seg$panel == "rmse"],
    suppressWarnings(collect_metrics(beside))$mean[[1L]]
  )

  subtitle <- plot_label(p, "subtitle")
  expect_match(subtitle, "2 workflows, 2 outer folds each.", fixed = TRUE)
  expect_match(
    subtitle,
    "\n1 of 2 workflows did not complete every fold; see summary().\n",
    fixed = TRUE
  )
})

test_that("AC3: the set's parameters view is one panel per workflow and tuned parameter, each the single view's points", {
  skip_if_no_wset_fixture()
  res <- wset_three_results()
  p <- expect_no_warning(autoplot(res))
  expect_s3_class(p, "ggplot")

  # Set order, the id ahead of the single view's label; the fixed workflow
  # tuned nothing and has no panel.
  expect_identical(
    strip_labels(p),
    c("tuned: num_comp", "threshold: threshold")
  )
  expect_identical(axis_labels(p, "x"), c("Fold1", "Fold2"))
  pts <- plot_points(p)
  for (i in c(1L, 3L)) {
    own <- plot_points(autoplot(res$result[[i]]))
    panel <- paste0(res$wflow_id[[i]], ": ", unique(own$panel))
    expect_identical(pts$fold[pts$panel == panel], own$fold)
    expect_identical(pts$y[pts$panel == panel], own$y)
  }
  expect_identical(nrow(pts), 4L)
  # Every value drawn is a number, so the axis is numeric, and the
  # whole-number panel keeps whole-number breaks beside the continuous one.
  b <- ggplot2::ggplot_build(p)
  expect_false(b$layout$panel_scales_y[[1L]]$is_discrete())
  expect_identical(axis_labels(b, "y", panel = 1L), c("2", "3"))
  expect_true(any(grepl(".", axis_labels(b, "y", panel = 2L), fixed = TRUE)))

  subtitle <- plot_label(p, "subtitle")
  expect_match(subtitle, "3 workflows, 2 outer folds each.", fixed = TRUE)
  expect_match(subtitle, "folds disagreed", fixed = TRUE)
  expect_identical(plot_label(p, "x"), "Outer fold")

  # The axis is decided over the pooled values: one workflow's character
  # selection puts every panel on a discrete axis, as one parameter's does
  # in the single view.
  mixed <- res
  mixed$result[[3L]]$.selected <- lapply(
    mixed$result[[3L]]$.selected,
    function(s) {
      s$threshold <- paste0("t", s$threshold)
      s
    }
  )
  b <- ggplot2::ggplot_build(autoplot(mixed))
  expect_true(b$layout$panel_scales_y[[1L]]$is_discrete())
  expect_true(b$layout$panel_scales_y[[2L]]$is_discrete())
  expect_identical(plot_points(autoplot(mixed))$fold, pts$fold)
})

test_that("AC3: a set in which no workflow tuned a parameter is refused, pointing at the other view", {
  skip_if_no_wset_fixture("nested_fit_resamples")
  res <- wset_results("nested_fit_resamples")
  cnd <- rlang::catch_cnd(autoplot(res), "error")
  expect_s3_class(cnd, "nestedtune_no_tuned_parameters")
  expect_match(conditionMessage(cnd), "no tuned parameters", fixed = TRUE)
  expect_match(conditionMessage(cnd), "type = \"performance\"", fixed = TRUE)
  expect_identical(rlang::call_name(conditionCall(cnd)), "autoplot")
  # The view it points at draws the set.
  p <- autoplot(res, type = "performance")
  expect_s3_class(p, "ggplot")
  expect_identical(axis_labels(p, "x"), res$wflow_id)
})

test_that("AC4: both set views warn once per workflow with a failed fold, naming it, and keep the fold's slot", {
  skip_if_no_wset_fixture()
  partial <- wset_three_results(broken = 1L)
  for (type in c("parameters", "performance")) {
    warnings <- partial_warnings(p <- autoplot(partial, type = type))
    expect_length(warnings, 3L)
    for (i in 1:3) {
      msg <- conditionMessage(warnings[[i]])
      expect_match(msg, paste0('^Workflow "', partial$wflow_id[[i]], '"'))
      expect_match(msg, "This figure covers 1 of 2 outer folds", fixed = TRUE)
      expect_match(msg, "Fold1", fixed = TRUE)
      expect_identical(
        rlang::call_name(conditionCall(warnings[[i]])),
        "autoplot"
      )
    }
    expect_match(
      plot_label(p, "subtitle"),
      "3 of 3 workflows did not complete every fold; see summary().",
      fixed = TRUE
    )
  }
  # The parameters view keeps the failed fold on the axis and draws no
  # point at it; the performance view draws one point per workflow, metric
  # and completed fold.
  p <- suppressWarnings(autoplot(partial))
  pts <- plot_points(p)
  expect_identical(axis_labels(p, "x"), c("Fold1", "Fold2"))
  expect_identical(unique(pts$fold), "Fold2")
  expect_identical(nrow(pts), 2L)
  pts <- plot_points(suppressWarnings(autoplot(partial, type = "performance")))
  expect_identical(nrow(pts), 6L)
  expect_identical(
    sort(pts$y),
    sort(
      suppressWarnings(collect_metrics(partial, summarize = FALSE))$.estimate
    )
  )
})

test_that("AC4: an all-failed workflow contributes no point to either view, and a set with none completed is refused", {
  skip_if_no_wset_fixture()
  beside <- broken_set_results()
  for (type in c("parameters", "performance")) {
    warnings <- partial_warnings(p <- autoplot(beside, type = type))
    expect_length(warnings, 1L)
    expect_match(
      conditionMessage(warnings[[1L]]),
      'Workflow "broken": no outer fold completed',
      fixed = TRUE
    )
    expect_identical(
      rlang::call_name(conditionCall(warnings[[1L]])),
      "autoplot"
    )
  }
  # The completing workflow's panel alone, and its points alone.
  expect_identical(
    strip_labels(suppressWarnings(autoplot(beside))),
    "tuned: num_comp"
  )
  expect_identical(
    unique(plot_points(suppressWarnings(autoplot(beside)))$fold),
    c("Fold1", "Fold2")
  )
  expect_identical(
    unique(
      plot_points(
        suppressWarnings(autoplot(beside, type = "performance"))
      )$fold
    ),
    "tuned"
  )

  alone <- broken_set_results(alone = TRUE)
  for (type in c("parameters", "performance")) {
    cnd <- rlang::catch_cnd(autoplot(alone, type = type), "error")
    expect_s3_class(cnd, "nestedtune_no_completed_folds")
    expect_match(conditionMessage(cnd), "nothing to plot", fixed = TRUE)
    expect_match(conditionMessage(cnd), "2 workflows", fixed = TRUE)
    expect_identical(rlang::call_name(conditionCall(cnd)), "autoplot")
  }
})

test_that("AC4: the set's autoplot() refuses a type outside the two, and fences its dots first", {
  skip_if_no_wset_fixture()
  res <- wset_three_results()
  expect_error(autoplot(res, type = "parameter"), "must be one of")
  expect_error(autoplot(res, type = "parameter"), "performance")
  expect_error(autoplot(res, type = 1), "must be one of")
  expect_error(autoplot(res, type = NA_character_), "must be one of")
  expect_s3_class(
    rlang::catch_cnd(autoplot(res, nonesuch = 1)),
    "rlib_error_dots_nonempty"
  )
  # The fence before the type check.
  expect_s3_class(
    rlang::catch_cnd(autoplot(res, type = "parameter", nonesuch = 1)),
    "rlib_error_dots_nonempty"
  )
})

# The pictures of the set views, on the three-workflow fixture: what a reader
# meets -- the id-prefixed strips, the workflows along one axis under each
# metric, the rules -- pinned after being rendered and read (M72).
test_that("both set views look the way they read", {
  skip_if_not_installed("vdiffr")
  skip_if_no_wset_fixture()
  res <- wset_three_results()
  vdiffr::expect_doppelganger("set parameters, three workflows", autoplot(res))
  vdiffr::expect_doppelganger(
    "set performance, three workflows",
    autoplot(res, type = "performance")
  )
})
