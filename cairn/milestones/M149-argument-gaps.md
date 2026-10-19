# M149: Three arguments from tidymodels: verbose on the map, a wide inner table, one workflow's plot

- **Status:** review
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

- [x] AC1: `nested_workflow_map()` takes `verbose = FALSE` between `fn` and `...`, where `workflowsets::workflow_map()` puts it. With `verbose = TRUE`, a run writes one message as each workflow starts, and one as each workflow finishes without error. Each message names the workflow's position in the set, its route, and its `wflow_id`. The route reads `tuning` or `resampling`. The end message also gives the time the workflow took. A test runs a set of one tuned and one fixed workflow and snapshots the four messages with the time masked. The same test asserts that the run with `verbose = FALSE` signals no message, and that the two runs return identical results. A `verbose` that is `NA`, of length 2, or not logical is refused with class `nestedtune_bad_verbose` before any workflow runs, and a test asserts each of the three.
- [x] AC2: `collect_inner_metrics()` on a `nested_results` and on a `nested_results_set` takes `type = c("long", "wide")` after `...`, as tune's `collect_metrics()` does. `"long"` returns the table that the call without `type` returns. `"wide"` has one column per metric that holds `mean`. It drops `.metric`, `.estimator`, `mean`, `n`, `std_err` and `.weight`, and keeps every other column as a key. A test rebuilds fold 1's inner `tune::tune_grid()` run and asserts that fold 1's wide rows, less the fold-label columns, equal `tune::collect_metrics(type = "wide")` on that run. A second test asserts that `.iter` stays a key column on a `nested_tune_bayes()` run. A third asserts that the set's wide table carries `wflow_id`. A metric named like a key column is refused with class `nestedtune_wide_collision`, and a `type` outside the two values with class `nestedtune_bad_type`. A test asserts each class on each method.
- [x] AC3: `autoplot()` on a `nested_results_set` takes `id = NULL` after `...`. With a `wflow_id`, it returns the plot that `autoplot()` on that workflow's `nested_results` returns for the same `type`, `metric` and `eval_time`. A test on a tuned workflow asserts for `type = "parameters"` and for `type = "performance"` that the two plots' `ggplot2::ggplot_build()` data are identical. With `id = NULL`, the three existing set-plot snapshots pass. An `id` other than `NULL` that is not one string naming a row of the set is refused with class `nestedtune_unknown_id`, and a test asserts it.
- [x] AC4: `cairn/references/export-surface-review.md` marks its three `proposed` rows `added`, and its verdict definitions say what `added` means. Every argument difference that `Rscript benchmarks/export-surface.R` prints at the milestone's head for the three changed items has a row with a verdict. The page also gives a verdict, `kept` or `proposed`, with a reason, for each argument default that differs from its counterpart's. Those defaults are the ones found by comparing the deparsed default of every argument both sides share, over every pair in the script's `pairs` table. No default changes in this milestone.
- [x] AC5: The `verbose`, `type` and `id` text on each changed help page names the function or method it applies to. `NEWS.md` gains one entry that names the three arguments. `devtools::test()` passes, and `devtools::check()` reports 0 errors, 0 warnings and 0 notes.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T4
- AC5 → T1, T2, T3, T5

## Tasks

- [x] T1: `verbose` in `R/nested-workflow-map.R:86`, before `...`. Check it before the per-workflow checks, with class `nestedtune_bad_verbose`. Print with `cli::cli_inform()` at each start and each clean finish, inside the loop at the `run_orchestrator()` call. Tests go in `test-nested-workflow-map-checks.R` and `test-nested-workflow-map-readers.R`, under `skip_if_no_wset_fixture()` (the M101 lesson). Mask the time in the snapshot with `transform`. Update `@param verbose` and the `@details` order sentence.
- [x] T2: `type` on `collect_inner_metrics.nested_results()` (`R/nested-results-collect.R:100`) and the set method (`R/nested-results-set.R:86`). Read it with `check_metrics_type()` and pivot with `pivot_metrics_wide()` (`R/nested-results.R:836`); the set pivots once after `stack_set()`, as `collect_metrics()` does. Build the fold 1 oracle on `analysis_framed_inner()`'s output (the M05 lesson). Plant the key collision with a parameter id named like a metric. Write `@param type` text that names `collect_inner_metrics()` on both pages.
- [x] T3: `id` on `autoplot.nested_results_set()` (`R/nested-results-plot.R:574`). A non-`NULL` id goes through `match_set_id()` and then `autoplot()` on that row's result, with the same `type`, `metric` and `eval_time`. Tests go in `test-nested-results-plot.R` beside the set snapshots. Write `@param id`.
- [x] T4: Update the review page for AC4. Run `benchmarks/export-surface.R` at the head and give each new difference a row: `type` on the set's `collect_inner_metrics()` beside workflowsets' `collect_metrics()`, and the `id` default. Run the default comparison over the `pairs` table. Write each verdict, and name the procedure and its date in the page. Add a candidate row for any `proposed` default (search first).
- [x] T5: One NEWS entry for the three arguments. Run `devtools::document()`, the prose sweeps from the verify slot, `air format --check .`, `devtools::test()` and `devtools::check()`.

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
- 2026-10-18: T4 done: the review page marks the three rows `added` and defines the verdict, gives rows to the two new differences the script prints at `33d77fd6` (`type` on the set's `collect_inner_metrics()`, the order of `id`), and gives 7 default verdicts, all `kept`. No `proposed` default, so no candidate row.
- 2026-10-18: claim audit: 34 claims read, 2 corrected — tests/testthat/test-collect-inner-metrics-wide.R (a comment on the long table's rows), R/nested-results-collect.R and man/collect_selections.Rd (`type` now names the two-estimator refusal). The reader re-read both corrections and found them true.
- 2026-10-18: verify: `devtools::test()` at `33d77fd6` gave 15583 passes, 0 failures, 0 skips (later commits change docs, NEWS, a test comment and tracking only). `devtools::check()` at `832d8b17` in the main checkout gave 0 errors, 0 warnings, 0 notes; a first run in a git worktree gave one NOTE on the worktree's `.git` file, which a plain checkout lacks. `air format --check .` and both prose sweeps clean.
- 2026-10-18: minor amendment: T1's tests went to a new `test-nested-workflow-map-verbose.R` in place of the readers file, and T1's `@details` order sentence needed no change, since the details name no argument order. T1 to T3 and T5 ticked; status set to `review`.

## Decisions

- 2026-10-18 (review): `nested_workflow_map()` takes `verbose` by position, third, as `workflowsets::workflow_map()` does. This narrows M71's rule that every argument after `fn` is matched by name: now every argument after `fn` and `verbose` is. A third positional value that is not `TRUE` or `FALSE` is refused as `nestedtune_bad_verbose`, with a hint to name the rest. The plan gate chose this order over `verbose` after `...` (work log). It is milestone-local, since no D-entry made M71's rule.

## Review

Pass 1, 2026-10-18, at `d7c747b5`. The default branch had not moved (0 commits behind `origin/main`).

- AC1 evidence: `formals(nested_workflow_map)` reads `object, fn, verbose, ...` with `verbose = FALSE`, the place `workflow_map()` gives it. `test-nested-workflow-map-verbose.R` passed 3 of 3 with `NOT_CRAN=true`: the snapshot holds the four lines (`i 1 of 2 tuning: tuned`, its `v` finish line with the time masked, then `resampling: fixed` twice), the `verbose = FALSE` run signals no message, and the two results are identical. `test-nested-workflow-map-checks.R` passed 197 of 197, including the block that refuses `NA`, `c(TRUE, TRUE)` and `1` with `nestedtune_bad_verbose` and an untouched `.Random.seed`.
- AC2 evidence: both methods' formals read `x, ..., type` with `type = c("long", "wide")`. `test-collect-inner-metrics-wide.R` passed 19 of 19: `"long"` is identical to the call without `type` on a run and on a set; fold 1's wide rows, less `id`, are identical to `tune::collect_metrics(type = "wide")` on the reference loop's fold 1 `tune_grid()` run; `.iter` stays a key on `bayes_results()` with `.metric`, `.estimator`, `mean`, `n` and `std_err` absent; the set's wide table opens with `wflow_id`; a parameter id `rmse` gives `nestedtune_wide_collision` and `type = "tall"` gives `nestedtune_bad_type` on both methods. `.weight` is dropped by `pivot_metrics_wide()` (R/nested-results.R), which both methods call. Implement's planted defect failed 4 of these assertions.
- AC3 evidence: `formals(autoplot.nested_results_set)` reads `object, type, metric, eval_time, ..., id` with `id = NULL`. `test-nested-results-plot.R` passed 285 of 285 with vdiffr installed and no snapshot file changed (`git status` clean): the `ggplot_build()` data of `autoplot(set, id = "tuned")` equal the single run's under `"parameters"`, `"performance"` and `"performance"` with `metric = "rsq"`; the three set snapshots pass; `"nonesuch"`, `c("tuned", "fixed")`, `1` and `NA_character_` give `nestedtune_unknown_id`.
- AC4 evidence: `Rscript benchmarks/export-surface.R` at the head printed an argument half identical to the run at `33d77fd6` that the page cites. For the three changed items it prints `seed` (workflow map), `eval_time`, `rank_metric`, `select_best`, `std_errs` and the shared order with `id` (set plot), `summarize` (run's inner metrics), and `type` and `summarize` (set's inner metrics); each has a row. The page has 3 `added` rows, 0 `proposed`, and defines `added` in its Scope paragraph. The default comparison over the `pairs` table printed 8 differing defaults, which the page's 7 rows cover (one row holds both `objective` methods), all `kept`.

Consistency gate: `cairn_validate.py` passed every check. `devtools::document()` gave no diff. `pkgdown::check_pkgdown()` found no problems. All six gating prose sweeps clean. NEWS has the entry. No new top-level file. README not touched. No principle changed, so `cairn_impact` was skipped.

spawned: diff-bug, blame-history, prior-review

- diff-bug #1: the `id` path gives no partial-run warning where the whole-set plot warns — fix now, fixed 581fc633: the single-run plot states the shortfall in its subtitle, so `@param id` now says so, and a test asserts no warning and the subtitle.
- diff-bug #2: errors on the `id` path do not name the workflow — fix now, fixed 581fc633: the call goes through `for_workflow()`, so they gain `Workflow "<id>": ` and the user's call; a test asserts both.
- diff-bug #3: the naming hint shows when `verbose` was given by name — fix now, fixed 581fc633: the hint shows only when the call did not name `verbose`; a test asserts its absence.
- diff-bug #4: the dots refusal and its comment still say everything after `fn` is matched by name — fix now, fixed 581fc633: both now say after `fn` and `verbose`.
- diff-bug #5: `verbose` is evaluated outside the RNG guard `capture_dots()` gives `...` — reject, not a defect: it is a flag, `fn` has the same exposure, and the guard covers the orchestrators' arguments.
- diff-bug #6: on a 0-row inner table the wide shape has no metric columns — reject, not a defect: there is no metric to pivot, as `collect_metrics(type = "wide")` on the same table.
- diff-bug #7: the set page's `type` text does not fit `collect_inner_metrics()` — fix now, fixed 581fc633: it now says a missing column is `NA` and a workflow with no inner candidates has no rows.
- diff-bug #8: the run page's `type` text says one row per candidate and metric — fix now, fixed 581fc633: one row per fold, candidate and metric, and a metric a fold did not score is `NA`. `.weight` is left unnamed: the inner tables carry none.
- diff-bug #9: the review page says workflowsets puts `id` third — fix now, fixed 581fc633: fourth, third of the shared arguments.
- diff-bug #10: the AC3 test compares only built data and passes no `eval_time` — fix now, fixed 581fc633: it compares the labels too, and asserts that `eval_time` reaches the single view's refusal.
- diff-bug #11: the Bayes test hard-codes two metrics — fix now, fixed 581fc633: it counts the metrics.
- diff-bug #12: the collision test's run half sits under the workflow-set skip — fix now, fixed 581fc633: the run and the set are two blocks with their own skips.
- blame-history #1: a positional third argument changes refusal class with no NEWS word — fix now, fixed 581fc633: the NEWS entry says so.
- blame-history #2: no record of the positional `verbose` beside M71's name-matching rule — fix now, fixed 581fc633: a milestone-local decision records it; the plan gate line holds the alternative.
- blame-history #3: stale rule text — fix now, as diff-bug #4.
- blame-history #4: the `verbose` check runs before the dots check, so a positional design hides a dots typo — reject, not a defect: either order reports one mistake first, and this order names the one that caused the first failure.
- blame-history #5: the `id` path's errors name the single-run call — fix now, as diff-bug #2.
- prior-review #1: the new oracle file has no CRAN guard (M118) — fix now, fixed 581fc633: `skip_heavy_on_cran()` at the top; the verbose file already skips on CRAN through `skip_if_no_wset_fixture()`.
- prior-review #2: a 0-row table loses its metric columns in the wide shape (M049) — reject, as diff-bug #6.
- prior-review #3: the run page's `type` text does not say a missing cell is `NA` (M065 F4) — fix now, as diff-bug #8.
- prior-review #4: a `...` name that is a prefix of `verbose` is partly matched — reject, not a defect: no orchestrator argument starts with `v`, so such a name is refused either way.
- prior-review #5: the verbose test uses the grid tuner alone (M120) — reject, not a defect: the log does not read the tuner, and both route words are drawn.
- prior-review #6: the `id` test reads only built data (the M08 lesson) — fix now, as diff-bug #10.
- prior-review #7: a 90-column test comment — reject, style; it is rewrapped with diff-bug #11's edit.

After the fixes, the six touched test files passed fresh (verbose 3, map checks 200, wide 19, plot 294, map readers 451, dots barrier 96; 0 failed, 0 skipped), `air format --check .` and all six sweeps were clean.

- AC5 evidence: `man/nested_workflow_map.Rd` gives `verbose` text naming `nested_workflow_map()`; `man/collect_selections.Rd` and `man/collect_metrics.nested_results_set.Rd` give `type` text naming `collect_inner_metrics()`; `man/summary.nested_results_set.Rd` gives `id` text naming `autoplot()`. `NEWS.md` opens with one entry naming `verbose`, `type = "wide"` and `id`. `devtools::check()` at `581fc633` in the main checkout gave 0 errors, 0 warnings, 0 notes, with the full test suite run inside it.
