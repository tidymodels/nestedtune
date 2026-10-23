# M155: Test comments and test names state only what the code cannot show

- **Status:** review
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

- [x] AC1: At the head, `benchmarks/sweep-test-comments.R` reads every `COMMENT` token that `getParseData()` gives for its files, and every `note` string of a `tb_row()` call. None matches its pattern. Its file list equals `Sys.glob()` of `tests/testthat/{test,helper,teardown}-*.R` plus `tests/testthat.R`, and the script asserts that equality. The pattern matches milestone, decision, review, report, criterion and block ids, a `YYYY-MM-DD` date, a run number, and an oracle-type label. It matches a PR number only in the form "PR #N", so that a bare `#N` issue citation passes. The script flags a planted milestone id and stays silent on a planted `#123`.
- [x] AC2: At the head, no value in the `test` column of the `benchmarks/test-blocks.R` table matches the script's pattern. The names are unique within each file.
- [x] AC3: Join the `benchmarks/test-blocks.R` tables of the branch point and the head on file and test name, through the rename map. A name absent from the map maps to itself. Every branch-point row is at the head with the same expectation count, and the head has as many rows as the branch point.
- [x] AC4: Split each `tests/testthat/_snaps/*.md` file at both trees into its `# name` sections. Every branch-point section is at the head under its mapped name with an identical body, and the head has no other sections. Every `.svg` file under `_snaps/` is byte-identical at both trees.
- [x] AC5: The profile's `verify` slot is clean at the head.

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
- [x] T6: Run the `verify` slot.

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
- 2026-10-22: T6 done: `devtools::test()` at beb6320b, 1153 blocks, 0 failed, 0 errored, 0 skipped, no snapshot file written; `air format --check .` clean; no `R/`, `vignettes/`, `README.Rmd` or roxygen change, so the prose sweeps and `document()` are not owed. Head table kept as `benchmarks/test-blocks-beb6320b.csv`.
- 2026-10-22: claim audit: not owed — internal tier.
- 2026-10-22: implement done; status review.

## Decisions

## Review

- AC1 evidence (2026-10-22, 53519dfb): `Rscript benchmarks/sweep-test-comments.R` exits 0 and prints nothing; `--counts` reads 7222 comments and 66 ledger notes in 119 files, 0 matches. The glob of `tests/testthat/{test,helper,teardown}-*.R` plus `tests/testthat.R` is 119 files, and the script stops unless its `list.files()` list equals that glob. Planted cases run fresh: a copy with `M12` added to the quiet `#123` case halts, a copy with the planted `M155` changed to `#155` halts, and a `# planted M12 id` line appended to `test-argument-order.R` is reported (`M12`) with exit 1. The pattern in the script header covers milestone, decision, review and report, finding/oracle/task/question ids, criterion (`AC`, `BC`) and principle ids, `YYYY-MM-DD`, `run` plus five or more digits, `PR #N`, and `-- type "`.
- AC1 re-run (2026-10-22, 67d84ed0, after the review's fixes): the sweep, now also matching review ids in words and planting one case per id kind, exits 0 on the 119 files; a copy without the review-words branch halts on its planted case.
- AC2 evidence (2026-10-22, 67d84ed0): `Rscript benchmarks/test-blocks.R` at the head writes `benchmarks/test-blocks-67d84ed0.csv`, 1153 rows; `sweep-test-comments.R --names` on it exits 0 with no line, so no `test` value matches the pattern and no name repeats within a file. The same mode on the branch-point table prints 354 names.
- AC3 evidence (2026-10-22, 67d84ed0): `Rscript benchmarks/test-renames-check.R 576c3d19 benchmarks/test-blocks-576c3d19.csv benchmarks/test-blocks-67d84ed0.csv benchmarks/test-renames-576c3d19.csv` reports 1153 blocks before and after and 0 mismatches: every branch-point row is at the head under its mapped name with the same expectation count (and the same failed, skipped and error values), no two map rows share a new name, and both tables hold 1153 rows. A copy of the map without the test-nested-final-fit-print.R rows gave 17 mismatches.
- AC4 evidence (2026-10-22, 67d84ed0): the same run splits the 10 `_snaps/*.md` files at both trees into 22 sections; each branch-point section is at the head under its mapped name with an identical body, none is added or repeated, and the 8 `.svg` files are the same set and byte-identical (blob bytes from `git cat-file`). Appending one byte to an svg gave "svg differs".
- AC5 evidence (2026-10-22, 67d84ed0): `devtools::test()` 1153 blocks, 0 failed, 0 errored, 0 skipped, no snapshot written; `air format --check .` clean; `R/` comments changed, so `sweep-prose.R --plain` run, exit 0; no roxygen change, so `document()` and `--roxygen --plain` not owed (document() run at the gate anyway).
- snapshot: tests/testthat/_snaps/extract-procedure.md — section headers renamed through the map, bodies unchanged (AC4); the Scope's rename calls for it, no finding.
- snapshot: tests/testthat/_snaps/nested-final-fit-print.md — same: headers renamed, bodies unchanged; called for, no finding.
- snapshot: tests/testthat/_snaps/nested-results-print.md — same: headers renamed, bodies unchanged; called for, no finding.
- snapshot: tests/testthat/_snaps/nested-workflow-map-readers.md — same: headers renamed, bodies unchanged; called for, no finding.
- snapshot: tests/testthat/_snaps/nested-workflow-map-verbose.md — same: headers renamed, bodies unchanged; called for, no finding.
- gate (2026-10-22, bad60ff0): `cairn_validate.py` exit 0 (18 references-staleness advisories, unrelated); no principle changed, `cairn_impact` skipped; `devtools::document()` diff only `Config/roxygen2/version` 8.1.0 → 8.1.1 from the local roxygen2 8.1.1, reverted, not this branch's; `pkgdown::check_pkgdown()` no problems; the six gating prose sweeps exit 0.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: `cairn/DESIGN.md` Conventions names the test headers as the oracle record "by ID, type", which the branch removed — fix now, fixed 67d84ed0 (convention corrected in place, marked corrected M155) and follow-up for the registry itself (row "Keep an oracle registry outside tests").
- diff-bug #2: test-nested-tune-grid-results.R says `has_results_columns()` names the seed columns; it does not, `record_columns()` does — fix now, fixed 67d84ed0.
- diff-bug #3: test-workflow-identity.R says the fixture predates the identity; its generator says it predates case weights and the postprocessor — fix now, fixed 67d84ed0.
- diff-bug #4: helper-time-budget.R calls classify the file with the largest declared wait; the ledger totals say identity 960 s, detection 780 s, classify 228.7 s — fix now, fixed 67d84ed0.
- diff-bug #5: test-dplyr-compat.R states the help page promises the opposite, in the present tense — fix now, fixed 67d84ed0.
- diff-bug #6: line citations the branch moved: helper-time-budget.R classify :691/:697 (now :687/:693), metrics :50/:53 (now :51/:54), test-parallel-metrics.R identity :11-13 (now :12-13) — fix now, fixed 67d84ed0.
- diff-bug #7: test-metrics-argument.R says deleting the argument would leave the suite green, which the sep_* tests contradict — fix now, fixed 67d84ed0.
- diff-bug #8: test-nested-tune-grid-checks.R "Before this" left with no referent — fix now, fixed 67d84ed0.
- diff-bug #9: "Closed form from theory." oracle-type label kept in test-nested-fit-resamples-oracles.R — fix now, fixed 67d84ed0.
- diff-bug #10: helper-orchestration.R names "the third oracle", which no header numbers now — fix now, fixed 67d84ed0.
- diff-bug #11: test-eval-time.R "Pinned by" names match no test — fix now, fixed 67d84ed0.
- diff-bug #12: the files no longer say which records are the two independent types — follow-up (row "Keep an oracle registry outside tests").
- diff-bug #13: review references in words left (test-selection-rule.R four, test-nested-tune-grid-checks.R, test-parallel-identity.R, test-dplyr-compat.R) — fix now, fixed 67d84ed0, and the sweep now matches them; "the criterion" in about ten comments and history in three test names — follow-up (row "Clear tracking words from test code").
- diff-bug #14: narrative history left — fix now, fixed 67d84ed0, for test-split-checks.R, test-nested-tune-grid-failures.R, test-vctrs-compat.R, test-parallel-classify.R ("39 minutes"); reject for the mutation note in test-parallel-classify.R and the planted-leak note in test-nested-fit-resamples-oracles.R (false: each states the evidence that the check can fail, which the code cannot show).
- diff-bug #15: test-id-columns.R "the form that gives a wrong label" reads as current behavior — fix now, fixed 67d84ed0.
- diff-bug #16: sweep gaps — fix now, fixed 67d84ed0, for review ids in words (b) and one planted case per id kind (f); reject (planned change: AC1 fixes the forms the pattern must match, and each is matched) for other oracle-label phrasings (a), case and spacing variants (c), and the data-date rewording (d); reject (false) for "PR N" being a superset (e, harmless); reject (planned change) for `--names` reading a table (g).
- diff-bug #17: rename-check gaps — fix now, fixed 67d84ed0, for svg byte identity and added svg files (a), failed/skipped/error columns (b), duplicate new names (c), repeated snapshot names (e); reject (planned change: AC4 reads the working head, and the head table is rebuilt at review) for (d).
- diff-bug #18: identifiers keep ids (`ac1_control`, `CLASSIFY_BUDGET_PRE_M16_S`, `PRINT_AS_AGREED_M46`) — follow-up (row "Clear tracking words from test code"); test code was out of scope.
- diff-bug #19: minor wording — fix now, fixed 67d84ed0, for test-hang-trace.R (cause inverted) and test-nested-tune-sim-anneal-checks.R ("The falsifier"); reject (planned change) for helper-cran.R's dropped milestone pointer; reject (style) for "blocks" in test-dplyr-compat.R.
- diff-bug #20: the review's `R/` comment edits need a reason — noted: they are ripple #4-#7 fixes, comment-only.
- blame-history #1: oracle-type audit trail removed — follow-up (row "Keep an oracle registry outside tests").
- blame-history #2: teardown-fixture-cache.R's no-log claim lost its evidence — fix now, fixed 67d84ed0 ("verified with a two-file fixture").
- blame-history #3: the kill test's mutation evidence removed — reject (planned change: history; the reason stays in present form).
- blame-history #4: summing convention lost "(M16 plan gate)" — reject (planned change).
- blame-history #5: helper-time-budget.R :691/:697 stale — fix now, fixed 67d84ed0 (as diff-bug #6).
- blame-history #6: regression header lost "each test fails against the implementation as it stood" — reject (planned change: narrative bug history).
- blame-history #7: incident records (dates, PR #13, run number) removed — reject (planned change).
- blame-history #8: helper-cran.R lost the pointer to the milestone record — reject (planned change).
- blame-history #9: test-hang-trace.R lost the rejected occurrence-counter alternative — reject (planned change: history).
- blame-history #10: observed crashes in test-dplyr-compat.R now conditional — reject (planned change: dated measurements).
- blame-history #11: test-ci-workflows.R lost the never-executed history — reject (planned change).
- blame-history #12: test-suite-hygiene.R "established by running them" vaguer — reject (planned change).
- blame-history #13: test-suite-hygiene.R cites `R/parallel.R:91` — follow-up (row "Drop line numbers from test comments").
- blame-history #14: decision and principle links removed — reject (planned change).
- blame-history #15: "unleaned"/"leaned" wording — reject (style); identifiers with ids — follow-up (row "Clear tracking words from test code").
- prior-review #1: line citations the branch moved — fix now, fixed 67d84ed0 (as diff-bug #6).
- prior-review #2: the classify ceiling sentence is false — fix now, fixed 67d84ed0 (as diff-bug #4).
- prior-review #3: test-nested-fit-resamples-checks.R's "untouched stream is the evidence that no fold ran" kept — follow-up (row "Clear two leftovers of the test prune", which names it).
- prior-review #4: `R/parallel.R:91` citation kept — follow-up (row "Drop line numbers from test comments").
- prior-review #5: other line citations in touched files — follow-up (same row).
- prior-review #6: identifiers keep ids — follow-up (row "Clear tracking words from test code").
- prior-review #7: test name "print() used to emit" — follow-up (same row).
- prior-review #8: test-nested-final-fit-oracles.R misstates tune's `allow_par` default — reject (false: it says tune's default with `allow_par` off, and the expectation below builds exactly that).
- ripple #1, #2: helper-time-budget.R citations — fix now, fixed 67d84ed0 (as diff-bug #6).
- ripple #3: `benchmarks/rsample-283-reprex.R` cites test-nested-resamples-memory.R:43 for `analytic_size()`, now :36 — fix now, fixed 67d84ed0 (names the function).
- ripple #4: `R/nested-results.R` cites test-vctrs-compat.R's "AC3 block" — fix now, fixed 67d84ed0 (names the block).
- ripple #5: `R/parallel.R` says "the heterogeneous pool AC1 asks for" — fix now, fixed 67d84ed0.
- ripple #6: `R/nested-workflow-map.R` cites "(AC2)" twice — fix now, fixed 67d84ed0.
- ripple #7: `R/parallel.R` "BC1 requires" — fix now, fixed 67d84ed0.
- ripple #8: `R/nested-final-fit.R` "RR02's BC6" — reject (false: it names a review-brief criterion, not a test this branch renamed).
- ripple #9: ROADMAP parked row says "BC6 compares" — fix now, fixed 67d84ed0.
- ripple #10: ROADMAP row says the ledger citations are accurate — fix now, fixed 67d84ed0 (row re-pointed); pre-existing `benchmarks/probe-mori-dispatch.R` and `R/parallel.R` byte-figure citations — follow-up (row "Drop line numbers from test comments").
