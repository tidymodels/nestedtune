# Nested cross-validation with simulated annealing inside

`nested_tune_sim_anneal()` runs the outer loop of nested
cross-validation with
[`finetune::tune_sim_anneal()`](https://finetune.tidymodels.org/reference/tune_sim_anneal.html)
as the inner tuner. For each outer fold it scores `initial` candidates
on that fold's inner resamples, then for `iter` iterations perturbs the
current candidate, scores the perturbation and keeps it or falls back by
finetune's annealing rule, and then selects, finalizes, fits and scores
on the outer split as
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
does. That page is the reference for everything the orchestrators share,
and
[`nested_tune_bayes()`](https://nestedtune.tidymodels.org/reference/nested_tune_bayes.md)
is this function's nearest sibling.

The estimate describes the annealing-and-fit procedure as a whole and is
reported for it; the model to deploy comes from
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
which runs the recorded search once more on all the data.

## Usage

``` r
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
  with at least one parameter marked for tuning with
  [`tune::tune()`](https://hardhat.tidymodels.org/reference/tune.html);
  a workflow with no marker is refused, and
  [`nested_fit_resamples()`](https://nestedtune.tidymodels.org/reference/nested_fit_resamples.md)
  scores one on the same design.

- resamples:

  A nested resampling design from
  [`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md)
  or
  [`rsample::nested_cv()`](https://rsample.tidymodels.org/reference/nested_cv.html),
  one row per outer fold, meeting the requirements the section on nested
  designs states.

- ...:

  A control object from
  [`finetune::control_sim_anneal()`](https://finetune.tidymodels.org/reference/control_sim_anneal.html)
  as `control` and nothing else, matched by name; what becomes of each
  slot is under the section on differences from finetune.

- iter:

  The number of search iterations, a whole number of at least 1; the
  section on the iterations says why `0` is refused.

- param_info:

  A
  [`dials::parameters()`](https://dials.tidymodels.org/reference/parameters.html)
  object, or `NULL` to let tune derive one from the workflow; the
  section on finalizing a parameter range says where a range that
  depends on the data is finalized.

- metrics:

  A
  [`yardstick::metric_set()`](https://yardstick.tidymodels.org/reference/metric_set.html),
  or `NULL` to compute a standard set of metrics.

- initial:

  The number of candidates each fold scores before the first iteration,
  a whole number of at least 1 (finetune's default); a `tune_results`
  object, which finetune also accepts here, is refused.

- event_level:

  `"first"` (the default) or `"second"`, naming which level of a
  two-class outcome is the event, for the inner tuning run and the outer
  scoring fit alike.

- eval_time:

  A numeric vector of evaluation times for a censored regression model,
  or `NULL` (the default) to leave the choice to tune; the section on
  evaluation times says what this package refuses.

- select:

  A
  [`selection_rule()`](https://nestedtune.tidymodels.org/reference/selection_rule.md)
  naming which of tune's selectors each outer fold picks its candidate
  with, on its own inner run and the first metric; the default is
  [`tune::select_best()`](https://tune.tidymodels.org/reference/show_best.html).

## Value

A `nested_results` with one row per outer fold and the columns
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
documents. Each fold's `.inner_metrics` carries an `.iter` column after
`.config`: `0` for the initial candidates, whose `.config` finetune
prefixes `initial_`, and `i` for the candidate the `i`-th iteration
scored, labelled `Iter<i>`. There is no `grid` attribute; the
`procedure` record names the tuner `"tune_sim_anneal"` and holds `iter`
and `initial` beside the arguments every orchestrator records.

## Details

finetune must be installed; a missing package is refused at entry,
before any fold runs.

## The initial candidates and the iterations

Each fold draws its own space-filling set of `initial` candidates with
[`dials::grid_space_filling()`](https://dials.tidymodels.org/reference/grid_space_filling.html)
and scores it with
[`tune::tune_grid()`](https://tune.tidymodels.org/reference/tune_grid.html)
under its tuning seed, as
[`nested_tune_bayes()`](https://nestedtune.tidymodels.org/reference/nested_tune_bayes.md)
does, and a `tune_results` object is refused as `initial` for the reason
that page gives. Each iteration then perturbs the current candidate and
scores the result on the fold's inner resamples.

`iter = 0` is refused: finetune 1.3.0 iterates over
`(existing_iter + 1):iter`, which at `iter = 0` is `1:0`, so it runs two
iterations rather than none, where
[`tune::tune_bayes()`](https://tune.tidymodels.org/reference/tune_bayes.html)
at `iter = 0` proposes nothing. finetune stops a fold's search early
after `no_improve` consecutive iterations without improvement (`Inf` by
default, so never, unless the control sets it) or when `time_limit` is
reached; the fold completes with the candidates scored so far, and
nothing about the early stop reaches `.notes`.

Annealing draws from the generator even with a deterministic engine: the
initial candidates are a space-filling design drawn under the fold's
tuning seed, and each perturbation is drawn from the stream that seed
started.
[`finetune::control_sim_anneal()`](https://finetune.tidymodels.org/reference/control_sim_anneal.html)
has no seed slot, so nothing is injected into the control. On the
parallel path every daemon's library must hold finetune, which the loop
attaches in each daemon before the first fold is sent, warning where it
cannot.

## Reproducibility

Seed the session before the call, as elsewhere in tidymodels; there is
no `seed` argument. On entry the function draws `2 * n` seeds in a
single `sample.int(.Machine$integer.max, 2 * n)` call, where `n` is the
number of outer folds. Fold `i` uses element `2 * i - 1` for its tuning
step and element `2 * i` for its outer fit, each applied with the
generator kind pinned. A fold's seed depends on its position and not on
the order the folds run in, so the same seed gives the same result
serially and in parallel, at any number of daemons. The two seeds are
kept on the result as `.tuning_seed` and `.outer_fit_seed`, and
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

There is no `control` formal, but a
[`finetune::control_sim_anneal()`](https://finetune.tidymodels.org/reference/control_sim_anneal.html)
passed through `...` as `control` reaches the inner search in every fold
and the final fit that re-runs the result:
`control = control_sim_anneal( no_improve = 5, verbose_iter = FALSE)`,
say, to stop a fold's search sooner and keep the console quiet. What
runs is the control passed, or finetune's default when none is, with the
slots this package forces overwritten; the result records that effective
control as `extract_procedure(res)$control`. Every slot of
`control_sim_anneal()` falls under one of seven headings.

**Forced: `allow_par`.** The inner search and the outer scoring fit both
run at `allow_par = FALSE`, whatever the control carries; parallelism
belongs over the outer folds.

**Settable as its own argument: `event_level`.** Set through the
argument alone, as on the grid page; a control at finetune's default
takes the argument's level, and one naming a different level is refused
at entry. `iter`, `initial` and `eval_time` are arguments of
`tune_sim_anneal()` rather than control slots, offered here as arguments
and reaching it unchanged.

**Refused: none.** No slot is refused on its own; what is refused at
entry is a control of another class (a `control_bayes()`, which finetune
itself would run under) and the `event_level` conflict above.

**Passed through: `no_improve`, `restart`, `radius`, `flip`,
`cooling_coef`, `time_limit`, `verbose`, `verbose_iter`, `pkgs`,
`parallel_over`, `workflow_size`.** Each reaches `tune_sim_anneal()` as
given. `no_improve`, `restart`, `radius`, `flip` and `cooling_coef`
govern each fold's search as they would a direct call: when a search
stops or restarts from its best candidate, how far and how a
perturbation moves, and how the acceptance probability cools.
`time_limit` is a wall-clock stop, and a wall-clock stop makes the
candidate set depend on the machine: two runs under the same seed can
stop at different iterations, which is outside what the seeds can
promise. `verbose_iter`, `TRUE` in finetune's default, prints the
annealing log from every fold of a serial run, one log per fold, and
from a mirai daemon where nothing shows it; pass
`control = control_sim_anneal(verbose_iter = FALSE)` for a quiet run.
`verbose` likewise. `pkgs`, `parallel_over` and `workflow_size` behave
as the grid page describes, `parallel_over` included. This
classification was read on finetune 1.3.0; the version that added
`workflow_size` to `control_sim_anneal()` is not named in finetune's
NEWS, and the `>= 1.0.1` floor this package declares does not require
it.

**Kept from the outer fit: `save_pred`, `extract`.** Both reach the
outer fit, whose predictions and extracts come back as `.predictions`
and `.extracts` (the grid page has the shape); the inner search's are
still discarded.

**Not returned: `save_workflow`, `save_history`.** `save_workflow` lands
on the inner `tune_results` a fold record discards, so setting it costs
the work and returns nothing; the final fit keeps its tuning run as
`$tuning`, where what it saved is reachable. `save_history` writes
finetune's search history to `sa_history.RData` in the temporary
directory of the process that tuned (a daemon's own on the parallel
path), every fold overwriting the last one's; nothing of it reaches the
result.

**Inert: `backend_options`.** A parallel backend's options, and there is
no backend to reach at `allow_par = FALSE`.

## Nested designs

`resamples` is a data frame whose `splits` column holds one `rsplit` per
outer fold, whose `inner_resamples` column holds one `rset` with at
least one row per outer fold, and whose every other column labels the
outer folds. A label column is named `id`, or `id` followed by a digit
from 1 to 9, and holds character or factor values; together the label
columns give every outer fold a distinct label with no `NA`.

Inside each inner `rset`, every element of `splits` is an `rsplit`, and
all of a fold's inner splits carry one frame: either the outer split's
own data frame (what
[`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md)
builds) or that split's analysis set (what
[`rsample::nested_cv()`](https://rsample.tidymodels.org/reference/nested_cv.html)
builds). An inner split carrying the outer data frame indexes, in its
`in_id` and any non-`NA` `out_id`, only rows the outer split's `in_id`
holds, so no inner analysis or assessment set reaches a row the outer
fold holds out.

A design breaking any of this, or using a bootstrap for the outer loop,
is refused before anything is fitted, with condition class
`nestedtune_bad_design` and every offending row, column, inner split or
index named. The checks exist because
[`rsample::nested_cv()`](https://rsample.tidymodels.org/reference/nested_cv.html)
builds a design whatever its `inside` argument returned, and because a
design assembled by hand can index rows its outer fold never sees.

## Finalizing a parameter range

`param_info` is passed unchanged to the inner tuning call on every outer
fold, so a restricted range restricts what every fold searches. A
parameter whose range is unknown until the data is seen (`mtry()`, or a
`min_n()` finalized by row count) is finalized by tune on the outer
fold's analysis rows, never on the rows that fold holds out. On a
[`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md)
design the inner call therefore receives the fold's inner resamples
re-pointed at its analysis set rather than the design's own
`inner_resamples` element, which indexes the whole data. A design from
[`rsample::nested_cv()`](https://rsample.tidymodels.org/reference/nested_cv.html)
already carries the analysis set and is passed as it is, as is the
design's element under an outer split that repeats a row (an evaluated
[`rsample::manual_rset()`](https://rsample.tidymodels.org/reference/manual_rset.html)),
where the re-pointing is ambiguous.
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
finalizes on the full data.

## Evaluation times

`eval_time` reaches every tune call whose answer depends on it, so a
dynamic or integrated survival metric (`brier_survival()`,
`roc_auc_survival()` and their relatives) is measured at the times you
name. It is ignored, with a warning from tune, whenever the metric set
has no metric that reads it; tune keys that warning on the metrics
rather than on the model's mode.

Refused here, ahead of tune: anything that is not numeric, an empty
vector, and any element that is missing, negative or not finite. tune
treats those unevenly and only once a metric reads the times, so this
package refuses them all at entry, before a whole run is paid for. Zero,
repeated times and times out of order are accepted and passed on
untouched, since tune normalizes those itself; a repeated time draws
tune's warning that 0 inappropriate evaluation time points were removed,
once per tune call.

The selector `select` names is called without `eval_time`. Left unset it
selects at the first of the evaluation times the tuning run was built
with, which are the ones named here, so passing them again would change
no choice and would repeat tune's message about which time it took.

## See also

[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
[`nested_tune_bayes()`](https://nestedtune.tidymodels.org/reference/nested_tune_bayes.md),
[`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md),
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
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
