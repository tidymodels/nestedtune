# M101: The outer average honors tune's resample weights

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP2
- **Resolves:** —
- **Surface tier:** user-facing — the numbers collect_metrics(), print, summary, autoplot and compute_metrics() report
- **Branch/PR:** —

## Goal

A nested design carrying tune's `.resample_weights` attribute (set by `tune::add_resample_weights()`, which accepts a `nested_resamples` object today) yields a weighted outer average, with tune 2.1.0's weighted mean and standard error over the folds that scored.

## Scope

**In:** `summarize_folds()` (`R/nested-results.R:809`) reading per-fold weights; the results object recording the weights aligned to its label columns so every reader that shares `summarize_folds()` (`collect_metrics()`, print, `summary()`, `autoplot()`, `compute_metrics()`) reports them; the shared help template stating the door and the `NA`-fold divergence; a tune issue asking whether its weighted branch means to return `NA` on a failed fold.

**Out:** a `weights` argument on the orchestrators (a candidate row; D-030's per-argument rule and a D-entry would apply); weights on the inner resamples (tune reads them itself, GP1); `nested_final_fit()`'s summary, which reports no estimate by design (IP3).

## Acceptance criteria

- [ ] AC1: For a nested design carrying `.resample_weights`, `collect_metrics()` reports, per metric, `mean` equal to `stats::weighted.mean()` of the folds with a non-`NA` `.estimate` by their weights, and `std_err` equal to the weighted standard deviation of those estimates over the square root of their effective sample size, both as tune 2.1.0's `estimate_tune_results()` computes them on non-`NA` inputs; `n` stays the count of folds that scored; a run with one failed fold reports these over the folds that scored.
- [ ] AC2: A design without the attribute reports numbers identical to before: every `collect_metrics()`, `print`, `summary()` and `autoplot()` snapshot present at the branch point passes unedited.
- [ ] AC3: On a weighted run, `compute_metrics()` with the run's own metric set returns `collect_metrics()`'s rows (D-063's promise), and `collect_metrics(summarize = FALSE)` carries a `.weight` column holding each fold's weight.
- [ ] AC4: `?nested_tune_grid` states, through the shared template, that weights set with `tune::add_resample_weights()` on the design reach the outer average, and that a failed fold is dropped and the weights renormalized, where tune returns `NA`.
- [ ] AC5: `devtools::test()` clean, `devtools::check()` at 0 errors, 0 warnings, 0 notes, and every sweep `--list-gating` names runs clean.

## Coverage

- AC1 → T1, T2
- AC2 → T2
- AC3 → T2, T3
- AC4 → T4
- AC5 → T5

## Tasks

- [ ] T1: Tests first: a weighted design through `nested_fit_resamples()` and `nested_tune_grid()`; expected `mean` and `std_err` computed in the test from tune's formulas (read from `deparse(tune:::estimate_tune_results)` and `tune:::.weighted_sd`, lines cited in a comment, the M28 lesson), on all folds and with one fold failed; the unweighted path unchanged (existing snapshots).
- [ ] T2: Record the weights on the results object (`R/nested-results.R:44` constructor, from `attr(design, ".resample_weights")`; `check_results_record()` tolerates its absence for older records) and weight `summarize_folds()`'s mean and SE when present; `n` unchanged; grep every caller of `summarize_folds()` and `per_fold_metrics()` first (M41 lesson).
- [ ] T3: `collect_metrics(summarize = FALSE)` and `compute_metrics()` carry `.weight`; a test that the two agree on a weighted run; the set path through `stack_set()`.
- [ ] T4: The shared reproducibility or estimate template gains the weights paragraph; a NEWS bullet; file the tune issue and record its URL in the work log.
- [ ] T5: `devtools::test()`, `devtools::check()`, gating sweeps (`--roxygen --plain` too), `air format --check`.

## Work log

- 2026-09-16: created by /milestone-plan from the candidate row added 2026-09-13 (M092 Out).
- 2026-09-16: plan gate chose dropping a failed fold's `NA` and renormalizing over tune's weighted-branch `NA` because the package's unweighted path and tune's unweighted branch both drop `NA`, so one failed fold must not blank a weighted run; falsified by tune confirming the `NA` is intended.
- 2026-09-16: plan gate chose the `add_resample_weights()` door alone over a `weights` argument on the orchestrators because the door already works on a `nested_resamples` object (probed 2026-09-16) and adds no formal; falsified by a user unable to reach the attribute through it.

## Decisions

## Review
