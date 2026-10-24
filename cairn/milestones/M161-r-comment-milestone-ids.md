<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M161: R source comments carry no milestone ids

- **Status:** planned
- **Priority:** normal
- **Depends on:** M160
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — comments in `R/*.R`; no code, help page or behavior changes
- **Branch/PR:** —

## Goal

Remove the milestone ids from the comments in `R/*.R`, rewording each comment that reads as tracking history so that it states the fact.

## Scope

**In:** the 299 ids that `utils::getParseData()` finds in comment tokens of the 25 files of `R/*.R` at 6e5e3527 (67 in `R/checks.R`, 41 in `R/parallel.R`; none in roxygen or code tokens). Labels that point into a milestone go with their id (`T5`, `S1`, "M134 review", "probed at M133"). Phrases such as "this milestone declined" are reworded to state what the code does or why.

**Out:** decision ids (`D-102`) stay, since they point to the rationale in `cairn/DECISIONS.md`, which the repo carries. Milestone ids in `benchmarks/` and `.github/` are outside the row, which names R comments, and get no row. Test files: M155 cleared them. No code, help page or NEWS change.

## Acceptance criteria

- [ ] AC1: At the branch head, no terminal token that `utils::getParseData()` returns for any file `Sys.glob("R/*.R")` lists has text matching the perl pattern `\bM[0-9]{2,3}\b`.
- [ ] AC2: The package code is unchanged: `Sys.glob("R/*.R")` lists the same files at the branch point and the branch head, `deparse()` of `parse(file, keep.source = FALSE)` is identical at both for each file, and `git diff <branch point> -- man NAMESPACE DESCRIPTION` is empty.
- [ ] AC3: No comment line the diff from the branch point adds to `R/*.R` holds a match of `\b(AC|BC|T|O|F|P)[0-9]{1,2}\b`, a match of `\bS[0-9]{1,2}\b` other than `S3`, `S4` and `S7`, or the word "milestone" in any letter case.
- [ ] AC4: At the branch head, `devtools::test()` reports 0 failures, `devtools::check()` reports 0 errors, 0 warnings and 0 notes, `air format --check .` is clean, and `Rscript benchmarks/sweep-prose.R --plain` is clean.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2, T3
- AC3 → T1, T2
- AC4 → T3

## Tasks

- [ ] T1: Rewrite the comments of `R/checks.R` and `R/parallel.R`. Drop each id with the labels that point into its milestone, keep decision ids, and reword a comment that only makes sense with the id. Where an id was the only pointer to a reason the code still needs, state the reason in the comment.
- [ ] T2: Rewrite the other 23 files under the T1 spec, through Haiku subagents for file groups if the count warrants it; read each diff before it lands.
- [ ] T3: Run the AC1 sweep (show it reads 25 files and finds 299 ids at the branch point), the AC2 comparison, the AC3 search over `git diff -U0`, the verify slot and `devtools::check()` from the main checkout (LESSONS M149), and record the results.

## Work log

- 2026-10-24: created by /milestone-plan.
- 2026-10-24: tier check: not run — work named at the question set.
- 2026-10-24: idea vet: no concern. The ids are tracking pointers a reader of `R/` cannot use without `cairn/`, and M155 removed the same kind from the tests; decision ids are kept as pointers to current rationale.
- 2026-10-24: collision check: absorbs the candidate row "Clear milestone ids from R comments" (filed at M156's plan gate). M155 did tests only. No D-entry collides. Inbox sweep: no overlap (see M160).
- 2026-10-24: question set: plan a second milestone after the first — "Also the id cleanup"; it depends on M160 because both edit `R/nested-final-fit.R` comments.
- 2026-10-24: plan gate chose keeping decision ids over removing them with the milestone ids, because the row asks for milestone ids and a decision id names a live record of why the code is as it is; falsified by a user or maintainer asking for decision ids out of `R/` too.
- 2026-10-24: plan gate chose one-off sweep commands in the criteria over extending `benchmarks/sweep-test-comments.R` to `R/`, because a new checker over repo-internal text would need upkeep for a one-time cleanup; falsified by milestone ids reappearing in `R/` after this milestone.

## Decisions

## Review
