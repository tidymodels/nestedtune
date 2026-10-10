# Extract the tuning run of a final fit

`extract_tune_results()` returns the tuning run from which
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
selected its parameters on all the data.

## Usage

``` r
extract_tune_results(x, ...)
```

## Arguments

- x:

  A `nested_final_fit` from
  [`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md).

- ...:

  Not used, and must be empty.

## Value

tune's own `tune_results` object, so tune's functions apply to it. A
final fit that ran no tuning gives an error.

## Details

Do not report this run's metrics. They were computed on the resamples
that chose the parameters, so they are optimistic on average about the
final model. Report the nested estimate, from
[collect_metrics()](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results.md)
on the nested run.

## See also

[`extract_scored_candidates()`](https://nestedtune.tidymodels.org/reference/extract_scored_candidates.md),
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)

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
set.seed(3)
final <- nested_final_fit(wf, res)
extract_tune_results(final)
#> # Tuning results
#> # 2-fold cross-validation 
#> # A tibble: 2 × 4
#>   splits          id    .metrics         .notes          
#>   <list>          <chr> <list>           <list>          
#> 1 <split [16/16]> Fold1 <tibble [4 × 5]> <tibble [0 × 4]>
#> 2 <split [16/16]> Fold2 <tibble [4 × 5]> <tibble [0 × 4]>
```
