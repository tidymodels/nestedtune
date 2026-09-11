# Stack each workflow's table of a workflow-set run under its id

The six readers of a `nested_results` also answer on a
`nested_results_set`, what
[`nested_workflow_map()`](https://nestedtune.tidymodels.org/reference/nested_workflow_map.md)
returns. Each calls its single-workflow method on every element and
binds the tables in the set's order, under a `wflow_id` column placed
first.

[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
gives one row per workflow and metric, or per workflow, outer fold and
metric with `summarize = FALSE`.
[`collect_selections()`](https://nestedtune.tidymodels.org/reference/collect_selections.md),
[`collect_inner_metrics()`](https://nestedtune.tidymodels.org/reference/collect_selections.md),
[`collect_notes()`](https://tune.tidymodels.org/reference/collect_predictions.html),
[`collect_predictions()`](https://tune.tidymodels.org/reference/collect_predictions.html)
and
[`collect_extracts()`](https://tune.tidymodels.org/reference/collect_predictions.html)
stack their per-fold tables the same way.

## Usage

``` r
# S3 method for class 'nested_results_set'
collect_metrics(x, ..., summarize = TRUE)

# S3 method for class 'nested_results_set'
collect_selections(x, ...)

# S3 method for class 'nested_results_set'
collect_inner_metrics(x, ...)

# S3 method for class 'nested_results_set'
collect_notes(x, ...)

# S3 method for class 'nested_results_set'
collect_predictions(x, ...)

# S3 method for class 'nested_results_set'
collect_extracts(x, ...)
```

## Arguments

- x:

  A `nested_results_set` from
  [`nested_workflow_map()`](https://nestedtune.tidymodels.org/reference/nested_workflow_map.md).

- ...:

  Not used; must be empty, so an argument given here is an error and not
  a silent no-op.

- summarize:

  Whether to average each workflow's per-fold metrics (`TRUE`, the
  default) or return them one row per outer fold (`FALSE`), as on
  [`collect_metrics.nested_results()`](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results.md).

## Value

A tibble: `wflow_id` first, then the columns the single-workflow reader
returns for each element, bound in the set's order over the union of the
elements' columns, `NA` where an element lacks one (`NULL` in a list
column). An element whose table has no rows contributes none.

## Workflows and folds that failed

Five of the readers take the folds that completed, as they do on one
workflow. A workflow with some folds failed contributes the folds that
ran, and that reader's own partial-run warning is raised once for it
with the workflow's id in front of the message. A workflow in which no
fold completed is left out while another workflow completed one, warned
about with class `nestedtune_partial_summary`. A set in which no
workflow completed a fold is refused with class
`nestedtune_no_completed_folds`.

[`collect_notes()`](https://tune.tidymodels.org/reference/collect_predictions.html)
is the exception: it reads every workflow, including those in which no
fold completed, and refuses nothing, since a failed workflow's notes are
the reason to ask.

## Columns not saved, and colliding ids

A control reaches each workflow of a set through the call's `...` or
through its own `option` entry, so one workflow can have kept what
another did not.
[`collect_predictions()`](https://tune.tidymodels.org/reference/collect_predictions.html)
and
[`collect_extracts()`](https://tune.tidymodels.org/reference/collect_predictions.html)
therefore refuse a set in which a workflow that would contribute rows
lacks the column, with class `nestedtune_column_not_saved` naming it.

An element's table that already has a `wflow_id` column, a parameter
given that id, is refused with class
`nestedtune_collect_name_collision`.

## See also

[`nested_workflow_map()`](https://nestedtune.tidymodels.org/reference/nested_workflow_map.md),
[`collect_metrics.nested_results()`](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results.md),
[`collect_selections()`](https://nestedtune.tidymodels.org/reference/collect_selections.md),
[`collect_predictions.nested_results()`](https://nestedtune.tidymodels.org/reference/collect_predictions.nested_results.md),
[`summary.nested_results_set()`](https://nestedtune.tidymodels.org/reference/summary.nested_results_set.md)
for the set's [`summary()`](https://rdrr.io/r/base/summary.html),
[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
and
[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md)

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
collect_metrics(res)
#> # A tibble: 4 × 6
#>   wflow_id .metric .estimator  mean     n std_err
#>   <chr>    <chr>   <chr>      <dbl> <int>   <dbl>
#> 1 pca_lm   rmse    standard   2.98      2  0.459 
#> 2 pca_lm   rsq     standard   0.747     2  0.0691
#> 3 none_lm  rmse    standard   5.93      2  2.06  
#> 4 none_lm  rsq     standard   0.495     2  0.119 
collect_metrics(res, summarize = FALSE)
#> # A tibble: 8 × 5
#>   wflow_id id    .metric .estimator .estimate
#>   <chr>    <chr> <chr>   <chr>          <dbl>
#> 1 pca_lm   Fold1 rmse    standard       3.44 
#> 2 pca_lm   Fold1 rsq     standard       0.678
#> 3 pca_lm   Fold2 rmse    standard       2.52 
#> 4 pca_lm   Fold2 rsq     standard       0.816
#> 5 none_lm  Fold1 rmse    standard       3.87 
#> 6 none_lm  Fold1 rsq     standard       0.614
#> 7 none_lm  Fold2 rmse    standard       7.98 
#> 8 none_lm  Fold2 rsq     standard       0.375
collect_selections(res)
#> # A tibble: 2 × 4
#>   wflow_id id    num_comp .config        
#>   <chr>    <chr>    <int> <chr>          
#> 1 pca_lm   Fold1        1 pre1_mod0_post0
#> 2 pca_lm   Fold2        1 pre1_mod0_post0
collect_notes(res)
#> # A tibble: 0 × 6
#> # ℹ 6 variables: wflow_id <chr>, id <chr>, location <chr>, type <chr>,
#> #   note <chr>, trace <list>
```
