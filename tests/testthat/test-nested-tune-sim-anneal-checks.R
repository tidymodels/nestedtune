# Every refusal `nested_tune_sim_anneal()` makes at entry, fired once. A
# provably wrong call is refused before a whole outer loop is paid for.
#
# Two halves. The refusals that are this orchestrator's own -- finetune not
# installed, `iter` below its floor of 1, `initial` below its floor of 1 or a
# `tune_results` -- each fire with a class of their own, naming the user's
# call. And every check the Bayesian sibling makes, other than the one that
# judges an acquisition function, fires here too, through one table held to
# the list read off the Bayesian body, so a check added there and missing
# here fails by name.

anneal_folds <- function(d) det_nested(d, v = 2)

# The refusal, as the condition it raised. Fitting is replaced by a sentinel
# so a check that ran AFTER the loop began would surface as the sentinel's
# class rather than its own -- which is what separates "refused at entry"
# from "refused eventually".
refusal <- function(expr) {
  sentinel <- function(...) {
    rlang::abort("fitting began", class = "nestedtune_sentinel")
  }
  testthat::local_mocked_bindings(dispatch_folds = sentinel)
  tryCatch(expr, error = function(cnd) cnd)
}

expect_refused <- function(cnd, class, pattern) {
  testthat::expect_s3_class(cnd, class)
  testthat::expect_false(inherits(cnd, "nestedtune_sentinel"))
  testthat::expect_match(conditionMessage(cnd), pattern)
  testthat::expect_identical(
    conditionCall(cnd)[[1L]],
    as.name("nested_tune_sim_anneal")
  )
  invisible(cnd)
}

# The absence of one package, seen through the seam the check reads: every
# other package answers as it really is, so the refusal is shown to be about
# the one made absent and not about a mock that says no to everything.
local_absent <- function(pkg, env = parent.frame()) {
  real <- rlang::is_installed
  testthat::local_mocked_bindings(
    is_installed = function(pkg_, ...) {
      if (pkg_ %in% pkg) FALSE else real(pkg_, ...)
    },
    .package = "rlang",
    .env = env
  )
}

test_that("finetune must be installed", {
  skip_if_no_anneal_fixture()

  d <- make_reg_data()
  wf <- det_workflow(d)
  folds <- anneal_folds(d)

  local({
    local_absent("finetune")
    cnd <- refusal(nested_tune_sim_anneal(wf, folds))
    expect_refused(cnd, "nestedtune_pkg_not_installed", "finetune")
    expect_match(conditionMessage(cnd), "not installed")
    expect_match(
      conditionMessage(cnd),
      'install.packages("finetune")',
      fixed = TRUE
    )
  })
  # The discrimination: with nothing made absent, the same call passes the
  # check and reaches the sentinel.
  cnd <- refusal(nested_tune_sim_anneal(wf, folds, control = anneal_control()))
  expect_s3_class(cnd, "nestedtune_sentinel")
})

test_that("`iter` must be a single whole number of at least 1", {
  skip_if_no_anneal_fixture()

  d <- make_reg_data()
  wf <- det_workflow(d)
  folds <- anneal_folds(d)

  # Each kind of bad value has its exemplar: below the floor (0, where
  # finetune runs two iterations, and -1), fractional, non-numeric (character,
  # logical, list, NULL), length 0 and 2, `NA` in both types, and non-finite.
  for (bad in list(
    0,
    -1,
    2.5,
    "3",
    TRUE,
    list(1),
    NULL,
    numeric(0),
    c(1, 2),
    NA,
    NA_real_,
    Inf
  )) {
    cnd <- refusal(nested_tune_sim_anneal(wf, folds, iter = bad))
    expect_refused(cnd, "nestedtune_bad_iter", "at least 1")
  }
  # The value is named when there is one to name.
  cnd <- refusal(nested_tune_sim_anneal(wf, folds, iter = 0))
  expect_match(conditionMessage(cnd), "Got 0")

  # The floor is this sibling's own: `nested_tune_bayes()` still accepts 0.
  expect_no_error(check_iter(0))
  expect_error(check_iter(0, floor = 1), class = "nestedtune_bad_iter")

  # And 1 is accepted: the checks pass and the loop is about to begin.
  cnd <- refusal(nested_tune_sim_anneal(
    wf,
    folds,
    iter = 1,
    control = anneal_control()
  ))
  expect_s3_class(cnd, "nestedtune_sentinel")
})

test_that("`initial` must be a single whole number of at least 1", {
  skip_if_no_anneal_fixture()

  d <- make_reg_data()
  wf <- det_workflow(d)
  folds <- anneal_folds(d)

  for (bad in list(
    0,
    -3,
    2.5,
    "5",
    TRUE,
    list(1),
    NULL,
    numeric(0),
    c(3, 4),
    NA,
    NA_real_,
    Inf
  )) {
    cnd <- refusal(nested_tune_sim_anneal(wf, folds, initial = bad))
    # The class is shared with the `tune_results` refusal below, so the
    # message says which of the two fired.
    expect_refused(cnd, "nestedtune_bad_initial", "at least 1")
  }

  # The floor is this sibling's own: the Bayesian sibling's is 2.
  expect_no_error(check_initial(1, floor = 1))
  expect_error(check_initial(1), class = "nestedtune_bad_initial")

  cnd <- refusal(nested_tune_sim_anneal(
    wf,
    folds,
    initial = 1,
    control = anneal_control()
  ))
  expect_s3_class(cnd, "nestedtune_sentinel")
})

test_that("`initial` refuses a tune_results, which finetune would accept", {
  skip_if_no_anneal_fixture()

  d <- make_reg_data()
  wf <- det_workflow(d)
  folds <- anneal_folds(d)

  # A genuine tuning run, so the refusal is shown to fire on the object
  # tune's own `check_initial()` accepts rather than on a stand-in wearing
  # its class.
  set.seed(1)
  earlier <- tune::tune_grid(
    wf,
    resamples = folds$inner_resamples[[1L]],
    grid = det_grid(),
    control = tune::control_grid(allow_par = FALSE)
  )
  expect_s3_class(earlier, "tune_results")

  cnd <- refusal(nested_tune_sim_anneal(wf, folds, initial = earlier))
  expect_refused(cnd, "nestedtune_bad_initial", "not a")
  expect_match(conditionMessage(cnd), "tune_results")
  expect_match(conditionMessage(cnd), "assessment rows")
  expect_no_match(conditionMessage(cnd), "at least 1")
})

# The shared checks. The list is derived, not written: every `check_*()` the
# Bayesian orchestrator's body calls, less the one that judges an acquisition
# function, must fire through this orchestrator.

check_calls <- function(fn) {
  nms <- all.names(body(fn))
  sort(unique(nms[startsWith(nms, "check_")]))
}

test_that("each shared check fires through nested_tune_sim_anneal()", {
  skip_if_no_anneal_fixture()

  d <- make_reg_data()
  wf <- det_workflow(d)
  folds <- anneal_folds(d)
  ctrl <- anneal_control()

  fired <- list(
    check_dots_control = function() {
      nested_tune_sim_anneal(wf, folds, 3, control = ctrl)
    },
    check_control = function() {
      nested_tune_sim_anneal(wf, folds, control = "no")
    },
    check_required = function() nested_tune_sim_anneal(wf),
    check_no_preprocessor = function() {
      nested_tune_sim_anneal(
        wf,
        preprocessor = y ~ x1,
        resamples = folds,
        control = ctrl
      )
    },
    # An empty workflow, since a bare spec takes the model-spec route.
    check_workflow = function() {
      nested_tune_sim_anneal(workflows::workflow(), folds, control = ctrl)
    },
    check_untuned_workflow = function() {
      nested_tune_sim_anneal(fixed_workflow(d), folds, control = ctrl)
    },
    check_nested = function() {
      nested_tune_sim_anneal(wf, rsample::vfold_cv(d, v = 2), control = ctrl)
    },
    check_iter = function() {
      nested_tune_sim_anneal(wf, folds, iter = 0, control = ctrl)
    },
    check_initial = function() {
      nested_tune_sim_anneal(wf, folds, initial = 0, control = ctrl)
    },
    check_metrics = function() {
      nested_tune_sim_anneal(wf, folds, metrics = "rmse", control = ctrl)
    },
    check_param_info = function() {
      nested_tune_sim_anneal(
        wf,
        folds,
        param_info = data.frame(num_comp = 1:3),
        control = ctrl
      )
    },
    check_event_level = function() {
      nested_tune_sim_anneal(wf, folds, event_level = "third", control = ctrl)
    },
    check_eval_time = function() {
      nested_tune_sim_anneal(wf, folds, eval_time = -1, control = ctrl)
    },
    check_selection_rule = function() {
      nested_tune_sim_anneal(wf, folds, select = "best", control = ctrl)
    }
  )
  patterns <- c(
    check_dots_control = "accepts `control`",
    check_control = "control_sim_anneal",
    check_no_preprocessor = "carries its own preprocessor",
    check_required = "`resamples` is absent",
    check_workflow = "no model specification",
    check_untuned_workflow = "no parameter marked for tuning",
    check_nested = "nested resampling design",
    check_iter = "at least 1",
    check_initial = "at least 1",
    check_metrics = "metric_set",
    check_param_info = "parameters",
    check_event_level = "event_level",
    check_eval_time = "eval_time",
    check_selection_rule = "selection_rule"
  )

  shared <- setdiff(check_calls(nested_tune_bayes.workflow), "check_objective")
  # One fact held independently of the derivation: the list cannot silently
  # empty.
  expect_true(all(c("check_iter", "check_initial") %in% shared))
  expect_identical(setdiff(shared, names(fired)), character(0))

  for (nm in names(fired)) {
    cnd <- refusal(fired[[nm]]())
    expect_s3_class(cnd, "error")
    expect_false(inherits(cnd, "nestedtune_sentinel"))
    expect_match(conditionMessage(cnd), patterns[[nm]], info = nm)
    expect_identical(
      conditionCall(cnd)[[1L]],
      as.name("nested_tune_sim_anneal")
    )
  }
})

# What would show the floor wrong, pinned: `iter`'s floor of 1 rests on
# finetune running iterations at `iter = 0` (its loop is
# `(existing_iter + 1):iter`, which at 0 is `1:0`). A finetune whose loop runs
# none at 0 turns this red, which is the signal to reopen accepting 0 as the
# Bayesian sibling does.
test_that("finetune still iterates at iter = 0, the fact iter's floor of 1 rests on", {
  skip_if_no_anneal_fixture()

  d <- make_reg_data()
  wf <- det_workflow(d)
  inner <- anneal_folds(d)$inner_resamples[[1L]]
  ctrl <- anneal_control()
  ctrl$allow_par <- FALSE

  set.seed(1)
  fit <- finetune::tune_sim_anneal(
    wf,
    inner,
    iter = 0,
    initial = 1,
    metrics = reg_metrics(),
    control = ctrl
  )
  m <- tune::collect_metrics(fit)
  iterated <- !startsWith(m$.config, "initial_")
  expect_gt(sum(iterated), 0L)
})

test_that("the desirability rule is refused at entry", {
  skip_if_no_anneal_fixture()
  skip_if_not_installed("desirability2", minimum_version = "0.2.0")

  d <- make_reg_data()
  wf <- det_workflow(d)
  cnd <- refusal(nested_tune_sim_anneal(
    wf,
    anneal_folds(d),
    select = selection_rule("desirability", maximize(rsq)),
    control = anneal_control()
  ))
  expect_refused(
    cnd,
    "nestedtune_selection_rule_unsupported",
    "tune_sim_anneal"
  )
  # The message names the orchestrators the user calls.
  msg <- cli::ansi_strip(conditionMessage(cnd))
  expect_match(msg, "under `nested_tune_sim_anneal()`", fixed = TRUE)
  expect_match(msg, "`nested_tune_bayes()`", fixed = TRUE)
})

test_that("a workflow with no tune() marker is refused, naming nested_fit_resamples()", {
  skip_if_no_engines()
  skip_if_not_installed("finetune")
  d <- make_reg_data()
  wf <- fixed_workflow(d)
  folds <- det_nested(d)

  cnd <- rlang::catch_cnd(nested_tune_sim_anneal(wf, folds, iter = 1))
  expect_s3_class(cnd, "nestedtune_untuned_workflow")
  expect_identical(
    rlang::call_name(conditionCall(cnd)),
    "nested_tune_sim_anneal"
  )
  expect_match(conditionMessage(cnd), "nested_fit_resamples()", fixed = TRUE)
})
