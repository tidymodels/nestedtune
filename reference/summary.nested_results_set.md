# Summarize, plot and tabulate a workflow-set run

The three readers of one workflow's run answer on a
`nested_results_set`, what
[`nested_workflow_map()`](https://nestedtune.tidymodels.org/reference/nested_workflow_map.md)
returns, each workflow's view keyed by its `wflow_id`.
[`summary()`](https://rdrr.io/r/base/summary.html) summarizes every
workflow;
[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
draws the two views of
[`autoplot.nested_results()`](https://nestedtune.tidymodels.org/reference/autoplot.nested_results.md)
across the workflows; and
[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md)
stacks each workflow's selection table under its id.

## Usage

``` r
# S3 method for class 'nested_results_set'
agreement(x, ...)

# S3 method for class 'nested_results_set'
autoplot(object, type = c("parameters", "performance"), ...)

# S3 method for class 'nested_results_set'
summary(object, ...)

# S3 method for class 'summary.nested_results_set'
print(x, ...)
```

## Arguments

- x, object:

  A `nested_results_set` from
  [`nested_workflow_map()`](https://nestedtune.tidymodels.org/reference/nested_workflow_map.md);
  for the print method, the `summary.nested_results_set` that
  [`summary()`](https://rdrr.io/r/base/summary.html) returns.

- ...:

  Not used; must be empty. An argument passed here is an error rather
  than silently ignored.

- type:

  Which view to draw: `"parameters"` (the default) or `"performance"`,
  as on
  [`autoplot.nested_results()`](https://nestedtune.tidymodels.org/reference/autoplot.nested_results.md).

## Value

[`summary()`](https://rdrr.io/r/base/summary.html) returns a
`summary.nested_results_set`: a list of one
[`summary.nested_results()`](https://nestedtune.tidymodels.org/reference/summary.nested_results.md)
object per workflow, named by `wflow_id` in the set's order, each the
summary of that workflow's run called alone, with the orchestrator's
name as the list's `fn` attribute. Its print shows the orchestrator and
the workflow count, then one section per workflow holding that run's
design, failed folds, selected parameters and estimate, and the note on
what a nested estimate describes once at the end.

[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
returns a `ggplot` object. Under `type = "performance"` the workflows
stand along the x axis inside one panel per metric, one point per
completed outer fold's score and a dashed rule at each workflow's nested
estimate, the value
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
reports for it on the set; the panels are named as the single view names
them. Under `type = "parameters"` there is one panel per workflow and
tuned parameter, in the set's order, labelled by the id and then the
single view's label for that parameter, with the outer folds along the x
axis, so each panel asks the single view's question of one workflow. The
selected-value axis is decided over every workflow's values at once:
numeric when all are numbers, discrete otherwise. A workflow with
nothing to tune contributes no panel.

[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md)
returns a tibble: `wflow_id`, then one column per parameter any
workflow's completed fold selected, then `n` and `prop`, with each
workflow's rows as
[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md)
on that run alone gives them, in the set's order, `NA` in a column that
workflow's run does not tune; inside a workflow's own rows `NA` keeps
the meaning
[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md)
gives it there, a fold that recorded no value for the parameter. A
workflow with nothing to tune contributes no row.

## Details

The three readers follow the fold-state rules of the set's
[collect_metrics()](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results_set.md).
A workflow in which some outer folds failed is read over the folds that
ran, with one warning of class `nestedtune_partial_summary` naming it. A
workflow in which no fold completed is still summarized by
[`summary()`](https://rdrr.io/r/base/summary.html), which describes a
failed run rather than refusing; the performance view keeps its slot on
the x axis and draws nothing for it, the parameters view draws no panel
for it, and
[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md)
leaves it out, each warning once naming it. A set in which no workflow
completed a fold is refused by the plots and by
[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md)
with class `nestedtune_no_completed_folds`. A set in which no workflow's
completed fold recorded a selected parameter is refused under
`type = "parameters"` with class `nestedtune_no_tuned_parameters`.

The performance view's subtitle names the workflow and fold counts and
then, each on a line of its own and only when there is one to name, how
many workflows did not complete every fold and how many rest a metric's
average on fewer folds than they completed;
[`summary()`](https://rdrr.io/r/base/summary.html) names the folds and
prints each workflow's count per metric. The two counts are separate: a
workflow that ran whole can still be named by the second, since a
completed fold can score `NA` on one metric while scoring the others,
and a metric no completed fold scored is counted there while drawing no
rule. A tuned parameter whose id is `wflow_id` cannot be tabulated
beside the set's own column and is refused with class
`nestedtune_collect_name_collision`; one whose id is `n` or `prop` is
refused as
[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md)
refuses it, the workflow named in front.

## See also

[`collect_metrics.nested_results_set()`](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results_set.md),
[`summary.nested_results()`](https://nestedtune.tidymodels.org/reference/summary.nested_results.md),
[`autoplot.nested_results()`](https://nestedtune.tidymodels.org/reference/autoplot.nested_results.md),
[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md),
[`nested_workflow_map()`](https://nestedtune.tidymodels.org/reference/nested_workflow_map.md)

## Examples

``` r
data(mtcars)

rec <- recipes::recipe(mpg ~ ., data = mtcars)
tuned <- recipes::step_pca(rec, recipes::all_predictors(), num_comp = tune::tune())
wset <- workflowsets::workflow_set(
  preproc = list(pca = tuned, none = rec),
  models = list(lm = parsnip::linear_reg())
)

set.seed(1)
folds <- nested_resamples(
  mtcars,
  outside = rsample::vfold_cv(v = 2),
  inside = rsample::vfold_cv(v = 2)
)

set.seed(2)
res <- nested_workflow_map(wset, resamples = folds, grid = data.frame(num_comp = 1:2))

summary(res)
#> 
#> ── Nested cross-validation results for a workflow set ─────────────────
#> Orchestrator: `nested_tune_grid()` (grid search)
#> Workflows: 2
#> 
#> ── Workflow "pca_lm" ──
#> 
#> Outer resamples: 2-fold cross-validation
#> Outer folds: 2 requested, 2 completed
#> 
#> ── Selected parameters 
#> ✔ num_comp: 1 (all 2 completed folds agree)
#> 
#> ── Estimate (2 of 2 outer folds) 
#> rmse (standard): 2.98
#> rsq (standard): 0.747
#> 
#> ── Workflow "none_lm" ──
#> 
#> Outer resamples: 2-fold cross-validation
#> Outer folds: 2 requested, 2 completed
#> 
#> ── Selected parameters 
#> ℹ No tuned parameters.
#> 
#> ── Estimate (2 of 2 outer folds) 
#> rmse (standard): 5.93
#> rsq (standard): 0.495
#> 
#> ℹ A nested estimate describes the tune-and-fit procedure, not a model
#>   you can deploy. Build that with `nested_final_fit()`, and report
#>   this estimate as what its procedure achieves.
agreement(res)
#> # A tibble: 1 × 4
#>   wflow_id num_comp     n  prop
#>   <chr>       <int> <int> <dbl>
#> 1 pca_lm          1     2     1
autoplot(res)

autoplot(res, type = "performance")
```
