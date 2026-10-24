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

- [x] AC1: At the branch head, no terminal token that `utils::getParseData()` returns for any file `Sys.glob("R/*.R")` lists has text matching the perl pattern `\bM[0-9]{2,3}\b`.
- [x] AC2: The package code is unchanged: `Sys.glob("R/*.R")` lists the same files at the branch point and the branch head, `deparse()` of `parse(file, keep.source = FALSE)` is identical at both for each file, and `git diff <branch point> -- man NAMESPACE DESCRIPTION` is empty.
- [x] AC3: No comment token that `utils::getParseData()` returns at the branch head, on a line of `R/*.R` that the diff from the branch point adds, holds a match of `\b(AC|BC|T|O|F|P)[0-9]{1,2}\b`, a match of `\bS[0-9]{1,2}\b` other than `S3`, `S4` and `S7`, or the word "milestone" in any letter case.
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
- 2026-10-24: review pass 1: four lenses spawned; 39 findings settled (25 fix now, fixed in 0df9ef6e or at hygiene, 13 rejected, 1 follow-up row); AC1-AC3 verified at 0df9ef6e; AC4's test and check re-running at 0df9ef6e, so AC4 is not yet ticked (checkpoint).

## Decisions

## Review

Pass 1, 2026-10-24, head 0df9ef6e, branch point 84eb2a20 (default branch unmoved).

- AC1 evidence: `getParseData()` terminal-token sweep over `Sys.glob("R/*.R")` reads 25 files and finds 0 matches of `\bM[0-9]{2,3}\b` at 0df9ef6e; the same sweep in a worktree at 84eb2a20 finds 299, all in COMMENT tokens (domain non-empty).
- AC2 evidence: `Sys.glob("R/*.R")` lists the same 25 files as `git ls-tree 84eb2a20 R/`; `deparse(parse(f, keep.source = FALSE))` is identical at 84eb2a20 and 0df9ef6e for all 25; `git diff 84eb2a20 -- man NAMESPACE DESCRIPTION` prints 0 lines. Control: a copy of `R/tuner.R` with `planted <- 1L` appended compares as different.
- AC3 evidence: the lines `git diff -U0 84eb2a20 0df9ef6e -- R/` adds are 385 lines in 19 files; `getParseData()` at 0df9ef6e gives 385 COMMENT tokens on them and 0 match the three patterns (`(AC|BC|T|O|F|P)[0-9]{1,2}`, `S[0-9]{1,2}` other than S3/S4/S7, "milestone" in any case). Control: the same patterns match 32 of the lines the diff removes.

Consistency gate at 0df9ef6e: `cairn_validate.py` exit 0 (18 references-staleness advisories, none from this branch). No principle changed, so `cairn_impact` skipped. `devtools::document()` leaves `man/` and `NAMESPACE` unchanged and rewrites only `Config/roxygen2/version` 8.1.0 to 8.1.1 in DESCRIPTION, because the local roxygen2 is 8.1.1; the branch changes no roxygen line, so this is the environment, not drift (reverted). README not touched. `pkgdown::check_pkgdown()`: no problems. NEWS: no entry, since nothing a user sees changed. No new top-level files. All six `sweep-prose.R --list-gating` commands clean. `air format --check .` clean.

spawned: diff-bug, blame-history, prior-review, ripple

- diff-bug #1: `R/parallel.R:283` "a dependency the package does not take" is not a reason the code still has and reads as a rule on utils — fix now, fixed 0df9ef6e (now "which the package does not call").
- diff-bug #2: `R/parallel.R:395` lists `...`, `param_info` and `event_level` as "that signature", false for the generic `(object, ...)` and incomplete for the methods — fix now, fixed 0df9ef6e.
- diff-bug #3: `R/nested-results.R:161` "each pattern misses some spelling" contradicts its own examples, which caught too much — fix now, fixed 0df9ef6e.
- diff-bug #4: `R/parallel.R:592` lost its period, so two sentences run together — fix now, fixed 0df9ef6e.
- diff-bug #5: `R/parallel.R:1011` lost its period — fix now, fixed 0df9ef6e (also moved to present tense).
- diff-bug #6: `R/nested-final-fit.R:243` "departs from RR02's recommendation" dropped which RR02 item and misnamed it — fix now, fixed 0df9ef6e (now names what RR02 asks for: identical results from one user-visible seed under either generator kind).
- diff-bug #7: `R/parallel.R:1140` "a handler for those classes misses it" gives "handler" two meanings; the `inherits()` test misses it — fix now, fixed 0df9ef6e.
- diff-bug #8: `R/nested-results-print.R:470` "so that it does not raise" reads as a purpose clause — fix now, fixed 0df9ef6e.
- diff-bug #9: `R/parallel.R:1164` "the same probe" has no antecedent after "as probed" — fix now, fixed 0df9ef6e ("by a probe").
- diff-bug #10: `R/nested-results.R:170` "the conservative direction chosen ... it could not recognize" has no subject — fix now, fixed 0df9ef6e.
- diff-bug #11: `R/nested-results-agreement.R:84` the colon became a period, so the reason no longer reads as the reason — fix now, fixed 0df9ef6e.
- diff-bug #12: `R/extract-procedure.R:5` "Before this generic" still reads as project history — fix now, fixed 0df9ef6e.
- diff-bug #13: `R/nested-results-plot.R:171` "a comment here once claimed ... a re-review disproved it" still reads as history — fix now, fixed 0df9ef6e.
- diff-bug #14: `R/nested-results-collect.R:684, :1104` and `R/checks.R:2042` "built before the procedure was recorded" is ambiguous between the package and the run — fix now, fixed 0df9ef6e ("before the package recorded ...").
- diff-bug #15: `R/tuner.R:195` "held to the selection rule" reads as applying the rule, not requiring a recorded one — fix now, fixed 0df9ef6e.
- diff-bug #16: `R/tuner.R:57` "Every site that used to switch on that name" is history wording in a hunk's context — fix now, fixed 0df9ef6e (the Goal's rewording clause covers it).
- diff-bug #17: `R/nested-tune-grid.R:523` a short line before the next comment line — reject, style.
- diff-bug #18: short lines at `R/parallel.R:478, :913`, `R/nested-final-fit-extract.R:58`, `R/checks.R:992` — reject, style.
- diff-bug #19: `R/nested-workflow-map.R:264` the present-tense claim about a rebuilt condition is unchecked — reject, false: a condition `rlang::abort()` builds from formatted text has the text and any class passed, and none of the original's parent, bullets, format flag or data fields, which is why `for_workflow()` re-signals the object with `cnd_signal()`.
- diff-bug #20: `R/checks.R:608` "(probed 2026-09-30)" noted with no defect claimed — reject, false (prior-review #3 below changed the line).
- blame-history #1: `R/parallel.R:798` dropping "extends M10-D1's rather than reordering it" loses the ladder's ordering constraint — reject, false: the kept first sentence, the class goes to whichever failure names the most actionable fix, is the rule that fixes the order, and the next sentence states the order.
- blame-history #2: `R/parallel.R:283` turns a deferral into a standing rule on utils — fix now, fixed 0df9ef6e (as diff-bug #1).
- blame-history #3: `R/nested-final-fit.R:243` lost the BC6 pointer — fix now, fixed 0df9ef6e (as diff-bug #6; AC3 bars the `BC` token, so the comment names the requirement in words).
- blame-history #4: `R/nested-results-print.R:471` no longer says a wrong "does not raise" claim was once made — reject, planned change (the Scope removes history; the reason the sentence blocks the claim stays).
- blame-history #5: `R/nested-final-fit.R:270` dropped "(a milestone-local decision, M70)" — reject, planned change (the reason, nothing on this path reads it, stays).
- blame-history #6: `R/nested-tune-grid.R:635` lost the pointer to the M21 record — reject, planned change (the asymmetry is stated).
- blame-history #7: `R/nested-results.R:161` the claim became general — fix now, fixed 0df9ef6e (as diff-bug #3).
- blame-history #8: `R/extract-procedure.R:5` "Before this generic" has no referent — fix now, fixed 0df9ef6e (as diff-bug #12).
- blame-history #9: `R/parallel.R:912` "refuses" became "also avoids" — reject, style (same meaning: the non-answer message also names every fault).
- blame-history #10: lesson pointers removed at `R/checks.R:1693`, `R/nested-workflow-map.R:216, :221`, `R/nested-results.R:1160`, and "since M58" at `R/checks.R:104` — reject, planned change (each reason stays).
- blame-history #11: `R/nested-workflow-map.R:264` "what M71 did" dropped, present tense — reject, planned change (no content lost, the lens says so).
- prior-review #1: `R/nested-results-plot.R:171` narrated history — fix now, fixed 0df9ef6e (as diff-bug #13).
- prior-review #2: `R/extract-procedure.R:5` change-history phrasing — fix now, fixed 0df9ef6e (as diff-bug #12).
- prior-review #3: `R/checks.R:608` the date put in for "probed at M133" is the squash-merge date, not shown to be the probe date — fix now, fixed 0df9ef6e (now pinned to commit 4b3f15db, which added the rule and the figure).
- prior-review #4: undated byte figures at `R/parallel.R:82, :280, :470`, the same text as on the default branch — follow-up, new row "Pin the byte figures in parallel.R".
- ripple #1: `cairn/ROADMAP.md` row "Clear milestone ids from R comments" still counts about 290 ids in `R/` — fix now, at step 9's hygiene, which graduates the row this milestone absorbed.
