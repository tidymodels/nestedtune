# M143: The other loop pages, the final fit and the design page read like tune's

- **Status:** in-progress
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

- [ ] AC1: On each of the seven rendered pages, the Description is at most 40 words, as `Rscript benchmarks/doc-profile.R` reports at the merge head.
- [ ] AC2: `Rscript benchmarks/doc-profile.R --tune` reports these at the merge head. Each of the seven pages has at most 1.1 times the prose of tune's `?tune_bayes`. The seven together have at most half their prose at this milestone's branch point.
- [ ] AC3: `grep -n -E 'nestedtune_[a-z_]+|sample\.int|serializ|dplyr_reconstruct|vec_restore|orchestrator|sibling' man/<page>.Rd` prints nothing for each of the seven pages at the merge head.
- [ ] AC4: `tests/testthat/test-control-slots.R` passes at the merge head, with its slot rules unchanged from the branch point. It reads the bayes, race, sim-anneal and fit-resamples pages. It takes the slot names from tune's `formals()`. It requires each slot under exactly one of the seven Differences headings (GP1).
- [ ] AC5: On `?nested_final_fit`, at least one sentence says that the nested estimate describes the procedure and not this model, and what to report for this model (IP3). Review quotes it with its line.
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
- [ ] T5: Rewrite the text-matching lines of any test that reads the old text, and keep the slot rules of `test-control-slots.R`.
- [ ] T6: Run the verify slot and the gating sweeps, record the head figures, and add a NEWS bullet. At review, one fresh reader reads the seven pages beside their tune and finetune counterparts. The gate triages every entry (D-061).

## Work log

- 2026-10-09: created by /milestone-plan with M142, M144 and M145. M142's work log holds the collision sweep, the criteria audit and the gate's answers.
- 2026-10-09: inputs from M142's review. `orchestrator` is still used on these pages, and the grid page no longer defines it (AC3 removes it). The bayes, race and sim-anneal Descriptions still open with "gives you an honest score" and carry an IP3 sentence the grid page moved to Details. `man-roxygen/differences-passed-shared.R` says the passed-through slots "behave as the grid page describes", and the grid page now gives them one short paragraph.
- 2026-10-10: implement started on `m143-tune-style-loop-pages`, cut from `5ca197ee`. T1: the branch-point figures are in the comparison note. The seven pages hold 10,343 prose words, so AC2's total cap is 5,171, and the per-page cap is 1,714 (1.1 times `tune_bayes`'s 1,559).
- 2026-10-10: T2: bayes 746, race 765, sim-anneal 698 prose words. The three pages drop the inherited grid sections (designs, finalizing, evaluation times, weights, reproducibility) and point to `?nested_tune_grid` instead. `details-param-info` is deleted, and the six templates only these pages use are cut to one or two sentences. The anchors `test-control-slots.R` and `test-help-structure.R` read are kept, so both pass unedited.
- 2026-10-10: the full suite run after T2 passed except one `test-sweep-prose.R` span hit. It came from the map page, which T4 was editing during the run, and T4 fixed it.
- 2026-10-10: T3: fit-resamples 507 and final-fit 498 prose words. The final-fit page drops its refusal list, the workflow-identity rules and the two citations. Its `inside` re-evaluation note moves into Details. It keeps what it fits, what it returns, the IP3 "What to report" section and the hand recipe. `test-tuner-registry.R` and `test-eval-time.R` (full suite) pass unedited.
- 2026-10-10: T4: workflow-map 383 and nested_resamples 726 prose words. The seven pages total 4,338, under AC2's 5,171. The map page folds its six sections into five short Details paragraphs. `?nested_resamples` keeps the D-110 reasons as one list and the per-function time-series claims (D-085, D-115) as three items, under the two section titles the README cites.
