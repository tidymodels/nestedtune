# M165: Keep the devel-vctrs test choice from drifting

**Status:** done (2026-10-31, PR #181 https://github.com/tidymodels/nestedtune/pull/181)

**Goal:** Remove the two places where `devel-vctrs.yaml` can drift without a signal, while its push and pull-request runs stay limited to the vctrs test files.

**Outcome:** `.github/workflows/devel-vctrs.yaml` and a comment line in three test files; no `R/`, help or NEWS change.
- `test-vctrs-compat.R`, `test-dplyr-compat.R` and `test-nested-results-set-compat.R` carry the line `# devel-vctrs.yaml runs this file on every push and pull request.`
- On a push or pull request the test step selects the `tests/testthat/test-*.R` files holding that line as a whole line, prints them, stops with an error when none does, and builds the `test_local()` filter from their stems with regex characters escaped. A file renamed within `test-*.R` stays in; a file whose marker is removed leaves with no signal (D-122's falsifier).
- The step decides the whole-suite switch from `GITHUB_EVENT_NAME` and `FULL_INPUT` (`inputs.full`). The concurrency group is `workflow-ref-event_name-inputs.full`, so a scheduled run and a full dispatch now sit in separate groups.
- `cairn/PROFILE.md` lines 44 and 65 name the raw key and the marker. Plan gate: simplify the workflow over a drift test in `test-ci-workflows.R`, keep push runs off the whole suite.
- PR run 41205200894 (`pull_request`) watched the three files, contexts `dplyr-compat`, `nested-results-set-compat`, `vctrs-compat`, 988 passes.

**Decisions:** milestone-local: marker line over a `-compat` name convention; raw-value group key over the copied switch. D-122 narrows D-119.

**Review:** Four-lens fan-out, one pass: 17 lines, 8 fixed (comment and record wording: the group fixes the whole-suite choice, not the file list; the rename claim held to `test-*.R`; PROFILE line 65), 4 rejected as planned, 5 noted. No return. `devtools::check()` 0/0/0; `document()` changed only the roxygen2 stamp (local 8.1.1), reverted; CI 16 checks green; PR conversation empty. The merge waited one session on CI and resumed with a re-posed chip. The unpushed PR-URL, AC1-evidence, stop and approval commits went with the deleted branch; this summary records them. Graduated "Guard the devel-vctrs filter from drift". One lesson added; the M50 and M86 lessons marked used.
