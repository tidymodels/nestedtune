# M150: macOS CI takes CRAN binaries again

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — CI configuration, which no user of the package relies on
- **Branch/PR:** m150-macos-cran-binaries, https://github.com/tidymodels/nestedtune/pull/167

## Goal

The macOS CI jobs install their R packages from CRAN's binaries instead of P3M's.

## Scope

**In:** `.github/workflows/R-CMD-check.yaml`: the macOS leg takes CRAN binaries (`use-public-rspm: ${{ matrix.config.os != 'macos-latest' }}`, the form tidymodels/tune uses), the `gower?source` build and its comment go, and the setup-r comment is rewritten. `.github/workflows/stress-daemon-tests.yaml`, the one other workflow that can run on macOS (found by `git grep use-public-rspm`), gets the same split. One manual stress run on the branch checks its install step. A D-entry records the choice. One README sentence (`README.Rmd` and `README.md`) loses the modal that keeps `prose-sweep.yaml` and `test-sweep-prose.R` red on main since 60be3479, since this PR cannot merge with that check red.

**Out:** the Linux and Windows legs, `pkgdown.yaml`, `pr-commands.yaml` and `R-CMD-check-cran.yaml`, which run off macOS and keep P3M. pak reading zstd archives is upstream work (r-lib/pkgdepends#485). A test pinning the repository choice in `test-ci-workflows.R` is not added, because the CI run on the PR is the check. No NEWS entry, because nothing a user sees changes.

## Acceptance criteria

- [x] AC1: In `.github/workflows/R-CMD-check.yaml`, the `setup-r` step's `use-public-rspm` expression evaluates to `false` for the `macos-latest` matrix entry and to `true` for each of the other four entries, and the `setup-r-dependencies` step's `extra-packages` expression evaluates to `any::rcmdcheck` for all five.
- [x] AC2: In `.github/workflows/stress-daemon-tests.yaml`, the `setup-r` step's `use-public-rspm` expression evaluates to `false` when `inputs.os` is `macos-latest` and to `true` when it is `ubuntu-latest` or `windows-latest`.
- [ ] AC3: On the milestone PR's CI run, the `macos-latest (release)` job of `R-CMD-check.yaml` passes, and its `setup-r-dependencies` step installs packages from CRAN, not from P3M (`packagemanager.posit.co`).
- [x] AC4: A `workflow_dispatch` run of `stress-daemon-tests.yaml` on the milestone branch with `os: macos-latest` and `iterations: 1` completes its `setup-r-dependencies` step, installing packages from CRAN, not from P3M.
- [x] AC5: In `R-CMD-check.yaml`, the comment above `use-public-rspm` states that macOS takes CRAN binaries and the other legs take P3M binaries, and the comment block above `setup-r-dependencies` that explains `gower?source` is removed. In `stress-daemon-tests.yaml`, a comment above `use-public-rspm` states the same split.
- [x] AC6: The profile's `verify` slot is clean: `devtools::test()` passes, `test-ci-workflows.R` included.

## Coverage

- AC1 → T2
- AC2 → T3
- AC3 → T1, T2
- AC4 → T3, T5
- AC5 → T2, T3
- AC6 → T4, T7

## Tasks

- [x] T1: Re-run the zstd probe. Take the recursive Depends/Imports/LinkingTo closure of `DESCRIPTION`'s Depends, Imports and Suggests plus `rcmdcheck`, from CRAN's `bin/macosx/sonoma-arm64/contrib/4.6/PACKAGES`. Read the first four bytes of each binary with a range request. Log the counts per format in one work-log line. If any file starts `28b52ffd` (zstd), set the milestone `blocked`, naming the package, and stop.
- [x] T2: In `R-CMD-check.yaml`, set `use-public-rspm` to `${{ matrix.config.os != 'macos-latest' }}`, set `extra-packages` to `any::rcmdcheck`, and delete the `gower?source` comment block. Rewrite the setup-r comment from T1's output and same-session reads, not from this plan: P3M's macOS binaries link OpenMP and the runners ship no libomp (job 99324307884 of run 33336519275); r-lib/actions#1110 made P3M the macOS default on 2026-09-21, so `false` there is a departure; pak still cannot read zstd (r-lib/pkgdepends#485), so a zstd binary on CRAN breaks this leg as on PR #118. Pin the T1 result with its date and procedure.
- [x] T3: In `stress-daemon-tests.yaml`, set `use-public-rspm` to `${{ inputs.os != 'macos-latest' }}` with a short comment that states the split and points at `R-CMD-check.yaml`'s comment.
- [x] T4: Run the verify slot: `Rscript -e 'devtools::test()'`. `test-ci-workflows.R` parses `R-CMD-check.yaml`.
- [x] T5: Push the branch, which starts no check workflow (their `push` filter is the default branch), and dispatch `gh workflow run stress-daemon-tests.yaml --ref <branch> -f os=macos-latest -f iterations=1`. Log the run id, the install step's result, and the `packagemanager.posit.co` count in its job log.
- [x] T6: Append a D-entry: the macOS CI jobs take CRAN binaries, departing from setup-r's default since r-lib/actions#1110. Rejected: staying on P3M with `gower?source`. Falsified by a zstd binary in the macOS install closure, or a CRAN binary failing to load on the runner.
- [x] T7: Rewrite the `README.Rmd:138` sentence that `sweep-prose.R --plain` flags as a modal, and the same sentence in `README.md`.

## Work log

- 2026-10-20: created by /milestone-plan.
- 2026-10-20: tier check: milestone — a CI configuration change that departs from setup-r's macOS default is a design decision.
- 2026-10-20: collision check: absorbs candidate row "macOS off P3M after zstd support". M147, M033 and D-076 (macOS alone builds the vignettes) read; no overlap, and D-076 is unaffected. Inbox sweep: 1 open issue (#91), 0 open PRs, no overlap.
- 2026-10-20: zstd probe at plan time: pkgdepends#485 still open with no zstd commit (last commit 2026-08-14), but of the 165 CRAN macOS arm64 binaries in the install closure, 152 are gzip, 13 are xz, 0 are zstd. pak's `detect_package_archive_type()` reads gzip, bzip2 and xz.
- 2026-10-20: question set: move macOS to CRAN now, stay on P3M, or keep waiting — move to CRAN now.
- 2026-10-20: question set: one dispatch of stress-daemon-tests on the milestone branch (macOS, 1 iteration) — granted.
- 2026-10-20: plan gate chose CRAN binaries on macOS over staying on P3M (setup-r's default since r-lib/actions#1110) because P3M's macOS binaries link OpenMP the runners lack, and tidymodels/tune takes CRAN on macOS; falsified by a zstd binary in the macOS install closure, or a CRAN binary failing to load on the runner.
- 2026-10-20: plan chose dropping `gower?source` over keeping it, because its comment ties it to the P3M binary; falsified by `gower` failing to load from CRAN's binary on the macOS leg.
- 2026-10-20: plan chose to include `stress-daemon-tests.yaml`, the other macOS site `git grep use-public-rspm` finds. No test added to `test-ci-workflows.R`, so the CI-file checker is not extended. No NEWS entry.
- 2026-10-20: criteria audit (reduced mode, fresh Opus reader) returned 3 findings, all fixed: AC3 and AC4 bound a log grep and run ids (instrument), reworded to the install source; AC5 swept a recalled keyword list (bounded promise), narrowed to two named comment sites.
- 2026-10-20: lessons harvested: push restarts the PR matrix, so keep docs-only commits local while the PR waits (M50); name a CI run by id (M51).
- 2026-10-20: implement started on m150-macos-cran-binaries, cut from main at 21835c1c.
- 2026-10-20: T1: probe re-run against CRAN's `sonoma-arm64/contrib/4.6/PACKAGES`: 165 binaries in the closure, 152 gzip (`1f8b0800`), 13 xz (`fd377a58`), 0 zstd. No stop.
- 2026-10-20: T2: `R-CMD-check.yaml` sets `use-public-rspm` to `${{ matrix.config.os != 'macos-latest' }}` and `extra-packages` to `any::rcmdcheck`; the `gower?source` block is gone and the setup-r comment is rewritten from T1's output, PR #118, ab1faf53 and r-lib/actions#1110 (each read this session). Both files parse with `yaml::read_yaml()`. The comment does not claim CRAN's `gower` loads on the runner, since no run observed that; AC3 will.
- 2026-10-20: T3: `stress-daemon-tests.yaml` sets `use-public-rspm` to `${{ inputs.os != 'macos-latest' }}`, with a two-line comment pointing at `R-CMD-check.yaml`'s.
- 2026-10-20: T6: D-118 appended (macOS CI jobs take CRAN binaries; rejected staying on P3M with `gower?source`).
- 2026-10-20: T5: branch pushed at b24238e5; dispatched stress-daemon-tests run 39378513433 (job 118481968962, macos-latest, 1 iteration) passed, its `setup-r-dependencies` step included. Its job log has 0 `packagemanager.posit.co` lines; packages came from `cran.rstudio.com/bin/macosx/sonoma-arm64/contrib/4.6/`, `gower` 1.0.2 among them (`Got gower 1.0.2 (aarch64-apple-darwin23)`).
- 2026-10-20: T4: full `devtools::test()` at 28a102a6: one failure, `test-sweep-prose.R:302-303`, the plain sweep flagging a modal at `README.Rmd:138`. That line came from 60be3479 on main, where `prose-sweep.yaml` is red since (runs on 60be3479 and 31dc1e84). `test-ci-workflows.R` passed.
- 2026-10-20: substantive amendment: Scope In adds the README sentence fix (T7), because `prose-sweep.yaml` runs on this PR and a red check blocks the merge. No criterion changes; AC6 now maps to T4 and T7.
- 2026-10-20: T7: the sentence now reads "Selecting on a sum-of-squares metric also tends to pick the largest number of clusters in the grid. An estimate from that selection describes the grid and not the data." in both READMEs, edited by hand since a re-knit is not needed for one prose line (the two texts compared equal). `sweep-prose.R --plain` prints clean; `test-sweep-prose.R` and `test-ci-workflows.R` pass.
- 2026-10-20: claim audit: not owed — internal tier.
- 2026-10-20: all tasks checked; status review.
- 2026-10-20: review started at e2b461ba; main had not moved (0 commits ahead of the branch point), no PR, Copilot round off.
- 2026-10-20: step-7 approval: m150-macos-cran-binaries approved for merge

## Review

- AC1: `yaml::read_yaml()` of `R-CMD-check.yaml` at e2b461ba, each matrix entry's `use-public-rspm` and `extra-packages` evaluated: macos-latest release `FALSE`; windows-latest release, ubuntu devel, ubuntu release, ubuntu oldrel-1 `TRUE`; `extra-packages` `any::rcmdcheck` on all five. Pass.
- AC2: the same read of `stress-daemon-tests.yaml` over the `os` input's three options: macos-latest `FALSE`, ubuntu-latest `TRUE`, windows-latest `TRUE`. Pass.
- AC4: run 39378513433 (job 118481968962, dispatched on the branch at b24238e5 with `os: macos-latest`, `iterations: 1`; both workflow files are unchanged since) concluded success, its `setup-r-dependencies` step success. Its job log holds 0 `packagemanager.posit.co` lines, and packages came from `https://cran.rstudio.com/bin/macosx/sonoma-arm64/contrib/4.6/`, `gower` 1.0.2 among them. Pass.
- AC5: `R-CMD-check.yaml:174-175` opens "The macOS leg takes CRAN's binaries and the other four legs take P3M's"; the `setup-r-dependencies` step has no comment block above it, and the one remaining `gower?source` mention (line 197) is the fallback instruction. `stress-daemon-tests.yaml:58-59` states "macOS takes CRAN's binaries and ubuntu and windows take P3M's". Pass.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: the comment said `true` put macOS on P3M "since r-lib/actions#1110", but job 99324307884 (2026-08-30) already ran macOS on P3M through setup-r's default — fix now: the comment now says that job ran with it and #1110 made it the default for every repository., fixed 771b30fb
- diff-bug #2: "Commit ab1faf53's version of the file" as the way back would revert the later vignette split and CRAN jobs and break `test-ci-workflows.R` — fix now: the comment and D-118 name the two lines to change and say not to restore that version whole., fixed 771b30fb
- diff-bug #3: "the other four legs take P3M's" binaries is not true for devel, which builds from source — fix now: the comment says the four legs take their packages from P3M and that devel gets source packages there., fixed 771b30fb
- diff-bug #4: the candidate row "macOS off P3M after zstd support" still describes the old setup — reject (planned change): step 9's hygiene deletes the row this milestone graduates.
- diff-bug #5: "CRAN once shipped" reads broader than the closure probe — fix now: "CRAN shipped", plus a sentence that the probe covers this closure on that date, not CRAN as a whole., fixed 771b30fb
- diff-bug #6: no run has yet loaded CRAN's `gower` on the macOS runner — reject (planned change): the plan accepted this risk and AC3, read before the merge, is the run that loads it.
- blame-history #1: same as diff-bug #6 — reject (planned change), as above.
- blame-history #2: the branch reverts on a probe snapshot, not on pkgdepends reading zstd as ab1faf53's comment said, and the ROADMAP row is stale — reject (planned change): the user chose this at the plan gate, D-118 records it, and step 9 deletes the row.
- blame-history #3: the probe's closure may miss `gower`, reached through Suggests — reject (false): `closure.txt` lists `gower_1.0.2.tgz`, which `recipes` imports.
- blame-history #4: the README sentence lost its hedge ("would describe" became "describes") although the sentence before says "tends to" — fix now: it reads "When it does, the estimate describes the grid and not the data." in both READMEs; plain and default sweeps clean., fixed 771b30fb
- prior-review #1: same README hedge point, with M082 and M127 as the prior lessons — fix now, as blame-history #4, fixed 771b30fb.
- ripple #1: the candidate row "macOS off P3M after zstd support" now disagrees with the workflow — reject (planned change): step 9 deletes it.
- AC6: `devtools::check()` on the branch (tests run with `NOT_CRAN` true, vignettes rebuilt): Status OK, 0 errors, 0 warnings, 0 notes, 10m15s. After the review fixes, `devtools::test(filter = "sweep-prose|ci-workflows")` at 771b30fb passes with no failure. Pass.
- gate: `cairn_validate.py` all checks passed, coverage complete; no principle changed, so no `cairn_impact`. `devtools::document()` changed only `Config/roxygen2/version` (8.1.0 to the local 8.1.1), reverted, so no man/NAMESPACE drift. `pkgdown::check_pkgdown()` no problems. All six gating sweeps from `sweep-prose.R --list-gating` print clean. README.md matches README.Rmd on the edited sentence (hand-edited, compared). No NEWS entry: CI and one README wording change, nothing a user calls behaves differently. No new top-level files.
- AC3: pending; read from the PR's CI run at step 8, before the merge command.
