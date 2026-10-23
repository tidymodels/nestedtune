# M153: The devel-vctrs job runs the vctrs test files on each push and the whole suite each week

**Status:** done (2026-10-23, PR #170 https://github.com/tidymodels/nestedtune/pull/170)

**Goal:** On a push or pull request, the `devel-vctrs.yaml` job runs only the test files that exercise vctrs. On its weekly schedule, it runs the whole suite.

**Outcome:** `.github/workflows/devel-vctrs.yaml` only; no `R/`, test, help or NEWS change.
- The test step passes `filter = "^(vctrs-compat|dplyr-compat|nested-results-set-compat)$"` to `testthat::test_local()` unless its `FULL_SUITE` env value is `true`, which it is on `schedule` and on a `workflow_dispatch` whose new boolean input `full` (default true) is true. The step prints `Whole suite: TRUE|FALSE`.
- The workflow-level concurrency group is keyed on the same expression as well as workflow and ref, so a three-file run never cancels or replaces a whole-suite run.
- Header comments state the split and that other test files (`test-nested-tune-bayes-oracles.R`) also call vctrs functions; the timeout comment cites the three-file run (job 120134601264 of run 39867888167). `cairn/PROFILE.md`'s CI sentences state the split.
- Runs on the final workflow: 39867888167 (`full=false`, three files, 988 passes, 2m38s) and 39867891668 (`full=true`, all 105 files, 13367 passes, 36m43s), side by side; the PR's `pull_request` run took 1m57s.

**Decisions:** D-119 narrows D-116 for this job. D-119 was corrected in place before merge, since it existed only on the branch.

**Review:** Four-lens fan-out, two passes. Pass 1: gate failure (`PROFILE.md` 121 lines, cap <120) and a concurrency defect (a three-file push run could replace a pending weekly whole-suite run, and the plan's two dispatches cancelled each other), sent back as review return 1 with the wording fixes; T5 fixed both and reran the dispatches. Pass 2: 9 fixed (timing citation with job id, D-119 verb, PROFILE sentences, concurrency pointer). Totals: 23 fixed, 21 rejected with reasons, 2 to the new row "Guard the devel-vctrs filter from drift". `devtools::check()` 0/0/0; `document()` changed only the roxygen2 version stamp (local 8.1.1), reverted as tool drift. The first CI wait hit the tool ceiling; on resume the pkgdown `build` job had hit its 20-minute cap in the runner's apt installs and passed on rerun, and the merge was re-approved. No candidate graduated or unparked. One lesson extended (M50 line).
