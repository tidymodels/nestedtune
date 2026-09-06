# What the final fit hands back (AC1).

test_that("the final fit returns a trained workflow inside its own object", {
  skip_if_no_engines()

  d <- make_reg_data()
  wf <- det_workflow(d)
  res <- final_results(d)

  set.seed(3)
  final <- memoised(nested_final_fit(wf, res))

  expect_s3_class(final, "nested_final_fit")
  expect_named(
    final,
    c("workflow", "selected", "tuning", "tuning_seed", "fit_seed", "procedure")
  )

  extracted <- extract_workflow(final)
  expect_s3_class(extracted, "workflow")
  expect_true(workflows::is_trained_workflow(extracted))

  # The selection is a single candidate row drawn from the grid that was asked
  # for, not a ranking over candidates.
  expect_s3_class(final$selected, "data.frame")
  expect_identical(nrow(final$selected), 1L)
  expect_true(final$selected$num_comp %in% det_grid()$num_comp)

  # The tuning run it was chosen from travels with it, and it is tune's own
  # object rather than a summary of one.
  expect_s3_class(final$tuning, "tune_results")

  expect_type(final$tuning_seed, "integer")
  expect_type(final$fit_seed, "integer")
  expect_false(identical(final$tuning_seed, final$fit_seed))
})

test_that("the fitted workflow predicts on new data", {
  skip_if_no_engines()

  d <- make_reg_data()
  wf <- det_workflow(d)
  res <- final_results(d)

  set.seed(3)
  final <- memoised(nested_final_fit(wf, res))

  preds <- predict(extract_workflow(final), new_data = d[1:5, ])
  expect_identical(nrow(preds), 5L)
  expect_true(all(is.finite(preds$.pred)))
})

test_that("the final fit trains on every row, not on an outer analysis set", {
  skip_if_no_engines()

  d <- make_reg_data()
  wf <- det_workflow(d)
  res <- final_results(d)

  set.seed(3)
  final <- memoised(nested_final_fit(wf, res))

  # The mould records how many rows the workflow was fitted on. Any outer
  # analysis set would be smaller, so this is what separates a final fit from
  # one more fold.
  mould <- workflows::extract_mold(extract_workflow(final))
  expect_identical(nrow(mould$predictors), nrow(d))
})

# The recorded selection rule reaches the final fit (M69, AC2): under each of
# the three rules the full-data selection is what tune's own selector, called
# by name here with the recorded orderings and limit, picks on the final fit's
# own tuning run. The oracle is tune's selector on `$tuning`, never the
# package's `apply_selection_rule()`.

final_fit_selector <- function(final, rule) {
  tuning <- final$tuning
  metric <- tune::.get_tune_metric_names(tuning)[[1L]]
  switch(
    rule$rule,
    best = tune::select_best(tuning, metric = metric),
    one_std_err = rlang::inject(tune::select_by_one_std_err(
      tuning,
      !!!rule$order,
      metric = metric
    )),
    pct_loss = rlang::inject(tune::select_by_pct_loss(
      tuning,
      !!!rule$order,
      metric = metric,
      limit = rule$limit
    ))
  )
}

test_that("AC2: the final fit selects by the recorded rule, and records it (M69)", {
  skip_if_no_bayes_fixture()

  d <- make_reg_data()
  wf <- bayes_workflow(d)
  folds <- final_nested(d)
  p <- bayes_param_info(wf)
  ms <- reg_metrics()
  g <- expand.grid(df1 = c(2L, 5L, 8L), df2 = c(2L, 5L, 8L))

  rules <- list(
    best = selection_rule("best"),
    one_std_err = selection_rule("one_std_err", desc(df1), df2),
    pct_loss = selection_rule("pct_loss", desc(df1), df2, limit = 5)
  )
  picked <- list()
  for (nm in names(rules)) {
    set.seed(22)
    res <- memoised(nested_tune_grid(
      wf,
      folds,
      grid = g,
      metrics = ms,
      param_info = p,
      select = rules[[nm]]
    ))
    expect_identical(extract_procedure(res)$select, rules[[nm]])

    set.seed(3)
    final <- memoised(nested_final_fit(wf, res))
    expect_identical(final$selected, final_fit_selector(final, rules[[nm]]))
    expect_identical(extract_procedure(final)$select, rules[[nm]])
    # And the fitted workflow is the selection, finalized.
    expect_identical(
      tune::extract_parameter_set_dials(extract_workflow(final))$id,
      character(0)
    )
    picked[[nm]] <- final$selected
  }

  # The three rules do not all agree on this run, so a final fit that ignored
  # the record could not match all three selectors (measured 2026-09-06 on
  # the full-data run: best picks (2, 2), one_std_err and pct_loss (5, 2)).
  expect_false(
    identical(picked$best, picked$one_std_err) &&
      identical(picked$best, picked$pct_loss)
  )
})
