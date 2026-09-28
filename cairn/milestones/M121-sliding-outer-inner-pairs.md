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

- [ ] AC1: One test runs for each of the nine pairs, built on the M120 data builder with gaps in `date`. It asserts that `nested_resamples()` builds the same outer and inner splits as `rsample::nested_cv()`, row for row. It asserts that the first outer split and the first inner split have the two designs' split classes. All nine tests pass under `devtools::test()`.
- [ ] AC2: One test runs for each of the nine pairs, on the design `nested_resamples()` builds. It asserts that `nested_tune_grid()` completes every fold. It asserts that the seeds, `.metrics` and `.selected` equal those of `reference_nested_loop()`. It asserts that the first outer split and the first inner split have the two designs' split classes. All nine tests pass under `devtools::test()`.
- [ ] AC3: This criterion covers the three texts M120's AC5 names. The command `git diff main -- R/nested-tune-grid.R R/nested-resamples.R NEWS.md` lists the sentences this milestone adds or changes in them. Each such sentence claims only pairs of an outer and an inner design that an AC1 or AC2 test runs. It claims them only for `nested_resamples()` and `nested_tune_grid()`, never for `nested_final_fit()`. After the change, no sentence in the three texts calls a pair untested that an AC1 or AC2 test runs.
- [ ] AC4: `devtools::check()` reports 0 errors, 0 warnings and 0 notes.

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

## Decisions

## Review
