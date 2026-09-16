# The outer average under tune's resample weights (M101).
#
# The door is `tune::add_resample_weights()` on the design. tune normalizes
# the weights to sum one and stores them as the rset's `.resample_weights`
# attribute; equal weights are stored as no attribute at all
# (`tune:::.validate_resample_weights`, tune 2.1.0, read 2026-09-16).
#
# Oracle provenance (GP2, two independent types for AC1):
#
# O1 -- type "analytic by-hand". Source: tune's own weighted formulas,
#   written out below in `weighted_summary()` from
#   `deparse(tune:::estimate_tune_results)` lines 51-54 (`weighted.mean`,
#   `.effective_sample_size` over the non-NA folds' weights, `.weighted_sd`
#   over `sqrt(pmax(effective_n, 1))`), `deparse(tune:::.weighted_sd)` lines
#   12-15 (`stats::cov.wt(..., cor = FALSE)$cov[1, 1]`, square-rooted) and
#   `deparse(tune:::.effective_sample_size)` lines 7-12
#   (`sum(w)^2 / sum(w^2)`), tune 2.1.0, read 2026-09-16 (the M28 lesson).
#   The per-fold estimates it averages are read off the UNWEIGHTED run of
#   the same fixture, never off the weighted run under test. On a failed
#   fold the formulas are applied to the folds that scored, the divergence
#   from tune the plan chose: tune's weighted branch takes no `na.rm`, so
#   a fold scoring NA errors inside `cov.wt()`, and a failed fold makes it
#   ignore the weights with a warning (run 2026-09-16, tune#1197).
#
# O2 -- type "live" (reference implementation). Source: `tune::fit_resamples()`
#   on the same outer `vfold_cv()` splits under the same weights, whose
#   `collect_metrics()` is tune's weighted branch itself. Every-fold case
#   only, where tune and this package agree.

weighted_design <- function(data, weights = c(1, 2, 3)) {
  tune::add_resample_weights(det_nested(data), weights)
}

# O1, written from tune's code and never from the package's.
weighted_summary <- function(estimates, weights) {
  keep <- !is.na(estimates)
  x <- estimates[keep]
  w <- weights[keep]
  effective_n <- sum(w)^2 / sum(w^2)
  weighted_sd <- if (length(x) <= 1L) {
    NA_real_
  } else {
    sqrt(stats::cov.wt(data.frame(x), wt = w, cor = FALSE)$cov[1, 1])
  }
  list(
    mean = stats::weighted.mean(x, w),
    n = length(x),
    std_err = weighted_sd / sqrt(max(effective_n, 1))
  )
}

expect_weighted_rows <- function(summarized, per_fold, weights) {
  expect_setequal(summarized$.metric, unique(per_fold$.metric))
  for (m in summarized$.metric) {
    rows <- per_fold[per_fold$.metric == m, ]
    # Fold order in the per-fold table is design order, the order tune's
    # attribute is in; the weights are matched by fold label so a reordered
    # table cannot pass by position alone.
    w <- weights[match(rows$id, names(weights))]
    ref <- weighted_summary(rows$.estimate, w)
    got <- summarized[summarized$.metric == m, ]
    expect_equal(got$mean, ref$mean, tolerance = 1e-12)
    expect_identical(got$n, as.integer(ref$n))
    expect_equal(got$std_err, ref$std_err, tolerance = 1e-12)
  }
}

# The normalized weights tune stores, named by fold id.
stored_weights <- function(design) {
  w <- attr(design, ".resample_weights")
  names(w) <- design$id
  w
}

weighted_grid_run <- function(
  d,
  design = weighted_design(d),
  control = tune::control_grid()
) {
  set.seed(2)
  memoised(nested_tune_grid(
    det_workflow(d),
    design,
    grid = det_grid(),
    metrics = reg_metrics(),
    control = control
  ))
}

unweighted_grid_run <- function(d) {
  set.seed(2)
  memoised(nested_tune_grid(
    det_workflow(d),
    det_nested(d),
    grid = det_grid(),
    metrics = reg_metrics()
  ))
}

test_that("AC1: nested_fit_resamples() on a weighted design reports tune's weighted mean and standard error (O1)", {
  skip_if_no_engines()
  d <- make_reg_data()
  design <- weighted_design(d)
  set.seed(30)
  res <- memoised(nested_fit_resamples(
    fixed_workflow(d),
    design,
    metrics = reg_metrics()
  ))
  plain <- fit_resamples_results(d)

  # The same folds under the same seed score the same numbers; the weights
  # change the average only.
  expect_identical(res$.metrics, plain$.metrics)
  per_fold <- collect_metrics(plain, summarize = FALSE)
  expect_false(".weight" %in% names(per_fold))

  got <- collect_metrics(res)
  expect_weighted_rows(got, per_fold, stored_weights(design))
  # A weighted mean that equals the plain one would make the assertion
  # above blind; on this fixture the two differ.
  expect_false(isTRUE(all.equal(got$mean, collect_metrics(plain)$mean)))
})

test_that("AC1: nested_fit_resamples() on a weighted design matches tune::fit_resamples() under the same weights (O2)", {
  skip_if_no_engines()
  d <- make_reg_data()
  wf <- fixed_workflow(d)
  ms <- reg_metrics()
  weights <- c(1, 2, 3)
  design <- weighted_design(d, weights)

  # The same call under the same seed det_nested() makes internally, so the
  # outer splits are identical without reading them off the nested object.
  set.seed(11)
  outer <- tune::add_resample_weights(rsample::vfold_cv(d, v = 3), weights)

  set.seed(30)
  res <- memoised(nested_fit_resamples(wf, design, metrics = ms))
  plain <- tune::fit_resamples(
    wf,
    resamples = outer,
    metrics = ms,
    control = tune::control_resamples(allow_par = FALSE)
  )
  ref <- tune::collect_metrics(plain)
  got <- collect_metrics(res)
  expect_identical(got$.metric, ref$.metric)
  expect_equal(got$mean, ref$mean, tolerance = 1e-12)
  expect_identical(got$n, ref$n)
  expect_equal(got$std_err, ref$std_err, tolerance = 1e-12)
})

test_that("AC1: nested_tune_grid() on a weighted design reports tune's weighted mean and standard error", {
  skip_if_no_engines()
  d <- make_reg_data()
  design <- weighted_design(d)
  res <- weighted_grid_run(d, design)
  plain <- unweighted_grid_run(d)

  expect_identical(res$.metrics, plain$.metrics)
  expect_identical(res$.selected, plain$.selected)
  got <- collect_metrics(res)
  expect_weighted_rows(
    got,
    collect_metrics(plain, summarize = FALSE),
    stored_weights(design)
  )
  expect_false(isTRUE(all.equal(got$mean, collect_metrics(plain)$mean)))
})

test_that("AC1: with one fold failed, the weighted average covers the folds that scored", {
  skip_if_no_engines()
  d <- make_reg_data()
  design <- break_fold(weighted_design(d), 2L, "inner tuning")
  # break_fold() assigns into a column and keeps the attribute; asserted so
  # the test cannot pass on an unweighted run by accident.
  expect_length(attr(design, ".resample_weights"), 3L)
  res <- suppressWarnings(weighted_grid_run(d, design))
  expect_identical(res$.completed, c(TRUE, FALSE, TRUE))

  plain_design <- break_fold(det_nested(d), 2L, "inner tuning")
  set.seed(2)
  plain <- suppressWarnings(memoised(nested_tune_grid(
    det_workflow(d),
    plain_design,
    grid = det_grid(),
    metrics = reg_metrics()
  )))
  expect_identical(res$.metrics, plain$.metrics)

  got <- suppressWarnings(collect_metrics(res))
  per_fold <- suppressWarnings(collect_metrics(plain, summarize = FALSE))
  expect_weighted_rows(got, per_fold, stored_weights(design))
  expect_identical(got$n, c(2L, 2L))
  expect_false(anyNA(got$mean))
  expect_false(anyNA(got$std_err))
  expect_s3_class(
    rlang::catch_cnd(collect_metrics(res), "nestedtune_partial_summary"),
    "nestedtune_partial_summary"
  )
})

test_that("AC1: with a fold scoring NA, the weights are renormalized over the folds that scored", {
  skip_if_no_engines()
  d <- make_reg_data()
  design <- weighted_design(d)
  res <- weighted_grid_run(d, design)
  plain <- unweighted_grid_run(d)
  # An NA estimate planted on one fold's rsq row of both runs, through the
  # record rather than the reader, so the summary's NA rule is what is under
  # test; the per-fold estimates the oracle averages come off the unweighted
  # run, as in the other tests.
  plant_na <- function(x) {
    x$.metrics[[3L]]$.estimate[x$.metrics[[3L]]$.metric == "rsq"] <- NA_real_
    x
  }
  res <- plant_na(res)
  plain <- plant_na(plain)
  per_fold <- collect_metrics(plain, summarize = FALSE)
  expect_identical(sum(is.na(per_fold$.estimate)), 1L)
  expect_identical(
    collect_metrics(res, summarize = FALSE)$.estimate,
    per_fold$.estimate
  )

  got <- collect_metrics(res)
  expect_weighted_rows(got, per_fold, stored_weights(design))
  expect_identical(got$n[got$.metric == "rsq"], 2L)
  expect_identical(got$n[got$.metric == "rmse"], 3L)
})

test_that("AC2: equal weights are no weights, and the numbers are the unweighted run's", {
  skip_if_no_engines()
  d <- make_reg_data()
  design <- tune::add_resample_weights(det_nested(d), c(2, 2, 2))
  expect_null(attr(design, ".resample_weights"))
  res <- weighted_grid_run(d, design)
  plain <- unweighted_grid_run(d)
  expect_identical(collect_metrics(res), collect_metrics(plain))
  expect_identical(
    collect_metrics(res, summarize = FALSE),
    collect_metrics(plain, summarize = FALSE)
  )
  expect_null(attr(res, "resample_weights"))
})

test_that("AC3: collect_metrics(summarize = FALSE) carries each fold's weight, by fold label", {
  skip_if_no_engines()
  d <- make_reg_data()
  design <- weighted_design(d)
  res <- weighted_grid_run(d, design)
  w <- stored_weights(design)

  per_fold <- collect_metrics(res, summarize = FALSE)
  expect_true(".weight" %in% names(per_fold))
  expect_identical(
    names(per_fold),
    c("id", ".metric", ".estimator", ".estimate", ".weight")
  )
  expect_equal(per_fold$.weight, unname(w[per_fold$id]))

  # A reordered run keeps each fold's own weight: the record is keyed by
  # fold label, not by row position.
  reordered <- dplyr::arrange(res, dplyr::desc(id))
  expect_s3_class(reordered, "nested_results")
  per_fold_r <- collect_metrics(reordered, summarize = FALSE)
  expect_identical(per_fold_r$id[[1L]], "Fold3")
  expect_equal(per_fold_r$.weight, unname(w[per_fold_r$id]))
  # Equal up to summation order, which the reorder changes.
  expect_equal(
    dplyr::arrange(collect_metrics(reordered), .metric),
    dplyr::arrange(collect_metrics(res), .metric)
  )
})

test_that("AC3: compute_metrics() with the run's metric set is collect_metrics() on a weighted run", {
  skip_if_no_engines()
  d <- make_reg_data()
  design <- weighted_design(d)
  res <- weighted_grid_run(
    d,
    design,
    control = tune::control_grid(save_pred = TRUE)
  )
  expect_identical(compute_metrics(res, reg_metrics()), collect_metrics(res))
  expect_identical(
    compute_metrics(res, reg_metrics(), summarize = FALSE),
    collect_metrics(res, summarize = FALSE)
  )
  # And not by both being unweighted.
  expect_true(
    ".weight" %in% names(compute_metrics(res, reg_metrics(), summarize = FALSE))
  )
})

test_that("AC3: the set readers stack each workflow's weighted rows", {
  skip_if_no_engines()
  d <- make_reg_data()
  design <- tune::add_resample_weights(final_nested(d), c(1, 3))
  # The fixed set through the plain orchestrator, so one control reaches
  # every workflow and compute_metrics() can answer on the set.
  set.seed(31)
  wset <- wset_fixed(d)
  set.seed(31)
  res <- memoised(nested_workflow_map(
    object = wset,
    fn = "nested_fit_resamples",
    resamples = design,
    metrics = reg_metrics(),
    control = tune::control_resamples(save_pred = TRUE)
  ))

  per_fold <- collect_metrics(res, summarize = FALSE)
  expect_true(".weight" %in% names(per_fold))
  expect_equal(
    per_fold$.weight,
    unname(stored_weights(design)[per_fold$id])
  )
  by_element <- lapply(res$result, collect_metrics)
  stacked <- collect_metrics(res)
  for (i in seq_along(res$wflow_id)) {
    own <- stacked[stacked$wflow_id == res$wflow_id[[i]], ]
    expect_equal(own$mean, by_element[[i]]$mean)
    expect_equal(own$std_err, by_element[[i]]$std_err)
  }
  expect_identical(compute_metrics(res, reg_metrics()), collect_metrics(res))
})

test_that("AC1: summary(), print and autoplot read the weighted estimate", {
  skip_if_no_engines()
  d <- make_reg_data()
  design <- weighted_design(d)
  res <- weighted_grid_run(d, design)
  weighted <- collect_metrics(res)
  plain <- collect_metrics(unweighted_grid_run(d))
  expect_identical(summary(res)$estimate, weighted)
  text <- print_text(summary(res))
  printed <- regmatches(text, regexpr("rmse \\(standard\\): [0-9.]+", text))
  printed <- sub("rmse \\(standard\\): ", "", printed)
  expect_identical(printed, format(weighted$mean[[1L]], digits = 3))
  expect_false(identical(printed, format(plain$mean[[1L]], digits = 3)))
  # The dashed rule is the first layer of the performance view.
  p <- autoplot(res, type = "performance")
  rules <- ggplot2::layer_data(p, 1L)$yintercept
  expect_equal(sort(rules), sort(weighted$mean))
})

test_that("AC1: folds that scored carrying zero weight between them read NA, not an error", {
  skip_if_no_engines()
  d <- make_reg_data()
  # tune admits a zero weight; the dropped fold held all the weight.
  design <- break_fold(
    tune::add_resample_weights(det_nested(d), c(0, 0, 1)),
    3L,
    "inner tuning"
  )
  res <- suppressWarnings(weighted_grid_run(d, design))
  expect_identical(res$.completed, c(TRUE, TRUE, FALSE))
  got <- suppressWarnings(collect_metrics(res))
  expect_true(all(is.na(got$mean)))
  expect_true(all(is.na(got$std_err)))
  expect_identical(got$n, c(2L, 2L))
})

test_that("AC3: a bare result sheds the weights with the class (IP4)", {
  skip_if_no_engines()
  d <- make_reg_data()
  res <- weighted_grid_run(d, weighted_design(d))
  expect_false(is.null(attr(res, "resample_weights")))
  bare <- res[1:2, ]
  expect_false(inherits(bare, "nested_results"))
  expect_null(attr(bare, "resample_weights"))
})
