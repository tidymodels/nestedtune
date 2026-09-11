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

The estimate describes the race-and-fit procedure as a whole and is
reported for it. The model to deploy comes from
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
which races the same grid once more on all the data.

## Usage

``` r
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
  with at least one parameter marked for tuning with
  [`tune::tune()`](https://hardhat.tidymodels.org/reference/tune.html).
  A workflow with no marker is refused, and
  [`nested_fit_resamples()`](https://nestedtune.tidymodels.org/reference/nested_fit_resamples.md)
  scores one on the same design.

- resamples:

  A nested resampling design from
  [`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md)
  or
  [`rsample::nested_cv()`](https://rsample.tidymodels.org/reference/nested_cv.html),
  one row per outer fold. The section on nested designs says what the
  design must hold.

- ...:

  A control object from
  [`finetune::control_race()`](https://finetune.tidymodels.org/reference/control_race.html),
  as `control`, and nothing else. Every argument after `...` is matched
  by name. The section on differences from finetune says what becomes of
  each slot.

- param_info:

  A
  [`dials::parameters()`](https://dials.tidymodels.org/reference/parameters.html)
  object, or `NULL` to let tune derive one from the workflow. The
  section on finalizing a parameter range says where a range that
  depends on the data is finalized.

- grid:

  A data frame of candidate parameter values, or a positive whole number
  for the size of a grid to generate, the design the race is offered. A
  data frame must have one column per tuned parameter and no other
  column.

- metrics:

  A
  [`yardstick::metric_set()`](https://yardstick.tidymodels.org/reference/metric_set.html),
  or `NULL` to compute a standard set of metrics.

- event_level:

  `"first"` (the default) or `"second"`. It names which level of a
  two-class outcome is the event, and applies to the inner tuning run
  and the outer scoring fit alike.

- eval_time:

  A numeric vector of evaluation times for a censored regression model,
  or `NULL` (the default) to leave the choice to tune. The section on
  evaluation times says what this package refuses.

- select:

  A
  [`selection_rule()`](https://nestedtune.tidymodels.org/reference/selection_rule.md)
  naming which of tune's selectors each outer fold picks its candidate
  with, on its own inner run and the first metric. The default is
  [`tune::select_best()`](https://tune.tidymodels.org/reference/show_best.html).

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

## Reproducibility

Seed the session before the call, as elsewhere in tidymodels. There is
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

**Forced: `allow_par`.** The inner race and the outer scoring fit both
run at `allow_par = FALSE`, whatever the control carries, because
parallelism belongs over the outer folds.

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

- `pkgs`, `parallel_over` and `workflow_size` behave as the grid page
  describes, `parallel_over` included.

This classification was read on finetune 1.3.0. The version that added
`workflow_size` to `control_race()` is not named in finetune's NEWS, and
the `>= 1.0.1` floor this package declares does not require it.

**Kept from the outer fit: `save_pred`, `extract`.** Each reaches the
outer fit as well as the race. The outer fit's predictions and extracts
are kept as `.predictions` and `.extracts` in the shape the grid page
describes, and the race's own are still discarded.

**Not returned: `save_workflow`.** It lands on the inner race result a
fold record discards, so setting it costs the work and returns nothing.
The final fit keeps its race as `$tuning`, where what it saved is
reachable.

**Inert: `backend_options`.** Backend options with no parallel backend
to reach, because `allow_par` is forced off.

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
builds. An inner split carrying the outer frame must index only rows the
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

## Finalizing a parameter range

`param_info` is passed unchanged to the inner tuning call on every outer
fold, so a restricted range restricts what every fold searches. Some
ranges are unknown until the data is seen: `mtry()`, or a `min_n()`
finalized by row count. tune finalizes such a range on the outer fold's
analysis rows, never on the rows that fold holds out. On a
[`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md)
design the inner call therefore receives the fold's inner resamples
re-pointed at its analysis set, not the design's own `inner_resamples`
element, which indexes the whole data. A design from
[`rsample::nested_cv()`](https://rsample.tidymodels.org/reference/nested_cv.html)
already carries the analysis set and is passed as it is. So is the
design's element under an outer split that repeats a row, an evaluated
[`rsample::manual_rset()`](https://rsample.tidymodels.org/reference/manual_rset.html),
where the re-pointing is ambiguous.
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
finalizes on the full data.

## Evaluation times

`eval_time` reaches every tune call whose answer depends on it. So a
dynamic or integrated survival metric, `brier_survival()`,
`roc_auc_survival()` and their relatives, is measured at the times you
name. When the metric set has no metric that reads it, tune ignores it
with a warning. tune keys that warning on the metrics, not on the
model's mode.

Refused here, ahead of tune: anything that is not numeric, an empty
vector, and any element that is missing, negative or not finite. tune
treats those unevenly, and only once a metric reads the times, so they
are refused at entry, before a whole run is paid for. Zero, repeated
times and times out of order are accepted and passed on untouched,
because tune normalizes those itself. A repeated time draws tune's
warning that 0 inappropriate evaluation time points were removed, once
per tune call.

The selection rule is applied without `eval_time`. Left unset, it
selects at the first of the evaluation times the tuning run was built
with, which are the ones named here. Passing them again changes no
choice, and repeats tune's message about which time it took.

## See also

[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
[`nested_tune_bayes()`](https://nestedtune.tidymodels.org/reference/nested_tune_bayes.md),
[`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md),
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
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
