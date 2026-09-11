# Stack a per-fold column of a nested resampling run across the outer folds

[`collect_notes()`](https://tune.tidymodels.org/reference/collect_predictions.html),
`collect_selections()` and `collect_inner_metrics()` each give you one
of a run's per-fold records as a single table. A `nested_results` keeps
three such records as one table per outer fold, in list columns. They
are what went wrong (`.notes`), what the fold's inner tuning selected
(`.selected`), and everything that tuning scored (`.inner_metrics`).
Each function stacks one column across the folds, the design's fold
labels first, so every row says which fold it came from.

- [`collect_notes()`](https://tune.tidymodels.org/reference/collect_predictions.html)
  stacks `.notes` over every outer fold, failed folds included. A
  completed fold can carry an error note too, from an `extract` that
  failed on it (see
  [`collect_extracts()`](https://nestedtune.tidymodels.org/reference/collect_predictions.nested_results.md)).

- `collect_selections()` stacks `.selected`: one row per completed fold.
  A
  [`nested_fit_resamples()`](https://nestedtune.tidymodels.org/reference/nested_fit_resamples.md)
  result gives no rows, since no fold selected anything.

- `collect_inner_metrics()` stacks `.inner_metrics`: one row per
  candidate, a parameter setting, and metric that a completed fold's
  inner tuning scored, and per iteration where the tuner iterates.

## Usage

``` r
collect_selections(x, ...)

# S3 method for class 'nested_results'
collect_selections(x, ...)

collect_inner_metrics(x, ...)

# S3 method for class 'nested_results'
collect_inner_metrics(x, ...)

# S3 method for class 'nested_results'
collect_notes(x, ...)
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

A tibble whose first columns are the design's fold labels and whose
remaining columns come from the stacked tables. See What the columns
are.

## What the columns are

The first columns are the design's fold labels: `id` on a plain v-fold
design, `id` and `id2` on a repeated one, read from the object's record
rather than recognized by name. Then come the stacked tables' own
columns, over the union of what any stacked fold carries. A fold lacking
one holds `NA` there, exactly as a fold whose recorded value is `NA`
does, so the two cannot be told apart.

[`collect_notes()`](https://tune.tidymodels.org/reference/collect_predictions.html)
stacks tune's four note columns, from `location` to `trace`. A run that
recorded no note gives no rows with those columns. A stacked table
carrying a column named like a label column, say a parameter whose id is
`id`, is refused with class `nestedtune_collect_name_collision`.

## Which folds are read

`collect_selections()` and `collect_inner_metrics()` read the folds that
completed, as
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
and
[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md)
do. A run with some folds failed is stacked over the rest, with one
warning of class `nestedtune_partial_summary` naming the missing folds.
A run in which no fold completed is an error of class
`nestedtune_no_completed_folds`.
[`collect_notes()`](https://tune.tidymodels.org/reference/collect_predictions.html)
reads every fold and warns about none.

## Reading `.config`

The `.config` of a selection or an inner-metrics row is kept as the fold
recorded it. It labels a candidate inside that one fold's tuning run. So
a selected row's `.config` is found among the same fold's rows in
`collect_inner_metrics()`. Since folds can search different candidates,
it identifies nothing across them, which is why
[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md)
leaves it out.

## See also

[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html),
[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md),
[`summary.nested_results()`](https://nestedtune.tidymodels.org/reference/summary.nested_results.md),
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
set.seed(2)
res <- nested_tune_grid(wf, folds, grid = data.frame(num_comp = 1:2))
collect_selections(res)
#> # A tibble: 2 × 3
#>   id    num_comp .config        
#>   <chr>    <int> <chr>          
#> 1 Fold1        1 pre1_mod0_post0
#> 2 Fold2        1 pre1_mod0_post0
collect_inner_metrics(res)
#> # A tibble: 8 × 8
#>   id    num_comp .metric .estimator  mean     n std_err .config        
#>   <chr>    <int> <chr>   <chr>      <dbl> <int>   <dbl> <chr>          
#> 1 Fold1        1 rmse    standard   3.20      2 0.476   pre1_mod0_post0
#> 2 Fold1        1 rsq     standard   0.772     2 0.00975 pre1_mod0_post0
#> 3 Fold1        2 rmse    standard   3.46      2 0.207   pre2_mod0_post0
#> 4 Fold1        2 rsq     standard   0.737     2 0.0434  pre2_mod0_post0
#> 5 Fold2        1 rmse    standard   6.33      2 0.886   pre1_mod0_post0
#> 6 Fold2        1 rsq     standard   0.756     2 0.0235  pre1_mod0_post0
#> 7 Fold2        2 rmse    standard   6.58      2 0.610   pre2_mod0_post0
#> 8 Fold2        2 rsq     standard   0.671     2 0.0377  pre2_mod0_post0
collect_notes(res)
#> # A tibble: 0 × 5
#> # ℹ 5 variables: id <chr>, location <chr>, type <chr>, note <chr>,
#> #   trace <list>
```
