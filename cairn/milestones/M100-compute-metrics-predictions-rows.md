# M100: compute_metrics() refuses a fold whose saved predictions do not match what it held out

- **Status:** in-progress
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

- [ ] AC1: `compute_metrics()` on a `nested_results` with a completed fold whose `.predictions` fails `predictions_match_rows()` (`R/nested-results-collect.R:740`) against that fold's held-out rows refuses with a classed error whose message names that fold's labels and no other fold's, for each of the five mismatch shapes M093 enumerated (a missing row, a repeated `.row`, an `NA` `.row`, a foreign row, no `.row` column), and the refusal fires with the metric set called zero times.
- [ ] AC2: An unaltered run is scored as before: every `compute_metrics()` expectation in `tests/testthat/test-compute-metrics.R` and `tests/testthat/test-nested-workflow-map-readers.R` present at the branch point passes unedited, and a run on a repeated v-fold outer design (a row held out in more than one fold) is scored, not refused.
- [ ] AC3: The `compute_metrics()` help page names the refusal and the five shapes.
- [ ] AC4: `devtools::test()` clean, `devtools::check()` at 0 errors, 0 warnings, 0 notes, and every sweep `Rscript benchmarks/sweep-prose.R --list-gating` names runs clean.

## Coverage

- AC1 → T1, T2
- AC2 → T2
- AC3 → T3
- AC4 → T4

## Tasks

- [x] T1: Tests first in `test-compute-metrics.R`: one planted mutation per shape (mirror `test-augment.R:211-240`), asserting the class, the fold labels named and not named, and a metric set wrapped to count calls at zero; a repeated v-fold run scored.
- [x] T2: Generalize `check_predictions_rows()` to take the caller's class and verb (`nestedtune_compute_metrics_predictions`), call it in `compute_metrics.nested_results()` after `check_column_saved()`; confirm the set path names the workflow through `for_workflow()`.
- [ ] T3: Help page (`R/nested-results-collect.R` roxygen) and a NEWS bullet; `devtools::document()` (M92 lesson: confirm roxygen2 meets `Config/roxygen2/version`).
- [ ] T4: `devtools::test()`, `devtools::check()`, gating sweeps, `air format --check`.

## Work log

- 2026-09-16: created by /milestone-plan from the candidate row added 2026-09-14 (M093 Out).
- 2026-09-16: plan gate chose the full held-out match (as `augment()`) over a repeated-`.row`-only check because one rule for both readers is easier to state and M093 already enumerates the shapes; falsified by a tune version or preprocessor that completes a fold with fewer predictions than held-out rows, which would then refuse a valid run.
- 2026-09-16: question gate skipped, the plan fixed the class, the check's position and the help. T1: `plant_row_mismatch()` and `edit_fold_predictions()` moved from `test-augment.R` to `helper-predictions.R` (parallel test files each source the helpers, not each other). A counting metric set reads the folds scored. Twelve new expectations red before T2, `augment` green.
- 2026-09-16: T2: `check_predictions_rows()` takes `verb` (`augment` or `compute_metrics`, matched) and derives the class `nestedtune_<verb>_predictions` from it, one rule for both readers. `compute_metrics.nested_results()` calls it after `check_column_saved()`. The set path names the workflow through `for_workflow()` with no code change (set test green). Full `devtools::test()`, `--plain` sweep and `air format --check` clean.

## Decisions

## Review
