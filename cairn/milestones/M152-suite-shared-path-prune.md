# M152: The suite drops tests that repeat a shared path, cannot fail, or test a dependency

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2
- **Resolves:** —
- **Surface tier:** internal — test files only, and no help, NEWS or package code changes
- **Branch/PR:** m152-suite-shared-path-prune

## Goal

Remove the test blocks and expectation lines that the "What gets a test" floor calls superfluous, outside the time-series files.

## Scope

**In:** the candidates below came from four read-only reviews on 2026-10-21. Implement re-reads each one before it removes it. A candidate that is the only test of a documented claim or of a fixed defect stays, and the prune ledger says why. Line numbers are at `16c38162`.
- (a) Serial-parallel identity. In `test-parallel-identity.R`, three blocks on the shared fixture each pass one more formal of `dispatch_folds()` (`R/parallel.R`) to the workers: BC6 with `param_info`, BC11 with `control` and BC15 with `select`. Merge them into one run that sets all three. BC7 and BC8 need their own fixtures and stay. The tuner blocks BC10, BC12, BC13, BC16 and BC17 vary the tuner or the object, so they stay. Under (b), BC12 runs one racer.
- (b) The second racer. `nested_tune_race()` is the one body of both racers. In the `for (fn in RACERS)` loops and the per-racer blocks of `test-nested-tune-race-{oracles,rng,checks}.R`, `test-design-support.R` (:1235, :1306, :1492) and `test-parallel-required-pkgs.R:80`, keep `nested_tune_race_anova()`. Keep `nested_tune_race_win_loss()` only where it runs code that the anova racer does not, such as its registry entry or its packages.
- (c) Checks that cannot fail. The seed-identity checks in "refused before fitting" blocks pass on every exit path, because `nested_loop()` restores the seed in `on.exit()`. These are `test-nested-tune-grid-checks.R:186, :262, :623`, bayes-checks :305, race-checks :462, anneal-checks :403, and the seed lines in the AC5 blocks and in `expect_map_refusal()`. `test-suite-hygiene.R:312` cannot fail once :311 passes.
- (d) Repeats of one shared path. These are the per-driver blocks in `test-nested-tune-{bayes,sim-anneal,race}-checks.R` that the file's own shared-check table already covers. They also include the error-path RNG restore copies (bayes-rng :257, race-rng :112, anneal-rng :107) and bayes-rng :106 and :157. The Bayesian copies in `test-nested-final-fit-rng.R` and the two RNG blocks of `test-nested-fit-resamples-rng.R` go too. So do the `all.names(body())` structure blocks (bayes-checks :137, race-checks :288, anneal-checks :250). Also the five row-mismatch cases looped in `test-augment.R`, `test-compute-metrics.R` and `test-collect-predictions-summarize.R`: keep them in one file and one case in each other file. Also the per-tuner routes of `test-model-spec-input.R:332-520`, and four of the six AC1 and AC2 blocks of `test-nested-final-fit-predict.R`. The duplicated final fits in `test-nested-final-fit-identity.R` (AC3, AC4) and `test-nested-final-fit-set.R` go too. The reviews list more shared-path repeats in these files, and they go too: `test-selection-rule-installed.R`, `test-nested-tune-bayes-oracles.R`, `test-metrics-argument.R` and the two grid failure and results files. The list continues with `test-dplyr-compat.R`, `test-vctrs-compat.R`, `test-extract-procedure.R`, `test-eval-time.R` and `test-dots-barrier.R`. It ends with `test-parallel-{detection,interrupt,payload,classify}.R`, `test-nested-resamples-specs.R`, `test-design-support.R` (:57, :70) and the results, print and plot files.
- (e) A weaker expectation after an exact one that covers it. These are expectation lines, not whole blocks, in the reader, print, selection-rule, grid-oracles, grid-failures, bayes-results and grid-results files.
- (f) Dependency behavior. These are `test-nested-tune-grid-results.R:144, :156`, `test-nested-workflow-map-readers.R:493`, `test-fixture-cache.R:484-487`, the character-and-factor block of `test-nested-resamples-specs.R`, and the rsample size checks of `test-nested-resamples-memory.R`. They also include the tune-generic refusal blocks of `test-nested-final-fit-print.R` and `test-nested-final-fit-predict.R`, `test-event-level.R:208`, `test-skip-heavy.R:59-62`, and `test-covr-traces.R:44-52`.

**Out:**
- The `ggplot_build()` assertions in `test-nested-results-plot.R` that check drawn values against `collect_metrics()`. They test documented claims that a `vdiffr` snapshot cannot state.
- The two-versus-three daemon blocks, which D-079 keeps.
- The time-series files → M151. Re-keying the wait ledger → M154. Comments → M155.

## Acceptance criteria

- [ ] AC1: Join the `benchmarks/test-blocks.R` tables of the branch point and the head on file and test name. Each block that the head lacks, or whose expectation count changed, falls in a category, (a) to (f). For each one, a head block runs the same package path, or the block calls no package function.
- [ ] AC2: `benchmarks/coverage-lines.R` gives each line of `R/` the same hit-or-miss status at the branch point and at the head, compared on `file` and `pos`.
- [ ] AC3: `git diff --stat <branch point>..HEAD -- R man NEWS.md README.Rmd README.md vignettes` is empty.
- [ ] AC4: Take each of `param_info`, `control` and `select` in turn. A mutation makes `dispatch_folds()` pass that formal's default in both of its `.args` lists. With each mutation, the merged identity run of (a) fails.
- [ ] AC5: Run `benchmarks/profile-tests.R 1` on one machine at the branch point and at the head. The head's suite total is at least 100 s lower.
- [ ] AC6: The profile's `verify` slot is clean at the head.

## Coverage

- AC1 → T1, T2, T3, T4, T5, T7
- AC2 → T1, T7
- AC3 → T7
- AC4 → T2
- AC5 → T1, T7
- AC6 → T8

## Tasks

- [ ] T1: Record the branch point. Run `benchmarks/test-blocks.R`, `benchmarks/coverage-lines.R` and `benchmarks/profile-tests.R 1` on it in the background.
- [x] T2: Do (a). Plant the three mutations of AC4 in a scratch copy of `R/parallel.R`, and record which expectation fails for each.
- [ ] T3: Do (b) and (c).
- [ ] T4: Do (d) for the driver, RNG, final-fit and model-spec files.
- [ ] T5: Do (d) for the reader, compat, parallel and misc files, then (e) and (f).
- [ ] T6: Update the `helper-time-budget.R` rows of each deleted or merged wait, and `Config/testthat/start-first`.
- [ ] T7: Run the three scripts at the head and compare. Write a prune ledger to the Review section. It has one row per removed or changed block, with its category and the head block that covers it. Add the coverage and timing results.
- [ ] T8: Run the `verify` slot.

## Work log

- 2026-10-21: created by /milestone-plan.
- 2026-10-21: tier check: milestone — test pruning across about 60 files, more than one sitting.
- 2026-10-21: idea vet: one concern, that merging identity blocks weakens the tests behind IP2; settled in scope, since only the three argument blocks on the shared fixture merge, every tuner block stays, and AC4's mutations show the merged run still fails on a dropped argument.
- 2026-10-21: plan gate chose keeping the plot file's `ggplot_build()` value checks over removing them under the profile's vdiffr-only clause, because they test documented claims a snapshot cannot state; falsified by such a check that asserts only cosmetic output.
- 2026-10-21: criteria audit (reduced, fresh Opus reader): two findings, both fixed. AC1 now states a property of the suite, with the ledger moved to T7; AC4 is narrowed to three formals, since `dispatch_folds()` builds two `.args` lists and the tuner blocks cannot merge into one run. AC5's bar went from 150 s to 100 s on the re-estimate that followed.
- 2026-10-21: collision: D-079 keeps the two-versus-three daemon blocks (Out). The parked "Fix the M079 review leftovers" row names suite time being priced again as a promotion condition; it is left for triage, not absorbed.
- 2026-10-22: branch cut from 5feebda2 (the branch point). T1's block and coverage runs started on a detached worktree of it in the scratchpad; the timing run waits for T7, so both trees are timed side by side.
- 2026-10-22: minor amendment: each task updates the `helper-time-budget.R` rows of the lines it moves, since the hygiene test fails otherwise; T6 keeps the final ledger check and `start-first`.
- 2026-10-22: T2: BC6's `param_info` block, BC11 and BC15 merged into one `nested_tune_bayes()` run that sets all three. The rule is `pct_loss` on `df1, df2` at limit 20: BC15's old rule picked the default's candidates on this run, and its select mutation failed nothing. AC4 mutations, on scratch copies of `R/parallel.R` with both `.args` lists set to the default: each of `param_info`, `control` and `select` fails the merged block at :492 (per column) and :494 (whole object). BC12 runs the ANOVA racer, and its ledger row drops `times = 2`.
- 2026-10-22: T2 verify: full suite at d1949e23, 0 failures, 0 errors; `air format --check .` clean.
- 2026-10-22: T3: (b) the race oracles, RNG, checks and design-support files run the ANOVA racer. The deterministic oracle, the model-package block and the final-fit package block keep both racers, since they read each racer's registry entry. `test-parallel-required-pkgs.R:80` already ran the ANOVA racer alone, so it is unchanged. (c) grid-checks :186, :262 and :623, bayes :305, race :462, anneal :403, the AC5 seed lines and `expect_map_refusal()`'s seed lines are gone. Grid-checks :467 stays: it starts with no seed, which `restore_rng()` leaves alone, so it can fail. Hygiene :312 and its constant are gone.
- 2026-10-22: T3 also took the (d) blocks of the same files: the race error-path RNG block, and in the bayes, anneal and race checks files the structure blocks and the per-driver malformed-design, dots, control-class, control event-level and select blocks, whose checks the file's table fires and the grid checks file tests in full.
- 2026-10-22: T3 verify: full suite at 8fded33f, 0 failures, 0 errors.
- 2026-10-22: T4 (part): bayes-rng :106, :157, :257 and anneal-rng :107 gone; the five Bayesian blocks of `test-nested-final-fit-rng.R` and the two RNG blocks of `test-nested-fit-resamples-rng.R` gone. Final-fit identity AC3 drops the assembled workflow's fits and AC4's set fit goes; the set file's loop now asserts the row's workflow entry and reads the selections from its own fits, so its two extra fits go. Final-fit predict keeps AC1 on the regression fit and AC2 on the censored fit, since `augment()` passes `eval_time` by name. Model-spec input drops the per-tuner route runs and AC3's duplicate fit; the forwarding block now asserts each method's wrapped workflow, shown to fail at :217 on a planted wrap that drops the preprocessor.
- 2026-10-22: T5 (part): the row-mismatch loops of compute-metrics and collect-predictions-summarize keep the `repeated` case; augment keeps all five. (f): fixture-cache :484-487, event-level's AC3 block and its O3 record (O1 and O2 remain), skip-heavy :59-62, covr-traces :44-52, the rsample slope bounds and the "rsample's own size" block of resamples-memory, and the final-fit print and predict tune-generic blocks are gone.
- 2026-10-22: the 2026-10-21 review notes behind the unnamed (d) and (e) candidates were not saved, so three read-only Opus surveys re-derive them (driver and results files; compat, reader, print and plot files; parallel files); each candidate is re-read before removal.
- 2026-10-22: verify at bf2449d4: full suite 0 failures, 0 errors.
- 2026-10-22: from the parallel survey: detection's "a primed pool matches the host's namespace exactly" (covered by :396, whose "ok" implies no incompatible daemon) and "dispatch_folds warns once per call" (covered by the grid run on the same pool), and classify's primed-pool dispatch, ambiguous-teardown, non-report-answer and every-outcome blocks; classify's driver loop keeps one answer set per driver. The interrupt file's normal-finish block stays: with the detection block gone it is the one run of the stand-in branch to a normal finish. Their ledger rows went and the rest were re-pointed by a line-map script over the two files' diff; hygiene green.
- 2026-10-22: from the driver survey: (d) bayes-results' row-reorder procedure block (dplyr-compat and vctrs-compat assert the procedure at every door) and the selection-rule print block with its snapshot file (the label block asserts `format()` exactly); (e) the quosure checks after exact identicals and guard lines implied by the exact checks beside them in grid-oracles, grid-failures, grid-results and bayes-results; (f) grid-results' tune-selector and default-metrics blocks. Kept on the survey's reading: the Bayesian desirability blocks in selection-rule-installed and bayes-oracles, each the only test of a NEWS claim.

## Decisions

## Review
