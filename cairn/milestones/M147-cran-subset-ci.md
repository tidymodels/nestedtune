# M147: CI runs the tests CRAN runs, with the Suggests and without them

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — CI jobs over this repository, which no user of the package relies on
- **Branch/PR:** m147-cran-subset-ci

## Goal

Two CI jobs run `R CMD check --as-cran` with `NOT_CRAN` false, so the test subset CRAN runs is checked on every pull request.

## Scope

**In:** a new workflow file, `.github/workflows/R-CMD-check-cran.yaml`, with two ubuntu-latest R-release jobs. One installs the Suggests and builds the vignettes, like CRAN's main check. One installs the hard dependencies only, like CRAN's noSuggests check. Its triggers carry the same `paths-ignore` list as the other check workflows, which `.github/ci-usage.py` reads. Comments that say no CI job runs the CRAN subset are corrected, in `tests/testthat/helper-cran.R` and in the two existing check workflows. The hard workflow's header line saying no Suggests are installed is corrected too, because tune pulls in some of them.

**Out:** the new jobs go in their own file because `tests/testthat/test-ci-workflows.R` pins one vignette-building leg and one `NESTEDTUNE_FULL_SUITE` line in `R-CMD-check.yaml` (D-076, D-077). That file's legs stay as they are. macOS and windows CRAN-condition legs are not planned, since CRAN's own flavors check those at submission. A job at the testthat floor stays with its `[low]` candidate row. A CI bound on the CRAN test step's CPU time is not planned, because runner time varies with the runner (LESSONS 2026-09-03). The LESSONS line saying no job runs the CRAN path is corrected at this milestone's hygiene.

## Acceptance criteria

- [ ] AC1: A new workflow file, `.github/workflows/R-CMD-check-cran.yaml`, has a job whose `setup-r-dependencies` step leaves `dependencies` at its default, which installs the Suggests. The job sets `NOT_CRAN` to `false` for its check step, does not set `NESTEDTUNE_FULL_SUITE`, and runs `R CMD check --as-cran` with the vignettes built and checked. Its run on the milestone's PR passes, and the testthat output of that run, read from the job's log or its uploaded check results, reports at least one skip whose reason is `Outside the CRAN smoke layer; set NESTEDTUNE_FULL_SUITE=true to run it`.
- [ ] AC2: The same file has a second job whose `setup-r-dependencies` step sets `dependencies: '"hard"'` and whose `extra-packages` lists only rcmdcheck, testthat, knitr and rmarkdown. It sets `NOT_CRAN` to `false` for its check step, does not set `NESTEDTUNE_FULL_SUITE`, and runs `R CMD check --as-cran`. Its run on the milestone's PR passes, and its testthat output reports at least one skip with that reason.
- [ ] AC3: This milestone changes no line of `.github/workflows/R-CMD-check.yaml` or `.github/workflows/R-CMD-check-hard.yaml` other than comment lines, and each job of those two files passes on the milestone's PR.

## Coverage

- AC1 → T1, T4
- AC2 → T2, T4
- AC3 → T3

## Tasks

- [x] T1: Write the file and its first job. Copy the triggers and `paths-ignore` from `R-CMD-check-hard.yaml`. Set a job cap from the hard job's measured run and say how it was set, and use `upload-results` so the testthat output is readable on a passing run.
- [ ] T2: Add the second job, modeled on `R-CMD-check-hard.yaml`'s `check-no-suggests`, with `NOT_CRAN: false` on its check step.
- [ ] T3: Correct the comments named in Scope: `tests/testthat/helper-cran.R` (the `NOT_CRAN` paragraph), the `env` comment and the header line of `R-CMD-check-hard.yaml`, and any such line in `R-CMD-check.yaml`. Confirm `test-ci-workflows.R` and `.github/ci-usage.py` still pass on the new file set.
- [ ] T4: Before the first push, run `R CMD check --as-cran` locally with `NOT_CRAN=false` and no `NESTEDTUNE_FULL_SUITE`, once with the Suggests and once with a library holding only the hard dependencies. Note the result and the skip count in the work log.

## Work log

- 2026-10-17: created by /milestone-plan.
- 2026-10-17: tier check: milestone — the request (items 1, 4 and 5 of the release-readiness list) includes CI jobs and an export review, and asked for a plan.
- 2026-10-17: question set: which CI jobs should run the CRAN subset — both jobs, with and without the Suggests.
- 2026-10-17: criteria audit (reduced mode) returned three findings. AC2's "installs no Suggests beyond testthat, knitr and rmarkdown" named nothing that lists the installed set, and tune's own dependencies pull in dials, R6, recipes, survival, tailor, tibble and yardstick. AC2 now names the setup step's `dependencies` and `extra-packages` values. AC1 and AC3 needed "a new job", since AC3 forbids the skip in the existing jobs. Two jobs in `R-CMD-check.yaml` would break `test-ci-workflows.R:133-190`, so the jobs moved to a new file and AC3 became a no-change promise over the two existing files.
- 2026-10-17: plan gate chose a new workflow file over new legs in `R-CMD-check.yaml`, because that file's tests and D-076 pin one vignette leg and one `NESTEDTUNE_FULL_SUITE` line; falsified by the new file's triggers drifting from the other check workflows unnoticed.
- 2026-10-17: inbox sweep: 1 open issue (#91), no overlap with this milestone.
- 2026-10-18: implement started; branch m147-cran-subset-ci cut from main at 1e1cb499.
- 2026-10-18: T1 done. `R-CMD-check-cran.yaml` with job `check-cran-suggests`: ubuntu release, P3M binaries, default `dependencies`, step-level `NOT_CRAN: false`, explicit `--as-cran` args, vignettes built and checked, 30-minute cap from the hard job's run plus the measured vignette cost. Choices: own `artifact-name` and `snapshot-artifact-name`, because both jobs share matrix-free index 0 and the action's default names would collide; no `concurrency` block, matching `R-CMD-check-hard.yaml`. `ci-usage.py`'s reader accepts the new file's lists.
- 2026-10-18: checkpoint, T2 and T3 not yet ticked. T2's job `check-cran-no-suggests` is written, and `test-ci-workflows.R` gains `job_lines()` and a test that both CRAN jobs set no `NESTEDTUNE_FULL_SUITE` and set `NOT_CRAN: false` and `--as-cran` on their check step (planted `true`, a removed line and an added switch each read wrong). T3's comment edits are written in `helper-cran.R`, both existing workflows and PROFILE.md. The full `devtools::test()` run is still going.

## Decisions

## Review
