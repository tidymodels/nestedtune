# M097: The Differences sections render each heading's paragraph whole and one list per page

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — the rendered help pages that readers open
- **Branch/PR:** `m097-differences-section-rendering`

## Goal

On the grid, bayes, race and sim-anneal help pages, the "Differences from calling ... directly" section renders every sentence inside the paragraph of the run-in heading it continues, renders the "Passed through" slots as one list followed by prose, and keeps each shared text in one `man-roxygen/` template.

## Scope

**In:** two templates take an optional tail sentence. They are `man-roxygen/differences-forced.R` and `differences-settable.R`. The tail arrives through one inline brew expression on a `#'` line. The four pages move their orphan sentences into `@templateVar FORCED_TAIL` or `SETTABLE_TAIL`. They drop the `@section` re-open lines those sentences needed. `differences-passed-shared.R` becomes a closing paragraph after the page's own list. A regression test renders the pages and asserts the structure.

**Out:** the doubled blank lines at each merge boundary in the Rd source. Measured at `63c449f`: `tools::Rd2txt()`, `tools::Rd2HTML()` and pkgdown's renderer all collapse them. No reader sees a gap. Nothing in this repo changes how roxygen joins merged sections. Dropped at the plan gate, 2026-09-15. A NEWS bullet is also out. The warts came in with M96 inside the current development version, and no release shipped them. M96's bullet already describes the pages as they will read (plan gate, 2026-09-15). Passing a page's bullets through a template variable is out. Roxygen converts a `@templateVar` value's markdown to Rd before substitution, so merging lists needs string surgery on Rd markup. The work log records that rejection. The other candidate rows on the help pages, such as the `#91` human pass, stay where they are.

## Acceptance criteria

The rendering of a page is the text that `tools::Rd2txt(rd, options = list(underline_titles = FALSE))` prints under `options(useFancyQuotes = FALSE)`, where `rd` is the page's object in `tools::Rd_db()`. A paragraph is a run of consecutive non-blank lines. The lines are joined with single spaces before any search. Anchors carry no backticks, because `\code{}` renders as plain single quotes.

- [ ] AC1: In the rendering of `man/nested_tune_grid.Rd`, inside the "Differences from calling tune directly" section, the paragraph that contains "Forced:" also contains "Leaving parallelism to a caller puts two pools in contention."
- [ ] AC2: In the rendering of `man/nested_tune_bayes.Rd` (section "Differences from calling tune directly"), `man/nested_tune_race.Rd` and `man/nested_tune_sim_anneal.Rd` (section "Differences from calling finetune directly"), the paragraph that contains "Settable as its own argument:" also contains the page's anchor. On bayes the anchor is "are arguments of 'tune_bayes()'". On race it is "'grid' and 'eval_time' are the racing functions' own arguments". On sim-anneal it is "are arguments of 'tune_sim_anneal()'".
- [ ] AC3: In the parsed Rd of each of those three pages, the Differences section holds exactly one `\itemize` element, and the text of that element does not contain "behave as the grid page describes". In the rendering of each, the paragraph that contains "behave as the grid page describes" lies after the section's last bullet line. A bullet line begins, after leading spaces, with U+2022.
- [ ] AC4: Every file that `ls man-roxygen/*.R` lists consists solely of lines that begin with `#'`. So `benchmarks/sweep-prose.R`'s roxygen reader and M096's duplicate-line command each read a template as one roxygen block.
- [ ] AC5: M096's duplicate-line command, run from the repo root at the branch head, prints nothing and exits 0. The command is in the Decisions section of `git show 66f1cfa:cairn/milestones/M096-help-inherits-tune-params.md`. Over the six tag kinds it keeps in `R/*.R` and `man-roxygen/*.R`, no prose line of 12 or more words appears in two or more roxygen blocks.
- [ ] AC6: On a tree with no uncommitted changes at the branch head, `Rscript -e 'devtools::document()'` leaves it so, `Rscript -e 'devtools::test()'` passes, and every command that `Rscript benchmarks/sweep-prose.R --list-gating` prints exits 0.
- [ ] AC7: At the branch head, `git diff --name-only main -- man/` reports exactly `man/nested_tune_grid.Rd`, `man/nested_tune_bayes.Rd`, `man/nested_tune_race.Rd` and `man/nested_tune_sim_anneal.Rd`. The Differences section of `man/nested_tune_grid.Rd` holds no `\itemize` element in the parsed Rd, as at `main`.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T1, T3
- AC4 → T2, T3
- AC5 → T4
- AC6 → T4
- AC7 → T4

## Tasks

- [x] T1: Write `tests/testthat/test-help-structure.R`. It asserts AC1, AC2 and AC3 as the criteria define them. Pages come from `tools::Rd_db("nestedtune")` when the package is installed (R CMD check), else from `tools::Rd_db(dir = <source root>)` under `devtools::test()`. Section text comes from `tools::Rd2txt()` with the stated options. `\itemize` elements are counted on the parsed section. Run it against today's `man/` and record it red for the stated reason, which is a paragraph or count assertion and never an error in the lookup.
- [x] T2: Add a last line to `man-roxygen/differences-forced.R`: `#' <%= if (exists("FORCED_TAIL", inherits = FALSE)) FORCED_TAIL else "" %>`. Add the same line with `SETTABLE_TAIL` to `differences-settable.R`. The names differ because a `@templateVar` is block-scoped and last-wins. Move grid's sentence (`R/nested-tune-grid.R:379-380`) into `@templateVar FORCED_TAIL`. Move the three "arguments of" paragraphs (`R/nested-tune-bayes.R:98-101`, `R/nested-tune-race.R:85-88`, `R/nested-tune-sim-anneal.R:91-94`) into `@templateVar SETTABLE_TAIL`, each on one roxygen line. Delete the `@section` re-open lines and blank lines they needed.
- [x] T3: Rewrite `man-roxygen/differences-passed-shared.R` as a paragraph. It says that `pkgs`, `parallel_over` and `workflow_size` also pass through and behave as the grid page describes, and that `parallel_over` changes the numbers a stochastic engine produces even at `allow_par = FALSE`. Keep the three use sites where they are, after each page's list.
- [ ] T4: Run `Rscript -e 'devtools::document()'`, `devtools::test()` (T1 green), every `--list-gating` sweep, the M096 duplicate-line command, and `git diff --name-only main -- man/`. Render the four pages with `tools::Rd2txt()`. Summarize the paragraph and list evidence in the work log for review.

## Work log

- 2026-09-15: created by /milestone-plan from the candidate row M96's review added (diff-bug findings 7 and 8).
- 2026-09-15: criteria audit ran in full mode with a fresh [O] reader, two passes. Pass 1 returned nine findings: the "..." section anchor matched no page, paragraph checks bound Rd source while T1 read parsed Rd, the duplicate-line gloss quantified over prose the command does not read, AC4 asserted a property the sweep has by construction, no criterion bound the rendered reading, the untouched pages were unstated, and AC5/AC6 bind instruments. Pass 2 on the revised set returned four: the "passed through" anchor wraps across rendered lines, the bullet glyph was unnamed, the tail anchors had lost the function names, AC7 sampled two files from an open domain. All fixed as the criteria now read. AC5 and AC6 stay: AC6 is the profile's mandated verify criterion and AC5 preserves M96's deliverable.
- 2026-09-15: plan gate chose a closing paragraph for the shared "passed through" text over passing each page's bullets through a template variable, because roxygen converts a variable's markdown to Rd before substitution and one list then needs string surgery on Rd markup. Falsified by a roxygen release that substitutes variables before the markdown pass.
- 2026-09-15: plan gate chose an inline brew expression on a `#'` line for the optional tail over bare `<% if %>` lines, because a line without `#'` ends the roxygen block for `benchmarks/sweep-prose.R` and the M096 command and splits one template into two blocks. Falsified by either reader gaining a brew-aware line skip.
- 2026-09-15: plan gate chose a new testthat file over a prose-sweep mode, because a rendering check widens a checker M84 and M89 already hardened. Falsified by the sweep growing a renderer of its own for another reason.
- 2026-09-15: plan gate dropped the doubled blank lines from scope on the measurement that every renderer collapses them. Falsified by a renderer in use here (pkgdown, `Rd2HTML`, `Rd2txt`) starting to show them.
- 2026-09-15: /milestone-implement started. Branch cut from the pushed `main` at `df032a5`. The plan left nothing open, so no question gate.
- 2026-09-15 (T1): `tests/testthat/test-help-structure.R` written. Against `man/` at `df032a5` it fails ten times: the grid forced paragraph lacks the contention sentence, the three settable paragraphs lack their tails, the three sections hold two `\itemize` elements, and the shared paragraph starts on the last bullet line. No lookup error.
- 2026-09-15 (T2): tail line added to both templates; grid's sentence moved to `FORCED_TAIL`, the three "arguments of" paragraphs to `SETTABLE_TAIL`, their `@section` re-open lines dropped. `document()` rewrote the four pages only. The test's AC1 and AC2 assertions pass, its six AC3 assertions stay red for T3. Sweeps `--plain` and `--roxygen --plain` clean, M096's duplicate-line command silent at exit 0.
- 2026-09-15 (T3): `differences-passed-shared.R` rewritten as a closing paragraph. `document()` rewrote the bayes, race and sim-anneal pages. `test-help-structure.R` passes all 24 assertions. The three sections each hold one `\itemize`, grid none. Both sweeps and the duplicate-line command clean.
- 2026-09-15: claim audit: 14 claims read, 2 corrected — tests/testthat/test-help-structure.R (the header said all four sections hold one list, and the section-lines comment said the lines start at the title line; both comments now match the code, re-read once by the same [O] reader as borne out).

## Decisions

## Review
