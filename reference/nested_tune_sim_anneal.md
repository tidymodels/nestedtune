# Nested cross-validation with simulated annealing inside

`nested_tune_sim_anneal()` gives you an honest score for a model you
tune with
[`finetune::tune_sim_anneal()`](https://finetune.tidymodels.org/reference/tune_sim_anneal.html).
It is
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
with the inner tuner swapped, and that page is the reference for
everything the orchestrators share.
[`nested_tune_bayes()`](https://nestedtune.tidymodels.org/reference/nested_tune_bayes.md)
is this function's nearest sibling. For each outer fold it scores
`initial` candidates on that fold's inner resamples. Then for `iter`
iterations it perturbs the current candidate, scores the perturbation,
and keeps it or falls back by finetune's annealing rule. The fold then
selects, finalizes, fits and scores on the outer split as the grid page
describes.

The estimate describes the annealing-and-fit procedure as a whole. The
model to deploy comes from
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
which runs the recorded search once more on all the data, and the
estimate is the number to report for that model.

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

  The number of search iterations, a whole number of at least 1. The
  section on the iterations says why `0` is refused.

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
  a whole number of at least 1 (finetune's default). A `tune_results`
  object, which finetune also accepts here, is refused.

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

A `nested_results` shaped as
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
documents, one row per outer fold. Each fold's `.inner_metrics` carries
an `.iter` column after `.config`. It is `0` for the initial candidates,
whose `.config` finetune prefixes `initial_`. It is `i` for the
candidate the `i`-th iteration scored, labelled `Iter<i>`. There is no
`grid` attribute. The `procedure` record names the tuner
`"tune_sim_anneal"` and holds `iter` and `initial` beside the arguments
every orchestrator records.

## Details

finetune must be installed. A missing package is refused at entry,
before any fold runs.

`param_info` reaches the inner call as
[`tune::tune_grid()`](https://tune.tidymodels.org/reference/tune_grid.html)
takes it. The section on finalizing a parameter range says where a range
that depends on the data is finalized.

## The initial candidates and the iterations

Each fold draws its own space-filling set of `initial` candidates with
[`dials::grid_space_filling()`](https://dials.tidymodels.org/reference/grid_space_filling.html)
and scores it with
[`tune::tune_grid()`](https://tune.tidymodels.org/reference/tune_grid.html)
under its tuning seed, as
[`nested_tune_bayes()`](https://nestedtune.tidymodels.org/reference/nested_tune_bayes.md)
does. A `tune_results` object is refused as `initial` for the reason
that page gives. Each iteration then perturbs the current candidate and
scores the result on the fold's inner resamples.

`iter = 0` is refused. finetune 1.3.0 iterates over
`(existing_iter + 1):iter`, which at `iter = 0` is `1:0`, so it runs two
iterations rather than none.
[`tune::tune_bayes()`](https://tune.tidymodels.org/reference/tune_bayes.html)
at `iter = 0` proposes nothing. finetune stops a fold's search early
after `no_improve` consecutive iterations without improvement, or when
`time_limit` is reached. `no_improve` is `Inf` by default, so never,
unless the control sets it. The fold completes with the candidates
scored so far, and nothing about the early stop reaches `.notes`.

Annealing draws from the generator even with a deterministic engine. The
initial candidates are a space-filling design drawn under the fold's
tuning seed, and each perturbation is drawn from the stream that seed
started.
[`finetune::control_sim_anneal()`](https://finetune.tidymodels.org/reference/control_sim_anneal.html)
has no seed slot, so nothing is injected into the control. On the
parallel path every daemon's library must hold finetune. The loop
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
[`finetune::control_sim_anneal()`](https://finetune.tidymodels.org/reference/control_sim_anneal.html)
passed through `...` as `control` reaches the inner search in every fold
and the final fit that re-runs the result.
`control = control_sim_anneal( no_improve = 5, verbose_iter = FALSE)`,
say, stops a fold's search sooner and keeps the console quiet. What runs
is the control passed, or finetune's default when none is, with the
slots this package forces overwritten. The result records that effective
control as `extract_procedure(res)$control`. Every slot of
`control_sim_anneal()` falls under one of seven headings.

**Forced: `allow_par`.** The inner search and the outer fit run with
`allow_par = FALSE`, because the outer folds carry the parallelism.

**Settable as its own argument: `event_level`.** The argument is the one
place the level is set, as on the grid page. A control at finetune's
default takes it, and a control naming another level is refused at
entry, with a refusal that names both. `iter`, `initial` and `eval_time`
are arguments of `tune_sim_anneal()` rather than control slots, offered
here as arguments and reaching it unchanged.

**Refused: none.** No slot is refused on its own. A control of another
class is refused at entry, as is the `event_level` conflict above.

**Passed through: `no_improve`, `restart`, `radius`, `flip`,
`cooling_coef`, `time_limit`, `verbose`, `verbose_iter`, `pkgs`,
`parallel_over`, `workflow_size`.** Each reaches `tune_sim_anneal()` as
given:

- `no_improve` and `restart` set when a search stops or restarts from
  its best candidate. `radius` and `flip` set how far and how a
  perturbation moves, and `cooling_coef` how the acceptance probability
  cools. All five govern each fold's search as they do in a direct call.

- `time_limit` is a wall-clock stop, and a wall-clock stop makes the
  candidate set depend on the machine. Two runs under the same seed can
  stop at different iterations, which is outside what the seeds can
  promise.

- `verbose_iter`, `TRUE` in finetune's default, prints the annealing log
  from every fold of a serial run, one log per fold, and from a mirai
  daemon where nothing shows it. Pass
  `control = control_sim_anneal(verbose_iter = FALSE)` for a quiet run.
  `verbose` likewise.

`pkgs`, `parallel_over` and `workflow_size` behave as the grid page
describes. `parallel_over` changes the numbers a stochastic engine
produces even at `allow_par = FALSE`.

This classification was read on finetune 1.3.0. The version that added
`workflow_size` to `control_sim_anneal()` is not named in finetune's
NEWS, and the `>= 1.0.1` floor this package declares does not require
it.

**Kept from the outer fit: `save_pred`, `extract`.** Each reaches the
outer fit as well as the inner search. The outer fit's predictions and
extracts are kept as `.predictions` and `.extracts`, as the grid page
describes, and the inner search's own are still discarded.

**Not returned: `save_workflow`, `save_history`.** `save_workflow` lands
on the inner `tune_results` a fold record discards, so setting it costs
the work and returns nothing. The final fit keeps its tuning run as
`$tuning`, where what it saved is reachable. `save_history` writes
finetune's search history to `sa_history.RData` in the temporary
directory of the process that tuned, a daemon's own on the parallel
path. Every fold overwrites the last one's, and nothing of it reaches
the result.

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
