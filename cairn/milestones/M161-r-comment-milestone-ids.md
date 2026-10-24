<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M161: R source comments carry no milestone ids

- **Status:** review
- **Priority:** normal
- **Depends on:** M160
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — comments in `R/*.R`; no code, help page or behavior changes
- **Branch/PR:** m161-r-comment-milestone-ids

## Goal

Remove the milestone ids from the comments in `R/*.R`, rewording each comment that reads as tracking history so that it states the fact.

## Scope

**In:** the 299 ids that `utils::getParseData()` finds in comment tokens of the 25 files of `R/*.R` at 6e5e3527 (67 in `R/checks.R`, 41 in `R/parallel.R`; none in roxygen or code tokens). Labels that point into a milestone go with their id (`T5`, `S1`, "M134 review", "probed at M133"). Phrases such as "this milestone declined" are reworded to state what the code does or why.

**Out:** decision ids (`D-102`) stay, since they point to the rationale in `cairn/DECISIONS.md`, which the repo carries. Milestone ids in `benchmarks/` and `.github/` are outside the row, which names R comments, and get no row. Test files: M155 cleared them. No code, help page or NEWS change.

## Acceptance criteria

- [ ] AC1: At the branch head, no terminal token that `utils::getParseData()` returns for any file `Sys.glob("R/*.R")` lists has text matching the perl pattern `\bM[0-9]{2,3}\b`.
- [ ] AC2: The package code is unchanged: `Sys.glob("R/*.R")` lists the same files at the branch point and the branch head, `deparse()` of `parse(file, keep.source = FALSE)` is identical at both for each file, and `git diff <branch point> -- man NAMESPACE DESCRIPTION` is empty.
- [ ] AC3: No comment token that `utils::getParseData()` returns at the branch head, on a line of `R/*.R` that the diff from the branch point adds, holds a match of `\b(AC|BC|T|O|F|P)[0-9]{1,2}\b`, a match of `\bS[0-9]{1,2}\b` other than `S3`, `S4` and `S7`, or the word "milestone" in any letter case.
- [ ] AC4: At the branch head, `devtools::test()` reports 0 failures, `devtools::check()` reports 0 errors, 0 warnings and 0 notes, `air format --check .` is clean, and `Rscript benchmarks/sweep-prose.R --plain` is clean.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2, T3
- AC3 → T1, T2
- AC4 → T3

## Tasks

- [x] T1: Rewrite the comments of `R/checks.R` and `R/parallel.R`. Drop each id with the labels that point into its milestone, keep decision ids, and reword a comment that only makes sense with the id. Where an id was the only pointer to a reason the code still needs, state the reason in the comment.
- [x] T2: Rewrite the other 23 files under the T1 spec, through Haiku subagents for file groups if the count warrants it; read each diff before it lands.
- [x] T3: Run the AC1 sweep (show it reads 25 files and finds 299 ids at the branch point), the AC2 comparison, the AC3 search over `git diff -U0`, the verify slot and `devtools::check()` from the main checkout (LESSONS M149), and record the results.

## Work log

- 2026-10-24: created by /milestone-plan.
- 2026-10-24: tier check: not run — work named at the question set.
- 2026-10-24: idea vet: no concern. The ids are tracking pointers a reader of `R/` cannot use without `cairn/`, and M155 removed the same kind from the tests; decision ids are kept as pointers to current rationale.
- 2026-10-24: collision check: absorbs the candidate row "Clear milestone ids from R comments" (filed at M156's plan gate). M155 did tests only. No D-entry collides. Inbox sweep: no overlap (see M160).
- 2026-10-24: question set: plan a second milestone after the first — "Also the id cleanup"; it depends on M160 because both edit `R/nested-final-fit.R` comments.
- 2026-10-24: plan gate chose keeping decision ids over removing them with the milestone ids, because the row asks for milestone ids and a decision id names a live record of why the code is as it is; falsified by a user or maintainer asking for decision ids out of `R/` too.
- 2026-10-24: plan gate chose one-off sweep commands in the criteria over extending `benchmarks/sweep-test-comments.R` to `R/`, because a new checker over repo-internal text would need upkeep for a one-time cleanup; falsified by milestone ids reappearing in `R/` after this milestone.
- 2026-10-24: criteria audit (reduced mode, fresh Opus reader): AC1, AC2 and AC4 passed. AC3 passed, with the note that "comment line" was loose, so AC3 now reads comment tokens from `utils::getParseData()` on the added lines. The reader found no one-digit or four-digit `M` ids in `R/*.R`, so AC1's pattern misses none today. No criterion binds an instrument.
- 2026-10-24: branch m161-r-comment-milestone-ids cut from 84eb2a20 (pushed default branch, M160 merged). The AC1 sweep there reads 25 files and 299 ids, all in COMMENT tokens; by token count `R/checks.R` holds 71 and `R/parallel.R` 42 (the plan's 67 and 41 were `grep -c` line counts).
- 2026-10-24: implementation choice: a milestone-local decision label (`M10-D1`, `M07-D6`) and a "since M58" or "before M24" phrase are reworded to the fact they stood for; "M03 records fold failures" becomes "the outer loop records"; the "(probed at M133)" figure keeps a date (2026-09-30, M133's PR date) under the derived-figures rule; the "M05/M45 lesson" becomes its reason, that a frame in a message is deparsed whole.
- 2026-10-24: T1 done: `R/checks.R` and `R/parallel.R` hold no milestone ids; 186 ids remain in the other 23 files. AC2's comparison finds no code change in any of the 25 files; `air format --check .` clean. Tests and check run once at T3, since AC2 shows the package code unchanged.
- 2026-10-24: delegation: three Haiku subagents rewrote the other 23 files in groups of 2, 3 and 12 files (55, 55 and 76 ids) under the T1 spec. I read all three diffs and fixed 12 sites: a sentence left with no period, two joined lines over 80 characters, a present-tense claim that the final fit's run is "reachable only as an undocumented list slot" (false since D-023), "Tune" capitalized, an event-level reword checked against the `control_last_fit(event_level = )` call, and six rewordings that still read as history.
- 2026-10-24: implementation choice: review-report pointers (`RR02 Q7`, `RR03 Q5`, `RB04`) stay, for the reason decision ids stay: they name live records in `cairn/reviews/archive/`. The two comments that held the word "milestone" with no id (`R/nested-results.R`, `R/parallel.R`) are reworded under the Scope's "this milestone declined" clause.
- 2026-10-24: T2 done: the AC1 sweep finds 0 ids in 25 files; AC2 finds no code change; no added comment line holds an AC3 pattern or runs over 80 characters; `air format --check .` clean.
- 2026-10-24: T3 done at 3c4bc360 against branch point 84eb2a20. AC1: 25 files, 299 ids at the branch point, 0 at the head, all hits in COMMENT tokens. AC2: same 25 files, `deparse(parse(keep.source = FALSE))` identical for all 25, `git diff 84eb2a20 -- man NAMESPACE DESCRIPTION` empty; control: a planted `planted <- 1L` in a copy of `R/tuner.R` reads as different. AC3: 370 comment tokens on 370 added lines in 19 files, 0 hits; control: the same patterns hit 32 removed lines. AC4: `devtools::test()` 0 failures (13371 passes), `devtools::check()` 0 errors, 0 warnings, 0 notes (main checkout), `air format --check .` clean, `sweep-prose.R --plain` clean.
- 2026-10-24: claim audit: not owed — internal tier.

## Decisions

## Review
