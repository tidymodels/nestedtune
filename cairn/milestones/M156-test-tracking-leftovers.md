# M156: Test code cites no line numbers and names no tracking records

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — test comments, test identifiers and names, two `R/` code comments and one benchmark comment; no exported behavior, help page or NEWS changes
- **Branch/PR:** —

## Goal

Clear the tracking leftovers that M152, M154 and M155's reviews filed against the test code, as the candidate row "Clear tracking leftovers from test code" lists them.

## Scope

**In:**
- Line-number citations. Each `file:line` or bare `:NNN` citation in a comment under `tests/testthat/` or in `R/*.R` names the call, block or test it means instead: `test-event-level.R` (`R/nested-final-fit.R:106-118`), `test-parallel-metrics.R` (`test-parallel-identity.R:12-13`), `test-suite-hygiene.R` (`R/parallel.R:91`), the four notes in `helper-time-budget.R` (classify `:687`/`:693`, `:165`/`:167`/`:172`, `:51`/`:54`, `:48`), and `R/nested-results-plot.R` (`R/nested-results-print.R:229`). Also `benchmarks/probe-mori-dispatch.R`'s `helper-parallel.R:52`.
- Tracking ids in identifiers: `PRINT_AS_AGREED_M46` (`test-nested-final-fit-print.R`), `ac1_control()` (`helper-orchestration.R` and its four callers), `CLASSIFY_BUDGET_PRE_M16_S` (`helper-time-budget.R` and `benchmarks/test-time-budget.R`). Each gets a name that says what the value is.
- History in three test names: "the branch point" (`test-workflow-identity.R`), "pre-milestone" (`test-parallel-payload.R`), "used to emit" (`test-nested-results-print.R`). None has a snapshot section or a `helper-time-budget.R` ledger row (grep, 2026-10-23).
- "criterion" in the 11 test comments that use it (`test-control-slots.R`, `test-dots-barrier.R`, `test-dplyr-compat.R`, `test-nested-final-fit-print.R`, `test-nested-results-print.R`, `test-nested-tune-sim-anneal-checks.R`, `test-parallel-identity.R`): each states the property in its own words.
- `R/parallel.R`: the `workflow_pkgs()` comment names `test-parallel-interrupt.R` and `test-parallel-payload.R` as the files that drive `dispatch_folds()` with stand-in payloads, in place of `test-parallel-detection.R`. The `.args` comment's 25,714,635 B and 4,701,505 B, which `test-parallel-payload.R` does not hold, give way to what that file asserts.
- Seed-identity assertions that cannot show a fold did not run, since the shared driver restores the caller's RNG state on exit (`restore_rng()` in `R/nested-tune-grid.R`): both in `test-nested-fit-resamples-checks.R` and the one in `test-nested-workflow-map-checks.R`, with the first file's comment claiming they do. A block left asserting only bare `expect_error()` calls either asserts each condition class or is removed where another test already asserts that refusal's class.

**Out:**
- `M<NNN>` ids in `R/*.R` comments (about 290): new candidate row "Clear milestone ids from R comments".
- The fixture generator name `fixtures/make-branch-point-results.R` and its commit header: fixture provenance, which the test-comment rule allows.
- `test-resample-weights.R`'s "lines 51-54" of `deparse()` output from tune functions: they cite tune's code as deparsed, not a repo file.
- Other `file:line` citations in `benchmarks/` (`probe-mori-dispatch.R` beyond `:112`, `probe-daemon-orphans.R`, `rsample-283-reprex.R`): dated probe scripts, not test code; they stay.
- The other `R/parallel.R` byte figures (the 202,363 B closure, the 5,141,166 B payload): not named by the row; `test-parallel-payload.R` holds the second.
- A new check in `benchmarks/sweep-test-comments.R` for line citations or tracking words: not built (Work log).

## Acceptance criteria

- [ ] AC1: `grep -nE '[A-Za-z0-9_./-]+\.(R|Rmd|md|ya?ml):[0-9]+' tests/testthat/*.R R/*.R` and `grep -nE '(^|[ (]):[0-9]+' tests/testthat/*.R` print nothing, and `grep -n 'helper-parallel.R:' benchmarks/probe-mori-dispatch.R` prints nothing.
- [ ] AC2: `grep -nwE '[A-Za-z_]*_M[0-9]{2,3}[A-Za-z0-9_]*|ac[0-9]+_[a-z_]+' tests/testthat/*.R benchmarks/*.R` prints nothing.
- [ ] AC3: `grep -niw 'criterion' tests/testthat/*.R` and `grep -nE 'test_that\("[^"]*(branch point|pre-milestone|used to emit)' tests/testthat/*.R` print nothing.
- [ ] AC4: In `R/parallel.R`, the comment above `workflow_pkgs()` names `test-parallel-interrupt.R` and `test-parallel-payload.R` and not `test-parallel-detection.R`, and the `.args` comment in `dispatch_folds()` states no byte count that `test-parallel-payload.R` does not hold.
- [ ] AC5: `grep -nE 'expect_identical\(\.Random\.seed' tests/testthat/test-nested-fit-resamples-checks.R tests/testthat/test-nested-workflow-map-checks.R` prints nothing, and no `test_that()` block in those two files is left whose only expectations are bare `expect_error()` calls.
- [ ] AC6: The `verify` slot is clean: `devtools::test()` with 0 failures, `air format --check .`, and `Rscript benchmarks/sweep-prose.R --plain`; `Rscript benchmarks/sweep-test-comments.R` exits 0, and `Rscript benchmarks/test-time-budget.R` runs to its end with the renamed constant.

## Coverage

- AC1 → T1
- AC2 → T3
- AC3 → T4
- AC4 → T2
- AC5 → T5
- AC6 → T6

## Tasks

- [ ] T1: Rewrite the line citations Scope In lists to name the call, block or test; run AC1's greps.
- [ ] T2: Fix the two `R/parallel.R` comments (stand-in payload files; `.args` byte figures, read against `test-parallel-payload.R`'s assertions); run `air format --check .` and the prose sweep.
- [ ] T3: Rename `PRINT_AS_AGREED_M46`, `ac1_control()` and `CLASSIFY_BUDGET_PRE_M16_S` at every site the AC2 grep lists; run AC2's grep.
- [ ] T4: Rename the three test names; grep `tests/testthat/_snaps/` and `helper-time-budget.R` for the old names first; rewrite the 11 "criterion" comments; run AC3's greps.
- [ ] T5: Remove the seed-identity assertions and the comment that vouches for them; give any block left with bare `expect_error()` calls its condition classes, or remove it where another test asserts the same classes (name that test in the work log).
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
