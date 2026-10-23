<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M157: Test checks and names that M156's review flagged say only what they check

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate; RR<NN> whose Binding criteria bind this milestone's ACs (binding-criteria check), or — -->
- **Principles touched:** —   <!-- owner: plan · create/amend-via-gate; comma-separated IPn/GPn ids this milestone touches, or — -->
- **Resolves:** —   <!-- owner: plan · create/amend-via-gate; comma-separated GitHub issues the scope absorbs, each `#N closes` (the PR closes it at merge) or `#N partial` (the remainder gets a candidate row), or — ; skill conduct only — no validate check parses it -->
- **Surface tier:** internal — test files, a test helper comment and a tracking reference page, with no change to exported behavior, help pages or NEWS   <!-- owner: plan · create/amend-via-gate; user-facing | internal — <one-clause reason>; skill conduct only — no validate check parses it -->
- **Branch/PR:** m157-m156-review-leftovers   <!-- owner: implement (branch) / review (PR URL) · create; a companion checkout the milestone also works in is one further entry per checkout, `companion: <abs-path> <branch>` (implement), its PR URL appended by review — /milestone-review merges companions first, in listed order -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Fix the test-code findings that M156's review filed, as the candidate row "Fix the leftovers of M156's review" lists them.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** The two final-fit refusal blocks switch from seed identity to the existence check. Four test names lose a promise they do not check. The grid block "the new refusals ..." gets a name, a comment and assertions that say which failure it expects. A helper comment moves to the function it describes. The code inventory's provenance names the commit its line numbers match.

**Out:**
- An existence check on `nested_fit_resamples()` and `nested_workflow_map()` refusals (the row's item 2). Dropped at the plan gate: the map deletes the state it created, so the check cannot discriminate there, and no document promises the random state after a refusal.
- A condition class on `check_metrics()` (the row's item 4). It goes to the new candidate row "Give the unclassed refusals a class", which covers all 19 unclassed refusals in `R/checks.R`.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets.
     Every item opens with its positional label — `ACn:` — the item's
     position counted top-to-bottom, the number Coverage cites; an
     insertion, removal, or reorder renumbers the labels and the Coverage
     lines together.
     Driving RR set → its Binding criteria appear VERBATIM here (binding-
     criteria check), each ingested as a numbered criterion carrying its tag
     — `- [ ] ACn (BCm): <verbatim>` — with its own Coverage line, since
     coverage-complete counts AC checkboxes positionally (M107); departures:
     a "Deviations from RR<NN>" table ends this section. -->

- [x] AC1: In `tests/testthat/test-nested-final-fit-checks.R`, the blocks "the record refusals fire before anything is drawn" and "the all-failed refusal fires before anything is drawn" each remove `.Random.seed` before the refused call. After the call, each asserts `expect_false(exists(".Random.seed", envir = globalenv(), inherits = FALSE))`. Neither block compares `.Random.seed` before and after the call. If the `sample.int()` draw in `nested_final_fit()` moves above `check_workflow(object)` with its snapshot and `on.exit()` lines, each block fails. When the draw moves back, each block passes again.
- [x] AC2: The four blocks named "a workflow with no tune() marker is refused, naming nested_fit_resamples(), before any fold runs" are named "a workflow with no tune() marker is refused, naming nested_fit_resamples()". They are in the grid, bayes, race and sim-anneal check files. `grep -rn 'naming nested_fit_resamples(), before any fold runs' tests/testthat` finds nothing.
- [x] AC3: The grid block "the new refusals fire before the RNG is drawn from" has a new name that states what it refuses and does not say "new". The comment above it does not say "added here". The block asserts each of its three refused calls with `expect_error()`. If the refusal has a `nestedtune_` class, the assertion names that class. If it has none, the assertion names a message pattern.
- [x] AC4: In `tests/testthat/helper-orchestration.R`, the comment that opens "The stochastic sibling's parameter set" is directly above `bayes_stoch_param_info <- function`. The comment directly above `early_stop_control <- function` is the one that opens "The early-stopping control".
- [x] AC5: The provenance of `cairn/references/code-inventory.md` names `601cff7e` as the commit its `R/` line numbers are read at. For each of the 106 `F` rows of its table, the cited line in `git show 601cff7e:<file>` contains the row's function name, by the row loop in T4.
- [x] AC6: `Rscript -e 'devtools::test()'` reports 0 failures. `air format --check .` is clean. `Rscript benchmarks/sweep-test-comments.R` is clean.

## Coverage
<!-- owner: plan · create/amend-via-gate; each acceptance criterion → the
     task(s) satisfying it, by positional number (AC/Task counted
     top-to-bottom). Review reads to fence evidence — tracking-rules "AC fencing". -->

- AC1 → T1
- AC2 → T2
- AC3 → T2
- AC4 → T3
- AC5 → T4
- AC6 → T5

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits); substantive
     change is amend-via-gate. Every item opens with its positional label —
     `Tn:` — the item's position counted top-to-bottom, the number Coverage
     cites; an insertion, removal, or reorder renumbers the labels and the
     Coverage lines together. -->

- [x] T1: Rewrite the two final-fit blocks of AC1. Save the caller's `.Random.seed` and restore it at block end, as the grid block does. Remove it before the call and assert that it does not exist after. Delete the comment that says a reordering advances the caller's stream. Make the AC1 move by hand, see both blocks fail, and revert it.
- [x] T2: Rename the four blocks of AC2. Rename the grid block of AC3, fix its comment, and assert each refusal by class or message. Read each refusal's class by running it before writing the assertion.
- [x] T3: Move the comment of AC4.
- [x] T4: Edit the inventory provenance. Run a shell loop over the table's `F` rows against `601cff7e`.
- [x] T5: Run the verify slot and the test-comment sweep.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates.
     EXEMPT from the 150-line cap (D-046): history under D-045, never edited,
     so the cap must never demand a trim here. Wrapped entries get a WARN.
     The rejected-alternative record (/milestone-plan step 4) takes this form:
     `- YYYY-MM-DD: plan gate chose <approach> over <alternative> because
     <reason>; falsified by <evidence class>.` — one per approach choice the
     gate actually weighed, none where it weighed none, and it is the record
     `/milestone-review`'s thrash trigger (b) reads. It lives here rather than
     below so an instantiated file inherits no placeholder to delete.
     A milestone of a feature series also carries the plan's
     `feature series: M<a> -> M<b>[ -> …]` line (tracking-rules "Feature series"). -->

- 2026-10-23: created by /milestone-plan.
- 2026-10-23: tier check: milestone — the row's items change test code, not only comments or tracking files.
- 2026-10-23: idea vet: two concerns. Item 2: `nested_workflow_map()` deletes the random state it created, so an existence check cannot tell a refusal before the draw from one after it, and no document promises the random state after a refusal. The set chose to build neither check. Item 4: 19 refusals in `R/checks.R` lack a `nestedtune_` class, not `check_metrics()` alone, and a class changes what users see. The set chose a new candidate row. Item 6 found all 106 inventory rows correct at `601cff7e`, where M33 remapped them, so only the provenance names the wrong commit.
- 2026-10-23: collision check: absorbs the candidate row "Fix the leftovers of M156's review". Extends done M156, whose review rejected seed identity as evidence that a refusal precedes the draw. D-011's net-zero RNG contract is unchanged. Inbox: 1 open issue (#91, a parked row holds it), 0 open PRs, no overlap.
- 2026-10-23: lessons: the M09 lesson on `identical(.Random.seed, before)` against `exists(".Random.seed")` shapes AC1. Per the M152 lesson, no `helper-time-budget.R` row or snapshot names a renamed block (grep 2026-10-23). The benchmark block tables are pinned to their commits and stay as they are.
- 2026-10-23: criteria audit (reduced mode, fresh Opus reader): no findings on AC1-AC6. Its one note, to restore AC1's file path, was taken.
- 2026-10-23: plan gate chose the existence check for the final-fit blocks over removing their seed checks as M156 did, because the blocks' names promise "before anything is drawn" and the existence check can fail on that order. Falsified by evidence that `restore_rng()` removes a state it created.
- 2026-10-23: plan gate chose renaming the four untuned-workflow blocks over adding an empty-dispatch-record check, because the criteria need no new test on unchanged code and M156 renamed two such blocks. Falsified by a refusal of an untuned workflow found to run a fold.
- 2026-10-23: plan gate chose fixing the inventory's provenance over editing its two cited rows, because every `F` row matches `601cff7e`. Falsified by a row loop miss at `601cff7e`.
- 2026-10-23: ROADMAP caps: the M157 row and the new candidate row took it to 60 lines and about 24,200 bytes. The plan merged the Posit and CODEOWNERS rows into "Settle two tidymodels org conventions" and cut ten repeated old titles from parked rows' detail, leaving 59 lines and 23,875 bytes.
- 2026-10-23: question set: run mode — plan, build and review in one session. Item 2 — build neither check. Item 4 — new candidate row "Give the unclassed refusals a class".
- 2026-10-23: correction to the ROADMAP caps line above: the plan cut nine repeated old titles from parked rows, not ten. The two others went in the Posit and CODEOWNERS merge.
- 2026-10-23: /milestone-implement started on branch m157-m156-review-leftovers, cut from main at d6ec5a7b.
- 2026-10-23: T1 done. Both final-fit blocks now remove the seed and assert it does not exist after the refusal, following the pattern in test-nested-final-fit-rng.R. Mutation by hand: with the snapshot, `on.exit()` and draw moved above `check_workflow(object)`, each block failed once, on its `exists()` expectation, with 0 other failures in the file. Reverted with `git checkout`, and the file passed 31 blocks, 0 failed.
- 2026-10-23: T2 done. The four untuned-workflow blocks lost ", before any fold runs". The grid block is now "a malformed design or a workflow with no preprocessor is refused before the RNG is drawn from". Probed by running each refusal: both design refusals carry `nestedtune_bad_design`, and the no-preprocessor refusal carries only `rlang_error`. Each design refusal is asserted by class and its own message, since the two share a class, and the no-preprocessor one by message. Three planted mismatches (the splits message on the inner refusal, the design class on the no-preprocessor refusal, "malformed" on the no-preprocessor refusal) each failed. The four check files passed, 0 failed.
- 2026-10-23: implementation choice: each task runs its changed test files, and the full `devtools::test()` runs once at T5 over T1-T3, because the three tasks change only tests. The verify slot asks for the full suite before each task is checked off. This is a deviation, and T5's run is the evidence for all three.
- 2026-10-23: T3 done. The ten-line `min_n` comment moved, unchanged, from above `early_stop_control()` to directly above `bayes_stoch_param_info()`. `air format --check` is clean on the helper.
- 2026-10-23: T4 done. The inventory's provenance gains a "Line numbers" line naming `601cff7e`, marked "corrected M157". The row loop read 106 `F` rows with 0 misses. The line says the prose's own line citations were not re-read, since AC5's loop covers the table only.
- 2026-10-23: T5 done at 4e88e2e2. `devtools::test()` gave 1152 blocks, 0 failed, 0 errors, 0 skipped. The `step_pca()` error lines in its log are tune notes that fixtures print. `air format --check .` is clean at air 0.12.0, the latest release. `Rscript benchmarks/sweep-test-comments.R` exited 0 with no hits.
- 2026-10-23: claim audit: not owed — internal tier.
- 2026-10-23: all tasks done. Status set to review, and handed to /milestone-review.
- 2026-10-23: review pass 1: four lenses, 22 findings. 3 fixed on the branch at 8af67613, 3 to the new row "Fix seed checks in four refusal tests", 16 rejected. No defect return. The new row is written at post-merge hygiene, after the absorbed row graduates, because the ROADMAP holds 59 of its 60 lines now.

## Decisions
<!-- owner: implement / review · append-only; milestone-local; promote
     cross-cutting ones to cairn/DECISIONS.md.
     EXEMPT from the 150-line cap (D-074) because D-045 makes it history like the work log — dated dispositions, never edited — so the cap must never demand a trim here either.
     Entries carry their rationale; the counterweight `decisions format`
     advisory watches for pasted output, not for entry length (D-075). -->

## Review
<!-- owner: review · exclusive; evidence per criterion, consistency-gate
     results, review findings + triage. EXEMPT from the 150-line cap (M55),
     as are the work log (D-046) and the decisions section (D-074); evidence
     never scrambles plan-owned content. -->

Review pass 1, 2026-10-23, at 4622dfbb. main had not moved since the cut (d6ec5a7b), so no sync was needed. The Copilot round is off (no header line in PROFILE.md).

- AC1 evidence: In the two named blocks, an `awk` extract shows `rm(".Random.seed", ...)` before the refused call and `expect_false(exists(".Random.seed", ...))` after it, and no `before <-` or `identical(.Random.seed` line. Unmutated, the file ran 31 blocks with 0 failed, and both blocks had 2 expectations and 0 failures. Mutation in a `git archive` copy of HEAD, outside the work tree: the snapshot, `on.exit()` and `sample.int()` lines moved above `check_workflow(object)` (line 167, above line 168). Each block then had 1 failure, "Expected `exists(".Random.seed", envir = globalenv(), inherits = FALSE)` to be FALSE", and other blocks had 0 failures. Pass.
- AC2 evidence: `grep -rn 'naming nested_fit_resamples(), before any fold runs' tests/testthat` exited 1 with no output. The new name `a workflow with no tune() marker is refused, naming nested_fit_resamples()` is in exactly the grid, race, sim-anneal and bayes check files. Pass.
- AC3 evidence: The block at `test-nested-tune-grid-checks.R:435` is named "a malformed design or a workflow with no preprocessor is refused before the RNG is drawn from". A grep for "the new refusals" and "added here" in the file finds nothing. The block asserts `expect_error(r$refuse(), r$regexp, class = r$class)` over three entries. The two design refusals give `class = "nestedtune_bad_design"`, the class a run of each refusal showed at T2. The no-preprocessor refusal, which has no `nestedtune_` class, gives `class = NULL` and `regexp = "has no preprocessor"`. Pass.
- AC4 evidence: In `helper-orchestration.R`, the comment opening "The stochastic sibling's parameter set" runs from line 1795 to line 1804, and `bayes_stoch_param_info <- function` is at line 1805. Those ten lines hold no non-comment line. The comment run directly above `early_stop_control <- function` opens at line 1740 with "The early-stopping control". Pass.
- AC5 evidence: Line 10 of `code-inventory.md` names `601cff7e` as the commit the table's `R/` line numbers are read at. A fresh row loop over the `| F` rows read 106 rows with 0 misses at `601cff7e`. Pass.
- Consistency gate: `cairn_validate.py` passed, with 18 advisory warnings, all reference-page staleness. No principle changed, so `cairn_impact` was skipped. `air format --check .` is clean at air 0.12.0. `sweep-test-comments.R` exited 0. All six gating `sweep-prose.R` modes exited 0. `pkgdown::check_pkgdown()` found no problems. NEWS needs no entry, since nothing users see changed. README is untouched. `devtools::document()` left `man/` and `NAMESPACE` unchanged but bumped `Config/roxygen2/version` from 8.1.0 to 8.1.1, because the local roxygen2 is 8.1.1. That is an environment difference, not this branch, and the line was reverted.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: four other refusal blocks back an ordering claim with `expect_identical(.Random.seed, before)` (`test-event-level.R` "the refusal fires before anything is fitted", which also uses a bare `expect_error()`, `test-nested-final-fit-resamples.R`, `test-nested-final-fit-identity.R`, `test-nested-final-fit-set.R`) — follow-up, new row "Fix seed checks in four refusal tests"
- diff-bug #2: the absorbed candidate row still lists the fixed items — reject (planned change): post-merge hygiene graduates the row
- diff-bug #3: the grid comment's "both drivers install their restoring on.exit()" names no driver, and the block calls one — fix now, fixed 8af67613
- diff-bug #4: the grid comment "its message names it" has no clear referent — fix now, fixed 8af67613
- diff-bug #5: "the record refusals fire before anything is drawn" names a plural, but the block triggers one record refusal — follow-up, row "Fix seed checks in four refusal tests". AC1 quotes the name, so a rename here would change a criterion.
- diff-bug #6: `saved` is the fixture's seed, not the state on entry to the block — reject (false): the block restores the session state at its own exit, as `test-nested-final-fit-rng.R` does, and both fixtures seed first
- diff-bug #7: `R/nested-final-fit.R`'s comment says a refusal before the draw "leaves the caller's generator state untouched", which `restore_rng()` makes true wherever the refusal fires — follow-up, row "Fix seed checks in four refusal tests" (an unmodified line)
- diff-bug #8: the inventory's "Lines" counts carry no date — reject (false): the Extraction line dates every extracted value at `89d8418`, and the new line moves only the line numbers
- blame-history #1: the four renamed blocks dropped an ordering claim that GP3 and M070's criterion assert, and nothing in those files checks it — reject (planned change): the body never checked the order (read at `71e19150^`), and the plan gate chose renaming over a new dispatch check
- blame-history #2: clearing `.Random.seed` first loses detection of a refusal that advances an existing seed — reject (false): any draw creates the absent seed, so existence catches every draw that identity caught, and `restore_rng()` puts back an existing seed on every exit
- blame-history #3: `saved <- .Random.seed` has no existence guard — reject (false): both fixtures call `set.seed()` before it, so the seed always exists there
- blame-history #4: the provenance names two commits — reject (false): the Extraction line dates the extraction, and the new line dates the line numbers. The lens's loop found 106 of 106 rows at `601cff7e` and 68 misses at `89d8418`, which backs the correction.
- prior-review #1: the no-preprocessor refusal is asserted by message only, the defect M156's review returned on — fix now: assert `class = "rlang_error"` with the message, fixed 8af67613
- prior-review #2: the unguarded `saved <- .Random.seed` — reject (false), as blame-history #3
- prior-review #3: the inventory header still names `89d8418`, the prose citations were not re-read, and milestone ids appear on the page — reject (false): `89d8418` is the true extraction commit, the prose gap is disclosed, and milestone ids are allowed in `cairn/` records
- prior-review #4: the grid block "`select` must be a selection_rule(), refused before any fold runs" keeps the phrase — reject (false): `grid_refusal()` mocks `dispatch_folds()` with a sentinel, and the block shows the accepting side reaching it
- ripple #1-#3: lines 4, 9 and 24 of the inventory name `89d8418` — reject (false): they date the extraction and the definition count, which the new line leaves true
- ripple #4: three prose citations of `R/nested-results.R:69` for `[.nested_results` — reject (false): line 69 holds that definition at `601cff7e` (checked)
- ripple #5: the absorbed ROADMAP row still lists the fixed items — reject (planned change), as diff-bug #2
- ripple #6: the select block's "before any fold runs" — reject (false), as prior-review #4
- AC6 evidence: at 97ddd076, after the review fixes, `devtools::test()` gave 1152 blocks, 0 failed, 0 errors, 0 skipped. `air format --check .` is clean, and `Rscript benchmarks/sweep-test-comments.R` exited 0. `devtools::check()` at 4622dfbb gave 0 errors, 0 warnings and 0 notes. Pass.
- snapshot: no changed `_snaps` file in `git diff --name-only main...HEAD`.
