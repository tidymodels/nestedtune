# M154: The wait ledger finds each call by its test block, so moving a line breaks no test

- **Status:** review
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

- [x] AC1: In a scratch copy of the head tree, insert one blank line at the top of each file that the ledger names. `testthat::test_file()` on `test-suite-hygiene.R` then passes.
- [x] AC2: In a scratch copy, delete one ledger row whose `call` is in `BUDGETED_WAIT_CALLS`. Do it once for each such row, by a script that loops over them. Each run of `test-suite-hygiene.R` fails, and the failing expectation names that row's call site.
- [x] AC3: Take the ledger rows whose `call` is `daemons_load_status` or `collect_bounded`, whose `seconds` is above 0, and that `DECLARED_UNCHECKABLE_BOUNDS` does not list. This set, computed from the ledger, has the same size at the branch point and at the head. In a scratch copy, double the explicit bound argument of one such call. A script does this once for each row of the set. Each run fails on the bound check for that row.
- [x] AC4: `time_budget_totals()` returns the same file, seconds and count for every file at the branch point and at the head.
- [x] AC5: The profile's `verify` slot is clean at the head.

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
- 2026-10-22: claim audit: not owed — internal tier
- 2026-10-22: all tasks done; status review, handed to /milestone-review.
- 2026-10-22: review checkpoint (in progress): AC1-AC4 evidence recorded and ticked; `cairn_validate` passed; `document()` changed only the roxygen2 version stamp in DESCRIPTION (local 8.1.1), reverted as not this milestone's; six gating prose sweeps exit 0. Waiting on the AC5 suite run, `devtools::check()`, and four reviewers.
- 2026-10-22: four reviewers returned 20 findings (5 duplicates); 10 fixed on the branch in 7a7ae282, 3 to a new candidate row, 6 rejected, none a return. The earlier AC5 suite run was stopped because it predated the fixes; a fresh run on 7a7ae282 is under way.
- 2026-10-22: correction to the line above: of the 20 findings, 12 were settled fix now (7 unique fixes plus 5 duplicates of them), 3 follow-up and 5 rejected, as the Review section lists. AC5 verified on 7a7ae282; `devtools::check()` running.

## Decisions

## Review

Evidence gathered 2026-10-22 on a `git archive` copy of 41e04c07 (code identical to 8fd3a459), by the scratchpad script `probes.R`, which loads the package once from the copy and runs `test-suite-hygiene.R` from it through `testthat::test_file()` after each planted change.

- AC1: a blank line inserted at the top of all 8 files the ledger names (the 7 `test-parallel-*.R` files and `helper-parallel.R`); `test-suite-hygiene.R` ran 29 expectations with 0 failures.
- AC2: the script loops over the 95 ledger rows whose `call` is in `BUDGETED_WAIT_CALLS`, replacing one `tb_row()` call with `NULL` per run. All 95 runs failed, and in each the failure message held the deleted row's key (file, test name, call position and call).
- AC3: the set, computed from each ledger with that commit's own `DECLARED_UNCHECKABLE_BOUNDS`, holds 10 rows at 5bae6873 (ledger loaded from a `git archive` copy) and 10 at the head. The script doubled the `seconds` or `timeout` literal of each of the 10 calls, one per run; all 10 runs failed with an expectation message that opens with that row's key and "declares".
- AC4: `time_budget_totals()` from the 5bae6873 copy and from the head copy is identical in file and seconds for all 8 files (classify 228.678, detection 780, identity 960, interrupt 255, required-pkgs 300, metrics 120, payload 120, helper-parallel 0), and the per-file row counts are identical too (98 rows in all).
- AC5: the `verify` slot at 7a7ae282 (the head after the review fixes; later commits touch `cairn/` only): `air format --check .` exit 0 with air 0.12.0, and `devtools::test()` exit 0 with no Failed, Warnings or Skipped section in its summary. No roxygen, `R/`, vignette or README change, so `document()` and the prose sweep lines of the slot do not apply beyond the gate runs below.

Consistency gate: `cairn_validate.py` exit 0 (18 `references staleness` advisories, none on this milestone's files). `devtools::document()` changed nothing in `man/` or `NAMESPACE`; its one diff was the `Config/roxygen2/version` stamp (local roxygen2 8.1.1 against the recorded 8.1.0), reverted as not this milestone's. The six gating `sweep-prose.R` runs exit 0. No README, pkgdown, `_pkgdown.yml` or new top-level file change; no changelog entry, since the diff changes only tests and a benchmark script, which users do not see. No DESIGN principle changed, so `cairn_impact` was skipped.

spawned: diff-bug, blame-history, prior-review, ripple

- diff-bug #1: `cairn/DESIGN.md:140-143` still says the ledger holds `file:line` positions that a formatting pass must re-point — fix now, fixed 7a7ae282 (same finding: ripple #1, prior-review #2).
- diff-bug #2: `wait_calls()` errors ("arguments imply differing number of rows: 1, 0") on a budgeted file with no wait calls, because the diff dropped the old zero-row return — fix now, fixed 7a7ae282 (same finding: blame-history #1, prior-review #1).
- diff-bug #3: the stale-row comment says a stale row "silently excuses the live call that took its place", which exact key matching rules out — fix now, fixed 7a7ae282 (the comment now says a stale row adds seconds for a call that is gone).
- diff-bug #4: the key comment says swapping two wait calls in a unit fails the guards, false for two calls of the same name — fix now, fixed 7a7ae282 (comment narrowed to two different calls).
- diff-bug #5: `enclosing_unit()` gives `(top level)` for `testthat::test_that()`, `=` and `->` assignment, takes the code text for a `test_that(code =, desc =)` call, and shares one count between two blocks of the same name; the comment named none of this — fix now for the comment, fixed 7a7ae282 (it now states the bare-literal `test_that()` and `<-` rules and the `(top level)` fallback). The shapes themselves stay: the suite uses none, and each gives the same key on the ledger side and the source side, so the guards still decide correctly.
- diff-bug #6: the comment kept by the diff says the bound read "can never read a neighbour's", false for a same-kind wait call nested in the arguments or a bound written in a comment inside the call — fix now, fixed 7a7ae282 (comment states both cases; the suite has neither).
- diff-bug #7: the 45.678 s row's note says the option is set "at :760"; it is set at classify :691 — fix now, fixed 7a7ae282 (note names no line). The other line citations in the helper are accurate today and go to the follow-up below.
- diff-bug #8: the two `daemons` rows share one key (`#NA daemons`), told apart only by `note` — reject, planned change: the plan dropped the line field, and these rows sit outside every guard by design.
- diff-bug #9: the benchmark's "further call(s) classified as no-wait" line keeps its old indent — reject, style.
- diff-bug #10: AC5 unticked while T5 is recorded done — reject, false: review ticks AC5 against its own fresh run, below.
- blame-history #2: `DECLARED_UNCHECKABLE_BOUNDS` no longer survives a wait call added before a declared call in its block — reject, planned change: the plan keyed the list on position, and the plan gate recorded reordering as the accepted cost; the failure is loud.
- blame-history #3: line references remain in helper comments (:44, :335, :789, :815) — follow-up, row "Drop line numbers from test comments" (:335 fixed under diff-bug #7).
- blame-history #4: no DECISIONS.md entry for the keying change — reject, false: the choice is local to the suite and recorded in this file's plan-gate work-log line, where the rulebook puts milestone-local decisions.
- prior-review #3: `test-suite-hygiene.R` cites `R/parallel.R:91` for the production `collect_mirai()`, which sits near :367; stale before this branch — follow-up, row "Drop line numbers from test comments".
- prior-review #4: the remaining line-anchored helper comments will drift now that no key holds lines — follow-up, row "Drop line numbers from test comments".
- ripple #2: `test-parallel-required-pkgs.R:52-53` says the bound is re-read "from this line" — fix now, fixed 7a7ae282 ("from this call").
- LESSONS.md:29 said the ledger is the one test-enforced `file:line` citation set (raised by prior-review #2) — fixed in place, marked corrected M154, 7a7ae282.
