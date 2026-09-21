# A parsnip model specification with a formula or a recipe as the
# orchestrators' input (M107, D-069). Each export is a generic on `object`:
# the `model_spec` method takes `(object, preprocessor, resamples, ...)` in
# tune's order, wraps the two in `workflows::workflow(preprocessor, object)`,
# and calls the generic again, so the run is the workflow path's own.

ORCHESTRATORS <- c(
  "nested_tune_grid",
  "nested_tune_bayes",
  "nested_tune_race_anova",
  "nested_tune_race_win_loss",
  "nested_tune_sim_anneal",
  "nested_fit_resamples"
)

# Whether the packages an orchestrator's tuner needs are installed, read off
# the package's registry. On a workflow, the racers and the annealer refuse a
# missing finetune before anything else, so a check that runs after that one
# is only reachable where these are present.
tuner_ready <- function(fn) {
  key <- sub("^nested_", "", fn)
  requires <- tuner_registry[[key]]$requires
  all(vapply(requires, rlang::is_installed, logical(1)))
}

bare_spec <- function() parsnip::linear_reg()

# The export called by its own name, so a condition's call is the export's
# and not a local alias's.
call_by_name <- function(fn, ...) {
  rlang::eval_bare(rlang::call2(fn, ...), parent.frame())
}

# The refusals ----------------------------------------------------------
#
# None of these reaches a design or a fit, so they need no engine: a stand-in
# `resamples` is never judged, since each refusal fires before
# `check_nested()`. Each asserts the class, and that the condition names the
# export the user called rather than a method.

test_that("AC4: a model specification with no preprocessor is refused by class", {
  for (fn in ORCHESTRATORS) {
    f <- function(...) call_by_name(fn, ...)
    cnd <- rlang::catch_cnd(f(bare_spec(), resamples = 1))
    expect_s3_class(cnd, "nestedtune_bad_preprocessor")
    expect_match(conditionMessage(cnd), "`preprocessor` is missing")
    expect_identical(rlang::call_name(conditionCall(cnd)), fn)
  }
})

test_that("AC4: a preprocessor that is neither a formula nor a recipe is refused by class", {
  # A number, a design handed where the preprocessor goes, and variables,
  # which tune's own method refuses and which only a workflow takes.
  wrong <- list(
    number = 1,
    design = rsample::nested_cv(
      data.frame(x = 1:12, y = 1:12),
      outside = rsample::vfold_cv(v = 2),
      inside = rsample::vfold_cv(v = 2)
    ),
    variables = workflows::workflow_variables(y, x)
  )
  hints <- c(
    number = NA,
    design = "third argument",
    variables = "add_variables"
  )
  for (fn in ORCHESTRATORS) {
    f <- function(...) call_by_name(fn, ...)
    for (nm in names(wrong)) {
      cnd <- rlang::catch_cnd(f(bare_spec(), wrong[[nm]], 1))
      expect_s3_class(cnd, "nestedtune_bad_preprocessor")
      expect_match(conditionMessage(cnd), "must be a formula or a recipe")
      if (!is.na(hints[[nm]])) {
        expect_match(conditionMessage(cnd), hints[[nm]])
      }
      expect_identical(rlang::call_name(conditionCall(cnd)), fn)
    }
  }
})

test_that("AC4: a preprocessor beside a workflow is refused by class, by name or by position", {
  wf <- workflows::workflow(y ~ x, bare_spec())
  for (fn in ORCHESTRATORS) {
    if (!tuner_ready(fn)) {
      next
    }
    f <- function(...) call_by_name(fn, ...)
    by_name <- rlang::catch_cnd(f(wf, preprocessor = y ~ x, resamples = 1))
    expect_s3_class(by_name, "nestedtune_preprocessor_with_workflow")
    expect_match(
      conditionMessage(by_name),
      "A workflow carries its own preprocessor"
    )
    expect_match(conditionMessage(by_name), "`preprocessor` beside a workflow")
    expect_identical(rlang::call_name(conditionCall(by_name)), fn)

    # In tune's order beside a workflow, the formula lands in `resamples`.
    by_position <- rlang::catch_cnd(f(wf, y ~ x, 1))
    expect_s3_class(by_position, "nestedtune_preprocessor_with_workflow")
    expect_match(conditionMessage(by_position), "where `resamples` goes")
    expect_identical(rlang::call_name(conditionCall(by_position)), fn)

    # The control: the same workflow with nothing beside it passes this
    # check and is refused by a later one.
    control <- rlang::catch_cnd(f(wf, resamples = 1))
    expect_s3_class(control, "error")
    expect_false(inherits(control, "nestedtune_preprocessor_with_workflow"))
  }
})

test_that("an object that is neither a workflow nor a model specification is refused", {
  for (fn in ORCHESTRATORS) {
    f <- function(...) call_by_name(fn, ...)
    cnd <- rlang::catch_cnd(f(data.frame(x = 1), 1))
    expect_s3_class(cnd, "rlang_error")
    expect_match(
      conditionMessage(cnd),
      "must be a <workflow> or a parsnip model specification"
    )
    expect_identical(rlang::call_name(conditionCall(cnd)), fn)
  }
})

test_that("AC4: nested_final_fit() given a bare model specification names workflows::workflow()", {
  cnd <- rlang::catch_cnd(nested_final_fit(bare_spec(), 1))
  expect_s3_class(cnd, "rlang_error")
  expect_match(conditionMessage(cnd), "must be a <workflow>")
  expect_match(
    conditionMessage(cnd),
    "workflows::workflow(preprocessor, spec)",
    fixed = TRUE
  )
  expect_identical(rlang::call_name(conditionCall(cnd)), "nested_final_fit")
})

# The identities ----------------------------------------------------------
#
# The spec route against the workflow route, one direct call each under one
# entry seed (never through `memoised()`, so the identity is between two
# executions). Every argument, the preprocessor above all, is built once
# before the seed and handed to both calls: a recipe step draws its id from
# the stream when it is built, so a recipe built twice would differ in its id.
# ranger draws its fits from the stream the fold seeds start, so the identity
# also holds the seeds to the same values on both routes.

spec_routes <- function(fn, spec, preprocessor, folds, ...) {
  f <- get(fn)
  wf <- workflows::workflow(preprocessor, spec)
  set.seed(107)
  via_spec <- f(spec, preprocessor, folds, ...)
  set.seed(107)
  via_workflow <- f(wf, folds, ...)
  list(spec = via_spec, workflow = via_workflow)
}

expect_same_run <- function(routes, selections = TRUE) {
  # Both routes completing is what keeps the identity from holding between
  # two all-failed runs.
  expect_true(all(routes$spec$.completed))
  expect_identical(
    collect_metrics(routes$spec, summarize = FALSE),
    collect_metrics(routes$workflow, summarize = FALSE)
  )
  if (selections) {
    expect_identical(
      collect_selections(routes$spec),
      collect_selections(routes$workflow)
    )
  }
  expect_identical(
    extract_procedure(routes$spec)$workflow,
    extract_procedure(routes$workflow)$workflow
  )
}

stoch_spec <- function() {
  parsnip::set_mode(
    parsnip::set_engine(
      parsnip::rand_forest(min_n = tune::tune(), trees = 25),
      "ranger",
      num.threads = 1
    ),
    "regression"
  )
}

fixed_stoch_spec <- function() {
  parsnip::set_mode(
    parsnip::set_engine(
      parsnip::rand_forest(min_n = 10L, trees = 25),
      "ranger",
      num.threads = 1
    ),
    "regression"
  )
}

reg_formula <- function() y ~ x1 + x2 + x3 + x4

test_that("AC1: nested_tune_grid() on a spec and a formula is the workflow run", {
  skip_if_no_engines(stochastic = TRUE)
  d <- make_reg_data()
  folds <- det_nested(d)
  f <- reg_formula()
  ms <- reg_metrics()
  routes <- spec_routes(
    "nested_tune_grid",
    stoch_spec(),
    f,
    folds,
    grid = stoch_grid(),
    metrics = ms
  )
  expect_same_run(routes)
})

test_that("AC1: nested_tune_bayes() on a spec and a formula is the workflow run", {
  skip_if_no_bayes_fixture(stochastic = TRUE)
  d <- make_reg_data()
  folds <- det_nested(d)
  f <- reg_formula()
  spec <- stoch_spec()
  p <- bayes_stoch_param_info(workflows::workflow(f, spec))
  ms <- reg_metrics()
  routes <- spec_routes(
    "nested_tune_bayes",
    spec,
    f,
    folds,
    iter = 2,
    initial = 3,
    param_info = p,
    metrics = ms
  )
  expect_same_run(routes)
})

test_that("AC1: the two racers on a spec and a formula are the workflow run", {
  for (fn in c("nested_tune_race_anova", "nested_tune_race_win_loss")) {
    skip_if_no_race_fixture(sub("^nested_", "", fn), stochastic = TRUE)
    d <- make_reg_data()
    folds <- det_nested(d)
    f <- reg_formula()
    ms <- reg_metrics()
    ctrl <- race_control()
    routes <- spec_routes(
      fn,
      stoch_spec(),
      f,
      folds,
      grid = stoch_grid(),
      metrics = ms,
      control = ctrl
    )
    expect_same_run(routes)
  }
})

test_that("AC1: nested_tune_sim_anneal() on a spec and a formula is the workflow run", {
  skip_if_no_anneal_fixture(stochastic = TRUE)
  skip_if_not_installed("dials")
  d <- make_reg_data()
  folds <- det_nested(d)
  f <- reg_formula()
  spec <- stoch_spec()
  p <- bayes_stoch_param_info(workflows::workflow(f, spec))
  ms <- reg_metrics()
  routes <- spec_routes(
    "nested_tune_sim_anneal",
    spec,
    f,
    folds,
    iter = 2,
    initial = 3,
    param_info = p,
    metrics = ms
  )
  expect_same_run(routes)
})

test_that("AC1: nested_fit_resamples() on a spec and a formula is the workflow run", {
  skip_if_no_engines(stochastic = TRUE)
  d <- make_reg_data()
  folds <- det_nested(d)
  f <- reg_formula()
  ms <- reg_metrics()
  routes <- spec_routes(
    "nested_fit_resamples",
    fixed_stoch_spec(),
    f,
    folds,
    metrics = ms
  )
  expect_same_run(routes, selections = FALSE)
  expect_identical(
    collect_metrics(routes$spec),
    collect_metrics(routes$workflow)
  )
})

# The recipe cases (AC2). The step id is written out, and the recipe is
# built once, so both routes carry the same one. The grid case runs on
# `final_nested()`, whose literal inner specification survives the final
# fit's re-run, so AC3 below builds its final fits from these two results.

pca_recipe <- function(data, num_comp = tune::tune()) {
  recipes::step_pca(
    recipes::recipe(y ~ x1 + x2 + x3 + x4, data = data),
    recipes::all_predictors(),
    num_comp = num_comp,
    id = "pca_spec_input"
  )
}

recipe_grid_routes <- function() {
  d <- make_reg_data()
  folds <- final_nested(d)
  rec <- pca_recipe(d)
  ms <- reg_metrics()
  list(
    data = d,
    recipe = rec,
    routes = spec_routes(
      "nested_tune_grid",
      bare_spec(),
      rec,
      folds,
      grid = det_grid(),
      metrics = ms
    )
  )
}

test_that("AC2: nested_tune_grid() on a spec and a recipe is the workflow run", {
  skip_if_no_engines()
  run <- recipe_grid_routes()
  expect_same_run(run$routes)
})

# The final fit takes a workflow (D-041), so a result built from a spec is
# finalized on `workflow(preprocessor, spec)`, the workflow the spec route
# recorded. The identity check refuses a workflow that differs from the
# recorded one with `nestedtune_workflow_mismatch`, so a fit that returns at
# all has passed it; the class is asserted absent too, and the control shows
# the same check refusing a workflow with another recipe.
test_that("AC3: a spec route's result takes its final fit on the wrapped workflow, as the workflow route's does", {
  skip_if_no_engines()
  run <- recipe_grid_routes()
  wf <- workflows::workflow(run$recipe, bare_spec())

  set.seed(3)
  from_spec <- rlang::catch_cnd(
    nested_final_fit(wf, run$routes$spec),
    classes = "nestedtune_workflow_mismatch"
  )
  expect_null(from_spec)
  set.seed(3)
  from_spec <- nested_final_fit(wf, run$routes$spec)
  set.seed(3)
  from_workflow <- nested_final_fit(wf, run$routes$workflow)

  expect_identical(
    predict(from_spec, new_data = run$data),
    predict(from_workflow, new_data = run$data)
  )

  # The control: the check is live on this result, so a recipe over other
  # predictors, tuning the same parameter, is refused rather than fitted.
  other_recipe <- recipes::step_pca(
    recipes::recipe(y ~ x1 + x2 + x3, data = run$data),
    recipes::all_predictors(),
    num_comp = tune::tune(),
    id = "pca_spec_input"
  )
  other <- workflows::workflow(other_recipe, bare_spec())
  expect_error(
    nested_final_fit(other, run$routes$spec),
    class = "nestedtune_workflow_mismatch"
  )
})

test_that("AC2: nested_fit_resamples() on a spec and a recipe is the workflow run", {
  skip_if_no_engines()
  d <- make_reg_data()
  folds <- det_nested(d)
  rec <- pca_recipe(d, num_comp = 2L)
  ms <- reg_metrics()
  routes <- spec_routes(
    "nested_fit_resamples",
    bare_spec(),
    rec,
    folds,
    metrics = ms
  )
  expect_same_run(routes, selections = FALSE)
  expect_identical(
    collect_metrics(routes$spec),
    collect_metrics(routes$workflow)
  )
})
