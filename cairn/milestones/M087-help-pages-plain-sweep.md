# M087: The help pages pass the plain-English sweep

- **Status:** review
- **Priority:** high
- **Depends on:** M086
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** #91 partial
- **Surface tier:** user-facing — every exported help page
- **Branch/PR:** `m087-help-pages-plain-sweep`

## Goal

Rewrite every roxygen sentence in `R/*.R` and `man-roxygen/*.R` that fails the plain clauses.

## Scope

The plain clauses, the reference intro and the sweep's prose definition are as M086's Scope defines them; the `--plain` mode and its fixture test ship in M086. At the branch point the roxygen surface carries about 66 semicolons outside code (most end list items), 31 modal words, 26 comma-plus-`ing` clauses and 1 slop word, none of which M085's caps (30 words, four spans, first-use setups, openings) bound.

**In:** the rewrite of every roxygen block the `--roxygen --plain` sweep lists; `devtools::document()`; one NEWS bullet; the reader prompt review runs.

**Out:** the six pages → M086; the sweeps in CI and the test suite → M088; `@param` inheritance from tune, the use of "you", and roxygen templates → the #91 remainder candidate row; the `Differences from calling ... directly` run-in headings stay excluded from the sweeps as M085 set them.

## Acceptance criteria

- [x] AC1: `Rscript benchmarks/sweep-prose.R --roxygen --plain` reports every roxygen prose sentence (the script's `--roxygen` prose definition) matching a plain clause, in the same form as M086 AC1, and at the milestone's head prints `clean` and exits 0.
- [x] AC2: `Rscript benchmarks/sweep-prose.R --roxygen` and `Rscript benchmarks/sweep-prose.R --roxygen --spans` print `clean` and exit 0, and `grep -c "^#'"` summed over `R/*.R` and `man-roxygen/*.R` is at most 110% of its value at the branch point.
- [ ] AC3: one fresh-context reading per review pass of the rendered help pages (`man/*.Rd` through `tools::Rd2txt`) in the SimpleEnglish skill's check mode, in M086 AC5's entry form, by a reader withheld this milestone file and the `--roxygen --plain` output, saved as `cairn/surveys/M087-reader-review.md`; every entry triaged at the review gate as fixed or rejected with a reason, never rerun after fixes within a pass.
- [x] AC4: `Rscript -e 'devtools::document()'` produces no diff; `Rscript -e 'devtools::check()'` reports 0 errors, 0 warnings, 0 notes; `NEWS.md` carries one bullet for the rewrite.

## Coverage

- AC1 → T1, T2, T3
- AC2 → T1, T2, T3, T4
- AC3 → T5
- AC4 → T4

## Tasks

- [x] T1: Rewrite the orchestrator pages — `R/nested-tune-grid.R` (36 marker lines at the branch point), `R/nested-tune-bayes.R`, `R/nested-tune-sim-anneal.R`, `R/nested-tune-race.R`, `R/nested-fit-resamples.R`, `R/nested-workflow-map.R` and `man-roxygen/*.R` — until `--roxygen --plain` lists nothing in them; list items lose their `;` terminators rather than gaining a rewrite; keep `--roxygen` and `--roxygen --spans` clean.
- [x] T2: Rewrite the final-fit pages — `R/nested-final-fit.R`, `R/nested-final-fit-print.R`, `R/nested-final-fit-predict.R`, `R/nested-final-fit-extract.R` — the same way.
- [x] T3: Rewrite the results pages — `R/nested-results.R`, `R/nested-results-print.R`, `R/nested-results-set.R`, `R/nested-results-collect.R`, `R/nested-results-plot.R`, `R/nested-results-agreement.R`, `R/extract-procedure.R`, `R/selection-rule.R`, `R/nested-resamples.R` — and any file the sweep still lists, the same way.
- [x] T4: `devtools::document()`; record the `#'` line count at the branch point and the head in the work log; one `NEWS.md` bullet; `devtools::check()` clean.
- [x] T5: Write `cairn/surveys/M087-reader-prompt.md`: the check-mode instructions, the `tools::Rd2txt` rendering command over `man/*.Rd`, and the withheld files, handed unchanged to a fresh reader at each review pass.

## Work log

- 2026-09-11: created by /milestone-plan.
- 2026-09-11: criteria audit ran in full mode (the M086 work log holds the shared findings); M087-specific: the reader reads `man/*.Rd` while fixes land in roxygen, which AC4's no-diff `document()` pins; `grep -c "^#'"` counts `@examples` lines too, accepted as a bounded proxy for growth.
- 2026-09-11: plan gate chose a second milestone for the help pages over folding them into M086 because the roxygen surface holds about four times the guides' hits and M085 took a full milestone at a smaller clause set; falsified by M086 finishing with more than a session to spare, in which case M087's tasks fold into the next docs milestone.

- 2026-09-11: /milestone-implement started; branch cut from origin/main at 047fe5f; branch point: `--roxygen --plain` 127 hits (72 semicolon, 30 modal, 24 comma-ing, 1 slop), `#'` count 2718 (AC2 cap 2989); question gate skipped, the plan leaving no choice open.
- 2026-09-11: T5 done: `cairn/surveys/M087-reader-prompt.md` written in M086's shape, rendering `man/*.Rd` through `tools::Rd2txt` to `/tmp/nestedtune-rd/` (the command tested on `nested_tune_grid.Rd`); withheld: this file, `cairn/surveys/`, `R/`, `man-roxygen/`, the sweep output.
- 2026-09-11: T1 and T2+T3 delegated to two [O] subagents in parallel over disjoint file sets; diffs verified by the session before each checkpoint.
- 2026-09-11: T2 done: 14 sentences across the four final-fit files (the `...` params split at "Not used. It must be empty."; the print page's seven-item list de-semicoloned; "may be ignored" narrowed to "parsnip decides whether to ignore it"); `document()` deferred to T4 so `man/` regenerates once over T1–T3.
- 2026-09-11: T3 done: 20 sentences across nine results files (three lists de-semicoloned; "could score" → "scored"; "would collide" → "collides"; "None may be named" → "Do not name any of them"); the session reworded one subagent rewrite ("due to contribute rows" → "that contributes rows").
- 2026-09-11: T1 done: 64 sentences across the six orchestrator files and `man-roxygen/section-reproducibility.R`; six counterfactuals restated in the present ("would not preserve" → "does not preserve"; "may not be interruptible" → "is sometimes not interruptible", which also cleared the `simply` hit); the nested-design "may index only" became "must index only", the sentence stating the rule the `nestedtune_bad_design` refusal enforces; the session rewrapped three over-long lines and reworded the workflow-map typo sentence. All three `--roxygen` sweeps `clean`; `#'` count 2726.
- 2026-09-11: claim audit: 70 claims read, 4 corrected — R/nested-results-set.R ("a workflow that contributes rows" → "with completed folds", the refusal firing before any row exists), R/selection-rule.R ("Do not name any of them" → "A named one is refused", `check_dots_unnamed()`), R/nested-final-fit-predict.R (parsnip is not shown to be the decider), R/nested-tune-grid.R ("the run" → "the inner tuning" as the subject that returns a candidate).
- 2026-09-11: T4 checkpoint, half done: `document()` regenerated 26 `man/*.Rd` and a second run produced no diff; NEWS bullet added; `#'` count 2727 (cap 2989); `devtools::check()` still running at this commit, its result to be logged before T4 is ticked.
- 2026-09-11: first `devtools::check()` 0 errors, 0 warnings, 0 notes (6m51s), run on the tree at a316e35 plus `man/` and NEWS, before the four claim-audit edits; a second check at 578e6fd's tree is logged in the next line.
- 2026-09-11: second `devtools::check()` at the head 0 errors, 0 warnings, 0 notes (6m36s); T4 done; all tasks checked; status set to review.

## Decisions

## Review

Pass 1, 2026-09-11, branch head b328643, origin/main at 047fe5f (the branch point; main has not moved).

- AC1 evidence: `Rscript benchmarks/sweep-prose.R --roxygen --plain` printed `clean` and exited 0 at the head. Verified.
- AC2 evidence: `--roxygen` and `--roxygen --spans` each printed `clean` and exited 0. The `grep -c "^#'"` sum over `R/*.R` and `man-roxygen/*.R` is 2727 at the head against 2718 at 047fe5f (100.3%, cap 2989). Verified.
- AC4 evidence: `devtools::document()` at the head left `git status` empty. The run noted that the installed roxygen2 8.0.0 is older than the 8.1.0 DESCRIPTION records, a mismatch that predates this branch. `devtools::check()` at the head: 0 errors, 0 warnings, 0 notes (6m54s). `NEWS.md` carries one bullet for the rewrite. Verified.
- AC3 evidence: one [O] fresh reader ran the `cairn/surveys/M087-reader-prompt.md` block over the 28 rendered pages, withheld this file, `cairn/surveys/`, `R/`, `man-roxygen/` and the sweep output. Report saved as `cairn/surveys/M087-reader-review.md`: 234 entries (rule 3.6 passive voice 101, rule 3.5 `-ing` verbs 48, rule 6.3 the 25-word cap 43, rule 4.2 omitted words 24, rule 9.4 since→because 12, rule 3.4 present perfect 3, rule 1.7 nouns as verbs 2, rule 9.1 restructure 1). Triage at the gate is below. Verified once the gate accepts the triage.

Reader triage (proposed, decided at the gate):
- Fixed: the 12 since→because entries, plus the four other roxygen `since` sites the reader did not list, so no help page reads `since` for `because`. The 3 present-perfect entries (`can have kept` → `can keep`, `once every candidate has failed` → `after every candidate failed`, `once its entry checks have run` → `after its entry checks ran`). Entry 21, the dangling `refuse such an object with` sentence, recast.
- Rejected, the 25-word cap (43 entries): the milestone's cap is 30 words, the M086 decision the reference intro fixed.
- Rejected, rule 4.2 omitted words (24 entries): article and `that` insertion is outside the sweep's clauses and the pages read on one pass without them.
- Rejected, rule 1.7 (2 entries): `error` and `errored` as verbs are the R idiom every page uses for a raised condition.
- Follow-up: the 149 passive-voice and `-ing`-verb entries (rules 3.6 and 3.5) join the #91 candidate row at hygiene, beside M086's 49 of the same shape.

Reviewer findings (three lenses, ranked by each lens, every finding listed):
- [O] diff-bug 1, confirmed against `check_race_burn_in()`: "when finetune refuses any outer fold's inner `rset`" named an event the package's own check pre-empts. Fixed: "when any outer fold's inner `rset` meets that condition". The [S] blame-history lens reported the same site as its first finding.
- [O] diff-bug 2 and [S] blame-history 2: "A version that built them earlier stays reproducible" asserts a hypothetical in the present. Fixed: "Were they built earlier, the run reproduces from the session seed alone, not from the two seeds above."
- [O] diff-bug 3: "Left alone, a fold's proposals then depend" reads as fact. Fixed: "Were the slot left alone, a fold's proposals depend".
- [O] diff-bug 4: "A named one is refused" reaches past a sentence for its referent. Fixed: "An ordering given a name is refused."
- [O] diff-bug 5: "nothing it saves exists to be withheld" gives a verb to a run that does not exist. Fixed: "there is nothing to withhold".
- [O] diff-bug 6: the `extract_procedure()` list items end without a period while the workflow-map list keeps them. Rejected: markdown list items without terminators are the common shape, and no reader entry named it.
- [O] diff-bug 7: the NEWS bullet's "is rewritten" overclaims for the two pages that already passed. Fixed: "now passes".
- [O] diff-bug 8: ragged short lines inside four rewritten paragraphs. Rejected: no rendering effect, a style point.
- [S] prior-PR-comments: no prior-review finding contradicted; the GitHub inline-comment probe found human comments, none on the touched files. Zero findings.

Post-fix re-run at 06a319c: `document()` ran twice, the second writing nothing and `git status` empty. The three roxygen sweeps printed `clean`. The `#'` count is 2728 (cap 2989). The `devtools::check()` result is logged in the work log.
