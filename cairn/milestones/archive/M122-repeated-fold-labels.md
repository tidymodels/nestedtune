# M122: Repeated-design fold labels in per-fold metrics

**Status:** done (2026-09-28, PR #137 https://github.com/tidymodels/nestedtune/pull/137)

**Goal:** Every per-fold metrics table labels a repeated design's folds with the design's own label columns.

**Outcome:** `per_fold_metrics()` in `R/nested-results.R` writes each column that `id_columns()` recorded, so a repeated design gives `id` and `id2`. It no longer writes one `id` pasted by `fold_ids()` (M106 review F3). If the record cannot label the rows, it keeps one `id` of row positions from `fold_ids()`. New helpers `usable_label_columns()`, `per_fold_label_columns()` and `paste_labels()` sit beside `fold_ids()`. `collect_metrics(summarize = FALSE)` long and wide and `compute_metrics(summarize = FALSE)` follow, on `nested_results` and `nested_results_set`, with `wflow_id` first on a set. `plot_performance()` pastes the labels for its fold axis. `plot_set_performance()` reads no fold label and did not change. Three help pages and `NEWS.md` state the change and say that a join on a repeated design uses both columns. `tests/testthat/test-fold-labels.R` holds 7 tests with 75 expectations, and the expected labels come from the design's rows.

**Decisions:** none. The plan chose separate label columns over a documented pasted `id`, under D-036.

**Review:** Three fresh reviewers found no bug. The prior-review lens found that the diff resolves M106's F3. The diff reviewer ranked R1-R8, and the history reviewer added R9, a roxygen line break. Fixed at the gate: tests for the fallback labels (R1) and for a fold with no metrics rows (R3). A planted defect turned each of the two tests red. The weighted path from R3 has no test. R2 (pre-existing fallback join mismatch), R4, R5, R6 and R9 were rejected with reasons, and R7 and R8 were noted. `devtools::check()` gave 0 errors, 0 warnings and 0 notes. CI `format-suggest` flagged line layout in the new test file. `air format` fixed it, and a timed-out CI wait resumed and merged on green.
