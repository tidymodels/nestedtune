# Score a workflow with nothing to tune on a nested design

`nested_fit_resamples()` gives you the score of a workflow with nothing
to tune on the same outer folds a tuned workflow scores on. It runs the
outer loop of a nested design with the inner stage skipped, since there
is nothing to search. For each outer fold it fits the workflow on the
fold's analysis set and scores it on the assessment set with
[`tune::last_fit()`](https://tune.tidymodels.org/reference/last_fit.html).
It is
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
with the inner tuner removed. So a fixed workflow and a tuned one score
on identical outer folds, and their per-fold metrics join by fold label.
That page is the reference for everything the orchestrators share.

Use it for the baseline a tuned procedure is compared against. A plain
`rset` of outer folds is what
[`tune::fit_resamples()`](https://tune.tidymodels.org/reference/fit_resamples.html)
already serves; what this function adds is the same nested design, so
the two runs' folds are the same rows.

## Usage

``` r
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
  with no parameter marked for tuning with
  [`tune::tune()`](https://hardhat.tidymodels.org/reference/tune.html),
  every value fixed as
  [`tune::fit_resamples()`](https://tune.tidymodels.org/reference/fit_resamples.html)
  takes it. A workflow carrying a marker is refused at entry.

- resamples:

  A nested resampling design from
  [`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md)
  or
  [`rsample::nested_cv()`](https://rsample.tidymodels.org/reference/nested_cv.html),
  one row per outer fold. The section on nested designs says what the
  design must hold.

- ...:

  A control object from
  [`tune::control_resamples()`](https://tune.tidymodels.org/reference/control_grid.html),
  as `control`, and nothing else; every argument after `...` is matched
  by name. The section on differences from tune says what becomes of
  each slot.

- metrics:

  A
  [`yardstick::metric_set()`](https://yardstick.tidymodels.org/reference/metric_set.html),
  or `NULL` to use tune's defaults for the model's mode. There is no
  inner run to select on, so the set's order carries no weight here.

- event_level:

  `"first"` (the default) or `"second"`, naming which level of a
  two-class outcome is the event in the one tune call a fold makes, the
  outer scoring fit.

- eval_time:

  A numeric vector of evaluation times for a censored regression model,
  or `NULL` (the default) to leave the choice to tune. Anything not
  numeric, an empty vector, or an element that is missing, negative or
  not finite is refused at entry.

## Value

A `nested_results` with one row per outer fold and the columns
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
documents, three of them holding what no tuning leaves. `.selected` is a
zero-row, zero-column tibble on every completed fold and `NULL` on a
failed one. `.inner_metrics` is a zero-row table with tune's summary
columns and no parameter column. `.tuning_seed` holds the seed the loop
drew for the fold's tuning step, consumed by nothing. There is no `grid`
attribute. The `procedure` record names the tuner `"fit_resamples"`, and
holds no grid, parameter set or selection rule.

## One door for a fixed workflow, one for a tuned one

A workflow that still carries a
[`tune::tune()`](https://hardhat.tidymodels.org/reference/tune.html)
marker is refused at entry with condition class
`nestedtune_tuned_workflow`, naming the five orchestrators that tune.
Each of those refuses a workflow with no marker, with class
`nestedtune_untuned_workflow`, naming this one.

The final fit ties the workflow to the record as well. The result
records the identity of the workflow it ran under, and
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
refuses a workflow whose identity differs, as its "What is refused"
section says.

## What the reading functions answer

Every function that reads a `nested_results` answers on the result.
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html),
[`summary()`](https://rdrr.io/r/base/summary.html),
[`print()`](https://rdrr.io/r/base/print.html),
[`collect_notes()`](https://tune.tidymodels.org/reference/collect_predictions.html),
[collect_predictions()](https://nestedtune.tidymodels.org/reference/collect_predictions.nested_results.md)
and
[collect_extracts()](https://nestedtune.tidymodels.org/reference/collect_predictions.nested_results.md)
read what the outer fits produced.
[`collect_selections()`](https://nestedtune.tidymodels.org/reference/collect_selections.md),
[`collect_inner_metrics()`](https://nestedtune.tidymodels.org/reference/collect_selections.md)
and
[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md)
return zero rows. `autoplot(type = "performance")` draws the fold
scores, where `autoplot(type = "parameters")` refuses with class
`nestedtune_no_tuned_parameters`, there being nothing to draw.
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
accepts the result and fits the workflow on every row, with no tuning
run.

## Reproducibility

Seed the session before the call, as elsewhere in tidymodels; there is
no `seed` argument. On entry the function draws `2 * n` seeds in a
single `sample.int(.Machine$integer.max, 2 * n)` call, where `n` is the
number of outer folds. Fold `i` uses element `2 * i - 1` for its tuning
step and element `2 * i` for its outer fit, each applied with the
generator kind pinned. A fold's seed depends on its position, not on the
order the folds run in. So the same seed gives the same result serially
and in parallel, at any number of daemons. The two seeds are kept on the
result as `.tuning_seed` and `.outer_fit_seed`, and
[`?nested_tune_grid`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
shows how to reproduce one fold by hand from them.

The caller's RNG state and generator kind are restored on exit,
including when the call errors, so a seeded script that draws afterwards
is unaffected. One consequence: two consecutive calls with no
[`set.seed()`](https://rdrr.io/r/base/Random.html) between them return
identical results, exactly as repeated
[`tune::tune_grid()`](https://tune.tidymodels.org/reference/tune_grid.html)
calls do.

This binds randomness that flows through R's generator. Engines that
randomize outside it (kernlab's SVMs, the deep-learning engines) cannot
be pinned by any R-side scheme, here or in tune.

## The two seeds on a run with no tuning

A tuned run under the same session seed on the same design shares each
fold's outer-fit seed with this one. The same `2 * n` seeds are drawn as
on a tuned run. The record keeps one layout across the six
orchestrators. The tuning seed is drawn and consumed by nothing. It is
recorded as drawn rather than as `NA`, so the two seed columns read the
same on every result. Fold `i` is exactly
[`tune::last_fit()`](https://tune.tidymodels.org/reference/last_fit.html)
of `object` on `resamples$splits[[i]]` under `res$.outer_fit_seed[[i]]`,
with no tuning line before it. The seed is applied as the grid page
shows.

## Differences from calling tune directly

There is no `control` formal. A
[`tune::control_resamples()`](https://tune.tidymodels.org/reference/control_grid.html)
passed through `...` as `control` is recorded, and two of its slots
reach the outer fit. What is recorded is the control passed, or tune's
default when none is, with the slots this package forces overwritten, as
`extract_procedure(res)$control`. tune gives `control_resamples()`,
[`tune::control_grid()`](https://tune.tidymodels.org/reference/control_grid.html)
and
[`tune::control_last_fit()`](https://tune.tidymodels.org/reference/control_last_fit.html)
one class, so any of the three is accepted here as the same object.

Every slot of `control_resamples()` falls under one of seven headings,
most under the last. The one tune call a fold makes here is the outer
scoring fit, whose own control this package builds.

**Forced: `allow_par`.** The outer fit runs at `allow_par = FALSE`
whatever the control carries, since parallelism belongs over the outer
folds.

**Settable as its own argument: `event_level`.** The argument is the one
place the level is set. A control at tune's default takes it. A control
naming another level is refused at entry, and the refusal names both
levels. `eval_time` is offered the same way, for the same reason.

**Refused: none.** No slot is refused on its own. A control of another
class, such as a `control_bayes()`, is refused at entry, as is the
`event_level` conflict above.

**Passed through: none.** There is no inner tuning call for a slot to be
passed through to.

**Kept from the outer fit: `save_pred`, `extract`.** With
`save_pred = TRUE` the result carries a `.predictions` list column: each
completed fold's predictions on its assessment rows, as
[`tune::last_fit()`](https://tune.tidymodels.org/reference/last_fit.html)
returns them. With `extract` a function, it carries an `.extracts` list
column holding the function's value on each completed fold's fitted
workflow. Here there is no inner run whose predictions and extracts are
discarded. The outer fit's are the only ones, and they are still
discarded on a run that did not ask.

**Not returned: none.** Nothing an inner run would have saved exists to
be withheld.

**Inert: `verbose`, `pkgs`, `save_workflow`, `parallel_over`,
`backend_options`, `workflow_size`.** Each governs an inner tuning call
this function never makes. The outer fit runs under
[`tune::control_last_fit()`](https://tune.tidymodels.org/reference/control_last_fit.html)
at the level and parallelism above, which reads none of these. The
workflow's packages are required at entry, and the fitted workflow is
reached through `extract`.

## Nested designs

`resamples` is a data frame with one row per outer fold. Its `splits`
column holds that fold's `rsplit`, its `inner_resamples` column holds an
`rset` with at least one row, and every other column labels the fold. A
label column is named `id`, or `id` followed by a digit from 1 to 9, and
holds character or factor values. Together the label columns give every
outer fold a distinct label with no `NA`.

Inside each inner `rset`, every element of `splits` is an `rsplit`. All
of a fold's inner splits carry one data frame: either the outer split's
own frame, as
[`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md)
builds, or that split's analysis set, as
[`rsample::nested_cv()`](https://rsample.tidymodels.org/reference/nested_cv.html)
builds. An inner split carrying the outer frame may index only rows the
outer split's `in_id` holds, in its `in_id` and any non-`NA` `out_id`.
So no inner analysis or assessment set reaches a row the outer fold
holds out.

A design breaking any of this, or using a bootstrap for the outer loop,
is refused before anything is fitted. The error has condition class
`nestedtune_bad_design` and names every offending row, column, inner
split or index. The checks exist because
[`rsample::nested_cv()`](https://rsample.tidymodels.org/reference/nested_cv.html)
builds a design whatever its `inside` argument returned, and because a
design assembled by hand can index rows its outer fold never sees.

## See also

[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
[`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md),
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
[`tune::fit_resamples()`](https://tune.tidymodels.org/reference/fit_resamples.html)

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
# A fixed workflow: no tune() marker anywhere.
fixed <- workflows::workflow(mpg ~ ., parsnip::linear_reg())

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
