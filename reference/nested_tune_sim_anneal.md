# Nested cross-validation with simulated annealing inside

`nested_tune_sim_anneal()` estimates how well a model tuned with
[`finetune::tune_sim_anneal()`](https://finetune.tidymodels.org/reference/tune_sim_anneal.html)
performs on new data. It runs the loop of
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
with simulated annealing on each outer fold's inner resamples.

## Usage

``` r
nested_tune_sim_anneal(object, ...)

# Default S3 method
nested_tune_sim_anneal(object, ...)

# S3 method for class 'model_spec'
nested_tune_sim_anneal(
  object,
  preprocessor,
  resamples,
  ...,
  iter = 10,
  param_info = NULL,
  metrics = NULL,
  initial = 1,
  event_level = "first",
  eval_time = NULL,
  select = selection_rule()
)

# S3 method for class 'workflow'
nested_tune_sim_anneal(
  object,
  resamples,
  ...,
  iter = 10,
  param_info = NULL,
  metrics = NULL,
  initial = 1,
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
  `control = finetune::control_sim_anneal()` here to set the control.
  Name every argument after `...`.

- preprocessor:

  A formula or recipe, when `object` is a model specification.

- resamples:

  A nested resampling design from
  [`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md)
  or
  [`rsample::nested_cv()`](https://rsample.tidymodels.org/reference/nested_cv.html).

- iter:

  The number of search iterations, a whole number of at least 1. `0` is
  an error, because finetune 1.3.0 runs two iterations there and not
  none.

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
  a whole number of at least 1. A `tune_results` object is an error,
  because one tuning run cannot serve every outer fold.

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
iteration scored. There is no `grid` attribute.

## Details

Each outer fold scores `initial` candidates from a space-filling design.
For `iter` iterations, it then changes the current candidate a little
and keeps the new one or goes back, by finetune's annealing rule.
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
documents what the loop functions share, such as the design, what the
estimate describes, the seeds, failed folds and parallel execution.

finetune must be installed, on each parallel daemon as well.

## Differences from calling finetune directly

A
[`finetune::control_sim_anneal()`](https://finetune.tidymodels.org/reference/control_sim_anneal.html)
passed through `...` as `control` reaches the inner search in every
fold, and
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
runs again with it. Its settings differ from a direct call as follows.

**Forced: `allow_par`.** The inner search and the outer fit run with
`allow_par = FALSE`, because the outer folds carry the parallelism.

**Settable as its own argument: `event_level`.** Set the level with the
`event_level` argument, as on
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md).
A control left at the default level, `"first"`, takes the argument's
level. A control set to another level than the argument's is an error.
`iter`, `initial` and `eval_time` are arguments of `tune_sim_anneal()`,
not control settings.

**Refused: none.** No setting is refused on its own. A control of
another class is an error.

**Passed through: `no_improve`, `restart`, `radius`, `flip`,
`cooling_coef`, `time_limit`, `verbose`, `verbose_iter`, `pkgs`,
`parallel_over`, `workflow_size`.** Each reaches `tune_sim_anneal()` as
given:

- `no_improve` and `restart` set when a search stops or starts again.
  `radius`, `flip` and `cooling_coef` set how it moves. All five act on
  each fold's search as in a direct call.

- `time_limit` is a wall-clock stop, and a wall-clock stop makes the
  candidate set depend on the machine. Two runs with the same seed can
  stop at different iterations.

- `verbose_iter`, `TRUE` by default, prints the annealing log from every
  fold of a serial run. Pass
  `control = control_sim_anneal(verbose_iter = FALSE)` for a quiet run.
  `verbose` prints from each fold as well.

`pkgs`, `parallel_over` and `workflow_size` behave as on
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md).

These settings were read from finetune 1.3.0. The oldest finetune this
package accepts can lack `workflow_size` in `control_sim_anneal()`.

**Kept from the outer fit: `save_pred`, `extract`.** As on
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
the outer fit's predictions and extracts are kept as `.predictions` and
`.extracts` when you ask for them. The inner search's own are still
discarded.

**Not returned: `save_workflow`, `save_history`.** The nested run does
not keep the inner tuning results, so `save_workflow` returns nothing
there.
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
keeps its own tuning run as `$tuning`. `save_history` writes finetune's
search history to a file in the temporary directory of the process that
tuned, and each fold overwrites the one before.

**Inert: `backend_options`.** Options for a parallel backend, with no
backend to reach at `allow_par = FALSE`.

## See also

[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
[`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md),
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
[`nested_tune_bayes()`](https://nestedtune.tidymodels.org/reference/nested_tune_bayes.md),
[`finetune::tune_sim_anneal()`](https://finetune.tidymodels.org/reference/tune_sim_anneal.html)

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
res <- nested_tune_sim_anneal(
  wf,
  folds,
  iter = 3,
  initial = 2,
  control = finetune::control_sim_anneal(verbose_iter = FALSE)
)
collect_metrics(res)
#> # A tibble: 2 × 5
#>   .metric .estimator  mean     n std_err
#>   <chr>   <chr>      <dbl> <int>   <dbl>
#> 1 rmse    standard   2.98      2  0.459 
#> 2 rsq     standard   0.747     2  0.0691

# What the first fold searched: the initial candidates at `.iter` 0,
# then one perturbation per iteration.
res$.inner_metrics[[1]]
#> # A tibble: 10 × 8
#>    num_comp .metric .estimator  mean     n std_err .config        .iter
#>       <int> <chr>   <chr>      <dbl> <int>   <dbl> <chr>          <int>
#>  1        2 rmse    standard   3.46      4 0.119   initial_pre1_…     0
#>  2        2 rsq     standard   0.737     4 0.0251  initial_pre1_…     0
#>  3        4 rmse    standard   3.24      2 0.627   initial_pre2_…     0
#>  4        4 rsq     standard   0.693     2 0.0113  initial_pre2_…     0
#>  5        3 rmse    standard   3.37      2 0.292   Iter1              1
#>  6        3 rsq     standard   0.754     2 0.00240 Iter1              1
#>  7        2 rmse    standard   3.46      4 0.119   Iter2              2
#>  8        2 rsq     standard   0.737     4 0.0251  Iter2              2
#>  9        1 rmse    standard   3.20      2 0.476   Iter3              3
#> 10        1 rsq     standard   0.772     2 0.00975 Iter3              3
```
