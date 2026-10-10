# Join the held-out predictions of a nested run onto its data

[`augment()`](https://generics.r-lib.org/reference/augment.html) returns
the data a nested run was given, with each row's predictions from the
outer folds that held it out. A model that never saw the row made each
prediction.

## Usage

``` r
# S3 method for class 'nested_results'
augment(x, ...)
```

## Arguments

- x:

  A `nested_results` from a run with `save_pred = TRUE` in its control.

- ...:

  Not used, and must be empty. tune's `parameters` argument is not
  offered, because each fold predicted with the parameters it selected.

## Value

A tibble with the data's rows in the data's order: the outcome, then the
prediction columns, whose names start with `.pred`, then the other data
columns. For a censored outcome, the prediction columns come first.
Unlike tune's
[`augment()`](https://generics.r-lib.org/reference/augment.html), it
adds no `.resid` column.

## Details

These are the outer fits' predictions, not the final model's.
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
fits that model on all the rows, and its own
[`augment()`](https://generics.r-lib.org/reference/augment.html) method
predicts new data.

The outer design must hold out every data row at least once. A Monte
Carlo design can miss rows, and a time-series design misses the rows
before its first assessment set. For those, use
[`collect_predictions()`](https://tune.tidymodels.org/reference/collect_predictions.html).

On a design that holds out some row more than once, every row gets the
average that `collect_predictions(summarize = TRUE)` gives. So a
`.pred_class` saved beside class probabilities is recomputed from the
averaged probabilities, whatever a postprocessor set. A metric computed
on averaged predictions is not the nested estimate.

A row held out only by failed folds gets missing predictions, with a
warning. The run needs `save_pred = TRUE` in its control.

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
