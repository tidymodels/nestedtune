# Fit the final model after nested cross-validation

`nested_final_fit()` builds the model you deploy after a nested run. It
runs the recorded procedure, tune, select and fit, once more with the
whole dataset in hand. That means rebuilding the inner resamples on
every row, tuning with the recorded tuner, selecting by the recorded
[`selection_rule()`](https://nestedtune.tidymodels.org/reference/selection_rule.md),
and fitting the finalized workflow on all the data.

What comes back is the model to deploy. It carries no performance number
of its own. The number to report is
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
on the results object you passed in, for the reason the section on what
to report gives.

## Usage

``` r
nested_final_fit(object, results, ..., id = NULL)
```

## Arguments

- object:

  The
  [`workflows::workflow()`](https://workflows.tidymodels.org/reference/workflow.html)
  the nested run was built around, or a `nested_results_set` from
  [`nested_workflow_map()`](https://nestedtune.tidymodels.org/reference/nested_workflow_map.md)
  with `id` naming the workflow to fit. A workflow is checked against
  the record before anything is fitted.

- results:

  The `nested_results` object from
  [`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
  or one of its siblings whose estimate you will report for this model.
  Everything the re-run needs is read from it.

- ...:

  Not used; must be empty. Everything the re-run needs, the grid and the
  metrics included, now comes from `results`, so passing an argument
  here is an error.

- id:

  For a `nested_results_set` as `object`, the `wflow_id` of the workflow
  to fit; `results` is then left missing. `NULL`, the default, for a
  plain workflow.

## Value

An object of class `nested_final_fit`. Its elements are:

- `workflow`, the trained workflow. The object answers
  [predict()](https://nestedtune.tidymodels.org/reference/predict.nested_final_fit.md)
  and [`augment()`](https://generics.r-lib.org/reference/augment.html)
  directly, and
  [`extract_workflow()`](https://hardhat.tidymodels.org/reference/hardhat-extract.html)
  returns the workflow itself.

- `selected`, the parameters chosen, and `tuning`, the tuning run they
  were chosen from.

- `tuning_seed` and `fit_seed`, the two seeds that reproduce it.

- `procedure`, the record re-run, as `results` carried it.

Where nothing was tuned, `selected` is an empty table and `tuning` is
`NULL`.
[`extract_tune_results()`](https://nestedtune.tidymodels.org/reference/extract_tune_results.md)
and
[`extract_scored_candidates()`](https://nestedtune.tidymodels.org/reference/extract_scored_candidates.md)
then refuse the object with class `nestedtune_no_tuning_run`, and its
print says no tuning ran.

## Details

The procedure a nested estimate describes is "resample this dataset by
the inner specification, tune, select, fit". The dataset that procedure
is meant for is all of yours. So the final model comes from running it
again with nothing held out: the same convention as cross-validating a
model and then refitting on everything, one level up.

The outer folds play no part here. Their selections belong to the
estimate, which describes the procedure across the instability those
selections reveal. They are not pooled or voted on to build this model.

## The results object

`results` supplies the inner resampling specification the design stored,
the data every split references, the `procedure` record, and the metric
set as `attr(results, "metrics")`. The record names the tuner and that
tuner's own arguments, the grid or the iteration counts. It also holds
`param_info`, `event_level`, `eval_time` and `select`, the
[`selection_rule()`](https://nestedtune.tidymodels.org/reference/selection_rule.md)
the folds selected by.
[`extract_procedure()`](https://nestedtune.tidymodels.org/reference/extract_procedure.md)
shows you the record.

A `param_info` parameter whose range is unknown until the data is seen
is finalized here on the full data, since every row is this model's
training data. Each outer fold of the nested run finalized it on that
fold's analysis rows alone, so this model's candidate range can be wider
than any fold's.

A run in which some folds failed is still fitted. Its estimate is
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)'s,
with that function's partial-run warning.

## Fitting one workflow of a set

[`nested_workflow_map()`](https://nestedtune.tidymodels.org/reference/nested_workflow_map.md)
returns a `nested_results_set` holding each workflow beside its own
results. Pass the set as `object`, name the row with `id`, and leave
`results` missing. The fit is then
`nested_final_fit(extract_workflow(object, id), object$result[[i]])`:
the workflow and its record are read off one row, so the two cannot be
mispaired.

## What is refused

A workflow other than the one the estimate was built around is refused
here where the record names a tuner that takes a grid. `object` is then
judged against the recorded grid as
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
judged it, rather than by tune a whole tuning run later. Where nothing
was tuned (see
[`nested_fit_resamples()`](https://nestedtune.tidymodels.org/reference/nested_fit_resamples.md)),
the workflow must carry no
[`tune::tune()`](https://hardhat.tidymodels.org/reference/tune.html)
marker, and one that does is refused with class
`nestedtune_tuned_workflow`.

Three shapes of `results` are refused before any fitting, with condition
class `nestedtune_bad_results`. One carries no record: it was built by
an earlier version of nestedtune, or from a design assembled by hand
rather than by
[`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md)
or
[`rsample::nested_cv()`](https://rsample.tidymodels.org/reference/nested_cv.html).
One is no longer a `nested_results`, because an operation that added or
removed rows returned a plain tibble. And one has no rows.

A results object in which no outer fold completed is refused next, with
class `nestedtune_no_completed_folds`. There is no estimate to report
the model with, and [`summary()`](https://rdrr.io/r/base/summary.html)
lists the stage each fold failed at. That is the class
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html),
[autoplot()](https://nestedtune.tidymodels.org/reference/autoplot.nested_results.md)
and
[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md)
refuse it with.

An `id` naming no row of a set is refused with class
`nestedtune_unknown_id`. A set given with `results` supplied, a set
given with no `id`, and an `id` given beside a plain workflow are each
refused with class `nestedtune_bad_final_fit_args`.

## What to report

Report the estimate
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
returns from the results object you handed over. It describes the whole
tune-and-fit procedure that produced this model, measured on rows no
part of that procedure ever saw. It is the number to report for this
model. The model has no performance number of its own. That includes the
metrics inside the tuning run stored on it. They were computed on the
resamples that chose the candidate, so they are selection-time
quantities, optimistically biased as a claim about this model.
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
on `x$tuning` hands them over without saying so.

Expect the nested estimate to run slightly pessimistic instead, since
each outer fold trained on its analysis rows alone. Varma and Simon
(2006) measured a 4.2-point overshoot at n = 40, and Wilimitis and Walsh
(2023) about 1 to 2 percent of AUROC on 41,121 records. That offset
shrinks with fold size and is not a correction to apply.

Two things the estimate does not say. This model carries one parameter
setting, but the estimate makes no claim about that setting in
particular. It is marginal over selection: it averages over what each
fold's tuning chose. And it describes new data drawn like your training
data, not a different population, and not a model retrained at another
size.

If the outer folds disagreed about the best parameters, report that too.

## Reproducibility

Seed the session before the call; there is no `seed` argument. Two seeds
are drawn on entry and applied with the generator kind pinned: the first
builds the inner resamples and tunes, the second fits. Both are kept on
the object, and the caller's generator state is put back on the way out.
So two calls with no [`set.seed()`](https://rdrr.io/r/base/Random.html)
between them give the same model, as repeated
[`tune::tune_grid()`](https://tune.tidymodels.org/reference/tune_grid.html)
calls do.
[`?nested_tune_grid`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
covers the rest, including what an R-side seed cannot pin.

You can redo the run by hand from those two seeds and the record
[`extract_procedure()`](https://nestedtune.tidymodels.org/reference/extract_procedure.md)
returns. Every value below comes from that record, except `metrics`,
which is `attr(results, "metrics")`. Only the tuning line changes with
the tuner. `control` is the record's own: the control the run was given
or tune's default, with the slots this package forces already applied.

    set.seed(fit$tuning_seed, kind = "Mersenne-Twister",
             normal.kind = "Inversion", sample.kind = "Rejection")
    inner <- <the design's `inside` specification>(data)
    control <- extract_procedure(fit)$control
    # A grid search takes the recorded control untouched. So does a race,
    # ANOVA or win/loss: its own draws, the resample order under `randomize`,
    # come from the stream the tuning seed set.
    tuned <- tune_grid(object, inner, grid = grid, param_info = param_info,
      metrics = metrics, eval_time = eval_time, control = control)
    tuned <- tune_race_anova(object, inner, grid = grid, param_info = param_info,
      metrics = metrics, eval_time = eval_time, control = control)
    tuned <- tune_race_win_loss(object, inner, grid = grid, param_info = param_info,
      metrics = metrics, eval_time = eval_time, control = control)
    # Annealing draws its perturbations from that stream too, and
    # `control_sim_anneal()` has no seed slot, so again nothing is set.
    tuned <- tune_sim_anneal(object, inner, iter = iter, initial = initial,
      param_info = param_info, metrics = metrics, eval_time = eval_time,
      control = control)
    # Bayesian optimization is the one branch that sets a slot: its Gaussian
    # process takes the tuning seed, the rule every outer fold used, and the
    # recorded control carries no seed of its own.
    control$seed <- fit$tuning_seed
    tuned <- tune_bayes(object, inner, iter = iter, initial = initial,
      objective = objective, param_info = param_info, metrics = metrics,
      eval_time = eval_time, control = control)
    final <- finalize_workflow(object, select_best(tuned, metric = <first metric>))
      # Under the recorded default rule; select_by_one_std_err() or
      # select_by_pct_loss() with the recorded orderings and limit otherwise.
    set.seed(fit$fit_seed, kind = "Mersenne-Twister",
             normal.kind = "Inversion", sample.kind = "Rejection")
    fit(final, data)

Where nothing was tuned there is no such line to redo. Both seeds are
still drawn, so the object's seed layout is the one above. But the first
is consumed by nothing and the inner specification is left unevaluated.
The whole recipe is `fit(object, data)` under the second seed.

Building the resamples sits inside the first seed's scope rather than
before it. Constructing an `rset` draws from the generator. A version
that built them earlier would still be reproducible from the session
seed, but no longer from the two seeds above.

## The inner specification is re-evaluated

A nested design stores its `inside` argument as an unevaluated call, and
the nested run records it on its result. This function evaluates it
again, against the whole dataset, in the environment you call from
rather than the one the design was built in.

Write it with literal arguments. `inside = vfold_cv(v = 5)` is
re-evaluated identically anywhere. `inside = vfold_cv(v = k)` is not. If
`k` is gone by the time you call this you get an error naming the
specification, and if some other `k` is in scope you silently get a
different design. Building a design inside a function that parameterizes
its resampling is the common way to meet this.

## References

Varma, S., & Simon, R. (2006). Bias in error estimation when using
cross-validation for model selection. *BMC Bioinformatics*, 7, 91.

Wilimitis, D., & Walsh, C. G. (2023). Practical considerations and
applied examples of cross-validation for model development and
evaluation in health care: Tutorial. *JMIR AI*, 2, e49023.

## See also

[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
[`nested_tune_bayes()`](https://nestedtune.tidymodels.org/reference/nested_tune_bayes.md),
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
#> 
#> ℹ This model has no performance estimate of its own. Report the nested
#>   estimate from `collect_metrics()` on the results object this fit was
#>   built from, which describes the procedure that produced it.
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
