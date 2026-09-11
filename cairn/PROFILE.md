# Toolchain profile: r-package

<!-- A cairn *toolchain profile*: the language-specific slots the operational skills read. The Validation
     doctrine is universal, not a slot (skills/shared/validation-doctrine.md); all seven slots must be non-empty — cairn_validate FAILs on a missing or empty slot. -->

The R-package toolchain: devtools/roxygen/testthat/pkgdown, CRAN release.

## verify
Run by `/milestone-implement` (per task) and `/hotfix` (gate-lite):
- After roxygen changes: `Rscript -e 'devtools::document()'`.
- After code changes, before a task is checked off: `Rscript -e 'devtools::test()'` clean.
- Before a task touching `vignettes/`, `README.Rmd`, `R/` or `man-roxygen/` is checked off: `Rscript benchmarks/sweep-prose.R --plain` clean, and `--roxygen --plain` after roxygen changes.
- `/hotfix` gate-lite: `devtools::test()` clean; `devtools::document()` if roxygen changed; `devtools::check()` if anything structural was touched.

## consistency-gate
Toolchain checks `/milestone-review` runs *in addition to* the universal
cairn-file checks (`cairn_validate`, coverage completeness, `cairn_impact`):
- `devtools::document()` produces no diff.
- Generated files are never hand-edited: `NAMESPACE`, `man/`, and `data/*.rda`
  regenerate from roxygen and `data-raw/` scripts (the no-diff `document()`
  check catches drift).
- README.md is knitted from README.Rmd; present and out of sync with README.md → `devtools::build_readme()`, commit.
- pkgdown site present → `pkgdown::check_pkgdown()` passes (catches exports missing from `_pkgdown.yml`).
- The declared changelog (`## changelog` slot) has an entry for this milestone's user-visible changes (no milestone numbers in user-facing text).
- New top-level files have `.Rbuildignore` entries (check `check()` NOTEs).
- Full check at review: `Rscript -e 'devtools::check()'` clean (0 errors, 0 warnings; justify NOTEs).
- The six gating prose sweeps clean: `Rscript benchmarks/sweep-prose.R`, `--spans`, `--plain`, and each of the three with `--roxygen` (also run by `prose-sweep.yaml` and `tests/testthat/test-sweep-prose.R`).

## test-doctrine
R-mechanical test expectations layered on the universal "What gets a test"
rules in tracking-rules:
- Tests are written for `testthat` edition 3 (3e).
- Every exported function: happy path, every `cli_abort()` branch fired, R edge cases — zero rows, `NA`, length-one,
  factor vs. character, empty strings.
- New user-facing conditions use `cli::cli_abort()` / rlang, not assertthat.
- Indirect by default: internal helpers (direct tests only for independent logic).
- Never test print cosmetics beyond meaningful snapshots, trivial pass-throughs, dependency behavior, or plots except
  `vdiffr` when the plot is the product.
- `covr` is a diagnostic, never a gate.
- CI starts from the usethis pair: `check-standard` runs `R CMD check` across platforms (a normal CI check — see the
  merge clause below), `test-coverage` runs `covr` to Codecov, annotating a PR but never gating it; `.github/` is
  `.Rbuildignore`d.
- Divergences from that stock shape (M11 ×2, M12 rev. M31, M14, M33, M52, M78, M80, M88). **A `concurrency` block** cancels a
  superseded run on every ref but the default branch, a distribution channel that keeps a completed check instead. **A
  `paths-ignore` filter** on both triggers of `R-CMD-check-hard.yaml`, `R-CMD-check.yaml`, `devel-vctrs.yaml`,
  `pkgdown.yaml`, `prose-sweep.yaml` and `test-coverage.yaml` skips `cairn/**`, `CLAUDE.md`, `.claude/**`, which cannot change what `R CMD
  check` sees — that is the test a fourth path must meet; it bites on `push` only, GitHub evaluating it on a
  `pull_request` against the whole PR diff. **Hang caps** turn a hang into a failed job with a timestamp; every figure
  stays in the workflow declaring it. `R-CMD-check.yaml` bounds its job and its `check-r-package` step separately, the
  step higher on windows; `test-coverage.yaml`, `R-CMD-check-hard.yaml` (M57), `devel-vctrs.yaml` and `prose-sweep.yaml`
  (M88, its `push` with no `branches` filter, the yaml saying why) each bound one job; `pkgdown.yaml` bounds `build` and `deploy` apart. Each yaml comment holds its own measurements and rationale.
  The step bound is the guarantee, both pre-M14 hangs having sat in `test_check("nestedtune")` (52 minutes under `R
  CMD check`, 40 under `covr`), which is why each workflow carries its own; the job bound covers the devel leg's
  from-source dependency build, which a smaller one once killed before cache-save. A step bound is not free headroom:
  a leg nearing its own is a suite to make faster (M52). **Parallel test files** (`Config/testthat/parallel: true`,
  M52): `Config/testthat/start-first` in DESCRIPTION queues named files first, so a long file cannot land last
  (corrected M76: the run is *not* bounded by its largest file and re-ordering has nothing to recover;
  `benchmarks/test-timing-parallel.md` owns the measurements). The worker count is `TESTTHAT_CPUS` (testthat reads
  `getOption("Ncpus")` first when set; no `.Rprofile` here sets it), set at one per runner core in the job `env:` of
  the four workflows that run the whole suite and left at testthat's default of 2 locally; the stress workflow below
  sets none, running one file per process. **A `workflow_dispatch`-only stress
  workflow** (`stress-daemon-tests.yaml`) hunts the hang on demand under a job cap far above the rest, invisible to
  `ci-usage.py` for carrying neither trigger. **A devel-vctrs leg** (`devel-vctrs.yaml`, M80) runs the suite against
  vctrs from `r-lib/vctrs@main`, watching the experimental `vec_cbind_frame_ptype()` `R/nested-results.R` has a method
  on; non-gating and outside the required checks, so an unreleased upstream branch cannot freeze a merge here. **Three
  organization workflows** ride unedited at tidymodels' shared blobs (`lock.yaml`, `pr-commands.yaml`,
  `format-suggest.yaml`, M33): no `push`/`pull_request` trigger, so neither the filter nor `ci-usage.py` sees them;
  `format-suggest.yaml` runs `air format .` (see DESIGN).
- Locating a hang, since the cap only ends one: `HangTraceReporter` (`tests/testthat/helper-hang-trace.R`) writes
  timestamped start/end lines per test file and per `test_that()` block to unbuffered `stderr()`, so a killed job's
  last unmatched `start` names the block it died in (M14, per-test M16; under parallel files it runs in the parent in
  testthat's live-update mode, M52).
- `.github/ci-usage.py` measures the first two over any window in GitHub's 90-day retention (baseline:
  `.github/ci-usage-baseline.md`), counting commits from `git log` and never crediting a cancelled run its whole
  would-be duration.
- **The merge clause, for the filters:** cairn never merges red or pending CI. A filtered event produces no run, so
  its check is absent rather than pending and merging past it is correct; what it forbids is a check that ran and
  failed, or one still running. Required status checks (none here) would leave a filtered check `Pending` forever.
- Change governance: the dependency surface is DESCRIPTION Imports/Suggests, and a breaking change warns via
  `lifecycle::deprecate_warn()` before removal. The gates themselves are universal (tracking-rules "Universal tracking
  rules").
- Every newly exported object gets a `_pkgdown.yml` reference-index row in the same commit.
- Every committed test fixture carries reproducible provenance: its source, the committed `data-raw/` generator that
  rebuilds it from scratch, and any seed — the R-mechanical form of the universal Reproducibility hard-stop. That
  content is required; its shape is the repo's choice (a `provenance` attribute, embedded `.rds`/`.rda` fields, or a
  header comment naming source + generator + seed).

## release-walk
Followed by `/cairn-release` — a CRAN release walk (never self-submits):
- Version decision (patch/minor/major) from the declared changelog; pre-1.0 conventions per DESIGN.md.
- Changelog consolidation (the declared file): retitle the dev heading to the version; group entries; prune noise.
- Full local verification: `devtools::document()` (no diff), `devtools::test()`
  and `devtools::check()` clean, `devtools::build_readme()`, `pkgdown::check_pkgdown()`,
  `urlchecker::url_check()`.
- Wide checks as applicable: `devtools::check_win_devel()` and/or R-hub; `revdepcheck` if dependents exist.
- Update `cran-comments.md` (test environments, check results, NOTE justifications, revdep summary).
- Bump `Version:` in DESCRIPTION.
- Handoff checklist (user runs): `devtools::submit_cran()`, confirm the CRAN
  email, then `usethis::use_github_release()` + `usethis::use_dev_version()`.

## init-detection
Recognized by `cairn-init` when a **`DESCRIPTION` file is present** at the repo
root. Carries the `.Rbuildignore` `^cairn$` entry (keeps the tracking dir out
of the built package).

## greenfield-openers
Language-specific opener `cairn-init` asks in a new/empty R package; the
universal openers (CRAN intent, numeric-work oracle verification) come from
cairn-init's universal layer.

- **Compiled code?** Rcpp / RcppArmadillo / C / C++ / Fortran, or pure R?
  Compiled means a `src/` dir, `LinkingTo`, a C/C++ toolchain, and `R CMD
  check` compiling on every check; adding it later is additive, so pure R is
  the reversible default. Lands in DESIGN Conventions (a "compiled code via
  <pkg>" line) and informs the `verify` / `test-doctrine` check surface.

## changelog
The repo's changelog file, read by `/hotfix`, the release-walk, and the
consistency-gate: **`NEWS.md`** (the R-package convention).
