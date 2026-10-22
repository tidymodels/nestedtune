# M151: The four other tuners are tested on one inner sliding design, and the help claims only what the tests run

- **Status:** review
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — the help of `nested_resamples()` and `nested_tune_grid()` and `NEWS.md` state a narrower tested set
- **Branch/PR:** m151-time-series-tuner-cut

## Goal

Cut the suite time that the inner-design tuner matrix costs. The help and `NEWS.md` then name a function and design as tested only where a test runs them.

## Scope

**In:**
- Delete `tests/testthat/test-time-series-inner-bayes-anneal.R` and `tests/testthat/test-time-series-inner-race.R` whole. Together they hold 24 blocks and took 521 s of a 1,850 s serial run (2026-10-21, `16c38162`). Each tuner keeps its run on an inner sliding design in `test-time-series-pairs-other.R`.
- In `tests/testthat/test-time-series-inner-other.R`, delete the four blocks named "a workflow set run with fn = `<fn>` on an inner sliding-period design matches the hand calls". Here `<fn>` is `nested_tune_bayes`, `nested_tune_race_anova`, `nested_tune_race_win_loss` and `nested_tune_sim_anneal`. `test-nested-workflow-map-oracles.R` keeps the test of how the map routes `fn`.
- In `test-time-series-designs.R`, delete the three blocks named "the final fit on a `<design>` design matches a hand-rolled reference". Here `<design>` is `sliding-window`, `sliding-index` and `sliding-period`. The final fit reads the data, not the outer splits (D-075). So the rolling-origin final fit runs the same path. The `fit_resamples()` final-fit blocks stay.
- The Bayesian final fit on the sliding-window outer design in `test-time-series-bayes.R` stays, because D-080 names it as the test that D-075 rests on.
- Rewrite the `Time-series designs` section of `?nested_resamples` (`R/nested-resamples.R:57-85`) to the tested set that remains. Do the same for the sentences of `?nested_tune_grid` (`R/nested-tune-grid.R:89-95`) that name other functions, and for the time-series bullets of `NEWS.md` (lines 288-330).
- Remove the deleted files from `Config/testthat/start-first` in `DESCRIPTION`.
- Write one D-entry that supersedes the clauses of D-080, D-085, D-112 and D-113 that the cut changes. Widen the "Inner designs M140 leaves out" candidate row to name the combinations that become unclaimed.

**Out:**
- Every `nested_tune_grid()` test on a time-series design stays, because the README resampling table rests on them (D-095).
- The grid reference loops on an outer sliding design with an inner `rolling_origin()` stay.
- Pruning outside the time-series files → M152. Comment cleanup in the files that remain → M155.

## Acceptance criteria

- [x] AC1: Join the `benchmarks/test-blocks.R` tables of the branch point and the head on file and test name. Every block that the head lacks is in the two deleted files or has a name that Scope In lists. Every other block is at the head with the same expectation count.
- [x] AC2: Read each sentence that names a function and a time-series design. Such sentences are in the `Time-series designs` section of `?nested_resamples`, the time-series paragraph of `?nested_tune_grid`, and the time-series bullets of `NEWS.md`. A sentence that calls a combination tested names one that a head block runs. A sentence that calls a combination untested names one that no head block in `test-time-series-*.R` runs.
- [x] AC3: `cairn/DECISIONS.md` holds one new entry. It names the clauses of D-080, D-085, D-112 and D-113 that it supersedes, and it says that the test D-075 rests on stays.
- [x] AC4: In `R-CMD-check.yaml` run 39525408946 on the default branch (commit a3513d8c, whose `tests/`, `R/` and `DESCRIPTION` match the branch point's), read the `[hang-trace]` lines whose target has the form `<file> :: <test>`. A block's time is its `end` timestamp minus its `start` timestamp. On each of the run's five check legs, the blocks that the head lacks under AC1's join take at least 12% of the summed time of that leg's blocks.
- [x] AC5: `benchmarks/coverage-lines.R` gives each line of `R/` the same hit-or-miss status at the branch point and at the head, compared on `file` and `pos`.
- [ ] AC6: The profile's `verify` slot is clean at the head.

## Coverage

- AC1 → T1, T2, T5
- AC2 → T3, T5
- AC3 → T4
- AC4 → T5
- AC5 → T1, T5
- AC6 → T6

## Tasks

- [x] T1: Record the branch point. Run `benchmarks/test-blocks.R`, `benchmarks/coverage-lines.R` and `benchmarks/profile-tests.R 1` on it in the background, with outputs in the scratchpad.
- [x] T2: Delete the files and blocks that Scope In names. If no other file calls a fixture helper, delete it. Update `DESCRIPTION` start-first. Check `helper-time-budget.R` for rows on the deleted files.
- [x] T3: Rewrite the help section and sentences, and run `devtools::document()`. Rewrite the `NEWS.md` bullets. Write each claim against a head test block.
- [x] T4: Write the D-entry, and widen the inner-designs candidate row.
- [x] T5: Run the three scripts at the head and compare. Record the block comparison, the claim check of each help and `NEWS.md` sentence, the timing and the coverage results in the work log, for review to verify in its Review section.
- [x] T6: Run the `verify` slot.

## Work log

- 2026-10-21: created by /milestone-plan.
- 2026-10-21: tier check: milestone — a test cut that narrows help and NEWS claims and supersedes four D-entries.
- 2026-10-21: idea vet: one concern, that D-085 and D-112 claim the inner sliding designs under every tuner because the inner design reaches the tuner; answered at the question set, which chose the cut, since that path reaches tune's code and nestedtune's inner-split handling stays tested under grid.
- 2026-10-21: question set: cut the inner-design tuner matrix? — cut, and narrow the help to the tested set.
- 2026-10-21: plan gate chose narrowing the help to the tested set over a wide claim resting on the shared path, because the help claims only what a test runs (D-071); falsified by a tuner that fails on an inner sliding design where it passes on the sliding-window pair.
- 2026-10-21: collision: D-080, D-085, D-112 and D-113 are superseded by T4's entry; the Bayesian sliding-window final fit, which D-080 names as D-075's evidence, stays; the "Inner designs M140 leaves out" row is widened at T4, not absorbed.
- 2026-10-21: criteria audit (full, fresh Opus reader): three findings, all fixed. AC1 now lists exact block names; AC2 covers tested and untested sentences, with the ledger moved to T5; the Bayesian final-fit deletion was dropped because D-080 names that block as D-075's evidence.
- 2026-10-21: split: the four requested pieces became M151 to M155; the ledger re-key and the comment cleanup were split into M154 and M155, because one goal needed "and".
- 2026-10-21: inbox sweep: one open issue (#91, docs pass), no overlap; no open PRs.
- 2026-10-21: lessons harvested: M51 (a CI leg's time moves with the runner, so the timing criteria use local serial runs on one machine).
- 2026-10-21: T1 started: branch point 3af50898 checked out as a detached worktree in the scratchpad; test-blocks and coverage-lines run there in the background; the branch-point profile runs alone after them, so its timing has no contention.
- 2026-10-21: T2 done: deleted the two inner tuner files, the four map-with-tuner blocks and the three sliding outer final fits; no helper became unused (each is called from another test file); start-first drops the two files; the ledger has no rows on them; the O2 and O3 oracle headers no longer name the deleted tests. The edited files and the start-first guard pass.
- 2026-10-21: T3 done: `?nested_resamples` and the two `NEWS.md` bullets now name the grid final fit on the rolling-origin outer design alone, and say that the four other tuners are not tested under an outer rolling-origin with an inner sliding design; `?nested_tune_grid` needed no change, since it names only grid. `document()` raised `Config/roxygen2/version` to the local 8.1.1, and that line was put back to 8.1.0. All six gating prose sweeps clean.
- 2026-10-21: verify: the full suite passed on the branch, 1245 blocks, 0 failures, 0 errors, 0 skips.
- 2026-10-21: claim audit: 21 claims read, 3 corrected — tests/testthat/test-time-series-designs.R (the final fit takes its data from the first outer split and never reads the split indices; the sliding-index and sliding-period loop no longer runs O3 or the other tuners). Every help and NEWS sentence held.
- 2026-10-21: minor amendment: T5 records its evidence in the work log, since the Review section belongs to review.
- 2026-10-21: T5 blocks: `test-blocks.R` gives 1276 blocks at 3af50898 and 1245 at b3bcd82e; the 31 the head lacks are the 24 of the two deleted files, the 4 map-with-tuner blocks and the 3 sliding outer final fits; no block is new, and the 1245 kept blocks have the same expectation counts; 0 failed, errored or skipped.
- 2026-10-21: T5 coverage: `coverage-lines.R` gives 6352 lines at both trees, joined on file and pos with none unmatched; no line changes hit-or-miss status, and 128 are uncovered at each.
- 2026-10-21: T5 claims: the claim audit read each sentence of the `Time-series designs` section and the three NEWS bullets against the head tests; each "tested" sentence names a head block that runs it, and each "not tested" sentence names a combination no `test-time-series-*.R` block runs. `?nested_tune_grid` names only grid, whose 16 design combinations all keep a test.
- 2026-10-22: T5 timing: `profile-tests.R 1` gave 917.1 s at 3af50898 and 1058.3 s at b3bcd82e, run back to back on one machine; unchanged files ran up to 2.7 times slower in the second run, so the local single-run comparison measures machine state, not the cut. The 2026-10-21 run behind the plan's 521 s figure was about twice as slow overall; at 3af50898 the two deleted files took 119 s of 917 s.
- 2026-10-22: T5 CI share: in the hang trace of `R-CMD-check.yaml` run 39525408946 the 31 blocks the head lacks take 557 s of 3384 s on macOS (16.4%), 842 of 5432 on devel (15.5%), 821 of 5302 on oldrel-1 (15.5%), 841 of 5486 on release (15.3%) and 938 of 6056 on windows (15.5%).
- 2026-10-22: question at stop: AC4's 450 s local target cannot pass, and the cut saves about 15% of each CI leg's test time, not the planned 31%; how to go on — keep the cut and reword AC4 to the measured CI share (user's choice).
- 2026-10-22: substantive amendment: AC4 now reads the deleted blocks' share of block time in the hang trace of main's run 39525408946, at least 12% on each of the five legs, in place of a 450 s drop between two local serial runs; Coverage AC4 → T5. The lessons line above, which names local serial runs for the timing criteria, is superseded by this entry.
- 2026-10-22: re-audit: AC4 (full) — satisfiable at 15.3% to 16.4% per leg; three gaps fixed in the wording: name the run's commit and that its tests match the branch point, count only `<file> :: <test>` lines, and drop T1 from Coverage. It also noted that a `memoised()` cache entry built by a deleted block and reused by a kept one would move cost onto the kept block; the deleted blocks run inner sliding fixtures that no kept block requests, so this is recorded and not checked.
- 2026-10-22: re-audit: AC4 (full) — holds as written; one reading recorded: a block's timestamp is the clock time the `[hang-trace]` marker prints, not the runner's line prefix, which is the same for every line because the log is dumped at the end. Review should read the run before GitHub's log retention ends.
- 2026-10-22: T6 verify: the full suite passed earlier at 3e0db968 (1245 blocks, 0 failures); since then only comments changed, and `test-time-series-designs.R` passes (22 blocks). `air format --check .` clean; the six gating prose sweeps clean; `devtools::document()` gives no diff except raising `Config/roxygen2/version` to the local roxygen2 8.1.1, which was put back. Status set to review.
- 2026-10-21: T4 done: D-118 written; the "Inner designs M140 leaves out" row now names the combinations D-118 leaves untested.

## Decisions

## Review

Reviewed 2026-10-22 at 6fd4eea9 on m151-time-series-tuner-cut; the default branch (3af50898) has not moved since the cut.

- AC1: `benchmarks/test-blocks.R` tables at 3af50898 (1276 blocks, 15595 expectations) and b3bcd82e (1245 blocks, 15309 expectations); `git diff b3bcd82e HEAD -- tests R DESCRIPTION man NEWS.md` is empty, so the head table stands for 6fd4eea9. The join on file and test leaves 31 branch-point blocks absent: 12 in `test-time-series-inner-bayes-anneal.R`, 12 in `test-time-series-inner-race.R`, 4 in `test-time-series-inner-other.R` and 3 in `test-time-series-designs.R`, each in a deleted file or named in Scope In (0 outside it). No head block is new; the 1245 kept blocks keep their expectation counts. Pass.
- AC2: each sentence matched against the head block table by name pattern (scratchpad `ac2.R`). `?nested_resamples` bullet 1 and NEWS bullet 1: grid reference loop on the four outer designs (4 blocks, `test-time-series-designs.R`), `nested_fit_resamples()` (4) and its final fit (4) on the four, the grid final fit on rolling-origin (1, the only grid final fit on an outer design), the four other tuners (4) and their final fits (4) on rolling-origin in the bayes, race and anneal files, the Bayesian final fit on sliding-window (1), the map on rolling-origin (1). Bullet 2 and NEWS bullet 2: grid (3) and its final fit (3) on the three inner designs in `test-time-series-inner.R`, the map with its default `fn` (3) and `nested_fit_resamples()` (3) in `test-time-series-inner-other.R`; the untested claims hold, with 0 time-series blocks whose name pairs a Bayes, racing or annealing tuner with an inner design (case-insensitive) and 0 blocks with `fn =`. Bullet 3 and NEWS bullet 3: grid on the nine pairs (9); the four tuners (4) and the map, the grid final fit and `nested_fit_resamples()` (3) on the sliding-window pair in `test-time-series-pairs-other.R`; each of the three other pairs files holds 6 blocks, its three pairs' grid and splits tests. Splits match `rsample::nested_cv()` in 16 blocks (4 outer, 3 inner, 9 pairs). `?nested_tune_grid` claims grid on the 16 outer-by-inner combinations, and all 16 keep a block. The test files hold no inner design other than `rolling_origin()` and the three sliding designs. Pass.
- AC3: `cairn/DECISIONS.md` gains one entry on the branch (`git diff 3af50898 HEAD` adds one `### D-` heading), D-118 at line 2114. Its supersession note names clauses of D-085, D-112, D-113 and D-080, and its Decision says the Bayesian final fit on the sliding-window outer design stays "because it is the test that D-075 rests on". Pass.
- AC4: recomputed from the `[hang-trace]` marker times of `<file> :: <test>` lines in run 39525408946 (commit a3513d8c; `git diff a3513d8c 3af50898 -- tests R DESCRIPTION` empty). All 31 blocks the head lacks are found on each leg. Their share of summed block time: macOS 557 of 3384 s (16.4%), ubuntu devel 842 of 5432 s (15.5%), oldrel-1 821 of 5302 s (15.5%), release 841 of 5486 s (15.3%), windows 938 of 6056 s (15.5%); each is at least 12%. Pass.
- AC5: `benchmarks/coverage-lines.R` at 3af50898 (branch-point worktree) and on the branch tree after T4 (3e0db968; `R/` unchanged since, and the later test edits are comments only): 6352 tallied lines in each, joined on `file` and `pos` with 0 unmatched; 0 lines change hit-or-miss status; 128 uncovered in each. Pass.
