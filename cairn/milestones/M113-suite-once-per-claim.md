# M113: The suite runs in three quarters of its serial time with no line of coverage lost

- **Status:** planned
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, GP2
- **Resolves:** —
- **Surface tier:** user-facing, because the help of `nested_tune_grid()` and `nested_resamples()` and `NEWS.md` change what they say is tested
- **Branch/PR:** —

## Goal

Cut the test suite's serial time to three quarters of today's by removing repeated fits, with every line of `R/` that covr reports covered today still covered.

## Scope

**In:** The three tuner time-series files run on the rolling-origin design alone. The help, `NEWS.md` and D-079 say so. The per-tuner selection-rule blocks for Bayes and annealing go. The success-path RNG blocks for Bayes, racing and annealing go. The identity file's three-daemon section keeps the grid check alone. Fresh fits that repeat a cached fixture read the cache. Daemon-pool probes that read one healthy pool share it. A removals ledger. Serial, coverage and CI measurements before and after.

**Out:** Re-ordering or splitting test files, because M76 measured nothing to recover. Moving the harness tests (`test-sweep-prose.R`, `test-hang-trace.R`, `test-suite-hygiene.R`, `test-covr-traces.R`, `test-ci-workflows.R`) out of the default suite, dropped at the plan gate because they cost 9 s of 1276 locally and skip under `R CMD check`. The `test-parallel-interrupt.R:108` flake and the other M079 leftovers, whose candidate row stays. The fixture-cache key gaps, whose candidate row stays. A lighter Bayes fixture engine, which becomes a candidate row if T7's figures show Bayes still dominant. Any CI cap.

## Acceptance criteria

- [ ] AC1: `Rscript benchmarks/profile-tests.R 3`, the branch head's copy of the script, is run on both trees. Its suite total on the branch head, the median of three serial runs, is at most 75% of its total on the branch point `5088fb7`. Both are run on the same machine and R version with every Suggests package installed, and each of the six runs reports 0 failures.
- [ ] AC2: No line under `R/` that `covr::package_coverage()` reports with at least one hit on the branch point is reported with zero hits on the branch head. Both runs are serial, with every Suggests package installed, `NOT_CRAN=true`, and the daemon-trace sidecar merged as `test-coverage.yaml` does. Lines are matched by file and by position among lines not opening with `#'`, because the branch changes no other line of `R/`. A line whose reading flips is re-run once on each tree and counts only if both readings repeat.
- [ ] AC3: Every claim, one `expect_*()` call, that a `test_that()` block asserted at `5088fb7` and whose block's description is gone or body differs at the head, is asserted by a surviving block. The blocks are enumerated from `git diff 5088fb7..HEAD -- tests/testthat`. The exceptions are the claims D-079 names dropped: (a) reference-loop identity for `nested_tune_bayes()`, the two racers and `nested_tune_sim_anneal()` on the sliding-window, sliding-index and sliding-period outer designs. (b) Agreement with tune's selector for the Bayes and sim-anneal selection-rule blocks. (c) Serial-parallel identity at three daemons for BC10, BC12 and BC13. (d) Caller-RNG-survival and no-RNG-state on the success path in the Bayes, race and anneal rng files.
- [ ] AC4: `devtools::test()` on the branch head on macOS, with every Suggests package installed and `NOT_CRAN=true`, reports 0 failures and 0 skips.
- [ ] AC5: For each of the six orchestrators, `nested_final_fit()` and `nested_workflow_map()`, the time-series paragraphs in the help of `nested_tune_grid()`, `nested_resamples()` and `augment()`, and the `NEWS.md` entry on time-series designs, name exactly the outer designs on which a `test-time-series-*.R` file compares that function against its reference.
- [ ] AC6: On the measured head, the ubuntu release leg's `Running ‘testthat.R’` elapsed time, the median of three `R-CMD-check.yaml` attempts, is at most 80% of the median of three attempts of run 35883406135 on `5088fb7`. The measured head is a pushed commit from which the merge-time branch head differs only under `cairn/`. The CI bar is looser than AC1's because the leg varies about 20% on identical code (M51 lesson).

## Coverage

- AC1 → T1, T7
- AC2 → T1, T7
- AC3 → T2, T3, T4, T5, T6, T7
- AC4 → T7
- AC5 → T2
- AC6 → T1, T8

## Tasks

- [ ] T1: Baselines on `5088fb7`. Run `Rscript benchmarks/profile-tests.R 3` and record it in `benchmarks/test-timing-baseline.md` with its conditions. Run covr serially with the sidecar merged and save the per-line hits under `benchmarks/`, keyed by file and non-roxygen position. Run `gh run rerun 35883406135` twice, read the three attempts' `testthat.R` elapsed figures from `gh api .../attempts/<n>/jobs`, and log their median.
- [ ] T2: `test-time-series-{bayes,race,anneal}.R` loop over the rolling-origin design alone. `TS_DESIGNS` keeps all four for `test-time-series-designs.R`. Reword the help at `R/nested-tune-grid.R:108-117` and `R/nested-resamples.R:40-49`, the `augment()` help, and `NEWS.md:24-33` from the tests' own loops. D-079 is on `main` from the plan commit. Re-read `Config/testthat/start-first` against the new file times.
- [ ] T3: Selection-rule loops. Drop the Bayes (`test-nested-tune-bayes-oracles.R:434`) and anneal (`test-nested-tune-sim-anneal-oracles.R:308`) M69 blocks. Grid's (`test-nested-tune-grid-oracles.R:313`) and race's (`test-nested-tune-race-oracles.R:341`) explicit `best` step reads the cached fixture, and the `procedure$select` assertion stays.
- [ ] T4: RNG duplicates. Drop the success-path "caller's state survives" and "no RNG state" blocks in `test-nested-tune-{bayes,race,sim-anneal}-rng.R`. Grid's copies and every error-path copy stay. Drop the fold-order and ambient-kind blocks in the race and anneal rng files. Bayes keeps them for its control seed slot.
- [ ] T5: Cache the fresh repeats. `test-nested-fit-resamples-oracles.R:108,258` read `fit_resamples_results()`. `test-nested-tune-grid-oracles.R:112,175` and `test-nested-tune-grid-rng.R:25,49` go through `memoised()` where the M42 lesson allows. `test-nested-workflow-map-readers.R:161,210,298` read `broken_set_results()`. `test-nested-workflow-map-oracles.R:94` reads the cached hand call. `test-time-series-designs.R:494` reuses the runs at `:446`. `test-nested-resamples-memory.R` computes `measure(V_VALUES)` once. `test-nested-final-fit-rng.R:342,369,418` fold onto the shared envelope.
- [ ] T6: Daemon work. `test-parallel-identity.R:889-1022` keeps BC1 alone at three daemons, and the serial references for the two-daemon blocks are built once per file. BC4 (`:120`) reads a fabricated worker count. `test-parallel-detection.R:55,420` share one heterogeneous pool and `:122,138,396` one primed pool. Re-key the `helper-time-budget.R` ledger and keep `test-suite-hygiene.R` green.
- [ ] T7: Write the removals ledger in this file (block, file:line at `5088fb7`, surviving block or D-079 clause). Then measure AC1, AC2 and AC4 on the head and put the figures in `benchmarks/test-timing-baseline.md`.
- [ ] T8: Push the measured head, read three `R-CMD-check.yaml` attempts per the M51 lesson, and log AC6's figure with the run id and attempt numbers.

## Work log

- 2026-09-23: created by /milestone-plan. Serial suite at `5088fb7` measured by `devtools::test()` under `TESTTHAT_PARALLEL=FALSE`: 1276.4 s over 1004 blocks, 0 failed, 0 skipped. The four `test-time-series-*.R` files took 299 s, `test-nested-tune-bayes-oracles.R` 95 s, `test-parallel-identity.R` 85 s. In CI run 35883406135, the ubuntu release `testthat.R` took 25 min of a 26 min check step, and the macOS step took 29 of its 30 min cap.
- 2026-09-23: criteria audit ran in full mode on a fresh Opus reader. Two decisions went to the gate (the time-series cut against D-074 and D-078, and the single-attempt CI baseline). Six one-fix findings were applied (AC1 script copy and 0-failure runs, AC2 line matching with sidecar and flip re-run, AC3 domain and claim definition, AC4 platform, AC5 entry-point list).
- 2026-09-23: plan gate chose the three tuners on the rolling-origin design alone over keeping all four, because the outer design never reaches tuner code and grid and fit_resamples keep all four. Falsified by a tuner failing on a sliding design that passes on rolling-origin.
- 2026-09-23: plan gate chose dropping the per-tuner selection-rule and success-path RNG duplicates over caching their repeats, because each exercises one shared call under a second tuner. Falsified by a tuner-specific draw or selection reaching either shared site.
- 2026-09-23: plan gate chose grid alone at three daemons over all four tuners, because every tuner keeps its two-daemon identity and no tuner code reads the worker count. Falsified by a tuner's result changing with the daemon count.
- 2026-09-23: plan gate chose re-running main's run twice for a median over the single attempt, because the leg varies about 20% on identical code. Falsified by the three attempts agreeing within a minute.
- 2026-09-23: plan chose leaving the harness tests in the default suite over moving them to a CI job, because they cost 9 s locally and skip under `R CMD check`. Falsified by a harness file passing 30 s serially.

## Decisions

## Review
