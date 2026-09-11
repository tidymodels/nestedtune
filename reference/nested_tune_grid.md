# Nested cross-validation with a grid search inside

`nested_tune_grid()` gives you an honest score for a model you tune with
[`tune::tune_grid()`](https://tune.tidymodels.org/reference/tune_grid.html).
It runs the outer loop of nested cross-validation. For each outer fold
it tunes on that fold's inner resamples and selects a candidate, one row
of the grid, by the rule `select` names. It finalizes the workflow with
that candidate, fits it on the fold's analysis rows, and scores it on
the assessment rows with
[`tune::last_fit()`](https://tune.tidymodels.org/reference/last_fit.html).
Every step is tune's; what this function adds is the loop, the seeds,
and a result that keeps what each fold chose.

Tune, select, fit and score, taken together, are the procedure this
function scores. The estimate
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
returns describes that whole procedure, not any one fitted model, and it
is the number to report. No model is returned here.
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
builds the model to deploy by running the recorded procedure once more
on all the data, and that model has no performance number of its own.

## Usage

``` r
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
  [`tune::control_grid()`](https://tune.tidymodels.org/reference/control_grid.html),
  passed as `control`, and nothing else; every argument after `...` is
  matched by name. The section on differences from tune says what
  becomes of each control slot.

- param_info:

  A
  [`dials::parameters()`](https://dials.tidymodels.org/reference/parameters.html)
  object, or `NULL` to let tune derive one from the workflow. The
  section on finalizing a parameter range says where a range that
  depends on the data is finalized.

- grid:

  A data frame of candidate parameter values, or a positive whole number
  for the size of a grid tune generates. A data frame has one column per
  tuned parameter and no other column.

- metrics:

  A
  [`yardstick::metric_set()`](https://yardstick.tidymodels.org/reference/metric_set.html),
  or `NULL` to compute a standard set of metrics.

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

A tibble of class `nested_results` with one row per outer fold. Beside
the fold's split and labels, each row holds:

- `.metrics`, the metrics scored on the fold's assessment set;

- `.selected`, the candidate the fold's inner tuning chose;

- `.inner_metrics`, the inner run's own metrics;

- `.completed`, whether the fold finished, and `.notes`, what went
  wrong;

- `.tuning_seed` and `.outer_fit_seed`, the two seeds that reproduce it.

[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
summarizes the result.
[`summary()`](https://rdrr.io/r/base/summary.html),
[`collect_selections()`](https://nestedtune.tidymodels.org/reference/collect_selections.md),
[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md)
and
[autoplot()](https://nestedtune.tidymodels.org/reference/autoplot.nested_results.md)
read it in other ways.

## Details

The same outer loop runs with other searches inside. Four siblings run
it with another search:
[`nested_tune_bayes()`](https://nestedtune.tidymodels.org/reference/nested_tune_bayes.md),
[`nested_tune_race_anova()`](https://nestedtune.tidymodels.org/reference/nested_tune_race.md),
[`nested_tune_race_win_loss()`](https://nestedtune.tidymodels.org/reference/nested_tune_race.md)
and
[`nested_tune_sim_anneal()`](https://nestedtune.tidymodels.org/reference/nested_tune_sim_anneal.md).
A fifth,
[`nested_fit_resamples()`](https://nestedtune.tidymodels.org/reference/nested_fit_resamples.md),
runs it for a workflow with nothing to tune. With this function they are
the package's orchestrators: each runs the outer loop and hands the
inner tuning to tune or finetune. Their pages say what differs; this
page is the reference for what the six share.

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

## Selecting a candidate

tune leaves the choice of candidate to a call you make on the tuning
result. Here the choice is made inside every fold, so the rule is an
argument. `select` takes what
[`selection_rule()`](https://nestedtune.tidymodels.org/reference/selection_rule.md)
returns:
[`tune::select_best()`](https://tune.tidymodels.org/reference/show_best.html)
by default, or
[`tune::select_by_one_std_err()`](https://tune.tidymodels.org/reference/show_best.html)
or
[`tune::select_by_pct_loss()`](https://tune.tidymodels.org/reference/show_best.html)
with the orderings and limit the rule carries. Each fold applies the
rule to its own inner run, with `metric` the first metric in `metrics`.
Every name an ordering uses must be a parameter `object` tunes, and
anything but a
[`selection_rule()`](https://nestedtune.tidymodels.org/reference/selection_rule.md)
is refused at entry. The result records the rule as
`extract_procedure(res)$select`, and
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
selects by it too.

## What the result records

Two records describe the grid, and they answer different questions.
`attr(x, "grid")` holds the `grid` argument as it was given: a positive
whole number, not a table of candidates, whenever a size was passed. The
`.inner_metrics` column holds what each outer fold's inner tuning
scored,
[`tune::collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
of that fold's tuning run, one table per fold. Each table has a column
per tuned parameter and one row per candidate and metric. Beside them
sit the summary columns
[`tune::collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
writes, with `.eval_time` among them when a dynamic survival metric was
scored. The candidates a fold searched are the table's distinct
parameter rows.

The two diverge routinely. tune expands a size and may reach fewer
candidates than were asked for: a request for 20 on a parameter with
four reachable values evaluates four. A candidate that fails scores
nothing. Folds can also differ from each other. Expanding a size draws
from the generator, and each fold tunes under its own seed, so a
continuous parameter gives every fold its own candidates. Printing says
so when it happens. A candidate that failed on every inner resample has
no row in `.inner_metrics`; `.notes` is where its failure is recorded. A
fold that scored no candidate at all carries a zero-row table with a
completed fold's columns, never `NULL`.

`attr(x, "metrics")` holds the `metrics` argument, and is absent when
none was supplied.

The `procedure` record, which
[`extract_procedure()`](https://nestedtune.tidymodels.org/reference/extract_procedure.md)
returns, names the tuner (`"tune_grid"` here) and that tuner's own
arguments (`grid` here). It also holds `param_info`, `event_level`,
`eval_time`, `select` and the effective control, on the result of every
orchestrator.

## Operations on the result

You can reorder rows and add or reorder columns, and the result stays a
`nested_results`. Those are the rules tune states for its own results
objects. Rows are never added or removed. Every column named under Value
must still be present, holding the values it held.

The fold-label columns are the ones the resampling design named, and
`nested_tune_grid()` records them when it builds the result. So a column
you add afterwards is read as a fold label only when the design itself
carries a column of that name: `id`, and `id2` for a repeated design.
Adding `id2` to a result from a plain v-fold design leaves the class,
the record and the fold labels alone, exactly as adding `extra` does.

An operation that stays inside those rules returns a `nested_results`
with the call's record intact: `arrange()`, `mutate()` adding a column,
a join that matches one row apiece. Anything else returns a bare tibble,
with the record removed along with the class: `slice()`, a
[`filter()`](https://rdrr.io/r/stats/filter.html) that drops a fold,
`bind_rows()`, `x[1, ]`, dropping one of the columns above. A three-row
object cannot describe itself as the ten-fold design it was cut from, so
it stops describing itself and hands back the data.

One rule covers every verb that subsets or combines a result. dplyr's
verbs and `[` reach it through a `dplyr_reconstruct()` method. vctrs'
own verbs, `vec_slice()`, `vec_rbind()`, `vec_c()` and the others, reach
it through `vec_restore()`. And
[`rbind()`](https://rdrr.io/r/base/cbind.html) and `rename()`, which
reach neither generic, have methods of their own. Two cases differ.
`vctrs::vec_rbind(x)` and `vctrs::vec_c(x)` hand back a bare tibble even
with nothing to combine with, where `dplyr::bind_rows(x)` keeps the
class. And `bind_cols()` and `vec_cbind()` build their answer on the
first argument's type. So `bind_cols(x, extra)` keeps the class while
`bind_cols(extra, x)` is a plain tibble holding the same columns.
`group_by()`, `rowwise()` and
[`tibble::as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)
return a grouped, a rowwise and a plain tibble, each still carrying the
attributes.

## Reproducibility

Seed the session before the call, as elsewhere in tidymodels; there is
no `seed` argument. On entry the function draws `2 * n` seeds in a
single `sample.int(.Machine$integer.max, 2 * n)` call, where `n` is the
number of outer folds. Fold `i` uses element `2 * i - 1` for its tuning
step and element `2 * i` for its outer fit, each applied with the
generator kind pinned. A fold's seed depends on its position, not on the
order the folds run in. So the same seed gives the same result serially
and in parallel, at any number of daemons. The two seeds are kept on the
result as `.tuning_seed` and `.outer_fit_seed`, and `?nested_tune_grid`
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

## Reproducing one fold by hand

Fold `i` is exactly the code below. On a
[`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md)
design, `resamples$inner_resamples[[i]]` stands for that inner rset
re-pointed at `analysis(resamples$splits[[i]])`, as the section on
finalizing a parameter range describes. Under a `select` other than the
default, the selection line is
[`tune::select_by_one_std_err()`](https://tune.tidymodels.org/reference/show_best.html)
or
[`tune::select_by_pct_loss()`](https://tune.tidymodels.org/reference/show_best.html)
with the rule's orderings and limit.

    set.seed(res$.tuning_seed[[i]], kind = "Mersenne-Twister",
             normal.kind = "Inversion", sample.kind = "Rejection")
    tuned <- tune_grid(object, resamples$inner_resamples[[i]], grid = grid,
                       param_info = param_info, metrics = metrics,
                       eval_time = eval_time,
                       control = extract_procedure(res)$control)
    final <- finalize_workflow(object, select_best(tuned, metric = <first metric>))
    set.seed(res$.outer_fit_seed[[i]], kind = "Mersenne-Twister",
             normal.kind = "Inversion", sample.kind = "Rejection")
    last_fit(final, resamples$splits[[i]], metrics = metrics,
             eval_time = eval_time,
             control = control_last_fit(event_level = event_level))

The siblings differ only in the tuning line.
[`tune::tune_bayes()`](https://tune.tidymodels.org/reference/tune_bayes.html)
takes `iter`, `initial` and `objective`, and finetune's racers take
`grid`.
[`finetune::tune_sim_anneal()`](https://finetune.tidymodels.org/reference/tune_sim_anneal.html)
takes `iter` and `initial`; each runs with the recorded control.
[`nested_fit_resamples()`](https://nestedtune.tidymodels.org/reference/nested_fit_resamples.md)
has no tuning line at all. A Bayesian fold also gives that control the
fold's tuning seed before the call,
`control$seed <- res$.tuning_seed[[i]]`.
[`tune::control_bayes()`](https://tune.tidymodels.org/reference/control_bayes.html)
otherwise draws the seed for its Gaussian process proposals from the
stream, and the recorded control carries none.

## When a fold fails

A fold that fails does not end the run. The remaining folds still run,
and the failed fold is recorded rather than discarded. Its `.completed`
is `FALSE` and its `.notes` holds what went wrong, in the shape tune
uses. That is one row naming the stage that failed, `"inner tuning"` or
`"outer fit"`, followed by tune's own notes about the cause. The number
of folds attempted and the number completed are stored as the
`folds_attempted` and `folds_completed` attributes.

Both stages can fail quietly. Inner tuning raises only once every
candidate has failed, and the outer fit does not raise at all: it hands
back a result with no metrics. Both are recorded as failures here. A
fold can also complete and carry notes. When only some of a fold's inner
resamples fail, tuning still returns a candidate and the fold finishes.
It finished on less of the inner design than was asked for, and the
notes say so.

A failed fold still records the candidates it got as far as scoring. A
fold that died at the outer fit had already tuned, so its
`.inner_metrics` holds the full table. Only a fold that never reached a
scored candidate holds a zero-row table. No fold is reported as having
searched a grid it did not.

The run warns when it finishes with any fold unfinished.
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
warns again, summarizing only the folds that ran and reporting how many
those were. It refuses outright when no fold completed: an estimate is
never reported for a design that did not execute.

## Parallel execution

The outer folds run in parallel when you have started mirai daemons, and
serially otherwise. There is no argument for this: start daemons before
the call and the loop uses them.

    mirai::daemons(4)
    res <- nested_tune_grid(wf, folds, grid = grid)
    mirai::daemons(0)

Two or more daemons are needed before the loop dispatches; below that it
stays serial, the threshold tune applies. Inner tuning always runs
serially whatever you set, because nested parallelism oversubscribes
cores. Results do not depend on how the loop ran. Each fold's seeds are
drawn up front and assigned by position, so the same seed gives the same
result serially and in parallel. The one difference carries no numbers:
a fold that failed on a daemon records that daemon's call stack in
`.notes` rather than yours.

Each fold is sent one copy of the data, not one per inner split. A
resampling split carries the whole frame it indexes, and serializing a
fold for a daemon would not preserve the single copy the design shares.
So each fold's splits are emptied before dispatch and refilled on the
worker. On a
[`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md)
design that is one copy per fold. A design from
[`rsample::nested_cv()`](https://rsample.tidymodels.org/reference/nested_cv.html)
holds an analysis frame per outer fold, so each fold also carries its
own, still once rather than once per inner split.

A recipe keeps a copy of the data it was created with, and a formula
carries the environment it was written in. So a workflow built inside a
function that holds a large object sends that object with every fold;
building the workflow at the top level avoids that.

Daemons are separate R processes, which has consequences worth knowing:

- They do not inherit your session's options,
  [`.libPaths()`](https://rdrr.io/r/base/libPaths.html) changes, or
  environment variables you set after launching them. Set what a fold
  needs with
  [`mirai::everywhere()`](https://mirai.r-lib.org/reference/everywhere.html),
  or start the daemons after setting it.

- They load nestedtune from an installed library. Under
  `devtools::load_all()` the daemons cannot see it, and the call stops
  rather than failing every fold with the same note. During development,
  prime them with `mirai::everywhere(pkgload::load_all("<path>"))`.

- Before dispatching, the call checks every connected daemon. It asks
  whether the daemon can load this package and each package the workflow
  and the tuner need. It also asks whether the daemon's copy defines
  each internal function this session's copy defines. If any daemon
  cannot, the call stops, naming how many are affected and what is
  missing. A daemon holding an older install loads the package and then
  fails every fold. The remedy is to reinstall and restart the pool,
  since a running daemon keeps the namespace it has already loaded.

- A daemon that does not answer is reported as a non-response, not as a
  missing package. The check waits 30 seconds by default; set
  `options(nestedtune.preflight_timeout = <milliseconds>)` to a single
  positive, finite number to change that. The first parallel call after
  starting daemons is the slow one, because the check makes every daemon
  load the tidymodels stack; later calls reuse what they loaded.

- That check is bounded; the folds themselves are not. If every daemon
  dies after folds are dispatched, the call blocks waiting for results
  that never arrive, and you interrupt it. No per-fold timeout is
  imposed, because a slow fold and a dead one would be
  indistinguishable.

A fold whose worker dies is recorded as a failed fold, like any other
failure. The run finishes, the other folds keep their results, and
`.notes` names the worker as the stage. Calling `mirai::daemons(0)`
while folds are outstanding produces exactly what a daemon dying
mid-fold produces, so it is recorded as fold failures rather than as a
cancellation.

Stopping a run is not a fold failure. Stopping the dispatched tasks
aborts the call and returns nothing, raising a `nestedtune_cancelled`
condition. That class inherits from `nestedtune_interrupted`, the class
a task interrupted on its own daemon raises. An interrupt at your own
console unwinds the blocking wait before any worker's value is
classified, so an ordinary interrupt propagates with no nestedtune class
attached. Either way the caller's RNG state is restored. The outstanding
folds are cancelled on the way out, so the pool goes idle rather than
computing folds nobody will read.

Cancelling needs mirai's dispatcher, which `mirai::daemons(n)` starts by
default. A pool started with `dispatcher = FALSE` cannot be stopped this
way, and you are told so at dispatch by a warning of class
`nestedtune_pool_not_cancellable`, once per call. Stopping is a request
rather than a guarantee: a fold inside a compiled fitting routine may
not be interruptible, and one that has nearly finished may simply
finish.

## Differences from calling tune directly

There is no `control` formal. A
[`tune::control_grid()`](https://tune.tidymodels.org/reference/control_grid.html)
passed through `...` as `control` reaches the inner `tune_grid()` in
every fold, and the final fit that re-runs the result. What runs is the
control passed, or tune's default when none is, with the slots this
package forces overwritten. The result records that effective control as
`extract_procedure(res)$control`. Every slot of `control_grid()` falls
under one of seven headings.

**Forced: `allow_par`.** Both tune calls a fold makes, the inner tuning
run and the outer scoring fit, run at `allow_par = FALSE`, whatever the
control carries. Parallelism belongs over the outer folds, as above, and
leaving it to a caller would put two pools in contention.

**Settable as its own argument: `event_level`.** The argument reaches
the inner `control_grid()` and the outer `control_last_fit()` alike, and
is the one place the level is set. A control left at tune's default
takes the argument's level. A control naming a level that is neither
tune's default nor the argument's is refused at entry, naming both.
`eval_time` is offered the same way, for the same reason: it changes a
number the caller is shown. It is an argument of `tune_grid()` and
`last_fit()` rather than a control slot.

**Refused: none.** No slot is refused on its own. What is refused at
entry is a control of another class, such as a `control_bayes()` that
tune itself would accept here, and the `event_level` conflict above.
tune gives
[`tune::control_resamples()`](https://tune.tidymodels.org/reference/control_grid.html)
and
[`tune::control_last_fit()`](https://tune.tidymodels.org/reference/control_last_fit.html)
the `control_grid` class, so either is accepted as what `control_grid()`
returns, its slots read under these headings.

**Passed through: `verbose`, `pkgs`, `parallel_over`, `workflow_size`.**
Each reaches `tune_grid()` as given. `verbose` prints from a serial run,
beside the progress the outer loop reports, and from a mirai daemon
where nothing shows it. `pkgs` is required before fitting on the serial
path as on the parallel one. `parallel_over` is not inert at
`allow_par = FALSE`. It still chooses how tune loops over resamples and
candidates, and with it the seed each model fit starts from. So a
stochastic engine's numbers differ between `"resamples"` and
`"everything"`. `workflow_size` is the size past which tune remarks on a
workflow `save_workflow` keeps.

**Kept from the outer fit: `save_pred`, `extract`.** Each reaches the
outer scoring fit as well as the inner run. With `save_pred = TRUE` the
result carries a `.predictions` list column: each completed fold's
predictions on its assessment rows, as
[`tune::last_fit()`](https://tune.tidymodels.org/reference/last_fit.html)
returns them. With `extract` a function, it carries an `.extracts` list
column: the function's value on each completed fold's fitted workflow. A
failed fold holds `NULL` in each. A fold whose extract errored stays
completed with `NULL` there and a note at location `"outer extract"`.
[`collect_predictions()`](https://nestedtune.tidymodels.org/reference/collect_predictions.nested_results.md)
and
[`collect_extracts()`](https://nestedtune.tidymodels.org/reference/collect_predictions.nested_results.md)
stack the two columns with the fold labels. What is kept is the outer
fit's; the inner run's predictions and extracts are still discarded with
that run.

**Not returned: `save_workflow`.** It lands on the inner `tune_results`,
which a fold record discards once the fold succeeds. So on a nested run
setting it costs the work and returns nothing; `extract = function(x) x`
keeps a fold's fitted workflow instead.
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
keeps its own tuning run as `$tuning`, where
[`extract_tune_results()`](https://nestedtune.tidymodels.org/reference/extract_tune_results.md)
reaches what it saved.

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

# What each fold chose. Disagreement here is selection instability, and
# it is information, not noise.
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
