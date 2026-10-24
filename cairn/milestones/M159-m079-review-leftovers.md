# M159: The snapshot naming is tested where it runs, the hygiene header describes its file, and the interrupt block withstands its failure's cause

- **Status:** in-progress
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — test-suite code and comments under `tests/testthat/`, which no user of the package runs
- **Branch/PR:** m159-m079-review-leftovers

## Goal

Close the three suite findings M079's review left (5, 8, 9) and the `test-parallel-interrupt.R` failure that the same review found inside the parallel suite.

## Scope

**In:** finding 5, a test of `daemon_state_snapshot()`'s naming that drives the snapshot itself rather than `name_by_pid()` alone. Finding 9, the header of `tests/testthat/test-suite-hygiene.R`, which still says the file holds one rule. The block "an interrupted run leaves no fold executing" in `tests/testthat/test-parallel-interrupt.R`, which fails inside full suite runs and passes when its file runs alone: diagnose the cause by execution, fix the block, and make a signal that was never sent fail with its own message. Finding 8 closes at this plan with no code change (work log).

**Out:** a defect in `R/` that the diagnosis finds, such as `dispatch_folds()` losing an interrupt. That is a user-visible bug, so implement stops there and it goes to `/hotfix` (question set). Other daemon blocks that fail when other R sessions run beside the suite (`test-parallel-identity.R`) stay with the M152 line in `cairn/LESSONS.md`.

## Acceptance criteria

- [ ] AC1: A block in `tests/testthat/test-suite-hygiene.R` calls `daemon_state_snapshot()` and asserts that each record it returns is named by the pid that record carries. The block fails when `daemon_state_snapshot()` returns its answers without passing them through `name_by_pid()`, and passes, unskipped, on the helper as the branch leaves it.
- [ ] AC2: The comment at the head of `tests/testthat/test-suite-hygiene.R` no longer says the file holds one rule, and for each line that `grep -n '^test_that(' tests/testthat/test-suite-hygiene.R` lists at the branch head, the header names the check that block makes.
- [ ] AC3: The block "an interrupted run leaves no fold executing" withstands the cause of its failure that T3 records: a reproduction of that cause, planted inside the block's own run as T3 describes it, fails the block on `main` at `3fac0b62` and passes it on the branch head.
- [ ] AC4: When the block's signal to the host is never sent, because the folds did not both mark themselves started within the wait, the block fails with an expectation whose message says the signal was not sent, rather than only with `expect_true(interrupted)`.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3, T4
- AC4 → T4

## Tasks

- [x] T1: Add the snapshot naming block to `test-suite-hygiene.R` (finding 5). Drive `daemon_state_snapshot()` over fabricated answers by mocking the round trip (`mirai::everywhere()` and `collect_bounded()` in `helper-parallel.R`), so the block needs no pool and runs where the suite runs. Keep or fold in the existing `name_by_pid()` block, whichever leaves no repeated check. Plant the defect once (return `answers` unnamed from `daemon_state_snapshot()`), see the block red, restore, and record both outcomes in the work log.
- [x] T2: Rewrite the header of `test-suite-hygiene.R` (finding 9) so it names each check the file makes: the budget ledger rows, the copied bounds, the declared worst cases, the blocking-collect rule, and the snapshot naming. Record in the work log which header check covers each `^test_that(` line.
- [x] T3: Diagnose the interrupt failure on `main` at `3fac0b62` by execution. Instrument a scratch copy of the block, outside the repo, to record whether the shell sent the signal, when dispatch began, and when each marker appeared. Run it inside full suite runs, quiet and side by side (M152's side-by-side runs failed it in both). Record which stage fails and a reproduction of that cause that can be planted inside the block's own run (for example, a delay in the mocked fold before it marks itself started). If the cause is in `R/`, stop for the user and route it to `/hotfix` (question set).
- [x] T4: Fix the block for T3's cause. Make a wait that times out fail with its own message (AC4): the shell writes a file when it sends the signal or gives up, and the block asserts it was sent. Show both by planting: T3's reproduction on `main` and on the branch head (AC3), and a wait that cannot see the markers (AC4). Re-point `helper-time-budget.R` rows for any bound that moves, once, against the committed text (M152 lesson).
- [ ] T5: The `verify` slot: `devtools::test()` with no failure and no error, and `air format --check .` clean. Then the full suite runs for review evidence: three runs alone and two pairs run side by side on the branch head, with no other R session open, recording the interrupt block's result in each run.

## Work log

- 2026-10-23: created by /milestone-plan.
- 2026-10-23: tier check: milestone — the interrupt failure needs diagnosis by execution and a design choice, more than one sitting.
- 2026-10-23: idea vet: finding 8 is a cost, not a defect (the forced run takes 6.1, 5.0 and 4.8 s, about 0.6% of an 820 s serial suite, and is the only test that an explicit seed is overwritten); question set: keep it, no code change. A fix that only widens the interrupt block's waits could hide a real interrupt defect, so T3 diagnoses first and a cause in `R/` stops for `/hotfix` (question set). Findings 5 and 9: no concern.
- 2026-10-23: collision check: absorbs the candidate row "Fix the M079 review leftovers" in full; the M152 lesson on daemon blocks under side-by-side runs bears on T3; no D-entry overlaps. Inbox sweep: 1 open issue (#91) and 0 open PRs, none overlapping.
- 2026-10-23: lessons harvested: M152 (daemon blocks fail beside other R sessions; re-point ledger rows once), M15 (a real SIGINT from a detached `sh` waiting on marker files), M14 (`TESTTHAT_PARALLEL=FALSE` for teardown output, `HangTraceReporter` stamps for per-file wall clock), M51 (battery throttling and run-to-run drift), M09 (assertions that cannot fail).
- 2026-10-23: criteria audit (reduced, fresh Opus reader): AC1 and the not-sent criterion no finding. AC2 "names each check" had no procedure; fixed with the reader's wording, the grep anchored at `^test_that(` so a comment at line 94 does not match. The two full-suite-run criteria bound runs and machine state, an instrument across process boundaries; replaced by AC3, a planted reproduction of the diagnosed cause inside the block's own run, and the runs moved to T5 as review evidence.
- 2026-10-23: plan gate chose a planted reproduction of the diagnosed cause (AC3) over full-suite pass counts as the criterion, because pass counts bind runs rather than code and an intermittent failure can pass a few runs unfixed; falsified by the cause not being plantable inside one block run.
- 2026-10-23: plan gate chose mocking the snapshot's round trip (T1) over a live two-daemon pool, because the mock needs no pool and runs on every leg the suite runs on; falsified by the mock passing while a live pool's snapshot names a record wrongly.
- 2026-10-23: question set: finding 8 — keep the forced-seed run as is. Review evidence — three quiet full runs plus two side-by-side pairs on this Mac, with no other R session open. A cause in `R/` — stop and route to `/hotfix`.
- 2026-10-23: started; branch `m159-m079-review-leftovers` cut from `main` at `3da94c6f`.
- 2026-10-23: T1 — the existing naming block now takes its snapshots through `daemon_state_snapshot()` with `collect_bounded()` rebound by `rlang::local_bindings()` (testthat's `local_mocked_bindings()` searches the namespace and could not find the helper), so no pool is needed and one block holds the check. File `[ FAIL 0 | PASS 29 ]`, no skip. Plant: `daemon_state_snapshot()` returning `answers` unnamed gave 3 failures, each an `expect_identical()` on the names (`c("10", "20", "30")`, the pid vector's names, `c("10", "30", NA, NA)`); helper restored, `git diff` empty. `air format --check .` clean.
- 2026-10-23: T2 — header now lists four checks and calls the blocking-collect rule "the first rule" (the ledger section below already says "the second rule"). Coverage of `grep -n '^test_that('`: :188, :217, :305 → the ledger check; :373, :383 → the worst-case ceilings; :393 → the blocking-collect rule; :434 → the snapshot naming. File `[ FAIL 0 | PASS 29 ]`, `air format --check .` clean.
- 2026-10-23: T3 — on `main` at `3fac0b62` in a scratch worktree, on battery, the block instrumented to stamp the shell's send, dispatch start and end, and the marker mtimes. Alone: pass, markers 70 ms after dispatch. One quiet full parallel run: whole suite 0 failures, block passed. One side-by-side pair: run B passed; run A FAILED — markers 70 ms after dispatch, the shell sent SIGINT on its first check, and the collect still ran its full 60 s and returned with `interrupted = FALSE` and no error. Serial run of the `^parallel` files in one process: pass, so no earlier file in a shared worker sets it up. The cause is a SIGINT lost after it is sent, under load. The wait window is not the cause. `dispatch_folds()`'s collect is a bare `mirai::collect_mirai()` with no interrupt handler in `R/`, so the loss is below the package (R, mirai 2.7.2, nanonext 1.10.2) and the `/hotfix` route does not apply. Plantable reproduction: the shell's first signal replaced by `kill -0` (a signal that reaches no R handler).
- 2026-10-23: T4 — the shell now sends up to three SIGINTs, 3 s apart, stopping once the host's handler writes an `ack` file. It records each send and its finish in a `sent` file. The existing 15 s deadline poll also waits for the shell to finish and catches a late signal, so the ledger row keeps its 15 s and changes only its note. Two `expect()` messages: no signal sent (the wait timed out), and signals sent that never reached the host. Plants: `main` with `kill -INT` → `kill -0` fails at :108, "Expected `interrupted` to be TRUE"; the branch with its first send → `kill -0` passes, 8 expectations, so a later real signal reached the host. The branch with marker 1's path made unreachable fails once at :152, "The shell sent no interrupt: the two folds did not both mark themselves started within its 20 s wait." All restored (`cmp` equal). Unplanted, the file passes with 8 expectations. `air format --check .` clean.
- 2026-10-23: T5 verify slot — `devtools::test()` on `932c3e47`, whole suite, no failure and no error (23:24 to 23:32, on battery); `air format --check .` clean. The evidence runs (three alone, two side-by-side pairs) are not made: T5 sets them on AC power and the Mac reads "Battery Power", so implement stops for the user to plug in. Resume with `/milestone-implement M159`, which makes the runs and hands off to review.
- 2026-10-24: minor amendment: T5 drops "on AC power". The user re-ran `/milestone-implement M159` with the Mac still on battery. The runs judge pass or fail, not timing, and battery throttling only adds load (M51). Quiet runs started on `9e45aaea`.
- 2026-10-24: T5 quiet runs on `9e45aaea`, on battery, no other R session: run 1 (07:25-07:33) — interrupt block passed (8 expectations); 10 failures, all in `test-parallel-identity.R` (:241, :312, :357, :414), where `shared_daemons(2)` read 1 connection for 2. Runs 2 (07:33-07:43) and 3 (07:43-07:51) — whole suite 0 failures, interrupt block passed. The identity failures are outside Scope (Out: the M152 lesson). Their first quiet-run occurrence got the candidate row "Find why the identity pool loses a daemon". Side-by-side pairs started.

## Decisions

## Review
