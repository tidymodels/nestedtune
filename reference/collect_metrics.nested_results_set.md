# Collect the results of a workflow-set run

These methods read a `nested_results_set` from
[`nested_workflow_map()`](https://nestedtune.tidymodels.org/reference/nested_workflow_map.md).
Each one calls its method for one workflow on every workflow in the set,
and stacks the tables under a `wflow_id` column.

## Usage

``` r
# S3 method for class 'nested_results_set'
collect_metrics(x, ..., summarize = TRUE, type = c("long", "wide"))

# S3 method for class 'nested_results_set'
collect_selections(x, ...)

# S3 method for class 'nested_results_set'
collect_inner_metrics(x, ..., type = c("long", "wide"))

# S3 method for class 'nested_results_set'
collect_notes(x, ...)

# S3 method for class 'nested_results_set'
collect_predictions(x, ..., summarize = FALSE)

# S3 method for class 'nested_results_set'
collect_extracts(x, ...)

# S3 method for class 'nested_results_set'
compute_metrics(x, metrics, ..., summarize = TRUE, event_level = NULL)

# S3 method for class 'nested_results_set'
augment(x, ...)
```

## Arguments

- x:

  A `nested_results_set` from
  [`nested_workflow_map()`](https://nestedtune.tidymodels.org/reference/nested_workflow_map.md).

- ...:

  Not used, and must be empty.

- summarize:

  As on
  [`collect_metrics.nested_results()`](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results.md),
  and for
  [`collect_predictions()`](https://tune.tidymodels.org/reference/collect_predictions.html)
  as on
  [`collect_predictions.nested_results()`](https://nestedtune.tidymodels.org/reference/collect_predictions.nested_results.md).

- type:

  For
  [`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
  and
  [`collect_inner_metrics()`](https://nestedtune.tidymodels.org/reference/collect_selections.md),
  `"long"` (the default) or `"wide"`. The wide shape is keyed on
  `wflow_id` too. A column that a workflow lacks is `NA` in its rows,
  such as a metric it did not score or a parameter it does not tune. A
  workflow with no inner candidates, such as a fixed one, has no rows in
  [`collect_inner_metrics()`](https://nestedtune.tidymodels.org/reference/collect_selections.md).

- metrics, event_level:

  As on
  [`compute_metrics.nested_results()`](https://nestedtune.tidymodels.org/reference/compute_metrics.nested_results.md).
  The default `event_level` takes each workflow's recorded level.

## Value

A tibble with `wflow_id` first, then the columns that the method for one
workflow returns, bound in the set's order. A column that one workflow
lacks is `NA` in its rows, or `NULL` in a list column.

## Details

A workflow in which no fold completed is left out with a warning. If no
workflow completed a fold, the function gives an error.
[`collect_notes()`](https://tune.tidymodels.org/reference/collect_predictions.html)
reads every workflow, the failed ones included.

Each workflow can have its own control, so one workflow can save
predictions or extracts that another did not. A function that reads
saved predictions or extracts gives an error that names a workflow with
completed folds that did not save them.

## See also

[`nested_workflow_map()`](https://nestedtune.tidymodels.org/reference/nested_workflow_map.md),
[`collect_metrics.nested_results()`](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results.md),
[`collect_selections()`](https://nestedtune.tidymodels.org/reference/collect_selections.md),
[`collect_predictions.nested_results()`](https://nestedtune.tidymodels.org/reference/collect_predictions.nested_results.md),
[`compute_metrics.nested_results()`](https://nestedtune.tidymodels.org/reference/compute_metrics.nested_results.md),
[`augment.nested_results()`](https://nestedtune.tidymodels.org/reference/augment.nested_results.md),
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
