# M133: Refuse inner ids that tune misreads, at entry and at the final fit

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP3, IP4
- **Resolves:** —
- **Surface tier:** user-facing — it changes which designs the exported functions refuse
- **Branch/PR:** m133-inner-id-rules

## Goal

The entry check and the final fit refuse an inner design that tune misreads by its ids or cannot use (D-102).

## Scope

**In:** Two inner-loop rules with class `nestedtune_bad_design`. The first refuses a split whose `id` is missing. The second refuses a design in which two splits carry the same id values. Both apply at `check_nested()`, at `nested_resamples()` from `inside`, and to the design that `nested_final_fit()` rebuilds. That rebuilt design also gets the design refusals of D-096, D-097 and D-099, in the entry check's order. The README, three help sites, a NEWS bullet and the DESIGN convention bullet state the rules. This absorbs findings F6 and F7 of M132's review.

**Out:**
- A split whose analysis and assessment sets share a row, which is F8 widened. M134 holds it.
- A missing value in `id2` to `id9` stays accepted, a plan gate choice. tune reads such a design correctly, and D-102 names the falsifier. No row.
- The race rule stays off `nested_resamples()`, which does not know the tuner (D-101). No row.
- The final fit's rebuilt design gets no empty-design, split-class or frame check. `eval_inside_spec()` already refuses a result that is not an rset, and the frame rules do not apply to a design on the whole data. No row, because no probe reached a failure there.

## Acceptance criteria

- [ ] AC1: Take an inner design that holds a split whose `id` value is NA, as `is.na()` reads it. `check_nested()` refuses the design before any fold runs. As it builds the design from `inside`, `nested_resamples()` refuses it. Both use class `nestedtune_bad_design`. At both sites the rule runs after the refusal of `loo_cv()`, `apparent()` and `permutations()` designs, and before the "Apparent" rules that the site applies. The message names the offending elements of `inner_resamples`, or the outer fold. It says that tune leaves a split with a missing id out of its estimates. `tests/testthat/test-design-support.R` asserts the class and that reason through `nested_tune_grid()` and through `nested_resamples()`. Its inner `vfold_cv()` designs have one id set to NA, once as a character and once as a factor. One more case, through `nested_tune_grid()`, sets the NA in the second of three outer folds only. It asserts that the message names element 2. Two passing controls run through `nested_tune_grid()`. One is an inner `vfold_cv(repeats = 2)` design with one `id2` value set to NA. The other is an inner `vfold_cv()` design whose factor id has NA as a level through `addNA()`, which tune keeps in its estimates.
- [ ] AC2: Take an inner design in which two splits carry the same values in every id column, read with `as.character()`. The id columns are `id`, and `id2` to `id9` where present. `check_nested()` and `nested_resamples()` refuse the design with class `nestedtune_bad_design`, at the place AC1 names. A split whose `id` is missing is reported by the AC1 rule alone. Two missing values in `id2` to `id9` compare equal, as `vctrs::vec_duplicate_detect()` treats them. The message names the offending elements or the outer fold. It says that tune miscounts the resamples of a design whose ids repeat. Tests assert the class and that reason through `nested_tune_grid()` and through `nested_resamples()`. One inner `vfold_cv()` design has one `id` repeated. One inner `vfold_cv(repeats = 2)` design has one pair of `id` and `id2` values repeated. In a third, the first two `id2` values of a `vfold_cv(repeats = 2)` design are set to NA. A passing control runs an inner `vfold_cv(repeats = 2)` design, whose `id` values repeat across `id2`, through `nested_tune_grid()`.
- [ ] AC3: `nested_final_fit()` rebuilds an inner design on the whole data. Before it tunes, it applies five groups of rules to that design in this order, each with class `nestedtune_bad_design`. The first refuses `loo_cv()`, `apparent()` and `permutations()` designs by rset class or split class (D-096, D-097). The second is the rule on an apparent split beside bootstrap or permutation splits (D-099). The third and fourth are the AC1 and AC2 rules. The fifth is the two "Apparent" rules it applies today (D-101). No message of these rules at the final fit holds the words "outer fold". The entry-check messages are unchanged. `tests/testthat/test-nested-final-fit-checks.R` replaces the `inside` of a result and asserts the class and the reason for ten calls. Under a grid record, the first five calls are `rsample::loo_cv()`, `rsample::apparent()` and `rsample::permutations(permute = y, times = 3, apparent = TRUE)`. They also include a `manual_rset()` of `loo_cv()` splits, and a `manual_rset()` of the splits of `permutations(apparent = TRUE)`. Next is a `bootstraps(apparent = TRUE)` design whose apparent split carries another id. Two `vfold_cv()` designs follow, one with an id set to NA and one with an id repeated. The existing `vfold_apparent()` case is a `manual_rset()` of `vfold_cv()` splits and an apparent split under the id "Apparent". It now gets the `apparent()` refusal, and its test changes to assert that. Under a `nested_tune_race_anova()` record, `permutations(permute = y, times = 3, apparent = TRUE)` gets the permutations refusal, not the race refusal. The `apparent()` and `permutations()` cases assert that the message does not hold "Give the split another id".
- [ ] AC4: The README paragraph on refused designs, the design block of `?nested_resamples` and the "Nested designs" section of `?nested_tune_grid` state the AC1 and AC2 rules. The "What is refused" section of `?nested_final_fit` states that the rebuilt design is refused for a refused design, a missing id and a repeated id. One NEWS bullet states the two rules and the checks the final fit gains.
- [ ] AC5: `devtools::test()` gives 0 failures. `devtools::check()` gives 0 errors, 0 warnings and 0 notes. `Rscript benchmarks/sweep-prose.R --plain` and `--roxygen --plain` are clean.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T3, T4
- AC4 → T5
- AC5 → T5

## Tasks

- [ ] T1: Write the AC1 and AC2 tests first, in `tests/testthat/test-design-support.R`. After the AC1 amendment, the `addNA()` case moves from the refusals to the controls, and also runs through `nested_resamples()` and the final fit. One more AC2 case gives two splits the NA level. Set the ids with `$<-`, since `rebuilt()` (line 326) keeps the original ids. Use `entry_refusal()` (line 163) for the `nested_tune_grid()` cases. For `nested_resamples()`, give `inside` a call to a local builder. The refusals fail on the current code, and the two controls pass.
- [ ] T2: Add the two rules in `R/checks.R`. Read the id columns by `is_id_name()` and as characters, as `check_label_values()` does, so an `addNA()` level reads as NA. Name every offending element in one message. Call the rules from `check_nested()` before `check_inner_apparent_ids()` (line 385). Call them from `inner_resamples_from_split()` before the "Apparent" check (`R/nested-resamples.R:273`). Give cli the reasons as values (M83 lesson).
- [ ] T3: Write the AC3 tests first, beside the "Apparent" block of `tests/testthat/test-nested-final-fit-checks.R` (line 429). The racer case skips where `tuner_ready()` is false (M101 lesson).
- [ ] T4: Extend `check_final_inner()` (`R/checks.R:608`). Run `inner_refused_design()` with a reason about the rebuilt design, with the `renamed_apparent()` hint. Then run the AC1 and AC2 rules, then the two "Apparent" rules. Update the comment on `misread_apparent_rows()` (line 531), which says that the final fit gets no refused-design check.
- [ ] T5: Update the documentation and run the checks. Change the Refused paragraph in `README.Rmd` and run `devtools::build_readme()`. Change `R/nested-resamples.R:40` and the "Nested designs" section at `R/nested-tune-grid.R:102`. Add the final fit's checks to its "What is refused" section (`R/nested-final-fit.R:98`). Add the NEWS bullet, and update the DESIGN.md convention bullet on invalid designs. Run `devtools::document()`, both prose sweeps, `devtools::test()` and `devtools::check()`.

## Work log

- 2026-09-30: created by /milestone-plan, from the "M132's review leftovers" candidate row (F6, F7), with the repeated-id rule added at the plan gate.
- 2026-09-30: criteria audit (full mode, fresh Opus reader) returned 13 findings over the M133 and M134 drafts. Fixed: rule order at each site, named reasons, and a case in one fold of three. The final fit gained a race record, a renamed bootstrap apparent split and split-class permutations. The repeated-id gap went to the gate, which added AC2.
- 2026-09-30: plan gate chose refusing a missing value in `id` alone over every id column, as D-047 does for the outer folds. tune drops a split only by its `id`: an NA `id2` gave n = 6 of 6 in `fit_resamples()` and `tune_race_anova()`. Falsified by a tune or finetune release that reads `id2` to filter or pair resamples.
- 2026-09-30: plan gate chose refusing a repeated inner id tuple now over a candidate row. tune miscounts such a design: 3 folds with one id repeated gave n = 5. Falsified by a tune release that keys its estimate on the split rather than the id.
- 2026-09-30: re-audit of the gate-changed criteria (full mode, same Opus reader) returned 7 findings, all fixed. AC1 names the site's own "Apparent" rules and runs its element-2 case through `nested_tune_grid()`. AC2 compares NA `id2` values as equal, with a case. AC3 splits the NA and repeat calls, adds the `vfold_apparent()` change and keeps the entry messages unchanged.
- 2026-09-30: implement started on branch m133-inner-id-rules. No question gate, since the plan left no choice open.
- 2026-09-30: checkpoint. T1 to T4 code and tests written; the design-support and final-fit-checks files pass. The new entry tests failed first by reaching the fold sentinel. T5 docs edited but not yet rendered. Full suite still running, so no task is ticked yet.
- 2026-09-30: full suite at `92687bf5` plus T1 to T4 gave 0 failures, 0 errors and 0 skips. Both prose sweeps clean. Rendered the help pages and README.
- 2026-09-30: claim audit: 31 claims read, 5 corrected — R/checks.R, tests/testthat/test-nested-final-fit-checks.R
- 2026-09-30: the claim audit found that tune keeps a split whose factor id has NA as a level (n = 3 of 3). So AC1's reason was false there. The user chose at a mini gate to stop refusing it, and D-105 corrects D-102.
- 2026-09-30: amendment: AC1 reads `id` with `is.na()`, and the `addNA()` case moves from the refusals to a passing control. T1 gains that control through `nested_resamples()` and the final fit. It also gains an AC2 case with two NA levels.
- 2026-09-30: re-audit: AC1 (full) returned four findings, none changing the text. D-102's reading needed a correction (D-105). Two NA levels reach the repeated-id rule, which is right, and gained a case. More entry points were added to T1. The tune clause in the control stays as its reason.

## Decisions

## Review
