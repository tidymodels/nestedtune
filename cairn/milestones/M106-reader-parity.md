# M106: tune's reader arguments and extract methods on the nested classes

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP3, GP3
- **Resolves:** —
- **Surface tier:** user-facing — new methods and arguments on exported generics
- **Branch/PR:** m106-reader-parity

## Goal

A tidymodels user reaches the fitted parts of a final fit, the wide metrics table and a filtered performance plot with the calls tune taught them.

## Scope

**In:** seven `nested_final_fit` methods on generics tune and hardhat export (`extract_fit_parsnip()`, `extract_fit_engine()`, `extract_recipe()`, `extract_mold()`, `extract_preprocessor()`, `extract_spec_parsnip()`, `outcome_names()`). A `type` argument on `collect_metrics()` for both result classes. `metric` and `eval_time` arguments on `autoplot()` for both result classes. A `predict()` method on both result classes that refuses and names `nested_final_fit()`.

**Out:** `extract_parameter_set_dials()` and `extract_workflow_set_result()`, which go to a candidate row added with this plan. Search-trajectory and race plots stay on their existing candidate row. The `"marginals"` plot type is left out: a nested run has no one grid to draw marginals over, because each fold searches its own (M21's candidate row).

## Acceptance criteria

- [x] AC1: Each of the seven generics named in Scope has a `nested_final_fit` method. For each one, a test asserts that the result is `identical()` to the same call on `extract_workflow(fit)`, on a recipe-based fixture.
- [x] AC2: `collect_metrics()` on a `nested_results` and on a `nested_results_set` takes `type = c("long", "wide")`. A test asserts that `type = "long"` is `identical()` to the call without `type`. A second test asserts that `type = "wide"` equals a reference pivot the test writes with `stats::reshape()`. The pivot puts metric names in columns and `mean` or `.estimate` in the values. Its keys are the fold label columns for unsummarized output, `.eval_time` where the run has it, and `wflow_id` on a set. It drops `.estimator`, `n` and `std_err`. The test covers `summarize = TRUE` and `FALSE`, on a classification fixture and on the survival fixture. An unknown `type` raises an error the test names by class.
- [x] AC3: `autoplot()` on a `nested_results` and on a `nested_results_set` takes `metric` and `eval_time`, each `NULL` by default, meaning all. With `type = "performance"`, a test reads `ggplot2::ggplot_build()`. It asserts that the panels drawn are exactly those whose metric is in the named set, and whose time is too on the survival fixture. One filtered plot gets a `vdiffr` snapshot. Three inputs each raise an error the test names by class: a metric absent from every workflow of the run, a time absent from the run, and either argument given with `type = "parameters"`.
- [x] AC4: `predict()` on a `nested_results` or a `nested_results_set` raises an error that the test names by class, and whose message names `nested_final_fit()`.
- [ ] AC5: `NEWS.md` describes the new methods and arguments, and each help page documents them. `devtools::check()` gives 0 errors, 0 warnings, and no note absent from the check of `main` at the branch point.

## Coverage

- AC1 → T1
- AC2 → T2, T8
- AC3 → T3, T7
- AC4 → T4, T9
- AC5 → T5, T6

## Tasks

- [x] T1: Add the seven `nested_final_fit` methods beside `extract_workflow.nested_final_fit()` (`R/nested-final-fit.R:481`), each delegating to the stored workflow. Register `outcome_names` from tune. Test each against `extract_workflow(fit)`.
- [x] T2: Add `type` to `collect_metrics.nested_results()` (`R/nested-results.R:840`) and `collect_metrics.nested_results_set()` (`R/nested-results-set.R:82`). Pivot with dplyr and vctrs, since tidyr is not a dependency. Test against the `stats::reshape()` reference.
- [x] T3: Add `metric` and `eval_time` to both `autoplot()` methods (`R/nested-results-plot.R:77`). Filter the rows before `plot_performance()` builds its panels, because the panel labels carry qualifiers (`metric_panel()`, `qualify_panels()`). Render the filtered plot before approving its snapshot (LESSONS, plots).
- [x] T4: Add `predict.nested_results()` and `predict.nested_results_set()`, each refusing with a class and naming `nested_final_fit()`. For a set, the message names its `id` argument.
- [x] T5: Write the help and `NEWS.md` text, then run `devtools::document()`, the prose sweeps from the verify slot, and `devtools::check()`.
- [ ] T6: Add `extract-nested_final_fit` and `predict.nested_results` to the `_pkgdown.yml` reference index, and write a D-entry for the seven re-exported generics and the predict refusal (review F16).
- [ ] T7: Read the scored times before the `metric` filter in `filter_plot_rows()` (F1). Test a set in which one workflow lacks a metric through the filter directly (F7).
- [ ] T8: Refuse a wide pivot in which two rows share a key and a metric, or a metric is named like a key column, with one class (F2, F4). Document the refusal and fix the `type` help's pointer (F14). Add an oracle provenance header and a weighted-run wide test (F6).
- [ ] T9: Move the misplaced comment in `R/checks.R` (F9), tighten the predict set test's `id` match (F10), re-wrap lines over 80 columns (F15), and mention the extractors in the final-fit object comment (history note).

## Work log

- 2026-09-21: created by /milestone-plan.
- 2026-09-21: criteria audit ran in full mode and returned five findings, all fixed in the wording above. They were a snapshot baseline, loose pivot keys, qualified panel names, no check-notes baseline, and tidyr absent from Suggests.
- 2026-09-21: plan gate chose a dplyr pivot over adding tidyr, because a dependency needs its own decision; falsified by the pivot diverging from tune's `pivot_metrics()` on a shape tune supports.
- 2026-09-21: T1 done. The seven methods refuse stray arguments, because workflows' extractors other than `extract_recipe()` drop unknown ones silently (the `augment.nested_final_fit()` precedent). `extract_recipe()` takes `estimated` by name, and the generics are re-exported beside `extract_workflow()`. The full suite ran once, failing only on the dots probe's seven new methods before the fence, and both touched files pass after it.
- 2026-09-21: T2 done. The wide pivot keys on every column that is not a metric or summary field, and a bad `type` raises `nestedtune_bad_type`. The `reshape()` reference first merged rows keyed on a static metric's NA time, so it now keys on a string. That mismatch showed the reference can fail. The full suite failed only on the formals test and one help sentence the prose sweep flagged. Both files pass after the fix.
- 2026-09-21: T3 done, and the full suite is clean. `eval_time` keeps a static metric's untimed panel, as tune's `autoplot()` does. The survival fixture scores `brier_survival` at two times beside `concordance_survival`, so the tests cover that case. A metric or time absent from the run, a malformed value, or either argument with the parameters view raises `nestedtune_bad_plot_filter`. The new snapshot was rendered and read before approval.
- 2026-09-21: T4 done. Both refusals raise `nestedtune_predict_results` and are exempt from the dots probe, because a caller's `new_data` arrives through `...`. The full suite failed only on the Bayesian oracle file's table of every method on the class. That table now runs the refusal, and the file passes.
- 2026-09-21: claim audit: 47 claims read, 4 corrected — NEWS.md, R/nested-final-fit.R, R/nested-results.R, tests/testthat/test-collect-metrics-wide.R, tests/testthat/test-nested-final-fit-extract.R
- 2026-09-21: T5 done. `devtools::check()` gave 0 errors, 0 warnings and 0 notes on the branch point `d477922` and on the branch at `25170cf`, both run the same day. Status set to review.
- 2026-09-21: review pass 1 returned the milestone: the consistency gate's `pkgdown::check_pkgdown()` failed, with `extract-nested_final_fit` and `predict.nested_results` missing from the `_pkgdown.yml` reference index. Defect return 1.
- 2026-09-21: pass-1 triage accepted at the gate. Tasks T6-T9 added for the pkgdown index and the fix-now findings, and Coverage extended to them. F3 becomes a candidate row, and F5, F8, F11, F12 and F13 are rejected.

## Decisions

## Review

Pass 1, 2026-09-21, at `c8822f6`. The full suite ran with `NOT_CRAN=true`, so snapshots were active. It gave 0 failures and 0 skips in the six files below.

- AC1: `test-nested-final-fit-extract.R` passed. It asserts `identical()` for each of the seven generics against `extract_workflow(final)` on the recipe fixture, plus `estimated = FALSE`.
- AC2: `test-collect-metrics-wide.R` passed. The long type is identical to the call without a type, and the wide type equals the `stats::reshape()` reference for both `summarize` values. The fixtures are the classification run, the survival run with `.eval_time`, and the survival set with `wflow_id`. The refusal is `nestedtune_bad_type`.
- AC3: `test-autoplot-filter.R` passed. The panels drawn equal the unfiltered plot's panels for the named metrics and times on both classes, and the `vdiffr` snapshot matched. Each refusal is `nestedtune_bad_plot_filter`.
- AC4: `test-predict-results.R` passed. Both classes raise `nestedtune_predict_results` with `nested_final_fit()` in the message.
- AC5: not ticked in this pass. The check evidence dates from implement, and the return below changes the tree.

Consistency gate: `cairn_validate` passed, `devtools::document()` gave no diff, and all six gating prose sweeps were clean. `pkgdown::check_pkgdown()` FAILED, with 2 topics missing from the `_pkgdown.yml` index: `extract-nested_final_fit` and `predict.nested_results`.

Independent review, three lenses:
- Blame-history: no finding contradicts a decision. One note: the object comment in `R/nested-final-fit.R` does not mention that extractors now exist beside the absent ranking and collecting generics.
- Prior-review record: no finding. No past review point is reintroduced.
- Diff-bug: 16 ranked findings. F1: the `eval_time` refusal reads times after the `metric` filter, so it falsely says a time was not scored (`R/nested-results-plot.R:390`). F2: the wide pivot silently overwrites when two rows share a key and a metric, for example one metric under two estimators (`R/nested-results.R:894`). F3: a repeated design's wide table keys on the pasted `id` from the long shape, not `id` and `id2`. F4: a metric named like a key column overwrites that key. F5: an `NA` in `.metric` gives a base R error. F6: the wide reference copies the drop list, the file has no oracle provenance header, and the `.weight` drop is not exercised. F7: the set filter's case where one workflow lacks a metric is untested. F8: a set warns about failed folds before refusing a bad `metric`. F9: a comment now sits above `check_metrics_type()` instead of `check_plot_type()`. F10: the predict set test matches `"id"` as a bare substring. F11: `eval_time` matches exactly, as tune does. F12: `extract_recipe()` on a formula fit gives workflows' own message. F13: the generics are imported through tune, as `extract_workflow` is. F14: the `type` help's pointer to the shapes section, and no mention of estimator collisions. F15: `NEWS.md:14` and one roxygen line run past 80 columns. F16: no D-entry records the seven re-exports and the predict refusal, where D-052 and D-063 recorded such re-exports.

Pass-1 triage, accepted at the gate on 2026-09-21:
- Fix now (T6-T9): the pkgdown index failure, F1, F2, F4, F6, F7, F9, F10, F14, F15, F16, and the blame-history note on the object comment.
- Follow-up: F3, as a candidate row added with this triage.
- Rejected: F5, because `per_fold_metrics()` never writes an `NA` metric. F8, because the failed-fold warnings are true before the refusal. F11, because exact matching is what tune's `autoplot()` does. F12, because workflows' message names the missing recipe accurately. F13, because it matches the `extract_workflow` re-export, and the objects are identical.
