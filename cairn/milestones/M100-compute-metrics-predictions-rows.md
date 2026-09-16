# M100: compute_metrics() refuses a fold whose saved predictions do not match what it held out

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP3
- **Resolves:** —
- **Surface tier:** user-facing — an exported reader's refusal
- **Branch/PR:** m100-compute-metrics-predictions-rows

## Goal

`compute_metrics()` on a nested run applies the same per-fold row check `augment()` applies (M093), so a fold whose saved predictions repeat, miss, or add a row is refused rather than scored.

## Scope

**In:** calling `check_predictions_rows()` (`R/nested-results-collect.R:715`) from `compute_metrics.nested_results()` (`:361`) before any fold is scored, under a class of its own; five planted mismatch tests; the help page and a NEWS bullet; the set method inherits through `stack_set()`.

**Out:** a `.row` check on `collect_metrics()` or `collect_predictions()` (they report what the run recorded; candidate row if wanted); averaging repeated predictions (`summarize = TRUE` candidate row); a check on `.extracts`.

## Acceptance criteria

- [x] AC1: `compute_metrics()` on a `nested_results` with a completed fold whose `.predictions` fails `predictions_match_rows()` (`R/nested-results-collect.R:740`) against that fold's held-out rows refuses with a classed error whose message names that fold's labels and no other fold's, for each of the five mismatch shapes M093 enumerated (a missing row, a repeated `.row`, an `NA` `.row`, a foreign row, no `.row` column), and the refusal fires with the metric set called zero times.
- [x] AC2: An unaltered run is scored as before: every `compute_metrics()` expectation in `tests/testthat/test-compute-metrics.R` and `tests/testthat/test-nested-workflow-map-readers.R` present at the branch point passes unedited, and a run on a repeated v-fold outer design (a row held out in more than one fold) is scored, not refused.
- [x] AC3: The `compute_metrics()` help page names the refusal and the five shapes.
- [ ] AC4: `devtools::test()` clean, `devtools::check()` at 0 errors, 0 warnings, 0 notes, and every sweep `Rscript benchmarks/sweep-prose.R --list-gating` names runs clean.

## Coverage

- AC1 → T1, T2
- AC2 → T2
- AC3 → T3
- AC4 → T4

## Tasks

- [x] T1: Tests first in `test-compute-metrics.R`: one planted mutation per shape (mirror `test-augment.R:211-240`), asserting the class, the fold labels named and not named, and a metric set wrapped to count calls at zero; a repeated v-fold run scored.
- [x] T2: Generalize `check_predictions_rows()` to take the caller's class and verb (`nestedtune_compute_metrics_predictions`), call it in `compute_metrics.nested_results()` after `check_column_saved()`; confirm the set path names the workflow through `for_workflow()`.
- [x] T3: Help page (`R/nested-results-collect.R` roxygen) and a NEWS bullet; `devtools::document()` (M92 lesson: confirm roxygen2 meets `Config/roxygen2/version`).
- [x] T4: `devtools::test()`, `devtools::check()`, gating sweeps, `air format --check`.

## Work log

- 2026-09-16: created by /milestone-plan from the candidate row added 2026-09-14 (M093 Out).
- 2026-09-16: plan gate chose the full held-out match (as `augment()`) over a repeated-`.row`-only check because one rule for both readers is easier to state and M093 already enumerates the shapes; falsified by a tune version or preprocessor that completes a fold with fewer predictions than held-out rows, which would then refuse a valid run.
- 2026-09-16: question gate skipped, the plan fixed the class, the check's position and the help. T1: `plant_row_mismatch()` and `edit_fold_predictions()` moved from `test-augment.R` to `helper-predictions.R` (parallel test files each source the helpers, not each other). A counting metric set reads the folds scored. Twelve new expectations red before T2, `augment` green.
- 2026-09-16: T2: `check_predictions_rows()` takes `verb` (`augment` or `compute_metrics`, matched) and derives the class `nestedtune_<verb>_predictions` from it, one rule for both readers. `compute_metrics.nested_results()` calls it after `check_column_saved()`. The set path names the workflow through `for_workflow()` with no code change (set test green). Full `devtools::test()`, `--plain` sweep and `air format --check` clean.
- 2026-09-16: T3: the Refusals section of the `compute_metrics()` help names the class, the five shapes and the fold naming, and a NEWS bullet says the same. roxygen2 8.1.0 meets `Config/roxygen2/version`. `document()` also rewrote `NAMESPACE` to one `importFrom()` per line: the default branch carries the wrapped form from a formatter commit, and both forms pass `air format --check`, so roxygen's form is committed here. `--roxygen --plain` and `--plain` sweeps clean.
- 2026-09-16: claim audit: 19 claims read, 1 corrected — NEWS.md, R/nested-results-collect.R, man/compute_metrics.nested_results.Rd. The five shapes were named as a closed list, and the check also refuses a `.row` that is not numeric or not a whole number; the list is now open and the whole-number case is named. The reader re-read the corrected wording once and it holds.
- 2026-09-16: T4: `devtools::check()` on the final head 0 errors, 0 warnings, 0 notes (8m19s). The six gating sweeps, `air format --check .` and `devtools::test()` are clean. Status to review.

## Decisions

## Review

- 2026-09-16 sync: `origin/main` at `dff2127` is an ancestor of the branch head. No PR exists for the branch.
- AC1: `devtools::test()` on the branch head, run alone, gave 10317 pass, 0 fail, 0 skip. `test-compute-metrics.R` plants each of the five shapes on fold 1 and fold 3. Each case asserts the class `nestedtune_compute_metrics_predictions`, the call name, the edited fold's label present, every other label absent, and zero metric calls. The counting metric set is itself tested to count one call per scored fold. The set path is covered in `test-nested-workflow-map-readers.R`. Verified.
- AC2: `git diff --numstat` shows `test-compute-metrics.R` +126/-0 and `test-nested-workflow-map-readers.R` +15/-0. Every branch-point expectation stands unedited and passed in the run above. The repeated v-fold test holds every row out twice and is scored with one metric call per fold. The censored-regression rescore test at `test-compute-metrics.R:190` passed under the new check with no skip. Verified.
- AC3: `man/compute_metrics.nested_results.Rd` carries the refusal paragraph naming the class and the five shapes. `devtools::document()` on the head produced no diff. The local roxygen2 is 8.0.0, below the declared 8.1.0, and roxygen only informs on an older version and generates as usual. Verified.
