# M087: The help pages pass the plain-English sweep

- **Status:** in-progress
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

- [ ] AC1: `Rscript benchmarks/sweep-prose.R --roxygen --plain` reports every roxygen prose sentence (the script's `--roxygen` prose definition) matching a plain clause, in the same form as M086 AC1, and at the milestone's head prints `clean` and exits 0.
- [ ] AC2: `Rscript benchmarks/sweep-prose.R --roxygen` and `Rscript benchmarks/sweep-prose.R --roxygen --spans` print `clean` and exit 0, and `grep -c "^#'"` summed over `R/*.R` and `man-roxygen/*.R` is at most 110% of its value at the branch point.
- [ ] AC3: one fresh-context reading per review pass of the rendered help pages (`man/*.Rd` through `tools::Rd2txt`) in the SimpleEnglish skill's check mode, in M086 AC5's entry form, by a reader withheld this milestone file and the `--roxygen --plain` output, saved as `cairn/surveys/M087-reader-review.md`; every entry triaged at the review gate as fixed or rejected with a reason, never rerun after fixes within a pass.
- [ ] AC4: `Rscript -e 'devtools::document()'` produces no diff; `Rscript -e 'devtools::check()'` reports 0 errors, 0 warnings, 0 notes; `NEWS.md` carries one bullet for the rewrite.

## Coverage

- AC1 → T1, T2, T3
- AC2 → T1, T2, T3, T4
- AC3 → T5
- AC4 → T4

## Tasks

- [ ] T1: Rewrite the orchestrator pages — `R/nested-tune-grid.R` (36 marker lines at the branch point), `R/nested-tune-bayes.R`, `R/nested-tune-sim-anneal.R`, `R/nested-tune-race.R`, `R/nested-fit-resamples.R`, `R/nested-workflow-map.R` and `man-roxygen/*.R` — until `--roxygen --plain` lists nothing in them; list items lose their `;` terminators rather than gaining a rewrite; keep `--roxygen` and `--roxygen --spans` clean.
- [ ] T2: Rewrite the final-fit pages — `R/nested-final-fit.R`, `R/nested-final-fit-print.R`, `R/nested-final-fit-predict.R`, `R/nested-final-fit-extract.R` — the same way.
- [ ] T3: Rewrite the results pages — `R/nested-results.R`, `R/nested-results-print.R`, `R/nested-results-set.R`, `R/nested-results-collect.R`, `R/nested-results-plot.R`, `R/nested-results-agreement.R`, `R/extract-procedure.R`, `R/selection-rule.R`, `R/nested-resamples.R` — and any file the sweep still lists, the same way.
- [ ] T4: `devtools::document()`; record the `#'` line count at the branch point and the head in the work log; one `NEWS.md` bullet; `devtools::check()` clean.
- [ ] T5: Write `cairn/surveys/M087-reader-prompt.md`: the check-mode instructions, the `tools::Rd2txt` rendering command over `man/*.Rd`, and the withheld files, handed unchanged to a fresh reader at each review pass.

## Work log

- 2026-09-11: created by /milestone-plan.
- 2026-09-11: criteria audit ran in full mode (the M086 work log holds the shared findings); M087-specific: the reader reads `man/*.Rd` while fixes land in roxygen, which AC4's no-diff `document()` pins; `grep -c "^#'"` counts `@examples` lines too, accepted as a bounded proxy for growth.
- 2026-09-11: plan gate chose a second milestone for the help pages over folding them into M086 because the roxygen surface holds about four times the guides' hits and M085 took a full milestone at a smaller clause set; falsified by M086 finishing with more than a session to spare, in which case M087's tasks fold into the next docs milestone.

- 2026-09-11: /milestone-implement started; branch cut from origin/main at 047fe5f; branch point: `--roxygen --plain` 127 hits (72 semicolon, 30 modal, 24 comma-ing, 1 slop), `#'` count 2718 (AC2 cap 2989); question gate skipped, the plan leaving no choice open.

## Decisions

## Review
