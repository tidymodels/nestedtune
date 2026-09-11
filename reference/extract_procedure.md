# Extract the record of the procedure that ran

Returns the `procedure` record a nested result carries, or the one a
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
re-ran: which tuner ran, that tuner's own arguments, and the control as
it took effect.

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
tuner's own arguments, the arguments every orchestrator shares
(`param_info`, `event_level`, `eval_time` and `select`) as they were
given, and `control` as it took effect. The section below says what each
holds.

## Details

A final fit built from a results object re-runs exactly what this record
describes, so reading it is how you see what a fit will do before you
ask for one.

## What the record holds

`tuner` names the tune or finetune function that ran: `"tune_grid"`,
`"tune_bayes"`, `"tune_race_anova"`, `"tune_race_win_loss"`,
`"tune_sim_anneal"`, or `"fit_resamples"` for a run with nothing to
tune. Beside it sit that tuner's own arguments: `grid` for the grid and
racing tuners; `iter`, `initial` and `objective` for the Bayesian one;
`iter` and `initial` for simulated annealing; none for the plain fit.

`select` is the
[`selection_rule()`](https://nestedtune.tidymodels.org/reference/selection_rule.md)
each fold selected by. `control` is the control object the run was
given, or tune's default when none was, with the slots this package
forces already applied, and with `seed` left out on a Bayesian result. A
`"fit_resamples"` record carries no `param_info` and no `select`, since
no parameter set was read and no rule applied. See "Differences from
calling tune directly" on each orchestrator's help page for what those
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
