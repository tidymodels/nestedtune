# How the help pages and guides compare with tune's (M142)

**Provenance.** Ingested 2026-10-09 by M142's plan from two read-only comparisons. The first read the installed tune 2.1.0 and finetune 1.3.0 help (`tools::Rd_db()`) against this package's `man/` at `b2bbb494`. The second read the guides and README at `b2bbb494` against tune's `vignettes/tune.Rmd`, `vignettes/acquisition_functions.Rmd` and `vignettes/extras/optimizations.Rmd`, the tune and finetune READMEs, and the tidymodels.org pages `start/tuning`, `learn/work/nested-resampling`, `learn/work/tune-svm` and `learn/work/bayes-opt`, read from GitHub's default branches.
Pagination: —.
Extraction: a 2026-10-09 snapshot. The first section's figures came from throwaway scripts, and the `doc-profile.R` section's figures were read directly from the script on the pinned comparator copies — observed 2026-10-09.

**Scope.** This page records how far this package's documentation sits from tune's and tidymodels.org's in length, structure and voice. It also lists the patterns that make the gap. It is the target M142 to M145 read. It is not a style guide and not a source summary. It is a reference, not an authority: status lives in `ROADMAP.md`, decisions in `DECISIONS.md`, and architecture in `DESIGN.md`.

**Evidence snapshot.**

- This package's `man/`, `vignettes/` and `README.Rmd` at `b2bbb494` — observed 2026-10-09.
- tune 2.1.0 and finetune 1.3.0 help, as installed — observed 2026-10-09.
- The tune, finetune and tidymodels.org pages named above, at the default branch on GitHub — observed 2026-10-09.

## What the two sets of documentation are

Help pages. This package has about 34,400 prose words over 32 pages, a median of 487 a page. tune has 16,100 over 45 pages, a median of 129. The median Description is 74 words here and 17 in tune. 26 of 32 pages here carry an `@section`, against 8 of 45 in tune. Argument text is no longer the main gap (median 24 words here, 10 in tune, 20 in finetune). Mean sentence length is 18 words here and 14 in tune.

| Page pair | Prose words | Description words |
|---|---|---|
| `nested_tune_grid` / `tune_grid` | 4,943 / 1,564 | 157 / 33 |
| `nested_tune_bayes` / `tune_bayes` | 3,046 / 1,602 | 131 / 14 |
| `nested_fit_resamples` / `fit_resamples` | 2,358 / 1,024 | 143 / 39 |
| `nested_final_fit` / `last_fit` | 2,021 / 651 | 113 / 28 |
| `collect_selections` / `show_best` | 437 / 319 | 146 / 62 |

Guides. Length and code density already match tidymodels.org: the four larger guides run 1,350 to 1,400 prose words and 48 to 59 words a code chunk, against 1,137 to 1,279 and 41 to 60. The gaps are elsewhere. Paragraphs average 44 to 56 words here and 22 to 36 there. The coined terms (`record`, `refus*`, `orchestrator`, `sibling`, and `procedure`) run 13 to 31 per 1,000 words here and 0 to 11 there. Negations run 11 to 24 per 1,000 words here and 0.5 to 9 there. No page here uses "we", and the tidymodels.org pages use it 13 to 55 times per 1,000 words.

## Measured with `benchmarks/doc-profile.R`

The figures above came from throwaway scripts. The ones below come from `Rscript benchmarks/doc-profile.R --tune --pages <comparator copies> <pages>`, whose header defines every column, and they are the ones the M142 to M145 criteria read. The comparator copies sit on the gitignored shelf under `cairn/references/sources/tune-docs/`. They were fetched from tidymodels/tidymodels.org at `ed3cb150` and from tidymodels/tune at `d047fc3a`, on 2026-10-09.

At the M142 branch point (`54ac8f31`, 2026-10-09):

| Help page | prose | desc | args | arg_med | sections |
|---|---|---|---|---|---|
| `nested_tune_grid` | 4,960 | 159 | 10 | 37 | 12 |
| `tune::tune_grid` | 1,557 | 33 | 9 | 13 | 6 |
| `tune::tune_bayes` | 1,603 | 14 | 11 | 14 | 9 |

| Guide page | prose | paras | para_mean | coined | you |
|---|---|---|---|---|---|
| `nested-cv.Rmd` | 1,350 | 31 | 43.5 | 3 | 1 |
| `README.Rmd` | 534 | 10 | 53.4 | 6 | 1 |
| tidymodels.org `learn/work/nested-resampling` | 1,137 | 32 | 35.5 | 0 | 0 |
| tidymodels.org `start/tuning` | 1,238 | 33 | 37.5 | 0 | 3 |
| tidymodels.org `learn/work/tune-svm` | 634 | 24 | 26.4 | 0 | 0 |
| tidymodels.org `learn/work/bayes-opt` | 654 | 19 | 34.4 | 0 | 0 |
| tune `vignettes/tune.Rmd` | 971 | 42 | 23.1 | 0 | 0 |

At the M142 head (2026-10-09), the same script reads `nested_tune_grid` at 1,208 prose words with a 36-word Description (after the claim audit's fixes and the script's punctuation fix). It reads `nested-cv.Rmd` at 652 prose words in 24 paragraphs (mean 27.2, 0 coined), and `README.Rmd` at 397 prose words (mean 44.1, 2 coined). The shared templates also cut the sibling pages: `nested_tune_bayes` 1,528, `nested_tune_race` 1,641, `nested_tune_sim_anneal` 1,543 and `nested_fit_resamples` 1,282 (1,245 after the fixes).

At the M143 branch point (`5ca197ee`, 2026-10-10), the script reads the seven pages M143 rewrites, beside their comparators:

| Help page | prose | desc | sections | coined |
|---|---|---|---|---|
| `nested_tune_bayes` | 1,554 | 131 | 7 | 17 |
| `nested_tune_race` | 1,664 | 152 | 7 | 20 |
| `nested_tune_sim_anneal` | 1,567 | 128 | 7 | 18 |
| `nested_fit_resamples` | 1,298 | 143 | 7 | 22 |
| `nested_workflow_map` | 1,225 | 121 | 5 | 31 |
| `nested_final_fit` | 1,753 | 113 | 6 | 40 |
| `nested_resamples` | 1,282 | 81 | 3 | 23 |
| the seven together | 10,343 | | | |
| `tune::tune_bayes` | 1,559 | 14 | 9 | 0 |
| `finetune::tune_race_anova` | 628 | 62 | 0 | 0 |
| `finetune::tune_sim_anneal` | 865 | 30 | 0 | 0 |
| `tune::fit_resamples` | 983 | 39 | 5 | 0 |
| `tune::last_fit` | 620 | 28 | 3 | 0 |

At the M143 head (`90ad5811`, 2026-10-10), the same script reads the seven pages at: `nested_tune_bayes` 746 prose words (29-word Description), `nested_tune_race` 765 (32), `nested_tune_sim_anneal` 713 (28), `nested_fit_resamples` 507 (31), `nested_workflow_map` 383 (21), `nested_final_fit` 498 (24) and `nested_resamples` 726 (35). The seven total 4,338, against 10,343 at the branch point.

At the M144 branch point (`16fd160c`, 2026-10-10), the script reads the 24 pages M144 rewrites at 9,116 prose words together. Seventeen Descriptions are over 40 words, the largest `collect_predictions.nested_results` at 148. Beside their comparators:

| Help page | prose | desc | sections | coined |
|---|---|---|---|---|
| `agreement` | 316 | 93 | 2 | 1 |
| `augment.nested_results` | 668 | 55 | 3 | 10 |
| `autoplot.nested_results` | 402 | 100 | 2 | 7 |
| `collect_metrics.nested_results` | 727 | 57 | 3 | 4 |
| `collect_metrics.nested_results_set` | 496 | 124 | 2 | 6 |
| `collect_predictions.nested_results` | 861 | 148 | 3 | 8 |
| `collect_selections` | 437 | 146 | 3 | 8 |
| `compute_metrics.nested_results` | 466 | 43 | 2 | 10 |
| `extract_procedure` | 525 | 47 | 1 | 11 |
| `extract_scored_candidates` | 223 | 38 | 1 | 2 |
| `extract_tune_results` | 169 | 32 | 1 | 4 |
| `extract_workflow.nested_results_set` | 61 | 18 | 0 | 1 |
| `extract-nested_final_fit` | 205 | 33 | 0 | 2 |
| `nestedtune-package` | 170 | 56 | 0 | 1 |
| `predict.nested_final_fit` | 313 | 31 | 2 | 3 |
| `predict.nested_results` | 77 | 62 | 0 | 1 |
| `print.nested_final_fit` | 362 | 105 | 2 | 2 |
| `print.nested_results` | 206 | 38 | 1 | 1 |
| `print.nested_results_set` | 66 | 44 | 0 | 1 |
| `reexports` | 31 | 31 | 0 | 0 |
| `selection_rule` | 616 | 67 | 3 | 14 |
| `summary.nested_final_fit` | 508 | 145 | 2 | 4 |
| `summary.nested_results` | 468 | 80 | 2 | 6 |
| `summary.nested_results_set` | 743 | 48 | 5 | 8 |
| `tune::collect_predictions` (holds `collect_metrics`) | 587 | 8 | 1 | 0 |
| `tune::show_best` | 315 | 62 | 0 | 0 |
| `tune::autoplot.tune_results` | 417 | 4 | 0 | 0 |
| `tune::augment.tune_results` | 218 | 24 | 0 | 0 |
| `tune::compute_metrics` | 243 | 64 | 0 | 0 |

At the M144 implement head (`b906d8eb`, 2026-10-10), the same script reads the 24 pages at 4,008 prose words together, 44% of the branch point, with Descriptions of 15 to 35 words (corrected M144: an earlier line here gave 3,990 words and a 32-word largest Description, read before the last two edits). After the review's fixes (`b691fe58`), the 24 pages read 4,385 prose words, 48% of the branch point, with Descriptions of 15 to 37 words. No page has a `nestedtune_*` class name, `orchestrator` or `sibling`.

At the M145 branch point (`f1446754`, 2026-10-10), the script reads the four guides M145 rewrites. Its caps are 70% of these prose figures (974, 945, 976 and 357 words), a paragraph mean of 37.5, and 2 coined terms.

| Guide page | prose | paras | para_mean | coined | you |
|---|---|---|---|---|---|
| `estimate.Rmd` | 1,392 | 26 | 53.5 | 0 | 2 |
| `tuners.Rmd` | 1,350 | 24 | 56.2 | 6 | 1 |
| `results.Rmd` | 1,395 | 31 | 45.0 | 5 | 2 |
| `articles/parallel.Rmd` | 510 | 10 | 51.0 | 2 | 1 |

The largest comparator paragraph mean is 37.5 (`start/tuning`). Without `procedure`, the coined list finds few hits on the guides: 3 on `nested-cv.Rmd` and 6 on the README.

## Patterns found here and not in tune

Help pages:

1. The Description argues a thesis ("the number to report", "honest score") and walks the algorithm, where tune says what the function computes.
2. "Differences from calling tune directly" sections explain every control slot at length under seven headings. GP1 requires the divergences to be documented, and `test-control-slots.R` holds the classification, so the headings stay and the explanation shrinks.
3. Refusal lists and `nestedtune_*` condition class names, on 26 and 22 pages. tune names no condition class and mentions errors in one clause.
4. Implementation mechanics: seed arithmetic, mirai serialization, the preflight wait, vctrs and dplyr dispatch.
5. Literature arguments inside help text: the standard-error section on `collect_metrics`, Stone (1974) on the grid page, Varma and Simon on the final-fit page.
6. Test inventories, such as the list of time-series design pairs and how each is tested.
7. Pointers from one section or page to another in prose ("The section on X says"), where tune uses See Also.
8. Small mtcars examples of about 26 lines on every page, where tune uses modeldata sets in 35 to 76 lines.

Guides:

1. Every page opens with "You want" or "You have" and then a paragraph that lists what the page will do.
2. Slogans repeated across pages: "the number to report" on 7 sites and "the procedure run once more" on 6.
3. Terms glossed again on every page ("candidates, the settings to try").
4. The same setup code repeated on three pages, and a 25-line dependency guard on four.
5. Refusals shown as behavior, with `error = TRUE` chunks.
6. About 55 statements of what the package does not do.
7. Implementation detail in guide prose: the seeding story on four pages.
8. `estimate.Rmd` is an essay with six citations and no code. tidymodels.org's nested-resampling article gives the theory in three paragraphs and spends the rest on code.
9. `results.Rmd` tours the result's columns, failed folds and dplyr class rules, which are reference material.

## What tune does that this package does not

A one-sentence Description, then arguments that can be skimmed. Short Details tied to a choice the user makes. Examples on shipped data that show output. Links to articles from the help pages. A See Also that says how two functions differ for the user. A "we" voice in the articles, and few coined terms.
