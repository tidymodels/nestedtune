# collect_predictions(summarize = TRUE) on a nested run (M124).
#
# Oracle provenance. AC1's oracle is tune itself:
# `tune::collect_predictions(summarize = TRUE)` on `tune::fit_resamples()`
# over the same outer splits. Every fold of a `nested_fit_resamples()` run
# fits the one workflow, so the two averages must agree. The engines are
# deterministic (lm, glm, survreg), because a stochastic engine's per-fold
# predictions differ between the two runs. AC2's oracle is `hand_average()`
# below, base R written from the rules the help page states and read off
# `collect_predictions(res)`, never off the method's output.

skip_heavy_on_cran()

# A logistic regression, deterministic, with one tunable recipe step so a
# grid run has candidates to disagree on.
logit_pca_workflow <- function(data) {
  rec <- recipes::step_pca(
    recipes::recipe(y ~ x1 + x2 + x3 + x4, data = data),
    recipes::all_predictors(),
    num_comp = tune::tune(),
    id = "pca_logit"
  )
  workflows::workflow(rec, parsnip::logistic_reg())
}

logit_workflow <- function() {
  workflows::workflow(y ~ x1 + x2 + x3 + x4, parsnip::logistic_reg())
}

srv_fixed_workflow <- function(data) {
  tune::finalize_workflow(srv_workflow(data), data.frame(dist = "weibull"))
}

# The repeated outer design and the rset `fit_resamples()` reads. Each is
# drawn under the same seed, the outer design first, so the splits are the
# same without being read off the nested object.
repeated_pair <- function(data, seed, stratify = FALSE) {
  set.seed(seed)
  if (stratify) {
    folds <- nested_resamples(
      data,
      outside = rsample::vfold_cv(v = 3, repeats = 2, strata = y),
      inside = rsample::vfold_cv(v = 3)
    )
    set.seed(seed)
    outer <- rsample::vfold_cv(data, v = 3, repeats = 2, strata = y)
  } else {
    folds <- nested_resamples(
      data,
      outside = rsample::vfold_cv(v = 3, repeats = 2),
      inside = rsample::vfold_cv(v = 3)
    )
    set.seed(seed)
    outer <- rsample::vfold_cv(data, v = 3, repeats = 2)
  }
  list(folds = folds, outer = outer)
}

# One fixed-workflow run and its fit_resamples() twin, both saving
# predictions under the same metric set and `eval_time`.
fixed_pair <- function(
  wf,
  data,
  seed,
  metrics,
  eval_time = NULL,
  stratify = FALSE
) {
  pair <- repeated_pair(data, seed, stratify = stratify)
  folds <- pair$folds
  res <- memoised(nested_fit_resamples(
    wf,
    folds,
    metrics = metrics,
    eval_time = eval_time,
    control = tune::control_resamples(save_pred = TRUE)
  ))
  plain <- tune::fit_resamples(
    wf,
    resamples = pair$outer,
    metrics = metrics,
    eval_time = eval_time,
    control = tune::control_resamples(save_pred = TRUE, allow_par = FALSE)
  )
  list(res = res, plain = plain)
}

reg_pair <- function() {
  d <- make_reg_data()
  fixed_pair(fixed_workflow(d), d, 41, metrics = reg_metrics())
}

prob_pair <- function() {
  d <- cls_data()
  fixed_pair(logit_workflow(), d, 42, metrics = cls_metrics(), stratify = TRUE)
}

class_pair <- function() {
  d <- cls_data()
  fixed_pair(
    logit_workflow(),
    d,
    43,
    metrics = yardstick::metric_set(yardstick::accuracy),
    stratify = TRUE
  )
}

srv_pair <- function() {
  d <- srv_data()
  fixed_pair(
    srv_fixed_workflow(d),
    d,
    44,
    metrics = srv_set_metrics(),
    eval_time = srv_eval_times()
  )
}

# The grid runs AC2 reads. Seeds 21 and 25 were picked because the repeats
# select two different candidates under them, which each test asserts.
grid_reg_run <- function() {
  d <- make_reg_data()
  set.seed(21)
  folds <- nested_resamples(
    d,
    outside = rsample::vfold_cv(v = 3, repeats = 2),
    inside = rsample::vfold_cv(v = 3)
  )
  memoised(nested_tune_grid(
    det_workflow(d),
    folds,
    grid = det_grid(),
    metrics = reg_metrics(),
    control = tune::control_grid(save_pred = TRUE)
  ))
}

grid_prob_run <- function() {
  d <- cls_data()
  set.seed(25)
  folds <- nested_resamples(
    d,
    outside = rsample::vfold_cv(v = 3, repeats = 2, strata = y),
    inside = rsample::vfold_cv(v = 3, strata = y)
  )
  memoised(nested_tune_grid(
    logit_pca_workflow(d),
    folds,
    grid = data.frame(num_comp = 1:4),
    metrics = cls_metrics(),
    control = tune::control_grid(save_pred = TRUE)
  ))
}

grid_srv_run <- function() {
  d <- srv_data()
  set.seed(21)
  folds <- nested_resamples(
    d,
    outside = rsample::vfold_cv(v = 3, repeats = 2),
    inside = rsample::vfold_cv(v = 3)
  )
  suppressWarnings(memoised(nested_tune_grid(
    srv_workflow(d),
    folds,
    grid = srv_grid(),
    metrics = srv_set_metrics(),
    eval_time = srv_eval_times(),
    control = tune::control_grid(save_pred = TRUE)
  )))
}

mc_run <- function() {
  d <- make_reg_data()
  set.seed(45)
  folds <- nested_resamples(
    d,
    outside = rsample::mc_cv(prop = 0.75, times = 4),
    inside = rsample::vfold_cv(v = 3)
  )
  memoised(nested_fit_resamples(
    fixed_workflow(d),
    folds,
    metrics = reg_metrics(),
    control = tune::control_resamples(save_pred = TRUE)
  ))
}

by_row <- function(x) x[order(x$.row), ]

# The AC2 rules, written from the help page in base R over the stacked
# per-fold predictions. One entry per `.row`, in `.row` order.
hand_average <- function(p, outcome) {
  rows <- sort(unique(p$.row))
  f <- factor(p$.row, levels = rows)
  per_row <- function(v, fn) as.vector(tapply(v, f, fn))
  out <- list(.row = rows, outcome = p[[outcome]][match(rows, p$.row)])
  if (is.numeric(p[[".pred"]])) {
    out$.pred <- per_row(p$.pred, function(v) mean(v, na.rm = TRUE))
  }
  if (is.factor(p[[outcome]]) && ".pred_class" %in% names(p)) {
    lvls <- levels(p[[outcome]])
    probs <- sapply(lvls, function(l) {
      per_row(p[[paste0(".pred_", l)]], function(v) mean(v, na.rm = TRUE))
    })
    probs <- probs / rowSums(probs)
    for (l in lvls) out[[paste0(".pred_", l)]] <- unname(probs[, l])
    first_max <- apply(probs, 1, function(r) which(r == max(r))[[1L]])
    out$.pred_class <- factor(lvls[first_max], levels = lvls)
  }
  if (".pred_time" %in% names(p)) {
    out$.pred_time <- per_row(p$.pred_time, stats::median)
  }
  if (is.list(p[[".pred"]])) {
    long <- do.call(
      rbind,
      Map(function(tbl, r) cbind(.row = r, as.data.frame(tbl)), p$.pred, p$.row)
    )
    out$.pred <- lapply(rows, function(r) {
      mine <- long[long$.row == r, ]
      times <- unique(mine$.eval_time)
      data.frame(
        .eval_time = times,
        .pred_survival = vapply(times, function(t) {
          mean(mine$.pred_survival[mine$.eval_time == t], na.rm = TRUE)
        }, numeric(1)),
        .weight_censored = vapply(times, function(t) {
          mean(mine$.weight_censored[mine$.eval_time == t], na.rm = TRUE)
        }, numeric(1))
      )
    })
  }
  out
}

expect_matches_hand <- function(avg, hand, outcome) {
  expect_identical(avg$.row, hand$.row)
  expect_equal(avg[[outcome]], hand$outcome)
  for (nm in setdiff(names(hand), c(".row", "outcome", ".pred"))) {
    expect_equal(avg[[nm]], hand[[nm]], info = nm)
  }
  if (is.list(hand$.pred)) {
    expect_identical(length(avg$.pred), length(hand$.pred))
    for (i in seq_along(hand$.pred)) {
      expect_equal(as.data.frame(avg$.pred[[i]]), hand$.pred[[i]])
    }
  } else if (!is.null(hand$.pred)) {
    expect_equal(avg$.pred, hand$.pred)
  }
}

# ---- AC1: equal to tune's own average on the same outer splits -------------

expect_matches_tune <- function(pair) {
  avg <- by_row(collect_predictions(pair$res, summarize = TRUE))
  ref <- by_row(tune::collect_predictions(pair$plain, summarize = TRUE))
  # Every row of the design is held out once per repeat, so both tables
  # cover every data row.
  expect_identical(nrow(avg), nrow(ref))
  expect_equal(avg, ref[names(avg)])
  # The prediction columns tune averaged are all present, by name.
  pred_cols <- grep("^\\.pred", names(ref), value = TRUE)
  expect_true(all(pred_cols %in% names(avg)))
}

test_that("AC1: summarize defaults to FALSE, the per-fold table", {
  skip_if_no_engines()
  res <- reg_pair()$res
  expect_identical(
    collect_predictions(res),
    collect_predictions(res, summarize = FALSE)
  )
  expect_true(all(c("id", "id2", ".config") %in% names(collect_predictions(res))))
})

test_that("AC1: a regression average equals tune's on the same outer splits", {
  skip_if_no_engines()
  expect_matches_tune(reg_pair())
})

test_that("AC1: a probability classification average equals tune's", {
  skip_if_no_engines()
  pair <- prob_pair()
  expect_true(all(
    c(".pred_class", ".pred_event", ".pred_other") %in%
      names(collect_predictions(pair$res))
  ))
  expect_matches_tune(pair)
})

test_that("AC1: a class-only classification average equals tune's", {
  skip_if_no_engines()
  pair <- class_pair()
  expect_false(".pred_event" %in% names(collect_predictions(pair$res)))
  expect_matches_tune(pair)
})

test_that("AC1: a censored regression average equals tune's", {
  skip_if_no_engines()
  skip_if_no_censored()
  pair <- srv_pair()
  expect_true(all(
    c(".pred", ".pred_time") %in% names(collect_predictions(pair$res))
  ))
  expect_matches_tune(pair)
})

# ---- AC2: across the candidates the folds selected ------------------------

# One missing value planted in fold 1's first saved row, so the rule that
# ignores missing values is exercised. A run's own predictions carry none.
plant_missing <- function(x, column) {
  edit_fold_predictions(x, 1L, function(p) {
    if (is.list(p[[column]])) {
      p[[column]][[1L]]$.pred_survival[[1L]] <- NA
      p[[column]][[1L]]$.weight_censored[[1L]] <- NA
    } else {
      p[[column]][[1L]] <- NA
    }
    p
  })
}

test_that("AC2: a regression average spans the candidates the repeats selected", {
  skip_if_no_engines()
  res <- grid_reg_run()
  expect_gte(length(unique(collect_selections(res)$num_comp)), 2L)
  res <- plant_missing(res, ".pred")
  avg <- collect_predictions(res, summarize = TRUE)
  expect_false(anyNA(avg$.pred))
  expect_matches_hand(avg, hand_average(collect_predictions(res), "y"), "y")
})

test_that("AC2: a probability average is renormalized and names its class", {
  skip_if_no_engines()
  res <- grid_prob_run()
  expect_gte(length(unique(collect_selections(res)$num_comp)), 2L)
  res <- plant_missing(res, ".pred_event")
  avg <- collect_predictions(res, summarize = TRUE)
  expect_false(anyNA(avg$.pred_event))
  expect_matches_hand(avg, hand_average(collect_predictions(res), "y"), "y")
})

test_that("AC2: a censored average takes the median time and the mean survival", {
  skip_if_no_engines()
  skip_if_no_censored()
  res <- grid_srv_run()
  target <- res$.predictions[[1L]]$.row[[1L]]
  res <- plant_missing(res, ".pred")
  p <- collect_predictions(res)
  outcome <- "survival::Surv(time, event)"
  avg <- collect_predictions(res, summarize = TRUE)
  # The planted row's first survival probability comes from its other fold.
  # `.weight_censored` is missing in some rows of the run itself, so only
  # `.pred_survival` is asserted here.
  expect_false(is.na(avg$.pred[[which(avg$.row == target)]]$.pred_survival[[1L]]))
  expect_matches_hand(avg, hand_average(p, outcome), outcome)
})

test_that("AC2: a missing .pred_time makes the row's median missing", {
  skip_if_no_engines()
  skip_if_no_censored()
  res <- grid_srv_run()
  target <- res$.predictions[[1L]]$.row[[1L]]
  res <- edit_fold_predictions(res, 1L, function(p) {
    p$.pred_time[[1L]] <- NA
    p
  })
  avg <- collect_predictions(res, summarize = TRUE)
  expect_true(is.na(avg$.pred_time[avg$.row == target]))
  # The other rows keep a median.
  expect_false(anyNA(avg$.pred_time[avg$.row != target]))
})

# ---- AC3: ties go to the first level ---------------------------------------

# The folds holding `row` out, in fold order, and each one's position of it.
holders <- function(x, row) {
  which(vapply(x$.predictions, function(p) row %in% p$.row, logical(1)))
}

plant_row <- function(x, row, column, values) {
  folds <- holders(x, row)
  stopifnot(length(folds) == length(values))
  for (k in seq_along(folds)) {
    x <- edit_fold_predictions(x, folds[[k]], function(p) {
      p[[column]][p$.row == row] <- values[[k]]
      p
    })
  }
  x
}

relevel_class <- function(x, levels) {
  for (i in seq_len(nrow(x))) {
    x <- edit_fold_predictions(x, i, function(p) {
      p$.pred_class <- factor(as.character(p$.pred_class), levels = levels)
      p
    })
  }
  x
}

avg_class <- function(x, row) {
  avg <- collect_predictions(x, summarize = TRUE)
  avg$.pred_class[avg$.row == row]
}

test_that("AC3: a two-class vote tie goes to the first level, in either order", {
  skip_if_no_engines()
  res <- class_pair()$res
  row <- res$.predictions[[1L]]$.row[[1L]]
  expect_length(holders(res, row), 2L)
  lv <- levels(res$.predictions[[1L]]$.pred_class)
  expect_identical(lv, c("event", "other"))

  for (votes in list(c("event", "other"), c("other", "event"))) {
    planted <- plant_row(res, row, ".pred_class", votes)
    got <- avg_class(planted, row)
    expect_identical(as.character(got), "event")
    expect_identical(levels(got), lv)
  }
  # A clear majority is not a tie: both folds say "other".
  expect_identical(
    as.character(avg_class(plant_row(res, row, ".pred_class", c("other", "other")), row)),
    "other"
  )
})

test_that("AC3: a tie that excludes the first level goes to the earlier tied level", {
  skip_if_no_engines()
  res <- relevel_class(class_pair()$res, c("event", "other", "third"))
  row <- res$.predictions[[1L]]$.row[[1L]]
  for (votes in list(c("third", "other"), c("other", "third"))) {
    planted <- plant_row(res, row, ".pred_class", votes)
    expect_identical(as.character(avg_class(planted, row)), "other")
  }
})

test_that("AC3: a tie between averaged probabilities goes to the first level", {
  skip_if_no_engines()
  res <- prob_pair()$res
  row <- res$.predictions[[1L]]$.row[[1L]]
  for (event in list(c(0.75, 0.25), c(0.25, 0.75))) {
    planted <- plant_row(res, row, ".pred_event", event)
    planted <- plant_row(planted, row, ".pred_other", 1 - event)
    # The saved class says "other" in both folds; the average recomputes it.
    planted <- plant_row(planted, row, ".pred_class", c("other", "other"))
    avg <- collect_predictions(planted, summarize = TRUE)
    mine <- avg[avg$.row == row, ]
    expect_identical(mine$.pred_event, 0.5)
    expect_identical(mine$.pred_other, 0.5)
    expect_identical(as.character(mine$.pred_class), "event")
  }
})

# ---- AC4: the table's rows and columns ------------------------------------

held_out_rows <- function(x) {
  sort(unique(unlist(lapply(x$splits[x$.completed], rsample::complement))))
}

expect_averaged_shape <- function(x, labels) {
  per_fold <- collect_predictions(x)
  avg <- collect_predictions(x, summarize = TRUE)
  expect_identical(
    names(avg),
    setdiff(names(per_fold), c(labels, ".config"))
  )
  expect_identical(avg$.row, held_out_rows(x))
  expect_s3_class(avg, "tbl_df")
}

test_that("AC4: one row per held-out row, the labels and .config dropped", {
  skip_if_no_engines()
  res <- grid_reg_run()
  expect_gte(length(unique(collect_selections(res)$num_comp)), 2L)
  expect_averaged_shape(res, c("id", "id2"))
})

test_that("AC4: a Monte Carlo run averages over the union of assessment rows", {
  skip_if_no_engines()
  res <- mc_run()
  # Some row must be held out more than once and some never, or the union
  # is not what is being tested.
  counts <- table(unlist(lapply(res$splits, rsample::complement)))
  expect_true(any(counts > 1L))
  expect_lt(length(held_out_rows(res)), nrow(res$splits[[1L]]$data))
  expect_averaged_shape(res, "id")
})
