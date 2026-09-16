# M101: The outer average honors tune's resample weights

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP2
- **Resolves:** —
- **Surface tier:** user-facing — the numbers collect_metrics(), print, summary, autoplot and compute_metrics() report
- **Branch/PR:** m101-resample-weights · https://github.com/tidymodels/nestedtune/pull/114

## Goal

A nested design carrying tune's `.resample_weights` attribute (set by `tune::add_resample_weights()`, which accepts a `nested_resamples` object today) yields a weighted outer average, with tune 2.1.0's weighted mean and standard error over the folds that scored.

## Scope

**In:** `summarize_folds()` (`R/nested-results.R:809`) reading per-fold weights; the results object recording the weights aligned to its label columns so every reader that shares `summarize_folds()` (`collect_metrics()`, print, `summary()`, `autoplot()`, `compute_metrics()`) reports them; the shared help template stating the door and the `NA`-fold rule; a tune issue reporting that its weighted branch errors on a fold scoring `NA` and ignores the weights, with a warning, on a fold that failed.

**Out:** a `weights` argument on the orchestrators (a candidate row; D-030's per-argument rule and a D-entry would apply); weights on the inner resamples (tune reads them itself, GP1); `nested_final_fit()`'s summary, which reports no estimate by design (IP3).

## Acceptance criteria

- [x] AC1: For a nested design carrying `.resample_weights`, `collect_metrics()` reports, per metric, `mean` equal to `stats::weighted.mean()` of the folds with a non-`NA` `.estimate` by their weights, and `std_err` equal to the weighted standard deviation of those estimates over the square root of their effective sample size, both as tune 2.1.0's `estimate_tune_results()` computes them on non-`NA` inputs; `n` stays the count of folds that scored; a run with one failed fold reports these over the folds that scored.
- [x] AC2: A design without the attribute reports numbers identical to before: every `collect_metrics()`, `print`, `summary()` and `autoplot()` snapshot present at the branch point passes unedited.
- [x] AC3: On a weighted run, `compute_metrics()` with the run's own metric set returns `collect_metrics()`'s rows (D-063's promise), and `collect_metrics(summarize = FALSE)` carries a `.weight` column holding each fold's weight.
- [x] AC4: Each of the five orchestrator help pages (`?nested_tune_grid`, `?nested_tune_bayes`, `?nested_tune_race`, `?nested_tune_sim_anneal`, `?nested_fit_resamples`) states, through the shared template, that weights set with `tune::add_resample_weights()` on the design reach the outer average, and that a fold that fails or scores `NA` is dropped and the weights renormalized over the folds that scored.
- [x] AC5: `devtools::test()` clean, `devtools::check()` at 0 errors, 0 warnings, 0 notes, and every sweep `--list-gating` names runs clean.

## Coverage

- AC1 → T1, T2
- AC2 → T2
- AC3 → T2, T3
- AC4 → T4
- AC5 → T5

## Tasks

- [x] T1: Tests first: a weighted design through `nested_fit_resamples()` and `nested_tune_grid()`; expected `mean` and `std_err` computed in the test from tune's formulas (read from `deparse(tune:::estimate_tune_results)` and `tune:::.weighted_sd`, lines cited in a comment, the M28 lesson), on all folds and with one fold failed; the unweighted path unchanged (existing snapshots).
- [x] T2: Record the weights on the results object (`R/nested-results.R:44` constructor, from `attr(design, ".resample_weights")`; `check_results_record()` tolerates its absence for older records) and weight `summarize_folds()`'s mean and SE when present; `n` unchanged; grep every caller of `summarize_folds()` and `per_fold_metrics()` first (M41 lesson).
- [x] T3: `collect_metrics(summarize = FALSE)` and `compute_metrics()` carry `.weight`; a test that the two agree on a weighted run; the set path through `stack_set()`.
- [x] T4: The shared reproducibility or estimate template gains the weights paragraph; a NEWS bullet; file the tune issue and record its URL in the work log.
- [x] T5: `devtools::test()`, `devtools::check()`, gating sweeps (`--roxygen --plain` too), `air format --check`.

## Work log

- 2026-09-16: created by /milestone-plan from the candidate row added 2026-09-13 (M092 Out).
- 2026-09-16: plan gate chose dropping a failed fold's `NA` and renormalizing over tune's weighted-branch `NA` because the package's unweighted path and tune's unweighted branch both drop `NA`, so one failed fold must not blank a weighted run; falsified by tune confirming the `NA` is intended.
- 2026-09-16: plan gate chose the `add_resample_weights()` door alone over a `weights` argument on the orchestrators because the door already works on a `nested_resamples` object (probed 2026-09-16) and adds no formal; falsified by a user unable to reach the attribute through it.
- 2026-09-16: /milestone-implement started; branch m101-resample-weights cut from main at 3166268.
- 2026-09-16: question gate chose a `resample_weights` attribute keyed by the fold label columns over a `.weight` record column, so a reordered run keeps each fold's weight and the print is unchanged; a new shared template `section-resample-weights.R` on the five orchestrator pages over a paragraph in the reproducibility template; and filing the tune issue with gh at T4.
- 2026-09-16: amendment (substantive): the plan's premise that tune's weighted branch returns `NA` on a missing fold was read from its code, not run; run on tune 2.1.0, a fold scoring `NA` makes `collect_metrics()` error in `cov.wt()` and a failed fold makes tune ignore the weights with a warning. Mini gate chose AC4 stating this package's rule alone over naming tune's observed behavior; Scope In's issue clause reworded to what the issue reports.
- 2026-09-16: re-audit: AC4 (full) — one finding: the criterion bound `?nested_tune_grid` alone while the template sits on five pages; fixed by naming the five pages.
- 2026-09-16: re-audit: AC4 (full) — nothing.
- 2026-09-16: T1 to T3 done in one checkpoint: `tests/testthat/test-resample-weights.R` (two oracle types for AC1: tune's formulas written out, and `tune::fit_resamples()` under the same weights; a planted wrong SE divisor fails 9 assertions), the `resample_weights` attribute keyed by fold label in the constructor and carried by `stamp_results()`, `.weight` on the per-fold table, the weighted branch of `summarize_folds()`; T1's tests were red before T2 and are committed with it. `devtools::test()` clean, `air format --check` clean, `sweep-prose.R --plain` clean.
- 2026-09-16: T4 done: `man-roxygen/section-resample-weights.R` on the five orchestrator pages, NEWS bullet, `--roxygen --plain` sweep clean.
- 2026-09-16: tune issue filed as approved at the question gate: https://github.com/tidymodels/tune/issues/1197 (its weighted branch errors on an `NA` estimate and ignores the weights on a failed resample).
- 2026-09-16: claim audit: 41 claims read, 2 corrected — R/nested-results.R (fold_weights() comment), tests/testthat/test-resample-weights.R (NA-fold test read its estimates off the run under test); the session also corrected three "tune returns NA" sentences the reader had passed (NEWS.md, the summarize_folds() comment, the test header), against the tune#1197 reprex; the reader's one re-read of the corrected sites holds.
- 2026-09-16: T5 done: `devtools::check()` at 577b73c 0 errors, 0 warnings, 0 notes (9m 18s); all six `--list-gating` sweeps clean; `devtools::test()` clean; the claim-audit corrections after that check touch comments, NEWS and one test, and `test-resample-weights.R` reruns clean. Status → review.

## Decisions

## Review

- 2026-09-16 evidence at 147ab14, branch in sync with main (0 behind).
- AC1: `devtools::test()` clean (FAIL 0, WARN 0, PASS 10421); `test-resample-weights.R` holds both oracles: O1 recomputes tune 2.1.0's `weighted.mean`, `cov.wt`-based weighted sd and `sum(w)^2/sum(w^2)` from the unweighted run's per-fold estimates, on `nested_fit_resamples()` and `nested_tune_grid()`, on all folds, with one fold failed (`n` = 2, no NA mean or SE) and with one fold scoring NA; O2 matches `tune::fit_resamples()` under the same weights to 1e-12. Formulas re-read from `deparse(tune:::estimate_tune_results)`, `.weighted_sd`, `.effective_sample_size` at tune 2.1.0 today and agree with `weighted_std_err()`. Verified.
- AC2: `git diff origin/main..HEAD -- tests/testthat/_snaps/` names 0 files; every snapshot passes in the clean test run; the equal-weights test shows an identical `collect_metrics()` to the unweighted run. Verified.
- AC3: tests "compute_metrics() with the run's metric set is collect_metrics() on a weighted run" (identical summarized and per-fold, `.weight` present) and "collect_metrics(summarize = FALSE) carries each fold's weight, by fold label" (also under a reordered run and on a stacked set) pass. Verified.
- AC4: `grep` finds `add_resample_weights` and the "scaled up to sum to one" NA-fold sentence in each of the five Rd files (grid, bayes, race, sim_anneal, fit_resamples); `devtools::document()` produces no diff. Verified.
- AC5: `devtools::check()` at 147ab14: 0 errors, 0 warnings, 0 notes (7m 44s); `devtools::test()` clean; all six `--list-gating` sweeps clean. Verified.
- Driving RR: none; projection-vs-outcome no-ops.
- Consistency gate: `cairn_validate.py` exit 0 (18 references-staleness advisories, pre-existing); no principle changed, `cairn_impact` skipped; `document()` no diff; README.md in sync; `pkgdown::check_pkgdown()` no problems; NEWS bullet present without milestone numbers; `man-roxygen` in `.Rbuildignore`; `air format --check` clean.
- Independent review 2026-09-16: [S] blame-history lens: no findings (run_attributes/stamp_results follow the M38 id_columns pattern; summarize_folds NA rule unchanged since M03). [S] prior-review lens: no prior-review evidence on the touched files (archive read; the gh probe found real threads, none on these files). [O] diff-bug lens: 11 findings, triaged at the gate (user chose "apply fix-nows, re-verify, re-pose merge"):
  - F1 fold_weights() comment claimed a NA-weight row unreachable while `x$id[2] <- "zzz"` reaches it and cov.wt() then errors — fix now: comment reworded to name the door; the mutation itself is outside the class's doors and unchanged.
  - F2 weights c(0, 0, 1) with fold 3 failed leave w = c(0, 0) and cov.wt() aborts with a stats error — fix now: a metric whose scoring folds carry zero weight reads NA mean and std_err, `n` unchanged; test added.
  - F3 ?collect_metrics "Reading std_err" stated the unweighted formula and "What the two shapes hold" omitted `.weight` — fix now: both sections amended.
  - F4 the help does not name tune's divergence (tune#1197) — rejected: the 2026-09-16 mini gate chose stating this package's rule alone; NEWS and code comments name the divergence.
  - F5 the all-NA `.weight` guard's comment described a set the API cannot build — fix now: comment reworded; guard kept.
  - F6 O1 mirrors the implementation's cov.wt() call — rejected: O2 (tune::fit_resamples) is independent on the every-fold case, and the failed-fold rule is this package's own, with no external oracle.
  - F7 a malformed hand-set `.resample_weights` reads as unweighted — rejected: tune validates at its door.
  - F8 an rset reordered after add_resample_weights() mispairs weights — rejected: tune's own `.create_weight_mapping()` behaves identically (GP1).
  - F9 duplicate fold labels take the first weight — rejected: no reachable rsample scheme produces them.
  - F10 DESIGN.md has no note on the results object's weights — follow-up: written in the step-9 hygiene commit.
  - F11 no test for the attribute shedding with the class or for a zero weight — fix now: both tests added.
- Fix-now re-verification: `devtools::test()` FAIL 0, WARN 0, PASS 10428; `document()` regenerated collect_metrics.nested_results.Rd, no further diff; `air format --check` clean; all six sweeps clean; `devtools::check()` result recorded below.
- `devtools::check()` at 27cd920: 0 errors, 0 warnings, 0 notes. AC5 holds after the fix-nows.
- 2026-09-16: step-7 approval: m101-resample-weights approved for merge (after fix-nows F1, F2, F3, F5, F11).
- 2026-09-16: resume: PR #114 OPEN; re-entering at step 1 (route c). CI red on ubuntu-latest (release): the set test in test-resample-weights.R failed with "there is no package called 'workflowsets'" because it used the bare engine skip; fixed by the shared `skip_if_no_wset_fixture()` skip every other set test uses (a test-guard change, no runtime surface). Trivial fix, no re-approval requested. `devtools::test(filter = "resample-weights")` clean.
- conversation: PR #114 — empty read (0 reviews, 0 comments, 0 unresolved threads).
- 2026-09-16: step-7 approval: m101-resample-weights approved for merge (re-posed after the CI skip fix).
