# The desirability rule where desirability2 is absent (M109, AC5, D-072): the
# constructor, an orchestrator given a rule built while the package was
# installed, and the final fit on a result that recorded the rule each refuse
# with the class the racing tuners' absent-package refusal carries. The
# absence is mocked through `rlang::is_installed()`, which every one of the
# three asks, as test-nested-final-fit-sim-anneal.R masks finetune.

mask_desirability2 <- function(env = parent.frame()) {
  real <- rlang::is_installed
  testthat::local_mocked_bindings(
    is_installed = function(pkg, ...) {
      if (identical(pkg, "desirability2")) FALSE else real(pkg, ...)
    },
    .package = "rlang",
    .env = env
  )
}

expect_desirability2_refusal <- function(cnd, fn) {
  testthat::expect_s3_class(cnd, "nestedtune_pkg_not_installed")
  msg <- cli::ansi_strip(conditionMessage(cnd))
  testthat::expect_match(msg, "desirability2", fixed = TRUE)
  testthat::expect_match(msg, "0.2.0", fixed = TRUE)
  testthat::expect_identical(conditionCall(cnd)[[1L]], as.name(fn))
  invisible(cnd)
}

test_that("AC5: selection_rule() refuses the desirability rule without desirability2", {
  skip_if_not_installed("desirability2", minimum_version = "0.2.0")

  # The passing control: the same call builds the rule with the package.
  expect_s3_class(
    selection_rule("desirability", maximize(rsq)),
    "selection_rule"
  )
  mask_desirability2()
  cnd <- rlang::catch_cnd(selection_rule("desirability", maximize(rsq)))
  expect_desirability2_refusal(cnd, "selection_rule")
  # The other rules need nothing from it.
  expect_s3_class(selection_rule("one_std_err", num_comp), "selection_rule")
})

test_that("AC5: nested_tune_grid() refuses a desirability rule at entry without desirability2", {
  skip_if_no_engines()
  skip_if_not_installed("desirability2", minimum_version = "0.2.0")

  d <- make_reg_data()
  wf <- det_workflow(d)
  folds <- nested_resamples(
    d,
    outside = rsample::vfold_cv(v = 2),
    inside = rsample::vfold_cv(v = 2)
  )
  rule <- selection_rule("desirability", maximize(rsq))

  # A sentinel in place of the loop, so the refusal is shown to fire at
  # entry, and the passing control reaches it.
  testthat::local_mocked_bindings(
    dispatch_folds = function(...) {
      rlang::abort("fitting began", class = "nestedtune_sentinel")
    }
  )
  expect_error(
    nested_tune_grid(wf, folds, grid = det_grid(), select = rule),
    class = "nestedtune_sentinel"
  )
  mask_desirability2()
  cnd <- rlang::catch_cnd(
    nested_tune_grid(wf, folds, grid = det_grid(), select = rule),
    classes = "error"
  )
  expect_false(inherits(cnd, "nestedtune_sentinel"))
  expect_desirability2_refusal(cnd, "nested_tune_grid")
})

test_that("AC5: nested_final_fit() refuses a result that recorded the desirability rule without desirability2", {
  skip_if_no_bayes_fixture()
  skip_if_not_installed("desirability2", minimum_version = "0.2.0")

  # The run the final-fit oracle builds (test-nested-final-fit-results.R),
  # spelled the same way so the cache serves it.
  d <- make_reg_data()
  wf <- bayes_workflow(d)
  folds <- final_nested(d)
  p <- bayes_param_info(wf)
  ms <- reg_metrics()
  g <- expand.grid(df1 = c(2L, 5L, 8L), df2 = c(2L, 5L, 8L))
  rule <- selection_rule(
    "desirability",
    minimize(rmse),
    maximize(rsq),
    target(df1, target = 5)
  )
  set.seed(22)
  res <- memoised(nested_tune_grid(
    wf,
    folds,
    grid = g,
    metrics = ms,
    param_info = p,
    select = rule
  ))

  # The refusal comes before the inner run is built: the tuner is mocked to
  # a sentinel, which a refusal after that point would raise instead.
  testthat::local_mocked_bindings(
    run_tuner = function(...) {
      rlang::abort("tuning began", class = "nestedtune_sentinel")
    }
  )
  expect_error(nested_final_fit(wf, res), class = "nestedtune_sentinel")
  mask_desirability2()
  cnd <- rlang::catch_cnd(nested_final_fit(wf, res), classes = "error")
  expect_false(inherits(cnd, "nestedtune_sentinel"))
  expect_desirability2_refusal(cnd, "nested_final_fit")
})
