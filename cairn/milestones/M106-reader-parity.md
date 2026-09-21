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

- [ ] AC1: Each of the seven generics named in Scope has a `nested_final_fit` method. For each one, a test asserts that the result is `identical()` to the same call on `extract_workflow(fit)`, on a recipe-based fixture.
- [ ] AC2: `collect_metrics()` on a `nested_results` and on a `nested_results_set` takes `type = c("long", "wide")`. A test asserts that `type = "long"` is `identical()` to the call without `type`. A second test asserts that `type = "wide"` equals a reference pivot the test writes with `stats::reshape()`. The pivot puts metric names in columns and `mean` or `.estimate` in the values. Its keys are the fold label columns for unsummarized output, `.eval_time` where the run has it, and `wflow_id` on a set. It drops `.estimator`, `n` and `std_err`. The test covers `summarize = TRUE` and `FALSE`, on a classification fixture and on the survival fixture. An unknown `type` raises an error the test names by class.
- [ ] AC3: `autoplot()` on a `nested_results` and on a `nested_results_set` takes `metric` and `eval_time`, each `NULL` by default, meaning all. With `type = "performance"`, a test reads `ggplot2::ggplot_build()`. It asserts that the panels drawn are exactly those whose metric is in the named set, and whose time is too on the survival fixture. One filtered plot gets a `vdiffr` snapshot. Three inputs each raise an error the test names by class: a metric absent from every workflow of the run, a time absent from the run, and either argument given with `type = "parameters"`.
- [ ] AC4: `predict()` on a `nested_results` or a `nested_results_set` raises an error that the test names by class, and whose message names `nested_final_fit()`.
- [ ] AC5: `NEWS.md` describes the new methods and arguments, and each help page documents them. `devtools::check()` gives 0 errors, 0 warnings, and no note absent from the check of `main` at the branch point.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T4
- AC5 → T5

## Tasks

- [x] T1: Add the seven `nested_final_fit` methods beside `extract_workflow.nested_final_fit()` (`R/nested-final-fit.R:481`), each delegating to the stored workflow. Register `outcome_names` from tune. Test each against `extract_workflow(fit)`.
- [x] T2: Add `type` to `collect_metrics.nested_results()` (`R/nested-results.R:840`) and `collect_metrics.nested_results_set()` (`R/nested-results-set.R:82`). Pivot with dplyr and vctrs, since tidyr is not a dependency. Test against the `stats::reshape()` reference.
- [ ] T3: Add `metric` and `eval_time` to both `autoplot()` methods (`R/nested-results-plot.R:77`). Filter the rows before `plot_performance()` builds its panels, because the panel labels carry qualifiers (`metric_panel()`, `qualify_panels()`). Render the filtered plot before approving its snapshot (LESSONS, plots).
- [ ] T4: Add `predict.nested_results()` and `predict.nested_results_set()`, each refusing with a class and naming `nested_final_fit()`. For a set, the message names its `id` argument.
- [ ] T5: Write the help and `NEWS.md` text, then run `devtools::document()`, the prose sweeps from the verify slot, and `devtools::check()`.

## Work log

- 2026-09-21: created by /milestone-plan.
- 2026-09-21: criteria audit ran in full mode and returned five findings, all fixed in the wording above. They were a snapshot baseline, loose pivot keys, qualified panel names, no check-notes baseline, and tidyr absent from Suggests.
- 2026-09-21: plan gate chose a dplyr pivot over adding tidyr, because a dependency needs its own decision; falsified by the pivot diverging from tune's `pivot_metrics()` on a shape tune supports.
- 2026-09-21: T1 done. The seven methods refuse stray arguments, because workflows' extractors other than `extract_recipe()` drop unknown ones silently (the `augment.nested_final_fit()` precedent). `extract_recipe()` takes `estimated` by name, and the generics are re-exported beside `extract_workflow()`. The full suite ran once, failing only on the dots probe's seven new methods before the fence, and both touched files pass after it.
- 2026-09-21: T2 done. The wide pivot keys on every column that is not a metric or summary field, and a bad `type` raises `nestedtune_bad_type`. The `reshape()` reference first merged rows keyed on a static metric's NA time, so it now keys on a string, and that mismatch showed the reference can fail. The full suite failed only on the formals test naming the old signature and one help sentence the prose sweep flagged, and both files pass after the fix.

## Decisions

## Review
