# M155: Test comments and test names state only what the code cannot show

**Status:** done (2026-10-23, PR #172 https://github.com/tidymodels/nestedtune/pull/172)

**Goal:** Bring the comments and the test names of every file under `tests/testthat/` to the rulebook's test-comment rule.

**Outcome:** Tests, two new benchmark scripts and five `R/` comments; no help or NEWS change.
- Comments in all 119 test, helper and teardown files and `tests/testthat.R` lost milestone, decision, review, criterion and principle ids, dates, PR and run numbers, oracle-type labels and "used to" history; seven ledger `note` strings lost "(M14)"/"(M50)". Eight Haiku subagents and one more for `helper-orchestration.R` did the test files under one spec; each diff was read, and about 40 rewrites corrected before review.
- 354 `test_that()` names lost their id prefixes in one scripted pass, with 10 snapshot headers and 21 ledger `payer` strings renamed to match; map in `benchmarks/test-renames-576c3d19.csv`.
- `benchmarks/sweep-test-comments.R` reads every `COMMENT` token and ledger note, asserts its file list equals the glob, plants one case per id kind, and with `--names` checks a `test-blocks.R` table. `benchmarks/test-renames-check.R` joins two block tables through the map and compares snapshot sections and svg bytes.
- Block tables kept: `test-blocks-576c3d19.csv` (branch point), `-beb6320b.csv`, `-67d84ed0.csv` (review head): 1153 blocks and 13367 expectations at both ends, 0 mismatches.
- `R/parallel.R`, `R/nested-workflow-map.R`, `R/nested-results.R` and `benchmarks/rsample-283-reprex.R` no longer cite tests by the removed `AC`/`BC` labels or a moved line. DESIGN.md's oracle-records convention says the headers carry source and pinning test, no ID or type (corrected M155).

**Decisions:** milestone-local: the sweep also matches principle ids and single-letter review/oracle/task ids (less `S3`, `S4`, `S7`, `R6`); names were renamed centrally rather than per file group. None promoted.

**Review:** Four-lens fan-out, one pass, no return. 52 findings: 30 fixed on the branch (four comments made false by the rewrite, stale line citations the cleanup moved, `R/` references to removed labels, leftover review references, script gaps, the DESIGN convention), 21 rejected (mostly planned history removal; two false), 13 to rows: new "Keep an oracle registry outside tests" and "Clear tracking words from test code", "Drop line numbers from test comments" extended, "Clear two leftovers of the test prune" unchanged. M152 row pruned for the ROADMAP line cap; four parked rows compressed for its byte budget. `devtools::check()` 0/0/0. On CI the `R-CMD-check-hard.yaml` ubuntu job was cancelled at its 30-minute cap inside `setup-r-dependencies` (as M154's CRAN jobs were) and passed on rerun. The last local tracking commits (PR URL record, CI stops, conversation read) were dropped by `--delete-branch`; this summary carries them. No lesson added (LESSONS at 19,856 bytes); none retired; none unparked.
