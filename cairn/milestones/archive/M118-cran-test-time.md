# M118: The test step CRAN runs uses at most 120 s of CPU, and CI still runs every slow test

**Status:** done (2026-09-27, PR #133 https://github.com/tidymodels/nestedtune/pull/133)

**Goal:** Under CRAN's conditions, the test step of `R CMD check --as-cran` uses at most 120 s of CPU. The CI check matrix still runs every test that this milestone skips on CRAN.

**Outcome:** `skip_heavy_on_cran()` in `tests/testthat/helper-cran.R` skips unless `NOT_CRAN` or `NESTEDTUNE_FULL_SUITE` reads as true through `as.logical()`. 41 test files outside the CRAN smoke layer call it at the top. The smoke layer is the input-refusal files, the reader files, files under 2 s at the branch point, and one end-to-end run per exported `nested_*` function. `R-CMD-check.yaml` sets `NESTEDTUNE_FULL_SUITE: true`, but `setup-r` already sets `NOT_CRAN: true` in every CI job, so every job runs the full suite and none runs the CRAN subset. `benchmarks/cran-check-timing.md` records the command and the runs. Test CPU went from 560 s to 93 s, and the whole check from 370 s to 134 s (medians of three runs at the head). `devtools::test()` passes 11514 expectations with 0 skips.

**Decisions:** The CRAN smoke layer is decided per file, by class first and time second. Oracle, RNG, time-series and print-shape files skip, and three small oracle files stay under the 2 s rule. The plan gate chose a package switch over `NOT_CRAN=true` on the matrix, but CI already set `NOT_CRAN`, so the switch has no effect in CI today.

**Review:** The first review verified six criteria and returned AC4 for amendment. Its skip-count wording caught the helper's own `skip()`. Two fresh readers re-audited AC4, which now reads as a diff-line claim. The re-review fixed F1 (comments claimed that the hard job ran the CRAN subset) in prose only. It also fixed O3, O8, O9, O10, O12 and O13. O7 (testthat minimum version) went to a candidate row, and O6, O11 and O14 were rejected. Three post-fix CRAN runs overlapped other packages' checks and read 134-142 s. A clean rerun read 93 s. The first CI wait reached its timeout, and the resumed review merged on green CI. One lesson line was extended with `setup-r`'s `NOT_CRAN`.
