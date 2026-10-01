# M135: Close the split-check gaps M134's review left

**Status:** done (2026-09-30, PR #150 https://github.com/tidymodels/nestedtune/pull/150)

**Goal:** The split checks give the right refusal on each shape M134's review logged, in a fraction of their present time on large inner designs.

**Outcome:** `malformed_lines()` in `R/checks.R` names a split element that lacks the `rsplit` class or is not a list. `check_nested()` uses it for the outer and inner `splits` columns, and `nested_resamples()` uses it for `outside` and each `inside` rset before any split is read. These refusals have class `nestedtune_bad_design` and replace unclassed crashes. `complement_is_default()` now also looks for a `complement.<class>` method in rsample's namespace, its parents up to the global environment, and base, as S3 dispatch does. On an inner split built on the outer frame, `fold_overlap_rows()` passes a mark of the outer `in_id`. So the shared-rows rule counts only held rows, and the containment rule names a held-out row (D-109). If `rows` repeats no value, `split_shares_rows()` skips a default-complement split. The containment loop marks the outer `in_id` once per fold. `benchmarks/split-check-speed.R` times a base commit and the working tree in one session. NEWS has four sub-bullets for the refusals and one for the speed.

**Decisions:** D-109 at plan. The question gate narrowed AC3 to a method that returns only rows of the frame and dropped the attached-environment case.

**Review:** Three fresh reviewers found no failing criterion. All five criteria had fresh evidence. The suite ran 1212 tests with 0 failures, and `devtools::check()` gave 0 errors, 0 warnings and 0 notes. Check time fell by 88.2% and 86.1% against an 80% bar. Of 14 findings, D1, D2, D5, B5 (NEWS precision) and D6 (benchmark header) were fixed at the gate. B1, P1 and P3 (test gaps) became one candidate row. D1's out-of-frame limit went to DESIGN Known issues. The rest were rejected with reasons in the milestone file in git. All 14 PR checks passed. No lesson was added or retired.
