# M109: Selecting each fold's candidate by desirability over several metrics

- **Status:** review
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

**Out:** The rule under `nested_tune_race_anova()`, `nested_tune_race_win_loss()` and `nested_tune_sim_anneal()`, which refuse it at entry here. Their support goes to a candidate row added with this plan.

## Acceptance criteria

- [ ] AC1: `selection_rule("desirability", ...)` takes desirability2 terms such as `maximize()` and `minimize()` as `...`. The procedure records the terms, and `print()` shows them. `nested_tune_grid()` and `nested_tune_bayes()` each refuse at entry a term that names neither a metric in the run's metric set nor a tuned parameter. With no `metrics`, the check uses the default set tune uses for the model's mode. The test names that error by class.
- [ ] AC2: On a fixture with two metrics, each fold's `.selected` has the parameter values and `.config` that `desirability2::select_best_desirability()` gives with the same terms. The reference applies it to that fold's inner tuning run. That run comes from `reference_nested_loop()` for the grid and `reference_nested_bayes_loop()` for the Bayesian path, each run with the default rule. The test covers `nested_tune_grid()` and `nested_tune_bayes()`.
- [ ] AC3: `nested_final_fit()` on such a result selects what `select_best_desirability()` selects on the run `extract_tune_results()` returns, tested.
- [ ] AC4: Each of the two racing tuners and `nested_tune_sim_anneal()` refuses the rule at entry with an error the test names by class.
- [ ] AC5: If desirability2 is not installed, three calls refuse with an error the test names by class. The first is `selection_rule("desirability", ...)`. The second is `nested_tune_grid()` given a rule built while the package was installed. The third is `nested_final_fit()` on a result that recorded the rule.
- [ ] AC6: A D-entry records desirability2 joining Suggests, and a D-entry supersedes D-056's rule clause and, for this rule, its clause that orderings name only tuned parameters. `NEWS.md` describes the rule, and `selection_rule()`'s help documents it. `devtools::check()` gives 0 errors, 0 warnings, and no note absent from the check of `main` at the branch point.

## Coverage

- AC1 → T1, T2
- AC2 → T3
- AC3 → T3
- AC4 → T2
- AC5 → T4
- AC6 → T1, T5

## Tasks

- [x] T1: Install desirability2. Read its `NAMESPACE`, `select_best_desirability()`'s arguments and return columns, and whether a term can name a tuned parameter (LESSONS, claims about another package). Write the two D-entries, then add desirability2 to Suggests.
- [x] T2: Extend `selection_rule()` (`R/selection-rule.R:76`) with the rule. Capture the terms as expressions, as the orderings are captured. Add the entry check against the run's metric set and tuned parameters, and add the three tuners' refusal.
- [x] T3: Apply the rule where the recorded rule selects today, for the folds and the final fit. Write the AC2 and AC3 oracle tests, comparing parameter columns and `.config` only.
- [x] T4: Add the absent-package refusals in the pattern `check_tuner_installed()` uses (D-044), and test them with desirability2 masked.
- [x] T5: Write the help and `NEWS.md` text, then run `devtools::document()`, the prose sweeps from the verify slot, and `devtools::check()`.

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

## Decisions

## Review
