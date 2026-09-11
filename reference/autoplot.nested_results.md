# Plot a nested cross-validation result

Two views of a `nested_results`, both drawing one point per outer fold,
with the folds in design order.

`type = "parameters"`, the default, shows what each outer fold's inner
tuning selected. A flat row of points means the folds agreed; points at
different heights mean they disagreed, so the tuning procedure is
unstable on this data, which averaging the metrics hides.

`type = "performance"` shows each outer fold's score on its held-out
assessment set, with a rule at the nested estimate, the value
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
reports.

## Usage

``` r
# S3 method for class 'nested_results'
autoplot(object, type = c("parameters", "performance"), ...)
```

## Arguments

- object:

  A `nested_results` from
  [`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
  or one of its siblings,
  [`nested_fit_resamples()`](https://nestedtune.tidymodels.org/reference/nested_fit_resamples.md)
  included.

- type:

  Which view to draw: `"parameters"` (the default) or `"performance"`.

- ...:

  Not used; must be empty. An argument passed here is an error rather
  than silently ignored.

## Value

A `ggplot` object.

## Folds with nothing to draw

An outer fold that failed keeps its place on the x axis and draws no
point, as does one that completed without recording a value for a
parameter. Nothing is imputed and nothing leaves the axis, so the
shortfall shows in the figure.

A run in which no fold completed is refused with class
`nestedtune_no_completed_folds`, as
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html),
[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md)
and
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
refuse it. A run in which no completed fold selected a parameter, such
as a
[`nested_fit_resamples()`](https://nestedtune.tidymodels.org/reference/nested_fit_resamples.md)
result, is refused under `type = "parameters"` with class
`nestedtune_no_tuned_parameters`, while `type = "performance"` draws it.

## What the labels say

The subtitle gives how much of the requested design ran. How many folds
stand behind a panel is said on the panel instead, since it varies
between them: a panel reading `mtry (2 of 3 chose)` or
`rmse (from 2 folds)` had fewer than the run completed, and an
unqualified one had them all. A requested metric that no completed fold
could score keeps an empty panel rather than disappearing.

The selected-value axis is numeric when every value drawn is a number
and discrete otherwise, since one axis cannot be both and
character-valued parameters are ordinary. On that discrete axis a fold
that selected `NA` draws a point at `NA` rather than no point.

## See also

[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
[`print.nested_results()`](https://nestedtune.tidymodels.org/reference/print.nested_results.md),
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html),
[`summary.nested_results_set()`](https://nestedtune.tidymodels.org/reference/summary.nested_results_set.md)
for the same two views of a workflow-set run

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
autoplot(res)

autoplot(res, type = "performance")
```
