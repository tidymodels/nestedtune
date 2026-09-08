# M75: The suite makes each claim once, and the files that test the harness rather than the package are deleted or trimmed

- **Status:** review
- **Priority:** normal
- **Depends on:** M74
- **Driving RR:** —
- **Principles touched:** GP4
- **Resolves:** —
- **Surface tier:** internal — deletes and trims test files; no external consumer of the package relies on them
- **Branch/PR:** m075-suite-prune

## Goal

Delete test blocks whose claim a surviving block already asserts, and thin the nine files that test the harness, the CI yaml or the vignettes' citations rather than the package, so the suite reads as one check per claim.

## Scope

**In:** the per-tuner blocks the 2026-09-07 survey found repeating a sibling's claim (the `expect_outer_columns_kept()` trio in bayes-results, race-oracles and anneal-oracles; the zero-row `.iter` pair in anneal-oracles and bayes-results; the failed-fold RNG restoration trio in race-rng, bayes-rng and anneal-rng; the by-hand recipe blocks in race-oracles and anneal-oracles that re-run a fold the reference-loop block already matched; bayes-oracles' "every NAMESPACE method runs"; the `iter = 0` identity asserted in both bayes-oracles and final-fit-oracles; the three final-fit-results blocks sharing one cached fit), each removed with its survivor named; a disposition per harness-testing file — `test-fixture-cache.R`, `test-hang-trace.R`, `test-suite-hygiene.R`, `test-ci-workflows.R`, `test-vignette-citations.R`, `test-drift-manifest.R`, `test-dots-barrier.R`, `test-control-slots.R`, `test-parallel-classify.R` — deleted, kept whole, or trimmed; helpers left uncalled by the deletions removed; the `Config/testthat/start-first` list and the `helper-time-budget.R` ledger re-keyed where a deletion moves a budgeted call.

**Out:** making the surviving blocks faster → M74. Deleting any oracle, rng or identity block that is the only assertion of its claim → never in this milestone; a block whose partner is unclear stays. A coverage-percentage target → none (PROFILE: covr is a diagnostic).

## Acceptance criteria

- [ ] AC1: Every `test_that()` block removed between the branch point and the head — enumerated by diffing `test_that_descriptions()` over `tests/testthat/test-*.R` at the two refs — has its claim asserted by a block that survives on the head, except a block removed from a harness-testing file under T3's trim rule (whose claim is about the harness, not the package) and a block removed with its whole file under AC4's deleted disposition; a block added on the head may be the survivor for the blocks it replaces.
- [ ] AC2: The head has at least 45 fewer `test_that()` blocks than the branch point, counted by `test_that_descriptions()` over `tests/testthat/test-*.R` (795 at the branch point `accfbe2`; the question gate of 2026-09-08 kept four of the nine files whole and read `test-parallel-classify.R` as package tests, so the floor is the 15 duplicates the removal table names plus 30 of the 31 blocks the two deletions and two trims remove).
- [ ] AC3: Every function defined in `tests/testthat/helper-*.R` (enumerated by `grep -n -E '^[A-Za-z_.]+ <- function' tests/testthat/helper-*.R`) is named outside a comment or string in another top-level expression of some file under `tests/testthat/`, its own included, found by `grep -n -F` on the name; a function that is not is removed.
- [ ] AC4: Each of the nine harness-testing files named in Scope carries one of three dispositions — deleted, kept whole, or trimmed — in a classification ledger in the milestone file, one row per file naming the disposition and its reason; a trimmed file's removed blocks appear in AC1's table.
- [ ] AC5: `Rscript -e 'devtools::test()'` on the head reports 0 failures and 0 skips, and the active profile's verify slot is clean — `devtools::check()` 0 errors, 0 warnings, 0 unjustified notes — with `air format --check` clean on every file the branch touches (`git diff --name-only <branch point>`).

## Coverage

- AC1 → T1, T2, T3
- AC2 → T2, T3
- AC3 → T4
- AC4 → T3
- AC5 → T5

## Tasks

- [x] T1: Write the removal table from the survey's per-file findings before deleting anything: one row per candidate block with its surviving partner's `file: description`, and drop from the list any block whose partner asserts less than it does.
- [x] T2: Delete the per-tuner duplicates in the table; where a partner asserts less, extend the partner rather than keep both.
- [x] T3: Disposition each of the nine harness-testing files in the classification ledger — a file whose subject is a repo artifact (the yaml, vignette citations, the drift manifest) is deleted unless a block detects a defect that has reached the default branch before, cited by commit; a file testing a harness the surviving tests depend on (the hang trace, the fixture cache, the parallel classifier) is trimmed to the blocks that would fail on a defect in that harness — then apply it, re-key `start-first` and the time-budget ledger.
- [x] T4: Run the AC3 enumeration; remove every helper it leaves uncalled.
- [x] T5: `devtools::test()`, `devtools::check()`, `air format --check`.

## Removals (AC1)

One row per removed `test_that()` description; the survivor is the block on the head that asserts the removed block's claim. Mechanism notes cite the one site in `R/` the duplicated blocks all exercised.

| Removed (`file: description`) | Survivor (`file: description`) | Note |
|---|---|---|
| `test-nested-tune-bayes-results.R: a Bayesian run keeps the outer fit's predictions and extracts when the control asks (AC1, AC2)` | `test-nested-tune-grid-results.R: save_pred = TRUE keeps each fold's outer-fit predictions, identical to last_fit()'s (AC1)`; `test-nested-tune-grid-results.R: extract = f keeps f() of each fold's outer-fit workflow, identical to f() on last_fit()'s (AC2)` | one outer-fit site reads the merged control for every tuner (`R/nested-tune-grid.R`, `save_pred` and `extract` branches of the outer fit) |
| `test-nested-tune-race-oracles.R: a racing run keeps the outer fit's predictions and extracts when the control asks (AC1, AC2)` | the two grid-results blocks above | same site |
| `test-nested-tune-sim-anneal-oracles.R: an annealing run keeps the outer fit's predictions and extracts when the control asks (AC1, AC2)` | the two grid-results blocks above | same site |
| `test-nested-tune-sim-anneal-oracles.R: a fold that scored nothing carries .iter on its zero-row table (AC1)` | `test-nested-tune-bayes-results.R: a Bayesian fold that scored nothing carries a zero-row table with .iter`; `test-nested-tune-sim-anneal-oracles.R: nested_tune_sim_anneal() carries the Bayesian sibling's formals less objective, with initial at 1 (AC1)` (asserts `.iter` on the completed annealing record) | one prototype site builds the zero-row table from a completed fold's columns (`R/nested-tune-grid.R`) |
| `test-nested-tune-race-rng.R: the RNG state is restored when folds fail but the run completes` | `test-nested-tune-grid-rng.R: the RNG state is restored when folds fail but the run completes`; its no-`.iter` clause moves to `test-nested-tune-race-oracles.R: the fold record is every candidate the race scored, and the selection a survivor (AC3)` | one `restore_rng()` exit handler in the shared loop (`R/nested-tune-grid.R`) serves every tuner |
| `test-nested-tune-bayes-rng.R: the RNG state is restored when folds fail but the run completes` | the grid-rng block above | same handler |
| `test-nested-tune-sim-anneal-rng.R: the RNG state is restored when folds fail but the run completes` | the grid-rng block above; its `.iter` clause by the zero-row survivors above | same handler, same prototype site |
| `test-nested-tune-race-oracles.R: the help page's by-hand recipe reproduces a fold's inner table and selection (AC4)` | `test-nested-tune-race-oracles.R: per-fold metrics, selections and inner tables match a hand-rolled racing reference loop (AC1, deterministic)` (recorded `.tuning_seed` and inner tables against a loop seeded by the documented contract with the kind pinned); `test-nested-final-fit-race.R: the racing final fit matches a hand-rolled reference pipeline (AC6)` (the recorded control re-run) | — |
| `test-nested-tune-sim-anneal-oracles.R: the help page's by-hand recipe reproduces a fold's inner table and selection (AC4)` | `test-nested-tune-sim-anneal-oracles.R: per-fold metrics, selections and inner tables match a hand-rolled annealing reference loop (AC1, deterministic)`; `test-nested-final-fit-sim-anneal.R: the annealing final fit matches a hand-rolled reference pipeline (AC5)` | — |
| `test-nested-tune-bayes-oracles.R: every nested_results method in NAMESPACE runs on a Bayesian result` | `test-nested-tune-bayes-results.R: print() and summary() count the candidates a Bayesian fold scored`; the per-method blocks on grid results in `test-collect-readers.R`, `test-vctrs-compat.R`, `test-dplyr-compat.R`, `test-nested-results-plot.R`, `test-nested-results-agreement.R` | the block asserted only that each method runs, on a record whose reader-facing columns the grid record shares |
| `test-nested-final-fit-results.R: the fitted workflow predicts on new data` | `test-nested-final-fit-results.R: the final fit returns a trained workflow inside its own object` (extended with the prediction assertions) | one cached fit |
| `test-nested-final-fit-results.R: the final fit trains on every row, not on an outer analysis set` | the same extended block | one cached fit |

| `test-parallel-classify.R: dispatch refuses daemons that cannot load the package` | `test-parallel-classify.R: a pool that cannot load AND holds an old build names both fixes` (its plain-pool clause makes the same call and class assertion) | its ledger row (`helper-time-budget.R`, line 209) goes with it |
| `test-parallel-classify.R: a load failure still outranks an incompatible daemon` | the same both-fixes block (asserts `outcome`, `cannot_load` and `incompatible` on the same pool shape, plus the message) | — |
| `test-parallel-classify.R: a miraiInterrupt aborts instead of being recorded as a failed fold` | `test-parallel-classify.R: a real interrupt is an interrupt, not a cancellation` (extended to assert the condition is an error of that class) | same fixture |
| `test-fixture-cache.R: the report counts one build per signature and every request` | — (T3 trim rule: tests the build report, a diagnostic the cache's correctness does not rest on) | — |
| `test-fixture-cache.R: one call written two ways is one fixture, reported as built twice` | — (T3 trim rule: report grouping) | — |
| `test-fixture-cache.R: the same call under two seeds is two fixtures, not one rebuilt` | — (T3 trim rule: report grouping; the seed's place in the key is `the key separates the seed, and argument order does not` and `a different seed rebuilds rather than serving the first result`) | — |
| `test-fixture-cache.R: the teardown's report is written to stderr, and nothing to stdout` | — (T3 trim rule: the report's print format) | — |
| `test-hang-trace.R: the two-block fixture's directory is gone once its caller returns` | — (T3 trim rule: a self-test of the test fixture's cleanup) | — |
| `test-hang-trace.R: the duplicate-description scan reports a planted duplicate` | — (T3 trim rule: a planted-defect self-test of the scan; `no two test_that() blocks in one file share a description` is the check the suite depends on) | — |

The 25 descriptions removed with `test-vignette-citations.R` and `test-drift-manifest.R` are in git at the branch point (`accfbe2`) and take AC4's deleted disposition.
Considered and kept: the `iter = 0` pair (`test-nested-tune-bayes-oracles.R` run identity with `.iter` zeros; `test-nested-final-fit-oracles.R` final-fit identity) — each asserts what the other does not.

## File ledger (AC4)

| File | Disposition | Reason |
|---|---|---|
| `test-fixture-cache.R` | trimmed | the hit-identity, condition-replay, RNG, caller-frame and key-separation blocks fail on a cache defect and stay; the four report and teardown-format blocks test the diagnostic |
| `test-hang-trace.R` | trimmed | the pairing, bracket, wedge, file-end, live-mode and duplicate-description blocks stay; the fixture-directory and planted-duplicate self-tests go |
| `test-suite-hygiene.R` | kept whole | guards the time-budget ledger the scope keeps and the bounded-wait rule (question gate 2026-09-08) |
| `test-ci-workflows.R` | kept whole | the regression test of a defect that reached the default branch (pkgdown deploy hotfix, commit 7ca14b7, PR #17) |
| `test-vignette-citations.R` | deleted | repo-artifact test with no defect on the default branch behind it; skips in a built package (question gate 2026-09-08) |
| `test-drift-manifest.R` | deleted | repo-artifact test of `benchmarks/mori-wire-manifest.json`, no defect on the default branch behind it; `helper-drift-manifest.R` goes with it |
| `test-dots-barrier.R` | kept whole | tests exported behavior: the condition class each entry point raises on an unknown argument (question gate 2026-09-08) |
| `test-control-slots.R` | kept whole | a documented contract read from tune's `formals()` (question gate 2026-09-08) |
| `test-parallel-classify.R` | trimmed | package tests of `R/parallel.R`, not a harness (question gate 2026-09-08): only blocks repeating a sibling's claim go, each in the AC1 table |

## Work log

- 2026-09-07: created by /milestone-plan, from the user's question at M74's plan gate on how many tests are needed. Criteria audit ran in reduced mode (internal tier) on a fresh [O] reader: five findings on AC1–AC5, all fixed — AC3's uncalled test counts a helper's own file (23 helpers are used only there); AC4's planted-defect family replaced by a per-file classification ledger; AC1 records one row per removed description with its survivor and admits a replacing block; AC3's "called" made a grep; AC5 reads one `devtools::test()` rather than the three-run profiler and states 0 unjustified notes.
- 2026-09-08: question gate: `test-parallel-classify.R` read as package tests and deduplicated only; `test-vignette-citations.R` deleted; suite-hygiene, dots-barrier and control-slots kept whole; `test-ci-workflows.R` kept as the regression test of 7ca14b7 (PR #17). T1: removal table written, 15 rows (12 from the scope's tuner list, 3 from an [O] survey of `test-parallel-classify.R`, verified by reading each pair); the `iter = 0` pair kept, each block asserting what the other does not. Branch point `accfbe2` has 795 blocks.
- 2026-09-08: amendment gate (Substantive): AC1 admits no survivor-less removal, which every whole-file deletion and harness self-test trim is, and AC2's 60 is out of reach under the question gate's choices (46 reachable); the user chose to amend both.
- 2026-09-08: re-audit: AC2 (reduced) — nothing; the parenthetical read as provenance for the floor, not a condition.
- 2026-09-08: re-audit: AC1 (reduced) — instrument finding: the proposed text led with "has one row in the removal table", a property of the record, not the suite; the reader's repair leads with the claim-asserted-by-a-survivor property and makes the table the record.
- 2026-09-08: re-audit: AC1 (reduced) — the repaired wording re-entered with a fresh reader: instrument finding on its second sentence (the table clause binds the recording instrument; T1 already mandates the table); this second line is the stop, so the choice between the two repairs goes to the user.
- 2026-09-08: AC2 amended to the audited text above. T2: the 15 removal-table blocks deleted; the partners that asserted less extended (`the final fit returns a trained workflow inside its own object` takes the prediction and mould assertions; race-oracles' AC3 block asserts no `.iter` on the race record; `a real interrupt is an interrupt, not a cancellation` asserts the error by class); the 43 remaining `test-parallel-classify.R` ledger rows re-keyed by a line map and the removed block's row dropped. `devtools::test()` with 6 workers: 786 blocks, 0 failures, 0 skips; `air format --check` clean on the touched files.
- 2026-09-08: AC1 amended to the second reader's wording at the user's choice (the table sentence dropped; the table stays T1's deliverable).
- 2026-09-08: T3: the ledger applied — `test-vignette-citations.R`, `test-drift-manifest.R` and `helper-drift-manifest.R` deleted; four report blocks cut from `test-fixture-cache.R` and two self-tests from `test-hang-trace.R`; one comment in `test-dplyr-compat.R` that named the deleted file trimmed. Nothing in `start-first` or the time-budget ledger keyed to the moved calls. Head count 749 against 795 (46 fewer). `devtools::test()` with 6 workers: 755 blocks, 0 failures, 0 skips; `air format --check` clean on the trimmed files.
- 2026-09-08: T4: the AC3 enumeration (parse tokens over every file under `tests/testthat/`, the defining expression excluded) left two helpers uncalled — `fixture_cache_reset()`, uncalled before this branch, and `expect_outer_columns_kept()`, left by T2 — both removed from `helper-orchestration.R`; 156 helpers remain, none uncalled. `devtools::test()` with 6 workers: 755 blocks, 0 failures, 0 skips.
- 2026-09-08: T5: `devtools::check()` on the head — 0 errors, 0 warnings, 0 notes (7m 16s); `air format --check` clean on every R file the branch diff touches; the description diff against `accfbe2` is 46 removed and none added, matching the removal table's 21 rows plus the 25 descriptions of the two deleted files. Status to review.
- 2026-09-07: plan gate chose a separate pruning milestone over folding it into M74 (see M74's work log); no other alternative weighed here.

## Decisions

## Review
