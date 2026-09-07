# Stack the outer fit's predictions or extracts across the outer folds

A run whose control asked for them keeps, per outer fold, the
predictions its finalized model made on the fold's assessment rows
(`.predictions`, under `save_pred = TRUE`) and the value the control's
`extract` function returned for the fold's fitted workflow
(`.extracts`). These two readers, methods on tune's generics, stack one
such column into a single table with the columns the design labelled its
folds with placed first.

- [`collect_predictions()`](https://tune.tidymodels.org/reference/collect_predictions.html)
  stacks `.predictions` over the folds that completed: one row per
  assessment row of every completed fold, the columns as
  [`tune::last_fit()`](https://tune.tidymodels.org/reference/last_fit.html)
  produced them (the outcome, `.pred` or the class columns, `.row` and
  `.config`).

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

  A `nested_results` object from
  [`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
  or one of its siblings, run with a control that asked for the column.

- ...:

  Not used; must be empty. An argument passed here is an error rather
  than silently ignored. tune's `summarize` and `parameters` arguments
  are not offered.

## Value

A tibble. The first columns are the design's fold labels, read from the
object's record: `id` on a plain v-fold design, `id` and `id2` on a
repeated one. Then, for
[`collect_predictions()`](https://tune.tidymodels.org/reference/collect_predictions.html),
the columns of the stacked prediction tables over the union of the
columns any fold carries, `NA` where a fold lacks one; for
[`collect_extracts()`](https://tune.tidymodels.org/reference/collect_predictions.html),
the `.extracts` list column. A prediction table carrying a column named
like a fold label column is refused with condition class
`nestedtune_collect_name_collision`.

## Details

Both read the folds that completed, the rule
[`collect_selections()`](https://nestedtune.tidymodels.org/reference/collect_selections.md)
and
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
follow: a partial run is stacked over the completed folds with one
warning of class `nestedtune_partial_summary`, and a run in which no
fold completed is an error of class `nestedtune_no_completed_folds`. An
object whose run's control did not ask for `.predictions` or
`.extracts`, read from the recorded procedure, or that no longer carries
the column, is refused with condition class
`nestedtune_column_not_saved`, the message naming the slot to set.

The predictions are the outer fit's on each fold's assessment rows, so
on a v-fold outer design every row of the data appears once per repeat
in
[`collect_predictions()`](https://tune.tidymodels.org/reference/collect_predictions.html)'s
table; on a bootstrap or Monte Carlo outer design a row appears as often
as it was held out. The inner tuning run's predictions and extracts,
which the same two slots also save inside tune, are not kept.

## See also

[`collect_selections()`](https://nestedtune.tidymodels.org/reference/collect_selections.md),
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html),
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
[`collect_metrics.nested_results_set()`](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results_set.md)
for the same readers on a workflow-set run

## Examples

``` r
data(mtcars)

rec <- recipes::step_pca(
  recipes::recipe(mpg ~ ., data = mtcars),
  recipes::all_predictors(),
  num_comp = tune::tune()
)
wf <- workflows::workflow(rec, parsnip::linear_reg())

set.seed(1)
folds <- nested_resamples(
  mtcars,
  outside = rsample::vfold_cv(v = 3),
  inside = rsample::vfold_cv(v = 3)
)

set.seed(2)
res <- nested_tune_grid(
  wf,
  folds,
  grid = data.frame(num_comp = 1:3),
  control = tune::control_grid(
    save_pred = TRUE,
    extract = function(x) coef(workflows::extract_fit_engine(x))
  )
)

collect_predictions(res)
#> # A tibble: 32 × 5
#>    id      mpg .pred  .row .config        
#>    <chr> <dbl> <dbl> <int> <chr>          
#>  1 Fold1  21    23.6     1 pre0_mod0_post0
#>  2 Fold1  21    23.6     2 pre0_mod0_post0
#>  3 Fold1  22.8  25.8     3 pre0_mod0_post0
#>  4 Fold1  21.4  20.3     4 pre0_mod0_post0
#>  5 Fold1  19.2  23.0    10 pre0_mod0_post0
#>  6 Fold1  17.3  17.9    13 pre0_mod0_post0
#>  7 Fold1  21.5  25.2    21 pre0_mod0_post0
#>  8 Fold1  15.2  17.7    23 pre0_mod0_post0
#>  9 Fold1  19.2  13.8    25 pre0_mod0_post0
#> 10 Fold1  30.4  25.7    28 pre0_mod0_post0
#> # ℹ 22 more rows
collect_extracts(res)
#> # A tibble: 3 × 2
#>   id    .extracts
#>   <chr> <list>   
#> 1 Fold1 <dbl [3]>
#> 2 Fold2 <dbl [2]>
#> 3 Fold3 <dbl [2]>
```
