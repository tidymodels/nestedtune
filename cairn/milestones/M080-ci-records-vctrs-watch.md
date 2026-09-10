# M080: The CI records name the workflows that exist and stop copying their caps, and a leg watches the development vctrs one invariant rests on

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — CI configuration and repository tracking records, all of them `.Rbuildignore`d or outside the package build.
- **Branch/PR:** —

## Goal

The repository's CI records describe the eight workflows that exist rather
than the two that existed in July, a check leg watches vctrs' development
branch, and the upstream ask that leg was scheduled beside is drafted.

## Scope

**In:** `cairn/PROFILE.md`'s test-doctrine slot, whose cap passage copies five
`timeout-minutes` figures (60, 30, 40, 20, 30) as prose, two of them stale and
three more caps uncopied, and which says "both gating workflows" carry
`paths-ignore` where four now do; the stale cross-reference at
`.github/workflows/test-coverage.yaml:33-34`, which credits R-CMD-check's
check step with a 20-minute cap where `R-CMD-check.yaml:176` declares 30, or
40 on windows; `.github/ci-usage-baseline.md`, generated 2026-07-27 and naming
two workflows at its line 5; a new workflow leg against `r-lib/vctrs@main`;
and the drafted upstream issue.

**Out:** posting that issue — the text is drafted here and posted by the
maintainer, never from a session. Teaching `.github/ci-usage.py` to read
`timeout-minutes`: the cap passage stops carrying figures, so there is nothing
left for such a check to compare, and the script's promise is untouched. The
windows leg's remaining minutes and the coverage leg's intermittent failure →
their own ROADMAP candidate row. A scheduled warm-up run for the R-devel
dependency cache → its own row. The review remainders → M079.

## Acceptance criteria

- [ ] AC1: `cairn/PROFILE.md`'s test-doctrine slot states no `timeout-minutes`
      figure of its own, and every cap it discusses is named by the workflow
      file and the job or step that declares it.
- [ ] AC2: That slot names as carrying `paths-ignore` exactly the workflows
      `read_paths_ignore()` (`.github/ci-usage.py:195`) reports in its
      `source` field for the current tree.
- [ ] AC3: `.github/workflows/test-coverage.yaml`'s comment about
      R-CMD-check's cap states the figure `.github/workflows/R-CMD-check.yaml`
      declares today.
- [ ] AC4: `.github/ci-usage-baseline.md` is the output of one `python3
      .github/ci-usage.py` run over a window ending on the branch date.
- [ ] AC5: `.github/workflows/` carries a leg that installs vctrs from
      `r-lib/vctrs@main` and runs the package's test suite, triggered on
      `push` and `pull_request`.
- [ ] AC6: `cairn/milestones/M080-ci-records-vctrs-watch.md` carries the
      upstream issue text in a fenced block whose body names three things: the
      file and line of the package method that depends on the experimental
      generic, the wording vctrs' own documentation uses to mark that generic
      experimental, and the date vctrs' `sf` method for that generic last
      changed.
- [ ] AC7: `Rscript -e 'devtools::check()'` clean (0 errors, 0 warnings) and
      `Rscript -e 'devtools::document()'` produces no diff.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T4
- AC5 → T5
- AC6 → T7
- AC7 → T8

## Tasks

- [ ] T1: Rewrite the cap passage in `cairn/PROFILE.md`'s test-doctrine slot
      so it carries no minute figure of its own — each cap named by its
      workflow file and the job or step declaring it, the existing "re-read
      them with grep" sentence dropped as it no longer guards anything. Keep
      the passage's rationale, which the figures were only illustrating.
      Historical hang durations are not caps and stay.
- [ ] T2: Correct the same slot's `paths-ignore` sentence against
      `read_paths_ignore()`'s `source` field: four workflows carry the filter
      (`R-CMD-check.yaml`, `R-CMD-check-hard.yaml`, `test-coverage.yaml`,
      `pkgdown.yaml`), not "both gating workflows".
- [ ] T3: Correct `.github/workflows/test-coverage.yaml:33-34`, which says
      R-CMD-check "bounds the same risk at 20 minutes ... on its check step"
      where that step declares `${{ ... windows && 40 || 30 }}`
      (`R-CMD-check.yaml:176`). M31's review fixed a sibling of this line in
      `pkgdown.yaml`; this one survived.
- [ ] T4: Run `python3 .github/ci-usage.py` over a window ending on the branch
      date and commit its output as `.github/ci-usage-baseline.md`. The
      "Path filter read from" line corrects itself, the script reading the
      workflow list off the directory. Record the command and window in the
      Review section.
- [ ] T5: Add the devel-vctrs leg: install vctrs from `r-lib/vctrs@main`, run
      the package's test suite, trigger on `push` and `pull_request` with the
      same `paths-ignore` the other four legs carry, and give the job a cap
      sized from the release leg's measured time.
- [ ] T6: Prove the leg able to fail — point it once at a deliberately broken
      expectation, record the red run's id in the Review section, revert — and
      confirm it is absent from the default branch's required checks, so a red
      upstream branch cannot block a merge.
- [ ] T7: Draft the upstream issue for `r-lib/vctrs` into this file: ask that
      `vec_cbind_frame_ptype()` be stabilized, or that `vec_cbind()` restore
      its output against the first data-frame input's full type as
      `dplyr::bind_cols()` already patches in. Cite `R/nested-results.R:519`,
      vctrs' own experimental/keyword-internal wording, and the 2020-03-27
      date its `sf` method last changed. Post nothing.
- [ ] T8: `Rscript -e 'devtools::check()'` clean; `devtools::document()` no
      diff.

## Work log

- 2026-09-10: created by /milestone-plan; absorbs the CI-records candidate row, which graduates when this milestone completes; the two vctrs items are the recommendations D-033's body scheduled onto that row rather than taking at M37, so this plans them rather than superseding anything.
- 2026-09-10: criteria audit ran in reduced mode (internal tier), fresh [O] reader, twice — first pass returned five findings on this milestone's criteria, four instrument-binding (AC1, AC3, AC4 and AC5 each mandated an evidence quotation or a work-log recording act) and one proportionality (AC5's red-run demonstration spans process and environment boundaries), all five fixed at the gate by moving the quotations and the red-run demonstration into T4 and T6 and narrowing AC5 to the leg's own file properties; second pass audited AC6, new at the gate, and returned nothing.
- 2026-09-10: plan gate chose dropping the copied cap figures from `PROFILE.md` over teaching `.github/ci-usage.py` to compare them, because the copies are the only thing that can drift and removing them leaves nothing to check; falsified by a reader needing the figures at hand in the profile rather than in the workflow files.
- 2026-09-10: plan gate chose regenerating `.github/ci-usage-baseline.md` over stamping it as a July 2026 historical record, because the script reads the workflow list off the directory and so corrects line 5 as a side effect; falsified by the Actions API no longer covering a window that makes the figures comparable.
- 2026-09-10: plan gate chose a non-blocking devel-vctrs leg on `push` and `pull_request` over a blocking one and over a schedule-only one, because it surfaces an upstream move within a day without letting another project's unreleased branch freeze merges here; falsified by the leg's noise outweighing its signal, or by the required-checks list acquiring it.

## Decisions

## Review
