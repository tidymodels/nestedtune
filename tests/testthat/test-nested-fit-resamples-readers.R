# Every reader of a `nested_results` answers on a `nested_fit_resamples()`
# result (M70, AC3): the ones that read the outer fits return what they
# read, the ones that read the inner stage return zero rows, and the one
# view with nothing to draw refuses by name.

test_that("AC3: the readers over the outer fits answer without a condition", {
  skip_if_no_engines()
  d <- make_reg_data()
  res <- fit_resamples_results(d)

  expect_no_condition(metrics <- collect_metrics(res))
  expect_identical(nrow(metrics), 2L)
  expect_setequal(metrics$.metric, c("rmse", "rsq"))
  expect_identical(metrics$n, c(3L, 3L))

  expect_no_condition(per_fold <- collect_metrics(res, summarize = FALSE))
  expect_identical(nrow(per_fold), 6L)

  expect_no_condition(s <- summary(res))
  expect_s3_class(s, "summary.nested_results")
  expect_identical(s$completed, 3L)
  expect_length(s$selection, 0L)

  expect_no_condition(text <- print_text(res))
  expect_match(text, "3-fold cross-validation", fixed = TRUE)
  expect_no_condition(summary_text <- print_text(s))
  expect_match(summary_text, "No tuned parameters", fixed = TRUE)

  expect_no_condition(notes <- collect_notes(res))
  expect_identical(nrow(notes), 0L)
  expect_true(all(c("id", "location", "type", "note") %in% names(notes)))
})

test_that("AC3: the readers over the inner stage return zero rows", {
  skip_if_no_engines()
  d <- make_reg_data()
  res <- fit_resamples_results(d)

  expect_no_condition(sel <- collect_selections(res))
  expect_identical(nrow(sel), 0L)
  expect_identical(names(sel), "id")

  expect_no_condition(inner <- collect_inner_metrics(res))
  expect_identical(nrow(inner), 0L)
  expect_identical(
    names(inner),
    c("id", ".metric", ".estimator", "mean", "n", "std_err", ".config")
  )

  # `agreement()` on a run that selected nothing is D-039's zero rows: the
  # two count columns and nothing to key them by.
  expect_no_condition(agree <- agreement(res))
  expect_identical(nrow(agree), 0L)
  expect_identical(names(agree), c("n", "prop"))
})

test_that("AC3: the outer fit's predictions and extracts stack when they were kept", {
  skip_if_no_engines()
  d <- make_reg_data()
  folds <- det_nested(d)

  set.seed(30)
  res <- memoised(nested_fit_resamples(
    fixed_workflow(d),
    folds,
    metrics = reg_metrics(),
    control = tune::control_resamples(
      save_pred = TRUE,
      extract = function(x) class(x)
    )
  ))

  expect_no_condition(preds <- collect_predictions(res))
  expect_identical(nrow(preds), nrow(d))
  expect_true(all(c("id", ".pred", ".row") %in% names(preds)))

  expect_no_condition(extracts <- collect_extracts(res))
  expect_identical(nrow(extracts), 3L)
  expect_identical(names(extracts), c("id", ".extracts"))

  # A run that did not ask refuses under the class the five refuse with.
  plain <- fit_resamples_results(d)
  expect_error(
    collect_predictions(plain),
    class = "nestedtune_column_not_saved"
  )
  expect_error(collect_extracts(plain), class = "nestedtune_column_not_saved")
})

test_that("AC3: the performance view draws and the parameters view refuses by name", {
  skip_if_no_engines()
  d <- make_reg_data()
  res <- fit_resamples_results(d)

  expect_no_condition(p <- autoplot(res, type = "performance"))
  expect_s3_class(p, "ggplot")

  cnd <- rlang::catch_cnd(autoplot(res, type = "parameters"))
  expect_s3_class(cnd, "nestedtune_no_tuned_parameters")
  expect_match(conditionMessage(cnd), "no tuned parameters", fixed = TRUE)
  expect_match(conditionMessage(cnd), "type = \"performance\"", fixed = TRUE)
  # The default type is the parameters view, so the bare call refuses too.
  expect_error(autoplot(res), class = "nestedtune_no_tuned_parameters")
})
