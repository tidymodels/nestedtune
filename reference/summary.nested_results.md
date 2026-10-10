# Summarize a nested cross-validation result

[`summary()`](https://rdrr.io/r/base/summary.html) reports how much of
the outer design ran, which folds failed and at which stage, what each
fold selected, and the nested estimate.

## Usage

``` r
# S3 method for class 'nested_results'
summary(object, ...)

# S3 method for class 'summary.nested_results'
print(x, ...)
```

## Arguments

- object:

  A `nested_results` from
  [`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
  or a related function.

- ...:

  Not used, and must be empty.

- x:

  A `summary.nested_results` object from `summary.nested_results()`.

## Value

[`summary()`](https://rdrr.io/r/base/summary.html) returns a
`summary.nested_results`, a list with these components:

- `outer_label`, the outer resampling scheme's label

- `requested` and `completed`, the fold counts

- `failures`, the failed folds and the stage each failed at

- `selection`, what the completed folds selected

- `select` and `first_metric`, as
  [`extract_procedure()`](https://nestedtune.tidymodels.org/reference/extract_procedure.md)
  records them

- `grids`, the candidates each fold scored

- `estimate`, the averaged metrics, or `NULL` when no fold completed

[`print()`](https://rdrr.io/r/base/print.html) returns `x`, invisibly.

## Details

Folds that selected different parameters show that the tuning procedure
picks different values on different data. The averaged metrics hide
this, so the summary marks it. The nested estimate describes the tuning
procedure, not a fitted model.
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
fits the model to deploy.

Under a rule other than `"best"`, a line such as
`Selected by: one_std_err by num_comp` names the rule. A
`Selecting metric:` line names the metric that chose each fold's
candidate. It is absent under the `"desirability"` rule and on a
[`nested_fit_resamples()`](https://nestedtune.tidymodels.org/reference/nested_fit_resamples.md)
run.

A run with failed folds gives a warning and still returns its summary,
even when no fold completed.

## See also

[`print.nested_results()`](https://nestedtune.tidymodels.org/reference/print.nested_results.md),
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
[collect_metrics()](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results.md),
[`summary.nested_results_set()`](https://nestedtune.tidymodels.org/reference/summary.nested_results_set.md)
for a workflow-set run

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
set.seed(2)
res <- nested_tune_grid(wf, folds, grid = data.frame(num_comp = 1:2))
summary(res)
#> 
#> ── Nested cross-validation results ────────────────────────────────────
#> Outer resamples: 2-fold cross-validation
#> Outer folds: 2 requested, 2 completed
#> 
#> ── Selected parameters ──
#> 
#> Selecting metric: rmse
#> ✔ num_comp: 1 (all 2 completed folds agree)
#> 
#> ── Estimate (2 of 2 outer folds) ──
#> 
#> rmse (standard): 2.98
#> rsq (standard): 0.747
#> 
#> ℹ A nested estimate describes the tune-and-fit procedure. For a
#>   procedure chosen before seeing this estimate, it is the number to
#>   report for the model `nested_final_fit()` builds.
```
