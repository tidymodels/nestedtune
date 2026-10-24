# M161: R source comments carry no milestone ids

**Status:** done (2026-10-24, PR #178 https://github.com/tidymodels/nestedtune/pull/178)

**Goal:** Remove the milestone ids from the comments in `R/*.R`, rewording each comment that reads as tracking history so that it states the fact.

**Outcome:** Comments only; no code, help page, NAMESPACE, DESCRIPTION or NEWS change.
- The 299 ids in 19 of the 25 `R/*.R` files are gone, with the task, review-finding and milestone-local decision labels that pointed into them (`T5`, `S1`, "M134 review", `M10-D1`). Comments that needed the id now state the fact or reason: "M03 records fold failures" reads "the outer loop records", "since M58" and "before M24" phrases state the current behavior, and the "M05/M45 lesson" names its reason, that a frame in a message is deparsed whole.
- Decision ids, principle ids and review-report pointers (`RR02 Q7`, `RB04`) stay, as pointers to live records. The two comments with the word "milestone" and no id were reworded too.
- The "8 result rows for 6 splits" figure in `R/checks.R` is pinned to commit 4b3f15db, which added it.
- `R/checks.R` and `R/parallel.R` were done inline; the other 17 files by three Haiku subagents, whose diffs needed 12 fixes before commit.

**Decisions:** milestone-local only: review-report pointers kept for the reason decision ids are; one-off sweep commands in the criteria rather than a new checker (plan gate). None promoted.

**Review:** Four-lens fan-out, one pass, no return. 36 findings: 24 fixed (false or garbled rewordings, among them a wrong list of `nested_tune_grid()` arguments and a name-pattern sentence that contradicted its examples, lost periods and colons, unclear antecedents, leftover history wording, the probe date), 11 rejected (4 style, 3 false, 4 planned change), 1 follow-up: new row "Pin the byte figures in parallel.R". AC1 0 ids against 299 at 84eb2a20; AC2 parsed code identical in all 25 files; AC3 385 added comment tokens, 0 hits. At 0df9ef6e `devtools::test()` 0 failed (13371 passes) and `check()` 0/0/0. CI green on #178 (16 pass, deploy skipped); the first watch hit its 590 s ceiling and the review resumed. The local commits after the pushed approval (PR record, CI stop, resume, re-posed approval) were dropped by `--delete-branch`; this summary carries them. `document()` bumped only `Config/roxygen2/version` from the local roxygen2 8.1.1, reverted. Row "Clear milestone ids from R comments" graduated. No lesson added, since LESSONS holds 32 against the 25 limit; the M149 lesson marked used. None retired; none unparked.
