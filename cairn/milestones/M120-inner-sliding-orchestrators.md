# M120: Inner sliding designs under the other orchestrators

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP2
- **Resolves:** —
- **Surface tier:** user-facing — the help and `NEWS.md` state which orchestrators users can run on these designs
- **Branch/PR:** m120-inner-sliding-orchestrators

## Goal

An inner `sliding_window()`, `sliding_index()` or `sliding_period()` design under an outer `rolling_origin()` is tested and documented under every orchestrator other than `nested_tune_grid()`.

## Scope

**In:** the four other tuners against their reference loops on the three inner designs in `TS_INNER_DESIGNS`. The final fits of those four tuners on the sliding-period design. `nested_fit_resamples()` and `nested_workflow_map()` on the three designs. The sliding-index fixture moves to data whose dates have gaps, so its splits differ from the sliding-window fixture's (M119 review F1). The help, `NEWS.md` and one D-entry state the new claim.

**Out:** sliding outer designs with inner sliding designs → M121. Final fits of these four tuners on the sliding-window and sliding-index designs → dropped at this plan gate. M119 tests the inner-design rebuild on all three designs under grid, and AC1 tests each tuner on all three. Any other inner design → stays unclaimed, in the inner-design candidate row.

## Acceptance criteria

- [x] AC1: One test runs for each of the 12 pairs of a tuner and a design in `TS_INNER_DESIGNS` (`tests/testthat/helper-orchestration.R`). The tuners are `nested_tune_bayes()`, `nested_tune_race_anova()`, `nested_tune_race_win_loss()` and `nested_tune_sim_anneal()`. Each test asserts that every fold completed. It asserts that the seeds, `.metrics` and `.selected` equal those of the tuner's reference loop in that helper file. It asserts that the first fold's inner split has the design's split class. All 12 tests pass under `devtools::test()`.
- [x] AC2: One test runs for each of the four tuners on the sliding-period design. It asserts that `nested_final_fit()` on the AC1 result equals the tuner's reference final fit. That reference is built on the full data from the design's literal inner call. Equal means the same two seeds, the same inner `in_id` and `out_id` values, the same selected parameters, and the same predictions on the full data. The test also asserts that the final fit's first inner split has class `sliding_period_split`. All 4 tests pass under `devtools::test()`.
- [x] AC3: For each of the three designs, one test asserts that `nested_fit_resamples()` completes every fold. It asserts that the `.metrics` equal those of `tune::fit_resamples()` run by hand on the outer splits. This shows only that the design is accepted, because `nested_fit_resamples()` checks the inner design but fits nothing on it. For each of the three designs, one test runs `nested_workflow_map()` over a set of one tuned and one fixed workflow. It asserts that each workflow's seeds, `.metrics` and `.selected` equal those of `hand_call("nested_tune_grid", ...)` for that workflow. All 6 tests pass under `devtools::test()`.
- [x] AC4: The sliding-index fixture in `TS_INNER_DESIGNS` is built on its own data, whose `date` column has gaps. The fixtures in `TS_DESIGNS` keep `make_ts_data()`. A test asserts that, in at least one outer fold, the sliding-index fixture's inner `in_id` values differ from those of the sliding-window fixture. The M119 tests in `tests/testthat/test-time-series-inner.R` pass on the changed fixture.
- [x] AC5: This criterion covers three texts. They are the time-series paragraph of `@section Nested designs` in `R/nested-tune-grid.R`, `@section Time-series designs` in `R/nested-resamples.R`, and the time-series bullets in the development section of `NEWS.md`. The command `git diff main -- R/nested-tune-grid.R R/nested-resamples.R NEWS.md` lists the sentences this milestone adds or changes in them. Each such sentence claims only triples that an AC1-AC3 test runs. A triple is a function, the orchestrator whose results it acts on or none, and an inner design. A sentence naming `nested_fit_resamples()` with these designs says that it checks the inner design but fits nothing on it. After the change, no sentence in the three texts calls a function untested with an inner sliding design that an AC1-AC3 test runs it with.
- [x] AC6: `devtools::check()` reports 0 errors, 0 warnings and 0 notes.

## Coverage

- AC1 → T1, T3
- AC2 → T2, T4
- AC3 → T4
- AC4 → T1
- AC5 → T5
- AC6 → T6

## Tasks

- [x] T1: Add a data builder with gaps in `date` to `helper-orchestration.R` and give each `TS_INNER_DESIGNS` entry its data builder. Move the sliding-index entry onto the new builder, and make `test-time-series-inner.R` build each design on its entry's data. Keep at least 3 inner resamples in every outer fold of each fixture, because the racers refuse fewer at `burn_in = 2`. Recount them, and state the counts and the counting command in the fixture comment. Add the AC4 test, then run the M119 tests.
- [x] T2: Give `expect_ts_final_matches()` the expected inner split class as an argument, defaulting to `"rof_split"`. It hard-codes that class today (`helper-orchestration.R:752`). The existing callers keep passing.
- [x] T3: Write the AC1 tests in a new `test-time-series-*.R` file with a file-level `skip_heavy_on_cran()` and an oracle header naming the reference loops. Each test takes its tuner's skip helper, for example `skip_if_no_race_fixture()`, because the hard-dependency leg installs no Suggests (LESSONS M101).
- [x] T4: Write the AC2 final-fit tests with the reference final-fit helpers' `inner_design` argument, and write the AC3 tests. Time each new file serially. Split a file that runs far longer than the others, and add a long one to `Config/testthat/start-first` (LESSONS M16).
- [x] T5: Update the three AC5 texts and run `devtools::document()`. Append a D-entry that claims the new triples. It supersedes the clauses of D-083 and D-084 that leave the other orchestrators and `nested_workflow_map()` unclaimed here. Run `Rscript benchmarks/sweep-prose.R --plain` and `--roxygen --plain`.
- [x] T6: Run `devtools::test()` and `devtools::check()`, and record the new files' serial times in the work log.

## Work log

- 2026-09-27: created by /milestone-plan. Absorbs part of the inner-design candidate row and its M119 review F1 note. The criteria audit ran in full mode and returned 8 findings, all fixed before the gate.
- 2026-09-27: plan gate chose final-fit tests on the sliding-period design alone over all three designs. M119 tests the inner-design rebuild under grid on all three, and AC1 tests each tuner on all three. Falsified by a tuner's final fit failing on an inner sliding-window or sliding-index design.
- 2026-09-27: the full-mode re-audit of the final wording returned no blocking findings and 2 minor ones on AC5, both fixed (the triple's definition, and the `nested_fit_resamples()` sentence).
- 2026-09-27: plan gate chose two milestones over one, because together they pass the criteria-count split limit. Falsified by M121 needing a change M120 makes to package code.
- 2026-09-27: implement started on `m120-inner-sliding-orchestrators`. No question gate, because the plan leaves no API, naming or dependency choice open.
- 2026-09-27: T1 done. `make_ts_weekday_data()` gives weekday-only dates, and the sliding-index fixture runs on it with 7, 9 and 11 inner resamples. `test-time-series-inner.R` passes 10 of 10. On `make_ts_data()` the new check reads no difference, so it can fail.
- 2026-09-27: T2 done. `expect_ts_final_matches()` takes `split_class`, checks it on the reference and the final fit, and now compares `out_id` too. Its three callers pass 9 of 9.
- 2026-09-27: T3 and T4 done in one pass. The files are split by tuner family, so each holds its AC1 runs and the AC2 final fits that reuse them. `test-time-series-inner-bayes-anneal.R` passes 8 of 8 in 52 s, `test-time-series-inner-race.R` 8 of 8 in 36 s, and `test-time-series-inner-other.R` (AC3) 6 of 6 in 14 s. Each time is serial with the package load. The first two join `Config/testthat/start-first`.
- 2026-09-27: T5 done. The last sentence of the M119 text in the two help sections and `NEWS.md` became four sentences, and the M119 sentences about grid are unchanged. D-085 appended. `devtools::document()` rewrote six Rd files, and both prose sweeps are clean.
- 2026-09-27: claim audit: 36 claims read, 4 corrected — helper-orchestration.R, test-time-series-inner.R, test-time-series-inner-other.R, R/nested-tune-grid.R, R/nested-resamples.R, NEWS.md. The corrections are the 40-row lookback count, the AC4 check tightened to every fold, the O1 header's outer design, and "reads no inner design".
- 2026-09-27: amendment at a mini gate, approved by the user. AC3 and AC5 changed "reads no inner design" to "checks the inner design but fits nothing on it", because `nested_fit_resamples()` runs `check_nested()` on the inner design and ships it with each fold.
- 2026-09-27: re-audit: AC3 (full) — nothing.
- 2026-09-27: re-audit: AC5 (full) — D-085 and one test comment still used the old phrase. D-086 corrects D-085, and the comment was fixed. The optional "or equivalent" wording was not taken, because the help uses the exact phrase.
- 2026-09-27: the four claim-audit fixes and the new phrase applied to the help, `NEWS.md` and two test files. The AC4 check now requires a difference in every fold. `devtools::document()` rewrote six Rd files, both prose sweeps are clean, and the inner files pass 32 of 32.
- 2026-09-27: T6 done. The full suite ran 1033 tests with 0 failures and 0 skips, on the tree before the claim-audit fixes. `devtools::check()` on the final tree gave 0 errors, 0 warnings and 0 notes. The new files' serial times are in the T3-T4 line. Status set to review.

## Decisions

## Review

Reviewed 2026-09-27 on `65dddc1e`, which contains `origin/main`, so no merge was needed. The full `devtools::test()` run gave 11986 expectations, 0 failed, 0 skipped and 0 errors. It ran with `NOT_CRAN=true`.

- AC1: `test-time-series-inner-bayes-anneal.R` has 6 AC1 blocks (bayes and anneal, one per design), and `test-time-series-inner-race.R` has 6 (both racers, one per design). That makes 12. Each block checks the first fold's inner split class, then calls `expect_ts_matches_reference()`. That helper checks `all(res$.completed)`, both seeds, and `.metrics` and `.selected` for each fold against the tuner's reference loop. All pass in the full run, with 0 skips.
- AC2: the two files hold 4 final-fit blocks on the sliding-period design, one per tuner. Each calls `expect_ts_final_matches()` with `split_class = spec$split_class`. That helper compares both seeds, the inner `in_id` and `out_id` values, the selected parameters and the full-data predictions against a reference. The reference is rebuilt from the design's literal inner call. The helper also checks the split class on the reference and on the final fit. All 4 pass in the full run.
- AC3: `test-time-series-inner-other.R` has 6 blocks. For each design, one block checks `all(res$.completed)` and compares each fold's `.metrics` with `tune::fit_resamples()` on the outer splits. It first asserts that the reference holds 2 rows. One block runs `nested_workflow_map()` over a tuned and a fixed workflow, and compares seeds, `.metrics` and `.selected` with `hand_call("nested_tune_grid", ...)`. All 6 pass in the full run.
- AC4: in `TS_INNER_DESIGNS` the sliding-index entry uses `data = make_ts_weekday_data`, and the other two use `make_ts_data`. The branch diff does not touch `TS_DESIGNS`. A load of the helper shows that the weekday data has 5 weekday codes and a largest date gap of 3 days. The block "the inner sliding-index fixture builds splits sliding-window does not" asserts that the inner `in_id` values differ in every outer fold. The criterion asks for one fold. `test-time-series-inner.R` passes 10 of 10 blocks in the full run.
- AC5: `git diff main -- R/nested-tune-grid.R R/nested-resamples.R NEWS.md` shows the same four new sentences in all three texts. It also shows one changed sentence, and unchanged M119 sentences that share a diff line with them. The first new sentence names the four tuners and `nested_workflow_map()`, which AC1 and AC3 run on each design. The second names `nested_final_fit()` for the four tuners on sliding-period alone, which AC2 runs. The third names `nested_fit_resamples()`, which AC3 runs. The fourth says that it checks the inner design but fits nothing on it. The changed sentence names only the other three outer designs as untested. A search of the three texts for "not tested", "untested" and "unclaimed" finds no sentence that calls a tested function untested.
- AC6: `devtools::check()` on `65dddc1e` reported 0 errors, 0 warnings and 0 notes in 8 min 42 s.

Consistency gate: `cairn_validate.py` exits 0 with 18 references-staleness advisories. No DESIGN principle changed, so `cairn_impact` was skipped. `devtools::document()` leaves no diff. The six gating prose sweeps are clean. `pkgdown::check_pkgdown()` finds no problems. The branch does not touch `README.Rmd` or `README.md`. `NEWS.md` has the entry. `air format --check` changes no tracked R or test file.

Independent review: three fresh reviewers ran. The blame-history reviewer found nothing. The prior-review reviewer raised P1 below. The diff reviewer found no correctness bug and ranked O1-O9.
- O1: the help and NEWS claim for `nested_workflow_map()` does not name `fn`. Only the default `fn = "nested_tune_grid"` and the fixed-workflow route run on these designs.
- O2: the D-085 heading says "claimed under every orchestrator", but its body limits `nested_fit_resamples()` to accepting the design.
- O3: the workflow-set test checks `.completed` on the hand calls but not on the map result.
- O4: the AC1 split-class check reads the input fixture, not the result. The criterion asks for this.
- O5 and P1: the new help and NEWS sentence breaks after "tested with these", and the break carries into six Rd files.
- O6 and P1: the new `start-first` line in DESCRIPTION is 88 characters.
- O7: the `make_ts_weekday_data()` comment has one long sentence that is hard to read.
- O8: race test names use the `RACERS` names, not the exported function names. This follows the existing race files.
- O9: `ts_inner_outer()` restates the outer `rolling_origin()` call. A drift fails loudly.
