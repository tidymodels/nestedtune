# M108: Rolling-origin and sliding-window outer designs

**Status:** done (2026-09-21, PR #123 https://github.com/tidymodels/nestedtune/pull/123)

**Goal:** The package tests and documents `rolling_origin()` and `sliding_window()` outer designs, which run today with no test and no stated support.

**Outcome:** `tests/testthat/test-time-series-designs.R` runs `nested_tune_grid()` over two `rsample::nested_cv()` fixtures from `helper-orchestration.R`. One is `rolling_origin()` outer and inner. The other is `sliding_window()` outer (with `lookback`) and `rolling_origin()` inner. Both use `assess = 1`. Each fold matches `reference_nested_loop()`. `nested_resamples()` builds both designs split for split. `nested_final_fit()` matches a `tune_grid()`, `select_best()`, `fit()` reference under the recorded seeds. `collect_predictions()` returns each outer-assessment row once per fold. `augment()` still refuses such a result with `nestedtune_augment_rows`. Where no row is held out twice, its message now names the rows no fold held out, by count and first and last row numbers. It no longer names a repeated or Monte Carlo design there. The help of `nested_tune_grid()`, `nested_resamples()` and `augment()` states the support, and the siblings inherit the `nested_tune_grid()` section. `NEWS.md` has two entries. `sliding_index()`, `sliding_period()` and the other orchestrators stay unsupported (candidate row).

**Decisions:** D-071 (the support and its bound to what is tested).

**Review:** All six criteria verified with fresh evidence and `devtools::check()` at 0 notes. The blame-history and prior-review lenses found nothing. The diff-bug lens ranked 11 findings. The gate fixed four: R2 (an `augment()` test on the sliding-window result), R3 (the condition call), R8 (a help link) and R9 (`memoised()` runs). R1 (an overlapping `sliding_window()` design still gets the repeated-design message) went to the time-series candidate row. R4-R7, R10 and R11 were noted with no change. CI first failed `format-suggest` on three long test lines, fixed by `air format`, then went green on 14 checks. No lesson was added or retired at hygiene.
