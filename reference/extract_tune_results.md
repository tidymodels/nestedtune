# Extract the tuning run a final fit was selected from

Returns the tuning result that
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
chose its parameters from. It is the record of what selection saw when
the recorded procedure, tune, select and fit, was re-run on the complete
dataset.

## Usage

``` r
extract_tune_results(x, ...)
```

## Arguments

- x:

  A `nested_final_fit` object from
  [`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md).

- ...:

  Not used. It must be empty. Passing an argument here raises an error
  instead of leaving it silently ignored.

## Value

The stored `tune_results` object, unchanged. It is tune's own object, so
tune's generics apply to it directly. A fit that ran no tuning is
refused with condition class `nestedtune_no_tuning_run`.

## What its numbers are, and are not

Do not report the metrics this object gives you. It answers
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
and hands its metrics over unqualified. Each of them was computed on the
resamples that chose the parameter setting it describes. That makes it a
selection-time quantity, optimistically biased as a claim about the
model this final fit produced.

The nested estimate is the honest one, and
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
says why. This run is kept because it is the record of what selection
saw, not because it describes the model.

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
