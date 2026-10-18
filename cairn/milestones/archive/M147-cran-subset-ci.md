# M147: CI runs the tests CRAN runs, with the Suggests and without them

**Status:** done (2026-10-18, PR #164 https://github.com/tidymodels/nestedtune/pull/164)

**Goal:** Two CI jobs run `R CMD check --as-cran` with `NOT_CRAN` false, so the test subset CRAN runs is checked on every pull request.

**Outcome:** `.github/workflows/R-CMD-check-cran.yaml` has two ubuntu R-release jobs. Each sets `NOT_CRAN: false` on its `check-r-package` step, leaves `NESTEDTUNE_FULL_SUITE` and `TESTTHAT_CPUS` unset (testthat's default of 2 workers, CRAN's two cores), and passes `--as-cran`.
- `check-cran-suggests` installs the Suggests from P3M binaries with the cache, and builds and checks the vignettes. `check-cran-no-suggests` copies `R-CMD-check-hard.yaml`'s dependency setup (`dependencies: '"hard"'`, no cache).
- Each job has a 30-minute job cap and a 20-minute step cap, its own artifact names (the action's defaults collide at job index 0), a `concurrency` block, and the shared `paths-ignore` list that `ci-usage.py` reads.
- `test-ci-workflows.R` gains `job_lines()` and a test pinning both jobs' `NOT_CRAN`, `args` and `dependencies`, with no switch line.
- Comments corrected in `helper-cran.R`, both existing check workflows (comment lines only), `benchmarks/cran-check-timing.md` and PROFILE.md's test-doctrine slot.

**Decisions:** D-116 records the two jobs, narrows M118's every-job-full-suite statement, and corrects D-077 on where the vignettes run in full.

**Review:** AC1 to AC3 passed. On PR #164 at `0ae0ae1d`, the Suggests job passed in 8m58s (FAIL 0, SKIP 121, PASS 7704) and the no-Suggests job in 7m19s (FAIL 0, SKIP 225, PASS 5206). Each listed 52 skips with the smoke-layer reason, and every job of the two existing check workflows passed. `devtools::check()` gave 0 errors, 0 warnings, 0 notes. Three lenses reported 26 findings: 22 fixed in `cf0b636c` (step caps, concurrency, two workers, D-116, comment fixes, setup pins), 2 rejected and parts of 2 others, 1 noted, and 1 handled at hygiene. The local no-Suggests check first stopped on missing Suggests, because `check-r-package` sets `_R_CHECK_FORCE_SUGGESTS_` false and the local run did not. The first CI wait reached its limit, and the resumed review merged. LESSONS lines on `NOT_CRAN` and `R_KEEP_PKG_SOURCE` were corrected, and nothing was retired.
