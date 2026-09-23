# M112: Vignettes built and checked on the macOS check leg alone

- **Status:** review
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

- [x] AC1: In `.github/workflows/R-CMD-check.yaml`, the matrix has exactly one `macos-latest` entry, and the `check-r-package` step's `build_args` and `args` are each one expression keyed on `matrix.config.os == 'macos-latest'`. For that entry they give `c("--no-manual","--compact-vignettes=gs+qpdf")` and `c("--no-manual","--as-cran")`. For the other four entries they give `c("--no-manual","--no-build-vignettes")` and `c("--no-manual","--as-cran","--ignore-vignettes")`, tested.
- [x] AC2: The step-cap comment in `R-CMD-check.yaml` states that, of its five legs, only `macos-latest` builds and checks the vignettes. It also states that `R-CMD-check-hard.yaml` checks them and `pkgdown.yaml` knits them. The test-doctrine slot of `cairn/PROFILE.md` states the same scope in one clause.
- [x] AC3: `devtools::test()` passes, and `devtools::check()` gives 0 errors, 0 warnings, and no note absent from the check of the default branch at the branch point.

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
- 2026-09-22: return fixed. The T3 clause now shares lines with the existing text, so `cairn/PROFILE.md` is 119 lines and `cairn_validate` passes. Only that file changed, so the suite and check results from `ca51211` and `61b5622` still cover the code. Status set to review.
- 2026-09-22: review defect return 2, at step 3 on AC2. AC2 asks the PROFILE test-doctrine slot to state the scope "in one clause". `cairn/PROFILE.md:50` states it in two sentences, split in T3 for the prose lint. Status back to in-progress. AC1 was verified first. The fresh suite, the check and the three reviewers were stopped before they reported. The light gate checks passed at `75fc491`: `cairn_validate`, `document()` with no diff, `check_pkgdown()`, and all six prose sweeps.
- 2026-09-22: return 2 fixed. `cairn/PROFILE.md:50` now states the vignette scope in one sentence, with `R-CMD-check-hard.yaml` and `pkgdown.yaml` in a relative clause. The file is 119 lines and `cairn_validate` passes. No code changed. Status set to review.
- 2026-09-22: gate fixes F1, F3, F5 and F6 landed at `3d228b3`. `devtools::test()` then passed with no failed tests.
- step-7 approval: m112-vignettes-one-leg approved for merge

## Decisions

## Review

- AC1 (2026-09-22, head `75fc491`): the matrix has one `{os: macos-latest` entry. A YAML parse of the `check-r-package` step gives `build_args` and `args` as one `matrix.config.os == 'macos-latest'` expression each, with the four flag vectors AC1 names. The test block "R-CMD-check.yaml builds and checks the vignettes on macOS alone" passes, and the file passes 10 of 10. The block failed on the pre-change yaml and on each of the four planted defects (work log, T2).
- AC1 still holds at `cf01af1`: `git diff 75fc491 cf01af1` touches only `cairn/`.
- AC2 (2026-09-22, head `cf01af1`): `R-CMD-check.yaml:104` says "Of these five legs, only macos-latest builds and checks the vignettes." Lines 113-115 say `R-CMD-check-hard.yaml` builds and checks them and `pkgdown.yaml` knits them. `cairn/PROFILE.md:50` states the same scope in one sentence, the other two workflows in a relative clause.
- Gate (head `cf01af1`): `cairn_validate` exit 0. `devtools::document()` left no diff. `pkgdown::check_pkgdown()` found no problems. All six gating prose sweeps exit 0. README.Rmd and NEWS.md are untouched, since the change has no user-visible surface. No new top-level files. No DESIGN.md principle changed, so `cairn_impact` is skipped.
- AC3 (2026-09-22, head `cf01af1`): `devtools::test()` exit 0 with no failed tests. `devtools::check()` gave 0 errors, 0 warnings and 0 notes in 9m 47s. The baseline check of the branch point `aaf2279`, from a `git archive` export at T4, also gave 0 notes, so no note is new.
- Reviewers: [S] blame-history, 0 findings, and it traced the removed "windows under 24" sentence to the candidate row that M112 absorbed. [S] prior-review, 0 findings, no past review on per-leg vignette flags. [O] diff-bug, 8 findings, ranked:
  - F1: `R-CMD-check-hard.yaml` installs hard dependencies only. So `nested-cv.Rmd`, `results.Rmd` and `tuners.Rmd` stop at their missing-package notice there. The comment (lines 113-115), `PROFILE.md:50` and D-076's Decision overstate that job as a second check. Verified against `R-CMD-check-hard.yaml:74-81` and `vignettes/*.Rmd` `knit_exit()`.
  - F2: CI never runs the new test, because `.github/` is build-ignored and the test skips there. This is the file's existing convention.
  - F3: the single-macOS count at `test-ci-workflows.R:140` matches one spelling only. It misses `os: 'macos-latest'` and `- os: macos-latest`.
  - F4: macOS was chosen from one run with a 1-minute margin over oldrel-1. The M76 medians rank macOS above oldrel-1 and ubuntu release.
  - F5: D-076's Context says "the slower legs", but M111's block note records ubuntu release alone.
  - F6: the `step_value()` header says "the line after". The code searches the whole step for one `key:` line.
  - F7: `PROFILE.md:50` is not wrapped at about 120 characters.
  - F8: the `--as-cran` behavior on the four legs is known only from a local run. CI sets `_R_CHECK_CRAN_INCOMING_=false`.
- Triage at the gate (user chose "Fix 4, then merge"): F1 fixed now. The yaml comment and `PROFILE.md:50` now say the hard job runs the vignettes without tidymodels or ranger. They say `pkgdown.yaml` knits them in full. D-077 corrects D-076. F3 fixed now: the macOS count matches flow and block forms, quoted or not. Four planted spellings each fail at `test-ci-workflows.R:144`. F5 fixed now in D-077. F6 fixed now: the helper header is corrected. F2 rejected, because it is the file's existing convention for `.github/` tests. F4 rejected, because D-076 already names the macOS step near its cap as its falsifier. F7 rejected, because wrapping puts `PROFILE.md` at its 120-line cap. F8 noted, and the PR's CI run settles it.
- AC1 and AC2 after the fixes: the workflow test file passes 10 of 10. `R-CMD-check.yaml:104` still says only macos-latest builds and checks the vignettes. Lines 113-117 still name `R-CMD-check-hard.yaml` as building and checking them and `pkgdown.yaml` as knitting them. `PROFILE.md:50` is still one sentence. `cairn_validate` exit 0, and the yaml parses.
