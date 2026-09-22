# M109: Selecting each fold's candidate by desirability over several metrics

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP3, GP1, GP3
- **Resolves:** —
- **Surface tier:** user-facing — a new rule on an exported constructor
- **Branch/PR:** m109-desirability-selection

## Goal

`selection_rule("desirability", ...)` selects each fold's candidate, and the final fit's, with desirability2's joint desirability over several metrics.

## Scope

**In:** A fourth rule on `selection_rule()` taking desirability2 terms as `...`. It is recorded in the procedure, printed, and applied by `nested_tune_grid()`, `nested_tune_bayes()` and `nested_final_fit()`. desirability2 joins Suggests. A D-entry supersedes D-056's clause that refuses a rule outside tune's three.

**Out:** The rule under `nested_tune_race_anova()`, `nested_tune_race_win_loss()` and `nested_tune_sim_anneal()`, which refuse it at entry here. The rule on a censored regression model, which `nested_tune_grid()` and `nested_tune_bayes()` refuse at entry here. Their support goes to a candidate row added with this plan.

## Acceptance criteria

- [ ] AC1: `selection_rule("desirability", ...)` takes desirability2 terms such as `maximize()` and `minimize()` as `...`. The procedure records the terms, and `print()` shows them. `nested_tune_grid()` and `nested_tune_bayes()` each refuse at entry a term that names neither a metric in the run's metric set nor a tuned parameter. With no `metrics`, the check uses the default set tune uses for the model's mode. The test names that error by class.
- [x] AC2: On a fixture with two metrics, each fold's `.selected` has the parameter values and `.config` that `desirability2::select_best_desirability()` gives with the same terms. The reference applies it to that fold's inner tuning run. That run comes from `reference_nested_loop()` for the grid and `reference_nested_bayes_loop()` for the Bayesian path, each run with the default rule. The test covers `nested_tune_grid()` and `nested_tune_bayes()`.
- [x] AC3: `nested_final_fit()` on such a result selects what `select_best_desirability()` selects on the run `extract_tune_results()` returns, tested.
- [x] AC4: Each of the two racing tuners and `nested_tune_sim_anneal()` refuses the rule at entry with an error the test names by class.
- [x] AC5: If desirability2 is not installed, three calls refuse with an error the test names by class. The first is `selection_rule("desirability", ...)`. The second is `nested_tune_grid()` given a rule built while the package was installed. The third is `nested_final_fit()` on a result that recorded the rule.
- [x] AC6: A D-entry records desirability2 joining Suggests, and a D-entry supersedes D-056's rule clause and, for this rule, its clause that orderings name only tuned parameters. `NEWS.md` describes the rule, and `selection_rule()`'s help documents it. `devtools::check()` gives 0 errors, 0 warnings, and no note absent from the check of `main` at the branch point.

## Coverage

- AC1 → T1, T2, T6, T7
- AC2 → T3, T8
- AC3 → T3
- AC4 → T2
- AC5 → T4
- AC6 → T1, T5, T9

## Tasks

- [x] T1: Install desirability2. Read its `NAMESPACE`, `select_best_desirability()`'s arguments and return columns, and whether a term can name a tuned parameter (LESSONS, claims about another package). Write the two D-entries, then add desirability2 to Suggests.
- [x] T2: Extend `selection_rule()` (`R/selection-rule.R:76`) with the rule. Capture the terms as expressions, as the orderings are captured. Add the entry check against the run's metric set and tuned parameters, and add the three tuners' refusal.
- [x] T3: Apply the rule where the recorded rule selects today, for the folds and the final fit. Write the AC2 and AC3 oracle tests, comparing parameter columns and `.config` only.
- [x] T4: Add the absent-package refusals in the pattern `check_tuner_installed()` uses (D-044), and test them with desirability2 masked.
- [x] T5: Write the help and `NEWS.md` text, then run `devtools::document()`, the prose sweeps from the verify slot, and `devtools::check()`.
- [ ] T6: Print each goal in full in `print()` and the "Selected by" line, and test a goal long enough that `rlang::as_label()` shortens it (review finding 3).
- [ ] T7: Refuse at build or entry a goal whose later arguments hold a variable or name a metric. No such goal must reach a fold (review findings 1 and 4).
- [ ] T8: For censored models, select at the first evaluation time as tune's selectors do, or refuse the rule, and test the choice (review finding 2).
- [ ] T9: Make the empty-selection hint name the rule that ran, and add the `nestedtune_selection_rule_terms` class and the `limit` refusal to NEWS. Narrow the help sentence on what desirability2 checks at build (review findings 5 and 9).

## Work log

- 2026-09-21: created by /milestone-plan.
- 2026-09-21: criteria audit ran in full mode and returned five findings, all fixed above. They were D-056's standing refusal, terms that can name parameters, no stored inner run for the oracle, return columns unverified, and no refusal for a final fit without the package.
- 2026-09-21: plan gate chose grid and Bayesian support with the other three tuners refusing, over all five tuners, because racing drops candidates before the end and needs its own oracle; falsified by desirability2 documenting its selector for racing results.
- 2026-09-21: re-audit in full mode returned four findings, all fixed after the plan commit. AC1 did not say which orchestrators check or which metric set applies by default. AC2 had no Bayesian reference, AC5 had no refusal on entry, and AC6 left D-056's parameters-only clause standing.
- 2026-09-21: implement started on branch m109-desirability-selection. desirability2 0.2.0 installed from CRAN.
- 2026-09-21: question gate took the four recommendations: Suggests floor 0.2.0, terms run through `desirability()` at build with errors rewrapped, classes `nestedtune_pkg_not_installed` reused plus `_unknown_term` and `_unsupported`, label kept as `desirability by <terms>`.
- 2026-09-21: T1 done. `show_best_desirability()` reads the wide `collect_metrics()` columns less `.config`, so a term can name a metric or a tuned parameter. D-072 and D-073 written, desirability2 (>= 0.2.0) in Suggests.
- 2026-09-21: T2 done. The constructor takes the fourth rule and runs its terms through `desirability()`. The registry gains a `desirability` field that the entry check reads to refuse the racers and annealing. The unknown-term check reads `check_metrics_arg()`. The constructor's absent-package refusal landed here, and its test waits for T4. Planted defects turned the new tests red. Suite and plain sweep clean.
- 2026-09-21: T3 done. `apply_selection_rule()` gained the branch in T2, so the folds and the final fit share it. The grid, Bayesian and final-fit oracle tests each use terms that move at least one pick off the default rule's, measured and recorded in the test files. A planted fallback to the default rule turned all three red. desirability2 refuses goals written as `desirability2::maximize()`. A cache miss on repeated reference-loop requests predates this branch and went to the fixture-key candidate row. Suite and plain sweep clean.
- 2026-09-21: T4 done. `nested_final_fit()` asks for desirability2 when the record holds the rule. Discovered sub-task: `needed_pkgs()` adds desirability2 for the rule, so a daemon without it is refused before any fold is sent. The three AC5 refusals are tested with the package masked, each beside a passing control, and a no-op planted check turned all three red. Suite and plain sweep clean.
- 2026-09-21: T5 done. `selection_rule()`'s help gains the fourth rule and a section on writing a goal, `nested_tune_grid()`'s select text names the rule, and NEWS.md has the entry. `document()` run, all six gating sweeps clean. `devtools::check()` on the branch gives 0 errors, 0 warnings, 0 notes. On main at the branch point, run from a worktree, it gives one note, for the worktree's `.git` file.
- 2026-09-21: claim audit: 50 claims read, 1 corrected — R/selection-rule.R, man/selection_rule.Rd (desirability2 estimates only the limits a goal leaves out). The reader re-read the correction and confirmed it.
- 2026-09-21: status set to review.
- 2026-09-21: review return 1 (defect). AC1 fails: `print()` shortened a long goal to `target(...)` (finding 3). A goal holding a variable passed entry and failed every fold (finding 1). At the gate the user sent findings 1-5 and 9 back as T6-T9 and findings 6-8 to the desirability candidate row. AC2-AC6 evidence stands. Status set to in-progress.
- 2026-09-21: resume question gate took both recommendations. T7 refuses at build any name in a goal's later arguments, pointing to `!!`. T8 refuses the rule on a censored regression model at entry. Scope Out gains that refusal, amended at this gate. Censored support joins the desirability candidate row.

## Decisions

## Review

Sync: `origin/main` is at ea063a1, the branch point, so nothing needed a merge. Unless stated, the evidence comes from `devtools::test()` over the nine touched test files on 2026-09-21, with 0 failures and 0 skips.

- AC1: `test-selection-rule.R` asserts that `$order` holds the terms as bare calls. It also asserts the `format()` label `desirability by maximize(rsq), minimize(num_comp, scale = 2)`. `print()` calls `format()`, and from the branch source it printed `<selection_rule> desirability by maximize(rsq), minimize(num_comp)`. The grid and Bayesian check files each assert class `nestedtune_selection_rule_unknown_term` for a term outside an explicit metric set. With no `metrics`, each asserts the same class for `accuracy` against tune's regression default. Passing controls for a metric, a tuned parameter, and a default-set metric reach the loop sentinel. Pass.
- AC2: `test-nested-tune-grid-oracles.R` (O6) and `test-nested-tune-bayes-oracles.R` compare each fold's `.selected` parameter columns and `.config` with `desirability2::select_best_desirability()`. The reference runs on that fold's run from `reference_nested_loop()` or `reference_nested_bayes_loop()` under the default rule, with rmse and rsq in the metric set. Each test also asserts that its picks differ from the default rule's picks on at least one fold. Pass.
- AC3: `test-nested-final-fit-results.R` fits `nested_final_fit()` on a grid result that recorded the rule. It asserts that `$selected` equals `select_best_desirability()` on the run `extract_tune_results()` returns, over the parameter columns and `.config`. It also asserts that the pick differs from `select_best()` by rmse on that run. Pass.
- AC4: `test-nested-tune-race-checks.R` loops over both racers and asserts class `nestedtune_selection_rule_unsupported` at entry, with a message naming `tune_grid`. `test-nested-tune-sim-anneal-checks.R` asserts the same class for `nested_tune_sim_anneal()`, with a message naming `tune_bayes`. Pass.
- AC5: `test-selection-rule-installed.R` masks desirability2 through `rlang::is_installed()`. It asserts class `nestedtune_pkg_not_installed` and the call name for three calls. They are `selection_rule()`, `nested_tune_grid()` given a rule built before the mask, and `nested_final_fit()` on a result that recorded the rule. Each has an unmasked passing control, and the orchestrator cases show the refusal fires before the loop or tuner sentinel. Pass.
- AC6: D-072 records desirability2 (>= 0.2.0) in Suggests. D-073 supersedes D-056's rule clause and, for this rule, its parameters-only ordering clause. `NEWS.md` has the entry, and `man/selection_rule.Rd` documents the rule and a section on writing a goal. `devtools::check()` on the branch gave 0 errors, 0 warnings, 0 notes (8 minutes, 2026-09-21). The implement log records one note on `main` at the branch point, for a worktree `.git` file, so the branch adds no note. Pass.

Consistency gate, 2026-09-21: `cairn_validate` exit 0 with 18 references-staleness advisories. `devtools::document()` left no diff. README is not touched. `pkgdown::check_pkgdown()` found no problems. All six gating prose sweeps exit 0. No DESIGN principle changed, so `cairn_impact` is skipped.

Independent review, three fresh-context lenses. The prior-review lens found no regressions against M69, M98 or D-056. Findings, most severe first:

1. [O] A goal argument written as a variable, as in `maximize(rsq, low = lo)`, passes the build and entry checks. After all inner tuning runs, desirability2 then fails to evaluate it in every fold. Reproduced by the reviewer.
2. [O] Censored models: `select_best_desirability()` ranks one row per candidate per evaluation time and returns `.eval_time` with the pick. tune's selectors use the first evaluation time. Read from source, not run.
3. [O] Through `rlang::as_label()`, `print()` and the "Selected by" line shorten a long goal. `target(rsq, low = 0.1, target = 0.5, high = 0.9, scale_low = 2, scale_high = 3)` printed as `target(...)`, reproduced here. AC1 says `print()` shows the terms.
4. [O] The entry check reads only a goal's first argument, so a metric named in a later argument fails in each fold, as in finding 1.
5. [O][S] The empty-selection error hint names `tune::select_by_one_std_err()` for every rule. `slice_max()` drops an all-NA desirability, which reaches this message under the new rule.
6. [O] Daemons are checked for desirability2 but not for the 0.2.0 floor, and no end-to-end parallel test runs the rule.
7. [S] `attach_daemon_pkgs()`'s default `pkgs` does not pass the rule to `needed_pkgs()`. Its one caller passes `pkgs`, so no path reaches the default today.
8. [S] For this rule, the absent-package refusal runs before the named-dots check, the reverse of the other rules' order.
9. [O] NEWS omits class `nestedtune_selection_rule_terms` and the refusal of `limit`. The help sentence that desirability2 checks each goal at build overstates the shape check.
