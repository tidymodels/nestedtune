# Entry checks on nested_fit_resamples() (M70). The refusal that is this
# orchestrator's own -- a workflow with something to tune -- and the shared
# checks it inherits, each fired before any fold runs.

test_that("AC5: a workflow with a tune() marker is refused, naming the tuning orchestrators, before any fold runs", {
  skip_if_no_engines()
  d <- make_reg_data()
  folds <- det_nested(d)

  wf <- det_workflow(d)
  set.seed(1)
  before <- .Random.seed
  cnd <- rlang::catch_cnd(nested_fit_resamples(wf, folds))
  expect_s3_class(cnd, "nestedtune_tuned_workflow")
  expect_identical(rlang::call_name(conditionCall(cnd)), "nested_fit_resamples")
  # The seeds are drawn only once every check has passed, so an untouched
  # stream is the evidence that no fold ran (the M03 discipline).
  expect_identical(.Random.seed, before)

  msg <- conditionMessage(cnd)
  expect_match(msg, "num_comp", fixed = TRUE)
  for (fn in c(
    "nested_tune_grid",
    "nested_tune_bayes",
    "nested_tune_race_anova",
    "nested_tune_race_win_loss",
    "nested_tune_sim_anneal"
  )) {
    expect_match(msg, paste0(fn, "()"), fixed = TRUE)
  }
})

test_that("AC5: a workflow tuning two parameters is refused naming both", {
  skip_if_no_engines()
  skip_if_not_installed("dials")
  d <- make_reg_data()

  cnd <- rlang::catch_cnd(nested_fit_resamples(
    bayes_workflow(d),
    det_nested(d)
  ))
  expect_s3_class(cnd, "nestedtune_tuned_workflow")
  expect_match(conditionMessage(cnd), "2 parameters", fixed = TRUE)
  expect_match(conditionMessage(cnd), "df1", fixed = TRUE)
  expect_match(conditionMessage(cnd), "df2", fixed = TRUE)
})

test_that("the shared entry checks fire, in the shared shapes", {
  skip_if_no_engines()
  d <- make_reg_data()
  wf <- fixed_workflow(d)
  folds <- det_nested(d)

  # `object` first: not a workflow, and a fitted one.
  expect_error(nested_fit_resamples(1, folds), "must be a")
  fitted <- parsnip::fit(wf, d)
  expect_error(
    nested_fit_resamples(fitted, folds),
    "must not already be fitted"
  )

  # The design.
  expect_error(
    nested_fit_resamples(wf, rsample::vfold_cv(d, v = 3)),
    class = "nestedtune_bad_design"
  )
  expect_error(
    nested_fit_resamples(wf, data.frame()),
    class = "nestedtune_bad_design"
  )

  # The arguments the outer fit reads.
  expect_error(nested_fit_resamples(wf, folds, metrics = "rmse"), "metric_set")
  expect_error(
    nested_fit_resamples(wf, folds, event_level = "third"),
    "must be \"first\" or \"second\""
  )
  expect_error(
    nested_fit_resamples(wf, folds, eval_time = c(1, -1)),
    "Element 2"
  )

  # The dots (D-042): `control` and nothing else, of the tuner's class, and
  # not naming a level the argument does not.
  expect_error(
    nested_fit_resamples(wf, folds, nonesuch = 1),
    class = "nestedtune_bad_dots"
  )
  expect_error(
    nested_fit_resamples(wf, folds, control = tune::control_bayes(seed = 1)),
    class = "nestedtune_bad_control"
  )
  cnd <- rlang::catch_cnd(
    nested_fit_resamples(wf, folds, control = tune::control_bayes(seed = 1))
  )
  expect_match(conditionMessage(cnd), "control_resamples", fixed = TRUE)
  expect_error(
    nested_fit_resamples(
      wf,
      folds,
      control = tune::control_resamples(event_level = "second")
    ),
    class = "nestedtune_bad_control"
  )
  # tune gives `control_grid()` the same class, so it is the same object here.
  set.seed(30)
  expect_no_error(
    under_grid <- nested_fit_resamples(
      wf,
      folds,
      metrics = reg_metrics(),
      control = tune::control_grid()
    )
  )
  expect_identical(under_grid$.metrics, fit_resamples_results(d)$.metrics)
})

test_that("the refusals fire before the RNG is drawn from", {
  skip_if_no_engines()
  d <- make_reg_data()
  wf <- fixed_workflow(d)
  folds <- det_nested(d)

  # Built before the snapshot: constructing an rset draws from the stream.
  plain <- rsample::vfold_cv(d, v = 3)
  set.seed(1)
  before <- .Random.seed
  expect_error(nested_fit_resamples(wf, folds, metrics = "rmse"))
  expect_error(nested_fit_resamples(wf, folds, nonesuch = 1))
  expect_error(nested_fit_resamples(wf, plain))
  expect_identical(.Random.seed, before)
})
