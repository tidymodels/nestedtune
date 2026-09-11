# Changelog

## nestedtune 0.0.0.9000

- Every result records the model specification and the preprocessor of
  the workflow it ran under, as the `workflow` entry of the record
  [`extract_procedure()`](https://nestedtune.tidymodels.org/reference/extract_procedure.md)
  returns. The entry holds the model’s type, engine, mode and arguments,
  and the preprocessor, in deparsed form, with recipe step ids and the
  data left out. Case weights and a postprocessor are not part of the
  entry.
  [`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
  compares the workflow it is handed against that entry and refuses one
  whose model or preprocessor differs, with class
  `nestedtune_workflow_mismatch`, naming the part that differs. A
  workflow rebuilt from the same code is accepted. A results object
  saved before this entry existed is refused as one from an earlier
  version.

- Every help page is rewritten for someone who has run `tune_grid()` and
  never nested: no roxygen sentence over 30 words, no sentence naming
  more than four code spans, each page opening on what the reader gets
  from it, and the words “procedure”, “orchestrator” and “candidate” set
  up once on
  [`?nested_tune_grid`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
  and either set up again or preceded by a link to that page wherever
  another page uses them.
  [`extract_scored_candidates()`](https://nestedtune.tidymodels.org/reference/extract_scored_candidates.md),
  [`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md),
  [`selection_rule()`](https://nestedtune.tidymodels.org/reference/selection_rule.md)
  and
  [`extract_procedure()`](https://nestedtune.tidymodels.org/reference/extract_procedure.md)
  have new titles; nothing else about any page’s arguments or behaviour
  changed.

- The four guides, the parallel article and the README are rewritten for
  someone who has run `tune_grid()` and never nested: no prose sentence
  over 30 words, the words “procedure” and “candidate” set up on each
  page before it relies on them, and the word “orchestrator” gone. Those
  pages, and this file, keep each explanation on one page with a link
  from the others. The site-only article “Why nest: a simulation” and
  its simulation script are removed; the estimate page’s cited
  measurements make the same point.

- Every help page is rewritten for a tidymodels user: argument entries
  of at most two sentences, detail under section headings, the arguments
  an orchestrator shares with the tune, finetune or workflowsets
  function it wraps inherited from that page, and examples written with
  `|>` that run under `R CMD check`.
  [`?nested_resamples`](https://nestedtune.tidymodels.org/reference/nested_resamples.md)
  carries the memory table the README used to.

- The documentation site no longer carries pages built from files
  internal to the repository, and its build fails if any tracked
  markdown file other than the README, this file, the licence, the code
  of conduct or the contributing guide gets a top-level page.

- [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  on a `nested_results_set` with `type = "performance"` adds a subtitle
  sentence counting the workflows whose average for a metric comes from
  fewer outer folds than the workflow completed, pointing at
  [`summary()`](https://rdrr.io/r/base/summary.html) for which metric
  and how many folds.

- A `nested_results_set` keeps its class only while every row is one of
  the run’s own workflows, so dropping or reordering rows and adding
  columns keep it and a record column dropped or renamed, a repeated
  `wflow_id` or a row not the run’s own give a plain tibble. A warning
  or error raised for one workflow is the original condition with
  `Workflow "<id>":` in front of its message.

- [`summary()`](https://rdrr.io/r/base/summary.html),
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  and
  [`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md)
  answer on a `nested_results_set`, each workflow’s view keyed by its
  `wflow_id`: [`summary()`](https://rdrr.io/r/base/summary.html) returns
  one summary per workflow and prints one section each, the performance
  plot puts the workflows along the x axis inside a panel per metric,
  the parameters plot draws a panel per workflow and tuned parameter,
  and
  [`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md)
  stacks each workflow’s table under `wflow_id`.

- [`nested_workflow_map()`](https://nestedtune.tidymodels.org/reference/nested_workflow_map.md)
  runs every workflow of a
  [`workflowsets::workflow_set()`](https://workflowsets.tidymodels.org/reference/workflow_set.html)
  through one nested design in one call, with `fn` naming the
  orchestrator, the orchestrator’s arguments in `...`, and the set’s
  `option` column overriding an argument for one workflow. It returns a
  `nested_results_set`, one `nested_results` per row, whose
  `collect_*()` readers stack each workflow’s table under `wflow_id`,
  and `nested_final_fit(x, id = )` fits one workflow by its own record;
  `workflowsets` joins Suggests.

- [`nested_fit_resamples()`](https://nestedtune.tidymodels.org/reference/nested_fit_resamples.md)
  scores a workflow with nothing to tune on the outer folds of a nested
  design, the same outer loop with the inner stage removed, so a fixed
  workflow and a tuned one score on identical folds. Its result answers
  every reader, with `.selected` empty on every fold and
  [`extract_procedure()`](https://nestedtune.tidymodels.org/reference/extract_procedure.md)
  naming the tuner `"fit_resamples"`.

- The five tuning orchestrators refuse a workflow with no `tune()`
  marker at entry, with class `nestedtune_untuned_workflow`, naming
  [`nested_fit_resamples()`](https://nestedtune.tidymodels.org/reference/nested_fit_resamples.md),
  which in turn refuses a workflow carrying a marker with class
  `nestedtune_tuned_workflow`.

- A `select` argument on the five tuning orchestrators names the rule
  each outer fold selects its candidate by, built by the new
  [`selection_rule()`](https://nestedtune.tidymodels.org/reference/selection_rule.md):
  `"best"` by default, or `"one_std_err"` and `"pct_loss"` with the
  parameter orderings tune’s rules take. The rule is recorded as
  `extract_procedure(res)$select` and
  [`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
  selects by it.

- `save_pred` and `extract` on a control passed as `control` reach the
  outer fit, adding a `.predictions` or `.extracts` list column to the
  result, and
  [`collect_predictions()`](https://tune.tidymodels.org/reference/collect_predictions.html)
  and
  [`collect_extracts()`](https://tune.tidymodels.org/reference/collect_predictions.html)
  stack them with the fold labels over the folds that completed. A run
  that did not ask for the column is refused with class
  `nestedtune_column_not_saved`.

- [`extract_procedure()`](https://nestedtune.tidymodels.org/reference/extract_procedure.md)
  returns the record of what ran, the tuner, its arguments and the
  control as it took effect, from a results object and from a final fit
  alike.

- The em dash is gone from every text the package publishes.

- Three readers stack a per-fold list column into one table with the
  design’s fold labels beside it:
  [`collect_notes()`](https://tune.tidymodels.org/reference/collect_predictions.html)
  over every outer fold, and
  [`collect_selections()`](https://nestedtune.tidymodels.org/reference/collect_selections.md)
  and
  [`collect_inner_metrics()`](https://nestedtune.tidymodels.org/reference/collect_selections.md)
  over the folds that completed, warning once with class
  `nestedtune_partial_summary` on a partial run.

- `tidymodels` joins Suggests. Every vignette attaches it before
  `nestedtune`, behind a guard that ends the page with one notice when
  it or another of the page’s optional packages is absent.

- The parallel article and three further vignettes are added. The
  parallel article runs the guide’s loop on two mirai daemons and shows
  the result identical to the serial run;
  [`vignette("results")`](https://nestedtune.tidymodels.org/articles/results.md)
  reads every column and reader of the results object;
  [`vignette("tuners")`](https://nestedtune.tidymodels.org/articles/tuners.md)
  runs the Bayesian, racing and annealing searches on the guide’s
  design; and
  [`vignette("estimate")`](https://nestedtune.tidymodels.org/articles/estimate.md)
  says what the nested number estimates, leaving
  [`vignette("nested-cv")`](https://nestedtune.tidymodels.org/articles/nested-cv.md)
  as the getting-started path.

- The tuning orchestrators refuse a malformed `resamples` design at the
  call, before any fold runs, with class `nestedtune_bad_design`, naming
  every offending fold, split, index or column: an inner element that is
  not an `rsplit` or `rset`, an inner split over a frame other than the
  outer split’s own or its analysis set, an inner split indexing a row
  its outer fold holds out, an empty inner design, an `NA` or repeated
  label, and a label column that is not character or factor or not named
  `id` or `id` followed by a digit. Designs from
  [`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md)
  and
  [`rsample::nested_cv()`](https://rsample.tidymodels.org/reference/nested_cv.html)
  pass unchanged.

- Before any fold is dispatched to mirai daemons, the startup check asks
  every daemon for each package the workflow and the tuner need, and
  stops with class `nestedtune_daemons_missing_pkgs` naming how many
  daemons are affected and which packages. The host’s own entry check
  refuses a package the workflow needs that is not installed, a recipe
  step’s as well as the engine’s, under `nestedtune_pkg_not_installed`
  with an
  [`install.packages()`](https://rdrr.io/r/utils/install.packages.html)
  call to paste.

- [`extract_tune_results()`](https://nestedtune.tidymodels.org/reference/extract_tune_results.md)
  and
  [`extract_scored_candidates()`](https://nestedtune.tidymodels.org/reference/extract_scored_candidates.md)
  on an object they have no method for signal
  `nestedtune_no_extract_method` naming that object, whatever else was
  passed in `...`.

- Printing the columnless type token
  [`vctrs::vec_cbind_frame_ptype()`](https://vctrs.r-lib.org/reference/vec_cbind_frame_ptype.html)
  hands back writes the banner and the rows alone. A column add that
  leaves two columns sharing a record column’s name returns a bare
  tibble, and `names<-` keeps the object intact when each record column
  keeps its name and returns a bare tibble when one is renamed or
  shadowed.

- On a
  [`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md)
  design, every inner tuning call sees only its outer fold’s analysis
  rows, so a `param_info` parameter whose range tune finalizes from the
  data is finalized without the rows that fold holds out, as it already
  was on an
  [`rsample::nested_cv()`](https://rsample.tidymodels.org/reference/nested_cv.html)
  design. The candidates such a run searches, and so its selections and
  estimate, change from earlier development versions;
  [`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
  still finalizes on the full data.

- [`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
  refuses a results object in which no outer fold completed, with class
  `nestedtune_no_completed_folds`, the class
  [`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html),
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  and
  [`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md)
  raise on the same object.

- [`nested_tune_sim_anneal()`](https://nestedtune.tidymodels.org/reference/nested_tune_sim_anneal.md)
  runs the outer loop with finetune’s simulated annealing inside: each
  fold scores `initial` candidates on its inner resamples, then perturbs
  the current candidate for `iter` iterations, with a
  [`finetune::control_sim_anneal()`](https://finetune.tidymodels.org/reference/control_sim_anneal.html)
  passed as `control`. `iter` below 1 and `initial` below 1 or given as
  a `tune_results` are refused at entry, and
  `control_sim_anneal(verbose_iter = FALSE)` keeps a serial run quiet
  ([\#35](https://github.com/tidymodels/nestedtune/issues/35)).

- [`nested_tune_race_anova()`](https://nestedtune.tidymodels.org/reference/nested_tune_race.md)
  and
  [`nested_tune_race_win_loss()`](https://nestedtune.tidymodels.org/reference/nested_tune_race.md)
  run the outer loop with finetune’s two racing tuners inside, taking
  [`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)’s
  arguments and a
  [`finetune::control_race()`](https://finetune.tidymodels.org/reference/control_race.html)
  as `control`; each fold’s `.inner_metrics` holds every candidate its
  race scored with `n` the inner resamples each was scored on. A package
  the race needs that is not installed, a control of the wrong kind, and
  an inner design with no more resamples than the control’s `burn_in`
  are refused at entry; finetune, lme4 and BradleyTerry2 join Suggests
  ([\#35](https://github.com/tidymodels/nestedtune/issues/35)).

- Each outer fold of a `nested_results` carries its inner tuning run’s
  metrics as `.inner_metrics`,
  [`tune::collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
  of that fold’s run with one row per candidate and metric, plus `.iter`
  from the iterating searches. A fold that scored nothing carries a
  zero-row table, and
  [`extract_scored_candidates()`](https://nestedtune.tidymodels.org/reference/extract_scored_candidates.md)
  no longer carries `.eval_time`
  ([\#57](https://github.com/tidymodels/nestedtune/issues/57)).

- [`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
  and
  [`nested_tune_bayes()`](https://nestedtune.tidymodels.org/reference/nested_tune_bayes.md)
  take a control object passed as `control`,
  [`tune::control_grid()`](https://tune.tidymodels.org/reference/control_grid.html)
  or
  [`tune::control_bayes()`](https://tune.tidymodels.org/reference/control_bayes.html),
  and pass it to the inner tuning call in every fold, with `allow_par`
  forced to `FALSE` and the Bayesian `seed` set to each fold’s tuning
  seed. A control of the wrong kind is refused with class
  `nestedtune_bad_control`, and any other name or an unnamed value in
  `...` with `nestedtune_bad_dots`
  ([\#33](https://github.com/tidymodels/nestedtune/issues/33),
  [\#35](https://github.com/tidymodels/nestedtune/issues/35)).

- [`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
  takes the workflow and the `nested_results` object,
  `nested_final_fit(object, results)`, and re-runs the procedure that
  result recorded: the design’s inner resampling specification, the
  tuner and its arguments, the metric set and the selection rule. A
  results object with no such record, one that is no longer a
  `nested_results`, or one with no rows is refused before any fitting
  with class `nestedtune_bad_results`.

- [`predict()`](https://rdrr.io/r/stats/predict.html) and
  [`augment()`](https://generics.r-lib.org/reference/augment.html) work
  directly on a `nested_final_fit`, returning what the same call on
  `extract_workflow(final)` returns; `augment` is re-exported.
  [`augment()`](https://generics.r-lib.org/reference/augment.html) takes
  `new_data` and `eval_time` only and refuses anything else.

- [`print()`](https://rdrr.io/r/base/print.html) and
  [`summary()`](https://rdrr.io/r/base/summary.html) on a
  `nested_final_fit` name the procedure that ran: the candidates scored
  for a grid search, and for an iterating search the initial candidates
  and iterations, each as what ran beside what was requested.

- [`nested_tune_bayes()`](https://nestedtune.tidymodels.org/reference/nested_tune_bayes.md)
  runs the outer loop with
  [`tune::tune_bayes()`](https://tune.tidymodels.org/reference/tune_bayes.html)
  as the inner tuner, scoring `initial` space-filling candidates on each
  fold’s inner resamples and letting a Gaussian process propose up to
  `iter` more under `objective`. The Gaussian process is seeded from the
  fold’s tuning seed, so a fold reproduces from its `.tuning_seed`
  alone, and `initial` is a count only, since one tuning run cannot
  serve every outer fold.

- Every `nested_results` carries a `procedure` attribute recording the
  tuner that ran, its own arguments, and `param_info`, `event_level` and
  `eval_time`, which travels with the class and is shed with it. The
  metric set travels beside it as `attr(x, "metrics")`, absent when none
  was passed.

- [`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md)
  reports how often each candidate was selected across the outer folds:
  one row per distinct combination of selected values, with `n` and
  `prop` over the completed folds, most frequent first. The most
  frequent combination is not the final model’s parameters.

- [`print()`](https://rdrr.io/r/base/print.html) on a `nested_results`
  accepts `n` and `width` and passes them to the rendering of the
  outer-fold rows, matched by full name only.

- [`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
  takes an `eval_time` argument, passed to every tune call whose answer
  depends on it, so a censored regression workflow scored by a dynamic
  survival metric is measured at the times named. A metric measured at
  several times is summarized per time by
  [`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
  and [`summary()`](https://rdrr.io/r/base/summary.html) in an
  `.eval_time` column and drawn one panel per time by
  `autoplot(type = "performance")`.

- [`summary()`](https://rdrr.io/r/base/summary.html) on a
  `nested_final_fit` reports the full-data tuning run’s resampling
  scheme, the candidates it scored and the values selection chose, and
  says, where a number would be, that this model has no performance
  estimate of its own and the nested estimate is the one to report.

- Printing a `nested_results` shows the object: its outer folds as the
  tibble rows they are, the resampling scheme, a count of the folds that
  did not complete, and a note when the folds did not all search the
  same grid. Printing never warns and never errors, a run in which no
  fold completed included.

- [`summary()`](https://rdrr.io/r/base/summary.html) on a
  `nested_results` returns an object holding the requested and completed
  fold counts, the failed folds with the stage each failed at, the
  values the completed folds selected, and the metric estimates over the
  folds that completed. A partial run warns and still returns the
  summary, and one where every fold failed does the same.

- A `nested_results` whose record of its fold-label columns cannot label
  its rows names each fold by its row position.

- An operation that changes which outer folds a `nested_results` holds
  returns a plain tibble: `slice()`,
  [`head()`](https://rdrr.io/r/utils/head.html), `x[1, ]`, a
  [`filter()`](https://rdrr.io/r/stats/filter.html) that drops a fold,
  `bind_rows()`, and dropping any of the columns the run is recorded in.
  Reordering rows with `arrange()`, adding a column with `mutate()` or
  `bind_cols()`, reordering columns with `relocate()`, and a
  `left_join()` that matches one row apiece keep the class and the run’s
  record.

- The same rule covers the vctrs verbs and base
  [`rbind()`](https://rdrr.io/r/base/cbind.html):
  `vctrs::vec_slice(x, 1)`,
  [`vctrs::vec_rbind()`](https://vctrs.r-lib.org/reference/vec_bind.html),
  [`vctrs::vec_c()`](https://vctrs.r-lib.org/reference/vec_c.html) and
  [`rbind()`](https://rdrr.io/r/base/cbind.html) return a plain tibble,
  while reordering rows with `vec_slice()` and adding a column with
  `vctrs::vec_cbind(x, extra)` keep the class. `vec_cbind()` and
  `bind_cols()` build on the first argument’s type, so with the results
  object second they return a plain tibble.

- [`dplyr::rename()`](https://dplyr.tidyverse.org/reference/rename.html)
  moving one of the columns the run is recorded in returns a plain
  tibble.

- `dplyr` and `vctrs` are hard dependencies; both were already installed
  alongside nestedtune through `tune`.

- A results object records the columns its resampling design labelled
  the folds with, so a column you add is read as a fold label only when
  the design itself carries a column of that name. Before, the
  fold-label columns were worked out from the column names, so adding
  `id_extra` reported the folds as `Fold1, x`.

- Replacing a fold-label column with a value that cannot be ordered, as
  `dplyr::mutate(x, id = list(c(1, 2), 3, 4))` does, returns a plain
  tibble rather than failing inside the class rule.

- The packages a workflow declares are attached inside each mirai daemon
  before any fold is dispatched, so a recipe with unqualified selectors
  such as `all_numeric_predictors()` resolves on a worker as it does
  serially.

- [`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
  [`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
  and
  [`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md)
  take `...` immediately after their required arguments, so `grid`,
  `metrics` and `param_info` must be named and a mistyped or unsupported
  argument is an error naming the function it was passed to. Every
  method the package registers whose `...` is documented as unused
  refuses an argument the same way.

- [`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
  on a `nested_results` takes `summarize` after `...`, matching tune’s
  own method, so it must be named.

- [`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
  takes `param_info`, passed unchanged to
  [`tune::tune_grid()`](https://tune.tidymodels.org/reference/tune_grid.html)
  on every outer fold, and refuses one that is not a
  [`dials::parameters()`](https://dials.tidymodels.org/reference/parameters.html)
  object before the first fold is fitted.

- [`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
  takes `event_level`, naming which level of a two-class outcome factor
  counts as the event, and sends it to the inner tuning run and the
  outer scoring fit alike. A value that is not `"first"` or `"second"`
  is refused before the first fold is fitted.

- The documentation site builds with the tidymodels organization’s
  shared pkgdown theme, and the organization’s contributing guide and
  code of conduct build as pages of the site.

- The package has moved to the tidymodels organization, at
  <https://github.com/tidymodels/nestedtune> with its documentation site
  at <https://nestedtune.tidymodels.org/>. The old repository address
  redirects; the old documentation address does not.

- A parallel run refuses to start when a daemon is holding an older
  install of nestedtune, with class `nestedtune_daemons_incompatible`,
  naming the functions its copy is missing and the fix: reinstall, then
  restart the pool. A running daemon keeps the version it has already
  loaded, so reinstalling underneath one changes nothing.

- A parallel run started on a pool that cannot be cancelled, one from
  `mirai::daemons(n, dispatcher = FALSE)`, warns once at the start of
  the run with class `nestedtune_pool_not_cancellable`. Its results are
  correct; what the pool lacks is the ability to stop on an interrupt.

- Running the outer folds in parallel sends each fold one copy of the
  data instead of one copy per inner resample, the splits being emptied
  before dispatch and refilled on the daemon. Results are unchanged, and
  the serial path is untouched.

- The object
  [`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
  returns has two accessors for the tuning run behind it:
  [`extract_tune_results()`](https://nestedtune.tidymodels.org/reference/extract_tune_results.md)
  returns that run, and
  [`extract_scored_candidates()`](https://nestedtune.tidymodels.org/reference/extract_scored_candidates.md)
  the candidate settings it scored. Every metric inside that run was
  computed on the resamples that chose the candidate it describes, so it
  is not the model’s performance.

- [`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
  and
  [`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
  refuse a workflow that has a model but no preprocessor, pointing at
  [`workflows::add_formula()`](https://workflows.tidymodels.org/reference/add_formula.html),
  `add_recipe()` and `add_variables()`, and a workflow with no model,
  pointing at
  [`workflows::add_model()`](https://workflows.tidymodels.org/reference/add_model.html).

- When
  [`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
  cannot re-run a design’s stored inner specification, the error names
  the caller’s call rather than an internal function.

- [`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md)
  refuses an `inside` specification that does not produce an `rset`.

- When a resampling specification fails to evaluate, the error names the
  specification that was tried instead of deparsing the data into the
  message, and is wrapped in a nestedtune error carrying the original as
  its cause.

- The reference pages and the vignettes are built into a documentation
  website, rebuilt whenever a change lands on the default branch that
  the package itself can see.

- Interrupting a parallel run asks the folds already sent to the daemons
  to stop, so the pool goes idle rather than computing results nobody
  will read. Cancelling needs mirai’s dispatcher, which
  `mirai::daemons(n)` starts by default, and a fold already inside a
  compiled fitting routine may not be interruptible.

- The check that runs before parallel dispatch asks every connected
  daemon whether it can load the package, and a daemon that does not
  answer is reported as a non-response, class
  `nestedtune_daemons_no_response`, rather than as one that cannot load
  the package, class `nestedtune_daemons_cannot_load`. Both also carry
  `nestedtune_daemons_unusable`.

- The wait for that check is settable with
  `options(nestedtune.preflight_timeout = <milliseconds>)`, a single
  positive, finite number, 30 seconds by default. The first parallel
  call after starting a cold pool is the slow one, since it is what
  makes each daemon load the package.

- Cancelling a parallel run stops it, raising a `nestedtune_cancelled`
  condition that inherits from `nestedtune_interrupted` and returning
  nothing, with the caller’s RNG state restored. Calling
  `mirai::daemons(0)` while folds are outstanding is recorded as fold
  failures instead, since it produces exactly what a daemon dying
  mid-fold produces.

- [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  draws a nested cross-validation result. The default view puts one
  point per outer fold at the value that fold’s inner tuning selected,
  one panel per tuned parameter, and `type = "performance"` draws each
  outer fold’s score with a dashed line at the nested estimate, read
  from the same place
  [`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
  reads it.

- Both views keep every outer fold that was attempted on the axis, a
  fold that failed leaving a visible gap. The subtitle says how much of
  the requested design ran, and each panel says when fewer folds
  contributed to it than completed, as `mtry (2 of 3 chose)` or
  `rmse (from 2 folds)`.

- `ggplot2` is a hard dependency. Plotting a run where no outer fold
  completed, or asking for the parameters view of a design with no tuned
  parameters, is refused with a message saying which it was.

- [`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
  runs its outer folds in parallel when mirai daemons are connected,
  with no argument to set, and inner tuning stays serial because nesting
  parallelism inside parallelism oversubscribes cores. Parallel results
  are identical to serial ones, because each fold’s seeds are drawn
  before the loop starts and assigned by position.

- [`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
  builds the model to deploy by running the same tuning procedure the
  nested estimate describes with the whole dataset in hand, and returns
  it as a separate object carrying no performance number of its own.
  [`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html),
  `show_best()` and `select_best()` refuse a final fit rather than
  returning something that reads as its score.

- Because the inner resampling specification is stored unevaluated and
  re-evaluated at final-fit time, it is written with literal arguments,
  `inside = vfold_cv(v = 5)` rather than `inside = vfold_cv(v = k)`. A
  specification whose variables have gone out of scope fails with a
  message naming it.

- An outer fold that fails does not end the run: the remaining folds
  still run, `.completed` marks the failed one, and `.notes` says which
  stage failed and why, carrying tune’s own notes about the cause. A
  fold that completes on only part of its inner design keeps the notes
  explaining what was lost.

- [`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
  checks a data-frame `grid` against the workflow before fitting
  anything, refusing by name a column that is not marked for tuning or a
  tuned parameter with no column.

- [`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
  summarizes only the outer folds that completed, warns naming the ones
  that did not, and errors rather than returning `NA` when none
  completed.

- [`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
  runs the nested cross-validation loop end to end: for each outer fold
  it tunes on that fold’s inner resamples with
  [`tune::tune_grid()`](https://tune.tidymodels.org/reference/tune_grid.html),
  selects a candidate, finalizes the workflow, and fits and scores it on
  the outer split. The result keeps each fold’s chosen parameters
  alongside its metrics, so disagreement between folds is visible rather
  than averaged away, and
  [`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
  returns the per-fold metrics or their summary across outer folds.

- [`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
  is reproducible from a single
  [`set.seed()`](https://rdrr.io/r/base/Random.html) before the call: it
  derives one tuning seed and one outer-fit seed per fold up front, so a
  fold’s result depends on its position in the design rather than on the
  order folds run in, and it leaves the caller’s random-number state as
  it found it.

- [`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md)
  builds a nested resampling design without keeping a copy of the data
  for every outer fold, selecting the same rows as
  [`rsample::nested_cv()`](https://rsample.tidymodels.org/reference/nested_cv.html)
  for the same seed and specifications. On a 20000-row dataset with a
  five-fold inner resampling, a 50-fold outer design holds 10× the
  source data rather than 57×.

- [`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md)
  refuses an outer bootstrap, since the same observation can otherwise
  land in both the inner analysis and the inner assessment set.
