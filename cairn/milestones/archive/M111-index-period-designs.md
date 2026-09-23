# M111: Index-based and period-based sliding outer designs

**Status:** done (2026-09-23, PR #127 https://github.com/tidymodels/nestedtune/pull/127)

**Goal:** `sliding_index()` and `sliding_period()` outer designs are tested and documented under the six orchestrators and `nested_final_fit()`.

**Outcome:** `helper-orchestration.R` gains `make_ts_data()`, which is `make_reg_data()` plus 90 consecutive dates. It also gains `ts_index_nested()` and `ts_period_nested()`, each with an inner `rolling_origin()`, and both join `TS_DESIGNS`. The four `test-time-series-*.R` files run every orchestrator's reference loop on them. `test-time-series-designs.R` adds the split-identity tests and the grid and fit_resamples final-fit tests. `check_held_out_once()` reads the first outer split's class against `TIME_SERIES_SPLITS`. An overlapping time-series design gets its own message, with the class still `nestedtune_augment_rows`. A test ties that list to the four fixtures' split classes. The help of the orchestrators and `nested_resamples()`, and `NEWS.md`, state the support. They say the final fit is tested on the new designs for grid and fit_resamples results.

**Decisions:** D-078 extends D-075 to the two designs and the overlap message. It was drafted as D-076. M112 then took D-076 and D-077 on `main`, so it was renumbered.

**Review:** Blocked on 2026-09-22, because the tests put the ubuntu release check step at an estimated 31.5 of 30 min. It resumed after M112. The claim audit read 33 claims and corrected 9. All seven criteria were verified at `d9e5614`, with 1003 tests, 0 skipped, and `devtools::check()` at 0 notes. The blame-history and prior-review lenses found nothing. The diff-bug lens ranked 9 findings. The gate fixed F1 (the split-class test), F4 (narrower final-fit wording), F6 (oracle counts), F7 (comment wrap) and F9 (message wording). It rejected F2, F3, F5 and F8. On PR #127 the check steps took 20.5 min on ubuntu release, against 27.3 estimated, and 27.3 of 30 on oldrel-1.
