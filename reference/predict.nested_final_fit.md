# Predict with the final model

[`predict()`](https://rdrr.io/r/stats/predict.html) and
[`augment()`](https://generics.r-lib.org/reference/augment.html) on a
`nested_final_fit` call the trained workflow's own methods. Each returns
what the same call on the workflow from
[`extract_workflow()`](https://hardhat.tidymodels.org/reference/hardhat-extract.html)
returns.

## Usage

``` r
# S3 method for class 'nested_final_fit'
predict(object, new_data, type = NULL, opts = list(), ...)

# S3 method for class 'nested_final_fit'
augment(x, new_data, eval_time = NULL, ...)
```

## Arguments

- object, x:

  A `nested_final_fit` from
  [`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md).

- new_data:

  A data frame of new observations to predict.

- type, opts:

  Passed to
  [`workflows::predict.workflow()`](https://workflows.tidymodels.org/reference/predict-workflow.html)
  unchanged. `type` selects the prediction type, such as `"numeric"`,
  `"prob"` or `"survival"`. Left unset, it takes the workflow's default.

- ...:

  For [`predict()`](https://rdrr.io/r/stats/predict.html), arguments for
  the model's predict method, such as `level` with `type = "conf_int"`.
  parsnip gives an error for a name outside its list of predict
  arguments. For
  [`augment()`](https://generics.r-lib.org/reference/augment.html), not
  used, and must be empty.

- eval_time:

  For censored regression, the times at which to evaluate survival
  probabilities in
  [`augment()`](https://generics.r-lib.org/reference/augment.html).
  Ignored otherwise.

## Value

[`predict()`](https://rdrr.io/r/stats/predict.html) returns the
workflow's tibble of predictions.
[`augment()`](https://generics.r-lib.org/reference/augment.html) returns
the prediction columns, then the columns of `new_data`, with a `.resid`
column for a regression model when the outcome is present.

## Details

Residuals on the rows the model was fit on are in-sample, so they do not
measure performance. Report the nested estimate from
[collect_metrics()](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results.md)
on the nested run the fit was built from.

## See also

[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
[`extract_workflow()`](https://hardhat.tidymodels.org/reference/hardhat-extract.html),
[`workflows::predict.workflow()`](https://workflows.tidymodels.org/reference/predict-workflow.html),
[`workflows::augment.workflow()`](https://workflows.tidymodels.org/reference/augment.workflow.html)

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
predict(final, new_data = mtcars[1:3, ])
#> # A tibble: 3 × 1
#>   .pred
#>   <dbl>
#> 1  23.1
#> 2  23.1
#> 3  25.2
predict(final, new_data = mtcars[1:3, ], type = "conf_int", level = 0.9)
#> # A tibble: 3 × 2
#>   .pred_lower .pred_upper
#>         <dbl>       <dbl>
#> 1        22.1        24.2
#> 2        22.1        24.2
#> 3        23.9        26.5
augment(final, new_data = mtcars[1:3, ])
#> # A tibble: 3 × 13
#>   .pred .resid   mpg   cyl  disp    hp  drat    wt  qsec    vs    am
#> * <dbl>  <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>
#> 1  23.1  -2.14  21       6   160   110  3.9   2.62  16.5     0     1
#> 2  23.1  -2.14  21       6   160   110  3.9   2.88  17.0     0     1
#> 3  25.2  -2.38  22.8     4   108    93  3.85  2.32  18.6     1     1
#> # ℹ 2 more variables: gear <dbl>, carb <dbl>
```
