# M122: Repeated-design fold labels in per-fold metrics

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1
- **Resolves:** —
- **Surface tier:** user-facing — it changes the columns of existing per-fold tables
- **Branch/PR:** —

## Goal

Every per-fold metrics table labels a repeated design's folds with the design's own label columns.

## Scope

**In:** `per_fold_metrics()` writes each column that `id_columns()` recorded. It stops writing one `id` pasted by `fold_ids()` (M106 review F3, D-036). The readers built on it follow: `collect_metrics()` long and wide, and `compute_metrics()`, on both result classes. The performance plots keep their pasted fold axis. The help and `NEWS.md` state the change.

**Out:** the final fit's parameter set → M123. `extract_workflow_set_result()` and the other extractors → the rewritten M106 candidate row. Designs with three or more label columns are not claimed, because rsample records one or two.

## Acceptance criteria

- [ ] AC1: The claimed domain is rsample outer designs, which record one or two label columns. The test designs are `rsample::vfold_cv(v = 2, repeats = 2)` and a single-column design. On a `nested_results`, three unsummarized tables carry each recorded label column as its own column. The tables are those of `collect_metrics()` (long and wide) and `compute_metrics()`. No column holds the labels pasted together. Each row's labels equal those of its outer fold. A test builds the expected labels from the design object's rows, not from the result. The summarized tables have the same column names on both designs.
- [ ] AC2: The run is a `nested_results_set` from `nested_workflow_map()` over the repeated design. On it, `collect_metrics(summarize = FALSE)` (long and wide) and `compute_metrics(summarize = FALSE)` carry `wflow_id`, `id` and `id2` as separate columns. A test asserts this as AC1 asserts.
- [ ] AC3: On the repeated design, `autoplot(type = "performance")` on a `nested_results` draws one point for each non-missing per-fold estimate. Its fold axis levels are `paste(id, id2, sep = ", ")` of the outer design, in design order. A test asserts the built plot's levels and point count. A test also builds the set's performance plot and prints the `nested_results`, both without error.
- [ ] AC4: Three help pages say that the unsummarized table carries the design's label columns: `id`, and `id2` on a repeated design. The pages are `collect_metrics.nested_results`, `collect_metrics.nested_results_set` and `compute_metrics.nested_results`. A `NEWS.md` bullet says that the pasted `id` is gone. It says that a join on a repeated design uses both columns.
- [ ] AC5: `devtools::check()` reports 0 errors, 0 warnings and 0 notes.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T2, T3
- AC4 → T4
- AC5 → T5

## Tasks

- [ ] T1: Write the AC1 and AC2 tests first, in a new `tests/testthat/test-fold-labels.R`. Give it a file-level `skip_heavy_on_cran()`. Build the expected labels from the rsample design rows. The set test takes the workflow-set skip and the engine skip (LESSONS M101). Run the tests before T2 and record that they fail on the pasted `id`.
- [ ] T2: Change `per_fold_metrics()` (`R/nested-results.R:1126`) to write each recorded label column. If the record cannot label the rows, keep one `id` from `fold_ids()`. Make `plot_performance()` (`R/nested-results-plot.R:272`) and `plot_set_performance()` (`R/nested-results-plot.R:627`) paste the labels for the fold axis. Update the test that pins the pasted `id` (`tests/testthat/test-compute-metrics.R:220`). Read the join at `vignettes/tuners.Rmd:340` and every other `by = "id"` join that `grep` finds under `vignettes/`.
- [ ] T3: Write the AC3 tests. They cover the built plot's fold levels and point count on the repeated design, the set plot build, and the print.
- [ ] T4: Update the three help pages and add the `NEWS.md` bullet. Run `Rscript benchmarks/sweep-prose.R --plain` and `--roxygen --plain`.
- [ ] T5: Run `devtools::document()` and `devtools::check()`.

## Work log

- 2026-09-28: created by /milestone-plan from the "What M106 left" candidate row, split from M123 at the plan gate.
- 2026-09-28: criteria audit (full mode, fresh [O] reader) read the combined draft and returned 14 findings, each with one fix, all applied before the gate. For this milestone it removed the wide shape from `compute_metrics()`, which has no `type` argument. It fixed the test design and added the set's `compute_metrics()`. It added the set plot, the print, and the join note in `NEWS.md`. The split then moved the criteria between files without a change of wording.
- 2026-09-28: plan chose separate label columns over keeping the pasted `id` and documenting it, because D-036 has every reader take the labels from the record and tune's tables carry `id` and `id2`; falsified by a reader that needs one key column per fold.

## Decisions

## Review
