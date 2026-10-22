# M151: The four other tuners are tested on one inner sliding design, and the help claims only what the tests run

- **Status:** in-progress
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

- [ ] AC1: Join the `benchmarks/test-blocks.R` tables of the branch point and the head on file and test name. Every block that the head lacks is in the two deleted files or has a name that Scope In lists. Every other block is at the head with the same expectation count.
- [ ] AC2: Read each sentence that names a function and a time-series design. Such sentences are in the `Time-series designs` section of `?nested_resamples`, the time-series paragraph of `?nested_tune_grid`, and the time-series bullets of `NEWS.md`. A sentence that calls a combination tested names one that a head block runs. A sentence that calls a combination untested names one that no head block in `test-time-series-*.R` runs.
- [ ] AC3: `cairn/DECISIONS.md` holds one new entry. It names the clauses of D-080, D-085, D-112 and D-113 that it supersedes, and it says that the test D-075 rests on stays.
- [ ] AC4: Run `benchmarks/profile-tests.R 1` on one machine at the branch point and at the head. The head's suite total is at least 450 s lower.
- [ ] AC5: `benchmarks/coverage-lines.R` gives each line of `R/` the same hit-or-miss status at the branch point and at the head, compared on `file` and `pos`.
- [ ] AC6: The profile's `verify` slot is clean at the head.

## Coverage

- AC1 → T1, T2, T5
- AC2 → T3, T5
- AC3 → T4
- AC4 → T1, T5
- AC5 → T1, T5
- AC6 → T6

## Tasks

- [ ] T1: Record the branch point. Run `benchmarks/test-blocks.R`, `benchmarks/coverage-lines.R` and `benchmarks/profile-tests.R 1` on it in the background, with outputs in the scratchpad.
- [ ] T2: Delete the files and blocks that Scope In names. If no other file calls a fixture helper, delete it. Update `DESCRIPTION` start-first. Check `helper-time-budget.R` for rows on the deleted files.
- [ ] T3: Rewrite the help section and sentences, and run `devtools::document()`. Rewrite the `NEWS.md` bullets. Write each claim against a head test block.
- [ ] T4: Write the D-entry, and widen the inner-designs candidate row.
- [ ] T5: Run the three scripts at the head and compare. Write the block comparison, a claim ledger with one row per help or `NEWS.md` sentence, the timing and the coverage results to the Review section.
- [ ] T6: Run the `verify` slot.

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

## Decisions

## Review
