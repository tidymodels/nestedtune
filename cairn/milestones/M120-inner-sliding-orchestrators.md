# M120: Inner sliding designs under the other orchestrators

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP2
- **Resolves:** —
- **Surface tier:** user-facing — the help and `NEWS.md` state which orchestrators users can run on these designs
- **Branch/PR:** —

## Goal

An inner `sliding_window()`, `sliding_index()` or `sliding_period()` design under an outer `rolling_origin()` is tested and documented under every orchestrator other than `nested_tune_grid()`.

## Scope

**In:** the four other tuners against their reference loops on the three inner designs in `TS_INNER_DESIGNS`. The final fits of those four tuners on the sliding-period design. `nested_fit_resamples()` and `nested_workflow_map()` on the three designs. The sliding-index fixture moves to data whose dates have gaps, so its splits differ from the sliding-window fixture's (M119 review F1). The help, `NEWS.md` and one D-entry state the new claim.

**Out:** sliding outer designs with inner sliding designs → M121. Final fits of these four tuners on the sliding-window and sliding-index designs → dropped at this plan gate. M119 tests the inner-design rebuild on all three designs under grid, and AC1 tests each tuner on all three. Any other inner design → stays unclaimed, in the inner-design candidate row.

## Acceptance criteria

- [ ] AC1: One test runs for each of the 12 pairs of a tuner and a design in `TS_INNER_DESIGNS` (`tests/testthat/helper-orchestration.R`). The tuners are `nested_tune_bayes()`, `nested_tune_race_anova()`, `nested_tune_race_win_loss()` and `nested_tune_sim_anneal()`. Each test asserts that every fold completed. It asserts that the seeds, `.metrics` and `.selected` equal those of the tuner's reference loop in that helper file. It asserts that the first fold's inner split has the design's split class. All 12 tests pass under `devtools::test()`.
- [ ] AC2: One test runs for each of the four tuners on the sliding-period design. It asserts that `nested_final_fit()` on the AC1 result equals the tuner's reference final fit. That reference is built on the full data from the design's literal inner call. Equal means the same two seeds, the same inner `in_id` and `out_id` values, the same selected parameters, and the same predictions on the full data. The test also asserts that the final fit's first inner split has class `sliding_period_split`. All 4 tests pass under `devtools::test()`.
- [ ] AC3: For each of the three designs, one test asserts that `nested_fit_resamples()` completes every fold. It asserts that the `.metrics` equal those of `tune::fit_resamples()` run by hand on the outer splits. This shows only that the design is accepted, because `nested_fit_resamples()` reads no inner design. For each of the three designs, one test runs `nested_workflow_map()` over a set of one tuned and one fixed workflow. It asserts that each workflow's seeds, `.metrics` and `.selected` equal those of `hand_call("nested_tune_grid", ...)` for that workflow. All 6 tests pass under `devtools::test()`.
- [ ] AC4: The sliding-index fixture in `TS_INNER_DESIGNS` is built on its own data, whose `date` column has gaps. The fixtures in `TS_DESIGNS` keep `make_ts_data()`. A test asserts that, in at least one outer fold, the sliding-index fixture's inner `in_id` values differ from those of the sliding-window fixture. The M119 tests in `tests/testthat/test-time-series-inner.R` pass on the changed fixture.
- [ ] AC5: This criterion covers three texts. They are the time-series paragraph of `@section Nested designs` in `R/nested-tune-grid.R`, `@section Time-series designs` in `R/nested-resamples.R`, and the time-series bullets in the development section of `NEWS.md`. The command `git diff main -- R/nested-tune-grid.R R/nested-resamples.R NEWS.md` lists the sentences this milestone adds or changes in them. Each such sentence claims only triples that an AC1-AC3 test runs. A triple is a function, the orchestrator whose results it acts on or none, and an inner design. A sentence naming `nested_fit_resamples()` with these designs says that it reads no inner design. After the change, no sentence in the three texts calls a function untested with an inner sliding design that an AC1-AC3 test runs it with.
- [ ] AC6: `devtools::check()` reports 0 errors, 0 warnings and 0 notes.

## Coverage

- AC1 → T1, T3
- AC2 → T2, T4
- AC3 → T4
- AC4 → T1
- AC5 → T5
- AC6 → T6

## Tasks

- [ ] T1: Add a data builder with gaps in `date` to `helper-orchestration.R` and give each `TS_INNER_DESIGNS` entry its data builder. Move the sliding-index entry onto the new builder, and make `test-time-series-inner.R` build each design on its entry's data. Keep at least 3 inner resamples in every outer fold of each fixture, because the racers refuse fewer at `burn_in = 2`. Recount them, and state the counts and the counting command in the fixture comment. Add the AC4 test, then run the M119 tests.
- [ ] T2: Give `expect_ts_final_matches()` the expected inner split class as an argument, defaulting to `"rof_split"`. It hard-codes that class today (`helper-orchestration.R:752`). The existing callers keep passing.
- [ ] T3: Write the AC1 tests in a new `test-time-series-*.R` file with a file-level `skip_heavy_on_cran()` and an oracle header naming the reference loops. Each test takes its tuner's skip helper, for example `skip_if_no_race_fixture()`, because the hard-dependency leg installs no Suggests (LESSONS M101).
- [ ] T4: Write the AC2 final-fit tests with the reference final-fit helpers' `inner_design` argument, and write the AC3 tests. Time each new file serially. Split a file that runs far longer than the others, and add a long one to `Config/testthat/start-first` (LESSONS M16).
- [ ] T5: Update the three AC5 texts and run `devtools::document()`. Append a D-entry that claims the new triples. It supersedes the clauses of D-083 and D-084 that leave the other orchestrators and `nested_workflow_map()` unclaimed here. Run `Rscript benchmarks/sweep-prose.R --plain` and `--roxygen --plain`.
- [ ] T6: Run `devtools::test()` and `devtools::check()`, and record the new files' serial times in the work log.

## Work log

- 2026-09-27: created by /milestone-plan. Absorbs part of the inner-design candidate row and its M119 review F1 note. The criteria audit ran in full mode and returned 8 findings, all fixed before the gate.
- 2026-09-27: plan gate chose final-fit tests on the sliding-period design alone over all three designs. M119 tests the inner-design rebuild under grid on all three, and AC1 tests each tuner on all three. Falsified by a tuner's final fit failing on an inner sliding-window or sliding-index design.
- 2026-09-27: the full-mode re-audit of the final wording returned no blocking findings and 2 minor ones on AC5, both fixed (the triple's definition, and the `nested_fit_resamples()` sentence).
- 2026-09-27: plan gate chose two milestones over one, because together they pass the criteria-count split limit. Falsified by M121 needing a change M120 makes to package code.

## Decisions

## Review
