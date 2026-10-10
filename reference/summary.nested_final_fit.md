# Summarize a final fit

[`summary()`](https://rdrr.io/r/base/summary.html) returns the facts of
a final fit as values: the tuning run on all the data, the tuner and its
counts, how many candidates it scored, and the selected values.

## Usage

``` r
# S3 method for class 'nested_final_fit'
summary(object, ...)

# S3 method for class 'summary.nested_final_fit'
print(x, ...)
```

## Arguments

- object:

  A `nested_final_fit` from
  [`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md).

- ...:

  Not used, and must be empty.

- x:

  A `summary.nested_final_fit` object from `summary.nested_final_fit()`.

## Value

[`summary()`](https://rdrr.io/r/base/summary.html) returns a
`summary.nested_final_fit`, a list with these components:

- `tuning_label`, the tuning run's resampling label

- `tuner`, the tune or finetune function that ran

- `candidates`, the number of candidates the run scored

- `initial`, `initial_requested`, `iterations_completed` and
  `iterations_requested`, the counts of an iterating search

- `selection`, the selected parameter values

- `select` and `first_metric`, as
  [`extract_procedure()`](https://nestedtune.tidymodels.org/reference/extract_procedure.md)
  records them

- `estimate`, always `NULL`

[`print()`](https://rdrr.io/r/base/print.html) returns `x`, invisibly.

## Details

The `estimate` component is always `NULL`, because the number to report
is not stored on the fit. It is the nested estimate from
[collect_metrics()](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results.md)
on the nested run the fit was built from. The nested estimate describes
the procedure that produced this model, not the fitted model itself.

The four iteration counts are `NULL` for a grid search or a race. On a
fit with nothing to tune, `candidates` is 0, `selection` is empty, and
the other components but `tuner` are `NULL`.

## See also

[`print.nested_final_fit()`](https://nestedtune.tidymodels.org/reference/print.nested_final_fit.md),
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
[`summary.nested_results()`](https://nestedtune.tidymodels.org/reference/summary.nested_results.md),
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
summary(final)
#> 
#> ── Nested cross-validation final fit ──────────────────────────────────
#> Full-data tuning: 2-fold cross-validation
#> Procedure: grid search, 2 candidates scored
#> Candidates scored: 2
#> 
#> ── Selected parameters ──
#> 
#> Selecting metric: rmse
#> num_comp: 1
#> 
#> ── Estimate ──
#> 
#> ℹ Report the nested estimate from `collect_metrics()` on the results
#>   object this fit was built from. For a fit built from a workflow set,
#>   that is this workflow's rows of `collect_metrics()` on the set. That
#>   holds for a workflow chosen before seeing the set's estimates. It
#>   describes the procedure that produced this model, and it is the
#>   number to report for this model.
#> ℹ The tuning run above has metrics, but selection consumed them.
#>   `extract_tune_results()` reaches them, and every one is a
#>   selection-time quantity, optimistically biased as a claim about this
#>   model.
```
