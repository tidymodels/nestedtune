# M138: Refuse an NA in a split's row indices

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP3, IP1
- **Resolves:** —
- **Surface tier:** user-facing — it changes which designs the exported drivers and `nested_resamples()` refuse
- **Branch/PR:** m138-na-split-indices

## Goal

The entry check and `nested_resamples()` refuse a design whose split indices hold an `NA`, and the message names each position.

## Scope

**In:** one rule over the four index slots, which are the outer and inner `in_id` and `out_id`. `check_nested()` runs it before the shared-rows and containment rules. `nested_resamples()` runs its outer half on `outside`. Only an `out_id` identical to the logical `NA` is exempt, because rsample reads that value as the complement. The milestone also covers the docs, NEWS, D-111, and the DESIGN.md Known issues entry on index shapes. It absorbs the ROADMAP candidate on an `NA` in both an outer and an inner `in_id` (M137 review B2, B3, O6). The plan commit removes that row.

A probe on 2026-10-01 showed the defect. An `NA` in an outer `in_id` passes `check_nested()`. The fold then fails with rsample's "only 0's may be mixed with negative subscripts", and `print()` of the results errors. `rsample::make_splits()` refuses an `NA` in the analysis indices.

**Out:** the other shapes in that Known issues entry stay there. They are a non-numeric or fractional index, an empty inner `in_id`, and a non-data.frame outer `$data`. A second defect is also out. If an outer `in_id` repeats a row, a whole-frame inner split with a logical `NA` `out_id` is scored on outer held-out rows. That defect is a `[high]` candidate row, and `/hotfix` is its door.

## Acceptance criteria

- [ ] AC1: The four index slots are the outer `in_id`, the outer `out_id`, the inner `in_id` and the inner `out_id`. If a slot holds a value for which `is.na()` is TRUE, `check_nested()` refuses the design with class `nestedtune_bad_design`. The one exemption is an `out_id` identical to the logical `NA`, rsample's mark for the complement. The tests plant these values on a `nested_resamples()` design. Each of the four slots gets an `NA` beside real indices. An `out_id` stored as the logical `NA` is made explicit first. Each `in_id` slot gets a lone logical `NA`. Each `out_id` slot gets `NA_integer_` and `c(NA, NA)`. On an `rsample::nested_cv()` design, the tests plant an `NA` in the outer `in_id` and in an inner `in_id`. Each plant goes through `nested_tune_grid()` with `expect_grid_refuses()`. Then `expect_match()` asserts that the message is the `NA` refusal and names the planted position and slot.
- [ ] AC2: The refusal names each position that holds an `NA`. A position is the outer fold, then either the outer slot (`in_id` or `out_id`) or the inner split number and its slot. A test plants an `NA` in an outer slot of one fold and in an inner slot of another fold. It asserts that the message names both positions and both slots. A second plant puts an `NA` in both the `in_id` and the `out_id` of one inner split. The test asserts that the message names both slots.
- [ ] AC3: `check_nested()` runs the `NA` rule before its shared-rows and containment rules. Tests show this on two designs. The first has an `NA` in an inner `in_id` of fold 1 of a `nested_resamples()` design. Without the `NA` rule, the containment rule refuses it. The second has an `NA` in fold 1 and a shared row in the outer split of fold 2. Without the `NA` rule, `check_outer_overlap()` refuses it. Each design gets the `NA` refusal. The test asserts that the containment or shared-rows message is absent.
- [ ] AC4: If a split of an `outside` design holds an `NA` in its `in_id`, `nested_resamples()` refuses the design with class `nestedtune_bad_design`. If the split's `out_id` holds an `NA` and is not the logical `NA`, it refuses the design too. The tests plant an `NA` beside real indices in an outside `in_id`. They plant an `NA` beside real indices, `NA_integer_` and `c(NA, NA)` as an outside `out_id`. They assert the class, and that the message names the split and the slot.
- [ ] AC5: `check_nested()` accepts a `nested_resamples()` design and an `rsample::nested_cv()` design, each built from `rsample::vfold_cv()` in both loops. Each of these designs holds logical `NA` `out_id` values. A test asserts that both designs pass.
- [ ] AC6: `NEWS.md`, `?nested_resamples` and the design paragraph of `?nested_tune_grid` state the refusals. The Rd files are regenerated from `R/nested-tune-grid.R` and `R/nested-resamples.R`. `devtools::test()` reports 0 failures. `devtools::check()` reports 0 errors, 0 warnings and 0 notes.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T1, T2, T5
- AC4 → T3, T5
- AC5 → T1, T2
- AC6 → T4, T5

## Tasks

- [x] T1: Write the `check_nested()` tests first in `tests/testthat/test-split-checks.R`. Add the AC1, AC2 and AC3 plants and the AC5 designs. Assert that each AC5 design holds a logical `NA` `out_id`, so the test exercises the exemption. Remove the `NA` from the containment block's `in_id` plants (`test-split-checks.R:316`). Turn the block at `:374` into the AC3 fold-2 test. That block is the held-shared-row test with an `NA` in the outer `in_id`. Run the file and see the new blocks fail.
- [x] T2: Add the rule to `R/checks.R`. It reads `splits` and the `splits` of each `inner_resamples` element. It skips an element that is not a list with the `rsplit` class, because the class rules refuse that element later. Call the rule in `check_nested()` before `check_outer_overlap()`. Use the class `nestedtune_bad_design`, and write bullets in the style of the other rules. Pass values to cli as values (LESSONS, M83). If the `NA` path of `held()` in `check_inner_splits()` can no longer be reached, update its comment. The T1 tests then pass.
- [x] T3: In `nested_resamples()`, run the outer half of the rule on `outside` after `check_outer_splits()` (`R/nested-resamples.R:241`). Add the AC4 tests. The test at `tests/testthat/test-design-support.R:1615` expects such a design to build. Change it to expect the refusal.
- [x] T4: Update the docs. At `R/nested-tune-grid.R:116`, replace the phrase "any non-`NA` `out_id`" with a statement of the rule. Add a sentence to `?nested_resamples`. Run `devtools::document()`. Add a NEWS bullet. In DESIGN.md Known issues, find the entry "Index-slot shapes `check_inner_splits()` leaves to rsample". Remove its clause on an element-wise `NA` in `out_id`, and mark the entry `corrected M138`.
- [ ] T5: Do the planted-defect runs. Remove the rule's call from `check_nested()`, and see the AC1, AC2 and AC3 tests fail. Remove the call from `nested_resamples()`, and see the AC4 tests fail. Restore both calls. Then run `devtools::test()` and `devtools::check()`. Run `air format --check` on the touched files.

## Work log

- 2026-10-01: created by /milestone-plan. The criteria audit ran in full mode with two fresh Opus readers. The first returned 13 findings, and the plan fixed all of them in the wording but one. That one claimed an IP1 leak, and a probe showed that the normal path re-points the split at the analysis frame. The second reader returned 4 wording fixes and 2 optional ones, and the plan took all six.
- 2026-10-01: plan gate chose refusing an `NA` in all four slots over a fix to `held()` alone. An outer-only `NA` still fails at run time and breaks `print()`. Falsified by a real design that needs an `NA` index to run.
- 2026-10-01: plan gate chose exempting only the logical `NA` `out_id` over any all-`NA` `out_id`. rsample reads `NA_integer_` and `c(NA, NA)` as indices that give rows of NAs. Falsified by an rsample release that reads any all-`NA` `out_id` as the complement.
- 2026-10-01: plan gate chose a refusal in `nested_resamples()` too over a candidate row, because the constructor otherwise builds a design that every driver refuses (GP3). Falsified by a user who builds such a design on purpose and repairs it before a driver runs.
- 2026-10-01: implement started on branch `m138-na-split-indices`. The question gate was skipped, because the plan left nothing open.
- 2026-10-01: T1 and T2 done. The new blocks failed first with the containment and shared-rows refusals. `check_na_indices()` now runs after `check_outer_splits()`, and the AC3 test mocks it away to show the later refusals. A `nested_resamples()` design stores explicit inner `out_id` values, so the AC5 test reads the logical `NA` from the outer splits there. `devtools::test()` reports 0 failures.
- 2026-10-01: checkpoint, T3 and T4 written but not yet checked off. `check_outer_na()` runs in `nested_resamples()`. The AC4 tests and the changed `test-design-support.R` test pass. Docs and NEWS are updated, and `devtools::document()` and both prose sweeps are clean. The full `devtools::test()` run for these two tasks is still going.
- 2026-10-01: T3 and T4 done. The full `devtools::test()` run reports 0 failures. The NEWS bullet names the nested tuning functions and `nested_fit_resamples()`, because `check_nested()` is not exported. The docs and the error say that the logical `NA` `out_id` tells rsample to use `rsample::complement()`. Rolling-origin and sliding splits have their own complement methods.
- 2026-10-01: checkpoint during T5. The planted-defect runs passed their test: stubbing `check_na_indices()` failed the AC1, AC2 and AC3 blocks, and stubbing `check_outer_na()` failed the AC4 block. Without the rule, the plants were accepted. The claim-audit corrections are applied, and the reader's re-read and `devtools::check()` are still running.
- claim audit: 33 claims read, 3 corrected — R/checks.R, tests/testthat/test-split-checks.R
- 2026-10-01: the re-read cleared two corrections. It found the `check_inner_splits()` comment still imprecise for `out_id`, so I took its wording. It also found that an inner `out_id` index beyond integer range passes every rule. That shape went into the DESIGN.md Known issues entry on index slots, because a candidate row would put ROADMAP.md at its 60-line cap.

## Decisions

## Review
