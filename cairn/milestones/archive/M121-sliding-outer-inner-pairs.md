# M121: Sliding outer designs with inner sliding designs

**Status:** done (2026-09-27, PR #136 https://github.com/tidymodels/nestedtune/pull/136)

**Goal:** Each sliding outer design with each inner sliding design is tested and documented under `nested_tune_grid()`.

**Outcome:** `TS_SLIDING_PAIRS` in `helper-orchestration.R` holds the nine pairs of an outer and an inner design drawn from `sliding_window()`, `sliding_index()` and `sliding_period()`. Each pair is a literal `nested_resamples()` call on `make_ts_weekday_data()`. Each pair has 3 or 4 outer folds, and every fold after the first re-points its inner splits at a window that does not start at row 1. `ts_pair_reference()` rebuilds a pair's call with `rsample::nested_cv()` and stops on any other body shape. Three new files, `test-time-series-pairs-{window,index,period}.R`, hold 18 tests and run 11 to 14 s each serially. They test each pair's splits against `rsample::nested_cv()` and its `nested_tune_grid()` run against `reference_nested_loop()`. A planted no-op in the inner re-pointing failed every grid test. The help of `nested_tune_grid()` and `nested_resamples()` and `NEWS.md` claim the pairs under those two functions and name the functions not tested on them. No package code changed.

**Decisions:** D-087 claims the nine pairs under `nested_resamples()` and `nested_tune_grid()`. D-088 corrects its Consequences, its supersession of D-084 and its falsifier, and cites the D-085 clause it fulfils.

**Review:** Three fresh reviewers. Blame-history and prior-review found nothing. The diff reviewer ranked F1-F9 with no bug. Fixed at the gate: D-087's wording faults in D-088 (F1, F3-F5). The grid help's not-tested list dropped `augment()` (F2), and `ts_pair_reference()` gained a shape check (F6). F7 (three near-identical test files) and F8 (class read on fold 1 only) were rejected with reasons, and F9 closed with the AC4 evidence. The pre-review claim audit corrected 2 of 30 claims. The first CI wait timed out, and the resumed review merged on green CI.
