# M096 param survey

One row per `#' @param` tag the AC1 grep prints at the branch point (`9dea05d`, 24 tags). The upstream text is the `\item` of the installed Rd (tune 2.1.0, finetune 1.3.0, workflowsets 1.1.1), read through `tools::Rd_db()` and whitespace-collapsed. `inherit` is required when the upstream page documents the argument and neither text names a value one side accepts and the other refuses or adds. A `local` row names that value. An `inherit` row names where each removed sentence went (AC2).

Two facts the rows lean on were run at the branch point: `tune::tune_grid()` refuses a grid data frame with a column not marked for tuning (`.check_grid`, "has not been marked for tuning by `tune()`"), and `tune::tune_bayes(iter = 0)` returns an `iteration_results` with no proposal.

## nested_tune_grid (`R/nested-tune-grid.R`, upstream `tune::tune_grid`)

| Argument | Disposition | Upstream text | Local text (branch point) | Reason / where the removed text went |
|---|---|---|---|---|
| `object` | local | A parsnip model specification or an unfitted workflow(). No tuning parameters are allowed; if arguments have been marked with tune(), their values must be finalized. | A workflow with at least one parameter marked for tuning with tune(). A workflow with no marker is refused, and nested_fit_resamples() scores one on the same design. | Upstream accepts a parsnip model specification. This refuses one. Upstream requires no `tune()` marker. This requires one. |
| `resamples` | local | An rset resampling object created from an rsample function, such as rsample::vfold_cv(). | A nested resampling design from nested_resamples() or rsample::nested_cv(), one row per outer fold. The section on nested designs says what the design must hold. | Upstream accepts a plain `rset`. This refuses one and requires a nested design. |
| `...` | local | Not currently used. | A control object from tune::control_grid(), passed as control, and nothing else. Every argument after ... is matched by name. The section on differences from tune says what becomes of each control slot. | Upstream takes nothing here. This takes `control`. |
| `param_info` | inherit | A dials::parameters() object or NULL. If none is given, a parameters set is derived from other arguments. Passing this argument can be useful when parameter ranges need to be customized. | A dials::parameters() object, or NULL to let tune derive one from the workflow. The section on finalizing a parameter range says where a range that depends on the data is finalized. | Same values. The first sentence is said by the inherited text. The second moved to the page's Details. |
| `grid` | inherit | A data frame of tuning combinations or a positive integer. The data frame should have columns for each parameter being tuned and rows for tuning parameter candidates. An integer denotes the number of candidate parameter sets to be created automatically. | A data frame of candidate parameter values, or a positive whole number for the size of a grid tune generates. A data frame has one column per tuned parameter and no other column. | Same values: tune refuses an extra column too (`.check_grid`). The first sentence is said by the inherited text. "A data frame has one column per tuned parameter and no other column." moved to the page's Details. |
| `event_level` | local | (not an argument of `tune_grid()`, a `control_grid()` slot) | "first" (the default) or "second". It names which level of a two-class outcome is the event, and applies to the inner tuning run and the outer scoring fit alike. | The upstream page does not document it as an argument. |
| `eval_time` | local | A numeric vector of time points where dynamic event time metrics should be computed (e.g. the time-dependent ROC curve, etc). The values must be non-negative and should probably be no greater than the largest event time in the training set (See Details below). | A numeric vector of evaluation times for a censored regression model, or NULL (the default) to leave the choice to tune. The section on evaluation times says what this package refuses. | This refuses an empty vector and any missing or non-finite element at entry (`check_eval_time()`); tune accepts them and drops or coerces them later. |
| `select` | local | (no such argument) | A selection_rule() naming which of tune's selectors each outer fold picks its candidate with, on its own inner run and the first metric. The default is tune::select_best(). | Package-own argument. |

`metrics` was already inherited from `tune::tune_grid` at the branch point.

## nested_tune_bayes (`R/nested-tune-bayes.R`, upstream `tune::tune_bayes`)

| Argument | Disposition | Upstream text | Local text (branch point) | Reason / where the removed text went |
|---|---|---|---|---|
| `...` | local | Not currently used. | A control object from tune::control_bayes(), as control, and nothing else. Every argument after ... is matched by name. The section on differences from tune says what becomes of each slot. | Upstream takes nothing here. This takes `control`. |
| `iter` | inherit | The maximum number of search iterations. | The number of search iterations, a non-negative whole number. The section on the iterations says what 0 does. | Same values: tune accepts `iter = 0` and this passes it through. Both sentences moved to the page's Details. |
| `initial` | local | An initial set of results in a tidy format (as would result from tune_grid()) or a positive integer. It is suggested that the number of initial results be greater than the number of parameters being optimized. | The number of candidates each fold scores before the first iteration, a whole number of at least 2. A tune_results object, which tune also accepts here, is refused. | Upstream accepts a `tune_results`. This refuses one. |
| `objective` | local | A character string for what metric should be optimized or an acquisition function object. | An acquisition function from tune. It decides which candidate the Gaussian process proposes next: tune::exp_improve() (the default), tune::prob_improve() or tune::conf_bound(). | Upstream accepts a character string. This refuses one (`check_objective()`). |

## nested_tune_race (`R/nested-tune-race.R`, upstream `finetune::tune_race_anova`)

| Argument | Disposition | Upstream text | Local text (branch point) | Reason / where the removed text went |
|---|---|---|---|---|
| `...` | local | Not currently used. | A control object from finetune::control_race(), as control, and nothing else. Every argument after ... is matched by name. The section on differences from finetune says what becomes of each slot. | Upstream takes nothing here. This takes `control`. |
| `grid` | inherit | A data frame of tuning combinations or a positive integer. The data frame should have columns for each parameter being tuned and rows for tuning parameter candidates. An integer denotes the number of candidate parameter sets to be created automatically. | A data frame of candidate parameter values, or a positive whole number for the size of a grid to generate, the design the race is offered. A data frame must have one column per tuned parameter and no other column. | Same values, as on the grid page (finetune's grid check is tune's). The first sentence's opening is said by the inherited text; its closing clause, "the design the race is offered", and the second sentence moved to the page's Details. |

## nested_tune_sim_anneal (`R/nested-tune-sim-anneal.R`, upstream `finetune::tune_sim_anneal`)

| Argument | Disposition | Upstream text | Local text (branch point) | Reason / where the removed text went |
|---|---|---|---|---|
| `...` | local | Not currently used. | A control object from finetune::control_sim_anneal() as control and nothing else, matched by name. The section on differences from finetune says what becomes of each slot. | Upstream takes nothing here. This takes `control`. |
| `iter` | local | The maximum number of search iterations. | The number of search iterations, a whole number of at least 1. The section on the iterations says why 0 is refused. | finetune accepts `iter = 0`. This refuses it. |
| `initial` | local | An initial set of results in a tidy format (as would the result of tune::tune_grid(), tune::tune_bayes(), tune_race_win_loss(), or tune_race_anova()) or a positive integer. If the initial object was a sequential search method, the simulated annealing iterations start after the last iteration of the initial results. | The number of candidates each fold scores before the first iteration, a whole number of at least 1 (finetune's default). A tune_results object, which finetune also accepts here, is refused. | Upstream accepts a `tune_results`. This refuses one. |

## nested_fit_resamples (`R/nested-fit-resamples.R`, upstream `tune::fit_resamples`)

| Argument | Disposition | Upstream text | Local text (branch point) | Reason / where the removed text went |
|---|---|---|---|---|
| `object` | local | A parsnip model specification or an unfitted workflow(). No tuning parameters are allowed; if arguments have been marked with tune(), their values must be finalized. | A workflow with no parameter marked for tuning with tune(), every value fixed as tune::fit_resamples() takes it. A workflow carrying a marker is refused at entry. | Upstream accepts a parsnip model specification. This refuses one. |
| `...` | local | Currently unused. | A control object from tune::control_resamples(), as control, and nothing else. Every argument after ... is matched by name. The section on differences from tune says what becomes of each slot. | Upstream takes nothing here. This takes `control`. |
| `metrics` | inherit | A yardstick::metric_set(), or NULL to compute a standard set of metrics. | A yardstick::metric_set(), or NULL to use tune's defaults for the model's mode. There is no inner run to select on, so the set's order carries no weight here. | Same values. The first sentence is said by the inherited text. The second moved to the page's Details. |
| `event_level` | local | (not an argument of `fit_resamples()`, a `control_resamples()` slot) | "first" (the default) or "second". It names which level of a two-class outcome is the event in the one tune call a fold makes, the outer scoring fit. | The upstream page does not document it as an argument. |
| `eval_time` | local | (as `tune_grid`'s) | A numeric vector of evaluation times for a censored regression model, or NULL (the default) to leave the choice to tune. Anything not numeric, an empty vector, or an element that is missing, negative or not finite is refused at entry. | This refuses an empty vector and any missing or non-finite element at entry; tune accepts them. |

## nested_workflow_map (`R/nested-workflow-map.R`, upstream `workflowsets::workflow_map`)

| Argument | Disposition | Upstream text | Local text (branch point) | Reason / where the removed text went |
|---|---|---|---|---|
| `fn` | local | The name of the function to run, as a character. Acceptable values are: "tune_grid", "tune_bayes", "fit_resamples", "tune_race_anova", "tune_race_win_loss", or "tune_sim_anneal". Note that users need not provide the namespace or parentheses in this argument, e.g. provide "tune_grid" rather than "tune::tune_grid" or "tune_grid()". | The name of the orchestrator to run each workflow through: "nested_tune_grid" (the default), "nested_tune_bayes", "nested_tune_race_anova" or "nested_tune_race_win_loss". "nested_tune_sim_anneal" and "nested_fit_resamples" are the other two. | The accepted names differ: upstream takes tune's names, this takes the orchestrators'. |
| `...` | local | Options to pass to the modeling function. See details below. | The orchestrator's arguments, every one named: the nested design as resamples (required), any of its other arguments, and a control as it takes one through its own .... A name the orchestrator fn names does not take is refused, as is an unnamed argument or a call with no resamples. | This refuses an unnamed argument, an unknown name and a call with no `resamples`; upstream does not document those refusals. |

`object` was already inherited from `workflowsets::workflow_map` at the branch point.

## Totals

24 tags: 5 `inherit` (`nested_tune_grid` `param_info` and `grid`, `nested_tune_bayes` `iter`, `nested_tune_race` `grid`, `nested_fit_resamples` `metrics`), 19 `local`.
