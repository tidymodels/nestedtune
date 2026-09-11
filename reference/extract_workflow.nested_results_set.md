# Extract one workflow of a workflow-set run

Returns the workflow the set holds under one `wflow_id`, as it was
given, with nothing fitted or finalized.

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

  Not used. It must be empty.

## Value

The workflow, untrained, as the set held it. An `id` naming no row of
the set is refused with class `nestedtune_unknown_id`.

## See also

[`nested_workflow_map()`](https://nestedtune.tidymodels.org/reference/nested_workflow_map.md),
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)

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
