# M112: Vignettes built and checked on the macOS check leg alone

**Status:** done (2026-09-23, PR #126 https://github.com/tidymodels/nestedtune/pull/126)

**Goal:** The four `R-CMD-check.yaml` legs other than macOS skip building and checking the vignettes, so their check step has room for M111's tests under its cap.

**Outcome:** The `check-r-package` step's `build_args` and `args` are each one expression keyed on `matrix.config.os == 'macos-latest'`. The other four legs pass `--no-build-vignettes` to `R CMD build` and `--ignore-vignettes` to `R CMD check`, and keep `--as-cran`. A block in `tests/testthat/test-ci-workflows.R` checks the four flag vectors through the helpers `step_value()` and `os_arms()`. It also checks for a single macOS matrix entry in flow or block form. It runs under `devtools::test()` only, since `.github/` is build-ignored. The step-cap comment gives the vignette cost from run 35801023421. It says `R-CMD-check-hard.yaml` checks the vignettes without tidymodels or ranger, and `pkgdown.yaml` knits them in full. The PROFILE test-doctrine slot states the same scope. On the PR run, the four legs finished in 23.7 to 25.6 min of job time.

**Decisions:** D-076 puts the vignettes on the macOS leg alone, and it is the first D-entry on the CI caps. D-077 corrects D-076 on what the hard-dependency job checks and on which leg M111 pushes past its cap.

**Review:** Two defect returns before the gate, both about tracking text. `cairn/PROFILE.md` reached its 120-line cap, and then AC2's "one clause" failed on a two-sentence split. All three criteria were then verified at `cf01af1`, and `devtools::check()` gave 0 notes, as at the branch point. The blame-history and prior-review lenses found nothing. The diff-bug lens ranked 8 findings. The gate fixed four. F1: the hard job runs the vignettes without their Suggests, as the M101 lesson already records. F3: the macOS count missed quoted and block spellings. F5: D-076's "slower legs". F6: a helper header. F2, F4 and F7 were rejected, and F8 was noted and settled by the green PR run. No lesson was added, because LESSONS.md sits at its byte budget.
