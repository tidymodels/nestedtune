# augment() on a nested run (M92).
#
# Oracle provenance. The expected table is built from the data and from
# `collect_predictions()` by matching `.row`, never from the method: each data
# row's prediction columns are that row's entry in the stacked predictions,
# and the data columns are the data as the design holds it.

# A regression run on `folds`, saving predictions, served from the cache.
augment_run <- function(
  data,
  folds,
  control = tune::control_grid(save_pred = TRUE)
) {
  set.seed(21)
  suppressWarnings(memoised(nested_tune_grid(
    det_workflow(data),
    folds,
    grid = det_grid(),
    metrics = reg_metrics(),
    control = control
  )))
}

grouped_data <- function() {
  d <- make_reg_data()
  d$g <- factor(rep(seq_len(15), each = 6))
  d
}

# The expected augment() table by hand. Rows whose fold failed have no entry
# in collect_predictions(), so they hold NA in every prediction column.
hand_augmented <- function(x) {
  data <- tibble::as_tibble(x$splits[[1]]$data)
  preds <- suppressWarnings(collect_predictions(x))
  pred_cols <- grep("^\\.pred", names(preds), value = TRUE)
  at <- match(seq_len(nrow(data)), preds$.row)
  out <- tibble::as_tibble(preds[at, pred_cols])
  dplyr::bind_cols(data[, "y"], out, data[, setdiff(names(data), "y")])
}

expect_augmented <- function(x) {
  aug <- augment(x)
  data <- x$splits[[1]]$data
  expect_identical(nrow(aug), nrow(data))
  expect_false(any(c(".row", ".config", "id", "id2") %in% names(aug)))
  # One outcome column, the data's.
  expect_identical(sum(names(aug) == "y"), 1L)
  expect_identical(aug$y, data$y)
  expect_identical(aug, hand_augmented(x))
  invisible(aug)
}

# ---- AC4: one row per data row -------------------------------------------

test_that("on a v-fold design from nested_resamples(), augment() joins each row's held-out prediction", {
  skip_if_no_engines()
  d <- make_reg_data()
  set.seed(31)
  folds <- nested_resamples(
    d,
    outside = rsample::vfold_cv(v = 3),
    inside = rsample::vfold_cv(v = 3)
  )
  res <- augment_run(d, folds)
  aug <- expect_augmented(res)
  expect_identical(names(aug), c("y", ".pred", "x1", "x2", "x3", "x4"))
  expect_false(anyNA(aug$.pred))
})

test_that("on a v-fold design from rsample::nested_cv(), augment() joins each row's held-out prediction", {
  skip_if_no_engines()
  d <- make_reg_data()
  set.seed(32)
  folds <- rsample::nested_cv(
    d,
    outside = rsample::vfold_cv(v = 3),
    inside = rsample::vfold_cv(v = 3)
  )
  res <- augment_run(d, folds)
  aug <- expect_augmented(res)
  expect_false(anyNA(aug$.pred))
})

test_that("on a grouped v-fold design, augment() joins each row's held-out prediction", {
  skip_if_no_engines()
  d <- grouped_data()
  set.seed(33)
  folds <- nested_resamples(
    d,
    outside = rsample::group_vfold_cv(group = g, v = 3),
    inside = rsample::vfold_cv(v = 3)
  )
  res <- augment_run(d, folds)
  aug <- expect_augmented(res)
  expect_identical(aug$g, d$g)
  expect_false(anyNA(aug$.pred))
})

test_that("on a classification run, the class and probability columns are joined", {
  skip_if_no_engines(stochastic = TRUE)
  d <- cls_data()
  set.seed(3)
  res <- memoised(nested_tune_grid(
    cls_workflow(d),
    cls_nested(d),
    grid = cls_grid(),
    metrics = cls_metrics(),
    event_level = "second",
    control = tune::control_grid(save_pred = TRUE)
  ))
  aug <- expect_augmented(res)
  expect_identical(
    names(aug)[1:4],
    c("y", ".pred_class", ".pred_event", ".pred_other")
  )
  expect_identical(levels(aug$.pred_class), levels(d$y))
})

test_that("on a censored-regression run, whose outcome names no data column, the predictions come first", {
  skip_if_no_censored()
  d <- srv_data()
  set.seed(4)
  res <- suppressWarnings(memoised(nested_tune_grid(
    srv_workflow(d),
    srv_nested(d),
    grid = srv_grid(),
    metrics = srv_metrics(),
    eval_time = srv_eval_times(),
    control = tune::control_grid(save_pred = TRUE)
  )))
  aug <- augment(res)
  expect_identical(nrow(aug), nrow(d))
  expect_identical(names(aug), c(".pred", names(d)))
  expect_type(aug$.pred, "list")
  preds <- collect_predictions(res)
  expect_identical(aug$.pred, preds$.pred[match(seq_len(nrow(d)), preds$.row)])
})

# ---- AC5: refusals and failed folds --------------------------------------

test_that("an outer design holding a row out other than once is refused with nestedtune_augment_rows", {
  skip_if_no_engines()
  d <- make_reg_data()
  set.seed(34)
  repeated <- nested_resamples(
    d,
    outside = rsample::vfold_cv(v = 3, repeats = 2),
    inside = rsample::vfold_cv(v = 3)
  )
  set.seed(35)
  monte_carlo <- nested_resamples(
    d,
    outside = rsample::mc_cv(prop = 0.75, times = 3),
    inside = rsample::vfold_cv(v = 3)
  )
  for (folds in list(repeated, monte_carlo)) {
    res <- augment_run(d, folds)
    cnd <- rlang::catch_cnd(augment(res), "error")
    expect_s3_class(cnd, "nestedtune_augment_rows")
    expect_identical(conditionCall(cnd)[[1L]], as.name("augment"))
  }
})

test_that("a run without saved predictions is refused with nestedtune_column_not_saved", {
  skip_if_no_engines()
  d <- make_reg_data()
  res <- augment_run(d, det_nested(d), control = NULL)
  cnd <- rlang::catch_cnd(augment(res), "error")
  expect_s3_class(cnd, "nestedtune_column_not_saved")
  expect_match(conditionMessage(cnd), "save_pred", fixed = TRUE)
})

test_that("a run with no completed fold is refused with nestedtune_no_completed_folds", {
  skip_if_no_engines()
  d <- make_reg_data()
  res <- augment_run(d, break_every_fold(det_nested(d)))
  expect_false(any(res$.completed))
  cnd <- rlang::catch_cnd(augment(res), "error")
  expect_s3_class(cnd, "nestedtune_no_completed_folds")
})

test_that("on a run with a failed fold, the rows it held out hold NA and a nestedtune_partial_summary warning is raised", {
  skip_if_no_engines()
  d <- make_reg_data()
  res <- augment_run(d, break_fold(det_nested(d), 2L, "inner tuning"))
  expect_identical(res$.completed, c(TRUE, FALSE, TRUE))

  expect_warning(aug <- augment(res), class = "nestedtune_partial_summary")
  held_out <- rsample::complement(res$splits[[2L]])
  expect_identical(which(is.na(aug$.pred)), sort(held_out))
  expect_identical(nrow(aug), nrow(d))
  expect_identical(aug, suppressWarnings(hand_augmented(res)))
})

test_that("non-empty `...` is refused", {
  skip_if_no_engines()
  d <- make_reg_data()
  res <- augment_run(d, det_nested(d))
  expect_error(augment(res, parameters = 1), class = "rlib_error_dots_nonempty")
})

# ---- M93: saved predictions that do not match the held-out rows ----------
# `edit_fold_predictions()` and `plant_row_mismatch()` are in
# `helper-predictions.R`, shared with the `compute_metrics()` tests (M100).

expect_predictions_refused <- function(x, labels) {
  cnd <- rlang::catch_cnd(augment(x), "error")
  expect_s3_class(cnd, "nestedtune_augment_predictions")
  expect_identical(conditionCall(cnd)[[1L]], as.name("augment"))
  expect_match(conditionMessage(cnd), labels, fixed = TRUE)
  invisible(cnd)
}

for (case in row_mismatch_cases) {
  test_that(
    paste0(
      "the `",
      case,
      "` mismatch on the first and a later fold is refused with nestedtune_augment_predictions"
    ),
    {
      skip_if_no_engines()
      d <- make_reg_data()
      res <- augment_run(d, det_nested(d))
      expect_true(all(res$.completed))
      for (i in c(1L, 3L)) {
        cnd <- expect_predictions_refused(
          plant_row_mismatch(res, i, case),
          res$id[[i]]
        )
        # Only the edited fold is named.
        for (other in setdiff(res$id, res$id[[i]])) {
          expect_no_match(conditionMessage(cnd), other, fixed = TRUE)
        }
      }
    }
  )
}

test_that("a mismatch is refused before a data column named like a prediction column", {
  skip_if_no_engines()
  d <- make_reg_data()
  res <- augment_run(d, det_nested(d))
  planted <- plant_row_mismatch(res, 1L, "missing")
  planted$splits[[1L]]$data$.pred <- 1
  expect_predictions_refused(planted, res$id[[1L]])
})

test_that("a double .row with the held-out values is accepted", {
  skip_if_no_engines()
  d <- make_reg_data()
  res <- augment_run(d, det_nested(d))
  as_double <- res
  for (i in seq_len(nrow(res))) {
    as_double <- edit_fold_predictions(as_double, i, function(p) {
      p$.row <- as.double(p$.row)
      p
    })
  }
  expect_type(as_double$.predictions[[1L]]$.row, "double")
  expect_identical(augment(as_double), augment(res))
})

test_that("on a censored-regression run, a fold missing a held-out row is refused", {
  skip_if_no_censored()
  d <- srv_data()
  set.seed(4)
  res <- suppressWarnings(memoised(nested_tune_grid(
    srv_workflow(d),
    srv_nested(d),
    grid = srv_grid(),
    metrics = srv_metrics(),
    eval_time = srv_eval_times(),
    control = tune::control_grid(save_pred = TRUE)
  )))
  expect_type(res$.predictions[[2L]]$.pred, "list")
  expect_predictions_refused(
    plant_row_mismatch(res, 2L, "missing"),
    res$id[[2L]]
  )
})

test_that("on a run with a failed fold, a mismatch is refused before the partial-run warning", {
  skip_if_no_engines()
  d <- make_reg_data()
  res <- augment_run(d, break_fold(det_nested(d), 2L, "inner tuning"))
  expect_identical(res$.completed, c(TRUE, FALSE, TRUE))
  planted <- plant_row_mismatch(res, 3L, "repeated")
  expect_no_warning(
    cnd <- expect_predictions_refused(planted, res$id[[3L]])
  )
  expect_no_match(conditionMessage(cnd), res$id[[1L]], fixed = TRUE)
})

test_that("a data column named like a prediction column is refused, not renamed", {
  skip_if_no_engines()
  d <- make_reg_data()
  res <- augment_run(d, det_nested(d))
  res$splits[[1L]]$data$.pred <- 1
  cnd <- rlang::catch_cnd(augment(res), "error")
  expect_s3_class(cnd, "nestedtune_collect_name_collision")
  expect_match(conditionMessage(cnd), ".pred", fixed = TRUE)
})
