# M088: Prose that fails the sweep cannot merge

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** M086, M087
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — a CI job, a test and profile slots over the repo's own documentation sources
- **Branch/PR:** m088-prose-sweep-gate

## Goal

Every gating mode of `benchmarks/sweep-prose.R` runs on every pull request and on every local test run from the source tree, red on any hit.

## Scope

The six gating invocations are `Rscript benchmarks/sweep-prose.R`, `--spans`, `--plain`, and each of the three with `--roxygen`. The authoring side is already covered: the SimpleEnglish plugin's session hook injects its rules into every session in this repo; this milestone adds the check that the result obeyed them. Under `R CMD check` the tests run from the built tarball, which `.Rbuildignore` strips `benchmarks/` from, so the test skips there and the workflow is the gate a PR meets.

**In:** the test over the real pages and roxygen sources; `.github/workflows/prose-sweep.yaml`; the `cairn/PROFILE.md` slot lines; the planted-defect demonstration.

**Out:** new clauses → a later docs milestone; a pass rule on the reader report → the existing panel-rate candidate row; the sweep script's prose-definition gaps → the existing candidate row.

## Acceptance criteria

- [ ] AC1: `tests/testthat/test-sweep-prose.R` runs the six gating invocations over the real pages and roxygen sources, asserts each prints `clean`, and first asserts `--paragraphs` lists at least one paragraph for each of the six pages and `--roxygen --paragraphs` at least one for `R/nested-tune-grid.R`; it skips with the reason `sweep-prose.R not in the source tree` when the script is absent from the package root testthat resolves.
- [ ] AC2: `.github/workflows/prose-sweep.yaml` runs on `push` and `pull_request` with the `paths-ignore` filter `cairn/**`, `CLAUDE.md`, `.claude/**` on both triggers, executes the six gating invocations, and is shown to discriminate: a run on a commit of the milestone branch that adds one sentence containing a semicolon to `README.Rmd` fails, and a run on the commit reverting it passes.
- [ ] AC3: `cairn/PROFILE.md`'s `verify` slot names `Rscript benchmarks/sweep-prose.R --plain` (and `--roxygen --plain` after roxygen changes) as a check before a task touching `vignettes/`, `README.Rmd`, `R/` or `man-roxygen/` is checked off; its `consistency-gate` slot lists the six gating invocations clean; and its `test-doctrine` filter list names `prose-sweep.yaml` beside the five workflows it names today.
- [ ] AC4: `Rscript -e 'devtools::check()'` reports 0 errors, 0 warnings, 0 notes.

## Coverage

- AC1 → T1
- AC2 → T2, T3
- AC3 → T4
- AC4 → T5

## Tasks

- [x] T1: Extend `tests/testthat/test-sweep-prose.R` (M086) with the real-source block: the non-empty `--paragraphs` assertions first, then the six invocations, each asserted `clean`; the skip reason unchanged.
- [ ] T2: Write `.github/workflows/prose-sweep.yaml` on the shape of `R-CMD-check.yaml` (concurrency block, the `paths-ignore` filter on both triggers, a job cap with its measurement in a comment, `setup-r` with no package install beyond base R); `python3 .github/ci-usage.py` accepts the filter.
- [ ] T3: Push a commit adding a semicolon sentence to `README.Rmd`, record the red run id in the work log, revert it, record the green run id.
- [ ] T4: Edit `cairn/PROFILE.md`: the `verify` line, the `consistency-gate` line, and `prose-sweep.yaml` in the `test-doctrine` filter list.
- [ ] T5: `devtools::check()` clean; `cairn_validate` clean.

## Work log

- 2026-09-11: created by /milestone-plan.
- 2026-09-11: criteria audit ran in reduced mode (bounded-promise, proportionality and instrument questions). Must-fix, fixed: AC1 named `--paragraphs` for `R/nested-tune-grid.R`, which the non-roxygen mode lists nothing for (now `--roxygen --paragraphs`); the profile's named filter list would have gone stale (AC3 now adds `prose-sweep.yaml`). Noted: the semicolon probe exercises the `--plain` leg only, one exemplar for the wiring.
- 2026-09-11: plan gate chose a CI workflow plus the test plus the profile slots over the test and slots alone because a PR opened without a local test run is otherwise caught only by the coverage leg, which never gates; falsified by the workflow's minutes exceeding what `.github/ci-usage.py` shows the suite saving, in which case the workflow folds into an existing leg.
- 2026-09-11: plan gate chose mechanical enforcement over a profile rule alone because the session hook already states the rules and M084 and M085 left 66 semicolons on the help pages, which no clause of theirs bound; falsified by nothing short of the sweeps never firing across ten merged PRs.

- 2026-09-11: T1 done. The real-source block asserts `--paragraphs` non-empty for the six pages and `--roxygen --paragraphs` for `R/nested-tune-grid.R`, then the six invocations `clean`; 34 pass. Discrimination shown locally: one appended semicolon sentence in `README.Rmd` fails the `--plain` leg with `README.Rmd:90: semicolon: …`, reverted.

## Decisions

## Review
