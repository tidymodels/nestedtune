# M081: The help pages read for a tidymodels user: one-sentence arguments, shared text once, piped examples

- **Status:** in-progress
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP3
- **Resolves:** #91 partial
- **Surface tier:** user-facing — the Rd pages, examples and pkgdown reference blurbs ship in the package and on the site
- **Branch/PR:** `m081-help-pages-rewrite`

## Goal

Rewrite every help page so a tidymodels user meets one-sentence argument entries, a short description, details under their own headings, examples written with pipes, and none of the double hyphens, internal vocabulary or text pasted between files that issue #91 names.

## Scope

**In:** the roxygen of every exported topic under `R/` (27 topics, 3,158 `#'` lines at `c5638cf`); `@inheritParams` onto the wrapped tune, finetune and workflowsets functions; `man-roxygen/` templates and shared `@example` files for the text the audit found pasted (the `mtcars` scaffold 23 times, the seeding paragraph 5, the RNG-restore sentence 6, the control-slot section's shared sentences 5); the package-level doc in `R/nestedtune-package.R`; the `desc:` blurbs of `_pkgdown.yml`; the memory table from `README.Rmd`'s "Why" section moved into `?nested_resamples` Details; regenerated `man/`; a NEWS entry.

**Out:** vignettes, articles, README and NEWS prose → M082. Any change to what a function does or accepts → its own milestone. A re-runnable prose checker → declined at the plan gate (the criteria name the commands review runs). Code comments under `R/` that carry milestone and decision ids → untouched; they are not user-facing.

## Acceptance criteria

- [ ] AC1: Every `\item` under `\arguments` in every `man/*.Rd` file is at most two sentences and at most 50 words, measured by parsing each file with `tools::parse_Rd()` and counting words in each argument item's text.
- [ ] AC2: On the six orchestrator topics (`nested_tune_grid`, `nested_tune_bayes`, `nested_tune_race`, `nested_tune_sim_anneal`, `nested_fit_resamples`, `nested_workflow_map`), every argument sharing its name with the wrapped tune, finetune or workflowsets function (`object`, `resamples`, `param_info`, `grid`, `metrics`, `eval_time`, `iter`, `initial`, `objective`) is documented either by `@inheritParams` naming that function or by a one-sentence override; the nested-design requirements for `resamples` and the data-dependent finalization note for `param_info` sit under a `@section` of `nested_tune_grid` that the five siblings pull in with `@inheritSection`, and appear in no `@param` tag. Checked by reading the nine `@param` tags in the six source files and the six Rd files.
- [ ] AC3: No window of three consecutive roxygen `#'` lines, whitespace-normalized, recurs in two different roxygen blocks across `R/*.R` and `man-roxygen/*.R`, measured by a script that hashes every such window and reports any hash seen in more than one block; the `mtcars` example scaffold, the seeding paragraph and the RNG-restore sentence each live once, in a `man-roxygen/` template or an `@example` file. The per-page control-slot contents `tests/testthat/test-control-slots.R` pins stay on each page; only their shared sentences are templated.
- [ ] AC4: Every `@examples` block that builds a recipe uses `|>`: no `#'` line of `R/*.R` or `man-roxygen/*.R` matches `%>%`, no example source (each `\examples` section of `man/*.Rd`, parsed with `parse()` and walked) contains a `step_*()` call whose first argument is a call to `recipe()` or to another `step_*()`, and `devtools::run_examples()` completes with no error.
- [ ] AC5: Over every `#'` line of `R/*.R` and `man-roxygen/*.R`, every line of `man/*.Rd`, and every line of `_pkgdown.yml`, the command `grep -nE -- '--|—|contract|invariant|rests on'` returns no hit.
- [ ] AC6: `?nested_tune_grid` and `?nested_final_fit` each keep one paragraph saying that the estimate from `collect_metrics()` describes the tune-and-fit procedure, that it is the number to report, and that the final model has no performance number of its own (IP3's documentation obligation). (RB tripwire: ip-touching)
- [ ] AC7: `devtools::document()` leaves the tree clean, `devtools::check()` reports 0 errors, 0 warnings, 0 notes, and `tests/testthat/test-control-slots.R`, `test-eval-time.R`, `test-tuner-registry.R` and `test-id-columns.R`, which read `man/*.Rd` and `NEWS.md`, pass unchanged.

## Coverage

- AC1 → T2, T3, T4, T5, T6
- AC2 → T2, T3
- AC3 → T1, T6
- AC4 → T1, T6
- AC5 → T5, T6
- AC6 → T2, T4
- AC7 → T6

## Tasks

- [ ] T1: Create `man-roxygen/` templates for the seeding paragraph (`R/nested-tune-grid.R:244` and its four copies) and the RNG-restore sentence (`R/nested-tune-grid.R:275` and five copies), and one shared `@example` file for the `mtcars` scaffold written with `|>` (`R/nested-tune-grid.R:539` and 22 copies; the doubly nested `R/nested-tune-bayes.R:186-193` included); replace every copy with the template or example call.
- [x] T2: Rewrite `R/nested-tune-grid.R`'s block: a two-paragraph description, `@inheritParams tune::tune_grid` with one-sentence overrides where nestedtune narrows the argument, a `@section` for the nested-design requirements (`:44`) and the finalization note (`:67`), the `eval_time` (`:96`) and `select` (`:119`) detail moved under sections, the control-slot section kept in the shape `test-control-slots.R` pins, and the IP3 paragraph kept. (RB tripwire: ip-touching)
- [x] T3: Rewrite the five sibling orchestrators (`R/nested-tune-bayes.R`, `nested-tune-race.R`, `nested-tune-sim-anneal.R`, `nested-fit-resamples.R`, `nested-workflow-map.R`) onto `@inheritParams` of their wrapped function and of `nested_tune_grid`, `@inheritSection` for the shared sections, one-sentence overrides for `param_info`, `iter`, `initial` and `grid`, and their own control-slot contents.
- [x] T4: Rewrite `R/nested-final-fit.R` (`results` at `:38` is 266 words, `object` at `:29`, `id` at `:71`) and its methods in `nested-final-fit-print.R`, `nested-final-fit-predict.R`, `nested-final-fit-extract.R` and `extract-procedure.R`, keeping the IP3 paragraph. (RB tripwire: ip-touching)
- [ ] T5: Rewrite the reader topics (`nested-results.R`, `nested-results-collect.R`, `nested-results-print.R`, `nested-results-plot.R`, `nested-results-agreement.R`, `nested-results-set.R`, `selection-rule.R`, `nested-resamples.R` with the README memory table under Details, `nestedtune-package.R`, `reexports.R`) and the `desc:` blurbs of `_pkgdown.yml`.
- [ ] T6: Run the AC1, AC3, AC4 and AC5 procedures, fix every hit, `devtools::document()`, `devtools::run_examples()`, the four Rd-reading test files, `devtools::check()`; NEWS entry.

## Work log

- 2026-09-10: created by /milestone-plan from issue #91 (topepo). Two [S] audits: roxygen (27 topics, 27 `@param` entries over 40 words, 23 pasted example scaffolds, 96 lines with `--`) and vignettes.
- 2026-09-10: criteria audit ran in full mode ([O] fresh reader): seven findings fixed (`carries` left the token list because `test-id-columns.R` pins it; the control-slot section exempted from templating because `test-control-slots.R` pins per-page contents; `resamples` detail reaches the siblings through `@inheritSection`; the example check parses instead of greps; Review-quotation clauses struck as instrument properties), six judgment calls disposed here (the argument cap kept universal over every Rd item; `reaches`, `answers`, `surface` dropped from the token list as ordinary prose).
- 2026-09-10: plan gate chose two milestones with the help pages first over one milestone and over guides-first because the split tripwires fire on either half and the README table lands on a help page; falsified by the two pull requests turning out to need one review.
- 2026-09-10: plan gate chose criteria naming the commands review runs over extending `benchmarks/sweep-vignette-idioms.R` to roxygen because a wider checker over repo-internal artifacts is the regress shape; falsified by a second prose pass being wanted and re-deriving the same commands.
- 2026-09-10: the `#91 partial` remainder is M082, planned in the same commit, so no candidate row holds it.
- 2026-09-10: implementation gate: the three recommended options taken (Decisions below); no dependency changes.
- 2026-09-10: T2 done first (minor reorder): the four `man-roxygen/` files are created with it and T1 ticks once every copy across the other pages is replaced; `^man-roxygen$` added to `.Rbuildignore`. Only roxygen lines change on this branch (checked per file with `git diff` filtered to non-`#'` lines), so the five Rd-reading test files run per task and the whole suite at T6.
- 2026-09-10: T2: `nested_tune_grid`'s page rewritten: two-paragraph description with the IP3 paragraph, `@inheritParams tune::tune_grid` (pulls `metrics`), one-sentence overrides for the other eight arguments, sections for nested designs, finalizing a range, evaluation times, selecting a candidate, what the result records, operations on the result, the shared Reproducibility template plus a by-hand section, fold failure, parallel execution and the control-slot section in the shape `test-control-slots.R` pins. AC1 and AC5 clean on the page; the five Rd-reading test files pass; the example runs.
- 2026-09-10: T3: the five siblings rewritten onto `@inheritParams nested_tune_grid` plus the wrapped function's (`tune::tune_bayes` for `iter`, `finetune::tune_sim_anneal`, `workflowsets::workflow_map` for `object`), one-sentence overrides for `...`, `param_info`, `grid`, `initial`, `objective`, `iter` and `fn`, `@inheritSection` for the nested-design and finalization sections, the Reproducibility template, and their own control-slot contents; every page's example runs off the setup template, the racing page building its own five-inner-fold design beside it. The five Rd-reading test files pass and the five examples run.
- 2026-09-10: T4 and T5 delegated to two [O] subagents with the finished `nested_tune_grid` page as the reference; T4 returned (diff verified below), T5 still running at this line.
- 2026-09-10: mini gate (Substantive): AC3 narrowed to prose windows, since tag-and-blank windows recur on every templated page by construction; the user chose the narrowing over keeping the literal wording. The amended text is written once the fresh reader's re-audit line lands.
- 2026-09-10: T4 ([O] subagent, diff read line by line): `nested_final_fit` and its four method files rewritten; `results` 266 words to 32, `object` and `id` to two sentences each, the rest under sections (the results object, fitting one workflow of a set, what is refused, what to report with the IP3 paragraph and both citations, Reproducibility with the five-tuner recipe `test-tuner-registry.R` pins, the re-evaluated inner specification); `x` and `...` defined once on `print.nested_final_fit` and inherited by the extractors. Only `#'` lines changed; AC1, AC4 and AC5 report nothing on these pages; the seven examples run; `test-eval-time.R` and `test-tuner-registry.R` pass. One edit of mine on top: `[nested_fit_resamples]` restored to a call link outside the pinned section.

## Decisions

- 2026-09-10: The shared example setup is a `man-roxygen/` template that carries its own `@examplesIf` guard, and each page adds its lines under a guard of its own, so every example block balances by itself. `\donttest{}` is dropped: `R CMD check --as-cran` runs those examples anyway, and `devtools::run_examples()` skipped every guarded example under it. Falsified by an example that must not run under check.
- 2026-09-10: The IP3 paragraph is one plain paragraph on `?nested_tune_grid` and `?nested_final_fit`: the estimate from `collect_metrics()` describes the tune-and-fit procedure, it is the number to report, and the final model has no performance number of its own. The final-fit page keeps its two citations in one sentence.
- 2026-09-10: The Reproducibility section is one template shared by the six orchestrators, and the by-hand reproduction of a fold stays on `?nested_tune_grid` under its own section, the siblings pointing there. A roxygen template must open with a tag, so a sentence-sized template was not available.

## Review
