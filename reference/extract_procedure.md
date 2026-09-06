# Extract the record of the procedure that ran

Returns the `procedure` record a
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
[`nested_tune_bayes()`](https://nestedtune.tidymodels.org/reference/nested_tune_bayes.md),
[`nested_tune_race_anova()`](https://nestedtune.tidymodels.org/reference/nested_tune_race.md),
[`nested_tune_race_win_loss()`](https://nestedtune.tidymodels.org/reference/nested_tune_race.md)
or
[`nested_tune_sim_anneal()`](https://nestedtune.tidymodels.org/reference/nested_tune_sim_anneal.md)
result carries, or the one a
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
re-ran: which tuner ran, that tuner's own arguments, and the control as
it took effect. A final fit built from a results object re-runs exactly
what this record describes.

## Usage

``` r
extract_procedure(x, ...)
```

## Arguments

- x:

  A `nested_results` object from one of the orchestrators, or a
  `nested_final_fit` object from
  [`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md).

- ...:

  Not used; must be empty. An argument passed here is an error rather
  than silently ignored.

## Value

The stored record, unchanged: a flat named list with `tuner`, the name
of the tune or finetune function that ran (`"tune_grid"`,
`"tune_bayes"`, `"tune_race_anova"`, `"tune_race_win_loss"` or
`"tune_sim_anneal"`); that tuner's own arguments (`grid` for the grid
and racing tuners; `iter`, `initial` and `objective` for the Bayesian
tuner; `iter` and `initial` for simulated annealing); the arguments
every orchestrator shares, `param_info`, `event_level` and `eval_time`,
as they were given; and `control`, the control object the run was given,
or tune's default when none was, with the slots this package forces
already applied, and on a Bayesian result with `seed` left out. See
"Differences from calling tune directly" on each orchestrator's help
page for what those slots are.

On a `nested_results` the record travels as an attribute of the object;
on a `nested_final_fit` it is the record the fit re-ran, which is the
record of the results object it was built from.

## See also

[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
[`extract_tune_results()`](https://nestedtune.tidymodels.org/reference/extract_tune_results.md),
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)

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
res <- nested_tune_grid(wf, folds, grid = data.frame(num_comp = 1:3))
procedure <- extract_procedure(res)
procedure$tuner
#> [1] "tune_grid"
procedure$control$allow_par
#> [1] FALSE

set.seed(3)
final <- nested_final_fit(wf, res)
identical(extract_procedure(final)$tuner, procedure$tuner)
#> [1] TRUE
```
