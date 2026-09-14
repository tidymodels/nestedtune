# M095: The summary note, plot subtitles and tuner help name the number to report for the deployed model

- **Status:** in-progress
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

- [ ] AC1: Over `R/`, `vignettes/`, `README.Rmd` and `man-roxygen/`, `grep -rnE 'not a model you can deploy|reported for (the procedure|it)([^a-z]|$)'` prints no line. The grep reads single lines, so the claim covers phrasing that sits on one line. The note `summary()` prints, where the phrase is split across lines, is AC2's. Evidence: the command and its empty output.
- [ ] AC2: The note `summary()` prints for a `nested_results` and for a `nested_results_set` says that the estimate describes the tune-and-fit procedure. It also says that, for a procedure chosen before seeing the estimate, the estimate is the number to report for the model `nested_final_fit()` builds. The set's note also says that each workflow's estimate goes with the fit built with that workflow's `id`. A test in `tests/testthat/test-nested-results-print.R` matches each of these facts on each path that carries it. Evidence: both printed notes quoted, and the test names. (RB tripwire: ip-touching)
- [ ] AC3: The last line of the `autoplot(type = "performance")` subtitle for a `nested_results` and for a `nested_results_set` is fixed text of at most 68 characters. It says that the estimate describes the procedure and is the number to report for the final fit. Each of the two `subtitle = paste0(...)` calls in `R/nested-results-plot.R` holds as many `\n` as it did at the plan commit. A test in `tests/testthat/test-nested-results-plot.R` matches both facts on each path. Evidence: the two calls quoted with the last line's character count, and the test names.
- [ ] AC4: The Description of `?nested_tune_bayes`, `?nested_tune_race` and `?nested_tune_sim_anneal` says that the estimate describes the procedure and is the number to report for the model `nested_final_fit()` builds, as `?nested_tune_grid` does. Evidence: the sentences quoted from each rendered `man/*.Rd` file.
- [ ] AC5: The message `print()` and `summary()` show for a `nested_final_fit` says that for a fit built from a workflow set, the number to report is that workflow's rows of `collect_metrics()` on the set. The sweep is `grep -nE 'number to report|results object' R/nested-final-fit*.R`. Each roxygen sentence in those files that contains a line the sweep prints, and that names where the number to report is found, says the same. The claim covers the sentences that grep locates. A test in `tests/testthat/test-nested-final-fit-print.R` prints a fit built from a set and a fit built from a single workflow. It matches that wording on both. Evidence: the grep output with each located sentence classified, the qualifying sentences quoted, and the test name.
- [ ] AC6: In `NEWS.md`, the bullet on `nested_final_fit()` and the bullet on `summary()` of a `nested_final_fit` (lines 435-440 and 262-266 at the plan commit) name the nested estimate as the number to report for the final fit. `tr '\n' ' ' < NEWS.md | grep -cE 'no +performance +(number|estimate)'` prints 0. Evidence: both bullets quoted and the command's output.
- [ ] AC7: `devtools::test()` is clean, each command `Rscript benchmarks/sweep-prose.R --list-gating` prints exits 0, `devtools::document()` leaves no diff, `devtools::check()` reports 0 errors, 0 warnings and 0 notes, and `git diff <plan commit> -- cairn/DESIGN.md` is empty. Evidence: each command's result.

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
- [ ] T6: Run AC1's grep, AC6's command, every gating sweep, `air format --check` on touched R files, `devtools::document()`, `devtools::test()`, `devtools::check()` and the DESIGN.md diff. Record each result in the work log.

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

## Decisions

## Review
