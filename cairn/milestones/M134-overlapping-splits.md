# M134: Refuse a split that assesses rows it trains on

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** M133
- **Driving RR:** —
- **Principles touched:** IP1, IP4, GP3, GP4
- **Resolves:** —
- **Surface tier:** user-facing — it changes which designs the exported functions refuse
- **Branch/PR:** m134-overlapping-splits

## Goal

A split that assesses rows it also trains on is refused in both loops, whatever class it carries (D-103).

## Scope

**In:** One rule with class `nestedtune_bad_design`, applied to outer and inner splits. It refuses a split whose analysis and assessment sets share a row index of the data. It applies at `check_nested()`, at `nested_resamples()` for `outside` and for each inner design from `inside`, and to the design that `nested_final_fit()` rebuilds. The bootstrap's own apparent split stays exempt where tune leaves it out. The README, three help sites, a NEWS bullet and the DESIGN convention bullet state the rule. This absorbs finding F8 of M132's review, widened after the plan-gate probes.

**Out:**
- A `make_splits()` rebuild stays unrecognized as its design (D-097). Only the overlap is refused. No row, because a rebuilt split with no overlap is a valid split.
- The race rule on the bootstrap's own apparent split is unchanged (D-100). No row.

## Acceptance criteria

- [ ] AC1: Take an outer split whose analysis set and assessment set share a row index of the data. `check_nested()` refuses the design before any fold runs, and `nested_resamples()` refuses such an `outside`. Both use class `nestedtune_bad_design`. At both sites the rule runs after the refusals that read the rset class or the split classes. The message names the row of the design that holds the split. It says that such a fold scores the model on rows it trained on. `tests/testthat/test-design-support.R` asserts the class and that reason through `nested_tune_grid()` and through `nested_resamples()`. It uses three outer `manual_rset()` designs of `vfold_cv()` splits. In the first, one split is a `make_splits()` split whose assessment rows equal its analysis rows. In the second, such a split shares one row. In the third, one split keeps its `vfold_split` class, and its `out_id` is edited to hold one of its `in_id` rows. A fourth test asserts that an outer `manual_rset()` of `apparent()` splits still gets the `apparent()` refusal. (RB tripwire: ip-touching)
- [ ] AC2: Take an inner split whose analysis set and assessment set share a row index of the data. An index into an outer analysis frame counts as the data row that the outer `in_id` maps it to. `check_nested()`, `nested_resamples()` and the design that `nested_final_fit()` rebuilds refuse it with class `nestedtune_bad_design`. At each site this rule runs after the rules of M133 AC3's first two groups. It runs before the missing-id, repeated-id and "Apparent" rules. One split is exempt under every tuner. It is a split of class `apparent_split` whose `as.character(id)` is "Apparent", beside `boot_split` or `group_boot_split` splits. tune leaves that split out of its estimates, and under the two racers the race rule still refuses it (D-100). The message names the element of `inner_resamples` or the outer fold, and the split. It says that such a split scores the model on rows it trained on. Tests assert the class and that reason in eight cases. Cases 1 to 4 use an inner design of `make_splits()` rebuilds of every split of `bootstraps(apparent = TRUE)`. Through `nested_tune_grid()`, the rebuilt apparent split carries the id "Apparent" as a character, then as a factor, then another id. Through `nested_tune_race_anova()`, it carries "Apparent". Cases 1, 2 and 4 assert that the message does not hold "Give the split another id". Case 5 runs through `nested_tune_grid()` an inner `vfold_cv()` design with one `make_splits()` split that shares one row, under an ordinary id. Case 6 is a `nested_resamples()` design whose `outside` is a `manual_rset()` of bootstrap splits rebuilt with `make_splits()`. Case 7 is an `rsample::nested_cv()` design over that outer design, run through `nested_tune_grid()`. Case 8 gives a grid result an `inside` call that builds the case 1 design on the data it gets, then calls `nested_final_fit()`. A passing control runs an inner `bootstraps(apparent = TRUE)` design through `nested_tune_grid()`.
- [ ] AC3: The README paragraph on refused designs, the design block of `?nested_resamples` and the "Nested designs" section of `?nested_tune_grid` state the rules of AC1 and AC2. The "What is refused" section of `?nested_final_fit` names the AC2 rule among the checks of its rebuilt design. One NEWS bullet states both rules.
- [ ] AC4: Every design that the README resampling table marks `Yes` still runs through `nested_tune_grid()` in that role, shown by the tests that D-095 requires. `devtools::test()` gives 0 failures. `devtools::check()` gives 0 errors, 0 warnings and 0 notes. `Rscript benchmarks/sweep-prose.R --plain` and `--roxygen --plain` are clean.

## Coverage

- AC1 → T1, T2
- AC2 → T3, T4
- AC3 → T6
- AC4 → T5, T6

## Tasks

- [x] T1: Write the AC1 tests first, in `tests/testthat/test-design-support.R`. Build the splits with `rsample::make_splits()` and wrap them with `rsample::manual_rset()`. The refusals fail on the current code, and the `apparent()` test passes.
- [x] T2: Add a helper in `R/checks.R` that finds the splits of an rset whose analysis and assessment indexes share a row, reading `rsample::complement()`. It reads only `rsplit` elements and leaves malformed ones to the later checks. Apply it to the outer splits in `check_nested()` after `check_outer_splits()` (line 383), and in `nested_resamples()` after its `check_outer_splits()` call. Give cli the reasons as values (M83 lesson).
- [x] T3: Write the AC2 tests first. The racer case skips where `tuner_ready()` is false (M101 lesson). Case 8 goes beside the "Apparent" block of `tests/testthat/test-nested-final-fit-checks.R`.
- [x] T4: Apply the helper to the inner splits. If an inner split's frame is not the outer split's own, map its indexes through the outer `in_id`. `check_inner_splits()` tells the two frames apart (`R/checks.R:1003`). Call it in `check_nested()` after `check_inner_refused()`, in `inner_resamples_from_split()` after the refused-design check, and in `check_final_inner()` after the rules of M133's AC3 first two groups. Keep the exemption in step with `misread_apparent_rows()`.
- [x] T5: Measure the added check time (GP4). Time `check_nested()` before and after the change on a `nested_resamples()` design of 10^5 rows with 10 outer and 10 inner folds. Record both times and the commit in the work log.
- [ ] T6: Update the documentation and run the checks. Change the Refused paragraph in `README.Rmd` and run `devtools::build_readme()`. Change `R/nested-resamples.R:40`, the "Nested designs" section at `R/nested-tune-grid.R:102`, and the "What is refused" section at `R/nested-final-fit.R:98`. Add the NEWS bullet, and update the DESIGN.md convention bullet on invalid designs. Run `devtools::document()`, both prose sweeps, `devtools::test()` and `devtools::check()`.

## Work log

- 2026-09-30: created by /milestone-plan, from finding F8 of the "M132's review leftovers" candidate row, split from M133 at the plan gate.
- 2026-09-30: plan-gate probes. An outer `manual_rset()` holding a `make_splits()` split with equal analysis and assessment rows ran, and the fold was scored on its training rows. A rebuilt outer bootstrap passed `nested_resamples()`, and `rsample::nested_cv()` with `check_nested()`. Of 14 supported designs, only an apparent split shared rows.
- 2026-09-30: plan gate chose refusing shared row indexes over recognizing a rebuilt split's design, since nothing in a `make_splits()` split names its design. It also rejected fixing only F8's message, which leaves the outer leak open. Falsified by a supported rsample design whose splits share rows by design, other than the bootstrap's apparent split.
- 2026-09-30: the criteria audit (see M133's work log) moved the IP1 citation to AC1 alone, since an inner overlap never reaches an outer assessment row. It also stated the rule order, the exemption and the index reading.
- 2026-09-30: the re-audit found that the exemption held only outside the racers. `check_nested()` does not know the tuner and runs before the race rule, so a racer got the overlap message as planned. The exemption now holds under every tuner, and D-104 corrects D-103. AC2 also places the rule after M133 AC3's first two groups and names case 5's entry point.
- 2026-09-30: implement started on branch `m134-overlapping-splits`. Question gate skipped: the plan leaves no API, naming or dependency choice open.
- 2026-09-30: T1 and T2 done. The AC1 refusal tests failed first (the design reached the fold dispatch), and the `apparent()` test passed. `split_shares_rows()`, `overlap_rows()` and `check_outer_overlap()` in `R/checks.R` run after `check_outer_splits()` in `check_nested()` and `nested_resamples()`. `devtools::test()` 0 failures, `--plain` sweep clean.
- 2026-09-30: T3 and T4 done. All eight AC2 cases failed first, and the new passing control (a full `nested_tune_grid()` run on an inner `bootstraps(apparent = TRUE)`) passed. `check_inner_overlap()` runs after `check_inner_refused()`, and the same rule runs in `inner_resamples_from_split()` and `check_final_inner()` after the refused-design checks. `bootstrap_apparent()` now holds the exemption for both this rule and `misread_apparent_rows()`. `inner_frame_kinds()` was split out of `check_inner_splits()` so both rules tell the two frames apart the same way.
- 2026-09-30: minor amendment, two older tests adjusted. The M55 plant `index_held_out_both` put one outer held-out row in both slots of an inner split, which the new rule now refuses first, so it now plants two different held-out rows and still tests the containment message. The finalize test on an outer split that repeats rows now groups its inner folds on `x1`, so the copies of a row never split across one inner split. `devtools::test()` 0 failures, `--plain` sweep clean.
- 2026-09-30: T5 done. The design has 10^5 rows and 10 outer by 10 inner v-folds, timed as the median of 5 runs of `check_nested()`. On a `nested_resamples()` design it took 1.085 s at main `b182fa6a` and 1.160 s at the T5 commit. On an `rsample::nested_cv()` design of the same size it took 0.008 s and 0.109 s. The first version cost 0.8 s more on the second design, because rsample's `complement()` calls `unique()` on the training rows. `split_shares_rows()` now marks a logical vector instead, and it skips `complement()` for a split that rsample's default method reads with a missing `out_id`. `devtools::test()` 0 failures, `--plain` sweep clean.
- 2026-09-30: T6 checkpoint, not yet checked off. The README, the three help sites, NEWS and the DESIGN bullet state both rules. All six gating sweeps are clean and `devtools::test()` gives 0 failures. `devtools::check()` is still running.

## Decisions

## Review
