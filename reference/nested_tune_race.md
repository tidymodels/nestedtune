# Nested cross-validation with racing inside

`nested_tune_race_anova()` and `nested_tune_race_win_loss()` estimate
how well a model tuned with finetune's racing functions performs on new
data. They run the loop of
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
with a race on each outer fold's inner resamples.

## Usage

``` r
nested_tune_race_anova(object, ...)

# Default S3 method
nested_tune_race_anova(object, ...)

# S3 method for class 'model_spec'
nested_tune_race_anova(
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
nested_tune_race_anova(
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

nested_tune_race_win_loss(object, ...)

# Default S3 method
nested_tune_race_win_loss(object, ...)

# S3 method for class 'model_spec'
nested_tune_race_win_loss(
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
nested_tune_race_win_loss(
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
  `control = finetune::control_race()` here to set the control. Name
  every argument after `...`.

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

A `nested_results`, as
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
describes.

## Details

Each outer fold scores every candidate in `grid` on the first `burn_in`
inner resamples. It then drops the candidates that are clearly worse
than the best, by a repeated-measures ANOVA or by a model of pairwise
wins and losses. The rest are scored on the remaining resamples.
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
documents what the loop functions share, such as the design, what the
estimate describes, the seeds, failed folds and parallel execution.

Both functions need finetune, on each parallel daemon as well.
`nested_tune_race_anova()` also needs lme4, and
`nested_tune_race_win_loss()` needs BradleyTerry2.

Each fold's `.inner_metrics` holds every candidate its race scored,
including the ones it dropped. In that table, `n` is the number of inner
resamples each candidate was scored on, so a dropped candidate has a
smaller `n`. A candidate that failed on every inner resample is missing,
and its failure is in `.notes`. The recorded grid, `attr(res, "grid")`,
is the design the race was offered, exactly as given.

An inner design with an apparent split, such as the one
`bootstraps(apparent = TRUE)` makes, is an error here, though finetune
runs it. A race drops candidates on the score of each split, and an
apparent split is scored on the rows the model trained on. The other
tuners accept the split, because tune leaves it out of its estimates.
[`nested_workflow_map()`](https://nestedtune.tidymodels.org/reference/nested_workflow_map.md)
checks for it before its first workflow runs.

## Differences from calling finetune directly

A
[`finetune::control_race()`](https://finetune.tidymodels.org/reference/control_race.html)
passed through `...` as `control` reaches the inner race in every fold,
and
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
runs again with it. Its settings differ from a direct call as follows.

**Forced: `allow_par`.** The inner race and the outer fit run with
`allow_par = FALSE`, because the outer folds carry the parallelism.

**Settable as its own argument: `event_level`.** Set the level with the
`event_level` argument, as on
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md).
A control left at the default level, `"first"`, takes the argument's
level. A control set to another level than the argument's is an error.
`grid` and `eval_time` are the racing functions' own arguments, not
control settings.

**Refused: none.** No setting is refused on its own. A control of
another class is an error, even a `control_grid()` that finetune
accepts.

**Passed through: `burn_in`, `alpha`, `num_ties`, `randomize`,
`verbose_elim`, `verbose`, `pkgs`, `parallel_over`, `workflow_size`.**
Each reaches the race as given:

- `burn_in`, `alpha`, `num_ties` and `randomize` act on each fold's race
  as in a direct call. With `randomize = TRUE`, the default, the fold's
  tuning seed sets which resamples the burn-in uses.

- A `burn_in` that is not smaller than some fold's number of inner
  resamples is an error before any fold runs. The default `burn_in` is
  3, so a design with three inner resamples needs a `burn_in` of 2 or
  fewer.

- `verbose` and `verbose_elim` print from each fold, and only a serial
  run shows the output.

`pkgs`, `parallel_over` and `workflow_size` behave as on
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md).

These settings were read from finetune 1.3.0. The oldest finetune this
package accepts can lack `workflow_size` in `control_race()`.

**Kept from the outer fit: `save_pred`, `extract`.** As on
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
the outer fit's predictions and extracts are kept as `.predictions` and
`.extracts` when you ask for them. The inner race's own are still
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
[`nested_tune_bayes()`](https://nestedtune.tidymodels.org/reference/nested_tune_bayes.md),
[`finetune::tune_race_anova()`](https://finetune.tidymodels.org/reference/tune_race_anova.html),
[`finetune::tune_race_win_loss()`](https://finetune.tidymodels.org/reference/tune_race_win_loss.html)

## Examples

``` r
data(mtcars)

rec <- recipes::recipe(mpg ~ ., data = mtcars) |>
  recipes::step_pca(recipes::all_predictors(), num_comp = tune::tune())
wf <- workflows::workflow(rec, parsnip::linear_reg())

# A race needs more inner resamples than its burn-in, so five inner folds.
set.seed(1)
folds5 <- nested_resamples(
  mtcars,
  outside = rsample::vfold_cv(v = 2),
  inside = rsample::vfold_cv(v = 5)
)

set.seed(2)
res <- nested_tune_race_anova(
  wf,
  folds5,
  grid = data.frame(num_comp = 1:4),
  control = finetune::control_race(burn_in = 2, verbose_elim = FALSE)
)
collect_metrics(res)
#> # A tibble: 2 × 5
#>   .metric .estimator  mean     n std_err
#>   <chr>   <chr>      <dbl> <int>   <dbl>
#> 1 rmse    standard   2.98      2  0.459 
#> 2 rsq     standard   0.747     2  0.0691

# Every candidate the first fold's race scored, and on how many inner
# resamples: `n` below 5 is a candidate the race eliminated.
res$.inner_metrics[[1]]
#> # A tibble: 8 × 7
#>   num_comp .metric .estimator  mean     n std_err .config        
#>      <int> <chr>   <chr>      <dbl> <int>   <dbl> <chr>          
#> 1        1 rmse    standard   2.42      5  0.576  pre1_mod0_post0
#> 2        1 rsq     standard   0.861     5  0.0627 pre1_mod0_post0
#> 3        2 rmse    standard   2.81      5  0.414  pre2_mod0_post0
#> 4        2 rsq     standard   0.847     5  0.0630 pre2_mod0_post0
#> 5        3 rmse    standard   2.86      5  0.365  pre3_mod0_post0
#> 6        3 rsq     standard   0.828     5  0.0482 pre3_mod0_post0
#> 7        4 rmse    standard   3.26      2  0.693  pre4_mod0_post0
#> 8        4 rsq     standard   0.693     2  0.0868 pre4_mod0_post0
```
