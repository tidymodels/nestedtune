# The fold label columns of the per-fold metrics tables (M122).
#
# Oracle provenance. The expected labels are read from the rsample design
# object the run was given, row by row, and repeated once per metric in the
# order the metric set lists them. Nothing expected is read from the result,
# so a table that pasted the labels or reordered the folds fails.

skip_heavy_on_cran()

# The repeated design: v = 2 repeated twice, four outer folds labelled by
# `id` (the repeat) and `id2` (the fold). Returned beside the run, so a test
# reads its expected labels from the design.
repeated_label_design <- function(d) {
  set.seed(41)
  nested_resamples(
    d,
    outside = rsample::vfold_cv(v = 2, repeats = 2),
    inside = rsample::vfold_cv(v = 2)
  )
}

single_label_design <- function(d) {
  set.seed(42)
  nested_resamples(
    d,
    outside = rsample::vfold_cv(v = 2),
    inside = rsample::vfold_cv(v = 2)
  )
}

label_run <- function(folds, d) {
  set.seed(43)
  memoised(nested_tune_grid(
    det_workflow(d),
    folds,
    grid = det_grid(),
    metrics = reg_metrics(),
    control = tune::control_grid(save_pred = TRUE)
  ))
}

# The tuned workflow keeps its predictions through the call's control, the
# fixed one through its own option, as the set reader tests do.
label_set_run <- function(folds, d) {
  set.seed(44)
  wset <- workflowsets::option_add(
    wset_two(d),
    id = "fixed",
    control = tune::control_resamples(save_pred = TRUE)
  )
  set.seed(44)
  memoised(nested_workflow_map(
    object = wset,
    fn = "nested_tune_grid",
    resamples = folds,
    grid = det_grid(),
    metrics = reg_metrics(),
    control = tune::control_grid(save_pred = TRUE)
  ))
}

# The design's own labels, one row per fold repeated `each` times, as columns.
design_labels <- function(folds, cols, each) {
  out <- lapply(cols, function(nm) rep(folds[[nm]], each = each))
  names(out) <- cols
  out
}

n_metrics <- function(ms) length(attr(ms, "metrics"))

# Every column of `tbl` other than the label columns holds no value that
# pastes two of the design's labels together.
expect_no_pasted_label <- function(tbl, folds) {
  pasted <- paste(folds$id, folds$id2, sep = ", ")
  for (nm in names(tbl)) {
    if (is.character(tbl[[nm]]) || is.factor(tbl[[nm]])) {
      expect_false(any(as.character(tbl[[nm]]) %in% pasted), label = nm)
    }
  }
}

test_that("AC1: a repeated design's per-fold tables carry id and id2 from the design, long and wide", {
  skip_if_no_engines()
  d <- make_reg_data()
  folds <- repeated_label_design(d)
  expect_identical(names(folds)[names(folds) %in% c("id", "id2")], c("id", "id2"))
  res <- label_run(folds, d)
  expect_identical(nrow(res), 4L)
  expect_true(all(res$.completed))

  long <- collect_metrics(res, summarize = FALSE)
  expect_identical(names(long)[1:2], c("id", "id2"))
  expected <- design_labels(folds, c("id", "id2"), n_metrics(reg_metrics()))
  expect_identical(long$id, expected$id)
  expect_identical(long$id2, expected$id2)
  expect_no_pasted_label(long, folds)

  wide <- collect_metrics(res, summarize = FALSE, type = "wide")
  expect_identical(names(wide)[1:2], c("id", "id2"))
  expect_identical(wide$id, folds$id)
  expect_identical(wide$id2, folds$id2)
  expect_no_pasted_label(wide, folds)

  ms <- yardstick::metric_set(yardstick::mae)
  scored <- compute_metrics(res, ms, summarize = FALSE)
  expect_identical(names(scored)[1:2], c("id", "id2"))
  expect_identical(scored$id, folds$id)
  expect_identical(scored$id2, folds$id2)
  expect_no_pasted_label(scored, folds)
})

test_that("AC1: a single-column design keeps its one id column, and the summaries match the repeated design's names", {
  skip_if_no_engines()
  d <- make_reg_data()
  single_folds <- single_label_design(d)
  single <- label_run(single_folds, d)
  repeated <- label_run(repeated_label_design(d), d)

  long <- collect_metrics(single, summarize = FALSE)
  expect_identical(names(long)[[1L]], "id")
  expect_false("id2" %in% names(long))
  expect_identical(
    long$id,
    design_labels(single_folds, "id", n_metrics(reg_metrics()))$id
  )
  wide <- collect_metrics(single, summarize = FALSE, type = "wide")
  expect_identical(wide$id, single_folds$id)
  expect_false("id2" %in% names(wide))
  ms <- yardstick::metric_set(yardstick::mae)
  expect_identical(
    compute_metrics(single, ms, summarize = FALSE)$id,
    single_folds$id
  )

  expect_identical(
    names(collect_metrics(repeated)),
    names(collect_metrics(single))
  )
  expect_identical(
    names(collect_metrics(repeated, type = "wide")),
    names(collect_metrics(single, type = "wide"))
  )
  expect_identical(
    names(compute_metrics(repeated, ms)),
    names(compute_metrics(single, ms))
  )
})

test_that("AC2: a set over a repeated design carries wflow_id, id and id2 as separate columns", {
  skip_if_no_wset_fixture()
  d <- make_reg_data()
  folds <- repeated_label_design(d)
  res <- label_set_run(folds, d)
  expect_identical(res$wflow_id, c("tuned", "fixed"))
  n_wf <- nrow(res)

  long <- collect_metrics(res, summarize = FALSE)
  expect_identical(names(long)[1:3], c("wflow_id", "id", "id2"))
  per_wf <- n_metrics(reg_metrics()) * nrow(folds)
  expect_identical(long$wflow_id, rep(res$wflow_id, each = per_wf))
  expected <- design_labels(folds, c("id", "id2"), n_metrics(reg_metrics()))
  expect_identical(long$id, rep(expected$id, times = n_wf))
  expect_identical(long$id2, rep(expected$id2, times = n_wf))
  expect_no_pasted_label(long, folds)

  wide <- collect_metrics(res, summarize = FALSE, type = "wide")
  expect_identical(names(wide)[1:3], c("wflow_id", "id", "id2"))
  expect_identical(wide$id, rep(folds$id, times = n_wf))
  expect_identical(wide$id2, rep(folds$id2, times = n_wf))
  expect_no_pasted_label(wide, folds)

  ms <- yardstick::metric_set(yardstick::mae)
  scored <- compute_metrics(res, ms, summarize = FALSE)
  expect_identical(names(scored)[1:3], c("wflow_id", "id", "id2"))
  expect_identical(scored$id, rep(folds$id, times = n_wf))
  expect_identical(scored$id2, rep(folds$id2, times = n_wf))
  expect_no_pasted_label(scored, folds)
})

test_that("AC3: the performance plot's fold axis pastes the design's labels and draws each non-missing estimate", {
  skip_if_no_engines()
  skip_if_not_installed("ggplot2")
  d <- make_reg_data()
  folds <- repeated_label_design(d)
  res <- label_run(folds, d)
  pasted <- paste(folds$id, folds$id2, sep = ", ")
  per_fold <- n_metrics(reg_metrics())

  p <- autoplot(res, type = "performance")
  expect_identical(levels(p$data$fold), pasted)
  expect_identical(nrow(p$data), nrow(folds) * per_fold)
  expect_identical(as.character(p$data$fold), rep(pasted, each = per_fold))

  # One estimate emptied: the first metric of the first fold draws no point,
  # and the fold keeps its slot on the axis.
  holed <- res
  holed$.metrics[[1L]]$.estimate[[1L]] <- NA_real_
  q <- autoplot(holed, type = "performance")
  expect_identical(levels(q$data$fold), pasted)
  expect_identical(nrow(q$data), nrow(folds) * per_fold - 1L)
  expect_identical(
    as.character(q$data$fold),
    rep(pasted, each = per_fold)[-1L]
  )
  expect_no_error(on_null_device(ggplot2::ggplot_gtable(ggplot2::ggplot_build(q))))

  expect_no_error(utils::capture.output(print(res), type = "message"))
})

test_that("AC3: a set's performance plot builds on a repeated design", {
  skip_if_no_wset_fixture()
  skip_if_not_installed("ggplot2")
  d <- make_reg_data()
  res <- label_set_run(repeated_label_design(d), d)
  p <- autoplot(res, type = "performance")
  expect_s3_class(p, "ggplot")
  expect_no_error(on_null_device(ggplot2::ggplot_gtable(ggplot2::ggplot_build(p))))
})
