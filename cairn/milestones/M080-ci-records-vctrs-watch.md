# M080: The CI records name the workflows that exist and stop copying their caps, and a leg watches the development vctrs one invariant rests on

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — CI configuration and repository tracking records, all of them `.Rbuildignore`d or outside the package build.
- **Branch/PR:** `m080-ci-records-vctrs-watch` — draft PR [#90](https://github.com/tidymodels/nestedtune/pull/90), opened at T5 so the new leg could be shown able to fail

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
two workflows at its line 5, and the same wrong figure in
`stress-daemon-tests.yaml:43` and `pkgdown.yaml:69`; a new workflow leg against
`r-lib/vctrs@main`; the drafted upstream issue; and `tests/testthat/test-ci-workflows.R:59-66`,
whose ordering assertion names a `pkgdown` job M78 replaced with `build` and
`deploy`, so four items fail under `devtools::test()` in the source tree while
`R CMD check` skips the block.

**Out:** posting that issue — the text is drafted here and posted by the
maintainer, never from a session. Teaching `.github/ci-usage.py` to read
`timeout-minutes`: the cap passage stops carrying figures, so there is nothing
left for such a check to compare, and the script's promise is untouched. The
windows leg's remaining minutes and the coverage leg's intermittent failure →
their own ROADMAP candidate row. A scheduled warm-up run for the R-devel
dependency cache → its own row. The review remainders → M079.

## Acceptance criteria

- [x] AC1: `cairn/PROFILE.md`'s test-doctrine slot states no `timeout-minutes`
      figure of its own, and every cap it discusses is named by the workflow
      file and the job or step that declares it.
- [x] AC2: That slot names as carrying `paths-ignore` exactly the workflows
      `read_paths_ignore()` (`.github/ci-usage.py:195`) reports in its
      `source` field for the current tree.
- [x] AC3: `.github/workflows/test-coverage.yaml`'s comment about
      R-CMD-check's cap states the figure `.github/workflows/R-CMD-check.yaml`
      declares today.
- [x] AC4: `.github/ci-usage-baseline.md` is the output of one `python3
      .github/ci-usage.py` run over a window ending on the branch date.
- [x] AC5: `.github/workflows/` carries a leg that installs vctrs from
      `r-lib/vctrs@main` and runs the package's test suite, triggered on
      `push` and `pull_request`.
- [x] AC6: `cairn/milestones/M080-ci-records-vctrs-watch.md` carries the
      upstream issue text in a fenced block whose body names three things: the
      file and line of the package method that depends on the experimental
      generic, the wording vctrs' own documentation uses to mark that generic
      experimental, and the date vctrs' `sf` method for that generic last
      changed.
- [ ] AC7: `Rscript -e 'devtools::check()'` clean (0 errors, 0 warnings) and
      `Rscript -e 'devtools::document()'` produces no diff.

## Coverage

- AC1 → T2
- AC2 → T6
- AC3 → T3
- AC4 → T7
- AC5 → T4
- AC6 → T8
- AC7 → T9

## Tasks

- [x] T1: Repair `tests/testthat/test-ci-workflows.R`'s ordering assertion
      against the two-job `pkgdown.yaml` M78 left: the `deploy` job runs its own
      `actions/checkout@v7` (:267) before the deploy action (:278), so the
      assertion reads that job. Rewrite the file-header comment, which still
      says the file builds and deploys in a single `pkgdown` job.
- [x] T2: Rewrite the cap passage in `cairn/PROFILE.md`'s test-doctrine slot
      so it carries no minute figure of its own — each cap named by its
      workflow file and the job or step declaring it, the existing "re-read
      them with grep" sentence dropped as it no longer guards anything. Keep
      the passage's rationale, which the figures were only illustrating.
      Historical hang durations are not caps and stay.
- [x] T3: Correct `.github/workflows/test-coverage.yaml:33-34`, which says
      R-CMD-check "bounds the same risk at 20 minutes ... on its check step"
      where that step declares `${{ ... windows && 40 || 30 }}`
      (`R-CMD-check.yaml:176`). M31's review fixed a sibling of this line in
      `pkgdown.yaml`; this one survived. Two further copies of the same figure
      — `stress-daemon-tests.yaml:43` and `pkgdown.yaml:69` — are corrected
      with it.
- [x] T4: Add the devel-vctrs leg: install vctrs from `r-lib/vctrs@main`, run
      the package's test suite, trigger on `push` and `pull_request` with the
      same `paths-ignore` the other four legs carry, and give the job a cap
      sized from the release leg's measured time.
- [x] T5: Prove the leg able to fail — point it once at a deliberately broken
      expectation, record the red run's id in the Review section, revert — and
      confirm it is absent from the default branch's required checks, so a red
      upstream branch cannot block a merge.
- [x] T6: Correct the same slot's `paths-ignore` sentence against
      `read_paths_ignore()`'s `source` field, which after T4 reports five
      workflows carrying the filter, not "both gating workflows".
- [x] T7: Run `python3 .github/ci-usage.py` over a window ending on the branch
      date and commit its output as `.github/ci-usage-baseline.md`. The
      "Path filter read from" line corrects itself, the script reading the
      workflow list off the directory. Record the command and window in the
      Review section.
- [x] T8: Draft the upstream issue for `r-lib/vctrs` into this file: ask that
      `vec_cbind_frame_ptype()` be stabilized, or that `vec_cbind()` restore
      its output against the first data-frame input's full type as
      `dplyr::bind_cols()` already patches in. Cite `R/nested-results.R:519`,
      vctrs' own experimental/keyword-internal wording, and the 2020-03-27
      date its `sf` method last changed. Post nothing.
- [x] T9: `Rscript -e 'devtools::check()'` clean; `devtools::document()` no
      diff.

## Work log

- 2026-09-10: created by /milestone-plan; absorbs the CI-records candidate row, which graduates when this milestone completes; the two vctrs items are the recommendations D-033's body scheduled onto that row rather than taking at M37, so this plans them rather than superseding anything.
- 2026-09-10: criteria audit ran in reduced mode (internal tier), fresh [O] reader, twice — first pass returned five findings on this milestone's criteria, four instrument-binding (AC1, AC3, AC4 and AC5 each mandated an evidence quotation or a work-log recording act) and one proportionality (AC5's red-run demonstration spans process and environment boundaries), all five fixed at the gate by moving the quotations and the red-run demonstration into T4 and T6 and narrowing AC5 to the leg's own file properties; second pass audited AC6, new at the gate, and returned nothing.
- 2026-09-10: plan gate chose dropping the copied cap figures from `PROFILE.md` over teaching `.github/ci-usage.py` to compare them, because the copies are the only thing that can drift and removing them leaves nothing to check; falsified by a reader needing the figures at hand in the profile rather than in the workflow files.
- 2026-09-10: plan gate chose regenerating `.github/ci-usage-baseline.md` over stamping it as a July 2026 historical record, because the script reads the workflow list off the directory and so corrects line 5 as a side effect; falsified by the Actions API no longer covering a window that makes the figures comparable.
- 2026-09-10: plan gate chose a non-blocking devel-vctrs leg on `push` and `pull_request` over a blocking one and over a schedule-only one, because it surfaces an upstream move within a day without letting another project's unreleased branch freeze merges here; falsified by the leg's noise outweighing its signal, or by the required-checks list acquiring it.

- 2026-09-10: implement gate amended Scope In to cover `tests/testthat/test-ci-workflows.R`'s ordering assertion, which names a `pkgdown` job M78 replaced, and added it as T1; no acceptance criterion changed wording, the clean `devtools::test()` the verify slot already demands being what proves the repair.
- 2026-09-10: implement gate reordered the eight planned tasks so the devel-vctrs leg (now T4) lands before the `paths-ignore` sentence (now T6) and the regenerated usage baseline (now T7), both of which read the workflow directory; `Tn:` labels and the Coverage lines renumbered together, task wording otherwise unchanged.

- 2026-09-10: T1 — the pkgdown ordering assertion now reads the `deploy` job, whose own `actions/checkout@v7` precedes the deploy action; the file-header comment and the job-boundary comment corrected to the two-job file. `devtools::test()` 9592 pass, 0 fail.

- 2026-09-10: T2 — the cap passage carries no minute figure of its own, naming each cap by its workflow file and the job or step declaring it, and the grep sentence is gone; the two pre-M14 hang durations stay. Compressed in the same pass so `PROFILE.md` clears its 120-line cap with headroom (119 before, 120 after the first rewrite, 118 now): `stress-daemon-tests.yaml` is named once rather than twice, and the parallel-files figures cross-reference `benchmarks/test-timing-parallel.md`, which owns them.

- 2026-09-10: implement gate widened Scope In and T3 from one stale cap cross-reference to three, the two siblings found while writing T2 crediting R-CMD-check's check step with the same 20 minutes; no criterion changed wording and no task was added.
- 2026-09-10: T3 — all three comments now state 30 minutes, 40 on windows, the figure `R-CMD-check.yaml:176` declares. `R-CMD-check.yaml:108`'s 20-minute mention is a past cap that killed a build, not a copy of a live one, and stays.

- 2026-09-10: T4 — `.github/workflows/devel-vctrs.yaml` installs vctrs from `r-lib/vctrs@main` after the dependency install, records the version and remote sha it got, and runs `testthat::test_local(stop_on_failure = TRUE)` under `NOT_CRAN` and `TESTTHAT_CPUS: 4`; `push` and `pull_request` carry the same `paths-ignore`, and `read_paths_ignore()` now reports five workflows. Job cap 45, derived in the file from the ubuntu release leg's measured 23m42s (run 34522794223); this leg's own time is measured at T5. Four sibling header comments enumerated the filter-carrying workflows by name and counted the copies, which adding a fifth falsified, so each now points at "every other workflow carrying the filter" instead. The profile's divergence list and `paths-ignore` sentence follow at T6.

- 2026-09-10: T6 — the slot's `paths-ignore` sentence names `R-CMD-check-hard.yaml`, `R-CMD-check.yaml`, `devel-vctrs.yaml`, `pkgdown.yaml` and `test-coverage.yaml`, the five `read_paths_ignore()` reports; the divergence list gains the devel-vctrs leg and drops its own count, and the worker-count sentence stops naming "the three check workflows", now four. Compressed in the same pass to hold the 120-line cap: the hang-locating bullet, the parallel-files parenthetical and the `benchmarks/` listing, and the slot's remaining bullets rewrapped to the width the rest of it uses. 117 lines.

- 2026-09-10: T7 — `BASELINE_SINCE`/`BASELINE_UNTIL` re-pointed to `[2026-08-11T00:00:00Z, 2026-09-10T00:00:00Z)`, a thirty-day window ending on the branch date and clear of any run still in flight, so the bare `python3 .github/ci-usage.py` AC4 names reproduces the file; its line 5 now reads the five filter-carrying workflows off the directory. Command and window recorded in the Review section.

- 2026-09-10: T8 — the upstream issue is drafted into this file's `## Upstream issue draft` section, placed after `## Review` so it stays outside the plan-owned 150-line cap. Its three facts were read this session: the method sits at `R/nested-results.R:519`; `man/vec_cbind_frame_ptype.Rd` in `r-lib/vctrs` carries `\keyword{internal}`, an `[Experimental]` badge and "Expect changes"; and `vec_cbind_frame_ptype.sf()` last changed on 2020-03-27 in `647d8975`, confirmed by scanning all 84 commits to `R/bind.R` for a later patch touching it. `dplyr::bind_cols()` calling `vec_cbind()` then `dplyr_reconstruct(out, first)` was read off the installed function. Nothing was posted.

- 2026-09-10: T5 — the leg reported red on the planted break and green without it, and `main` carries no branch protection and no rulesets, so no required check exists for it to join. Cap re-sized to 90 from the leg's own measured run rather than the release leg's, the green run having taken 35m24s against the 45 first guessed.

- 2026-09-10: T9 — `devtools::document()` produces no diff; `devtools::check()` Status OK, 0 errors, 0 warnings, 0 notes, 10m07s, tests 846s/458s.
- 2026-09-10: claim audit: not owed — internal tier.
- 2026-09-10: status set to review; all nine tasks checked, `devtools::test()` and `devtools::check()` clean locally.

## Decisions

## Review

Fresh evidence, 2026-09-10, on `43c45ad`:

- AC1: the `## test-doctrine` slot, read whole, carries no `timeout-minutes`
  key and one minute figure — "52 minutes under `R CMD check`, 40 under
  `covr`", the two pre-M14 hang durations, which are observed run times and not
  caps (T2 keeps them by name). Every cap it discusses is named by file and
  scope: `R-CMD-check.yaml` job and `check-r-package` step separately;
  `test-coverage.yaml`, `R-CMD-check-hard.yaml` and `devel-vctrs.yaml` one job
  each; `pkgdown.yaml`'s `build` and `deploy` apart;
  `stress-daemon-tests.yaml` a job cap "far above the rest". `grep -rn
  timeout-minutes .github/workflows/` returns eight declarations across those
  six files, each of which the slot's enumeration reaches.
- AC2: `read_paths_ignore()` (`.github/ci-usage.py:195`) called on the current
  tree returns `source` = `R-CMD-check-hard.yaml, R-CMD-check.yaml,
  devel-vctrs.yaml, pkgdown.yaml, test-coverage.yaml`. The slot's
  `paths-ignore` sentence names those five and no others.
- AC3: `.github/workflows/test-coverage.yaml:34` reads "at 30 minutes, 40 on
  windows"; `.github/workflows/R-CMD-check.yaml:175` declares
  `${{ matrix.config.os == 'windows-latest' && 40 || 30 }}`. The two siblings
  T3 widened to agree: `stress-daemon-tests.yaml:43-44` and
  `pkgdown.yaml:68-70` both now say 30, 40 on windows.
- AC4: `python3 .github/ci-usage.py` run bare from the repo root on 2026-09-10,
  exit 0, stdout diffed against the committed `.github/ci-usage-baseline.md` —
  no difference, the two byte-identical. The window is `BASELINE_SINCE`/
  `BASELINE_UNTIL` = `[2026-08-11T00:00:00Z, 2026-09-10T00:00:00Z)`, closed and
  a whole day behind the branch date, which is why a second run over the same
  window reproduces the first exactly.
- AC5: `.github/workflows/devel-vctrs.yaml` exists; `on:` carries `push` and
  `pull_request`; the step "Install vctrs from its development branch" runs
  `pak::pak("r-lib/vctrs@main")`; the step after it runs
  `pkgload::load_all(".")` then `testthat::test_local(stop_on_failure = TRUE)`.
- AC6: the `## Upstream issue draft` fenced block names all three, each
  re-verified this session against its source rather than the draft. Method
  site: `vec_cbind_frame_ptype.nested_results <-` sits at
  `R/nested-results.R:519`. Experimental wording: `man/vec_cbind_frame_ptype.Rd`
  on `r-lib/vctrs` main carries `\keyword{internal}` (:21), the
  `[Experimental]` lifecycle badge (:15) and "Expect changes" (:19); the
  installed 4.6 vctrs renders the same text. sf method: `gh api
  repos/r-lib/vctrs/commits/647d8975` dates it 2020-03-27T16:19:09Z, message
  "Add `sf` method for `vec_cbind_frame_ptype()`", and the method's body is
  byte-identical between that ref and main today (`data.frame()`, at :195 then
  and :255 now), so the draft's "has not changed since" holds.

### Independent review

Three fresh-context lenses, none having seen the implementation. The
blame-history lens and the prior-review lens each reported no findings: the
first traced every deleted figure and enumeration to a surviving copy in the
workflow that declares it, the second read M076's and M078's archived `## Review`
sections and found this diff correcting those points rather than regressing
them (its GitHub probe found three human comments, all on PR #30, none
contradicted). The diff-bug lens returned twelve, ranked; each is verified
below against the implementation.

- F1 (confirmed): `devel-vctrs.yaml:10` says the break "surfaces on the day it
  lands upstream", but the leg triggers only on `push` and `pull_request`, so
  an upstream rename during a quiet week surfaces at the next push here, not
  the next day. The comment overstates what the trigger delivers.
- F2 (confirmed): the profile's worker-count sentence now reads "every workflow
  that runs the suite", where the pre-diff text read "the three check
  workflows". `stress-daemon-tests.yaml` runs `testthat::test_dir("tests/testthat",
  filter = …)` through `benchmarks/stress-daemon-tests.R:107` and sets no
  `TESTTHAT_CPUS`, so the generalization the diff introduced has a
  counterexample.
- F3 (confirmed): `pkgdown.yaml:68-70`, rewritten by T3, now enumerates "20 on
  test-coverage's job" inside a sentence beginning "Not the gating workflows'
  measured caps" — on a job whose own cap is also 20, and about a workflow the
  same profile says "annotat[es] a PR but never gat[es] it".
- F4 (confirmed as a shared key, consequence bounded): `devel-vctrs.yaml:80`
  and `stress-daemon-tests.yaml:62` pass byte-identical `extra-packages:
  any::testthat, any::pkgload` to `setup-r-dependencies@v2`, whose cache is
  saved post-job — so devel-vctrs can save a library holding unreleased vctrs
  under a key the stress leg may restore. The stress leg is
  `workflow_dispatch`-only and diagnostic, so the blast radius is a hang hunt
  reading the wrong vctrs, not a false green on a gating check.
- F5 (confirmed): the Goal says "the eight workflows that exist";
  `.github/workflows/` holds nine once T4's leg lands. The count was true when
  planned and is falsified by the milestone's own work.
- F6 (confirmed): AC2 cites `.github/ci-usage.py:195`; `read_paths_ignore()` is
  at :197, the diff's own comment edit having shifted it. The criterion names
  the function, so what it tests is unchanged.
- F7 (confirmed, fixed): the AC3 evidence bullet above cited
  `test-coverage.yaml:32-33` for text on :34. Corrected in place before the
  gate.
- F8 (rejected): AC7's box was unticked when the lens read the file because
  `devtools::check()` was still running; not a defect.
- F9 (confirmed): `.github/ci-usage.py:60-61` says the upper bound is "a whole
  day behind the capture". `BASELINE_UNTIL` is midnight of the capture day, so
  the stated rule is not the rule the values follow; the invariant actually
  wanted is that the bound precedes any run still in flight.
- F10 (confirmed, bounded): `devel-vctrs.yaml` runs unpinned upstream HEAD and
  carries `GITHUB_PAT` under `permissions: read-all`. The token is read-only,
  so nothing here can write, but `pkgdown.yaml:56-63` reasons that a job
  executing ref code should hold no more token than it needs, and this job
  executes another project's code.
- F11 (confirmed, by construction): `.github/ci-usage-baseline.md:5` names
  `devel-vctrs.yaml` among the filter-carrying workflows though the leg existed
  for none of the measured window. The script reads the workflow list off the
  directory, which is the behaviour AC4 and T7 relied on.
- F12 (confirmed, pre-existing): the divergence tag list at `PROFILE.md:42`
  reads `(M11 ×2, M12 rev. M31, M14, M33, M52, M80)` and omits M78, whose
  two-job pkgdown split the same sentence now asserts.

Evidence recorded during implementation, for the review phase to read:

- T5: the leg's first run, green, was run 34526174374 on `2f85a8e` — job
  35m24s (20:24:23Z to 20:59:47Z), suite step 33m19s. The planted break
  (`expect_true(FALSE)` beside the `vec_cbind()` class assertion in
  `tests/testthat/test-vctrs-compat.R`) produced run 34529742899 on `215bbb4`,
  conclusion `failure`, whose log names one failure and it is the planted one:
  `Failure ('test-vctrs-compat.R:171:3'): vec_cbind() and bind_cols() adding a
  column answer the same way`, at `FAIL 1 | WARN 0 | SKIP 0 | PASS 9592` — the
  same pass count the green local run reports, so nothing else went red with
  it. The break is reverted in the commit that ticks this task.
- T5: `gh api repos/tidymodels/nestedtune/branches/main/protection` returns 404
  and `.../rulesets` returns `[]`, so the default branch has no required checks
  at all and this leg is absent from them.
- T7 (AC4): `python3 .github/ci-usage.py` run bare on 2026-09-10 from the repo
  root, window `[2026-08-11T00:00:00Z, 2026-09-10T00:00:00Z)` as
  `BASELINE_SINCE`/`BASELINE_UNTIL` declare; stdout redirected to
  `.github/ci-usage-baseline.md`, exit 0, 2067 completed runs and 3893 jobs in
  window.

## Upstream issue draft

For `r-lib/vctrs`. Not posted from any session — the maintainer posts it.

```
Title: Stabilize `vec_cbind_frame_ptype()`, or restore `vec_cbind()` output
against the first data frame's type

`vec_cbind()` builds its output's container by calling `x[0]` through
`vec_cbind_frame_ptype()`. For a data-frame subclass whose zero-column subset
is a bare tibble — the rule tibble's `[` follows — the subclass is therefore
gone before `vec_ptype2()` or `vec_restore()` is ever consulted, so a method on
`vec_cbind_frame_ptype()` is the only way to carry a class through
`vec_cbind()`.

nestedtune does exactly that. `vec_cbind_frame_ptype.nested_results()`, at
`R/nested-results.R:519`, exists solely so that `vctrs::vec_cbind(res, extra)`
and `dplyr::bind_cols(res, extra)` answer the same way.

The difficulty is that the generic is documented as not for public use.
`man/vec_cbind_frame_ptype.Rd` carries `\keyword{internal}` alongside an
`[Experimental]` badge, and its description tells readers to "Expect changes".
A package that needs `vec_cbind()` to preserve a class has one door and is told
not to walk through it.

Either of two changes would settle it.

1. Stabilize `vec_cbind_frame_ptype()`: drop `\keyword{internal}` and the
   "Expect changes" wording, and document it as the extension point it already
   is in practice. It has been stable in fact for years — the only method vctrs
   itself ships for it, `vec_cbind_frame_ptype.sf()`, was added on 2020-03-27
   in `647d8975` ("Add `sf` method for `vec_cbind_frame_ptype()`") and has not
   changed since.

2. Or have `vec_cbind()` restore its own output against the first data-frame
   input's full type, which is what `dplyr::bind_cols()` already patches around
   it — `bind_cols()` calls `vec_cbind()` and then `dplyr_reconstruct(out,
   first)`. With that in vctrs, `vec_ptype2()` and `vec_restore()` would carry
   the class the way they do everywhere else, and the frame-prototype generic
   could stay internal.

Happy to send a PR for whichever direction you prefer.
```
