# M110: Rolling-origin and sliding-window designs under every orchestrator

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, IP4, GP1, GP2
- **Resolves:** —
- **Surface tier:** user-facing — states which outer designs each orchestrator supports
- **Branch/PR:** m110-time-series-all-tuners

## Goal

The rolling-origin and sliding-window outer designs that M108 supports under `nested_tune_grid()` are tested and documented under the five other orchestrators.

## Scope

**In:** `nested_tune_bayes()`, `nested_tune_race_anova()`, `nested_tune_race_win_loss()`, `nested_tune_sim_anneal()`, `nested_fit_resamples()` and `nested_workflow_map()` over the two M108 fixtures, `ts_rolling_nested()` and `ts_sliding_nested()` (`tests/testthat/helper-orchestration.R:544-562`). Each has an inner `rolling_origin()`. `nested_final_fit()` on each orchestrator's result. A D-entry extending D-071, the help, and `NEWS.md`.

**Out:** `sliding_index()` and `sliding_period()` outer designs, and the `augment()` message for overlapping assessment sets, go to M111. Inner designs other than `rolling_origin()` go to a candidate row added with this plan.

## Acceptance criteria

- [x] AC1: `nested_tune_bayes()`, `nested_tune_race_anova()`, `nested_tune_race_win_loss()` and `nested_tune_sim_anneal()` each complete every fold on `ts_rolling_nested()` and on `ts_sliding_nested()`, tested. On each design, each fold's `.metrics`, `.selected`, `.tuning_seed` and `.outer_fit_seed` equal those of the orchestrator's reference loop on the same design and seed. The reference loops are `reference_nested_bayes_loop()`, `reference_nested_race_loop()` and `reference_nested_anneal_loop()` in `tests/testthat/helper-orchestration.R`.
- [x] AC2: `nested_fit_resamples()` completes every fold on each of the two designs, tested. Each fold's `.estimate` for each metric in the set is identical to that of the oracle. The oracle is `tune::fit_resamples()` run by hand on the same outer splits, as `tests/testthat/test-nested-fit-resamples-oracles.R` does.
- [x] AC3: The four tuners in AC1 each give a `ts_rolling_nested()` result. `nested_final_fit()` on each result matches a reference built in the test under the final fit's recorded seeds, tested. The reference runs the tuner by hand over `rolling_origin(initial = 40, assess = 1, skip = 4)` on the full data and selects with `tune::select_best(metric = "rmse")`. It then calls `fit()`. The test asserts that the inner splits' `in_id` and `final$selected` equal the reference's, and that `predict()` on the full data equals the reference's. The same comparison passes for a `ts_sliding_nested()` result from `nested_tune_bayes()`.
- [x] AC4: `nested_final_fit()` on a `nested_fit_resamples()` result over `ts_rolling_nested()` has a `NULL` tuning run and an empty selection, tested. Its `predict()` on the full data equals that of `fit()` on the full data under the recorded `fit_seed`.
- [x] AC5: `nested_workflow_map()` runs a set of one tuned and one fixed workflow on `ts_rolling_nested()`, routing the tuned one to `nested_tune_grid()`, tested. Each workflow's `.metrics` and `.selected` equal those that `hand_call()` (`tests/testthat/test-nested-workflow-map-oracles.R`) returns for it under the same seed.
- [x] AC6: The time-series paragraph of the `nested_tune_grid()` help (`R/nested-tune-grid.R:109-115`), which its five siblings inherit, states support for both designs with an inner `rolling_origin()`. It covers all six orchestrators and `nested_final_fit()`. The `nested_resamples()` help states the same. Both name `sliding_index()` and `sliding_period()` as not tested. `NEWS.md` has an entry.
- [x] AC7: `devtools::check()` gives 0 errors, 0 warnings, and no note absent from the check of the default branch at the branch point.

## Coverage

- AC1 → T2
- AC2 → T3
- AC3 → T1, T4
- AC4 → T4
- AC5 → T5
- AC6 → T7
- AC7 → T6, T7

## Tasks

- [x] T1: Give `reference_bayes_final_fit()`, `reference_race_final_fit()` and `reference_anneal_final_fit()` (`tests/testthat/helper-orchestration.R:409`, `:1984`, `:2215`) an argument for the inner design. Today each builds `vfold_cv(v = 3)` on the full data. Their current callers keep that default.
- [x] T2: Write the AC1 tests in `tests/testthat/test-time-series-designs.R`. The racers use `control_race(burn_in = 2)`, as `helper-orchestration.R:1774` does, and take the skips the M101 lesson names. A mismatch is a defect to fix, not a test to loosen.
- [x] T3: Write the AC2 tests.
- [x] T4: Write the AC3 and AC4 final-fit tests.
- [x] T5: Write the AC5 test.
- [x] T6: Time `test-time-series-designs.R` alone and the whole suite in parallel. Compare both with the CI step caps that `cairn/PROFILE.md` names. Record the figures in the work log.
- [x] T7: Write the D-entry extending D-071. It records that a final fit reads only the inner design, so one sliding-window final-fit test stands for the other tuners. Write the help and `NEWS.md` text. Run `devtools::document()`, the prose sweeps from the verify slot, and `devtools::check()`.

## Work log

- 2026-09-22: created by /milestone-plan. Absorbs the ROADMAP candidate "Time-series outer designs past M108" with M111. An Explore pass found no package code that reads the split class of these designs, so no code change is expected.
- 2026-09-22: criteria audit ran in full mode and returned 11 findings on the two plans, all fixed before the gate. The M110 findings were test counts stated as promises and an oracle comparing `.estimate`, not `.metrics`. Also a fit_resamples final fit with no inner design, a reference copying the selection under test, an unnamed routed orchestrator, and a claim missing its inner design.
- 2026-09-22: plan gate chose both designs under every orchestrator over rolling-origin alone, because the help then states one rule. Falsified by the added runs pushing a CI leg past its step cap.
- 2026-09-22: plan gate chose two milestones over one, because one carries 11 criteria. Falsified by M111 needing no work beyond what M110 builds.
- 2026-09-22: implement started on branch `m110-time-series-all-tuners`. No question gate, because the plan left no choice open.
- 2026-09-22: T1 done. `reference_inner()` in `helper-orchestration.R` builds the final-fit references' inner design, `vfold_cv(v = 3)` unless a test passes `inner_design`. The three final-fit oracle files pass unchanged.
- 2026-09-22: T2 done. The Bayesian, both racing and the annealing tuners match their reference loops on both designs, with no package change. `test-time-series-designs.R` runs 215 expectations, 0 failures, in 84 s alone.
- 2026-09-22: T3 done. `nested_fit_resamples()` matches `tune::fit_resamples()` on the outer splits rebuilt from each fixture's literal outer call, 14 expectations per design, 0 failures.
- 2026-09-22: T4 done. The final fit matches each tuner's reference on the rolling-origin result, and the Bayesian one on the sliding-window result too. The fit_resamples final fit has no tuning run and equals the plain fit. A reference left on its default `vfold_cv()` inner design gives different `in_id`s, so the comparison can fail.
- 2026-09-22: T5 done. `hand_call()` moved unchanged from `test-nested-workflow-map-oracles.R` to `helper-orchestration.R`, so the time-series file can use it. A two-workflow set on the rolling-origin design matches the hand calls. Both files pass, 387 expectations.
- 2026-09-22: checkpoint, T7 half-done. D-074, the help source and the `NEWS.md` bullet are written. `man/` is not yet regenerated, and the full-suite run for T6 is in progress.
- 2026-09-22: T6 done. At `a14fdfe` the full suite ran in 721 s wall on 2 local workers, 11451 expectations, 0 failures. `test-time-series-designs.R` alone ran in 169 s, 26 tests, 279 expectations. The CI caps are 30 min for the check step (40 on windows) and 30 min for `test-coverage`.
- 2026-09-22: `devtools::document()` regenerated six Rd files. All six gating prose sweeps print clean.
- 2026-09-22: claim audit: 24 claims read, 4 corrected — R/nested-tune-grid.R, R/nested-resamples.R, NEWS.md, tests/testthat/test-time-series-designs.R. The help and `NEWS.md` said `nested_workflow_map()` was tested on both designs, but it is tested on the rolling-origin design alone. The test comment's premise now says the final fit never reads the outer splits. It still reads the data through the first split. D-074's phrase "never reads the outer design" means the same.
- 2026-09-22: T7 done. `devtools::check()` at `98eac1e` gave 0 errors, 0 warnings, 0 notes. After the claim-audit edits, `tools::checkRd()` passes on the six changed Rd files and `test-help-structure.R` passes, 24 expectations. Status set to review.
- 2026-09-22: review gate fixes committed on the branch: D-075, class assertions, a sliding-window fit_resamples final fit, oracle records moved to the header, and seed columns in the set test. F4 (`start-first`) was reverted while applying it, against the M76 measurement.
- 2026-09-22: step-7 approval: m110-time-series-all-tuners approved for merge

## Decisions

## Review

Fresh evidence, 2026-09-22, at `dc35bf8`, `main` unmoved at `fdad226`. `testthat::test_file()` on `test-time-series-designs.R` ran 26 tests, all passing with no skip or error.

- AC1: 8 tests, "`<tuner>` matches its reference loop on a `<design>` design", one per tuner and design, 9 expectations each, 0 failed. Each asserts `.completed` on every fold, and both seed columns, `.metrics` and `.selected` per fold, identical to the named reference loop.
- AC2: "nested_fit_resamples() matches fit_resamples() on a `<design>` design", 2 tests, 14 expectations each, 0 failed. Each asserts every fold completed, and each `rmse` and `mae` `.estimate` identical to `tune::fit_resamples()` on the outer rset rebuilt from the fixture's literal call.
- AC3: 5 tests, "the `<tuner>` final fit on a `<design>` result matches its reference": the Bayesian, both racing and the annealing final fit on rolling-origin, plus the Bayesian one on sliding-window. Each has 5 expectations and 0 failed. Each asserts the seeds, the inner `in_id`s, a `rof_split` inner design, `final$selected`, and `predict()` on the full data, identical to the reference. The reference is built over `ts_inner()` and selects with `select_best(metric = "rmse")` itself. Implement recorded that a reference on its default `vfold_cv()` gives different `in_id`s.
- AC4: "the final fit on a rolling-origin fit_resamples() result fits every row", 3 expectations, 0 failed. It asserts `final$tuning` is `NULL` and `final$selected` is 0 by 0. It also asserts `predict()` on the full data is identical to `fit()` on the full data under `final$fit_seed`, kind pinned.
- AC5: "a workflow set on a rolling-origin design matches the hand calls", 8 expectations, 0 failed. The tuners recorded are `tune_grid` and `fit_resamples`, and each workflow's `.metrics` and `.selected` are identical to `hand_call("nested_tune_grid", ...)` under seed 26.
- AC6: `tools::Rd2txt()` on `nested_tune_grid`, `nested_tune_bayes`, `nested_tune_race`, `nested_tune_sim_anneal` and `nested_fit_resamples` renders one identical paragraph. It states support for both designs with an inner `rolling_origin()`, names all six orchestrators as tested on both, and states `nested_final_fit()` tested on both. `nested_resamples.Rd` states the same. Both name `sliding_index()` and `sliding_period()` as not tested. `NEWS.md:22-28` carries the entry.

Consistency gate at `dc35bf8`. `cairn_validate` passes, with 18 advisory references-staleness warnings. `devtools::document()` leaves no diff, `README.Rmd` is untouched, and `pkgdown::check_pkgdown()` finds no problems. No top-level file is added, `air format --check` is clean on the touched R files, and all six gating prose sweeps print clean. `NEWS.md` has the entry. No principle changed, so `cairn_impact` is skipped.

- AC7: `devtools::check()` at `dc35bf8`, the branch head with the claim-audit edits, gave 0 errors, 0 warnings, 0 notes. With no note, none is absent from the check of `main`.

Independent review at `dc35bf8`. The [S] blame-history lens found nothing. The [S] prior-review lens found nothing reintroduced or contradicted. The [O] diff-bug lens ranked 15 findings, none showing a criterion failing. Triage follows at the gate.

Triage, accepted at the gate as proposed on 2026-09-22:
- F1 (D-074 claims the map on both fixtures), F8 (D-074's "never reads the outer design"), F10 (D-071's Consequences not marked superseded): fix now. D-075 corrects all three.
- F2 (no suite-time baseline): follow-up at step 8. Each CI leg's time is compared with `main`'s last run before the merge.
- F3 (AC3 tuner runs rebuilt, the recipe step ids drawn from the stream): follow-up. It joins the fixture-key candidate row at hygiene.
- F4 (file not in `start-first`): accepted as fix now, then rejected while applying it. The PROFILE test-doctrine slot (M76) and the `R-CMD-check.yaml` comment record that re-ordering measured 2.4% slower and bought nothing.
- F5 (AC7 without evidence at HEAD): resolved by the check at `dc35bf8`.
- F6 (no design-class assertion in the M110 loops): fix now. `TS_SPLIT_CLASS` is asserted in every looped test.
- F7 (the sliding-window Bayesian final fit tests the D-074 premise only): noted, matches D-074.
- F9 ("tested on both" not covering the fit_resamples final fit): fix now. A sliding-window case was added.
- F11 (oracle records mid-file): fix now. O4-O7 moved to the header.
- F12 (one oracle type): rejected. These are checks that the orchestrators match hand-run tune calls, as M108's were, and the header now says so.
- F13 (an M108 test reads its seeds from the output): rejected, the test predates this diff.
- F14 (AC5 without seed columns): fix now. Both seed columns are asserted.
- F15 (stale text): the Review section is committed. AC5's `hand_call()` path is plan text, which review does not edit, noted.

After the fixes, `test-time-series-designs.R` runs 27 tests, 300 expectations, 0 failures.
