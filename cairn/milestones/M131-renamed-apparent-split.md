# M131: Keep a renamed apparent split out of a bootstrap design

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP3
- **Resolves:** —
- **Surface tier:** user-facing — it changes which designs the exported functions refuse
- **Branch/PR:** m131-renamed-apparent-split

## Goal

If an apparent split sits beside bootstrap or permutation splits, it counts as part of that design only if its id is "Apparent" (D-099).

## Scope

**In:** The id condition in `split_designs()`, which serves both loops at `check_nested()` and at `nested_resamples()`. A hint in the inner refusal that says tune leaves out an apparent split whose id is "Apparent". The README Refused paragraph, the shared help text, `?nested_resamples`, a NEWS bullet and the DESIGN convention bullet.

**Out:**
- An outer design that keeps the `bootstraps` rset class is refused by that class before any split is read. So a renamed apparent split in it is not named. No row, because the design is refused either way.
- An apparent split with the id "Apparent" from a separate `apparent()` call, beside outer bootstrap splits, is still named as a bootstrap row. The two splits are identical objects. No row, because no check can tell them apart.
- Take an inner design of `vfold_cv()` splits and one apparent split with the id "Apparent". It stays refused as `apparent()` (D-097), but tune leaves that split out. No row, because nothing asks for it.
- A test that watches tune's rule for leaving out the "Apparent" split joins the `[low]` README-table candidate row.

## Acceptance criteria

- [ ] AC1: Four inner designs hold bootstrap splits and one `apparent_split` whose id is not "Apparent". Three are built with `rsample::manual_rset()`. The first has three `bootstraps()` splits and the apparent split. The second has three `group_bootstraps()` splits and the apparent split. The third has two `vfold_cv()` splits, two `bootstraps()` splits and the apparent split. Each of the three is built with the apparent id "apparent" and with "Bootstrap4". The fourth is `rsample::bootstraps(times = 3, apparent = TRUE)` with its id column changed to "A" by `$<-`, so it keeps its rset class. `nested_tune_grid()` refuses each of the seven as the inner design of every outer fold, with class `nestedtune_bad_design`, before any fold runs. `nested_resamples()` refuses each of the seven as the rset an `inside` function returns. Each message names `rsample::apparent()` and does not name `bootstraps()` or `group_bootstraps()`. Each message says that tune leaves out an apparent split whose id is "Apparent". An inner `manual_rset()` of `vfold_cv()` splits and one `apparent_split` is still refused, and its message does not carry that sentence.
- [ ] AC2: Take the three `manual_rset()` designs of AC1 with the apparent id "Apparent", and once more with that id stored as a factor. Each of the six passes every entry check at `nested_tune_grid()` and reaches the fold dispatch with no `nestedtune_bad_design` error. `nested_resamples()` builds a design from an `inside` function that returns each of them.
- [ ] AC3: Two outer `manual_rset()` designs hold an `apparent_split` with the id "A" as row 6. The first has two `vfold_cv()` splits and three `bootstraps()` splits before it. The second has two `vfold_cv()` splits and three `permutations()` splits before it. `nested_tune_grid()` refuses each as the outer design, and `nested_resamples()` refuses each as `outside`, with class `nestedtune_bad_design`. Each message names row 6 as an `rsample::apparent()` row and "Rows 3, 4, and 5" as rows of the host function. Give the bootstrap design's apparent split the id "Apparent". At both entries, its message then names "Rows 3, 4, 5, and 6" as `rsample::bootstraps()` rows and does not name `apparent()`.
- [ ] AC4: Four sites state the new rule. The first is the README Refused paragraph knitted into `README.md`. The second is the shared help text at `R/nested-tune-grid.R:128`, in each page it renders into. The others are `?nested_resamples` and one new `NEWS.md` bullet. Some sentences at these sites say that an apparent split counts as part of a bootstrap or permutation design. Each such sentence also says that its id must be "Apparent".
- [ ] AC5: `devtools::test()` gives 0 failures. `devtools::check()` gives 0 errors, 0 warnings and 0 notes. `Rscript benchmarks/sweep-prose.R --plain` and `--roxygen --plain` are clean.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T1, T2
- AC4 → T3
- AC5 → T3

## Tasks

- [x] T1: Tests first, in `tests/testthat/test-design-support.R`. Build the designs with `rsample::manual_rset()` directly, because `rebuilt()` (line 326) keeps the original ids. Use `entry_refusal()` (line 163) for the `nested_tune_grid()` cases. Expect AC1's seven refusals and AC3's "A" cases to fail on the current code. Expect AC1's v-fold control, AC2 and AC3's "Apparent" case to pass today, as guards.
- [x] T2: Change `split_designs()` (`R/checks.R:458`). For an apparent split, compare `as.character()` of its row's id with "Apparent", the comparison tune makes. The host rule takes the split on a match alone, and an NA id is no match. If `x` has no id column of the same length as its splits, no apparent split joins the host. Add the hint to the inner refusals in `check_inner_refused()` (`R/checks.R:599`) and `inner_resamples_from_split()` (`R/nested-resamples.R:248`). Add it only for an element whose apparent split has bootstrap splits beside it. Hand the text to cli as a value. Update the comments at `R/checks.R:479`.
- [ ] T3: Documentation and checks. Change the Refused paragraph in `README.Rmd` and run `devtools::build_readme()`. Change the help at `R/nested-tune-grid.R:128` and `R/nested-resamples.R:40`, add the NEWS bullet, and update the DESIGN.md convention bullet on invalid designs. Run `devtools::document()`, both prose sweeps, `devtools::test()` and `devtools::check()`.

## Work log

- 2026-09-29: created by /milestone-plan. It absorbs the M129 review candidate row (findings O3 and O4).
- 2026-09-29: criteria audit ran in full mode (fresh [O] reader) and found 9 items. It asked for a D-entry for the narrowed D-097 rule and a bootstraps case that keeps its class. It asked for tune's id comparison, which accepts a factor, and for the permutation and `nested_resamples(outside =)` paths. It asked for cli's serial comma and an AC2 promise about the package, not the test stand-in. It asked for named doc sites in AC4 in place of a grep, and direct `manual_rset()` builds in T1. It found the class-kept outer bootstrap limit unstated. All were fixed before the gate.
- 2026-09-29: plan gate chose tune's id rule. The rejected option refuses every apparent split in an inner design that lost its bootstrap class. It lost because tune leaves the "Apparent" split out, and M129 keeps such rebuilds running. Falsified by a tune release that scores a split with the id "Apparent".
- 2026-09-29: plan gate chose one id rule for both loops over keeping today's outer naming, so the two loops read a split the same way. Falsified by a supported outer design whose refusal names the wrong function.
- 2026-09-29: plan gate chose a hint in the inner refusal over a bare refusal, at priority normal.
- 2026-09-29: the revised criteria went back to the same reader for a recheck. Its result was still pending at the plan commit.
- 2026-09-29: the recheck found all 9 repairs held and 2 new items. T2 now says an NA id is no match, and AC3's last case now covers both entries.
- 2026-09-29: implement started on branch m131-renamed-apparent-split. No question gate, because the plan left no choice open.
- 2026-09-29: T1 added five test blocks to `test-design-support.R`. On the pre-fix code, the AC1 block fails (6 failures and an error) and the AC3 block fails its 8 "A" expectations. The v-fold control, AC2 and AC3's "Apparent" case pass. Checkpoint: red until T2.
- 2026-09-29: T2 code in: `apparent_ids()`, `renamed_apparent()` and the hint in `R/checks.R` and `R/nested-resamples.R`. The design-support file passes (46 blocks). T1's factor case had built the id "1" through `c()` and was fixed. T3's README.Rmd, NEWS, roxygen and DESIGN edits are in. Checkpoint: the full suite is running, and T2 is not yet ticked.
- 2026-09-29: the full suite passed on the T2 code (1157 test blocks, 0 failures), so T2 is ticked. `devtools::document()` rewrote six Rd files, `devtools::build_readme()` changed only the Refused paragraph, and both prose sweeps are clean. `devtools::check()` and a final suite run are in progress.
- 2026-09-29: claim audit: 41 claims read, 1 corrected — NEWS.md
- 2026-09-29: the corrected NEWS claim now covers a bootstraps rset renamed in place as well as a `manual_rset()` rebuild. It went back to the same reader for its one re-read, which found it true and asked only for the paragraph to be rewrapped.

## Decisions

## Review
