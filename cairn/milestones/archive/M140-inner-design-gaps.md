# M140: Inner-design gaps under the other functions

**Status:** done (2026-10-01, PR #156 https://github.com/tidymodels/nestedtune/pull/156)

**Goal:** The inner-design gaps that M120 and M121 left are tested and documented.

**Outcome:** The Bayes, racing and annealing final-fit tests in `test-time-series-inner-bayes-anneal.R` and `test-time-series-inner-race.R` now loop over all three inner sliding designs. Each run comes from the file's fixture cache. `reference_final_fit()` takes an `inner_design` argument. `expect_ts_final_matches()` also compares each inner split's frame, because the same positions on another frame are other rows. `test-time-series-inner-other.R` runs `nested_workflow_map()` with each tuner `fn` on the inner sliding-period design. It compares the recorded tuner, because a race that drops no candidate scores as grid does. The new `test-time-series-pairs-other.R` covers the sliding-window / sliding-window pair. It tests the four tuners, `nested_fit_resamples()`, the map with its default `fn` and the grid final fit. Its grid test finalizes `min_n` from each fold's analysis rows, with an analytic oracle and a `nested_cv()` reference. The range is 6 to 30 on 60 rows, against 9 to 45 on the whole frame. If the re-pointing of the inner splits is skipped, the test fails. No M121 test caught that. `FINALIZE_FRAC`, `frac_min_n()` and `frac_param_info()` moved to `helper-orchestration.R`. The help of `nested_resamples()` and `nested_tune_grid()`, its five inherited pages and two NEWS bullets state the new tested set. No package code changed.

**Decisions:** D-112 records the new claims. D-113 corrects its heading, supersession note and falsifiers.

**Review:** three-lens fan-out, with 20 findings merged into 13 and none failing a criterion. Fixed at the gate:
- F1 to F3: D-112 left D-085's Consequences clause and D-087's re-pointing sentence standing. Its heading overclaimed, and its falsifiers did not test its claims. D-113 fixes all three.
- F4: a reader can take "These functions are not tested on the other eight pairs" to include grid. The help and NEWS now name the two tested functions.
- F5: two unclaimed combinations on the pair joined the inner-design candidate row.

F6, the added test time, was measured on PR #156: macOS 27m11s, Windows 28m53s, `test-devel-vctrs` 37m10s, all green. F7 to F13 were rejected. They were unasserted fixture literals, race elimination in the map tests, and the map oracle from before M140. The rest were test names, unticked boxes, a repeated grid run, and a stale count in the timing baseline. No lesson was added or retired. The two lessons this milestone taught live in D-112 and in the test comments.
