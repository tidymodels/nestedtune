# Collect the metrics from a nested resampling run

[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
returns the nested estimate from
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
and the other nested functions. The nested estimate is each metric's
mean over the outer folds' held-out scores.

## Usage

``` r
# S3 method for class 'nested_results'
collect_metrics(x, ..., summarize = TRUE, type = c("long", "wide"))
```

## Arguments

- x:

  A `nested_results` from
  [`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
  or a related function.

- ...:

  Not used, and must be empty.

- summarize:

  Whether to average the per-fold metrics (`TRUE`, the default) or
  return one row per outer fold (`FALSE`).

- type:

  `"long"` (the default), one row per metric, or `"wide"`, one column
  per metric. The wide shape drops the estimator, `n`, `std_err` and
  `.weight`. It gives an error for a metric with two estimators. It also
  gives an error for a metric named like a key column, such as `id` in
  the per-fold table.

## Value

A tibble with `.metric` and `.estimator`. Summarized, it has one row per
metric, with `mean`, `n` and `std_err`. Unsummarized, it has one row per
outer fold and metric, with the design's fold labels first (`id`, and
`id2` on a repeated design) and `.estimate`. On a design weighted with
[`tune::add_resample_weights()`](https://tune.tidymodels.org/reference/add_resample_weights.html),
it also has each fold's `.weight`.

## Details

The estimate describes the whole procedure (tune, select, fit), not one
fitted model.
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
runs that procedure on all the data to fit the model to deploy. For a
procedure chosen before seeing this estimate, it is the number to report
for that model, because the model comes from the same procedure.

With `summarize = FALSE`, the function returns each outer fold's scores.

Only the outer folds that completed are read. Failed folds are dropped
with a warning, and `n` counts the folds behind each row. If no fold
completed, the function gives an error.

`std_err` is the standard error of the mean across the outer folds, as
tune computes it. Do not build a confidence interval from it, because
the outer folds share most of their training rows.
[`vignette("estimate")`](https://nestedtune.tidymodels.org/articles/estimate.md)
covers how to read the standard error.

A metric scored at several evaluation times gets one row per time, in a
`.eval_time` column.

## See also

[`collect_metrics.nested_results_set()`](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results_set.md)
for a workflow-set run,
[`compute_metrics.nested_results()`](https://nestedtune.tidymodels.org/reference/compute_metrics.nested_results.md),
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
set.seed(2)
res <- nested_tune_grid(wf, folds, grid = data.frame(num_comp = 1:2))
# The estimate, then the per-fold scores behind it.
collect_metrics(res)
#> # A tibble: 2 × 5
#>   .metric .estimator  mean     n std_err
#>   <chr>   <chr>      <dbl> <int>   <dbl>
#> 1 rmse    standard   2.98      2  0.459 
#> 2 rsq     standard   0.747     2  0.0691
collect_metrics(res, summarize = FALSE)
#> # A tibble: 4 × 4
#>   id    .metric .estimator .estimate
#>   <chr> <chr>   <chr>          <dbl>
#> 1 Fold1 rmse    standard       3.44 
#> 2 Fold1 rsq     standard       0.678
#> 3 Fold2 rmse    standard       2.52 
#> 4 Fold2 rsq     standard       0.816
```
