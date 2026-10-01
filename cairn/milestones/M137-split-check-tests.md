# M137: Test the split-check gaps M135's review left

- **Status:** in-progress
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

- [ ] AC1: `tests/testthat/test-split-checks.R` has a test on a `nested_resamples()` design. The inner splits of that design index the outer frame. The test plants each of `0`, `-1`, `NA` and the frame's row count plus one in an inner split's `in_id`. It plants each of `0`, `-1` and the row count plus one in that split's `out_id`. For each of the seven plants, it asserts that `check_nested()` refuses with class `nestedtune_bad_design`. It also asserts the containment message, naming the planted value in that slot. When `held()` in `check_inner_splits()` (`R/checks.R`) is edited to answer `TRUE` for every index outside the frame, the test fails.
- [ ] AC2: `tests/testthat/test-split-checks.R` has a test on a `nested_resamples()` design whose first outer `in_id` holds an `NA`. The first inner split of that fold holds a row of that outer `in_id` in both its analysis and assessment sets. The test asserts that `check_nested()` refuses with class `nestedtune_bad_design`. It also asserts the inner shared-rows message, naming element 1, split 1. When `fold_overlap_rows()` (`R/checks.R`) is edited to return no rows for a fold whose outer `in_id` holds an `NA`, the test fails.
- [ ] AC3: A search of `tests/testthat/test-split-checks.R` for `nestedtune_bad_design` finds two kinds of `test_that()` block: a block whose body holds that string, and a block that calls a helper whose body holds it. Every block of either kind asserts the condition's call. A block calling `nested_resamples()` asserts that `rlang::call_name(conditionCall(cnd))` is `"nested_resamples"`. A block calling `check_nested()` also passes the same design to `nested_tune_grid()`. It asserts that the refusal there has the same class and message, and the call name `"nested_tune_grid"`.
- [ ] AC4: `Rscript -e 'devtools::test()'` reports 0 failures. `Rscript -e 'devtools::check()'` reports 0 errors and 0 warnings.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T4

## Tasks

- [ ] T1: Add the index-plant test of AC1 to `tests/testthat/test-split-checks.R`, with `edit_whole_inner()`. Make the `out_id` plants on a split whose `out_id` is not `NA`. Plant the `held()` edit, see the test fail, revert the edit, and log one work-log line.
- [ ] T2: Add the NA outer `in_id` test of AC2 next to the M135 shared-rows tests. Plant the early return in `fold_overlap_rows()` and see the test fail on the containment message. Revert the edit and log one work-log line.
- [ ] T3: Add a test helper that passes a design to `nested_tune_grid()` with a small workflow on `shape_data()` and returns the refusal. Extend each block that AC3 names, the new blocks of T1 and T2 included. The hard-dependency CI leg can lack a package that the helper needs. In that case, guard the entry assertion with the skip helper the suite uses for that package (LESSONS, M101).
- [ ] T4: Run the full suite and `devtools::check()`. Before the review push, run `air format --check` on the touched file.

## Work log

- 2026-09-30: created by /milestone-plan from the candidate row "M135's review leftovers on split-check tests" (B1, P1, P3), which the plan commit removes.
- 2026-09-30: reduced criteria audit (fresh Opus reader) returned one finding. AC3's search missed blocks that refuse only through `expect_contained()` or `expect_not_list()`. AC3 now also covers blocks that call a helper holding the string. The reader said that T2's planted edit fails at `expect_error`. That note was not taken, because a probe showed that the NA outer `in_id` makes the containment rule refuse row 1.
- 2026-09-30: T1 added the seven-plant index test. With `held()` edited to answer `TRUE` outside the frame, `check_nested()` accepted the `in_id` 0 plant and the test failed at its `expect_error()`. Edit reverted, `R/checks.R` matches main.
- 2026-09-30: T2 added the NA outer `in_id` test, the NA appended to the outer `in_id`. With the early return planted in `fold_overlap_rows()`, `check_nested()` accepted the design and the test failed at its `expect_error()`, not on the containment message T2 expected. The plan-time reader's note was right for this placement. Edit reverted.
- 2026-09-30: checkpoint. T1 and T2 tests are committed and the full suite is still running, so neither task is ticked yet.
- 2026-09-30: plan gate chose a `nested_tune_grid()` pass in every refusal block over one block per refusal message. The per-message set is a recalled list. Falsified by a refusal in the file that `nested_tune_grid()` meets with a different, earlier message.
- 2026-09-30: plan gate chose planted-defect runs in AC1 and AC2 over passing tests alone. A new test is shown able to fail before it is trusted. Falsified by evidence that the planted edits are not defects a real change to `R/checks.R` can make.

## Decisions

## Review
