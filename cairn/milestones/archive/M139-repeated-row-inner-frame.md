# M139: Frame the inner splits on the analysis set under a repeated outer row

**Status:** done (2026-10-01, PR #155 https://github.com/tidymodels/nestedtune/pull/155)

**Goal:** Under an outer split whose `in_id` repeats a row, each inner tuning call gets its inner splits on the outer fold's analysis set. So tune finalizes an unknown parameter range without the outer held-out rows.

**Outcome:** `analysis_framed_inner()` (`R/nested-resamples.R`) maps each inner index by occurrence through `occurrence_map()`. The r-th mention of a row goes to its r-th copy in the outer `in_id`, cycling past the last copy. `match()` runs when no row repeats. Under repeats a logical `NA` `out_id` becomes every analysis-frame position whose row lies in `rsample::complement()` over the whole frame. That is each outer copy, and no held-out row. `whole_frame_inner()` replaces the hotfix's `complement_within_outer()`. On every path that keeps the whole frame, it makes each derivable logical `NA` `out_id` explicit as outer rows, with or without repeats. Those paths are an outer index that is `NA`, fractional, below 1 or past the data, and an inner split the map cannot place. So a failed fold's inner metrics hold no outer held-out row. `test-nested-tune-finalize.R` holds O1, from dials `get_n_frac_range()`, where the 65-row frame gives 6 to 32 and the whole frame 9 to 45. It holds O2, against an analysis-frame reference design. It also tests the map, the complement, the whole-frame paths and RNG use. The help, the DESIGN Architecture paragraph and NEWS are updated.

**Decisions:** milestone-local, from RR09. Keep the occurrence map and its wrap. Ship the by-copy complement, stated through `rsample::complement()`. Test with `nested_tune_grid()` and the recorded `run_tuner()` frame only.

**Review:** three-lens fan-out. The prior-review lens found no regression. Fixed at the gate:
- F1: the path without repeats ran the occurrence map, 7.5 s against 0.41 s for five folds at 1e6 rows.
- F2: one split whose complement errors stopped the per-split repair.
- F3: a fractional or over-range outer index under repeats failed as "inner tuning".
- F4: memory grew with the square of a row's copy count.
- F5: two test gaps. F6: overclaims in NEWS and DESIGN.

The fix re-read found F11, a regression: without repeats, the widened guard left a logical `NA` `out_id` unrepaired. Running `whole_frame_inner()` on every path fixed it. That also closed the past-the-data leak without repeats, so its candidate row was removed. Rejected: F7, an apparent-split caveat in the help. F8, that O1 cannot tell two identical folds apart, as planned. F9, that positions differ from rsample's for inner designs that do not ascend, per RR09 R3. The claim audit at implement read 30 claims and corrected 4. CI's formatter check failed once on a long test line, which was wrapped before the merge. No lesson was added or retired.
