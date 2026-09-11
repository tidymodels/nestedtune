# Stack the outer fit's predictions or extracts across the outer folds

A run whose control asked for them keeps, per outer fold, the
predictions its finalized model made on the fold's assessment rows
(`.predictions`, under `save_pred = TRUE`) and whatever the control's
`extract` function returned for the fold's fitted workflow
(`.extracts`). These two methods on tune's generics stack one such
column into a single table, the design's fold labels first.

- [`collect_predictions()`](https://tune.tidymodels.org/reference/collect_predictions.html)
  gives one row per assessment row of every completed fold, with the
  columns
  [`tune::last_fit()`](https://tune.tidymodels.org/reference/last_fit.html)
  produced: the outcome, `.pred` or the class columns, `.row` and
  `.config`.

- [`collect_extracts()`](https://tune.tidymodels.org/reference/collect_predictions.html)
  gives one row per completed fold, the fold's value in an `.extracts`
  list column. A completed fold whose extract function errored holds
  `NULL` there, and its `.notes` say why.

## Usage

``` r
# S3 method for class 'nested_results'
collect_predictions(x, ...)

# S3 method for class 'nested_results'
collect_extracts(x, ...)
```

## Arguments

- x:

  A `nested_results` run with a control that asked for the column. See
  [`collect_metrics.nested_results()`](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results.md)
  for what the object is.

- ...:

  Not used; must be empty. tune's `summarize` and `parameters` arguments
  are not offered here.

## Value

A tibble: the design's fold labels (`id`, and `id2` on a repeated
design), then the stacked prediction columns, or the `.extracts` list
column.

## Folds that failed, and columns not saved

Both readers take the folds that completed, as
[`collect_selections()`](https://nestedtune.tidymodels.org/reference/collect_selections.md)
does, warning once with class `nestedtune_partial_summary` on a partial
run and erroring with class `nestedtune_no_completed_folds` when no fold
completed.

An object whose recorded control did not ask for the column, or that no
longer carries it, is refused with class `nestedtune_column_not_saved`,
and the message names the control slot to set. A prediction table
carrying a column named like a fold label column is refused with class
`nestedtune_collect_name_collision`.

## Which predictions these are

They are the outer fit's, on each fold's assessment rows. On a v-fold
outer design every row of the data therefore appears once per repeat; on
a Monte Carlo design a row appears as often as it was held out. The
inner tuning run's own predictions and extracts, which the same two
control slots save inside tune, are not kept.

## See also

[`collect_selections()`](https://nestedtune.tidymodels.org/reference/collect_selections.md),
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html),
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
[`collect_metrics.nested_results_set()`](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results_set.md)
for the same readers on a workflow-set run

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
# Ask the control to keep the predictions and a coefficient extract.
set.seed(2)
res <- nested_tune_grid(
  wf,
  folds,
  grid = data.frame(num_comp = 1:2),
  control = tune::control_grid(
    save_pred = TRUE,
    extract = function(x) coef(workflows::extract_fit_engine(x))
  )
)

collect_predictions(res)
#> # A tibble: 32 × 5
#>    id      mpg .pred  .row .config        
#>    <chr> <dbl> <dbl> <int> <chr>          
#>  1 Fold1  21    23.2     1 pre0_mod0_post0
#>  2 Fold1  22.8  25.2     3 pre0_mod0_post0
#>  3 Fold1  21.4  20.0     4 pre0_mod0_post0
#>  4 Fold1  18.1  21.2     6 pre0_mod0_post0
#>  5 Fold1  14.3  14.2     7 pre0_mod0_post0
#>  6 Fold1  19.2  22.7    10 pre0_mod0_post0
#>  7 Fold1  17.8  22.7    11 pre0_mod0_post0
#>  8 Fold1  16.4  18.1    12 pre0_mod0_post0
#>  9 Fold1  14.7  11.9    17 pre0_mod0_post0
#> 10 Fold1  32.4  26.6    18 pre0_mod0_post0
#> # ℹ 22 more rows
collect_extracts(res)
#> # A tibble: 2 × 2
#>   id    .extracts
#>   <chr> <list>   
#> 1 Fold1 <dbl [2]>
#> 2 Fold2 <dbl [2]>
```
