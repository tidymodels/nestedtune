# Entry checks on nested_workflow_map() (M71, AC5). Each refusal is asserted
# by its condition class, named for the user's call, and shown to fire before
# any fold runs: the orchestrators draw their seeds only once every check has
# passed, so an untouched `.Random.seed` and an empty dispatch record are
# the evidence that nothing ran (the M03 discipline, as
# test-nested-fit-resamples-checks.R applies it).

# The refusal, with the stream and the dispatch record asserted untouched.
expect_map_refusal <- function(expr, class) {
  reset_dispatch_record()
  set.seed(1)
  before <- .Random.seed
  cnd <- rlang::catch_cnd(expr)
  expect_s3_class(cnd, class)
  expect_identical(rlang::call_name(conditionCall(cnd)), "nested_workflow_map")
  expect_identical(.Random.seed, before)
  expect_null(last_dispatch())
  invisible(cnd)
}

test_that("AC5: an object that is not a workflow_set is refused", {
  skip_if_no_wset_fixture()
  d <- make_reg_data()
  folds <- det_nested(d)
  # Built before the call: a recipe draws its step id from the stream, and
  # the untouched-stream assertion is about the map, not the fixture.
  wf <- det_workflow(d)

  cnd <- expect_map_refusal(
    nested_workflow_map(wf, resamples = folds, grid = det_grid()),
    "nestedtune_bad_workflow_set"
  )
  expect_match(conditionMessage(cnd), "workflow_set", fixed = TRUE)
  # A tibble wearing the class but lacking the columns is refused too: the
  # map reads `wflow_id`, `info` and `option` off the set, so the columns
  # are the contract, not the class alone.
  bare <- structure(
    tibble::tibble(wflow_id = "a"),
    class = c("workflow_set", "tbl_df", "tbl", "data.frame")
  )
  cnd <- expect_map_refusal(
    nested_workflow_map(bare, resamples = folds, grid = det_grid()),
    "nestedtune_bad_workflow_set"
  )
  expect_match(conditionMessage(cnd), "info", fixed = TRUE)
})

test_that("AC5: fn must name one of the six orchestrators", {
  skip_if_no_wset_fixture()
  d <- make_reg_data()
  wset <- wset_two(d)
  folds <- det_nested(d)

  # tune's own name for the function is not the orchestrator's.
  cnd <- expect_map_refusal(
    nested_workflow_map(
      wset,
      "tune_grid",
      resamples = folds,
      grid = det_grid()
    ),
    "nestedtune_bad_fn"
  )
  expect_match(conditionMessage(cnd), "tune_grid", fixed = TRUE)
  for (fn in MAP_FNS) {
    expect_match(conditionMessage(cnd), fn, fixed = TRUE)
  }
  expect_map_refusal(
    nested_workflow_map(wset, 1, resamples = folds, grid = det_grid()),
    "nestedtune_bad_fn"
  )
  expect_map_refusal(
    nested_workflow_map(wset, MAP_FNS[1:2], resamples = folds),
    "nestedtune_bad_fn"
  )
})

test_that("AC5: a name in `...` the named orchestrator does not take is refused", {
  skip_if_no_wset_fixture()
  d <- make_reg_data()
  wset <- wset_two(d)
  folds <- det_nested(d)

  # A typo would otherwise be narrowed away without a word.
  cnd <- expect_map_refusal(
    nested_workflow_map(wset, resamples = folds, gird = det_grid()),
    "nestedtune_bad_dots"
  )
  expect_match(conditionMessage(cnd), "gird", fixed = TRUE)
  # `iter` is the Bayesian orchestrator's, not the grid orchestrator's.
  cnd <- expect_map_refusal(
    nested_workflow_map(wset, resamples = folds, grid = det_grid(), iter = 2),
    "nestedtune_bad_dots"
  )
  expect_match(conditionMessage(cnd), "iter", fixed = TRUE)
  expect_match(conditionMessage(cnd), "nested_tune_grid", fixed = TRUE)
  # `control` is not a formal of any orchestrator and still passes the fence.
  cnd <- expect_map_refusal(
    nested_workflow_map(
      wset,
      resamples = folds,
      grid = det_grid(),
      control = tune::control_grid(),
      nonesuch = 1
    ),
    "nestedtune_bad_dots"
  )
  expect_match(
    conditionMessage(cnd),
    "does not take: `nonesuch`.",
    fixed = TRUE
  )
  # Everything after `fn` is matched by name.
  cnd <- expect_map_refusal(
    nested_workflow_map(wset, "nested_tune_grid", folds, grid = det_grid()),
    "nestedtune_bad_dots"
  )
  expect_match(conditionMessage(cnd), "unnamed", fixed = TRUE)
  # The design is the one argument every route needs.
  cnd <- expect_map_refusal(
    nested_workflow_map(wset, grid = det_grid()),
    "nestedtune_bad_dots"
  )
  expect_match(conditionMessage(cnd), "resamples", fixed = TRUE)
})

test_that("AC5: an option entry the routed orchestrator does not take is refused, naming the workflow", {
  skip_if_no_wset_fixture()
  d <- make_reg_data()
  folds <- det_nested(d)

  # `iter` on a workflow routed to the grid orchestrator.
  wset <- workflowsets::option_add(wset_two(d), id = "tuned", iter = 2)
  cnd <- expect_map_refusal(
    nested_workflow_map(wset, resamples = folds, grid = det_grid()),
    "nestedtune_bad_option"
  )
  expect_match(conditionMessage(cnd), "tuned", fixed = TRUE)
  expect_match(conditionMessage(cnd), "iter", fixed = TRUE)
  expect_match(conditionMessage(cnd), "nested_tune_grid", fixed = TRUE)

  # `grid` on a fixed workflow: it routes to the plain resampling
  # orchestrator whatever `fn` names, and that one takes no grid. The same
  # name in `...` is narrowed away for it; as an option it is a claim about
  # this workflow, and refused.
  wset <- workflowsets::option_add(wset_two(d), id = "fixed", grid = 3)
  cnd <- expect_map_refusal(
    nested_workflow_map(wset, resamples = folds, grid = det_grid()),
    "nestedtune_bad_option"
  )
  expect_match(conditionMessage(cnd), "fixed", fixed = TRUE)
  expect_match(conditionMessage(cnd), "nested_fit_resamples", fixed = TRUE)

  # The design and the workflow are the call's, never an option's.
  wset <- workflowsets::option_add(wset_two(d), id = "tuned", resamples = folds)
  cnd <- expect_map_refusal(
    nested_workflow_map(wset, resamples = folds, grid = det_grid()),
    "nestedtune_bad_option"
  )
  expect_match(conditionMessage(cnd), "resamples", fixed = TRUE)
  # `option_add()` refuses `object` itself, so the entry is planted by hand,
  # the shape a set built outside workflowsets' constructors could carry.
  wset <- wset_two(d)
  wset$option[[2L]] <- structure(
    list(object = 1),
    class = c("workflow_set_options", "list")
  )
  expect_map_refusal(
    nested_workflow_map(wset, resamples = folds, grid = det_grid()),
    "nestedtune_bad_option"
  )
})

test_that("AC5: a workflow check_workflow() refuses is refused naming its wflow_id", {
  skip_if_no_wset_fixture()
  d <- make_reg_data()
  folds <- det_nested(d)

  # `as_workflow_set()` admits a fitted workflow, which no orchestrator
  # does; the second element is the offender so the message's id is shown
  # to be the workflow's and not the first row's.
  wset <- workflowsets::as_workflow_set(
    tuned = det_workflow(d),
    fitted = parsnip::fit(fixed_workflow(d), d)
  )
  reset_dispatch_record()
  set.seed(1)
  before <- .Random.seed
  cnd <- rlang::catch_cnd(
    nested_workflow_map(wset, resamples = folds, grid = det_grid())
  )
  expect_s3_class(cnd, "error")
  expect_match(
    conditionMessage(cnd),
    "must not already be fitted",
    fixed = TRUE
  )
  expect_match(conditionMessage(cnd), "fitted", fixed = TRUE)
  expect_identical(rlang::call_name(conditionCall(cnd)), "nested_workflow_map")
  expect_identical(.Random.seed, before)
  expect_null(last_dispatch())
})

test_that("AC5: a marked workflow under the plain resampling orchestrator is refused naming its wflow_id", {
  skip_if_no_wset_fixture()
  d <- make_reg_data()
  folds <- det_nested(d)
  wset <- wset_two(d)

  # The mixed set under `fn = "nested_fit_resamples"`: the fixed workflow
  # would run, the tuned one cannot, and the whole set is refused before
  # either starts (D-057's door, asked of every element at entry).
  cnd <- expect_map_refusal(
    nested_workflow_map(wset, "nested_fit_resamples", resamples = folds),
    "nestedtune_tuned_workflow"
  )
  expect_match(conditionMessage(cnd), "tuned", fixed = TRUE)
  expect_match(conditionMessage(cnd), "num_comp", fixed = TRUE)
})

test_that("AC5: every workflow's packages are checked at entry", {
  skip_if_no_wset_fixture()
  d <- make_reg_data()
  folds <- det_nested(d)

  # The absent-package fixture from test-workflow-pkgs.R, placed second so
  # the first workflow's clean check does not stand in for the set's.
  wset <- workflowsets::as_workflow_set(
    tuned = det_workflow(d),
    absent = absent_step_workflow(d)
  )
  cnd <- expect_map_refusal(
    nested_workflow_map(wset, resamples = folds, grid = det_grid()),
    "nestedtune_pkg_not_installed"
  )
  expect_match(conditionMessage(cnd), ABSENT_PKG, fixed = TRUE)
  expect_match(conditionMessage(cnd), "absent", fixed = TRUE)
})

# AC4 (M73): a condition `for_workflow()` re-signals is the original
# object, its first message line prefixed with the workflow's id and its
# call the map's or the reader's. Every planted form is compared field by
# field with the same condition caught outside `for_workflow()`, so a
# re-signal that rebuilt the condition from its message -- what M71 did,
# dropping `parent` and every data field -- fails here on each form.

# The condition `expr` raises, caught outside any re-signal.
planted_cnd <- function(expr) {
  rlang::catch_cnd(expr)
}

# The forms: cli-built with bullets, a parent and a data field; rlang
# plain; base. Each is a function so the same expression can be raised
# twice, once caught bare and once through `for_workflow()`.
RESIGNAL_FORMS <- list(
  list(
    name = "cli_abort with bullets, parent and data",
    kind = "error",
    f = function() {
      cli::cli_abort(
        c("Planted {.val header}", i = "a bullet", x = "another"),
        class = "nestedtune_planted",
        parent = simpleError("the root cause"),
        planted_field = 1:2
      )
    }
  ),
  list(
    name = "rlang::abort plain",
    kind = "error",
    f = function() {
      rlang::abort("plain header\nsecond line", class = "nestedtune_planted")
    }
  ),
  list(
    name = "base stop",
    kind = "error",
    f = function() stop("a base message")
  ),
  list(
    name = "cli_warn partial_summary with bullets, parent and data",
    kind = "warning",
    f = function() {
      cli::cli_warn(
        c("Planted {.val header}", i = "a bullet"),
        class = "nestedtune_partial_summary",
        parent = simpleWarning("the root cause"),
        planted_field = "a"
      )
    }
  ),
  list(
    name = "cli_warn failed_folds with bullets, parent and data",
    kind = "warning",
    f = function() {
      cli::cli_warn(
        c("Planted {.val header}", i = "a bullet"),
        class = "nestedtune_failed_folds",
        parent = simpleWarning("the root cause"),
        planted_field = list(1)
      )
    }
  ),
  list(
    name = "rlang::warn partial_summary plain",
    kind = "warning",
    f = function() {
      rlang::warn("plain warning", class = "nestedtune_partial_summary")
    }
  ),
  list(
    name = "rlang::warn failed_folds plain",
    kind = "warning",
    f = function() {
      rlang::warn("plain warning", class = "nestedtune_failed_folds")
    }
  )
)

# The fields a re-signal may set: the call, and the trace rlang adds to
# an error it signals. Everything else must come through unchanged.
RESIGNAL_OWN_FIELDS <- c("message", "call", "trace")

test_that("AC4: a re-signalled condition keeps the original's class, parent, body, footer, format flag and data fields", {
  call <- quote(the_reader(x))
  for (form in RESIGNAL_FORMS) {
    original <- planted_cnd(form$f())
    got <- rlang::catch_cnd(
      for_workflow("tuned", call, form$f()),
      classes = form$kind
    )
    expect_identical(class(got), class(original), info = form$name)
    for (field in c("parent", "body", "footer", "use_cli_format")) {
      expect_identical(
        got[[field]],
        original[[field]],
        info = paste(form$name, field)
      )
    }
    kept <- setdiff(names(original), RESIGNAL_OWN_FIELDS)
    expect_identical(got[kept], original[kept], info = form$name)
    expect_identical(got$call, call, info = form$name)

    # The message: the original's, the id in front of its first line.
    expected <- conditionMessage(original)
    prefix <- 'Workflow "tuned": '
    expect_identical(
      conditionMessage(got),
      paste0(prefix, expected),
      info = form$name
    )
    lines <- strsplit(conditionMessage(got), "\n", fixed = TRUE)[[1L]]
    expect_identical(
      sum(grepl(prefix, lines, fixed = TRUE)),
      1L,
      info = form$name
    )
    expect_match(
      lines[[1L]],
      paste0("^", gsub("([\"()])", "\\\\\\1", prefix)),
      info = form$name
    )
  }

  # The package's callers hand their own frame, which `rlang::error_call()`
  # resolves to that frame's call.
  a_reader <- function(x) {
    for_workflow(
      "tuned",
      environment(),
      rlang::abort("planted", class = "nestedtune_planted")
    )
  }
  cnd <- rlang::catch_cnd(a_reader(1))
  expect_s3_class(cnd, "nestedtune_planted")
  expect_identical(cnd$call, quote(a_reader(1)))
  expect_identical(conditionMessage(cnd), 'Workflow "tuned": planted')
})

test_that("a re-signalled condition with no message text gets the prefix as its message", {
  call <- quote(the_reader(x))
  empty <- rlang::catch_cnd(
    for_workflow(
      "tuned",
      call,
      rlang::cnd_signal(rlang::error_cnd(
        "nestedtune_planted",
        message = character(0)
      ))
    )
  )
  expect_s3_class(empty, "nestedtune_planted")
  expect_identical(empty$message, 'Workflow "tuned": ')
  absent <- rlang::catch_cnd(
    for_workflow(
      "tuned",
      call,
      stop(structure(
        class = c("nestedtune_planted", "error", "condition"),
        list(message = NULL, call = NULL)
      ))
    )
  )
  expect_s3_class(absent, "nestedtune_planted")
  expect_identical(absent$message, 'Workflow "tuned": ')
  expect_identical(conditionMessage(absent), 'Workflow "tuned": ')
})

test_that("AC4: a re-signalled warning is muffled at the source and a warning of another class passes untouched", {
  call <- quote(the_reader(x))
  # One warning reaches the caller, the prefixed one; the original does not
  # reach it a second time.
  seen <- list()
  withCallingHandlers(
    for_workflow(
      "tuned",
      call,
      rlang::warn("plain warning", class = "nestedtune_failed_folds")
    ),
    warning = function(w) {
      seen[[length(seen) + 1L]] <<- w
      invokeRestart("muffleWarning")
    }
  )
  expect_length(seen, 1L)
  expect_match(
    conditionMessage(seen[[1L]]),
    '^Workflow "tuned": plain warning$'
  )

  other <- rlang::catch_cnd(
    for_workflow(
      "tuned",
      call,
      rlang::warn("not ours", class = "some_other_warning")
    ),
    classes = "warning"
  )
  expect_identical(conditionMessage(other), "not ours")
  expect_null(other$call)
})
