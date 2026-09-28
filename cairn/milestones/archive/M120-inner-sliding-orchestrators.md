# M120: Inner sliding designs under the other orchestrators

**Status:** done (2026-09-27, PR #135 https://github.com/tidymodels/nestedtune/pull/135)

**Goal:** An inner `sliding_window()`, `sliding_index()` or `sliding_period()` design under an outer `rolling_origin()` is tested and documented under every orchestrator other than `nested_tune_grid()`.

**Outcome:** Three new test files run on `TS_INNER_DESIGNS`. `test-time-series-inner-bayes-anneal.R` and `test-time-series-inner-race.R` test the four other tuners on each design against their reference loops (12 tests). They also test the four tuners' final fits on sliding-period (4 tests). `test-time-series-inner-other.R` tests `nested_fit_resamples()` against `tune::fit_resamples()` and `nested_workflow_map()` against hand calls (6 tests). The sliding-index fixture moved to `make_ts_weekday_data()`, with weekday-only dates, so its inner splits differ from sliding-window's in every fold. `expect_ts_final_matches()` takes `split_class` and compares `out_id`. The two long files joined `Config/testthat/start-first`. The help of `nested_tune_grid()` and `nested_resamples()` and `NEWS.md` state the new claims. No package code changed.

**Decisions:** D-085 claims the designs under the other orchestrators and `nested_workflow_map()`, with final fits on sliding-period alone. D-086 corrects it: `nested_fit_resamples()` checks the inner design but fits nothing on it.

**Review:** Three fresh reviewers. Blame-history found nothing. The diff reviewer found no bug and ranked O1-O9, and prior-review raised the same line-wrap point as P1. Fixed at the gate: the broken help and NEWS line, the long DESCRIPTION line and one helper comment (O5-O7, P1). O1 went to the inner-design candidate row: `nested_workflow_map()` is tested only with its default grid tuner. O2-O4, O8 and O9 were rejected with reasons. The pre-review claim audit corrected 4 of 36 claims and led to an AC3 and AC5 amendment. The first CI wait timed out, and the resumed review merged on green CI.
