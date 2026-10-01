# M138: Refuse an NA in a split's row indices

**Status:** done (2026-10-01, PR #153 https://github.com/tidymodels/nestedtune/pull/153)

**Goal:** The entry check and `nested_resamples()` refuse a design whose split indices hold an `NA`, and the message names each position.

**Outcome:** `check_na_indices()` in `R/checks.R` reads the outer and inner `in_id` and `out_id` of every split. It runs in `check_nested()` after `check_outer_splits()` and before the shared-rows and containment rules. It refuses any value for which `is.na()` is TRUE, with class `nestedtune_bad_design`. The one exemption is an `out_id` identical to the logical `NA`, rsample's mark for the complement. The message names each outer fold, inner split and slot. `check_outer_na()` runs the outer half in `nested_resamples()` on `outside`, naming "Row f of `outside`". Before, an `NA` in an outer `in_id` passed the entry check and the fold failed inside rsample. `?nested_resamples`, the design paragraph of `?nested_tune_grid` and NEWS state the rule. The ROADMAP candidate on an `NA` in both an outer and an inner `in_id` (M137 review B2, B3, O6) was absorbed at plan.

**Decisions:** D-111. It narrows D-049's `out_id` clause and the DESIGN.md Known issues entry on index shapes.

**Review:** Three fresh reviewers found no failing criterion, and all six criteria had fresh evidence. Removing each call turned its tests red. `devtools::check()` gave 0 errors, 0 warnings and 0 notes. There were 19 findings. Nine were fixed at the gate, four went to the Known issues entry on index shapes, and five were rejected. The last one got a fixed comment, and its shape went to Known issues. The fixes were two comments on indices beyond integer range, a check that no unplanted position is named, and three new plants. A test label and two DESIGN.md edits were also fixed. Two of the open shapes pass every rule. They are an index beyond integer range in both an outer and an inner `in_id`, and a `NULL` `out_id`. The milestone file in git gives each reason. CI passed 14 checks with 1 skipped, after re-runs of two jobs that hit their time caps while installing dependencies. No lesson was added or retired.
