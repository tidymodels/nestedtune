# M154: The wait ledger finds each call by its test block, so moving a line breaks no test

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** M152
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — a check over the repo's own test files
- **Branch/PR:** m154-wait-ledger-rekey

## Goal

Key each row of the `helper-time-budget.R` wait ledger on its file, its enclosing unit and its call, not on its line number.

## Scope

**In:**
- Each of the 106 `tb_row()` calls names a `file`, a `line` and a `payer`. `test-suite-hygiene.R:99-156` matches rows to call sites by `file:line`. So a comment added above a wait call fails the suite, which the floor calls a defect in the test.
- Replace the `line` key with the enclosing unit and the call's position among the wait calls of that unit. The enclosing unit is the `test_that()` block, or the function for the four `helper-parallel.R` rows. Make `wait_call_sites()` report the same key.
- Re-read the explicit bound argument (`test-suite-hygiene.R:179-300`) by the new key.
- Drop the `line` field from the rows, or keep it as a note that nothing reads.

**Out:**
- The bounds, the per-file totals and the cap checks stay as they are.
- `DECLARED_UNCHECKABLE_BOUNDS` keeps its role and gets the new key.
- Comment cleanup in these files → M155.

## Acceptance criteria

- [ ] AC1: In a scratch copy of the head tree, insert one blank line at the top of each file that the ledger names. `testthat::test_file()` on `test-suite-hygiene.R` then passes.
- [ ] AC2: In a scratch copy, delete one ledger row whose `call` is in `BUDGETED_WAIT_CALLS`. Do it once for each such row, by a script that loops over them. Each run of `test-suite-hygiene.R` fails, and the failing expectation names that row's call site.
- [ ] AC3: Take the ledger rows whose `call` is `daemons_load_status` or `collect_bounded`, whose `seconds` is above 0, and that `DECLARED_UNCHECKABLE_BOUNDS` does not list. This set, computed from the ledger, has the same size at the branch point and at the head. In a scratch copy, double the explicit bound argument of one such call. A script does this once for each row of the set. Each run fails on the bound check for that row.
- [ ] AC4: `time_budget_totals()` returns the same file, seconds and count for every file at the branch point and at the head.
- [ ] AC5: The profile's `verify` slot is clean at the head.

## Coverage

- AC1 → T2, T4
- AC2 → T1, T2, T4
- AC3 → T3, T4
- AC4 → T1, T4
- AC5 → T5

## Tasks

- [x] T1: Record the branch point and save `time_budget_totals()` there.
- [x] T2: Change `tb_row()`, the rows and `wait_call_sites()` to the new key. Change both accounting guards in `test-suite-hygiene.R`.
- [x] T3: Change the bound re-read and `DECLARED_UNCHECKABLE_BOUNDS` to the new key.
- [x] T4: Write the three probe scripts in the scratchpad and run them. Compare `time_budget_totals()`, and write the results to the work log (the Review section is review's alone).
- [x] T5: Run the `verify` slot.

## Work log

- 2026-10-21: created by /milestone-plan.
- 2026-10-21: tier check: milestone — a change to the suite's own guard that needs its own discrimination probes.
- 2026-10-21: idea vet: found no concern.
- 2026-10-21: plan gate chose keying each row on its enclosing unit and call position over one counted bound per file, because it keeps per-row bounds and the explicit-bound re-read; falsified by a reorder of wait calls inside one block that fails the guard.
- 2026-10-21: depends on M152, because M152 deletes and merges wait calls in the parallel files, which changes the ledger's rows.
- 2026-10-21: criteria audit (reduced, fresh Opus reader): three findings, all fixed. The row count is 106, not 107; the four `helper-parallel.R` rows key on their function; AC2's domain is the rows whose `call` is in `BUDGETED_WAIT_CALLS`; AC3's domain is computed from the ledger and has the same size at both ends.
- 2026-10-22: implement started; branch m154-wait-ledger-rekey cut from main at 5bae6873, the branch point.
- 2026-10-22: T1 done. Saved `time_budget_totals()` and the ledger at 5bae6873 to the scratchpad. The ledger has 98 rows, not the plan's 106, because M152 removed rows after the plan counted them; 95 of them name a call in `BUDGETED_WAIT_CALLS`.
- 2026-10-22: found that `payer` is a hand-written paraphrase of the test name, and wrong in 8 rows (6 detection rows name a neighbouring test, 2 required-pkgs rows sit in a local `attached()` function). Decided: `payer` becomes the exact `test_that()` description, read from the parse tree, or the top-level function name in `helper-parallel.R`; the key is file, payer, and the call's position among the wait calls of that unit.
- 2026-10-22: T2 and T3 done in one commit, because the bound re-read looks calls up by the row key and cannot keep line numbers once the rows drop them. `tb_row()` takes `at` in place of `line`; the 98 rows were rewritten from the parse tree by a scratchpad script, and the three rows whose call no guard sees (two bare `daemons`, the deadline poll) carry `at = NA`. New helpers in `test-suite-hygiene.R`: `wait_call_key()`, `enclosing_unit()`, `wait_calls()`, `ledger_keys()`. The bound re-read reads the call's parsed text, not whole source lines. `benchmarks/test-time-budget.R` prints `#at` and the payer in place of the line. The full suite passed and `air format --check .` was clean.
- 2026-10-22: note for M155: test names are now part of the ledger key, so renaming a `test_that()` block in the eight budgeted files means editing its ledger rows' `payer` too; the guards fail and name the row if that is missed.
- 2026-10-22: minor amendment: T4 wrote its results to the Review section, which the rulebook gives to review alone; it writes them here instead.
- 2026-10-22: T4 done. One scratchpad script (`probes.R`) runs all three probes on a `git archive` copy of 8fd3a459, loading the package once and running `test-suite-hygiene.R` through `testthat::test_file()` after each planted change. AC1: a blank line atop the 8 files gave 0 failures of 29 expectations at the head, and 4 failures (both accounting guards and both bound checks) at 5bae6873. AC2: 95 rows deleted one at a time, 95 runs failed with the deleted row's key in the message. AC3: set size 10 at 5bae6873 and at the head; 10 bounds doubled one at a time, 10 runs failed on that row's bound check. AC4: `time_budget_totals()` plus the per-file row count is identical to the 5bae6873 copy.
- 2026-10-22: T5 done. The `verify` slot ran on the tree that 8fd3a459 commits: `devtools::test()` clean, `air format --check .` clean (air 0.12.0). No roxygen, `R/`, vignette or README change, so `document()` and the prose sweep do not apply. T4 changed no code.

## Decisions

## Review
