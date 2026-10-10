# Print a workflow-set run

Printing a `nested_results_set` shows the nested function the set ran
through and the number of workflows. Each workflow then gets a line with
its id, how many outer folds completed, and the tuner that ran.

## Usage

``` r
# S3 method for class 'nested_results_set'
print(x, ...)
```

## Arguments

- x:

  A `nested_results_set` from
  [`nested_workflow_map()`](https://nestedtune.tidymodels.org/reference/nested_workflow_map.md).

- ...:

  Not used, and must be empty.

## Value

`x`, invisibly.

## Details

[`summary.nested_results_set()`](https://nestedtune.tidymodels.org/reference/summary.nested_results_set.md)
shows each workflow's selections and nested estimate. Each nested
estimate describes its workflow's tuning procedure, not a fitted model.

## See also

[`nested_workflow_map()`](https://nestedtune.tidymodels.org/reference/nested_workflow_map.md),
[`collect_metrics.nested_results_set()`](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results_set.md),
[`summary.nested_results_set()`](https://nestedtune.tidymodels.org/reference/summary.nested_results_set.md)

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
print(res)
#> 
#> ── Nested cross-validation results for a workflow set ─────────────────
#> Orchestrator: `nested_tune_grid()` (grid search)
#> Workflows: 2
#> ✔ "pca_lm": 2 of 2 outer folds completed (grid search)
#> ✔ "none_lm": 2 of 2 outer folds completed (no tuning)
#> ℹ Use `collect_metrics()` for every workflow's estimate under its id,
#>   and `x$result[[i]]` for one workflow's run.
```
