# The export surface beside its tidymodels counterparts (M148)

**Provenance.** Ingested 2026-10-18 by M148 from the output of `benchmarks/export-surface.R` and from `DECISIONS.md` read by its headings. The script ran on the source tree at `93c10377` against the installed tune 2.1.0, finetune 1.3.0, workflowsets 1.1.1 and hardhat 1.4.3.
Pagination: —.
Extraction: derived, a 2026-10-18 snapshot of this package's `NAMESPACE` and the four installed packages, which a new run of the script re-reads — observed 2026-10-18.

**Scope.** This page pairs each package-owned export, each method of an exported generic, and each result column with its tidymodels counterpart. It gives one verdict for each difference. A kept verdict cites the decision or reason that chose the difference. A changed verdict moves an argument after `...`, which breaks no call. A proposed verdict is any other change, left for a later plan. This page is not a style review of the help pages, which `tune-docs-comparison.md` owns. It is a reference, not an authority: status lives in `ROADMAP.md`, decisions in `DECISIONS.md`, and architecture in `DESIGN.md`.

**Evidence snapshot.**

- `NAMESPACE` and `R/` at `93c10377`: 16 package-owned functions, 59 methods of exported generics — observed 2026-10-18.
- tune 2.1.0, finetune 1.3.0, workflowsets 1.1.1 and hardhat 1.4.3, as installed — observed 2026-10-18.

## How the script reads the surface

`benchmarks/export-surface.R` keeps each `export()` whose object lives in this package's namespace. That drops the 16 re-exports from tune and ggplot2. It keeps each `S3method()` whose generic is one of the exports. It leaves out the methods of print, summary, predict, format, `[`, `names<-` and rbind. It also leaves out the vctrs and dplyr methods. For all of these, the generic sets the arguments. If the pairing table and `NAMESPACE` name different items, the script stops.

For each pair, the script prints the arguments one side lacks and any shared arguments in a different order. Its second half runs each orchestrator on a nested design of `mtcars` with three outer and four inner folds. Each run uses `save_pred = TRUE` and an `extract` function. Each counterpart runs on the inner resamples of outer fold 1 under the same control. The script then prints the column names that one result lacks.

## Pairings

A `nested_results` method pairs with tune's `tune_results` method. A `nested_results_set` method pairs with workflowsets' `workflow_set` method. An extractor on `nested_final_fit` pairs with tune's `tune_results` method. For `extract_parameter_set_dials()`, tune has no such method, so the extractor pairs with hardhat's generic. Each orchestrator's generic, `default`, `model_spec` and `workflow` method pairs with tune's or finetune's of the same tuner.

`nested_final_fit()` pairs with `tune::fit_best()`. Both refit a chosen candidate on all the training data. D-041 names `fit_best()` and `last_fit()` as the routes for a tuned fit without a nested run.

These items pair with none of the four packages:

- `agreement()`, `collect_selections()`, `extract_procedure()`, `extract_scored_candidates()`, `extract_tune_results()`, `collect_inner_metrics()`, and the `default` method of each. Each is a generic this package owns (D-023, D-039, D-052), with the signature `(x, ...)`.
- `nested_resamples(data, outside, inside, ...)`. Its counterpart is `rsample::nested_cv(data, outside, inside)`, outside the four packages. The three shared arguments are in the same order.
- `selection_rule(rule, ..., limit)`. It builds the rule that an orchestrator's `select` takes (D-056). Its `limit` has the meaning of the `limit` of `tune::select_by_pct_loss()`.
- `augment.nested_final_fit(x, new_data, eval_time, ...)`. No `augment()` method in tune has a `new_data` argument. The object holds a trained workflow, and `workflows::augment.workflow()` has the same four arguments in the same order.
- `augment.nested_results_set()` and `compute_metrics.nested_results_set()`. workflowsets defines no method for either generic.

These pairs have the same arguments in the same order:

- the six orchestrator generics and their `default` methods,
- `collect_extracts()`, `collect_notes()`, `collect_metrics()` and `compute_metrics()` on `nested_results`,
- `collect_extracts()` and `collect_notes()` on `nested_results_set`,
- `extract_workflow()` on `nested_final_fit` and on `nested_results_set`,
- the seven other `nested_final_fit` extractors, and `outcome_names()`.

## Argument verdicts

### The orchestrators

These rows cover the `workflow` and `model_spec` methods of all six orchestrators. Each argument appears in both methods.

| Argument | Side | Verdict | Reason |
|---|---|---|---|
| `control` | theirs only | kept | D-042: a control reaches the inner call through `...`. topepo reserves the `control` formal for a control of the outer work. |
| `event_level` | ours only | kept | D-030 and D-042: it stays an argument beside the control. A control that names another level is an error. |
| `select` | ours only, five tuners | kept | D-056: it is the rule that picks each fold's candidate. tune leaves that choice to a later `select_best()` call. `nested_fit_resamples()` tunes nothing and has no `select` (D-057). |
| order of `eval_time`, `objective`, `initial` | `nested_tune_bayes()` | changed | The order was `metrics, initial, objective, event_level, eval_time`. It is now `metrics, event_level, eval_time, objective, initial`, so the shared arguments follow `tune_bayes()`. No decision chose the old order. |
| order of `eval_time`, `initial` | `nested_tune_sim_anneal()` | changed | The order was `metrics, initial, event_level, eval_time`. It is now `metrics, event_level, eval_time, initial`, so the shared arguments follow `tune_sim_anneal()`. No decision chose the old order. |

The grid, race and `nested_fit_resamples()` methods already had tune's order among the shared arguments.

### `nested_final_fit()` and `tune::fit_best()`

| Argument | Side | Verdict | Reason |
|---|---|---|---|
| `x` | theirs only | kept | D-041: the function takes the workflow as `object` and the nested results as `results`. `fit_best()` reads the workflow from a `tune_results` that was saved with `save_workflow = TRUE`. |
| `object`, `results` | ours only | kept | D-041, as above. |
| `id` | ours only | kept | D-058: for a `nested_results_set` as `object`, it names the workflow to fit. |
| `metric`, `parameters` | theirs only | kept | D-041 and D-056: the recorded selection rule picks the candidate. So the final model comes from the procedure that the estimate describes. |
| `eval_time` | theirs only | kept | D-041 removed it, because the value is read from `results`. |
| `verbose` | theirs only | kept | The re-run tunes under the control that `results` recorded. The `verbose` slot of that control sets what the tuning prints. |
| `add_validation_set` | theirs only | kept | The function always fits on all the rows of the data the design was built on. No held-out validation rows exist to add. |

### `nested_workflow_map()` and `workflowsets::workflow_map()`

| Argument | Side | Verdict | Reason |
|---|---|---|---|
| `seed` | theirs only | kept | D-011 and D-058: the caller calls `set.seed()` first. The generator state is put back before each workflow, so every workflow runs under the same per-fold seeds. `workflow_map()` gets the same pairing by seeding each workflow with `seed`. |
| `verbose` | theirs only | proposed | Add `verbose` to log each workflow as it starts and ends. No decision chose its absence. |

### The readers on `nested_results`

| Method | Argument | Side | Verdict | Reason |
|---|---|---|---|---|
| `augment()` | `parameters` | theirs only | kept | D-090: each fold predicted with the candidate it selected, so no single candidate exists to choose. |
| `collect_predictions()` | `parameters` | theirs only | kept | D-090, as above. |
| `collect_inner_metrics()` against tune's `collect_metrics()` | `summarize` | theirs only | kept | D-043: `.inner_metrics` holds each fold's inner metrics in summarized form. There are no per-resample rows to return. |
| `collect_inner_metrics()` against tune's `collect_metrics()` | `type` | theirs only | proposed | Add `type = c("long", "wide")`, as the method in tune has. No decision chose its absence. |
| `autoplot()` | `width` | theirs only | kept | In tune, `width` sets the width of the confidence interval bars. The `"performance"` view here plots each outer fold's score as a point and draws no interval bars. |
| `autoplot()` | `call` | theirs only | kept | tune passes its error-reporting frame through `call`, with `rlang::current_env()` as the default. It is plumbing for the helpers in tune, not a setting for the plot. |

### The readers on `nested_results_set`

| Method | Argument | Side | Verdict | Reason |
|---|---|---|---|---|
| `collect_metrics()` | `type` | ours only | kept | The method follows the `tune_results` method in tune and the `nested_results` method here, which both take `type`. |
| `collect_inner_metrics()` against workflowsets' `collect_metrics()` | `summarize` | theirs only | kept | D-043, as on `nested_results`. |
| `collect_predictions()` | `parameters` | theirs only | kept | D-090, as on `nested_results`. |
| `collect_predictions()` | `select_best`, `metric` | theirs only | kept | D-054: the outer predictions come from the candidate each fold selected. There are no other candidates to filter out. |
| `autoplot()` | `rank_metric`, `select_best`, `std_errs` | theirs only | kept | D-058: the set has no ranking or best-workflow view, because a ranking of nested estimates is the reading that IP3 forbids. |
| `autoplot()` | `id` | theirs only | proposed | Add `id` to plot one workflow's `nested_results`, as `autoplot(x$result[[i]])` does today. No decision chose its absence. |
| `autoplot()` | `eval_time` | ours only | kept | The method follows `autoplot.nested_results()` and `autoplot.tune_results()` in tune, which both take it. |
| `autoplot()` | order of `type` and `metric` | both before `...` | kept | The order here is `object, type, metric`, as in `autoplot.tune_results()`, so one call works on both classes. The `type` in workflowsets is another setting with the same name: it picks how points are colored. |

## Column verdicts

Each orchestrator's result and its counterpart's result share `splits`, `id`, `.metrics`, `.notes`, `.predictions` and `.extracts`, in that order.

| Column | Side | Verdict | Reason |
|---|---|---|---|
| `.selected` | ours only | kept | D-043: it records the candidate that each fold's outer fit used. |
| `.inner_metrics` | ours only | kept | D-043: it holds each fold's summarized inner metrics. |
| `.completed` | ours only | kept | D-031 and D-052: it marks whether a fold completed, and the readers read completed folds only. |
| `.tuning_seed`, `.outer_fit_seed` | ours only | kept | D-011: these are the two seeds that reproduce each fold. |
| `.iter` | theirs only, Bayes and annealing | kept | A row here is an outer fold, which has no search iteration. Each fold's `.inner_metrics` carries `.iter` for these two tuners (D-043). |
| `.order` | theirs only, both races | kept | A row here is an outer fold, and the outer folds are not raced. The race happens inside each fold. |
| `workflow` | ours only, the set | kept | D-058: the set is a tibble of `wflow_id`, `workflow` and `result`. |
| `info`, `option` | theirs only, the set | kept | D-058: the set does not carry the `workflow_set` class. At run time, each workflow's options are merged into its call. |

The `result` of each set row has the same columns as the result of a single run.

## What the proposed verdicts ask for

Three changes are left for a later plan, and one ROADMAP candidate row holds them. They are a `verbose` argument on `nested_workflow_map()`, a `type` argument on `collect_inner_metrics()`, and an `id` argument on `autoplot()` for a `nested_results_set`. Each change can add its argument after `...`, and an argument there breaks no call.
