# Oracle records for nested_tune_grid() (DESIGN Conventions: oracles are
# recorded in the test file that asserts them).
#
# Source: the tidymodels pipeline itself, recomputed at test
#   time by reference_nested_loop() in helper-orchestration.R, which is written
#   from the documented seed contract rather than from the driver. Pinned by
#   "per-fold metrics and selections match a hand-rolled reference loop"
#   (deterministic and stochastic variants).
#
# No external source; the agreement between two independent internal
#   routes is the check. With a single-candidate grid there is nothing to
#   select, so nested CV must degenerate to ordinary CV and per-fold metrics
#   must equal tune::fit_resamples() on the same outer rset. Pinned by "a
#   single-candidate grid degenerates to fit_resamples()". Deterministic engine
#   only: matching fit_resamples() with a stochastic engine would require
#   replicating tune's internal substream derivation.
#
# The evaluated-candidate record, rather than the estimate, is checked against
#   tune::tune_grid() itself, re-run by hand on a fold's own inner resamples
#   under that fold's `.tuning_seed` with the generator kind pinned, exactly as
#   the roxygen's by-hand reproduction recipe prescribes. Pinned by "an integer
#   grid records the candidates that fold actually expanded". A tune_results
#   carries no record of its own expansion -- attributes are `parameters`,
#   `metrics`, `outcomes`, `rset_info` and nothing else (measured on tune 2.1.0)
#   -- so re-running is the only route to an independent answer.
#
# The companion check covers the branch that re-run cannot reach: a data-frame
#   grid must come back as itself, since nothing expands. Pinned in
#   test-nested-tune-grid-results.R ("each fold records the candidates its inner
#   tuning actually scored").
#
# Observed, not asserted. On tune 2.1.0, integer-grid expansion is
# stochastic for a continuous parameter, so folds tuning under their own seeds
# search different candidate sets. Measured on the fixture the integer-grid
# test below builds -- cont_workflow(), grid = 5, seeds 11 and 20 -- the three
# outer folds expanded thresholds:
#
#   fold 1: 0.00059 0.24510 0.50336 0.74564 0.98373
#   fold 2: 0.03347 0.25516 0.49639 0.75686 0.99656
#   fold 3: 0.00259 0.23142 0.48026 0.74269 0.99798
#
# This is why the record is a column and not one attribute: no single value
# describes what this run searched. It is recorded rather than asserted because
# it is a property of tune's expansion, which the package declines to guarantee
# across tune versions -- asserting it would turn a correct package red on an
# upstream change. The integer-grid test below asserts the part that IS this
# package's contract: each fold's record matches what that fold ran.

skip_heavy_on_cran()

test_that("per-fold metrics and selections match a hand-rolled reference loop", {
  skip_if_no_engines()

  d <- make_reg_data()
  wf <- det_workflow(d)
  ms <- reg_metrics()
  grid <- det_grid()

  set.seed(11)
  folds <- nested_resamples(
    d,
    outside = rsample::vfold_cv(v = 3),
    inside = rsample::vfold_cv(v = 3)
  )

  set.seed(20)
  res <- nested_tune_grid(wf, folds, grid = grid, metrics = ms)

  ref <- memoised(reference_nested_loop(
    wf,
    folds,
    grid,
    ms,
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
  }
})

test_that("the reference loop also matches with a stochastic engine", {
  skip_if_no_engines(stochastic = TRUE)

  d <- make_reg_data()
  wf <- stoch_workflow(d)
  ms <- reg_metrics()
  grid <- stoch_grid()

  set.seed(12)
  folds <- nested_resamples(
    d,
    outside = rsample::vfold_cv(v = 3),
    inside = rsample::vfold_cv(v = 3)
  )

  set.seed(21)
  res <- memoised(nested_tune_grid(wf, folds, grid = grid, metrics = ms))

  ref <- memoised(reference_nested_loop(
    wf,
    folds,
    grid,
    ms,
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

test_that("a control passed through `...` reaches the inner tune_grid()", {
  skip_if_no_engines(stochastic = TRUE)

  d <- make_reg_data()
  wf <- stoch_workflow(d)
  ms <- reg_metrics()
  grid <- stoch_grid()

  set.seed(12)
  folds <- nested_resamples(
    d,
    outside = rsample::vfold_cv(v = 3),
    inside = rsample::vfold_cv(v = 3)
  )

  # `parallel_over = "everything"` changes the seed each model fit starts
  # from even at `allow_par = FALSE`, so a stochastic engine's numbers differ
  # from the default run's: on this fixture fold 2's outer metrics and
  # selection differ and folds 1 and 3 agree (measured on tune 2.1.0). The run
  # under the control matches the reference loop run under the same control,
  # fold by fold.
  ctrl <- tune::control_grid(parallel_over = "everything")
  set.seed(21)
  res <- nested_tune_grid(wf, folds, grid = grid, metrics = ms, control = ctrl)

  ref <- memoised(reference_nested_loop(
    wf,
    folds,
    grid,
    ms,
    seed = 21,
    metric_name = "rmse",
    control = ctrl
  ))

  for (i in seq_len(nrow(res))) {
    expect_identical(res$.metrics[[i]], ref[[i]]$metrics)
    expect_identical(res$.selected[[i]], ref[[i]]$selected)
  }

  # The discrimination: the same run without the control is not this one, so
  # the match above is not the default run agreeing with itself. The plain
  # run is the stochastic oracle's, served from the cache.
  set.seed(21)
  plain <- memoised(nested_tune_grid(wf, folds, grid = grid, metrics = ms))
  expect_false(identical(plain$.metrics, res$.metrics))
})

test_that("a single-candidate grid degenerates to fit_resamples()", {
  skip_if_no_engines()

  d <- make_reg_data()
  wf <- det_workflow(d)
  ms <- reg_metrics()
  grid <- data.frame(num_comp = 2L)

  set.seed(13)
  folds <- nested_resamples(
    d,
    outside = rsample::vfold_cv(v = 3),
    inside = rsample::vfold_cv(v = 3)
  )
  # The same call under the same seed nested_resamples() makes internally, so
  # the outer splits are identical without reading them off the nested object.
  set.seed(13)
  outer <- rsample::vfold_cv(d, v = 3)

  set.seed(30)
  res <- nested_tune_grid(wf, folds, grid = grid, metrics = ms)

  plain <- tune::fit_resamples(
    tune::finalize_workflow(wf, grid),
    resamples = outer,
    metrics = ms,
    control = tune::control_resamples(allow_par = FALSE)
  )
  plain_metrics <- tune::collect_metrics(plain, summarize = FALSE)

  expect_identical(res$id, outer$id)
  for (i in seq_len(nrow(res))) {
    fold_ref <- plain_metrics[plain_metrics$id == outer$id[[i]], ]
    fold_res <- res$.metrics[[i]]
    for (m in fold_ref$.metric) {
      expect_identical(
        fold_res$.estimate[fold_res$.metric == m],
        fold_ref$.estimate[fold_ref$.metric == m]
      )
    }
  }
})

test_that("an integer grid records the candidates that fold actually expanded", {
  skip_if_no_engines()

  # The record cannot be checked against the `grid` argument here -- that is
  # the number 5 -- so the reference is tune itself, re-run by hand on the
  # fold's own inner resamples under the fold's own seed, the same reproduction
  # recipe the roxygen hands users.
  d <- make_reg_data()
  wf <- cont_workflow(d)
  ms <- reg_metrics()

  set.seed(11)
  folds <- nested_resamples(
    d,
    outside = rsample::vfold_cv(v = 3),
    inside = rsample::vfold_cv(v = 3)
  )

  set.seed(20)
  res <- nested_tune_grid(wf, folds, grid = 5, metrics = ms)
  expect_true(all(res$.completed))

  for (i in seq_len(nrow(res))) {
    set.seed(
      res$.tuning_seed[[i]],
      kind = "Mersenne-Twister",
      normal.kind = "Inversion",
      sample.kind = "Rejection"
    )
    tuned <- tune::tune_grid(
      wf,
      resamples = folds$inner_resamples[[i]],
      grid = 5,
      metrics = ms,
      control = tune::control_grid(allow_par = FALSE)
    )
    reference <- sort(unique(tune::collect_metrics(tuned)$threshold))
    expect_identical(sort(unique(res$.inner_metrics[[i]]$threshold)), reference)

    # The table itself: the fold's `.inner_metrics` is what tune
    # summarizes for the same hand run -- identical, not merely the same
    # candidates -- so a reader computing the best candidate from it computes
    # it from the inner run's own numbers.
    expect_identical(res$.inner_metrics[[i]], tune::collect_metrics(tuned))
  }
})

test_that("a grid size larger than the reachable candidates records what ran", {
  skip_if_no_engines()

  # A truncated grid is the case the `grid` attribute cannot describe at all:
  # num_comp reaches at most one candidate per predictor, so a request for 20 is
  # met by however many exist and the request stands unchanged beside it.
  d <- make_reg_data()

  set.seed(11)
  folds <- nested_resamples(
    d,
    outside = rsample::vfold_cv(v = 3),
    inside = rsample::vfold_cv(v = 3)
  )

  set.seed(20)
  res <- nested_tune_grid(
    det_workflow(d),
    folds,
    grid = 20L,
    metrics = reg_metrics()
  )

  expect_identical(attr(res, "grid"), 20L)
  for (g in candidate_sets(res)) {
    expect_identical(nrow(g), 4L)
  }
})

# Selection rules are checked against tune's own selectors, called by name on
#   the fold's hand-run tuning result inside reference_nested_loop()
#   (reference_select() in helper-orchestration.R), with the orderings the test
#   built spliced in. Pinned by the test below. The two-parameter fixture is
#   bayes_workflow() (df1, df2), on a 3-by-3 grid, so a two-term ordering with
#   desc() has something to order; the default rule is covered by "per-fold
#   metrics and selections match a hand-rolled reference loop".
#   Measured on this fixture under seed 20: best picks (2,2),
#   (2,2), (2,5); one_std_err (2,2), (8,2), (2,5); pct_loss at limit 5
#   (2,2), (5,2), (2,5). The two non-default rules each differ from best in
#   a fold, which is what lets the test tell a driver that applied the rule
#   from one that ignored it.

test_that("each selection rule picks what tune's selector picks on the fold's inner run", {
  skip_if_no_bayes_fixture()

  d <- make_reg_data()
  wf <- bayes_workflow(d)
  folds <- det_nested(d)
  p <- bayes_param_info(wf)
  ms <- reg_metrics()
  g <- expand.grid(df1 = c(2L, 5L, 8L), df2 = c(2L, 5L, 8L))

  rules <- list(
    best = selection_rule("best"),
    one_std_err = selection_rule("one_std_err", desc(df1), df2),
    pct_loss = selection_rule("pct_loss", desc(df1), df2, limit = 5)
  )
  # One reference tuning stage for the configuration, served from the cache;
  # each rule is applied to it through reference_with_rule().
  set.seed(20)
  ref_best <- memoised(reference_nested_loop(
    wf,
    folds,
    g,
    ms,
    seed = 20,
    metric_name = "rmse"
  ))
  picked <- list()
  for (nm in names(rules)) {
    set.seed(20)
    res <- memoised(nested_tune_grid(
      wf,
      folds,
      grid = g,
      metrics = ms,
      param_info = p,
      select = rules[[nm]]
    ))
    expect_true(all(res$.completed), info = nm)
    ref <- reference_with_rule(ref_best, wf, folds, ms, rules[[nm]], "rmse")
    for (i in seq_len(nrow(res))) {
      expect_identical(res$.selected[[i]], ref[[i]]$selected, info = nm)
      expect_identical(res$.metrics[[i]], ref[[i]]$metrics, info = nm)
    }
    expect_identical(extract_procedure(res)$select, rules[[nm]])
    picked[[nm]] <- res$.selected
  }

  # The rule reached the selection (see the selection-rule note above).
  expect_false(identical(picked$one_std_err, picked$best))
  expect_false(identical(picked$pct_loss, picked$best))
})

# The three rules as tune 2.1.0's `?select_best` page defines them.
test_that("each selection rule picks the candidate its definition names in the fold's inner metrics", {
  skip_if_no_bayes_fixture()

  d <- make_reg_data()
  wf <- bayes_workflow(d)
  folds <- det_nested(d)
  p <- bayes_param_info(wf)
  ms <- reg_metrics()
  g <- expand.grid(df1 = c(2L, 5L, 8L), df2 = c(2L, 5L, 8L))

  rules <- list(
    best = selection_rule("best"),
    one_std_err = selection_rule("one_std_err", desc(df1), df2),
    pct_loss = selection_rule("pct_loss", desc(df1), df2, limit = 5)
  )
  # rmse is minimized. Simplest first is large df1, then small df2.
  pick <- function(m, rule) {
    m <- m[m$.metric == "rmse", ]
    best <- which.min(m$mean)
    if (rule == "best") {
      keep <- seq_len(nrow(m)) == best
    } else if (rule == "one_std_err") {
      keep <- m$mean <= m$mean[[best]] + m$std_err[[best]]
    } else {
      keep <- (m$mean - m$mean[[best]]) / m$mean * 100 < 5
    }
    m <- m[keep, ]
    m <- m[order(-m$df1, m$df2), ]
    c(df1 = m$df1[[1L]], df2 = m$df2[[1L]])
  }

  runs <- lapply(rules, function(rule) {
    set.seed(20)
    memoised(nested_tune_grid(
      wf,
      folds,
      grid = g,
      metrics = ms,
      param_info = p,
      select = rule
    ))
  })
  # The rule changes only what is selected, so one run's inner metrics serve all three.
  inner <- runs$best$.inner_metrics
  expect_identical(runs$one_std_err$.inner_metrics, inner)
  expect_identical(runs$pct_loss$.inner_metrics, inner)
  for (nm in names(rules)) {
    for (i in seq_along(inner)) {
      sel <- runs[[nm]]$.selected[[i]]
      expect_identical(
        c(df1 = sel$df1, df2 = sel$df2),
        pick(inner[[i]], nm),
        info = paste(nm, "fold", i)
      )
    }
  }
  picked <- lapply(runs, function(r) r$.selected)
  expect_false(identical(picked$one_std_err, picked$best))
  expect_false(identical(picked$pct_loss, picked$best))
  expect_false(identical(picked$one_std_err, picked$pct_loss))
})

# The desirability rule is checked against
#   desirability2::select_best_desirability(), called by name with the terms
#   written out here, on each fold's hand-run tuning result from
#   reference_nested_loop() under the default rule, the same cached run the
#   selection-rule note above reads. Only the parameter columns and `.config`
#   are compared. Measured on this fixture under seed 20 (tune 2.1.0,
#   desirability2 0.2.0): best picks (2,2), (2,2), (2,5), and the terms below
#   pick (2,2), (2,2), (2,2). The third fold differs, which is what lets the
#   test tell a driver that applied the rule from one that ignored it.

test_that("the desirability rule picks what desirability2 picks on the fold's inner run", {
  skip_if_no_bayes_fixture()
  skip_if_not_installed("desirability2", minimum_version = "0.2.0")

  d <- make_reg_data()
  wf <- bayes_workflow(d)
  folds <- det_nested(d)
  p <- bayes_param_info(wf)
  ms <- reg_metrics()
  g <- expand.grid(df1 = c(2L, 5L, 8L), df2 = c(2L, 5L, 8L))
  cols <- c("df1", "df2", ".config")

  set.seed(20)
  ref_best <- memoised(reference_nested_loop(
    wf,
    folds,
    g,
    ms,
    seed = 20,
    metric_name = "rmse"
  ))
  rule <- selection_rule(
    "desirability",
    minimize(rmse),
    maximize(rsq),
    minimize(df1),
    minimize(df2)
  )
  set.seed(20)
  res <- nested_tune_grid(
    wf,
    folds,
    grid = g,
    metrics = ms,
    param_info = p,
    select = rule
  )
  expect_true(all(res$.completed))
  expect_identical(extract_procedure(res)$select, rule)
  for (i in seq_len(nrow(res))) {
    ref <- desirability2::select_best_desirability(
      ref_best[[i]]$tuned,
      minimize(rmse),
      maximize(rsq),
      minimize(df1),
      minimize(df2)
    )
    expect_identical(
      res$.selected[[i]][cols],
      ref[cols],
      info = paste("fold", i)
    )
  }

  # The rule reached the selection (see the desirability note above).
  best <- lapply(ref_best, function(fold) fold$selected[cols])
  expect_false(identical(lapply(res$.selected, `[`, cols), best))
})
