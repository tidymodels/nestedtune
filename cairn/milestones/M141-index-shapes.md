# M141: Refuse a split index that is not a row number, and an empty assessment set

- **Status:** review
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

- [x] AC1: If an index slot holds a value outside integer range, `check_nested()` refuses the design with class `nestedtune_bad_design`. Such a value sits in a slot for which `is.numeric()` is TRUE. It is not `NA`, and `is.na(suppressWarnings(as.integer(value)))` is TRUE for it. The tests plant each of `3e9`, `-3e9` and `Inf` beside real indices in each of the four slots. They do this on a `nested_resamples()` design and on an `rsample::nested_cv()` design. An `out_id` stored as the logical `NA` is made explicit first. Each plant goes through `nested_tune_grid()` with `expect_grid_refuses()`. Then `expect_match()` asserts that the message is this rule's refusal and names the planted position and slot.
- [x] AC2: If an index slot is a vector for which `is.numeric()` is FALSE, `check_nested()` refuses the design with class `nestedtune_bad_design`. The one exemption is an `out_id` identical to the logical `NA`. The tests plant four forms in each of the four slots, on a `nested_resamples()` design and on an `rsample::nested_cv()` design. The forms are the real indices as character, as a factor, and as a list, and a logical vector of `TRUE` values. An `out_id` stored as the logical `NA` is made explicit first. The assertions are those of AC1.
- [x] AC3: If an outer or inner `out_id` is `NULL` or has length 0, `check_nested()` refuses the design with class `nestedtune_bad_design`. The tests plant each form in the outer `out_id` and in an inner `out_id`, on a `nested_resamples()` design and on an `rsample::nested_cv()` design. The assertions are those of AC1.
- [x] AC4: If a split of an `outside` design breaks the AC1, AC2 or AC3 rule, `nested_resamples()` refuses the design with class `nestedtune_bad_design`. The tests plant `3e9`, the character form and the list form in each slot of an `outside` split. An `out_id` stored as the logical `NA` is made explicit first. They also plant a `NULL` and an `integer(0)` `out_id`. They assert the class, and that the message names the split's row in `outside` and the slot.
- [x] AC5: One refusal names every position that breaks the `NA` rule or the AC1, AC2 or AC3 rule, and names no other position. It names each slot once, by the first shape in this order: an `NA`, an empty `out_id`, a non-numeric vector, a value outside integer range. A test on a `nested_resamples()` design plants four shapes. Fold 1 gets an `NA` in an outer slot, and fold 2 gets `3e9` in an inner `in_id`. Fold 3 gets an empty inner `out_id` and the character form in its outer `in_id`. The other splits stay clean. The test asserts that the message names exactly the four planted positions, each with its shape. A second test plants an `NA` in one row of `outside` and the list form in another, and asserts the same for `nested_resamples()`. M138's tests of a lone logical `NA` `in_id` and a `c(NA, NA)` `out_id` still pass, so each slot is named as holding an `NA`.
- [x] AC6: `check_nested()` runs the rule before its shared-rows and containment rules, and the refusal raises no warning. Two tests use a `nested_resamples()` design with `3e9` alone in an inner `in_id`, and then the character `"a"` alone there. Without the rule, the containment rule refuses each with a base coercion warning. Each test asserts this rule's refusal, that the containment message is absent, and that no warning is raised. `check_nested()` accepts a valid `nested_resamples()` design and a valid `rsample::nested_cv()` design. In each, every `in_id` is stored as a double, and so is every `out_id` other than the logical `NA`.
- [x] AC7: `NEWS.md`, `?nested_resamples` and the design paragraph of `?nested_tune_grid` state the rule and the logical `NA` exemption. The Known issues entry on index shapes lists no shape that AC1 to AC4 refuse. `devtools::test()` reports 0 failures. `devtools::check()` reports 0 errors, 0 warnings and 0 notes.

## Coverage

- AC1 → T1, T2, T5
- AC2 → T1, T2, T5
- AC3 → T1, T2, T5
- AC4 → T3, T5
- AC5 → T1, T2, T3
- AC6 → T1, T2, T5
- AC7 → T4, T5

## Tasks

- [x] T1: Write the `check_nested()` tests first in `tests/testthat/test-split-checks.R`, next to M138's `NA` blocks (`:458` to `:572`). Loop the AC1, AC2 and AC3 plants over slot, frame kind and form, and add the AC5 and AC6 tests. Run the file and see the new blocks fail.
- [x] T2: Widen `na_slots()` and `na_line()` in `R/checks.R` to the full rule, and rename them and `check_na_indices()` to fit it. Each line says what the slot holds: an `NA`, a value outside integer range, a non-numeric vector, or nothing. Call `as.integer()` under `suppressWarnings()`. Hand values to cli as values (LESSONS, M83). Update the comments in `check_inner_splits()` (`:1755` to `:1765`) on values beyond integer range, which the containment rule no longer meets. Move the block at `tests/testthat/test-split-checks.R:317`, which plants `1e10` in an inner `in_id` and expects the containment refusal, into the AC1 and AC6 tests. Update the `NA_REFUSED` header (`:398`) and the header asserted at `:586` to the new message. Run `devtools::test()`, and change any other test that planted a newly refused shape. The T1 tests then pass.
- [x] T3: Run the same rule in `nested_resamples()` on `outside` (`R/nested-resamples.R:257`). Add the AC4 tests and the second AC5 test.
- [x] T4: Update the docs. Restate the rule at `R/nested-tune-grid.R:118` and `R/nested-resamples.R:89`, and run `devtools::document()`. Add a NEWS bullet. In DESIGN.md Known issues, edit the entry "Index-slot shapes `check_inner_splits()` leaves to rsample". Remove its non-numeric clause and its sentence on the three open shapes. Add the empty-complement shape, and mark the entry `corrected M141`.
- [x] T5: Do the planted-defect runs. Stub the rule's call in `check_nested()`, and see the AC1, AC2, AC3, AC5 and AC6 tests fail. Stub its call in `nested_resamples()`, and see the AC4 tests fail. Restore both calls. Run `devtools::test()`, `devtools::check()`, both prose sweeps, and `air format --check .`.

## Work log

- 2026-10-01: created by /milestone-plan. The criteria audit ran in full mode with one fresh Opus reader, twice. The first read returned 11 findings, and the plan took all 11. The gate then changed the rule, and the re-read returned 7 findings. They were a slot named twice, M138's `NA` tests, and the range clause on a non-numeric slot. They were also the double control, the explicit `out_id`, the mixed plant, and the `1e10` test block. The plan took all 7.
- 2026-10-01: plan gate chose a type rule (`is.numeric()`) plus a range rule over a range rule alone. A character index that reads as row numbers passes the range rule and then fails the fold in vctrs. Falsified by a real design whose index slot is not numeric and runs.
- 2026-10-01: plan gate chose refusing a `NULL` or length-0 `out_id` over computing each logical `NA` `out_id`'s complement too. rsample builds an empty complement only for a split that holds every row. Falsified by a design that reaches a driver with an empty complement.
- 2026-10-01: plan chose one refusal over all four shapes over a separate refusal per shape, so a user sees every bad position at once. Falsified by a shape whose reason a shared message misstates.

- 2026-10-01: checkpoint, half-done. T1 tests written and seen failing on the old code. T2 rule written (`check_split_indices()`, `check_outer_indices()`), with the `nested_resamples()` call renamed ahead of T3. `test-split-checks.R` passes, but the full suite has not finished, so T1 and T2 stay unticked. T4 docs, NEWS and DESIGN.md entry drafted. The NEWS item on the repeated-row fix loses "too large for an integer", a shape now refused at entry. Question gate skipped: nothing open.
- 2026-10-01: T1 and T2 done. The full suite failed only `test-sweep-prose.R`, on a 5-span sentence the T4 roxygen edit added mid-run. Split it, and all six sweeps and that file pass. `air format --check .` clean.
- 2026-10-01: T3 done. AC4 plant loop and the second AC5 test added, and `test-split-checks.R` passes. The `nested_resamples()` call itself landed with T2's rename.
- 2026-10-01: T4 done in the T1-T2 commits. Both help paragraphs, a NEWS bullet, and the Known issues entry, which also gains the outer `in_id` past the frame within integer range, so the entry lists every shape the plan's Out section keeps there.
- 2026-10-01: T5 planted runs. With the `check_nested()` call stubbed, the AC1, AC2, AC3, AC5 and AC6 refusal tests and M138's NA tests fail, and the doubles control passes. With the `nested_resamples()` call stubbed, the AC4 test, the second AC5 test and M138's outside test fail, the folds failing in vctrs with `vctrs_error_subscript_type`. Both calls restored. Full test and check running.
- 2026-10-01: claim audit delegated to a fresh Opus reader, running.
- claim audit: 33 claims read, 3 corrected — NEWS.md
- 2026-10-01: claim audit corrections applied. "below 1" became "negative", because an index of 0 is dropped by vctrs and the fold runs. The `3e9` "before" sentence now says that it passed in most slots, and that in an inner `in_id` it was refused as not held. "says what the slot holds" became "says how the slot breaks the rule". The reader also found that a fractional outer `in_id` stops `check_nested()` under `nested_cv()` with a raw vctrs error. That is out of scope and was added to the Known issues entry on index shapes.
- 2026-10-01: T5 done. `devtools::test()` gave 0 failures. `devtools::check()` gave 0 errors, 0 warnings and 0 notes. All six gating sweeps and `air format --check .` are clean. Status set to review.
- 2026-10-01: review checkpoint, half-done. AC1 to AC6 evidence recorded and ticked. `devtools::check()` for AC7 is running, and the gate and triage are still owed.
- 2026-10-01: review gate. 17 findings, none failing a criterion. The maintainer took fix 8, reject 7. The fixes are tests and tracking records only, and the split-check file and its planted run pass.
- step-7 approval: m141-index-shapes approved for merge

## Decisions

## Review

Fresh runs on 2026-10-01 at `01eb538b`. The branch is level with `origin/main`. `devtools::test()` gave 15441 passes, 0 failures, 0 errors and 0 skips. The planted runs stub the rule in memory and edit no file. A stub of `check_split_indices()` fails 8 blocks of `test-split-checks.R`: M138's five NA blocks and the three new index blocks. A stub of `check_outer_indices()` fails the 3 `outside` blocks. The doubles control passes under both stubs.

- AC1: the block "check_nested() refuses each index shape in each slot of both designs" plants `3e9`, `-3e9` and `Inf`. It plants each in the outer and an inner `in_id` and `out_id`, on a `nested_resamples()` and an `rsample::nested_cv()` design, with `out_id` made explicit first. `expect_index_refused()` asserts the class, the header, the planted bullet and the count of named positions. It also runs `expect_grid_refuses()`. The block passes, and it fails under the stub.
- AC2: the same block plants four forms in the same four slots of both designs. The forms are character, factor, list and all `TRUE`. The assertions are those of AC1. It passes, and it fails under the stub.
- AC3: the same block plants `NULL` and `integer(0)` in the outer and an inner `out_id` of both designs. The assertions are those of AC1. It passes, and it fails under the stub.
- AC4: the block "nested_resamples() refuses each index shape in an outside split" plants three forms in each slot of an `outside` split. They are `3e9`, the character form and the list form. It also plants a `NULL` and an `integer(0)` `out_id`. `expect_outside_refused()` asserts the class, the header, the row and slot, and the count of named rows. It also asserts the call. The block passes, and it fails under the `check_outer_indices()` stub.
- AC5: the block "the index refusal names every bad position once, by its first shape" plants the four positions of the criterion. It asserts exactly those four bullets, each with its shape. The block "the outside refusal names every bad row, each by its shape" plants an `NA` in row 1. It plants the list form in row 3. It asserts exactly those two rows. M138's lone logical `NA` `in_id` and `c(NA, NA)` `out_id` plants still pass. All pass, and each fails under its stub.
- AC6: the block "the index rule runs before the containment rule, with no warning" plants `3e9` and then `"a"` alone in an inner `in_id`. It asserts this rule's refusal, no containment message and no warning. Under a mock of the rule, it asserts the containment refusal and the coercion warning. The block "check_nested() accepts row indices stored as doubles" stores every index as a double. Both constructors' designs pass. Both blocks pass, and the first fails under the stub.
- AC7: three texts state the rule and the logical `NA` exemption, read in the branch diff. They are the NEWS bullet, the `outside` paragraph of `?nested_resamples` and the design paragraph of `?nested_tune_grid`. The Known issues entry on index shapes lists five shapes. They are a fractional index, a non-data-frame `$data`, an empty inner `in_id`, an outer `in_id` past the frame within integer range, and an empty complement. AC1 to AC4 refuse none of these. `devtools::test()` gave 0 failures. `devtools::check()` gave 0 errors, 0 warnings and 0 notes in 12 min 24 s.

Consistency gate. `cairn_validate.py` exit 0, with 18 references-staleness advisories that this branch did not touch. `cairn_impact.py --changed` finds no changed principle. `devtools::document()` gives no diff. `pkgdown::check_pkgdown()` finds no problems. README is untouched. NEWS has the entry. No new top-level file. All six gating prose sweeps exit 0, and `air format --check .` is clean under air 0.12.0.

Independent review: three fresh reviewers, an Opus diff-bug lens, a Sonnet history lens and a Sonnet prior-review lens. The PR-comment probe found no human threads on these files. No finding shows a criterion failing, so status stays `review`. The maintainer took the recommended triage at the gate.

- Fix now, diff 1: a classed numeric, a matrix or an integer64 slot passes `is.numeric()` and fails the fold in vctrs. Added to the Known issues entry. A stricter rule is not taken, because an integer64 inner `in_id` runs.
- Fix now, diff 2: a negative or empty outer `in_id` passes and is not in Known issues. Added to the entry.
- Fix now, diff 3 and prior 2: no test plants two slots of one split, so the joined and plural clauses are not asserted. Added the block "the index refusal joins two bad slots of one split in one line".
- Fix now, history 5: no test plants `3e9` in the outer and an inner `in_id` of one fold, the hole of M138's review. Added the block "3e9 in the outer and an inner in_id of one fold is refused".
- Fix now, diff 6: the `outside` shape loop asserts no absence of warnings. Wrapped in `expect_no_warning()`.
- Fix now, prior 1: two type checks in the doubles loop name no design. `expect_type()` takes no `info`, so they became `expect_identical(typeof(...), info = name)`.
- Fix now, history 2: the DESIGN.md principle on refusing invalid designs named only the `NA` rule. It now names the D-114 shapes.
- Fix now, history 3: the M139 DESIGN.md paragraph said an outer `NA` `in_id` keeps the whole frame. Marked corrected M141.
- Rejected, history 1: the NEWS claim that a fractional outer `in_id` fold still fails. A probe on a `nested_resamples()` design ran the fold to a note. The `nested_cv()` case is already in Known issues.
- Rejected, diff 4: the header "not valid row numbers" for an empty `out_id`. The bullet says "is empty".
- Rejected, diff 5: clauses ordered by shape, not slot. That is the order the plan set.
- Rejected, diff 7: `nested_resamples()` does not check the inner splits that `inside` builds. The drivers' entry check refuses them, and AC4 does not cover them.
- Rejected, history 6 and prior 3: NEWS "most slots" and the dropped index 0. The claim audit read both.
- Rejected, history 4: the `check_inner_splits()` comment does not call the kept guards a second line. The comment states the invariant, and the guards are in plain view.
- Rejected, history 7: no benchmark for the new pass. It is linear, the same order as M138's `anyNA()`.
- No defect, diff 8 to 10: NA, NaN, `-Inf` and `-2147483648` are classed as the plan says. The tests assert class and message. The NEWS claims probed hold.

After the fixes, `test-split-checks.R` gives 1061 passes and 0 failures, and `air format --check .` is clean. With `check_split_indices()` stubbed, 10 blocks fail, the two new ones among them.
