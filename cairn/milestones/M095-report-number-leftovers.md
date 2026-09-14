# M095: The summary note, plot subtitles and tuner help name the number to report for the deployed model

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP3
- **Resolves:** —
- **Surface tier:** user-facing — a print note, two plot subtitles, help pages, a print message and NEWS
- **Branch/PR:** m095-report-number-leftovers

## Goal

Every text M091 left saying the nested estimate is "not a model you can deploy" or is "reported for the procedure" names it as the number to report for the deployed model instead.

## Scope

**In:** `print_procedure_note()` in `R/nested-results-print.R`, shown by `summary()` on a `nested_results` and on a `nested_results_set`. The two `autoplot(type = "performance")` subtitles in `R/nested-results-plot.R`. The Description of the bayes, race and sim-anneal help pages. `final_fit_estimate_msg` and the roxygen sentences in `R/nested-final-fit*.R` that say where the number to report is found. One static text then also covers a fit built from a workflow set. The two `NEWS.md` bullets that say the final fit has no performance number, and one new bullet. The tests and snapshots these texts reach.

**Out:** IP3's principle text in `cairn/DESIGN.md` (unchanged, AC7 checks). Recording the workflow id on a `nested_final_fit` so its print names the workflow (declined at the plan gate, work log). The plain-prose pass over the other NEWS bullets (the `[low]` NEWS candidate row). The wider #91 rewrite (its candidate row). The vignettes, which M091 already aligned.

## Acceptance criteria

- [x] AC1: Over `R/`, `vignettes/`, `README.Rmd` and `man-roxygen/`, `grep -rnE 'not a model you can deploy|reported for (the procedure|it)([^a-z]|$)'` prints no line. The grep reads single lines, so the claim covers phrasing that sits on one line. The note `summary()` prints, where the phrase is split across lines, is AC2's. Evidence: the command and its empty output.
- [x] AC2: The note `summary()` prints for a `nested_results` and for a `nested_results_set` says that the estimate describes the tune-and-fit procedure. It also says that, for a procedure chosen before seeing the estimate, the estimate is the number to report for the model `nested_final_fit()` builds. The set's note also says that each workflow's estimate goes with the fit built with that workflow's `id`. A test in `tests/testthat/test-nested-results-print.R` matches each of these facts on each path that carries it. Evidence: both printed notes quoted, and the test names. (RB tripwire: ip-touching)
- [x] AC3: The last line of the `autoplot(type = "performance")` subtitle for a `nested_results` and for a `nested_results_set` is fixed text of at most 68 characters. It says that the estimate describes the procedure and is the number to report for the final fit. Each of the two `subtitle = paste0(...)` calls in `R/nested-results-plot.R` holds as many `\n` as it did at the plan commit. A test in `tests/testthat/test-nested-results-plot.R` matches both facts on each path. Evidence: the two calls quoted with the last line's character count, and the test names.
- [x] AC4: The Description of `?nested_tune_bayes`, `?nested_tune_race` and `?nested_tune_sim_anneal` says that the estimate describes the procedure and is the number to report for the model `nested_final_fit()` builds, as `?nested_tune_grid` does. Evidence: the sentences quoted from each rendered `man/*.Rd` file.
- [x] AC5: The message `print()` and `summary()` show for a `nested_final_fit` says that for a fit built from a workflow set, the number to report is that workflow's rows of `collect_metrics()` on the set. The sweep is `grep -nE 'number to report|results object' R/nested-final-fit*.R`. Each roxygen sentence in those files that contains a line the sweep prints, and that names where the number to report is found, says the same. The claim covers the sentences that grep locates. A test in `tests/testthat/test-nested-final-fit-print.R` prints a fit built from a set and a fit built from a single workflow. It matches that wording on both. Evidence: the grep output with each located sentence classified, the qualifying sentences quoted, and the test name.
- [x] AC6: In `NEWS.md`, the bullet on `nested_final_fit()` and the bullet on `summary()` of a `nested_final_fit` (lines 435-440 and 262-266 at the plan commit) name the nested estimate as the number to report for the final fit. `tr '\n' ' ' < NEWS.md | grep -cE 'no +performance +(number|estimate)'` prints 0. Evidence: both bullets quoted and the command's output.
- [x] AC7: `devtools::test()` is clean, each command `Rscript benchmarks/sweep-prose.R --list-gating` prints exits 0, `devtools::document()` leaves no diff, `devtools::check()` reports 0 errors, 0 warnings and 0 notes, and `git diff <plan commit> -- cairn/DESIGN.md` is empty. Evidence: each command's result.

## Coverage

- AC1 → T1, T2, T3
- AC2 → T1
- AC3 → T2
- AC4 → T3
- AC5 → T4
- AC6 → T5
- AC7 → T6

## Tasks

- [x] T1: `print_procedure_note()` at `R/nested-results-print.R:292-300` takes whether it prints under a set (callers at `:185` and `:244`) and states AC2's facts. Update the test at `tests/testthat/test-nested-results-print.R:424-439`, add the set path, and re-accept `_snaps/nested-results-print.md` after reading each changed note. `Rscript benchmarks/sweep-prose.R --plain` clean.
- [x] T2: Subtitles at `R/nested-results-plot.R:286-290` and `:628`. Update `tests/testthat/test-nested-results-plot.R:445` and `:722`. Render and view each changed vdiffr snapshot (`performance-folds-agree`, `set-performance-three-workflows`, `set-performance-both-shortfall-sentences`) before accepting it (LESSONS, M08).
- [x] T3: Descriptions at `R/nested-tune-bayes.R:14-17`, `R/nested-tune-race.R:17-19` and `R/nested-tune-sim-anneal.R:14-16`, with `R/nested-tune-grid.R:13-18` as the model. `devtools::document()`, then `--roxygen --plain` clean.
- [x] T4: `final_fit_estimate_msg` at `R/nested-final-fit-print.R:13-16`, and the sentences AC5's grep locates (at planning: `R/nested-final-fit.R:24-25` and `:146`, `R/nested-final-fit-print.R:25-26` and `:106-108`, `R/nested-final-fit-predict.R:61`). Update `tests/testthat/test-nested-final-fit-print.R:21` and `:161`, add a print of a fit built from a set, re-accept `_snaps/nested-final-fit-print.md`, `devtools::document()`.
- [x] T5: `NEWS.md`: reword the bullets at 262-266 and 435-440, and add one bullet at the top for the changed note, subtitles, help and final-fit message.
- [x] T6: Run AC1's grep, AC6's command, every gating sweep, `air format --check` on touched R files, `devtools::document()`, `devtools::test()`, `devtools::check()` and the DESIGN.md diff. Record each result in the work log.

## Work log

- 2026-09-14: created by /milestone-plan, promoting the M91 leftover-text candidate row.
- 2026-09-14: criteria audit (full mode) returned 12 findings on the first draft: a line-bound grep missing the split print-note phrase, the 68-character subtitle budget, AC5's grep as a line proxy, the static set wording, the unstated "chosen before seeing" condition, the set note's several workflows, and wording nits. The clear ones were fixed. The condition and the set wording went to the gate.
- 2026-09-14: criteria re-audit (full mode) of the gate-changed wording returned 5 findings: the note function has no set argument (T1), AC3's bound read the literal and not the rendered line (now bounds the last line), AC5's sentence reference, AC6's grep missing a phrase split across lines (now joins lines), and snapshot re-acceptance (T1, T2, T4). All fixed.
- 2026-09-14: plan gate chose one static set-fit wording over recording the workflow id on the fit object, because the id changes the object's shape for one sentence; falsified by a user misreading which workflow's rows to report.
- 2026-09-14: plan gate chose putting the "chosen before seeing the estimate" condition in both summary notes over the set note alone or nowhere, because the help already carries it and a subtitle has no room; falsified by a user reporting a single run's estimate after comparing several runs by hand.
- 2026-09-14: plan gate chose fixing the two contradicting NEWS bullets now over leaving them for the release consolidation, because they contradict the help today; falsified by the release walk rewriting them anyway.
- 2026-09-14: plan gate chose mechanical checks over a fresh-reader report, because about eight sentences change and M091 already took a report on the framing; falsified by a reader misreading the new note or subtitles.
- 2026-09-14: implement started on branch m095-report-number-leftovers. The question gate took the drafted summary notes and the set sentence second in the final-fit message. It took the subtitle line "It describes the procedure and is the final fit's number to report." (67 characters).
- 2026-09-14: T1 done. `print_procedure_note(set)` prints the single-run and set notes, and two tests match their facts. Seven snapshot notes were re-accepted after reading each. Print tests: 233 passed. The `--plain` sweep is clean.
- 2026-09-14: T2 done. Both subtitles end with the gate's 67-character line, and both tests check the last line's two facts and its length. The three vdiffr snapshots each changed one text line and were rendered and viewed before acceptance. Plot tests: 277 passed.
- 2026-09-14: T3 done. The bayes, race and sim-anneal Descriptions now say the estimate describes the procedure and is the number to report for the model `nested_final_fit()` builds. `document()` also regrouped the tune and vctrs `importFrom` lines in `NAMESPACE`, and this commit carries that rewrite, as the NAMESPACE drift candidate row asks. The `--roxygen --plain` and `--plain` sweeps are clean.
- 2026-09-14: T4 done. `final_fit_estimate_msg` gained the set sentence second. Five roxygen sentences that name where the number is found now carry the set case: nested-final-fit.R Description and "What to report", print Description, summary Description, and predict's residuals section. The other sweep lines are code comments, a heading, or sentences that do not name where. A new test prints and summarizes a set-built fit and a workflow-built fit. The hand-agreed print constant and 4 snapshot messages were updated. Final-fit tests: 770 passed. Both sweeps are clean.
- 2026-09-14: T5 done. The `summary()` and `nested_final_fit()` bullets in NEWS.md name the nested estimate as the number to report, and a new top bullet covers the note, subtitles, help and final-fit message. AC6's joined-line grep prints 0.
- 2026-09-14: T6 found the `--roxygen` sweep failing on four T4 sentences over 30 words. Each was shortened and kept as one sentence carrying the set case. All six gating sweeps now exit 0.
- 2026-09-14: claim audit: 22 claims read, 0 corrected — NEWS.md, R/nested-final-fit.R, R/nested-final-fit-print.R, R/nested-final-fit-predict.R, R/nested-tune-bayes.R, R/nested-tune-race.R, R/nested-tune-sim-anneal.R, R/nested-results-print.R, R/nested-results-plot.R, three test files. The reader noted that the set subtitle carries no "chosen before seeing" limit. The plan gate accepted that, because a subtitle has no room.
- 2026-09-14: T6 done. AC1's grep prints nothing, and it matched at the plan commit. AC6's command prints 0, and it printed 1 at the plan commit. Six gating sweeps exit 0 and `air format --check` is clean. `devtools::document()` leaves no diff, and the DESIGN.md diff is empty. `devtools::test()`: 10116 passed, 0 failed. `devtools::check()`: 0 errors, 0 warnings, 0 notes. Status set to review.
- 2026-09-14: review in progress. AC1-AC6 evidence recorded and ticked. The full suite, `devtools::check()` and three fresh reviewers are still running.

## Decisions

## Review

Review run 2026-09-14 on `m095-report-number-leftovers`, which already contains `origin/main` (no merge needed). No PR exists yet.

- AC1 evidence: `grep -rnE 'not a model you can deploy|reported for (the procedure|it)([^a-z]|$)' R/ vignettes/ README.Rmd man-roxygen/` prints nothing (exit 1). The same pattern at the plan commit `ad303dc` matched 5 lines (plot.R:289 and :628, and the bayes, race and sim-anneal Descriptions), so the grep can fire.
- AC2 evidence: `print_procedure_note()` prints, for a `nested_results`: "A nested estimate describes the tune-and-fit procedure. For a procedure chosen before seeing this estimate, it is the number to report for the model `nested_final_fit()` builds." For a `nested_results_set` (`set = TRUE`, the call at `print.summary.nested_results_set`): "Each nested estimate describes its workflow's tune-and-fit procedure. For a workflow chosen before seeing these estimates, its estimate is the number to report for the model `nested_final_fit()` builds with that workflow's `id`." The single-run test "summarizing names the estimate as the number to report for the final fit" (5 expectations) and the set test "summarizing a set names each workflow's estimate as the number to report for its fit" (4 expectations) both pass. Each matches the procedure fact, the chosen-before-seeing condition and the number-to-report fact. The set test also matches the `id` fact. `test-nested-results-print.R`: 222 passed, 0 failed, 2 snapshot tests skipped locally.
- AC3 evidence: `R/nested-results-plot.R:286` is `paste0(design_line(x), " The line marks the nested estimate.\nIt describes the procedure ", "and is the final fit's number to report.")`. `:623` is `paste0(set_design_line(x), " Each line marks a workflow's nested estimate.", set_shortfall_line(x), set_short_average_line(x, summaries), "\nIt describes the procedure and is the final fit's number to report.")`. Each call holds one `\n`, as it did at `ad303dc`. The last line is 67 characters on both paths. The tests "the performance view says the estimate is not a model's score" and "AC2: the set's performance view puts the workflows on x inside one panel per metric" pass. Each matches "describes the procedure" and "final fit's number to report" on the last line and bounds it at 68 characters. `test-nested-results-plot.R`: 270 passed, 0 failed, 2 skipped.
- AC4 evidence, read from the `\description{}` blocks of the rendered `man/*.Rd` files. `nested_tune_bayes.Rd`: "The estimate describes the whole search-and-fit procedure rather than any one model. The model to deploy comes from `nested_final_fit()`, which runs the recorded search once more on all the data, and the estimate is the number to report for that model." `nested_tune_race.Rd`: "The estimate describes the race-and-fit procedure as a whole. The model to deploy comes from `nested_final_fit()`, which races the same grid once more on all the data, and the estimate is the number to report for that model." `nested_tune_sim_anneal.Rd`: "The estimate describes the annealing-and-fit procedure as a whole. The model to deploy comes from `nested_final_fit()`, which runs the recorded search once more on all the data, and the estimate is the number to report for that model." The model, `nested_tune_grid.Rd`, ends "...and the estimate is the number to report for that model."
- AC5 evidence: `final_fit_estimate_msg` reads "Report the nested estimate from `collect_metrics()` on the results object this fit was built from. For a fit built from a workflow set, that is this workflow's rows of `collect_metrics()` on the set. It describes the procedure that produced this model, and it is the number to report for this model." The sweep `grep -nE 'number to report|results object' R/nested-final-fit*.R` prints 20 lines. Classified:
  - Roxygen sentences that name where the number is found, each carrying the set case: print.R:26-28 (print Description), print.R:108-111 (summary `estimate` component), predict.R:61-63 (residuals section), final-fit.R:24-27 (Description), final-fit.R:148-150 ("What to report").
  - Not naming where: print.R:23 ("which number to report"), print.R:31, predict.R:64 and final-fit.R:152 (sentences pointing to the reason or stating the fact), final-fit.R:154 (tuning-run metrics are not a number to report), final-fit.R:135 (refusal condition).
  - Not roxygen prose: print.R:11 and :184 and final-fit.R:439 (code comments), print.R:14 (the message constant, quoted above), final-fit.R:70 (section heading), final-fit.R:253 (example code comment).
  - The test "printing a fit built from a set and one built from a workflow names the set's rows on both" passes 12 expectations. It prints and summarizes a fit from `nested_final_fit(wset_results("nested_tune_grid"), id = "tuned")` and a single-workflow fit, and matches the set-rows wording on each. `test-nested-final-fit-print.R`: 177 passed, 0 failed, 3 skipped.
- AC6 evidence: the `summary()` bullet now reads "...and the values selection chose. Where a number would be, it names the nested estimate as the number to report for this model." The `nested_final_fit()` bullet now reads "...and returns it as a separate object. The nested estimate is the number to report for that model." `tr '\n' ' ' < NEWS.md | grep -cE 'no +performance +(number|estimate)'` prints 0. It printed 1 at `ad303dc`.
- AC7 evidence: `devtools::test()`: 10116 passed, 0 failed, 0 errors, 0 skipped. Each of the six commands `--list-gating` prints exits 0. `devtools::document()` leaves no diff. `devtools::check()`: 0 errors, 0 warnings, 0 notes. `git diff ad303dc -- cairn/DESIGN.md` is empty.
- Consistency gate: `cairn_validate.py` exits 0, with 18 references-staleness advisories that predate this milestone. `pkgdown::check_pkgdown()` finds no problems. README.Rmd and README.md are untouched. NEWS.md carries a top bullet for the change. No new top-level files. `air format --check` on the touched R files is clean. No principle text changed, so `cairn_impact.py` does not apply.
- Reviewers: [O] diff-bug, [S] blame-history and [S] prior-review ran on fresh context. The blame-history and prior-review lenses report no findings. The prior-review lens found M091's review named this follow-up, and found one human GitHub thread, on an unrelated file.
- [O] findings, ranked, verified where noted. Dispositions are set at the merge gate.
  - O1 (verified): the final-fit message and `?nested_final_fit` (lines 24-27, 148-150) tell a set-built fit's owner to report that workflow's rows, with no "chosen before seeing the estimates" condition. The summary note, `?collect_metrics.nested_results` and `vignettes/tuners.Rmd:439` carry it.
  - O2: the set subtitle's last line carries no condition, and "It" and "the final fit" have no single referent when several workflows are drawn.
  - O3: `R/nested-final-fit.R:148-149` joins the results-object case and the set case with "and", which reads as "report both". The sibling sentences use "or".
  - O4 (verified): print.R:26 and :108 and predict.R:61 changed "the results object the fit was built from" to "the fit's results object", but the fit stores no results object.
  - O5: one static message mentions workflow sets on every fit, and a set-built fit does not name its workflow.
  - O6: the new final-fit print test cannot tell a set-built fit from a workflow-built one, because the message is a constant.
  - O7: the plot test is still named "the performance view says the estimate is not a model's score".
  - O8: long or unwrapped lines at print.R:16 (116 characters), final-fit.R:150 (93), final-fit.R:25-27 (early wrap), NEWS.md:8 (92) and test-nested-final-fit-print.R:9 (107).
  - O9: the multi-line `importFrom` form in NAMESPACE may depend on the local roxygen2 8.1.0 build.
  - O10: the subtitles shorten "tune-and-fit procedure" to "the procedure".
  - O11: the bayes Description says "rather than any one model" and then "for that model". `?nested_tune_grid` has the same pattern.
  - O12: the new NEWS bullet is not reflowed.
