# Package index

## Nested resampling

Build the design the outer loop runs on: one outer fold per row, with
that fold’s inner resamples beside it, and no copy of the data per fold.

- [`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md)
  : Build a nested resampling design without copying the data per outer
  fold

## Running the loop

Tune on each outer fold’s inner resamples, select a candidate, then fit
and score it on the outer split, keeping what every fold chose. A
workflow with nothing to tune and a whole workflow set run on the same
design.

- [`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
  : Nested cross-validation with a grid search inside
- [`nested_tune_bayes()`](https://nestedtune.tidymodels.org/reference/nested_tune_bayes.md)
  : Nested cross-validation with Bayesian optimization inside
- [`nested_tune_race_anova()`](https://nestedtune.tidymodels.org/reference/nested_tune_race.md)
  [`nested_tune_race_win_loss()`](https://nestedtune.tidymodels.org/reference/nested_tune_race.md)
  : Nested cross-validation with racing inside
- [`nested_tune_sim_anneal()`](https://nestedtune.tidymodels.org/reference/nested_tune_sim_anneal.md)
  : Nested cross-validation with simulated annealing inside
- [`nested_fit_resamples()`](https://nestedtune.tidymodels.org/reference/nested_fit_resamples.md)
  : Score a workflow with nothing to tune on a nested design
- [`nested_workflow_map()`](https://nestedtune.tidymodels.org/reference/nested_workflow_map.md)
  : Run every workflow of a workflow set through one nested design
- [`collect_metrics(`*`<nested_results>`*`)`](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results.md)
  : Collect the metrics from a nested resampling run
- [`collect_selections()`](https://nestedtune.tidymodels.org/reference/collect_selections.md)
  [`collect_inner_metrics()`](https://nestedtune.tidymodels.org/reference/collect_selections.md)
  [`collect_notes(`*`<nested_results>`*`)`](https://nestedtune.tidymodels.org/reference/collect_selections.md)
  : Stack a per-fold column of a nested resampling run across the outer
  folds
- [`collect_predictions(`*`<nested_results>`*`)`](https://nestedtune.tidymodels.org/reference/collect_predictions.nested_results.md)
  [`collect_extracts(`*`<nested_results>`*`)`](https://nestedtune.tidymodels.org/reference/collect_predictions.nested_results.md)
  : Stack the outer fit's predictions or extracts across the outer folds
- [`print(`*`<nested_results>`*`)`](https://nestedtune.tidymodels.org/reference/print.nested_results.md)
  : Print a nested cross-validation result
- [`summary(`*`<nested_results>`*`)`](https://nestedtune.tidymodels.org/reference/summary.nested_results.md)
  [`print(`*`<summary.nested_results>`*`)`](https://nestedtune.tidymodels.org/reference/summary.nested_results.md)
  : Summarize a nested cross-validation result
- [`autoplot(`*`<nested_results>`*`)`](https://nestedtune.tidymodels.org/reference/autoplot.nested_results.md)
  : Plot a nested cross-validation result
- [`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md)
  : Tabulate how often each parameter setting was selected across the
  outer folds
- [`extract_procedure()`](https://nestedtune.tidymodels.org/reference/extract_procedure.md)
  : Extract the record of what ran
- [`selection_rule()`](https://nestedtune.tidymodels.org/reference/selection_rule.md)
  : Choose the rule each fold selects its parameters by
- [`collect_metrics(`*`<nested_results_set>`*`)`](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results_set.md)
  [`collect_selections(`*`<nested_results_set>`*`)`](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results_set.md)
  [`collect_inner_metrics(`*`<nested_results_set>`*`)`](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results_set.md)
  [`collect_notes(`*`<nested_results_set>`*`)`](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results_set.md)
  [`collect_predictions(`*`<nested_results_set>`*`)`](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results_set.md)
  [`collect_extracts(`*`<nested_results_set>`*`)`](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results_set.md)
  : Stack each workflow's table of a workflow-set run under its id
- [`print(`*`<nested_results_set>`*`)`](https://nestedtune.tidymodels.org/reference/print.nested_results_set.md)
  : Print a workflow-set run
- [`extract_workflow(`*`<nested_results_set>`*`)`](https://nestedtune.tidymodels.org/reference/extract_workflow.nested_results_set.md)
  : Extract one workflow of a workflow-set run
- [`agreement(`*`<nested_results_set>`*`)`](https://nestedtune.tidymodels.org/reference/summary.nested_results_set.md)
  [`autoplot(`*`<nested_results_set>`*`)`](https://nestedtune.tidymodels.org/reference/summary.nested_results_set.md)
  [`summary(`*`<nested_results_set>`*`)`](https://nestedtune.tidymodels.org/reference/summary.nested_results_set.md)
  [`print(`*`<summary.nested_results_set>`*`)`](https://nestedtune.tidymodels.org/reference/summary.nested_results_set.md)
  : Summarize, plot and tabulate a workflow-set run

## The final model

Run the recorded tuning procedure once more with the whole dataset in
hand and get back the model to deploy. It is its own object, never a
field on the results.

- [`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
  : Fit the final model after nested cross-validation
- [`print(`*`<nested_final_fit>`*`)`](https://nestedtune.tidymodels.org/reference/print.nested_final_fit.md)
  : Print a final fit
- [`summary(`*`<nested_final_fit>`*`)`](https://nestedtune.tidymodels.org/reference/summary.nested_final_fit.md)
  [`print(`*`<summary.nested_final_fit>`*`)`](https://nestedtune.tidymodels.org/reference/summary.nested_final_fit.md)
  : Summarize a final fit
- [`predict(`*`<nested_final_fit>`*`)`](https://nestedtune.tidymodels.org/reference/predict.nested_final_fit.md)
  [`augment(`*`<nested_final_fit>`*`)`](https://nestedtune.tidymodels.org/reference/predict.nested_final_fit.md)
  : Predict with the final model
- [`extract_tune_results()`](https://nestedtune.tidymodels.org/reference/extract_tune_results.md)
  : Extract the tuning run a final fit was selected from
- [`extract_scored_candidates()`](https://nestedtune.tidymodels.org/reference/extract_scored_candidates.md)
  : Extract the parameter settings a final fit actually scored

## Re-exports

- [`reexports`](https://nestedtune.tidymodels.org/reference/reexports.md)
  [`collect_metrics`](https://nestedtune.tidymodels.org/reference/reexports.md)
  [`extract_workflow`](https://nestedtune.tidymodels.org/reference/reexports.md)
  [`autoplot`](https://nestedtune.tidymodels.org/reference/reexports.md)
  [`augment`](https://nestedtune.tidymodels.org/reference/reexports.md)
  [`collect_notes`](https://nestedtune.tidymodels.org/reference/reexports.md)
  [`collect_predictions`](https://nestedtune.tidymodels.org/reference/reexports.md)
  [`collect_extracts`](https://nestedtune.tidymodels.org/reference/reexports.md)
  : Objects exported from other packages
