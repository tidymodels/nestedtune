# M145: The other four guides read like the tidymodels.org articles

- **Status:** in-progress
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

- [ ] AC1: For each of the four pages, `Rscript benchmarks/doc-profile.R` reports at most 70% of the page's prose words at this milestone's branch point.
- [ ] AC2: On each of the four pages, the mean words per prose paragraph are at most the largest mean among the comparator copies M142 fetched, as `doc-profile.R` reports.
- [ ] AC3: On each of the four pages, `doc-profile.R` counts at most 2 coined terms in the prose.
- [ ] AC4: On the four pages, `doc-profile.R` counts no sentence that opens with "You" or "Your". `grep -n 'error = TRUE' vignettes/estimate.Rmd vignettes/tuners.Rmd vignettes/results.Rmd vignettes/articles/parallel.Rmd` prints nothing.
- [ ] AC5: In `estimate.Rmd`, at least one sentence says what the nested estimate describes and what a user reports for the deployed model, and why (IP3). Review quotes it with its line. The page keeps a reference list for each source it cites.
- [ ] AC6: The verify slot is clean. `devtools::test()` passes, and `devtools::check()` gives 0 errors and 0 warnings with the vignettes built. Every gating prose sweep prints clean, and `pkgdown::check_pkgdown()` passes.

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
- [ ] T4: Rewrite `results.Rmd` as one narrative. Drop the column tour, the failed-fold run, the dplyr class rules and the `event_level` note.
- [ ] T5: Rewrite `parallel.Rmd` as a short how-to. Cut the seeding detail to one sentence and a link to `?nested_tune_grid`.
- [ ] T6: Run the verify slot, the gating sweeps and `pkgdown::check_pkgdown()`. Record the head figures and add a NEWS bullet. At review, one fresh reader reads the four pages beside the tidymodels.org articles. The gate triages every entry (D-061).

## Work log

- 2026-10-09: created by /milestone-plan with M142, M143 and M144. M142's work log holds the collision sweep, the criteria audit and the gate's answers.
- 2026-10-09: inputs from M142's review reader. No guide says where a held-out test set (`initial_split()` and `last_fit()`) fits around nested resampling. No guide says how to choose v for each loop. Both belong in `estimate.Rmd`, under this milestone's T2.
- 2026-10-09: plan gate chose no optimism demonstration over a site-only simulation article, because M082 deleted such a page and one random draw can fail to show the gap; falsified by a user or maintainer asking to see the flat score's optimism shown.
- 2026-10-10: input from M144 T2. `?collect_metrics` no longer cites Bengio and Grandvalet (2004) or Gauran, Ombao and Yu (2025) on why the fold scores give no valid standard error, and points to `vignette("estimate")`. That vignette's standard error section cites neither. T2 decides whether they belong there.
- 2026-10-10: implement started on branch `m145-tune-style-guides`, cut from `f1446754`.
- 2026-10-10: T1 done. At `f1446754`, `doc-profile.R` reads estimate 1,392 prose words, tuners 1,350, results 1,395 and parallel 510; the caps are 974, 945, 976 and 357, a paragraph mean of 37.5 and 2 coined terms. Figures are in `references/tune-docs-comparison.md`.
- 2026-10-10: T2 done. `estimate.Rmd` reads 952 prose words, 27 paragraphs (mean 35.3), 0 coined, 0 "You" openers; the gating sweeps print clean. It gains a test-set section (`initial_split()`, `training()`, `testing()`, as `last_fit()` does) and a fold-count section citing Arlot and Celisse (2010). Decided: Bengio and Grandvalet (2004) joins the standard error section, and Gauran, Ombao and Yu (2025) stays out, because its result holds for ridge and LASSO designs only.
- 2026-10-10: T3 done. `tuners.Rmd` reads 533 prose words, 17 paragraphs (mean 31.4), 0 coined, 0 "You" openers, and knits with no error. The `error = TRUE` chunk, the `.iter` and `n` explanations, the knitted prose chunks and the set's `summary()`, `agreement()` and parameters plot are gone. A probe showed that `nested_tune_sim_anneal()` finalizes `mtry` itself and `nested_tune_bayes()` fails every fold without a range, so the page names `tune_bayes()` alone for that rule.
