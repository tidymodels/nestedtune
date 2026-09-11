# M085 survey: roxygen paragraphs failing the plain-prose standard (2026-09-10)

_Owned by M085; the AC3 (iii) probe set. Each entry is one paragraph, identified by its first `#'` line at the branch head and its quoted opening words, refreshed 2026-09-11 after the T1-T5 rewrites; the original entries, one bare line number each at `0d8611e`, are in git (`de8494b` and earlier). A paragraph's extent is the run `Rscript benchmarks/sweep-prose.R --roxygen --paragraphs` prints at HEAD containing the entry's line; the six entries that named `@section` header lines at `0d8611e` now name the section's first paragraph. An entry in a "Differences from calling ... directly" section quotes its source line with the bold run-in heading the script drops before counting, so the printed run's opening is the text after that heading. Letters as in `M084-survey.md`: (a) reader first, (b) problem before term, (c) one idea per sentence, (d) package word unset, (e) sentence over 30 words, as judged at survey time. Files with no failing paragraph: `nestedtune-package.R` (5), `man-roxygen/*` (3 prose paragraphs), `reexports.R`, `checks.R`, `parallel.R`, `tuner.R` (no prose)._

## `R/nested-tune-grid.R` — 26 of 53
- :4 "`nested_tune_grid()` gives you an honest score" — b d e
- :13 "Tune, select, fit and score, taken together" — d
- :31 "A [workflows::workflow()] with at least one parameter marked" (the `@param` run; the entry was the `select` entry at `0d8611e:46`) — c d
- :57 "A tibble of class `nested_results` with one row" — e
- :74 "`resamples` is a data frame with one row" — e
- :81 "Inside each inner `rset`, every element of `splits`" — e
- :89 "A design breaking any of this, or using" — e
- :98 "`param_info` is passed unchanged to the inner tuning" — d e
- :120 "Refused here, ahead of tune: anything that is" — e
- :129 "The selection rule is applied without `eval_time`. Left" — e
- :136 "tune leaves the choice of candidate to a" — e
- :150 "Two records describe the grid, and they answer" — e
- :172 "`attr(x, "metrics")` holds the `metrics` argument, and is"metrics")` holds the `metrics` argument, and is" — d e
- :188 "The fold-label columns are the ones the resampling" — d
- :203 "It is one rule, reached through four doors." — e
- :220 "Fold `i` is exactly the code below. On" — e
- :242 "The siblings differ only in the tuning line." — e
- :253 "A fold that fails does not end the" — e
- :302 "Each fold is sent one copy of the" — e
- :325 "- Before dispatching, the call checks every connected" — e
- :351 "Stopping a run is not a fold failure." — e
- :371 "There is no `control` formal. A [tune::control_grid()] passed" — c
- :384 "**Settable as its own argument: `event_level`.** The argument" — e
- :400 "**Passed through: `verbose`, `pkgs`, `parallel_over`, `workflow_size`.**" — e
- :411 "**Kept from the outer fit: `save_pred`, `extract`.** Each" — e
- :424 "**Not returned: `save_workflow`.** It lands on the inner" — d

## `R/nested-final-fit.R` — 9 of 26
- :18 "`nested_final_fit()` builds the model you deploy after a" — c d
- :42 "An object of class `nested_final_fit`. Its elements are" — e
- :70 "`results` supplies the inner resampling specification the design" — d e
- :98 "A workflow other than the one the estimate" — e
- :106 "Three shapes of `results` are refused before any" — e
- :126 "Report the estimate [collect_metrics()] returns from the results" — e
- :153 "Seed the session before the call; there is" — e
- :161 "You can redo the run by hand from" — c
- :214 "A nested design stores its `inside` argument as" — e

## `R/nested-results-set.R` — 12 of 38
- :12 "You read a `nested_results_set`, what [nested_workflow_map()] returns," — d
- :29 "A tibble: `wflow_id` first, then the columns the" — e
- :37 "Failed folds are left out, as on one" — c
- :230 "A list of one [summary.nested_results()] object per workflow" — d e
- :235 "Printing it shows that function's name and the" — d e
- :242 "Under `type = "performance"` the workflows stand along" — e
- :247 "Under `type = "parameters"` there is one panel" — d e
- :258 "`wflow_id`, then one column per parameter any workflow's" — c e
- :277 "A workflow in which no fold completed is" — e
- :289 "The performance view's subtitle gives the workflow and" — e
- :265 "A tuned parameter whose id is `wflow_id` cannot" (moved from the counting section to the `agreement()` section in T6) — e
- :317 "Shows which loop function the set ran through," — d

## `R/nested-workflow-map.R` — 10 of 14
- :12 "`nested_workflow_map()` gives you nested estimates for every workflow" — d
- :28 "The name of the orchestrator to run each" (the `@param` run) — c
- :39 "A `nested_results_set`: a tibble of class" — e
- :66 "A workflow with no parameter marked by [tune::tune()]" (was the Routing header at `0d8611e:59`) — e
- :72 "For each workflow the merged arguments are narrowed" — e
- :82 "A name that the orchestrator `fn` names does" — c
- :92 "Seed the session before the call, as before" (was the Seeds header at `0d8611e:84`) — e
- :106 "An orchestrator warns when some of its outer" (was the Warnings header at `0d8611e:98`) — e
- :125 "Each row's `nested_results` describes its own run whole," (was the Subsetting header at `0d8611e:113`) — e
- :141 "Anything else comes back a plain tibble without" — e

## `R/nested-fit-resamples.R` — 8 of 20
- :4 "`nested_fit_resamples()` gives you the score of a workflow" — e
- :38 "A `nested_results` with one row per outer fold" — c
- :50 "A workflow that still carries a [tune::tune()] marker" — d e
- :57 "Every function that reads a `nested_results` answers on" — e
- :74 "The same `2 * n` seeds are drawn" — d e
- :85 "There is no `control` formal. A [tune::control_resamples()] passed" — e
- :113 "**Kept from the outer fit: `save_pred`, `extract`.** With" — e
- :125 "**Inert: `verbose`, `pkgs`, `save_workflow`, `parallel_over`," — c

## `R/nested-tune-sim-anneal.R` — 7 of 19
- :4 "`nested_tune_sim_anneal()` gives you an honest score for a" — e
- :33 "A `nested_results` shaped as [nested_tune_grid()] documents" — d e
- :44 "Each fold draws its own space-filling set of" — e
- :51 "`iter = 0` is refused. finetune 1.3.0 iterates" — e
- :76 "There is no `control` formal. A [finetune::control_sim_anneal()] passed" — e
- :101 "**Passed through: `no_improve`, `restart`, `radius`, `flip`," — e
- :132 "**Not returned: `save_workflow`, `save_history`.** `save_workflow` lands" — e

## `R/nested-tune-race.R` — 6 of 17
- :4 "`nested_tune_race_anova()` and `nested_tune_race_win_loss()` give you an" — e
- :37 "A `nested_results` with one row per outer fold" — d
- :45 "Each fold's `.inner_metrics` holds every candidate its race" — e
- :56 "A race draws from the generator even with" — e
- :72 "There is no `control` formal. A [finetune::control_race()] passed" — e
- :92 "**Refused: none.** No slot is refused on its" — c e

## `R/nested-tune-bayes.R` — 5 of 19
- :4 "`nested_tune_bayes()` gives you an honest score for a" — e
- :33 "A `nested_results` with one row per outer fold" — d
- :61 "A parameter range that depends on the data" — c e
- :75 "There is no `control` formal. A [tune::control_bayes()] passed" — e
- :84 "**Forced: `allow_par`, `seed`.** `allow_par = FALSE` on both" — e

## Three or fewer
- `R/extract-procedure.R` (3 of 8): :13 "Returns the `procedure` record a nested result carries" — d · :26 "The stored record, unchanged: a flat named list" — d · :42 "`select` is the [selection_rule()] each fold selected by" — e
- `R/nested-final-fit-extract.R` (3 of 10): :26 "Returns the tuning result that [nested_final_fit()] chose its" — d · :91 "Returns the candidates, the parameter settings [nested_final_fit()]'s" — d e · :97 "A tibble with one row per candidate scored," — e
- `R/nested-final-fit-print.R` (3 of 16): :28 "The line under the heading tells you what" (was the section header at `0d8611e:27`) — e · :108 "`summary()` returns an object of class `summary.nested_final_fit`, a" — e · :125 "The four counts are `NULL` on a grid" — c d
- `R/nested-resamples.R` (3 of 12): :4 "`nested_resamples()` builds the nested resampling design" — d · :31 "[rsample::analysis()] and [rsample::assessment()] return identical frames" — e · :49 "Sizes below are multiples of the source data," — e
- `R/nested-results-collect.R` (3 of 20): :16 "`collect_notes()`, `collect_selections()` and `collect_inner_metrics()`" — d · :32 "* `collect_inner_metrics()` stacks `.inner_metrics`: one row per" — c · :178 "`collect_predictions()` and `collect_extracts()` give you the outer" — e
- `R/nested-results.R` (2 of 13): :723 "A metric measured at several evaluation times" — c e · :749 "That is a limit of the statistics, not" — e
- `R/nested-results-plot.R` (2 of 11): :45 "A run in which no fold completed is" — e · :54 "The subtitle gives how much of the requested" — c e
- `R/nested-results-print.R` (2 of 15): :22 "Shows the object: its outer folds as the" — d · :41 "Folds can score different candidate sets, the parameter" — c
- `R/nested-final-fit-predict.R` (1 of 11): :47 "`predict()` forwards them, for example `level` with" — c
- `R/nested-results-agreement.R` (1 of 7): :33 "Every completed fold is counted once, so `sum(n)`" — e
- `R/selection-rule.R` (1 of 9): :51 "An ordering is a parameter name, wrapped in" — e

Total: 107 of 343 at survey time. `orchestrator` first appeared cold at `0d8611e` in `nested-resamples.R:4`, `nested-tune-grid.R:156`, `nested-tune-bayes.R:32`, `nested-tune-race.R:35`, `nested-tune-sim-anneal.R:32`, `nested-fit-resamples.R:49`, `nested-workflow-map.R:12`, `nested-results-set.R:227`, `extract-procedure.R:25`.
