# Score the saved predictions of a nested run with a metric set

[`compute_metrics()`](https://tune.tidymodels.org/reference/compute_metrics.html)
scores the predictions a run kept under `save_pred = TRUE` with a metric
set you give it. The table it returns has the shape and the averaging of
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html).
You get a metric the run did not compute without running the nested loop
again.

## Usage

``` r
# S3 method for class 'nested_results'
compute_metrics(x, metrics, ..., summarize = TRUE, event_level = NULL)
```

## Arguments

- x:

  A `nested_results` from
  [`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
  or one of its siblings, run with `save_pred = TRUE` in its control.

- metrics:

  A
  [`yardstick::metric_set()`](https://yardstick.tidymodels.org/reference/metric_set.html).

- ...:

  Not used. It must be empty.

- summarize:

  Whether to average the per-fold metrics (`TRUE`, the default) or
  return them one row per outer fold (`FALSE`).

- event_level:

  For a two-class outcome, which level is the event: `"first"` or
  `"second"`. The default, `NULL`, takes the level the run recorded.
  tune's own method defaults to `"first"` instead.

## Value

A tibble in the two shapes
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
returns. Given the metric set and the event level the run used, it is
identical to `collect_metrics(x, summarize = summarize)`.

## What is scored again, and what is not

Each outer fold kept the predictions its outer fit made on the fold's
assessment rows. Those rows are scored again, fold by fold, and the
per-fold scores are averaged as
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
averages them. A fold that scores `NA` is left out of the mean, and `n`
counts the folds behind each row.

The inner selection is not run again. Every fold keeps the parameters it
selected under the metrics of the run, and only the scoring of its outer
fit changes. A metric that is to choose the parameters has to be given
to the run itself.

On a repeated design each repeat of a fold is scored as its own fold.

## Refusals

A run whose control did not set `save_pred = TRUE` is refused with class
`nestedtune_column_not_saved`. A run in which no fold completed is
refused with class `nestedtune_no_completed_folds`.

A `metrics` that is not a metric set is refused with class
`nestedtune_bad_metrics`. A metric that reads a kind of prediction the
run did not save is refused with class
`nestedtune_metric_type_not_saved`. An example is a class metric such as
`accuracy` on a run whose metrics read only class probabilities.

A completed fold whose saved predictions do not match the rows it held
out is refused with class `nestedtune_compute_metrics_predictions`,
before any fold is scored. Its `.row` column must hold each of those
rows once and no other row. Five shapes this refuses are a missing row,
a repeated `.row`, an `NA` `.row`, a row the fold did not hold out, and
no `.row` column. A `.row` that is not a whole number is refused too.
The message names each fold that fails.
[`augment()`](https://generics.r-lib.org/reference/augment.html) refuses
the same shapes.

A run with some failed folds is scored over the rest, with a warning of
class `nestedtune_partial_summary`.

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
