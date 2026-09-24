# The record's `first_metric` entry (M116): the name of the first metric in the
# set, as tune resolves it for the workflow. The oracle is tune's own reading
# of the final fit's stored tuning run, `tune::.get_tune_metric_names()`, the
# call every fold and the final fit select on. It is compared with the entry
# on both the results object and the final fit built from it.

expect_first_metric <- function(res, final) {
  want <- tune::.get_tune_metric_names(extract_tune_results(final))[[1L]]
  expect_identical(extract_procedure(res)$first_metric, want)
  expect_identical(extract_procedure(final)$first_metric, want)
}

test_that("a grid run records the first metric of the set it was given, in either order (M116 AC1)", {
  skip_if_no_engines()
  d <- make_reg_data()
  wf <- det_workflow(d)

  for (ms in list(
    yardstick::metric_set(yardstick::mae, yardstick::rmse),
    yardstick::metric_set(yardstick::rmse, yardstick::mae)
  )) {
    res <- final_results(d, metrics = ms)
    set.seed(31)
    final <- memoised(nested_final_fit(wf, res))
    expect_first_metric(res, final)
    expect_identical(
      extract_procedure(res)$first_metric,
      names(attr(ms, "metrics"))[[1L]]
    )
  }
})

test_that("a grid run given no metric set records the first metric of tune's default (M116 AC1)", {
  skip_if_no_engines(stochastic = TRUE)

  d <- make_reg_data()
  wf <- det_workflow(d)
  res <- final_results(d, metrics = NULL)
  set.seed(31)
  final <- memoised(nested_final_fit(wf, res))
  expect_first_metric(res, final)
  expect_identical(extract_procedure(res)$first_metric, "rmse")

  # A classification workflow's default set opens on another metric.
  d <- cls_data()
  wf <- cls_workflow(d)
  set.seed(22)
  res <- memoised(nested_tune_grid(wf, cls_nested(d), grid = cls_grid()))
  set.seed(31)
  final <- memoised(nested_final_fit(wf, res))
  expect_first_metric(res, final)
  expect_false(identical(extract_procedure(res)$first_metric, "rmse"))
})

test_that("the Bayesian, racing and annealing runs record the first metric (M116 AC1)", {
  skip_if_no_bayes_fixture()
  skip_if_no_race_fixture()
  skip_if_no_anneal_fixture()

  d <- make_reg_data()

  res <- bayes_final_results(d)
  set.seed(31)
  final <- memoised(nested_final_fit(bayes_workflow(d), res))
  expect_first_metric(res, final)

  for (fn in RACERS) {
    res <- race_final_results(fn, d)
    set.seed(33)
    final <- memoised(nested_final_fit(det_workflow(d), res))
    expect_first_metric(res, final)
  }

  res <- anneal_final_results(d)
  set.seed(33)
  final <- memoised(nested_final_fit(det_workflow(d), res))
  expect_first_metric(res, final)
})

test_that("the entry reaches no tuner, and a run that selects nothing records none (M116 AC1)", {
  skip_if_no_engines(stochastic = TRUE)

  d <- make_reg_data()
  res <- final_results(d)
  expect_false("first_metric" %in% names(procedure_tuner(extract_procedure(res))$args))

  fr <- fit_resamples_results(d)
  expect_false("first_metric" %in% names(extract_procedure(fr)))
})

# A metric set tune cannot resolve for the workflow's mode is refused before
# any fold runs, since the entry cannot be recorded for it (M116 review). Each
# fold's run would fail on the same set.
test_that("a metric set that does not suit the model's mode is refused at entry (M116)", {
  skip_if_no_engines()
  d <- make_reg_data()
  wrong <- yardstick::metric_set(yardstick::accuracy)

  cnd <- expect_error(
    nested_tune_grid(det_workflow(d), det_nested(d), grid = det_grid(), metrics = wrong),
    class = "nestedtune_metrics_mode"
  )
  expect_identical(rlang::call_name(cnd$call), "nested_tune_grid")
  expect_s3_class(cnd$parent, "error")
})

test_that("a workflow set with an unsuitable metric set is refused before any workflow runs (M116)", {
  skip_if_no_engines()
  d <- make_reg_data()
  # The workflow with nothing to tune comes first, so a refusal made only at
  # the tuned workflow's turn would follow its run and its failed-fold warning.
  wset <- workflowsets::as_workflow_set(
    fixed = fixed_workflow(d),
    tuned = det_workflow(d)
  )
  warned <- 0L
  withCallingHandlers(
    expect_error(
      nested_workflow_map(
        object = wset,
        fn = "nested_tune_grid",
        resamples = det_nested(d),
        metrics = yardstick::metric_set(yardstick::accuracy),
        grid = det_grid()
      ),
      class = "nestedtune_metrics_mode"
    ),
    warning = function(w) {
      warned <<- warned + 1L
      invokeRestart("muffleWarning")
    }
  )
  expect_identical(warned, 0L)
})
