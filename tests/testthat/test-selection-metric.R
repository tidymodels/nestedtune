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
  expect_false(
    "first_metric" %in% names(procedure_tuner(extract_procedure(res))$args)
  )

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
    nested_tune_grid(
      det_workflow(d),
      det_nested(d),
      grid = det_grid(),
      metrics = wrong
    ),
    class = "nestedtune_metrics_mode"
  )
  expect_identical(rlang::call_name(cnd$call), "nested_tune_grid")
  expect_s3_class(cnd$parent, "error")
})

# `nested_fit_resamples()` selects nothing and records no name, but every
# fold's run would still fail on such a set, so it is refused at entry too
# (M117, D-082). Before, each fold ran, failed, and the call warned. The
# warning count shows that the call did not reach the failed-fold warning,
# which follows every fold's run.
expect_metrics_mode_refusal <- function(expr, fn) {
  warned <- 0L
  cnd <- withCallingHandlers(
    expect_error(expr, class = "nestedtune_metrics_mode"),
    warning = function(w) {
      warned <<- warned + 1L
      invokeRestart("muffleWarning")
    }
  )
  expect_identical(warned, 0L)
  expect_identical(rlang::call_name(cnd$call), fn)
  expect_s3_class(cnd$parent, "error")
  invisible(cnd)
}

test_that("nested_fit_resamples() refuses a metric set that does not suit the model's mode (M117 AC1)", {
  skip_if_no_engines()
  d <- make_reg_data()
  wrong <- yardstick::metric_set(yardstick::accuracy)

  expect_metrics_mode_refusal(
    nested_fit_resamples(fixed_workflow(d), det_nested(d), metrics = wrong),
    "nested_fit_resamples"
  )
  expect_metrics_mode_refusal(
    nested_fit_resamples(
      parsnip::linear_reg(),
      y ~ x1 + x2 + x3 + x4,
      det_nested(d),
      metrics = wrong
    ),
    "nested_fit_resamples"
  )
})

test_that("a workflow set with an unsuitable metric set is refused before any workflow runs (M116)", {
  skip_if_no_wset_fixture()
  d <- make_reg_data()
  # The workflow with nothing to tune comes first and takes a suitable set
  # from its own `option` entry, so the refusal is the tuned workflow's (M117
  # made the pre-check judge both routes). A refusal made only at the tuned
  # workflow's turn would follow the first workflow's run, which the counter
  # on `run_orchestrator()` would see.
  wset <- workflowsets::as_workflow_set(
    fixed = fixed_workflow(d),
    tuned = det_workflow(d)
  )
  wset <- workflowsets::option_add(wset, id = "fixed", metrics = reg_metrics())
  runs <- 0L
  local_mocked_bindings(run_orchestrator = function(...) {
    runs <<- runs + 1L
    NULL
  })
  cnd <- expect_error(
    nested_workflow_map(
      object = wset,
      fn = "nested_tune_grid",
      resamples = det_nested(d),
      metrics = yardstick::metric_set(yardstick::accuracy),
      grid = det_grid()
    ),
    class = "nestedtune_metrics_mode"
  )
  expect_identical(runs, 0L)
  expect_match(conditionMessage(cnd), "Workflow \"tuned\"", fixed = TRUE)
})

# A workflow the map routes to `nested_fit_resamples()` is judged in the
# pre-check too (M117, D-082), whether `fn` names that function or a tuner. The refused workflow
# comes second and takes its set from its own `option` entry, since a shared
# set in `...` would refuse the first. No orchestrator call may start.
test_that("a workflow the map routes to nested_fit_resamples() is refused before any workflow runs (M117 AC2)", {
  skip_if_no_wset_fixture()
  d <- make_reg_data()
  wset <- workflowsets::as_workflow_set(
    ok = fixed_workflow(d),
    bad = fixed_workflow(d)
  )
  wset <- workflowsets::option_add(
    wset,
    id = "bad",
    metrics = yardstick::metric_set(yardstick::accuracy)
  )

  for (fn in c("nested_fit_resamples", "nested_tune_grid")) {
    runs <- 0L
    local_mocked_bindings(run_orchestrator = function(...) {
      runs <<- runs + 1L
      NULL
    })
    cnd <- expect_error(
      nested_workflow_map(
        object = wset,
        fn = fn,
        resamples = det_nested(d),
        metrics = reg_metrics()
      ),
      class = "nestedtune_metrics_mode"
    )
    expect_match(conditionMessage(cnd), "Workflow \"bad\"", fixed = TRUE)
    expect_identical(runs, 0L)
  }
})
