<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M160: Seed checks in four refusal tests can fail

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — test code and one source comment; no export, help page or behavior changes
- **Branch/PR:** m160-seed-check-refusals

## Goal

Make the four refusal tests named by the candidate row "Fix seed checks in four refusal tests" back their RNG claims with checks that can fail, and fix the two smaller items the row lists.

## Scope

**In:** the four blocks the row names, where `expect_identical(.Random.seed, before)` passes whether or not the refusal comes before the RNG draw, because `restore_rng()` is registered before the draw and puts the caller's state back either way. The bare `expect_error()` in the `test-event-level.R` block. The six other sites of the same comparison in `tests/testthat/` (ten in all at 6e5e3527), each read and fixed only where its comparison cannot fail on code that breaks its block's claim. The plural name of the final-fit block "the record refusals fire before anything is drawn", which triggers one refusal. The comment above `check_workflow_identity()` in `R/nested-final-fit.R`, which gives the order a weak reason.

**Out:** milestone ids in that comment and in every other `R/` comment → M161. The interrupt block's leftovers → candidate row "Tidy the interrupt block's leftovers". Existence checks for `nested_fit_resamples()` and `nested_workflow_map()` refusals: dropped at M157's plan gate, since the map deletes the state it creates. No package behavior, help page or NEWS change.

## Acceptance criteria

- [ ] AC1: In each of the four blocks "the refusal fires before anything is fitted" (`test-event-level.R`), "a marked workflow is refused by the final fit on such a record, before fitting" (`test-nested-final-fit-resamples.R`), "an id naming no row is refused" (`test-nested-final-fit-set.R`) and "a record with no workflow entry is refused before the identity check" (`test-nested-final-fit-identity.R`), under these names or the names the milestone gives them, moving the function's refusal after its RNG draw makes the block fail, and every RNG check the block keeps is among the failures testthat reports. A block whose name claims an order against fitting or drawing keeps at least one such check. The `test-event-level.R` block asserts its refusal by condition class.
- [ ] AC2: For every line that `grep -nF 'expect_identical(.Random.seed, before)' tests/testthat/*.R` prints at the branch head, the comparison on that line fails under the one break that matches the RNG claim its block's name makes: the refusal moved after the draw (a refusal comes before a draw), an extra draw added before the function returns (nothing is drawn), or the `restore_rng()` registration removed (the caller's state is restored or unchanged).
- [ ] AC3: The block "the record refusals fire before anything is drawn" in `test-nested-final-fit-checks.R` has a name that covers only the refusal it triggers.
- [ ] AC4: The comment above the `check_workflow_identity(object, procedure$workflow)` call in `R/nested-final-fit.R` gives this reason for the order: a refusal there comes before the seeds are drawn, so a session with no generator state still has none after it, while `restore_rng()` puts back the state of a session that had one, whichever comes first.
- [ ] AC5: At the branch head, `devtools::test()` reports 0 failures, `devtools::check()` reports 0 errors, 0 warnings and 0 notes, `air format --check .` is clean, and `Rscript benchmarks/sweep-prose.R --plain` is clean.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T3
- AC5 → T4

## Tasks

- [ ] T1: Fix the four AC1 blocks. Where the function keeps a state its draw created (`nested_tune_grid()`, `nested_final_fit()`), use the existence check of "the record refusals fire before anything is drawn" (`test-nested-final-fit-checks.R:245`). Where it does not (read the set path behind `test-nested-final-fit-set.R:50` first), use another check that can fail, or drop the comparison where the name claims no order. Give the event-level block `class =`. For each block, move the refusal after the draw on a scratch edit, read the failing expectations from testthat's output, and revert.
- [ ] T2: Read the six other sites (`test-nested-final-fit-resamples.R:128`, `test-nested-final-fit-identity.R:124`, `test-nested-tune-bayes-results.R:284`, `test-nested-tune-finalize.R:799`, `test-nested-workflow-map-rng.R:31` and `:130`, line numbers at 6e5e3527). Fix each comparison that cannot fail on code that breaks its block's claim, or narrow the name to what it checks. Record each site's reading in one work-log line, and plant the AC2 break that matches each kept comparison's claim, restore claims included. `test-nested-tune-bayes-results.R:293` (`expect_false(identical(...))`, a check that the state moves) is outside AC2.
- [ ] T3: Rename the AC3 block to the refusal it triggers. Reword the AC4 comment, reading `restore_rng()` (`R/nested-tune-grid.R:1004`) and the T1 existence check's result for the claim.
- [ ] T4: Run the verify slot and `devtools::check()` from the main checkout (LESSONS M149), and record the AC5 results.

## Work log

- 2026-10-24: created by /milestone-plan.
- 2026-10-24: tier check: not run — work named at the question set.
- 2026-10-24: idea vet: no concern. The fix replaces comparisons that cannot fail with ones that can, the pattern M157 used for two final-fit blocks; the repo's own review filed the row.
- 2026-10-24: collision check: absorbs the candidate row "Fix seed checks in four refusal tests" (filed at M157's review). M157 shipped the existence check this reuses and dropped existence checks for the map and `nested_fit_resamples()`, kept Out. No D-entry collides; D-011 (net-zero RNG) is the contract the checks test. Inbox sweep: 1 open issue (#91, cross-referenced by a parked row), 0 PRs, no overlap.
- 2026-10-24: question set: which candidate to plan — "Fix the seed checks"; plan a second milestone — "Also the id cleanup" (M161).
- 2026-10-24: scope: the plan's grep found ten `.Random.seed, before)` sites, not the row's four; the six others join as AC2, fixed only where they cannot fail.
- 2026-10-24: plan gate chose renaming the AC3 block to its one refusal over triggering each record refusal, because the narrower promise matches what the block checks and the record refusals each have their own blocks; falsified by evidence that no block tests the order of the other record refusals against the draw.
- 2026-10-24: criteria audit (reduced mode, fresh Opus reader): 3 findings, all fixed. AC2 promised failure on any breaking code, so it now names one break per claim kind, and T2 plants it for restore claims too. AC2's grep also matched an `expect_false(identical(...))` line, so the pattern is now `expect_identical(.Random.seed, before)` and T2 names that line as outside. AC1 promised each RNG check fails while T1 only saw the block fail, so AC1 and T1 now read the failing expectations. AC3, AC4 and AC5 passed; no criterion binds an instrument.
- 2026-10-24: implement started on `m160-seed-check-refusals`, cut from main at c869c197.
- 2026-10-24: T1 (checkpoint, not yet ticked): the four blocks now remove `.Random.seed` and assert it is still absent after the refusal, and the event-level block asserts `nestedtune_bad_event_level`. All four refusals sit before the draw in `nested_tune_grid()` or `nested_final_fit()`, both of which keep a state their draw created, so the existence check applies to all four, the set path included. The identity block puts the seed back before its second half, which builds fixtures. Plant: moving `check_event_level()` after the draw in `nested_tune_grid()`, and the snapshot and draw to the top of `nested_final_fit()`, failed each of the four blocks on its `exists()` expectation, and that is the only RNG check each keeps. Reverted. The four files pass (26 blocks, 0 failed); the full suite is running.

## Decisions

## Review
