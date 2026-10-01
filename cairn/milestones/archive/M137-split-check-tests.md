# M137: Test the split-check gaps M135's review left

**Status:** done (2026-10-01, PR #152 https://github.com/tidymodels/nestedtune/pull/152)

**Goal:** The split-check tests reach the index shapes, the NA outer `in_id` and the condition calls that M135's review found untested.

**Outcome:** `tests/testthat/test-split-checks.R` gained three things, and `R/` did not change. A new block plants 0, -1, NA and the row count plus one in an inner `in_id`. It plants 0, -1 and the row count plus one in that split's `out_id`. It asserts that the containment rule refuses each plant and names the planted value. A second new block puts an NA in the first outer `in_id`. It asserts that the inner shared-row rule still refuses a held shared row. A new helper, `expect_grid_refuses()`, passes a design to `nested_tune_grid()`. It asserts the same class vector, the same message and the call name `nested_tune_grid`. All 13 refusal blocks now assert the condition's call. The ROADMAP row "M135's review leftovers on split-check tests" was removed at plan.

**Decisions:** none. The plan gate chose a `nested_tune_grid()` pass in every refusal block over one block per message. It also chose planted-defect runs over passing tests alone.

**Review:** Three fresh reviewers found no correctness defect, and all four criteria had fresh evidence. With the `held()` edit planted, all seven plants were accepted and the first block failed. With the `fold_overlap_rows()` edit planted, the second block failed. `devtools::check()` gave 0 errors, 0 warnings and 0 notes. CI passed 14 checks with 1 skipped. Of 14 findings, O1 to O4 and B4 were fixed at the gate: failure labels in the loops, an exact class comparison, and an assertion that the containment message is absent. B2, B3 and O6 became a candidate row. It records that an NA in both the outer and an inner `in_id` passes the containment check. The others were rejected with reasons in the milestone file in git. No lesson was added or retired.
