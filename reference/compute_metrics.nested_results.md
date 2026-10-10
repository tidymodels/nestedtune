# Score the saved predictions of a nested run with a metric set

[`compute_metrics()`](https://tune.tidymodels.org/reference/compute_metrics.html)
scores the predictions a nested run saved with a new metric set, and
returns a table shaped like
[collect_metrics()](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results.md).
The nested loop does not run again.

## Usage

``` r
# S3 method for class 'nested_results'
compute_metrics(x, metrics, ..., summarize = TRUE, event_level = NULL)
```

## Arguments

- x:

  A `nested_results` from a run with `save_pred = TRUE` in its control.

- metrics:

  A
  [`yardstick::metric_set()`](https://yardstick.tidymodels.org/reference/metric_set.html).

- ...:

  Not used, and must be empty.

- summarize:

  Whether to average the per-fold metrics (`TRUE`, the default) or
  return one row per outer fold (`FALSE`).

- event_level:

  For a two-class outcome, `"first"` or `"second"`. The default, `NULL`,
  takes the level the run used, where tune's method takes `"first"`.

## Value

A tibble in the long shape of
[collect_metrics()](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results.md).
With the run's own metric set and event level, it equals
`collect_metrics(x, summarize = summarize)`.

## Details

Each completed outer fold's saved predictions are scored on their own,
and the per-fold scores are averaged as in
[collect_metrics()](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results.md).
Each repeat of a repeated design counts as its own fold. A fold that
scores `NA` is left out of the mean.

Each fold keeps the candidate it selected. To select with a metric, pass
it in the `metrics` argument of
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
or the other nested function.

The run needs `save_pred = TRUE` in its control, and a metric that reads
a kind of prediction the run did not save is an error. So is an edited
`.predictions` column whose `.row` values do not match the rows each
fold held out.

## See also

[`collect_metrics.nested_results()`](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results.md),
[`collect_predictions.nested_results()`](https://nestedtune.tidymodels.org/reference/collect_predictions.nested_results.md),
[`augment.nested_results()`](https://nestedtune.tidymodels.org/reference/augment.nested_results.md),
[`collect_metrics.nested_results_set()`](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results_set.md)
for the same function on a workflow-set run

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
res <- nested_tune_grid(
  wf,
  folds,
  grid = data.frame(num_comp = 1:2),
  control = tune::control_grid(save_pred = TRUE)
)

# The run scored rmse and rsq. Score its predictions with mae as well.
compute_metrics(res, yardstick::metric_set(yardstick::mae))
#> # A tibble: 1 × 5
#>   .metric .estimator  mean     n std_err
#>   <chr>   <chr>      <dbl> <int>   <dbl>
#> 1 mae     standard    2.43     2   0.588
compute_metrics(res, yardstick::metric_set(yardstick::mae), summarize = FALSE)
#> # A tibble: 2 × 4
#>   id    .metric .estimator .estimate
#>   <chr> <chr>   <chr>          <dbl>
#> 1 Fold1 mae     standard        3.02
#> 2 Fold2 mae     standard        1.84
```
