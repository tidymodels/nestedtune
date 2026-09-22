# M110: Rolling-origin and sliding-window designs under every orchestrator

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, IP4, GP1, GP2
- **Resolves:** —
- **Surface tier:** user-facing — states which outer designs each orchestrator supports
- **Branch/PR:** —

## Goal

The rolling-origin and sliding-window outer designs that M108 supports under `nested_tune_grid()` are tested and documented under the five other orchestrators.

## Scope

**In:** `nested_tune_bayes()`, `nested_tune_race_anova()`, `nested_tune_race_win_loss()`, `nested_tune_sim_anneal()`, `nested_fit_resamples()` and `nested_workflow_map()` over the two M108 fixtures, `ts_rolling_nested()` and `ts_sliding_nested()` (`tests/testthat/helper-orchestration.R:544-562`). Each has an inner `rolling_origin()`. `nested_final_fit()` on each orchestrator's result. A D-entry extending D-071, the help, and `NEWS.md`.

**Out:** `sliding_index()` and `sliding_period()` outer designs, and the `augment()` message for overlapping assessment sets, go to M111. Inner designs other than `rolling_origin()` go to a candidate row added with this plan.

## Acceptance criteria

- [ ] AC1: `nested_tune_bayes()`, `nested_tune_race_anova()`, `nested_tune_race_win_loss()` and `nested_tune_sim_anneal()` each complete every fold on `ts_rolling_nested()` and on `ts_sliding_nested()`, tested. On each design, each fold's `.metrics`, `.selected`, `.tuning_seed` and `.outer_fit_seed` equal those of the orchestrator's reference loop on the same design and seed. The reference loops are `reference_nested_bayes_loop()`, `reference_nested_race_loop()` and `reference_nested_anneal_loop()` in `tests/testthat/helper-orchestration.R`.
- [ ] AC2: `nested_fit_resamples()` completes every fold on each of the two designs, tested. Each fold's `.estimate` for each metric in the set is identical to that of the oracle. The oracle is `tune::fit_resamples()` run by hand on the same outer splits, as `tests/testthat/test-nested-fit-resamples-oracles.R` does.
- [ ] AC3: The four tuners in AC1 each give a `ts_rolling_nested()` result. `nested_final_fit()` on each result matches a reference built in the test under the final fit's recorded seeds, tested. The reference runs the tuner by hand over `rolling_origin(initial = 40, assess = 1, skip = 4)` on the full data and selects with `tune::select_best(metric = "rmse")`. It then calls `fit()`. The test asserts that the inner splits' `in_id` and `final$selected` equal the reference's, and that `predict()` on the full data equals the reference's. The same comparison passes for a `ts_sliding_nested()` result from `nested_tune_bayes()`.
- [ ] AC4: `nested_final_fit()` on a `nested_fit_resamples()` result over `ts_rolling_nested()` has a `NULL` tuning run and an empty selection, tested. Its `predict()` on the full data equals that of `fit()` on the full data under the recorded `fit_seed`.
- [ ] AC5: `nested_workflow_map()` runs a set of one tuned and one fixed workflow on `ts_rolling_nested()`, routing the tuned one to `nested_tune_grid()`, tested. Each workflow's `.metrics` and `.selected` equal those that `hand_call()` (`tests/testthat/test-nested-workflow-map-oracles.R`) returns for it under the same seed.
- [ ] AC6: The time-series paragraph of the `nested_tune_grid()` help (`R/nested-tune-grid.R:109-115`), which its five siblings inherit, states support for both designs with an inner `rolling_origin()`. It covers all six orchestrators and `nested_final_fit()`. The `nested_resamples()` help states the same. Both name `sliding_index()` and `sliding_period()` as not tested. `NEWS.md` has an entry.
- [ ] AC7: `devtools::check()` gives 0 errors, 0 warnings, and no note absent from the check of the default branch at the branch point.

## Coverage

- AC1 → T2
- AC2 → T3
- AC3 → T1, T4
- AC4 → T4
- AC5 → T5
- AC6 → T7
- AC7 → T6, T7

## Tasks

- [ ] T1: Give `reference_bayes_final_fit()`, `reference_race_final_fit()` and `reference_anneal_final_fit()` (`tests/testthat/helper-orchestration.R:409`, `:1984`, `:2215`) an argument for the inner design. Today each builds `vfold_cv(v = 3)` on the full data. Their current callers keep that default.
- [ ] T2: Write the AC1 tests in `tests/testthat/test-time-series-designs.R`. The racers use `control_race(burn_in = 2)`, as `helper-orchestration.R:1774` does, and take the skips the M101 lesson names. A mismatch is a defect to fix, not a test to loosen.
- [ ] T3: Write the AC2 tests.
- [ ] T4: Write the AC3 and AC4 final-fit tests.
- [ ] T5: Write the AC5 test.
- [ ] T6: Time `test-time-series-designs.R` alone and the whole suite in parallel. Compare both with the CI step caps that `cairn/PROFILE.md` names. Record the figures in the work log.
- [ ] T7: Write the D-entry extending D-071. It records that a final fit reads only the inner design, so one sliding-window final-fit test stands for the other tuners. Write the help and `NEWS.md` text. Run `devtools::document()`, the prose sweeps from the verify slot, and `devtools::check()`.

## Work log

- 2026-09-22: created by /milestone-plan. Absorbs the ROADMAP candidate "Time-series outer designs past M108" with M111. An Explore pass found no package code that reads the split class of these designs, so no code change is expected.
- 2026-09-22: criteria audit ran in full mode and returned 11 findings on the two plans, all fixed before the gate. The M110 findings were test counts stated as promises and an oracle comparing `.estimate`, not `.metrics`. Also a fit_resamples final fit with no inner design, a reference copying the selection under test, an unnamed routed orchestrator, and a claim missing its inner design.
- 2026-09-22: plan gate chose both designs under every orchestrator over rolling-origin alone, because the help then states one rule. Falsified by the added runs pushing a CI leg past its step cap.
- 2026-09-22: plan gate chose two milestones over one, because one carries 11 criteria. Falsified by M111 needing no work beyond what M110 builds.

## Decisions

## Review
