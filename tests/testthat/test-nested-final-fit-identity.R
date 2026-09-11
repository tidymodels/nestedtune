# The workflow identity on the record, and the final fit's refusal of any
# other workflow (M83).
#
# Every orchestrator records `workflow_identity()` of the workflow it was
# given as the `workflow` entry of its procedure record (AC1), and
# `nested_final_fit()` compares the workflow it is handed against that entry
# after the record checks, the grid-column check and the tune() marker
# check, and before any seed is drawn (AC2). test-workflow-identity.R pins
# the identity function itself.

# AC1: every tuner the registry enumerates records the identity, and so
# does each row of a set and the final fit's own record.

test_that("AC1: every orchestrator's result records the workflow it ran under", {
  skip_if_no_race_fixture()
  skip_if_no_anneal_fixture()
  skip_if_no_bayes_fixture()
  d <- make_reg_data()

  # One result per registry entry, beside the workflow its fixture built
  # it from; the loop over the registry's names is what ties the six to
  # the registry rather than to this list.
  runs <- list(
    tune_grid = list(res = final_results(d), wf = det_workflow(d)),
    tune_bayes = list(res = bayes_results(), wf = bayes_workflow(d)),
    tune_race_anova = list(
      res = race_results("tune_race_anova"),
      wf = det_workflow(d)
    ),
    tune_race_win_loss = list(
      res = race_results("tune_race_win_loss"),
      wf = det_workflow(d)
    ),
    tune_sim_anneal = list(res = anneal_results(), wf = det_workflow(d)),
    fit_resamples = list(res = fit_resamples_results(d), wf = fixed_workflow(d))
  )
  expect_setequal(names(runs), names(tuner_registry))

  for (tuner in names(tuner_registry)) {
    run <- runs[[tuner]]
    procedure <- extract_procedure(run$res)
    expect_identical(procedure$tuner, tuner)
    expect_identical(procedure$workflow, workflow_identity(run$wf))
    # Never forwarded to the tuner as one of its own arguments.
    expect_false("workflow" %in% names(procedure_tuner(procedure)$args))
  }
})

test_that("AC1: each row of a nested_results_set records its own workflow", {
  skip_if_no_wset_fixture()

  set <- wset_results("nested_tune_grid")
  expect_gt(nrow(set), 1L)
  for (i in seq_len(nrow(set))) {
    expect_identical(
      extract_procedure(set$result[[i]])$workflow,
      workflow_identity(set$workflow[[i]])
    )
  }
  # The two rows differ, so the entry is the row's own rather than one
  # shared value.
  expect_false(identical(
    extract_procedure(set$result[[1L]])$workflow,
    extract_procedure(set$result[[2L]])$workflow
  ))
})

test_that("AC1: the final fit's record carries the same entry, and the fit runs", {
  skip_if_no_engines()
  d <- make_reg_data()

  res <- final_results(d)
  set.seed(5)
  fit <- nested_final_fit(det_workflow(d), res)
  expect_s3_class(fit, "nested_final_fit")
  expect_identical(
    extract_procedure(fit)$workflow,
    extract_procedure(res)$workflow
  )

  res <- fit_resamples_results(d)
  set.seed(5)
  fit <- nested_final_fit(fixed_workflow(d), res)
  expect_s3_class(fit, "nested_final_fit")
  expect_identical(
    extract_procedure(fit)$workflow,
    extract_procedure(res)$workflow
  )
})
