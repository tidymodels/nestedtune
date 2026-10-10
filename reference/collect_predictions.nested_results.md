# Collect the predictions or extracts of a nested run's outer fits

[`collect_predictions()`](https://tune.tidymodels.org/reference/collect_predictions.html)
and
[`collect_extracts()`](https://tune.tidymodels.org/reference/collect_predictions.html)
return what each outer fold's fit saved, stacked across the folds with
the fold labels first.

## Usage

``` r
# S3 method for class 'nested_results'
collect_predictions(x, ..., summarize = FALSE)

# S3 method for class 'nested_results'
collect_extracts(x, ...)
```

## Arguments

- x:

  A `nested_results` from a run with `save_pred = TRUE`, or with an
  `extract` function for
  [`collect_extracts()`](https://tune.tidymodels.org/reference/collect_predictions.html).

- ...:

  Not used, and must be empty. tune's `parameters` argument is not
  offered, because each fold predicted with the parameters it selected.

- summarize:

  For
  [`collect_predictions()`](https://tune.tidymodels.org/reference/collect_predictions.html),
  whether to average the predictions for each data row (`TRUE`) or
  return them per fold (`FALSE`, the default).

## Value

A tibble with the fold labels first (`id`, and `id2` on a repeated
design). For
[`collect_predictions()`](https://tune.tidymodels.org/reference/collect_predictions.html),
the columns
[`tune::last_fit()`](https://tune.tidymodels.org/reference/last_fit.html)
saved follow: the outcome, the predictions, `.row` and `.config`. That
`.config` labels the outer fit, not the selected candidate. Averaged,
the table has one row per data row that a completed fold held out, in
`.row` order. It has no fold labels and no `.config`.

## Details

The run's control must ask for the column: `save_pred = TRUE` for
predictions, or an `extract` function for extracts. Otherwise the
function gives an error that names the setting.

The predictions are the outer fits' predictions on the rows each fold
held out. The inner tuning runs' own predictions and extracts are not
kept. Only the folds that completed are read, with a warning if some
failed.

[`collect_extracts()`](https://tune.tidymodels.org/reference/collect_predictions.html)
gives one row per completed fold, with the value in an `.extracts` list
column. If the extract function failed on a fold, the value is `NULL`
and the fold's `.notes` say why.

## Averaging across the folds

A repeated or Monte Carlo design can hold a data row out more than once.
`summarize = TRUE` averages each row's predictions over the completed
folds that held it out, by the rules of
[`tune::collect_predictions()`](https://tune.tidymodels.org/reference/collect_predictions.html).
The saved columns decide which rule applies. A `.pred_class` saved
beside class probabilities is recomputed from the averaged
probabilities, whatever a postprocessor set. A `NULL` entry in a
censored `.pred` is left out of its row's average. The rules differ from
tune's in three ways:

- Each fold selected its own candidate, so the average spans the
  selected candidates, and the fold labels and `.config` are dropped.

- A row whose averaged class probabilities are missing gets a missing
  class, where tune gives it the first level.

- Quantile predictions are not averaged, and they give an error.

A metric computed on these averages describes an average of several
fitted models, so it is not the nested estimate.
[collect_metrics()](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results.md)
gives that estimate.

## See also

[`collect_selections()`](https://nestedtune.tidymodels.org/reference/collect_selections.md),
[collect_metrics()](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results.md),
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
[`collect_metrics.nested_results_set()`](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results_set.md)
for the same functions on a workflow-set run

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

# A repeated design holds each row out once per repeat. The average
# gives one prediction per row.
set.seed(3)
repeated <- nested_resamples(
  mtcars,
  outside = rsample::vfold_cv(v = 2, repeats = 2),
  inside = rsample::vfold_cv(v = 2)
)
res_rep <- nested_tune_grid(
  wf,
  repeated,
  grid = data.frame(num_comp = 1:2),
  control = tune::control_grid(save_pred = TRUE)
)
collect_predictions(res_rep, summarize = TRUE)
#> # A tibble: 32 × 3
#>      mpg .pred  .row
#>    <dbl> <dbl> <int>
#>  1  21    22.6     1
#>  2  21    23.7     2
#>  3  22.8  25.4     3
#>  4  21.4  19.4     4
#>  5  18.7  15.7     5
#>  6  18.1  20.6     6
#>  7  14.3  14.3     7
#>  8  24.4  23.5     8
#>  9  22.8  23.1     9
#> 10  19.2  23.1    10
#> # ℹ 22 more rows
```
