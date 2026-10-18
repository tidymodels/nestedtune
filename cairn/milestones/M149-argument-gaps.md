# M149: Three arguments from tidymodels: verbose on the map, a wide inner table, one workflow's plot

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1
- **Resolves:** —
- **Surface tier:** user-facing — three new arguments on exported functions
- **Branch/PR:** m149-argument-gaps

## Goal

The three argument gaps that M148's review proposed are closed in the tidymodels shape, and each argument default that differs from its counterpart has a verdict.

## Scope

**In:** `verbose` on `nested_workflow_map()`. `type = c("long", "wide")` on both `collect_inner_metrics()` methods. `id` on `autoplot.nested_results_set()`. Their help text and one NEWS entry. The review page `cairn/references/export-surface-review.md` updated for the three arguments, with a verdict on each differing default.

**Out:** Changing any argument default. A default verdict of `proposed` becomes a candidate row. A default comparison inside `benchmarks/export-surface.R`: the page records the one-time procedure instead. A failure line under `verbose`: an error stops the run and already names the workflow.

## Acceptance criteria

- [ ] AC1: `nested_workflow_map()` takes `verbose = FALSE` between `fn` and `...`, where `workflowsets::workflow_map()` puts it. With `verbose = TRUE`, a run writes one message as each workflow starts, and one as each workflow finishes without error. Each message names the workflow's position in the set, its route, and its `wflow_id`. The route reads `tuning` or `resampling`. The end message also gives the time the workflow took. A test runs a set of one tuned and one fixed workflow and snapshots the four messages with the time masked. The same test asserts that the run with `verbose = FALSE` signals no message, and that the two runs return identical results. A `verbose` that is `NA`, of length 2, or not logical is refused with class `nestedtune_bad_verbose` before any workflow runs, and a test asserts each of the three.
- [ ] AC2: `collect_inner_metrics()` on a `nested_results` and on a `nested_results_set` takes `type = c("long", "wide")` after `...`, as tune's `collect_metrics()` does. `"long"` returns the table that the call without `type` returns. `"wide"` has one column per metric that holds `mean`. It drops `.metric`, `.estimator`, `mean`, `n`, `std_err` and `.weight`, and keeps every other column as a key. A test rebuilds fold 1's inner `tune::tune_grid()` run and asserts that fold 1's wide rows, less the fold-label columns, equal `tune::collect_metrics(type = "wide")` on that run. A second test asserts that `.iter` stays a key column on a `nested_tune_bayes()` run. A third asserts that the set's wide table carries `wflow_id`. A metric named like a key column is refused with class `nestedtune_wide_collision`, and a `type` outside the two values with class `nestedtune_bad_type`. A test asserts each class on each method.
- [ ] AC3: `autoplot()` on a `nested_results_set` takes `id = NULL` after `...`. With a `wflow_id`, it returns the plot that `autoplot()` on that workflow's `nested_results` returns for the same `type`, `metric` and `eval_time`. A test on a tuned workflow asserts for `type = "parameters"` and for `type = "performance"` that the two plots' `ggplot2::ggplot_build()` data are identical. With `id = NULL`, the three existing set-plot snapshots pass. An `id` other than `NULL` that is not one string naming a row of the set is refused with class `nestedtune_unknown_id`, and a test asserts it.
- [ ] AC4: `cairn/references/export-surface-review.md` marks its three `proposed` rows `added`, and its verdict definitions say what `added` means. Every argument difference that `Rscript benchmarks/export-surface.R` prints at the milestone's head for the three changed items has a row with a verdict. The page also gives a verdict, `kept` or `proposed`, with a reason, for each argument default that differs from its counterpart's. Those defaults are the ones found by comparing the deparsed default of every argument both sides share, over every pair in the script's `pairs` table. No default changes in this milestone.
- [ ] AC5: The `verbose`, `type` and `id` text on each changed help page names the function or method it applies to. `NEWS.md` gains one entry that names the three arguments. `devtools::test()` passes, and `devtools::check()` reports 0 errors, 0 warnings and 0 notes.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T4
- AC5 → T1, T2, T3, T5

## Tasks

- [ ] T1: `verbose` in `R/nested-workflow-map.R:86`, before `...`. Check it before the per-workflow checks, with class `nestedtune_bad_verbose`. Print with `cli::cli_inform()` at each start and each clean finish, inside the loop at the `run_orchestrator()` call. Tests go in `test-nested-workflow-map-checks.R` and `test-nested-workflow-map-readers.R`, under `skip_if_no_wset_fixture()` (the M101 lesson). Mask the time in the snapshot with `transform`. Update `@param verbose` and the `@details` order sentence.
- [ ] T2: `type` on `collect_inner_metrics.nested_results()` (`R/nested-results-collect.R:100`) and the set method (`R/nested-results-set.R:86`). Read it with `check_metrics_type()` and pivot with `pivot_metrics_wide()` (`R/nested-results.R:836`); the set pivots once after `stack_set()`, as `collect_metrics()` does. Build the fold 1 oracle on `analysis_framed_inner()`'s output (the M05 lesson). Plant the key collision with a parameter id named like a metric. Write `@param type` text that names `collect_inner_metrics()` on both pages.
- [ ] T3: `id` on `autoplot.nested_results_set()` (`R/nested-results-plot.R:574`). A non-`NULL` id goes through `match_set_id()` and then `autoplot()` on that row's result, with the same `type`, `metric` and `eval_time`. Tests go in `test-nested-results-plot.R` beside the set snapshots. Write `@param id`.
- [ ] T4: Update the review page for AC4. Run `benchmarks/export-surface.R` at the head and give each new difference a row: `type` on the set's `collect_inner_metrics()` beside workflowsets' `collect_metrics()`, and the `id` default. Run the default comparison over the `pairs` table. Write each verdict, and name the procedure and its date in the page. Add a candidate row for any `proposed` default (search first).
- [ ] T5: One NEWS entry for the three arguments. Run `devtools::document()`, the prose sweeps from the verify slot, `air format --check .`, `devtools::test()` and `devtools::check()`.

## Work log

- 2026-10-18: created by /milestone-plan.
- 2026-10-18: tier check: not run — work named at the question set.
- 2026-10-18: absorbed the candidate row "Argument gaps beside tidymodels" in full, the defaults note included. No other ROADMAP row, archive or D-entry overlaps (D-019, D-043, D-052, D-058 and D-117 read whole). Inbox sweep: issue #91 open, no overlap; no open PRs.
- 2026-10-18: criteria audit (full mode, fresh Opus reader) returned 11 findings, all fixed: end message only on a clean finish; classes named; the two-estimator refusal left to the pivot's own test, since no fixture reaches it here; `.weight` named among the dropped columns; a Bayes probe for `.iter`; `NULL` taken out of the refused ids; a tuned workflow for both plot types; snapshots named as the unchanged-plot check; `added` in place of `changed`; counts clause replaced by a row for each new difference; help text must name the method. Answered: `check()` with 0 notes stays, as in M148.
- 2026-10-18: plan gate chose `verbose` before `...` over after it, because it matches `workflow_map()`'s order and every `...` argument must be named; falsified by an orchestrator argument whose name is a prefix of `verbose`.
- 2026-10-18: plan gate chose `id = NULL` over workflowsets' `id = "workflow_set"`, because a workflow could carry that id and `nested_final_fit()` reads ids with no sentinel; falsified by a user report that a copied workflowsets call breaks.
- 2026-10-18: plan gate chose no failure line under `verbose` over workflowsets' "failed with" line, because the error stops the run and already names the workflow; falsified by `nested_workflow_map()` coming to keep running after a workflow fails.
- 2026-10-18: plan gate chose a one-time default comparison recorded in the page over a new section of `benchmarks/export-surface.R`, so the script's promise does not widen; falsified by a later review needing the default comparison again.

- 2026-10-18: T1 code and tests in place: `check_map_verbose()` (class `nestedtune_bad_verbose`), start and finish lines through `cli::cli_inform()` with the text passed as a value. A design passed third by position now lands in `verbose`, so its refusal gains a hint that every argument of `fn` must be named, and the old unnamed-dots test moved to a fourth positional. Full suite pending.
- 2026-10-18: T2 code and tests in place: both methods read `type` with `check_metrics_type()` and pivot with `pivot_metrics_wide()`, the set once after stacking. The fold 1 oracle tunes on `inner_resamples[[1]]` directly, since `det_grid()` names every candidate and no range depends on the data. A planted defect (dropping `rsq` before the pivot) failed 4 assertions, the oracle among them. Full suite pending.
- 2026-10-18: T3 code and tests in place: a non-`NULL` `id` goes through `match_set_id()` before the type check, and the single-run method then reads `type`, `metric` and `eval_time` and gives its own refusals. Tests compare `ggplot_build()` data under both views and a metric filter, and refuse four bad ids. The plot file passed with its three set snapshots unchanged. Full suite pending.

## Decisions

## Review
