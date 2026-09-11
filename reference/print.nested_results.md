# Print a nested cross-validation result

Shows the object: its outer folds as the tibble rows they are, and the
outer resampling scheme it came from. It also says how many folds did
not complete, and points to
[`summary.nested_results()`](https://nestedtune.tidymodels.org/reference/summary.nested_results.md)
for what the run means.

## Usage

``` r
# S3 method for class 'nested_results'
print(x, ..., n = NULL, width = NULL)
```

## Arguments

- x:

  A `nested_results` from
  [`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
  or one of its siblings.

- ...:

  Not used. It must be empty, so `n` and `width` must be given by name
  in full.

- n:

  Number of fold rows to show, passed to tibble's printing. `NULL`, the
  default, leaves the choice to tibble and its `print_max` and
  `print_min` options. `Inf` shows every fold.

- width:

  Width of the printed rows, passed to tibble's printing. `NULL`, the
  default, uses the `width` option, and columns that do not fit are
  named in the footer.

## Value

`x`, invisibly.

## When the folds searched different candidates

Folds can score different candidate sets, the parameter settings each
inner search tried. When two or more completed folds did, and only then,
the print adds a line with each fold's candidate count. A grid given as
a size is the usual cause. It is expanded once per fold, under that
fold's own seed, so a continuous parameter leaves every fold with
candidates of its own. It matters for reading the selections: folds that
disagreed were not choosing from the same menu.

## See also

[`summary.nested_results()`](https://nestedtune.tidymodels.org/reference/summary.nested_results.md),
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)

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
