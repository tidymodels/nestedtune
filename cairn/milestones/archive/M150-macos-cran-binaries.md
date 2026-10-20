# M150: macOS CI takes CRAN binaries again

**Status:** dropped (2026-10-20, PR #167 https://github.com/tidymodels/nestedtune/pull/167, closed unmerged). The user chose to stay on P3M after two CI readings showed the macOS check step slower on CRAN binaries.

**Goal:** The macOS CI jobs install their R packages from CRAN's binaries instead of P3M's.

**Outcome:** Nothing merged. Branch `m150-macos-cran-binaries` (pushed, tip 0eafe6e4) set `use-public-rspm: ${{ matrix.config.os != 'macos-latest' }}` in `R-CMD-check.yaml` and `${{ inputs.os != 'macos-latest' }}` in `stress-daemon-tests.yaml`, dropped `gower?source`, and rewrote the setup-r comment. It also split the `README.Rmd:138` sentence whose modal keeps `prose-sweep.yaml` red on main since 60be3479; that fix did not land either.
- What it measured on 2026-10-20: of the 165 CRAN macOS arm64 binaries in the install closure (`sonoma-arm64/contrib/4.6`, read by first bytes), 152 were gzip, 13 xz, 0 zstd, so pak could read them all. pkgdepends#485 is still open.
- The installs worked: stress run 39378513433 and PR run 39425745143 took every package from `cran.rstudio.com`, `gower` included, and passed (`Status: OK`, 0 failures).
- The cost: the macOS `check-r-package` step took 29m50s (job 118637736671) and 26m29s (rerun, job 118855128571) against its 30-minute cap. Main's last P3M run took 22m41s (run 39197471635), and the 11 green P3M runs before it took 17m39s to 28m03s. Tests ran 48-53 min CPU on CRAN against 40 on P3M, and the vignette rebuild took 125-136 s against 78 s.

**Decisions:** D-118 was written on the branch only and never reached main. No D-entry records the drop; the candidate row "Move macOS CI off P3M binaries" holds the evidence and the promotion condition.

**Review:** AC1-AC6 passed with evidence; four lenses (diff-bug, blame-history, prior-review, ripple) reported 13 findings: 6 fixed on the branch, 7 rejected (6 planned change, 1 false), none to candidate rows. One inline finding (the macOS step time) went to the user, who first chose a rerun and then, on its 26m29s reading, chose to stay on P3M over raising the cap to 40 or merging at 30. The candidate row lost its `— started M150` token and was rewritten with these readings.
