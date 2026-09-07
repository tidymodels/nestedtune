# M74: The check suite runs faster without dropping an assertion, and every CI leg's step cap returns to 30 minutes

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, GP4
- **Resolves:** —
- **Surface tier:** user-facing — the test suite and CI caps are internal, but the help-page examples the milestone lightens are documentation every user reads
- **Branch/PR:** `m074-suite-speed`

## Goal

Cut the time the check suite and the help-page examples take, so every CI leg's check step finishes in at most 24 minutes and the step cap returns to 30 everywhere, with every assertion the suite makes today still made.

## Scope

**In:** the reference loops the oracle files build by hand go through `memoised()`, and each selection-rule block runs its reference tuning stage once per configuration; blocks that rerun the same un-memoised orchestrator call twice (the rng "same seed" / "different seed" pairs for bayes, race and anneal; `test-nested-tune-bayes-results.R`'s two inline-control runs; `test-nested-tune-finalize.R`'s second grid run; `test-nested-final-fit-oracles.R`'s repeated fit-and-reference pair) share one run; `test-parallel-identity.R` reuses one 2-daemon and one 3-daemon pool across the blocks that only need a primed pool, with a snapshot probe before each reuse and private pools for the block that pollutes daemons and the block that kills one; `helper-time-budget.R` re-summed; a lighter shared example run across the 16 help pages that build one; `benchmarks/time-examples.R`; the check step cap back to 30 on the devel and windows legs with the yaml comment and the PROFILE test-doctrine slot updated; NEWS entry for the example change.

**Out:** deleting blocks whose claim another block asserts, and thinning the harness-testing files → M75. A disk-backed fixture cache shared across workers → stays in the M52-leftovers candidate row (measured 2026-09-07: 873 CPU-s on 4 workers against 690 serial, so cross-worker rebuilds are at most a quarter of the CPU and do not meet M57's falsifier). Smaller fixture data or fewer trees in the oracle fixtures → not touched, since the metric-separating and unstable fixtures' properties were found by search (M18 lesson). Vignette render time → unchanged (M66 owns its cap). The `R-CMD-check-hard.yaml` and `test-coverage.yaml` job caps → unchanged.

## Acceptance criteria

- [ ] AC1: `Rscript benchmarks/profile-tests.R 3` on the maintainer's machine reports a suite total (median of three runs) of at most 480 s on the branch head, with `fail 0 | skip 0` and a `pass` count no lower than the same command reports on a checkout of the branch point (690.3 s, 9324 passing at `6cfccb1`, 2026-09-07).
- [ ] AC2: Every call site of a `reference_*` helper under `tests/testthat/` — enumerated by `grep -n -E 'reference_(nested_[a-z_]*loop|[a-z_]*final_fit)\(' tests/testthat/*.R`, less the definitions in `helper-orchestration.R` — is reached through `memoised()`; and in each of the four selection-rule blocks (`test-nested-tune-grid-oracles.R` "AC1 selection rules", `test-nested-tune-bayes-oracles.R` "AC1 selection rules", `test-nested-tune-race-oracles.R` "AC1 selection rules", `test-nested-tune-sim-anneal-oracles.R` "AC1 selection rules") the reference tuning stage runs once per workflow-design-seed configuration with the three rules applied to that one run, the serial fixture-cache report showing one `reference_*` signature per configuration.
- [ ] AC3: `test-parallel-identity.R` starts at most four daemon pools per run — the sum of the `times` multipliers over the `start_daemons`, `start_daemons_undispatched` and `start_mixed_daemons` rows the `helper-time-budget.R` ledger attributes to that file — and before every block that reuses a shared pool a probe compares `daemon_state_snapshot()` (loaded namespaces, the options the package reads, `search()`, and the environment variables the package reads, per daemon) field for field against the snapshot taken when that pool started; the file's serial-versus-parallel identity assertions are unchanged in number and in what each compares. (RB tripwire: ip-touching)
- [ ] AC4: On the measured head (a pushed commit from which the merge-time branch head differs only under `cairn/`), the slowest of the five `R-CMD-check.yaml` legs' `check-r-package` steps is at most 24 minutes and the `Test coverage` step of `test-coverage.yaml` at most 14 minutes, each the median of three workflow attempts of that head read from `gh run view --json jobs`.
- [ ] AC5: The `check-r-package` step cap in `R-CMD-check.yaml` is 30 minutes on all five legs, and the yaml comment and the `cairn/PROFILE.md` test-doctrine slot state that figure.
- [ ] AC6: The active profile's verify slot is clean on the branch head — `devtools::check()` 0 errors, 0 warnings, 0 unjustified notes — and `air format --check` is clean on every file the branch touches (`git diff --name-only <branch point>`).
- [ ] AC7: `Rscript benchmarks/time-examples.R` (added here: `tools::Rd2ex()` per page under `man/`, each sourced in one process, with and without `\donttest`, three runs, medians) reports totals of at most 17 s without and 25 s with `\donttest` on the maintainer's machine, each pass completing with no error, against the figures the same script reports on a checkout of the branch point; every page that had an `\examples` section at the branch point still has one calling the same set of exported functions (the `NAMESPACE` export names found in that page's `\examples` at the two refs); `grep -l dontrun man/*.Rd` is empty; and `devtools::document()` produces no diff.

## Coverage

- AC1 → T1, T2, T3, T4, T6
- AC2 → T2
- AC3 → T4
- AC4 → T7
- AC5 → T7
- AC6 → T8
- AC7 → T5

## Tasks

- [ ] T1: Record the branch point: `Rscript benchmarks/profile-tests.R 3` output, and the last two default-branch runs' per-leg `check-r-package`, test, example and vignette times (2026-09-07 runs 34129642542 and 34077230243) in the work log.
- [x] T2: Wrap every `reference_*` call in `memoised()` (the seed-scoped call the reference takes must be inside the memoised expression so the key sees it); in the four selection-rule blocks build one reference per configuration and apply the three rules through `reference_select()`; check the serial cache report for one `reference_*` signature per configuration.
- [x] T3: Merge the rerun pairs: bayes-rng `:12`/`:52`, race-rng `:21`/`:49`, anneal-rng `:23`/`:50` (one seed-77 run per tuner, the different-seed run beside it); bayes-results `:249`/`:279` into one run under an inline control; finalize AC2 (`:220`) reads AC1's recorded run; final-fit-oracles `:65`/`:128` share one memoised fit-and-reference pair as `bayes_final_and_reference()` does.
- [ ] T4: In `helper-parallel.R` add `shared_daemons(n)` (start once per file, `daemon_state_snapshot()` at start, `expect_identical()` against it before each reuse) and `daemon_state_snapshot()`; convert the 19 blocks that only need a primed 2-daemon pool and the n=3 arms of BC1, BC10, BC12, BC13; BC9 and BC3 keep private pools; re-key the `helper-time-budget.R` ledger to the new `file:line` sites and re-sum per file against the CI caps (M16 lesson). Add a Wichmann-Hill kind check to the probe so a missing pin still fails (M07 lesson).
- [ ] T5: One example helper shape across the 16 pages that build a tuning run: `mtcars`, 2 outer × 2 inner folds, `num_comp = 1:2`, the rest of each example unchanged; `\donttest` untouched; `benchmarks/time-examples.R` committed with a header stating its method; `devtools::document()`; NEWS bullet.
- [ ] T6: `Rscript benchmarks/profile-tests.R 3` on the head; record the per-file table in the work log; if the total is above 480 s, name the file and return to T2–T4.
- [ ] T7: Revert the 40s in `R-CMD-check.yaml:141` to a flat 30, rewrite the cap comment's M72 paragraph to state the measurement, update `cairn/PROFILE.md` lines 47–49; push the measured head and read three attempts' step times.
- [ ] T8: `devtools::check()` and `air format --check` on the touched files.

## Work log

- 2026-09-07: created by /milestone-plan. Criteria audit ran in full mode (user-facing tier and an ip-touching tag) on two fresh [O] readers: ten findings on AC1–AC6 (pass floor added to AC1; AC2's second clause rewritten around the four selection-rule blocks since the cache report cannot see a rebuild under a different RNG state; AC3 counts ledger `times` multipliers over all three pool-starting helpers and names a snapshot helper; AC4 stated on the slowest leg; AC5's recording clause dropped; AC6 matched to the verify slot; the suggestion to pin the cap in `test-ci-workflows.R` declined as widening a checker over repo-internal artifacts) and five on AC7 (examples must complete, median of three, exported-function set pinned, `document()` no diff, branch point re-measured by the same script).
- 2026-09-07: plan gate chose a speed-only milestone with pruning planned as M75 over folding pruning in, because review cannot separate a timing regression from a dropped claim in one diff; falsified by M75 finding its deletions cannot be verified without M74's memoised fixtures.
- 2026-09-07: plan gate chose sharing one daemon pool with a state probe over keeping 26 restarts (M12's decline, whose promotion condition was such a probe), because 19 of 21 two-daemon starts serve blocks needing only a primed pool; falsified by a probe difference between blocks on a run whose identity assertions still pass, which would show the probe cannot see the leak M12 feared.
- 2026-09-07: plan gate chose a 24-minute bar with every cap back to 30 over keeping M72's 40s, because the yaml's own stance is that a leg nearing its cap is a suite to make faster; falsified by three attempts of the measured head with a leg above 24 on runners that were not slower than the branch point's.
- 2026-09-07: plan gate chose including the example pages over a candidate row, at the user's choice; falsified by a page whose lighter design changes what its printed output demonstrates.
- 2026-09-07: plan step 2 chose cheaper reference and rerun paths over a shared disk cache (M57's decline stands on today's 873-versus-690 CPU-second measurement) and over smaller fixture data (M18's searched-property fixtures); falsified by a per-worker report showing rebuilds above a quarter of the CPU, or by an oracle fixture whose property survives a smaller size.
- 2026-09-07: question gate — the race help page keeps inner v = 5 (the burn-in check refuses a race with no more inner resamples than its `burn_in` of 2) and goes to 2 outer folds; BC9 pollutes the shared 2-daemon pool in place as the last 2-daemon block instead of restarting; the n=3 arms of BC1, BC10, BC12 and BC13 become their own blocks on a shared 3-daemon pool, each rebuilding its serial reference, since mirai holds one pool at a time.
- 2026-09-07: T1 (CI part) — default-branch runs 34129642542 / 34077230243 `check-r-package` minutes: ubuntu release 26.9 / 26.3, devel 20.9 / 28.2, oldrel 20.5 / 25.2, macOS 22.9 / 22.0, windows 18.0 / 23.3; tests 17 / 17, 13 / 18, 13 / 16, 14 / 14, 11 / 14 min; examples 70 / 63, 59 / 76, 53 / 62, 62 / 43, 45 / 58 s; vignettes 165 / 161, 154 / 184, 143 / 164, 122 / 126, 125 / 157 s.
- 2026-09-07: T2 — every `reference_*` site goes through `memoised()` (18 sites); `reference_nested_loop()` keeps its `tuned` result and `reference_with_rule()` applies a rule to a cached reference, so the four selection-rule blocks build one reference per configuration; serial run of the 11 touched files: 57 signatures, 57 builds, 89 requests, one `reference_*` signature per configuration; 1110 pass, 0 fail, 0 skip.
- 2026-09-07: T3 — the seed-77 run is memoised in the bayes, race and anneal rng pairs (`first` the build, `second` direct); bayes-results' two control blocks are one run under `control_bayes(allow_par = TRUE)`; finalize AC2 reads AC1's memoised grid run; `grid_final_and_reference()` serves final-fit-oracles' two strands.

## Decisions

## Review
