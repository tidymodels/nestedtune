# Extract the procedure a nested run used

`extract_procedure()` returns what a nested run recorded about its
procedure: the tuner and its arguments, the selection rule, the control
and the workflow.
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
runs this procedure again.

## Usage

``` r
extract_procedure(x, ...)
```

## Arguments

- x:

  A `nested_results` from
  [`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
  or a related function, or a `nested_final_fit`.

- ...:

  Not used, and must be empty.

## Value

A named list with these elements, in this order:

- `tuner` and the tuner's own arguments

- `param_info`, `event_level` and `eval_time`

- `select` and `first_metric`

- `control` and `workflow`

## Details

`tuner` names the tune or finetune function that ran, with its own
arguments beside it:

- `"tune_grid"`, with `grid`

- `"tune_race_anova"` or `"tune_race_win_loss"`, also with `grid`

- `"tune_bayes"`, with `iter`, `initial` and `objective`

- `"tune_sim_anneal"`, with `iter` and `initial`

- `"fit_resamples"`, with none

`select` is the
[`selection_rule()`](https://nestedtune.tidymodels.org/reference/selection_rule.md),
and `first_metric` is the first metric of the set, as tune resolves it.
A run given no metric set names the first metric of tune's default set.
`param_info`, `event_level` and `eval_time` are as given. `control` is
the control that took effect, with the settings this package forces
applied. On a Bayesian run, its `seed` is left out. A `"fit_resamples"`
record has no `param_info`, `select` or `first_metric`.

`workflow` describes the model, the preprocessor, and any case-weights
column and tailor postprocessor as text.
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
uses it to check that it gets the same workflow. A model argument is
stored as written, so a variable's name is stored and not its value. The
workflow object and the data are not stored.

## See also

[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
[`selection_rule()`](https://nestedtune.tidymodels.org/reference/selection_rule.md),
[`extract_tune_results()`](https://nestedtune.tidymodels.org/reference/extract_tune_results.md),
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
and the other loop functions for what the forced control settings are

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
procedure <- extract_procedure(res)
procedure$tuner
#> [1] "tune_grid"
procedure$control$allow_par
#> [1] FALSE

identical(extract_procedure(final)$tuner, procedure$tuner)
#> [1] TRUE
```
