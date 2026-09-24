# Oracle records (DESIGN Conventions: oracles are recorded in the test file
# that asserts them).
#
# O1 -- type "live" (reference implementation). Source: the tidymodels pipeline
#   itself, recomputed at test time by reference_nested_loop() in
#   helper-orchestration.R, which is written from the documented seed contract
#   rather than from the driver. The same oracle test-nested-tune-grid-oracles.R
#   records; asserted here on the sep_* fixture with `metric_name = "mae"`, so
#   it pins the metric the inner tuning selected under. Since M115 it is
#   asserted under two rules, with the set's order as the variable: under
#   `metric_set(mae, rmse)` each fold's candidate is the one tune's selector
#   picks on the inner run's `mae` column, and each fold's outer `rmse` is the
#   one `tune::last_fit()` gives that candidate. Pinned by "the first metric
#   in the set selects, and the outer loop scores every metric".
#
# The `metrics` argument reaches tune (M18).
#
# Nothing here asserted anything before M18: the suite's shared metric set is
# `metric_set(rmse, rsq)`, which IS tune's regression default, so every test
# passing it produced a run identical to one passing nothing. Deleting the
# argument from any call site left the suite green.
#
# These tests run on sep_* (helper-orchestration.R), a fixture built so that the
# caller's metric set and tune's default disagree about both the metric names
# and the selected candidate. The disagreement is the whole instrument, so the
# first test below asserts the fixture still has it -- without that, the other
# two would pass vacuously against a future tune whose defaults had changed,
# which is the failure mode this file exists to prevent.

test_that("the fixture separates the caller's metric set from tune's default", {
  skip_if_no_engines()

  d <- sep_data()
  wf <- sep_workflow(d)
  nested <- sep_nested(d)

  set.seed(20)
  mine <- memoised(nested_tune_grid(
    wf,
    nested,
    grid = sep_grid(),
    metrics = sep_metrics()
  ))
  set.seed(20)
  theirs <- memoised(nested_tune_grid(
    wf,
    nested,
    grid = sep_grid(),
    metrics = NULL
  ))

  # Different metric names, so the outer .metrics column can tell them apart.
  expect_false(setequal(
    unique(unlist(lapply(mine$.metrics, function(m) m$.metric))),
    unique(unlist(lapply(theirs$.metrics, function(m) m$.metric)))
  ))
  # Different selections in every outer fold, so .selected can tell them apart
  # even though the inner tuning run is not retained on nested_results.
  mine_sel <- vapply(mine$.selected, function(s) s$num_comp, integer(1))
  theirs_sel <- vapply(theirs$.selected, function(s) s$num_comp, integer(1))
  expect_true(all(mine_sel != theirs_sel))
})

test_that("nested_tune_grid() scores the metrics it was given", {
  skip_if_no_engines()

  d <- sep_data()
  wf <- sep_workflow(d)
  nested <- sep_nested(d)

  set.seed(20)
  res <- memoised(nested_tune_grid(
    wf,
    nested,
    grid = sep_grid(),
    metrics = sep_metrics()
  ))

  expect_equal(nrow(res), 3L)
  for (i in seq_len(nrow(res))) {
    expect_identical(sort(res$.metrics[[i]]$.metric), c("mae", "rmse"))
  }
})

test_that("nested_final_fit() tunes under the metrics it was given", {
  skip_if_no_engines()

  d <- sep_data()
  wf <- sep_workflow(d)
  nested <- sep_nested(d)

  res <- memoised(nested_tune_grid(
    wf,
    nested,
    grid = sep_grid(),
    metrics = sep_metrics()
  ))
  set.seed(30)
  final <- memoised(nested_final_fit(wf, res))

  expect_identical(
    sort(unique(tune::collect_metrics(final$tuning)$.metric)),
    c("mae", "rmse")
  )
})

# O1's pin (M115). The ordering is `desc(num_comp)` and not `num_comp`.
# Measured 2026-09-24 on this fixture under seed 20, `mae` first against `rmse`
# first: "best" picks 1 2 2 against 3 1 3; "one_std_err" by `num_comp` picks
# 1 1 1 against 1 1 1, so the two orders cannot be told apart; by
# `desc(num_comp)` it picks 5 5 4 against 5 5 5.

test_that("the first metric in the set selects, and the outer loop scores every metric", {
  skip_if_no_engines()

  d <- sep_data()
  wf <- sep_workflow(d)
  nested <- sep_nested(d)
  mae_first <- sep_metrics()
  rmse_first <- yardstick::metric_set(yardstick::rmse, yardstick::mae)

  rules <- list(
    best = selection_rule(),
    one_std_err = selection_rule("one_std_err", desc(num_comp))
  )
  # The default-rule run is requested as the tests above request it, from the
  # same RNG state, so the cache serves it. The reference resolves the first
  # metric of the caller's set, as the driver does off its own tuned object, so
  # this fails if the inner tune_grid() stops receiving `metrics` and falls
  # back to `rmse`. Each rule is applied to the one reference tuning stage
  # through reference_with_rule() (M74).
  set.seed(20)
  default_run <- memoised(nested_tune_grid(
    wf,
    nested,
    grid = sep_grid(),
    metrics = sep_metrics()
  ))
  ref_tuned <- memoised(reference_nested_loop(
    wf,
    nested,
    sep_grid(),
    sep_metrics(),
    seed = 20,
    metric_name = "mae"
  ))
  expect_identical(extract_procedure(default_run)$select, rules$best)
  for (nm in names(rules)) {
    set.seed(20)
    res <- if (nm == "best") {
      default_run
    } else {
      memoised(nested_tune_grid(
        wf,
        nested,
        grid = sep_grid(),
        metrics = mae_first,
        select = rules[[nm]]
      ))
    }
    ref <- reference_with_rule(
      ref_tuned,
      wf,
      nested,
      mae_first,
      rules[[nm]],
      "mae"
    )
    expect_equal(nrow(res), 3L)
    for (i in seq_len(nrow(res))) {
      expect_identical(res$.selected[[i]], ref[[i]]$selected, info = nm)
      outer_rmse <- res$.metrics[[i]][res$.metrics[[i]]$.metric == "rmse", ]
      ref_rmse <- ref[[i]]$metrics[ref[[i]]$metrics$.metric == "rmse", ]
      expect_equal(nrow(outer_rmse), 1L)
      expect_identical(outer_rmse, ref_rmse, info = nm)
    }

    # The same call with the order reversed selects on `rmse`, and moves the
    # choice in at least one fold.
    set.seed(20)
    flipped <- memoised(nested_tune_grid(
      wf,
      nested,
      grid = sep_grid(),
      metrics = rmse_first,
      select = rules[[nm]]
    ))
    mine <- vapply(res$.selected, function(s) s$num_comp, integer(1))
    theirs <- vapply(flipped$.selected, function(s) s$num_comp, integer(1))
    expect_true(any(mine != theirs), info = nm)
  }
})
