# Extract one workflow of a workflow-set run

Extract one workflow of a workflow-set run

## Usage

``` r
# S3 method for class 'nested_results_set'
extract_workflow(x, id, ...)
```

## Arguments

- x:

  A `nested_results_set` from
  [`nested_workflow_map()`](https://nestedtune.tidymodels.org/reference/nested_workflow_map.md).

- id:

  The `wflow_id` of the workflow to return, one of `x$wflow_id`.

- ...:

  Not used; must be empty.

## Value

The workflow, untrained, as the set held it. An `id` naming no row of
the set is refused with class `nestedtune_unknown_id`.

## See also

[`nested_workflow_map()`](https://nestedtune.tidymodels.org/reference/nested_workflow_map.md),
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)

## Examples

``` r
data(mtcars)
rec <- recipes::recipe(mpg ~ ., data = mtcars)
wset <- workflowsets::workflow_set(
  preproc = list(none = rec),
  models = list(lm = parsnip::linear_reg())
)
set.seed(1)
folds <- nested_resamples(
  mtcars,
  outside = rsample::vfold_cv(v = 3),
  inside = rsample::vfold_cv(v = 3)
)
set.seed(2)
res <- nested_workflow_map(wset, resamples = folds)
extract_workflow(res, "none_lm")
#> ══ Workflow ═══════════════════════════════════════════════════════════
#> Preprocessor: Recipe
#> Model: linear_reg()
#> 
#> ── Preprocessor ───────────────────────────────────────────────────────
#> 0 Recipe Steps
#> 
#> ── Model ──────────────────────────────────────────────────────────────
#> Linear Regression Model Specification (regression)
#> 
#> Computational engine: lm 
#> 
```
