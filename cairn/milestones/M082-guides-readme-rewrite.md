# M082: The guides, README and NEWS are written for someone running nested cross-validation, and the page that served the author is gone

- **Status:** in-progress
- **Priority:** high
- **Depends on:** M081
- **Driving RR:** —
- **Principles touched:** IP3
- **Resolves:** #91 closes
- **Surface tier:** user-facing — the vignettes, the site articles, README and NEWS ship with the package and on the site
- **Branch/PR:** `m082-guides-readme-rewrite`

## Goal

Rewrite the four guides, the parallel article, README and NEWS in plain prose for a tidymodels user, with each explanation on one page, the sections that served the author removed, and the why-nest article deleted.

## Scope

**In:** `vignettes/nested-cv.Rmd`, `estimate.Rmd`, `tuners.Rmd`, `results.Rmd`, `articles/parallel.Rmd`, `README.Rmd` (re-knit to `README.md`), `NEWS.md`; deletion of `vignettes/articles/why-nest.Rmd`, `why-nest-sim.R` and `why-nest.rds` and their `_pkgdown.yml` row; the `estimate` page keeps its theory, citations and References, written plainly.

**Out:** help pages, templates, examples and pkgdown reference blurbs → M081. Re-running or re-siting the why-nest simulation → dropped at the plan gate (the estimate page's cited figures carry the same point). Any change to what a function does → its own milestone. A re-runnable prose checker → declined at the plan gate. The parallel article's internals (payload, cancellation edge cases, `load_all()` interaction) → removed here and not re-homed; `R/parallel.R`'s comments already hold them.

## Acceptance criteria

- [ ] AC1: The pages under `vignettes/` are exactly `nested-cv.Rmd`, `estimate.Rmd`, `tuners.Rmd`, `results.Rmd` and `articles/parallel.Rmd`, checked by `ls -R vignettes/`; `articles/why-nest.Rmd`, `articles/why-nest-sim.R` and `articles/why-nest.rds` are deleted; `_pkgdown.yml` lists only pages that exist; the shipped-vignette vector at `benchmarks/sweep-vignette-idioms.R:133` names the four guides.
- [ ] AC2: Prose word counts, measured per file by `awk '/^```/{f=!f;next} !f' <file> | wc -w`, are at most: `nested-cv.Rmd` 1500, `estimate.Rmd` 1400, `tuners.Rmd` 1500, `results.Rmd` 1500, `articles/parallel.Rmd` 700, `README.Rmd` 350.
- [ ] AC3: These are gone, checked by grepping each heading over `vignettes/` and `README.Rmd`: the "Where this example sits" section of `nested-cv.Rmd`; the survival `event_level`/`eval_time` worked example of `results.Rmd`; the "Passing a control through `...`" and "What differs from calling tune or finetune directly" sections of `tuners.Rmd`; the "What crosses the wire" and "Interrupting and cancelling" sections of `articles/parallel.Rmd`; the "Why" section and its memory table of `README.Rmd`. Each of these five explanations, and no claim is made about others, appears in full on one page only and elsewhere as at most one sentence with a `vignette()` link: the case for nesting, the fit-count arithmetic, the seeding paragraph, the rule that two nested estimates are not subtracted, feature selection inside the workflow.
- [ ] AC4: With prose extracted by the AC2 `awk` command from every `.Rmd` under `vignettes/`, `README.Rmd` and `NEWS.md`, then filtered by `grep -vE '^---$|^<!--.*-->$'` to drop the YAML front-matter delimiters and HTML comment lines: `grep -nE -- '--|—|contract|invariant|rests on'` returns no hit; `grep -ciw 'you\|your'` returns at most 5 lines per file; every heading line (`^#+ `) is a noun phrase with no finite verb, checked by reading; and `Rscript benchmarks/sweep-vignette-idioms.R` exits 0.
- [ ] AC5: `README.Rmd` consists of, in order: the title and badges, one paragraph saying what the package does, an Installation section, one example calling `nested_resamples()`, `nested_tune_grid()`, `collect_metrics()` and `nested_final_fit()`, and a "Learn more" list linking the four guides and the parallel article; `README.md` is re-knit from it.
- [ ] AC6: `nested-cv.Rmd` and `estimate.Rmd` each say in one paragraph that the estimate describes the tune-and-fit procedure, that it is the number to report, and that the final model has no performance number of its own (IP3's documentation obligation). (RB tripwire: ip-touching)
- [ ] AC7: `NEWS.md` keeps its `# nestedtune 0.0.0.9000` heading; every bullet is one or two sentences naming one user-visible behavior; the sentence `tests/testthat/test-id-columns.R:230` pins is kept verbatim; `devtools::check()` reports 0 errors, 0 warnings, 0 notes, and `test-id-columns.R` passes.

## Coverage

- AC1 → T1
- AC2 → T2, T3, T4, T5, T6, T8
- AC3 → T2, T3, T4, T5, T6
- AC4 → T2, T3, T4, T5, T6, T7, T8
- AC5 → T6
- AC6 → T2, T3
- AC7 → T7, T8

## Tasks

- [x] T1: Delete the three why-nest files, their `_pkgdown.yml` row and any `vignette()` or site link naming the page (`grep -rn why-nest vignettes/ README.Rmd _pkgdown.yml`); confirm `nnet` is not in `DESCRIPTION` (it is not at `c5638cf`).
- [x] T2: Rewrite `nested-cv.Rmd` as the getting-started page: design, run, read, final fit, write-up; the "Where this example sits" section (`:361`) and the `show_best()` aside (`:334-343`) removed; the IP3 paragraph kept. (RB tripwire: ip-touching)
- [x] T3: Rewrite `estimate.Rmd` in plain prose as the theory page: the estimand, the bias direction with its cited figures (`:73-83`), `std_err`, the no-comparison rule, when nesting is worth it (`:168-197` shortened), feature selection, References kept. (RB tripwire: ip-touching)
- [x] T4: Rewrite `tuners.Rmd` as choosing a tuner (one example per tuner, the workflow-set run) with `:307-344` and `:429-471` removed, pointing at the help pages M081 rewrote.
- [x] T5: Rewrite `results.Rmd` as reading the results: readers, summary, plots, agreement, a short failed-fold note in place of `:254-376`, dplyr rules; the survival example (`:416-564`) removed.
- [x] T6: Rewrite `articles/parallel.Rmd` (start daemons, same call, same result, when it pays) and `README.Rmd` to the AC5 shape; re-knit `README.md`.
- [x] T7: Rewrite `NEWS.md` bullets to one or two sentences each, the heading and the pinned id-column sentence kept.
- [ ] T8: Run the AC2 and AC4 commands and the sweep script, fix every hit, render the pages (`devtools::build_vignettes()` or `pkgdown::build_articles()`), `devtools::check()`; NEWS entry for the docs change.

## Work log

- 2026-09-10: created by /milestone-plan from issue #91 (topepo), the second half of the split M081 opens. [S] audit of the pages: ~10,300 words, zero `--` or em dashes left after M67, 80 to 100 mannered constructions, the nested-CV argument stated four times, the `mtcars` setup four times.
- 2026-09-10: criteria audit ran in full mode ([O] fresh reader, shared with M081): `nnet` found absent from Suggests, so no dependency decision; the NEWS heading and the pinned id-column sentence kept; the prose extraction stated once and both greps run over it; the five-explanation clause narrowed to those five; the sweep-script clause now names its line.
- 2026-09-10: plan gate chose deleting the why-nest article over keeping it trimmed because the user is fine dropping it if not needed and the estimate page's cited figures make the same point; the user asked to keep some theory, so `estimate.Rmd` keeps its citations at a 1400-word cap rather than the 900-word rules-of-thumb cut proposed; falsified by a reader asking for the simulation the article showed.
- 2026-09-10: plan gate chose including NEWS over a candidate row because it is in the same register and ships with the package; falsified by nothing, a deferral would have been a roadmap fact.
- 2026-09-10: implement started on `m082-guides-readme-rewrite`; gate took all four recommendations (see Decisions). T1: the three why-nest files and their `_pkgdown.yml` row deleted, no other reference to the page outside `NEWS.md` (T7) and the CI baseline record; `nnet` absent from DESCRIPTION; `pkgdown::check_pkgdown()` clean.
- 2026-09-10: T2: `nested-cv.Rmd` rewritten (1198 prose words, from 1747); the "Where this example sits" section, the `show_best()` direction paragraph and the baseline section gone, the case for nesting and the no-subtraction rule each one sentence with a link, the fit-count arithmetic and the seeding paragraph in full, the IP3 paragraph as decided; renders clean. The AC4 grep's only hits on the page are the YAML `---` delimiters, which the criterion as written cannot avoid; raised at T8.
- 2026-09-10: T3: `estimate.Rmd` rewritten (1397 prose words, from 2071): the case for nesting, the no-subtraction rule and feature selection in full, the six citations and every figure they carry kept, the IP3 paragraph as decided, headings noun phrases; the selection-time paragraph on `nested-cv.Rmd` cut to one sentence with a link. Three counting passes were needed to reach the cap; renders clean.
- 2026-09-10: T4: `tuners.Rmd` rewritten (1262 prose words, from 1781): the control-through-`...` and what-differs sections gone, each tuner's page named for its control slots, the `nested_fit_resamples()` baseline moved in from the guide with its join against the Bayesian run's per-fold scores, the fit count and seeding each one sentence with a link; renders clean.
- 2026-09-10: T5: `results.Rmd` rewritten (1274 prose words, from 1749): the survival example and its five chunks gone, `event_level` and `eval_time` one closing paragraph pointing at `?nested_tune_grid`, the failed-fold section cut to the run, the failed fold's notes and one paragraph on how the readers answer; renders clean.
- 2026-09-10: T6: `articles/parallel.Rmd` rewritten (529 prose words, from 1343): the pre-flight, wire, `load_all()` and interrupt sections gone with one sentence pointing at `?nested_tune_grid`'s parallel section, the no-dispatcher chunks gone with them; `README.Rmd` to the AC5 shape (201 prose words, from 414), the Why section and memory table gone, the example attaching tidymodels; `README.md` re-knit by `devtools::build_readme()`. The "Learn more" list is a lead-in line and a list rather than a heading, so AC4's heading test and AC5's name both hold.
- 2026-09-10: T7: `NEWS.md` rewritten to 76 bullets of one or two sentences (from 1003 lines), the heading and the pinned id-column sentence kept, a top bullet for this milestone's docs change added; dropped as superseded: the `.grid` column and its attributes, the print-as-report shape, the why-nest article, the pre-record fold-label rule, the dev-only fixes (summary advice naming `x$.notes`, the site publish job), the help-page example speed, and the docs bullets the rewrites replace. Signatures and condition classes read from `man/*.Rd` usages and `R/` before writing. `test-id-columns.R` passes (156 expectations).
- 2026-09-10: substantive amendment at a mini gate, user accepted: AC4 gains the clause "then filtered by `grep -vE '^---$\|^<!--.*-->$'` to drop the YAML front-matter delimiters and HTML comment lines", because the grep as written hit the YAML `---` delimiters on every page and README's three HTML comment lines and nothing else; the four checks are unchanged. With the filter the grep returns no hit on any of the seven files.
- 2026-09-10: re-audit: AC4 (full) — nothing blocking; the reader noted the heading clause is decided by reading rather than a command (as the plan-gate wording already was), the filter is asserted without a probe of its own, and the YAML front-matter body stays inside the extracted prose.

## Decisions

- 2026-09-10 (implement gate): the five shared explanations are homed as follows: the case for nesting, the no-subtraction rule and feature selection inside the workflow on `estimate.Rmd`; the fit-count arithmetic and the seeding paragraph on `nested-cv.Rmd`. Every other page gets at most one sentence and a `vignette()` link. Chosen because the theory page is where a reader goes for the argument and the getting-started page for the mechanics.
- 2026-09-10 (implement gate): the `nested_fit_resamples()` baseline moves from `nested-cv.Rmd` to `tuners.Rmd` as a short section before the workflow-set run, so the getting-started page is design, run, read, final fit, write-up and the tuners page holds every way of running the loop.
- 2026-09-10 (implement gate): NEWS drops a bullet whose behavior a later bullet replaced (the `.grid` column, the print-as-report shape, the why-nest article, the pre-record fold-label rule) rather than shortening it, since no release has shipped and the file describes what 0.0.0.9000 does; the heading and the pinned id-column sentence stay.
- 2026-09-10 (implement gate): the IP3 paragraph on `nested-cv.Rmd` and `estimate.Rmd` is, on both: "The number `collect_metrics()` reports describes the whole tune-and-fit procedure: resample, tune, select, fit. That is the number to report. The model fitted at the end for deployment is a separate object, and it has no performance number of its own, because everything computable from its training data was used up in selecting and fitting it." Escalation was offered on the ip-touching tripwire and declined.

## Review
