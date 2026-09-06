# The final fit on a record that selected nothing (M70, AC4): the procedure
# record's shape, the record check, the fit with no tuning run, its print,
# and the two accessors that have nothing to return.

test_that("AC4: the procedure record names the tuner and carries no grid, param_info or select", {
  skip_if_no_engines()
  d <- make_reg_data()
  res <- fit_resamples_results(d)

  procedure <- extract_procedure(res)
  expect_identical(procedure$tuner, "fit_resamples")
  expect_identical(procedure$event_level, "first")
  expect_null(procedure$eval_time)
  expect_true("eval_time" %in% names(procedure))
  expect_false(any(c("grid", "param_info", "select") %in% names(procedure)))
  expect_null(attr(res, "grid"))

  # The effective control (D-042): tune's `control_resamples()` with the
  # forced slots applied, and nothing else changed.
  expected <- tune::control_resamples()
  expected$allow_par <- FALSE
  expected$event_level <- "first"
  expect_identical(procedure$control, expected)

  # The record check accepts it: no rule is asked of a tuner that selects
  # nothing.
  expect_identical(check_results_record(res), res)
})

test_that("AC4: the final fit fits the workflow on every row with no tuning run", {
  skip_if_no_engines()
  d <- make_reg_data()
  wf <- fixed_workflow(d)
  res <- fit_resamples_results(d)

  set.seed(31)
  seeds <- sample.int(.Machine$integer.max, 2L)
  set.seed(31)
  fit <- nested_final_fit(wf, res)

  expect_s3_class(fit, "nested_final_fit")
  expect_identical(fit$tuning_seed, seeds[[1L]])
  expect_identical(fit$fit_seed, seeds[[2L]])
  expect_null(fit$tuning)
  expect_true("tuning" %in% names(fit))
  expect_identical(dim(fit$selected), c(0L, 0L))
  expect_identical(extract_procedure(fit), extract_procedure(res))
  expect_true(workflows::is_trained_workflow(extract_workflow(fit)))

  # Its predictions are the plain fit's on the whole data.
  plain <- parsnip::fit(wf, data = d)
  expect_identical(
    predict(fit, new_data = d[1:10, ]),
    predict(plain, new_data = d[1:10, ])
  )
})

test_that("AC4: the print names the procedure as no tuning and the selection as nothing", {
  skip_if_no_engines()
  d <- make_reg_data()
  set.seed(31)
  fit <- nested_final_fit(fixed_workflow(d), fit_resamples_results(d))

  text <- print_text(fit)
  expect_match(text, "Procedure: no tuning\n", fixed = TRUE)
  expect_match(text, "Selected: nothing to select", fixed = TRUE)
  expect_no_match(text, "candidates scored", fixed = TRUE)
  expect_match(text, "No tuning ran", fixed = TRUE)
  expect_match(text, "extract_workflow()", fixed = TRUE)

  s <- summary(fit)
  expect_identical(s$tuner, "fit_resamples")
  expect_identical(s$candidates, 0L)
  expect_length(s$selection, 0L)
  expect_null(s$estimate)
  summary_text <- print_text(s)
  expect_match(summary_text, "Procedure: no tuning", fixed = TRUE)
  expect_match(summary_text, "No tuned parameters", fixed = TRUE)
  expect_no_match(summary_text, "Candidates scored", fixed = TRUE)
})

test_that("AC4: the two extractors refuse a fit that ran no tuning", {
  skip_if_no_engines()
  d <- make_reg_data()
  set.seed(31)
  fit <- nested_final_fit(fixed_workflow(d), fit_resamples_results(d))

  cnd <- rlang::catch_cnd(extract_tune_results(fit))
  expect_s3_class(cnd, "nestedtune_no_tuning_run")
  expect_identical(rlang::call_name(conditionCall(cnd)), "extract_tune_results")
  expect_match(conditionMessage(cnd), "nested_fit_resamples", fixed = TRUE)

  cnd <- rlang::catch_cnd(extract_scored_candidates(fit))
  expect_s3_class(cnd, "nestedtune_no_tuning_run")
  expect_identical(
    rlang::call_name(conditionCall(cnd)),
    "extract_scored_candidates"
  )
})

test_that("a marked workflow is refused by the final fit on such a record, before fitting", {
  skip_if_no_engines()
  d <- make_reg_data()
  res <- fit_resamples_results(d)

  wf <- det_workflow(d)
  set.seed(1)
  before <- .Random.seed
  cnd <- rlang::catch_cnd(nested_final_fit(wf, res))
  expect_s3_class(cnd, "nestedtune_tuned_workflow")
  expect_identical(rlang::call_name(conditionCall(cnd)), "nested_final_fit")
  expect_identical(.Random.seed, before)
})

test_that("the caller's RNG state is restored, and the same seed gives the same fit", {
  skip_if_no_engines(stochastic = TRUE)
  d <- make_reg_data()
  wf <- fixed_stoch_workflow(d)
  folds <- final_nested(d)
  set.seed(23)
  res <- memoised(nested_fit_resamples(wf, folds, metrics = reg_metrics()))

  set.seed(5)
  before <- .Random.seed
  first <- nested_final_fit(wf, res)
  expect_identical(.Random.seed, before)
  set.seed(5)
  second <- nested_final_fit(wf, res)
  expect_identical(first$fit_seed, second$fit_seed)
  expect_identical(
    predict(first, new_data = d[1:10, ]),
    predict(second, new_data = d[1:10, ])
  )
  # ranger draws from the stream, so a different seed is a different forest:
  # the identity above is not vacuous.
  set.seed(6)
  third <- nested_final_fit(wf, res)
  expect_false(identical(
    predict(first, new_data = d[1:10, ]),
    predict(third, new_data = d[1:10, ])
  ))
})
