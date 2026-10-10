# M143: The other loop pages, the final fit and the design page read like tune's

- **Status:** review
- **Priority:** normal
- **Depends on:** M142
- **Driving RR:** —
- **Principles touched:** IP3, GP1
- **Resolves:** #91 partial
- **Surface tier:** user-facing — the help pages for the functions that run the loop
- **Branch/PR:** m143-tune-style-loop-pages

## Goal

Rewrite seven help pages to the target M142 sets: `nested_tune_bayes`, `nested_tune_race`, `nested_tune_sim_anneal`, `nested_fit_resamples`, `nested_workflow_map`, `nested_final_fit` and `nested_resamples`.

## Scope

**In:** the roxygen of the seven pages in `R/` and any `man-roxygen/` template that only these pages use. Tests that read the text of these pages, rewritten to the new pages. The figures in `cairn/references/tune-docs-comparison.md`.

**Out:**

- `?nested_tune_grid` and the shared Differences templates are M142's.
- The reader pages go to M144, and the guides go to M145.
- The reasons for the README's `Refused` and `No` cells stay on `?nested_resamples` (D-110), in shorter form.
- The design claims D-085 puts on `?nested_resamples` stay, as a short list.

**Target:** the M142 target, read from `cairn/references/tune-docs-comparison.md`. Condition class names (`nestedtune_*`) leave these pages, because the condition carries its class and tune names none on its pages.

## Acceptance criteria

- [x] AC1: On each of the seven rendered pages, the Description is at most 40 words, as `Rscript benchmarks/doc-profile.R` reports at the merge head.
- [x] AC2: `Rscript benchmarks/doc-profile.R --tune` reports these at the merge head. Each of the seven pages has at most 1.1 times the prose of tune's `?tune_bayes`. The seven together have at most half their prose at this milestone's branch point.
- [x] AC3: `grep -n -E 'nestedtune_[a-z_]+|sample\.int|serializ|dplyr_reconstruct|vec_restore|orchestrator|sibling' man/<page>.Rd` prints nothing for each of the seven pages at the merge head.
- [x] AC4: `tests/testthat/test-control-slots.R` passes at the merge head, with its slot rules unchanged from the branch point. It reads the bayes, race, sim-anneal and fit-resamples pages. It takes the slot names from tune's `formals()`. It requires each slot under exactly one of the seven Differences headings (GP1).
- [x] AC5: On `?nested_final_fit`, at least one sentence says that the nested estimate describes the procedure and not this model, and what to report for this model (IP3). Review quotes it with its line.
- [ ] AC6: The verify slot is clean. `devtools::document()` leaves no diff. `devtools::test()` passes, and `devtools::check()` gives 0 errors and 0 warnings. Every gating prose sweep prints clean, and `air format --check .` is clean.

## Coverage

- AC1 → T2, T3, T4
- AC2 → T2, T3, T4
- AC3 → T2, T3, T4
- AC4 → T2, T5
- AC5 → T3
- AC6 → T5, T6

## Tasks

- [x] T1: Run `doc-profile.R` at the branch point and record the seven pages' figures in the comparison note.
- [x] T2: Rewrite the bayes, race and sim-anneal pages, with the race and sim-anneal templates they alone use. Keep each tuner's own arguments and its Differences list. Point to `?nested_tune_grid` for what the loop pages share.
- [x] T3: Rewrite `nested_fit_resamples` and `nested_final_fit`. On the final-fit page, keep what it fits, what it returns, and the IP3 sentence. Move the refusal list out, because the error messages carry it.
- [x] T4: Rewrite `nested_workflow_map` and `nested_resamples`. On `nested_resamples`, keep the D-110 reasons and the D-085 claims in short lists.
- [x] T5: Rewrite the text-matching lines of any test that reads the old text, and keep the slot rules of `test-control-slots.R`.
- [x] T6: Run the verify slot and the gating sweeps, record the head figures, and add a NEWS bullet. At review, one fresh reader reads the seven pages beside their tune and finetune counterparts. The gate triages every entry (D-061).

## Work log

- 2026-10-09: created by /milestone-plan with M142, M144 and M145. M142's work log holds the collision sweep, the criteria audit and the gate's answers.
- 2026-10-09: inputs from M142's review. `orchestrator` is still used on these pages, and the grid page no longer defines it (AC3 removes it). The bayes, race and sim-anneal Descriptions still open with "gives you an honest score" and carry an IP3 sentence the grid page moved to Details. `man-roxygen/differences-passed-shared.R` says the passed-through slots "behave as the grid page describes", and the grid page now gives them one short paragraph.
- 2026-10-10: implement started on `m143-tune-style-loop-pages`, cut from `5ca197ee`. T1: the branch-point figures are in the comparison note. The seven pages hold 10,343 prose words, so AC2's total cap is 5,171, and the per-page cap is 1,714 (1.1 times `tune_bayes`'s 1,559).
- 2026-10-10: T2: bayes 746, race 765, sim-anneal 698 prose words. The three pages drop the inherited grid sections (designs, finalizing, evaluation times, weights, reproducibility) and point to `?nested_tune_grid` instead. `details-param-info` is deleted, and the six templates only these pages use are cut to one or two sentences. The anchors `test-control-slots.R` and `test-help-structure.R` read are kept, so both pass unedited.
- 2026-10-10: the full suite run after T2 passed except one `test-sweep-prose.R` span hit. It came from the map page, which T4 was editing during the run, and T4 fixed it.
- 2026-10-10: T3: fit-resamples 507 and final-fit 498 prose words. The final-fit page drops its refusal list, the workflow-identity rules and the two citations. Its `inside` re-evaluation note moves into Details. It keeps what it fits, what it returns, the IP3 "What to report" section and the hand recipe. `test-tuner-registry.R` and `test-eval-time.R` (full suite) pass unedited.
- 2026-10-10: T4: workflow-map 383 and nested_resamples 726 prose words. The seven pages total 4,338, under AC2's 5,171. The map page folds its six sections into five short Details paragraphs. `?nested_resamples` keeps the D-110 reasons as one list and the per-function time-series claims (D-085, D-115) as three items, under the two section titles the README cites.
- 2026-10-10: T5: no test edit was needed. The rewritten pages keep every anchor `test-control-slots.R`, `test-help-structure.R`, `test-tuner-registry.R` and `test-eval-time.R` read, and no page, guide or error message points at a removed section.
- 2026-10-10: T6 in progress (checkpoint): the NEWS bullet is written and the head figures are in the comparison note. At `90ad5811`, `document()` leaves no diff, the six gating sweeps and `air format --check .` are clean, and the AC3 grep prints nothing on the seven pages. The full suite, `check()` and the claim audit are still running.
- 2026-10-10: the full suite passed at `49fa840d` with no failure. claim audit: 110 claims read, 6 corrected — R/nested-workflow-map.R, R/nested-fit-resamples.R, man-roxygen/differences-settable.R, R/nested-resamples.R, NEWS.md. All six claimed more than the code does: map warnings, map subsetting, the control classes, the `event_level` conflict rule, the memory test, and the NEWS pointer claim. The seven pages now total 4,427 prose words. The reader's one re-read and `check()` are pending.
- 2026-10-10: claim audit: 110 claims read, 6 corrected — R/nested-workflow-map.R, R/nested-fit-resamples.R, man-roxygen/differences-settable.R, R/nested-resamples.R, NEWS.md. The same reader re-read the six corrections once, and all six hold.
- 2026-10-10: T6 done at `689e48c0`. `devtools::check()` gives 0 errors, 0 warnings and 0 notes, and it ran the tests on the corrected tree. `document()` leaves no diff, and the six gating sweeps and `air` are clean. Status set to review. The fresh reader beside tune's pages is review's step.

## Review

Evidence read at `20dcd6d2` (2026-10-10). `main` and `origin/main` are both `5ca197ee`, the branch point, so no merge was needed.

- AC1: `Rscript benchmarks/doc-profile.R --tune` gives these Description word counts: bayes 29, race 32, sim-anneal 28, fit-resamples 31, workflow-map 21, final-fit 24, nested_resamples 35. All seven are at most 40.
- AC2: the same run gives prose of bayes 761, race 780, sim-anneal 728, fit-resamples 522, workflow-map 402, final-fit 498 and nested_resamples 736. `tune::tune_bayes` is 1,559, so the per-page cap is 1,714.9, and every page is under it. The seven total 4,427. The branch-point copies (`git show 5ca197ee:man/<page>.Rd`, read with `--man`) total 10,343, so the cap is 5,171.5, and the total is under it.
- AC3: the grep prints nothing on each of the seven `man/*.Rd` pages. A planted line holding `orchestrator` matches once, so the pattern can fail.
- AC4: `test-control-slots.R` passes (148 expectations, read at `689e48c0`, whose package tree `git diff --quiet` shows equal to HEAD outside `cairn/`). `git diff main -- tests/testthat/test-control-slots.R` is empty, so the slot rules are unchanged. The file reads the bayes, race, sim-anneal and fit-resamples pages, takes the slots from tune's `formals()` and requires each slot under exactly one of the seven headings.
- AC5: `R/nested-final-fit.R:63-65` (rendered at `man/nested_final_fit.Rd:62-64`) says: "The nested estimate describes the procedure that produced this model, not this model itself. Report [collect_metrics()] on `results` as the estimate for this model, because the model comes from the same procedure."

Re-read at `b3c54fec`, after the fixes below:

- AC1: Descriptions unchanged (29, 32, 28, 31, 21, 24, 35), all at most 40.
- AC2: prose is bayes 811, race 858, sim-anneal 760, fit-resamples 549, workflow-map 477, final-fit 629 and nested_resamples 742. Each is under 1,714.9, and the total of 4,826 is under 5,171.5.
- AC3: the grep still prints nothing on all seven pages.
- AC4: `git diff main -- tests/testthat/test-control-slots.R` is still empty. The file passes at `b3c54fec` (148 expectations), run after the fixes were rebuilt.
- AC5: the sentence now sits at `R/nested-final-fit.R:69-71` (`man/nested_final_fit.Rd:68-70`), worded as quoted above.

spawned: diff-bug, blame-history, prior-review, plus the plan's fresh reader (`reader`, beside the tune, finetune, workflowsets and rsample pages, D-061 triage). They reported 67 findings: 45 fixed on the branch, 19 rejected, 3 sent on.

- diff-bug #1: Bayes `seed` reason wrong — fix now
- diff-bug #2: final-fit "a workflow that differs is an error" claims more than the identity check — fix now
- diff-bug #3: "no other function" on the eight pairs leaves out `nested_resamples()` (D-113) — fix now
- diff-bug #4: "gives the same splits" drops "tested" (D-071) — fix now
- diff-bug #5: final-fit Details unconditional for a fit-resamples record, and `results` excludes it — fix now
- diff-bug #6: IP3 caveats lost (marginal over selection, same population) — fix now
- diff-bug #7: `x$tuning` names an undefined `x` — fix now
- diff-bug #8: Bayes "ten iterations" unconditional — fix now
- diff-bug #9: Bayes page no longer says the kept control drops `seed` — fix now
- diff-bug #10: `save_workflow` pointer to the final fit's `$tuning` dropped — fix now
- diff-bug #11: kept template reads unconditional and drops the column names — fix now
- diff-bug #12: finetune version note drops the declared-floor gap — fix now
- diff-bug #13: race page drops three facts — fix now for the failed-candidate note and the map's apparent-split check; the grid-column rule rejected, planned change (the error message carries it)
- diff-bug #14: map error leaves results unclear, and the unread `result` column — fix now
- diff-bug #15: fit-resamples Inert drops that packages are still required — fix now
- diff-bug #16: "the grid page" in plain text, no link — fix now
- diff-bug #17: grid page's finalizing rule versus Bayes — reject, false (the Bayes page states its own exception)
- diff-bug #18: `?extract_procedure` cites the wrong section title on two pages — follow-up, M144's work log (its T3 rewrites that page)
- blame-history #1: map subsetting sentences gone, and DESIGN Known issues points at a removed section — fix now (page sentences restored, DESIGN pointer corrected M143)
- blame-history #2: function-body identity gap D-067 relies on — fix now (same fix as diff-bug #2)
- blame-history #3: "What to report" drops the caveats and the source for "slightly pessimistic" — fix now (caveats back, `vignette("estimate")` pointer)
- blame-history #4: tuner pages say nothing about what to report — fix now (the pointer sentence names what the estimate describes)
- blame-history #5: "Not returned" false for the final fit — fix now
- blame-history #6: race apparent-split divergence from finetune undocumented (GP1, D-100) — fix now
- blame-history #7: lost pointer to what a seed cannot pin, and the sim-anneal `time_limit` caveat — fix now
- blame-history #8: "tested" dropped — fix now (same as diff-bug #4)
- blame-history #9: fit-resamples metric-mode error dropped — fix now
- blame-history #10: smaller drops (`.notes` notes, record fields, mirai detail) — reject, planned change (implementation detail leaves the pages; the race failed-candidate note came back under diff-bug #13)
- blame-history #11: orphan line at `R/nested-tune-grid.R:95` — reject, false (a wrapped line of one sentence)
- prior-review #1: map `metrics` lost the first-metric rule and the `?selection_rule` pointer (M142 diff-bug #2) — fix now
- prior-review #2: reproducibility and weights templates removed from four pages — reject, planned change (T2 points to `?nested_tune_grid`, which keeps both)
- prior-review #3: "optimistic" stated flat (M142 reader #8) — fix now
- prior-review #4: final-fit pointer to what a seed cannot pin — fix now (same as blame-history #7)
- prior-review #5: `parallel_over` sentence dropped — reject, no defect (the grid page states it, which settles M142's follow-up)
- prior-review #6: refused-plain template trimmed — reject, false (not a regression of M142 #14)
- prior-review #7: "candidates" unglossed — reject, style
- reader #1: no path to a final fit after a run on a model specification — fix now
- reader #2: Bayes does not say how to finalize — fix now
- reader #3: `option` precedence is the reverse of workflowsets' — fix now
- reader #4: after a map error, are results returned — fix now
- reader #5: `control` hidden in `...` — reject, recorded decision (D-042 keeps "no `control` formal")
- reader #6: seven-heading scheme is jargon — reject, planned change (GP1, AC4)
- reader #7: race "Refused: none" contradicts the `burn_in` rule — fix now (rule moved under Passed through)
- reader #8: parallel backend only on the grid page — reject, planned change
- reader #9: final-fit recipe's `data` undefined — fix now
- reader #10: five tuning lines read as one script — fix now
- reader #11: time-series section reads as a test matrix — reject, planned change (D-115 keeps the full claims)
- reader #12: "Differences from rsample" is mostly validation rules — reject, planned change (D-110)
- reader #13: map has no `seed` argument, unstated — fix now
- reader #14: `event_level` sentence hard to parse — fix now
- reader #15: inherited `metrics` text names desirability unexplained — follow-up, new candidate row
- reader #16: inherited `eval_time` text drops tune's purpose sentence — follow-up, same row
- reader #17: fit-resamples example builds unused tuned objects — fix now
- reader #18: race example builds an unused `folds` — fix now
- reader #19: map names "the three columns" before Value — fix now
- reader #20: `save_history` label does not fit — reject, false (nothing reaches the result)
- reader #21: finetune version note is a maintainer note — reject, false (it tells a user an older finetune can lack a slot)
- reader #22: fit-resamples seed detail and inert list — reject, planned change (AC4 needs the list)
- reader #23: the set condition in "What to report" is unclear — fix now
- reader #24: no example of a set final fit — reject, false (Details states the call)
- reader #25: memory test path and date — reject, planned change (the derived-figures rule pins a figure to its procedure)
- reader #26: "design" for the race grid — reject, false (it is the grid design, tune's own term)
- reader #27: missing words in the apparent-split sentence — fix now
- reader #28: `?nested_resamples` title leads with an implementation detail — fix now (title is "Build a nested resampling design")
- reader #29: "Default S3 method" in Usage — reject, style (roxygen output)
- reader #30: sim-anneal `iter = 0` stated twice — fix now (reason moved into the argument)
- reader #31: final-fit See Also omits `nested_workflow_map()` — fix now
