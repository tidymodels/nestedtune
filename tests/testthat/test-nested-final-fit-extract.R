# The named accessors onto what selection saw (AC1, AC2, AC3).
#
# Oracle provenance: none is claimed here and none is owed. These accessors
# produce no numeric result of their own -- one returns a stored object
# untouched, the other delegates to `scored_candidates()`, whose derivation M21
# oracle-verified against a hand-run `tune_grid()` (O3) and a data-frame
# invariant (O4). What is asserted below is the contract, not the arithmetic.

final_for_extract <- function() {
  d <- make_reg_data()
  wf <- det_workflow(d)
  res <- final_results(d)
  set.seed(21)
  memoised(nested_final_fit(wf, res))
}

test_that("the tuning-run accessor returns the stored run, unreduced", {
  skip_if_no_engines()

  final <- final_for_extract()

  expect_identical(extract_tune_results(final), final$tuning)

  # The leg that carries the weight. `expect_identical()` above compares the
  # accessor against the slot it reads, so it cannot tell a live tune_results
  # from a reduced one -- reduce the storage and both sides reduce together.
  # This asks the returned object to behave like tune's own, which a summary
  # or a stripped copy would not.
  extracted <- extract_tune_results(final)
  expect_s3_class(extracted, "tune_results")
  metrics <- tune::collect_metrics(extracted)
  expect_s3_class(metrics, "data.frame")
  expect_gt(nrow(metrics), 0L)
})

test_that("the candidate accessor reports the candidates that scored", {
  skip_if_no_engines()

  final <- final_for_extract()
  cand <- extract_scored_candidates(final)

  # det_grid() is data.frame(num_comp = 1:3) on a four-predictor recipe, so
  # every candidate is reachable and every one of them scores. The right answer
  # is therefore known before the run: three rows, those three values.
  expect_s3_class(cand, "tbl_df")
  expect_identical(nrow(cand), nrow(det_grid()))
  expect_setequal(cand$num_comp, det_grid()$num_comp)

  # D-023: the same shape a fold's candidate set derived from `.inner_metrics`
  # carries, `.config` included, so the
  # two records of one thing can be compared without translating between them.
  expect_true(".config" %in% names(cand))
  expect_setequal(names(cand), c("num_comp", ".config"))
})

test_that("the candidate accessor holds up past nine candidates", {
  skip_if_no_engines()

  # tune zero-pads `.config` from ten candidates on ("pre01_" rather than
  # "pre1_"), and `scored_candidates()` orders by that label. Below ten the
  # padding never engages, so a fixture that stops at three cannot show whether
  # ordering survives the change -- which is the case a lexical sort of an
  # unpadded label would get wrong.
  d <- make_reg_data()
  folds <- final_nested(d)
  wf <- cont_workflow(d)
  grid <- data.frame(threshold = seq(0.05, 0.95, length.out = 11L))

  set.seed(4)
  res <- memoised(nested_tune_grid(
    wf,
    folds,
    grid = grid,
    metrics = reg_metrics()
  ))

  set.seed(4)
  final <- memoised(nested_final_fit(wf, res))
  cand <- extract_scored_candidates(final)

  expect_identical(nrow(cand), nrow(grid))
  expect_setequal(cand$threshold, grid$threshold)
  expect_true(any(grepl("^pre1[0-9]_", cand$.config)))
})

test_that("what the accessors return agrees with what the loop records", {
  skip_if_no_engines()

  # The `@return` promises a reader they can compare this table against a
  # fold's candidate set directly. That promise is only worth making if the two
  # really are the same shape, which nothing above checks -- both assertions so
  # far read the accessor alone.
  d <- make_reg_data()
  wf <- det_workflow(d)
  res <- final_results(d)

  set.seed(21)
  final <- memoised(nested_final_fit(wf, res))

  from_fit <- extract_scored_candidates(final)
  from_loop <- candidate_set(res$.inner_metrics[[1L]])

  expect_identical(names(from_fit), names(from_loop))

  # Names alone cannot fail here: both sides come from `scored_candidates()`
  # over the same deterministic grid, so they agree by construction. The plan
  # gate's recorded falsifier for this milestone's shape choice was "the
  # accessor and the fold's candidate set disagreeing on a run where both are
  # defined", and disagreement in VALUES is what that names -- so the values
  # are what has to be compared.
  expect_setequal(from_fit$num_comp, from_loop$num_comp)
  expect_setequal(from_fit$.config, from_loop$.config)
})

test_that("a survival fit's candidates carry no evaluation-time column", {
  skip_if_no_censored()

  # A dynamic survival metric is scored once per evaluation time, so the
  # run's own table has `.eval_time` and as many rows per candidate as there
  # are times. The accessor reports candidates, one row each, with the
  # per-metric columns -- `.eval_time` among them -- dropped (AC6).
  #
  # Two evaluation times draw tune's notice that the first is the one
  # selection uses -- once per fold and once at the final fit, the
  # documented behavior -- and that notice is not under test.
  data <- srv_data()
  workflow <- srv_workflow(data)
  res <- suppressWarnings(memoised(nested_tune_grid(
    workflow,
    srv_nested(data),
    grid = srv_grid(),
    metrics = srv_metrics(),
    eval_time = srv_eval_times()
  )))
  set.seed(11)
  final <- suppressWarnings(memoised(nested_final_fit(workflow, res)))

  scored <- tune::collect_metrics(extract_tune_results(final))
  expect_true(".eval_time" %in% names(scored))
  expect_identical(nrow(scored), nrow(srv_grid()) * length(srv_eval_times()))

  cand <- extract_scored_candidates(final)
  expect_setequal(names(cand), c("dist", ".config"))
  expect_identical(nrow(cand), nrow(srv_grid()))
  expect_setequal(cand$dist, srv_grid()$dist)
})

test_that("both accessors refuse an object they cannot answer for", {
  skip_if_no_engines()

  d <- make_reg_data()
  folds <- final_nested(d)
  wf <- det_workflow(d)
  set.seed(22)
  res <- memoised(nested_tune_grid(
    wf,
    folds,
    grid = det_grid(),
    metrics = reg_metrics()
  ))

  # A results object is the near miss worth firing: it is this package's own
  # class, it holds candidates, and it is the thing a user reaching for these
  # names is most likely to be holding by mistake.
  for (obj in list(res, list(a = 1), 1:3)) {
    expect_error(
      extract_tune_results(obj),
      class = "nestedtune_no_extract_method"
    )
    expect_error(
      extract_scored_candidates(obj),
      class = "nestedtune_no_extract_method"
    )
  }

  # R's bare dispatch failure names neither what it was handed nor what would
  # have answered, and never reaches the user here.
  expect_false(
    grepl(
      "applicable method",
      conditionMessage(rlang::catch_cnd(extract_tune_results(res)))
    )
  )
})

# The refusal names the object before anything in the dots. Before M56 the
# defaults checked their dots first, so `extract_tune_results(1, foo = 1)`
# complained of `foo` and said nothing of `1` (an `rlib_error_dots_nonempty`,
# measured 2026-09-03).
test_that("an object with no method is refused as such whatever rides in the dots", {
  for (fn in list(extract_tune_results, extract_scored_candidates)) {
    cnd <- rlang::catch_cnd(fn(1, foo = 1))
    expect_s3_class(cnd, "nestedtune_no_extract_method")
    expect_false(inherits(cnd, "rlib_error_dots_nonempty"))
  }

  # The passing control: the methods still refuse a stray argument, so the
  # dots check moved rather than went.
  skip_if_no_engines()
  final <- final_for_extract()
  expect_error(
    extract_tune_results(final, foo = 1),
    class = "rlib_error_dots_nonempty"
  )
  expect_error(
    extract_scored_candidates(final, foo = 1),
    class = "rlib_error_dots_nonempty"
  )
})

test_that("the refusals read the same for both accessors", {
  skip_if_no_engines()

  expect_snapshot(error = TRUE, {
    extract_tune_results(1:3)
    extract_scored_candidates(1:3)
  })
})

# M106 AC1: the final fit answers tune's and hardhat's extractors as the
# workflow it holds does. Each method hands its call to that workflow, so the
# reference is the same call made on `extract_workflow()` by hand.
test_that("the final fit answers the extractors as its workflow does", {
  skip_if_no_engines()

  final <- final_for_extract()
  wf <- extract_workflow(final)

  extractors <- list(
    extract_fit_parsnip = extract_fit_parsnip,
    extract_fit_engine = extract_fit_engine,
    extract_recipe = extract_recipe,
    extract_mold = extract_mold,
    extract_preprocessor = extract_preprocessor,
    extract_spec_parsnip = extract_spec_parsnip,
    outcome_names = outcome_names
  )
  for (nm in names(extractors)) {
    fn <- extractors[[nm]]
    expect_identical(fn(final), fn(wf), label = nm)
  }

  # The fixture is recipe-based, so the recipe reached is a trained one; the
  # untrained one differs from it and arrives only through `estimated`.
  expect_true(recipes::fully_trained(extract_recipe(final)))
  expect_identical(
    extract_recipe(final, estimated = FALSE),
    extract_recipe(wf, estimated = FALSE)
  )
  expect_false(recipes::fully_trained(extract_recipe(final, estimated = FALSE)))
})

# The extractors' workflow methods, `extract_recipe()` aside, drop an
# argument they do not know, so passing one on would be a silent no-op.
# These methods refuse it, as augment.nested_final_fit() does.
test_that("the workflow extractors refuse a stray argument", {
  skip_if_no_engines()

  final <- final_for_extract()
  for (fn in list(
    extract_fit_parsnip,
    extract_fit_engine,
    extract_recipe,
    extract_mold,
    extract_preprocessor,
    extract_spec_parsnip,
    outcome_names
  )) {
    expect_error(fn(final, nonesuch = 1), class = "rlib_error_dots_nonempty")
  }
})

# The parameter set a final fit's tuning run searched. The trained workflow
# holds no `tune()` placeholder, so handing the call to it, as the extractors
# above do, would return an empty set. Each expected value below is built
# from the orchestrator call's inputs, never read off the final fit. The
# expected sets are built with `tune::extract_parameter_set_dials()`, which is
# hardhat's generic re-exported, because hardhat is not declared in
# DESCRIPTION.
test_that("the final fit answers extract_parameter_set_dials() from its run", {
  skip_if_no_engines()

  d <- make_reg_data()
  wf <- det_workflow(d)

  # (b) No `param_info`, and `num_comp` has a known range: tune stores the
  # untrained workflow's own set.
  final <- final_for_extract()
  expect_identical(
    extract_parameter_set_dials(final),
    tune::extract_parameter_set_dials(wf)
  )

  # (a) A `param_info` whose range, [1, 3], is narrower than the workflow's
  # [1, 4]: tune stores that object, so the result is it and not the
  # workflow's set.
  pinfo <- stats::update(
    tune::extract_parameter_set_dials(wf),
    num_comp = dials::num_comp(c(1L, 3L))
  )
  folds <- final_nested(d)
  set.seed(22)
  res <- memoised(nested_tune_grid(
    wf,
    folds,
    grid = det_grid(),
    metrics = reg_metrics(),
    param_info = pinfo
  ))
  set.seed(21)
  final_pinfo <- memoised(nested_final_fit(wf, res))
  expect_identical(extract_parameter_set_dials(final_pinfo), pinfo)
  expect_false(identical(pinfo, tune::extract_parameter_set_dials(wf)))
})

# ranger's `mtry` has an upper bound that is unknown until the predictors are
# seen. tune fills it in for a grid it builds from a size, and leaves it
# unknown for a grid given as a data frame, which it does not need to build.
mtry_workflow <- function() {
  spec <- parsnip::set_mode(
    parsnip::set_engine(
      parsnip::rand_forest(mtry = tune::tune(), trees = 25),
      "ranger",
      num.threads = 1
    ),
    "regression"
  )
  workflows::workflow(y ~ x1 + x2 + x3 + x4, spec)
}

mtry_final <- function(grid) {
  d <- make_reg_data()
  wf <- mtry_workflow()
  folds <- final_nested(d)
  set.seed(22)
  res <- memoised(nested_tune_grid(
    wf,
    folds,
    grid = grid,
    metrics = reg_metrics()
  ))
  set.seed(21)
  memoised(nested_final_fit(wf, res))
}

test_that("a numeric grid gives the set finalized on the full data", {
  skip_if_no_engines(stochastic = TRUE)

  d <- make_reg_data()
  untrained <- tune::extract_parameter_set_dials(mtry_workflow())
  expected <- dials::finalize(untrained, d[c("x1", "x2", "x3", "x4")])

  # (c) The control: the expected set differs from the untrained one, so the
  # identity below shows the finalize step and not a stored copy.
  expect_true(dials::has_unknowns(untrained$object[[1]]))
  expect_false(dials::has_unknowns(expected$object[[1]]))

  final <- suppressMessages(mtry_final(grid = 3))
  expect_identical(extract_parameter_set_dials(final), expected)
})

test_that("a data-frame grid gives the set with the range still unknown", {
  skip_if_no_engines(stochastic = TRUE)

  # (d) The help states this case.
  final <- mtry_final(grid = data.frame(mtry = c(1L, 3L)))
  result <- extract_parameter_set_dials(final)
  expect_identical(
    result,
    tune::extract_parameter_set_dials(mtry_workflow())
  )
  expect_true(dials::has_unknowns(result$object[[1]]))
})

test_that("extract_parameter_set_dials() refuses a fit with no run, and dots", {
  skip_if_no_engines()

  d <- make_reg_data()
  fixed <- nested_final_fit(fixed_workflow(d), fit_resamples_results(d))
  expect_error(
    extract_parameter_set_dials(fixed),
    class = "nestedtune_no_tuning_run"
  )

  final <- final_for_extract()
  expect_error(
    extract_parameter_set_dials(final, nonesuch = 1),
    class = "rlib_error_dots_nonempty"
  )
})

test_that("extract_parameter_set_dials() is re-exported", {
  skip_if_no_engines()

  # The data is built before the workflow, as `final_for_extract()` builds
  # it. `step_pca()` draws its id from the stream, and a nested
  # `det_workflow(make_reg_data())` draws it before the data's own seed.
  d <- make_reg_data()
  wf <- det_workflow(d)
  final <- final_for_extract()
  expect_identical(
    nestedtune::extract_parameter_set_dials(final),
    tune::extract_parameter_set_dials(wf)
  )
})
