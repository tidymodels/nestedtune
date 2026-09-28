# M119: Inner sliding-window, sliding-index and sliding-period designs

**Status:** done (2026-09-27, PR #134 https://github.com/tidymodels/nestedtune/pull/134)

**Goal:** An inner `sliding_window()`, `sliding_index()` or `sliding_period()` design under an outer `rolling_origin()` is tested and documented under `nested_tune_grid()` and `nested_final_fit()`.

**Outcome:** `TS_INNER_DESIGNS` in `tests/testthat/helper-orchestration.R` holds three fixtures on `make_ts_data()`. Each pairs an outer `rolling_origin(initial = 60, assess = 1, skip = 9)` with one inner sliding design. `tests/testthat/test-time-series-inner.R` runs 9 tests against the grid reference loop, `rsample::nested_cv()`'s splits and a hand-run final fit. `expect_final_matches_reference()` moved to the helper, takes the inner call as `inner`, and now compares `out_id`s as well as `in_id`s. The help of `nested_tune_grid()` and `nested_resamples()` and `NEWS.md` state the support and what is not tested. No package code changed. The new file runs in 24 s serially, so `start-first` is unchanged.

**Decisions:** D-083 claims the three inner designs. D-084 corrects its scope and narrows D-074's inner-design clause as well as D-078's.

**Review:** Three fresh reviewers. Blame-history and prior-review found nothing to fix. The diff reviewer ranked 11 findings, none blocking. Fixed at the gate: the help's lead sentence (F2), the `out_id` check (F6), the fixture comment and its counting procedure (F7), and D-083's scope (F3-F5, by D-084). F1 went to the inner-design candidate row: on gap-free daily dates the sliding-index fixture builds the same splits as sliding-window. Rejected: F8 (one oracle type, by precedent), F9 and F11 (intended), F10 (maintenance only). The pre-review claim audit corrected 2 of 16 claims. `format-suggest` failed on one long line, which `air format` fixed. The first CI wait timed out, and the resumed review merged on green CI.
