# M114: The two Bayesian test files run in half their serial time

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP2
- **Resolves:** —
- **Surface tier:** internal — a change to test fixtures and benchmark records, which nothing outside the repo reads
- **Branch/PR:** m114-bayes-fixture-selectors

## Goal

The two heaviest Bayesian test files run in at most half their serial time with every test block's expectation count unchanged.

## Scope

The plan measured the cause on 2026-09-23. The candidate row blamed Gaussian-process fitting, but that fitting is under 3% of one Bayesian nested run. Of that run's profile samples, 65% sit in the recipes function `find_tune_id()`. It evaluates a bare-name step selector such as `x1` outside a selection context. The evaluation fails, and cli formats the failure message. A `tune_args()` call on `step_ns(x1)` took 10.8 ms and on `step_ns("x1")` 1.0 ms. A scratch copy put `"x1"` and `"x2"` in `bayes_workflow()`. It ran `test-time-series-bayes.R` in 18.8 s against 46.4 s. It ran `test-nested-tune-bayes-oracles.R` in 20.7 s against 47.7 s. Neither file failed.

**In:**
- `bayes_workflow()` and `srv_spline_workflow()` in `tests/testthat/helper-orchestration.R` name their spline columns by string.
- `benchmarks/recipes-tune-args-cost.R` (new) reproduces the per-call cost.
- `benchmarks/test-timing-baseline.md` gains an M114 section with both trees' timings and the per-block comparison.
- An issue for tidymodels/recipes is drafted with the measured figures. It is posted only on the user's approval at the review gate.

**Out:**
- The inline recipes in `test-nested-final-fit-identity.R` keep their bare names. Those tests check identity under that spelling, and the remaining cost stays with them.
- A lighter Gaussian-process engine or fewer iterations. The measured share does not justify either. The candidate row is absorbed here.
- A per-line covr comparison of the two trees. The plan gate dropped it, because the comparison reads trace files that worker processes write.
- The fix inside recipes itself belongs to the recipes maintainers, through the drafted issue.

## Acceptance criteria

- [ ] AC1: In `tests/testthat/helper-orchestration.R`, `bayes_workflow()` and `srv_spline_workflow()` pass every step's column selector as a string. A read of both function bodies at the head shows it.
- [ ] AC2: `test-time-series-bayes.R` and `test-nested-tune-bayes-oracles.R` each run serially in at most half their branch-point time. The figure is the median of three `benchmarks/profile-tests.R` passes per tree.
- [ ] AC3: One serial pass of the whole suite runs per tree. In testthat's results table, every test block, keyed by file and test name, has the same expectation count on both trees. No block fails, errors or skips on either tree.
- [ ] AC4: `benchmarks/recipes-tune-args-cost.R` prints the per-call time of `generics::tune_args()` on `step_ns(x1)` and on `step_ns("x1")`. On the head, the first figure is at least five times the second.

## Coverage

- AC1 → T2
- AC2 → T1, T3
- AC3 → T1, T3
- AC4 → T2

## Tasks

- [ ] T1: Measure the branch point before any fixture edit. Run three serial passes of `benchmarks/profile-tests.R` on mains power. Add `benchmarks/test-blocks.R`. From one serial pass, it writes one CSV row per test block: file, test, expectations, failed, skipped, error. Write the branch point's table beside it.
- [ ] T2: Add `benchmarks/recipes-tune-args-cost.R`. Change the selectors in both fixtures to strings. The comment above each fixture names the cost, the script and the date measured (the derived-figures rule). Run the two Bayesian files.
- [ ] T3: Measure the head the same way, on the same machine right after the branch point. Compare the two per-block tables by file and test name. Write the M114 section of `benchmarks/test-timing-baseline.md`. If the eleven heaviest files changed, re-cut `Config/testthat/start-first` in `DESCRIPTION`.
- [ ] T4: Search the tidymodels/recipes issues for an existing report on `find_tune_id()` or `tune_args()` cost. If none exists, draft the issue body in `cairn/milestones/M114-recipes-issue.md`, with the reproducer and the two figures. Nothing is posted before the user approves the text at the review gate.

## Work log

- 2026-09-23: created by /milestone-plan.
- 2026-09-23: criteria audit (reduced mode, fresh Opus reader) found nothing on AC1-AC3. It found that the draft covr criterion read worker-process trace files, outside the internal-tier standard. The gate dropped that criterion.
- 2026-09-23: plan chose string selectors over a lighter Gaussian-process engine or fewer iterations, because the fitting measured under 3% of a run. Falsified by a head profile where Gaussian-process fitting exceeds a quarter of a Bayesian run.
- 2026-09-23: plan gate chose the two helper fixtures over also changing the inline identity recipes, because those tests check the bare-name spelling. Falsified by `test-nested-final-fit-identity.R` entering the five heaviest files.
- 2026-09-23: plan gate chose per-block expectation counts over a per-line covr comparison as the no-loss evidence. Falsified by an `R/` code path that branches on how a recipe step names its columns.
- 2026-09-23: implement started on `m114-bayes-fixture-selectors`; no question gate, the plan left nothing open. Checkpoint: `benchmarks/test-blocks.R` written, branch-point runs started in a detached worktree at `1aef465`; T2's fixture edit and cost script drafted, not yet run.

## Decisions

## Review
