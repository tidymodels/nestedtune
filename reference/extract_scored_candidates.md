# Extract the candidates a final fit scored

`extract_scored_candidates()` returns the parameter settings that the
tuning run of
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
scored, one row per candidate. Compare them with
[`collect_inner_metrics()`](https://nestedtune.tidymodels.org/reference/collect_selections.md)
on the nested run.

## Usage

``` r
extract_scored_candidates(x, ...)
```

## Arguments

- x:

  A `nested_final_fit` from
  [`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md).

- ...:

  Not used, and must be empty.

## Value

A tibble with one column per tuned parameter, then `.config`, and
`.iter` where the search iterated. A candidate scored at several
evaluation times has one row. A final fit that ran no tuning gives an
error.

## Details

tune can reach fewer candidates than a `grid` size asks for. A candidate
that failed on every resample scored nothing and is missing here.
`tune::collect_notes(extract_tune_results(x))` shows why it failed.

## See also

[`extract_tune_results()`](https://nestedtune.tidymodels.org/reference/extract_tune_results.md),
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
extract_scored_candidates(final)
#> # A tibble: 2 × 2
#>   num_comp .config        
#>      <int> <chr>          
#> 1        1 pre1_mod0_post0
#> 2        2 pre2_mod0_post0
```
