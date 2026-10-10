# M142: The grid help page, the main guide and the README read like tune's

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP3, GP1
- **Resolves:** #91 partial
- **Surface tier:** user-facing — the help page, guide and README every user reads first
- **Branch/PR:** m142-tune-style-pilot

## Goal

Rewrite `?nested_tune_grid`, `vignettes/nested-cv.Rmd` and the README opening to the length, structure and voice of tune's help pages and the tidymodels.org articles. This pilot sets the target for M143, M144 and M145.

## Scope

**In:**

- The roxygen in `R/nested-tune-grid.R` and the `man-roxygen/` templates it uses. A template change reaches the five sibling pages too, and those pages are accepted as they then render.
- `vignettes/nested-cv.Rmd`.
- The `README.Rmd` prose before and around its two tables, re-knit.
- `benchmarks/doc-profile.R`, a new measuring script.
- `cairn/references/tune-docs-comparison.md`, updated with the script's figures.
- Tests that read help text, rewritten to the new pages. The slot rules in `test-control-slots.R` stay as they are.

**Out:**

- The other help pages' own roxygen: M143 takes the loop pages, the final fit and `nested_resamples()`. M144 takes the reader pages.
- The other four guides go to M145.
- The README's two support tables stay (D-095, D-110). Only the prose around them changes.
- The maintainers' human pass stays on the #91 candidate row.
- A sweep mode for the new measures is not planned. `doc-profile.R` reports and does not gate.

**Target**, from the comparison note. A help page says what the function computes in one or two sentences. It gives each argument as a noun phrase plus a hint. Its Details keep only what a user decides or needs to read the result. Refusal lists, condition class names, implementation mechanics (seed arithmetic, serialization, vctrs dispatch), literature arguments and test inventories leave the page. An error message carries its own reason. A guide opens by saying what nested resampling is. It narrates one worked example with "we", in short paragraphs. The word "procedure" is glossed once on a page and not repeated as a slogan.

## Acceptance criteria

- [x] AC1: On the rendered `?nested_tune_grid`, the Description is at most 40 words. The page's prose is at most 1.3 times the prose of tune's `?tune_grid`. `Rscript benchmarks/doc-profile.R --tune` reports all three figures at the merge head.
- [x] AC2: `grep -n -E 'nestedtune_[a-z_]+|sample\.int|serializ|dplyr_reconstruct|vec_restore|orchestrator|sibling|Stone,? (M\. )?\(1974' man/nested_tune_grid.Rd` prints nothing at the merge head.
- [x] AC3: `tests/testthat/test-control-slots.R` passes at the merge head. Its slot rules are unchanged from the branch point: the slot names come from tune's `formals()`, and each slot sits under exactly one of the seven headings of the page's Differences section (GP1).
- [x] AC4: For `vignettes/nested-cv.Rmd`, `doc-profile.R` reports at most 75% of the page's branch-point prose words. Its mean words per paragraph are at most the largest mean among the comparator copies T2 fetches. It counts no sentence that opens with "You" or "Your". `grep -n -E 'error = TRUE|Random\.seed' vignettes/nested-cv.Rmd` prints nothing.
- [x] AC5: The `README.Rmd` prose between the title heading and `## Installation` is at most 80 words. Both support tables keep every row and cell they hold at the branch point.
- [x] AC6: In the prose of `nested-cv.Rmd` and of `README.Rmd`, `doc-profile.R` counts at most 2 coined terms on each page.
- [x] AC7: In `nested-cv.Rmd` and in `?nested_tune_grid`, at least one sentence says that the nested estimate describes the tuning procedure and not the deployed model. It also says that the nested estimate is the number to report for a model refit by `nested_final_fit()` (IP3). Review quotes each sentence with its line.
- [x] AC8: The verify slot is clean. `devtools::document()` leaves no diff. `devtools::test()` passes, and `devtools::check()` gives 0 errors and 0 warnings. Every gating prose sweep prints clean, and `air format --check .` is clean. README.md matches a fresh knit of README.Rmd.

## Coverage

- AC1 → T1, T3
- AC2 → T3
- AC3 → T3, T4
- AC4 → T1, T2, T5
- AC5 → T6
- AC6 → T1, T5, T6
- AC7 → T3, T5
- AC8 → T4, T7

## Tasks

- [x] T1: Write `benchmarks/doc-profile.R`, with these definitions. Rd prose is the text of `\description`, `\details`, `\value`, every `\section`, `\seealso`, and each argument's text without its label. `\references` is not prose. A word is a whitespace token, and a `\code{}` or backtick span is one word. Rmd prose, paragraphs and sentences follow the `sweep-prose.R` reader, without tables and list items. A coined term matches `\b([Rr]ecord(s|ed|ing)?|[Rr]efus\w*|orchestrators?|siblings?)\b`. A "You" opener is a prose sentence whose first token is `You` or `Your`. With `--tune`, the script also reads the installed tune and finetune help. With `--pages`, it reads the named Rmd or md files. Show each measure on one planted page before you trust it.
- [x] T2: Fetch the comparator pages at a pinned commit into the gitignored `cairn/references/sources/` shelf: tidymodels.org `learn/work/nested-resampling`, `start/tuning`, `learn/work/tune-svm` and `learn/work/bayes-opt`, and tune's `vignettes/tune.Rmd`. Run the script on them and on this package at the branch point. Add the figures, the commit shas and the date to `cairn/references/tune-docs-comparison.md`.
- [x] T3: Rewrite the roxygen in `R/nested-tune-grid.R` to the target. Write the Description in one or two sentences and the arguments as noun phrases. Keep these in Details: the two loops, the nested designs D-085 claims (a short list), and reproducibility in two sentences (IP2). Add parallel use in a short paragraph and the IP3 sentence. Keep the seven Differences headings, each with one or two sentences. Put the result's columns in Value. Before you move text to another page, make sure that the page does not already say it.
- [x] T4: Rewrite the `man-roxygen/differences-*.R` templates to the short form and re-render the five sibling pages. Rewrite the text-matching lines of tests that read help text, and keep the slot rules of `test-control-slots.R`.
- [x] T5: Rewrite `vignettes/nested-cv.Rmd`. Open with what nested resampling is, and narrate the worked example with "we". Drop the roadmap paragraph, the metric-order aside, the Reproducibility section and the refusal chunk. Keep the write-up short, and keep the link to `estimate.Rmd` for the background.
- [x] T6: Rewrite the README opening into two or three sentences. Cut the prose under the tables to the definitions and pointers D-110 keeps. Re-knit.
- [x] T7: Run the verify slot and the gating sweeps. Record the `doc-profile.R` figures at the head in the comparison note, and add a NEWS bullet. At review, one fresh reader reads the three pages beside the `tune_grid` page and the tidymodels.org article. The reader reports what still reads unlike them, and the gate triages every entry (D-061).

## Work log

- 2026-10-09: created by /milestone-plan, from two read-only comparisons of `man/`, the guides and README against tune 2.1.0, finetune 1.3.0 and tidymodels.org (`cairn/references/tune-docs-comparison.md`).
- 2026-10-09: collision sweep. The #91 candidate row (the maintainers' human pass) stays as the remainder of `Resolves: #91 partial`. D-095 and D-110 keep both README tables, so only the prose around them changes. D-085 keeps the design claims on the grid and design pages as short lists. D-061 sets the reader-report shape. M096 cut the guides' "you" count, and this plan takes only the "You" openers. Inbox: 1 open issue (#91, slotted), 0 open PRs.
- 2026-10-09: criteria audit, full mode, fresh Opus reader: 12 findings, all fixed. Absolute word caps that the comparators fail became caps relative to tune or to the branch point. T1 now defines Rd prose, spans, the coined-term regex and the "You" opener. Comparator copies are fetched at a pinned commit (T2). The README criterion reads the prose before `## Installation`. The GP1 check is the existing `test-control-slots.R`. The Stone regex now matches the page. "Says once" became "at least one sentence, quoted at review". M144 names its six print and summary pages. M145 AC4 maps to T2, and M145 depends on M144.
- 2026-10-09: plan gate chose the tune shape (cut refusal lists, class names, mechanics, literature and test inventories) over trimming in place, because the gap is content and not sentence length; falsified by a maintainer or user asking for the cut detail back on the help pages.
- 2026-10-09: plan gate chose caps relative to tune and to the branch point over fixed word caps, because the comparators failed the fixed caps; falsified by two runs of `doc-profile.R` on one tree giving different figures.
- 2026-10-09: plan gate chose a report-only `doc-profile.R` over a new gating mode in `sweep-prose.R`, so no shipped checker is widened; falsified by a later milestone regrowing a page past its cap unseen.
- 2026-10-09: `procedure` left the coined-term list because it is the package's core concept (IP3) and the tidymodels.org nested-resampling article uses it too. Task text limits it to one gloss a page.
- 2026-10-09: the four new rows took ROADMAP to 61 lines (cap 60), so the plan commit merged the two `sweep-prose.R` candidate rows and the two pkgdown-settings rows, with no content dropped.
- 2026-10-09: question set: post the queue comment on #91 — declined, nothing written to GitHub. Help pages: tune shape. Guides: worked examples, no optimism demonstration. Voice: "we" with the plain-English sweep rules kept.
- 2026-10-09: T1 done. `benchmarks/doc-profile.R` loads `rmd_paragraphs()`, `sentences()` and their helpers from `sweep-prose.R` by parsing it, and gained `--man <dir>` so a planted page can be read. `test-doc-profile.R` pins every column on two hand-counted fixtures. A planted mutation (dropping `\code` from the one-word tags) moved the coined count from 2 to 3, which the test fails on. The branch-point `nested_tune_grid` figure is 4,960 prose words.
- 2026-10-09: T2 done. Comparators fetched to `cairn/references/sources/tune-docs/` (tidymodels.org `ed3cb150`, tune `d047fc3a`). The caps the criteria name resolve to: AC1 prose at most 2,024 (1.3 × `tune_grid` 1,557), AC4 at most 1,012 prose words (75% of 1,350) and a paragraph mean of at most 37.5 (`start/tuning`). AC6 starts at 3 coined terms on `nested-cv.Rmd` and 6 on the README.
- 2026-10-09: T3 and T4 done in one commit, because the shared templates render on the grid page. `?nested_tune_grid` went from 4,960 to 1,234 prose words, with a 36-word Description. Cut: the design-check list (each error names its cause), the per-function time-series list (`?nested_resamples` holds it, as D-095 says), the selection, result-record, operations and by-hand sections, the parallel internals, condition class names, and the Stone reference. Kept short: the three sections the bayes, race and sim-anneal pages inherit, the seven Differences headings, and one sentence on what removing a fold does. The templates `differences-forced`, `differences-refused`, `param-control-dots`, `section-reproducibility` and `section-resample-weights` were shortened, so the five sibling pages shrank too: bayes 1,528, race 1,641, sim-anneal 1,543, fit-resamples 1,282. Two text pins were rewritten to the new wording: the grid forced-paragraph test in `test-help-structure.R`, and the eval-time refusal lines in `test-eval-time.R`. `test-control-slots.R` is unchanged and passes.
- 2026-10-09: T5 done. `nested-cv.Rmd` is 652 prose words in 24 paragraphs (mean 27.2), with 0 coined terms and 0 "You" openers. It opens with what nested resampling is, narrates with "we", and drops the roadmap, the metric-order aside and Stone reference, the refusal chunks and the Reproducibility section. The seed sentence moved into the run section. The write-up is a blockquote with inline values, not a `cat(sprintf())` chunk. It knits on the installed branch. Minor amendment: `results.Rmd`, `tuners.Rmd` and `parallel.Rmd` each pointed to the removed Reproducibility section, so those three sentences now point to `?nested_tune_grid`. The rest of those pages stays for M145.
- 2026-10-09: T6 done. The README opening is 63 prose words: what the package does, and the IP3 sentence. The Refused definition and the `?nested_resamples` pointer stay (D-110). The pointer to `?nested_tune_race` for the racers' inner apparent split was dropped, because the race page states it. The README has 2 coined terms (6 at the branch point). Both tables are unchanged, and the re-knit changed only prose lines in README.md.
- 2026-10-09: claim audit: 133 claims read, 8 corrected — R/nested-tune-grid.R, R/nested-fit-resamples.R, vignettes/articles/parallel.Rmd, benchmarks/doc-profile.R. The fixes: the control reaches only the inner run, and the outer fit takes `event_level`, `save_pred` and `extract`. Integrated survival metrics read `eval_time` too. A design error can name the design rather than rows. The first metric selects only under the default rule. `.inner_metrics` holds candidates that scored. `doc-profile.R` no longer splits trailing punctuation off a `\code{}` mark, and the fixture plants that case. The broken pointers were fixed: the fit-resamples seed line now states the pinned kinds, and the parallel article no longer says the grid page lists what is sent.
- 2026-10-09: full suite: 15,493 passed, 4 failed, all from two tests that pinned removed grid-page wording. In `test-dplyr-compat.R`, the passing control now reads "returns a plain tibble". In `test-id-columns.R`, the fold-label promise is now required of NEWS alone, and the help page is held to not carrying the narrowed claim. Both files pass (156 and 311).
- 2026-10-09: T7 done. `devtools::check()` gives 0 errors, 0 warnings and 0 notes. `document()` leaves no diff, the six gating sweeps print clean, and `air` is clean. The fresh-reader report that T7 names runs at review. Status set to review.
- 2026-10-09: review pass 1: three lenses plus the T7 reader. The fix-now set landed in `25f4887a` and `6e28cd4e` and added D-115. The first fix took the README opening to 84 words, over AC5's cap. It was cut to 76 before any evidence was recorded. No criterion failed on the final head, so there was no return.
- 2026-10-09: review follow-ups routed to planned milestones, not new rows. M143 takes `orchestrator` still used on its pages, the sibling Descriptions' "honest score" and their IP3 sentence, and the `differences-passed-shared` pointer. M145 takes where a test set fits around nested resampling, and how to choose v in each loop.

## Review

spawned: diff-bug, blame-history, prior-review, and the T7 fresh reader (D-061).

Evidence, at the final branch head:

- AC1: `doc-profile.R --tune` reads `nested_tune_grid` at 1,542 prose words with a 39-word Description, and `tune::tune_grid` at 1,515. The cap is 1.3 × 1,515 = 1,969.5.
- AC2: the grep prints nothing (exit 1).
- AC3: `git diff 54ac8f31 HEAD -- tests/testthat/test-control-slots.R` is empty, and the file passes 148 checks.
- AC4: `nested-cv.Rmd` has 714 prose words against a cap of 1,012 (75% of the branch point's 1,350). Its paragraph mean is 31.0 against 37.5, the largest comparator mean (`start/tuning`). The script counts 0 "You" openers, and the grep prints nothing.
- AC5: the README prose between the title heading and `## Installation` is 76 words. A diff of the table lines against `54ac8f31` is empty.
- AC6: the script counts 0 coined terms on `nested-cv.Rmd` and 2 on `README.Rmd`.
- AC7: `R/nested-tune-grid.R:15-19` says the estimate "describes this whole procedure (tune, select, fit) and not one fitted model". It adds that the nested estimate "is the number to report for that model", meaning the one `nested_final_fit()` builds, "because the model comes from the same procedure". `vignettes/nested-cv.Rmd:148-151` says the estimate "describes the whole procedure (tune, select, fit) and not one fitted model". It adds: "It is still the number to report for the model that `nested_final_fit()` fits below". A deployed model is one fitted model, so "not one fitted model" covers "not the deployed model".
- AC8: at head `00ea69d9`, `devtools::test()` gives 15,498 passed and 0 failed. `devtools::check()` gives 0 errors, 0 warnings and 0 notes. `document()` leaves no diff, and the six gating sweeps print clean. `air format --check .` is clean, and README.md was re-knit at `6e28cd4e` with README.Rmd unchanged since. Two earlier runs failed. One was the wrapped "returns a plain tibble" pin, fixed in `00ea69d9`. The other was `test-parallel-interrupt.R:108`, the known flake on the M079 candidate row, which passed alone and in the final run.
- Gate: `cairn_validate` passes with advisories only. `document()` leaves no diff, `pkgdown::check_pkgdown()` finds no problems, and there is no new top-level file. NEWS has a bullet, and README.md is re-knit. No principle text changed, so `cairn_impact` does not apply.

Findings and dispositions:

- diff-bug #1: "Under the default selection rule" is wrong, because `one_std_err` and `pct_loss` use the first metric too — fixed 25f4887a.
- diff-bug #2: the `nested_workflow_map` `metrics` pointer named desirability text the grid page no longer holds — fixed 25f4887a, now pointing to `?selection_rule`.
- diff-bug #3: the Description read as fitting on the held-out rows — fixed 25f4887a.
- diff-bug #4: the sibling pages lost that the Bayes, race and annealing searches steer on the first metric — fixed 25f4887a, in the inherited `metrics` text.
- diff-bug #5: D-085, D-087 and D-112 say the grid page states the per-function claims — fixed by D-115.
- diff-bug #6: no remaining home for the missing per-fold timeout and the `dispatcher = FALSE` warning — fixed 25f4887a, in the parallel section.
- diff-bug #7: `test-id-columns.R` was weakened — fixed 25f4887a, with the fold-label sentence back in Value and the test requiring it again.
- diff-bug #8: `%||%` is not in base R before 4.4 — fixed 25f4887a, defined locally.
- diff-bug #9: `--file=` path handling — fixed 25f4887a (`~+~` decoded, `benchmarks/` fallback under `source()`).
- diff-bug #10: `--man` with a bad path was silent — fixed 25f4887a, now an error.
- diff-bug #11: `\if{html}{\out{}}` was counted as prose — fixed 25f4887a, with a fixture plant. `\describe`, `\enc` and `\ifelse` are rejected, false: no page uses them.
- diff-bug #12: blockquote markers were counted as words — fixed 25f4887a, with a fixture plant.
- diff-bug #13: the eval-time list dropped the non-numeric and empty cases and what passes through — fixed 25f4887a, re-pinned in `test-eval-time.R`.
- diff-bug #14: the Refused template dropped the GP1 divergence and the classes tune itself accepts — fixed 25f4887a.
- diff-bug #15: the page did not say `nested_final_fit()` reuses the control — fixed 25f4887a.
- diff-bug #16: the RNG restore was dropped — fixed 25f4887a, in the shared template.
- diff-bug #17: IP3's "why" was missing on the grid page and the README — fixed 25f4887a and 6e28cd4e.
- diff-bug #18: stale sibling pointers — the bayes pointer to result operations holds again (fixed 25f4887a). The `differences-passed-shared` pointer is a follow-up to M143.
- blame-history #1: the result-operation rules that D-032 and D-035 rely on were cut, which made a DESIGN Known issues line false — fixed 25f4887a, in Value.
- blame-history #2: the `nested-final-fit-extract.R` pointer to the removed records section — fixed 25f4887a (Value now holds the grid-versus-scored difference).
- blame-history #3: sibling pointers and Description match — the bayes pointer was fixed in 25f4887a. The Description match is a follow-up to M143.
- blame-history #4: the hand-replication recipe and the IP2 scope wording that D-011, D-016 and D-064 require were cut — fixed 25f4887a ("Reproducing one fold" section, full engine wording).
- blame-history #5: D-018's `load_all()` and stale-daemon note was cut — fixed 25f4887a.
- blame-history #6: the letter of the time-series D-entries — fixed by D-115.
- blame-history #7: dead `@inherit nested_tune_grid references` lines — fixed 25f4887a. Stone's removal was rejected as a planned change.
- blame-history #8: the write-up lost its IP3 sentence — fixed 25f4887a.
- blame-history #9: lower items. The eval-time list was fixed 25f4887a. The preprocessor refusals, the `show_best()` refusal chunk and the README opening are rejected as planned changes (the errors carry the reasons). The racers' README pointer is rejected, because the README table is scoped to `nested_tune_grid()` (D-095) and `?nested_tune_race` holds the rule.
- prior-review #1: `orchestrator` is undefined while the siblings use it — follow-up to M143, whose AC3 removes the word.
- prior-review #2: sibling pointers — fixed 25f4887a (the operations text is restored).
- prior-review #3: same as blame-history #4 — fixed 25f4887a.
- prior-review #4: the payload and workflow-environment cautions were cut — fixed 25f4887a.
- prior-review #5: unglossed `candidate` and `procedure` at first use — fixed 25f4887a (glosses on README and `nested-cv.Rmd`).
- prior-review #6: same as blame-history #9's README pointer — rejected, for the same reason.
- prior-review #7: the guide's two-sentence bias opener — rejected as a planned change (T5's definition-first opening).
- prior-review #8: test guards — fixed 25f4887a (`test-id-columns.R` and `test-eval-time.R` restored). The dead `FORCED_TAIL` branch was removed from `differences-forced.R`.
- prior-review #9: DESIGN.md Known issues line on `group_by()` — fixed 25f4887a, because the Value sentence is back.
- prior-review #10: the example setup and the sibling Descriptions. The example is rejected: it is piped since M081, and namespacing is needed because the examples attach nothing. The Descriptions are a follow-up to M143.
- reader #1: collapse the seven Differences labels — rejected, because GP1 and `test-control-slots.R` classify every slot by those headings (AC3).
- reader #2: `control` is hard to find — fixed 25f4887a ("pass `control = tune::control_grid()` here").
- reader #3: where a test set fits — follow-up to M145.
- reader #4: cut the README tables — rejected (D-095, D-110).
- reader #5: the "tested" wording and the reason for `lag` — the reason was fixed in 25f4887a. The "tested" wording is rejected, because the time-series D-entries claim tested support on purpose.
- reader #6: move the preflight option off the page — rejected, because it is a user option, and the D-018 constraints sit beside it.
- reader #7: the Value class note — rejected (D-032, D-035).
- reader #8: "selection-time" wording — fixed 25f4887a ("best inner score", optimistic on average).
- reader #9: "largely arbitrary" — fixed 25f4887a.
- reader #10: an abstract IP3 sentence — fixed 25f4887a, with the reason added.
- reader #11: the eval-time wording — fixed 25f4887a.
- reader #12: the `mtcars` sentence placement and choosing v — the placement was fixed in 25f4887a. Choosing v is a follow-up to M145.
- reader #13: a `select` example, and dropping the seed sentence — rejected (`?selection_rule` has examples, and the seed sentence is the guide's one IP2 line).
- reader #14: vague engine wording — fixed 25f4887a.
- reader #15: "This page documents what they share" — rejected, because it tells the reader that the shared sections apply to all six functions.
- reader #16: name the extractor — fixed 25f4887a.
- reader #17: the README never says why — fixed 25f4887a and 6e28cd4e.
- reader, missing items: a final fit in the help example, `collect_metrics()` columns on this page, a Contributing section, a CRAN line — rejected. The guide shows the final fit, `?collect_metrics.nested_results` holds the columns, and the package is not on CRAN, so the pak line is the install path.
