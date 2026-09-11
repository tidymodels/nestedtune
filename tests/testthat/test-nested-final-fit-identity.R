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

# AC2: the refusal, one probe per axis, on a fit_resamples, a tune_grid and
# a tune_bayes record, and a formula record for the axes a recipe record
# cannot carry (the preprocessor's formula, the model's mode).
#
# Each probe asserts which failure it is: the mismatch class, the part the
# message names, the user's call, the caller's generator state unchanged,
# and nothing fitted -- the worker is replaced with one that raises a class
# of its own, so a probe that reached it would fail on the class and not
# merely on a count (the passing control at the end of the block shows that
# stand-in firing).

expect_mismatch <- function(object, results, part) {
  # Forced before the snapshot: a probe's recipe draws its step id from the
  # stream, and that draw is the probe's, not the final fit's.
  force(object)
  force(results)
  testthat::local_mocked_bindings(
    final_fit_worker = function(...) {
      rlang::abort("the worker was reached", class = "nestedtune_test_fitted")
    }
  )
  set.seed(1)
  before <- .Random.seed
  cnd <- rlang::catch_cnd(nested_final_fit(object, results))
  testthat::expect_s3_class(cnd, "nestedtune_workflow_mismatch")
  testthat::expect_match(conditionMessage(cnd), part, fixed = TRUE)
  testthat::expect_match(conditionMessage(cnd), "`object`", fixed = TRUE)
  testthat::expect_identical(
    conditionCall(cnd)[[1]],
    as.name("nested_final_fit")
  )
  testthat::expect_identical(.Random.seed, before)
  invisible(cnd)
}

# The recipe the fixed fixture carries, and the two Bayesian steps, each
# rebuilt here so a probe can vary one thing about it.
base_recipe <- function(d) recipes::recipe(y ~ x1 + x2 + x3 + x4, data = d)

pca_workflow <- function(
  d,
  selector = recipes::all_predictors(),
  num_comp = 2L,
  model = parsnip::linear_reg()
) {
  rec <- recipes::step_pca(
    base_recipe(d),
    {{ selector }},
    num_comp = num_comp,
    id = "pca_fixed"
  )
  workflows::workflow(rec, model)
}

ns_workflow <- function(d, first = "x1", second = "x2", df2 = tune::tune("df2")) {
  rec <- recipes::step_ns(
    recipes::step_ns(base_recipe(d), !!rlang::sym(first), deg_free = tune::tune("df1")),
    !!rlang::sym(second),
    deg_free = df2
  )
  workflows::workflow(rec, parsnip::linear_reg())
}

# Two records through the plain resampling orchestrator for the axes the
# recipe records cannot carry: a formula record on lm with an engine
# argument (the formula and engine-argument-removed probes), and a formula
# record on parsnip's own null model, which has two modes and needs no
# package beyond parsnip (the mode probe).
formula_workflow <- function(
  formula = y ~ x1 + x2 + x3 + x4,
  spec = parsnip::set_engine(parsnip::linear_reg(), "lm", model = FALSE)
) {
  workflows::workflow(formula, spec)
}

formula_results <- function(d, seed = 32) {
  wf <- formula_workflow()
  folds <- final_nested(d)
  ms <- reg_metrics()
  set.seed(seed)
  memoised(nested_fit_resamples(wf, folds, metrics = ms))
}

null_results <- function(d, seed = 34) {
  wf <- formula_workflow(spec = parsnip::null_model(mode = "regression"))
  folds <- final_nested(d)
  ms <- reg_metrics()
  set.seed(seed)
  memoised(nested_fit_resamples(wf, folds, metrics = ms))
}

test_that("AC2: the model axes are refused on the three records", {
  skip_if_no_bayes_fixture()
  d <- make_reg_data()
  fr <- fit_resamples_results(d)
  grid <- final_results(d)
  bayes <- bayes_final_results(d)
  formula <- formula_results(d)
  null <- null_results(d)

  # A different model type, on each record. The package check runs ahead of
  # the identity check, so the other type is one parsnip serves alone.
  other_type <- parsnip::null_model(mode = "regression")
  expect_mismatch(
    pca_workflow(d, model = other_type),
    fr,
    "The model type differs: recorded \"linear_reg\", given \"null_model\""
  )
  expect_mismatch(
    workflows::update_model(det_workflow(d), other_type),
    grid,
    "The model type differs"
  )
  expect_mismatch(
    workflows::update_model(bayes_workflow(d), other_type),
    bayes,
    "The model type differs"
  )

  # A different engine.
  expect_mismatch(
    workflows::update_model(det_workflow(d), parsnip::linear_reg(engine = "glm")),
    grid,
    "The model's engine differs: recorded \"lm\", given \"glm\""
  )

  # A different mode, on the record whose model has two.
  expect_mismatch(
    formula_workflow(spec = parsnip::null_model(mode = "classification")),
    null,
    "The model's mode differs: recorded \"regression\", given \"classification\""
  )

  # A different main-argument value.
  expect_mismatch(
    pca_workflow(d, model = parsnip::linear_reg(penalty = 1)),
    fr,
    "The model's argument `penalty` differs: recorded \"NULL\", given \"1\""
  )

  # An engine argument added, and one removed.
  expect_mismatch(
    workflows::update_model(
      bayes_workflow(d),
      parsnip::set_engine(parsnip::linear_reg(), "lm", model = FALSE)
    ),
    bayes,
    "The model's engine arguments differ: \"model\" is given and not recorded"
  )
  expect_mismatch(
    formula_workflow(spec = parsnip::set_engine(parsnip::linear_reg(), "lm")),
    formula,
    "The model's engine arguments differ: \"model\" is recorded and not given"
  )

  # A tune() marker on one side and a value on the other, where no earlier
  # check reads the marker: the Bayesian record takes no grid, and its
  # tuner selects, so the identity check is the one that sees it.
  expect_mismatch(
    ns_workflow(d, df2 = 3L),
    bayes,
    "The recipe's step 2 (step_ns) setting `deg_free` differs: recorded \"tune(\\\"df2\\\")\", given \"3L\""
  )
})

test_that("AC2: the preprocessor axes are refused on the three records", {
  skip_if_no_bayes_fixture()
  d <- make_reg_data()
  fr <- fit_resamples_results(d)
  grid <- final_results(d)
  bayes <- bayes_final_results(d)
  formula <- formula_results(d)

  # A formula, and a variables selection, in place of the recipe.
  expect_mismatch(
    workflows::workflow(y ~ x1 + x2 + x3 + x4, parsnip::linear_reg()),
    fr,
    "The preprocessor differs: a recipe was recorded, and a formula was given"
  )
  expect_mismatch(
    workflows::workflow(
      workflows::workflow_variables(y, c(x1, x2, x3, x4)),
      parsnip::linear_reg()
    ),
    bayes,
    "The preprocessor differs: a recipe was recorded, and a variables selection was given"
  )

  # A different formula.
  expect_mismatch(
    formula_workflow(formula = y ~ x1 + x2),
    formula,
    "The formula differs: recorded \"y ~ x1 + x2 + x3 + x4\", given \"y ~ x1 + x2\""
  )

  # A step added, one removed, and two reordered.
  added <- workflows::update_recipe(
    pca_workflow(d),
    recipes::step_center(
      workflows::extract_preprocessor(pca_workflow(d)),
      recipes::all_predictors()
    )
  )
  expect_mismatch(
    added,
    fr,
    "The recipe's step count differs: 1 recorded, 2 given"
  )
  removed <- workflows::workflow(
    recipes::step_ns(base_recipe(d), x1, deg_free = tune::tune("df1")),
    parsnip::linear_reg()
  )
  expect_mismatch(
    removed,
    bayes,
    "The recipe's step count differs: 2 recorded, 1 given"
  )
  reordered <- workflows::workflow(
    recipes::step_ns(
      recipes::step_ns(base_recipe(d), x2, deg_free = tune::tune("df2")),
      x1,
      deg_free = tune::tune("df1")
    ),
    parsnip::linear_reg()
  )
  expect_mismatch(
    reordered,
    bayes,
    "The recipe's step 1 (step_ns) selector differs: recorded \"x1\", given \"x2\""
  )

  # A step with a different selector, and one with a different setting;
  # the tuned record keeps its marker, so the grid check passes and the
  # identity check is the one that refuses.
  expect_mismatch(
    pca_workflow(d, selector = recipes::all_numeric_predictors()),
    fr,
    "The recipe's step 1 (step_pca) selector differs"
  )
  expect_mismatch(
    pca_workflow(d, num_comp = 3L),
    fr,
    "The recipe's step 1 (step_pca) setting `num_comp` differs: recorded \"2L\", given \"3L\""
  )
  tuned_other_selector <- workflows::workflow(
    recipes::step_pca(
      base_recipe(d),
      recipes::all_numeric_predictors(),
      num_comp = tune::tune()
    ),
    parsnip::linear_reg()
  )
  expect_mismatch(
    tuned_other_selector,
    grid,
    "The recipe's step 1 (step_pca) selector differs"
  )

  # The passing control for the stand-in worker: a matching workflow gets
  # past every check and reaches it, under the stand-in's own class.
  testthat::local_mocked_bindings(
    final_fit_worker = function(...) {
      rlang::abort("the worker was reached", class = "nestedtune_test_fitted")
    }
  )
  expect_error(
    nested_final_fit(fixed_workflow(d), fr),
    class = "nestedtune_test_fitted"
  )
})

test_that("AC2: the identity check runs after the record, grid and marker checks", {
  skip_if_no_engines()
  d <- make_reg_data()
  fr <- fit_resamples_results(d)
  grid <- final_results(d)

  # A workflow tuning a parameter the recorded grid has no column for is
  # refused by the grid check, which names the column, and never reaches
  # the identity check.
  cnd <- rlang::catch_cnd(nested_final_fit(cont_workflow(d), grid))
  expect_false(inherits(cnd, "nestedtune_workflow_mismatch"))
  expect_match(conditionMessage(cnd), "recorded grid")

  # A marked workflow on a record that selected nothing is refused by the
  # marker check.
  expect_error(
    nested_final_fit(det_workflow(d), fr),
    class = "nestedtune_tuned_workflow"
  )

  # A record with no entry to compare against is refused by the record
  # check, whatever the workflow.
  stripped <- fr
  attr(stripped, "procedure")$workflow <- NULL
  expect_error(
    nested_final_fit(det_workflow(d), stripped),
    class = "nestedtune_bad_results"
  )
})

# AC3: a workflow rebuilt from the same code passes, and fits the same.

test_that("AC3: a rebuilt workflow is accepted and gives the same fit", {
  skip_if_no_engines()
  d <- make_reg_data()

  # A model with a constructor argument (lm ignores `penalty`; the record
  # holds it all the same) built the two ways AC3 names.
  in_call <- function() parsnip::linear_reg(engine = "lm", penalty = 1)
  assembled <- function() {
    parsnip::set_args(
      parsnip::set_engine(parsnip::linear_reg(), "lm"),
      penalty = 1
    )
  }
  fixed_rec <- function() {
    recipes::step_pca(base_recipe(d), recipes::all_predictors(), num_comp = 2L)
  }
  tuned_rec <- function() {
    recipes::step_pca(
      base_recipe(d),
      recipes::all_predictors(),
      num_comp = tune::tune()
    )
  }
  folds <- final_nested(d)
  ms <- reg_metrics()

  orig_fixed <- workflows::workflow(fixed_rec(), in_call())
  set.seed(33)
  fr <- memoised(nested_fit_resamples(orig_fixed, folds, metrics = ms))
  orig_tuned <- workflows::workflow(tuned_rec(), in_call())
  grid <- final_results(d, wf = orig_tuned)

  cases <- list(
    fit_resamples = list(
      orig = orig_fixed,
      res = fr,
      rebuilt = workflows::workflow(fixed_rec(), in_call()),
      assembled = workflows::workflow(fixed_rec(), assembled())
    ),
    tune_grid = list(
      orig = orig_tuned,
      res = grid,
      rebuilt = workflows::workflow(tuned_rec(), in_call()),
      assembled = workflows::workflow(tuned_rec(), assembled())
    )
  )
  coefs <- function(fit) {
    coef(workflows::extract_fit_parsnip(extract_workflow(fit))$fit)
  }
  for (case in cases) {
    # The rebuilds are not the original object: a drawn step id and a
    # fresh quosure frame each time.
    expect_false(identical(case$orig, case$rebuilt))
    expect_false(identical(case$orig, case$assembled))
    expect_identical(
      check_workflow_identity(case$rebuilt, extract_procedure(case$res)$workflow),
      case$rebuilt
    )
    expect_identical(
      check_workflow_identity(case$assembled, extract_procedure(case$res)$workflow),
      case$assembled
    )

    set.seed(7)
    from_orig <- nested_final_fit(case$orig, case$res)
    set.seed(7)
    from_rebuilt <- nested_final_fit(case$rebuilt, case$res)
    set.seed(7)
    from_assembled <- nested_final_fit(case$assembled, case$res)
    frame <- d[1:10, ]
    expect_identical(
      predict(from_rebuilt, new_data = frame),
      predict(from_orig, new_data = frame)
    )
    expect_identical(
      predict(from_assembled, new_data = frame),
      predict(from_orig, new_data = frame)
    )
    expect_identical(coefs(from_rebuilt), coefs(from_orig))
    expect_identical(coefs(from_assembled), coefs(from_orig))
  }
})

# AC4: a record from before the entry existed is refused as one from an
# earlier version, and the set path still fits.

test_that("AC4: a record with no workflow entry is refused before the identity check", {
  skip_if_no_engines()
  d <- make_reg_data()
  wf <- fixed_workflow(d)
  res <- fit_resamples_results(d)
  attr(res, "procedure")$workflow <- NULL
  expect_false("workflow" %in% names(extract_procedure(res)))

  set.seed(1)
  before <- .Random.seed
  cnd <- rlang::catch_cnd(nested_final_fit(wf, res))
  expect_s3_class(cnd, "nestedtune_bad_results")
  expect_match(conditionMessage(cnd), "no record of the workflow")
  expect_match(conditionMessage(cnd), "earlier version")
  expect_match(conditionMessage(cnd), "not migrated")
  expect_identical(conditionCall(cnd)[[1]], as.name("nested_final_fit"))
  expect_identical(.Random.seed, before)

  # A record missing both late entries names both, in one sentence.
  both <- final_results(d)
  attr(both, "procedure")$workflow <- NULL
  attr(both, "procedure")$select <- NULL
  cnd <- rlang::catch_cnd(nested_final_fit(det_workflow(d), both))
  expect_s3_class(cnd, "nestedtune_bad_results")
  expect_match(
    conditionMessage(cnd),
    "no selection rule and record of the workflow to re-run"
  )
  expect_match(conditionMessage(cnd), "were recorded")
})

test_that("AC4: the final fit on a set with an id still fits", {
  skip_if_no_wset_fixture("nested_fit_resamples")
  set <- wset_results("nested_fit_resamples")
  set.seed(3)
  fit <- nested_final_fit(set, id = "baseline")
  expect_s3_class(fit, "nested_final_fit")
  expect_identical(
    extract_procedure(fit)$workflow,
    workflow_identity(extract_workflow(set, "baseline"))
  )
})
