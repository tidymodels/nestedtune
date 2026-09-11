# Tabulate how often each parameter setting was selected across the outer folds

`agreement()` tells you how often the outer folds agreed on what to
select. Each outer fold tunes on its own inner resamples and selects one
candidate, one parameter setting. `agreement()` counts those selections:
one row per distinct combination of selected parameter values, most
frequent first.

The most frequent combination is not the final model's parameters. The
tuning procedure is tune then select, and the folds say how stable its
choice is. The model to deploy comes from
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
which runs the procedure once more on the whole dataset and selects for
itself.

## Usage

``` r
agreement(x, ...)
```

## Arguments

- x:

  A `nested_results` from
  [`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
  or one of its siblings.

- ...:

  Not used; must be empty. An argument passed here is an error rather
  than silently ignored.

## Value

A tibble with one column per parameter any completed fold selected, then
`n`, the number of completed folds that chose that combination, and
`prop`, `n` over the number of completed folds. Rows run from the
largest `n` down, ties in the order the combination first appears.

## How the folds are counted

Failed folds are left out, so `sum(n)` counts the completed folds
whenever the table has rows, each counted once. A run with some folds
failed is tabulated over the rest, with a warning saying so. A run in
which none completed is an error of class
`nestedtune_no_completed_folds`, as it is for
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html),
[autoplot()](https://nestedtune.tidymodels.org/reference/autoplot.nested_results.md)
and
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md).

Looking for tune's `.config`? It is not a column here: it labels a
candidate inside one fold's own tuning run, and folds can differ in
grid.

## Missing and colliding values

A completed fold whose selection carries no value for a parameter is
counted under `NA` for it, in the same row as a fold that selected `NA`.
[`summary.nested_results()`](https://nestedtune.tidymodels.org/reference/summary.nested_results.md)
tells the two apart. A workflow with nothing to tune gives columns `n`
and `prop` and no rows. A parameter whose id is `n` or `prop` would
collide with the counts and is an error.

## See also

[`summary.nested_results()`](https://nestedtune.tidymodels.org/reference/summary.nested_results.md),
[`autoplot.nested_results()`](https://nestedtune.tidymodels.org/reference/autoplot.nested_results.md),
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
[`summary.nested_results_set()`](https://nestedtune.tidymodels.org/reference/summary.nested_results_set.md)
for a workflow-set run

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
agreement(res)
#> # A tibble: 1 × 3
#>   num_comp     n  prop
#>      <int> <int> <dbl>
#> 1        1     2     1
```
