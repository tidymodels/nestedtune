# Tabulate how often each parameter setting was selected across the outer folds

`agreement()` counts how often the outer folds selected each combination
of parameter values, most frequent first.

## Usage

``` r
agreement(x, ...)
```

## Arguments

- x:

  A `nested_results` from
  [`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
  or a related function.

- ...:

  Not used, and must be empty.

## Value

A tibble with one column per selected parameter, then `n`, the number of
completed folds that chose the combination, and `prop`, its share of the
completed folds. There is no `.config` column, because a `.config`
labels a candidate inside one fold's tuning run.

## Details

Folds that agree suggest that the tuning procedure picks a stable value.
The final model's parameters can still differ from the most frequent
combination, because
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
tunes once more on all the data.

Failed folds are left out, with a warning. If no fold completed, the
function gives an error. A fold with no value for a parameter is counted
under `NA`, in the same row as a fold that selected `NA`.
[`summary.nested_results()`](https://nestedtune.tidymodels.org/reference/summary.nested_results.md)
tells the two apart. A workflow with nothing to tune gives no rows.

## See also

[`summary.nested_results()`](https://nestedtune.tidymodels.org/reference/summary.nested_results.md),
[`autoplot.nested_results()`](https://nestedtune.tidymodels.org/reference/autoplot.nested_results.md),
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
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
agreement(res)
#> # A tibble: 1 × 3
#>   num_comp     n  prop
#>      <int> <int> <dbl>
#> 1        1     2     1
```
