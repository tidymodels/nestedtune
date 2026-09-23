# M112: Vignettes built and checked on the macOS check leg alone

- **Status:** in-progress
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — a CI setting change that no user of the package relies on
- **Branch/PR:** m112-vignettes-one-leg

## Goal

The four `R-CMD-check.yaml` legs other than macOS skip building and checking the vignettes, so their check step has room for M111's tests under its cap.

## Scope

**In:** The `check-r-package` step's `build_args` and `args` in `.github/workflows/R-CMD-check.yaml`, keyed on the `macos-latest` leg. A block in `tests/testthat/test-ci-workflows.R` for them. The step-cap comment in that yaml, and the test-doctrine slot of `cairn/PROFILE.md`. A D-entry, because no D-entry covers the CI caps today (M094 review).

**Out:** A fixture cache shared across the test workers stays in the M56/M57 candidate row. Measured on `main` at `d870105`, repeat builds cost 110 s of 1184 s of file time at four workers. `R-CMD-check-hard.yaml` and `pkgdown.yaml` keep building the vignettes. The step caps stay 30 and 40 min. Unblocking M111 stays with M111's resume.

## Acceptance criteria

- [ ] AC1: In `.github/workflows/R-CMD-check.yaml`, the matrix has exactly one `macos-latest` entry, and the `check-r-package` step's `build_args` and `args` are each one expression keyed on `matrix.config.os == 'macos-latest'`. For that entry they give `c("--no-manual","--compact-vignettes=gs+qpdf")` and `c("--no-manual","--as-cran")`. For the other four entries they give `c("--no-manual","--no-build-vignettes")` and `c("--no-manual","--as-cran","--ignore-vignettes")`, tested.
- [ ] AC2: The step-cap comment in `R-CMD-check.yaml` states that, of its five legs, only `macos-latest` builds and checks the vignettes. It also states that `R-CMD-check-hard.yaml` checks them and `pkgdown.yaml` knits them. The test-doctrine slot of `cairn/PROFILE.md` states the same scope in one clause.
- [ ] AC3: `devtools::test()` passes, and `devtools::check()` gives 0 errors, 0 warnings, and no note absent from the check of the default branch at the branch point.

## Coverage

- AC1 → T1, T2
- AC2 → T3
- AC3 → T4

## Tasks

- [x] T1: Set `build_args` and `args` on the `check-r-package` step (`.github/workflows/R-CMD-check.yaml:191-196`) as AC1 states. Use non-empty strings on both sides of each `&& ||`, since GitHub reads `''` as false.
- [x] T2: Add a block to `tests/testthat/test-ci-workflows.R` that checks the AC1 values. It reads the matrix entries and the two step lines by indentation, as `job_uses()` does. Plant each defect and see the block fail: flags given to macOS, flags missing on a non-macOS leg, `--as-cran` dropped, and a second `macos-latest` entry.
- [x] T3: Rewrite the step-cap comment's vignette sentences for AC2, from the phase times of job 106991147696 in run 35801023421. Add the PROFILE clause. Write the D-entry on which leg checks the vignettes and why.
- [x] T4: Run `devtools::test()`, `devtools::check()`, and `devtools::check()` on the default branch at the branch point for the note baseline. Time a local `R CMD build` plus `R CMD check` with and without the non-macOS flags, and record the figures in the work log.

## Work log

- 2026-09-22: created by /milestone-plan from the "CI check steps near their caps" candidate row, for M111's block. On `main` after M110, the check step ran ubuntu release 25.9 and 28.8, oldrel-1 28.3, windows 32.5, and devel 19.1 to 28.6 min. In job 106991147696, building the vignettes took 2.4 min and re-checking them 2.4 min of 28.8.
- 2026-09-22: criteria audit (reduced) returned findings on AC1 and AC2, both fixed before the gate. AC1 named the test as its promise and did not pin the flag values, and setting `args` drops `--as-cran` unless it is repeated. AC2's "macOS alone" read as repo-wide, but `R-CMD-check-hard.yaml` also builds the vignettes. AC3 returned nothing.
- 2026-09-22: plan gate chose the vignettes on one leg over a fixture cache shared across the test workers, because the vignettes cost about 4.8 min per leg in a settings change, against about 2 min for the cache in a harness change. Falsified by a vignette failure that only a skipped leg's platform shows.
- 2026-09-22: plan gate chose macOS release as the leg that keeps the vignettes over ubuntu release and windows, because its step ran 16 to 22 min against a 30 min cap. Falsified by macOS nearing its cap.
- 2026-09-22: plan gate chose to read the CI saving from the PR run at review and from the first run on `main`, over adding a local timing criterion, because the PR opens only after approval and local minutes run about 4 times faster than CI. Falsified by a non-macOS leg's step on `main` after merge running no faster than before.
- 2026-09-22: implement started on `m112-vignettes-one-leg`, cut from `main` at `aaf2279`. Question gate skipped, since the plan left nothing open.
- 2026-09-22: checkpoint, T1 to T3 written and not yet checked off. The new test block failed on the old yaml and passes on the new one, and each of the four planted defects failed it at its own line. The full `devtools::test()` run is still going.
- 2026-09-22: T1 to T3 done. `devtools::test()` passed with 0 failures in 8.2 min, and the workflow test file passed 10 of 10 on the final tree. The comment's figures come from the step times of run 35801023421: macOS 21.4 min was the shortest of the five legs.
- 2026-09-22: T4 timing, local, in sequence at `ca51211`. With the macOS flags, `R CMD build` took 52 s and `R CMD check` 521 s. With the other legs' flags, they took 1 s and 457 s, so 115 s less in total. Both checks gave 1 NOTE, CRAN incoming feasibility. The other-leg flags add one line to that NOTE: "Package has a VignetteBuilder field but no prebuilt vignette index." The branch and baseline `devtools::check()` runs are being redone. The first branch run wrote an empty log, and the baseline showed a `.git` NOTE that came from the worktree.
- 2026-09-22: T4 done. `devtools::check()` gave 0 errors, 0 warnings and 0 notes on the branch at `61b5622`, and the same on a `git archive` export of `aaf2279`, the branch point.
- claim audit: not owed — internal tier
- 2026-09-22: all tasks checked, status set to review.
- 2026-09-22: review defect return 1, from the step-4 consistency gate. `cairn_validate` failed `weight caps`: `cairn/PROFILE.md` is 120 lines against a cap under 120, after T3's clause grew it by one line. Status back to in-progress. The fresh suite, the check and the three reviewers were stopped before they reported.

## Decisions

## Review
