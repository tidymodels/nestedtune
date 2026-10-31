# M167: Add second oracles to one-type parts

- **Status:** in-progress
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

- [ ] AC1: A test in `test-compute-metrics.R` asserts, at `summarize = TRUE` and at `summarize = FALSE`, that `compute_metrics()` called with a censored-regression run's own metric set equals `collect_metrics()` on that run, where the metric set holds a static, a dynamic and a linear-predictor survival metric.
- [ ] AC2: A test in `test-compute-metrics.R` asserts that `compute_metrics()` on a censored-regression run, with a metric set holding a static, a dynamic and a linear-predictor survival metric, equals yardstick called metric by metric on each fold's rows of `collect_predictions()`, both per fold and in a summary computed in the test.
- [ ] AC3: A test asserts, on a `nested_tune_race_anova()` run in which at least one fold eliminated a candidate, each eliminated candidate's row in the `.inner_metrics` of a fold that eliminated a candidate against an oracle whose type is not live.
- [ ] AC4: A test asserts the tuning run that `nested_final_fit()` stores under `event_level = "second"` against an oracle whose type is not live, on input where the first and second levels give different values for at least one metric the oracle checks.
- [ ] AC5: In `cairn/ORACLES.md`, each of the tests that AC1-AC4 name appears as a test line under a row with id, type and source. A test whose type and source match an existing row goes under that row, and any other test gets a new row. The `compute_metrics()`, racing and event-level groups each credit their part to rows of two types, and `grep -n 'Add second oracles to one-type parts' cairn/ORACLES.md` prints nothing.
- [ ] AC6: `devtools::test()` runs clean.

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
- [ ] T6: Run `devtools::test()` and `air format --check .` clean.

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
