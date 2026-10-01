# M137: Test the split-check gaps M135's review left

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, GP3
- **Resolves:** —
- **Surface tier:** internal — it adds tests only, and no exported behavior changes
- **Branch/PR:** m137-split-check-tests

## Goal

The split-check tests reach the index shapes, the NA outer `in_id` and the condition calls that M135's review found untested.

## Scope

**In:** new and extended `test_that()` blocks in `tests/testthat/test-split-checks.R`. They cover M135 review findings B1, P1 and P3. The ROADMAP candidate row "M135's review leftovers on split-check tests" holds those findings. This milestone takes all three, so the plan commit removes that row.

**Out:** a change to `R/` code. If a new test shows a defect, the defect goes to `/hotfix` or to a new candidate row. This milestone's test for it then waits on that fix. An `NA` added to an inner `out_id` is out, because the containment rule drops it by design (DESIGN.md Known issues, "Index-slot shapes"). A NEWS entry is out, because no user-visible behavior changes.

## Acceptance criteria

- [x] AC1: `tests/testthat/test-split-checks.R` has a test on a `nested_resamples()` design. The inner splits of that design index the outer frame. The test plants each of `0`, `-1`, `NA` and the frame's row count plus one in an inner split's `in_id`. It plants each of `0`, `-1` and the row count plus one in that split's `out_id`. For each of the seven plants, it asserts that `check_nested()` refuses with class `nestedtune_bad_design`. It also asserts the containment message, naming the planted value in that slot. When `held()` in `check_inner_splits()` (`R/checks.R`) is edited to answer `TRUE` for every index outside the frame, the test fails.
- [x] AC2: `tests/testthat/test-split-checks.R` has a test on a `nested_resamples()` design whose first outer `in_id` holds an `NA`. The first inner split of that fold holds a row of that outer `in_id` in both its analysis and assessment sets. The test asserts that `check_nested()` refuses with class `nestedtune_bad_design`. It also asserts the inner shared-rows message, naming element 1, split 1. When `fold_overlap_rows()` (`R/checks.R`) is edited to return no rows for a fold whose outer `in_id` holds an `NA`, the test fails.
- [x] AC3: A search of `tests/testthat/test-split-checks.R` for `nestedtune_bad_design` finds two kinds of `test_that()` block: a block whose body holds that string, and a block that calls a helper whose body holds it. Every block of either kind asserts the condition's call. A block calling `nested_resamples()` asserts that `rlang::call_name(conditionCall(cnd))` is `"nested_resamples"`. A block calling `check_nested()` also passes the same design to `nested_tune_grid()`. It asserts that the refusal there has the same class and message, and the call name `"nested_tune_grid"`.
- [x] AC4: `Rscript -e 'devtools::test()'` reports 0 failures. `Rscript -e 'devtools::check()'` reports 0 errors and 0 warnings.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T4

## Tasks

- [x] T1: Add the index-plant test of AC1 to `tests/testthat/test-split-checks.R`, with `edit_whole_inner()`. Make the `out_id` plants on a split whose `out_id` is not `NA`. Plant the `held()` edit, see the test fail, revert the edit, and log one work-log line.
- [x] T2: Add the NA outer `in_id` test of AC2 next to the M135 shared-rows tests. Plant the early return in `fold_overlap_rows()` and see the test fail. Revert the edit and log one work-log line.
- [x] T3: Add a test helper that passes a design to `nested_tune_grid()` with a small workflow on `shape_data()` and returns the refusal. Extend each block that AC3 names, the new blocks of T1 and T2 included. The hard-dependency CI leg can lack a package that the helper needs. In that case, guard the entry assertion with the skip helper the suite uses for that package (LESSONS, M101).
- [x] T4: Run the full suite and `devtools::check()`. Before the review push, run `air format --check` on the touched file.

## Work log

- 2026-09-30: created by /milestone-plan from the candidate row "M135's review leftovers on split-check tests" (B1, P1, P3), which the plan commit removes.
- 2026-09-30: reduced criteria audit (fresh Opus reader) returned one finding. AC3's search missed blocks that refuse only through `expect_contained()` or `expect_not_list()`. AC3 now also covers blocks that call a helper holding the string. The reader said that T2's planted edit fails at `expect_error`. That note was not taken, because a probe showed that the NA outer `in_id` makes the containment rule refuse row 1.
- 2026-09-30: T1 added the seven-plant index test. With `held()` edited to answer `TRUE` outside the frame, `check_nested()` accepted the `in_id` 0 plant and the test failed at its `expect_error()`. Edit reverted, `R/checks.R` matches main.
- 2026-09-30: T2 added the NA outer `in_id` test, the NA appended to the outer `in_id`. With the early return planted in `fold_overlap_rows()`, `check_nested()` accepted the design and the test failed at its `expect_error()`, not on the containment message T2 expected. The plan-time reader's note was right for this placement. Edit reverted.
- 2026-09-30: checkpoint. T1 and T2 tests are committed and the full suite is still running, so neither task is ticked yet.
- 2026-09-30: full suite on `eb1bc94a` with `R/checks.R` equal to main: 0 failures. T1 and T2 ticked.
- 2026-09-30: minor amendment. T2's wording no longer says the test fails on the containment message, because the plant made `check_nested()` accept the design.
- 2026-09-30: T3 added `expect_grid_refuses()` and call assertions in all 13 refusal blocks. It needs no skip, because tune imports recipes. With `call = NULL` planted in `nested_tune_grid()`'s `check_nested()` call, all 10 `check_nested()` blocks failed at the call-name line. Edit reverted. Checkpoint: the full suite is running, so T3 is not ticked.
- 2026-09-30: full suite on `2730209c` with `R/` equal to main: 0 failures. `air format --check` clean on the test file. T3 ticked.
- 2026-09-30: T4: `devtools::check()` on `eccea957` gave 0 errors, 0 warnings and 0 notes. The suite and `air` results are the T3 lines above.
- 2026-09-30: claim audit: not owed — internal tier
- 2026-09-30: implement done, status set to review.
- 2026-09-30: plan gate chose a `nested_tune_grid()` pass in every refusal block over one block per refusal message. The per-message set is a recalled list. Falsified by a refusal in the file that `nested_tune_grid()` meets with a different, earlier message.
- 2026-09-30: plan gate chose planted-defect runs in AC1 and AC2 over passing tests alone. A new test is shown able to fail before it is trusted. Falsified by evidence that the planted edits are not defects a real change to `R/checks.R` can make.
- 2026-10-01: review fixes O1 to O4 and B4 landed in the test file, and B2, B3 and O6 went to a candidate row.
- 2026-10-01: step-7 approval: m137-split-check-tests approved for merge

## Decisions

## Review

Evidence from 2026-09-30 on `1013cfb7`. The branch is level with `origin/main` at `db12d415`. The planted runs used `git archive` copies outside the repo, so `R/` in the checkout stayed equal to main.

- AC1: on the unedited copy, the block "an inner index outside the frame is refused as a leak" passed. It made 42 expectations, 6 for each of the seven plants. With `held()` changed to set `out[!inside] <- TRUE`, the block failed. `check_nested()` did not throw `nestedtune_bad_design` on the first plant (`in_id` 0). All other blocks in the file passed in both runs.
- AC2: on the unedited copy, the block "a held shared row is refused when the outer in_id holds an NA" passed with 6 expectations. The plant was an early `return(integer())` in `fold_overlap_rows()` for an outer `in_id` that holds NA. With that plant, the block failed, because `check_nested()` did not throw `nestedtune_bad_design`. No other block failed.
- AC3: a parse of the test file found three helpers whose bodies hold `nestedtune_bad_design`. They are `expect_grid_refuses()`, `expect_not_list()` and `expect_contained()`. It found 13 `test_that()` blocks that hold the string or call one of the three. The 3 blocks that call `nested_resamples()` assert the call name `"nested_resamples"` at each call. The 10 blocks that call `check_nested()` reach `expect_grid_refuses()`, directly or through `expect_contained()`. That helper asserts the class, the same `one_line()` message and the call name `"nested_tune_grid"`. No block lacked its assertion.
- AC1, added after the review: a probe ran each of the seven plants through `check_nested()` alone. On the unedited copy, all seven were refused. With the `held()` plant, all seven were accepted.
- AC4: `devtools::test()` on `1013cfb7` printed no failure or error in any file. `devtools::check()` on `1013cfb7` gave 0 errors, 0 warnings and 0 notes, in 10 minutes.

Consistency gate, 2026-09-30 on `1013cfb7`:

- `cairn_validate.py` passed, with 18 advisory warnings on reference staleness and none on this milestone.
- No principle text changed, so `cairn_impact.py` was not owed.
- `devtools::document()` on a copy gave no diff in `man/` or `NAMESPACE`.
- `pkgdown::check_pkgdown()` found no problems.
- README and NEWS were not owed, because the branch touches no file outside `tests/` and `cairn/`.
- `devtools::check()` is the AC4 line.
- All six gating prose sweeps exited 0.
- `air format --check` on the test file was clean.

Findings from three fresh reviewers. O is the Opus diff reviewer, B the blame-history reviewer, and P the prior-review reviewer. Each finding has the disposition recommended at the gate.

- O1: the first `expect_error()` in the seven-plant loop (test-split-checks.R:315) has no `info`, so a failure does not name the plant. Fix now.
- O2: the `expect_error()` in `expect_grid_refuses()` has no `info`, so a grid call that does not refuse cannot be traced to its loop iteration. Fix now.
- O3: `expect_grid_refuses()` checks the grid refusal's class by inheritance, not by comparing the two class vectors. Fix now.
- O4: the new call-name lines at test-split-checks.R:102 and 121 omit `info = type`, while the lines around them pass it. Fix now.
- B4: the NA outer `in_id` test does not assert that the containment message is absent, as `expect_contained()` does for its rule. Fix now.
- B2, B3, O6: with an NA in both the outer and an inner `in_id`, `check_nested()` accepts the design. `held()` reads NA through `%in%`, which matches the outer NA. A probe on 2026-09-30 showed it. The analysis-frame branch of `fold_overlap_rows()` also has no NA test. This code predates the branch. Follow-up candidate row.
- O5, B7, P4: `expect_grid_refuses()` builds a recipes workflow with no skip. Reject: tune imports recipes (LESSONS, M101), and the hard-dependency CI leg runs the helper before merge.
- B1: the NA `in_id` plant fixes the containment message as the answer, where DESIGN.md Known issues leaves some index shapes to rsample. Reject: AC1 asks for this plant, and that entry covers a non-numeric `in_id`, not an NA.
- B5: the helper duplicates the `det_workflow()` fixture. Reject: `det_workflow()` needs `x1` to `x4`, and `shape_data()` has only `x`.
- B6: the helper reads the call with `rlang::call_name()`, where two other files compare `conditionCall(cnd)[[1L]]`. Reject: the two checks are equivalent.
- B8: AC boxes were unticked at review, and plan-gate lines sit below implement lines in the work log. Reject: review ticks the boxes, and the work log is append-only.
- P1: the T1 work log showed only the first plant failing under the `held()` plant. Resolved by the AC1 probe line above, with no change to the branch.
- P2: the bullet assertion matches a prefix of the bullet, not the whole bullet. Reject: the headline is matched whole, and the prefix names the slot and value up to its comma.
- P3: the NA test does not reach the construction path in `nested_resamples()`. Reject: `test-design-support.R:1615` covers that path, and AC2 names `check_nested()`.

Gate, 2026-10-01: the user took the recommended dispositions. O1 to O4 and B4 were fixed in the test file. B2, B3 and O6 became a ROADMAP candidate row. The other findings were rejected with the reasons above. After the fixes, the test file passed with 180 expectations, and `air format --check` was clean. With the AC1 and AC2 plants, each planted copy failed only its own block. The full suite was not run again locally, and CI on the PR runs it.
