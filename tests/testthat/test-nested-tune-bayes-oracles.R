# Oracle records for nested_tune_bayes() (DESIGN Conventions: oracles are
# recorded in the test file that asserts them). The numbering is this file's
# own; test-nested-tune-grid-oracles.R keeps its O1-O4 for the grid path.
#
# O1 -- type "live" (reference implementation). Source: the tidymodels
#   pipeline itself, recomputed at test time by reference_nested_bayes_loop()
#   in helper-orchestration.R, written from the documented seed contract --
#   `set.seed(s)`, one `sample.int(.Machine$integer.max, 2 * n)`, fold i
#   tuning under element 2i-1 with the kind pinned and `control_bayes(seed =
#   <that element>, allow_par = FALSE)`, fitting under element 2i -- and never
#   from the driver's output. Pinned by "per-fold metrics and selections match
#   a hand-rolled Bayesian reference loop" (deterministic) and "the Bayesian
#   reference loop also matches with a stochastic engine". Satisfies AC2.
#
# O2 -- type "invariant". Source: no external one; the agreement between two
#   independent internal routes is the oracle. At `iter = 0` a Bayesian run
#   scores its initial candidates and proposes nothing, so it must equal
#   nested_tune_grid() on the grid those candidates form. The fixture has two
#   integer-valued parameters, and for two or more parameters
#   dials::grid_space_filling() returns sfd's precomputed design -- the same
#   rows in the same order under every seed, with no draw (measured
#   2026-09-01, dials 1.4.4; a single parameter is drawn from the stream and
#   differs across seeds) -- so one grid built outside the loop is what every
#   fold's Bayesian run scored. Pinned by "at iter = 0 the Bayesian path is the
#   grid path on the space-filling grid". Satisfies AC3.
#
# O3 -- type "invariant" (mode independence), pinned in
#   test-parallel-identity.R as BC10: the same seed gives an identical result
#   serially and at two daemon counts. Recorded here for the audit; the
#   assertion lives with the other dispatch identities.
#
# O4 -- type "live" (reference implementation), M48. Source: the same
#   reference loop, handed the caller's `control_bayes()` and applying the
#   documented merge -- `allow_par` off, the fold's tuning seed as `seed`,
#   every other slot as passed. Pinned by "a control passed through `...`
#   reaches every fold". The discriminator is the early stop `no_improve = 2`
#   produces on the fixture: two of three folds record five candidates
#   against the seven `initial + iter` would give, and the same run with no
#   control records seven in every fold (measured 2026-09-02, tune 2.1.0).
#   Satisfies M48 AC1.
#
# O1 and O2 are the >=2 independent oracle types GP2 asks of the package's own
# contribution -- the call, the seed, the record, the loop -- at the initial
# stage. The iteration stage has O1 and O3 only: the proposals are tune's own
# Gaussian-process search inside D-002's boundary, and no independent oracle
# for them exists here or in a review brief (plan gate, 2026-09-01).

test_that("per-fold metrics and selections match a hand-rolled Bayesian reference loop", {
  skip_if_no_bayes_fixture()

  d <- make_reg_data()
  wf <- bayes_workflow(d)
  folds <- det_nested(d)
  p <- bayes_param_info(wf)
  ms <- reg_metrics()

  # The suite's shared run, built with these objects under seed 20 -- which is
  # the seed the reference below starts from.
  res <- bayes_results()
  expect_true(all(res$.completed))

  ref <- memoised(reference_nested_bayes_loop(
    wf,
    folds,
    iter = 2,
    initial = 3,
    objective = tune::exp_improve(),
    param_info = p,
    metrics = ms,
    seed = 20,
    metric_name = "rmse"
  ))

  # The seeds the driver reports must be the ones the documented contract
  # derives -- checked before the metrics, because a driver that both
  # misassigns and misreports could otherwise agree with a loop fed its own
  # numbers.
  expect_identical(res$.tuning_seed, ref_field(ref, "tuning_seed"))
  expect_identical(res$.outer_fit_seed, ref_field(ref, "outer_fit_seed"))

  for (i in seq_len(nrow(res))) {
    expect_identical(res$.metrics[[i]], ref[[i]]$metrics)
    expect_identical(res$.selected[[i]], ref[[i]]$selected)
    # The inner table (M49, AC1): tune's own summary of the hand run, the
    # `.iter` column included, so a search trajectory can be drawn from it.
    expect_identical(
      res$.inner_metrics[[i]],
      tune::collect_metrics(ref[[i]]$tuned)
    )
    expect_true(".iter" %in% names(res$.inner_metrics[[i]]))
  }

  # The search ran: at least one proposal was scored in some fold. Without
  # this the reference could agree with a driver that never iterated, since
  # both would then be the initial stage alone.
  proposed <- vapply(
    res$.inner_metrics,
    function(m) any(m$.iter > 0L),
    logical(1)
  )
  expect_true(any(proposed))
})

test_that("a control passed through `...` reaches every fold (M48, AC1)", {
  skip_if_no_bayes_fixture()

  d <- make_reg_data()
  wf <- bayes_workflow(d)
  folds <- det_nested(d)
  p <- bayes_param_info(wf)
  ms <- reg_metrics()
  ctrl <- ac1_control()

  res <- bayes_control_results()
  expect_true(all(res$.completed))

  ref <- memoised(reference_nested_bayes_loop(
    wf,
    folds,
    iter = 4,
    initial = 3,
    objective = tune::exp_improve(),
    param_info = p,
    metrics = ms,
    seed = 20,
    metric_name = "rmse",
    control = ctrl
  ))

  expect_identical(res$.tuning_seed, ref_field(ref, "tuning_seed"))
  expect_identical(res$.outer_fit_seed, ref_field(ref, "outer_fit_seed"))

  for (i in seq_len(nrow(res))) {
    expect_identical(res$.metrics[[i]], ref[[i]]$metrics)
    expect_identical(res$.selected[[i]], ref[[i]]$selected)
    # The candidate set, as the hand run scored it: the same rows in the
    # same order, so a fold that stopped early stopped where tune stopped --
    # and derived from the fold's table exactly as the final fit derives its
    # own from its run (D-043).
    expect_identical(
      candidate_set(res$.inner_metrics[[i]]),
      scored_candidates(ref[[i]]$tuned)
    )
    # And the table under a control that stops folds early holds exactly the
    # iterations the hand run reached (M49, AC1).
    expect_identical(
      res$.inner_metrics[[i]],
      tune::collect_metrics(ref[[i]]$tuned)
    )
  }

  # The control changed the run: `no_improve = 2` stopped at least one fold
  # short of `iter`, so its candidate set is smaller than `initial + iter`.
  scored <- vapply(candidate_sets(res), nrow, integer(1))
  expect_true(any(scored < 3L + 4L))

  # And the same run with no control stops nowhere, so the shortfall above is
  # the control's and not the fixture's.
  set.seed(20)
  plain <- memoised(nested_tune_bayes(
    wf,
    folds,
    iter = 4,
    initial = 3,
    param_info = p,
    metrics = ms
  ))
  expect_true(all(plain$.completed))
  expect_identical(
    vapply(candidate_sets(plain), nrow, integer(1)),
    rep(7L, nrow(plain))
  )
})

test_that("the Bayesian reference loop also matches with a stochastic engine", {
  skip_if_no_bayes_fixture(stochastic = TRUE)

  d <- make_reg_data()
  wf <- stoch_workflow(d)
  p <- bayes_stoch_param_info(wf)
  ms <- reg_metrics()

  set.seed(12)
  folds <- nested_resamples(
    d,
    outside = rsample::vfold_cv(v = 3),
    inside = rsample::vfold_cv(v = 3)
  )

  set.seed(21)
  res <- nested_tune_bayes(
    wf,
    folds,
    iter = 2,
    initial = 3,
    param_info = p,
    metrics = ms
  )
  expect_true(all(res$.completed))

  ref <- memoised(reference_nested_bayes_loop(
    wf,
    folds,
    iter = 2,
    initial = 3,
    objective = tune::exp_improve(),
    param_info = p,
    metrics = ms,
    seed = 21,
    metric_name = "rmse"
  ))

  expect_identical(res$.tuning_seed, ref_field(ref, "tuning_seed"))
  expect_identical(res$.outer_fit_seed, ref_field(ref, "outer_fit_seed"))

  for (i in seq_len(nrow(res))) {
    expect_identical(res$.metrics[[i]], ref[[i]]$metrics)
    expect_identical(res$.selected[[i]], ref[[i]]$selected)
  }
})

test_that("at iter = 0 the Bayesian path is the grid path on the space-filling grid", {
  skip_if_no_bayes_fixture()

  d <- make_reg_data()
  wf <- bayes_workflow(d)
  folds <- det_nested(d)
  p <- bayes_param_info(wf)
  ms <- reg_metrics()

  # The grid every fold's Bayesian run scores: built once, outside any seed
  # scope, which is the O2 premise -- and asserted rather than assumed, so a
  # dials release that started drawing this design would fail here by name.
  set.seed(1)
  g <- dials::grid_space_filling(p, size = 3)
  set.seed(2)
  again <- dials::grid_space_filling(p, size = 3)
  expect_identical(again, g)
  expect_identical(nrow(g), 3L)

  set.seed(20)
  bayes <- nested_tune_bayes(
    wf,
    folds,
    iter = 0,
    initial = 3,
    param_info = p,
    metrics = ms
  )
  set.seed(20)
  grid <- nested_tune_grid(wf, folds, grid = g, param_info = p, metrics = ms)

  expect_true(all(bayes$.completed))
  expect_true(all(grid$.completed))
  expect_identical(bayes$.tuning_seed, grid$.tuning_seed)

  for (i in seq_len(nrow(bayes))) {
    expect_identical(bayes$.metrics[[i]], grid$.metrics[[i]])
    expect_identical(bayes$.selected[[i]], grid$.selected[[i]])

    # The grid record plus an `.iter` column of zeros: the same columns in the
    # same order, holding the same values, and then the iteration.
    b <- candidate_set(bayes$.inner_metrics[[i]])
    r <- candidate_set(grid$.inner_metrics[[i]])
    expect_identical(names(b), c(names(r), ".iter"))
    for (nm in names(r)) {
      expect_identical(b[[nm]], r[[nm]])
    }
    expect_identical(b$.iter, rep(0L, nrow(r)))

    # And the grid path scored exactly the grid it was handed, so the identity
    # above is with `g` and not merely between two runs of the same code.
    expect_identical(sort(r$df1 * 100L + r$df2), sort(g$df1 * 100L + g$df2))
  }
})

# The selection rule on the Bayesian path (M69, AC1): the reference loop's
# selection is tune's selector called by name on the hand run
# (reference_select(), helper-orchestration.R), so O1 pins the rule as it
# pins the default. Measured 2026-09-06 on bayes_results()'s fixture under
# seed 20: best picks (5,1), (5,1), (1,5); one_std_err by df1 (5,1), (5,1),
# (1,10); pct_loss by df1 at limit 5 (1,5), (5,1), (1,10).

test_that("AC1: each selection rule picks what tune's selector picks on the fold's Bayesian run (M69)", {
  skip_if_no_bayes_fixture()

  d <- make_reg_data()
  wf <- bayes_workflow(d)
  folds <- det_nested(d)
  p <- bayes_param_info(wf)
  ms <- reg_metrics()

  rules <- list(
    best = selection_rule("best"),
    one_std_err = selection_rule("one_std_err", df1),
    pct_loss = selection_rule("pct_loss", df1, limit = 5)
  )
  # One reference tuning stage for the configuration -- the one the default
  # oracle above built, served from the cache -- and each rule applied to it
  # through reference_with_rule() (M74).
  set.seed(20)
  ref_best <- memoised(reference_nested_bayes_loop(
    wf,
    folds,
    iter = 2,
    initial = 3,
    objective = tune::exp_improve(),
    param_info = p,
    metrics = ms,
    seed = 20,
    metric_name = "rmse"
  ))
  picked <- list()
  for (nm in names(rules)) {
    set.seed(20)
    res <- nested_tune_bayes(
      wf,
      folds,
      iter = 2,
      initial = 3,
      param_info = p,
      metrics = ms,
      select = rules[[nm]]
    )
    expect_true(all(res$.completed), info = nm)
    ref <- reference_with_rule(ref_best, wf, folds, ms, rules[[nm]], "rmse")
    for (i in seq_len(nrow(res))) {
      expect_identical(res$.selected[[i]], ref[[i]]$selected, info = nm)
      expect_identical(res$.metrics[[i]], ref[[i]]$metrics, info = nm)
    }
    expect_identical(extract_procedure(res)$select, rules[[nm]])
    picked[[nm]] <- res$.selected
  }

  # The rule reached the selection (see the note above).
  expect_false(identical(picked$one_std_err, picked$best))
  expect_false(identical(picked$pct_loss, picked$best))
})
