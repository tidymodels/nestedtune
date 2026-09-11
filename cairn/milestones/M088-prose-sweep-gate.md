# M088: Prose that fails the sweep cannot merge

- **Status:** review
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
- [x] T2: Write `.github/workflows/prose-sweep.yaml` on the shape of `R-CMD-check.yaml` (concurrency block, the `paths-ignore` filter on both triggers, a job cap with its measurement in a comment, `setup-r` with no package install beyond base R); `python3 .github/ci-usage.py` accepts the filter.
- [x] T3: Push a commit adding a semicolon sentence to `README.Rmd`, record the red run id in the work log, revert it, record the green run id.
- [x] T4: Edit `cairn/PROFILE.md`: the `verify` line, the `consistency-gate` line, and `prose-sweep.yaml` in the `test-doctrine` filter list.
- [x] T5: `devtools::check()` clean; `cairn_validate` clean.

## Work log

- 2026-09-11: created by /milestone-plan.
- 2026-09-11: criteria audit ran in reduced mode (bounded-promise, proportionality and instrument questions). Must-fix, fixed: AC1 named `--paragraphs` for `R/nested-tune-grid.R`, which the non-roxygen mode lists nothing for (now `--roxygen --paragraphs`); the profile's named filter list would have gone stale (AC3 now adds `prose-sweep.yaml`). Noted: the semicolon probe exercises the `--plain` leg only, one exemplar for the wiring.
- 2026-09-11: plan gate chose a CI workflow plus the test plus the profile slots over the test and slots alone because a PR opened without a local test run is otherwise caught only by the coverage leg, which never gates; falsified by the workflow's minutes exceeding what `.github/ci-usage.py` shows the suite saving, in which case the workflow folds into an existing leg.
- 2026-09-11: plan gate chose mechanical enforcement over a profile rule alone because the session hook already states the rules and M084 and M085 left 66 semicolons on the help pages, which no clause of theirs bound; falsified by nothing short of the sweeps never firing across ten merged PRs.

- 2026-09-11: T1 done. The real-source block asserts `--paragraphs` non-empty for the six pages and `--roxygen --paragraphs` for `R/nested-tune-grid.R`, then the six invocations `clean`; 34 pass. Discrimination shown locally: one appended semicolon sentence in `README.Rmd` fails the `--plain` leg with `README.Rmd:90: semicolon: …`, reverted.
- 2026-09-11: T2 done. `prose-sweep.yaml`: the filter on both triggers, concurrency block, a 10-minute job cap (six sweeps 1.4 s locally at 8b4c2eb, no package install), one step per mode; `ci-usage.py`'s parser reads the filter and lists the workflow with the five others, no disagreement.
- 2026-09-11: minor amendment. The `push` trigger fires on the default branch alone and the PR opens at review, so T3's runs need a `workflow_dispatch` trigger on the workflow, run with `gh workflow run prose-sweep.yaml --ref m088-prose-sweep-gate`; AC2's wording holds as written.
- 2026-09-11: the dispatch route failed, GitHub's API refusing a workflow absent from the default branch (HTTP 404). Superseding the line above: the `workflow_dispatch` trigger is removed and `push` carries no `branches` filter, so every branch push runs the sweep; the deviation from the other workflows' shape is stated in the yaml comment.
- 2026-09-11: T3 done. Planted commit 012f42a (one semicolon sentence appended to `README.Rmd`): run 34653377391 failed at the `Plain clauses (pages)` step, its log reading `README.Rmd:90: semicolon: …`, `1 hit(s)`. Revert commit e5f7d40: run 34653536495 succeeded, six steps clean. The baseline run 34653331312 on 313dc84 was cancelled by the planted push, as the concurrency block states.
- 2026-09-11: T4 done. `PROFILE.md`: the `verify` line naming `--plain` (and `--roxygen --plain`) before a prose-touching task is checked off, the consistency-gate line listing the six sweeps, `prose-sweep.yaml` in the filter list.
- 2026-09-11: T5 done. The first `devtools::check()` warned on an undeclared `withr` use in the new test; replaced with base `setwd()` (89af8e8) rather than a dependency change. Second check at 89af8e8: 0 errors, 0 warnings, 0 notes, 6m48s; `cairn_validate` all checks passed (18 advisories, pre-existing references staleness).
- 2026-09-11: claim audit: not owed — internal tier.
- 2026-09-11: the SimpleEnglish lint hook flagged `ROADMAP.md`, `PROFILE.md` and this file on every edit; the counts are pre-existing and the flagged sections are plan-owned or history, left untouched.
- 2026-09-11: status → review.

## Decisions

## Review
