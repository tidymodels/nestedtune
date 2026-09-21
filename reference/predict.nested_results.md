# Predicting from a nested run

A nested run holds one model per outer fold, each fitted to estimate how
the procedure performs, and none of them is the model to deploy.
[`predict()`](https://rdrr.io/r/stats/predict.html) on its results
therefore refuses, with class `nestedtune_predict_results`, and points
you to
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
which fits that model on all the data. For a workflow set, the message
names
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)'s
`id` argument, which picks the workflow.

## Usage

``` r
# S3 method for class 'nested_results'
predict(object, ...)

# S3 method for class 'nested_results_set'
predict(object, ...)
```

## Arguments

- object:

  A `nested_results` or a `nested_results_set`.

- ...:

  Not used.

## Value

None. The call is an error.

## See also

[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
[`predict.nested_final_fit()`](https://nestedtune.tidymodels.org/reference/predict.nested_final_fit.md)

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
# Predict from the final fit, not from `res`.
predict(final, new_data = mtcars[1:3, ])
#> # A tibble: 3 × 1
#>   .pred
#>   <dbl>
#> 1  23.1
#> 2  23.1
#> 3  25.2
```
