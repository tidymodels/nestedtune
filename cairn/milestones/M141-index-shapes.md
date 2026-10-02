# M141: Refuse a split index that is not a row number, and an empty assessment set

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP3, IP4
- **Resolves:** —
- **Surface tier:** user-facing — it changes which designs the exported drivers and `nested_resamples()` refuse
- **Branch/PR:** m141-index-shapes

## Goal

The entry check and `nested_resamples()` refuse two split shapes: an index slot that is not numeric or holds a value outside integer range, and an empty `out_id`.

## Scope

**In:** one rule over the four index slots, which are the outer and inner `in_id` and `out_id`. It extends the `NA` rule of M138 (`check_na_indices()`, `R/checks.R:1292`, and `check_outer_na()`) and runs where that rule runs. If `is.numeric()` is FALSE for a slot, the rule refuses the slot. If a slot holds a value for which `is.na(suppressWarnings(as.integer(value)))` is TRUE, the rule refuses it too. If an `out_id` is `NULL` or has length 0, the rule refuses it as well. The one exemption is an `out_id` identical to the logical `NA`, rsample's mark for the complement. One refusal names every position that breaks the rule. It names each slot once, by the first shape in this order: an `NA`, an empty `out_id`, a non-numeric vector, a value outside integer range. The milestone also covers the docs, NEWS, D-114, and the DESIGN.md Known issues entry on index shapes. It absorbs the ROADMAP candidate on the three split-index shapes from M138's review. The plan commit removes that row.

Probes on 2026-10-01 at `3a90e655` showed the defects. A value of `3e9` in any slot passes `check_nested()` with a base warning, and the fold then fails inside rsample. In both an outer and an inner `in_id`, the containment rule matches the two `NA` values that `as.integer()` gives and passes the split. A character index that reads as row numbers passes, and the fold fails in vctrs. A `NULL` or `integer(0)` outer `out_id` passes, and its fold fails. A `NULL` inner `out_id` under `nested_tune_grid()` is dropped without a note: the fold's `.inner_metrics` shows `n = 1` for a two-split inner design.

**Out:** these shapes stay in the Known issues entry on index shapes. They are a fractional index and an empty inner `in_id`. They also include an outer `in_id` past the frame within integer range, and an outer `$data` that is no data frame. The fixture `break_inner_split()` relies on the empty inner `in_id`. A logical `NA` `out_id` whose complement is empty also goes to that entry. rsample builds it only for a split that holds every row, and the plan gate chose not to compute complements at the entry check.

## Acceptance criteria

- [ ] AC1: If an index slot holds a value outside integer range, `check_nested()` refuses the design with class `nestedtune_bad_design`. Such a value sits in a slot for which `is.numeric()` is TRUE. It is not `NA`, and `is.na(suppressWarnings(as.integer(value)))` is TRUE for it. The tests plant each of `3e9`, `-3e9` and `Inf` beside real indices in each of the four slots. They do this on a `nested_resamples()` design and on an `rsample::nested_cv()` design. An `out_id` stored as the logical `NA` is made explicit first. Each plant goes through `nested_tune_grid()` with `expect_grid_refuses()`. Then `expect_match()` asserts that the message is this rule's refusal and names the planted position and slot.
- [ ] AC2: If an index slot is a vector for which `is.numeric()` is FALSE, `check_nested()` refuses the design with class `nestedtune_bad_design`. The one exemption is an `out_id` identical to the logical `NA`. The tests plant four forms in each of the four slots, on a `nested_resamples()` design and on an `rsample::nested_cv()` design. The forms are the real indices as character, as a factor, and as a list, and a logical vector of `TRUE` values. An `out_id` stored as the logical `NA` is made explicit first. The assertions are those of AC1.
- [ ] AC3: If an outer or inner `out_id` is `NULL` or has length 0, `check_nested()` refuses the design with class `nestedtune_bad_design`. The tests plant each form in the outer `out_id` and in an inner `out_id`, on a `nested_resamples()` design and on an `rsample::nested_cv()` design. The assertions are those of AC1.
- [ ] AC4: If a split of an `outside` design breaks the AC1, AC2 or AC3 rule, `nested_resamples()` refuses the design with class `nestedtune_bad_design`. The tests plant `3e9`, the character form and the list form in each slot of an `outside` split. An `out_id` stored as the logical `NA` is made explicit first. They also plant a `NULL` and an `integer(0)` `out_id`. They assert the class, and that the message names the split's row in `outside` and the slot.
- [ ] AC5: One refusal names every position that breaks the `NA` rule or the AC1, AC2 or AC3 rule, and names no other position. It names each slot once, by the first shape in this order: an `NA`, an empty `out_id`, a non-numeric vector, a value outside integer range. A test on a `nested_resamples()` design plants four shapes. Fold 1 gets an `NA` in an outer slot, and fold 2 gets `3e9` in an inner `in_id`. Fold 3 gets an empty inner `out_id` and the character form in its outer `in_id`. The other splits stay clean. The test asserts that the message names exactly the four planted positions, each with its shape. A second test plants an `NA` in one row of `outside` and the list form in another, and asserts the same for `nested_resamples()`. M138's tests of a lone logical `NA` `in_id` and a `c(NA, NA)` `out_id` still pass, so each slot is named as holding an `NA`.
- [ ] AC6: `check_nested()` runs the rule before its shared-rows and containment rules, and the refusal raises no warning. Two tests use a `nested_resamples()` design with `3e9` alone in an inner `in_id`, and then the character `"a"` alone there. Without the rule, the containment rule refuses each with a base coercion warning. Each test asserts this rule's refusal, that the containment message is absent, and that no warning is raised. `check_nested()` accepts a valid `nested_resamples()` design and a valid `rsample::nested_cv()` design. In each, every `in_id` is stored as a double, and so is every `out_id` other than the logical `NA`.
- [ ] AC7: `NEWS.md`, `?nested_resamples` and the design paragraph of `?nested_tune_grid` state the rule and the logical `NA` exemption. The Known issues entry on index shapes lists no shape that AC1 to AC4 refuse. `devtools::test()` reports 0 failures. `devtools::check()` reports 0 errors, 0 warnings and 0 notes.

## Coverage

- AC1 → T1, T2, T5
- AC2 → T1, T2, T5
- AC3 → T1, T2, T5
- AC4 → T3, T5
- AC5 → T1, T2, T3
- AC6 → T1, T2, T5
- AC7 → T4, T5

## Tasks

- [ ] T1: Write the `check_nested()` tests first in `tests/testthat/test-split-checks.R`, next to M138's `NA` blocks (`:458` to `:572`). Loop the AC1, AC2 and AC3 plants over slot, frame kind and form, and add the AC5 and AC6 tests. Run the file and see the new blocks fail.
- [ ] T2: Widen `na_slots()` and `na_line()` in `R/checks.R` to the full rule, and rename them and `check_na_indices()` to fit it. Each line says what the slot holds: an `NA`, a value outside integer range, a non-numeric vector, or nothing. Call `as.integer()` under `suppressWarnings()`. Hand values to cli as values (LESSONS, M83). Update the comments in `check_inner_splits()` (`:1755` to `:1765`) on values beyond integer range, which the containment rule no longer meets. Move the block at `tests/testthat/test-split-checks.R:317`, which plants `1e10` in an inner `in_id` and expects the containment refusal, into the AC1 and AC6 tests. Update the `NA_REFUSED` header (`:398`) and the header asserted at `:586` to the new message. Run `devtools::test()`, and change any other test that planted a newly refused shape. The T1 tests then pass.
- [ ] T3: Run the same rule in `nested_resamples()` on `outside` (`R/nested-resamples.R:257`). Add the AC4 tests and the second AC5 test.
- [ ] T4: Update the docs. Restate the rule at `R/nested-tune-grid.R:118` and `R/nested-resamples.R:89`, and run `devtools::document()`. Add a NEWS bullet. In DESIGN.md Known issues, edit the entry "Index-slot shapes `check_inner_splits()` leaves to rsample". Remove its non-numeric clause and its sentence on the three open shapes. Add the empty-complement shape, and mark the entry `corrected M141`.
- [ ] T5: Do the planted-defect runs. Stub the rule's call in `check_nested()`, and see the AC1, AC2, AC3, AC5 and AC6 tests fail. Stub its call in `nested_resamples()`, and see the AC4 tests fail. Restore both calls. Run `devtools::test()`, `devtools::check()`, both prose sweeps, and `air format --check .`.

## Work log

- 2026-10-01: created by /milestone-plan. The criteria audit ran in full mode with one fresh Opus reader, twice. The first read returned 11 findings, and the plan took all 11. The gate then changed the rule, and the re-read returned 7 findings. They were a slot named twice, M138's `NA` tests, and the range clause on a non-numeric slot. They were also the double control, the explicit `out_id`, the mixed plant, and the `1e10` test block. The plan took all 7.
- 2026-10-01: plan gate chose a type rule (`is.numeric()`) plus a range rule over a range rule alone. A character index that reads as row numbers passes the range rule and then fails the fold in vctrs. Falsified by a real design whose index slot is not numeric and runs.
- 2026-10-01: plan gate chose refusing a `NULL` or length-0 `out_id` over computing each logical `NA` `out_id`'s complement too. rsample builds an empty complement only for a split that holds every row. Falsified by a design that reaches a driver with an empty complement.
- 2026-10-01: plan chose one refusal over all four shapes over a separate refusal per shape, so a user sees every bad position at once. Falsified by a shape whose reason a shared message misstates.

## Decisions

## Review
