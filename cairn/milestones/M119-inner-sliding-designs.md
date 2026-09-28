# M119: Inner sliding-window, sliding-index and sliding-period designs

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, GP1, GP2
- **Resolves:** —
- **Surface tier:** user-facing — the help and `NEWS.md` state which designs a user can rely on
- **Branch/PR:** m119-inner-sliding-designs

## Goal

An inner `sliding_window()`, `sliding_index()` or `sliding_period()` design under an outer `rolling_origin()` is tested and documented under `nested_tune_grid()` and `nested_final_fit()`.

## Scope

**In:** Three fixtures in `tests/testthat/helper-orchestration.R`, each an outer `rolling_origin()` with one of the three inner sliding designs. A new test file runs them against the existing references. The help of `nested_tune_grid()` and `nested_resamples()`, `NEWS.md`, and a D-entry state the support and its bound. Probes on 2026-09-27 ran all three designs through `nested_tune_grid()`, `nested_final_fit()` and `nested_resamples()` with no code change, so none is planned.

**Out:** The five other orchestrators and `nested_workflow_map()` on these inner designs, and the three sliding outer designs paired with them. Both go to one candidate row that replaces the current inner-design row. `augment()` is untouched, because the inner design does not reach it.

## Acceptance criteria

- [ ] AC1: Three designs are built by `rsample::nested_cv()` on `make_ts_data()`. Each has the outer design `rolling_origin(initial = 60, assess = 1, skip = 9)`. The inner designs are `sliding_window(lookback = 39, assess_stop = 1, step = 5)`, `sliding_index(index = date, lookback = 39, assess_stop = 1, step = 5)` and `sliding_period(index = date, period = "week", lookback = 5)`. For each design, a test asserts that the first fold's first inner split has the class `sliding_window_split`, `sliding_index_split` or `sliding_period_split` as its name claims. The same test runs `nested_tune_grid()` and `reference_nested_loop()` on that nested object under one seed. It asserts a match through `expect_ts_matches_reference()`.
- [ ] AC2: For each of the three designs, a test calls `nested_resamples()` with the same `outside` and `inside` calls. It asserts that the splits match `rsample::nested_cv()`'s through `expect_outer_identical()` and `expect_inner_identical()`.
- [ ] AC3: For each of the three designs, a test runs `nested_final_fit()` on the `nested_tune_grid()` result. The reference runs under the final fit's recorded seeds. It evaluates the fixture's literal inner call on the full data, then runs `tune::tune_grid()`, `tune::select_best()` and `fit()`. The test asserts identical inner split `in_id`s, an identical selected row, and identical predictions on the full data.
- [ ] AC4: The help of `nested_tune_grid()` and of `nested_resamples()` states the three inner designs as tested. So does `NEWS.md`. Each of the three texts names the outer `rolling_origin()`, `nested_tune_grid()`, and `nested_final_fit()` for its results. Each also says that the other orchestrators and the other outer designs are not tested with these inner designs. The reviewer reads every hit of `grep -rn -i 'inner' R/ man/ NEWS.md vignettes/ README.md README.Rmd`. No hit limits the tested inner designs to `rolling_origin()` alone.
- [ ] AC5: `devtools::test()` passes with 0 failures. `devtools::check()` reports 0 errors, 0 warnings and 0 notes.

## Coverage

- AC1 → T1, T2
- AC2 → T2
- AC3 → T3
- AC4 → T4
- AC5 → T5

## Tasks

- [x] T1: Add `ts_inner_window_nested()`, `ts_inner_index_nested()` and `ts_inner_period_nested()` to `helper-orchestration.R`, with the calls AC1 names. Add a named list of them beside `TS_DESIGNS`, with the inner split class each builds.
- [x] T2: Add `tests/testthat/test-time-series-inner.R`. Call `skip_heavy_on_cran()` at the top and `skip_if_no_engines()` in each engine block. Write the AC1 and AC2 blocks, looping over the new list. If AC2 fails, stop and replan, because the fix is a code change.
- [x] T3: Give `expect_final_matches_reference()` in `test-time-series-designs.R` an inner-design argument. Its default keeps today's `rolling_origin()` call. If the new file needs it, move it to `helper-orchestration.R`. Write the AC3 blocks.
- [x] T4: Edit the time-series paragraph in `R/nested-tune-grid.R` and `R/nested-resamples.R`, and the `NEWS.md` entry, to AC4's wording. Run `devtools::document()`. Add a D-entry that extends D-078 with the claim and its bound, and supersedes its clause that leaves any inner design other than `rolling_origin()` unclaimed.
- [x] T5: Time the new file serially. If it runs over 30 s, add it to `Config/testthat/start-first`. Run `devtools::test()` and `devtools::check()`.

## Work log

- 2026-09-27: created by /milestone-plan. Promotes the inner sliding-design candidate row (added 2026-09-21 at M108's plan gate).
- 2026-09-27: criteria audit (full mode, fresh reader) returned 9 findings, all fixed at the gate. AC1 now uses `expect_ts_matches_reference()` and literal inner calls, and names the split class. AC2 adds the outer check. AC3 adds the split check. AC4 reads every "inner" hit and states what is untested. T4's D-entry supersedes D-078's clause. AC5 keeps "0 notes".
- 2026-09-27: plan gate chose `nested_tune_grid()` and `nested_final_fit()` over all seven functions, because tune accepts any rset and the CI legs were near their caps in M111. Falsified by a tuner failing on an inner sliding design that passes under grid.
- 2026-09-27: plan gate chose an outer `rolling_origin()` alone over all four outer designs, because the outer design never reaches the tuner (D-079). Falsified by a sliding outer design failing with an inner sliding design that passes under rolling-origin.
- 2026-09-27: checkpoint, in-progress. T1-T4 edits written, no task checked off yet. The new file passes serially in 24 s, and a planted copy that passes the default inner call fails the three final-fit tests. The full suite and `devtools::document()` are still owed.
- 2026-09-27: T1-T3 done. `TS_INNER_DESIGNS` holds the three fixtures, and `expect_final_matches_reference()` moved to the helper with an `inner` argument. `devtools::test()`: 1010 blocks, 0 failures, 0 errors, 8 min 11 s.
- 2026-09-27: T4 done. Help, `NEWS.md` and D-083 written, `devtools::document()` rewrote six Rd files, both prose sweeps clean. No "inner" hit in R/, man/, NEWS.md, vignettes/ or the README limits the tested inner designs to `rolling_origin()`.
- 2026-09-27: claim audit: 16 claims read, 2 corrected — tests/testthat/helper-orchestration.R (the inner resample counts, and the six-week sliding-period analysis sets). Re-read by the same reader is pending.
- 2026-09-27: the same reader re-read the two corrected claims and the added partial-week clause once, and found that all three hold.
- 2026-09-27: T5 done. The new file runs in 24 s serially, under 30 s, so `start-first` is unchanged. `devtools::check()`: 0 errors, 0 warnings, 0 notes, 9 min 27 s. Status set to review.

## Decisions

## Review
