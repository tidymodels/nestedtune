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

- [x] AC1: No prose sentence on `vignettes/nested-cv.Rmd`, `estimate.Rmd`, `tuners.Rmd`, `results.Rmd`, `articles/parallel.Rmd` or `README.Rmd` exceeds 30 words. Prose is what is left after the YAML header (everything between the first two `^---$` lines), fenced chunks, HTML comment lines, heading lines and list-item lines (`^\s*[-*] `) are dropped and backtick spans and inline `r` spans are removed; `et al.`, `e.g.`, `i.e.` and `vs.` are joined before splitting at `.`, `?` or `!` followed by whitespace or end of text. Evidence: `Rscript benchmarks/sweep-prose.R` prints every hit as `file:line` and exits 0.
- [x] AC2: On each of the six pages, each of the words `procedure`, `orchestrator` and `candidate` (whole word, any case, plural included) and, on `results.Rmd`, `reader` either does not appear in prose or first appears in a sentence that says what it names on that page. Evidence: the script's `--terms` mode prints each page's first occurrence per word as `file:line`, and each printed sentence is read.
- [ ] AC3: Every prose paragraph of the six pages meets (a)-(e). Verified by a reader with no authorship of the text, given the standard and the six pages, reporting every paragraph it cannot follow on one read; the 30 paragraphs `surveys/M084-survey.md` lists are the minimum probe set, read first, and the reader's list is empty.
- [x] AC4: M082's checks minus its "you" cap: over the AC1 prose `grep -nE -- '--|—|contract|invariant|rests on'` returns no hit; `Rscript benchmarks/sweep-vignette-idioms.R` exits 0; the word counts by `awk '/^```/{f=!f;next} !f' <file> | wc -w` are at most 1500 / 1400 / 1500 / 1500 / 700 / 350 in the AC1 file order; every heading is a noun phrase.
- [x] AC5: `nested-cv.Rmd` and `estimate.Rmd` each keep one paragraph saying the estimate describes the tune-and-fit procedure, that it is the number to report, and that the final model has no performance number of its own (IP3's documentation obligation). (RB tripwire: ip-touching)
- [x] AC6: `pkgdown::build_articles()` renders every page without error, a second `devtools::build_readme()` leaves `README.md` unchanged, and `devtools::check()` reports 0 errors, 0 warnings, 0 notes.

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
- [x] T6: Rewrite `articles/parallel.Rmd`'s opening paragraph (survey §5) and `README.Rmd`'s opening paragraph; re-knit `README.md`.
- [x] T7: Spawn the AC3 reader with the standard, the six pages and the survey list; fix every paragraph it reports; rerun until its list is empty; record each run's count in the work log.
- [x] T8: Run the AC1, AC2 and AC4 commands, `pkgdown::build_articles()`, `devtools::build_readme()` twice, `devtools::check()`; NEWS bullet.

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
- 2026-09-10: T6 done. `articles/parallel.Rmd`: 4 over-cap sentences to 0, 543 words, daemons glossed as separate R processes at first use; `README.Rmd`: the 35-word opening sentence split into three, 209 words, `README.md` re-knit (7 lines changed, all in that paragraph). The sweep is clean over all six pages: 45 hits to 0; word counts 1257 / 1396 / 1282 / 1341 / 543 / 209 against caps 1500 / 1400 / 1500 / 1500 / 700 / 350.
- 2026-09-10: T7: nine fresh [O] readers, each given the standard, the six pages and the survey list; paragraphs reported per run 15, 2, 5, 8, 4, 3, 3, 1, 2, every one fixed in the same turn (39 in all: sentence splits, glosses for `candidate` on results and parallel, "flat" and "reader" replaced on estimate and tuners, the Tibshirani figures restated in points off the true 0.5, the "four things it is not" list reordered). The sweep stays clean after every run.
- 2026-09-10: user chose stopping T7 after run 9 over a tenth run, an unbounded loop, or amending AC3 to a threshold: fresh readers report one to three new first-read stumbles per run and the count does not converge, review's own reader decides AC3, and a non-empty list there returns as a defect. AC3's text is unchanged.
- 2026-09-10: claim audit: 63 claims read, 2 corrected — vignettes/results.Rmd (the wholly-failed-run sentence named `summary()` among the refusing readers; now lists the six that refuse), vignettes/tuners.Rmd ("every function that reads a result answers on the baseline" omitted the parameters plot's refusal; now names it). The re-read ran in a fresh [O] reader rather than the same one, since agent continuation is disabled in this session; both corrected lines hold.
- 2026-09-10: T8 done on the final tree (`a58cf6a` plus nothing uncommitted): sweep clean and exit 0; `--terms` first uses all glossing sentences; the AC4 grep hits only the README's three HTML comment lines; idiom sweep clean; word counts 1272 / 1389 / 1293 / 1357 / 556 / 218; every heading a noun phrase; `pkgdown::build_articles()` exit 0 (pandoc deprecation warnings only); a second `devtools::build_readme()` left `README.md` unchanged; `devtools::check()` 0 errors, 0 warnings, 0 notes in 9m 21s. NEWS bullet added. Status set to review.
- 2026-09-11: /milestone-review ran on `fb85d5b`; AC1, AC2, AC4, AC5, AC6 verified and the consistency gate passed; AC3 failed: review's fresh reader listed ten paragraphs (the Review section names each), and the 2026-09-10 decision made a non-empty list a defect return. Defect return 1 of this milestone. Status back to in-progress; the three review lenses' findings are logged in the Review section for the next pass's triage.

## Review

Evidence gathered 2026-09-11 on `fb85d5b`, the branch head, with `origin/main` still at the branch point `2fc728f` (no sync needed, no PR open).

- AC1: `Rscript benchmarks/sweep-prose.R` printed `clean` and exited 0. Verified.
- AC2: `--terms` printed twelve first uses (procedure and candidate on all six pages, reader on results.Rmd) and each printed sentence glosses the word in the page's own terms; `orchestrator` matches nothing on any of the six pages (`grep -niE '\borchestrators?\b'` exit 1). Verified.
- AC4: the grep over the raw files hits only YAML fences and README HTML comments, none of which is AC1 prose; `sweep-vignette-idioms.R` printed `clean`, exit 0; word counts 1272 / 1389 / 1302 / 1359 / 556 / 218 against caps 1500 / 1400 / 1500 / 1500 / 700 / 350; the 33 headings read and each is a noun phrase. Verified.
- AC5: `nested-cv.Rmd` lines 30-33 and `estimate.Rmd` lines 43-47 each state the three claims: the number describes the tune-and-fit steps, it is the number to report or put in a write-up, and the final model has no score or performance number of its own. Verified.
- AC6: `pkgdown::build_articles()` exit 0 (pandoc `--mathml` deprecation warnings only); `devtools::build_readme()` run twice left `README.md` unchanged after each; `devtools::check()` Status: OK, 0 errors, 0 warnings, 0 notes. Verified.
- AC3: one fresh [O] reader, given the standard, the six pages and the survey list (found at `cairn/surveys/M084-survey.md`, not the `milestones/surveys/` path the file names), read 118 paragraphs (28 / 25 / 23 / 29 / 9 / 4) and reported ten. Not verified; the list is not empty. The ten, in the reader's order, most severe first:
  1. `nested-cv.Rmd:123` "That is `r nrow(grid)` candidates, each resampled": four inline-R multiplicands before the product; read twice. The reader's 33-word count includes the inline `r` spans AC1 strips, so AC1 is unaffected.
  2. `estimate.Rmd:56` "Four things it is not": the third item, a different population or sample size, denies a claim nothing raised.
  3. `estimate.Rmd:96` "Suppose you run the loop on two workflows": "that condition" points two sentences back and a difference having its own stability arrives compressed.
  4. `results.Rmd:302` "On a run with a failed fold": nine sentences switching from some-folds-failed to no-fold-completed, two function lists, lost which list governed which case.
  5. `tuners.Rmd:135` "The print notes that the folds did not search the same grid": "a vote over shared candidates" rules out something never raised (clause b).
  6. `nested-cv.Rmd:276` "The selection-time score is not an estimate of performance on anything": "whichever side of the nested estimate it lands on" assumes a comparison not yet drawn.
  7. `parallel.Rmd:17` "Nested cross-validation fits many models": opens with a property of the method, not what the reader wants (clause a); seven sentences mixing mechanism, threshold, plan and a cross-reference.
  8. `estimate.Rmd:32` "At a small sample size the noise is large": "not for which way it is off" needed a reread.
  9. `parallel.Rmd:151` "`identical()` on the outer scores": "a matter of the session rather than of the analysis" is an abstract restatement between two concrete sentences.
  10. `README.Rmd:24` opening paragraph: opens with what the package does rather than what the reader wants (clause a); the reader calls this defensible for a README.

Consistency gate: `cairn_validate.py` passed (18 `references staleness` advisories, pre-existing); no principle changed, so `cairn_impact.py` skipped; `pkgdown::check_pkgdown()` no problems; `NEWS.md` carries the bullet with no milestone number; `benchmarks` already in `.Rbuildignore`; `devtools::document()` rewrote NAMESPACE's `importFrom` lines from the multi-line form roxygen2 8.1.0 wrote at M30 to one per line, because the local roxygen2 is 8.0.0 against the 8.1.0 `DESCRIPTION` names; the branch touches no roxygen and the regeneration was reverted, so this is a tool-version artifact, not drift.

Independent review, three lenses, findings ranked by each lens and logged here for triage at the next pass's gate (the review returned before its gate):
- [S] blame-history: no findings; cross-links, the IP3 paragraphs, and the Tibshirani figures (0.384 as 11.6 points, 0.475 as 2.5, 0.498 as 0.2 off 0.5) checked against the archives and `references/tibshirani2009.md`.
- [S] prior-review-comments: no findings; M082's fixed items on all seven files preserved; the probe found one human inline comment (topepo, PR #30, on `pkgdown.yaml`, untouched), no walk.
- [O] diff-bug, fourteen findings, most severe first: O1 `tuners.Rmd:320` "the functions that read a result answer on the baseline, except the parameters plot" overclaims: `collect_predictions()` and `collect_extracts()` refuse under the default control (`check_column_saved()`, `R/nested-results-collect.R:246,261`). O2 `tuners.Rmd:354-355` says `fn` takes one of the five tuning functions above, but `check_map_fn()` accepts six including `nested_fit_resamples` (`R/checks.R:1459-1466`); introduced by the orchestrator replacement. O3 `sweep-prose.R:175-187` reports `file:line` one line low for every sentence after a backtick span that crosses a line break (reproduced on a synthetic page); hits and exit code unaffected. O4 `results.Rmd:307-311` lists six refusing readers; eight call `check_any_completed()`, `collect_predictions()` and `collect_extracts()` included. O5 `nested-cv.Rmd:23` `procedure` first appears in "scoring the whole tuning procedure rather than the winner alone", inside the frozen intro; the reviewer reads that as not saying what it names while the NEWS bullet claims every page does. O6 `results.Rmd:303-307` omits `autoplot()` from the functions that warn on a partial run (`warn_partial_summary`, `R/nested-results-plot.R:538,741`); pre-existing. O7 `README.Rmd:27-28` "every step above: resample, tune, select, fit" back-references steps the paragraph above names differently. O8 `NEWS.md:3-8` the new bullet restates the one below it. O9 nine added lines past the ~76-column wrap and two orphan short lines. O10 the T8 work-log word counts 1293 / 1357 do not reproduce (1302 / 1359 on the same tree). O11 `sweep-prose.R:118` drops only the opening line of a multi-line HTML comment; none exist today. O12 `sweep-prose.R:108` an indented fence would not toggle chunk state; none exist today. O13 README badge lines count as prose; a spec gap, no hit today. O14 the T8 log says the AC4 grep hits only the README's three comment lines; it also hits the twelve YAML fences.

Return: AC3 not verified (the reader's list has ten entries), so status returns to in-progress under the 2026-09-10 decision that made a non-empty list a defect return. Defect returns on this milestone: 1. Nothing was pushed and no PR was opened.
