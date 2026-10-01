# M138: Refuse an NA in a split's row indices

- **Status:** review
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

- [x] AC1: The four index slots are the outer `in_id`, the outer `out_id`, the inner `in_id` and the inner `out_id`. If a slot holds a value for which `is.na()` is TRUE, `check_nested()` refuses the design with class `nestedtune_bad_design`. The one exemption is an `out_id` identical to the logical `NA`, rsample's mark for the complement. The tests plant these values on a `nested_resamples()` design. Each of the four slots gets an `NA` beside real indices. An `out_id` stored as the logical `NA` is made explicit first. Each `in_id` slot gets a lone logical `NA`. Each `out_id` slot gets `NA_integer_` and `c(NA, NA)`. On an `rsample::nested_cv()` design, the tests plant an `NA` in the outer `in_id` and in an inner `in_id`. Each plant goes through `nested_tune_grid()` with `expect_grid_refuses()`. Then `expect_match()` asserts that the message is the `NA` refusal and names the planted position and slot.
- [x] AC2: The refusal names each position that holds an `NA`. A position is the outer fold, then either the outer slot (`in_id` or `out_id`) or the inner split number and its slot. A test plants an `NA` in an outer slot of one fold and in an inner slot of another fold. It asserts that the message names both positions and both slots. A second plant puts an `NA` in both the `in_id` and the `out_id` of one inner split. The test asserts that the message names both slots.
- [x] AC3: `check_nested()` runs the `NA` rule before its shared-rows and containment rules. Tests show this on two designs. The first has an `NA` in an inner `in_id` of fold 1 of a `nested_resamples()` design. Without the `NA` rule, the containment rule refuses it. The second has an `NA` in fold 1 and a shared row in the outer split of fold 2. Without the `NA` rule, `check_outer_overlap()` refuses it. Each design gets the `NA` refusal. The test asserts that the containment or shared-rows message is absent.
- [x] AC4: If a split of an `outside` design holds an `NA` in its `in_id`, `nested_resamples()` refuses the design with class `nestedtune_bad_design`. If the split's `out_id` holds an `NA` and is not the logical `NA`, it refuses the design too. The tests plant an `NA` beside real indices in an outside `in_id`. They plant an `NA` beside real indices, `NA_integer_` and `c(NA, NA)` as an outside `out_id`. They assert the class, and that the message names the split and the slot.
- [x] AC5: `check_nested()` accepts a `nested_resamples()` design and an `rsample::nested_cv()` design, each built from `rsample::vfold_cv()` in both loops. Each of these designs holds logical `NA` `out_id` values. A test asserts that both designs pass.
- [x] AC6: `NEWS.md`, `?nested_resamples` and the design paragraph of `?nested_tune_grid` state the refusals. The Rd files are regenerated from `R/nested-tune-grid.R` and `R/nested-resamples.R`. `devtools::test()` reports 0 failures. `devtools::check()` reports 0 errors, 0 warnings and 0 notes.

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
- [x] T5: Do the planted-defect runs. Remove the rule's call from `check_nested()`, and see the AC1, AC2 and AC3 tests fail. Remove the call from `nested_resamples()`, and see the AC4 tests fail. Restore both calls. Then run `devtools::test()` and `devtools::check()`. Run `air format --check` on the touched files.

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
- 2026-10-01: the re-read cleared two corrections. It found the `check_inner_splits()` comment still imprecise for `out_id`, so I took its wording. It also found that an inner `out_id` index beyond integer range passes every rule. That shape went into the DESIGN.md Known issues entry on index slots, because a candidate row puts ROADMAP.md at its 60-line cap.
- 2026-10-01: T5 done. The planted-defect runs passed their test. `devtools::check()` reports 0 errors, 0 warnings and 0 notes. It ran before the claim-audit fixes, which changed only comments and the error's reason text. On the final code, the split-check file passes, `devtools::document()` leaves no diff, `air format --check` and both prose sweeps are clean, and `cairn_validate` passes. Status set to review.
- 2026-10-01: review found no failing criterion. Three reviewers gave 19 findings. The gate took the fix-now set, which changes two comments, five tests and DESIGN.md, and changes no package behavior.
- step-7 approval: m138-na-split-indices approved for merge

## Decisions

## Review

Fresh evidence on 2026-10-01 at `3b2c2e25`, the branch already holding `origin/main`. The full `devtools::test()` run reports 0 failures and 0 skips. `test-split-checks.R` and `test-design-support.R` both ran.

- AC1: the block "check_nested() refuses an NA in each slot of a nested_resamples() design" plants all five `NA_PLANTS` in fold 2. Each goes in the outer split and in inner split 2. Each slot gets an `NA` beside real indices, after `explicit_out()`. Each `in_id` gets a lone logical `NA`. Each `out_id` gets `NA_integer_` and `c(NA, NA)`. The `nested_cv()` block plants an `NA` in the outer and in an inner `in_id`. `expect_na_refused()` asserts the class, matches the refusal heading and the position-and-slot bullet, and runs `expect_grid_refuses()`. Both pass. In a scratch copy with the `check_na_indices()` call removed, both blocks fail.
- AC2: the block "the NA refusal names every position and slot that holds one" has two plants. The first puts an `NA` in the outer `in_id` of fold 1 and in the `out_id` of inner split 2 of fold 3. The block asserts both bullets. The second plant puts an `NA` in both slots of inner split 1 of fold 2. The block asserts the bullet "in_id and out_id hold an `NA`". The block passes, and it fails in the scratch copy without the rule.
- AC3: the block "the NA rule runs before the containment and shared-rows rules" builds two designs. The first has an `NA` in the `in_id` of inner split 1 of fold 1. The second has an `NA` in the outer `in_id` of fold 1 and a shared row in the outer split of fold 2. Each gets the `NA` refusal, and the block asserts that the containment or shared-rows message is absent. With `check_na_indices()` mocked away, the first design gets the containment refusal. The second gets the shared-rows refusal on "Row 2 of `resamples`". The block passes, and it fails in the scratch copy without the rule.
- AC4: the block "nested_resamples() refuses an NA in an outside split" plants an `NA` beside real indices in an outside `in_id`. It also plants an `NA` beside real indices, `NA_integer_` and `c(NA, NA)` as an outside `out_id`. It asserts the class, the heading, the bullet "Row 2 of `outside`: <slot> holds an `NA`." and the call `nested_resamples`. The changed test in `test-design-support.R` expects the same refusal. Both pass. In a scratch copy with the `check_outer_na()` call removed, both fail. The design-support file needs `NOT_CRAN=true` to run.
- AC5: the block "check_nested() accepts the logical NA out_id of both constructors" builds `whole_design()` and `split_design()`. Each uses `rsample::vfold_cv()` in both loops. It asserts that each outer `out_id` is the logical `NA`, and that each inner `out_id` of the `nested_cv()` design is too. It asserts that `check_nested()` returns each design unchanged. The block passes.
- AC6: `NEWS.md` has a bullet on the refusal. `?nested_resamples` has a paragraph on it, and the design paragraph of `?nested_tune_grid` states the rule. `devtools::document()` leaves no diff, so the Rd files match the roxygen in both R files. The full `devtools::test()` run reports 0 failures. `devtools::check()` on `3b2c2e25` reports 0 errors, 0 warnings and 0 notes, in 19 minutes. This run is on the final code, which the work log's earlier run was not.

Consistency gate. `cairn_validate` passes, with 18 advisory reference-staleness warnings. No principle text changed, so `cairn_impact` was skipped. `devtools::document()` leaves no diff. README.Rmd is untouched. `pkgdown::check_pkgdown()` finds no problems. `NEWS.md` has the entry, with no milestone number. No new top-level file. `devtools::check()` is clean, as above. The six gating prose sweeps are clean. `air format --check` on the five touched R files is clean.

Findings from three fresh reviewers, ranked within each lens. D is the diff-bug lens, H the blame-history lens, P the prior-review lens. None shows a criterion failing.

- D1: an index beyond integer range in both an outer and an inner `in_id` passes every rule, because both coerce to `NA` and `%in%` matches them. The new comment in `check_inner_splits()` says `held()` counts such an `NA` as not held. A probe showed that the shape passes on `main` and on the branch, so the shape predates M138, but the comment is wrong.
- D2: the work log's `devtools::check()` predates the claim-audit fixes. The fresh run above answers it.
- D3: `expect_na_refused()` asserts the expected bullets but not that no other position is named.
- D4: the DESIGN.md Known issues entry now implies that M59 accepted the new beyond-integer shape, and it still cites the removed clause's finding.
- D5: the AC4 loop leaves out the lone-`NA` `in_id` plant with no reason given. A probe shows it is refused.
- D6: the entry check names "Outer fold f" in the `NA` rule and "Row f of `resamples`" in the shared-rows rule.
- D7: the `NA` rule runs before the column-class rules, so a design with both faults shows the `NA` refusal first.
- D8: a `NULL` `out_id` passes every rule, and rsample gives an empty assessment set. It is not an `NA`, and Known issues does not list it.
- D9: the DESIGN.md Conventions bullet on refused schemes does not name the D-111 refusal.
- D10: the reason line writes "NA" as plain text, and the heading formats it as code.
- H1: the containment block lost its `NA` `in_id` plant, and nothing now plants a beyond-integer index to reach the `NA` path of `held()`.
- H2: the removed held-shared-row test had an `NA` outer `in_id`. No test now reaches that filter with a coerced `NA`.
- H3: the same Known issues wording as D4.
- H4: the comment at `R/checks.R:1746` still says an `NA` `out_id` is the complement. Only the logical `NA` is.
- H5: `?nested_tune_grid` says no `out_id` holds an `NA`, but a beyond-integer `out_id` index coerces to one and passes.
- P1: the change reverses M134 S1's and M137's choice to leave an outer `NA` to later checks. D-111 records the reversal.
- P2: the shape M137 B2, B3 and O6 named, an `NA` in the outer and inner `in_id` of one fold, has no plant of its own.
- P3: one new loop in the AC5 block has no `info` label, which M137 O1 asked for.
- P4: the same shape as D1.

Triage at the gate, 2026-10-01. The maintainer took every recommended disposition.

- Fixed on the branch: D1's comment and H4, both in `check_inner_splits()`. D3, as a count of named positions in `expect_na_refused()`, shown to fail with 2 named against 1 expected. D5, P3, H1 as a `1e10` `in_id` plant, and P2 as its own block. D4 and H3, as a rewrite of the Known issues entry that keeps O7 out of the accepted list. D9, as a sentence in the Conventions bullet. After the fixes, `test-split-checks.R` passes 20 blocks and `test-design-support.R` passes 74, with no warning and no skip. `air format --check`, the plain sweep and `cairn_validate` are clean.
- Deferred to the Known issues entry, as open shapes: D1's shape and P4, D8, H2 and H5. ROADMAP.md has 59 of its 60 lines, so a candidate row was not used.
- Rejected: D2, which the fresh `devtools::check()` run answers. D6, because AC2 sets the entry check's wording and the constructor matches `check_outer_overlap()`. D7, because the plan set the rule's place in `check_nested()`. D10, because cli does not format text passed as a value. P1, because D-111 records the reversal.
