# Oracle records for nested_workflow_map() (M71, AC1; DESIGN Conventions:
# oracles are recorded in the test file that asserts them).
#
# O1 -- type "live" (reference implementation). Source: the orchestrator
#   each workflow routes to, called by hand on that workflow with the same
#   arguments after `set.seed()` of the same value. The map adds nothing
#   statistical: each element must be `identical()` to that hand call, seeds,
#   record and all. What the map is trusted with -- the routing, the option
#   override, the narrowing, the entry state reinstated before every workflow
#   -- is exactly what a wrong element would show. One block per `fn`, so a
#   route that drifts names its orchestrator.
#
# The hand call's arguments are written out here from the documented
# contract, never read off `orchestrator_args()`: for a tuned workflow the
# orchestrator `fn` names takes everything the map was given, and a fixed
# workflow runs through `nested_fit_resamples()` with the design and the
# metrics alone -- no `grid`, no counts, and no `control` (the class is
# `fn`'s, and the plain resampling orchestrator refuses it).

# The hand call for one workflow: the routed orchestrator, its arguments
# spelled by name, under the entry seed.
hand_call <- function(fn, workflow, folds, ms, seed) {
  tuned <- length(tune::extract_parameter_set_dials(workflow)$id) > 0L
  set.seed(seed)
  if (!tuned) {
    return(nested_fit_resamples(workflow, folds, metrics = ms))
  }
  switch(
    fn,
    nested_tune_grid = nested_tune_grid(
      workflow,
      folds,
      grid = det_grid(),
      metrics = ms
    ),
    nested_tune_bayes = nested_tune_bayes(
      workflow,
      folds,
      iter = 1,
      initial = 2,
      metrics = ms
    ),
    nested_tune_race_anova = nested_tune_race_anova(
      workflow,
      folds,
      grid = det_grid(),
      metrics = ms,
      control = race_control()
    ),
    nested_tune_race_win_loss = nested_tune_race_win_loss(
      workflow,
      folds,
      grid = det_grid(),
      metrics = ms,
      control = race_control()
    ),
    nested_tune_sim_anneal = nested_tune_sim_anneal(
      workflow,
      folds,
      iter = 2,
      initial = 3,
      metrics = ms,
      control = anneal_control()
    )
  )
}

for (fn in MAP_FNS) {
  test_that(
    paste0("AC1: each element is identical to the hand call (fn = ", fn, ")"),
    {
      skip_if_no_wset_fixture(fn)
      d <- make_reg_data()
      res <- wset_results(fn)

      # The same set, design and metrics `wset_results()` built, under its seed.
      set.seed(31)
      wset <- if (fn == "nested_fit_resamples") wset_fixed(d) else wset_two(d)
      folds <- final_nested(d)
      ms <- reg_metrics()

      expect_s3_class(res, "nested_results_set")
      expect_identical(
        class(res),
        c("nested_results_set", "tbl_df", "tbl", "data.frame")
      )
      expect_identical(names(res), c("wflow_id", "workflow", "result"))
      expect_identical(res$wflow_id, wset$wflow_id)
      expect_identical(attr(res, "fn"), fn)
      # The set's order is not its sort order, so a sorted set would fail here.
      expect_false(identical(res$wflow_id, sort(res$wflow_id)))

      for (i in seq_len(nrow(wset))) {
        wf <- wset$info[[i]]$workflow[[1L]]
        expect_identical(res$workflow[[i]], wf)
        hand <- hand_call(fn, wf, folds, ms, seed = 31)
        expect_true(all(hand$.completed))
        expect_identical(res$result[[i]], hand)
      }
      # The routing, read off each element's record: the tuned workflow ran
      # through `fn`, the fixed one through the plain resampling orchestrator.
      tuners <- vapply(
        res$result,
        function(r) extract_procedure(r)$tuner,
        character(1)
      )
      expected <- if (fn == "nested_fit_resamples") {
        c("fit_resamples", "fit_resamples")
      } else {
        c(sub("^nested_", "", fn), "fit_resamples")
      }
      expect_identical(tuners, expected)
      # Paired on seeds: every workflow's fold `i` drew the same two.
      seeds <- lapply(res$result, function(r) {
        r[c(".tuning_seed", ".outer_fit_seed")]
      })
      expect_identical(seeds[[2L]], seeds[[1L]])
    }
  )
}

test_that("AC1: a per-workflow grid option overrides the grid in `...` for that workflow alone", {
  skip_if_no_wset_fixture()
  d <- make_reg_data()
  set.seed(31)
  wset <- wset_three(d)
  folds <- final_nested(d)
  ms <- reg_metrics()

  set.seed(31)
  res <- nested_workflow_map(
    wset,
    resamples = folds,
    grid = det_grid(),
    metrics = ms
  )
  expect_identical(res$wflow_id, c("tuned", "fixed", "threshold"))

  # The first tuned workflow searched the call's grid, the third its own;
  # asserted on the recorded grid, then on the whole element.
  expect_identical(attr(res$result[[1L]], "grid"), det_grid())
  expect_identical(attr(res$result[[3L]], "grid"), cont_grid())
  expect_null(attr(res$result[[2L]], "grid"))

  set.seed(31)
  first <- nested_tune_grid(
    wset$info[[1L]]$workflow[[1L]],
    folds,
    grid = det_grid(),
    metrics = ms
  )
  set.seed(31)
  second <- nested_fit_resamples(
    wset$info[[2L]]$workflow[[1L]],
    folds,
    metrics = ms
  )
  set.seed(31)
  third <- nested_tune_grid(
    wset$info[[3L]]$workflow[[1L]],
    folds,
    grid = cont_grid(),
    metrics = ms
  )
  expect_identical(res$result[[1L]], first)
  expect_identical(res$result[[2L]], second)
  expect_identical(res$result[[3L]], third)
})

test_that("AC1: a control in `...` reaches the tuned workflows and an option control reaches the fixed one", {
  skip_if_no_wset_fixture()
  d <- make_reg_data()
  set.seed(31)
  wset <- workflowsets::option_add(
    wset_two(d),
    id = "fixed",
    control = tune::control_resamples(save_pred = TRUE)
  )
  folds <- final_nested(d)
  ms <- reg_metrics()

  set.seed(31)
  res <- nested_workflow_map(
    wset,
    resamples = folds,
    grid = det_grid(),
    metrics = ms,
    control = tune::control_grid(save_pred = TRUE)
  )
  # Both kept predictions: the tuned one from the call's control, the fixed
  # one from its own.
  expect_true(".predictions" %in% names(res$result[[1L]]))
  expect_true(".predictions" %in% names(res$result[[2L]]))

  set.seed(31)
  first <- nested_tune_grid(
    wset$info[[1L]]$workflow[[1L]],
    folds,
    grid = det_grid(),
    metrics = ms,
    control = tune::control_grid(save_pred = TRUE)
  )
  set.seed(31)
  second <- nested_fit_resamples(
    wset$info[[2L]]$workflow[[1L]],
    folds,
    metrics = ms,
    control = tune::control_resamples(save_pred = TRUE)
  )
  expect_identical(res$result[[1L]], first)
  expect_identical(res$result[[2L]], second)
})

test_that("AC1: a warning raised inside one workflow names it and keeps its class", {
  skip_if_no_wset_fixture()
  d <- make_reg_data()
  set.seed(31)
  wset <- wset_two(d)
  folds <- final_nested(d)
  ms <- reg_metrics()
  broken <- break_fold(folds, 1L, "outer fit")

  warnings <- list()
  set.seed(31)
  res <- withCallingHandlers(
    nested_workflow_map(
      wset,
      resamples = broken,
      grid = det_grid(),
      metrics = ms
    ),
    nestedtune_failed_folds = function(w) {
      warnings[[length(warnings) + 1L]] <<- w
      invokeRestart("muffleWarning")
    }
  )
  # One per workflow, each naming its workflow first and the fold after,
  # under the class the orchestrator raised, and naming the map as the call.
  expect_length(warnings, 2L)
  for (i in 1:2) {
    msg <- conditionMessage(warnings[[i]])
    expect_match(msg, paste0('^Workflow "', wset$wflow_id[[i]], '"'))
    expect_match(msg, "1 of 2 outer folds failed", fixed = TRUE)
    expect_match(msg, "Fold1", fixed = TRUE)
    expect_identical(
      rlang::call_name(conditionCall(warnings[[i]])),
      "nested_workflow_map"
    )
  }
  expect_identical(
    vapply(res$result, function(r) sum(r$.completed), integer(1)),
    c(1L, 1L)
  )
})

test_that("AC1: an error one workflow's orchestrator raises names the workflow", {
  skip_if_no_wset_fixture()
  d <- make_reg_data()
  set.seed(31)
  # The third workflow's own grid removed, so the call's `grid` -- a column
  # it does not tune -- reaches its orchestrator and is refused there, once
  # the two before it have run.
  wset <- wset_three(d)
  wset$option[[3L]] <- structure(
    list(),
    class = c("workflow_set_options", "list")
  )
  folds <- final_nested(d)

  cnd <- rlang::catch_cnd(
    nested_workflow_map(wset, resamples = folds, grid = det_grid()),
    "error"
  )
  expect_match(conditionMessage(cnd), '^Workflow "threshold"')
  expect_match(conditionMessage(cnd), "num_comp", fixed = TRUE)
  expect_identical(rlang::call_name(conditionCall(cnd)), "nested_workflow_map")
})
