# Stack the outer fit's predictions or extracts across the outer folds

[`collect_predictions()`](https://tune.tidymodels.org/reference/collect_predictions.html)
and
[`collect_extracts()`](https://tune.tidymodels.org/reference/collect_predictions.html)
give you the outer fit's predictions or extracts as one table across the
folds. A run whose control asked for them keeps two more records per
outer fold. `.predictions`, under `save_pred = TRUE`, holds the
predictions the fold's finalized model made on its assessment rows.
`.extracts` holds whatever the control's `extract` function returned for
the fold's fitted workflow. These two methods on tune's generics stack
one such column into a single table, the design's fold labels first.

- [`collect_predictions()`](https://tune.tidymodels.org/reference/collect_predictions.html)
  gives one row per assessment row of every completed fold, with the
  columns
  [`tune::last_fit()`](https://tune.tidymodels.org/reference/last_fit.html)
  produced: the outcome, the prediction columns, `.row` and `.config`.
  With `summarize = TRUE` it gives one averaged row per data row
  instead. See Averaging across the folds.

- [`collect_extracts()`](https://tune.tidymodels.org/reference/collect_predictions.html)
  gives one row per completed fold, the fold's value in an `.extracts`
  list column. A completed fold whose extract function errored holds
  `NULL` there, and its `.notes` say why.

## Usage

``` r
# S3 method for class 'nested_results'
collect_predictions(x, ..., summarize = FALSE)

# S3 method for class 'nested_results'
collect_extracts(x, ...)
```

## Arguments

- x:

  A `nested_results` run with a control that asked for the column. See
  [`collect_metrics.nested_results()`](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results.md)
  for what the object is.

- ...:

  Not used. It must be empty. tune's `parameters` argument is not
  offered here, because each fold predicted with the parameters it
  selected.

- summarize:

  For
  [`collect_predictions()`](https://tune.tidymodels.org/reference/collect_predictions.html),
  whether to average the predictions per data row (`TRUE`) or return
  them per fold (`FALSE`, the default). See Averaging across the folds.

## Value

A tibble: the design's fold labels (`id`, and `id2` on a repeated
design), then the stacked prediction columns, or the `.extracts` list
column. With `summarize = TRUE`, the columns of the per-fold table in
the same order, less the fold labels and `.config`, with one row per
`.row` in `.row` order.

## Folds that failed, and columns not saved

Both take the folds that completed, as
[`collect_selections()`](https://nestedtune.tidymodels.org/reference/collect_selections.md)
does. They warn once with class `nestedtune_partial_summary` on a
partial run and error with class `nestedtune_no_completed_folds` when no
fold completed.

An object whose recorded control did not ask for the column, or that no
longer carries it, is refused with class `nestedtune_column_not_saved`.
The message names the control slot to set. A prediction table carrying a
column named like a fold label column is refused with class
`nestedtune_collect_name_collision`.

## Which predictions these are

Will a row appear twice? On a v-fold outer design each row appears once
per repeat. On a Monte Carlo design it appears as often as it was held
out. These are the outer fit's predictions on the assessment rows. The
inner tuning run's own predictions and extracts, which the same two
control slots save inside tune, are not kept.

## Averaging across the folds

`summarize = TRUE` averages, for each data row, the predictions of every
completed fold that held the row out. A row that no completed fold held
out is left out, and a partial run warns once, as above. The rules are
tune's for `summarize = TRUE`, except where a rule below says otherwise.
The columns the run saved decide which rule applies.

- A numeric prediction, such as a regression's `.pred`, is its mean with
  missing values ignored.

- Class probabilities are each averaged the same way, then divided by
  the row's sum of those averages. A `.pred_class` saved beside them is
  recomputed as the class with the largest averaged probability. It is
  recomputed whatever a postprocessor set in the saved predictions. A
  row whose averaged probabilities are missing gets a missing class,
  where tune gives it the first level.

- A `.pred_class` saved without probabilities is the most frequent
  class. A missing vote counts as a class of its own, as in tune, so the
  class is missing only when missing votes outnumber every level.

- A censored run takes the median `.pred_time`, which is missing if any
  fold's value is. The survival probabilities in `.pred` take, per
  `.eval_time`, the mean `.pred_survival` and `.weight_censored` with
  missing values ignored. A `NULL` entry in `.pred` is left out of its
  row's average, and a row whose every entry is `NULL` holds `NULL`.

A tie, between votes or between averaged probabilities, goes to the
first of the tied levels in the factor's level order.

tune's own average groups the rows by candidate. Here each fold selected
its own candidate, so the average spans the candidates the folds
selected, and the fold labels and `.config` are dropped. Quantile
predictions are not averaged: a run whose saved predictions carry a
`.pred_quantile` column is refused with class
`nestedtune_summarize_quantile`.

A metric computed on these averages describes an average of several
fitted models, not the tuning procedure, so it is not the nested
estimate.
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
gives that estimate.

The average reads the saved predictions as the run returned them, and
refuses two kinds of edited table. A completed fold whose `.row` column
does not hold each row the fold held out exactly once, and no other row,
is refused with class `nestedtune_collect_predictions_predictions`. The
per-fold table, with `summarize = FALSE`, is not checked. Three shapes
are refused with class `nestedtune_summarize_columns`:

- Two or more factor outcome columns, where the average reads one.

- A `.pred_class` column with no factor outcome column.

- A censored `.pred` entry that is not `NULL` and has no `.eval_time`
  column.

An outcome column here is any column other than the prediction columns
and the fold labels. The columns tune adds beside the predictions are
not outcome columns either. Those are `.row`, `.config` and
`.case_weights`. Nor are `.iter` and `.eval_time`.

## See also

[`collect_selections()`](https://nestedtune.tidymodels.org/reference/collect_selections.md),
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html),
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
