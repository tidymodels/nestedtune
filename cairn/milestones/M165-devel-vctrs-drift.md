# M165: Keep the devel-vctrs test choice from drifting

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — a CI workflow and a marker comment in three test files; no package user relies on either
- **Branch/PR:** —

## Goal

Remove the two places where `devel-vctrs.yaml` can drift without a signal, while its push and pull-request runs stay limited to the vctrs test files.

## Scope

**In:** a marker line in `test-vctrs-compat.R`, `test-dplyr-compat.R` and `test-nested-results-set-compat.R`; the test step of `.github/workflows/devel-vctrs.yaml` selecting the `tests/testthat/test-*.R` files that hold that line, stopping when none does, and computing its whole-suite switch from `GITHUB_EVENT_NAME` and `inputs.full`; the workflow-level concurrency group keyed on those raw values; the workflow's comments and `cairn/PROFILE.md`'s concurrency sentence rewritten to match; a D-entry narrowing D-119.

**Out:** whole-suite runs on push or pull request, which this plan's question set ruled out (the weekly schedule and a full dispatch keep them, D-119). A drift test in `test-ci-workflows.R`, declined at this plan's question set in favor of simplifying the workflow; no row. Watching more test files on push, such as `test-nested-tune-bayes-oracles.R`: a file joins by taking the marker line, a later choice under D-119's falsifier; no row.

## Acceptance criteria

- [ ] AC1: On this milestone's PR `pull_request` run, `devel-vctrs.yaml` runs exactly the test files that `grep -lxF '# devel-vctrs.yaml runs this file on every push and pull request.' tests/testthat/test-*.R` lists at the PR head, and that command lists `test-vctrs-compat.R`, `test-dplyr-compat.R` and `test-nested-results-set-compat.R`. Evidence: the run passes, its log prints `Whole suite: FALSE`, and testthat's report in that log shows no context other than `vctrs-compat`, `dplyr-compat` and `nested-results-set-compat`.
- [ ] AC2: In a copy of the repo with `test-vctrs-compat.R` renamed to `test-renamed-plant.R`, the test step's R code selects that file and the other two watched files. With the marker line removed from all three, it stops with an error before `testthat::test_local()` is called.
- [ ] AC3: `grep -nE 'vctrs-compat|dplyr-compat|nested-results-set-compat' .github/workflows/devel-vctrs.yaml` prints no line.
- [ ] AC4: The `group:` line of the workflow-level `concurrency:` block in `.github/workflows/devel-vctrs.yaml` is four `${{ }}` blocks joined by `-`, holding `github.workflow`, `github.ref`, `github.event_name` and `inputs.full`, each a bare property with no operator.
- [ ] AC5: The test step's `env:` block holds one entry, mapped from `inputs.full`, read from the YAML. The step's switch code, run locally with (`GITHUB_EVENT_NAME`, full value) set to (`schedule`, ""), (`workflow_dispatch`, "true"), (`workflow_dispatch`, "false"), (`push`, "") and (`pull_request`, ""), prints `Whole suite: TRUE`, `TRUE`, `FALSE`, `FALSE` and `FALSE` in that order.

## Coverage

- AC1 → T1, T2
- AC2 → T2, T4
- AC3 → T3
- AC4 → T3
- AC5 → T2, T4

## Tasks

- [ ] T1: Add the line `# devel-vctrs.yaml runs this file on every push and pull request.` to `tests/testthat/test-vctrs-compat.R`, `test-dplyr-compat.R` and `test-nested-results-set-compat.R`, as a whole line after each file's header comment.
- [ ] T2: Rewrite the "Run the tests against it" step of `.github/workflows/devel-vctrs.yaml`. Its `env:` maps `inputs.full` alone; the R code sets the switch to true on `schedule`, and on `workflow_dispatch` when the full value is "true". When the switch is false, it reads `tests/testthat/test-*.R`, keeps the files holding the marker as a whole line, stops with an error naming the marker when none does, prints the selected files, and passes `testthat::test_local()` a filter built from their names with regex characters escaped. It prints `Whole suite:` as now.
- [ ] T3: Key the concurrency group on `github.workflow`, `github.ref`, `github.event_name` and `inputs.full`. Rewrite the header paragraph that names the three files, and the concurrency comment, from a same-session read of the new step, to point at the marker line and the raw key. Edit the `devel-vctrs.yaml` concurrency sentence on `cairn/PROFILE.md` line 44 in place, adding no line (the file is at 119 of its <120 cap).
- [ ] T4: Copy the step's R code to a scratch script and run it locally: the five cases of AC5, then the rename plant and the no-marker plant of AC2 on a copy of `tests/testthat/`, each plant seen to give its stated result. Record the outcomes in one work-log line.
- [ ] T5: Append a D-entry narrowing D-119: the concurrency group keys on `github.event_name` and `inputs.full`, and a test file joins the push-time watch by its marker line. Record the side effect: a scheduled run and a full dispatch no longer share a group, nor do a `full` false dispatch on the default branch and a push to it.

## Work log

- 2026-10-31: created by /milestone-plan.
- 2026-10-31: tier check: not run — work named at the question set.
- 2026-10-31: question set: what to plan — the devel-vctrs drift guard, without bringing back whole-suite runs on push and pull request.
- 2026-10-31: question set: simplify the workflow or add a drift test (checker-regress shape on `test-ci-workflows.R`) — simplify the workflow.
- 2026-10-31: idea vet: gap — the hand list of three files; reading taken: a marker line in each watched file selects them, so a rename keeps the file and an empty selection stops the run. gap — the concurrency group repeats the step's switch; reading taken: key the group on the raw event and input values the switch reads. No flaw.
- 2026-10-31: plan gate chose a marker line in each watched file over a `-compat` file-name convention because a file renamed out of the convention would still drop silently; falsified by a watched file losing its marker in an edit that no run flags.
- 2026-10-31: plan gate chose keying the group on raw `github.event_name` and `inputs.full` over keeping the copied switch expression because two runs in one group then share every value the switch reads; falsified by a three-file run cancelling or replacing a whole-suite run.
- 2026-10-31: collision: absorbed candidate "Guard the devel-vctrs filter from drift" (M153 review). D-119 narrowed at T5, not superseded. M153 (done) shipped the three-file filter; this extends it. Inbox: 1 open issue (#91, parked), 0 open PRs, no overlap.
- 2026-10-31: lessons used: 2026-09-02 (M50, extended M53/M58/M67/M79/M88/M153) on CI pushes and dispatch concurrency; 2026-09-11 (M86, extended M89) on a checker whose domain can empty.
- 2026-10-31: criteria audit (reduced mode, fresh Opus reader): AC1 claimed every push and pull request and a log listing no task printed; narrowed to this PR's run against a grep of marker files, the print moved to T2, contexts named instead of files. AC2 narrowed to two named plants, search limited to `test-*.R`. AC3 none. AC4 narrowed to four bare properties. AC5 narrowed to a one-entry `env:` and five named cases with empty full values. Side effect of AC4 moved to T5.
- 2026-10-31: no changelog entry: CI-only, as at M153.

## Decisions

## Review
