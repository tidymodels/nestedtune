# M085: The help pages read on one pass for a tune_grid user

- **Status:** planned
- **Priority:** high
- **Depends on:** M84
- **Driving RR:** —
- **Principles touched:** IP3
- **Resolves:** #91 closes
- **Surface tier:** user-facing — every exported topic's help page
- **Branch/PR:** —

## Goal

Rewrite every roxygen paragraph that a tidymodels user who has run `tune_grid()` cannot follow on one read, to the standard M84 sets, with the package's own words set up once on `?nested_tune_grid` and linked from every other page that uses them.

## Scope

**The standard.** M84's (a)-(e); `@param` entries and `\arguments` items are judged on (c)-(e) only, since an argument entry is not a paragraph in the (a)/(b) sense.

**In:** the 107 paragraphs `surveys/M085-survey.md` lists and any other the AC3 reader finds, across the 20 files under `R/` with roxygen prose and `man-roxygen/`; the `--roxygen` mode of `benchmarks/sweep-prose.R` (M84 T1); the term setup on `?nested_tune_grid`; a NEWS bullet.

**Out:** the guides → M84. M081's argument cap, no-recurring-window rule, pipe rule and banned-word grep stay as they are (AC4). Restructuring topics, sections or templates beyond what a rewrite needs → none. `NEWS.md` bullets → the candidate row M84 opened.

## Acceptance criteria

- [ ] AC1: No sentence of roxygen prose in `R/*.R` or `man-roxygen/*.R` exceeds 30 words. Roxygen prose is the text of `@title`, `@description`, `@details`, `@param`, `@return` and `@section` bodies, and untagged lines belonging to them; every other tag's lines and every `@examples` block are excluded; backtick spans, `[link]` targets and `\code{}` spans are removed and abbreviations joined as M84 AC1 states. Evidence: `Rscript benchmarks/sweep-prose.R --roxygen` prints every hit as `file:line` and exits 0.
- [ ] AC2: `?nested_tune_grid` sets up `procedure`, `orchestrator` and `candidate` in the sentence where each first appears on the page. In every other roxygen block, each of those words either does not appear, or its first sentence sets it up, or the block links `[nested_tune_grid()]` earlier in its text. `reader` is set up on `?collect_metrics.nested_results` (`R/nested-results-collect.R`) or does not appear elsewhere. Evidence: the script's `--roxygen --terms` mode prints each block's first occurrence per word as `file:line`, and each printed sentence and its block are read.
- [ ] AC3: Every paragraph of every rendered help page meets the standard: (c)-(e) inside `\arguments`, (a)-(e) elsewhere. Verified by a reader with no authorship of the text, given the standard and the text of every `man/*.Rd` from `tools::Rd2txt()`, reporting every paragraph it cannot follow on one read; the 107 paragraphs `surveys/M085-survey.md` lists are the minimum probe set, read first, and the reader's list is empty.
- [ ] AC4: M081's checks: every `\arguments` `\item` in `man/*.Rd` is at most two sentences and 50 words (`tools::parse_Rd()`); no whitespace-normalized window of three consecutive `#'` lines recurs in two roxygen blocks across `R/*.R` and `man-roxygen/*.R`; no `#'` line matches `%>%` and no example `step_*()` call takes a `recipe()` or `step_*()` call as its first argument; `devtools::run_examples()` completes; `grep -nE -- '--|—|contract|invariant|rests on'` over `#'` lines of `R/*.R` and `man-roxygen/*.R`, `man/*.Rd` and `_pkgdown.yml` returns no hit.
- [ ] AC5: `?nested_tune_grid` and `?nested_final_fit` each keep one paragraph saying the estimate describes the tune-and-fit procedure, that it is the number to report, and that the final model has no performance number of its own (IP3's documentation obligation). (RB tripwire: ip-touching)
- [ ] AC6: `devtools::document()` leaves the tree clean, `devtools::check()` reports 0 errors, 0 warnings, 0 notes, and `tests/testthat/test-control-slots.R`, `test-eval-time.R`, `test-tuner-registry.R` and `test-id-columns.R` pass unchanged.

## Coverage

- AC1 → T1, T2, T3, T4, T5
- AC2 → T1, T2, T3, T4, T5
- AC3 → T1, T2, T3, T4, T5, T6
- AC4 → T2, T3, T4, T5, T7
- AC5 → T1, T2
- AC6 → T7

## Tasks

- [ ] T1: Rewrite `R/nested-tune-grid.R`'s 26 listed paragraphs (survey §1) and flagged sentences; set up `procedure`, `orchestrator` and `candidate` where the page first uses each; the IP3 paragraph kept. (RB tripwire: ip-touching)
- [ ] T2: Rewrite `R/nested-final-fit.R` (9), `nested-final-fit-extract.R` (3), `nested-final-fit-predict.R` (1) and `nested-final-fit-print.R` (3); the IP3 paragraph kept. (RB tripwire: ip-touching)
- [ ] T3: Rewrite the four tuning siblings: `nested-tune-bayes.R` (5), `nested-tune-race.R` (6), `nested-tune-sim-anneal.R` (7), `nested-fit-resamples.R` (8); each links `[nested_tune_grid()]` before its first package word.
- [ ] T4: Rewrite `nested-workflow-map.R` (10), `nested-results-set.R` (12), `extract-procedure.R` (3).
- [ ] T5: Rewrite `nested-results-collect.R` (3), `nested-results.R` (2), `nested-results-plot.R` (2), `nested-results-print.R` (2), `nested-results-agreement.R` (1), `nested-resamples.R` (3), `selection-rule.R` (1).
- [ ] T6: `devtools::document()`; spawn the AC3 reader with the standard, the Rd2txt output and the survey list; fix every paragraph it reports; rerun until its list is empty; record each run's count in the work log.
- [ ] T7: Run the AC1, AC2 and AC4 commands, `devtools::run_examples()`, `devtools::check()`, the four pinned test files; NEWS bullet.

## Work log

- 2026-09-10: created by /milestone-plan. Survey: 107 of 343 roxygen paragraphs fail the standard (`surveys/M085-survey.md`); the dominant pattern is the 40-90 word sentence in `@return` blocks and the "Differences from calling tune directly" sections.
- 2026-09-10: criteria audit ran in full mode (shared with M84; see its work log); for this file it fixed the tag rule (an included list) and posed the term-setup site at the gate.
- 2026-09-10: plan gate chose setting each package word up once on `?nested_tune_grid` with a link from other pages over defining it in every block, because a per-block setup repeats across about 40 topics and the shared sections cover only three arguments; falsified by a reader of a sibling page reporting the word as cold despite the link.
