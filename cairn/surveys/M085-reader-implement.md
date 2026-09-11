# M085 implement-side reader pass (2026-09-11)

_Owned by M085 (T6). One fresh-context Opus reader, given the standard and the `tools::Rd2txt()` text of the 26 non-internal `man/*.Rd` pages after T1-T5 and the T6 opening fixes, withheld `M085-survey.md`, reported each paragraph it would send back with a clause and a reason. Its 93 entries are listed as reported, each with the disposition taken once; the pass was not rerun. AC3 (iv)'s report is review's own, taken separately._

Dispositions: **fixed** 46 (43 distinct edits; entries 47, 65, 71 and 77 are one inherited paragraph), **rejected** 47. Rejection classes: `paragraph` — the entry describes a paragraph holding several single-claim sentences, which clause (c) does not bind; `content` — the density is the section's subject (a rule with several parts, an enumeration that is the deliverable); `record` — the sentence is a provenance or dated-observation line the derived-figures rule requires; `inherited` — the paragraph is `?nested_tune_grid`'s, inherited by four pages, and is judged once there; `IP3` — the paragraph carries the three claims AC5 binds, each in its own sentence.

| # | page · section · opening | clause | disposition |
|---|---|---|---|
| 1 | agreement · Description · "The most frequent combination is not" | c | fixed: "The tuning procedure is tune then select, and the folds say how stable its choice is." |
| 2 | agreement · How the folds are counted · "tune's `.config` is not a column" | a | rejected, content: the paragraph answers where `.config` went; the absence is its subject |
| 3 | agreement · Missing and colliding values · "A completed fold whose selection carries" | c | fixed: split at the semicolon |
| 4 | autoplot.nested_results · What the labels say · "The subtitle gives how much of" | c | fixed: "Each panel says how many folds stand behind it, since that varies between panels." |
| 5 | autoplot.nested_results · What the labels say · "The selected-value axis is numeric when" | c | fixed: rule and its two reasons in separate sentences |
| 6 | collect_metrics.nested_results_set · Description · "The six reading functions of a" | a | fixed: opens on "You read a `nested_results_set` … with the same six functions" |
| 7 | collect_metrics.nested_results_set · Value · "A tibble: `wflow_id` first, then the" | c | fixed: column order and binding rule in separate sentences |
| 8 | collect_metrics.nested_results_set · Workflows and folds that failed · "Five of the six take the" | a | fixed: opens on "Failed folds are left out, as on one workflow" |
| 9 | collect_metrics.nested_results_set · Columns not saved · "A control reaches each workflow of" | c | fixed: the refusal's class and naming in their own sentence |
| 10 | collect_metrics.nested_results · Reading `std_err` · "That is a limit of the" | a | rejected, content: the paragraph explains the limit; the action (no interval) is the preceding paragraph's last sentence |
| 11 | collect_metrics.nested_results · Reading `std_err` · "Both results concern quantities close to" | a | rejected, content: the paragraph is the hedge on the two citations, and ends on the action |
| 12 | collect_predictions.nested_results · Description · "`collect_predictions()` and `collect_extracts()` give you the" | c | fixed: "the predictions the fold's finalized model made on its assessment rows" |
| 13 | collect_predictions.nested_results · Which predictions these are · "They are the outer fit's, on" | c | fixed: split at the semicolon |
| 14 | collect_selections · Description · "`collect_notes()`, `collect_selections()` and `collect_inner_metrics()` each" | c | rejected, paragraph: "three records as one table per fold, in list columns" is one claim about storage |
| 15 | collect_selections · What the columns are · "The label columns are read from" | a | fixed: opens on "The first columns are the design's fold labels" |
| 16 | collect_selections · Reading `.config` · "The `.config` of a selection or" | c | fixed: meaning and lookup recipe in separate sentences |
| 17 | extract_procedure · Value · "The stored record, unchanged: a flat" | c | rejected, content: the sentence enumerates the record's members, which the section then explains |
| 18 | extract_procedure · What the record holds · "`select` is the `selection_rule()` each fold" | c | fixed: the Bayesian `seed` case in its own sentence |
| 19 | extract_scored_candidates · Description · "Returns the candidates, the parameter settings" | c | fixed: counterpart and derivation in separate sentences |
| 20 | extract_scored_candidates · Value · "A tibble with one row per" | c | rejected, paragraph: four single-claim sentences |
| 21 | extract_scored_candidates · Scored, not asked for · "A `grid` given as a size" | c | fixed: split at "and" |
| 22 | extract_tune_results · What its numbers are, and are not · "The returned object answers `collect_metrics()` and" | a | fixed: opens on "Do not report the metrics this object gives you." |
| 23 | nested_final_fit · The results object · "`results` supplies three things: the inner" | c | fixed: the enumeration now names all four things, the metric set included |
| 24 | nested_final_fit · The results object · "A `param_info` parameter whose range is" | c | rejected, paragraph: two single-claim sentences |
| 25 | nested_final_fit · What is refused · "Where the record names a tuner" | a | fixed: opens on "A workflow other than the one the estimate was built around is refused here" |
| 26 | nested_final_fit · What is refused · "Three shapes of `results` are refused" | c | fixed: the no-completed-fold case is its own paragraph |
| 27 | nested_final_fit · What to report · "Report the estimate `collect_metrics()` returns from" | c | fixed: the pessimism sentences are their own paragraph |
| 28 | nested_final_fit · What to report · "Two things the estimate does not" | b | fixed: "marginal over selection" glossed as averaging over what each fold's tuning chose |
| 29 | nested_final_fit · Reproducibility · "You can redo the run by" | c | rejected, paragraph: four single-claim sentences |
| 30 | nested_final_fit · Reproducibility · "Where nothing was tuned there is" | c | fixed: the last sentence split in two |
| 31 | nested_final_fit · Reproducibility · "Building the resamples sits inside the" | a | rejected, content: a note for the reader redoing the run by hand, explaining the seed scope |
| 32 | nested_fit_resamples · Description · "`nested_fit_resamples()` gives you the score of" | c | fixed: the "so" clause is its own sentence |
| 33 | nested_fit_resamples · Description · "Use it for the baseline a" | c | fixed: the appositive dropped; the page links the grid page, which sets `procedure` up |
| 34 | nested_fit_resamples · Differences · "There is no `control` formal. A" | c | fixed: the seven-headings sentences are their own paragraph |
| 35 | nested_fit_resamples · Differences · "Settable as its own argument" | c | fixed: three sentences; "naming both" now "the refusal names both levels" |
| 36 | nested_fit_resamples · Nested designs · "Inside each inner `rset`, every element" | c | rejected, inherited (see 62) |
| 37 | nested_fit_resamples · Nested designs · "`resamples` is a data frame with" | c | rejected, inherited (see 63) |
| 38 | nested_fit_resamples · Differences · "Kept from the outer fit" | c | rejected, paragraph: single-claim sentences; the twist is the content |
| 39 | nested_resamples · Memory · "`rsample::nested_cv()` evaluates the inner specification against" | a | fixed: opens on "What you save is one copy of the analysis set per outer fold." |
| 40 | nested_resamples · Memory · "Sizes below are multiples of the" | c | rejected, record: the provenance the derived-figures rule requires beside the table |
| 41 | nested_tune_bayes · The initial candidates · "Each iteration proposes one candidate and" | c | fixed: the `iter = 0` sentence split |
| 42 | nested_tune_bayes · The initial candidates · "A parameter range that depends on" | c | rejected, paragraph: four single-claim sentences |
| 43 | nested_tune_bayes · Differences · "Forced: `allow_par`, `seed`" | c | rejected, paragraph: a chain of single-claim sentences |
| 44 | nested_tune_bayes · Nested designs · "`resamples` is a data frame with" | c | rejected, inherited (see 63) |
| 45 | nested_tune_bayes · Nested designs · "Inside each inner `rset`, every element" | c | rejected, inherited (see 62) |
| 46 | nested_tune_bayes · Finalizing a parameter range · "`param_info` is passed unchanged to the" | c | rejected, inherited (see 64) |
| 47 | nested_tune_bayes · Evaluation times · "The selector `select` names is called" | c | fixed (one paragraph on the grid page): "The selection rule is applied without `eval_time`." |
| 48 | nested_tune_grid · Description · "Tune, select, fit and score, taken" | c | rejected, IP3: the three claims AC5 binds, each its own sentence |
| 49 | nested_tune_grid · Details · "Four siblings run the same outer" | a | fixed: opens on "The same outer loop runs with other searches inside." |
| 50 | nested_tune_grid · What the result records · "Two records describe the grid, and" | c | rejected, paragraph: single-claim sentences |
| 51 | nested_tune_grid · What the result records · "The two diverge routinely. tune expands" | c | rejected, content: the causes of divergence, one sentence each |
| 52 | nested_tune_grid · What the result records · "`attr(x, "metrics")` holds the `metrics` argument," | a | fixed: the `procedure` record is its own paragraph |
| 53 | nested_tune_grid · Operations on the result · "It is one rule, reached through" | c | rejected, content: the four doors and two asymmetries, one sentence each |
| 54 | nested_tune_grid · Reproducing one fold by hand · "Fold `i` is exactly the code" | c | rejected, paragraph: two caveats in two sentences |
| 55 | nested_tune_grid · Reproducing one fold by hand · "The siblings differ only in the" | c | rejected, paragraph: single-claim sentences |
| 56 | nested_tune_grid · When a fold fails · "Both stages can fail quietly. Inner" | c | rejected, paragraph: three findings in three sentences |
| 57 | nested_tune_grid · Parallel execution · "Each fold is sent one copy" | c | fixed: the recipe-and-formula warning is its own paragraph |
| 58 | nested_tune_grid · Parallel execution · "Stopping a run is not a" | c | fixed: the dispatcher requirement is its own paragraph |
| 59 | nested_tune_grid · Differences · "Settable as its own argument" | c | fixed: the `eval_time` sentence split into reason and status |
| 60 | nested_tune_grid · Differences · "Passed through" | c | fixed: the `parallel_over` sentence split |
| 61 | nested_tune_grid · Differences · "Kept from the outer fit" | c | rejected, paragraph: single-claim sentences |
| 62 | nested_tune_grid · Nested designs · "Inside each inner `rset`, every element" | c | rejected, content: the index-containment rule is one claim; stated once, inherited by four pages |
| 63 | nested_tune_grid · Nested designs · "`resamples` is a data frame with" | c | rejected, content: the design's requirements, one claim per sentence |
| 64 | nested_tune_grid · Finalizing a parameter range · "`param_info` is passed unchanged to the" | c | rejected, content: the re-pointing rule and its two exceptions, one sentence each |
| 65 | nested_tune_grid · Evaluation times · "The selector `select` names is called" | c | fixed (see 47) |
| 66 | nested_tune_race · What a race records · "Each fold's `.inner_metrics` holds every candidate" | c | rejected, paragraph: single-claim sentences |
| 67 | nested_tune_race · Differences · "Refused: none" | c | rejected, content: the refusal list and its remedy, one sentence each |
| 68 | nested_tune_race · Differences · "This classification was read on finetune" | a | rejected, record: a dated observation the derived-figures rule requires |
| 69 | nested_tune_race · Nested designs · "Inside each inner `rset`, every element" | c | rejected, inherited (see 62) |
| 70 | nested_tune_race · Finalizing a parameter range · "`param_info` is passed unchanged to the" | c | rejected, inherited (see 64) |
| 71 | nested_tune_race · Evaluation times · "The selector `select` names is called" | c | fixed (see 47) |
| 72 | nested_tune_sim_anneal · The initial candidates · "`iter = 0` is refused. finetune" | c | fixed: the `tune_bayes()` contrast is its own sentence |
| 73 | nested_tune_sim_anneal · Differences · "The classification above was read on" | a | rejected, record (see 68) |
| 74 | nested_tune_sim_anneal · Differences · "Not returned: `save_workflow`, `save_history`" | c | rejected, paragraph: two slots, single-claim sentences |
| 75 | nested_tune_sim_anneal · Nested designs · "Inside each inner `rset`, every element" | c | rejected, inherited (see 62) |
| 76 | nested_tune_sim_anneal · Finalizing a parameter range · "`param_info` is passed unchanged to the" | c | rejected, inherited (see 64) |
| 77 | nested_tune_sim_anneal · Evaluation times · "The selector `select` names is called" | c | fixed (see 47) |
| 78 | nested_workflow_map · Arguments · "The orchestrator's arguments, every one named:" | c | rejected, content: the entry's second sentence lists the three refusals |
| 79 | nested_workflow_map · Value · "A `nested_results_set`: a tibble of class" | c | rejected, paragraph: single-claim sentences |
| 80 | nested_workflow_map · Routing · "For each workflow the merged arguments" | c | rejected, paragraph: single-claim sentences |
| 81 | nested_workflow_map · Seeds · "Seed the session before the call," | c | rejected, paragraph: single-claim sentences |
| 82 | nested_workflow_map · Warnings and errors · "An orchestrator warns when some of" | c | fixed: the error case is its own paragraph |
| 83 | nested_workflow_map · Subsetting · "Each row's `nested_results` describes its own" | c | fixed: the four-clause condition set as a list |
| 84 | nested_workflow_map · Subsetting · "Anything else comes back a plain" | c | rejected, content: one sentence per case |
| 85 | predict.nested_final_fit · What the dots accept · "`predict()` forwards them, for example `level`" | c | rejected, paragraph: single-claim sentences |
| 86 | predict.nested_final_fit · What the dots accept · "`augment()` fences them instead" | c | fixed: the conclusion is its own sentence |
| 87 | print.nested_final_fit · The procedure line · "The line names the procedure that" | a | fixed: opens on "The first line tells you what ran" |
| 88 | selection_rule · Writing an ordering · "An ordering is a parameter name," | c | fixed: "None may be named. That way a misspelled `limit` is refused" |
| 89 | summary.nested_final_fit · Description · "Gives the pieces the print method" | a | fixed: opens on "`summary()` gives you the facts of the final fit as values" |
| 90 | summary.nested_final_fit · Components that are absent · "The four counts are `NULL` on" | c | rejected, paragraph: single-claim sentences |
| 91 | summary.nested_results_set · What `autoplot()` draws · "Under `type = "parameters"` there is" | b | fixed: "the single view" replaced by "the one-workflow view, [autoplot.nested_results()]'s" |
| 92 | summary.nested_results_set · Counting what contributed · "The performance view's subtitle gives the" | c | rejected, paragraph: single-claim sentences |
| 93 | summary.nested_results_set · Counting what contributed · "A tuned parameter whose id is" | a | fixed: moved to the end of "What `agreement()` returns" |
