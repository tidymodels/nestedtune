# nested_final_fit() on a nested_results_set (M71, AC4): the set branch
# reads the workflow and its record off one row, and what it fits is what
# the hand pairing fits, seed for seed.

test_that("AC4: a fit by id is the fit of the extracted workflow with its own results", {
  skip_if_no_wset_fixture()
  d <- make_reg_data()
  res <- wset_results("nested_tune_grid")

  for (i in seq_len(nrow(res))) {
    id <- res$wflow_id[[i]]
    set.seed(41)
    by_id <- nested_final_fit(res, id = id)
    set.seed(41)
    by_hand <- nested_final_fit(extract_workflow(res, id), res$result[[i]])

    expect_s3_class(by_id, "nested_final_fit")
    expect_identical(by_id$selected, by_hand$selected)
    expect_identical(by_id$tuning_seed, by_hand$tuning_seed)
    expect_identical(by_id$fit_seed, by_hand$fit_seed)
    expect_identical(
      predict(by_id, new_data = d[1:5, ]),
      predict(by_hand, new_data = d[1:5, ])
    )
    expect_identical(
      extract_procedure(by_id)$tuner,
      extract_procedure(res$result[[i]])$tuner
    )
  }
  # The two rows really are two procedures: one selected, one did not.
  set.seed(41)
  expect_identical(nrow(nested_final_fit(res, id = "tuned")$selected), 1L)
  set.seed(41)
  expect_identical(nrow(nested_final_fit(res, id = "fixed")$selected), 0L)
})

test_that("AC4: an id naming no row is refused", {
  skip_if_no_wset_fixture()
  res <- wset_results("nested_tune_grid")
  set.seed(1)
  before <- .Random.seed
  cnd <- rlang::catch_cnd(nested_final_fit(res, id = "nonesuch"))
  expect_s3_class(cnd, "nestedtune_unknown_id")
  expect_identical(rlang::call_name(conditionCall(cnd)), "nested_final_fit")
  expect_match(conditionMessage(cnd), "nonesuch", fixed = TRUE)
  expect_identical(.Random.seed, before)
})

test_that("AC4: a set with results, a set with no id, and a workflow with an id are refused", {
  skip_if_no_wset_fixture()
  d <- make_reg_data()
  res <- wset_results("nested_tune_grid")
  single <- final_results(d)

  shapes <- list(
    set_with_results = function() {
      nested_final_fit(res, res$result[[1L]], id = "tuned")
    },
    set_without_id = function() nested_final_fit(res),
    workflow_with_id = function() {
      nested_final_fit(det_workflow(d), single, id = "tuned")
    }
  )
  for (name in names(shapes)) {
    cnd <- rlang::catch_cnd(shapes[[name]]())
    expect_s3_class(cnd, "nestedtune_bad_final_fit_args")
    expect_identical(
      rlang::call_name(conditionCall(cnd)),
      "nested_final_fit",
      info = name
    )
  }
  # The dots fence still comes first.
  expect_s3_class(
    rlang::catch_cnd(nested_final_fit(res, id = "tuned", nonesuch = 1)),
    "rlib_error_dots_nonempty"
  )
})
