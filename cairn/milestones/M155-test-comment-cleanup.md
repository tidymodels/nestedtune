# M155: Test comments and test names state only what the code cannot show

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** M151, M152, M154
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — comments and test names in the repo's own test files
- **Branch/PR:** m155-test-comment-cleanup

## Goal

Bring the comments and the test names of every file under `tests/testthat/` to the rulebook's test-comment rule.

## Scope

**In:**
- The rule allows a comment that states what the code cannot show, a one-line citation of a published source, and an issue number. It forbids narrative bug history, worked arithmetic and oracle-type labels.
- Remove milestone, decision, review, criterion and block ids from comment lines. Remove dated measurements, PR and run numbers, and "used to" or "before M" history. Rewrite a comment to the fact it carries. If the code shows that fact, delete the comment.
- Remove the oracle-type header labels of the oracle files, such as `O1 -- type live`.
- Cover every `test-*.R`, `helper-*.R` and `teardown-*.R` file and `tests/testthat.R`.
- A fixture's provenance stays in its generator under `tests/testthat/fixtures/` or `data-raw/`, as the profile requires.
- Strip the same ids from the `test_that()` descriptions, at the user's choice at the plan gate. Re-record the snapshots under the new names, and keep a map from each old name to its new name.
- Rename the blocks that `helper-time-budget.R` names as `payer` in the same commit. After M154 the guard keys on them, so the `verify` slot fails on a missed one.
- Strip the same ids from the `note` strings of the `tb_row()` calls in `helper-time-budget.R`.

**Out:**
- Comments in `R/` and in `benchmarks/` are outside the rule.
- Test code stays as it is. Superfluous tests → M152.

## Acceptance criteria

- [ ] AC1: At the head, `benchmarks/sweep-test-comments.R` reads every `COMMENT` token that `getParseData()` gives for its files, and every `note` string of a `tb_row()` call. None matches its pattern. Its file list equals `Sys.glob()` of `tests/testthat/{test,helper,teardown}-*.R` plus `tests/testthat.R`, and the script asserts that equality. The pattern matches milestone, decision, review, report, criterion and block ids, a `YYYY-MM-DD` date, a run number, and an oracle-type label. It matches a PR number only in the form "PR #N", so that a bare `#N` issue citation passes. The script flags a planted milestone id and stays silent on a planted `#123`.
- [ ] AC2: At the head, no value in the `test` column of the `benchmarks/test-blocks.R` table matches the script's pattern. The names are unique within each file.
- [ ] AC3: Join the `benchmarks/test-blocks.R` tables of the branch point and the head on file and test name, through the rename map. A name absent from the map maps to itself. Every branch-point row is at the head with the same expectation count, and the head has as many rows as the branch point.
- [ ] AC4: Split each `tests/testthat/_snaps/*.md` file at both trees into its `# name` sections. Every branch-point section is at the head under its mapped name with an identical body, and the head has no other sections. Every `.svg` file under `_snaps/` is byte-identical at both trees.
- [ ] AC5: The profile's `verify` slot is clean at the head.

## Coverage

- AC1 → T1, T2, T3, T4
- AC2 → T3, T4, T5
- AC3 → T5
- AC4 → T5
- AC5 → T6

## Tasks

- [x] T1: Write `benchmarks/sweep-test-comments.R`, with its planted cases. Run it on the branch point, and record the match count per file.
- [x] T2: Clean the helper and teardown files.
- [x] T3: Clean the driver, results, final-fit and readers test files, through Haiku subagents with a full spec, one file group each.
- [x] T4: Clean the parallel, time-series and remaining test files the same way. Read every subagent diff before it is committed.
- [x] T5: Run `benchmarks/test-blocks.R` at the head and compare with the branch point through the rename map. Compare each snapshot entry's body under its old and new names.
- [ ] T6: Run the `verify` slot.

## Work log

- 2026-10-21: created by /milestone-plan.
- 2026-10-21: tier check: milestone — a mechanical edit across about 130 files, more than one sitting.
- 2026-10-21: idea vet: found no concern.
- 2026-10-21: question set: should the cleanup reach test names — yes, comments and test names, with the snapshots re-recorded under the new names.
- 2026-10-21: depends on M151, M152 and M154, so that no deleted test is cleaned first, and the renamed blocks meet M154's new ledger key.
- 2026-10-21: criteria audit (reduced, fresh Opus reader, two passes): first pass, two findings fixed (the sweep reads `COMMENT` tokens, and its planted cases include a silent issue number). Second pass, after the gate added test names: four findings fixed. The file list must equal the glob; names are checked on `test-blocks.R`'s realized `test` column, since twelve are built with `sprintf()` or `paste0()`; AC3 counts rows instead of binding the map; AC4 runs both ways and covers the `.svg` files. The ledger's `note` strings joined the scope.
- 2026-10-22: implement started; branch m155-test-comment-cleanup cut from 576c3d19.
- 2026-10-22: choice: the sweep pattern also matches principle ids (`IP`/`GP`) and single-letter review, oracle, task and question ids (`B F O P Q R S T` and digits, less `S3`, `S4`, `S7`, `R6`), since each is cairn vocabulary a test reader cannot resolve; a `--names` mode checks a `test-blocks.R` table for AC2.
- 2026-10-22: T1 done: `benchmarks/sweep-test-comments.R` at the branch point, `--counts`: 1200 matching lines in 111 of 119 files (7399 comments, 66 ledger notes); largest helper-orchestration.R 122, test-parallel-classify.R 53, test-parallel-identity.R 52, helper-time-budget.R 31, test-nested-tune-grid-oracles.R 31; planted cases shown red by editing them in a copy.
- 2026-10-22: minor amendment: the test names are renamed in one scripted pass across all files at the start of T3, since a name also lives in its snapshot header and the ledger's `payer`; the subagents of T3 and T4 then clean comments only. Rule: drop a leading id prefix (`AC1: `, `M126 AC4: `) and an id-only parenthetical; six names fixed by hand. 354 names renamed (348 literal, six built by `paste0()` over `MAP_FNS`), 10 snapshot headers, 21 ledger `payer` strings; map in `benchmarks/test-renames-576c3d19.csv`; suite-hygiene passes.
- 2026-10-22: T2 done: the helper and teardown files other than helper-orchestration.R cleaned by hand; helper-orchestration.R (about 120 hits) delegated to a ninth Haiku subagent under the same spec. The ledger's seven id-bearing `note` strings lost their ids.
- 2026-10-22: delegation: eight Haiku subagents cleaned the test files in groups (tune-grid and resamples; other tuners, fit-resamples and map; final fit; results and readers; parallel; time-series; remaining A-H; remaining H-Z), one spec in the session scratchpad. Each diff read before commit; about 40 comments corrected after review (stale "four files" claims, an unverified mutation claim, leftover "this milestone" and milestone-file pointers, oracle-type labels kept as "Reference implementation." or "Closed form." now "Source:", over-long lines).
- 2026-10-22: T3, T4 done: sweep clean on all 119 files and 66 ledger notes; a parse-data comparison against 1e07e23c shows no non-comment token changed in any test file except the seven ledger notes; air clean.
- 2026-10-22: T5 done: `benchmarks/test-blocks.R` at both trees, 1153 blocks each, 13367 expectations each, 0 failed, skipped or errored; `benchmarks/test-renames-check.R` (new) finds 0 mismatches over 1153 blocks, 22 snapshot sections in 10 files and 8 svg files; a map with the final-fit-print rows removed gives 17 mismatches. `sweep-test-comments.R --names` silent on the head table. Branch-point table kept as `benchmarks/test-blocks-576c3d19.csv`.

## Decisions

## Review
