# Print a final fit

Printing a `nested_final_fit` shows the tuning run on all the data, the
parameters it selected, and which number to report for this model.

## Usage

``` r
# S3 method for class 'nested_final_fit'
print(x, ...)
```

## Arguments

- x:

  A `nested_final_fit` from
  [`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md).

- ...:

  Not used, and must be empty.

## Value

`x`, invisibly.

## Details

The number to report is the nested estimate from
[collect_metrics()](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results.md)
on the nested run the fit was built from. For a workflow set, it is that
workflow's rows. The nested estimate describes the procedure that
produced this model, not the fitted model itself. The tuning run's own
metrics were used to select, so they are optimistic on average.

The line under the heading names the tuner and its counts: the
candidates a grid search or a race scored, or the initial candidates and
iterations of an iterating search. A fit with nothing to tune reads "no
tuning".

Under a rule other than `"best"`, a line such as
`Selected by: pct_loss by num_comp (limit = 5)` names the rule. A
`Selecting metric:` line names the metric that chose the candidate. It
is absent under the `"desirability"` rule.

## See also

[`summary.nested_final_fit()`](https://nestedtune.tidymodels.org/reference/summary.nested_final_fit.md),
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
[`extract_tune_results()`](https://nestedtune.tidymodels.org/reference/extract_tune_results.md),
[`extract_scored_candidates()`](https://nestedtune.tidymodels.org/reference/extract_scored_candidates.md)

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
final
#> 
#> ── Nested cross-validation final fit ──────────────────────────────────
#> Procedure: grid search, 2 candidates scored
#> Selected: num_comp = 1
#> Selecting metric: rmse
#> 
#> ℹ Report the nested estimate from `collect_metrics()` on the results
#>   object this fit was built from. For a fit built from a workflow set,
#>   that is this workflow's rows of `collect_metrics()` on the set. That
#>   holds for a workflow chosen before seeing the set's estimates. It
#>   describes the procedure that produced this model, and it is the
#>   number to report for this model.
#> ℹ Compare the parameters above with `.selected` from that run. Outer
#>   folds choosing differently is selection instability, and it is
#>   information about the procedure rather than noise.
#> ℹ `extract_tune_results()` returns the tuning run selection came from,
#>   and `extract_scored_candidates()` the candidates it scored. Any
#>   metric reachable through the first is a selection-time quantity,
#>   optimistically biased as a claim about this model.
```
