# Nested cross-validation with Bayesian optimization inside

`nested_tune_bayes()` estimates how well a model tuned with
[`tune::tune_bayes()`](https://tune.tidymodels.org/reference/tune_bayes.html)
performs on new data. It runs the loop of
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
with a Bayesian search on each outer fold's inner resamples.

## Usage

``` r
nested_tune_bayes(object, ...)

# Default S3 method
nested_tune_bayes(object, ...)

# S3 method for class 'model_spec'
nested_tune_bayes(
  object,
  preprocessor,
  resamples,
  ...,
  iter = 10,
  param_info = NULL,
  metrics = NULL,
  initial = 5,
  objective = tune::exp_improve(),
  event_level = "first",
  eval_time = NULL,
  select = selection_rule()
)

# S3 method for class 'workflow'
nested_tune_bayes(
  object,
  resamples,
  ...,
  iter = 10,
  param_info = NULL,
  metrics = NULL,
  initial = 5,
  objective = tune::exp_improve(),
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
  `control = tune::control_bayes()` here to set the control. Name every
  argument after `...`.

- preprocessor:

  A formula or recipe, when `object` is a model specification.

- resamples:

  A nested resampling design from
  [`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md)
  or
  [`rsample::nested_cv()`](https://rsample.tidymodels.org/reference/nested_cv.html).

- iter:

  The maximum number of search iterations.

- param_info:

  A
  [`dials::parameters()`](https://dials.tidymodels.org/reference/parameters.html)
  object or `NULL`. If none is given, a parameters set is derived from
  other arguments. Passing this argument can be useful when parameter
  ranges need to be customized.

- metrics:

  A
  [`yardstick::metric_set()`](https://yardstick.tidymodels.org/reference/metric_set.html),
  or `NULL` for tune's default set. Under every rule but
  `"desirability"`, the first metric selects each fold's candidate, so
  put the metric you report first. The Bayes, race and annealing
  searches also steer on it. Every metric is scored on the outer folds.

- initial:

  The number of candidates each fold scores before the first iteration,
  a whole number of at least 2. A `tune_results` object is an error,
  because one tuning run cannot serve every outer fold.

- objective:

  An acquisition function from tune. It decides which candidate the
  Gaussian process proposes next:
  [`tune::exp_improve()`](https://tune.tidymodels.org/reference/prob_improve.html)
  (the default),
  [`tune::prob_improve()`](https://tune.tidymodels.org/reference/prob_improve.html)
  or
  [`tune::conf_bound()`](https://tune.tidymodels.org/reference/prob_improve.html).

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

A `nested_results`, as
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
describes. Each fold's `.inner_metrics` has an `.iter` column. It is `0`
for the initial candidates and `i` for the candidate the `i`-th
iteration proposed. There is no `grid` attribute.

## Details

Each outer fold scores `initial` candidates from a space-filling design.
A Gaussian process then proposes `iter` more candidates, one at a time.
The fold picks a candidate with `select`, fits it on its analysis set
and scores it on the rows it held out.
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
documents what the loop functions share, such as the design, what the
estimate describes, the seeds, failed folds and parallel execution.

`iter = 0` scores the initial candidates and proposes nothing. tune
stops a fold's search early when no new candidate remains, or after
`no_improve` iterations in a row without improvement (ten by default).
The fold then keeps the candidates it scored.

[`tune::tune_bayes()`](https://tune.tidymodels.org/reference/tune_bayes.html)
does not accept a parameter range that depends on the data, such as
`mtry()`. Set its range in `param_info` before the call, or every fold
fails.

## Differences from calling tune directly

A
[`tune::control_bayes()`](https://tune.tidymodels.org/reference/control_bayes.html)
passed through `...` as `control` reaches the inner `tune_bayes()` in
every fold, and
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
runs again with it. For example,
`control = control_bayes(no_improve = 5)` stops each search sooner. The
result keeps the control that ran, without `seed`, as
`extract_procedure(res)$control`. Its settings differ from a direct call
as follows.

**Forced: `allow_par`, `seed`.** `allow_par` is `FALSE`, because the
outer folds carry the parallelism. `seed` is set to the fold's tuning
seed. Left to tune, it is drawn from the random stream, so the proposals
depend on how much of the stream tune used before it.

**Settable as its own argument: `event_level`.** Set the level with the
`event_level` argument, as on
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md).
A control left at the default level, `"first"`, takes the argument's
level. A control set to another level than the argument's is an error.
`iter`, `initial`, `objective` and `eval_time` are arguments of
`tune_bayes()`, not control settings.

**Refused: none.** No setting is refused on its own. A control of
another class is an error.

**Passed through: `no_improve`, `uncertain`, `time_limit`, `verbose`,
`verbose_iter`, `save_gp_scoring`, `pkgs`, `parallel_over`,
`workflow_size`.** Each reaches `tune_bayes()` as given:

- `no_improve` and `uncertain` act on each fold's search as in a direct
  call.

- `time_limit` stops a search by the clock, so two runs with the same
  seed can differ from one machine to another.

- `verbose` and `verbose_iter` print from each fold, and only a serial
  run shows the output.

- `save_gp_scoring` writes its files to the temporary directory of the
  process that tuned the fold.

`pkgs`, `parallel_over` and `workflow_size` behave as on
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md).

**Kept from the outer fit: `save_pred`, `extract`.** As on
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
the outer fit's predictions and extracts are kept as `.predictions` and
`.extracts` when you ask for them. The inner search's own are still
discarded.

**Not returned: `save_workflow`.** The nested run does not keep the
inner tuning results, so this setting returns nothing there.
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
keeps its own tuning run as `$tuning`, which holds what the setting
saved.

**Inert: `backend_options`.** Options for a parallel backend, with no
backend to reach at `allow_par = FALSE`.

## See also

[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
[`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md),
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
[`tune::tune_bayes()`](https://tune.tidymodels.org/reference/tune_bayes.html)

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
res <- nested_tune_bayes(wf, folds, iter = 2, initial = 2)
collect_metrics(res)
#> # A tibble: 2 × 5
#>   .metric .estimator  mean     n std_err
#>   <chr>   <chr>      <dbl> <int>   <dbl>
#> 1 rmse    standard   3.06      2  0.539 
#> 2 rsq     standard   0.731     2  0.0853

# What the first fold searched: the initial candidates at `.iter` 0,
# then one proposal per iteration.
res$.inner_metrics[[1]]
#> # A tibble: 8 × 8
#>   num_comp .metric .estimator  mean     n std_err .config         .iter
#>      <int> <chr>   <chr>      <dbl> <int>   <dbl> <chr>           <int>
#> 1        2 rmse    standard   3.46      2 0.207   pre1_mod0_post0     0
#> 2        2 rsq     standard   0.737     2 0.0434  pre1_mod0_post0     0
#> 3        4 rmse    standard   3.24      4 0.362   pre2_mod0_post0     0
#> 4        4 rsq     standard   0.693     4 0.00655 pre2_mod0_post0     0
#> 5        4 rmse    standard   3.24      4 0.362   iter1               1
#> 6        4 rsq     standard   0.693     4 0.00655 iter1               1
#> 7        3 rmse    standard   3.37      2 0.292   iter2               2
#> 8        3 rsq     standard   0.754     2 0.00240 iter2               2
```
