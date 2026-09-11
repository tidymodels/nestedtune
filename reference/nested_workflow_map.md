# Run every workflow of a workflow set through one nested design

`nested_workflow_map()` gives you nested estimates for every workflow of
a
[`workflowsets::workflow_set()`](https://workflowsets.tidymodels.org/reference/workflow_set.html)
on one nested design, so you can compare model families on the same
folds. It takes the set and the name of one of the six orchestrators,
the loop functions
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
lists. It runs each workflow of the set through that orchestrator, in
the set's order. It is shaped like
[`workflowsets::workflow_map()`](https://workflowsets.tidymodels.org/reference/workflow_map.html):
the orchestrator's arguments come through `...`, and an entry in the
set's `option` column overrides the same-named argument for that
workflow alone.

It returns a `nested_results_set`, a tibble with one row per workflow
holding its id, the workflow and its `nested_results`. A comparison
across model families then reads off one object, with the workflow id
beside the fold labels.

## Usage

``` r
nested_workflow_map(object, fn = "nested_tune_grid", ...)
```

## Arguments

- object:

  A workflow set.

- fn:

  The name of the orchestrator to run each workflow through:
  `"nested_tune_grid"` (the default), `"nested_tune_bayes"`,
  `"nested_tune_race_anova"` or `"nested_tune_race_win_loss"`.
  `"nested_tune_sim_anneal"` and `"nested_fit_resamples"` are the other
  two.

- ...:

  The orchestrator's arguments, every one named: the nested design as
  `resamples` (required), any of its other arguments, and a `control` as
  it takes one through its own `...`. A name the orchestrator `fn` names
  does not take is refused, as is an unnamed argument or a call with no
  `resamples`.

## Value

A `nested_results_set`: a tibble of class
`c("nested_results_set", "tbl_df", "tbl", "data.frame")` with one row
per workflow in the set's order and three columns. `wflow_id` is the
set's id, `workflow` the workflow as the set held it, and `result` its
`nested_results` as the orchestrator that ran returned it. `fn` is kept
as an attribute. It does not carry the `workflow_set` class, so
[`workflowsets::rank_results()`](https://workflowsets.tidymodels.org/reference/rank_results.html)
and
[`tune::fit_best()`](https://tune.tidymodels.org/reference/fit_best.html)
refuse it. A ranking of the set's workflows by their nested estimates,
and a fit of the best, makes a selection the outer loop did not nest
(see
[`vignette("estimate")`](https://nestedtune.tidymodels.org/articles/estimate.md)).

## What the set answers

Six reading functions stack each workflow's table under a `wflow_id`
column:
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html),
[`collect_selections()`](https://nestedtune.tidymodels.org/reference/collect_selections.md),
[`collect_inner_metrics()`](https://nestedtune.tidymodels.org/reference/collect_selections.md),
[`collect_notes()`](https://tune.tidymodels.org/reference/collect_predictions.html),
[collect_predictions()](https://nestedtune.tidymodels.org/reference/collect_predictions.nested_results.md)
and
[collect_extracts()](https://nestedtune.tidymodels.org/reference/collect_predictions.nested_results.md).
[`extract_workflow()`](https://hardhat.tidymodels.org/reference/hardhat-extract.html)
with an `id` returns one workflow, and
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
with an `id` fits one workflow by its own record.
[`print()`](https://rdrr.io/r/base/print.html) shows the orchestrator
and each workflow's completed fold count. The `result` column of the set
given as `object` is not read: this function returns its results as its
own object rather than filling that column.

## Routing

A workflow with no parameter marked by
[`tune::tune()`](https://hardhat.tidymodels.org/reference/tune.html)
runs through
[`nested_fit_resamples()`](https://nestedtune.tidymodels.org/reference/nested_fit_resamples.md)
whatever `fn` names, because the five tuning orchestrators refuse it at
entry. A baseline beside tuned models on the same folds is the
comparison a set exists for, and each element's record names the
procedure that ran. Every other workflow runs through `fn`.

For each workflow the merged arguments are narrowed to what its
orchestrator accepts: its formals other than `object`, and, for a
workflow that runs through `fn`, the `control` in `...`. So a `grid` in
`...` reaches the tuned workflows and not the fixed one. A control's
class is `fn`'s own, and
[`nested_fit_resamples()`](https://nestedtune.tidymodels.org/reference/nested_fit_resamples.md)
refuses a racing, Bayesian or annealing control by that class. So a
fixed workflow routed there does not take the `control` in `...`. It
runs under tune's default
[`tune::control_resamples()`](https://tune.tidymodels.org/reference/control_grid.html)
unless its `option` entry names one, which is where a `save_pred` or
`extract` for the baseline goes.

A name that the orchestrator `fn` names does not take is refused at
entry, because narrowing otherwise drops a misspelled name for every
workflow without a message. A name in a workflow's `option` entry that
the orchestrator it routes to does not take is refused naming the
workflow. Under `fn = "nested_fit_resamples"` every workflow must be
fixed. One carrying a marker is refused at entry by name, as that
orchestrator refuses it.

## Seeds

Seed the session before the call, as before any orchestrator. The
generator state the call holds after its entry checks ran is reinstated
before each workflow. So every workflow's fold `i` runs under the same
two seeds. Each element is
[`identical()`](https://rdrr.io/r/base/identical.html) to the
orchestrator called by hand on that workflow, with the same arguments,
after the same [`set.seed()`](https://rdrr.io/r/base/Random.html). Under
a stochastic engine the workflows are therefore paired on seeds as well
as on folds. The caller's state is put back on exit, and a session that
had never drawn is left with no state, as it was found. Each element
runs its folds in parallel exactly as its orchestrator does: a running
mirai pool is used for every workflow's folds, one round of folds per
workflow.

## Warnings and errors from one workflow

An orchestrator warns when some of its outer folds failed, and a reading
function warns when it summarizes a partial run. Inside a set those
warnings are raised with the workflow's id at the front of the message,
under the same condition class. So a user who never calls a reading
function still learns which workflow lost folds.

An error an orchestrator raises for one workflow is raised the same way,
when that workflow's turn comes. A `grid` that names a parameter that
workflow does not tune is one such error, and a control of the wrong
class is another. The workflows before it have run by then. What is
raised is the original condition object, with `Workflow "<id>": `
written in front of the first line of its message and this function, or
the reading function, as its call. Its class vector, its `parent` and
the cause chain, its bullets and every field a handler reads are
unchanged.

## Subsetting

You can take a subset of the set and it still answers for the workflows
it holds, because each row's `nested_results` describes its own run
whole. An operation keeps the class and the `fn` attribute when its
result:

- holds the three columns under those names, none repeated.

- has at least one row, with no `wflow_id` repeated.

- has each row's three values identical to the row of that id in the
  operation's first data-frame argument.

So rows dropped or reordered and columns added keep the class.
[`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html),
[`dplyr::arrange()`](https://dplyr.tidyverse.org/reference/arrange.html)
and
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
do, and so does
[`dplyr::bind_cols()`](https://dplyr.tidyverse.org/reference/bind_cols.html)
with the set first. So do `x[i, ]` and
[`vctrs::vec_slice()`](https://vctrs.r-lib.org/reference/vec_slice.html)
on a kept subset. What they hand back is a set whose reading functions,
[`summary()`](https://rdrr.io/r/base/summary.html),
[`print()`](https://rdrr.io/r/base/print.html),
[`extract_workflow()`](https://hardhat.tidymodels.org/reference/hardhat-extract.html)
and
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
answer for the rows in hand alone.

Anything else comes back a plain tibble without the attribute. That
covers a record column dropped or renamed, no row left, and a `wflow_id`
repeated, as by `x[c(1, 1), ]`, `rbind(x, x)` or
`dplyr::bind_rows(x, x)`. It also covers a row that is not the run's
own, whether a `result` replaced or a row bound in from another set or a
bare table. And it covers
[`dplyr::bind_cols()`](https://dplyr.tidyverse.org/reference/bind_cols.html)
with a table first, and a direct
[`vctrs::vec_cbind()`](https://vctrs.r-lib.org/reference/vec_bind.html),
which finalizes to a tibble before the rule is asked. Replacing a value
under the class with `$<-` or `[[<-` is not checked, as it is not on a
`nested_results`.
[`dplyr::group_by()`](https://dplyr.tidyverse.org/reference/group_by.html),
[`dplyr::rowwise()`](https://dplyr.tidyverse.org/reference/rowwise.html)
and
[`tibble::as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)
return a grouped, a rowwise and a plain tibble that is not a set and
still carries the `fn` attribute.

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
