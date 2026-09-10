<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M078: The site build runs no repository code under a writable token, and the published site carries nothing the repository keeps to itself

- **Status:** planned
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — the deliverable is the published documentation site at `nestedtune.tidymodels.org` and the workflow that writes it
- **Branch/PR:** —

## Goal

Nothing the repository keeps to itself is served from the published pkgdown
site, and no repository code runs under a token that can write to the
repository.

## Scope

**In:** `.github/workflows/pkgdown.yaml` regains the two-job shape `72c3be2`
collapsed — a `build` job at the workflow's `read-all` handing `docs/` on as
an artifact, and a `deploy` job holding `contents: write` whose steps run
nothing checked out — with the job-level publish guard, the `timeout-minutes`
on both jobs, the repo-internal source removal and its guard, the
advertised-pages and `check_pkgdown()` guards, the `paths-ignore` copies, and
`extra-packages: local::.` (D-022's line). Each restored departure from the
r-lib stock template carries a comment saying why, so a later template sync
does not undo it silently. The two pages already published — `CLAUDE.html`
and `ci-usage-baseline.html` — come off the `gh-pages` branch with their
`sitemap.xml` and `search.json` entries. A reply to topepo's open review
question on [#30](https://github.com/tidymodels/nestedtune/pull/30) is drafted
and posted only on the user's approval at the review gate.

**Out:** pinning `r-lib/actions/pr-push@v2`, `posit-dev/setup-air@v1` and
`reviewdog/action-suggester@v1` → the standing ROADMAP candidate row that
tracks the pkgdown deploy pin, whose promotion condition (the organization
pinning them, or evidence a tag was altered) is unmet. Switching the deploy
off `clean: false` → the same row's site-hygiene half, since it reverses what
D-003 allows for pre-1.0 renamed pages. The `/dev/` site and the CI-records
row stay where they are.

## Acceptance criteria

- [ ] AC1: On a pull-request run of `pkgdown.yaml` from this milestone's
      branch, the "Set up job" log of the job that runs
      `pkgdown::build_site_github_pages` reports `contents: read`, and no job
      in that run reports any write scope.
- [ ] AC2: `.github/workflows/pkgdown.yaml` declares exactly two jobs; the job
      holding `contents: write` lists exactly three steps —
      `actions/checkout`, `actions/download-artifact`, and the SHA-pinned
      `JamesIves/github-pages-deploy-action` — carries its publish condition at
      job level as `github.ref_name == github.event.repository.default_branch`,
      and both jobs carry a `timeout-minutes`. On a `workflow_dispatch` run of
      the branch and on a pull-request run, that job reports as skipped.
- [ ] AC3: For every path `git ls-files -- '*.md' '.github/*.md'` returns on
      the branch, the branch's built site carries a page, a `sitemap.xml`
      entry and a `search.json` entry only where the path is `README.md`,
      `NEWS.md`, `LICENSE.md`, `.github/CODE_OF_CONDUCT.md` or
      `.github/CONTRIBUTING.md` — the check iterating that listing, never a
      hand list. `docs/index.html` and `docs/articles/nested-cv.html` are
      present, and `pkgdown::check_pkgdown()` reports no problems.
- [ ] AC4: `https://nestedtune.tidymodels.org/CLAUDE.html` and
      `.../ci-usage-baseline.html` each return HTTP 404 after redirects, and
      the live `sitemap.xml` and `search.json` match neither `CLAUDE` nor
      `ci-usage-baseline` — measured before the merge gate, the pages having
      been removed from `gh-pages` directly.
- [ ] AC5: The dependency step's `extra-packages` reads `local::.` alone, and
      the branch's site build is green with `needs: website` resolving the
      builder from `DESCRIPTION`'s `Config/Needs/website`.
- [ ] AC6: Both `pkgdown.yaml` triggers carry a `paths-ignore` list identical
      to the four copies in `R-CMD-check.yaml` and `test-coverage.yaml`, and
      `.github/ci-usage.py` exits zero with its filter line naming
      `pkgdown.yaml`.
- [ ] AC7: `Rscript -e 'devtools::check()'` is clean on the branch (0 errors,
      0 warnings; NOTEs justified), and `devtools::document()` produces no
      diff.

## Coverage

- AC1 → T1
- AC2 → T1
- AC3 → T2, T4
- AC4 → T5
- AC5 → T3
- AC6 → T3
- AC7 → T6

## Tasks

- [ ] T1: Split `.github/workflows/pkgdown.yaml` back into `build` (workflow
      `read-all`, uploads `docs/` as an artifact) and `deploy`
      (`permissions: contents: write`, job-level
      `if: github.ref_name == github.event.repository.default_branch`, steps
      limited to checkout, download-artifact and the SHA-pinned deploy action
      at its current v4.9.0 blob). Keep the `release: published` trigger
      `72c3be2` added. Give both jobs a `timeout-minutes` (20 build, 10
      deploy, the pre-collapse figures). Comment each departure from the stock
      template with the property it buys.
- [ ] T2: Restore the `Drop the repo-internal sources` step, the
      internal-pages guard, the advertised-pages guard and the
      `check_pkgdown()` step. Write the internal-pages guard to iterate
      `git ls-files -- '*.md' '.github/*.md'` against the built `docs/`,
      `sitemap.xml` and `search.json`, rather than the two hardcoded paths it
      carried before, so a markdown file added later is covered without an
      edit.
- [ ] T3: Restore `extra-packages: local::.` and the `paths-ignore` list on
      both triggers, matching the four copies in `R-CMD-check.yaml` and
      `test-coverage.yaml` byte for byte; run `.github/ci-usage.py` and record
      its filter line.
- [ ] T4: Prove each restored guard able to fail, planting a defect at a
      location the guard does not name: a fresh root `notes.md` for the
      internal-pages guard (not `CLAUDE.md`, which the removal step deletes),
      the `docs/index.html` arm for the advertised-pages guard (not the
      article arm), and an export dropped from `_pkgdown.yml` for
      `check_pkgdown()`. Record each red run id in the work log, then revert
      the plants.
- [ ] T5: Remove `CLAUDE.html`, `ci-usage-baseline.html` and their
      `sitemap.xml` and `search.json` entries from the `gh-pages` branch in
      one commit; verify the live 404s and the two index files after GitHub
      Pages rebuilds.
- [ ] T6: Run the consistency gate (`devtools::check()`, `document()` no-diff,
      `check_pkgdown()`), and update `cairn/DESIGN.md`'s Known issues entry on
      the vendored organization workflows to what survives this milestone.
- [ ] T7: Draft the reply to topepo's review comment on
      `.github/workflows/pkgdown.yaml:3` in [#30](https://github.com/tidymodels/nestedtune/pull/30)
      — what is being restored and the property each piece buys — and hold it
      for the user's approval at the review gate. Post nothing before that.

## Work log

- 2026-09-09: created by /milestone-plan.
- 2026-09-09: plan gate chose restoring the two-job split over a separate `workflow_run`-triggered deploy workflow because `workflow_run` runs the default branch's definition and needs its own artifact and ref plumbing for the same property; falsified by evidence that an artifact handoff between jobs cannot carry a built site.
- 2026-09-09: plan gate chose the two-job split over gating `permissions:` by expression on one job because the `permissions:` key is not expression-capable; falsified by GitHub documenting expression support there.
- 2026-09-09: plan gate chose removing the two pages from `gh-pages` directly over switching the deploy off `clean: false`, because the additive publish is what keeps pre-1.0 renamed pages reachable (D-003); falsified by evidence no renamed page is still served.
- 2026-09-09: criteria audit ran in full mode ([O], fresh context): nine findings over AC2-AC6, eight fixed at the gate (AC3 unsatisfiable — `package_mds()` on the checkout necessarily returns `CLAUDE.md` and never descends into `cairn/`; AC3 and AC6 bound instrument properties; AC4 was observable only post-merge; AC6 asserted a per-trigger report `ci-usage.py` does not emit), one routed to the gate as the `clean: false` question. AC1 and AC5 clean.

## Decisions

## Review
