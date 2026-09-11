# Collect the metrics from a nested resampling run

Reports the nested cross-validation estimate: what the tune-and-fit
procedure achieves on data it never saw. It is not the performance of
any model you have in hand.

## Usage

``` r
# S3 method for class 'nested_results'
collect_metrics(x, ..., summarize = TRUE)
```

## Arguments

- x:

  A `nested_results` from
  [`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
  or one of its siblings.

- ...:

  Not used; must be empty. An argument passed here is an error rather
  than silently ignored.

- summarize:

  Whether to average the per-fold metrics (`TRUE`, the default) or
  return them one row per outer fold (`FALSE`).

## Value

A tibble, described under What the two shapes hold.

## What the two shapes hold

Summarized, there is one row per metric, with the mean across outer
folds, the number of folds `n` behind it, and the standard error of that
mean. Unsummarized, there is one row per outer fold and metric.

A metric measured at several evaluation times (`eval_time` on
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md))
gets a row per time in both shapes, and is never averaged across times.
Both shapes carry a `.eval_time` column exactly when the run was scored
by a dynamic or integrated survival metric, as tune's own
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
does; a static metric's row beside one holds `NA` there.

## Folds that failed

Only the outer folds that completed are read, and `n` counts the folds
behind each row, so an estimate is never reported as though the whole
design had run. Failed folds are dropped with a warning naming them.

A run in which no fold completed is an error of class
`nestedtune_no_completed_folds`, rather than a table of `NA`. It is the
class
[autoplot()](https://nestedtune.tidymodels.org/reference/autoplot.nested_results.md),
[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md)
and
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
refuse such an object with.

## Reading `std_err`

`std_err` is the standard error of the mean across outer folds: the
standard deviation of the per-fold scores over the square root of how
many there were. It measures the precision of that mean, not the
fold-to-fold spread, which is larger by the same square-root factor. It
is not a confidence interval, and one should not be built from it.

That is a limit of the statistics, not of this implementation. Outer
fold scores are not independent, since any two folds share most of their
training rows, so a standard error computed as though they were can
misstate the uncertainty, usually downward. Bengio and Grandvalet (2004)
proved that no universally unbiased estimator of a k-fold estimate's
variance exists to put in its place. Gauran, Ombao and Yu (2025)
measured the cost inside a nested design: several of their test
statistics with a variance-based denominator rejected a true null far
above the nominal 5% they ran at (36% and 40% in their worst cells), and
they advise against such denominators.

Both results concern quantities close to this column rather than this
column exactly. Bengio and Grandvalet study a k-fold estimate built from
per-observation losses, and Gauran and colleagues work inside ridge and
LASSO designs. Neither gap rescues the column: no interval here is
oracle-backed. It is reported because tune reports it, and no
inferential claim is made with it.

## References

Bengio, Y., & Grandvalet, Y. (2004). No unbiased estimator of the
variance of K-fold cross-validation. *Journal of Machine Learning
Research*, 5, 1089–1105.

Gauran, I. I., Ombao, H., & Yu, Z. (2025). Predictive performance test
based on the exhaustive nested cross-validation for high-dimensional
data. *arXiv:2408.03138*.

## See also

[`collect_metrics.nested_results_set()`](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results_set.md)
for the same reader on a workflow-set run

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
# The estimate, then the per-fold scores behind it.
collect_metrics(res)
#> # A tibble: 2 × 5
#>   .metric .estimator  mean     n std_err
#>   <chr>   <chr>      <dbl> <int>   <dbl>
#> 1 rmse    standard   2.98      2  0.459 
#> 2 rsq     standard   0.747     2  0.0691
collect_metrics(res, summarize = FALSE)
#> # A tibble: 4 × 4
#>   id    .metric .estimator .estimate
#>   <chr> <chr>   <chr>          <dbl>
#> 1 Fold1 rmse    standard       3.44 
#> 2 Fold1 rsq     standard       0.678
#> 3 Fold2 rmse    standard       2.52 
#> 4 Fold2 rsq     standard       0.816
```
