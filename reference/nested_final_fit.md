# Fit the final model after nested cross-validation

`nested_final_fit()` fits the model to deploy after a nested run. It
runs the same procedure (tune, select, fit) once more on all the data.

## Usage

``` r
nested_final_fit(object, results, ..., id = NULL)
```

## Arguments

- object:

  The
  [`workflows::workflow()`](https://workflows.tidymodels.org/reference/workflow.html)
  the nested run used, or a `nested_results_set` from
  [`nested_workflow_map()`](https://nestedtune.tidymodels.org/reference/nested_workflow_map.md)
  with `id` naming the workflow to fit. After a run on a model
  specification, pass `workflows::workflow(preprocessor, spec)`.

- results:

  The `nested_results` from
  [`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
  another nested tuning function or
  [`nested_fit_resamples()`](https://nestedtune.tidymodels.org/reference/nested_fit_resamples.md).
  The tuner and its arguments, the metrics, `eval_time` and the
  selection rule are read from it.

- ...:

  Not used, and must be empty.

- id:

  For a `nested_results_set`, the `wflow_id` of the workflow to fit.
  Leave `results` missing then.

## Value

An object of class `nested_final_fit` with these elements:

- `workflow`, the trained workflow. The object answers
  [predict()](https://nestedtune.tidymodels.org/reference/predict.nested_final_fit.md)
  and [`augment()`](https://generics.r-lib.org/reference/augment.html)
  directly.

- `selected`, the parameters chosen, and `tuning`, the tuning run they
  were chosen from.

- `tuning_seed` and `fit_seed`, the two seeds that reproduce it.

- `procedure`, the settings of the run, as `results` holds them.

Where nothing was tuned, `selected` is an empty table and `tuning` is
`NULL`.

## Details

The function rebuilds the inner resamples on all the rows from the
design's `inside` specification. It tunes with the same tuner and
settings, picks a candidate with the same
[`selection_rule()`](https://nestedtune.tidymodels.org/reference/selection_rule.md),
and fits the finalized workflow on all the data. A parameter range that
depends on the data is finalized on all the rows. The outer folds and
their choices play no part. Where nothing was tuned, the function only
fits the workflow on all the data.

The design keeps `inside` as a call, and this function evaluates it
again in the environment you call from. Write it with literal arguments,
such as `vfold_cv(v = 5)`. With `vfold_cv(v = k)`, another `k` in scope
gives another design.

A workflow whose model or preprocessor differs from the one the nested
run used is an error, and the message names the first part that differs.
Model arguments and recipe functions are compared as written. So a name
bound to another value is not caught, and neither is a function with the
same body that uses other values. A run in which some folds failed is
still fitted. To fit one workflow of a set, pass the set as `object`,
name the workflow with `id`, and leave `results` missing.

## What to report

The nested estimate describes the procedure that produced this model,
not this model itself. Report
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
on `results` as the estimate for this model, because the model comes
from the same procedure. It averages over what each fold chose, so it
says nothing about the setting this model carries. It describes new data
drawn like your training data. If the outer folds chose different
parameters, report that too.

For a workflow from a set, report that workflow's rows only if you chose
the workflow before you saw the set's estimates. A choice made from
those estimates is a selection the outer loop did not nest.

Do not report the metrics in the `tuning` element. They come from the
resamples that chose the candidate, so they are optimistic on average.
The nested estimate tends to be slightly pessimistic instead, because
each outer fold trained on fewer rows.
[`vignette("estimate")`](https://nestedtune.tidymodels.org/articles/estimate.md)
gives the sizes measured in two studies.

## Reproducibility

Call [`set.seed()`](https://rdrr.io/r/base/Random.html) before the
function. It draws two seeds: the first builds the inner resamples and
tunes, and the second fits. Both are kept on the object, and your random
state is restored on exit. So two calls with no
[`set.seed()`](https://rdrr.io/r/base/Random.html) between them give the
same model, as repeated
[`tune::tune_grid()`](https://tune.tidymodels.org/reference/tune_grid.html)
calls do.
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
says what an R-side seed cannot pin.

The code below redoes the fit by hand. The values come from
[`extract_procedure()`](https://nestedtune.tidymodels.org/reference/extract_procedure.md),
except `metrics`, which is `attr(results, "metrics")`, and `data`, the
data the design was built on. Only the tuning line changes with the
tuner.

    set.seed(fit$tuning_seed, kind = "Mersenne-Twister",
             normal.kind = "Inversion", sample.kind = "Rejection")
    inner <- <the design's `inside` specification>(data)
    control <- extract_procedure(fit)$control
    # Run the one tuning line for the recorded tuner.
    # Grid search and the races use the control as it is.
    tuned <- tune_grid(object, inner, grid = grid, param_info = param_info,
      metrics = metrics, eval_time = eval_time, control = control)
    tuned <- tune_race_anova(object, inner, grid = grid, param_info = param_info,
      metrics = metrics, eval_time = eval_time, control = control)
    tuned <- tune_race_win_loss(object, inner, grid = grid, param_info = param_info,
      metrics = metrics, eval_time = eval_time, control = control)
    # So does annealing.
    tuned <- tune_sim_anneal(object, inner, iter = iter, initial = initial,
      param_info = param_info, metrics = metrics, eval_time = eval_time,
      control = control)
    # A Bayesian search also sets the control's seed.
    control$seed <- fit$tuning_seed
    tuned <- tune_bayes(object, inner, iter = iter, initial = initial,
      objective = objective, param_info = param_info, metrics = metrics,
      eval_time = eval_time, control = control)
    final <- finalize_workflow(object, select_best(tuned, metric = <first metric>))
      # Or select_by_one_std_err() or select_by_pct_loss(), as `select` says.
    set.seed(fit$fit_seed, kind = "Mersenne-Twister",
             normal.kind = "Inversion", sample.kind = "Rejection")
    fit(final, data)

Where nothing was tuned, the code is `fit(object, data)` under the
second seed.

## See also

[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
[`nested_tune_bayes()`](https://nestedtune.tidymodels.org/reference/nested_tune_bayes.md),
[`nested_workflow_map()`](https://nestedtune.tidymodels.org/reference/nested_workflow_map.md),
[`predict.nested_final_fit()`](https://nestedtune.tidymodels.org/reference/predict.nested_final_fit.md),
[`extract_workflow()`](https://hardhat.tidymodels.org/reference/hardhat-extract.html)

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
# The estimate: what the procedure achieves, and the number to report.
collect_metrics(res)
#> # A tibble: 2 × 5
#>   .metric .estimator  mean     n std_err
#>   <chr>   <chr>      <dbl> <int>   <dbl>
#> 1 rmse    standard   2.98      2  0.459 
#> 2 rsq     standard   0.747     2  0.0691

# The model: what you deploy.
final
#> 
#> ── Nested cross-validation final fit ──────────────────────────────────
#> Procedure: grid search, 2 candidates scored
#> Selected: num_comp = 1
#> Selecting metric: rmse
#> 
#> ℹ Report the nested estimate from `collect_metrics()` on the results
#>   object this fit was built from. For a fit built from a workflow set,
#>   that is this workflow's rows of `collect_metrics()` on the set. That
#>   holds for a workflow chosen before seeing the set's estimates. It
#>   describes the procedure that produced this model, and it is the
#>   number to report for this model.
#> ℹ Compare the parameters above with `.selected` from that run. Outer
#>   folds choosing differently is selection instability, and it is
#>   information about the procedure rather than noise.
#> ℹ `extract_tune_results()` returns the tuning run selection came from,
#>   and `extract_scored_candidates()` the candidates it scored. Any
#>   metric reachable through the first is a selection-time quantity,
#>   optimistically biased as a claim about this model.

predict(final, new_data = mtcars[1:3, ])
#> # A tibble: 3 × 1
#>   .pred
#>   <dbl>
#> 1  23.1
#> 2  23.1
#> 3  25.2
```
