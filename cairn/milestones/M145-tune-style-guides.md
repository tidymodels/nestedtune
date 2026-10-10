# M145: The other four guides read like the tidymodels.org articles

- **Status:** review
- **Priority:** normal
- **Depends on:** M142, M144
- **Driving RR:** —
- **Principles touched:** IP3, GP5
- **Resolves:** #91 partial
- **Surface tier:** user-facing — the guides on the package website and in the vignettes
- **Branch/PR:** m145-tune-style-guides

## Goal

Rewrite `vignettes/estimate.Rmd`, `vignettes/tuners.Rmd`, `vignettes/results.Rmd` and `vignettes/articles/parallel.Rmd` to the guide target M142 sets.

## Scope

**In:** the four pages, `_pkgdown.yml` where a heading or page title changes, and the figures in `cairn/references/tune-docs-comparison.md`.

**Out:**

- `nested-cv.Rmd` and the README are M142's.
- Column-by-column reference material leaves `results.Rmd`. The help pages that M144 rewrites hold it, so this milestone adds no help text.
- A runnable demonstration of the flat score's optimism (nested against flat against a large-sample truth) is not planned. M082 deleted the simulation article that did this.

**Target:** the M142 guide target. Each page opens by saying what it is for, in a sentence about the method and not about the reader. It narrates a worked example with "we" in short paragraphs. Edge cases, the failed-fold run and the dplyr class rules leave the guides, because the help pages hold them.

- `estimate.Rmd` keeps what the nested estimate means and what to report (IP3). It also keeps the cited background in a shorter form, with its reference list (GP5).
- `tuners.Rmd` becomes one short section for each tuner, each a small example on the shared setup.
- `results.Rmd` becomes one narrative: run, read the estimate, read the selections, and plot.
- `parallel.Rmd` becomes a short how-to.

## Acceptance criteria

- [x] AC1: For each of the four pages, `Rscript benchmarks/doc-profile.R` reports at most 70% of the page's prose words at this milestone's branch point.
- [x] AC2: On each of the four pages, the mean words per prose paragraph are at most the largest mean among the comparator copies M142 fetched, as `doc-profile.R` reports.
- [x] AC3: On each of the four pages, `doc-profile.R` counts at most 2 coined terms in the prose.
- [x] AC4: On the four pages, `doc-profile.R` counts no sentence that opens with "You" or "Your". `grep -n 'error = TRUE' vignettes/estimate.Rmd vignettes/tuners.Rmd vignettes/results.Rmd vignettes/articles/parallel.Rmd` prints nothing.
- [x] AC5: In `estimate.Rmd`, at least one sentence says what the nested estimate describes and what a user reports for the deployed model, and why (IP3). Review quotes it with its line. The page keeps a reference list for each source it cites.
- [x] AC6: The verify slot is clean. `devtools::test()` passes, and `devtools::check()` gives 0 errors and 0 warnings with the vignettes built. Every gating prose sweep prints clean, and `pkgdown::check_pkgdown()` passes.

## Coverage

- AC1 → T2, T3, T4, T5
- AC2 → T2, T3, T4, T5
- AC3 → T2, T3, T4, T5
- AC4 → T2, T3, T4, T5
- AC5 → T2
- AC6 → T6

## Tasks

- [x] T1: Run `doc-profile.R` at the branch point and record the four pages' figures in the comparison note.
- [x] T2: Rewrite `estimate.Rmd`. Keep the meaning of the estimate, what to report, and the background with its citations, all shorter. Drop the statements about what the package does not offer, unless a reader needs one to act.
- [x] T3: Rewrite `tuners.Rmd` as one short section for each tuner and one for the workflow set. Drop the column meanings such as `.iter` and `n`, which the help pages hold.
- [x] T4: Rewrite `results.Rmd` as one narrative. Drop the column tour, the failed-fold run, the dplyr class rules and the `event_level` note.
- [x] T5: Rewrite `parallel.Rmd` as a short how-to. Cut the seeding detail to one sentence and a link to `?nested_tune_grid`.
- [x] T6: Run the verify slot, the gating sweeps and `pkgdown::check_pkgdown()`. Record the head figures and add a NEWS bullet. At review, one fresh reader reads the four pages beside the tidymodels.org articles. The gate triages every entry (D-061).

## Work log

- 2026-10-09: created by /milestone-plan with M142, M143 and M144. M142's work log holds the collision sweep, the criteria audit and the gate's answers.
- 2026-10-09: inputs from M142's review reader. No guide says where a held-out test set (`initial_split()` and `last_fit()`) fits around nested resampling. No guide says how to choose v for each loop. Both belong in `estimate.Rmd`, under this milestone's T2.
- 2026-10-09: plan gate chose no optimism demonstration over a site-only simulation article, because M082 deleted such a page and one random draw can fail to show the gap; falsified by a user or maintainer asking to see the flat score's optimism shown.
- 2026-10-10: input from M144 T2. `?collect_metrics` no longer cites Bengio and Grandvalet (2004) or Gauran, Ombao and Yu (2025) on why the fold scores give no valid standard error, and points to `vignette("estimate")`. That vignette's standard error section cites neither. T2 decides whether they belong there.
- 2026-10-10: implement started on branch `m145-tune-style-guides`, cut from `f1446754`.
- 2026-10-10: T1 done. At `f1446754`, `doc-profile.R` reads estimate 1,392 prose words, tuners 1,350, results 1,395 and parallel 510; the caps are 974, 945, 976 and 357, a paragraph mean of 37.5 and 2 coined terms. Figures are in `references/tune-docs-comparison.md`.
- 2026-10-10: T2 done. `estimate.Rmd` reads 952 prose words, 27 paragraphs (mean 35.3), 0 coined, 0 "You" openers; the gating sweeps print clean. It gains a test-set section (`initial_split()`, `training()`, `testing()`, as `last_fit()` does) and a fold-count section citing Arlot and Celisse (2010). Decided: Bengio and Grandvalet (2004) joins the standard error section, and Gauran, Ombao and Yu (2025) stays out, because its result holds for ridge and LASSO designs only.
- 2026-10-10: T3 done. `tuners.Rmd` reads 533 prose words, 17 paragraphs (mean 31.4), 0 coined, 0 "You" openers, and knits with no error. The `error = TRUE` chunk, the `.iter` and `n` explanations, the knitted prose chunks and the set's `summary()`, `agreement()` and parameters plot are gone. A probe showed that `nested_tune_sim_anneal()` finalizes `mtry` itself and `nested_tune_bayes()` fails every fold without a range, so the page names `tune_bayes()` alone for that rule.
- 2026-10-10: T4 done. `results.Rmd` reads 321 prose words, 14 paragraphs (mean 22.9), 0 coined, 0 "You" openers, and knits with no error. It runs once and reads the estimate, the selections, the inner scores, the predictions (a new predicted-against-observed plot with `coord_obs_pred()`) and both `autoplot()` views. The column tour, the failed-fold run, the dplyr rules and the `event_level` note are gone, and the last paragraph points to `?nested_tune_grid`, which holds the failed-fold and dplyr text.
- 2026-10-10: T5 done. `articles/parallel.Rmd` reads 183 prose words, 7 paragraphs (mean 26.1), 0 coined, 0 "You" openers, and knits with no error, the serial and parallel results identical. The seeding text is one sentence that points to `?nested_tune_grid`, and the `.tuning_seed` identity and the `status()` calls are gone.
- 2026-10-10: T6 in progress, not checked off. The NEWS bullet and the head figures in `references/tune-docs-comparison.md` are written. The six gating sweeps print clean, `pkgdown::check_pkgdown()` finds no problems, and the `error = TRUE` grep prints nothing. `devtools::test()` and the claim audit are running, and `devtools::check()` is still owed.
- 2026-10-10: the claim audit's reader found 4 wrong claims and 2 loose ones, all fixed: the Bayle et al. coin-flip step (the paper shows a shrinking loss-difference variance), the Vabalas framing, the Arlot and Celisse "estimate" reading (their goal is model selection), and the parallel cost sentence (a probe timed the pool no slower). The print wording and the seed sentence are tightened too. Its re-read is pending.
- 2026-10-10: claim audit: 96 claims read, 6 corrected — vignettes/estimate.Rmd, vignettes/tuners.Rmd, vignettes/articles/parallel.Rmd. The same reader re-read the 6 and found that all hold.
- 2026-10-10: T6 done. `devtools::test()` passes with no failures, and `devtools::check()` gives 0 errors, 0 warnings and 0 notes with the vignettes rebuilt. No `.R` file and no roxygen changed, so `air` and `document()` are not owed. The fresh reader beside the tidymodels.org articles runs at review. Status set to review.

## Review

Head `8dac9123`, branch point `f1446754`. `doc-profile.R` read the branch-point pages from `git show f1446754:<path>` copies.

- AC1: prose words at head against the branch point: estimate 959 / 1,392 (68.9%), tuners 535 / 1,350 (39.6%), results 322 / 1,395 (23.1%), parallel 178 / 510 (34.9%). All at most 70%. Pass.
- AC2: paragraph means at head: 34.2, 31.5, 23.0 and 25.4. The largest comparator mean is 37.5 (`org-start-tuning.qmd`), read in the same run. Pass.
- AC3: coined terms at head: 0 on each of the four pages. Pass.
- AC4: `doc-profile.R` counts 0 "You" openers on each page, and the `error = TRUE` grep prints nothing (exit 1). Pass.
- AC5: `vignettes/estimate.Rmd:40`: "The estimate describes the procedure, not one fitted model, and we report it for the deployed model because `nested_final_fit()` runs that procedure on all the data." The page cites eight sources in prose (Arlot and Celisse, Bayle et al., Bengio and Grandvalet, Luo and Barber, Tibshirani and Tibshirani, Vabalas et al., Varma and Simon, Wilimitis and Walsh), and each has an entry at lines 130 to 156. Pass.

spawned: diff-bug, blame-history, prior-review, and the plan's fresh reader beside the tidymodels.org articles (slug `reader`).

No finding shows a criterion failing, and none is a defect in what a page does for its user that the fixes below leave open, so no return. The AC1 to AC5 lines above were read before the fixes, and the figures after them are re-read with AC6.

- diff-bug #1: `?nested_final_fit` says `vignette("estimate")` gives the sizes from two studies, but the rewrite cut Wilimitis and Walsh's sizes. Fix now: the 1 to 2% AUROC and 5 to 9% AUPR sizes are back.
- diff-bug #2: the test-set section gives a second number after the page says there is none, and does not say which to report. Fix now: the section says to report the test score for the fitted model and the nested estimate for the procedure.
- diff-bug #3: the standard error reads as valid, and the "ships no inference" line is gone. Fix now: the page says `std_err` treats the folds as independent though they share rows, so it tends to understate the uncertainty, and that the package builds no interval from it.
- diff-bug #4: the Bayle et al. fold-disagreement step does not follow from a shrinking variance alone. Fix now: the sentence says the comparison of two similar candidates is unstable.
- diff-bug #5: the Varma and Simon null-data result does not show a training-size effect. Reject, false: the paper attributes the 4.2 points to training-set size (`references/varma2006.md:45`). The page now names that as the authors' reading.
- diff-bug #6: `?nested_tune_grid` says a data-dependent range is finalized on each fold, which is false for `nested_tune_bayes()`. Follow-up: extends the `?nested_tune_grid` argument-text candidate row.
- diff-bug #7: `README.Rmd:155` still says the results guide covers every column. Follow-up: a new candidate row, since the README is outside this milestone.
- diff-bug #8: the DESIGN Known issues entry on what to report without nesting names this pass as its trigger, and nothing handles it. Fix now: the entry is re-read and kept, with its trigger narrowed to a user asking.
- diff-bug #9: the fold-count section gives no inner-loop advice. Fix now: it says the 5-to-10 advice is for model selection, which is the inner loop's job.
- diff-bug #10: AC6 is unticked while T6 is ticked. Reject, false: review ticks each criterion against its evidence, and AC6's evidence is recorded below.
- diff-bug #11: the NEWS bullet's "other four guides" is unclear, and the parallel page is an article. Fix now: the bullet names the four pages.
- diff-bug #12: "the tuning fits number the product" is hard to parse. Fix now: replaced by a pointer to the fit count in `vignette("nested-cv")`.
- diff-bug #13: the Tibshirani paragraph lost its learner caveat. Fix now: it names nearest shrunken centroids and gives the SVM and tree figures.
- diff-bug #14: four lines wrap unevenly. Reject, style. The fix edits reflowed most of them.
- blame-history #1: the same dangling sizes pointer as diff-bug #1. Fix now, as there.
- blame-history #2: the results page's first mention of the deployed model no longer names the number to report (M091). Fix now: the sentence says the estimate is still the number to report for that model, and why.
- blame-history #3: the one-split-against-spread contrast M091's gate chose is gone. Fix now: the test-set section opens with it.
- blame-history #4: `?nested_tune_grid` does not say that overwriting a column the run wrote sheds the class (D-031). Follow-up: extends the same `?nested_tune_grid` candidate row, since this milestone adds no help text.
- blame-history #5: no guide says a fold can complete and still carry notes. Fix now: the results page names `collect_notes()` for every fold, one that completed included.
- blame-history #6: the GP5 and IP3 statements that the package offers no test, no inference and no ranking are gone. Fix now: the estimate page says each, in one clause.
- blame-history #7: the parallel article lost its pointer to the parallel section of `?nested_tune_grid`. Fix now: one sentence points there.
- blame-history #8: "every row of the data is predicted once" is false for repeated designs. Fix now: the sentence says "On this design".
- blame-history #9: the Bayesian consequence for counting selections is dropped. Reject, planned change: `?print.nested_results` holds it.
- blame-history #10: the feature-selection leak sentence is thinner. Fix now: the page says a step run before the call is not repeated and no result shows it.
- blame-history #11: the `eval_time` note and the `extract_procedure()` mention are gone. Reject, planned change: argument and column reference left the guides, and `?nested_tune_grid` and `?extract_procedure` hold both.
- blame-history #12: the Known issues trigger fired (as diff-bug #8, fixed), and the "larger training set" scope fact is gone. Reject the second, planned change: "the error on this data set" keeps the point.
- prior-review #1: the Tibshirani cell lost its learner caveat and remedy (M082). Fix now, as diff-bug #13, with the remedy kept.
- prior-review #2: `candidate` and `procedure` are unglossed on the results page (M084). Fix now: both are glossed at first use, and `--terms` shows it.
- prior-review #3: the number to report is missing at the deployed-model mention (M091). Fix now, as blame-history #2.
- prior-review #4: the parallel pointer is gone. Fix now, as blame-history #7.
- prior-review #5: an older NEWS bullet still says the results guide reads every column. Fix now: that clause now says it reads the results object.
- prior-review #6: the fit-count arithmetic is restated off `nested-cv.Rmd`. Fix now on the estimate page. Reject the tuners sentence, planned change: it gives the race's comparison point, computed inline.
- prior-review #7: the failed-fold claim on the results page has no executed chunk. Reject, false: M062 and M082 verified it against `R/` and the tests, and `?nested_tune_grid` covers failed folds.
- prior-review #8: two timing claims on the parallel page are not executed. Reject, planned change: M063 chose no executed timings, and the claim audit's probe timed both.
- prior-review #9: the `std_err` formula ignores weighted designs (M101). Fix now: the page defines it as the standard error of the mean, with no unweighted formula.
- reader, estimate.Rmd. Fixed: the "(tune, select, fit)" wording now matches `nested-cv.Rmd`. "Fresh data" now reads "predicts new data", and the "k-fold test error" term is gone. The test-set section says which number to report. Luo and Barber are tied to "offers no such test". The cost grammar, the inner-loop advice, "null data", the unclear "it" in the Wilimitis sentence, and a reason for not adjusting are fixed. The interval question gets "builds no interval". "Loss difference" is gone, the Tibshirani units are one scale with the learner named, and "tall data" now reads "many rows". Rejected, planned change: the page runs no code and has no Introduction (the target's theory page), "how much data" and test-set code (no source, and the functions are named), defining "stable" and a remedy for picking the best (word cap, GP5), and the reference list (AC5). Rejected, false: "not a score of the parameter values" does not pull against "the number to report", which IP3 makes agree.
- reader, tuners.Rmd. Fixed: the opening says when a race or a proposing search fits (no retitle, because the README links the title). The twice-read opening sentence, the Gaussian process, the race's few drops, the reason for the fixed settings, the fold-by-fold reading, the two "baseline" names (now `linear`), `step_normalize()` before `step_pca()`, and the `option_add()` override are fixed. Rejected, planned change: the inner set size and `finalize()`, the print's "!" line, `burn_in`, and the unrun chosen-in-advance fit, all held by help pages. Rejected, style: comparing against `bayes` rather than the grid run.
- reader, results.Rmd. Rejected, planned change: whether `save_pred` saves inner predictions, the unexplained columns, reading the output's agreement split, the runner-up and inner-against-outer gap, the `.config` labels, and "which class", all reference material the help pages hold. Rejected, style: "how much of the design ran".
- reader, parallel.Rmd. Fixed: how many daemons, and what reaches them, through the new pointer to the parallel section. Rejected, planned change: why one daemon does not count, inner parallelism and tune's own support (help pages), no timing shown (M063), and checking only two columns. Rejected, style: "which call". Rejected, planned change: `nested-cv.Rmd` not linking these pages (M142's page).
- reader, all pages. Rejected, planned change: no Introduction, session info or data description (`nested-cv.Rmd` sets up the example), and the terse voice (the M142 target). Rejected, planned change: the per-page gloss of "candidates" (M084's rule).

Every fix-now item above landed in `29293479`.

Re-read at `29293479`, after the fixes. AC1: estimate 973 / 1,392 (69.9%), tuners 589 / 1,350 (43.6%), results 358 / 1,395 (25.7%), parallel 199 / 510 (39.0%). AC2: means 36.0, 34.6, 25.6 and 28.4, against 37.5. AC3: 0 coined on each page. AC4: 0 "You" openers, and the `error = TRUE` grep prints nothing. AC5: the sentence now sits at `vignettes/estimate.Rmd:37`, unchanged, and the eight entries at lines 126 to 152. All still pass.

- AC6: at `29293479`, `devtools::test()` finished with no failure or error, and `devtools::check()` gave 0 errors, 0 warnings and 0 notes with the vignettes rebuilt (14 min 40 s). The six gating sweeps from `--list-gating` print clean, and `pkgdown::check_pkgdown()` finds no problems. The verify slot owes no `air` or `document()` run (no `.R` or roxygen change), and `document()` left no diff. Pass.

Consistency gate: `cairn_validate.py` passes (18 references-staleness advisories, none new). The toolchain checks: `document()` gave no diff. The README is not touched, `check_pkgdown()` passes, and NEWS has this milestone's bullet. No new top-level file was added, and `check()` passes clean. The gating sweeps print clean. No DESIGN principle changed, so `cairn_impact.py` is not owed.
