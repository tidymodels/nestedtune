# Extract the parameter settings a final fit actually scored

Returns the candidates, the parameter settings
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)'s
tuning run evaluated. It is the full-data counterpart of the candidate
set each outer fold's `.inner_metrics` table describes. It is derived
the same way, so the two can be compared directly.

## Usage

``` r
extract_scored_candidates(x, ...)
```

## Arguments

- x:

  A `nested_final_fit` object from
  [`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md).

- ...:

  Not used; must be empty. Passing an argument here raises an error
  instead of leaving it silently ignored.

## Value

A tibble with one row per candidate scored, carrying one column per
tuned parameter plus tune's `.config` label, and `.iter` where the
search iterated. It is the distinct parameter rows of the run's
[`tune::collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
table, with everything tune wrote per metric dropped. So a candidate has
one row here however many evaluation times it was scored at. The times
and the scores are in `collect_metrics(extract_tune_results(x))`. A fit
that ran no tuning scored no candidate and is refused with condition
class `nestedtune_no_tuning_run`.

## Scored, not asked for

A `grid` given as a size is expanded by tune and may reach fewer
candidates than the number requested. A candidate that failed everywhere
scored nothing.
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
gives the full account of how the two records diverge under
`.inner_metrics`, and it holds here too.

One pointer there does not carry over. A candidate that failed on every
inner resample is missing from this table, and a `nested_final_fit` has
no `.notes` column to record it in. Look inside the run itself:
`tune::collect_notes(extract_tune_results(x))`.

## See also

[`extract_tune_results()`](https://nestedtune.tidymodels.org/reference/extract_tune_results.md),
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)

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
extract_scored_candidates(final)
#> # A tibble: 2 × 2
#>   num_comp .config        
#>      <int> <chr>          
#> 1        1 pre1_mod0_post0
#> 2        2 pre2_mod0_post0
```
