# M084: The guides and README read on one pass for a tune_grid user

- **Status:** planned
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP3
- **Resolves:** #91 partial
- **Surface tier:** user-facing — the vignettes, the parallel article and the README
- **Branch/PR:** —

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

- [ ] T1: Write `benchmarks/sweep-prose.R`: the AC1 extraction and sentence splitter over the six pages, printing over-cap sentences as `file:line`; a `--terms` mode printing each page's first occurrence of the AC2 words; a `--roxygen` mode for M85 over `#'` lines with the tag rules M85 AC1 states. Header comment states both modes. Run it on the current pages and record the hit counts in the work log.
- [ ] T2: Rewrite `estimate.Rmd`'s eight listed paragraphs (survey §1) and every sentence the script flags; the IP3 paragraph kept; "procedure" set up where the page first uses it. (RB tripwire: ip-touching)
- [ ] T3: Rewrite `nested-cv.Rmd`'s three listed paragraphs (survey §4) and flagged sentences; the intro at lines 17-33 untouched; the IP3 paragraph kept. (RB tripwire: ip-touching)
- [ ] T4: Rewrite `results.Rmd`'s nine listed paragraphs (survey §2) and flagged sentences; "reader", "procedure" and "record" set up in the page's own terms before use.
- [ ] T5: Rewrite `tuners.Rmd`'s nine listed paragraphs (survey §3) and flagged sentences; "orchestrator" replaced or set up.
- [ ] T6: Rewrite `articles/parallel.Rmd`'s opening paragraph (survey §5) and `README.Rmd`'s opening paragraph; re-knit `README.md`.
- [ ] T7: Spawn the AC3 reader with the standard, the six pages and the survey list; fix every paragraph it reports; rerun until its list is empty; record each run's count in the work log.
- [ ] T8: Run the AC1, AC2 and AC4 commands, `pkgdown::build_articles()`, `devtools::build_readme()` twice, `devtools::check()`; NEWS bullet.

## Work log

- 2026-09-10: created by /milestone-plan. Survey: 30 of 102 vignette paragraphs and the README's opening paragraph fail the standard (`surveys/M084-survey.md`); M081 and M082 measured only word caps, banned words and a "you" cap, none a readability judgment.
- 2026-09-10: criteria audit ran in full mode; returned nine findings: six fixed (YAML body filter and list lines in AC1; abbreviations joined before splitting; `design` and `record` dropped from AC2 as ordinary English; M85's tag rule inverted to an included list; AC3 rewritten as a property of the prose with the survey list as the probe set; the standard's clause (d) bound to AC2's words), two posed at the gate (the "you" cap, M85's term-setup site), one a stale citation removed.
- 2026-09-10: plan gate chose dropping M082's `you|your <= 5` cap over keeping it, because the accepted intro uses second person seven times and the impersonal sentences the cap produced are the ones the user rejected; falsified by a maintainer's read finding the second-person pages sound machine-written again (issue #91's original note).
- 2026-09-10: plan gate chose two milestones (guides, then help pages) over one, because the two surfaces total 137 failing paragraphs over 26 files, past the sizing tripwire, and the help pages should inherit the term choices the guides settle; falsified by the help-page rewrite needing terms the guides never set up.
- 2026-09-10: plan gate chose leaving NEWS out over adding it, because its 77 bullets are consolidated at the first release anyway; falsified by a release walk that keeps the bullets as they are.
