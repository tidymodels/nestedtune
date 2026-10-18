# The export surface beside its tidymodels counterparts (M148)

**Provenance.** Ingested 2026-10-18 by M148 from the output of `benchmarks/export-surface.R` and from `DECISIONS.md` read by its headings. The script first ran on the source tree at `93c10377`. The pairing table and the verdicts read its output at `890190d2`, after the argument reorder. Both runs used the installed tune 2.1.0, finetune 1.3.0, workflowsets 1.1.1 and hardhat 1.4.3. M149 added the three arguments that the proposed verdicts asked for. It re-ran the script at `33d77fd6` under the same four versions and added the default verdicts.
Pagination: —.
Extraction: derived, a 2026-10-18 snapshot of this package's `NAMESPACE` and the four installed packages, which a new run of the script re-reads — observed 2026-10-18.

**Scope.** This page pairs each package-owned export, each method of an exported generic, and each result column with its tidymodels counterpart. It gives one verdict for each difference. A kept verdict cites the decision or reason that chose the difference. A changed verdict moves an argument after `...`, which breaks no call. A proposed verdict is any other change, left for a later plan. An added verdict marks a proposed argument that a later milestone added, and its row names that milestone. This page is not a style review of the help pages, which `tune-docs-comparison.md` owns. It is a reference, not an authority: status lives in `ROADMAP.md`, decisions in `DECISIONS.md`, and architecture in `DESIGN.md`.

**Evidence snapshot.**

- `NAMESPACE` and `R/` at `890190d2`: 16 package-owned functions, 59 methods of exported generics — observed 2026-10-18.
- tune 2.1.0, finetune 1.3.0, workflowsets 1.1.1 and hardhat 1.4.3, as installed — observed 2026-10-18.

## How the script reads the surface

`benchmarks/export-surface.R` keeps each `export()` whose object lives in this package's namespace. That drops the 16 re-exports from tune and ggplot2. It keeps each `S3method()` whose generic is one of the exports. It leaves out the methods of print, summary, predict, format, `[`, `names<-` and rbind. It also leaves out the vctrs and dplyr methods. For all of these, the generic sets the arguments. If the pairing table and `NAMESPACE` name different items, the script stops.

For each pair, the script prints the arguments one side lacks and any shared arguments in a different order. Its second half runs each orchestrator on a nested design of `mtcars` with three outer and four inner folds. Each run uses `save_pred = TRUE` and an `extract` function. Each counterpart runs on the inner resamples of outer fold 1 under the same control. The script then prints the column names that one result lacks.

## Pairings

A `nested_results` method pairs with tune's `tune_results` method. A `nested_results_set` method pairs with workflowsets' `workflow_set` method. An extractor on `nested_final_fit` pairs with tune's `tune_results` method. For `extract_parameter_set_dials()`, tune has no such method, so the extractor pairs with hardhat's generic. Each orchestrator's generic, `default`, `model_spec` and `workflow` method pairs with tune's or finetune's of the same tuner.

`nested_final_fit()` pairs with `tune::fit_best()`. Both refit a chosen candidate on all the training data. D-041 names `fit_best()` and `last_fit()` as the routes for a tuned fit without a nested run.

These items pair with none of the four packages:

- `agreement()`, `collect_selections()`, `extract_procedure()`, `extract_scored_candidates()`, `extract_tune_results()`, `collect_inner_metrics()`, and the `default` method of each. Each is a generic this package owns, with the signature `(x, ...)`. D-023 chose the two `extract_` generics for the final fit, D-039 chose `agreement()`, and D-052 chose the two `collect_` generics. `extract_procedure()` follows D-023's shape, and `DESIGN.md` records it (M67).
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

### Every item and its counterpart

The table has one row for each of the 75 items the script reads, in the order it prints them. It names the counterpart, or none.

| Item | Counterpart | Arguments |
|---|---|---|
| `agreement()` | none | no pair |
| `collect_inner_metrics()` | none | no pair |
| `collect_selections()` | none | no pair |
| `extract_procedure()` | none | no pair |
| `extract_scored_candidates()` | none | no pair |
| `extract_tune_results()` | none | no pair |
| `nested_final_fit()` | `tune::fit_best.tune_results()` | differ, see below |
| `nested_fit_resamples()` | `tune::fit_resamples()` | same |
| `nested_resamples()` | none | no pair |
| `nested_tune_bayes()` | `tune::tune_bayes()` | same |
| `nested_tune_grid()` | `tune::tune_grid()` | same |
| `nested_tune_race_anova()` | `finetune::tune_race_anova()` | same |
| `nested_tune_race_win_loss()` | `finetune::tune_race_win_loss()` | same |
| `nested_tune_sim_anneal()` | `finetune::tune_sim_anneal()` | same |
| `nested_workflow_map()` | `workflowsets::workflow_map()` | differ, see below |
| `selection_rule()` | none | no pair |
| `agreement.default()` | none | no pair |
| `agreement.nested_results()` | none | no pair |
| `agreement.nested_results_set()` | none | no pair |
| `augment.nested_final_fit()` | none | no pair |
| `augment.nested_results()` | `tune::augment.tune_results()` | differ, see below |
| `augment.nested_results_set()` | none | no pair |
| `autoplot.nested_results()` | `tune::autoplot.tune_results()` | differ, see below |
| `autoplot.nested_results_set()` | `workflowsets::autoplot.workflow_set()` | differ, see below |
| `collect_extracts.nested_results()` | `tune::collect_extracts.tune_results()` | same |
| `collect_extracts.nested_results_set()` | `workflowsets::collect_extracts.workflow_set()` | same |
| `collect_inner_metrics.default()` | none | no pair |
| `collect_inner_metrics.nested_results()` | `tune::collect_metrics.tune_results()` | differ, see below |
| `collect_inner_metrics.nested_results_set()` | `workflowsets::collect_metrics.workflow_set()` | differ, see below |
| `collect_metrics.nested_results()` | `tune::collect_metrics.tune_results()` | same |
| `collect_metrics.nested_results_set()` | `workflowsets::collect_metrics.workflow_set()` | differ, see below |
| `collect_notes.nested_results()` | `tune::collect_notes.tune_results()` | same |
| `collect_notes.nested_results_set()` | `workflowsets::collect_notes.workflow_set()` | same |
| `collect_predictions.nested_results()` | `tune::collect_predictions.tune_results()` | differ, see below |
| `collect_predictions.nested_results_set()` | `workflowsets::collect_predictions.workflow_set()` | differ, see below |
| `collect_selections.default()` | none | no pair |
| `collect_selections.nested_results()` | none | no pair |
| `collect_selections.nested_results_set()` | none | no pair |
| `compute_metrics.nested_results()` | `tune::compute_metrics.tune_results()` | same |
| `compute_metrics.nested_results_set()` | none | no pair |
| `extract_fit_engine.nested_final_fit()` | `tune::extract_fit_engine.tune_results()` | same |
| `extract_fit_parsnip.nested_final_fit()` | `tune::extract_fit_parsnip.tune_results()` | same |
| `extract_mold.nested_final_fit()` | `tune::extract_mold.tune_results()` | same |
| `extract_parameter_set_dials.nested_final_fit()` | `hardhat::extract_parameter_set_dials()` | same |
| `extract_preprocessor.nested_final_fit()` | `tune::extract_preprocessor.tune_results()` | same |
| `extract_procedure.default()` | none | no pair |
| `extract_procedure.nested_final_fit()` | none | no pair |
| `extract_procedure.nested_results()` | none | no pair |
| `extract_recipe.nested_final_fit()` | `tune::extract_recipe.tune_results()` | same |
| `extract_scored_candidates.default()` | none | no pair |
| `extract_scored_candidates.nested_final_fit()` | none | no pair |
| `extract_spec_parsnip.nested_final_fit()` | `tune::extract_spec_parsnip.tune_results()` | same |
| `extract_tune_results.default()` | none | no pair |
| `extract_tune_results.nested_final_fit()` | none | no pair |
| `extract_workflow.nested_final_fit()` | `tune::extract_workflow.tune_results()` | same |
| `extract_workflow.nested_results_set()` | `workflowsets::extract_workflow.workflow_set()` | same |
| `nested_fit_resamples.default()` | `tune::fit_resamples.default()` | same |
| `nested_fit_resamples.model_spec()` | `tune::fit_resamples.model_spec()` | differ, see below |
| `nested_fit_resamples.workflow()` | `tune::fit_resamples.workflow()` | differ, see below |
| `nested_tune_bayes.default()` | `tune::tune_bayes.default()` | same |
| `nested_tune_bayes.model_spec()` | `tune::tune_bayes.model_spec()` | differ, see below |
| `nested_tune_bayes.workflow()` | `tune::tune_bayes.workflow()` | differ, see below |
| `nested_tune_grid.default()` | `tune::tune_grid.default()` | same |
| `nested_tune_grid.model_spec()` | `tune::tune_grid.model_spec()` | differ, see below |
| `nested_tune_grid.workflow()` | `tune::tune_grid.workflow()` | differ, see below |
| `nested_tune_race_anova.default()` | `finetune::tune_race_anova.default()` | same |
| `nested_tune_race_anova.model_spec()` | `finetune::tune_race_anova.model_spec()` | differ, see below |
| `nested_tune_race_anova.workflow()` | `finetune::tune_race_anova.workflow()` | differ, see below |
| `nested_tune_race_win_loss.default()` | `finetune::tune_race_win_loss.default()` | same |
| `nested_tune_race_win_loss.model_spec()` | `finetune::tune_race_win_loss.model_spec()` | differ, see below |
| `nested_tune_race_win_loss.workflow()` | `finetune::tune_race_win_loss.workflow()` | differ, see below |
| `nested_tune_sim_anneal.default()` | `finetune::tune_sim_anneal.default()` | same |
| `nested_tune_sim_anneal.model_spec()` | `finetune::tune_sim_anneal.model_spec()` | differ, see below |
| `nested_tune_sim_anneal.workflow()` | `finetune::tune_sim_anneal.workflow()` | differ, see below |
| `outcome_names.nested_final_fit()` | `tune::outcome_names.tune_results()` | same |

## Argument verdicts

### The orchestrators

These rows cover the `workflow` and `model_spec` methods of all six orchestrators. Each argument appears in both methods.

| Argument | Side | Verdict | Reason |
|---|---|---|---|
| `control` | theirs only | kept | D-042: a control reaches the inner call through `...`. topepo reserves the `control` formal for a control of the outer work. |
| `event_level` | ours only | kept | D-030 and D-042: it stays an argument beside the control. A control that names another level is an error. |
| `select` | ours only, five tuners | kept | D-056: it is the rule that picks each fold's candidate. tune leaves that choice to a later `select_best()` call. `nested_fit_resamples()` tunes nothing and has no `select` (D-057). |
| order of `eval_time`, `objective`, `initial` | `nested_tune_bayes()` | changed | The order was `metrics, initial, objective, event_level, eval_time`. It is now `metrics, event_level, eval_time, objective, initial`, so the shared arguments follow `tune_bayes()`. No decision chose the old order. D-069 kept each function's formals at the change to generics, and D-117 narrows that clause for this order. |
| order of `eval_time`, `initial` | `nested_tune_sim_anneal()` | changed | The order was `metrics, initial, event_level, eval_time`. It is now `metrics, event_level, eval_time, initial`, so the shared arguments follow `tune_sim_anneal()`. No decision chose the old order. D-117 narrows D-069 here too. |

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
| `verbose` | both, since M149 | added | M149 added `verbose = FALSE` between `fn` and `...`, where `workflow_map()` has it. It logs each workflow as it starts and as it finishes without error. |

### The readers on `nested_results`

| Method | Argument | Side | Verdict | Reason |
|---|---|---|---|---|
| `augment()` | `parameters` | theirs only | kept | D-092: `augment()` joins each row's saved prediction, or the D-090 average, and each fold predicted with the candidate it selected. So no single candidate exists to choose, as `?augment.nested_results` states. |
| `collect_predictions()` | `parameters` | theirs only | kept | D-090, as above. |
| `collect_inner_metrics()` against tune's `collect_metrics()` | `summarize` | theirs only | kept | D-043: `.inner_metrics` holds each fold's inner metrics in summarized form. There are no per-resample rows to return. |
| `collect_inner_metrics()` against tune's `collect_metrics()` | `type` | both, since M149 | added | M149 added `type = c("long", "wide")` after `...`, as the method in tune has it. |
| `autoplot()` | `width` | theirs only | kept | In tune, `width` sets the width of the confidence interval bars. The `"performance"` view here plots each outer fold's score as a point and draws no interval bars. |
| `autoplot()` | `call` | theirs only | kept | tune passes its error-reporting frame through `call`, with `rlang::current_env()` as the default. It is plumbing for the helpers in tune, not a setting for the plot. |

### The readers on `nested_results_set`

| Method | Argument | Side | Verdict | Reason |
|---|---|---|---|---|
| `collect_metrics()` | `type` | ours only | kept | The method follows the `tune_results` method in tune and the `nested_results` method here, which both take `type`. |
| `collect_inner_metrics()` against workflowsets' `collect_metrics()` | `summarize` | theirs only | kept | D-043, as on `nested_results`. |
| `collect_inner_metrics()` against workflowsets' `collect_metrics()` | `type` | ours only, since M149 | kept | The method follows the `nested_results` method and `collect_metrics()` on the set here, which both take `type`, as `collect_metrics()` in tune does. |
| `collect_predictions()` | `parameters` | theirs only | kept | D-090, as on `nested_results`. |
| `collect_predictions()` | `select_best`, `metric` | theirs only | kept | D-054: the outer predictions come from the candidate each fold selected. There are no other candidates to filter out. |
| `autoplot()` | `rank_metric`, `select_best` | theirs only | kept | D-058: the set has no ranking or best-workflow view, because a ranking of nested estimates is the reading that IP3 forbids. |
| `autoplot()` | `std_errs` | theirs only | kept | In workflowsets, `std_errs` sets how many standard errors the interval bars span. The set's plot here draws each fold's score as a point and the estimate as a flat rule, with no interval bars. |
| `autoplot()` | `id` | both, since M149 | added | M149 added `id = NULL` after `...`. One `wflow_id` draws the plot that `autoplot()` draws for that workflow's `nested_results`. |
| `autoplot()` | order of `id` | ours after `...`, theirs third | kept | The arguments before `...` keep the order of `autoplot.tune_results()`, so one call works on both classes, as the next row says. After `...`, `id` must be named, so adding it broke no call. |
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
| `.iter` | theirs only, Bayes and annealing | kept | A row here is an outer fold, which has no search iteration. Each fold's `.inner_metrics` carries `.iter` for these two tuners. D-043 states it for the Bayesian tuner, and `R/tuner.R` marks both tuners as iterating. |
| `.order` | theirs only, both races | kept | A row here is an outer fold, and the outer folds are not raced. The race happens inside each fold. |
| `workflow` | ours only, the set | kept | D-058: the set is a tibble of `wflow_id`, `workflow` and `result`. |
| `info`, `option` | theirs only, the set | kept | D-058: the set does not carry the `workflow_set` class. At run time, each workflow's options are merged into its call. |

The `result` of each set row has the same columns as the result of a single run.

## What the proposed verdicts asked for

M148 left three changes for a later plan, and M149 added them. They are `verbose` on `nested_workflow_map()`, `type` on `collect_inner_metrics()`, and `id` on `autoplot()` for a `nested_results_set`. `type` and `id` come after `...`. `verbose` comes before `...`, in the place `workflow_map()` gives it. Every argument in `...` must be named, so this broke no call. A third argument passed by position now lands in `verbose`, and its refusal says that every argument of `fn` must be named.

## Default verdicts

The script compares argument names and order, not defaults. M149 compared the defaults once, on 2026-10-18 at `33d77fd6`. For every pair in the script's `pairs` table, it compared the deparsed default of each argument that both sides share, other than `...`. These are the defaults that differ.

| Item | Argument | Ours | Theirs | Verdict | Reason |
|---|---|---|---|---|---|
| `nested_workflow_map()` | `fn` | `"nested_tune_grid"` | `"tune_grid"` | kept | Each default names the grid search of its own package. |
| `nested_tune_bayes()`, `workflow` and `model_spec` methods | `objective` | `tune::exp_improve()` | `exp_improve()` | kept | The same call. Only the namespace prefix differs. |
| `autoplot.nested_results()` | `type` | `"parameters"` first | `"marginals"` first | kept | D-019 made the view of what each outer fold selected the default. There is no `"marginals"` view, because the outer folds score one candidate each. |
| `autoplot.nested_results_set()` | `type` | `"parameters"` first | `"class"` | kept | The `type` in workflowsets is another setting, as the order row above says. |
| `autoplot.nested_results_set()` | `id` | `NULL` | `"workflow_set"` | kept | M149's plan gate chose `NULL`, because a workflow can have the id `"workflow_set"`, and `nested_final_fit()` reads an id with no such word. |
| `collect_predictions.nested_results_set()` | `summarize` | `FALSE` | `TRUE` | kept | The default follows the `nested_results` method here and the `tune_results` method in tune, which both default to `FALSE`. So one call reads the same rows from a run and from a set. D-090 makes the average an explicit request. |
| `compute_metrics.nested_results()` | `event_level` | `NULL` | `"first"` | kept | `NULL` takes the level the run recorded, and `"first"` for a run that recorded none, as `?compute_metrics.nested_results` says. |
