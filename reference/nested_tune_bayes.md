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
result may do.

The estimate describes the whole search-and-fit procedure rather than
any one model, and is reported for the procedure. The model to deploy
comes from
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
which runs the recorded search once more on all the data.

## Usage

``` r
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
  with at least one parameter marked for tuning with
  [`tune::tune()`](https://hardhat.tidymodels.org/reference/tune.html).
  A workflow with no marker is refused;
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
  [`tune::control_bayes()`](https://tune.tidymodels.org/reference/control_bayes.html),
  as `control`, and nothing else; every argument after `...` is matched
  by name. The section on differences from tune says what becomes of
  each slot.

- iter:

  The number of search iterations, a non-negative whole number; the
  section on the iterations says what `0` does.

- param_info:

  A
  [`dials::parameters()`](https://dials.tidymodels.org/reference/parameters.html)
  object, or `NULL` to let tune derive one from the workflow. The
  section on finalizing a parameter range says where a range that
  depends on the data is finalized.

- metrics:

  A
  [`yardstick::metric_set()`](https://yardstick.tidymodels.org/reference/metric_set.html),
  or `NULL` to compute a standard set of metrics.

- initial:

  The number of candidates each fold scores before the first iteration,
  a whole number of at least 2; a `tune_results` object, which tune also
  accepts here, is refused.

- objective:

  An acquisition function from tune, deciding which candidate the
  Gaussian process proposes next:
  [`tune::exp_improve()`](https://tune.tidymodels.org/reference/prob_improve.html)
  (the default),
  [`tune::prob_improve()`](https://tune.tidymodels.org/reference/prob_improve.html)
  or
  [`tune::conf_bound()`](https://tune.tidymodels.org/reference/prob_improve.html).

- event_level:

  `"first"` (the default) or `"second"`, naming which level of a
  two-class outcome is the event. It applies to the inner tuning run and
  the outer scoring fit alike.

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

A `nested_results` with one row per outer fold, the columns the grid
page documents. Each fold's `.inner_metrics` carries an `.iter` column
after `.config`. It is `0` for the initial candidates and `i` for the
candidate the `i`-th iteration proposed, so a fold's search trajectory
can be read from it. There is no `grid` attribute. The `procedure`
record names the tuner `"tune_bayes"`. It holds `iter`, `initial` and
`objective` beside the arguments every orchestrator records.

## The initial candidates and the iterations

Each fold generates its own space-filling set of `initial` candidates
from the parameter ranges with
[`dials::grid_space_filling()`](https://dials.tidymodels.org/reference/grid_space_filling.html),
and scores it with
[`tune::tune_grid()`](https://tune.tidymodels.org/reference/tune_grid.html)
under the fold's own tuning seed. A `tune_results` object is refused as
`initial` because one tuning run cannot serve every outer fold: its
candidates were scored on resamples that may hold a fold's assessment
rows.

Each iteration proposes one candidate and scores it on the fold's inner
resamples. `iter = 0` scores the initial candidates and proposes
nothing. The run is then
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
on the space-filling grid those candidates form. tune stops a fold's
search early when no unscored candidate remains, saying so on the
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
from the stream when it is not given. Left alone, a fold's proposals
would then depend on how much of the stream tune had consumed before
reaching it. Here the control is given the fold's own tuning seed, the
number `.tuning_seed` reports, whatever the control carried.

**Settable as its own argument: `event_level`.** The argument is the one
place the level is set, as on the grid page. A control at tune's default
takes it, and a control naming another level is refused at entry, naming
both. `iter`, `initial` and `objective` are arguments of `tune_bayes()`
rather than control slots, offered here as arguments and reaching it
unchanged. So is `eval_time`.

**Refused: none.** No slot is refused on its own. What is refused at
entry is a control of another class, such as a `control_grid()` that
tune itself would accept here, and the `event_level` conflict above.

**Passed through: `no_improve`, `uncertain`, `time_limit`, `verbose`,
`verbose_iter`, `save_gp_scoring`, `pkgs`, `parallel_over`,
`workflow_size`.** Each reaches `tune_bayes()` as given:

- `no_improve` and `uncertain` govern each fold's search as they would a
  direct call, so a fold may stop short of `iter`; its `.inner_metrics`
  records how far it went.

- `time_limit` stops a search by the clock. Two runs under the same seed
  can then stop at different iterations on different machines, which is
  outside what the seeds can promise.

- `verbose` and `verbose_iter` print from a serial run, and from a mirai
  daemon where nothing shows it.

- `save_gp_scoring` writes its files to the temporary directory of the
  process that tuned, a daemon's own on the parallel path.

- `pkgs`, `parallel_over` and `workflow_size` behave as the grid page
  describes. `parallel_over` changes the numbers a stochastic engine
  produces even at `allow_par = FALSE`.

**Kept from the outer fit: `save_pred`, `extract`.** The outer fit's
predictions and extracts are kept as `.predictions` and `.extracts`, as
the grid page describes, and the inner search's are still discarded.

**Not returned: `save_workflow`.** It lands on the inner `tune_results`
a fold record discards, so setting it costs the work and returns
nothing. The final fit keeps its own tuning run as `$tuning`, where what
it saved is reachable.

**Inert: `backend_options`.** Options for a backend the forced
`allow_par = FALSE` never reaches.

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
with a warning; tune keys that warning on the metrics, not on the
model's mode.

Refused here, ahead of tune: anything that is not numeric, an empty
vector, and any element that is missing, negative or not finite. tune
treats those unevenly, and only once a metric reads the times, so they
are refused at entry, before a whole run is paid for. Zero, repeated
times and times out of order are accepted and passed on untouched, since
tune normalizes those itself. A repeated time draws tune's warning that
0 inappropriate evaluation time points were removed, once per tune call.

The selection rule is applied without `eval_time`. Left unset, it
selects at the first of the evaluation times the tuning run was built
with, which are the ones named here. Passing them again would change no
choice, and would repeat tune's message about which time it took.

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
