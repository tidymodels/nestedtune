# Extract the record of what ran

Returns the `procedure` record a nested result carries, the tune, select
and fit steps as they were set. It says which tuner ran, that tuner's
own arguments, and the control as it took effect. A
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
carries the record it re-ran.

## Usage

``` r
extract_procedure(x, ...)
```

## Arguments

- x:

  A `nested_results` object from
  [`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
  or one of its siblings, or a `nested_final_fit` object from
  [`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md).

- ...:

  Not used; must be empty. Passing an argument here raises an error
  instead of leaving it silently ignored.

## Value

The stored record, unchanged: a flat named list with `tuner`, that
tuner's own arguments, the arguments every loop function shares, and
`control` as it took effect. The section below says what each holds.

## Details

Reading this record is how you see what a final fit will do before you
ask for one. A final fit built from a results object re-runs exactly
what the record describes.

## What the record holds

`tuner` names the tune or finetune function that ran, with that tuner's
own arguments beside it:

- `"tune_grid"`, with `grid`;

- `"tune_race_anova"` or `"tune_race_win_loss"`, also with `grid`;

- `"tune_bayes"`, with `iter`, `initial` and `objective`;

- `"tune_sim_anneal"`, with `iter` and `initial`;

- `"fit_resamples"`, for a run with nothing to tune, with none.

`select` is the
[`selection_rule()`](https://nestedtune.tidymodels.org/reference/selection_rule.md)
each fold selected by. `param_info`, `event_level` and `eval_time` are
as they were given. `control` is the control object the run was given,
or tune's default when none was, with the slots this package forces
already applied. On a Bayesian result `seed` is left out. A
`"fit_resamples"` record carries no `param_info` and no `select`, since
no parameter set was read and no rule applied. See "Differences from
calling tune directly" on each loop function's help page for what those
slots are.

On a `nested_results` the record travels as an attribute of the object.
On a `nested_final_fit` it is the record the fit re-ran, which is the
record of the results object it was built from.

## See also

[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
[`extract_tune_results()`](https://nestedtune.tidymodels.org/reference/extract_tune_results.md),
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
procedure <- extract_procedure(res)
procedure$tuner
#> [1] "tune_grid"
procedure$control$allow_par
#> [1] FALSE

identical(extract_procedure(final)$tuner, procedure$tuner)
#> [1] TRUE
```
