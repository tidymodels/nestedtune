# Summarize, plot and tabulate a workflow-set run

The three ways of reading one workflow's run,
[`summary()`](https://rdrr.io/r/base/summary.html),
[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
and
[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md),
also answer on a `nested_results_set`, what
[`nested_workflow_map()`](https://nestedtune.tidymodels.org/reference/nested_workflow_map.md)
returns. Each is keyed by `wflow_id`.
[`summary()`](https://rdrr.io/r/base/summary.html) summarizes every
workflow,
[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
draws the two views of
[`autoplot.nested_results()`](https://nestedtune.tidymodels.org/reference/autoplot.nested_results.md)
across them, and
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
  [`nested_workflow_map()`](https://nestedtune.tidymodels.org/reference/nested_workflow_map.md).
  For the print method, the `summary.nested_results_set` that
  [`summary()`](https://rdrr.io/r/base/summary.html) returns.

- ...:

  Not used. It must be empty, so an argument given here is an error and
  not a silent no-op.

- type:

  Which view to draw: `"parameters"` (the default) or `"performance"`,
  as on
  [`autoplot.nested_results()`](https://nestedtune.tidymodels.org/reference/autoplot.nested_results.md).

## Value

[`summary()`](https://rdrr.io/r/base/summary.html) returns a
`summary.nested_results_set` and
[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html) a
`ggplot` object.
[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md)
returns a tibble. The three sections below say what each one holds.

## What [`summary()`](https://rdrr.io/r/base/summary.html) holds

A list of one
[`summary.nested_results()`](https://nestedtune.tidymodels.org/reference/summary.nested_results.md)
object per workflow, named by `wflow_id` in the set's order. Each is the
summary of that workflow's run called alone. The name of the loop
function the set ran through is the list's `fn` attribute.

Printing it shows that function's name and the workflow count, then one
section per workflow. Each section holds that run's design, failed
folds, selected parameters and estimate. The note on what a nested
estimate describes is printed once, at the end.

## What [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html) draws

Under `type = "performance"` the workflows stand along the x axis inside
one panel per metric. Each panel has one point per completed outer
fold's score and a dashed rule at each workflow's nested estimate, the
value
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
reports for it on the set.

Under `type = "parameters"` there is one panel per workflow and tuned
parameter, in the set's order, with the outer folds along the x axis.
Each panel is the one-workflow view,
[`autoplot.nested_results()`](https://nestedtune.tidymodels.org/reference/autoplot.nested_results.md)'s,
for that workflow and parameter. It is labelled by the id and then by
that view's label for the parameter, and asks that view's question of
one workflow. The selected-value axis is decided over every workflow's
values at once: numeric when all are numbers, discrete otherwise. A
workflow with nothing to tune draws no panel.

## What [`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md) returns

`wflow_id`, then one column per parameter any workflow's completed fold
selected, then `n` and `prop`. Each workflow's rows are as
[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md)
on that run alone gives them, in the set's order. A column a workflow
does not tune holds `NA` in its rows. Within a workflow's rows `NA`
keeps the meaning
[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md)
gives it, a fold that recorded no value. A workflow with nothing to tune
contributes no row.

A tuned parameter whose id is `wflow_id` cannot be tabulated beside the
set's own column and is refused with class
`nestedtune_collect_name_collision`. One whose id is `n` or `prop` is
refused as
[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md)
refuses it, the workflow named in front.

## Workflows that failed

The three follow the fold-state rules of the set's
[collect_metrics()](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results_set.md).
A workflow with some folds failed is read over the folds that ran,
warned about once with class `nestedtune_partial_summary`.

A workflow in which no fold completed is still summarized by
[`summary()`](https://rdrr.io/r/base/summary.html), which describes a
failed run rather than refusing. The performance view keeps its slot on
the x axis and draws nothing there, and the parameters view draws no
panel for it.
[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md)
leaves it out. Each warns once and names it. A set in which no workflow
completed a fold is refused by the plots and by
[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md)
with class `nestedtune_no_completed_folds`. One in which no completed
fold selected a parameter is refused under `type = "parameters"` with
class `nestedtune_no_tuned_parameters`.

## Counting what contributed

Two shortfall counts can appear under the subtitle, each on a line of
its own and only when there is one to name. One is how many workflows
did not complete every fold. The other is how many averaged a metric
over fewer folds than they completed. The subtitle itself gives the
workflow and fold counts.
[`summary()`](https://rdrr.io/r/base/summary.html) names the folds and
prints each workflow's count per metric.

The two counts are separate. A workflow that ran whole can still be
named by the second, because a completed fold can score `NA` on one
metric while scoring the others. A metric no completed fold scored is
counted there while drawing no rule.

## See also

[`collect_metrics.nested_results_set()`](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results_set.md),
[`summary.nested_results()`](https://nestedtune.tidymodels.org/reference/summary.nested_results.md),
[`autoplot.nested_results()`](https://nestedtune.tidymodels.org/reference/autoplot.nested_results.md),
[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md),
[`nested_workflow_map()`](https://nestedtune.tidymodels.org/reference/nested_workflow_map.md)

## Examples

``` r
data(mtcars)

rec <- recipes::recipe(mpg ~ ., data = mtcars) |>
  recipes::step_pca(recipes::all_predictors(), num_comp = tune::tune())
wf <- workflows::workflow(rec, parsnip::linear_reg())

set.seed(1)
folds <- nested_resamples(
  mtcars,
  outside = rsample::vfold_cv(v = 2),
  inside = rsample::vfold_cv(v = 2)
)
# One tuned workflow and one baseline, on the same nested design.
wset <- workflowsets::workflow_set(
  preproc = list(pca = rec, none = recipes::recipe(mpg ~ ., data = mtcars)),
  models = list(lm = parsnip::linear_reg())
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
autoplot(res, type = "parameters")

autoplot(res, type = "performance")
```
