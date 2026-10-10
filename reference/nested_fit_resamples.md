# Score a workflow with nothing to tune on a nested design

`nested_fit_resamples()` scores a workflow with nothing to tune on a
nested design. Each outer fold fits the workflow on its analysis set and
scores it on the rows it held out.

## Usage

``` r
nested_fit_resamples(object, ...)

# Default S3 method
nested_fit_resamples(object, ...)

# S3 method for class 'model_spec'
nested_fit_resamples(
  object,
  preprocessor,
  resamples,
  ...,
  metrics = NULL,
  event_level = "first",
  eval_time = NULL
)

# S3 method for class 'workflow'
nested_fit_resamples(
  object,
  resamples,
  ...,
  metrics = NULL,
  event_level = "first",
  eval_time = NULL
)
```

## Arguments

- object:

  A
  [`workflows::workflow()`](https://workflows.tidymodels.org/reference/workflow.html)
  with no parameter marked with
  [`tune::tune()`](https://hardhat.tidymodels.org/reference/tune.html),
  or a parsnip model specification given with `preprocessor`.

- ...:

  On the generic, the arguments of the method. On a method, pass
  `control = tune::control_resamples()` here to set the control. Name
  every argument after `...`.

- preprocessor:

  A formula or recipe, when `object` is a model specification.

- resamples:

  A nested resampling design from
  [`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md)
  or
  [`rsample::nested_cv()`](https://rsample.tidymodels.org/reference/nested_cv.html).

- metrics:

  A
  [`yardstick::metric_set()`](https://yardstick.tidymodels.org/reference/metric_set.html),
  or `NULL` for tune's default set. Every metric is scored on the outer
  folds. A set that does not suit the model's mode is an error before
  any fold runs.

- event_level:

  `"first"` (the default) or `"second"`. It names which level of a
  two-class outcome is the event. It applies to the outer scoring fit.

- eval_time:

  A numeric vector of evaluation times for a censored regression model,
  or `NULL` (the default) to leave the choice to tune. Times that are
  not numeric, empty, missing, negative or not finite are an error.

## Value

A `nested_results`, as
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
describes. `.selected` is a zero-column tibble on each completed fold,
and `.inner_metrics` has zero rows. There is no `grid` attribute.

## Details

Use it for a baseline to compare with a tuned workflow. On the same
design, the two runs score the same outer folds, so their per-fold
metrics join by fold label.
[`tune::fit_resamples()`](https://tune.tidymodels.org/reference/fit_resamples.html)
does the same job on a plain set of folds.
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
documents what the loop functions share, such as the design, what the
estimate describes, the seeds, failed folds and parallel execution.

A workflow with a
[`tune::tune()`](https://hardhat.tidymodels.org/reference/tune.html)
marker is an error here, and a workflow with none is an error in the
tuning functions.

Fold `i` is
[`tune::last_fit()`](https://tune.tidymodels.org/reference/last_fit.html)
of `object` on `resamples$splits[[i]]`, under the seed in
`res$.outer_fit_seed[[i]]`. Each fold also draws a tuning seed that
nothing uses, so the outer-fit seeds match those of a tuned run on the
same design.

[`collect_selections()`](https://nestedtune.tidymodels.org/reference/collect_selections.md),
[`collect_inner_metrics()`](https://nestedtune.tidymodels.org/reference/collect_selections.md)
and
[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md)
return zero rows, and `autoplot(type = "parameters")` is an error.
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
fits the workflow on all the data.

## Differences from calling tune directly

A
[`tune::control_resamples()`](https://tune.tidymodels.org/reference/control_grid.html)
passed through `...` as `control` is kept as
`extract_procedure(res)$control`. The one tune call a fold makes is the
outer fit, which runs under its own
[`tune::control_last_fit()`](https://tune.tidymodels.org/reference/control_last_fit.html).
[`tune::control_grid()`](https://tune.tidymodels.org/reference/control_grid.html)
and `control_last_fit()` also carry the `control_resamples` class, so
both are accepted too.

**Forced: `allow_par`.** The outer fit runs with `allow_par = FALSE`,
because the outer folds carry the parallelism.

**Settable as its own argument: `event_level`.** Set the level with the
`event_level` argument. A control left at the default level, `"first"`,
takes the argument's level. A control set to another level than the
argument's is an error. `eval_time` is an argument too.

**Refused: none.** No setting is refused on its own. A control of
another class is an error, even a `control_bayes()` that tune itself
accepts.

**Passed through: none.** There is no inner tuning call.

**Kept from the outer fit: `save_pred`, `extract`.** With
`save_pred = TRUE`, the result has a `.predictions` column. With an
`extract` function, it has an `.extracts` column. Without them, the
outer fit's predictions and extracts are still discarded.

**Not returned: none.** There is no inner run.

**Inert: `verbose`, `pkgs`, `save_workflow`, `parallel_over`,
`backend_options`, `workflow_size`.** Each one sets an inner tuning call
that this function never makes. The workflow's packages must still be
installed.

## See also

[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
[`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md),
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
[`tune::fit_resamples()`](https://tune.tidymodels.org/reference/fit_resamples.html)

## Examples

``` r
data(mtcars)

# A fixed workflow: no tune() marker anywhere.
fixed <- workflows::workflow(mpg ~ ., parsnip::linear_reg())

set.seed(1)
folds <- nested_resamples(
  mtcars,
  outside = rsample::vfold_cv(v = 2),
  inside = rsample::vfold_cv(v = 2)
)

set.seed(2)
res <- nested_fit_resamples(fixed, folds)
collect_metrics(res)
#> # A tibble: 2 × 5
#>   .metric .estimator  mean     n std_err
#>   <chr>   <chr>      <dbl> <int>   <dbl>
#> 1 rmse    standard   5.93      2   2.06 
#> 2 rsq     standard   0.495     2   0.119

# The record says no tuning ran.
extract_procedure(res)$tuner
#> [1] "fit_resamples"
res$.selected[[1]]
#> # A tibble: 0 × 0
```
