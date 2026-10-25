<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M162: The shared test pool keeps both daemons

- **Status:** planned   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate; RR<NN> whose Binding criteria bind this milestone's ACs (binding-criteria check), or — -->
- **Principles touched:** IP2   <!-- owner: plan · create/amend-via-gate; comma-separated IPn/GPn ids this milestone touches, or — -->
- **Resolves:** —   <!-- owner: plan · create/amend-via-gate; comma-separated GitHub issues the scope absorbs, each `#N closes` (the PR closes it at merge) or `#N partial` (the remainder gets a candidate row), or — ; skill conduct only — no validate check parses it -->
- **Surface tier:** user-facing — the cause may sit in the cancel path of `R/parallel.R` that a user's pool goes through   <!-- owner: plan · create/amend-via-gate; user-facing | internal — <one-clause reason>; skill conduct only — no validate check parses it -->
- **Branch/PR:** —   <!-- owner: implement (branch) / review (PR URL) · create; a companion checkout the milestone also works in is one further entry per checkout, `companion: <abs-path> <branch>` (implement), its PR URL appended by review — /milestone-review merges companions first, in listed order -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Find the call that drops a daemon from `test-parallel-identity.R`'s shared 2-daemon pool, and fix it where it sits.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** a reproduction script under `benchmarks/`; switching off the candidate calls one at a time to name the cause; the fix in test code, in `R/`, or both; the `helper-time-budget.R` ledger rows a fix changes; a `NEWS.md` bullet only where `R/` changes. If fewer than 5 trials lose a daemon under the stated setup, implement stops (the goal-wrong stop), records the non-reproduction in the work log, and ships no fix.

**Out:** a report to mirai or nanonext upstream is an outward action the plan gate did not cover, so implement stops for the user's yes before posting one, and a declined report becomes a candidate row. The interrupt block's leftovers stay on the row "Tidy the interrupt block's leftovers". The byte figures in `R/parallel.R` stay on the row "Pin the byte figures in parallel.R".

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets.
     Every item opens with its positional label — `ACn:` — the item's
     position counted top-to-bottom, the number Coverage cites; an
     insertion, removal, or reorder renumbers the labels and the Coverage
     lines together.
     Driving RR set → its Binding criteria appear VERBATIM here (binding-
     criteria check), each ingested as a numbered criterion carrying its tag
     — `- [ ] ACn (BCm): <verbatim>` — with its own Coverage line, since
     coverage-complete counts AC checkboxes positionally (M107); departures:
     a "Deviations from RR<NN>" table ends this section. -->

- [ ] AC1: `benchmarks/probe-shared-pool-loss.R`, run against a checkout of the base commit with no file under `tests/` edited, reproduces the loss. Each trial is a fresh `Rscript` process running `devtools::test()` (the pkgload path) on the whole suite or on `test-parallel-identity.R` alone, beside the side load the script states. A trial lost a daemon when its results hold a failure of the `mirai::status()$connections` expectation raised from a `shared_daemons(2)` call in that file, and the script reports the line of the first such call. Its header states, from one run at the base commit, the commit, the mirai and nanonext versions, the trial shape and side load, the trial count, and the number of trials that lost a daemon, which is at least 5.
- [ ] AC2: The same script with the same trial shape, side load and trial count, run at the branch head, reports 0 trials that lost a daemon, and its header states that run's commit and counts beside the base run's. At the head, every expectation of the block "a cancelled parallel run returns nothing and restores the RNG state" is kept, and every block that ran `shared_daemons(2)` at the base still runs it, except a block the fix moves to a private pool.
- [ ] AC3: The work log names as the cause the candidate call (the test's mocked `stop_mirai()`, the `on.exit()` stop in `dispatch_folds()`, the pre-flight probe's stop, or another the reproduction points to) whose removal alone takes AC1's script to 0 lost trials under AC2's setup. If the fix changes any file under `R/`, a regression test fails at the base commit in each of 5 runs and passes at the head in each of 5, and `NEWS.md` gains one bullet that claims only the exit path that test covers. If it changes no file under `R/`, the diff adds no `NEWS.md` entry.
- [ ] AC4: At the branch head, the `verify` slot of `cairn/PROFILE.md` is clean, and `devtools::check()` run in the main checkout with the branch head checked out reports 0 errors, 0 warnings and 0 notes.

## Coverage
<!-- owner: plan · create/amend-via-gate; each acceptance criterion → the
     task(s) satisfying it, by positional number (AC/Task counted
     top-to-bottom). Review reads to fence evidence — tracking-rules "AC fencing". -->

- AC1 → T1
- AC2 → T3, T4
- AC3 → T2, T3
- AC4 → T5

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits); substantive
     change is amend-via-gate. Every item opens with its positional label —
     `Tn:` — the item's position counted top-to-bottom, the number Coverage
     cites; an insertion, removal, or reorder renumbers the labels and the
     Coverage lines together. -->

- [ ] T1: Write `benchmarks/probe-shared-pool-loss.R` on the shape of `benchmarks/stress-daemon-tests.R` (a kill deadline per trial, a `done` sentinel, errors counted apart from passes). Read each trial's results for the connections failure by its expectation and call site, not by count. Try the file alone with side load first, since it is faster, and fall back to the whole suite if it does not reproduce. Run it at the base commit in the background, set N so at least 5 trials lose a daemon, and write the header. Before each local run, write a work-log line naming the other R processes running (`pgrep -fl R`).
- [ ] T2: Name the cause. The first suspect is the block at `test-parallel-identity.R:151`, which stops a map just dispatched to the shared pool, followed by the first failing check at :241. Switch each candidate stop off alone (unmock the test's stop, mock out the `on.exit()` stop at `R/parallel.R:364`, the probe's stop at `R/parallel.R:561`) and rerun T1's setup. If the cause is mirai's or nanonext's own behavior, write a reprex without nestedtune under `benchmarks/` and stop for the user's yes before any upstream report.
- [ ] T3: Fix at the cause. In test code, for example, the cancel block gets a private pool as the kill block has, with its `helper-time-budget.R` rows moved. In `R/`, add the regression test AC3 names (forcing the race where possible) and the `NEWS.md` bullet, with roxygen updated if the exit contract changes.
- [ ] T4: Rerun T1's script at the branch head with the same setup and trial count, and add the head counts to the header.
- [ ] T5: Run the `verify` slot at the head, then `devtools::check()` from the main checkout with the branch head checked out (the M149 lesson).

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates.
     EXEMPT from the 150-line cap (D-046): history under D-045, never edited,
     so the cap must never demand a trim here. Wrapped entries get a WARN.
     The rejected-alternative record (/milestone-plan step 4) takes this form:
     `- YYYY-MM-DD: plan gate chose <approach> over <alternative> because
     <reason>; falsified by <evidence class>.` — one per approach choice the
     gate actually weighed, none where it weighed none, and it is the record
     `/milestone-review`'s thrash trigger (b) reads. It lives here rather than
     below so an instantiated file inherits no placeholder to delete.
     A milestone of a feature series also carries the plan's
     `feature series: M<a> -> M<b>[ -> …]` line (tracking-rules "Feature series"). -->

- 2026-10-25: created by /milestone-plan, absorbing the candidate row "Find why the identity pool loses a daemon".
- 2026-10-25: tier check: not run — work named at the question set.
- 2026-10-25: idea vet: no concern. A flaky gating test is worth fixing, and the row's framing holds, since the failures read 1 connection, a lost daemon and not a slow one. The fix may land in `R/`, which the surface tier and AC3 cover.
- 2026-10-25: question set: keep the Mac free of other R sessions for local runs, or use CI runs — the user answered "Not this work". No quiet machine is granted, so T1 runs locally and logs the R processes beside each run.
- 2026-10-25: lessons used: 2026-10-22 (M152), 2026-07-26 (M07), 2026-07-27 (M15), 2026-10-18 (M149).
- 2026-10-25: collision check: the candidate row is absorbed. M009 and M015 built the cancel path and its tests, and M159/M160 recorded the failures. No D-entry covers the shared pool. Inbox sweep: 1 open issue (#91, already a parked row), 0 open PRs, no overlap.
- 2026-10-25: criteria audit (full mode, fresh Opus reader): 11 findings, all taken. Named the pkgload path and side load (1). Script run against the base checkout with `tests/` unedited, loss read from the failure's call site (2). Non-reproduction stop moved into Scope (3). The instrument-bound AC1 stays as the diagnosis deliverable, with AC3's `R/` branch as the user-facing promise (4). AC2 keeps the cancel block's expectations and the pool checks, and the base floor is 5 losses (5). Cause named by switching off one candidate at a time (6). AC3 conditions on the diff, which covers a fix in both places, with the upstream case in T2 and Scope Out (7). Regression test runs 5 times each side, and NEWS claims only the covered exit path (8). AC4 is a gate, not evidence (9). The main checkout holds the branch head (10). AC4 cites the verify slot (11).
- 2026-10-25: plan gate chose fixing the call that drops the daemon over having `shared_daemons()` restart a lost daemon, because a restart would hide a loss a user's pool could also meet. Falsified by evidence that the loss is mirai behavior that no nestedtune call can avoid.

## Decisions
<!-- owner: implement / review · append-only; milestone-local; promote
     cross-cutting ones to cairn/DECISIONS.md.
     EXEMPT from the 150-line cap (D-074) because D-045 makes it history like the work log — dated dispositions, never edited — so the cap must never demand a trim here either.
     Entries carry their rationale; the counterweight `decisions format`
     advisory watches for pasted output, not for entry length (D-075). -->

## Review
<!-- owner: review · exclusive; evidence per criterion, consistency-gate
     results, review findings + triage. EXEMPT from the 150-line cap (M55),
     as are the work log (D-046) and the decisions section (D-074); evidence
     never scrambles plan-owned content. -->
