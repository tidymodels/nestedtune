# M086: The guides and README pass the plain-English sweep

- **Status:** review
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** #91 partial
- **Surface tier:** user-facing — the four guides, the parallel article and the README are the package's reader-facing pages
- **Branch/PR:** `m086-guides-plain-sweep`

## Goal

Rewrite every sentence of the six pages that fails the plain clauses, with those clauses added to `benchmarks/sweep-prose.R` as a `--plain` mode calibrated so the reference intro passes unchanged.

## Scope

Definitions this file and M087/M088 share. "The six pages" are `vignettes/nested-cv.Rmd`, `vignettes/estimate.Rmd`, `vignettes/tuners.Rmd`, `vignettes/results.Rmd`, `vignettes/articles/parallel.Rmd` and `README.Rmd`, the page list `benchmarks/sweep-prose.R` holds. "Prose" and "sentence" are what that script's header defines. "The reference intro" is `vignettes/nested-cv.Rmd` lines 17-33 at commit `0d8611e`. "The plain clauses" are: a semicolon; a contraction (a word ending `n't`, `'re`, `'ll`, `'ve`, `'d` or `'m`); `has been` or `have been`; one of the words `should`, `may`, `might`, `could`, `would`; a comma, one space, then a word ending in `ing` other than the words on the script header's exclusion list (seeded with `including`, `during`, `according`, `regarding`, `nothing`, `something`, `anything`, `everything`, extended only when the reference intro or a correct sentence of the pages needs it, each extension recorded in the work log); a phrase on the script header's slop list, each phrase copied from the left column of the SimpleEnglish skill's `references/word-swaps.md` with parenthetical qualifiers dropped and `/`-separated alternatives split into their own phrases. Each clause matches whole words, any case. The clauses are the SimpleEnglish skill's mechanical rules (SKILL.md rules 4-8 and 10); the 30-word sentence cap M084 set stays, because the reference intro has a 29-word sentence and the M084 lesson says a clause the reference fails is a wrong clause.

**In:** the `--plain` and `--pages` modes; the fixture test; the rewrite of the six pages; the README knit; one NEWS bullet; the reader prompt review runs.

**Out:** the help pages → M087; running the sweeps in CI, the test suite over the real pages, and the profile slots → M088; the 25-word cap → not adopted (work log); `NEWS.md`'s development bullets → the existing candidate row; #91's remaining items (`@param` inheritance, the use of "you", roxygen templates) → the candidate row this plan adds; the sweep script's prose-definition gaps → the existing candidate row.

## Acceptance criteria

- [ ] AC1: `Rscript benchmarks/sweep-prose.R --plain` reports every prose sentence of the six pages matching a plain clause, as `file:line: <clause name>: <text>` with `line` the line the sentence starts on, and exits 1 on any hit; at the milestone's head it prints `clean` and exits 0.
- [ ] AC2: `Rscript benchmarks/sweep-prose.R --plain --pages <path>` (`--pages` replacing the page list; a page read with or without a YAML header) run on a file holding only the reference intro prints `clean` and exits 0, the file's text byte-identical to `git show 0d8611e:vignettes/nested-cv.Rmd | sed -n '17,33p'`.
- [ ] AC3: `tests/testthat/test-sweep-prose.R` runs `--plain --pages` over a committed fixture under `tests/testthat/fixtures/` whose header comment names it hand-authored with no generator or seed, and which carries: one sentence per plain clause, at least one of them in mixed case and one wrapped across two lines; one sentence holding every clause's marker only inside backtick spans; and one near-miss sentence per clause (`maybe`, `shouldering`, `has not been`, `, the tuning`, a possessive `'s`) — and asserts that the output names each clause exactly once by clause name with the wrapped sentence reported at its first line, and names the backtick and near-miss sentences not at all. The test skips with the reason `sweep-prose.R not in the source tree` when `benchmarks/sweep-prose.R` is absent from the package root testthat resolves.
- [ ] AC4: `Rscript benchmarks/sweep-prose.R` and `Rscript benchmarks/sweep-prose.R --spans` print `clean` and exit 0 over the six pages, and `wc -w` on each of the six files is at most 110% of its value at the branch point.
- [ ] AC5: one fresh-context reading of the six pages per review pass in the SimpleEnglish skill's check mode (each entry a rule number quoted from the skill's `references/rule-catalog.md`, the offending text, a rewrite), by a reader withheld this milestone file and the `--plain` output, saved as `cairn/surveys/M086-reader-review.md`; every entry is triaged at the review gate as fixed or rejected with a reason, and the report is never rerun after fixes within a pass.
- [ ] AC6: `Rscript -e 'devtools::check()'` reports 0 errors, 0 warnings, 0 notes; `README.md` is re-knitted from `README.Rmd` with no further diff from `devtools::build_readme()`; `NEWS.md` carries one bullet for the rewrite.

## Coverage

- AC1 → T1, T3, T4, T5
- AC2 → T1
- AC3 → T2
- AC4 → T3, T4, T5, T6
- AC5 → T7
- AC6 → T5, T6

## Tasks

- [x] T1: Add `--pages <path>...` and `--plain` to `benchmarks/sweep-prose.R` (header: the clause list, the `ing` exclusion list, the slop list copied from `word-swaps.md`); a clause reports by name; `--pages` accepts a page without a YAML header. Calibrate on a scratch file holding the reference intro (AC2) before touching a page.
- [x] T2: Write `tests/testthat/fixtures/sweep-prose-plain.Rmd` (header comment: hand-authored, one sentence per clause, no generator or seed) and `tests/testthat/test-sweep-prose.R` (AC3); the test locates the script through `testthat::test_path("..", "..", "benchmarks", "sweep-prose.R")` and skips when it is absent.
- [x] T3: Rewrite `vignettes/nested-cv.Rmd` and `vignettes/estimate.Rmd` until `--plain` is clean over them, keeping the default and `--spans` sweeps clean; the reference intro is not edited.
- [x] T4: Rewrite `vignettes/tuners.Rmd` and `vignettes/results.Rmd` the same way.
- [x] T5: Rewrite `vignettes/articles/parallel.Rmd` and `README.Rmd` the same way; `devtools::build_readme()`.
- [x] T6: Record `wc -w` per page at the branch point and at the head in the work log; one `NEWS.md` bullet; `devtools::check()` clean.
- [x] T7: Write `cairn/surveys/M086-reader-prompt.md`: the check-mode instructions (rule numbers from `references/rule-catalog.md`, the six page paths, the withheld files) that review hands unchanged to a fresh reader at each pass.

## Work log

- 2026-09-11: created by /milestone-plan.
- 2026-09-11: criteria audit ran in full mode over M086 and M087 (fresh reader, none of the criteria its own). Must-fix findings, all fixed before writing: withheld survey files nothing created (AC5 now withholds this file and the `--plain` output); the fixture lacked the provenance clause `cairn/PROFILE.md` requires (AC3); AC3's probes were one exemplar per clause (mixed case, a wrapped sentence and near-miss silence added); AC2 did not say `--pages` reads a headerless page. Judgment calls settled: an exclusion list for non-verb `ing` words after a comma (`, including` at `R/nested-final-fit.R:179` is a correct sentence); the slop list's qualified entries split into plain phrases; D-061's "listed paragraphs changed" diff check is subsumed by AC1, since a listed sentence must change to pass.
- 2026-09-11: plan gate chose the 30-word cap over the SimpleEnglish skill's 25-word cap because the reference intro has a 29-word sentence and the M084 lesson forbids editing the reference to fit a clause; falsified by a fresh-reader report flagging a 26-30-word sentence in the intro for length.
- 2026-09-11: plan gate chose flagging `would`, `may`, `might`, `could` and `should` over leaving counterfactual modals alone because the skill's rule 5 names them and the reference intro uses none; falsified by a counterfactual sentence that no rewrite states without a modal, which then goes on the exclusion list.
- 2026-09-11: /milestone-implement started; branch `m086-guides-plain-sweep` cut from `main` at b84cbcb. Question gate skipped: nothing the plan left open changes the work. One call made in passing: a slop hit reports as `slop (<phrase>)`, so the clause name stays `slop` and the reader sees the phrase.
- 2026-09-11: T1 done. `--plain` reports one line per clause a sentence matches; `--pages` takes the paths up to the next `--` option. The reference intro (`git show 0d8611e:vignettes/nested-cv.Rmd | sed -n '17,33p'`, byte-identical scratch file) prints `clean` with no change to the `ing` exclusion list. Baseline over the six pages: 21 hits (11 modal, 6 comma-ing, 3 semicolon, 1 modal+comma-ing on one sentence; 0 slop, 0 contraction, 0 has-been).
- 2026-09-11: T2 done. Fixture `tests/testthat/fixtures/sweep-prose-plain.Rmd` (headerless, so it also exercises the no-YAML path) and `tests/testthat/test-sweep-prose.R`; `devtools::test(filter = "sweep-prose")` passes 13 expectations, skips under `R CMD check` because `benchmarks/` is `.Rbuildignore`d.
- 2026-09-11: T3 done. `nested-cv.Rmd` (5 sentences) and `estimate.Rmd` (4 sentences, two of them list-item continuation lines whose list-item line the sweep drops: the modals on those items were rewritten too). The reference intro is untouched. Every counterfactual modal restated without one, so the falsifier in the plan-gate line below did not fire and the exclusion list stays as seeded.
- 2026-09-11: T4 done. `tuners.Rmd` (3 sentences), `results.Rmd` (3 sentences).
- 2026-09-11: T5 done. `parallel.Rmd` (4 sentences), `README.Rmd` (1 list-item continuation, `, racing` read as a comma-ing hit); `devtools::build_readme()` re-knitted `README.md`, a two-line diff. Default, `--spans` and `--plain` sweeps print `clean` over the six pages.
- 2026-09-11: T7 done. `cairn/surveys/M086-reader-prompt.md` holds the check-mode block review hands unchanged to a fresh reader each pass. T6 in progress: `wc -w` at the branch point b84cbcb / at head: nested-cv 1798/1800, estimate 1408/1405, tuners 2187/2184, results 1836/1837, parallel 804/801, README 367/370 (every page within 110%); one NEWS bullet added; `devtools::check()` and the claim audit are running, their results pending in this checkpoint.
- 2026-09-11: claim audit: 38 claims read, 2 corrected — benchmarks/sweep-prose.R (the `--pages` header line claimed every mode; `--roxygen` ignores it), NEWS.md (the bullet claimed no `-ing` word after a comma; the exclusion list lets eight through). Both re-read once by the same reader and cleared.
- 2026-09-11: T6 done. `devtools::check()`: 0 errors, 0 warnings, 0 notes (run at dc492bb; the two later commits touch only a `.Rbuildignore`d header comment and NEWS wording). `devtools::test()` at head: FAIL 0, PASS 9795. Status set to review.
- 2026-09-11: plan gate chose the SimpleEnglish check-mode reader as the per-pass report over a rule-numbered pass bar because D-061 forbids binding a reader's list; falsified by nothing short of a superseding decision entry.

## Decisions

## Review
