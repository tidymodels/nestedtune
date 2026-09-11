# Summarize a nested cross-validation result

Answers what the run means. It says how much of the requested outer
design ran, and which outer folds failed at which stage. It also says
what each fold's inner tuning selected, and the estimate across the
folds that completed.

The selection lines are the part nothing else in the ecosystem shows.
Outer folds that chose different parameters mean the tuning procedure,
tune then select, is unstable on this data. Averaging the metrics hides
that, so the summary marks it.

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
  or one of its siblings.

- ...:

  Not used; must be empty. An argument passed here is an error rather
  than silently ignored.

- x:

  A `summary.nested_results` object from `summary.nested_results()`.

## Value

[`summary()`](https://rdrr.io/r/base/summary.html) returns an object of
class `summary.nested_results`, a list holding:

- the outer resampling scheme's label;

- the requested and completed fold counts;

- the failed folds, with the stage each failed at;

- what the completed folds selected, and the candidates, the parameter
  settings, each searched;

- the metric estimates averaged over them.

Printing it is what most callers want; the components are there for one
that needs a number rather than a line of text.

[`print()`](https://rdrr.io/r/base/print.html) returns `x`, invisibly.

## A run that did not finish

Summarizing a partly completed run warns and still returns the summary:
the folds that ran are described, and the warning says the design asked
for more. A run in which every fold failed behaves the same way,
describing a failed run rather than refusing to answer. That is where
this differs from
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html),
which errors when no outer fold completed.

## See also

[`print.nested_results()`](https://nestedtune.tidymodels.org/reference/print.nested_results.md),
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html),
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
#> ✔ num_comp: 1 (all 2 completed folds agree)
#> 
#> ── Estimate (2 of 2 outer folds) ──
#> 
#> rmse (standard): 2.98
#> rsq (standard): 0.747
#> 
#> ℹ A nested estimate describes the tune-and-fit procedure, not a model
#>   you can deploy. Build that with `nested_final_fit()`, and report
#>   this estimate as what its procedure achieves.
```
