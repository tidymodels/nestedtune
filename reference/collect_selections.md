# Collect each outer fold's selections, inner metrics or notes

`collect_selections()`, `collect_inner_metrics()` and
[`collect_notes()`](https://tune.tidymodels.org/reference/collect_predictions.html)
return what each outer fold's inner tuning selected, scored or noted, in
one table with the fold labels first.

## Usage

``` r
collect_selections(x, ...)

# S3 method for class 'nested_results'
collect_selections(x, ...)

collect_inner_metrics(x, ...)

# S3 method for class 'nested_results'
collect_inner_metrics(x, ...)

# S3 method for class 'nested_results'
collect_notes(x, ...)
```

## Arguments

- x:

  A `nested_results` from
  [`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
  or a related function.

- ...:

  Not used, and must be empty.

## Value

A tibble with the fold labels first (`id`, and `id2` on a repeated
design), then the stacked columns. A fold that lacks a column holds `NA`
there.
[`collect_notes()`](https://tune.tidymodels.org/reference/collect_predictions.html)
gives tune's note columns, from `location` to `trace`.

## Details

- `collect_selections()` gives the tuned parameter values and `.config`
  of the candidate each completed fold selected, one row per fold. A
  [`nested_fit_resamples()`](https://nestedtune.tidymodels.org/reference/nested_fit_resamples.md)
  result gives no rows.

- `collect_inner_metrics()` gives the columns of
  [`tune::collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
  for every candidate that each completed fold's inner tuning scored.

- [`collect_notes()`](https://tune.tidymodels.org/reference/collect_predictions.html)
  gives the notes of every fold, the failed ones included.

The first two read only the folds that completed, with a warning if some
failed. If no fold completed, they give an error.

A `.config` value labels a candidate inside one fold's tuning run, so it
does not identify a candidate across folds.

## See also

[collect_metrics()](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results.md),
[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md),
[`summary.nested_results()`](https://nestedtune.tidymodels.org/reference/summary.nested_results.md),
[`collect_metrics.nested_results_set()`](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results_set.md)
for the same functions on a workflow-set run

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
collect_selections(res)
#> # A tibble: 2 × 3
#>   id    num_comp .config        
#>   <chr>    <int> <chr>          
#> 1 Fold1        1 pre1_mod0_post0
#> 2 Fold2        1 pre1_mod0_post0
collect_inner_metrics(res)
#> # A tibble: 8 × 8
#>   id    num_comp .metric .estimator  mean     n std_err .config        
#>   <chr>    <int> <chr>   <chr>      <dbl> <int>   <dbl> <chr>          
#> 1 Fold1        1 rmse    standard   3.20      2 0.476   pre1_mod0_post0
#> 2 Fold1        1 rsq     standard   0.772     2 0.00975 pre1_mod0_post0
#> 3 Fold1        2 rmse    standard   3.46      2 0.207   pre2_mod0_post0
#> 4 Fold1        2 rsq     standard   0.737     2 0.0434  pre2_mod0_post0
#> 5 Fold2        1 rmse    standard   6.33      2 0.886   pre1_mod0_post0
#> 6 Fold2        1 rsq     standard   0.756     2 0.0235  pre1_mod0_post0
#> 7 Fold2        2 rmse    standard   6.58      2 0.610   pre2_mod0_post0
#> 8 Fold2        2 rsq     standard   0.671     2 0.0377  pre2_mod0_post0
collect_notes(res)
#> # A tibble: 0 × 5
#> # ℹ 5 variables: id <chr>, location <chr>, type <chr>, note <chr>,
#> #   trace <list>
```
