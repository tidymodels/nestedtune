# Print a nested cross-validation result

Printing a `nested_results` shows its outer folds as tibble rows, the
outer resampling scheme, and how many folds did not complete.

## Usage

``` r
# S3 method for class 'nested_results'
print(x, ..., n = NULL, width = NULL)
```

## Arguments

- x:

  A `nested_results` from
  [`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
  or a related function.

- ...:

  Not used, and must be empty. Give `n` and `width` by name.

- n:

  Number of fold rows to show, passed to tibble's printing. `NULL`, the
  default, leaves the choice to tibble. `Inf` shows every fold.

- width:

  Width of the printed rows, passed to tibble's printing.

## Value

`x`, invisibly.

## Details

When the completed folds scored different sets of candidates, the print
adds each fold's candidate count. A `grid` given as a size is the usual
cause, because each fold builds its own grid under its own seed. Folds
that disagree then did not choose from the same candidates.

[`summary.nested_results()`](https://nestedtune.tidymodels.org/reference/summary.nested_results.md)
shows the selections and the nested estimate. The nested estimate
describes the tuning procedure, not a fitted model.

## See also

[`summary.nested_results()`](https://nestedtune.tidymodels.org/reference/summary.nested_results.md),
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
[collect_metrics()](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results.md)

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
res
#> 
#> ── Nested cross-validation results ────────────────────────────────────
#> Outer resamples: 2-fold cross-validation
#> # A tibble: 2 × 9
#>   splits          id    .metrics .selected .inner_metrics   .notes  
#>   <list>          <chr> <list>   <list>    <list>           <list>  
#> 1 <split [16/16]> Fold1 <tibble> <tibble>  <tibble [4 × 7]> <tibble>
#> 2 <split [16/16]> Fold2 <tibble> <tibble>  <tibble [4 × 7]> <tibble>
#> # ℹ 3 more variables: .completed <lgl>, .tuning_seed <int>,
#> #   .outer_fit_seed <int>
#> ℹ Use `summary()` for what the run means: which folds failed, what
#>   each one selected, and the estimate across them.
```
