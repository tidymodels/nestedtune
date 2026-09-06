# Oracle records for nested_fit_resamples() (M70; DESIGN Conventions: oracles
# are recorded in the test file that asserts them).
#
# O1 -- type "live" (reference implementation). Source: tune::fit_resamples()
#   itself, run at test time on the same outer `vfold_cv()` splits the nested
#   design was built from, under the same seed, so the outer rows are the
#   same rows without being read off the nested object. With nothing to tune
#   the nested loop is ordinary resampling on the outer folds, and every
#   fold's `.estimate` must be identical to fit_resamples()'s per-fold row.
#   Pinned by "every fold's metrics are identical to fit_resamples() on the
#   same outer splits". Deterministic engine only (RR01 B2): matching tune's
#   own resampling with a stochastic engine would need its substream
#   derivation, and ranger is pinned by seed identity in
#   test-nested-fit-resamples-rng.R instead.
#
# O2 -- type "analytic by-hand" (independent computation). Source: the fold
#   done by hand with no tune call at all -- `fit()` on the split's analysis
#   set, `predict()` on its assessment set, and the metric set applied to the
#   two columns -- so a value that fit_resamples() and the loop both got wrong
#   the same way would still fail here. Pinned by "every fold's metrics are
#   identical to a by-hand fit, predict and score".
#
# O1 and O2 are the >=2 independent oracle types GP2 requires for the
# estimate this orchestrator reports (AC1).
#
# The rest of the file pins the record's shape (AC2): the same columns the
# five tuning orchestrators write, an empty selection on every completed
# fold, an inner table with tune's summary columns and no rows, the two seeds
# drawn by the documented contract and shared with a tuned run under the same
# session seed, the two optional columns present exactly when asked for, and
# a failing fold recorded as such.

test_that("AC1: every fold's metrics are identical to fit_resamples() on the same outer splits", {
  skip_if_no_engines()

  d <- make_reg_data()
  wf <- fixed_workflow(d)
  ms <- reg_metrics()

  set.seed(13)
  folds <- nested_resamples(
    d,
    outside = rsample::vfold_cv(v = 3),
    inside = rsample::vfold_cv(v = 3)
  )
  # The same call under the same seed nested_resamples() makes internally, so
  # the outer splits are identical without reading them off the nested object.
  set.seed(13)
  outer <- rsample::vfold_cv(d, v = 3)

  set.seed(30)
  res <- nested_fit_resamples(wf, folds, metrics = ms)

  plain <- tune::fit_resamples(
    wf,
    resamples = outer,
    metrics = ms,
    control = tune::control_resamples(allow_par = FALSE)
  )
  plain_metrics <- tune::collect_metrics(plain, summarize = FALSE)

  expect_identical(res$id, outer$id)
  expect_true(all(res$.completed))
  for (i in seq_len(nrow(res))) {
    fold_ref <- plain_metrics[plain_metrics$id == outer$id[[i]], ]
    fold_res <- res$.metrics[[i]]
    # Both metrics, by name, so a fold that scored one and not the other
    # cannot pass on the one it scored.
    expect_setequal(fold_res$.metric, c("rmse", "rsq"))
    for (m in fold_ref$.metric) {
      expect_identical(
        fold_res$.estimate[fold_res$.metric == m],
        fold_ref$.estimate[fold_ref$.metric == m]
      )
    }
  }
})

test_that("AC1: every fold's metrics are identical to a by-hand fit, predict and score", {
  skip_if_no_engines()

  d <- make_reg_data()
  wf <- fixed_workflow(d)
  ms <- reg_metrics()
  folds <- det_nested(d)

  set.seed(30)
  res <- nested_fit_resamples(wf, folds, metrics = ms)

  for (i in seq_len(nrow(res))) {
    split <- folds$splits[[i]]
    fitted <- parsnip::fit(wf, data = rsample::analysis(split))
    held <- rsample::assessment(split)
    scored <- data.frame(
      truth = held$y,
      estimate = predict(fitted, new_data = held)$.pred
    )
    by_hand <- ms(scored, truth = truth, estimate = estimate)
    fold_res <- res$.metrics[[i]]
    for (m in by_hand$.metric) {
      expect_identical(
        fold_res$.estimate[fold_res$.metric == m],
        by_hand$.estimate[by_hand$.metric == m]
      )
    }
  }
})

test_that("AC2: the record has the five orchestrators' columns, with nothing selected and no inner rows", {
  skip_if_no_engines()

  d <- make_reg_data()
  folds <- det_nested(d)
  ms <- reg_metrics()

  res <- fit_resamples_results(d)
  # The column set of a tuned run on the same design, read off a grid run
  # rather than restated here, so the two cannot drift apart.
  set.seed(2)
  tuned <- memoised(nested_tune_grid(
    det_workflow(d),
    folds,
    grid = det_grid(),
    metrics = ms
  ))
  expect_identical(names(res), names(tuned))
  expect_identical(
    names(res)[record_columns(res)],
    names(tuned)[record_columns(tuned)]
  )
  expect_s3_class(res, "nested_results")
  expect_true(all(res$.completed))

  # `.selected`: a zero-row, zero-column tibble on every completed fold.
  for (sel in res$.selected) {
    expect_s3_class(sel, "tbl_df")
    expect_identical(dim(sel), c(0L, 0L))
  }
  # `.inner_metrics`: tune's summary columns and no parameter column, no rows.
  for (inner in res$.inner_metrics) {
    expect_s3_class(inner, "tbl_df")
    expect_identical(
      names(inner),
      c(".metric", ".estimator", "mean", "n", "std_err", ".config")
    )
    expect_identical(nrow(inner), 0L)
  }
  # Neither optional column exists on a run that did not ask.
  expect_false(".predictions" %in% names(res))
  expect_false(".extracts" %in% names(res))
})

test_that("AC2: the two seeds are the documented draw, shared with a tuned run under the same session seed", {
  skip_if_no_engines()

  d <- make_reg_data()
  folds <- det_nested(d)
  ms <- reg_metrics()

  # The contract, written out rather than read off any run: `set.seed(s)`,
  # one `sample.int(.Machine$integer.max, 2 * n)`, fold i taking elements
  # 2i - 1 and 2i.
  # Both workflows are built before the seed is set: a recipe step draws its
  # id from the stream, and the contract's draw is the loop's first.
  wf <- fixed_workflow(d)
  tuned_wf <- det_workflow(d)
  set.seed(30)
  seeds <- sample.int(.Machine$integer.max, 2L * nrow(folds))

  set.seed(30)
  res <- nested_fit_resamples(wf, folds, metrics = ms)
  expect_identical(res$.tuning_seed, seeds[c(1L, 3L, 5L)])
  expect_identical(res$.outer_fit_seed, seeds[c(2L, 4L, 6L)])

  set.seed(30)
  tuned <- nested_tune_grid(
    tuned_wf,
    folds,
    grid = det_grid(),
    metrics = ms
  )
  expect_identical(res$.outer_fit_seed, tuned$.outer_fit_seed)
  expect_identical(res$.tuning_seed, tuned$.tuning_seed)
})

test_that("AC2: `.predictions` and `.extracts` are present exactly when the control asked", {
  skip_if_no_engines()

  d <- make_reg_data()
  folds <- det_nested(d)
  ms <- reg_metrics()

  set.seed(30)
  kept <- nested_fit_resamples(
    fixed_workflow(d),
    folds,
    metrics = ms,
    control = tune::control_resamples(
      save_pred = TRUE,
      extract = function(x) class(x)
    )
  )
  expect_true(all(c(".predictions", ".extracts") %in% names(kept)))
  # tune's order: `.predictions` then `.extracts`, after `.notes` (D-055).
  expect_identical(
    match(c(".notes", ".predictions", ".extracts"), names(kept)),
    match(".notes", names(kept)) + 0:2
  )
  for (i in seq_len(nrow(kept))) {
    preds <- kept$.predictions[[i]]
    expect_s3_class(preds, "tbl_df")
    expect_identical(
      nrow(preds),
      nrow(rsample::assessment(folds$splits[[i]]))
    )
    expect_true(".pred" %in% names(preds))
    expect_identical(
      kept$.extracts[[i]],
      class(parsnip::fit(fixed_workflow(d), d))
    )
  }

  set.seed(30)
  preds_only <- nested_fit_resamples(
    fixed_workflow(d),
    folds,
    metrics = ms,
    control = tune::control_resamples(save_pred = TRUE)
  )
  expect_true(".predictions" %in% names(preds_only))
  expect_false(".extracts" %in% names(preds_only))
})

test_that("AC2: a fold whose fit raises is recorded as failed with a note at the outer fit", {
  skip_if_no_engines()

  d <- make_reg_data()
  ms <- reg_metrics()
  nested <- break_fold(det_nested(d), fold = 2L, stage = "outer fit")

  wf <- fixed_workflow(d)
  set.seed(30)
  expect_warning(
    res <- nested_fit_resamples(wf, nested, metrics = ms),
    class = "nestedtune_failed_folds"
  )
  expect_identical(res$.completed, c(TRUE, FALSE, TRUE))
  expect_identical(attr(res, "folds_attempted"), 3L)
  expect_identical(attr(res, "folds_completed"), 2L)

  notes <- res$.notes[[2L]]
  expect_identical(notes$location[[1L]], "outer fit")
  expect_identical(notes$type[[1L]], "error")
  # The failure is the one the design plants: an outer `in_id` past the
  # frame, which `last_fit()` refuses (M54), not some other cause.
  expect_match(notes$note[[1L]], "999999", fixed = TRUE)

  # A failed fold holds NULL where a completed one holds the empty table,
  # and contributes no metric rows.
  expect_null(res$.selected[[2L]])
  expect_identical(nrow(res$.metrics[[2L]]), 0L)
  expect_identical(nrow(res$.inner_metrics[[2L]]), 0L)
  expect_identical(
    names(res$.inner_metrics[[2L]]),
    names(res$.inner_metrics[[1L]])
  )
  # The completed folds are untouched by the failure.
  expect_identical(dim(res$.selected[[1L]]), c(0L, 0L))
  expect_identical(nrow(res$.metrics[[1L]]), 2L)
})
