# Nested cross-validation with racing inside

`nested_tune_race_anova()` and `nested_tune_race_win_loss()` give you an
honest score for a model you tune with finetune's two racing tuners,
[`finetune::tune_race_anova()`](https://finetune.tidymodels.org/reference/tune_race_anova.html)
and
[`finetune::tune_race_win_loss()`](https://finetune.tidymodels.org/reference/tune_race_win_loss.html).
Each is
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
with the inner tuner swapped, and that page is the reference for
everything the racers share with the other orchestrators. For each outer
fold the race scores every candidate in `grid` on the first `burn_in`
inner resamples. It then drops the candidates that are already clearly
worse than the best, by a repeated-measures ANOVA or by a Bradley-Terry
model of pairwise wins and losses. The survivors are scored on the
remaining resamples, and the fold then selects, finalizes, fits and
scores on the outer split as the grid page describes.

The estimate describes the race-and-fit procedure as a whole. The model
to deploy comes from
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
which races the same grid once more on all the data, and the estimate is
the number to report for that model.

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

A `nested_results` with one row per outer fold and the columns
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
documents. The `procedure` record names the tuner, `"tune_race_anova"`
or `"tune_race_win_loss"`, and holds the `grid` beside the arguments
every orchestrator records. The section below says what `.inner_metrics`
and the recorded grid mean on a race.

## Details

Both functions need finetune installed. `nested_tune_race_anova()` also
needs lme4, which fits the ANOVA, and `nested_tune_race_win_loss()`
BradleyTerry2, which fits the win/loss model. A missing package is
refused at entry, before any fold runs.

`grid` is the design the race is offered. A data frame must have one
column per tuned parameter and no other column.

An inner design that holds an apparent split, such as the one
`bootstraps(apparent = TRUE)` adds, is refused at entry with class
`nestedtune_bad_design`. finetune eliminates race candidates on the
score of each split it has run, and the score of an apparent split comes
from the rows the model trained on. Build the bootstrap with
`apparent = FALSE`. If a workflow in a set routes to a racer,
[`nested_workflow_map()`](https://nestedtune.tidymodels.org/reference/nested_workflow_map.md)
refuses such a design before its first workflow runs. The other tuners
accept the split, because tune leaves it out of its estimates.

`param_info` reaches the inner call as
[`tune::tune_grid()`](https://tune.tidymodels.org/reference/tune_grid.html)
takes it. The section on finalizing a parameter range says where a range
that depends on the data is finalized.

## What a race records

Each fold's `.inner_metrics` holds every candidate its race scored,
eliminated candidates included:
`tune::collect_metrics(<the race>, all_configs = TRUE)`, where
finetune's own default keeps the survivors alone. In that table `n` is
the number of inner resamples each candidate was scored on. A candidate
that survived to the end has the full inner resample count, and one
eliminated along the way has fewer. The recorded `grid`, in the
`procedure` record and as `attr(x, "grid")`, is the design the race was
offered, exactly as given. What each candidate ran is `n`. A candidate
that failed on every inner resample is absent, and its failure is in
`.notes`.

A race draws from the generator even with a deterministic engine. With
`randomize = TRUE`, finetune's default, the inner resamples are shuffled
before the burn-in. So which resamples the burn-in uses, and with it
which candidates are eliminated when, comes from the fold's tuning seed.
On the parallel path every daemon's library must hold finetune. The loop
attaches it in each daemon before the first fold is sent, and warns
where it cannot.

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

## Differences from calling finetune directly

There is no `control` formal. A
[`finetune::control_race()`](https://finetune.tidymodels.org/reference/control_race.html)
passed through `...` as `control` reaches the inner race in every fold
and the final fit that re-runs the result.
`control = control_race(burn_in = 2)`, say, fits a design with three
inner resamples. What runs is the control passed, or finetune's default
when none is, with the slots this package forces overwritten. The result
records that effective control as `extract_procedure(res)$control`.
Every slot of `control_race()` falls under one of seven headings.

**Forced: `allow_par`.** The inner race and the outer fit run with
`allow_par = FALSE`, because the outer folds carry the parallelism.

**Settable as its own argument: `event_level`.** The argument is the one
place the level is set, as on the grid page. A control at finetune's
default takes it, and a control naming another level is refused at
entry, with a refusal that names both. `grid` and `eval_time` are the
racing functions' own arguments rather than control slots, offered here
as arguments and reaching them unchanged.

**Refused: none.** No slot is refused on its own. Three things are
refused at entry. The first is a control of another class, such as a
`control_grid()` that finetune itself accepts here. The second is the
`event_level` conflict above, and the third a `burn_in` no fold's inner
design can meet. finetune refuses a race whose resample count is not
greater than `burn_in`. This package refuses the whole call before any
fold runs when any outer fold's inner `rset` meets that condition, and
the refusal names the count and the burn-in. `control_race()` defaults
`burn_in` to 3, so a design with three inner resamples needs
`control = control_race(burn_in = 2)` or fewer.

**Passed through: `burn_in`, `alpha`, `num_ties`, `randomize`,
`verbose_elim`, `verbose`, `pkgs`, `parallel_over`, `workflow_size`.**
Each reaches the race as given:

- `burn_in`, `alpha`, `num_ties` and `randomize` govern each fold's race
  as they do in a direct call. `burn_in` is how many resamples every
  candidate is scored on before elimination starts. `alpha` is the
  significance level an elimination needs. `num_ties` is how many rounds
  two tied survivors are given before one is dropped. `randomize` is
  whether the resamples are shuffled first.

- `verbose_elim` prints finetune's elimination log from a serial run,
  once per fold, and from a mirai daemon where nothing shows it.
  `verbose` likewise.

`pkgs`, `parallel_over` and `workflow_size` behave as the grid page
describes. `parallel_over` changes the numbers a stochastic engine
produces even at `allow_par = FALSE`.

This classification was read on finetune 1.3.0. The version that added
`workflow_size` to `control_race()` is not named in finetune's NEWS, and
the `>= 1.0.1` floor this package declares does not require it.

**Kept from the outer fit: `save_pred`, `extract`.** Each reaches the
outer fit as well as the inner race. The outer fit's predictions and
extracts are kept as `.predictions` and `.extracts`, as the grid page
describes, and the inner race's own are still discarded.

**Not returned: `save_workflow`.** It lands on the inner `tune_results`
a fold record discards, so setting it costs the work and returns
nothing. The final fit keeps its own tuning run as `$tuning`, where what
it saved is reachable.

**Inert: `backend_options`.** Options for a parallel backend, with no
backend to reach at `allow_par = FALSE`.

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

Time-series designs work as well.
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
is tested with an outer
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
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
finalizes it on all the data. A range set in `param_info` applies to
every fold.

## Evaluation times

The inner tuning and the outer scoring both use the times in
`eval_time`. If the metric set has no dynamic or integrated survival
metric, tune ignores the times with a warning. Each fold selects at the
first of these times.

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

set.seed(1)
folds <- nested_resamples(
  mtcars,
  outside = rsample::vfold_cv(v = 2),
  inside = rsample::vfold_cv(v = 2)
)
# A race needs more inner resamples than its burn-in, so five inner folds.
set.seed(1)
folds5 <- nested_resamples(mtcars, outside = rsample::vfold_cv(v = 2),
                           inside = rsample::vfold_cv(v = 5))

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
