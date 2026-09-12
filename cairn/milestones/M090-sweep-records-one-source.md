# M090: The sweep's page list and gating modes each have one source

- **Status:** review
- **Priority:** normal
- **Depends on:** M089
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — the sweep's own page and mode records, none of them shipped in the built package
- **Branch/PR:** `m090-sweep-records-one-source`

## Goal

`benchmarks/sweep-prose.R` holds the only copy of its page list and of its gating invocations, and every other reader takes the list from the script.

## Scope

**In:** two listing modes on `benchmarks/sweep-prose.R`, the real-pages block of `tests/testthat/test-sweep-prose.R`, and the `consistency-gate` slot of `cairn/PROFILE.md`.

**Out:**
- A checker that compares the workflow's steps against the script after this milestone. The plan gate chose removing copies over checking them. That remainder goes to the candidate row this plan writes.
- The six named steps in `.github/workflows/prose-sweep.yaml`. They stay as the one accepted copy, because a red run then names the failing mode on the job summary.
- The two plain modes the `verify` slot names. They are a deliberate subset, not a copy of the six.
- The parser, which is M089.

## Acceptance criteria

- [x] AC1: `tests/testthat/test-sweep-prose.R` names no page path of its own. Its real-pages block takes the page list from the script. Evidence: `grep -nE 'vignettes/|README\.Rmd' tests/testthat/test-sweep-prose.R` returns nothing, and the block passes under `devtools::test()`.
- [x] AC2: The script prints its two lists on request. `Rscript benchmarks/sweep-prose.R --list-pages` prints the six page paths, one per line. `Rscript benchmarks/sweep-prose.R --list-gating` prints the six gating invocations, one per line. Both exit 0. Evidence: the two outputs.
- [x] AC3: The `consistency-gate` slot of `cairn/PROFILE.md` enumerates no sweep mode. It names the script's listing instead. Evidence: `sed -n '/^## consistency-gate/,/^## /p' cairn/PROFILE.md | grep -nE '\-\-(spans|plain|roxygen|terms|openings|paragraphs|list-)'` returns only the line that names the listing mode.
- [x] AC4: `.github/workflows/prose-sweep.yaml` runs one step per invocation that `--list-gating` prints, and no other sweep step. Evidence: the mode's output compared line by line against `grep -n 'sweep-prose.R' .github/workflows/prose-sweep.yaml`, both outputs recorded in this file's Review section.
- [x] AC5: The six gating sweeps print `clean` and exit 0. `Rscript -e 'devtools::test()'` runs clean. `Rscript -e 'devtools::check()'` reports 0 errors, 0 warnings and 0 notes.

## Coverage

- AC1 → T2
- AC2 → T1
- AC3 → T3
- AC4 → T1, T4
- AC5 → T5

## Tasks

- [x] T1: Add `--list-pages` and `--list-gating` to `benchmarks/sweep-prose.R`. Each reads the one declaration the script holds. Document both in the header's Modes block.
- [x] T2: Rewrite the real-pages block of `tests/testthat/test-sweep-prose.R`. It reads `--list-pages` for its page list and `--list-gating` for its `modes` list. Both hardcoded copies go.
- [x] T3: Replace the mode enumeration in the `consistency-gate` slot of `cairn/PROFILE.md` with a pointer at `--list-gating`. Leave the `verify` slot's two plain modes as they are.
- [x] T4: Compare `--list-gating` against the workflow's six steps and record the comparison. Update the yaml comment to say that the script owns the list.
- [x] T5: Run `Rscript -e 'devtools::test()'`, then `Rscript -e 'devtools::check()'`, then the six gating sweeps, then `air format --check` on the touched R files.

## Work log

- 2026-09-11: created by /milestone-plan. Split from M089 under the sizing tripwires, because the two halves ship on their own branches and the goal needed an "and".
- 2026-09-11: the duplication read at `c4bb5f9`. The page list sits in `benchmarks/sweep-prose.R` and again in `tests/testthat/test-sweep-prose.R`. The six gating invocations sit in the workflow's steps, in the test's `modes` list, and in the `consistency-gate` slot of `cairn/PROFILE.md`. The `verify` slot names two of the six, which is a subset rather than a copy.
- 2026-09-11: plan gate chose removing the duplicate lists over adding a mode that compares them, because a copy removed needs no checker. Falsified by the workflow's six steps drifting from the script's declaration unnoticed.
- 2026-09-11: plan gate chose keeping the workflow's six named steps over collapsing them into one. A red run then names the failing mode on the job summary. Falsified by those six steps drifting from the script's list.
- 2026-09-12: implement started on `m090-sweep-records-one-source`, cut from `origin/main` at `6436ebf`.
- 2026-09-12: question gate chose full command lines for `--list-gating`. The output then compares line for line against the workflow's `run:` lines. It also chose the effective page list for `--list-pages`, so `--pages` replaces it as in every other mode.
- 2026-09-12: T1 done. `benchmarks/sweep-prose.R` gained a `gating` vector and the two listing modes, both exiting 0, and the header's Modes block documents them. Suite clean, 9854 passing.
- 2026-09-12: T2 done. The real-pages block reads `--list-pages` and `--list-gating` and names no page path. What it states independently is shape: six pages that exist, six invocations, one of them bare, three reading roxygen. Suite clean, 9862 passing.
- 2026-09-12: T5 done. `devtools::test()` clean, 9862 passing. `devtools::check()` reports 0 errors, 0 warnings and 0 notes in 25m 36s. The six gating sweeps each print `clean` and exit 0. `air format --check` passes on both touched R files.
- 2026-09-12: claim audit: not owed — internal tier.
- 2026-09-12: T4 done. `diff <(Rscript benchmarks/sweep-prose.R --list-gating) <(sed -n 's/^ *run: //p' .github/workflows/prose-sweep.yaml)` is empty, so the six steps are the six invocations in that order and the job runs no other sweep step. The yaml comment now names the script's `gating` vector as the one declaration and the steps as its one accepted copy.
- 2026-09-12: T3 done. The `consistency-gate` slot names no sweep mode. It tells the reader to run each command `--list-gating` prints. The `verify` slot's two plain modes are untouched.
- 2026-09-12: both new reads proved able to fail. A `--plain` swapped to `--openings` in the `gating` vector turned the block red naming that mode. A page dropped from `pages` turned it red on the count.

## Decisions

## Review

Evidence gathered 2026-09-12 on `m090-sweep-records-one-source` at `46ac2a6`. `origin/main` had not moved since the branch was cut.

- AC1: `grep -nE 'vignettes/|README\.Rmd' tests/testthat/test-sweep-prose.R` printed nothing (exit 1). `devtools::test(filter = "sweep-prose")` ran FAIL 0, WARN 0, SKIP 0, PASS 70, so the real-pages block ran and passed in the source tree.
- AC2: `--list-pages` printed six paths, one per line (`vignettes/nested-cv.Rmd`, `vignettes/estimate.Rmd`, `vignettes/tuners.Rmd`, `vignettes/results.Rmd`, `vignettes/articles/parallel.Rmd`, `README.Rmd`), exit 0. `--list-gating` printed six invocations, one per line: the bare call, `--spans`, `--plain`, `--roxygen`, `--roxygen --spans`, `--roxygen --plain`, exit 0.
- AC3: the slot grep returned one line, slot line 13, the bullet telling the reader to run each command `--list-gating` prints. No other mode flag appears in the slot.
- AC4: `grep -n 'sweep-prose.R'` on the yaml returned comment lines 2, 4, 59 and 60. It also returned six `run:` lines, 66, 70, 74, 78, 82 and 86. Those six read, in order, the bare call, `--spans`, `--plain`, `--roxygen`, `--roxygen --spans`, `--roxygen --plain`, the same six lines `--list-gating` prints. `diff` of the mode's output against every `run:` line in the file was empty. The file holds six `run:` lines in all, so the job runs no other sweep step.
- AC5: each of the six commands `--list-gating` prints, run through `bash`, printed `clean` and exited 0. `devtools::test()` exited 0 with FAIL 0, WARN 0, SKIP 0, PASS 9862. `devtools::check()` reported 0 errors, 0 warnings and 0 notes in 23m 34.5s.

Consistency gate. `cairn_validate.py` exited 0, with 18 `references staleness` advisories on pages this milestone does not touch. No principle changed, so `cairn_impact` was skipped. `devtools::document()` left no diff, under a warning that the local roxygen2 is 8.0.0 against the 8.1.0 the package records. `pkgdown::check_pkgdown()` found no problems. The diff touches no `R/`, `man/`, README or NEWS file. It adds no top-level file. No NEWS entry or `.Rbuildignore` line is owed. `air format --check` passed on both touched R files.

Independent review: three fresh reviewers, because the diff touches executable files. Findings, most severe first within each lens.

- O1: `test-sweep-prose.R:213-224`. A duplicated gating line passes the shape checks, for example `--spans` listed twice in place of `--plain`. S1 states the same gap as a loss of the exact list M088's test held.
- O2: `cairn/PROFILE.md` consistency-gate slot. It says `prose-sweep.yaml` reads the list from the script, but the yaml keeps a hand-checked copy.
- O3: `test-sweep-prose.R:205-208`. A duplicated page in place of a dropped one passes the shape checks, and the dropped page is then never swept.
- O4: `sweep-prose.R:60-62`. The header says `--list-pages` prints the page list this run sweeps, but under `--roxygen` it prints the Rmd pages, which that run does not read.
- O5: `sweep-prose.R:138-145`. When both listing flags are given, `--list-pages` wins, and any other mode flag is ignored. The header does not say so.
- O6: `sweep-prose.R:113-122`. `--list-gating --pages` with no path stops on the `--pages` error, although the listing never reads pages.
- O7: `sweep-prose.R:138-141`. `--list-pages` prints paths that do not exist.
- O8: `test-sweep-prose.R:218-221`. The flag parse splits on spaces, so a quoted argument in a future gating line splits wrong.
- O9: `test-sweep-prose.R:181`. The test name still says "six". If a mode is added, the name is a third place to edit.
- S2: the workflow steps and `--list-gating` stay matched only by hand. That is the milestone's Out item and the ROADMAP candidate row this plan wrote.
- P: no prior-review evidence contradicted. The diff closes the M088 review point that the test and the profile each copied the lists.
