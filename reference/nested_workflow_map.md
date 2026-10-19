# Run every workflow of a workflow set through one nested design

`nested_workflow_map()` runs every workflow of a
[`workflowsets::workflow_set()`](https://workflowsets.tidymodels.org/reference/workflow_set.html)
through one nested design, so you can compare models on the same outer
folds.

## Usage

``` r
nested_workflow_map(object, fn = "nested_tune_grid", verbose = FALSE, ...)
```

## Arguments

- object:

  A workflow set.

- fn:

  The name of the function to run each workflow through. The default is
  `"nested_tune_grid"`. The others are `"nested_tune_bayes"`,
  `"nested_tune_race_anova"`, `"nested_tune_race_win_loss"` and
  `"nested_tune_sim_anneal"`. With `"nested_fit_resamples"`, no workflow
  can have a parameter to tune.

- verbose:

  Whether `nested_workflow_map()` writes a message as each workflow
  starts and as it finishes. The default is `FALSE`. The finish message
  gives the time the workflow took. A workflow that gives an error has
  no finish message.

- ...:

  The arguments of `fn`, each one named. `resamples`, the nested design,
  is required, and a `control` goes here as well. A name that `fn` does
  not take is an error. A `metrics` set reaches every workflow, and one
  that does not suit a workflow's model is an error before any workflow
  runs. Under every
  [`selection_rule()`](https://nestedtune.tidymodels.org/reference/selection_rule.md)
  but `"desirability"`, its first metric chooses each fold's candidate.

## Value

A `nested_results_set`, a tibble with one row per workflow. Its columns
are `wflow_id`, `workflow`, and `result`, the workflow's
`nested_results`. It is not a `workflow_set`, so
[`workflowsets::rank_results()`](https://workflowsets.tidymodels.org/reference/rank_results.html)
and
[`tune::fit_best()`](https://tune.tidymodels.org/reference/fit_best.html)
do not accept it. Choosing the best workflow by its nested estimate is a
selection that the outer loop did not nest.

## Details

The function works like
[`workflowsets::workflow_map()`](https://workflowsets.tidymodels.org/reference/workflow_map.html).
`fn` names the nested function to run, and its arguments come through
`...`. Unlike in workflowsets, an entry in the set's `option` column
overrides an argument of the same name in `...`, for that workflow
alone. The workflows run in the set's order, and the set's own `result`
column is not read.

A workflow with no
[`tune::tune()`](https://hardhat.tidymodels.org/reference/tune.html)
marker runs through
[`nested_fit_resamples()`](https://nestedtune.tidymodels.org/reference/nested_fit_resamples.md),
whatever `fn` names, so a baseline can sit beside the tuned models. Each
workflow gets only the arguments its function takes. So a `grid` reaches
the tuned workflows and not the fixed one, and the fixed one runs under
tune's default control unless its `option` entry names one.

There is no `seed` argument, so call
[`set.seed()`](https://rdrr.io/r/base/Random.html) first. Each workflow
starts from the same random state, so fold `i` of every workflow runs
under the same two seeds. Each result is identical to a call by hand on
that workflow, with the same arguments, after the same
[`set.seed()`](https://rdrr.io/r/base/Random.html).

An error from one workflow names that workflow at the front of its
message and keeps its class. So does a warning about failed folds. An
error stops the call, so nothing is returned, even for the workflows
that already ran.

[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
and the other `collect_*()` functions stack each workflow's table under
a `wflow_id` column.
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
with an `id` fits one workflow.

[`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html),
[`dplyr::arrange()`](https://dplyr.tidyverse.org/reference/arrange.html),
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
and `x[i, ]` keep the class. They keep it only while the `wflow_id`,
`workflow` and `result` columns keep their values. An operation that
empties the set, repeats a `wflow_id`, changes or drops one of those
columns, or brings in a row from elsewhere returns a plain tibble. So
does a direct
[`vctrs::vec_cbind()`](https://vctrs.r-lib.org/reference/vec_bind.html).
[`dplyr::group_by()`](https://dplyr.tidyverse.org/reference/group_by.html),
[`dplyr::rowwise()`](https://dplyr.tidyverse.org/reference/rowwise.html)
and
[`tibble::as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)
return other classes that still carry the `fn` attribute. A value
replaced with `$<-` or `[[<-` is not checked.

## See also

[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
[`nested_fit_resamples()`](https://nestedtune.tidymodels.org/reference/nested_fit_resamples.md),
[`collect_metrics.nested_results_set()`](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results_set.md),
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
[`workflowsets::workflow_map()`](https://workflowsets.tidymodels.org/reference/workflow_map.html)

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
# One tuned workflow and one baseline, on the same nested design.
wset <- workflowsets::workflow_set(
  preproc = list(pca = rec, none = recipes::recipe(mpg ~ ., data = mtcars)),
  models = list(lm = parsnip::linear_reg())
)

set.seed(2)
res <- nested_workflow_map(wset, resamples = folds, grid = data.frame(num_comp = 1:2))
res
#> 
#> ── Nested cross-validation results for a workflow set ─────────────────
#> Orchestrator: `nested_tune_grid()` (grid search)
#> Workflows: 2
#> ✔ "pca_lm": 2 of 2 outer folds completed (grid search)
#> ✔ "none_lm": 2 of 2 outer folds completed (no tuning)
#> ℹ Use `collect_metrics()` for every workflow's estimate under its id,
#>   and `x$result[[i]]` for one workflow's run.
collect_metrics(res)
#> # A tibble: 4 × 6
#>   wflow_id .metric .estimator  mean     n std_err
#>   <chr>    <chr>   <chr>      <dbl> <int>   <dbl>
#> 1 pca_lm   rmse    standard   2.98      2  0.459 
#> 2 pca_lm   rsq     standard   0.747     2  0.0691
#> 3 none_lm  rmse    standard   5.93      2  2.06  
#> 4 none_lm  rsq     standard   0.495     2  0.119 

# The baseline ran through nested_fit_resamples(), whatever fn named.
extract_procedure(res$result[[2]])$tuner
#> [1] "fit_resamples"
```
