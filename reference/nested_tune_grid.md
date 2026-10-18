# Nested cross-validation with a grid search inside

`nested_tune_grid()` estimates how well a model tuned with
[`tune::tune_grid()`](https://tune.tidymodels.org/reference/tune_grid.html)
performs on new data. Each outer fold tunes on its own inner resamples,
fits the chosen candidate on its analysis set, and scores it on the rows
it held out.

## Usage

``` r
nested_tune_grid(object, ...)

# Default S3 method
nested_tune_grid(object, ...)

# S3 method for class 'model_spec'
nested_tune_grid(
  object,
  preprocessor,
  resamples,
  ...,
  param_info = NULL,
  grid = 10,
  metrics = NULL,
  event_level = "first",
  eval_time = NULL,
  select = selection_rule()
)

# S3 method for class 'workflow'
nested_tune_grid(
  object,
  resamples,
  ...,
  param_info = NULL,
  grid = 10,
  metrics = NULL,
  event_level = "first",
  eval_time = NULL,
  select = selection_rule()
)
```

## Arguments

- object:

  A
  [`workflows::workflow()`](https://workflows.tidymodels.org/reference/workflow.html)
  with at least one parameter marked with
  [`tune::tune()`](https://hardhat.tidymodels.org/reference/tune.html),
  or a parsnip model specification.

- ...:

  On the generic, the arguments of the method. On a method, pass
  `control = tune::control_grid()` here to set the control. Name every
  argument after `...`.

- preprocessor:

  A formula or recipe, when `object` is a model specification.

- resamples:

  A nested resampling design from
  [`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md)
  or
  [`rsample::nested_cv()`](https://rsample.tidymodels.org/reference/nested_cv.html).

- param_info:

  A
  [`dials::parameters()`](https://dials.tidymodels.org/reference/parameters.html)
  object or `NULL`. If none is given, a parameters set is derived from
  other arguments. Passing this argument can be useful when parameter
  ranges need to be customized.

- grid:

  A data frame of tuning combinations or a positive integer. The data
  frame should have columns for each parameter being tuned and rows for
  tuning parameter candidates. An integer denotes the number of
  candidate parameter sets to be created automatically.

- metrics:

  A
  [`yardstick::metric_set()`](https://yardstick.tidymodels.org/reference/metric_set.html),
  or `NULL` for tune's default set. Under every rule but
  `"desirability"`, the first metric selects each fold's candidate, so
  put the metric you report first. The Bayes, race and annealing
  searches also steer on it. Every metric is scored on the outer folds.

- event_level:

  `"first"` (the default) or `"second"`. It names which level of a
  two-class outcome is the event. It applies to the inner tuning run and
  the outer scoring fit alike.

- eval_time:

  A numeric vector of evaluation times for a censored regression model,
  or `NULL` (the default) to leave the choice to tune. Times that are
  not numeric, empty, missing, negative or not finite are an error.
  Zero, repeated and unordered times are passed on to tune.

- select:

  A
  [`selection_rule()`](https://nestedtune.tidymodels.org/reference/selection_rule.md)
  that each outer fold uses to pick its candidate. The default is
  [`tune::select_best()`](https://tune.tidymodels.org/reference/show_best.html)
  on the first metric.

## Value

A tibble of class `nested_results` with one row per outer fold. Beside
the fold's split and labels, each row holds:

- `.metrics`, the metrics scored on the fold's assessment set.

- `.selected`, the candidate the fold's inner tuning chose.

- `.inner_metrics`, the inner run's metrics for every candidate that
  scored. A fold that scored no candidate holds a zero-row table, never
  `NULL`. tune can reach fewer candidates than a `grid` size asks for,
  so `attr(res, "grid")`, the argument as given, can differ from these
  rows.

- `.completed`, whether the fold finished, and `.notes`, what went
  wrong.

- `.tuning_seed` and `.outer_fit_seed`, the fold's two seeds.

Use
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
for the estimate. [`summary()`](https://rdrr.io/r/base/summary.html),
[`collect_selections()`](https://nestedtune.tidymodels.org/reference/collect_selections.md),
[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md)
and
[autoplot()](https://nestedtune.tidymodels.org/reference/autoplot.nested_results.md)
show it in other ways.

`arrange()`, `mutate()` adding a column, and a join that matches one row
per fold keep the class. Removing a fold or a column above returns a
plain tibble, because the result no longer describes the design that
ran. So do `slice()`, `bind_rows()` of two results, and
`vctrs::vec_rbind(x)` alone. `bind_cols()` keeps the class only with the
result as its first argument. `group_by()`, `rowwise()` and
[`tibble::as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)
return their own classes and keep the attributes. A column you add is
read as a fold label only when the design itself carries a column of
that name.

## Details

For each outer fold, the function calls
[`tune::tune_grid()`](https://tune.tidymodels.org/reference/tune_grid.html)
on the fold's inner resamples and picks a candidate with `select`. It
finalizes the workflow with that candidate. Then
[`tune::last_fit()`](https://tune.tidymodels.org/reference/last_fit.html)
fits the workflow on the fold's analysis set and scores it on the
assessment set.

The estimate from
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
describes this whole procedure (tune, select, fit) and not one fitted
model. To get a model to deploy, call
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
which runs the same procedure on all the data. The nested estimate is
the number to report for that model, because the model comes from the
same procedure.

[`nested_tune_bayes()`](https://nestedtune.tidymodels.org/reference/nested_tune_bayes.md),
[`nested_tune_race_anova()`](https://nestedtune.tidymodels.org/reference/nested_tune_race.md),
[`nested_tune_race_win_loss()`](https://nestedtune.tidymodels.org/reference/nested_tune_race.md)
and
[`nested_tune_sim_anneal()`](https://nestedtune.tidymodels.org/reference/nested_tune_sim_anneal.md)
run the same loop with another search.
[`nested_fit_resamples()`](https://nestedtune.tidymodels.org/reference/nested_fit_resamples.md)
runs it for a workflow with nothing to tune. This page documents what
they share.

`object` can also be a parsnip model specification, given with a
`preprocessor`, as in `nested_tune_grid(spec, preprocessor, resamples)`.

## Nested designs

`resamples` has one row per outer fold: a `splits` column of outer
splits, an `inner_resamples` column of inner rsets, and id columns. The
function checks the design before it fits anything. An outer bootstrap
is an error, and so are
[`rsample::loo_cv()`](https://rsample.tidymodels.org/reference/loo_cv.html),
[`rsample::apparent()`](https://rsample.tidymodels.org/reference/apparent.html)
and
[`rsample::permutations()`](https://rsample.tidymodels.org/reference/permutations.html)
in either loop. An inner split that reaches a row its outer fold holds
out is an error too. Each error names the design, or the rows, splits or
folds at fault.

Time-series designs work as well. `nested_tune_grid()` is tested with an
outer
[`rsample::rolling_origin()`](https://rsample.tidymodels.org/reference/rolling_origin.html),
[`rsample::sliding_window()`](https://rsample.tidymodels.org/reference/slide-resampling.html),
[`rsample::sliding_index()`](https://rsample.tidymodels.org/reference/slide-resampling.html)
or
[`rsample::sliding_period()`](https://rsample.tidymodels.org/reference/slide-resampling.html)
design and an inner design of any of those four kinds. Leave the `lag`
of
[`rsample::rolling_origin()`](https://rsample.tidymodels.org/reference/rolling_origin.html)
at 0, because a larger `lag` is an error.
[`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md)
says which of these designs the other functions are tested on.

## Finalizing a parameter range

A range that depends on the data, such as `mtry()`, is finalized on each
outer fold's analysis set, never on the rows that fold holds out.
[`nested_tune_bayes()`](https://nestedtune.tidymodels.org/reference/nested_tune_bayes.md)
is the exception:
[`tune::tune_bayes()`](https://tune.tidymodels.org/reference/tune_bayes.html)
does not finalize such a range, so set it in `param_info`, or every fold
fails.
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
finalizes it on all the data. A range set in `param_info` applies to
every fold.

## Evaluation times

The inner tuning and the outer scoring both use the times in
`eval_time`. If the metric set has no dynamic or integrated survival
metric, tune ignores the times with a warning. Each fold selects at the
first of these times.

## Weighting the outer folds

Weights set on the design with
[`tune::add_resample_weights()`](https://tune.tidymodels.org/reference/add_resample_weights.html)
give a weighted average of the outer folds' estimates, as tune computes
it. A fold that fails or scores `NA` is left out, and the other weights
are scaled to sum to one.

## Reproducibility

Call [`set.seed()`](https://rdrr.io/r/base/Random.html) before the
function, as elsewhere in tidymodels. Each fold takes its seeds from
that one seed by its position, so the result is the same serially and in
parallel. The seeds are kept as `.tuning_seed` and `.outer_fit_seed`.
The function restores your random state on exit, even after an error. So
two calls with no [`set.seed()`](https://rdrr.io/r/base/Random.html)
between them give the same result, as repeated
[`tune::tune_grid()`](https://tune.tidymodels.org/reference/tune_grid.html)
calls do.

This covers randomness that flows through R's generator. Engines that
randomize outside it (kernlab's SVMs, the deep-learning engines) cannot
be pinned by any R-side scheme, here or in tune.

## Reproducing one fold

Fold `i` runs the code below. On a
[`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md)
design, `inner` is the fold's inner rset re-pointed at
`rsample::analysis(resamples$splits[[i]])`. Under another `select`, the
selection line uses
[`tune::select_by_one_std_err()`](https://tune.tidymodels.org/reference/show_best.html)
or
[`tune::select_by_pct_loss()`](https://tune.tidymodels.org/reference/show_best.html).
A Bayesian fold also sets `control$seed` to the fold's tuning seed.

    set.seed(res$.tuning_seed[[i]], kind = "Mersenne-Twister",
             normal.kind = "Inversion", sample.kind = "Rejection")
    tuned <- tune_grid(object, inner, grid = grid,
                       param_info = param_info, metrics = metrics,
                       eval_time = eval_time,
                       control = extract_procedure(res)$control)
    final <- finalize_workflow(object, select_best(tuned, metric = <first metric>))
    set.seed(res$.outer_fit_seed[[i]], kind = "Mersenne-Twister",
             normal.kind = "Inversion", sample.kind = "Rejection")
    last_fit(final, resamples$splits[[i]], metrics = metrics,
             eval_time = eval_time,
             control = control_last_fit(event_level = event_level))

## When a fold fails

A fold that fails does not stop the run. Its `.completed` is `FALSE` and
its `.notes` says which stage failed and why. The run warns at the end,
and
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
summarizes only the folds that completed. If no fold completed,
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
gives an error.

## Parallel execution

The outer folds run in parallel when two or more mirai daemons are
running, and serially otherwise. Inner tuning always runs serially.

    mirai::daemons(4)
    res <- nested_tune_grid(wf, folds, grid = grid)
    mirai::daemons(0)

The daemons load nestedtune from an installed library, and they do not
inherit your session's options. Set what a fold needs with
[`mirai::everywhere()`](https://mirai.r-lib.org/reference/everywhere.html).
Under `devtools::load_all()`, the daemons cannot see your development
code, so run `mirai::everywhere(pkgload::load_all("<path>"))` first. A
running daemon keeps the version it loaded, so restart the pool after
you reinstall.

Before it sends the folds out, the function checks that every daemon can
load the packages the run needs. The check waits up to 30 seconds, and
`options(nestedtune.preflight_timeout = <ms>)` changes that limit. The
folds themselves have no time limit. If every daemon dies after
dispatch, the call waits until you interrupt it.

Each fold is sent one copy of the data. A workflow built inside a
function carries that function's environment to every fold, so build it
at the top level. On a pool with mirai's default dispatcher, an
interrupt cancels the folds that are still running. A pool started with
`dispatcher = FALSE` cannot be cancelled, and the call warns about that.

## Differences from calling tune directly

A
[`tune::control_grid()`](https://tune.tidymodels.org/reference/control_grid.html)
passed through `...` as `control` reaches the inner `tune_grid()` in
every fold. The outer fit runs under its own `control_last_fit()`, and
takes only `event_level`, `save_pred` and `extract` from the control.
The result keeps the control that ran as
`extract_procedure(res)$control`, and
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
runs again with it. Its settings differ from a direct `tune_grid()` call
as follows.

**Forced: `allow_par`.** The inner tuning run and the outer fit run with
`allow_par = FALSE`, because the outer folds carry the parallelism.

**Settable as its own argument: `event_level`.** Set the level with the
`event_level` argument, which reaches the inner run and the outer fit. A
control that names a level other than tune's default or the argument's
is an error. `eval_time` is an argument of `tune_grid()` too, not a
control setting.

**Refused: none.** No setting is refused on its own. A control of
another class is an error, even a `control_bayes()` that tune itself
accepts.

tune gives
[`tune::control_resamples()`](https://tune.tidymodels.org/reference/control_grid.html)
and
[`tune::control_last_fit()`](https://tune.tidymodels.org/reference/control_last_fit.html)
the `control_grid` class, so both are accepted here.

**Passed through: `verbose`, `pkgs`, `parallel_over`, `workflow_size`.**
Each reaches `tune_grid()` as given. `parallel_over` still sets the seed
each model fit starts from, so a stochastic engine's numbers depend on
it.

**Kept from the outer fit: `save_pred`, `extract`.** With
`save_pred = TRUE`, the result has a `.predictions` column of each
fold's outer predictions. With an `extract` function, it has an
`.extracts` column. The inner run's predictions and extracts are still
discarded.
[`collect_predictions()`](https://nestedtune.tidymodels.org/reference/collect_predictions.nested_results.md)
and
[`collect_extracts()`](https://nestedtune.tidymodels.org/reference/collect_predictions.nested_results.md)
read the two columns.

**Not returned: `save_workflow`.** The inner tuning results are not
kept, so this setting returns nothing. Use `extract = function(x) x` to
keep each fold's fitted workflow.

**Inert: `backend_options`.** Options for a parallel backend, with no
backend to reach at `allow_par = FALSE`.

## See also

[`nested_tune_bayes()`](https://nestedtune.tidymodels.org/reference/nested_tune_bayes.md),
[`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md),
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
[`tune::tune_grid()`](https://tune.tidymodels.org/reference/tune_grid.html)

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
collect_metrics(res)
#> # A tibble: 2 × 5
#>   .metric .estimator  mean     n std_err
#>   <chr>   <chr>      <dbl> <int>   <dbl>
#> 1 rmse    standard   2.98      2  0.459 
#> 2 rsq     standard   0.747     2  0.0691

# What each fold chose. Folds that disagree show the choice is unstable.
res$.selected
#> [[1]]
#> # A tibble: 1 × 2
#>   num_comp .config        
#>      <int> <chr>          
#> 1        1 pre1_mod0_post0
#> 
#> [[2]]
#> # A tibble: 1 × 2
#>   num_comp .config        
#>      <int> <chr>          
#> 1        1 pre1_mod0_post0
#> 
```
