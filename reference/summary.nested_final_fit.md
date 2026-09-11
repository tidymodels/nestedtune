# Summarize a final fit

[`summary()`](https://rdrr.io/r/base/summary.html) gives you the facts
of the final fit as values rather than printed lines. Those are the
full-data tuning run the selection came from, which search ran it and at
what counts, how many parameter settings it scored, and which values it
chose.

The `estimate` component is always `NULL`, and that is the point. The
stored tuning run's metrics are selection-time quantities, so this
object records the absence of a performance number rather than leaving
the name out. See
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
for the number to report instead.

## Usage

``` r
# S3 method for class 'nested_final_fit'
summary(object, ...)

# S3 method for class 'summary.nested_final_fit'
print(x, ...)
```

## Arguments

- object:

  A `nested_final_fit` object from
  [`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md).

- ...:

  Not used. It must be empty. Passing an argument here raises an error
  instead of leaving it silently ignored.

- x:

  A `summary.nested_final_fit` object from `summary.nested_final_fit()`.

## Value

[`summary()`](https://rdrr.io/r/base/summary.html) returns an object of
class `summary.nested_final_fit`, a list with these components:

- `tuning_label`, the tuning run's resampling label

- `tuner`, the name of the tune or finetune function that ran, as
  [`extract_procedure()`](https://nestedtune.tidymodels.org/reference/extract_procedure.md)
  records it

- `candidates`, the number of parameter settings that run scored

- `initial` and `initial_requested`, `iterations_completed` and
  `iterations_requested`, the iterating tuners' counts

- `selection`, the parameter values selection chose

- `estimate`, always `NULL`

Printing it is what most callers want. The components are there for a
caller that needs a value rather than a line of text.

[`print()`](https://rdrr.io/r/base/print.html) returns `x`, invisibly.

## Components that are absent

The four counts are `NULL` on a grid or a racing fit, which iterate over
nothing. They are carried rather than dropped, for the reason `estimate`
is. The scored figures are counted from the tuning run's metrics table,
and the requested ones are the counts the search was called with. A run
whose metrics table cannot be read reports its scored figures as zero
rather than failing to print.

Where nothing was tuned there is no run to describe, so `tuning_label`
is `NULL` and `candidates` is `0`. `selection` is empty.

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
#> num_comp: 1
#> 
#> ── Estimate ──
#> 
#> ℹ This model has no performance estimate of its own. Report the nested
#>   estimate from `collect_metrics()` on the results object this fit was
#>   built from, which describes the procedure that produced it.
#> ℹ The tuning run above has metrics, but selection consumed them.
#>   `extract_tune_results()` reaches them, and every one is a
#>   selection-time quantity, optimistically biased as a claim about this
#>   model.
```
