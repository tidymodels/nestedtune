# Run every workflow of a workflow set through one nested design

`nested_workflow_map()` takes a
[`workflowsets::workflow_set()`](https://workflowsets.tidymodels.org/reference/workflow_set.html)
and the name of one of the six orchestrators, and runs each workflow of
the set, in the set's order, through that orchestrator on one nested
design. It is shaped like
[`workflowsets::workflow_map()`](https://workflowsets.tidymodels.org/reference/workflow_map.html):
the orchestrator's arguments come through `...`, and an entry in the
set's `option` column overrides the same-named argument for that
workflow alone. It returns a `nested_results_set`, a tibble with one row
per workflow holding its id, the workflow and its `nested_results`, so
the comparison a user makes across model families reads off one object
with the workflow id beside the fold labels.

## Usage

``` r
nested_workflow_map(object, fn = "nested_tune_grid", ...)
```

## Arguments

- object:

  A
  [`workflowsets::workflow_set()`](https://workflowsets.tidymodels.org/reference/workflow_set.html):
  one workflow per row, untrained, with `wflow_id`, `info`, `option` and
  `result` columns as
  [`workflowsets::workflow_set()`](https://workflowsets.tidymodels.org/reference/workflow_set.html)
  and
  [`workflowsets::as_workflow_set()`](https://workflowsets.tidymodels.org/reference/as_workflow_set.html)
  build them. The `result` column is not read: this function returns its
  results as its own object rather than filling the set's column.

- fn:

  The name of the orchestrator to run each workflow through, one of
  `"nested_tune_grid"` (the default), `"nested_tune_bayes"`,
  `"nested_tune_race_anova"`, `"nested_tune_race_win_loss"`,
  `"nested_tune_sim_anneal"` or `"nested_fit_resamples"`. The package's
  own names, not tune's.

- ...:

  The orchestrator's arguments, every one named: the nested design as
  `resamples` (required), and any of that orchestrator's other arguments
  – `grid`, `param_info`, `metrics`, `event_level`, `eval_time`,
  `select`, `iter`, `initial`, `objective` – and a `control` as it takes
  one through its own `...`. An entry of the set's `option` column
  overrides the same-named argument for its workflow. A name the
  orchestrator `fn` names does not take is refused, as is an unnamed
  argument and a call with no `resamples`.

## Value

A `nested_results_set`: a tibble of class
`c("nested_results_set", "tbl_df", "tbl", "data.frame")` with one row
per workflow in the set's order and three columns, `wflow_id` (the set's
id), `workflow` (the workflow, as the set held it) and `result` (its
`nested_results`, as the orchestrator that ran returned it), with `fn`
kept as an attribute. It does not carry the `workflow_set` class, so
[`workflowsets::rank_results()`](https://workflowsets.tidymodels.org/reference/rank_results.html)
and
[`tune::fit_best()`](https://tune.tidymodels.org/reference/fit_best.html)
refuse it: a ranking of the set's workflows by their nested estimates,
and a fit of the best, would be a selection the outer loop did not nest
(see
[`vignette("estimate")`](https://nestedtune.tidymodels.org/articles/estimate.md)).
What it answers:
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html),
[`collect_selections()`](https://nestedtune.tidymodels.org/reference/collect_selections.md),
[`collect_inner_metrics()`](https://nestedtune.tidymodels.org/reference/collect_selections.md),
[`collect_notes()`](https://tune.tidymodels.org/reference/collect_predictions.html),
[collect_predictions()](https://nestedtune.tidymodels.org/reference/collect_predictions.nested_results.md)
and
[collect_extracts()](https://nestedtune.tidymodels.org/reference/collect_predictions.nested_results.md)
stack each workflow's table under a `wflow_id` column;
[`extract_workflow()`](https://hardhat.tidymodels.org/reference/hardhat-extract.html)
with an `id` returns one workflow;
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
with an `id` fits one workflow by its own record; and
[`print()`](https://rdrr.io/r/base/print.html) shows the orchestrator
and each workflow's completed fold count.

## Routing

A workflow with no parameter marked by
[`tune::tune()`](https://hardhat.tidymodels.org/reference/tune.html)
runs through
[`nested_fit_resamples()`](https://nestedtune.tidymodels.org/reference/nested_fit_resamples.md)
whatever `fn` names, since the five tuning orchestrators refuse it at
entry: a baseline beside tuned models on the same folds is the
comparison a set exists for, and each element's record names the
procedure that ran. Every other workflow runs through `fn`. For each
workflow the merged arguments are narrowed to what its orchestrator
accepts – its formals other than `object`, and, for a workflow that runs
through `fn`, the `control` in `...` – so a `grid` in `...` reaches the
tuned workflows and not the fixed one. A control's class is `fn`'s own,
and
[`nested_fit_resamples()`](https://nestedtune.tidymodels.org/reference/nested_fit_resamples.md)
refuses a racing, Bayesian or annealing control by that class, so a
fixed workflow routed there does not take the `control` in `...`: it
runs under tune's default
[`tune::control_resamples()`](https://tune.tidymodels.org/reference/control_grid.html)
unless its `option` entry names one, which is where a `save_pred` or
`extract` for the baseline goes. A name that the orchestrator `fn` names
does not take is refused at entry (a typo would otherwise be narrowed
away for every workflow); a name in a workflow's `option` entry that the
orchestrator it routes to does not take is refused naming the workflow.
Under `fn = "nested_fit_resamples"` every workflow must be fixed: one
carrying a marker is refused at entry, naming it, as that orchestrator
refuses it.

## Seeds

Seed the session before the call, as before any orchestrator. The
generator state the call holds once its entry checks have run is
reinstated before each workflow, so every workflow's fold `i` runs under
the same two seeds and each element is
[`identical()`](https://rdrr.io/r/base/identical.html) to the
orchestrator called by hand on that workflow, with the same arguments,
after the same [`set.seed()`](https://rdrr.io/r/base/Random.html). Under
a stochastic engine the workflows are therefore paired on seeds as well
as on folds. The caller's state is put back on exit, and a session that
had never drawn is left with no state, as it was found. Each element
runs its folds in parallel exactly as its orchestrator does: a running
mirai pool is used for every workflow's folds, one round of folds per
workflow.

## Warnings from one workflow

An orchestrator warns when some of its outer folds failed, and a reader
warns when it summarizes a partial run. Inside a set those warnings are
raised with the workflow's id at the front of the message, under the
same condition class, so a user who never calls a reader still learns
which workflow lost folds. An error an orchestrator raises for one
workflow – a `grid` that names a parameter that workflow does not tune,
a control of the wrong class – is raised the same way, when that
workflow's turn comes; the workflows before it have run by then.

## See also

[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
[`nested_fit_resamples()`](https://nestedtune.tidymodels.org/reference/nested_fit_resamples.md),
[`collect_metrics.nested_results_set()`](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results_set.md),
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
[`workflowsets::workflow_map()`](https://workflowsets.tidymodels.org/reference/workflow_map.html)

## Examples

``` r
data(mtcars)

# One tuned workflow and one baseline, on the same nested design.
rec <- recipes::recipe(mpg ~ ., data = mtcars)
tuned <- recipes::step_pca(rec, recipes::all_predictors(), num_comp = tune::tune())
wset <- workflowsets::workflow_set(
  preproc = list(pca = tuned, none = rec),
  models = list(lm = parsnip::linear_reg())
)

set.seed(1)
folds <- nested_resamples(
  mtcars,
  outside = rsample::vfold_cv(v = 3),
  inside = rsample::vfold_cv(v = 3)
)

set.seed(2)
res <- nested_workflow_map(
  wset,
  resamples = folds,
  grid = data.frame(num_comp = 1:3)
)
res
#> 
#> ── Nested cross-validation results for a workflow set ─────────────────
#> Orchestrator: `nested_tune_grid()` (grid search)
#> Workflows: 2
#> ✔ "pca_lm": 3 of 3 outer folds completed (grid search)
#> ✔ "none_lm": 3 of 3 outer folds completed (no tuning)
#> ℹ Use `collect_metrics()` for every workflow's estimate under its id,
#>   and `x$result[[i]]` for one workflow's run.
collect_metrics(res)
#> # A tibble: 4 × 6
#>   wflow_id .metric .estimator  mean     n std_err
#>   <chr>    <chr>   <chr>      <dbl> <int>   <dbl>
#> 1 pca_lm   rmse    standard   3.23      3   0.316
#> 2 pca_lm   rsq     standard   0.722     3   0.112
#> 3 none_lm  rmse    standard   3.31      3   0.565
#> 4 none_lm  rsq     standard   0.703     3   0.113

# The baseline ran through nested_fit_resamples(), whatever fn named.
extract_procedure(res$result[[2]])$tuner
#> [1] "fit_resamples"
```
