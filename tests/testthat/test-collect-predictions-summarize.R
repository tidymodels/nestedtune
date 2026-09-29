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
# select two different candidates under them. The regression and
# probability tests assert this.
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
    for (l in lvls) {
      out[[paste0(".pred_", l)]] <- unname(probs[, l])
    }
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
        .pred_survival = vapply(
          times,
          function(t) {
            mean(mine$.pred_survival[mine$.eval_time == t], na.rm = TRUE)
          },
          numeric(1)
        ),
        .weight_censored = vapply(
          times,
          function(t) {
            mean(mine$.weight_censored[mine$.eval_time == t], na.rm = TRUE)
          },
          numeric(1)
        )
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
  expect_true(all(
    c("id", "id2", ".config") %in% names(collect_predictions(res))
  ))
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
# ignores missing values is exercised. The regression and probability runs'
# own predictions carry none.
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
  expect_false(is.na(avg$.pred[[which(avg$.row == target)]]$.pred_survival[[
    1L
  ]]))
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

# The folds holding `row` out, in fold order.
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
    as.character(avg_class(
      plant_row(res, row, ".pred_class", c("other", "other")),
      row
    )),
    "other"
  )
})

test_that("AC3: a missing vote counts as a class of its own, as tune counts it", {
  skip_if_no_engines()
  # Three votes on one row. A repeated design holds a row out once per
  # repeat, so the vote is put to the helper directly. tune 2.1.0's
  # `class_summarize()` returns NA for (NA, NA, "a"), read 2026-09-28.
  lv <- c("a", "b")
  vote <- function(v) {
    class_by_vote(factor(v, levels = lv), factor(rep(1L, length(v))))
  }
  expect_true(is.na(vote(c(NA, NA, "a"))))
  # A tie between a missing vote and a level goes to the level.
  expect_identical(as.character(vote(c(NA, "b"))), "b")
  expect_identical(as.character(vote(c("b", "b", NA))), "b")
  expect_identical(levels(vote(c(NA, "b"))), lv)
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

test_that("a row whose averaged probabilities are missing gets a missing class", {
  skip_if_no_engines()
  res <- prob_pair()$res
  row <- res$.predictions[[1L]]$.row[[1L]]
  planted <- plant_row(res, row, ".pred_event", c(NA, NA))
  avg <- collect_predictions(planted, summarize = TRUE)
  mine <- avg[avg$.row == row, ]
  expect_true(is.na(mine$.pred_event))
  expect_true(is.na(mine$.pred_class))
  # The other rows keep their class.
  expect_false(anyNA(avg$.pred_class[avg$.row != row]))
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

test_that("an ordered outcome gives an ordered class, whatever the saved class is", {
  skip_if_no_engines()
  res <- prob_pair()$res
  # tune's `prob_summarize()` reads orderedness from the outcome. Here the
  # outcome is ordered and the saved class is not.
  for (i in seq_len(nrow(res))) {
    res <- edit_fold_predictions(res, i, function(p) {
      p$y <- factor(as.character(p$y), levels = levels(p$y), ordered = TRUE)
      p$.pred_class <- factor(
        as.character(p$.pred_class),
        levels = levels(p$.pred_class)
      )
      p
    })
  }
  avg <- collect_predictions(res, summarize = TRUE)
  expect_true(is.ordered(avg$.pred_class))
  expect_identical(levels(avg$.pred_class), levels(avg$y))
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

# ---- AC5: a run with failed folds ------------------------------------------

# Fold 1 and the repeat-2 fold holding fold 1's first held-out row, both
# broken at the outer fit. The rows both held out were held out by failed
# folds only.
partial_design <- function() {
  d <- make_reg_data()
  folds <- repeated_pair(d, 46)$folds
  held_1 <- rsample::complement(folds$splits[[1L]])
  second <- which(vapply(
    4:6,
    function(i) {
      held_1[[1L]] %in% rsample::complement(folds$splits[[i]])
    },
    logical(1)
  )) +
    3L
  folds <- break_fold(folds, 1L, "outer fit")
  folds <- break_fold(folds, second, "outer fit")
  list(folds = folds, broken = c(1L, second), data = d)
}

partial_run <- function() {
  design <- partial_design()
  folds <- design$folds
  wf <- fixed_workflow(design$data)
  suppressWarnings(memoised(nested_fit_resamples(
    wf,
    folds,
    metrics = reg_metrics(),
    control = tune::control_resamples(save_pred = TRUE)
  )))
}

# Every warning `expr` raises, muffled, in order.
all_warnings <- function(expr) {
  warnings <- list()
  value <- withCallingHandlers(
    expr,
    warning = function(w) {
      warnings[[length(warnings) + 1L]] <<- w
      invokeRestart("muffleWarning")
    }
  )
  list(value = value, warnings = warnings)
}

test_that("AC5: failed folds are left out of the average, with one warning", {
  skip_if_no_engines()
  broken <- partial_design()$broken
  res <- partial_run()
  expect_identical(which(!res$.completed), broken)

  got <- all_warnings(collect_predictions(res, summarize = TRUE))
  expect_length(got$warnings, 1L)
  expect_s3_class(got$warnings[[1L]], "nestedtune_partial_summary")
  avg <- got$value

  held <- lapply(res$splits, rsample::complement)
  only_failed <- intersect(held[[broken[[1L]]]], held[[broken[[2L]]]])
  one_failed <- setdiff(held[[broken[[1L]]]], held[[broken[[2L]]]])
  expect_gt(length(only_failed), 0L)
  expect_gt(length(one_failed), 0L)

  # A row only failed folds held out is left out.
  expect_false(any(only_failed %in% avg$.row))
  # A row held out by one failed and one completed fold takes the completed
  # fold's prediction.
  r <- one_failed[[1L]]
  keeper <- setdiff(
    which(vapply(held, function(h) r %in% h, logical(1))),
    broken
  )
  expect_length(keeper, 1L)
  kept <- res$.predictions[[keeper]]
  expect_identical(avg$.pred[avg$.row == r], kept$.pred[kept$.row == r])
})

# ---- AC6: a workflow set ---------------------------------------------------

set_run <- function() {
  d <- make_reg_data()
  set.seed(47)
  wset <- wset_fixed(d)
  folds <- repeated_pair(d, 47)$folds
  ms <- reg_metrics()
  memoised(nested_workflow_map(
    object = wset,
    fn = "nested_fit_resamples",
    resamples = folds,
    metrics = ms,
    control = tune::control_resamples(save_pred = TRUE)
  ))
}

test_that("AC6: a set's average is each workflow's own, bound under wflow_id", {
  skip_if_no_wset_fixture("nested_fit_resamples")
  res <- set_run()
  expect_identical(res$wflow_id, c("fixed", "baseline"))
  tables <- lapply(res$result, collect_predictions, summarize = TRUE)
  names(tables) <- res$wflow_id
  expected <- dplyr::bind_rows(tables, .id = "wflow_id")
  got <- collect_predictions(res, summarize = TRUE)
  expect_equal(got, expected)
  expect_false(any(c("id", "id2", ".config") %in% names(got)))
  # The default is still the per-fold table.
  expect_true("id2" %in% names(collect_predictions(res)))
})

# ---- AC7: quantile predictions are refused ---------------------------------

test_that("AC7: summarize = TRUE refuses saved quantile predictions", {
  skip_if_no_engines()
  res <- reg_pair()$res
  # The refusal reads the column's name, so a plain column stands in for
  # hardhat's `quantile_pred` type, keeping hardhat out of Suggests.
  res <- edit_fold_predictions(res, 2L, function(p) {
    p$.pred_quantile <- p$.pred
    p
  })
  expect_error(
    collect_predictions(res, summarize = TRUE),
    class = "nestedtune_summarize_quantile"
  )
})

# ---- M126: the edge cases of the average -----------------------------------
#
# The tests below are labelled with M126's criteria, not M124's above.

# The message as one line, cli's wrapping and styling removed.
flat_message <- function(cnd) {
  gsub("\\s+", " ", cli::ansi_strip(conditionMessage(cnd)))
}

# ---- M126 AC1: saved rows must match the rows each fold held out ----------

for (case in row_mismatch_cases) {
  test_that(
    paste0(
      "M126 AC1: the `",
      case,
      "` mismatch is refused under summarize = TRUE, naming the fold"
    ),
    {
      skip_if_no_engines()
      res <- reg_pair()$res
      planted <- plant_row_mismatch(res, 2L, case)
      cnd <- rlang::catch_cnd(
        collect_predictions(planted, summarize = TRUE),
        "error"
      )
      expect_s3_class(cnd, "nestedtune_collect_predictions_predictions")
      expect_identical(
        conditionCall(cnd)[[1L]],
        as.name("collect_predictions")
      )
      labels <- fold_ids(res)
      expect_match(flat_message(cnd), labels[[2L]], fixed = TRUE)
      for (other in labels[-2L]) {
        expect_no_match(flat_message(cnd), other, fixed = TRUE)
      }
      # The message points to the per-fold table the check leaves alone.
      expect_match(flat_message(cnd), "summarize = FALSE", fixed = TRUE)
      # The per-fold table reads the same run without a condition.
      expect_no_condition(per_fold <- collect_predictions(planted))
      expect_s3_class(per_fold, "tbl_df")
    }
  )
}

test_that("M126 AC1: a mismatch in one workflow of a set is refused", {
  skip_if_no_wset_fixture("nested_fit_resamples")
  res <- set_run()
  res$result[[1L]] <- plant_row_mismatch(res$result[[1L]], 2L, "repeated")
  expect_error(
    collect_predictions(res, summarize = TRUE),
    class = "nestedtune_collect_predictions_predictions"
  )
  expect_no_condition(collect_predictions(res))
})

# ---- M126 AC2: shapes the average misreads are refused ---------------------

# Every fold's saved predictions edited by `edit()`.
edit_all_folds <- function(x, edit) {
  for (i in seq_len(nrow(x))) {
    x <- edit_fold_predictions(x, i, edit)
  }
  x
}

# Both readers that average refuse `x` with class
# `nestedtune_summarize_columns`, each under its own name. Every row of the
# fixtures' repeated designs is held out twice, so `augment()` averages.
expect_shape_refused <- function(x) {
  for (verb in c("collect_predictions", "augment")) {
    cnd <- rlang::catch_cnd(
      if (verb == "augment") {
        augment(x)
      } else {
        collect_predictions(x, summarize = TRUE)
      },
      "error"
    )
    expect_s3_class(cnd, "nestedtune_summarize_columns")
    expect_identical(conditionCall(cnd)[[1L]], as.name(verb), info = verb)
  }
}

test_that("M126 AC2: two factor outcome columns are refused", {
  skip_if_no_engines()
  res <- edit_all_folds(prob_pair()$res, function(p) {
    p$also <- p$y
    p
  })
  expect_shape_refused(res)
})

test_that("M126 AC2: a saved class beside no factor outcome column is refused", {
  skip_if_no_engines()
  res <- prob_pair()$res
  # The outcome removed, and the outcome kept as text.
  expect_shape_refused(edit_all_folds(res, function(p) p[names(p) != "y"]))
  expect_shape_refused(edit_all_folds(res, function(p) {
    p$y <- as.character(p$y)
    p
  }))
})

test_that("M126 AC2: a censored .pred entry without .eval_time is refused", {
  skip_if_no_engines()
  skip_if_no_censored()
  res <- edit_fold_predictions(srv_pair()$res, 1L, function(p) {
    p$.pred[[1L]] <- p$.pred[[1L]][names(p$.pred[[1L]]) != ".eval_time"]
    p
  })
  expect_shape_refused(res)
})

# ---- M126 AC3: NULL entries in a censored .pred ---------------------------

# One row's survival average by base R: per `.eval_time`, the mean of the
# row's non-NULL entries with missing values ignored.
hand_survival <- function(entries) {
  long <- do.call(
    rbind,
    lapply(Filter(Negate(is.null), entries), as.data.frame)
  )
  times <- unique(long$.eval_time)
  data.frame(
    .eval_time = times,
    .pred_survival = vapply(
      times,
      function(t) mean(long$.pred_survival[long$.eval_time == t], na.rm = TRUE),
      numeric(1)
    ),
    .weight_censored = vapply(
      times,
      function(t) {
        mean(long$.weight_censored[long$.eval_time == t], na.rm = TRUE)
      },
      numeric(1)
    )
  )
}

# The saved `.pred` entries of `row`, one per fold holding it, in fold order.
row_entries <- function(x, row) {
  lapply(holders(x, row), function(i) {
    p <- x$.predictions[[i]]
    p$.pred[[which(p$.row == row)]]
  })
}

test_that("M126 AC3: a NULL entry is left out of its row's average", {
  skip_if_no_engines()
  skip_if_no_censored()
  res <- srv_pair()$res
  row <- res$.predictions[[1L]]$.row[[1L]]
  expect_length(holders(res, row), 2L)
  kept <- row_entries(res, row)[[2L]]
  planted <- edit_fold_predictions(res, 1L, function(p) {
    p$.pred[p$.row == row] <- list(NULL)
    p
  })
  avg <- collect_predictions(planted, summarize = TRUE)
  expect_equal(
    as.data.frame(avg$.pred[[which(avg$.row == row)]]),
    hand_survival(list(NULL, kept))
  )
})

test_that("M126 AC3: a row whose every entry is NULL holds NULL", {
  skip_if_no_engines()
  skip_if_no_censored()
  res <- srv_pair()$res
  row <- res$.predictions[[1L]]$.row[[1L]]
  planted <- res
  for (i in holders(res, row)) {
    planted <- edit_fold_predictions(planted, i, function(p) {
      p$.pred[p$.row == row] <- list(NULL)
      p
    })
  }
  avg <- collect_predictions(planted, summarize = TRUE)
  expect_null(avg$.pred[[which(avg$.row == row)]])
  # The other rows keep their averages.
  others <- avg$.pred[avg$.row != row]
  expect_true(all(vapply(others, is.data.frame, logical(1))))
})

test_that("M126 AC3: a table whose every entry is NULL averages to NULL entries", {
  skip_if_no_engines()
  skip_if_no_censored()
  planted <- edit_all_folds(srv_pair()$res, function(p) {
    p$.pred <- vector("list", nrow(p))
    p
  })
  avg <- collect_predictions(planted, summarize = TRUE)
  expect_identical(avg$.row, held_out_rows(planted))
  expect_true(all(vapply(avg$.pred, is.null, logical(1))))
})

# ---- M126 AC5: paths the M124 and M125 reviews found untested --------------

test_that("M126 AC5: a set refuses saved quantile predictions in both readers", {
  skip_if_no_wset_fixture("nested_fit_resamples")
  res <- set_run()
  res$result[[1L]] <- edit_fold_predictions(res$result[[1L]], 2L, function(p) {
    p$.pred_quantile <- p$.pred
    p
  })
  expect_error(
    collect_predictions(res, summarize = TRUE),
    class = "nestedtune_summarize_quantile"
  )
  expect_error(augment(res), class = "nestedtune_summarize_quantile")
})

test_that("M126 AC5: a .pred_linear_pred column averages to its per-row mean", {
  skip_if_no_engines()
  res <- edit_all_folds(reg_pair()$res, function(p) {
    p$.pred_linear_pred <- 2 * p$.pred + p$.row
    p
  })
  res <- plant_missing(res, ".pred_linear_pred")
  p <- collect_predictions(res)
  avg <- collect_predictions(res, summarize = TRUE)
  hand <- tapply(p$.pred_linear_pred, p$.row, mean, na.rm = TRUE)
  expect_identical(avg$.row, as.integer(names(hand)))
  expect_equal(avg$.pred_linear_pred, as.vector(hand))
  expect_false(anyNA(avg$.pred_linear_pred))
})

test_that("M126 AC5: a probability tie with one missing probability goes to the first level", {
  skip_if_no_engines()
  res <- prob_pair()$res
  row <- res$.predictions[[1L]]$.row[[1L]]
  for (event in list(c(NA, 0.5), c(0.5, NA))) {
    planted <- plant_row(res, row, ".pred_event", event)
    planted <- plant_row(planted, row, ".pred_other", c(0.5, 0.5))
    planted <- plant_row(planted, row, ".pred_class", c("other", "other"))
    avg <- collect_predictions(planted, summarize = TRUE)
    mine <- avg[avg$.row == row, ]
    expect_identical(mine$.pred_event, 0.5)
    expect_identical(mine$.pred_other, 0.5)
    expect_identical(as.character(mine$.pred_class), "event")
  }
})

test_that("M126: a probability tie whose plain sums round apart goes to the first level", {
  skip_if_no_engines()
  res <- prob_pair()$res
  row <- res$.predictions[[1L]]$.row[[1L]]
  # Both true means are 0.2. In `double` arithmetic, 0.05 + 0.35 rounds
  # below 0.2 + 0.2, so an average without `mean()`'s second pass gives the
  # tie to "other". `mean()` and `sum()` are not the premise here: where
  # `long double` is wider than `double`, as on x86_64 Linux, they sum in it.
  event <- c(0.05, 0.35)
  other <- c(0.2, 0.2)
  expect_lt(event[[1L]] + event[[2L]], other[[1L]] + other[[2L]])
  planted <- plant_row(res, row, ".pred_event", event)
  planted <- plant_row(planted, row, ".pred_other", other)
  avg <- collect_predictions(planted, summarize = TRUE)
  mine <- avg[avg$.row == row, ]
  expect_identical(mine$.pred_event, mine$.pred_other)
  expect_identical(as.character(mine$.pred_class), "event")
})
