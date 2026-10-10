# Nested cross-validation with Bayesian optimization inside

`nested_tune_bayes()` gives you an honest score for a model you tune
with
[`tune::tune_bayes()`](https://tune.tidymodels.org/reference/tune_bayes.html).
It is
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
with the inner tuner swapped. For each outer fold it scores `initial`
candidates on that fold's inner resamples and lets a Gaussian process
propose `iter` more, one at a time. It then selects by `select`,
finalizes the workflow, and fits and scores it on the outer split. The
grid page is the reference for everything the two share: the design, the
seeds, failed folds, parallel execution and what an operation on the
result does.

The estimate describes the whole search-and-fit procedure rather than
any one model. The model to deploy comes from
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
which runs the recorded search once more on all the data, and the
estimate is the number to report for that model.

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
  a whole number of at least 2. A `tune_results` object, which tune also
  accepts here, is refused.

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

A `nested_results` with one row per outer fold, the columns the grid
page documents. Each fold's `.inner_metrics` carries an `.iter` column
after `.config`. It is `0` for the initial candidates and `i` for the
candidate the `i`-th iteration proposed, so a fold's search trajectory
can be read from it. There is no `grid` attribute. The `procedure`
record names the tuner `"tune_bayes"`. It holds `iter`, `initial` and
`objective` beside the arguments every orchestrator records.

## Details

`iter` reaches
[`tune::tune_bayes()`](https://tune.tidymodels.org/reference/tune_bayes.html)
as given, and tune stops early when the search stalls. The number of
search iterations, a non-negative whole number. The section on the
iterations says what `0` does.

`param_info` reaches the inner call as
[`tune::tune_grid()`](https://tune.tidymodels.org/reference/tune_grid.html)
takes it. The section on finalizing a parameter range says where a range
that depends on the data is finalized.

## The initial candidates and the iterations

Each fold generates its own space-filling set of `initial` candidates
from the parameter ranges with
[`dials::grid_space_filling()`](https://dials.tidymodels.org/reference/grid_space_filling.html),
and scores it with
[`tune::tune_grid()`](https://tune.tidymodels.org/reference/tune_grid.html)
under the fold's own tuning seed. A `tune_results` object is refused as
`initial` because one tuning run cannot serve every outer fold: its
candidates were scored on resamples that can hold a fold's assessment
rows.

Each iteration proposes one candidate and scores it on the fold's inner
resamples. `iter = 0` scores the initial candidates and proposes
nothing. The run is then
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
on the space-filling grid those candidates form. tune stops a fold's
search early when no unscored candidate remains, and says so on the
console. It also stops after ten consecutive iterations without
improvement, its `no_improve` default, settable through the control. The
fold then completes with the candidates scored so far, and nothing about
the early stop reaches `.notes`.

A parameter range that depends on the data is a case apart.
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
and the finetune tuners finalize such a range on the outer fold's
analysis rows.
[`tune::tune_bayes()`](https://tune.tidymodels.org/reference/tune_bayes.html)
refuses it before any frame is read, and every outer fold records that
refusal as its failure. Finalize the range on the data first.

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

## Differences from calling tune directly

There is no `control` formal. A
[`tune::control_bayes()`](https://tune.tidymodels.org/reference/control_bayes.html)
passed through `...` as `control` reaches the inner `tune_bayes()` in
every fold and the final fit that re-runs the result.
`control = control_bayes(no_improve = 5, uncertain = 3)`, say, stops a
fold's search sooner. What runs is the control passed, or tune's default
when none is, with the slots this package forces overwritten. The result
records that effective control, `seed` left out, as
`extract_procedure(res)$control`. Every slot of `control_bayes()` falls
under one of seven headings.

**Forced: `allow_par`, `seed`.** `allow_par = FALSE` on both tune calls
a fold makes, because parallelism belongs over the outer folds. `seed`
is the slot that drives the Gaussian process's proposals. tune draws it
from the stream when it is not given. Were the slot left alone, a fold's
proposals depend on how much of the stream tune consumed before reaching
it. Here the control is given the fold's own tuning seed, the number
`.tuning_seed` reports, whatever the control carried.

**Settable as its own argument: `event_level`.** The argument is the one
place the level is set, as on the grid page. A control at tune's default
takes it, and a control naming another level is refused at entry, with a
refusal that names both. `iter`, `initial` and `objective` are arguments
of `tune_bayes()` rather than control slots, offered here as arguments
and reaching it unchanged. So is `eval_time`.

**Refused: none.** No slot is refused on its own. A control of another
class is refused at entry, as is the `event_level` conflict above.

**Passed through: `no_improve`, `uncertain`, `time_limit`, `verbose`,
`verbose_iter`, `save_gp_scoring`, `pkgs`, `parallel_over`,
`workflow_size`.** Each reaches `tune_bayes()` as given:

- `no_improve` and `uncertain` govern each fold's search as they do in a
  direct call, so a fold sometimes stops short of `iter`. Its
  `.inner_metrics` records how far it went.

- `time_limit` stops a search by the clock. Two runs under the same seed
  can then stop at different iterations on different machines, which is
  outside what the seeds can promise.

- `verbose` and `verbose_iter` print from a serial run, and from a mirai
  daemon where nothing shows it.

- `save_gp_scoring` writes its files to the temporary directory of the
  process that tuned, a daemon's own on the parallel path.

`pkgs`, `parallel_over` and `workflow_size` behave as the grid page
describes. `parallel_over` changes the numbers a stochastic engine
produces even at `allow_par = FALSE`.

**Kept from the outer fit: `save_pred`, `extract`.** Each reaches the
outer fit as well as the inner search. The outer fit's predictions and
extracts are kept as `.predictions` and `.extracts`, as the grid page
describes, and the inner search's own are still discarded.

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
