# M121: Sliding outer designs with inner sliding designs

- **Status:** review
- **Priority:** normal
- **Depends on:** M120
- **Driving RR:** —
- **Principles touched:** IP1, GP1, GP2
- **Resolves:** —
- **Surface tier:** user-facing — the help and `NEWS.md` state which designs users can nest
- **Branch/PR:** m121-sliding-outer-inner-pairs

## Goal

Each sliding outer design with each inner sliding design is tested and documented under `nested_tune_grid()`.

## Scope

**In:** the nine pairs of an outer and an inner design, both drawn from `sliding_window()`, `sliding_index()` and `sliding_period()`. Each pair is tested for its splits against `rsample::nested_cv()` and under `nested_tune_grid()` against `reference_nested_loop()`. The pairs run on the data builder with gaps in `date` that M120 adds, so the sliding-index designs differ from the sliding-window ones. Grid runs on the design `nested_resamples()` builds. That design's inner splits index the whole frame. Each fold re-points them at its outer analysis window, which does not start at row 1. The help, `NEWS.md` and one D-entry state the new claim.

**Out:** the other orchestrators and `nested_workflow_map()` on these pairs → the inner-design candidate row. `nested_final_fit()` on these pairs → the same row. The final fit never reads the outer splits (D-075), but no test here runs it. Any other inner design → stays unclaimed, in that row.

## Acceptance criteria

- [x] AC1: One test runs for each of the nine pairs, built on the M120 data builder with gaps in `date`. It asserts that `nested_resamples()` builds the same outer and inner splits as `rsample::nested_cv()`, row for row. It asserts that the first outer split and the first inner split have the two designs' split classes. All nine tests pass under `devtools::test()`.
- [x] AC2: One test runs for each of the nine pairs, on the design `nested_resamples()` builds. It asserts that `nested_tune_grid()` completes every fold. It asserts that the seeds, `.metrics` and `.selected` equal those of `reference_nested_loop()`. It asserts that the first outer split and the first inner split have the two designs' split classes. All nine tests pass under `devtools::test()`.
- [x] AC3: This criterion covers the three texts M120's AC5 names. The command `git diff main -- R/nested-tune-grid.R R/nested-resamples.R NEWS.md` lists the sentences this milestone adds or changes in them. Each such sentence claims only pairs of an outer and an inner design that an AC1 or AC2 test runs. It claims them only for `nested_resamples()` and `nested_tune_grid()`, never for `nested_final_fit()`. After the change, no sentence in the three texts calls a pair untested that an AC1 or AC2 test runs.
- [x] AC4: `devtools::check()` reports 0 errors, 0 warnings and 0 notes.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T3
- AC4 → T4

## Tasks

- [x] T1: Add the nine pair fixtures to `helper-orchestration.R`, each with its outer and inner split class and its literal `nested_resamples()` call. Choose the parameters so that each design has at least three outer folds and every outer fold holds at least one inner resample. State the counts and the counting command in the fixture comment.
- [x] T2: Write the AC1 and AC2 tests in new `test-time-series-*.R` files with a file-level `skip_heavy_on_cran()` and an oracle header. Time each file serially. Split a file that runs far longer than the others, and add a long one to `Config/testthat/start-first` (LESSONS M16).
- [x] T3: Update the three texts and run `devtools::document()`. Append a D-entry that claims the nine pairs under `nested_resamples()` and `nested_tune_grid()`. It supersedes the D-083 and D-084 clauses that leave the three sliding outer designs unclaimed with inner sliding designs. Run `Rscript benchmarks/sweep-prose.R --plain` and `--roxygen --plain`.
- [x] T4: Run `devtools::test()` and `devtools::check()`, and record the new files' serial times in the work log.

## Work log

- 2026-09-27: created by /milestone-plan. Absorbs the outer-design part of the inner-design candidate row. The criteria audit ran in full mode and returned 3 findings on this milestone, all fixed before the gate.
- 2026-09-27: the full-mode re-audit of the final wording returned no findings on this milestone.
- 2026-09-27: plan gate chose all nine pairs over a five-pair cross, so the help makes one claim with no list of exceptions. Falsified by the suite time the nine pairs add pushing a CI check step near its cap.
- 2026-09-27: implement started on branch `m121-sliding-outer-inner-pairs`. Question gate skipped: the plan fixes the parameters by T1's bounds and the file layout by T2.
- 2026-09-27: T1 done. `TS_SLIDING_PAIRS` holds the nine pairs on `make_ts_weekday_data()`, with 3 or 4 outer folds and 2 to 7 inner resamples per fold, counted in the fixture comment. `ts_pair_reference()` rebuilds a pair's call with `rsample::nested_cv()`.
- 2026-09-27: T2 done. `test-time-series-pairs-window.R`, `-index.R` and `-period.R` each pass 6 of 6, serially in 11.4 s, 10.8 s and 14.2 s with the package load. None runs far longer than the rest, so no split and no `start-first` entry. With the inner index remap planted as a no-op, each grid test fails 5 assertions. The full suite ran 1051 tests with 0 failures and 0 skips.
- 2026-09-27: T3 done. The sentence calling the three sliding outer designs untested with these inner designs is replaced in the two help sections and `NEWS.md` by the nine-pair claim, which names the functions not tested on the pairs. D-087 appended. `devtools::document()` rewrote six Rd files, and all six gating prose sweeps print clean.
- 2026-09-27: claim audit: 30 claims read, 2 corrected — helper-orchestration.R, R/nested-tune-grid.R. The corrections are the outer sliding-index window, a 69-day lookback spanning 70 days, and the grid help's nine-pair sentences, moved after the `augment()` sentences with `augment()` added to the not-tested list. The re-read found both accurate.
- 2026-09-27: T4 done. The full suite ran 1051 tests with 0 failures and 0 skips on the tree before the claim-audit fixes, which changed only comments and help text. `devtools::check()` on the final tree gave 0 errors, 0 warnings and 0 notes. The new files' serial times are in the T2 line. Status set to review.
- 2026-09-27: review gate fix-now work landed: D-088, `augment()` dropped from the grid help's not-tested list, and a shape check in `ts_pair_reference()`.
- step-7 approval: m121-sliding-outer-inner-pairs approved for merge

## Decisions

## Review

Evidence at `a7a754a0`, 2026-09-27. Main had not moved since the branch was cut.

- AC1: `devtools::test(filter = "time-series-pairs")` ran the nine "<pair> splits match rsample::nested_cv()" tests, one per name in `TS_SLIDING_PAIRS`, with 0 failures, 0 skips and 0 errors. Each builds on `make_ts_weekday_data()`, asserts the first outer and first inner split classes, and runs `expect_outer_identical()` and `expect_inner_identical()` against `ts_pair_reference()`, the pair's call with `rsample::nested_cv()` in place of `nested_resamples()`.
- AC2: the same run passed the nine "nested_tune_grid() on the <pair> pair matches a hand-rolled reference loop" tests with 0 failures, 0 skips and 0 errors. Each runs on `spec$build(d)`, the pair's `nested_resamples()` call, asserts both split classes, and calls `expect_ts_matches_reference()`, which asserts `.completed` on every fold, both seed columns, and each fold's `.metrics` and `.selected` against `reference_nested_loop()`. At implement, with the inner index remap planted as a no-op, each grid test failed 5 assertions.
- AC3: the named `git diff main` lists one changed sentence and one new passage per text. The changed sentence drops "The other three outer designs are not tested with these inner designs." The new passages claim the nine pairs, the AC1 and AC2 pairs, under `nested_resamples()` (splits) and `nested_tune_grid()` alone, and put `nested_final_fit()` in the not-tested list. A grep for "not tested", "untested", "unclaimed" and "not supported" across the three texts finds only "Any other inner design is not tested" and the new not-tested lists, none of which names a pair or function an AC1 or AC2 test runs.
- AC4: `devtools::check()` at `a7a754a0` gave 0 errors, 0 warnings and 0 notes.

Consistency gate, all clean: `cairn_validate` passes (18 references-staleness advisories, none from this milestone). `devtools::document()` leaves no diff. README untouched. `pkgdown::check_pkgdown()` finds no problems. `NEWS.md` has the entry. No new top-level files. All six gating prose sweeps print clean, and `air format --check` passes on the touched R files. No principle changed, so `cairn_impact` is skipped.

Independent review (user-facing tier, three lenses). Blame-history [S]: no findings. Prior-review [S]: no findings, and the M119 and M120 fixture lessons hold. Diff-bug [O], ranked, with proposed dispositions:
- F1: D-087's Consequences say "every function other than grid on these pairs stays unclaimed", which contradicts its own Decision claiming `nested_resamples()` too. Proposed: fix now, in a superseding D-088.
- F2: the grid help lists `augment()` as not tested on the pairs, but the `nested_resamples()` help, `NEWS.md` and D-087's Decision do not. Its refusal depends only on the outer design. Proposed: fix now, by dropping `augment()` from the grid list. The separate paragraph already resolves the claim-audit ambiguity.
- F3: D-087's supersession of "D-084's reading of D-083's claim as bound to an outer `rolling_origin()`" is looser than D-084's words ("on D-083's terms"). Proposed: fix now, in D-088.
- F4: D-087 does not cite the D-085 Consequences clause it fulfils ("where M121 takes grid"). Proposed: fix now, in D-088.
- F5: D-087's falsifier tests an assumption about the unclaimed functions and cannot falsify the claim itself. Proposed: fix now, in D-088.
- F6: `ts_pair_reference()` does not check that the call head is `nested_resamples` and drops any statement after the first. Proposed: fix now, with a stop on either shape.
- F7: the three test files are identical apart from the outer name. Proposed: reject, because the one-file-per-outer-design shape follows M119 and M120, and the split holds parallel timing.
- F8: the class assertions read only fold 1's first outer and inner split. Proposed: reject, because AC1 and AC2 ask for exactly that and a hand check found no other class in any fold.
- F9: AC4 had no evidence line yet. Resolved by the AC4 line above.

Triage at the gate (2026-09-27): the maintainer chose the proposed dispositions. F1, F3, F4 and F5 fixed in D-088. F2 fixed: the grid help's not-tested list drops `augment()`. F6 fixed: `ts_pair_reference()` stops on a body that is not one `nested_resamples()` call, shown to fire on a `nested_cv()` head and on a two-statement body. F7 and F8 rejected for the reasons above. F9 resolved. After the fixes, the 18 pair tests pass with 0 failures, the six prose sweeps print clean and `cairn_validate` passes.
