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

- [x] AC1: Three designs are built by `rsample::nested_cv()` on `make_ts_data()`. Each has the outer design `rolling_origin(initial = 60, assess = 1, skip = 9)`. The inner designs are `sliding_window(lookback = 39, assess_stop = 1, step = 5)`, `sliding_index(index = date, lookback = 39, assess_stop = 1, step = 5)` and `sliding_period(index = date, period = "week", lookback = 5)`. For each design, a test asserts that the first fold's first inner split has the class `sliding_window_split`, `sliding_index_split` or `sliding_period_split` as its name claims. The same test runs `nested_tune_grid()` and `reference_nested_loop()` on that nested object under one seed. It asserts a match through `expect_ts_matches_reference()`.
- [x] AC2: For each of the three designs, a test calls `nested_resamples()` with the same `outside` and `inside` calls. It asserts that the splits match `rsample::nested_cv()`'s through `expect_outer_identical()` and `expect_inner_identical()`.
- [x] AC3: For each of the three designs, a test runs `nested_final_fit()` on the `nested_tune_grid()` result. The reference runs under the final fit's recorded seeds. It evaluates the fixture's literal inner call on the full data, then runs `tune::tune_grid()`, `tune::select_best()` and `fit()`. The test asserts identical inner split `in_id`s, an identical selected row, and identical predictions on the full data.
- [x] AC4: The help of `nested_tune_grid()` and of `nested_resamples()` states the three inner designs as tested. So does `NEWS.md`. Each of the three texts names the outer `rolling_origin()`, `nested_tune_grid()`, and `nested_final_fit()` for its results. Each also says that the other orchestrators and the other outer designs are not tested with these inner designs. The reviewer reads every hit of `grep -rn -i 'inner' R/ man/ NEWS.md vignettes/ README.md README.Rmd`. No hit limits the tested inner designs to `rolling_origin()` alone.
- [x] AC5: `devtools::test()` passes with 0 failures. `devtools::check()` reports 0 errors, 0 warnings and 0 notes.

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
- step-7 approval: m119-inner-sliding-designs approved for merge

## Decisions

## Review

Evidence gathered 2026-09-27 on the branch at `2c3a15e7`. Main had not moved, so no merge was needed. `devtools::test()`: 1010 blocks, 0 failures, 0 errors, 0 skips.

- AC1 evidence: the three fixtures in `helper-orchestration.R` call `rsample::nested_cv()` on `make_ts_data()` with the named outer and inner calls. In `test-time-series-inner.R`, each "nested_tune_grid() on an inner ... design matches a hand-rolled reference loop" block asserts `rof_split` and the inner split class. It then runs both functions under seed 20 and calls `expect_ts_matches_reference()`. All three blocks passed, 11 expectations each.
- AC2 evidence: each "inner ... splits match rsample::nested_cv()" block calls `nested_resamples()` with the fixture's `outside` and `inside` calls (`TS_INNER_LEAN_CALLS`). It asserts both split classes, `expect_outer_identical()` and `expect_inner_identical()`. The blocks passed with 55, 55 and 51 expectations.
- AC3 evidence: each "the final fit on an inner ... design matches a hand-rolled reference" block runs `expect_final_matches_reference()` with the fixture's literal inner call as `inner`. The helper sets the final fit's `tuning_seed`, builds the inner design on the full data, and runs `tune_grid()` and `select_best()`. It then fits under `fit_seed` and asserts identical inner `in_id`s, selected row and predictions. The block also asserts the rebuilt inner split class. All three passed, 4 expectations each. A copy passing the default `rolling_origin()` call failed all three (implement work log).
- AC4 evidence: `R/nested-tune-grid.R:138-143`, `R/nested-resamples.R:53-60` and `NEWS.md:60-67` each name the three inner designs as tested. Each names the outer `rolling_origin()`, `nested_tune_grid()`, and `nested_final_fit()` for its results. Each says the other orchestrators, `nested_workflow_map()` and the other three outer designs are not tested with them. The grep gives 679 hits. A hit that limits the tested inner designs to `rolling_origin()` has to name it, and the hits naming `rolling` are only these new lines and `NEWS.md:49`. `NEWS.md:49` states the outer-design support and limits nothing. I also read the 45 hits naming a design, a test or support. The vignettes and README have no time-series text.
- AC5 evidence: `devtools::test()` gave 1010 blocks, 0 failures and 0 errors. `devtools::check()` gave 0 errors, 0 warnings and 0 notes (8 min 36 s).
- Consistency gate: `cairn_validate.py` passed, coverage complete, with 18 reference-staleness advisories. `devtools::document()` made no diff. `pkgdown::check_pkgdown()` found no problems. All six gating prose sweeps were clean. `NEWS.md` has an entry, with no milestone number. There are no new top-level files, the branch does not touch the README, and no principle changed.
- Independent review: the three reviewers ran fresh. Blame-history found nothing. Prior-review found no past finding reintroduced, and noted that the resample counts in the fixture comment are not pinned to a procedure. The diff-bug reviewer ranked 11 findings, none blocking:
  - F1: on gap-free daily dates, the sliding-index fixture builds the same inner splits as sliding-window (confirmed by probe), so it proves the split class only.
  - F2: the `nested_tune_grid()` help's lead sentence still says time-series designs are supported with an inner `rolling_origin()`.
  - F3: D-083 does not supersede D-074's matching "inner designs other than `rolling_origin()`" clause.
  - F4: D-083's title and parenthetical state the supersession wider than the three designs.
  - F5: D-083's rejection rationale says the other tuners reach no new code path, which is untested.
  - F6: the final-fit helper compares inner `in_id`s only, not `out_id`s.
  - F7: the fixture comment's six-week analysis sets are 36 rows in each first resample, because the data starts mid-week.
  - F8: all oracles in the new file are the live reference type.
  - F9: the AC1 reference reads the fixture's own inner splits.
  - F10: the fixture calls are spelled out in three places.
  - F11: AC3's grid result is a cache hit on AC1's build.
- Triage at the gate (user chose the proposed triage): F2 fixed (lead sentence names the inner sliding designs). F6 fixed (`out_id` assertion in `expect_final_matches_reference()`). F7 and the prior-review note fixed (comment gives the counting procedure and date, the short first analysis set, and the index-equals-window fact). F3-F5 fixed by D-084. F1 goes to the follow-up inner-design candidate row. Rejected: F8 (precedent recorded in `test-time-series-designs.R`, no second oracle type for pass-through checks), F9 (intended, AC2 covers split building), F10 (maintenance only, an edit to one copy fails loudly), F11 (intended, the test still runs alone).
