# M156: Test code cites no line numbers and names no tracking records

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — test comments, test identifiers and names, two `R/` code comments and one benchmark comment; no exported behavior, help page or NEWS changes
- **Branch/PR:** m156-test-tracking-leftovers

## Goal

Clear the tracking leftovers that M152, M154 and M155's reviews filed against the test code, as the candidate row "Clear tracking leftovers from test code" lists them.

## Scope

**In:**
- Line-number citations. Each comment citation AC1's grep finds names the call, block or test it means instead: `test-event-level.R` (`R/nested-final-fit.R:106-118`), `test-parallel-metrics.R` (`test-parallel-identity.R:12-13`), `test-suite-hygiene.R` (`R/parallel.R:91`), the four notes in `helper-time-budget.R` (classify `:687`/`:693`, `:165`/`:167`/`:172`, `:51`/`:54`, `:48`), `R/nested-results-plot.R` (`R/nested-results-print.R:229`), and `R/parallel.R` (`rehydrate_payload` at `:232`, `nested_fold_fit` at `:585`). Also `benchmarks/probe-mori-dispatch.R`'s `helper-parallel.R:52`.
- Tracking ids in identifiers: `PRINT_AS_AGREED_M46` (`test-nested-final-fit-print.R`), `ac1_control()` (`helper-orchestration.R` and its four callers), `CLASSIFY_BUDGET_PRE_M16_S` (`helper-time-budget.R` and `benchmarks/test-time-budget.R`). Each gets a name that says what the value is.
- History in three test names: "the branch point" (`test-workflow-identity.R`), "pre-milestone" (`test-parallel-payload.R`), "used to emit" (`test-nested-results-print.R`). None has a snapshot section or a `helper-time-budget.R` ledger row (grep, 2026-10-23).
- "criterion" in the 11 test comments that use it (`test-control-slots.R`, `test-dots-barrier.R`, `test-dplyr-compat.R`, `test-nested-final-fit-print.R`, `test-nested-results-print.R`, `test-nested-tune-sim-anneal-checks.R`, `test-parallel-identity.R`), and "criteria" in two comments (`test-dplyr-compat.R`, `test-help-structure.R`) and one test name (`test-workflow-identity.R`, "as the criteria describe", which has no snapshot section or ledger row): each states the property in its own words.
- `R/parallel.R`: the `workflow_pkgs()` comment names `test-parallel-interrupt.R` and `test-parallel-payload.R` as the files that drive `dispatch_folds()` with stand-in payloads, in place of `test-parallel-detection.R`. The `.args` comment's 25,714,635 B and 4,701,505 B, which `test-parallel-payload.R` does not hold, give way to what that file asserts.
- Seed-identity assertions that cannot show a fold did not run, since the shared driver restores the caller's RNG state on exit (`restore_rng()` in `R/nested-tune-grid.R`): both in `test-nested-fit-resamples-checks.R` and the one in `test-nested-workflow-map-checks.R`, with the first file's comment claiming they do and the `before <- .Random.seed` lines they read. The block "the refusals fire before the RNG is drawn from" asserts each of its three refusals by class, or goes where other tests assert those classes. Two test names in that file that promise "before any fold runs" or "before the RNG is drawn from" drop that clause, since nothing checks it after the removal.

**Out:**
- `M<NNN>` ids in `R/*.R` comments (about 290): new candidate row "Clear milestone ids from R comments".
- The fixture generator name `fixtures/make-branch-point-results.R` and its commit header: fixture provenance, which the test-comment rule allows.
- `test-resample-weights.R`'s "lines 51-54" of `deparse()` output from tune functions: they cite tune's code as deparsed, not a repo file.
- Other `file:line` citations in `benchmarks/` (`probe-mori-dispatch.R` beyond `:112`, `probe-daemon-orphans.R`, `rsample-283-reprex.R`): dated probe scripts, not test code; they stay.
- The other `R/parallel.R` byte figures (the 202,363 B closure, the 5,141,166 B payload): not named by the row; `test-parallel-payload.R` holds the second.
- A new check in `benchmarks/sweep-test-comments.R` for line citations or tracking words: not built (Work log).

## Acceptance criteria

- [ ] AC1: ``grep -nE '#.*([A-Za-z_`]|[ (]):[0-9]{2,}' tests/testthat/*.R R/*.R`` and `grep -n 'helper-parallel.R:' benchmarks/probe-mori-dispatch.R` print nothing.
- [ ] AC2: `grep -nwE '[A-Za-z_]*_M[0-9]{2,3}[A-Za-z0-9_]*|ac[0-9]+_[a-z_]+' tests/testthat/*.R benchmarks/*.R` prints nothing.
- [ ] AC3: `grep -niwE 'criteri(on|a)' tests/testthat/*.R` and `grep -nE 'test_that\("[^"]*(branch point|pre-milestone|used to emit)' tests/testthat/*.R` print nothing.
- [ ] AC4: In `R/parallel.R`, the comment above `workflow_pkgs()` names `test-parallel-interrupt.R` and `test-parallel-payload.R` and not `test-parallel-detection.R`, and the `.args` comment in `dispatch_folds()` states either no byte figure or only figures that appear verbatim in `test-parallel-payload.R` (`grep -F`).
- [ ] AC5: `grep -n 'Random\.seed' tests/testthat/test-nested-fit-resamples-checks.R` and `grep -n 'before <- \.Random\.seed' tests/testthat/test-nested-workflow-map-checks.R` print nothing, and the block "the refusals fire before the RNG is drawn from" either passes `class =` to each of its three `expect_error()` calls or is removed with the work log naming the test that asserts each class.
- [ ] AC6: The `verify` slot is clean: `devtools::test()` with 0 failures, `air format --check .`, and `Rscript benchmarks/sweep-prose.R --plain`; `Rscript benchmarks/sweep-test-comments.R` and `Rscript benchmarks/test-time-budget.R` exit 0.

## Coverage

- AC1 → T1
- AC2 → T3
- AC3 → T4
- AC4 → T2
- AC5 → T5
- AC6 → T6

## Tasks

- [x] T1: Rewrite the line citations Scope In lists to name the call, block or test; run AC1's greps.
- [x] T2: Fix the two `R/parallel.R` comments (stand-in payload files; `.args` byte figures, read against `test-parallel-payload.R`'s assertions); run `air format --check .` and the prose sweep.
- [x] T3: Rename `PRINT_AS_AGREED_M46`, `ac1_control()` and `CLASSIFY_BUDGET_PRE_M16_S` at every site the AC2 grep lists; run AC2's grep.
- [ ] T4: Rename the three test names; grep `tests/testthat/_snaps/` and `helper-time-budget.R` for the old names first; rewrite the 11 "criterion" comments and the three "criteria" sites; run AC3's greps.
- [ ] T5: Remove the seed-identity assertions, their `before` lines and the comment that vouches for them; give "the refusals fire before the RNG is drawn from" its condition classes, or remove it where other tests assert the same classes (name them in the work log); drop the unchecked "before ..." clause from the two test names, grepping `_snaps/` and `helper-time-budget.R` for the old names first; run AC5's greps.
- [ ] T6: Run the `verify` slot, `benchmarks/sweep-test-comments.R` and `benchmarks/test-time-budget.R`.

## Work log

- 2026-10-23: created by /milestone-plan.
- 2026-10-23: tier check: not run — work named at the question set.
- 2026-10-23: question set: what to plan — the test-code cleanup, joining three candidate rows; queue a second milestone — no, one milestone only.
- 2026-10-23: idea vet: no concern; the edits change no package behavior, follow the rulebook's test-comment rule, and the removed seed assertions are vacuous because the driver restores the caller's RNG state (`restore_rng()`; D-011).
- 2026-10-23: collision sweep: absorbs the rows "Clear two leftovers of the test prune", "Drop line numbers from test comments" and "Clear tracking words from test code" in full, merged into one row "Clear tracking leftovers from test code" to fit the ROADMAP's 60-line and 24,000-byte caps; extends M152, M154 and M155 (archived); no D-entry matched; inbox: 1 open issue (#91, docs), 0 open PRs, no overlap.
- 2026-10-23: plan gate chose plain edits checked by the AC greps over extending `benchmarks/sweep-test-comments.R` to catch line citations and tracking words, because hardening a checker an earlier milestone shipped is the checker-regress shape and the greps settle this milestone's sites; falsified by the same leftovers reappearing in test code after this merge.
- 2026-10-23: plan gate chose to remove the vacuous seed assertions over replacing them with `last_dispatch()` checks everywhere, because the map file already asserts an empty dispatch record and M152 removed the others the same way; falsified by a refusal in `nested_fit_resamples()` that a fold reaches before it fires.
- 2026-10-23: scope note: the second seed-identity block in `test-nested-fit-resamples-checks.R` ("the refusals fire before the RNG is drawn from") is beyond the row's named lines, taken in as the same defect in the same file.
- 2026-10-23: lessons harvested: M33 (resolve each citation to the symbol it names, never repair blind), M154 (renaming a test means editing its ledger rows; none of the three renamed tests has one), M152 (`test-parallel-interrupt.R` fails beside other suites, so run `devtools::test()` alone).
- 2026-10-23: checkpoint: plan committed locally while the reduced criteria audit runs; its result follows in the next line.
- 2026-10-23: criteria audit (reduced mode, fresh Opus reader): AC1 left a universal Scope claim unchecked over `R/*.R` and missed `R/parallel.R:465` and the `classify:687` form, fixed with one comment grep over both trees and the site added; AC3 left "criteria" at 3 sites, added; AC4 "hold" undefined, now verbatim per `grep -F`; AC5 missed the vouching comment and `before` lines and its bare-`expect_error()` clause named no procedure, now two greps and the one named block, and the two test names promising "before" lose that clause; AC6 now exit status; AC2 no finding.
- 2026-10-23: started on branch m156-test-tracking-leftovers, cut from main at defc7c02.
- 2026-10-23: implement decision: comment-only tasks (T1, T2, T4's comments) are checked off on a parse check, `air format --check .` and the prose sweep; files whose code changes (T3, T4's names, T5) run their own test files; the full `devtools::test()` runs once at T6 before review.
- 2026-10-23: T1 done: 10 citations now name the call, block or test (the ledger notes describe the `daemons(0)` calls by role, since their line numbers had drifted; required-pkgs now has two teardowns); AC1's greps print nothing; air, parse and prose sweep clean.
- 2026-10-23: T2 done: the `workflow_pkgs()` comment names test-parallel-interrupt.R and test-parallel-payload.R (both call `dispatch_folds()` with `object = NULL`); the `.args` comment states the under-a-quarter ratio that test-parallel-payload.R asserts, with no byte figure; air, parse and prose sweep clean.
- 2026-10-23: T3 done: `ac1_control()` is `early_stop_control()`, `PRINT_AS_AGREED_M46` is `PRINT_AS_AGREED`, `CLASSIFY_BUDGET_PRE_M16_S` is `CLASSIFY_BUDGET_BEFORE_CUT_S`, and `benchmarks/test-time-budget.R` prints "figure before the cut" in place of "pre-M16"; AC2's grep prints nothing; the three renamed test files pass (38 blocks, 0 failed); `benchmarks/test-time-budget.R` exits 0; `test-parallel-identity.R` runs at T6.
