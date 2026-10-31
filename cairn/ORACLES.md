# Oracle registry

This file records each oracle that the test comments at `576c3d19` recorded, by id, type, source and asserting test. The two greps below list those records. The file leaves out oracles whose comments the two greps do not read, such as the two selection tests that the selection group names. With it, a reviewer can audit the rule that each numeric result has at least two independent oracle types (DESIGN.md Conventions, GP2). Test comments hold each oracle's source, and for most oracles the test that pins it, but never its id or type (the test-comment rule). A milestone that adds or removes an oracle updates this file at its review. M164 added six rows for tests written after `576c3d19`, each naming its test in quotes. M166 added five more, and the lines that D-123 asks for.

M163 built the file on 2026-10-31 from the oracle records in `tests/testthat/` at `576c3d19`. That commit is the last one before M155 removed oracle ids and types from test comments. Two greps list the records that M163 read:

- Typed records: `git grep -E '^# +O[0-9]+[a-z]?( +--)? +type' 576c3d19 -- tests/testthat` (71 records in 26 files).
- Prose records: the files that `git grep -l -i -E '^# .*oracle' 576c3d19 -- tests/testthat` lists and that hold no typed record (20 files, listed at the end).

An id is the test file's name without `test-` and `.R`, then the record's own label (`O1`, `O3b`). A prose record takes `U1`, `U2` in file order. An oracle that a later milestone adds takes the `O` number after the highest one its file uses here. If its file uses none, it takes `O1`. A type is one of the doctrine's five: frozen, live, invariant, closed-form, simulation-coverage. Where the record used another word, the row gives that word in brackets. "Analytic" maps to closed-form. "Analytic by-hand" maps by what the oracle does: an independent run of the pipeline by hand is live, and formulas written out in code are closed-form. A reference that runs the package's own function by hand and compares is invariant, whatever word the record used.

Each test line gives a file under `tests/testthat/` and the first argument of a `test_that()` call in that file at the milestone's head. A literal name is in double quotes. For a name built in code, the line gives `code` and the one-line deparsed call. M163 mapped the names from `576c3d19` through `benchmarks/test-renames-576c3d19.csv`. Where a later commit merged tests, as six workflow-map tests became one `paste0()` loop, M163 read the file at the head. A test line ending "(found by reading)" is a test that the record does not name, found in the file's code. If a record's text quotes a test's name, the record names that test. In the quote, `...` or text in angle brackets matches any text. The full rule is M163's AC1, in the git history of `cairn/milestones/M163-oracle-registry.md`. A prose record names no test. Where a string quoted after "Pinned by" names no test, the row says so.

Each group collects rows that test one result, as this file cuts the results. The groups are one cut, and a finer cut can find more results backed by one type. M166 checked the nine that M163's and M164's reviews found. Each gained a row of a second type, or its group carries a line that says why it owes none (D-123). Rows for time-series designs join their function's group, because the design is an input to the same result. D-079 gives that reason for the Bayesian, racing and annealing tuners: the outer design never reaches tuner code. For the other functions, and for inner designs, pairs and the splits group, the grouping is this file's choice. Each row's source names its design. A row that tests two results is written once, and the second group counts it by id.

## nested_tune_grid() estimate: live, invariant (2 types)

- `nested-tune-grid-oracles/O1` live. Source: `reference_nested_loop()` in helper-orchestration.R, written from the documented seed contract.
  - test-nested-tune-grid-oracles.R :: "per-fold metrics and selections match a hand-rolled reference loop"
  - test-nested-tune-grid-oracles.R :: "the reference loop also matches with a stochastic engine" (found by reading)
- `nested-tune-grid-oracles/O2` invariant. Source: a single-candidate grid has nothing to select, so each fold equals `tune::fit_resamples()` on the same outer rset.
  - test-nested-tune-grid-oracles.R :: "a single-candidate grid degenerates to fit_resamples()"
- `metrics-argument/O1` live. Source: `reference_nested_loop()` on the sep_* fixture, where the first metric of the set selects.
  - test-metrics-argument.R :: "the first metric in the set selects, and the outer loop scores every metric"
- `time-series-designs/O1` live. Source: `reference_nested_loop()` on rolling-origin and sliding outer designs. The string its record quotes after "Pinned by the four", "match(es) a hand-rolled reference loop", names no test.
  - test-time-series-designs.R :: "a rolling-origin design matches a hand-rolled reference loop" (found by reading)
  - test-time-series-designs.R :: "a sliding-window design matches a hand-rolled reference loop" (found by reading)
  - test-time-series-designs.R :: code sprintf("a %s design matches a hand-rolled reference loop", design) (found by reading)
- `time-series-inner/O1` live. Source: `reference_nested_loop()` on inner sliding designs.
  - test-time-series-inner.R :: code sprintf("nested_tune_grid() on an inner %s design matches a hand-rolled reference loop", design)
- `time-series-pairs-index/O2` live. Source: `reference_nested_loop()` on the sliding-index pairs.
  - test-time-series-pairs-index.R :: code sprintf("nested_tune_grid() on the %s pair matches a hand-rolled reference loop", pair)
- `time-series-pairs-period/O2` live. Source: `reference_nested_loop()` on the sliding-period pairs.
  - test-time-series-pairs-period.R :: code sprintf("nested_tune_grid() on the %s pair matches a hand-rolled reference loop", pair)
- `time-series-pairs-window/O2` live. Source: `reference_nested_loop()` on the sliding-window pairs.
  - test-time-series-pairs-window.R :: code sprintf("nested_tune_grid() on the %s pair matches a hand-rolled reference loop", pair)

## nested_tune_grid() evaluated-candidate record: live, invariant (2 types)

- `nested-tune-grid-oracles/O3` live. Source: `tune::tune_grid()` re-run by hand on a fold's inner resamples under its `.tuning_seed`.
  - test-nested-tune-grid-oracles.R :: "an integer grid records the candidates that fold actually expanded"
- `nested-tune-grid-oracles/O4` invariant. Source: a data-frame grid comes back as itself, since nothing expands.
  - test-nested-tune-grid-results.R :: "each fold records the candidates its inner tuning actually scored"

## Selection rules and the selection metric: live, closed-form (2 types)

M164 added the closed-form row, which covers tune's three rules. M166 added closed-form rows for the desirability rule and the recorded selection metric. D-079 counts two oracles for the selection rules, grid and racing, but both are tune's own selector, one type. The racing one is a test in test-nested-tune-race-oracles.R: "each selection rule picks what tune's selector picks on the fold's race". No oracle record at `576c3d19` names it, so it has no row here. The same holds for the Bayesian path's desirability test in test-nested-tune-bayes-oracles.R, "the desirability rule picks what desirability2 picks on the fold's Bayesian run". Its comment names desirability2 as the reference. That file also holds typed records, so neither grep reads the comment as a prose record. It is live, the type this group already holds.

- `nested-tune-grid-oracles/O5` live. Source: tune's selectors called by name on each fold's hand-run tuning result (`reference_select()`).
  - test-nested-tune-grid-oracles.R :: "each selection rule picks what tune's selector picks on the fold's inner run" (found by reading)
- `nested-tune-grid-oracles/O6` live. Source: `desirability2::select_best_desirability()` called by name on each fold's hand-run tuning result.
  - test-nested-tune-grid-oracles.R :: "the desirability rule picks what desirability2 picks on the fold's inner run" (found by reading)
- `nested-tune-grid-oracles/O7` closed-form. Source: `select_best()`, `select_by_one_std_err()` and `select_by_pct_loss()` as tune 2.1.0's help page defines them, written out on each fold's `.inner_metrics`. The page's percent-loss example divides by the candidate's value and tune's code by the best's, which `references/tune-select-best.md` records.
  - test-nested-tune-grid-oracles.R :: "each selection rule picks the candidate its definition names in the fold's inner metrics"
- `nested-tune-grid-oracles/O8` closed-form. Source: the desirability terms and their geometric mean, as desirability2 0.2.0's help pages define them. They are written out on each fold's `.inner_metrics`, over each term's observed range. `references/desirability2-select-best.md` records the pages.
  - test-nested-tune-grid-oracles.R :: "the desirability rule picks the candidate its definition names in the fold's inner metrics"
- `nested-final-fit-results/U1` live. Source: tune's selector on the final fit's `$tuning`.
  - test-nested-final-fit-results.R :: "the final fit selects by the recorded rule, and records it" (found by reading)
- `nested-final-fit-results/U2` live. Source: `desirability2::select_best_desirability()` on the run `extract_tune_results()` returns.
  - test-nested-final-fit-results.R :: "the final fit selects by a recorded desirability rule" (found by reading)
- `selection-metric/U1` live. Source: `tune::.get_tune_metric_names()` on the final fit's stored tuning run.
  - test-selection-metric.R :: "a grid run records the first metric of the set it was given, in either order" (found by reading)
  - test-selection-metric.R :: "a grid run given no metric set records the first metric of tune's default" (found by reading)
  - test-selection-metric.R :: "the Bayesian, racing and annealing runs record the first metric" (found by reading)
- `selection-metric/O1` closed-form. Source: the first name of the metric set the test passes, read off the set's `metrics` attribute. It is compared with the entry on the results object and on its final fit.
  - test-selection-metric.R :: "a grid run records the first metric of the set it was given, in either order"

## nested_tune_bayes() estimate: live, invariant (2 types)

The records split this result in two. At the initial stage, O1 and O2 are the two types. At the iteration stage only O1 and O3 apply. The proposals are tune's own Gaussian-process search, and no independent oracle for them exists (the records cite the plan gate of 2026-09-01). O3 is a serial-against-parallel identity, which test-parallel-identity.R calls a mode-independence check, not a correctness check. Under D-123 the iteration stage keeps this one correctness type.

- `nested-tune-bayes-oracles/O1` live. Source: `reference_nested_bayes_loop()` in helper-orchestration.R, written from the seed contract.
  - test-nested-tune-bayes-oracles.R :: "per-fold metrics and selections match a hand-rolled Bayesian reference loop"
  - test-nested-tune-bayes-oracles.R :: "the Bayesian reference loop also matches with a stochastic engine"
- `nested-tune-bayes-oracles/O2` invariant. Source: at `iter = 0` a Bayesian run equals `nested_tune_grid()` on the space-filling grid of its initial candidates.
  - test-nested-tune-bayes-oracles.R :: "at iter = 0 the Bayesian path is the grid path on the space-filling grid"
- `nested-tune-bayes-oracles/O3` invariant. Source: the same seed gives an identical result serially and at two daemons.
  - test-parallel-identity.R :: "the Bayesian path matches serial at two daemons" (found by reading)
- `nested-tune-bayes-oracles/O4` live. Source: the reference loop handed the caller's `control_bayes()` under the documented merge.
  - test-nested-tune-bayes-oracles.R :: "a control passed through `...` reaches every fold"
- `time-series-bayes/O1` live. Source: `reference_nested_bayes_loop()` on the rolling-origin design.
  - test-time-series-bayes.R :: code sprintf("nested_tune_bayes() matches its reference loop on a %s design", design)
- `time-series-pairs-other/O1` live. Source: `reference_nested_bayes_loop()`, `reference_nested_race_loop()` and `reference_nested_anneal_loop()` on the sliding-window / sliding-window pair. Also counted in the racing and annealing groups.
  - test-time-series-pairs-other.R :: code sprintf("nested_tune_bayes() on the %s pair matches its reference loop", pair)
  - test-time-series-pairs-other.R :: code sprintf("%s on the %s pair matches its reference loop", fn, pair)
  - test-time-series-pairs-other.R :: code sprintf("nested_tune_sim_anneal() on the %s pair matches its reference loop", pair)

## nested_tune_race_anova() and nested_tune_race_win_loss() estimate: live, invariant (2 types)

The fold record holds every candidate the race scored. Its rows for eliminated candidates come from the same `collect_metrics(all_configs = TRUE)` call in `inner_metrics_table()` as the survivors' rows. O2 checks the survivors' rows against the grid path, and O3 checks the whole table, so the record owes no oracle of its own (D-123).

- `nested-tune-race-oracles/O1` live. Source: `reference_nested_race_loop()` in helper-orchestration.R, written from the seed contract. The string its record quotes after "Pinned by" names no test: the test's name adds "(deterministic)".
  - test-nested-tune-race-oracles.R :: "per-fold metrics, selections and inner tables match a hand-rolled racing reference loop (deterministic)" (found by reading)
  - test-nested-tune-race-oracles.R :: "the racing reference loop also matches on the metric-separating fixture" (found by reading)
- `nested-tune-race-oracles/O2` invariant. Source: a candidate raced to the end was scored on the resamples `tune_grid()` scores, so its mean equals the grid orchestrator's.
  - test-nested-tune-race-oracles.R :: "a candidate raced to the end carries the grid path's mean"
- `nested-tune-race-oracles/O3` live. Source: `collect_metrics(<the race>, all_configs = TRUE)` and `select_best()` on the race.
  - test-nested-tune-race-oracles.R :: "the fold record is every candidate the race scored, and the selection a survivor"
- `nested-tune-race-oracles/O4` invariant. Source: the same seed gives an identical result serially and at two daemons. test-parallel-identity.R calls this a mode-independence check, not a correctness check.
  - test-parallel-identity.R :: "both racing paths match serial at two daemons" (found by reading)
- `time-series-race/O1` live. Source: `reference_nested_race_loop()` on the rolling-origin design, for each racer.
  - test-time-series-race.R :: code sprintf("%s matches its reference loop on a %s design", fn, design)
- Also counted: `time-series-pairs-other/O1` live.

## nested_tune_sim_anneal() estimate: live, invariant (2 types)

The records split this result in two. At the initial stage, O1 and O2 are the two types. At the iteration stage only O1 and O3 apply. The perturbations are finetune's own search, and no independent oracle for them exists. O3 is a serial-against-parallel identity, which test-parallel-identity.R calls a mode-independence check, not a correctness check. Under D-123 the iteration stage keeps this one correctness type.

- `nested-tune-sim-anneal-oracles/O1` live. Source: `reference_nested_anneal_loop()` in helper-orchestration.R, written from the seed contract. The string its record quotes after "Pinned by" names no test: the test's name adds "(deterministic)".
  - test-nested-tune-sim-anneal-oracles.R :: "per-fold metrics, selections and inner tables match a hand-rolled annealing reference loop (deterministic)" (found by reading)
  - test-nested-tune-sim-anneal-oracles.R :: "the annealing reference loop also matches on the metric-separating fixture" (found by reading)
- `nested-tune-sim-anneal-oracles/O2` invariant. Source: the `initial` candidates are a space-filling design scored by `tune_grid()`, so the `.iter == 0` rows equal the grid path's under the same seed.
  - test-nested-tune-sim-anneal-oracles.R :: "the initial candidates are the grid path's under the same seed"
- `nested-tune-sim-anneal-oracles/O3` invariant. Source: the same seed gives an identical result serially and at two daemons.
  - test-parallel-identity.R :: "the annealing path matches serial at two daemons" (found by reading)
- `time-series-anneal/O1` live. Source: `reference_nested_anneal_loop()` on the rolling-origin design.
  - test-time-series-anneal.R :: code sprintf("nested_tune_sim_anneal() matches its reference loop on a %s design", design)
- Also counted: `time-series-pairs-other/O1` live.

## nested_fit_resamples() estimate: live, closed-form (2 types)

- `nested-fit-resamples-oracles/O1` live. Source: `tune::fit_resamples()` on the same outer `vfold_cv()` splits under the same seed.
  - test-nested-fit-resamples-oracles.R :: "every fold's metrics are identical to fit_resamples() on the same outer splits"
- `nested-fit-resamples-oracles/O2` live ["analytic by-hand"]. Source: each fold done by hand with no tune call: `fit()`, `predict()`, then the metric set.
  - test-nested-fit-resamples-oracles.R :: "every fold's metrics are identical to a by-hand fit, predict and score"
- `nested-fit-resamples-oracles/O3` closed-form ["analytic"]. Source: nachum2026, Lemma 4.9 and Theorem 4.10 (p. 11), the mean squared error of k-fold CV for the majority rule.
  - test-nested-fit-resamples-oracles.R :: "the outer estimate's mean squared error for the majority rule is nachum2026's closed form"
- `time-series-designs/O5` live. Source: `tune::fit_resamples()` on outer splits rebuilt from the fixture's literal outer call.
  - test-time-series-designs.R :: code sprintf("nested_fit_resamples() matches fit_resamples() on a %s design", design)
- `time-series-inner-other/O1` live. Source: `tune::fit_resamples()` on the outer `rolling_origin()` design. It shows only that the inner design is accepted.
  - test-time-series-inner-other.R :: code sprintf("nested_fit_resamples() matches fit_resamples() on an inner %s design", design)
- `time-series-pairs-other/O2` live. Source: `tune::fit_resamples()` on the pair's outer `sliding_window()` design. It shows only that the inner design is accepted.
  - test-time-series-pairs-other.R :: code sprintf("nested_fit_resamples() on the %s pair matches fit_resamples()", pair)

## nested_final_fit() on grid results: live, invariant (2 types)

- `nested-final-fit-oracles/O3` live. Source: `reference_final_fit()` in helper-orchestration.R, written from the documented seed contract.
  - test-nested-final-fit-oracles.R :: "the final fit matches a hand-rolled reference pipeline"
- `nested-final-fit-oracles/O4` invariant. Source: a single-candidate grid gives the direct fit of the workflow finalized on that candidate.
  - test-nested-final-fit-oracles.R :: "a single-candidate grid degenerates to a direct fit"
- `nested-final-fit-oracles/O5` live. Source: `tune::fit_best()` on the same tuning run. Its Bayesian strand, `tune::fit_best()` on the reference's own `tune_bayes()` run, is part of this row. The group "nested_final_fit() on Bayesian results" also counts it.
  - test-nested-final-fit-oracles.R :: "the final fit matches tune::fit_best() on the same tuning run"
  - test-nested-final-fit-oracles.R :: "the Bayesian final fit matches tune::fit_best() on the reference run" (found by reading)
- `time-series-designs/O3` live. Source: `tune::tune_grid()`, `tune::select_best()` and `fit()` by hand on an inner design built from the fixture's literal `rolling_origin()` call.
  - test-time-series-designs.R :: "the final fit on a rolling-origin design matches a hand-rolled reference"
- `time-series-inner/O3` live. Source: the same hand run on an inner design built from the fixture's literal inner call.
  - test-time-series-inner.R :: code sprintf("the final fit on an inner %s design matches a hand-rolled reference", design)
- `time-series-pairs-other/O4` live. Source: `reference_final_fit()` handed the sliding-window inner call.
  - test-time-series-pairs-other.R :: code sprintf("the grid final fit on the %s pair matches its reference", pair)

## nested_final_fit() on Bayesian results: live, invariant (2 types)

- `nested-final-fit-oracles/O3b` live. Source: `reference_bayes_final_fit()` in helper-orchestration.R, written from the seed contract.
  - test-nested-final-fit-oracles.R :: "the Bayesian final fit matches a hand-rolled reference pipeline"
- `nested-final-fit-oracles/O4b` invariant. Source: at `iter = 0` the Bayesian final fit equals the grid final fit on the space-filling grid.
  - test-nested-final-fit-oracles.R :: "at iter = 0 the Bayesian final fit is the grid final fit on the space-filling grid"
- `nested-final-fit-oracles/O3c` live. Source: `reference_bayes_final_fit()` handed the recorded control under the documented merge.
  - test-nested-final-fit-oracles.R :: "the final fit re-runs under the recorded control"
- `time-series-bayes/O2` live. Source: `reference_bayes_final_fit()` handed the fixture's literal inner `rolling_origin()` call.
  - test-time-series-bayes.R :: code sprintf("the Bayesian final fit on a %s result matches its reference", design)
- Also counted: `nested-final-fit-oracles/O5` live (its Bayesian strand).

## nested_final_fit() on racing results: live, invariant (2 types)

- `nested-final-fit-race/O6` invariant. Source: the recorded rule's pick from the final fit's own race (`extract_tune_results()`), finalized and fit by hand on the same data. The fixture is the deterministic one.
  - test-nested-final-fit-race.R :: "the racing final fit is the workflow finalized on its own race's pick"
- `nested-final-fit-race/O5` live. Source: `reference_race_final_fit()` in helper-orchestration.R, written from the documented contract.
  - test-nested-final-fit-race.R :: "the racing final fit matches a hand-rolled reference pipeline"
- `time-series-race/O2` live. Source: `reference_race_final_fit()` handed the fixture's literal inner `rolling_origin()` call.
  - test-time-series-race.R :: code sprintf("the %s final fit on a rolling-origin result matches its reference", fn)

## nested_final_fit() on annealing results: live, invariant (2 types)

- `nested-final-fit-sim-anneal/O6` invariant. Source: the recorded rule's pick from the final fit's own annealing run (`extract_tune_results()`), finalized and fit by hand on the same data. The fixture is the deterministic one.
  - test-nested-final-fit-sim-anneal.R :: "the annealing final fit is the workflow finalized on its own run's pick"
- `nested-final-fit-sim-anneal/O5` live. Source: `reference_anneal_final_fit()` in helper-orchestration.R, written from the documented contract.
  - test-nested-final-fit-sim-anneal.R :: "the annealing final fit matches a hand-rolled reference pipeline"
- `time-series-anneal/O2` live. Source: `reference_anneal_final_fit()` handed the fixture's literal inner `rolling_origin()` call.
  - test-time-series-anneal.R :: "the annealing final fit on a rolling-origin result matches its reference"

## nested_workflow_map(): invariant, live (2 types)

- `nested-workflow-map-oracles/O2` live. Source: `reference_nested_loop()` in helper-orchestration.R on the grid workflow of `wset_two()`. The workflow is deterministic, so the seed reaches nothing the test compares.
  - test-nested-workflow-map-oracles.R :: "the grid element matches a hand-rolled reference loop"
- `nested-workflow-map-oracles/O1` invariant ["live"]. Source: the orchestrator each workflow routes to, called by hand with the same arguments after `set.seed()` of the same value.
  - test-nested-workflow-map-oracles.R :: code paste0("each element is identical to the hand call (fn = ", fn, ")") (found by reading)
- `time-series-designs/O7` invariant ["live"]. Source: `hand_call()` in helper-orchestration.R under the same seed.
  - test-time-series-designs.R :: "a workflow set on a rolling-origin design matches the hand calls"
- `time-series-inner-other/O2` invariant ["live"]. Source: `hand_call()` on an inner sliding design.
  - test-time-series-inner-other.R :: code sprintf("a workflow set on an inner %s design matches the hand calls", design)
- `time-series-pairs-other/O3` invariant ["live"]. Source: `hand_call()` on the sliding-window / sliding-window pair.
  - test-time-series-pairs-other.R :: code sprintf("a workflow set on the %s pair matches the hand calls", pair)

## Splits that nested_resamples() builds: live, invariant (2 types)

- `nested-resamples-identity/O1` invariant. Source: each inner split's rows, mapped back through a row-id column to their outer analysis set. The design is a 3-fold outer and 4-fold inner one.
  - test-nested-resamples-identity.R :: "inner v-fold splits partition their outer analysis rows"

- `nested-resamples-identity/U1` live. Source: `rsample::nested_cv()` recomputed at test time, matched row for row under one seed.
  - test-nested-resamples-identity.R :: "inner splits match rsample::nested_cv() for a v-fold/v-fold scheme" (found by reading)
  - test-nested-resamples-identity.R :: "inner splits match rsample::nested_cv() for a v-fold/bootstrap scheme" (found by reading)
  - test-nested-resamples-identity.R :: "inner splits match rsample::nested_cv() for a repeated outer scheme" (found by reading)
  - test-nested-resamples-identity.R :: "an already-evaluated outer rset is accepted and matches" (found by reading)
- `time-series-designs/O2` live. Source: `rsample::nested_cv()` on the time-series outer designs. The string its record quotes after "Pinned by the four", "splits match rsample::nested_cv()", names no test.
  - test-time-series-designs.R :: "rolling-origin splits match rsample::nested_cv()" (found by reading)
  - test-time-series-designs.R :: "sliding-window splits match rsample::nested_cv()" (found by reading)
  - test-time-series-designs.R :: code sprintf("%s splits match rsample::nested_cv()", design) (found by reading)
- `time-series-inner/O2` live. Source: `rsample::nested_cv()` on inner sliding designs.
  - test-time-series-inner.R :: code sprintf("inner %s splits match rsample::nested_cv()", design)
- `time-series-pairs-index/O1` live. Source: `rsample::nested_cv()` on the pair's own arguments (`ts_pair_reference()`).
  - test-time-series-pairs-index.R :: code sprintf("%s splits match rsample::nested_cv()", pair)
- `time-series-pairs-period/O1` live. Source: `rsample::nested_cv()` on the pair's own arguments (`ts_pair_reference()`).
  - test-time-series-pairs-period.R :: code sprintf("%s splits match rsample::nested_cv()", pair)
- `time-series-pairs-window/O1` live. Source: `rsample::nested_cv()` on the pair's own arguments (`ts_pair_reference()`).
  - test-time-series-pairs-window.R :: code sprintf("%s splits match rsample::nested_cv()", pair)

## Each fold's outer-fit predictions and extracts: live, invariant (2 types)

- `nested-tune-grid-results/O1` invariant. Source: `predict()` of each fold's extracted outer-fit workflow on that fold's outer assessment rows.
  - test-nested-tune-grid-results.R :: "each fold's saved predictions are its extracted outer-fit workflow's predictions"

- `nested-tune-grid-results/U1` live. Source: `tune::last_fit()` called by hand on each fold's outer split under its recorded `.outer_fit_seed`.
  - test-nested-tune-grid-results.R :: "save_pred = TRUE keeps each fold's outer-fit predictions, identical to last_fit()'s" (found by reading)
  - test-nested-tune-grid-results.R :: "extract = f keeps f() of each fold's outer-fit workflow, identical to f() on last_fit()'s" (found by reading)

## Evaluation time on censored models: closed-form, live, invariant (3 types)

- `eval-time/O1` closed-form. Source: the definition of the IPCW Brier score, with Graf's weights from a reverse Kaplan-Meier fit on each fold's analysis rows.
  - test-eval-time.R :: "the metric each outer fold reports at the named evaluation time is the IPCW Brier score"
- `eval-time/O2` live. Source: `tune::tune_grid()` and `tune::last_fit()` run by the test from the fold's inner resamples and split, seeded as `nested_fold_fit()` seeds them. The string its record quotes after "Pinned by", "AC3: each run's per-fold metrics are the ones tune produces at that evaluation time", names no test, at the head or at `576c3d19`.
  - test-eval-time.R :: "two runs differing only in `eval_time` report different metrics, each the one tune produces" (found by reading)
  - test-eval-time.R :: "nested_final_fit() tunes and selects under the caller's evaluation time"
- `eval-time/O3` invariant. Source: a run at a multi-element `eval_time` and a run at its first element select and report the same. The string its record quotes after "Pinned by", "AC3: a multi-element evaluation time reports what its first element names", names no test, at the head or at `576c3d19`: the test's name has `` `eval_time` `` for "evaluation time".
  - test-eval-time.R :: "a multi-element `eval_time` reports what its first element names" (found by reading)
- `eval-time/O4` invariant. Source: two final fits, one on a run at a two-element `eval_time` and one on the run at its first element. They select the same candidate and predict the same, for both orders of the fixture's two times.
  - test-eval-time.R :: "a final fit at a multi-element `eval_time` is the final fit at its first element"

## Event level on classification models: closed-form, live (2 types)

- `event-level/O1` closed-form. Source: the definition of sensitivity, recomputed from a refit of each fold's selected candidate.
  - test-event-level.R :: "the sensitivity each outer fold reports is the one yardstick computes at that event level"
- `event-level/O2` live. Source: `tune::tune_grid()` run by the test under `event_level = "second"`, seeded by the by-hand recipe in `R/nested-final-fit.R`.
  - test-event-level.R :: "nested_final_fit() tunes under the caller's event level"
- `event-level/O3` invariant. Source: the final fit's tuning metrics at `event_level = "first"` and at `"second"`. Candidate for candidate, they keep `roc_auc` and exchange `sens` with `spec`, on a fixture where the two differ.
  - test-event-level.R :: "nested_final_fit() tunes under the caller's event level"

## Range finalized from the data: closed-form, live (2 types)

- `nested-tune-finalize/O1` closed-form ["analytic"]. Source: `dials::get_n_frac_range()`, whose range is `floor(nrow(x) * frac)` of the frame it is handed.
  - test-nested-tune-finalize.R :: "every candidate a fold searched lies inside the range its analysis rows finalize"
  - test-nested-tune-finalize.R :: "under a repeated outer row every candidate a fold searched lies inside the range its 65 analysis rows finalize"
- `nested-tune-finalize/O2` live. Source: `rsample::nested_cv()` under the same seed, whose inner splits carry each fold's analysis set as their frame.
  - test-nested-tune-finalize.R :: "a nested_resamples() design and the nested_cv() design it matches tune identically"
  - test-nested-tune-finalize.R :: "under a repeated outer row a nested_resamples() design and its analysis-frame reference tune identically"
- `time-series-pairs-other/O5` closed-form ["analytic"]. Source: `dials::get_n_frac_range()` on each fold's outer analysis rows of the pair.
  - test-time-series-pairs-other.R :: code sprintf("a range finalized from the data on the %s pair is finalized on each fold's analysis rows", pair) (found by reading)
- `time-series-pairs-other/O6` live. Source: `rsample::nested_cv()` on the pair's own call (`ts_pair_reference()`).
  - test-time-series-pairs-other.R :: code sprintf("a range finalized from the data on the %s pair is finalized on each fold's analysis rows", pair) (found by reading)

## Memory size of a nested_resamples() design: live, closed-form (2 types)

- `nested-resamples-memory/O1` live. Source: `rsample::nested_cv()` recomputed at test time.
  - test-nested-resamples-memory.R :: "the size slope is far shallower than rsample::nested_cv()'s"
- `nested-resamples-memory/O2` closed-form. Source: `analytic_size()`, a storage model of one shared data copy plus the outer and inner index vectors.
  - test-nested-resamples-memory.R :: "measured size matches the analytic prediction within 2%" (found by reading)
- Also counted for the size slope: `nested-resamples-memory/O2` closed-form. The slope that O1's test bounds is computed from the same measured sizes, each of which O2 checks against `analytic_size()`.

## Size of a fold's dispatch payload: closed-form, invariant (2 types)

- `parallel-payload/O1` closed-form. Source: `predicted_lean_bytes()` in helper-payload-size.R, from `n`, `v` and `inner_v` alone.
  - test-parallel-payload.R :: "a leaned payload weighs what the index vectors alone predict"
- `parallel-payload/O2` invariant. Source: `count_data_copies()` in helper-payload-size.R, which counts a data column's wire bytes in the stream.
  - test-parallel-payload.R :: "a fold's dispatch carries the data exactly once"
  - test-parallel-payload.R :: "a design whose folds share no frame is leaned too" (found by reading)

## Resample weights: closed-form, live (2 types)

- `resample-weights/O1` closed-form ["analytic by-hand"]. Source: tune's weighted formulas written out in `weighted_summary()` (tune 2.1.0), applied to the unweighted run's per-fold estimates.
  - test-resample-weights.R :: "nested_fit_resamples() on a weighted design reports tune's weighted mean and standard error" (found by reading)
  - test-resample-weights.R :: "nested_tune_grid() on a weighted design reports tune's weighted mean and standard error" (found by reading)
  - test-resample-weights.R :: "with one fold failed, the weighted average covers the folds that scored" (found by reading)
  - test-resample-weights.R :: "with a fold scoring NA, the weights are renormalized over the folds that scored" (found by reading)
- `resample-weights/O2` live. Source: `tune::fit_resamples()` on the same outer splits under the same weights.
  - test-resample-weights.R :: "nested_fit_resamples() on a weighted design matches tune::fit_resamples() under the same weights" (found by reading)
- `resample-weights/O3` invariant. Source: two runs that differ only in the weight of a fold that a summary row leaves out. The fold failed or scored NA. The two runs give that row the same mean, standard error and count.
  - test-resample-weights.R :: "a new weight on the fold a summary row leaves out leaves that row unchanged"

## collect_predictions(summarize = TRUE) average: live, closed-form (2 types)

The cases that only `hand_average()` checks are candidates that differ across repeats, renormalized probabilities, and the censored median time and mean survival. They run the same `average_fold_predictions()` branches that U1's four tests run. U1 and U2 back them, and they owe no oracle of their own (D-123). Each censored row is held out twice in these fixtures, so the median and the mean of `.pred_time` agree there. The parked row "M126 review leftovers on averaging" holds that gap.

- `collect-predictions-summarize/U1` live. Source: `tune::collect_predictions(summarize = TRUE)` on `tune::fit_resamples()` over the same outer splits.
  - test-collect-predictions-summarize.R :: "a regression average equals tune's on the same outer splits" (found by reading)
  - test-collect-predictions-summarize.R :: "a probability classification average equals tune's" (found by reading)
  - test-collect-predictions-summarize.R :: "a class-only classification average equals tune's" (found by reading)
  - test-collect-predictions-summarize.R :: "a censored regression average equals tune's" (found by reading)
- `collect-predictions-summarize/U2` closed-form. Source: `hand_average()`, base R written from the rules the help page states.
  - test-collect-predictions-summarize.R :: "a regression average spans the candidates the repeats selected" (found by reading)
  - test-collect-predictions-summarize.R :: "a probability average is renormalized and names its class" (found by reading)
  - test-collect-predictions-summarize.R :: "a censored average takes the median time and the mean survival" (found by reading)
  - test-collect-predictions-summarize.R :: "a missing .pred_time makes the row's median missing" (found by reading)

## compute_metrics() rescoring: invariant, live (2 types)

`compute_metrics()` runs the same scoring code, `score_fold()`, on the run's own metric set and on a new one. U1 and U2 back both inputs, and neither owes an oracle of its own (D-123).

- `compute-metrics/U1` invariant. Source: `collect_metrics()` on the same run, which reads the `.metrics` that `tune::last_fit()` wrote.
  - test-compute-metrics.R :: "with the run's metric set, compute_metrics() is collect_metrics() on a regression run" (found by reading)
  - test-compute-metrics.R :: "with the run's metric set and level, compute_metrics() is collect_metrics() on a classification run at event_level = "second"" (found by reading)
  - test-compute-metrics.R :: "with the run's metric set, compute_metrics() is collect_metrics() on a censored-regression run" (found by reading)
- `compute-metrics/U2` live. Source: yardstick called metric by metric on each fold's rows of `collect_predictions()`, with the summary computed by hand.
  - test-compute-metrics.R :: "a numeric metric set the run did not use is yardstick on each fold's rows, NA fold left out of the summary" (found by reading)
  - test-compute-metrics.R :: "a class-probability metric set the run did not use is yardstick on each fold's rows, NA fold left out of the summary" (found by reading)

The four groups below hold tables that restate what a run stored: numbers that the groups above test, and fold labels read from the design. Three of them rest on one type. Under D-121 a table that restates numbers another group checks, or holds no number, owes no second type of its own. Each of the three names the group it rides on, or says that it holds no number.

## Stacked reader tables: live, invariant (2 types)

- `collect-readers/U1` live. Source: each stacked table rebuilt by hand with `dplyr::bind_rows()` or `vctrs::vec_rbind()` over the list column.
  - test-collect-readers.R :: "collect_notes() stacks every fold's notes under its label" (found by reading)
  - test-collect-readers.R :: "collect_notes() on a run with no note is zero rows with the same columns" (found by reading)
  - test-collect-readers.R :: "collect_selections() is one labelled row per completed fold" (found by reading)
  - test-collect-readers.R :: "collect_selections() warns once on a partial run and stacks the completed folds" (found by reading)
  - test-collect-readers.R :: "collect_selections() stacks over the union of columns, NA where a fold lacks one" (found by reading)
  - test-collect-readers.R :: "collect_inner_metrics() stacks each completed fold's inner table under its label" (found by reading)
  - test-collect-readers.R :: "collect_inner_metrics() warns once on a partial run and refuses an all-failed one" (found by reading)
  - test-collect-readers.R :: "collect_inner_metrics() stacks over the union of columns, NA where a fold lacks one" (found by reading)
  - test-collect-readers.R :: "every reader carries the recorded label columns, id and id2 on a repeated design" (found by reading)
- `collect-readers/U2` live. Source: `hand_stacked()` over `.predictions`, and an extracts table built by hand from the object's columns.
  - test-collect-readers.R :: "collect_predictions() stacks each completed fold's predictions under id and id2" (found by reading)
  - test-collect-readers.R :: "collect_extracts() is one row per completed fold, the value in a list column, NULL kept" (found by reading)
  - test-collect-readers.R :: "on a fitted run, collect_predictions() is the hand stack of what the folds kept" (found by reading)
- `nested-workflow-map-readers/U1` invariant. Source: each element's own table with the id in front, bound in set order.
  - test-nested-workflow-map-readers.R :: "every reader's table is bind_rows() of the elements' tables under wflow_id, in set order" (found by reading)
  - test-nested-workflow-map-readers.R :: "compute_metrics() and augment() on a set are bind_rows() of each workflow's call under wflow_id" (found by reading)

## Wide metric tables: live (1 type)

Rides on "nested_tune_grid() estimate", whose oracles check the per-fold outer metrics that the wide type pivots (D-121).

- `collect-metrics-wide/U1` live. Source: a second pivot written with `stats::reshape()` (`wide_reference()`).
  - test-collect-metrics-wide.R :: "the wide type pivots a classification run's metrics" (found by reading)
  - test-collect-metrics-wide.R :: "the wide type keeps the evaluation time as a key" (found by reading)
  - test-collect-metrics-wide.R :: "the wide type pivots a set, keyed on the workflow" (found by reading)
  - test-collect-metrics-wide.R :: "the wide type drops a weighted run's fold weights" (found by reading)
- `collect-inner-metrics-wide/U1` live. Source: tune's own wide table on fold 1's inner run, rebuilt by hand from the seed contract.
  - test-collect-inner-metrics-wide.R :: "fold 1's wide rows equal tune's wide table on fold 1's inner run" (found by reading)

## Fold labels: invariant (1 type)

Holds no number: the labels are the design's `id` and `id2` values (D-121).

- `fold-labels/U1` invariant. Source: the labels read row by row from the rsample design the run was given, which must agree with the labels on the result.
  - test-fold-labels.R :: "a repeated design's per-fold tables carry id and id2 from the design, long and wide" (found by reading)
  - test-fold-labels.R :: "a single-column design keeps its one id column, and the summaries match the repeated design's names" (found by reading)
  - test-fold-labels.R :: "a set over a repeated design carries wflow_id, id and id2 as separate columns" (found by reading)
  - test-fold-labels.R :: "the performance plot's fold axis pastes the design's labels and draws each non-missing estimate" (found by reading)
  - test-fold-labels.R :: "a fold with no metrics rows leaves the later folds' labels on their own rows" (found by reading)
  - test-fold-labels.R :: "a record that cannot label the rows gives one id of row positions" (found by reading)

## Rows that augment() joins: invariant (1 type)

Rides on "Each fold's outer-fit predictions and extracts" and "collect_predictions(summarize = TRUE) average", whose oracles check the predictions that `augment()` joins to the data (D-121).

- `augment/U1` invariant. Source: the expected table built from the data and from `collect_predictions()` by `.row`.
  - test-augment.R :: "on a v-fold design from nested_resamples(), augment() joins each row's held-out prediction" (found by reading)
  - test-augment.R :: "on a v-fold design from rsample::nested_cv(), augment() joins each row's held-out prediction" (found by reading)
  - test-augment.R :: "on a grouped v-fold design, augment() joins each row's held-out prediction" (found by reading)
  - test-augment.R :: "on a classification run, the class and probability columns are joined" (found by reading)
  - test-augment.R :: "on a censored-regression run, whose outcome names no data column, the predictions come first" (found by reading)
- `augment/U2` invariant. Source: `collect_predictions(summarize = TRUE)`, each data row's entry in the averaged table.
  - test-augment.R :: "on a repeated v-fold regression, each row joins its averaged prediction" (found by reading)
  - test-augment.R :: "on a repeated v-fold probability classification, each row joins its averaged probabilities and class" (found by reading)
  - test-augment.R :: "on a repeated v-fold censored regression, each row joins its averaged survival and time" (found by reading)
  - test-augment.R :: "on a Monte Carlo design that holds every row out, each row joins its averaged prediction" (found by reading)

## Files with prose oracle comments at 576c3d19

- helper-orchestration.R: records no oracle. Its header says it holds "Fixtures and the reference loop for the orchestration oracles".
- helper-payload-size.R: `parallel-payload/O1`, `parallel-payload/O2`. Its header names the two oracles whose records are in test-parallel-payload.R.
- test-augment.R: `augment/U1`, `augment/U2`.
- test-collect-inner-metrics-wide.R: `collect-inner-metrics-wide/U1`.
- test-collect-metrics-wide.R: `collect-metrics-wide/U1`.
- test-collect-predictions-summarize.R: `collect-predictions-summarize/U1`, `collect-predictions-summarize/U2`.
- test-collect-readers.R: `collect-readers/U1`, `collect-readers/U2`.
- test-compute-metrics.R: `compute-metrics/U1`, `compute-metrics/U2`.
- test-fold-labels.R: `fold-labels/U1`.
- test-nested-final-fit-extract.R: records no oracle. Its comments say none is owed, because the accessors produce no numeric result of their own.
- test-nested-final-fit-predict.R: records no oracle. Its comments say none is owed, because both methods delegate to the trained workflow.
- test-nested-final-fit-results.R: `nested-final-fit-results/U1`, `nested-final-fit-results/U2`.
- test-nested-resamples-identity.R: `nested-resamples-identity/U1`.
- test-nested-results-agreement.R: records no oracle. Its comments say that it computes no statistic that needs an oracle.
- test-nested-results-plot.R: records no oracle. Its comments say that the plot produces no numeric result of its own.
- test-nested-tune-grid-results.R: `nested-tune-grid-results/U1`, `nested-tune-grid-oracles/O4`. The typed record `nested-tune-grid-oracles/O4` names a test in it.
- test-nested-workflow-map-readers.R: `nested-workflow-map-readers/U1`.
- test-parallel-identity.R: `nested-tune-bayes-oracles/O3`, `nested-tune-race-oracles/O4`, `nested-tune-sim-anneal-oracles/O3`. Its comments call its tests mode-independence assertions, and those three typed records point at tests in it.
- test-parallel-metrics.R: records no oracle. Its comments say that it tests argument delivery, not a numeric result.
- test-selection-metric.R: `selection-metric/U1`.
