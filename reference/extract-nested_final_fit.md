# Extract the parts of a final fit's workflow

These methods reach the fitted model, the preprocessor and the outcome
names of the workflow that
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
trained. Each one gives the same answer as the same call on
[`extract_workflow()`](https://hardhat.tidymodels.org/reference/hardhat-extract.html)'s
output.

## Usage

``` r
# S3 method for class 'nested_final_fit'
extract_fit_parsnip(x, ...)

# S3 method for class 'nested_final_fit'
extract_fit_engine(x, ...)

# S3 method for class 'nested_final_fit'
extract_recipe(x, ..., estimated = TRUE)

# S3 method for class 'nested_final_fit'
extract_mold(x, ...)

# S3 method for class 'nested_final_fit'
extract_preprocessor(x, ...)

# S3 method for class 'nested_final_fit'
extract_spec_parsnip(x, ...)

# S3 method for class 'nested_final_fit'
outcome_names(x, ...)
```

## Arguments

- x:

  A `nested_final_fit` from
  [`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md).

- ...:

  Must be empty. A workflow's methods other than
  [`extract_recipe()`](https://hardhat.tidymodels.org/reference/hardhat-extract.html)
  ignore an argument they do not know, so these refuse it rather than
  pass it on.

- estimated:

  For
  [`extract_recipe()`](https://hardhat.tidymodels.org/reference/hardhat-extract.html),
  whether to return the trained recipe (`TRUE`, the default) or the
  recipe as it was given.

## Value

What the same call returns for the trained workflow.

## See also

[`extract_workflow()`](https://hardhat.tidymodels.org/reference/hardhat-extract.html),
[`extract_tune_results()`](https://nestedtune.tidymodels.org/reference/extract_tune_results.md)

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
extract_fit_parsnip(final)
#> parsnip model object
#> 
#> 
#> Call:
#> stats::lm(formula = ..y ~ ., data = data)
#> 
#> Coefficients:
#> (Intercept)          PC1  
#>    30.61860      0.03842  
#> 
extract_recipe(final)
#> 
#> ── Recipe ─────────────────────────────────────────────────────────────
#> 
#> ── Inputs 
#> Number of variables by role
#> outcome:    1
#> predictor: 10
#> 
#> ── Training information 
#> Training data contained 32 data points and no incomplete rows.
#> 
#> ── Operations 
#> • PCA extraction with: cyl, disp, hp, drat, wt, qsec, ... | Trained
outcome_names(final)
#> [1] "mpg"
```
