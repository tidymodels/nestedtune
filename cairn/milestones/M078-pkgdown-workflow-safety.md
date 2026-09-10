<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M078: The site build runs no repository code under a writable token, and the published site carries nothing the repository keeps to itself

- **Status:** review
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — the deliverable is the published documentation site at `nestedtune.tidymodels.org` and the workflow that writes it
- **Branch/PR:** `m078-pkgdown-workflow-safety` / [#88](https://github.com/tidymodels/nestedtune/pull/88) (draft)

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
`extra-packages: local::.` (D-022's line).
`.github/workflows/R-CMD-check-hard.yaml` gains the same `paths-ignore` list
on both of its triggers: `.github/ci-usage.py` refuses to run while any `push`
or `pull_request` trigger in the repository carries no list, so AC6's
exit-zero clause is unreachable while that file has none. Each restored departure from the
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

- [x] AC1: On a pull-request run of `pkgdown.yaml` from this milestone's
      branch, the "Set up job" log of the job that runs
      `pkgdown::build_site_github_pages` reports `contents: read`, and no job
      in that run reports any write scope.
- [x] AC2: `.github/workflows/pkgdown.yaml` declares exactly two jobs; the job
      holding `contents: write` lists exactly three steps —
      `actions/checkout`, `actions/download-artifact`, and the SHA-pinned
      `JamesIves/github-pages-deploy-action` — carries its publish condition at
      job level as `github.ref_name == github.event.repository.default_branch`,
      and both jobs carry a `timeout-minutes`. On a `workflow_dispatch` run of
      the branch and on a pull-request run, that job reports as skipped.
- [x] AC3: For every path `git ls-files -- '*.md' '.github/*.md'` returns on
      the branch, the branch's built site carries a page, a `sitemap.xml`
      entry and a `search.json` entry only where the path is `README.md`,
      `NEWS.md`, `LICENSE.md`, `.github/CODE_OF_CONDUCT.md` or
      `.github/CONTRIBUTING.md` — the check iterating that listing, never a
      hand list. `docs/index.html` and `docs/articles/nested-cv.html` are
      present, and `pkgdown::check_pkgdown()` reports no problems.
- [x] AC4: `https://nestedtune.tidymodels.org/CLAUDE.html` and
      `.../ci-usage-baseline.html` each return HTTP 404 after redirects, and
      the live `sitemap.xml` and `search.json` match neither `CLAUDE` nor
      `ci-usage-baseline` — measured before the merge gate, the pages having
      been removed from `gh-pages` directly.
- [x] AC5: The dependency step's `extra-packages` reads `local::.` alone, and
      the branch's site build is green with `needs: website` resolving the
      builder from `DESCRIPTION`'s `Config/Needs/website`.
- [x] AC6: Both `pkgdown.yaml` triggers carry a `paths-ignore` list identical
      to the four copies in `R-CMD-check.yaml` and `test-coverage.yaml`, and
      `.github/ci-usage.py` exits zero with its filter line naming
      `pkgdown.yaml`.
- [x] AC7: `Rscript -e 'devtools::check()'` is clean on the branch (0 errors,
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

- [x] T1: Split `.github/workflows/pkgdown.yaml` back into `build` (workflow
      `read-all`, uploads `docs/` as an artifact) and `deploy`
      (`permissions: contents: write`, job-level
      `if: github.ref_name == github.event.repository.default_branch`, steps
      limited to checkout, download-artifact and the SHA-pinned deploy action
      at its current v4.9.0 blob). Keep the `release: published` trigger
      `72c3be2` added. Give both jobs a `timeout-minutes` (20 build, 10
      deploy, the pre-collapse figures). Comment each departure from the stock
      template with the property it buys.
- [x] T2: Restore the `Drop the repo-internal sources` step, the
      internal-pages guard, the advertised-pages guard and the
      `check_pkgdown()` step. Write the internal-pages guard to iterate
      `git ls-files -- '*.md' '.github/*.md'` against the built `docs/`,
      `sitemap.xml` and `search.json`, rather than the two hardcoded paths it
      carried before, so a markdown file added later is covered without an
      edit.
- [x] T3: Restore `extra-packages: local::.` and the `paths-ignore` list on
      both triggers, matching the four copies in `R-CMD-check.yaml` and
      `test-coverage.yaml` byte for byte; run `.github/ci-usage.py` and record
      its filter line.
- [x] T4: Prove each restored guard able to fail, planting a defect at a
      location the guard does not name: a fresh root `notes.md` for the
      internal-pages guard (not `CLAUDE.md`, which the removal step deletes),
      the `docs/index.html` arm for the advertised-pages guard (not the
      article arm), and an export dropped from `_pkgdown.yml` for
      `check_pkgdown()`. Record each red run id in the work log, then revert
      the plants.
- [x] T5: Remove `CLAUDE.html`, `ci-usage-baseline.html` and their
      `sitemap.xml` and `search.json` entries from the `gh-pages` branch in
      one commit; verify the live 404s and the two index files after GitHub
      Pages rebuilds.
- [x] T6: Run the consistency gate (`devtools::check()`, `document()` no-diff,
      `check_pkgdown()`), and update `cairn/DESIGN.md`'s Known issues entry on
      the vendored organization workflows to what survives this milestone.
- [x] T7: Draft the reply to topepo's review comment on
      `.github/workflows/pkgdown.yaml:3` in [#30](https://github.com/tidymodels/nestedtune/pull/30)
      — what is being restored and the property each piece buys — and hold it
      for the user's approval at the review gate. Post nothing before that.

## Work log

- 2026-09-09: created by /milestone-plan.
- 2026-09-09: plan gate chose restoring the two-job split over a separate `workflow_run`-triggered deploy workflow because `workflow_run` runs the default branch's definition and needs its own artifact and ref plumbing for the same property; falsified by evidence that an artifact handoff between jobs cannot carry a built site.
- 2026-09-09: plan gate chose the two-job split over gating `permissions:` by expression on one job because the `permissions:` key is not expression-capable; falsified by GitHub documenting expression support there.
- 2026-09-09: plan gate chose removing the two pages from `gh-pages` directly over switching the deploy off `clean: false`, because the additive publish is what keeps pre-1.0 renamed pages reachable (D-003); falsified by evidence no renamed page is still served.
- 2026-09-09: criteria audit ran in full mode ([O], fresh context): nine findings over AC2-AC6, eight fixed at the gate (AC3 unsatisfiable — `package_mds()` on the checkout necessarily returns `CLAUDE.md` and never descends into `cairn/`; AC3 and AC6 bound instrument properties; AC4 was observable only post-merge; AC6 asserted a per-trigger report `ci-usage.py` does not emit), one routed to the gate as the `clean: false` question. AC1 and AC5 clean.
- 2026-09-09: implement gate chose keeping the `release: published` trigger as a build-only check, since a release run's ref is the tag and the job-level publish guard names the default branch; and chose taking the two leaked pages' markdown sources off `gh-pages` alongside their HTML, which the plan's T5 named only as the two pages.
- 2026-09-09: T1 — `.github/workflows/pkgdown.yaml` split back into `build` (workflow `read-all`, uploads `docs/`) and `deploy` (`contents: write`, job-level default-branch guard, three steps), workflow-level `concurrency` restored, `timeout-minutes` 20/10, deploy pinned at the v4.9.0 blob `fa24774`, each departure from the stock template commented.
- 2026-09-09: T2 — restored the `Drop the repo-internal sources` step, `check_pkgdown()`, the advertised-pages guard and the internal-pages guard, the last rewritten to iterate `git ls-files -- '*.md' '.github/*.md'` (144 sources today) against the site root's file listing, `sitemap.xml` and `search.json`, allowing a page only for the five sources pkgdown is meant to publish. Local runs against the published site as it stands: red naming `CLAUDE.md` and `.github/ci-usage-baseline.md` on all four arms; green over the same 144 sources once the four files and their index entries are removed, with the five allowed pages still present. Root-file matching is done against a listing rather than `[ -f ]`, after a case-insensitive filesystem read `cairn/references/INDEX.md` as `docs/index.html`.
- 2026-09-09: T3 (partway) — `paths-ignore` restored on both `pkgdown.yaml` triggers and `extra-packages` back to `local::.`; the six copies across the three workflows compare identical. `.github/ci-usage.py` still exits non-zero: `R-CMD-check-hard.yaml`, added by `72c3be2` alongside the collapse, carries `push` and `pull_request` with no list, and the script refuses whenever any trigger lacks one while others have it. Held at a mini gate on extending Scope to that file.
- 2026-09-09: amendment (substantive, mini gate, user-selected) — Scope In extended to `.github/workflows/R-CMD-check-hard.yaml`'s two triggers, which gain the same `paths-ignore` list; no acceptance criterion's wording changes.
- 2026-09-09: T3 — the list now has eight identical copies across the four workflows carrying `push`/`pull_request`, and `.github/ci-usage.py` exits 0 with `Path filter read from R-CMD-check-hard.yaml, R-CMD-check.yaml, pkgdown.yaml, test-coverage.yaml: `cairn/**`, `CLAUDE.md`, `.claude/**``.
- 2026-09-09: PR [#88](https://github.com/tidymodels/nestedtune/pull/88) opened as a draft, so the pull-request runs the criteria ask for exist while the milestone is implemented. Baseline pkgdown run 34423656683 on `a43007b`: `build` pass in 6m10s, `deploy` skipping.
- 2026-09-09: T4 — each restored guard planted and seen red on its own pull-request run, then reverted. Run 34424415359: a tracked root `notes.md` the guard does not name, red at `Check the repo-internal pages are absent` on the page, copied-source and sitemap arms. Run 34424840769: `docs/index.html` removed after the build, red at `Check the advertised pages exist` naming that path, the internal-pages guard green on the same run. Run 34425274073: `agreement` dropped from `_pkgdown.yml`, red at `Check pkgdown config` with `In _pkgdown.yml, 1 topic missing from index: "agreement"`. Locally the same three guards were also run against the site as published, red on `CLAUDE.md` and `.github/ci-usage-baseline.md` and green over the same 144 sources once those four files and their index entries were removed.
- 2026-09-09: T5 — `gh-pages` commit `1275777` removed `CLAUDE.html`, `ci-usage-baseline.html`, their two markdown sources (a discovered addition to the task, taken at the implement gate) and their `sitemap.xml` and `search.json` entries; sitemap 46 -> 44 urls, search index 273 -> 269 entries. GitHub Pages rebuilt at that commit; all four paths return 404 after redirects, and `/`, `index.html`, `LICENSE.html`, `CODE_OF_CONDUCT.html`, `CONTRIBUTING.html`, `articles/nested-cv.html` and `news/index.html` all still return 200.
- 2026-09-09: T7 — reply to topepo's comment on `.github/workflows/pkgdown.yaml:3` in [#30](https://github.com/tidymodels/nestedtune/pull/30) drafted, unposted, at `benchmarks/pkgdown-30-reply.md`, following the convention `benchmarks/tune-969-reply.md` set. Nothing posted; it is held for the user's approval at the review gate.
- 2026-09-09: T5 correction — the `gh-pages` commit `1275777` staged only the four deletions; the `sitemap.xml` and `search.json` edits were left unstaged and the two files still listed the removed pages. `4eb11ed` lands them: sitemap 46 -> 44 urls, search index 273 -> 269 entries.
- 2026-09-09: T6 (partway) — `devtools::document()` produces no diff; `pkgdown::check_pkgdown()` reports no problems locally. `cairn/DESIGN.md`'s vendored-workflows Known-issues entry corrected to state that the shared-blob boundary is those three files alone and that this repository's own `pkgdown.yaml` and `R-CMD-check-hard.yaml` diverge from the r-lib templates deliberately. `NEWS.md` gains an entry for the site no longer carrying repository-internal pages. `devtools::check()` still running.
- 2026-09-09: live site after the `gh-pages` rebuild at `4eb11ed`: `/CLAUDE.html`, `/ci-usage-baseline.html`, `/CLAUDE.md` and `/ci-usage-baseline.md` each return 404 after redirects; `sitemap.xml` holds 44 urls and `search.json` 269 entries, neither matching `CLAUDE` or `ci-usage`; `/`, `/LICENSE.html`, `/CODE_OF_CONDUCT.html`, `/CONTRIBUTING.html`, `/articles/nested-cv.html` and `/news/index.html` still return 200.
- 2026-09-09: T6 — `devtools::check(error_on = "warning")` on the branch: Status OK, 0 errors, 0 warnings, 0 notes, 6m57s. `devtools::document()` leaves the tree clean. `pkgdown::check_pkgdown()` reports no problems.
- 2026-09-09: pkgdown run 34426080106 on the final tree (pull_request): `build` pass in 5m27s, `deploy` skipped; the build job's `GITHUB_TOKEN Permissions` block reports every scope as `read` including `Contents: read`, and neither job in the run reports a `write` scope. Run 34426477681 (workflow_dispatch on the branch): `build` success, `deploy` skipped.
- 2026-09-09: `cairn_validate` passes, 18 advisory warnings, all `references staleness` and none from this milestone. Plan-owned body 137 lines. Status set to `review`; PR [#88](https://github.com/tidymodels/nestedtune/pull/88) is still a draft and the R-CMD-check matrix and coverage legs were still running at handoff.
- 2026-09-09: review — all seven criteria executed with fresh evidence on head `d615311`; consistency gate clean (`cairn_validate` exit 0, `devtools::check()` Status OK, `document()` no diff, `check_pkgdown()` no problems).
- 2026-09-09: review — three fresh-context lenses; [S] blame-history and [S] prior-review found no defect, [O] diff-bug returned fourteen findings. Six fixed at the gate (led by the artifact hop dropping `docs/.nojekyll`, confirmed against run 34426967821's artifact and `gh-pages` history), three routed to a new candidate row, five rejected with reason. No finding demonstrated an acceptance criterion failing, so the return floor did not fire.
- 2026-09-09: review — the new candidate row put `cairn/ROADMAP.md` over its 24,000-byte budget; the widest rows were compressed in this same commit, back to 23,945 bytes over 53 lines.
- 2026-09-09: review — PR conversation read on [#88](https://github.com/tidymodels/nestedtune/pull/88): no reviews, no conversation comments, no unresolved review threads.
- 2026-09-09: step-7 approval: PR #88 approved for merge. The user also approved posting the drafted reply to topepo on [#30](https://github.com/tidymodels/nestedtune/pull/30) after the merge.
- 2026-09-09: review — PR #88 marked ready; the CI watcher reached the harness ceiling and was stopped. Fresh state at that point: `build` and `format-suggest` success, `deploy` skipped, the five R-CMD-check legs and `test-coverage` still in progress, nothing red. No merge attempted and no approval marker written; the recorded step-7 approval stands for the resume.
- 2026-09-09: review resume — `test-coverage` run 34429660527 failed at `Error in readRDS(f) : error reading from connection` in `merge_coverage.character`, after 15m50s and so under its 20-minute cap; the identity the standing coverage candidate row records as intermittent and pre-existing, and the profile declares the leg non-gating. Re-run of the failed job started. All five R-CMD-check legs, `build` and `format-suggest` are green and `deploy` skipped; the CI watcher reached the harness ceiling again and was stopped with the coverage re-run still in progress. No merge attempted, no approval marker written.

## Decisions

## Review

### Acceptance-criterion evidence

- AC1 — pkgdown run 34428228701 (pull_request, head `d615311`, build success;
  re-run after the fix-now batch changed the workflow, superseding the same
  measurement on 34426967821). The `build` job runs `pkgdown::build_site_github_pages`; its
  `Set up job` `GITHUB_TOKEN Permissions` group lists twenty scopes, every one
  `read`, `Contents: read` among them. The only `: write` string anywhere in
  the run's log is `Cache mode: write`, printed after the group's
  `##[endgroup]` and not a token scope. `deploy` was skipped and printed no
  permissions group.
- AC2 — parsing `.github/workflows/pkgdown.yaml` yields exactly two jobs,
  `build` and `deploy`. `deploy` carries `permissions: {contents: write}`,
  `if: github.ref_name == github.event.repository.default_branch` at job level,
  `timeout-minutes: 10`, and exactly three steps: `actions/checkout@v7`,
  `actions/download-artifact@v7`, and
  `JamesIves/github-pages-deploy-action@fa24774553152dd7873cd16ebd8d959b010c5445`
  (v4.9.0, SHA-pinned). `build` carries `timeout-minutes: 20` and no
  `permissions` key, so it sits at the workflow's `read-all`. `deploy` reports
  as skipped on both fresh runs of head `d615311`: pull-request run
  34428228701 and `workflow_dispatch` run 34428234800 (build success on each).
- AC3 — same run 34428228701. `Check the repo-internal pages are absent`
  passed, reporting `checking 145 tracked markdown sources`; the step's domain
  is `git ls-files -- '*.md' '.github/*.md'`, not a hand list
  (`.github/workflows/pkgdown.yaml:159`), and the allow-list it exempts is
  exactly `README.md`, `NEWS.md`, `LICENSE.md`, `.github/CODE_OF_CONDUCT.md`,
  `.github/CONTRIBUTING.md`. No `::error::` line was emitted anywhere in the
  run. `Check the advertised pages exist` passed, which is the assertion that
  `docs/index.html` and `docs/articles/nested-cv.html` are both present.
  `Check pkgdown config` printed `No problems found.`
- AC4 — measured 2026-09-09 against the live site.
  `https://nestedtune.tidymodels.org/CLAUDE.html` and
  `.../ci-usage-baseline.html` each return 404 after redirects. The live
  `sitemap.xml` holds 44 `<loc>` entries and `search.json` 269 entries;
  a case-insensitive grep for `CLAUDE` and for `ci-usage` matches 0 lines in
  each file. Controls still 200: `/`, `/LICENSE.html`,
  `/CODE_OF_CONDUCT.html`, `/CONTRIBUTING.html`, `/articles/nested-cv.html`,
  `/news/index.html`.
- AC5 — `.github/workflows/pkgdown.yaml` reads `extra-packages: local::.`
  and nothing else; `needs: website` sits beside it. Run 34428228701's
  `setup-r-dependencies` resolved `tidymodels`, `tidyverse/tidytemplate` and
  `pkgdown` each with `"type": "Config/Needs/website"`, and the `build` job
  finished success.
- AC6 — parsing all four workflows carrying `push`/`pull_request`
  (`R-CMD-check-hard.yaml`, `R-CMD-check.yaml`, `pkgdown.yaml`,
  `test-coverage.yaml`), every one of the eight `paths-ignore` lists is the
  identical `['cairn/**', 'CLAUDE.md', '.claude/**']`, so `pkgdown.yaml`'s two
  copies match the four in `R-CMD-check.yaml` and `test-coverage.yaml`.
  `python3 .github/ci-usage.py` exits 0, its filter line reading `Path filter
  read from R-CMD-check-hard.yaml, R-CMD-check.yaml, pkgdown.yaml,
  test-coverage.yaml: \`cairn/**\`, \`CLAUDE.md\`, \`.claude/**\``.
- AC7 — `Rscript -e 'devtools::check(error_on = "warning")'` on head `76b6ac9`:
  `Status: OK`, 0 errors, 0 warnings, 0 notes, 6m50s; the test leg ran
  `testthat.R` in 564s/308s OK. `Rscript -e 'devtools::document()'` afterwards
  left the tree clean apart from this milestone file's own review edits.

### Consistency gate

- `cairn_validate.py` exits 0; every check PASS or OK. Its 18 advisory
  warnings are all `references staleness` on `cairn/references/` pages, none
  from this milestone.
- `cairn_impact.py` skipped: the branch's `cairn/DESIGN.md` change is a Known
  issues edit, not an IP/GP principle change.
- Profile (`r-package`) consistency-gate slot: `devtools::document()` no diff
  (above); no generated file hand-edited (the no-diff `document()` covers
  `NAMESPACE` and `man/`); `README.Rmd`/`README.md` untouched by the branch and
  in sync; `pkgdown::check_pkgdown()` reports no problems, both locally and in
  run 34428228701; `NEWS.md` carries an entry for the site no longer serving
  repository-internal pages, with no milestone number in it; the one new
  top-level file, `benchmarks/pkgdown-30-reply.md`, sits under the already
  `.Rbuildignore`d `benchmarks/`, and `check()` reports 0 notes; full
  `devtools::check()` clean.

### Independent review

Three fresh-context lenses (user-facing tier, executable surface in the diff).
[S] blame-history: no findings — the restoration drops no property the
post-collapse shape added, and contradicts no recorded decision. [S]
prior-review: no regression against M17's review findings; it surfaced
topepo's open comment on `.github/workflows/pkgdown.yaml:3` in #30, which T7
already answers, and one comment on an unmodified line. [O] diff-bug returned
fourteen ranked findings, triaged below.

Fixed at the gate (committed on the branch as `d615311`, before approval):

- O1 — the artifact handoff silently drops `docs/.nojekyll`.
  `build_site_github_pages()` writes it, and `actions/upload-artifact` excludes
  hidden files by default, so the two-job shape publishes a site without it.
  Confirmed directly: the artifact of run 34426967821 carried `CNAME` but no
  `.nojekyll`, and `.nojekyll` first reached `gh-pages` on 2026-08-31, under
  the collapsed single-job shape — no deploy the earlier two-job shape made
  had it. Masked today only by `clean: false`, which leaves the copy already
  on the branch in place. Fixed with `include-hidden-files: true` and a
  comment recording why; run 34428234800's artifact carries `.nojekyll`.
- O3 — `NEWS.md` and the unposted reply draft both describe the guard as
  failing "if any page but" the five allowed sources reaches the built site.
  The guard's domain is tracked markdown matched at the site root; `404.html`,
  `authors.html`, every article and every reference topic are never
  candidates. Both narrowed to what the guard checks.
- O4 — the branch made three comments false by adding a fourth filtered
  workflow: `pkgdown.yaml`, `R-CMD-check.yaml` and `test-coverage.yaml` each
  still said six copies across three files. All three corrected to eight
  across four.
- O5 — `use-public-rspm: true` was restored bare, against the file's own rule
  that every departure from the stock template carries a comment naming what
  it buys. Comment added.
- O2 and O6 — the guard's two index arms are anchored at the domain root,
  which equals the site root only while `_pkgdown.yml`'s `url:` has no path
  segment; and `git ls-files` bounds the domain to tracked markdown, so an
  untracked root `.md` would be rendered and seen by no arm. Both are real
  limits the comments claimed away. The comments now state both; widening the
  coverage is the follow-up row below.

Follow-up (candidate row, added this pass):

- O2, O6, O7 — the internal-pages guard's coverage limits: the two index arms
  stop matching if the site gains a URL path segment; the domain is the git
  index rather than the filesystem; and stem-only root matching both
  false-positives on pkgdown's own generated root pages (a future tracked
  `authors.md`, `404.md`, `index.md` or `LICENSE-text.md` anywhere in the repo
  would fail the build permanently) and misses any repo-internal markdown
  pkgdown places outside the site root.

Rejected, with reason:

- O8 — "the `deploy` job has never actually executed", so a merge would be its
  first run under a job-level `permissions:` block that replaces the
  workflow's `read-all`. Refuted against the implementation: `gh-pages` holds
  deploys from 2026-07-28 to 2026-07-30 made by this same three-step job under
  the same `contents: write` block and the same `@v7` action pins, before
  `72c3be2` collapsed it. True only of GitHub's 90-day run retention, which
  holds no pre-collapse run.
- O9 — the `R-CMD-check-hard.yaml` comment overstated `ci-usage.py`'s refusal.
  Confirmed against `read_paths_ignore()`, and fixed in the batch above rather
  than rejected; listed here only because it was reported separately.
- O10 — `allowed="$(printf '%s\n' "$allowed" | sed 's/^ *//')"` is a no-op,
  the block scalar having already dedented the lines. Correct, and harmless;
  left alone rather than re-open a verified guard script for a cosmetic edit.
- O11 — `'.github/*.md'` is redundant in the pathspec (145 either way).
  Correct, but the pathspec appears verbatim in AC3's text, so changing it
  would edit a criterion at review.
- O12 — the restored comment dropped D-022's id. Style; the decision is cited
  in `cairn/DESIGN.md` and D-060.
- O13 — the advertised-pages guard has no `set -u` and checks presence only.
  A property of the pre-collapse step restored unchanged, not introduced here.
- O14 — `cairn/ROADMAP.md`'s hygiene line still reads "M78 planned". Correct;
  that line is rewritten by this milestone's own post-merge hygiene pass.
