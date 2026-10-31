# M167: Add second oracles to one-type parts

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP2
- **Resolves:** —
- **Surface tier:** internal — tests and in-repo tracking records; no package code or user doc changes
- **Branch/PR:** m167-one-type-parts

## Goal

Back each of the three parts that the candidate row "Add second oracles to one-type parts" names with oracles of two independent types: the survival branch of `compute_metrics()`, the racing record's rows for eliminated candidates, and the final fit under `event_level`.

## Scope

**In:** two tests on a censored-regression run whose metric set holds a static, a dynamic and a linear-predictor survival metric (`concordance_survival`, `brier_survival`, `royston_survival`). One test on the eliminated rows of a racing fold record, and one on the final fit's tuning run under `event_level = "second"`. A new test fixture where an existing one cannot show a defect in a part. `cairn/ORACLES.md` rows and group lines for the new oracles.

**Out:** the racing record under `nested_tune_race_win_loss()`, since both racers write the record through one body, `nested_tune_race()`. Pointing the oracle headers of the test files at the registry stays with its parked row. No change to package code; a defect a new test finds goes to `/hotfix`.

## Acceptance criteria

- [x] AC1: A test in `test-compute-metrics.R` asserts, at `summarize = TRUE` and at `summarize = FALSE`, that `compute_metrics()` called with a censored-regression run's own metric set equals `collect_metrics()` on that run, where the metric set holds a static, a dynamic and a linear-predictor survival metric.
- [x] AC2: A test in `test-compute-metrics.R` asserts that `compute_metrics()` on a censored-regression run, with a metric set holding a static, a dynamic and a linear-predictor survival metric, equals yardstick called metric by metric on each fold's rows of `collect_predictions()`, both per fold and in a summary computed in the test.
- [x] AC3: A test asserts, on a `nested_tune_race_anova()` run in which at least one fold eliminated a candidate, each eliminated candidate's row in the `.inner_metrics` of a fold that eliminated a candidate against an oracle whose type is not live.
- [x] AC4: A test asserts the tuning run that `nested_final_fit()` stores under `event_level = "second"` against an oracle whose type is not live, on input where the first and second levels give different values for at least one metric the oracle checks.
- [x] AC5: In `cairn/ORACLES.md`, each of the tests that AC1-AC4 name appears as a test line under a row with id, type and source. A test whose type and source match an existing row goes under that row, and any other test gets a new row. The `compute_metrics()`, racing and event-level groups each credit their part to rows of two types, and `grep -n 'Add second oracles to one-type parts' cairn/ORACLES.md` prints nothing.
- [x] AC6: `devtools::test()` runs clean.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T4
- AC5 → T5
- AC6 → T6

## Tasks

- [x] T1: Survival branch, invariant. In `test-compute-metrics.R`, beside the censored test at :192, add a run helper beside `saved_srv_run()` (:39) whose metric set holds the three kinds, with `save_pred = TRUE`; `saved_srv_run()` stays as it is, since other tests read its Brier-only set. Assert `compute_metrics()` against `collect_metrics()` at both `summarize` values. Plant: swap the static and linear-predictor estimates in `score_fold()` (R/nested-results-collect.R:840), see the test fail, and restore.
- [x] T2: Survival branch, live. Beside the yardstick tests at :207, score each fold's rows of `collect_predictions()` with `concordance_survival()`, `brier_survival()` and `royston_survival()` called one by one, summarize by hand as the numeric test does, and compare per fold and summarized. Plant: drop the dynamic `.pred` argument in `score_fold()`, see the test fail, and restore.
- [x] T3: Racing eliminated rows. In `test-nested-tune-race-oracles.R`, beside the test at :186, read which inner resamples the race scored each eliminated candidate on from the race's unsummarized metrics. Compare the candidate's `mean` and `n` with `nested_tune_grid()` over an inner design cut to those resamples (invariant, as `nested-tune-race-oracles/O2` is for survivors). If the grid path cannot be cut that way, refit the candidate on those inner analysis sets and compute its metric by formula (closed-form), building a fixture if the stochastic one cannot be refit exactly. Plant: store finetune's survivors alone (`all_configs = FALSE`), see the test fail, and restore.
- [x] T4: Final fit under `event_level`. In `test-event-level.R`, beside the test at :206, count sensitivity and specificity at the second level from the final fit's stored tuning run (closed-form, as `event-level/O1` counts for the outer folds), from its saved predictions or from a refit of each candidate. Build a fixture if `cls_*` cannot give a count that matches exactly. Plant: drop `event_level` from the final fit's tuning call, see the test fail, and restore.
- [x] T5: Registry. Add the AC5 test lines and rows under the file's quoting rule, and rewrite the three group lines at `cairn/ORACLES.md` :90, :240 and :311 so each credits its part to rows of two types (D-123 (1)). Re-point `helper-time-budget.R` rows for the new blocks in one pass.
- [x] T6: Run `devtools::test()` and `air format --check .` clean.

## Work log

- 2026-10-31: created by /milestone-plan.
- 2026-10-31: tier check: not run — work named at the question set.
- 2026-10-31: idea vet: gap — static and linear-predictor survival metrics reach no test, so a "second" oracle leaves them on one type; reading taken: bring each part to two types, the row's aim under GP2. No flaw. Checked by execution: tune 2.1.0 scores linear-predictor survival metrics (`pred_type()`, `maybe_estimate()`), and the survival engine of `survival_reg()` predicts `time` and `linear_pred`.
- 2026-10-31: question set: what to work on — the candidate row "Add second oracles to one-type parts"; a part no existing fixture can show a defect in — build a new fixture rather than record it as owing none or leave it on the row. No permission, file or access was asked.
- 2026-10-31: lessons used: 2026-10-31 (M166) credit a part only when its input can show a defect; 2026-10-31 (M164) a plant must be one the fixture can show; 2026-10-31 (M164) `info =` takes a character value; 2026-10-31 (M163) registry upkeep; 2026-10-22 (M152) re-point time-budget rows once, one racer where the record path is shared; 2026-09-16 (M101) skip helpers; 2026-07-27 (M12) memoised fixtures and RNG state.
- 2026-10-31: collision check: absorbs in full the candidate row "Add second oracles to one-type parts". D-123 created that row and is applied, not changed; D-121 is related. M164 and M166 are done and left these parts. Inbox: 1 open issue (#91, held by a parked row), 0 open PRs, no overlap. Investigation inline over the three groups' tests and `score_fold()`.
- 2026-10-31: criteria audit (reduced mode, internal tier; fresh Opus reader): AC1, AC2, AC4, AC6 no finding. AC5: "each oracle the tests add" had no list behind it, and a test matching an existing row's type and source adds no row; rewritten to the four named tests, filed under a matching row or a new one. AC3: "that fold" was unclear with several eliminating folds; narrowed to a fold that eliminated a candidate.
- 2026-10-31: plan gate chose an invariant against the grid orchestrator over an inner design cut to the race's resamples for the eliminated rows, over `tune::tune_grid()` called by the test, because the latter is live, the type O3 already holds; falsified by the cut grid's mean differing from the race's for a survivor scored on all resamples.
- 2026-10-31: plan gate chose a closed-form count for the final fit under `event_level` over a level-swap invariant (relevel `y`, run at `"first"`), because `vfold_cv(strata = y)` may draw other splits when the level order changes, which is unchecked; falsified by the swapped run drawing identical inner splits.
- 2026-10-31: plan gate chose one milestone over three, because four tests and the registry edit fit two sessions like M164 and M166; falsified by the plan-owned body passing the cap or T1-T5 not fitting two sessions.
- 2026-10-31: implement started; branch m167-one-type-parts cut from main at 6b374208.
- 2026-10-31: T1/T2 minor amendment: the planned swap plant passed on the unmodified run, since survreg's `.pred_time` rises with `.pred_linear_pred` and both metrics score by rank. Per the fixture answer, added `reverse_pred()` (one column reversed per fold) and an invariant test, "reordering a censored run's `.pred_time` moves only the static metric, and its `.pred_linear_pred` only the linear-predictor metric"; the live test runs on `.pred_time` reversed. The collect_metrics() test (AC1) cannot show the swap.
- 2026-10-31: T1/T2 done. Tests: AC1 "with a static, a dynamic and a linear-predictor metric, compute_metrics() is collect_metrics() on a censored-regression run"; AC2 "a static, a dynamic and a linear-predictor metric on a censored run are yardstick on each fold's rows"; the reordering invariant. Plants: static/linear swap failed the invariant (4) and live (5) tests; `.pred` reversed in the survival branch failed the old censored, AC1 and live tests; each restored. File: 23 tests clean.
- 2026-10-31: T3 minor amendment: the cut-design invariant fails on the stochastic fixture (ranger's seeds depend on the design's size: 1.97 against the race's 1.84 for `min_n = 25`, fold 1, seed 24), so the test runs on the deterministic fixture, whose race eliminates `num_comp = 1` in each fold and `num_comp = 3` in fold 3 (`race_results()`), resample ids read from the memoised reference race at seed 20. No new fixture was needed.
- 2026-10-31: T3 done. Test "an eliminated candidate carries the grid path's mean over the resamples the race scored it on" (invariant), 25 expectations. Plants: `all_configs = FALSE` and a 1e-9 shift of eliminated means in `inner_metrics_table()` each failed it (9 failures); restored.
- 2026-10-31: correction to the T3 amendment line: at seed 20 `race_results("tune_race_anova")` eliminates `num_comp = 1` alone in each of the three folds; the `num_comp = 3` elimination in fold 3 came from a seed-24 probe.
- 2026-10-31: T4 done. Test "the final fit's tuning run reports the sensitivity counted at the second level" (closed-form), on a `save_pred = TRUE` grid run at `event_level = "second"`, whose control the final fit reuses: 9 resample-candidate pairs, each count equal to tune's `sens` and differing from the first level's count. Plant: `event_level = "first"` where `nested_final_fit()` reads the procedure (R/nested-final-fit.R:228) failed it (9) and `event-level/O2`'s test (4); restored. A plant at `effective_control()` (:267) passed both, since `run_tuner()` sets the level again from its own argument.
- 2026-10-31: T5 done. `cairn/ORACLES.md`: rows `compute-metrics/O1` (invariant), `nested-tune-race-oracles/O5` (invariant), `event-level/O3` (closed-form); the AC1 test under `compute-metrics/U1` and the AC2 test under `compute-metrics/U2`, both "(found by reading)"; the three group lines rewritten and the header's two milestone sentences extended; `grep -n 'Add second oracles to one-type parts' cairn/ORACLES.md` prints nothing. The compute_metrics test header now quotes the invariant's test after "Pinned by". `helper-time-budget.R` names none of the three changed files, so no row moved.
- 2026-10-31: T6 done. `devtools::test()` run alone: 1169 tests, 0 failed, 0 errors, 0 skipped; `air format --check .` clean.
- 2026-10-31: claim audit: not owed — internal tier.
- 2026-10-31: implement complete; status review.
- 2026-10-31: step-7 approval: m167-one-type-parts approved for merge

## Decisions

## Review

Sync: branch level with origin/main at 6b374208; no PR; Copilot round off (no `# Copilot review:` line).

- AC1: `test-compute-metrics.R` :: "with a static, a dynamic and a linear-predictor metric, compute_metrics() is collect_metrics() on a censored-regression run" passes (file run 2026-10-31 at f4d1008b: 23 tests, 0 failed, 0 errors, 0 skipped). It loops `summarize` over TRUE and FALSE with `srv_kinds_metrics()` (`concordance_survival` static, `brier_survival` dynamic, `royston_survival` linear-predictor) and `expect_identical()` against `collect_metrics()`.
- AC2: `test-compute-metrics.R` :: "a static, a dynamic and a linear-predictor metric on a censored run are yardstick on each fold's rows" passes in the same run. It scores `collect_predictions()` rows per fold with the three yardstick functions called one by one (`hand_per_fold()`), compares id, metric, eval time and estimate per fold, and compares each summary row's mean, n and std_err with `hand_summary()`; the run has `.pred_time` reversed per fold.
- AC3: `test-nested-tune-race-oracles.R` :: "an eliminated candidate carries the grid path's mean over the resamples the race scored it on" passes (file run: 9 tests, 0 failed, 0 errors, 0 skipped). On `race_results("tune_race_anova")` it compares each eliminated row's mean, n and std_err with `nested_tune_grid()` over a `manual_rset()` cut to the race's resamples (invariant), and asserts `eliminated > 0`.
- AC4: `test-event-level.R` :: "the final fit's tuning run reports the sensitivity counted at the second level" passes (file run: 6 tests, 0 failed, 0 errors, 0 skipped). It counts sensitivity from the final fit's saved tuning predictions (closed-form) for all 9 resample-candidate pairs, and asserts the first level's count differs from the second's in each.
- AC5: `grep -n 'Add second oracles to one-type parts' cairn/ORACLES.md` prints nothing (exit 1). The AC1 test is a line under `compute-metrics/U1` and the AC2 test under `compute-metrics/U2` (same type and source); the AC3 test is under new row `nested-tune-race-oracles/O5` (invariant) and the AC4 test under new row `event-level/O3` (closed-form). The compute_metrics() group credits dynamic metrics to U1 and U2, and static and linear-predictor metrics to O1 and U2; the racing group credits eliminated rows to O3 (live) and O5 (invariant); the event-level group credits the final fit to O2 (live) and O3 (closed-form).

Consistency gate:
- `cairn_validate.py`: all checks passed, 18 advisory warnings (reference staleness, pre-existing). No principle changed, so `cairn_impact.py` skipped.
- `devtools::check()` at 5328c664: 0 errors, 0 warnings, 0 notes.
- `devtools::document()`: no diff in `man/` or `NAMESPACE`; it rewrote `Config/roxygen2/version` 8.1.0 → 8.1.1 (local roxygen2, the M166 lesson), restored.
- Six gating prose sweeps (`--list-gating`): each exit 0, clean. README.Rmd and README.md unchanged; no user-visible change, so no NEWS entry; no new top-level file.
- The suite run after the check (working tree with the unrun fix edits of b654e825): 1169 tests, 1 error, in the edited AC2 test (`order()` on a missing `.eval_time` for a set with no dynamic metric); fixed in 206d1137.

spawned: diff-bug, blame-history, prior-review, ripple
- ripple #1: the ROADMAP candidate row "Add second oracles to one-type parts" still states the pre-diff coverage — reject (planned change: post-merge hygiene graduates and deletes the row).
- blame-history #1: the event-level test re-checks yardstick's arithmetic, which M152 cut — reject (false: the plant at R/nested-final-fit.R:228 fails it 18 times, so it tests that the level reaches the final fit's run, not the level exchange).
- blame-history #2: `event-level/O3` reuses the label of the record M152 removed — reject (false: the registry header gives a new oracle the number after the highest its file uses here, O2; the removed record never entered the registry).
- blame-history #3: the racing group line should say the win-loss racer rests on the shared body — fix now (group line names `nested_tune_race()`).
- blame-history #4: the added fits are unmeasured — reject (false: 1.6 s for the racing test, 1.0 s for the event-level test, file runs 2026-10-31).
- prior-review #1: the widened compute_metrics() credits reverse M166's narrowing — reject (false: each credited part has a plant that fails its tests, recorded in the work log and below).
- prior-review #2: the one-candidate grid in O5 echoes M164's failed plant — reject (false: the survivors-only and full-count plants fail O5's test 3 and 12 times).
- prior-review #3: the censored tests pass no `event_level`, as M092 flagged for a set test — reject (false: survival metrics take no event level; the reviewer found it not reintroduced).
- prior-review #4: `reverse_pred()` and M092's `.row` join follow-up — reject (false: the helper leaves `.row` alone; not reintroduced).
- prior-review #5: M035's missing seed assertion — reject (false: the new test seeds both calls; not reintroduced).
- prior-review #6: duplicate test labels, flagged at M035 — reject (false: none in the three files).
- prior-review #7: power claims in new comments, as M166 found false records — reject (false: plants back the first-level and swap claims; re-run below).
- diff-bug #1: no test reaches the static-alone or linear-alone branches of `score_fold()` — fix now (both the invariant and the live test run six mixes of kinds).
- diff-bug #2: O5 picks the eliminated rows from the record under test — fix now (read from the reference race; the record must hold each one).
- diff-bug #3: O5's source line hides that the resample ids come from O1's reference race — fix now (registry row and test comment say so).
- diff-bug #4: the invariant test can pass on an empty metric mask — fix now (asserts the metric is present exactly when the set holds it).
- diff-bug #5: O1 checks which column a metric reads, not its value, and U1 goes uncredited for the values — fix now (group line credits truth and weights to U1 and U2, the column choice to O1 and U2).
- diff-bug #6: the header says the three parts were on one type, but static and linear-predictor metrics were on none — fix now ("one type or none").
- diff-bug #7: the test-file header says any one column moves only its metrics, but only two columns are reordered — fix now (names `.pred_time` and `.pred_linear_pred`).
- diff-bug #8: the AC2 test runs only on a run with hand-edited predictions — fix now (it runs on the run as saved and with `.pred_time` reversed).
- diff-bug #9: T4 counts sensitivity only while the group line credits the whole final fit — fix now (specificity counted; group line credits sensitivity and specificity, `roc_auc` level-free per O2's test).
- diff-bug #10: the event-level test partly checks yardstick — reject (false: as blame-history #1).
- diff-bug #11: the plant counts in the work log are file-wide — fix now (re-planted; per-test counts below).
- diff-bug #12: the new racing test runs uncached grid runs — reject (false: 1.6 s measured).
Return floor: no finding shows a criterion failing as written; the fixes keep each criterion's wording.

Re-run after the fixes (206d1137; file runs, 0 failed, 0 errors, 0 skipped in each file):
- AC1 test: 3 expectations, passes. AC2 test: 144 expectations over the run as saved and reversed, six mixes each, passes. Invariant test: 36 expectations, passes. AC3 test: 28 expectations, passes. AC4 test (renamed "the final fit's tuning run reports the sensitivity and specificity counted at the second level"): 29 expectations, passes.
- Plants, each restored (`git diff -- R/` empty after): linear-alone branch reads `.pred_time` → invariant 4, AC2 test 6 failures; static/linear swap in the combined branch → invariant 8, AC2 test 10; `all_configs = FALSE` → AC3 test 3; eliminated rows given the full count and a 1e-9 shift → AC3 test 12; `event_level = "first"` at R/nested-final-fit.R:228 → AC4 test 18, O2's test 4.
- AC6: `devtools::test()` run alone at 206d1137 (test files unchanged since; b5cf9aed changed only this file): 1169 tests, 0 failed, 0 errors, 0 skipped. `air format --check .` clean.
- `pkgdown::check_pkgdown()`: no problems found.
