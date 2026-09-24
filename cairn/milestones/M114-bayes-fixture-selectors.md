# M114: The two Bayesian test files run in half their serial time

- **Status:** review
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
- The inline recipes in `test-nested-final-fit-identity.R` keep their bare names, except the two that stand in for the Bayesian record: `ns_workflow()` and the reordered recipe. The identity check compares selectors as deparsed text, so those two follow the record's string spelling, and one expected message changes to match. The other recipes check identity under the bare spelling, and their cost stays with them.
- A lighter Gaussian-process engine or fewer iterations. The measured share does not justify either. The candidate row is absorbed here.
- A per-line covr comparison of the two trees. The plan gate dropped it, because the comparison reads trace files that worker processes write.
- The fix inside recipes itself belongs to the recipes maintainers, through the drafted issue.

## Acceptance criteria

- [x] AC1: In `tests/testthat/helper-orchestration.R`, `bayes_workflow()` and `srv_spline_workflow()` pass every step's column selector as a string. A read of both function bodies at the head shows it.
- [x] AC2: `test-time-series-bayes.R` and `test-nested-tune-bayes-oracles.R` each run serially in at most half their branch-point time. The figure is the median of three `benchmarks/profile-tests.R` passes per tree.
- [x] AC3: One serial pass of the whole suite runs per tree. In testthat's results table, every test block, keyed by file and test name, has the same expectation count on both trees. No block fails, errors or skips on either tree.
- [x] AC4: `benchmarks/recipes-tune-args-cost.R` prints the per-call time of `generics::tune_args()` on `step_ns(x1)` and on `step_ns("x1")`. On the head, the first figure is at least five times the second.

## Coverage

- AC1 → T2
- AC2 → T1, T3
- AC3 → T1, T3
- AC4 → T2

## Tasks

- [x] T1: Measure the branch point before any fixture edit. Run three serial passes of `benchmarks/profile-tests.R` on mains power. Add `benchmarks/test-blocks.R`. From one serial pass, it writes one CSV row per test block: file, test, expectations, failed, skipped, error. Write the branch point's table beside it.
- [x] T2: Add `benchmarks/recipes-tune-args-cost.R`. Change the selectors in both fixtures to strings. The comment above each fixture names the cost, the script and the date measured (the derived-figures rule). Run the two Bayesian files.
- [x] T3: Measure the head the same way, on the same machine right after the branch point. Compare the two per-block tables by file and test name. Write the M114 section of `benchmarks/test-timing-baseline.md`. If the eleven heaviest files changed, re-cut `Config/testthat/start-first` in `DESCRIPTION`.
- [x] T4: Search the tidymodels/recipes issues for an existing report on `find_tune_id()` or `tune_args()` cost. If none exists, draft the issue body in `benchmarks/recipes-tune-args-issue.md`, with the reproducer and the two figures. Nothing is posted before the user approves the text at the review gate.

## Work log

- 2026-09-23: created by /milestone-plan.
- 2026-09-23: criteria audit (reduced mode, fresh Opus reader) found nothing on AC1-AC3. It found that the draft covr criterion read worker-process trace files, outside the internal-tier standard. The gate dropped that criterion.
- 2026-09-23: plan chose string selectors over a lighter Gaussian-process engine or fewer iterations, because the fitting measured under 3% of a run. Falsified by a head profile where Gaussian-process fitting exceeds a quarter of a Bayesian run.
- 2026-09-23: plan gate chose the two helper fixtures over also changing the inline identity recipes, because those tests check the bare-name spelling. Falsified by `test-nested-final-fit-identity.R` entering the five heaviest files.
- 2026-09-23: plan gate chose per-block expectation counts over a per-line covr comparison as the no-loss evidence. Falsified by an `R/` code path that branches on how a recipe step names its columns.
- 2026-09-23: implement started on `m114-bayes-fixture-selectors`; no question gate, the plan left nothing open. Checkpoint: `benchmarks/test-blocks.R` written, branch-point runs started in a detached worktree at `1aef465`; T2's fixture edit and cost script drafted, not yet run.
- 2026-09-23: T1 done. Branch point `1aef465` on mains power, three serial passes: 762.5, 762.2 and 827.8 s, pass 11387, fail 0, skip 0. Medians: `test-nested-tune-bayes-oracles.R` 59.9 s, `test-time-series-bayes.R` 57.6 s. Block table `benchmarks/test-blocks-1aef465.csv`: 977 blocks in 88 files, file and test keys unique.
- 2026-09-23: scope amended at a mini gate (user chose amend). The string fixtures failed two expectations in `test-nested-final-fit-identity.R`. The identity check compares selectors as deparsed text, and `ns_workflow()` and the reordered recipe still wrote bare names. Those two now use strings. The first Out bullet now names them. No criterion changed. The planned falsifier on `R/` spelling branches did not fire: `R/workflow-identity.R` deparses both spellings on one path.
- 2026-09-23: T2 done. `benchmarks/recipes-tune-args-cost.R` prints 7.40 ms for `step_ns(x1)` and 0.60 ms for `step_ns("x1")`, ratio 12.3. An Rprof of the bare call puts 76% of its time in `conditionMessage()` cli formatting inside `try()`. Both fixtures use strings. `test-time-series-bayes.R` ran in 19.6 s and `test-nested-tune-bayes-oracles.R` in 20.7 s, no failures. `devtools::test()` clean: 11387 expectations, 0 failed.
- 2026-09-23: checkpoint. T3 head passes running. T4 in part: issue search found only #1506 and #1296, both about wrong results. Draft in `M114-recipes-issue.md` still holds a placeholder for the head figures, and its example is not yet run.
- 2026-09-23: T3 done. Head (code of `507906d`, printed as `39f4232`) three serial passes on mains power: 549.1, 550.0 and 544.4 s, pass 11387. Median 72.0% of the branch point. `test-time-series-bayes.R` 17.9 s (31.1%), `test-nested-tune-bayes-oracles.R` 20.3 s (33.9%). Block tables joined on file and test: 977 of 977 match on expectation count, no failed, errored or skipped block. A planted one-count change was detected. `start-first` re-cut to the head's eleven heaviest. `devtools::test()` clean after the re-cut.
- 2026-09-23: minor amendment: T4's draft path moved from `cairn/milestones/M114-recipes-issue.md` to `benchmarks/recipes-tune-args-issue.md`. `cairn_validate` failed the first path as a milestone file with no ROADMAP row, and earlier upstream drafts live in `benchmarks/`.
- 2026-09-23: T4 done. No existing recipes report on the cost. The draft's example ran and printed 6.4 and 0.6 ms. It carries the head file times.
- 2026-09-23: claim audit: not owed — internal tier
- 2026-09-23: implement complete. Status set to review.

## Decisions

## Review

Review run 2026-09-23 on `m114-bayes-fixture-selectors` at `791bbfc`. The default branch had not moved from the branch point `1aef465`, so no merge was needed.

- AC1: read at `791bbfc`, `tests/testthat/helper-orchestration.R`. `srv_spline_workflow()` passes `"x1"` to its one `step_ns()`. `bayes_workflow()` passes `"x1"` and `"x2"` to its two `step_ns()` calls. Neither function has another step. Pass.
- AC4: `Rscript benchmarks/recipes-tune-args-cost.R` ran at `791bbfc` with recipes 1.4.0, R 4.6.1 and 200 calls per spelling. It printed 6.25 ms per call for `step_ns(x1)` and 0.60 ms for `step_ns("x1")`, ratio 10.4. The criterion needs at least 5. Pass.
- AC2: `benchmarks/profile-tests.R` ran three serial passes per tree on mains power. The branch point ran first, in a clean worktree at `1aef465`. The head ran next at `f88dd63`, whose code is that of `791bbfc`. Suite totals: branch point 694.8, 776.5 and 904.4 s, head 604.4, 593.8 and 605.3 s, pass 11387 and fail 0 in all six. Median file times: `test-time-series-bayes.R` 19.9 s against 52.0 s (38.3%), `test-nested-tune-bayes-oracles.R` 22.1 s against 59.7 s (37.0%). Both are at most half. Pass.
- AC3: `benchmarks/test-blocks.R` ran one serial pass per tree. Each table has 977 blocks in 88 files, 11387 expectations and no duplicate file and test key. Joined on file and test, 0 blocks are missing from either side and 0 differ in expectation count. No block failed, skipped or errored on either tree. A planted one-count change to the head table showed as 1 mismatch. Pass.
