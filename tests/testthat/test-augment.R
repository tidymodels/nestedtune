# augment() on a nested run (M92).
#
# Oracle provenance. The expected table is built from the data and from
# `collect_predictions()` by matching `.row`, never from the method: each data
# row's prediction columns are that row's entry in the stacked predictions,
# and the data columns are the data as the design holds it.

skip_heavy_on_cran()

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

test_that("AC2: a Monte Carlo design that leaves rows out of every assessment set is refused, naming the first five", {
  skip_if_no_engines()
  d <- make_reg_data()
  set.seed(35)
  monte_carlo <- nested_resamples(
    d,
    outside = rsample::mc_cv(prop = 0.75, times = 3),
    inside = rsample::vfold_cv(v = 3)
  )
  res <- augment_run(d, monte_carlo)
  never <- never_held_rows(res)
  expect_gt(length(never), 5L)
  # The design also holds some rows out more than once: the refusal is for
  # the rows left out, not for the repeats.
  counts <- tabulate(
    unlist(lapply(res$splits, rsample::complement)),
    nbins = nrow(d)
  )
  expect_true(any(counts > 1L))
  msg <- expect_names_never_held(res, never)
  expect_no_match(msg, "Monte Carlo", fixed = TRUE)
  expect_no_match(msg, "time-series", fixed = TRUE)
})

test_that("AC2: a design leaving five or fewer rows out names all of them", {
  skip_if_no_engines()
  d <- make_reg_data()
  res <- augment_run(d, det_nested(d))
  # Moving two of fold 1's held-out rows into its analysis set leaves them
  # out of every assessment set.
  moved <- rsample::complement(res$splits[[1L]])[1:2]
  res$splits[[1L]]$in_id <- sort(c(res$splits[[1L]]$in_id, moved))
  expect_identical(never_held_rows(res), sort(moved))
  expect_names_never_held(res, sort(moved))
  # And one row, named in the singular.
  res$splits[[1L]]$in_id <- setdiff(res$splits[[1L]]$in_id, moved[[2L]])
  expect_identical(never_held_rows(res), moved[[1L]])
  expect_names_never_held(res, moved[[1L]])
})

# ---- M125: designs that hold a row out more than once ----------------------
#
# Oracle: `collect_predictions(summarize = TRUE)`, whose averages M124 checked
# against tune's own and against a base R one. Each data row's prediction
# columns must be that row's entry in the averaged table.

# Each data row's count of outer assessment sets holding it.
hold_counts <- function(x) {
  tabulate(
    unlist(lapply(x$splits, rsample::complement)),
    nbins = nrow(x$splits[[1L]]$data)
  )
}

expect_averaged_augment <- function(x, outcome = "y") {
  counts <- hold_counts(x)
  # The precondition AC1 names: every row held out, some more than once.
  expect_true(all(counts >= 1L))
  expect_true(any(counts > 1L))
  aug <- augment(x)
  data <- x$splits[[1L]]$data
  avg <- suppressWarnings(collect_predictions(x, summarize = TRUE))
  pred_cols <- grep("^\\.pred", names(avg), value = TRUE)
  at <- match(seq_len(nrow(data)), avg$.row)
  expect_identical(nrow(aug), nrow(data))
  expect_identical(
    names(aug),
    c(intersect(outcome, names(data)), pred_cols, setdiff(names(data), outcome))
  )
  for (nm in pred_cols) {
    expect_identical(aug[[nm]], avg[[nm]][at], info = nm)
  }
  for (nm in names(data)) {
    expect_identical(aug[[nm]], data[[nm]], info = nm)
  }
  invisible(aug)
}

repeated_folds <- function(data, seed, stratify = FALSE) {
  set.seed(seed)
  if (stratify) {
    return(nested_resamples(
      data,
      outside = rsample::vfold_cv(v = 3, repeats = 2, strata = y),
      inside = rsample::vfold_cv(v = 3, strata = y)
    ))
  }
  nested_resamples(
    data,
    outside = rsample::vfold_cv(v = 3, repeats = 2),
    inside = rsample::vfold_cv(v = 3)
  )
}

test_that("AC1: on a repeated v-fold regression, each row joins its averaged prediction", {
  skip_if_no_engines()
  d <- make_reg_data()
  res <- augment_run(d, repeated_folds(d, 34))
  aug <- expect_averaged_augment(res)
  expect_false(anyNA(aug$.pred))
})

test_that("AC1: on a repeated v-fold probability classification, each row joins its averaged probabilities and class", {
  skip_if_no_engines(stochastic = TRUE)
  d <- cls_data()
  res <- memoised(nested_tune_grid(
    cls_workflow(d),
    repeated_folds(d, 36, stratify = TRUE),
    grid = cls_grid(),
    metrics = cls_metrics(),
    event_level = "second",
    control = tune::control_grid(save_pred = TRUE)
  ))
  aug <- expect_averaged_augment(res)
  expect_identical(
    names(aug)[1:4],
    c("y", ".pred_class", ".pred_event", ".pred_other")
  )
  expect_identical(levels(aug$.pred_class), levels(d$y))
  expect_equal(aug$.pred_event + aug$.pred_other, rep(1, nrow(d)))
})

test_that("AC1: on a repeated v-fold censored regression, each row joins its averaged survival and time", {
  skip_if_no_censored()
  d <- srv_data()
  res <- suppressWarnings(memoised(nested_tune_grid(
    srv_workflow(d),
    repeated_folds(d, 37),
    grid = srv_grid(),
    # Concordance reads `.pred_time`, so both averaged columns are saved.
    metrics = srv_set_metrics(),
    eval_time = srv_eval_times(),
    control = tune::control_grid(save_pred = TRUE)
  )))
  aug <- expect_averaged_augment(res, outcome = character(0))
  expect_type(aug$.pred, "list")
  expect_true(".pred_time" %in% names(aug))
})

test_that("AC1: on a Monte Carlo design that holds every row out, each row joins its averaged prediction", {
  skip_if_no_engines()
  d <- make_reg_data()
  set.seed(38)
  folds <- nested_resamples(
    d,
    outside = rsample::mc_cv(prop = 0.5, times = 12),
    inside = rsample::vfold_cv(v = 3)
  )
  res <- memoised(nested_fit_resamples(
    fixed_workflow(d),
    folds,
    metrics = reg_metrics(),
    control = tune::control_resamples(save_pred = TRUE)
  ))
  # The design holds every row out, which a Monte Carlo draw need not do.
  expect_length(never_held_rows(res), 0L)
  aug <- expect_averaged_augment(res)
  expect_false(anyNA(aug$.pred))
})

test_that("AC3: a row that only failed folds held out holds NA, with one nestedtune_partial_summary warning", {
  skip_if_no_engines()
  d <- make_reg_data()
  folds <- repeated_folds(d, 39)
  # Fold 1 of repeat 1, and the repeat-2 fold holding fold 1's first row.
  # The rows both hold out are held out by failed folds only.
  held_1 <- rsample::complement(folds$splits[[1L]])
  second <- 3L +
    which(vapply(
      4:6,
      function(i) held_1[[1L]] %in% rsample::complement(folds$splits[[i]]),
      logical(1)
    ))
  folds <- break_fold(folds, 1L, "inner tuning")
  folds <- break_fold(folds, second, "inner tuning")
  res <- augment_run(d, folds)
  expect_identical(which(!res$.completed), c(1L, second))

  warnings <- list()
  aug <- withCallingHandlers(
    augment(res),
    warning = function(w) {
      warnings[[length(warnings) + 1L]] <<- w
      invokeRestart("muffleWarning")
    }
  )
  expect_length(warnings, 1L)
  expect_s3_class(warnings[[1L]], "nestedtune_partial_summary")

  held <- lapply(res$splits, rsample::complement)
  only_failed <- setdiff(
    seq_len(nrow(d)),
    unlist(held[res$.completed])
  )
  expect_setequal(only_failed, intersect(held_1, held[[second]]))
  expect_gt(length(only_failed), 0L)
  pred_cols <- grep("^\\.pred", names(aug), value = TRUE)
  for (nm in pred_cols) {
    expect_identical(which(is.na(aug[[nm]])), sort(only_failed), info = nm)
  }
  # Every other row joins its average over the completed folds.
  avg <- suppressWarnings(collect_predictions(res, summarize = TRUE))
  kept <- setdiff(seq_len(nrow(d)), only_failed)
  expect_identical(aug$.pred[kept], avg$.pred[match(kept, avg$.row)])
})

test_that("quantile predictions on a design holding a row out twice are refused with nestedtune_summarize_quantile", {
  skip_if_no_engines()
  d <- make_reg_data()
  res <- augment_run(d, repeated_folds(d, 34))
  # The refusal reads the column's name, so a plain column stands in for
  # hardhat's `quantile_pred` type, as in the collect_predictions() test.
  planted <- edit_fold_predictions(res, 2L, function(p) {
    p$.pred_quantile <- p$.pred
    p
  })
  cnd <- rlang::catch_cnd(augment(planted), "error")
  expect_s3_class(cnd, "nestedtune_summarize_quantile")
  expect_identical(conditionCall(cnd)[[1L]], as.name("augment"))
  # The augment() wording, not collect_predictions()'s.
  msg <- gsub("\\s+", " ", cli::ansi_strip(conditionMessage(cnd)))
  expect_match(
    msg,
    "The outer design holds some data rows out more than once",
    fixed = TRUE
  )

  # A design holding each row out once joins such a column as saved.
  once <- augment_run(d, det_nested(d))
  for (i in seq_len(nrow(once))) {
    once <- edit_fold_predictions(once, i, function(p) {
      p$.pred_quantile <- p$.pred
      p
    })
  }
  aug <- augment(once)
  expect_identical(aug$.pred_quantile, aug$.pred)
})

# A saved class that disagrees with the saved probabilities, as a
# postprocessor's threshold can leave it: each fold's `.pred_class` is set
# to the class other than the larger-probability one. A tie goes to the
# first level, "event", as in `class_from_probs()`.
plant_minority_class <- function(x) {
  for (i in which(x$.completed)) {
    x <- edit_fold_predictions(x, i, function(p) {
      p$.pred_class <- factor(
        ifelse(p$.pred_event >= p$.pred_other, "other", "event"),
        levels = levels(p$.pred_class)
      )
      p
    })
  }
  x
}

test_that("on a design holding each row out once, a saved class that disagrees with the probabilities is joined as saved", {
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
  expect_identical(levels(d$y), c("event", "other"))
  planted <- plant_minority_class(res)
  aug <- augment(planted)
  saved <- collect_predictions(planted)
  expect_identical(
    aug$.pred_class,
    saved$.pred_class[match(seq_len(nrow(d)), saved$.row)]
  )
  # The control: the planted class is not the larger-probability class, so
  # averaging or recomputing it would change the column.
  argmax <- ifelse(aug$.pred_event >= aug$.pred_other, "event", "other")
  expect_true(any(as.character(aug$.pred_class) != argmax))
})

test_that("on a design holding a row out more than once, a saved class is recomputed from the averaged probabilities", {
  skip_if_no_engines(stochastic = TRUE)
  d <- cls_data()
  res <- memoised(nested_tune_grid(
    cls_workflow(d),
    repeated_folds(d, 36, stratify = TRUE),
    grid = cls_grid(),
    metrics = cls_metrics(),
    event_level = "second",
    control = tune::control_grid(save_pred = TRUE)
  ))
  expect_identical(levels(d$y), c("event", "other"))
  aug <- augment(plant_minority_class(res))
  # The class with the larger averaged probability, whatever was saved. The
  # design has rows whose averaged probabilities tie at 0.5.
  argmax <- ifelse(aug$.pred_event >= aug$.pred_other, "event", "other")
  expect_identical(as.character(aug$.pred_class), argmax)
  expect_identical(aug, augment(res))
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

# ---- M126: the name collision before the averaging refusals ----------------

test_that("M126 AC4: on a repeated design, a name collision is refused before the quantile refusal", {
  skip_if_no_engines()
  d <- make_reg_data()
  res <- augment_run(d, repeated_folds(d, 34))
  planted <- edit_fold_predictions(res, 2L, function(p) {
    p$.pred_quantile <- p$.pred
    p
  })
  planted$splits[[1L]]$data$.pred <- 1
  expect_error(augment(planted), class = "nestedtune_collect_name_collision")
})

test_that("M126 AC4: on a repeated design, a name collision is refused before a shape the average misreads", {
  skip_if_no_engines()
  d <- make_reg_data()
  res <- augment_run(d, repeated_folds(d, 34))
  # A saved class beside a numeric outcome, which the average refuses.
  planted <- res
  for (i in seq_len(nrow(res))) {
    planted <- edit_fold_predictions(planted, i, function(p) {
      p$.pred_class <- factor(
        ifelse(p$.pred > 0, "a", "b"),
        levels = c("a", "b")
      )
      p
    })
  }
  expect_error(augment(planted), class = "nestedtune_summarize_columns")
  planted$splits[[1L]]$data$.pred <- 1
  expect_error(augment(planted), class = "nestedtune_collect_name_collision")
})

# ---- M126 AC5: the censored NULL row on the averaged path ------------------

test_that("M126 AC5: on a repeated censored design, a row only failed folds held out holds NULL in .pred", {
  skip_if_no_censored()
  d <- srv_data()
  folds <- repeated_folds(d, 37)
  held_1 <- rsample::complement(folds$splits[[1L]])
  second <- 3L +
    which(vapply(
      4:6,
      function(i) held_1[[1L]] %in% rsample::complement(folds$splits[[i]]),
      logical(1)
    ))
  folds <- break_fold(folds, 1L, "inner tuning")
  folds <- break_fold(folds, second, "inner tuning")
  res <- suppressWarnings(memoised(nested_tune_grid(
    srv_workflow(d),
    folds,
    grid = srv_grid(),
    metrics = srv_set_metrics(),
    eval_time = srv_eval_times(),
    control = tune::control_grid(save_pred = TRUE)
  )))
  expect_identical(which(!res$.completed), c(1L, second))
  expect_true(any(hold_counts(res) > 1L))

  expect_warning(aug <- augment(res), class = "nestedtune_partial_summary")
  only_failed <- intersect(held_1, rsample::complement(res$splits[[second]]))
  expect_gt(length(only_failed), 0L)
  is_null <- vapply(aug$.pred, is.null, logical(1))
  expect_identical(which(is_null), sort(only_failed))
  expect_true(all(is.na(aug$.pred_time[only_failed])))
})
