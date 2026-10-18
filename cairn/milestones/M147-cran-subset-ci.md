# M147: CI runs the tests CRAN runs, with the Suggests and without them

- **Status:** review
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
- [x] T2: Add the second job, modeled on `R-CMD-check-hard.yaml`'s `check-no-suggests`, with `NOT_CRAN: false` on its check step.
- [x] T3: Correct the comments named in Scope: `tests/testthat/helper-cran.R` (the `NOT_CRAN` paragraph), the `env` comment and the header line of `R-CMD-check-hard.yaml`, and any such line in `R-CMD-check.yaml`. Confirm `test-ci-workflows.R` and `.github/ci-usage.py` still pass on the new file set.
- [x] T4: Before the first push, run `R CMD check --as-cran` locally with `NOT_CRAN=false` and no `NESTEDTUNE_FULL_SUITE`, once with the Suggests and once with a library holding only the hard dependencies. Note the result and the skip count in the work log.

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
- 2026-10-18: T2 and T3 done. Full `devtools::test()` clean (no failures, no skips), `air format --check .` clean, `test-ci-workflows.R` and `ci-usage.py`'s reader pass on the final file set, and `git diff main` shows only comment lines changed in `R-CMD-check.yaml` and `R-CMD-check-hard.yaml`. The hard header's claim that tune imports Suggests was read from `packageDescription("tune")` (dials, recipes, tailor, tibble). `R-CMD-check.yaml`'s vignette paragraph now names the new Suggests job as a third place the vignettes run.
- 2026-10-18: T4 done. Local `R CMD build` then `R CMD check --as-cran --no-manual` at cf3c02a6 with `NOT_CRAN=false` and no `NESTEDTUNE_FULL_SUITE`. With the Suggests: vignettes built and re-built, status 1 NOTE (CRAN incoming feasibility: new submission, dev version, a check CI turns off), testthat FAIL 0, SKIP 121, PASS 7704, 52 skips with the smoke-layer reason. Hard-only library (pak `dependencies = NA` into a separate library, plus R's own library, which also holds pkgload): the first run stopped at "Packages suggested but not available", because `check-r-package` sets `_R_CHECK_FORCE_SUGGESTS_` and `_R_CHECK_CRAN_INCOMING_` to false when unset and the local run did not. Rerun with both false: status OK, FAIL 0, SKIP 225, PASS 5206, 52 skips with the smoke-layer reason.
- 2026-10-18: claim audit: not owed — internal tier.

## Decisions

## Review

- Route (d): no PR, main unmoved since the cut (1e1cb499). Copilot round off. Each criterion ends in "its run on the milestone's PR passes", and the PR opens only at step 8 (D-138), so no box is ticked before the merge question. The static half of each criterion is recorded here, and the CI half is read at step 8, before the merge, from the PR's runs.
- AC1 static (2026-10-18, `yaml::read_yaml` of the file at f5605df1): job `check-cran-suggests`; its `setup-r-dependencies` step has no `dependencies` key; its `check-r-package` step has `env: NOT_CRAN: false`, `args` `c("--no-manual","--as-cran")`, and `build_args` without `--no-build-vignettes`, `args` without `--ignore-vignettes`; no `NESTEDTUNE_FULL_SUITE:` line in the file. Local supporting run (T4): 52 skips with the smoke-layer reason. CI half pending.
- AC2 static (same read): job `check-cran-no-suggests`; `dependencies: '"hard"'`, `extra-packages` exactly rcmdcheck, testthat, knitr, rmarkdown; `NOT_CRAN: false` on the check step, same `args`, no switch. Local supporting run (T4): status OK, 52 skips with the smoke-layer reason. CI half pending.
- AC3 static (`git diff main..HEAD` over `R-CMD-check.yaml` and `R-CMD-check-hard.yaml`, filtered to added or removed lines not starting with `#`): no lines. CI half pending.
- Gate (at af5bf91d): `cairn_validate` all checks passed; `devtools::document()` no diff; `pkgdown::check_pkgdown()` no problems; six gating prose sweeps exit 0; README unchanged; no new top-level file; no NEWS entry owed (internal tier, no user-visible change). `devtools::check()` rerun after the fixes below, at cf0b636c: 0 errors, 0 warnings, 0 notes (14m04s). `test-ci-workflows.R` passes and `air format --check .` is clean there.
- spawned: diff-bug, blame-history, prior-review.
- diff-bug #1: PROFILE.md's added sentence made "Its legs set `NESTEDTUNE_FULL_SUITE`" read as the CRAN file — fix now, fixed cf0b636c.
- diff-bug #2: D-077 says only `pkgdown.yaml` runs the vignettes in full off macOS, now false, and no decision recorded — fix now, fixed cf0b636c (D-116).
- diff-bug #3: `TESTTHAT_CPUS: 4` departs from CRAN's two cores while the header claims CRAN conditions — fix now, fixed cf0b636c (unset, testthat's default of 2, read from `testthat:::default_num_cpus`).
- diff-bug #4: `R-CMD-check.yaml`'s vignette comment omits that the no-Suggests job also builds the vignettes — fix now, fixed cf0b636c.
- diff-bug #5: `helper-cran.R` says "one without" Suggests and that other jobs run "the full suite" — fix now, fixed cf0b636c (hard job still installs what tune imports; reworded to "`NOT_CRAN` is true and this helper skips nothing").
- diff-bug #6: the new test does not pin the setup step's `dependencies` — fix now, fixed cf0b636c (pins added, planted `'"hard"'` in the Suggests job reads wrong); flow-style `env:` or `GITHUB_ENV` writes going unseen — reject, false as a defect: the file's readers read block style by stated design; a quoted `'false'` failing the test — reject, style: it fails loudly, never silently.
- diff-bug #7: `benchmarks/cran-check-timing.md` still says every CI job runs the full suite — fix now, fixed cf0b636c (one added sentence); LESSONS line 25 — planned change, corrected at this milestone's hygiene per Scope.
- diff-bug #8: header says setup-r sets `NOT_CRAN` unconditionally, but it does so only when unset — fix now, fixed cf0b636c.
- diff-bug #9: the indentation-reading comment stayed on `job_uses()` after the logic moved to `job_lines()` — fix now, fixed cf0b636c.
- diff-bug #10: `use-public-rspm` set in one job only, and the hard file's "runs this job's setup" — rspm: reject, style (equivalent on ubuntu); wording: fix now, fixed cf0b636c (same as blame-history #4).
- diff-bug #11: the Suggests job's cap has no measured run of its own — fix now, fixed cf0b636c (comment says the Suggests install is unmeasured and binary; step cap added, see prior-review #1); the job's first PR run is recorded at step 8.
- diff-bug #12: CI half of AC1-AC3 unverified — noted, already recorded above.
- blame-history #1: job-only cap on a job that installs the Suggests, against PROFILE's "the step bound is the guarantee" — fix now, fixed cf0b636c (20-minute step cap on both check steps).
- blame-history #2: D-077 stale — fix now, fixed cf0b636c (D-116, same as diff-bug #2).
- blame-history #3: M118's "every CI job runs the full suite" reversed without a decision; LESSONS line 25 stale — D-116 records it (fix now, fixed cf0b636c); LESSONS: planned change at hygiene.
- blame-history #4: hard file's line saying the CRAN file runs its setup with `NOT_CRAN` false is wrong, setup runs with it true — fix now, fixed cf0b636c.
- blame-history #5: hard header omits `any::rcmdcheck` from what the setup names — reject, false: the sentence names Suggests, and rcmdcheck is not one.
- blame-history #6: `ci-usage-baseline.md` lists the old workflow set — reject, false: it is a dated record of the 2026-08-11 to 09-10 window.
- prior-review #1: no step-level cap on the check steps (LESSONS M16, PROFILE) — fix now, fixed cf0b636c (20 minutes each).
- prior-review #2: Suggests install unmeasured in the job cap — fix now, fixed cf0b636c (same as diff-bug #11).
- prior-review #3: no `concurrency` block, against M011 — fix now, fixed cf0b636c (copied from `R-CMD-check.yaml`).
- prior-review #4: hard file's `NOT_CRAN` wording — fix now, fixed cf0b636c (same as blame-history #4).
- prior-review #5: D-077 stale — fix now, fixed cf0b636c (D-116).
- prior-review #6: custom `artifact-name` values carry no comment saying what they buy (PR #30) — fix now, fixed cf0b636c.
- prior-review #7: LESSONS M73 says `R_KEEP_PKG_SOURCE` is set by "both check workflows" — follow-up at this milestone's hygiene (LESSONS is corrected there).
- prior-review #8: PROFILE's `TESTTHAT_CPUS` sentence does not name the new file — fix now, fixed cf0b636c (one sentence saying it sets none).
