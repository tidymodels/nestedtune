# M154: The wait ledger finds each call by its test block, so moving a line breaks no test

**Status:** done (2026-10-23, PR #171 https://github.com/tidymodels/nestedtune/pull/171)

**Goal:** Key each row of the `helper-time-budget.R` wait ledger on its file, its enclosing unit and its call, not on its line number.

**Outcome:** Tests and one benchmark script only; no `R/`, help or NEWS change.
- `tb_row()` takes `at` in place of `line`. `payer` is now the exact `test_that()` description (or the top-level function in `helper-parallel.R`); the old hand-written payers were wrong in 8 rows. The 98 rows (not the plan's 106; M152 removed some) were rewritten from the parse tree. The 3 rows outside `BUDGETED_WAIT_CALLS` (two bare `daemons`, the deadline poll) carry `at = NA`.
- `test-suite-hygiene.R` gains `wait_call_key()`, `enclosing_unit()`, `wait_calls()` and `ledger_keys()`. Both accounting guards and the bound re-read match on file, payer and the call's position among its unit's wait calls. The re-read reads the call's parsed text, and `DECLARED_UNCHECKABLE_BOUNDS` holds full keys.
- `benchmarks/test-time-budget.R` prints `#at` and the payer in place of the line. Bounds and per-file totals unchanged.
- DESIGN.md's `air` convention and LESSONS line 29 no longer say the ledger holds `file:line` positions (corrected M154).
- Probes on a scratch copy (script `probes.R`, one package load, `testthat::test_file()` per planted change): a blank line atop all 8 files, 0 failures at the head and 4 at the branch point; 95 single-row deletions, 95 failures naming the row's key; 10 doubled bounds (10 at both ends), 10 bound-check failures. Totals and row counts identical.

**Decisions:** milestone-local: `payer` is the key's unit, read from the parse tree; renaming a test or adding, removing or reordering a wait call in a budgeted file means editing its rows (the plan gate's accepted cost). None promoted.

**Review:** Four-lens fan-out, one pass, no return. 20 findings: 12 fix now (8 unique: the empty-file guard `wait_calls()` lost, the DESIGN bullet, five false comments, one wrong `:760` note, plus 4 duplicates), 3 to the new row "Drop line numbers from test comments", 5 rejected (shared `#NA` key on the bare `daemons` rows, a benchmark indent, AC5 unticked, renumbering `DECLARED_UNCHECKABLE_BOUNDS`, no D-entry). `devtools::check()` 0/0/0; `document()` changed only the roxygen2 version stamp, reverted. The first CI wait hit the tool ceiling; on resume both "CRAN conditions" jobs had been cancelled at their 30-minute cap during a 16-minute dependency install, passed on rerun (9 and 7 min), and the merge was re-approved. The last local tracking commits (PR URL record, CI stop, resume, re-approval) were dropped with the branch by `--delete-branch`; this summary carries them (local reflog 401c9657). Row "Clear two leftovers of the test prune" narrowed (its ledger-label item fixed). No lesson added (LESSONS at 19,856 bytes); none retired; none unparked.
