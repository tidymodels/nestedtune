# How the help pages and guides compare with tune's (M142)

**Provenance.** Ingested 2026-10-09 by M142's plan from two read-only comparisons. The first read the installed tune 2.1.0 and finetune 1.3.0 help (`tools::Rd_db()`) against this package's `man/` at `b2bbb494`. The second read the guides and README at `b2bbb494` against tune's `vignettes/tune.Rmd`, `vignettes/acquisition_functions.Rmd` and `vignettes/extras/optimizations.Rmd`, the tune and finetune READMEs, and the tidymodels.org pages `start/tuning`, `learn/work/nested-resampling`, `learn/work/tune-svm` and `learn/work/bayes-opt`, read from GitHub's default branches.
Pagination: —.
Extraction: a 2026-10-09 snapshot, measured with throwaway scripts whose definitions differ from `benchmarks/doc-profile.R`, and M142 T2 replaces the figures below with the script's — observed 2026-10-09.

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
