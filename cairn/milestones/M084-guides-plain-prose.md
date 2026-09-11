# M084: The guides and README read on one pass for a tune_grid user

- **Status:** in-progress
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP3
- **Resolves:** #91 partial
- **Surface tier:** user-facing — the vignettes, the parallel article and the README
- **Branch/PR:** `m084-guides-plain-prose`

## Goal

Rewrite every paragraph of the four guides, the parallel article and the README that a tidymodels user who has run `tune_grid()` cannot follow on one read, to the standard the accepted intro of `vignettes/nested-cv.Rmd` (lines 17-33 at `0d8611e`) sets.

## Scope

**The standard.** The reader has run `tune_grid()` and never nested. A paragraph passes when it (a) leads with what the reader does or wants, (b) states the problem before the term for it, (c) keeps one idea per sentence, (d) uses none of the words AC2 names before the page sets it up, and (e) has no sentence over 30 words.

**In:** the 30 paragraphs `surveys/M084-survey.md` lists and any other paragraph the AC3 reader finds; the README's opening paragraph; a prose sweep script `benchmarks/sweep-prose.R` (sentence cap, first-use locator); dropping M082's "you" cap; a NEWS bullet.

**Out:** the help pages → M85 (depends on this one so the term choices settle first). `NEWS.md`'s 77 bullets → candidate row, absorbed by the first release's NEWS consolidation. M082's banned-word grep, word caps, heading rule and idiom sweep stay as they are (AC4). New content, sections or pages → none; this milestone rewrites what is there.

## Acceptance criteria

- [ ] AC1: No prose sentence on `vignettes/nested-cv.Rmd`, `estimate.Rmd`, `tuners.Rmd`, `results.Rmd`, `articles/parallel.Rmd` or `README.Rmd` exceeds 30 words. Prose is what is left after the YAML header (everything between the first two `^---$` lines), fenced chunks, HTML comment lines, heading lines and list-item lines (`^\s*[-*] `) are dropped and backtick spans and inline `r` spans are removed; `et al.`, `e.g.`, `i.e.` and `vs.` are joined before splitting at `.`, `?` or `!` followed by whitespace or end of text. Evidence: `Rscript benchmarks/sweep-prose.R` prints every hit as `file:line` and exits 0.
- [ ] AC2: On each of the six pages, each of the words `procedure`, `orchestrator` and `candidate` (whole word, any case, plural included) and, on `results.Rmd`, `reader` either does not appear in prose or first appears in a sentence that says what it names on that page. Evidence: the script's `--terms` mode prints each page's first occurrence per word as `file:line`, and each printed sentence is read.
- [ ] AC3: Every prose paragraph of the six pages meets (a)-(e). Verified by a reader with no authorship of the text, given the standard and the six pages, reporting every paragraph it cannot follow on one read; the 30 paragraphs `surveys/M084-survey.md` lists are the minimum probe set, read first, and the reader's list is empty.
- [ ] AC4: M082's checks minus its "you" cap: over the AC1 prose `grep -nE -- '--|—|contract|invariant|rests on'` returns no hit; `Rscript benchmarks/sweep-vignette-idioms.R` exits 0; the word counts by `awk '/^```/{f=!f;next} !f' <file> | wc -w` are at most 1500 / 1400 / 1500 / 1500 / 700 / 350 in the AC1 file order; every heading is a noun phrase.
- [ ] AC5: `nested-cv.Rmd` and `estimate.Rmd` each keep one paragraph saying the estimate describes the tune-and-fit procedure, that it is the number to report, and that the final model has no performance number of its own (IP3's documentation obligation). (RB tripwire: ip-touching)
- [ ] AC6: `pkgdown::build_articles()` renders every page without error, a second `devtools::build_readme()` leaves `README.md` unchanged, and `devtools::check()` reports 0 errors, 0 warnings, 0 notes.

## Coverage

- AC1 → T1, T2, T3, T4, T5, T6
- AC2 → T1, T2, T3, T4, T5, T6
- AC3 → T2, T3, T4, T5, T6, T7
- AC4 → T2, T3, T4, T5, T6, T8
- AC5 → T2, T3
- AC6 → T8

## Tasks

- [x] T1: Write `benchmarks/sweep-prose.R`: the AC1 extraction and sentence splitter over the six pages, printing over-cap sentences as `file:line`; a `--terms` mode printing each page's first occurrence of the AC2 words; a `--roxygen` mode for M85 over `#'` lines with the tag rules M85 AC1 states. Header comment states both modes. Run it on the current pages and record the hit counts in the work log.
- [x] T2: Rewrite `estimate.Rmd`'s eight listed paragraphs (survey §1) and every sentence the script flags; the IP3 paragraph kept; "procedure" set up where the page first uses it. (RB tripwire: ip-touching)
- [x] T3: Rewrite `nested-cv.Rmd`'s three listed paragraphs (survey §4) and flagged sentences; the intro at lines 17-33 untouched except one word deleted from its 31-word sentence to meet AC1; the IP3 paragraph kept. (RB tripwire: ip-touching)
- [x] T4: Rewrite `results.Rmd`'s nine listed paragraphs (survey §2) and flagged sentences; "reader", "procedure" and "record" set up in the page's own terms before use.
- [x] T5: Rewrite `tuners.Rmd`'s nine listed paragraphs (survey §3) and flagged sentences; "orchestrator" replaced or set up.
- [ ] T6: Rewrite `articles/parallel.Rmd`'s opening paragraph (survey §5) and `README.Rmd`'s opening paragraph; re-knit `README.md`.
- [ ] T7: Spawn the AC3 reader with the standard, the six pages and the survey list; fix every paragraph it reports; rerun until its list is empty; record each run's count in the work log.
- [ ] T8: Run the AC1, AC2 and AC4 commands, `pkgdown::build_articles()`, `devtools::build_readme()` twice, `devtools::check()`; NEWS bullet.

## Work log

- 2026-09-10: created by /milestone-plan. Survey: 30 of 102 vignette paragraphs and the README's opening paragraph fail the standard (`surveys/M084-survey.md`); M081 and M082 measured only word caps, banned words and a "you" cap, none a readability judgment.
- 2026-09-10: criteria audit ran in full mode; returned nine findings: six fixed (YAML body filter and list lines in AC1; abbreviations joined before splitting; `design` and `record` dropped from AC2 as ordinary English; M85's tag rule inverted to an included list; AC3 rewritten as a property of the prose with the survey list as the probe set; the standard's clause (d) bound to AC2's words), two posed at the gate (the "you" cap, M85's term-setup site), one a stale citation removed.
- 2026-09-10: plan gate chose dropping M082's `you|your <= 5` cap over keeping it, because the accepted intro uses second person seven times and the impersonal sentences the cap produced are the ones the user rejected; falsified by a maintainer's read finding the second-person pages sound machine-written again (issue #91's original note).
- 2026-09-10: plan gate chose two milestones (guides, then help pages) over one, because the two surfaces total 137 failing paragraphs over 26 files, past the sizing tripwire, and the help pages should inherit the term choices the guides settle; falsified by the help-page rewrite needing terms the guides never set up.
- 2026-09-10: plan gate chose leaving NEWS out over adding it, because its 77 bullets are consolidated at the first release anyway; falsified by a release walk that keeps the bullets as they are.
- 2026-09-10: /milestone-implement started; branch `m084-guides-plain-prose` cut from pushed `main` at `2fc728f`.
- 2026-09-10: implement gate chose replacing `orchestrator` with plain words (the function name, or "the tuning functions") over defining it per page, so M85 inherits no new term; falsified by the help pages needing one noun for the five functions.
- 2026-09-10: implement gate chose splitting the 36-word sentence of `estimate.Rmd`'s IP3 paragraph in place, the three claims kept as written, over a Fable brief; the split is shown verbatim at the T2 checkpoint.
- 2026-09-10: T1 done. `benchmarks/sweep-prose.R` on the pages at `2fc728f`: 45 sentences over 30 words (nested-cv 5, estimate 15, tuners 10, results 10, parallel 4, README 1); `--terms` finds `orchestrator` cold on tuners:350 only, `reader` cold on results:20; `--roxygen`: 142 hits for M85. Spans are stripped over the joined paragraph, since a backtick span can cross a line break.
- 2026-09-10: T2 done. `estimate.Rmd`: 15 over-cap sentences to 0, 1396 words under the 1400 cap; `candidate` and `procedure` defined in their first sentences; the IP3 paragraph's 36-word sentence split into two with the three claims kept word for word; the Tibshirani figures re-read against `references/tibshirani2009.md` before rewording.
- 2026-09-10: T3 done. `nested-cv.Rmd`: 5 over-cap sentences to 0, 1257 words; minor amendment to T3's text: the accepted intro's third sentence was 31 words, so "which" is deleted from it and nothing else in lines 17-33 changes; `candidate` glossed at its first use; the IP3 paragraph (lines 30-33) untouched.
- 2026-09-10: T4 done. `results.Rmd`: 10 over-cap sentences to 0, 1341 words; `reader` defined in the intro as the functions that turn columns into tables, `procedure` as the record `extract_procedure()` returns (its contents read from that function's roxygen), `event_level`'s gloss read from `nested_fit_resamples()`'s roxygen; the failed-fold paragraph split in two.
- 2026-09-10: T5 done. `tuners.Rmd`: 10 over-cap sentences to 0, 1280 words; `orchestrator` replaced by "one of the tuning functions above" (its only use); `procedure` glossed as the resample-tune-select-fit sequence and `candidate` as the settings in the grid at their first uses; "the record says no tuning ran" now names `extract_procedure()`, which the chunk below it calls.
