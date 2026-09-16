# M096: The help pages inherit tune's argument text and share repeated text through templates

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1
- **Resolves:** #91 partial
- **Surface tier:** user-facing — the help pages every user reads
- **Branch/PR:** `m096-help-inherits-tune-params`

## Goal

Every `@param` on the six loop pages whose accepted values equal the wrapped tune, finetune or workflowsets argument's carries that package's own text, with the nested-CV qualification moved to the page's Details, and no roxygen prose line is repeated across blocks where a template or inheritance can carry it.

## Scope

**In:** the `@param` tags of `R/nested-tune-grid.R`, `R/nested-tune-bayes.R`, `R/nested-tune-race.R`, `R/nested-tune-sim-anneal.R`, `R/nested-fit-resamples.R` and `R/nested-workflow-map.R`: a survey deciding `inherit` or `local` per tag, `@inheritParams` for the former, each removed sentence relocated to the page's Details or "Differences from calling tune directly" section. The repeated roxygen runs the plan survey found: the five pages' "Differences" scaffold (the Forced, Settable, Refused, Kept-from-the-outer-fit, Not-returned and `pkgs`/`parallel_over` paragraphs, `R/nested-tune-grid.R:381-434` and siblings), the finetune 1.3.0 classification note (`R/nested-tune-race.R:121-124`, `R/nested-tune-sim-anneal.R:132-135`), the workflow-set `@examplesIf` guard (5 sites), the reader `@param x`, `summarize` and `...` family (`R/nested-results-collect.R`, `R/nested-results.R`, `R/nested-results-set.R`), the two `@seealso` families (`R/nested-results-collect.R:81,241,361,641`; the four sibling loop pages), the `save_pred`/`no_completed_folds` refusal sentences (`R/nested-results-collect.R:334-343,614-615`). One NEWS bullet.

**Out:** the guides' use of "you" — 24 occurrences across the six pages at `ca6c628` (9/6/4/2/3 per guide, 3 on README), the M082-era overuse #91 saw being gone; dropped at the plan gate, no cap and no sweep clause. The passive-voice and `-ing` entries → DESIGN Known issues (M087). The maintainers' human pass over the pages → the #91 candidate row. A `--duplicates` sweep mode → not planned; the gate chose a one-off command (T5). Help text on pages outside the six loop pages and the repeated runs named above → untouched.

## Acceptance criteria

- [x] AC1: For every `#' @param` tag `grep -n "^#' @param" R/nested-tune-grid.R R/nested-tune-bayes.R R/nested-tune-race.R R/nested-tune-sim-anneal.R R/nested-fit-resamples.R R/nested-workflow-map.R` prints at the branch point, `cairn/surveys/M096-param-survey.md` records one row: file, argument, `inherit` or `local`, reason. `inherit` is required when the wrapped upstream page (`tune::tune_grid`, `tune::tune_bayes`, `finetune::tune_race_anova`, `finetune::tune_sim_anneal`, `tune::fit_resamples`, `workflowsets::workflow_map`) documents the same argument and neither the upstream text nor the current local text names a value one accepts and the other refuses or adds; `local` otherwise, the row naming that value. For every `inherit` row the rendered `\item{<arg>}` of `man/<page>.Rd`, whitespace-collapsed through `tools::parse_Rd`, equals the same item of the upstream package's installed Rd (tune 2.1.0, finetune 1.3.0), and no local `@param` tag for it remains.
- [x] AC2: Every sentence removed from a `@param` body in `git diff main -- R/` either appears, whitespace-collapsed and free of markup, in the same page's rendered Details or "Differences" text (the `rd_text(help_rd(topic))` idiom `tests/testthat/test-control-slots.R` uses), or its survey row names it as already said by the inherited text.
- [x] AC3: Over the raw `#'` lines of `R/*.R` and `man-roxygen/*.R`, keeping only the bodies of `@description`, `@details`, `@param`, `@return`, `@section` and `@seealso` tags with their untagged continuation lines, whitespace-normalized, no line of 12 or more words appears in two or more roxygen blocks; the T5 command exits 0 and prints nothing. This is a full-line floor: a repeated paragraph whose every wrapped line is under 12 words is not swept, and the runs the Scope names are the record of intent, each served by a `man-roxygen/` template, `@inheritParams` or `@inheritSection`.
- [x] AC4: `git diff main -- tests/testthat/test-control-slots.R` is empty and `Rscript -e 'devtools::test()'` is clean.
- [x] AC5: `Rscript -e 'devtools::document()'` produces no diff at the review head; `Rscript -e 'devtools::check()'` reports 0 errors and 0 warnings; every command `Rscript benchmarks/sweep-prose.R --list-gating` prints exits 0; `NEWS.md` carries one bullet naming the pages whose argument text now comes from tune, finetune or workflowsets, with no milestone number.

## Coverage

- AC1 → T1, T2
- AC2 → T2
- AC3 → T3, T4, T5
- AC4 → T3, T6
- AC5 → T6

## Tasks

- [x] T1: Write `cairn/surveys/M096-param-survey.md`: one row per `@param` tag the AC1 grep prints, with the upstream item text quoted beside the local text and the disposition. Start from the plan survey's table (this file's work log names it). Check the upstream Rd items with `tools::Rd_db("tune")`, `Rd_db("finetune")`, `Rd_db("workflowsets")`.
- [x] T2: Apply `@inheritParams <upstream>` per `inherit` row and delete the local tag; move each removed sentence into Details or the "Differences" section of the same page, or mark it in the survey as said by the inherited text. Note `R/nested-tune-race.R` inherits from `nested_tune_grid` only today; add `finetune::tune_race_anova`. `devtools::document()`; run the AC1 item comparison and the AC2 idiom.
- [x] T3: Templates for the "Differences" scaffold: one `man-roxygen/differences-*.R` per repeated paragraph, parameterized through `@templateVar` (the control constructor, the page name), keeping the bold run-in headings byte-identical so `test-control-slots.R` parses them; the finetune classification note as one template. `devtools::test()` after each page.
- [x] T4: The remaining runs: the `@examplesIf` guard into `man-roxygen/example-set.R`; the reader `@param x`/`summarize`/`...` family and the refusal sentences via `@inheritParams collect_metrics.nested_results` or a template; the two `@seealso` families as templates with a `@templateVar` for the varying link.
- [x] T5: Write the AC3 command into this file's Decisions section and run it: an R snippet reading `#'` lines of `R/*.R` and `man-roxygen/*.R`, tracking tag state per block, keeping the six tag kinds, normalizing whitespace, and printing any line of 12+ words seen in two blocks. Fix each hit through T3/T4 or record why it stands.
- [x] T6: `devtools::document()` no-diff, `devtools::check()`, the gating sweeps, the NEWS bullet.

## Work log

- 2026-09-15: created by /milestone-plan. Plan survey (Explore subagent, read-only): 76 local `@param` lines in `R/*.R`, about 65 sharing a tune/finetune/workflowsets argument name, about 20 carrying a nested qualification; `@inheritParams tune::tune_grid` already supplies `metrics` on `?nested_tune_grid`; the "Differences" scaffold repeats about 40 lines over five pages; 16 repeated runs in all, listed in Scope.
- 2026-09-15: criteria audit ran in full mode on a fresh [O] reader: 12 findings. Nine fixed before writing (AC1 compares rendered items to the upstream Rd and adds the restriction-or-extension trigger; AC2's domain is every sentence removed in the diff, verified through the Rd idiom; the "every page changed" clause dropped; AC3 says "two or more blocks", covers `man-roxygen/`, and is stated as a full-line floor; AC4 requires the test file unchanged; the NEWS bullet names pages). One became the duplicate-check gate question; one (no IP/GP reachability problem) needed nothing.
- 2026-09-15: plan gate chose inheriting tune's text and moving the nested qualification to Details over keeping qualified `@param` entries local because #91 asks for exactly that split and Details already holds the "Differences" section; falsified by a user reading a page's Arguments alone and missing a fold-level restriction the Details state.
- 2026-09-15: plan gate chose a one-off duplicate command recorded in this file over a `--duplicates` sweep mode because the checker-regress shape recommends not widening `benchmarks/sweep-prose.R`'s promise for a one-time consolidation; falsified by repeated roxygen text re-accumulating across two later milestones.
- 2026-09-15: plan gate dropped the "you" item from scope (24 occurrences over six pages) and set `Resolves: #91 partial` with no acknowledgement comment, the remainder (the maintainers' human pass) staying on the #91 candidate row.
- 2026-09-15: /milestone-implement started on `m096-help-inherits-tune-params`. Question gate skipped: the AC1 rule settles every disposition (two facts checked at the branch point, recorded in the survey), and no dependency or naming choice is open.
- 2026-09-15: T1 done. Survey at `cairn/surveys/M096-param-survey.md`: 24 tags, 5 `inherit` (grid page `param_info` and `grid`, bayes `iter`, race `grid`, fit-resamples `metrics`), 19 `local`.
- 2026-09-15: T2 done. Five local tags deleted, `@inheritParams finetune::tune_race_anova` and `tune::fit_resamples` added; the five rendered items equal the upstream Rd items, and the seven removed sentences render in Details (scratch script over `tools::parse_Rd`). `document()`, `test()` (10116 pass), and both prose sweeps clean.
- 2026-09-15: checkpoint, T3 and T4 edits on disk and not yet checked off. Roxygen takes a `@template` as a one-line tag and splices the template's own tags in, so a plain-text template cannot sit inside a section. Each Differences template carries its own `@section` tag under the page's title, which roxygen merges, and a page's local paragraph after a template re-opens the section. A guard-only `@examplesIf` template is impossible for the same reason, so the four workflow-set guard lines outside `example-set.R` stay (7 words, under the AC3 floor). The sim-anneal "Refused" example changed: finetune 1.3.0 refuses to coerce a `control_bayes()` for `tune_sim_anneal()` (checked at the branch point), so the page no longer offers it as a class finetune accepts. T3 suite run in progress.
- 2026-09-15: T3 done. Eight `man-roxygen/differences-*.R` templates serve the five pages (forced, settable, refused, passed-shared bullet, finetune-version note, kept, not-returned, inert), and `param-control-dots`, `param-event-level`, `param-eval-time` and `seealso-orchestrator` serve the params and links. Suite 10116 pass after the edits, both roxygen sweeps clean.
- 2026-09-15: T4 done. `seealso-reader` at the four `R/nested-results-collect.R` sites, `refusals-saved-run` at the compute_metrics and augment sections, `@inheritParams` for compute_metrics' `summarize`, augment's `x` and the set summary page's `...`. The `collect_metrics.nested_results` seealso has no varying link and stays local (8 words).
- 2026-09-15: T5 done. The Decisions command exits 0 and prints nothing at this head; the three hits it printed after T3 were the two T4 sites and the sim-anneal "Refused" line, reworded. All six gating sweeps clean.
- 2026-09-15: claim audit: 25 claims read, 1 corrected — NEWS.md, R/nested-tune-grid.R, R/nested-tune-bayes.R, R/nested-tune-race.R, R/nested-tune-sim-anneal.R, R/nested-fit-resamples.R, R/nested-results-collect.R, R/nested-results-set.R, man-roxygen/*.R. The correction: the bayes page said tune accepts a `control_grid()` in `tune_bayes()`, and tune 2.1.0 refuses to coerce it; the bayes and sim-anneal pages now share `differences-refused-plain.R`, which names no example. Re-read by the same reader: holds. Suite 10116 pass after the fix.
- 2026-09-15: T6 done. `devtools::check()` at `1f3ac3d`: 0 errors, 0 warnings, 0 notes. `document()` no diff. NEWS bullet names the five pages and the four arguments. Status → review.
- 2026-09-15: /milestone-review: five criteria verified against recorded evidence, gate clean, three reviewers reported (0 + 0 regressions, 11 diff-bug findings to triage at the gate).
- 2026-09-15: gate: the user chose apply-fixes-then-merge. Fix-now findings 2, 3, 4, 5, 9 applied (`details-param-info` template, `VERSION_CTRL` variable, kept clause, NEWS six pages, bayes Details); AC1, AC2, AC3 and the six sweeps re-verified clean; `test()` and `check()` re-running, results in the next line.

## Decisions

- 2026-09-15 (T5): the AC3 duplicate-line command. Run from the repo root with `Rscript` on the script below. It reads every `#'` line of `R/*.R` and `man-roxygen/*.R`, numbers blocks per file, tracks the tag per line, keeps the six tag kinds with their untagged continuation lines, collapses whitespace, and prints each line of 12 or more words seen in two or more blocks, with the blocks. It exits 0 and prints nothing when there is none. A `@template` line is not one of the six kinds, so a template's use sites are not read as its text, and the template file's own block is.

```r
files <- c(Sys.glob("R/*.R"), Sys.glob("man-roxygen/*.R"))
keep_tags <- c("description", "details", "param", "return", "section", "seealso")
seen <- list()
for (f in files) {
  lines <- readLines(f, warn = FALSE)
  block <- 0L; in_block <- FALSE; tag <- NA_character_
  for (l in lines) {
    if (!startsWith(l, "#'")) { in_block <- FALSE; tag <- NA_character_; next }
    if (!in_block) { in_block <- TRUE; block <- block + 1L; tag <- "title" }
    body <- sub("^#' ?", "", l)
    m <- regmatches(body, regexec("^@([A-Za-z]+)\\s*(.*)$", body))[[1]]
    if (length(m)) { tag <- m[[2]]; body <- m[[3]] }
    if (!tag %in% keep_tags) next
    body <- gsub("\\s+", " ", trimws(body))
    if (!nzchar(body) || length(strsplit(body, " ", fixed = TRUE)[[1]]) < 12L) next
    seen[[body]] <- union(seen[[body]], paste0(f, "#", block))
  }
}
hits <- Filter(function(x) length(x) >= 2L, seen)
for (b in names(hits)) cat(b, "\n   ", paste(hits[[b]], collapse = "  "), "\n")
quit(status = as.integer(length(hits) > 0L))
```

## Review

Reviewed 2026-09-15 at `877c80e` on `m096-help-inherits-tune-params`; the branch contains `origin/main`, nothing to sync. No driving RR.

- AC1: the branch-point grep (`9dea05d`) prints 24 tags, and the survey holds 24 rows (8 grid, 4 bayes, 2 race, 3 sim-anneal, 5 fit-resamples, 2 workflow-map), 5 `inherit`, 19 `local`, each `local` row naming the differing value. A scratch script over `tools::parse_Rd` and `tools::Rd_db` (tune 2.1.0, finetune 1.3.0) found the five inherited items whitespace-equal to the upstream items, and `grep` finds no local `@param` tag for them. Evidence: `nested_tune_grid` `param_info` and `grid`, `nested_tune_bayes` `iter`, `nested_tune_race` `grid`, `nested_fit_resamples` `metrics` all EQUAL.
- AC2: the seven sentences the survey says moved (grid `param_info` pointer and `grid` column rule, both bayes `iter` sentences, race `grid` "the design the race is offered" and its column rule, fit-resamples `metrics` order sentence) each render, whitespace-collapsed, in the same page's Details through the `rd_text(help_rd())` idiom; the five opening sentences the survey marks as said by the inherited text are so marked. The `...`, `event_level` and `eval_time` bodies that moved into templates still render in each page's Arguments (the `event_level` scope clause reworded in place, not relocated).
- AC3: the Decisions command run from the repo root exits 0 and prints nothing.
- AC4: `git diff main -- tests/testthat/test-control-slots.R` is empty; `devtools::test()` 10116 pass, 0 fail, 0 warn, 0 skip.
- AC5: `devtools::document()` at the review head leaves the tree clean; `devtools::check()` 0 errors, 0 warnings, 0 notes (7m40s); all six `--list-gating` sweep commands exit 0; the NEWS bullet names the five pages and four arguments with no milestone number.

Consistency gate: `cairn_validate.py` all checks passed (19 advisory warnings, none a gate failure; the `decisions format` WARN is the AC3 fenced block the plan placed there). `cairn/DESIGN.md` unchanged, so `cairn_impact.py` skipped. Toolchain: `document()` no diff; `NAMESPACE`, `man/` regenerated only; README.Rmd unchanged; `pkgdown::check_pkgdown()` no problems; NEWS entry present; `man-roxygen` is `.Rbuildignore`d; `check()` clean; six gating sweeps clean.

Independent review (three lenses, fresh context):
- [S] blame-history: 7 items, no regression. The one substantive item, the bayes and sim-anneal "Refused" paragraphs dropping their named example, is supported by history (tune 2.1.0 and finetune 1.3.0 refuse the coercions the old examples claimed).
- [S] prior-review record: "no prior-review evidence", 0 findings (archived reviews M056, M065, M072, M073, M081, M085, M087 checked; the GitHub probe found one unrelated human comment on PR #30).
- [O] diff-bug: 11 findings, ranked by the reviewer, dispositions at the gate:
  1. `grid` inherit hides that the wrapper refuses `grid = 2.5` where tune accepts it.
  2. `@templateVar CONSTRUCTOR` is reassigned before the finetune-version template, so the race and sim-anneal `...` items render `control_race()` without the package prefix.
  3. The `param_info` pointer to the "Finalizing a parameter range" section vanished from the bayes, race and sim-anneal pages, which inherit it from the grid page; the sentence landed only in the grid page's Details.
  4. The NEWS bullet omits `nested_tune_sim_anneal()` (whose `param_info` text changed by inheritance) and its Details claim overstates for the pages of finding 3.
  5. The race and sim-anneal "Kept from the outer fit" paragraph lost the clause that `save_pred` and `extract` also reach the inner run.
  6. The race "Not returned" paragraph now says "inner `tune_results`" where it said "inner race result".
  7. The passed-shared template splits each page's "Passed through" bullet list into two `\itemize` blocks.
  8. Orphan paragraphs after a template boundary (grid "Leaving parallelism to a caller…", the three "are arguments of" sentences), plus doubled blank lines at each boundary.
  9. Bayes: the inherited item says "maximum number of search iterations", the Details paragraph says "the number of search iterations".
  10. `@inheritParams finetune::tune_race_anova` is a no-op because `nested_tune_grid` is inherited first and supplies `grid`; finetune's item is byte-identical to tune's.
  11. `nested_tune_sim_anneal`'s `param_info` shows tune's "parameters set" wording rather than finetune's "parameter set".

Gate triage (2026-09-15, the user chose "apply fixes, then merge"):
- Fix now, on the branch before the push: 2 (the version note gets its own `VERSION_CTRL` variable, the `...` items render `finetune::control_race()` and `finetune::control_sim_anneal()` again); 3 and 11 together (`man-roxygen/details-param-info.R`, a Details template on the bayes, race and sim-anneal pages pointing at their "Finalizing a parameter range" section; the wording stays tune's, which is what the inheritance chain the plan chose yields); 4 (the NEWS bullet names all six pages and claims Details only for the four arguments); 5 (the kept template restores "Each reaches the outer fit as well as the <inner run>"); 9 (the bayes Details says tune stops early when the search stalls, both relocated sentences kept verbatim for AC2).
- Follow-up, one candidate row: 7 and 8 (the template-merge pattern's rendering: a split `\itemize`, orphan paragraphs after a template boundary, doubled blank lines). No false text; a rendering wart.
- Rejected: 1 (AC1's rule reads the two texts, and both say integer or whole number, so the rendered "positive integer" is true of the wrapper; tune accepting `2.5` is tune's page under-documenting tune); 6 (a race result is a `tune_results` subclass); 10 (harmless, and it records the intended source).
- Return floor: no finding shows a criterion failing; no return.

After the fixes: `document()` no diff, AC1 five items EQUAL, AC2 sentences render, AC3 command silent, six sweeps clean, `devtools::test()` and `devtools::check()` re-run (results in the work log).

