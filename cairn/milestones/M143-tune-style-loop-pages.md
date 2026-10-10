# M143: The other loop pages, the final fit and the design page read like tune's

- **Status:** planned
- **Priority:** normal
- **Depends on:** M142
- **Driving RR:** —
- **Principles touched:** IP3, GP1
- **Resolves:** #91 partial
- **Surface tier:** user-facing — the help pages for the functions that run the loop
- **Branch/PR:** —

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

- [ ] T1: Run `doc-profile.R` at the branch point and record the seven pages' figures in the comparison note.
- [ ] T2: Rewrite the bayes, race and sim-anneal pages, with the race and sim-anneal templates they alone use. Keep each tuner's own arguments and its Differences list. Point to `?nested_tune_grid` for what the loop pages share.
- [ ] T3: Rewrite `nested_fit_resamples` and `nested_final_fit`. On the final-fit page, keep what it fits, what it returns, and the IP3 sentence. Move the refusal list out, because the error messages carry it.
- [ ] T4: Rewrite `nested_workflow_map` and `nested_resamples`. On `nested_resamples`, keep the D-110 reasons and the D-085 claims in short lists.
- [ ] T5: Rewrite the text-matching lines of any test that reads the old text, and keep the slot rules of `test-control-slots.R`.
- [ ] T6: Run the verify slot and the gating sweeps, record the head figures, and add a NEWS bullet. At review, one fresh reader reads the seven pages beside their tune and finetune counterparts. The gate triages every entry (D-061).

## Work log

- 2026-10-09: created by /milestone-plan with M142, M144 and M145. M142's work log holds the collision sweep, the criteria audit and the gate's answers.
