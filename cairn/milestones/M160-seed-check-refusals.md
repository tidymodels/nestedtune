<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M160: Seed checks in four refusal tests can fail

- **Status:** review
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

- [x] AC1: In each of the four blocks "the refusal fires before anything is fitted" (`test-event-level.R`), "a marked workflow is refused by the final fit on such a record, before fitting" (`test-nested-final-fit-resamples.R`), "an id naming no row is refused" (`test-nested-final-fit-set.R`) and "a record with no workflow entry is refused before the identity check" (`test-nested-final-fit-identity.R`), under these names or the names the milestone gives them, moving the function's refusal after its RNG draw makes the block fail, and every RNG check the block keeps is among the failures testthat reports. A block whose name claims an order against fitting or drawing keeps at least one such check. The `test-event-level.R` block asserts its refusal by condition class.
- [x] AC2: For every line that `grep -nF 'expect_identical(.Random.seed, before)' tests/testthat/*.R` prints at the branch head, the comparison on that line fails under the one break that matches the RNG claim its block's name makes: the refusal moved after the draw (a refusal comes before a draw), an extra draw added before the function returns (nothing is drawn), or the `restore_rng()` registration removed (the caller's state is restored or unchanged).
- [x] AC3: The block "the record refusals fire before anything is drawn" in `test-nested-final-fit-checks.R` has a name that covers only the refusal it triggers.
- [x] AC4: The comment above the `check_workflow_identity(object, procedure$workflow)` call in `R/nested-final-fit.R` gives this reason for the order: a refusal there comes before the seeds are drawn, so a session with no generator state still has none after it, while `restore_rng()` puts back the state of a session that had one, whichever comes first.
- [x] AC5: At the branch head, `devtools::test()` reports 0 failures, `devtools::check()` reports 0 errors, 0 warnings and 0 notes, `air format --check .` is clean, and `Rscript benchmarks/sweep-prose.R --plain` is clean.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T3
- AC5 → T4

## Tasks

- [x] T1: Fix the four AC1 blocks. Where the function keeps a state its draw created (`nested_tune_grid()`, `nested_final_fit()`), use the existence check of "the record refusals fire before anything is drawn" (`test-nested-final-fit-checks.R:245`). Where it does not (read the set path behind `test-nested-final-fit-set.R:50` first), use another check that can fail, or drop the comparison where the name claims no order. Give the event-level block `class =`. For each block, move the refusal after the draw on a scratch edit, read the failing expectations from testthat's output, and revert.
- [x] T2: Read the six other sites (`test-nested-final-fit-resamples.R:128`, `test-nested-final-fit-identity.R:124`, `test-nested-tune-bayes-results.R:284`, `test-nested-tune-finalize.R:799`, `test-nested-workflow-map-rng.R:31` and `:130`, line numbers at 6e5e3527). Fix each comparison that cannot fail on code that breaks its block's claim, or narrow the name to what it checks. Record each site's reading in one work-log line, and plant the AC2 break that matches each kept comparison's claim, restore claims included. `test-nested-tune-bayes-results.R:293` (`expect_false(identical(...))`, a check that the state moves) is outside AC2.
- [x] T3: Rename the AC3 block to the refusal it triggers. Reword the AC4 comment, reading `restore_rng()` (`R/nested-tune-grid.R:1004`) and the T1 existence check's result for the claim.
- [x] T4: Run the verify slot and `devtools::check()` from the main checkout (LESSONS M149), and record the AC5 results.

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
- 2026-10-24: T1 verify: full suite at d497772e, 1153 blocks, 0 failed; `air format --check .` clean. T1 ticked.
- 2026-10-24: T2 readings, with plants. `final-fit-resamples:128` (restored): kept, fails with `nested_final_fit()`'s restore removed. `bayes-results:284` ("draws nothing the caller can see", a restore claim): kept, fails with the loop's restore removed. `finalize:799` (draws nothing): kept, fails with a `runif()` planted in `analysis_framed_inner()`, which has no restore. `map-rng:31` (untouched): kept. The map puts its entry state back before every workflow and on exit, so it fails only with both the map's and the loop's restores removed, the break taken for the map. `identity:124`, in the `expect_mismatch()` helper ("generator state unchanged"): its refusal comes before any draw, so removing the restore could not fail it. It is now the existence check, and every probe fails with the draw moved to the top of `nested_final_fit()`. `map-rng:130` ("an error partway through the set still restores"): the error comes at the third workflow's grid check, before any draw, and the map reinstates the entry state, so it passed with every restore removed. It now runs in a session that never drew, asserts `nestedtune_bad_grid` and the absent state, and fails with the map's restore removed. Plants reverted. 4 `expect_identical(.Random.seed, before)` sites remain.
- 2026-10-24: T3: renamed the AC3 block "the refusal of a record with no inner specification fires before anything is drawn"; the old name is in no ledger or snapshot, only in the historical `benchmarks/test-blocks-*.csv` tables, left as they are. Reworded the AC4 comment, from `restore_rng()`'s two branches and T1's existence result. `M83` in it is left for M161.
- 2026-10-24: T4: the full suite at 3488fffc, run alone, failed 11 blocks, all in `test-parallel-identity.R` (22 failures, 11 errors; the silent reporter kept no messages, so whether it is the lost-daemon failure of the candidate row is not known). The file alone then passed, 21 blocks, 0 failed. M160 touches neither that file nor parallel code. Rerunning the full suite with messages kept.
- 2026-10-24: T4: the rerun at 3488fffc (tests unchanged since), run alone, gave 1153 blocks, 0 failed, 0 errors. `devtools::check()` running.
- 2026-10-24: T4: `devtools::check()` at 073dbf3b, main checkout: 0 errors, 0 warnings, 0 notes. `air format --check .` and `sweep-prose.R --plain` clean at 3488fffc. T2, T3 and T4 ticked.
- 2026-10-24: claim audit: not owed — internal tier.
- 2026-10-24: implement done; status review.

## Decisions

## Review

Pass 1, 2026-10-24, branch head fa0ec322, main not moved since the cut (c869c197). Plants run on scratch copies of `git archive HEAD`, never on the checkout.

- AC1: copy A puts the draw before each refusal (`check_event_level()` after the seed draw in `nested_tune_grid()`, the snapshot and draw at the top of `nested_final_fit()`). The four blocks failed on the four test files' run (26 blocks, 39 failures): "the refusal fires before anything is fitted", "a marked workflow is refused by the final fit on such a record, before fitting", "an id naming no row is refused" and "a record with no workflow entry is refused before the identity check", each on its `exists(".Random.seed", ...)` expectation, the one RNG check each keeps. The event-level block passes `class = "nestedtune_bad_event_level"` to `expect_error()`. Pass.
- AC2: the grep at fa0ec322 prints 4 lines: `test-nested-final-fit-resamples.R:131`, `test-nested-tune-bayes-results.R:284`, `test-nested-tune-finalize.R:799`, `test-nested-workflow-map-rng.R:31`. Copy B removes the restore registrations of `nested_final_fit()`, `nested_loop()` and `nested_workflow_map()`, and plants a `runif()` in `analysis_framed_inner()`. Each of the four lines failed there, on "Expected `.Random.seed` to be identical to `before`". The draws-nothing claim (`finalize:799`) fails on the planted draw, since `analysis_framed_inner()` has no restore. The restore claims (`resamples:131`, `bayes:284`) fail with their function's restore gone, and the map claim (`map-rng:31`) with both the map's and the loop's gone, the break the work log records for the map. Copy B carries all four breaks at once, so each failure has one cause per claim: each function's own draw changes the state once its restore is gone. Pass.
- AC3: the block at `test-nested-final-fit-checks.R:245` is now "the refusal of a record with no inner specification fires before anything is drawn". It sets `attr(res, "inside") <- NULL` and makes one `expect_error()` call, class `nestedtune_bad_results`, whose message (read by execution in T3) names the missing inner specification. Pass.
- AC4: `R/nested-final-fit.R:197-199` reads "It runs before the seeds below are drawn, so a session with no generator state still has none after a refusal here. A session that had one gets it back from `restore_rng()` either way." That matches `restore_rng()`'s two branches (`R/nested-tune-grid.R:1004`: assign when `had_seed`, else only `RNGkind()`) and copy A, where a draw before the refusal left a state behind. Pass.
- Suite at fa0ec322, run alone: 1153 blocks, 0 failed, 0 errors (AC5 re-run after the fix-now commit below).
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: the AC4 comment's "gets it back from `restore_rng()` either way" reads as if the restore runs on this refusal, which comes before the restore is registered — fix now: reworded to "would get it back from `restore_rng()` even if this check came after the draw", which still states AC4's reason, fixed f7fcdcb0.
- diff-bug #2: "the caller's state comes back either way" in five test comments has the same ambiguity — fix now: the comments are gone, and one helper comment states the reason (diff-bug #4), fixed f7fcdcb0.
- diff-bug #3: "Existence, not identity" sets the check against the old form, near bug history; the map comment reasons about a planted break — fix now: the helper comment states the fact without the contrast, and the map comment states what the map does, fixed f7fcdcb0.
- diff-bug #4: the save, on.exit and rm setup is copied five times, plus the reference block — fix now: `local_no_rng_state()` in `helper-nestedtune.R`, used at the six M160 sites and the two `test-nested-final-fit-checks.R` blocks that held the same setup, fixed f7fcdcb0.
- diff-bug #5: a reflowed comment line in `test-nested-final-fit-identity.R:99` is 84 characters — reject (style).
- diff-bug #6: `expect_mismatch()` no longer leaves the stream at `set.seed(1)`, and the map block dropped the caller-seed error case — reject (false): every caller reseeds before its next draw (suite green), and the dropped comparison passed with every restore removed (T2), so it could not fail; the block's name is fixed under blame-history #2.
- blame-history #1: same as diff-bug #1 — fix now, as there, fixed f7fcdcb0.
- blame-history #2: the map block's name "still restores the caller's state" no longer matches what it asserts — fix now: renamed "an error partway through the set still removes the state the map created", fixed f7fcdcb0.
- blame-history #3: `saved <- .Random.seed` errors in a session with no state, which the removed `set.seed()` calls had ruled out — fix now: `local_no_rng_state()` handles a session with no state and removes one created in the block, fixed f7fcdcb0.
- blame-history #4: the T4 work log ties the parallel-identity failure to the candidate row without evidence — reject (false): the line says its identity is not known. The observation goes to that row at hygiene (follow-up).
- prior-review #1: the map existence check contradicts M157's drop of existence checks for map refusals — reject (false): M157 dropped them as order checks on refusals; this block checks the map's exit handler, and it fails with that handler removed (copy C).
- prior-review #2: the same 84-character comment line — reject (style).
- prior-review #3: the renamed AC3 block matches what it triggers — noted, no defect.
- ripple #1: the map block's comment and name may misstate where the error is raised — fix now with blame-history #2. The error comes after an earlier workflow's orchestrator ran (two `nested_tune_grid()` entries counted by `trace()` in T2), so "partway" holds, fixed f7fcdcb0.
- ripple #2: the ROADMAP row "Fix seed checks in four refusal tests" quotes the old block name — reject (planned change): this merge's hygiene graduates the row.
- ripple #3: `saved <- .Random.seed` with no `set.seed()` before it — fix now with blame-history #3, fixed f7fcdcb0.
- Re-check after the fixes: the six edited files pass (61 blocks, 0 failed); `air format --check .` clean. Copy A fails all six refusal blocks and every `expect_mismatch()` probe on `exists()`; copy B fails the four AC2 lines; copy C (only the map's restore removed) fails both map existence blocks.
- AC5: at f7fcdcb0, run alone: `devtools::test()` 1153 blocks, 0 failed, 0 errors; `devtools::check()` 0 errors, 0 warnings, 0 notes (main checkout); `air format --check .` clean; `sweep-prose.R --plain` clean. Pass.
- Gate: `cairn_validate.py` passes (18 reference-staleness advisories, none from this milestone). `devtools::document()` changed only `Config/roxygen2/version` 8.1.0 → 8.1.1, from the local roxygen2 8.1.1, with no `man/` change; reverted as outside this milestone, and main gives the same diff. `pkgdown::check_pkgdown()` no problems. All six gating prose sweeps clean. No changelog entry: no user-visible change. No snapshot file changed. No principle changed, so no impact report. Feature cap: 0 open PRs of 1.
