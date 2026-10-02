# M141: Refuse a split index that is not a row number, and an empty assessment set

**Status:** done (2026-10-02, PR #157 https://github.com/tidymodels/nestedtune/pull/157)

**Goal:** The entry check and `nested_resamples()` refuse two split shapes: an index slot that is not numeric or holds a value outside integer range, and an empty `out_id`.

**Outcome:** `check_split_indices()` in `R/checks.R` replaces M138's `check_na_indices()`. `index_shape()` reads each outer and inner `in_id` and `out_id`. The rule refuses an `NA`, a `NULL` or empty `out_id`, a slot for which `is.numeric()` is FALSE, and a value that `as.integer()` reads as `NA`. The logical `NA` `out_id` stays exempt. The rule runs before the shared-rows and containment rules and raises no warning. One refusal names each bad slot once, by its first shape in that order. `check_outer_indices()` runs the same rule on `outside` in `nested_resamples()`. The help of `nested_resamples()` and `nested_tune_grid()` states the rule, and so do the inherited pages and a NEWS bullet. The DESIGN.md Known issues entry on index shapes keeps the shapes left to rsample. `test-split-checks.R` plants each shape in each slot of both constructors' designs, and those blocks fail with the rule stubbed.

**Decisions:** D-114, which extends D-111 and narrows D-049.

**Review:** three-lens fan-out, 17 findings, none failing a criterion. Fixed at the gate:
- Classed, matrix, integer64, negative and empty outer indices joined the Known issues entry. A stricter type rule was not taken, because an integer64 inner `in_id` runs.
- New tests: two bad slots in one split with the plural clauses, and `3e9` in both the outer and an inner `in_id` of one fold.
- A no-warning check on the `outside` loop, and `info` labels on two type checks.
- The DESIGN.md principle on invalid designs and an M139 paragraph were updated.

Seven were rejected with reasons in the branch's Review section, which git holds. The PR had no reviews or comments. All 14 CI checks passed. No lesson was added or retired.
