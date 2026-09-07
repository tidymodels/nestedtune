# The readers on a nested_results_set (M71, AC3), the print and the
# extractor (AC4). Every stacked table is checked against
# `dplyr::bind_rows()` of the per-element tables keyed by `wflow_id`, the
# oracle AC3 names, and every fold-state clause is asserted for each of the
# readers it names, by looping over them: one exemplar cannot stand for the
# family, since the five differ in what they check first.

# The five readers that read completed folds, by name, and the sixth.
COMPLETED_READERS <- list(
  collect_metrics = collect_metrics,
  collect_selections = collect_selections,
  collect_inner_metrics = collect_inner_metrics,
  collect_predictions = collect_predictions,
  collect_extracts = collect_extracts
)

# The oracle: each element's own table, the id in front, bound in set order.
bind_by_id <- function(x, reader) {
  tables <- lapply(x$result, reader)
  names(tables) <- x$wflow_id
  dplyr::bind_rows(tables, .id = "wflow_id")
}

# The set whose every workflow kept the two outer-fit columns: the tuned one
# through the call's control, the fixed one through its own option, since
# the call's control is the grid orchestrator's and does not reach it.
kept_set_results <- function(data, seed = 32) {
  set.seed(seed)
  wset <- workflowsets::option_add(
    wset_two(data),
    id = "fixed",
    control = tune::control_resamples(save_pred = TRUE, extract = coef_extract)
  )
  folds <- final_nested(data)
  ms <- reg_metrics()
  ctrl <- tune::control_grid(save_pred = TRUE, extract = coef_extract)
  set.seed(seed)
  memoised(nested_workflow_map(
    object = wset,
    fn = "nested_tune_grid",
    resamples = folds,
    grid = det_grid(),
    metrics = ms,
    control = ctrl
  ))
}

test_that("AC3: every reader's table is bind_rows() of the elements' tables under wflow_id, in set order", {
  skip_if_no_wset_fixture()
  d <- make_reg_data()
  res <- kept_set_results(d)
  expect_identical(res$wflow_id, c("tuned", "fixed"))
  expect_false(identical(res$wflow_id, sort(res$wflow_id)))

  readers <- c(
    COMPLETED_READERS,
    list(
      collect_notes = collect_notes,
      collect_metrics_folds = function(r) collect_metrics(r, summarize = FALSE)
    )
  )
  for (name in names(readers)) {
    reader <- readers[[name]]
    got <- reader(res)
    expect_identical(names(got)[[1L]], "wflow_id", info = name)
    expect_identical(got, bind_by_id(res, reader), info = name)
    # The set's order, not the sort order, over the workflows with a row.
    expect_identical(
      unique(got$wflow_id),
      res$wflow_id[res$wflow_id %in% got$wflow_id],
      info = name
    )
  }

  # `summarize = FALSE` puts the id ahead of the fold label columns.
  folds_tbl <- collect_metrics(res, summarize = FALSE)
  expect_identical(names(folds_tbl)[1:2], c("wflow_id", "id"))
  expect_identical(
    names(collect_metrics(res))[1:2],
    c("wflow_id", ".metric")
  )
  # The fixed workflow selected nothing, so it contributes no selection row
  # and no inner-metrics row, and the tables say so by its absence.
  expect_identical(unique(collect_selections(res)$wflow_id), "tuned")
  expect_identical(unique(collect_inner_metrics(res)$wflow_id), "tuned")
})

test_that("AC3: a workflow that only partly completed raises the reader's partial warning once, naming it", {
  skip_if_no_wset_fixture()
  d <- make_reg_data()
  set.seed(32)
  wset <- workflowsets::option_add(
    wset_two(d),
    id = "fixed",
    control = tune::control_resamples(save_pred = TRUE, extract = coef_extract)
  )
  folds <- final_nested(d)
  broken <- break_fold(folds, 1L, "outer fit")
  set.seed(32)
  res <- suppressWarnings(nested_workflow_map(
    wset,
    resamples = broken,
    grid = det_grid(),
    metrics = reg_metrics(),
    control = tune::control_grid(save_pred = TRUE, extract = coef_extract)
  ))
  for (r in res$result) {
    expect_identical(sum(r$.completed), 1L)
  }

  for (name in names(COMPLETED_READERS)) {
    reader <- COMPLETED_READERS[[name]]
    warnings <- list()
    got <- withCallingHandlers(
      do.call(name, list(res)),
      nestedtune_partial_summary = function(w) {
        warnings[[length(warnings) + 1L]] <<- w
        invokeRestart("muffleWarning")
      }
    )
    # One per workflow, each naming its workflow first and the reader's own
    # words after, under the reader's class, naming the generic as the call.
    expect_length(warnings, 2L)
    for (i in 1:2) {
      msg <- conditionMessage(warnings[[i]])
      expect_match(
        msg,
        paste0('^Workflow "', res$wflow_id[[i]], '"'),
        info = name
      )
      expect_match(msg, "covers 1 of 2 outer folds", fixed = TRUE, info = name)
      expect_match(msg, "Fold1", fixed = TRUE, info = name)
      expect_identical(
        rlang::call_name(conditionCall(warnings[[i]])),
        name,
        info = name
      )
    }
    # And the table is the completed folds' alone.
    expect_identical(
      got,
      suppressWarnings(bind_by_id(res, reader)),
      info = name
    )
  }
  # `collect_notes()` warns about nothing and reads every fold.
  expect_no_warning(notes <- collect_notes(res))
  expect_identical(notes, bind_by_id(res, collect_notes))
})

test_that("AC3: a workflow in which no fold completed is left out with a warning naming it, and collect_notes() keeps it", {
  skip_if_no_wset_fixture()
  d <- make_reg_data()
  set.seed(32)
  wset <- workflowsets::as_workflow_set(
    tuned = det_workflow(d),
    broken = broken_workflow(d)
  )
  folds <- final_nested(d)
  set.seed(32)
  res <- suppressWarnings(nested_workflow_map(
    wset,
    resamples = folds,
    grid = det_grid(),
    metrics = reg_metrics(),
    control = tune::control_grid(save_pred = TRUE, extract = coef_extract)
  ))
  expect_true(all(res$result[[1L]]$.completed))
  expect_false(any(res$result[[2L]]$.completed))

  for (name in names(COMPLETED_READERS)) {
    reader <- COMPLETED_READERS[[name]]
    warnings <- list()
    got <- withCallingHandlers(
      do.call(name, list(res)),
      nestedtune_partial_summary = function(w) {
        warnings[[length(warnings) + 1L]] <<- w
        invokeRestart("muffleWarning")
      }
    )
    expect_length(warnings, 1L)
    msg <- conditionMessage(warnings[[1L]])
    expect_match(msg, 'Workflow "broken"', fixed = TRUE, info = name)
    expect_match(msg, "no outer fold completed", fixed = TRUE, info = name)
    # The tuned workflow's rows alone: the broken one is left out, and its
    # missing predictions column is never asked about, since it would
    # contribute no row.
    expect_identical(unique(got$wflow_id), "tuned", info = name)
    tuned_only <- res[1L, ]
    class(tuned_only) <- class(res)
    attr(tuned_only, "fn") <- attr(res, "fn")
    expect_identical(got, bind_by_id(tuned_only, reader), info = name)
  }
  # The failed workflow's notes are the reason to ask, and they are there.
  notes <- expect_no_warning(collect_notes(res))
  expect_identical(notes, bind_by_id(res, collect_notes))
  expect_true("broken" %in% notes$wflow_id)
  expect_gt(sum(notes$wflow_id == "broken"), 0L)
})

test_that("AC3: a set in which no workflow completed a fold is refused, and collect_notes() still answers", {
  skip_if_no_wset_fixture()
  d <- make_reg_data()
  wset <- workflowsets::as_workflow_set(
    broken = broken_workflow(d),
    also_broken = broken_workflow(d)
  )
  folds <- final_nested(d)
  set.seed(32)
  res <- suppressWarnings(nested_workflow_map(
    wset,
    resamples = folds,
    metrics = reg_metrics(),
    control = tune::control_grid(save_pred = TRUE, extract = coef_extract)
  ))
  for (r in res$result) {
    expect_false(any(r$.completed))
  }

  for (name in names(COMPLETED_READERS)) {
    cnd <- rlang::catch_cnd(do.call(name, list(res)))
    expect_s3_class(cnd, "nestedtune_no_completed_folds")
    expect_identical(rlang::call_name(conditionCall(cnd)), name, info = name)
    expect_match(
      conditionMessage(cnd),
      "2 workflows",
      fixed = TRUE,
      info = name
    )
  }
  notes <- expect_no_warning(collect_notes(res))
  expect_identical(notes, bind_by_id(res, collect_notes))
  expect_identical(unique(notes$wflow_id), c("broken", "also_broken"))
})

test_that("AC3: a workflow that would contribute rows but did not keep the column is refused naming it, after the all-failed refusal", {
  skip_if_no_wset_fixture()
  d <- make_reg_data()
  # The call's control is the grid orchestrator's and does not reach the
  # fixed workflow, which kept neither column.
  set.seed(32)
  wset <- wset_two(d)
  folds <- final_nested(d)
  set.seed(32)
  res <- nested_workflow_map(
    wset,
    resamples = folds,
    grid = det_grid(),
    metrics = reg_metrics(),
    control = tune::control_grid(save_pred = TRUE, extract = coef_extract)
  )
  expect_true(".predictions" %in% names(res$result[[1L]]))
  expect_false(".predictions" %in% names(res$result[[2L]]))

  for (name in c("collect_predictions", "collect_extracts")) {
    cnd <- rlang::catch_cnd(do.call(name, list(res)))
    expect_s3_class(cnd, "nestedtune_column_not_saved")
    expect_match(
      conditionMessage(cnd),
      'Workflow "fixed"',
      fixed = TRUE,
      info = name
    )
    expect_identical(rlang::call_name(conditionCall(cnd)), name, info = name)
  }
  # The other three readers do not ask for the columns.
  for (name in c(
    "collect_metrics",
    "collect_selections",
    "collect_inner_metrics"
  )) {
    expect_no_error(COMPLETED_READERS[[name]](res))
  }

  # Ordering: a set with no completed fold anywhere and no column kept is
  # refused for the folds, not the column.
  wset <- workflowsets::as_workflow_set(
    broken = broken_workflow(d),
    also_broken = broken_workflow(d)
  )
  set.seed(32)
  nothing <- suppressWarnings(nested_workflow_map(
    wset,
    resamples = folds,
    metrics = reg_metrics()
  ))
  for (name in c("collect_predictions", "collect_extracts")) {
    cnd <- rlang::catch_cnd(COMPLETED_READERS[[name]](nothing))
    expect_s3_class(cnd, "nestedtune_no_completed_folds")
  }
})

test_that("AC3: an element's table carrying a wflow_id column is refused", {
  skip_if_no_wset_fixture()
  d <- make_reg_data()
  res <- wset_results("nested_tune_grid")
  # Planted on the element's selection table: the reader stacks it as it
  # finds it, and the set's own column would collide.
  planted <- res
  planted$result[[1L]]$.selected <- lapply(
    planted$result[[1L]]$.selected,
    function(s) {
      s$wflow_id <- "x"
      s
    }
  )
  cnd <- rlang::catch_cnd(collect_selections(planted))
  expect_s3_class(cnd, "nestedtune_collect_name_collision")
  expect_match(conditionMessage(cnd), 'workflow "tuned"', fixed = TRUE)
  # The control: the unplanted set stacks.
  expect_no_error(collect_selections(res))
})

# AC4 -------------------------------------------------------------------

test_that("AC4: print names the orchestrator, the workflow count and each workflow's fold counts", {
  skip_if_no_wset_fixture()
  d <- make_reg_data()
  res <- wset_results("nested_tune_grid")
  expect_snapshot(print(res))

  set.seed(32)
  wset <- wset_two(d)
  folds <- final_nested(d)
  set.seed(32)
  partial <- suppressWarnings(nested_workflow_map(
    wset,
    resamples = break_fold(folds, 1L, "outer fit"),
    grid = det_grid(),
    metrics = reg_metrics()
  ))
  expect_snapshot(print(partial))

  txt <- print_text(res)
  expect_match(txt, "nested_tune_grid()", fixed = TRUE)
  expect_match(txt, "grid search", fixed = TRUE)
  expect_match(txt, "Workflows: 2", fixed = TRUE)
  expect_match(txt, '"tuned": 2 of 2 outer folds completed', fixed = TRUE)
  expect_match(
    txt,
    '"fixed": 2 of 2 outer folds completed (no tuning)',
    fixed = TRUE
  )
  expect_match(
    print_text(partial),
    '"tuned": 1 of 2 outer folds completed',
    fixed = TRUE
  )
  expect_invisible(print(res))
})

test_that("AC4: extract_workflow() returns the element's workflow and refuses an unknown id", {
  skip_if_no_wset_fixture()
  res <- wset_results("nested_tune_grid")
  expect_identical(extract_workflow(res, "fixed"), res$workflow[[2L]])
  expect_identical(extract_workflow(res, "tuned"), res$workflow[[1L]])
  expect_s3_class(extract_workflow(res, "tuned"), "workflow")

  cnd <- rlang::catch_cnd(extract_workflow(res, "nonesuch"))
  expect_s3_class(cnd, "nestedtune_unknown_id")
  expect_match(conditionMessage(cnd), "nonesuch", fixed = TRUE)
  expect_match(conditionMessage(cnd), "tuned", fixed = TRUE)
  expect_s3_class(
    rlang::catch_cnd(extract_workflow(res)),
    "nestedtune_unknown_id"
  )
  expect_s3_class(
    rlang::catch_cnd(extract_workflow(res, 1)),
    "nestedtune_unknown_id"
  )
  expect_s3_class(
    rlang::catch_cnd(extract_workflow(res, c("tuned", "fixed"))),
    "nestedtune_unknown_id"
  )
  # The fence comes first.
  expect_s3_class(
    rlang::catch_cnd(extract_workflow(res, "tuned", nonesuch = 1)),
    "rlib_error_dots_nonempty"
  )
})

test_that("AC4: rank_results() and fit_best() raise on the set rather than answering", {
  skip_if_no_wset_fixture()
  res <- wset_results("nested_tune_grid")
  # workflowsets refuses the object as not a workflow set; tune has no
  # method. Each asserted as the failure it is, so a registered method
  # answering a table or a fit would fail here.
  expect_error(workflowsets::rank_results(res), "must be a workflow set")
  expect_error(tune::fit_best(res), "No `fit_best\\(\\)` exists")
})
