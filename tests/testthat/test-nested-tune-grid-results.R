example_results <- function(v = 3, metrics = reg_metrics(), seed = 55) {
  d <- make_reg_data()
  wf <- det_workflow(d)
  set.seed(1)
  folds <- nested_resamples(
    d,
    outside = rsample::vfold_cv(v = v),
    inside = rsample::vfold_cv(v = 3)
  )
  set.seed(seed)
  memoised(nested_tune_grid(wf, folds, grid = det_grid(), metrics = metrics))
}

test_that("the results object retains one row per outer fold with its selection", {
  skip_if_no_engines()

  res <- example_results()

  expect_s3_class(res, "nested_results")
  expect_identical(nrow(res), 3L)
  expect_true(all(
    c(
      "splits",
      "id",
      ".metrics",
      ".selected",
      ".tuning_seed",
      ".outer_fit_seed"
    ) %in%
      names(res)
  ))

  # Selection instability is the thing nothing else in the ecosystem keeps.
  for (sel in res$.selected) {
    expect_true(is.data.frame(sel))
    expect_identical(nrow(sel), 1L)
    expect_true("num_comp" %in% names(sel))
  }
  expect_type(res$.tuning_seed, "integer")
  expect_type(res$.outer_fit_seed, "integer")
})

test_that("collect_metrics() summarizes across outer folds", {
  skip_if_no_engines()

  res <- example_results()
  summarized <- collect_metrics(res)

  expect_identical(
    names(summarized),
    c(".metric", ".estimator", "mean", "n", "std_err")
  )
  expect_setequal(summarized$.metric, c("rmse", "rsq"))
  expect_true(all(summarized$n == 3L))

  # The summary is the mean of the per-fold estimates, computed the dumb way.
  per_fold <- collect_metrics(res, summarize = FALSE)
  for (m in summarized$.metric) {
    expect_equal(
      summarized$mean[summarized$.metric == m],
      mean(per_fold$.estimate[per_fold$.metric == m])
    )
    vals <- per_fold$.estimate[per_fold$.metric == m]
    expect_equal(
      summarized$std_err[summarized$.metric == m],
      stats::sd(vals) / sqrt(length(vals))
    )
  }
})

test_that("collect_metrics(summarize = FALSE) returns one row per fold and metric", {
  skip_if_no_engines()

  res <- example_results()
  per_fold <- collect_metrics(res, summarize = FALSE)

  expect_identical(
    names(per_fold),
    c("id", ".metric", ".estimator", ".estimate")
  )
  expect_identical(nrow(per_fold), 6L)
  expect_setequal(per_fold$id, res$id)
})

test_that("a single outer fold gives an NA standard error rather than an error", {
  skip_if_no_engines()

  res <- example_results(v = 2)
  # Two folds still admit an SE; the guard is for the degenerate case, which
  # is reached by summarizing a one-row object.
  one <- res[1, ]
  class(one) <- class(res)
  summarized <- collect_metrics(one)

  expect_true(all(is.na(summarized$std_err)))
  expect_true(all(summarized$n == 1L))
})

test_that("a fold scoring NA is dropped from the summary rather than poisoning it", {
  skip_if_no_engines()

  res <- example_results()
  # The real route here is an outer assessment set with a single class, where
  # last_fit() returns roc_auc = NA. The shape is what matters, so it is
  # injected rather than contrived out of imbalanced data.
  is_rmse <- res$.metrics[[1]]$.metric == "rmse"
  res$.metrics[[1]]$.estimate[is_rmse] <- NA_real_

  summarized <- collect_metrics(res)
  rmse <- summarized[summarized$.metric == "rmse", ]
  rsq <- summarized[summarized$.metric == "rsq", ]

  # n counts the folds that actually contributed, so the row never reports no
  # estimate while claiming every fold was in it.
  expect_identical(rmse$n, 2L)
  expect_false(is.na(rmse$mean))
  expect_identical(rsq$n, 3L)

  per_fold <- collect_metrics(res, summarize = FALSE)
  vals <- per_fold$.estimate[per_fold$.metric == "rmse"]
  expect_equal(rmse$mean, mean(vals[!is.na(vals)]))
  expect_equal(rmse$std_err, stats::sd(vals[!is.na(vals)]) / sqrt(2))
})

test_that("a metric that is NA in every fold summarizes to NA with n = 0", {
  skip_if_no_engines()

  res <- example_results()
  for (i in seq_len(nrow(res))) {
    is_rmse <- res$.metrics[[i]]$.metric == "rmse"
    res$.metrics[[i]]$.estimate[is_rmse] <- NA_real_
  }

  summarized <- collect_metrics(res)
  rmse <- summarized[summarized$.metric == "rmse", ]

  expect_identical(rmse$n, 0L)
  expect_true(is.na(rmse$mean))
  expect_true(is.na(rmse$std_err))
})

test_that("the results object is not a tune_results, so tune's selectors refuse it", {
  skip_if_no_engines()

  res <- example_results()

  expect_false(inherits(res, "tune_results"))
  # show_best()/select_best() on outer folds would rank folds against each
  # other and return something authoritative-looking and meaningless (D-010).
  expect_error(tune::select_best(res))
  expect_error(tune::show_best(res))
})

test_that("metrics = NULL falls back to tune's defaults", {
  skip_if_no_engines()

  res <- example_results(metrics = NULL)
  summarized <- collect_metrics(res)

  expect_setequal(summarized$.metric, c("rmse", "rsq"))
})

test_that("the object carries the grid and metrics it was asked to run", {
  skip_if_no_engines()

  # IP4: the object records what was asked for, positively, rather than leaving
  # it to be inferred. Until M20 both attributes were written by
  # new_nested_results() and read by nothing, so either could be dropped
  # without a test noticing.
  #
  # The metric set is bound ONCE and compared to that binding. Two
  # metric_set() calls are never identical() -- the closure environment refers
  # to itself and identical() compares environments by reference, the same
  # cycle helper-orchestration.R's canonical_form() exists to cut -- so
  # comparing against a second reg_metrics() call fails against correct code.
  metrics <- reg_metrics()
  grid <- det_grid()
  d <- make_reg_data()
  wf <- det_workflow(d)
  set.seed(1)
  folds <- nested_resamples(
    d,
    outside = rsample::vfold_cv(v = 3),
    inside = rsample::vfold_cv(v = 3)
  )
  set.seed(55)
  res <- nested_tune_grid(wf, folds, grid = grid, metrics = metrics)

  expect_identical(attr(res, "grid"), grid)
  expect_identical(attr(res, "metrics"), metrics)

  # Both describe the call rather than the rows, so an operation the invariants
  # allow keeps them as they are. Reordering the folds is such an operation:
  # the folds are a set, and rearranging them changes nothing the object claims.
  reordered <- res[rev(seq_len(nrow(res))), ]
  expect_s3_class(reordered, "nested_results")
  expect_identical(attr(reordered, "grid"), grid)
  expect_identical(attr(reordered, "metrics"), metrics)
  expect_identical(reordered$id, rev(res$id))

  # Dropping the two seed columns used to keep the class, on the ground that
  # has_results_columns() does not name them. M36 widened the set an operation
  # must leave alone to every column the constructor writes, so it no longer
  # does -- and the call's record goes with the class rather than staying
  # readable on the tibble that comes back.
  cols <- setdiff(names(res), c(".tuning_seed", ".outer_fit_seed"))
  narrowed <- res[, cols]
  expect_false(inherits(narrowed, "nested_results"))
  expect_null(attr(narrowed, "grid"))
  expect_null(attr(narrowed, "metrics"))
})

test_that("each fold records the candidates its inner tuning actually scored", {
  skip_if_no_engines()

  # IP4 asks for "the grid actually evaluated", which the `grid` attribute
  # cannot supply: it holds the request, so a size request records a number and
  # never the candidates. This column is the record, per fold because folds can
  # genuinely disagree (measured at M21's plan gate: integer-grid expansion is
  # stochastic for a continuous parameter, and each fold tunes under its own
  # seed).
  grid <- det_grid()
  res <- example_results()

  expect_true(".inner_metrics" %in% names(res))
  expect_type(res$.inner_metrics, "list")
  expect_length(res$.inner_metrics, 3L)

  # Each fold's table is tune's summary of its inner run -- one row per
  # candidate and metric -- and the candidate set is its distinct parameter
  # rows (M49).
  for (m in res$.inner_metrics) {
    expect_true(is.data.frame(m))
    expect_identical(nrow(m), nrow(grid) * 2L)
    expect_true(all(
      c("num_comp", ".metric", "mean", "n", ".config") %in% names(m)
    ))
  }
  for (g in candidate_sets(res)) {
    expect_true(is.data.frame(g))
    expect_identical(nrow(g), nrow(grid))
    expect_true(all(c("num_comp", ".config") %in% names(g)))

    # Compared by the shared parameter column, NEVER by .config. tune renumbers
    # .config into ascending parameter order, so a request frame given in any
    # other order fails a .config-ordered comparison on a set that is identical
    # (measured at M21's criteria audit, tune 2.1.0). Sorting the parameter
    # values is the comparison that holds for any request order.
    expect_identical(sort(g$num_comp), sort(grid$num_comp))
  }
})

test_that("the evaluated-candidate record travels with the rows it describes", {
  skip_if_no_engines()

  # Unlike the `grid` attribute, this record describes the rows rather than the
  # call -- so it is a column, and a row subset carries each fold's own record
  # rather than the parent's. An attribute could not do this: M20 measured that
  # arbitrary attributes survive a row subset untouched, which is exactly the
  # stale-parent claim IP4 forbids.
  res <- example_results()

  subset <- res[2:3, ]
  expect_length(subset$.inner_metrics, 2L)
  expect_identical(subset$.inner_metrics, res$.inner_metrics[2:3])
})

test_that("the object records the design's inner specification (M46)", {
  skip_if_no_engines()

  # The final fit re-runs the procedure from the results object alone (D-041),
  # so the design's stored `inside` call travels onto the result as the same
  # unevaluated call, and it describes the call rather than the rows: kept
  # through an operation the invariants allow, shed with the class.
  d <- make_reg_data()
  wf <- det_workflow(d)
  set.seed(1)
  folds <- nested_resamples(
    d,
    outside = rsample::vfold_cv(v = 2),
    inside = rsample::vfold_cv(v = 3)
  )
  set.seed(55)
  res <- memoised(nested_tune_grid(wf, folds, grid = det_grid()))

  expect_identical(attr(res, "inside"), quote(rsample::vfold_cv(v = 3)))
  expect_identical(attr(res, "inside"), attr(folds, "inside"))
  expect_true("inside" %in% run_attributes())

  reordered <- res[rev(seq_len(nrow(res))), ]
  expect_s3_class(reordered, "nested_results")
  expect_identical(attr(reordered, "inside"), attr(folds, "inside"))

  narrowed <- res[, setdiff(names(res), ".inner_metrics")]
  expect_false(inherits(narrowed, "nested_results"))
  expect_null(attr(narrowed, "inside"))
})

test_that("a run given no metric set carries no metrics attribute", {
  skip_if_no_engines()

  # `attr(x, "metrics") <- NULL` DELETES the attribute rather than storing a
  # NULL, so the default run is the case where the attribute is absent. Pinned
  # so the test above cannot be weakened into passing on a NULL-metrics run,
  # where every assertion in it holds vacuously.
  res <- example_results(metrics = NULL)

  expect_false("metrics" %in% names(attributes(res)))
  expect_null(attr(res, "metrics"))
})

# ---- .predictions and .extracts (M68) ----------------------------------------
#
# Oracle provenance. A fold's `.predictions` element is compared against the
# `.predictions[[1]]` of `tune::last_fit()` called by hand on that fold's
# outer split, with the workflow finalized on the fold's `.selected` row, the
# run's metrics, `eval_time` and `event_level`, under
# `control_last_fit(event_level, allow_par = FALSE)`, the fold's recorded
# `.outer_fit_seed` set (Mersenne-Twister, Inversion, Rejection) after
# finalizing and before the call -- the documented seed contract, never the
# driver's own fit. A fold's `.extracts` element is compared against the
# caller's function applied to that same call's `.workflow[[1]]`. Neither
# figure is the package's own.

saved_control <- function() tune::control_grid(save_pred = TRUE)

saved_results <- function(d = make_reg_data(), nested = det_nested(d)) {
  set.seed(2)
  memoised(nested_tune_grid(
    det_workflow(d),
    nested,
    grid = det_grid(),
    metrics = reg_metrics(),
    control = saved_control()
  ))
}

# The reference last_fit() for fold `i` of a grid run on the deterministic
# workflow, written from the documented contract.
reference_last_fit <- function(res, i, d, event_level = "first") {
  final_wf <- tune::finalize_workflow(det_workflow(d), res$.selected[[i]])
  set.seed(
    res$.outer_fit_seed[[i]],
    kind = "Mersenne-Twister",
    normal.kind = "Inversion",
    sample.kind = "Rejection"
  )
  tune::last_fit(
    final_wf,
    split = res$splits[[i]],
    metrics = reg_metrics(),
    eval_time = NULL,
    control = tune::control_last_fit(
      event_level = event_level,
      allow_par = FALSE
    )
  )
}

test_that("save_pred = TRUE keeps each fold's outer-fit predictions, identical to last_fit()'s (AC1)", {
  skip_if_no_engines()

  d <- make_reg_data()
  res <- saved_results(d)

  expect_true(".predictions" %in% names(res))
  expect_type(res$.predictions, "list")
  expect_true(all(res$.completed))
  for (i in seq_len(nrow(res))) {
    ref <- reference_last_fit(res, i, d)
    expect_identical(res$.predictions[[i]], ref$.predictions[[1L]])
    # One fact held independently of the derivation: the table is the fold's
    # assessment rows, one prediction each.
    expect_identical(
      nrow(res$.predictions[[i]]),
      nrow(rsample::assessment(res$splits[[i]]))
    )
    expect_true(all(c(".pred", ".row", "y", ".config") %in%
      names(res$.predictions[[i]])))
  }
})

test_that("the default control and save_pred = FALSE leave no .predictions column (AC1)", {
  skip_if_no_engines()

  d <- make_reg_data()
  by_default <- example_results()
  expect_false(".predictions" %in% names(by_default))

  # Not memoised: the run equals the default one in value, and the fixture
  # cache would report it as the same fit paid for twice.
  set.seed(2)
  off <- nested_tune_grid(
    det_workflow(d),
    det_nested(d),
    grid = det_grid(),
    metrics = reg_metrics(),
    control = tune::control_grid(save_pred = FALSE)
  )
  expect_false(".predictions" %in% names(off))
  # The passing control: the same run with the slot on carries the column.
  expect_true(".predictions" %in% names(saved_results(d)))
})

test_that("a failed fold's .predictions element is NULL (AC1)", {
  skip_if_no_engines()

  d <- make_reg_data()
  nested <- break_fold(det_nested(d), 2, "outer fit")
  res <- suppressWarnings(saved_results(d, nested))

  expect_identical(res$.completed, c(TRUE, FALSE, TRUE))
  expect_null(res$.predictions[[2L]])
  for (i in c(1L, 3L)) {
    ref <- reference_last_fit(res, i, d)
    expect_identical(res$.predictions[[i]], ref$.predictions[[1L]])
  }
})

extracted_results <- function(
  d = make_reg_data(),
  nested = det_nested(d),
  extract = coef_extract
) {
  set.seed(2)
  memoised(nested_tune_grid(
    det_workflow(d),
    nested,
    grid = det_grid(),
    metrics = reg_metrics(),
    control = tune::control_grid(save_pred = TRUE, extract = extract)
  ))
}

test_that("extract = f keeps f() of each fold's outer-fit workflow, identical to f() on last_fit()'s (AC2)", {
  skip_if_no_engines()

  d <- make_reg_data()
  res <- extracted_results(d)

  expect_true(".extracts" %in% names(res))
  expect_type(res$.extracts, "list")
  expect_true(all(res$.completed))
  for (i in seq_len(nrow(res))) {
    ref <- reference_last_fit(res, i, d)
    expect_identical(res$.extracts[[i]], coef_extract(ref$.workflow[[1L]]))
    # One fact held independently of the derivation: a linear model on
    # `num_comp` components has that many slopes and an intercept.
    expect_identical(
      length(res$.extracts[[i]]),
      res$.selected[[i]]$num_comp + 1L
    )
    expect_identical(names(res$.extracts[[i]])[[1L]], "(Intercept)")
  }
  # Both slots on one control: the run carries both columns, `.extracts`
  # before `.predictions` as tune orders them.
  expect_true(".predictions" %in% names(res))
  expect_lt(match(".extracts", names(res)), match(".predictions", names(res)))
})

test_that("an extract that errors leaves the fold completed, its element NULL, and one note (AC2)", {
  skip_if_no_engines()

  d <- make_reg_data()
  set.seed(2)
  # No warning: the fold completed, and a reporting failure is not a fold
  # failure (IP4).
  expect_no_warning(
    res <- memoised(nested_tune_grid(
      det_workflow(d),
      det_nested(d),
      grid = det_grid(),
      metrics = reg_metrics(),
      control = tune::control_grid(
        save_pred = TRUE,
        extract = function(x) stop("no extract for this fold")
      )
    ))
  )

  expect_true(all(res$.completed))
  expect_true(".extracts" %in% names(res))
  for (i in seq_len(nrow(res))) {
    expect_null(res$.extracts[[i]])
    # tune applies the same function inside the inner run and files each of
    # those errors as a note of its own, which the fold keeps (GP1); this
    # package's row is the one at its own stage.
    notes <- res$.notes[[i]]
    ours <- notes[notes$location == "outer extract", ]
    expect_identical(nrow(ours), 1L)
    expect_identical(ours$type, "error")
    expect_identical(ours$note, "no extract for this fold")
    expect_true(all(grepl("^inner tuning", notes$location[-nrow(notes)])))
    # The rest of the record is untouched: the predictions the same control
    # asked for are kept, and the metrics are the reference's.
    ref <- reference_last_fit(res, i, d)
    expect_identical(res$.predictions[[i]], ref$.predictions[[1L]])
    expect_identical(
      res$.metrics[[i]]$.estimate,
      tune::collect_metrics(ref)$.estimate
    )
  }
})

test_that("extract = NULL leaves no .extracts column (AC2)", {
  skip_if_no_engines()

  d <- make_reg_data()
  # The default control carries `extract = NULL`.
  expect_null(tune::control_grid()$extract)
  expect_false(".extracts" %in% names(example_results()))

  # Not memoised, for the reason the `save_pred = FALSE` run gives.
  set.seed(2)
  off <- nested_tune_grid(
    det_workflow(d),
    det_nested(d),
    grid = det_grid(),
    metrics = reg_metrics(),
    control = tune::control_grid(extract = NULL)
  )
  expect_false(".extracts" %in% names(off))
  # The passing control: the same run with a function carries the column.
  expect_true(".extracts" %in% names(extracted_results(d)))
})

test_that("a failed fold's .extracts element is NULL, with no extract note (AC2)", {
  skip_if_no_engines()

  d <- make_reg_data()
  nested <- break_fold(det_nested(d), 2, "outer fit")
  res <- suppressWarnings(extracted_results(d, nested))

  expect_identical(res$.completed, c(TRUE, FALSE, TRUE))
  expect_null(res$.extracts[[2L]])
  expect_false("outer extract" %in% res$.notes[[2L]]$location)
  for (i in c(1L, 3L)) {
    ref <- reference_last_fit(res, i, d)
    expect_identical(res$.extracts[[i]], coef_extract(ref$.workflow[[1L]]))
  }
})
