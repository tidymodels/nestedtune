# Join the held-out predictions of a nested run onto its data

[`augment()`](https://generics.r-lib.org/reference/augment.html) returns
the data a nested run was given, one row per data row, with the
predictions made for that row when its outer fold held it out. You can
plot or inspect every row's out-of-fold prediction beside its
predictors.

## Usage

``` r
# S3 method for class 'nested_results'
augment(x, ...)
```

## Arguments

- x:

  A `nested_results` from
  [`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
  or one of its siblings, run with `save_pred = TRUE` in its control.

- ...:

  Not used. It must be empty. tune's `parameters` argument is not
  offered here, because each fold made its predictions with the
  parameters it selected.

## Value

A tibble with the data's rows in the data's order. The outcome column
comes first, then the prediction columns, whose names start with
`.pred`, then the rest of the data's columns. A censored outcome is
saved under its `Surv()` call, which names no data column, so there the
prediction columns come first. The fold labels, `.row` and `.config` are
not joined, and no `.resid` column is added.

## Which predictions these are

The predictions come from the outer fits. Each outer fold tuned on its
analysis rows, fitted the parameters it selected, and predicted its
held-out assessment rows. So a row's prediction was made by a model that
never saw that row.

They are not predictions from the final model. That model is fitted on
all the rows by
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
and its own
[`augment()`](https://generics.r-lib.org/reference/augment.html) method
predicts new data with it.

## Designs and folds refused

The outer design must hold out every data row exactly once, as a v-fold
or grouped v-fold design does. A repeated v-fold or a Monte Carlo design
is refused with class `nestedtune_augment_rows`, because it predicts
some rows more than once or not at all. Read its predictions with
[`collect_predictions()`](https://tune.tidymodels.org/reference/collect_predictions.html)
instead. A
[`rsample::rolling_origin()`](https://rsample.tidymodels.org/reference/rolling_origin.html),
[`rsample::sliding_window()`](https://rsample.tidymodels.org/reference/slide-resampling.html),
[`rsample::sliding_index()`](https://rsample.tidymodels.org/reference/slide-resampling.html)
or
[`rsample::sliding_period()`](https://rsample.tidymodels.org/reference/slide-resampling.html)
design leaves rows out of every assessment set and is refused with the
same class. When no row is held out twice, the message names the rows
left out. When its assessment sets overlap, the message counts the rows
left out and the rows held out more than once, and does not name a
repeated or Monte Carlo design.

A run whose control did not set `save_pred = TRUE` is refused with class
`nestedtune_column_not_saved`. A run in which no fold completed is
refused with class `nestedtune_no_completed_folds`.

A completed fold whose saved predictions do not match the rows it held
out is refused with class `nestedtune_augment_predictions`. Its `.row`
column must hold each of those rows once and no other row. On a run with
some failed folds, the rows those folds held out hold a missing value in
every prediction column, with a warning of class
`nestedtune_partial_summary`. A missing value is `NA`, or `NULL` in a
list column such as the `.pred` of a censored-regression run. A data
column whose name is also a prediction column's name is refused with
class `nestedtune_collect_name_collision`.

## See also

[`collect_predictions.nested_results()`](https://nestedtune.tidymodels.org/reference/collect_predictions.nested_results.md),
[`compute_metrics.nested_results()`](https://nestedtune.tidymodels.org/reference/compute_metrics.nested_results.md),
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
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

augment(res)
#> # A tibble: 32 × 12
#>      mpg .pred   cyl  disp    hp  drat    wt  qsec    vs    am  gear
#>    <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>
#>  1  21    23.2     6  160    110  3.9   2.62  16.5     0     1     4
#>  2  21    23.1     6  160    110  3.9   2.88  17.0     0     1     4
#>  3  22.8  25.2     4  108     93  3.85  2.32  18.6     1     1     4
#>  4  21.4  20.0     6  258    110  3.08  3.22  19.4     1     0     3
#>  5  18.7  14.9     8  360    175  3.15  3.44  17.0     0     0     3
#>  6  18.1  21.2     6  225    105  2.76  3.46  20.2     1     0     3
#>  7  14.3  14.2     8  360    245  3.21  3.57  15.8     0     0     3
#>  8  24.4  24.6     4  147.    62  3.69  3.19  20       1     0     4
#>  9  22.8  24.1     4  141.    95  3.92  3.15  22.9     1     0     4
#> 10  19.2  22.7     6  168.   123  3.92  3.44  18.3     1     0     4
#> # ℹ 22 more rows
#> # ℹ 1 more variable: carb <dbl>
```
