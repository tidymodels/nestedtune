# M152: The suite drops tests that repeat a shared path, cannot fail, or test a dependency

- **Status:** review
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

- [x] AC1: Join the `benchmarks/test-blocks.R` tables of the branch point and the head on file and test name. Each block that the head lacks, or whose expectation count changed, falls in a category, (a) to (f). For each one, a head block runs the same package path, or the block calls no package function.
- [x] AC2: `benchmarks/coverage-lines.R` gives each line of `R/` the same hit-or-miss status at the branch point and at the head, compared on `file` and `pos`.
- [x] AC3: `git diff --stat <branch point>..HEAD -- R man NEWS.md README.Rmd README.md vignettes` is empty.
- [x] AC4: Take each of `param_info`, `control` and `select` in turn. A mutation makes `dispatch_folds()` pass that formal's default in both of its `.args` lists. With each mutation, the merged identity run of (a) fails.
- [ ] AC5: Run `benchmarks/profile-tests.R 1` on one machine at the branch point and at the head, side by side. The head's suite total is at least 60 s lower.
- [ ] AC6: The profile's `verify` slot is clean at the head.

## Coverage

- AC1 → T1, T2, T3, T4, T5, T7
- AC2 → T1, T7
- AC3 → T7
- AC4 → T2
- AC5 → T1, T7
- AC6 → T8

## Tasks

- [x] T1: Record the branch point. Run `benchmarks/test-blocks.R`, `benchmarks/coverage-lines.R` and `benchmarks/profile-tests.R 1` on it in the background.
- [x] T2: Do (a). Plant the three mutations of AC4 in a scratch copy of `R/parallel.R`, and record which expectation fails for each.
- [x] T3: Do (b) and (c).
- [x] T4: Do (d) for the driver, RNG, final-fit and model-spec files.
- [x] T5: Do (d) for the reader, compat, parallel and misc files, then (e) and (f).
- [x] T6: Update the `helper-time-budget.R` rows of each deleted or merged wait, and `Config/testthat/start-first`.
- [x] T7: Run the three scripts at the head and compare. Write a prune ledger to the Review section. It has one row per removed or changed block, with its category and the head block that covers it. Add the coverage and timing results.
- [x] T8: Run the `verify` slot.

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
- 2026-10-22: from the compat, reader and print survey: (d) dplyr-compat's slice, `[` and bind_rows single-form blocks and the id-prefixed column block (the verb table holds them), the kept-tibble loop and the no-scheme print loop trimmed to one form per door; vctrs' vec_rbind block; extract-procedure's dots block, print's two summary dots blocks, collect-readers' and map-readers' dots blocks (the dots-barrier probe calls every registered method); eval-time's scalar AC8 block; resamples-specs' stratified-inner, groups-whole and single-row blocks; print's design-summary block and its M116 rule loop trimmed to one rule; plot's no-tuned-parameters block, the set type-refusal lines and the bad-id loop trimmed to one id. (e) two lines in collect-readers and map-readers. (f) resamples-specs' character-and-factor block and map-readers' rank_results/fit_best block. Kept: design-support's two SUPPORTED loops, since each case is the only test of a README "Yes" cell.
- 2026-10-22: T6: no test file was removed, so `Config/testthat/start-first` names only real files; the ledger was kept in step task by task, hygiene green.
- 2026-10-22: T5 verify: full suite at 7040fc68, 0 failures, 0 errors. AC3: `git diff --stat 5feebda2..7040fc68` over R, man, NEWS.md, README and vignettes is empty.
- 2026-10-22: minor amendment: the prune ledger is committed as `benchmarks/prune-ledger-5feebda2-7040fc68.csv` beside the block and coverage tables, not in the Review section, which review alone writes.
- 2026-10-22: T7: block tables 5feebda2 1245 blocks / 15309 expectations, 7040fc68 1150 / 13269; 102 blocks gone and 44 counts changed, all 146 classified in the ledger (a 3, b 17, c 17, d 85, e 12, f 12), each with its covering head block. Both tables fail the one interrupt block "an interrupted run leaves no fold executing" with 3 expectations; it passes when its file runs alone at the head, so the failure is the concurrent runs', at both trees. AC2: 6352 lines at both trees, 128 uncovered at both, 0 lines change status on `file` and `pos`.
- 2026-10-22: T7 timing: `profile-tests.R 1` at both trees side by side on AC power: 5feebda2 893.4 s, 7040fc68 821.7 s, 71.7 s lower, short of AC5's 100 s. The remaining in-scope candidates are small (the final-fit race file 5.2 s, selection-metric 8.3 s); the larger files left are kept for stated reasons (the interrupt file 63 s, the design-support loops 20 s as the only tests of README "Yes" cells). Stop for the user on AC5.
- 2026-10-22: substantive amendment: AC5's bar lowered from 100 s to 60 s, and the runs made side by side, at the user's choice at the AC5 stop over keeping 100 s with more cuts or dropping AC5. The amended text: "Run `benchmarks/profile-tests.R 1` on one machine at the branch point and at the head, side by side. The head's suite total is at least 60 s lower."
- 2026-10-22: re-audit: AC5 (reduced) — nothing; the reader notes that side-by-side totals are contention figures and that 11.7 s of margin on one run per tree can fall to noise at review, where `profile-tests.R 3` would steady the comparison.
- 2026-10-22: T8: the verify slot is the full suite at 7040fc68 (0 failures, 0 errors) and `air format --check .` clean at the head; nothing outside `cairn/` and `benchmarks/` changed after 7040fc68.
- 2026-10-22: claim audit: not owed — internal tier.
- 2026-10-22: status review; handed to /milestone-review.

## Decisions

## Review

Review pass 1, 2026-10-22, on the branch at 35ca73f8, fixes at 4f13334f. Route (d): no PR, main not moved since the cut; Copilot round off.

spawned: diff-bug, blame-history, prior-review, ripple

- diff-bug #1: NEWS's claim that tune's generics refuse a final fit lost both tests; AC6 also asserted the package's own S3 registry, which is package behavior, not a dependency's — fix now, fixed 4f13334f (registry-only AC6 block restored)
- diff-bug #2: BC12 on the ANOVA racer alone contradicts D-079's "IP2 stays evidenced for every tuner at two daemons" — fix now, fixed 4f13334f (both racers, ledger row `times = 2` restored)
- diff-bug #3: `benchmarks/test-time-budget.R` reads the removed `CLASSIFY_BUDGET_PRE_M16_S` and halts — fix now, fixed 4f13334f (constant restored)
- diff-bug #4: `?nested_workflow_map` says `rank_results()` and `fit_best()` do not accept the set, and its test went — fix now, fixed 4f13334f (registry check)
- diff-bug #5: D-010's class choice (not a `tune_results`) no longer asserted — fix now, fixed 4f13334f
- diff-bug #6: the map-checks header said the map restores the stream on every exit, but the entry checks run before its restore point — fix now, fixed 4f13334f; the further claim that scope (c)'s premise fails for entry refusals is rejected — false: before the restore point no check draws, after it every draw is undone, so the seed lines cannot show that no fold ran
- diff-bug #7: scope (c) left the same seed lines in fit-resamples-checks and map-checks :219-230 — follow-up, row "Clear two leftovers of the test prune"
- diff-bug #8: the print block's comment named the rule it does not run — fix now, fixed 4f13334f
- diff-bug #9: the race-oracles header overstated which blocks run one racer — fix now, fixed 4f13334f
- diff-bug #10: the race-checks header miscounted the blocks that run both racers — fix now, fixed 4f13334f
- diff-bug #11: two line references in `helper-time-budget.R` comments went stale (classify :723/:729, detection :180/:182/:187) — fix now, fixed 4f13334f
- diff-bug #12: the deleted structure blocks took the guard that keeps each table's derived check list from emptying — fix now, fixed 4f13334f (one guard line per table)
- diff-bug #13: the profile asks for factor/character and length-one cases, and the diff removed two for `nested_resamples()` — reject, planned change: scope (d) and (f) name them, the profile's edge-case floor binds new exports, and the zero-row case stays
- diff-bug #14: the merged identity block did not show `param_info` and the rule in force — fix now, fixed 4f13334f (two expectations: a candidate past `deg_free()`'s default bound of 5 scored, and the recorded rule)
- blame-history #1: grid-results' tune_results block guarded D-010 — fix now, fixed 4f13334f (as diff-bug #5)
- blame-history #2: the final-fit generic refusals guarded D-014 — fix now, fixed 4f13334f (as diff-bug #1)
- blame-history #3: BC12, the racing selection-rule oracle and the desirability refusal went to one racer against D-079 — fix now for BC12, the desirability refusal and the shared-check table (both read each racer's registry entry), fixed 4f13334f; reject for the selection-rule oracle — false: D-079 keeps the racing selection-rule oracle, which stays on the ANOVA racer
- blame-history #4: the merged block moved BC6 and BC15 from grid to Bayes, and the mutations change both `.args` lists together — reject, false: `dispatch_folds()` forwards the formals the same way for every tuner, and real fold payloads always take the leaning branch; the other list serves stand-in payloads only
- blame-history #5: map-readers' rank_results/fit_best block — fix now, fixed 4f13334f (as diff-bug #4)
- blame-history #6: classify's teardown and non-report blocks and detection's warn-once block — reject, false: classify :93 holds the same errorValue 19, :322 the same answer list, and detection's grid run on the uncancellable pool asserts one warning over three folds
- blame-history #7: the grid "fires before any fitting" property is no longer tested — reject, false: the removed seed lines could not show it, and the refusals stay tested by the metrics and grid-column blocks
- blame-history #8: vec_rbind's cover is not the dplyr table — reject, false: the ledger's cover is the vctrs block that runs `expect_no_record(vctrs::vec_rbind(res, res))`
- blame-history #9: the set final fit's workflow check is only partly covered — reject, false: the set file's loop asserts each row's workflow entry
- blame-history #10: event-level AC3 also separated the level's plumbing — reject, planned change ((f)); AC2's closed-form oracle checks sensitivity at both levels
- blame-history #11: the Bayesian final-fit and fit-resamples RNG blocks — reject, planned change ((d))
- blame-history #12: the selection-rule print is no longer snapshotted — reject, false: the label block asserts `format()` exactly and `print()` is `cat(format())`, asserted by the long-goal block
- blame-history #13: no inner-stratified oracle is left — reject, planned change ((d)); the grouped inner oracle takes the same path
- blame-history #14: the scalar eval_time block — reject, planned change ((d))
- blame-history #15: skip-heavy's "TRUE"/"T" block — reject, planned change ((f))
- blame-history note: the plan's Out cites D-079 for the two-versus-three daemon blocks — reject, false: D-079 keeps grid's IP2 "at two counts", the two- and three-daemon BC1 blocks
- prior-review #1: M132 F2 wanted each racer its own block — reject, planned change ((b))
- prior-review #2: M107 kept separate racer route blocks — reject, planned change ((d)); the forwarding block now asserts each method's wrapped workflow, shown to fail on a planted defect
- prior-review #3: M48's control and dots blocks — reject, false: grid-checks keeps them, and each driver's table fires `check_dots_control` and `check_control`
- prior-review #4: fixture-cache's comment premise is no longer pinned — reject, planned change ((f)): the line asserted rlang's hashing
- prior-review #5: eval-time's scalar AC8 block — reject, planned change ((d))
- prior-review #6: detection's warn-once block — reject, false (as blame-history #6)
- prior-review #7: racer coverage halved — fix now in part (as blame-history #3), fixed 4f13334f; the rest planned change ((b))
- ripple #1: `R/parallel.R` near :618 cites test-parallel-detection.R for stand-in payloads — follow-up, row "Clear two leftovers of the test prune" (an `R/` edit is outside AC3)
- ripple #2: race-checks line 1 overstated its coverage — fix now, fixed 4f13334f
- ripple #3: pre-existing ledger labels that match no test — follow-up, the same row's item (3)
- ripple #4: the race-oracles header exception — fix now, fixed 4f13334f (as diff-bug #9)
- ripple #5: pre-existing: eval-time :545 cites a layout note dplyr-compat does not hold — follow-up, M155's test-comment scope
- snapshot: tests/testthat/_snaps/selection-rule.md — deleted with its block, which scope (d) names; follow-up none

Evidence (fresh, at 4f13334f unless named):

- AC1: `benchmarks/test-blocks.R` at 5feebda2 gives 1245 blocks and 15309 expectations, at 4f13334f 1153 and 13367. Joined on file and test, 99 blocks are gone and 47 changed count. All 146 fall in a category (a 3, b 14, c 17, d 88, e 12, f 12). Each row names its covering head block, or the reason its removed lines call no package function of their own, in `benchmarks/prune-ledger-5feebda2-4f13334f.csv`. AC2's equal line coverage shows that every `R/` line those blocks ran still runs. Both tables fail the one block "an interrupted run leaves no fold executing", with 3 expectations each. It passes when its file runs alone, so the failure comes from running beside other suites, at both trees.
- AC2: `benchmarks/coverage-lines.R` gives 6352 lines at 5feebda2 and at 4f13334f, joined on `file` and `pos` with none unmatched. 128 are uncovered at both, and no line changes hit-or-miss status. The tables are `benchmarks/coverage-lines-5feebda2.csv` and `-4f13334f.csv`.
- AC3: `git diff --stat 5feebda2..19fc9eeb -- R man NEWS.md README.Rmd README.md vignettes` prints nothing.
- AC4: three scratch copies of 4f13334f each set one formal to its default in both `.args` lists of `dispatch_folds()`. With `param_info` set to NULL, the merged block "BC6, BC11, BC15" fails at :504 (per column, 3 columns) and :506 (whole object). With `control` set to NULL it fails the same way. With `select` set to `selection_rule()` it fails at :504 (2 columns) and :506.
