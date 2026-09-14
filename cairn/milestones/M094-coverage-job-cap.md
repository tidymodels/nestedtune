# M094: The coverage job runs under a 30-minute cap

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — a CI job cap and a benchmark script, which no external consumer of the package relies on
- **Branch/PR:** m094-coverage-job-cap

## Goal

The `test-coverage` job cap goes from 20 to 30 minutes, the step cap `R-CMD-check.yaml` gives its non-windows legs.

## Scope

**In:** The milestone changes `timeout-minutes` in `.github/workflows/test-coverage.yaml` and the comment above it. It also changes the two lines of `benchmarks/test-time-budget.R` that state a 20-minute cap (7 and 73).

The plan measured the job on 2026-09-14 with `gh run list --workflow test-coverage.yaml` and `gh run view --json jobs`. The "Test coverage" step ran 12.0 to 19.5 minutes on the completed runs of 2026-09-12 to 2026-09-14. Setup before the step took about 1.2 minutes. The hang-trace stamps of run 34862873009 give 76 files summing 4,234 s over 4 workers in a 1,063 s span. The workers have no idle time, so re-ordering has nothing to recover (M076 found the same for the check legs).

**Out:**
- The windows leg's last 1.3 minutes and the check-time vignette rebuild stay in their candidate row, re-cut at this plan.
- The plan gate rejected skipping slow test files under covr to keep the 20-minute cap (work log). A later speed need starts from the M079 leftovers row on suite time.
- Comments that describe a run under the old cap stay as written, because they record past events. These are `tests/testthat/test-suite-hygiene.R:56`, `helper-time-budget.R:6`, `helper-hang-trace.R:6` and `benchmarks/stress-daemon-ledger.md`.
- The caps in `R-CMD-check.yaml` do not change.

## Acceptance criteria

- [ ] AC1: `.github/workflows/test-coverage.yaml` bounds the `test-coverage` job at `timeout-minutes: 30`.
- [ ] AC2: `grep -nE '[0-9]+[ -]minute|1200' benchmarks/test-time-budget.R` prints nothing, and `Rscript benchmarks/test-time-budget.R` exits 0.

## Coverage

- AC1 → T1
- AC2 → T2

## Tasks

- [x] T1: Set `timeout-minutes: 30` at `.github/workflows/test-coverage.yaml:38`. Rewrite the comment above it (lines 31-37) and keep the hang rationale. Give the step range with the procedure and date of its measurement (the derived-figures rule). Say that the figure now matches the step cap `R-CMD-check.yaml` declares for non-windows legs. Make sure that the file still parses as YAML.
- [ ] T2: Rewrite `benchmarks/test-time-budget.R:7` and `:73` to name the workflow files that declare the caps, not a figure. PROFILE keeps every cap figure in the workflow that declares it. Do not write the key name `timeout-minutes` in those lines, because AC2's grep matches it. Run the script from the repo root.

## Work log

- 2026-09-14: created by /milestone-plan from the coverage half of the candidate row on the windows leg and the `test-coverage` cap. PR #106 hit the 20-minute cap twice on 2026-09-14.
- 2026-09-14: the criteria audit (reduced mode, internal tier) returned 3 findings, all fixed before the gate. AC1 lost a run-id quotation in the yaml comment, an instrument property that moved to T1. A criterion on the PR's coverage run was cut, because that run exists only after merge approval. A repo-wide grep with hand-listed exceptions narrowed to the one file that states the cap in the present tense.
- 2026-09-14: a re-audit of the revised wording found that the grep word `minute` matched `timeout-minutes`, so the pattern became `[0-9]+[ -]minute|1200`.
- 2026-09-14: plan gate chose a 30-minute cap over skipping slow test files under covr. The workers are already busy, and skipping changes what the coverage report measures. Falsified by the step nearing 30 minutes on the default branch, or by a hang that costs a review because 30 minutes let it run.
- 2026-09-14: plan gate chose 30 over 25 minutes, because 25 leaves about 4 minutes over the slowest recent step as tests grow. Falsified by the step staying under 20 minutes across the next month of runs.
- 2026-09-14: implement started on branch m094-coverage-job-cap. The question gate was skipped, because the plan left nothing open.
- 2026-09-14: T1 done. The job cap is 30 and the comment gives the measured step range with its procedure and date. `yaml::read_yaml()` parses the file and reads 30. `devtools::test()` was not run, because the change touches no R code.

## Decisions

## Review
