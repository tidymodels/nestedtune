# M106 AC4: predict() on a results object refuses and names the final fit.
#
# A nested run holds one fitted model per outer fold and none for new data.
# Without a method, R answers "no applicable method", which does not say
# where the model to predict with comes from.

test_that("predict() on a nested_results names nested_final_fit()", {
  skip_if_no_engines()

  d <- make_reg_data()
  res <- final_results(d)
  cnd <- rlang::catch_cnd(predict(res, new_data = d))
  expect_s3_class(cnd, "nestedtune_predict_results")
  expect_match(conditionMessage(cnd), "nested_final_fit()", fixed = TRUE)
  expect_snapshot(error = TRUE, predict(res, new_data = d))
})

test_that("predict() on a nested_results_set names nested_final_fit()", {
  skip_if_no_wset_fixture()

  res <- wset_results("nested_tune_grid")
  cnd <- rlang::catch_cnd(predict(res, new_data = make_reg_data()))
  expect_s3_class(cnd, "nestedtune_predict_results")
  expect_match(conditionMessage(cnd), "nested_final_fit()", fixed = TRUE)
  expect_match(conditionMessage(cnd), "naming it with `id`", fixed = TRUE)
  expect_snapshot(error = TRUE, predict(res, new_data = make_reg_data()))
})
