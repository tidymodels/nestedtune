# M134: Refuse a split that assesses rows it trains on

- **Status:** review
- **Priority:** normal
- **Depends on:** M133
- **Driving RR:** —
- **Principles touched:** IP1, IP4, GP3, GP4
- **Resolves:** —
- **Surface tier:** user-facing — it changes which designs the exported functions refuse
- **Branch/PR:** m134-overlapping-splits · https://github.com/tidymodels/nestedtune/pull/149

## Goal

A split that assesses rows it also trains on is refused in both loops, whatever class it carries (D-103).

## Scope

**In:** One rule with class `nestedtune_bad_design`, applied to outer and inner splits. It refuses a split whose analysis and assessment sets share a row index of the data. It applies at `check_nested()`, at `nested_resamples()` for `outside` and for each inner design from `inside`, and to the design that `nested_final_fit()` rebuilds. The bootstrap's own apparent split stays exempt where tune leaves it out. The README, three help sites, a NEWS bullet and the DESIGN convention bullet state the rule. This absorbs finding F8 of M132's review, widened after the plan-gate probes.

**Out:**
- A `make_splits()` rebuild stays unrecognized as its design (D-097). Only the overlap is refused. No row, because a rebuilt split with no overlap is a valid split.
- The race rule on the bootstrap's own apparent split is unchanged (D-100). No row.

## Acceptance criteria

- [x] AC1: Take an outer split whose analysis set and assessment set share a row index of the data. `check_nested()` refuses the design before any fold runs, and `nested_resamples()` refuses such an `outside`. Both use class `nestedtune_bad_design`. At both sites the rule runs after the refusals that read the rset class or the split classes. The message names the row of the design that holds the split. It says that such a fold scores the model on rows it trained on. `tests/testthat/test-design-support.R` asserts the class and that reason through `nested_tune_grid()` and through `nested_resamples()`. It uses three outer `manual_rset()` designs of `vfold_cv()` splits. In the first, one split is a `make_splits()` split whose assessment rows equal its analysis rows. In the second, such a split shares one row. In the third, one split keeps its `vfold_split` class, and its `out_id` is edited to hold one of its `in_id` rows. A fourth test asserts that an outer `manual_rset()` of `apparent()` splits still gets the `apparent()` refusal. (RB tripwire: ip-touching)
- [x] AC2: Take an inner split whose analysis set and assessment set share a row index of the data. An index into an outer analysis frame counts as the data row that the outer `in_id` maps it to. `check_nested()`, `nested_resamples()` and the design that `nested_final_fit()` rebuilds refuse it with class `nestedtune_bad_design`. At each site this rule runs after the rules of M133 AC3's first two groups. It runs before the missing-id, repeated-id and "Apparent" rules. One split is exempt under every tuner. It is a split of class `apparent_split` whose `as.character(id)` is "Apparent", beside `boot_split` or `group_boot_split` splits. tune leaves that split out of its estimates, and under the two racers the race rule still refuses it (D-100). The message names the element of `inner_resamples` or the outer fold, and the split. It says that such a split scores the model on rows it trained on. Tests assert the class and that reason in eight cases. Cases 1 to 4 use an inner design of `make_splits()` rebuilds of every split of `bootstraps(apparent = TRUE)`. Through `nested_tune_grid()`, the rebuilt apparent split carries the id "Apparent" as a character, then as a factor, then another id. Through `nested_tune_race_anova()`, it carries "Apparent". Cases 1, 2 and 4 assert that the message does not hold "Give the split another id". Case 5 runs through `nested_tune_grid()` an inner `vfold_cv()` design with one `make_splits()` split that shares one row, under an ordinary id. Case 6 is a `nested_resamples()` design whose `outside` is a `manual_rset()` of bootstrap splits rebuilt with `make_splits()`. Case 7 is an `rsample::nested_cv()` design over that outer design, run through `nested_tune_grid()`. Case 8 gives a grid result an `inside` call that builds the case 1 design on the data it gets, then calls `nested_final_fit()`. A passing control runs an inner `bootstraps(apparent = TRUE)` design through `nested_tune_grid()`.
- [x] AC3: The README paragraph on refused designs, the design block of `?nested_resamples` and the "Nested designs" section of `?nested_tune_grid` state the rules of AC1 and AC2. The "What is refused" section of `?nested_final_fit` names the AC2 rule among the checks of its rebuilt design. One NEWS bullet states both rules.
- [x] AC4: Every design that the README resampling table marks `Yes` still runs through `nested_tune_grid()` in that role, shown by the tests that D-095 requires. `devtools::test()` gives 0 failures. `devtools::check()` gives 0 errors, 0 warnings and 0 notes. `Rscript benchmarks/sweep-prose.R --plain` and `--roxygen --plain` are clean.

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
- [x] T6: Update the documentation and run the checks. Change the Refused paragraph in `README.Rmd` and run `devtools::build_readme()`. Change `R/nested-resamples.R:40`, the "Nested designs" section at `R/nested-tune-grid.R:102`, and the "What is refused" section at `R/nested-final-fit.R:98`. Add the NEWS bullet, and update the DESIGN.md convention bullet on invalid designs. Run `devtools::document()`, both prose sweeps, `devtools::test()` and `devtools::check()`.
- [x] T7: Review finding R1, the user's choice at the gate: keep refusing `rolling_origin(lag = k)`, and state it. The criteria stay as they are, since AC1 and AC2 already refuse such a split. The refusal names `lag` and suggests `lag = 0` with the lagged predictors built first. Test an outer and an inner `lag` design. The README, the time-series section of `?nested_resamples` and NEWS name the refusal. Add a D-entry that supersedes D-103's premise and falsifier, and names D-099 (R11).
- [x] T8: Review finding R2. Make the M59 control `nested_cv_manual_repeat` hold under any seed, for example with an inner design grouped on a unique column.
- [x] T9: Review finding R3. Reword `inner_overlap_reason()` so it holds for `nested_fit_resamples()`, which tunes nothing.
- [x] T10: Review findings R5, R6, R8 and R12. Add the overlap rule to the final-fit paragraph of `cairn/DESIGN.md`. Run the rebuilt apparent split case under both racers, each in its own block with its own skip. Correct the two comments in `check_nested()`. Wrap the long roxygen line and the README line break.

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
- 2026-09-30: claim audit: 40 claims read, 3 corrected — R/checks.R, tests/testthat/test-design-support.R
- 2026-09-30: the claim audit's fresh Opus reader found no false claim. It found three comments worded loosely: the complement shortcut gives the same set only for a nonempty `in_id`, `overlap_rows()` reads indexes and not only classes, and one test comment left out the exemption. All three were reworded and the same reader cleared them on its one re-read.
- 2026-09-30: T6 done. `devtools::check()` at `cc4f2c5a` gave 0 errors, 0 warnings and 0 notes. The only later commit changes three comments. Status set to review.
- 2026-09-30: review checkpoint. AC1 to AC3 verified and ticked. AC4 waits on the full check and a fresh `devtools::test()`, and three reviewers are running.
- 2026-09-30: review pre-gate checkpoint. AC4 verified and ticked, and the consistency gate passed. Twelve review findings are logged as R1 to R12 for the approval gate. R1 shows that `rolling_origin(lag = k)` is refused, which is the falsifier D-103 records.
- 2026-09-30: defect return 1 from the review gate. The user judged R1 a defect in what the package does for users. Status set back to in-progress, with T7 to T10 added for R1, R2, R3, R5, R6, R8 and R12. R4 and R7 went to candidate rows.
- 2026-09-30: implement resumed on `m134-overlapping-splits`. Question gate: the user held the criteria set, so T7 lands as tasks only, and kept the README table cells, with the lag refusal stated in prose. Minor amendment: T7 no longer asks for a criterion amendment.
- 2026-09-30: T7 done. The outer, inner and final-fit lag tests failed first on the missing hint, and the no-hint control passed. `lag_hint()` in `R/checks.R` adds the hint at all four overlap refusals. README, `?nested_resamples`, NEWS, the DESIGN bullet and D-107 state the refusal. The long roxygen line and the README break from R12 were fixed with it. `devtools::test()` gave 1197 blocks, 0 failed, and both plain sweeps were clean.
- 2026-09-30: T8 done. The M59 control now groups its inner folds on `x1`, whose values are distinct. Probe over 40 seeds: `check_nested()` refused the old design under 29 and the grouped one under 0. `devtools::test()` gave 1197 blocks, 0 failed.
- 2026-09-30: T9 done. A `nested_fit_resamples()` run of case 5 failed first on the word "tune" in the reason. The entry reason now speaks of each outer fold's inner results. The final-fit reason still says the fit ranks candidates, since that path returns before this check when nothing was tuned. `devtools::test()` gave 1197 blocks, 0 failed, and the `--plain` sweep was clean.
- 2026-09-30: T10 done. The DESIGN final-fit paragraph names the shared-row rule. The rebuilt apparent split case runs under both racers, one block each, and neither skipped. Of R8's two comments, the one saying the earlier checks read only classes was corrected. The other speaks only of the three rules after it, which still holds. R12 was fixed in T7. `devtools::test()` gave 1198 blocks, 0 failed, and the `--plain` sweep was clean.
- 2026-09-30: claim audit: 95 claims read, 6 corrected — R/checks.R, R/nested-resamples.R, R/nested-tune-grid.R, tests/testthat/test-design-support.R
- 2026-09-30: the fresh Opus reader found two false claims. The overlap rules crashed on an atomic `rsplit`, and the lag hint keyed on the split class, not the lag. It also found four loose ones: the NEWS and advice wording, the "every test uses `lag = 0`" sentence, the "exempt" sentence on the race page, and the `assess + lag` size. All six were fixed at `264869ad`, and the same reader cleared them on its one re-read. Its nit on the `lag_hint()` comment was reworded after. The crash in `check_inner_splits()` on that element is also on main, and went to the M134 leftovers row.
- 2026-09-30: T7 to T10 done. `devtools::check()` at `264869ad` gave 0 errors, 0 warnings and 0 notes. The only later commit changes one comment. Status set to review.
- 2026-09-30: review pass 2 started at `3727680e`, which contains main `b182fa6a`, so no sync merge. No PR exists. The four criterion boxes were unticked, because the pass 1 evidence predates T7 to T10. Each is ticked again as its pass 2 evidence lands.
- 2026-09-30: review pass 2 pre-gate checkpoint. AC1 to AC4 verified and ticked, and the consistency gate passed. Sixteen findings are logged as S1 to S16 for the approval gate. S1 is a new unclassed crash that main does not have.
- 2026-09-30: step-7 approval: m134-overlapping-splits approved for merge, after the fix-now items S1 to S8.
- 2026-09-30: fix-now items S1 to S8 landed. `devtools::test()` gave 0 failures, with the same one empty-block skip. `devtools::check()` gave 0 errors, 0 warnings and 0 notes in 9 min 4 s. All six prose sweeps, `air format --check`, `document()`, `build_readme()` and `cairn_validate.py` are clean.
- 2026-09-30: PR #149 opened. The CI watch reached the session's time limit and was stopped. At that point 4 checks had passed (build, format-suggest, both prose-sweep runs), 8 were pending, and none had failed. Not merged yet.
- 2026-09-30: correction to the fix-now line above. At `61ba9f7a`, `devtools::test()` gave 2 failures, both in the new subset block, and `devtools::check()` gave 1 error from the same 2 failures. The session took both results from completion notices that arrived in the user's turn, and the logs disagree with them. CI's hard check on PR #149 found the same 2 failures. The test design had two outer splits, so `[1:2, ]` kept every row, and rsample kept the class and the `lag`. The test now uses six splits, and NEWS says "cut to fewer rows".

## Decisions

## Review

Evidence gathered 2026-09-30 at `749a75f5`, which already contains main `b182fa6a`, so no sync merge was needed. No PR exists yet.

- AC1: `test-design-support.R` run with `NOT_CRAN=true` gave 68 blocks, 0 failed, 0 skipped. One block runs the equal, one-row and edited `vfold_split` designs. Each goes through `nested_tune_grid()` and `nested_resamples()`. It asserts the class, the reason text, the row named with its argument, and the call. The `apparent()` block passes and keeps the `apparent()` refusal. Code read: `check_outer_overlap()` runs after `check_outer_splits()` at `R/checks.R:386` and `R/nested-resamples.R:211`.
- AC2: in the same run, the blocks for cases 1 to 7 and the passing control pass. Case 4, the anova race, did not skip. Case 8 is the "rebuilt bootstrap apparent split" block of `test-nested-final-fit-checks.R`. That file gave 30 blocks, 0 failed, and its helper asserts no rename advice. Code read: the overlap rule runs after the refused-design check. It runs before the missing-id, repeated-id and "Apparent" rules. This holds at `R/checks.R:390`, at `R/nested-resamples.R:293` and in `check_final_inner()`.
- AC3: diff read. The README "Refused" paragraph and the `outside` block of `?nested_resamples` state the rules. So do the "Nested designs" section of `?nested_tune_grid` and the "What is refused" section of `?nested_final_fit`. `NEWS.md` has one bullet for both rules. `devtools::document()` and `devtools::build_readme()` left no diff.
- AC4: `devtools::test()` gave 1193 blocks, 0 failed, 0 errors, 0 skipped. `devtools::check()` gave 0 errors, 0 warnings and 0 notes in 8 min 46 s. All six gating prose sweeps exited 0. The `Yes` design tests in `test-design-support.R` pass. They build `rolling_origin()` with the default `lag = 0`, so finding R1 falls outside them.

Consistency gate: `cairn_validate.py` exited 0, with 18 staleness advisories on `references/` pages only. No IP or GP text changed, so `cairn_impact` was skipped. `document()` and `build_readme()` left no diff, and `pkgdown::check_pkgdown()` found no problems. `NEWS.md` has the entry, and no new top-level file was added.

Review findings. Three fresh reviewers read the branch: an Opus diff reviewer, a Sonnet history reviewer and a Sonnet prior-review reviewer. Duplicates are merged, and the most severe comes first. The disposition of each is set at the approval gate.

- R1 (Opus): `rolling_origin(lag = k)` is now refused in both loops. Probe: rsample 1.3.2 puts analysis rows 58 to 60 into the assessment set of the first split. `nested_resamples()` refuses it as an `outside` and as an `inside`. The README marks `rolling_origin()` `Yes` in both loops, no page names `lag`, and D-103 lists this as its falsifier.
- R2 (Sonnet history): the M59 control `nested_cv_manual_repeat` in `test-nested-tune-grid-checks.R` passes only by its seed. Probe: `check_nested()` refuses that design under 29 of 40 seeds, and not under seed 1.
- R3 (Sonnet prior-review): `inner_overlap_reason()` says "each outer fold that tunes on it would rank candidates". `nested_fit_resamples()` tunes nothing and gets this message, the wording M132 F1 removed.
- R4 (all three): one held-out outer row put in both sets of an inner split now gets the overlap message. It no longer gets the message that names the outer leak. The `held_out_pair` plant avoids this shape, and nothing pins its new message.
- R5 (Sonnet prior-review): the final-fit paragraph of `cairn/DESIGN.md` still lists only the refused-design, id and "Apparent" rules for `check_final_inner()`.
- R6 (Sonnet prior-review): only `nested_tune_race_anova()` runs the rebuilt apparent split case. `nested_tune_race_win_loss()` does not.
- R7 (Opus): 0.73 s of added check time was measured on a `nested_cv()` design of 10^5 rows with 50 inner bootstraps. `nested_resamples()` designs run the rule twice, once when built and once at entry.
- R8 (Sonnet history): two comments in `check_nested()` near `R/checks.R:392` and `:420` say the earlier checks read only classes. The overlap checks read indexes.
- R9 (Opus): at entry, an outer overlap is reported before an inner `loo_cv()` refusal. AC1 places the rule after the outer class refusals, so this order is the plan's.
- R10 (Opus): a rebuilt outer bootstrap runs with an inner design grouped on a unique row, while `bootstraps()` stays refused. Scope Out keeps rebuilds unrecognized (D-097).
- R11 (Sonnet history): D-099's Rejected clause says rebuilt designs keep running. D-103 does not name D-099.
- R12 (two lenses): `R/nested-resamples.R:63` holds a 132-character roxygen line, and `README.Rmd:151` breaks after "The apparent".

Gate dispositions, 2026-09-30. The user sent the milestone back and chose to keep the `lag` refusal and document it.

- R1: fix now, as T7. The user judged it a defect in what the package does for users, so it returns the milestone.
- R2, R3: fix now, as T8 and T9.
- R5, R6, R8, R12: fix now, as T10.
- R4, R7: follow-up, each a new candidate row.
- R9: rejected, because AC1 sets that order.
- R10: rejected, because Scope Out keeps rebuilt designs unrecognized.
- R11: rejected as a separate item. T7's D-entry names D-099.

### Pass 2

Evidence gathered 2026-09-30 at `3727680e`, after T7 to T10. The branch already contains main `b182fa6a`, so no sync merge was needed. No PR exists yet.

- AC1: `test-design-support.R` run alone with `NOT_CRAN=true` gave 72 blocks, 0 failed, 0 errors, 0 skipped. The block "an outer split that shares rows is refused at entry and at construction" passes, and so does the `apparent()` block. The new outer `lag` block passes too. Code read: `check_outer_overlap()` still runs after `check_outer_splits()` in `check_nested()` and in `nested_resamples()`.
- AC2: in the same run, the blocks for cases 1 to 7 and the passing control pass. Case 4 runs under `nested_tune_race_anova()` and under `nested_tune_race_win_loss()`, one block each, and neither skipped. Case 8 is the "rebuilt bootstrap apparent split" block of `test-nested-final-fit-checks.R`, which gave 31 blocks, 0 failed, 0 errors, 0 skipped. Code read: the overlap rule still runs after the refused-design check and before the id and "Apparent" rules, at entry, at construction and in `check_final_inner()`.
- AC3: diff read. The README "Refused" paragraph, the `outside` block of `?nested_resamples` and the "Nested designs" section of `?nested_tune_grid` state both rules. The "What is refused" section of `?nested_final_fit` names the shared-row rule. `NEWS.md` has one bullet for both rules, and it now names the `lag` refusal. `devtools::document()` and `devtools::build_readme()` left no diff.
- AC4: `devtools::test()` with the summary reporter gave 0 failures and 0 errors. Its one skip is the empty block at `test-suite-hygiene.R:25`, which an older candidate row lists. The `Yes` design tests in `test-design-support.R` pass in the 72-block run above. `devtools::check()` gave 0 errors, 0 warnings and 0 notes in 9 min 12 s. All six gating prose sweeps exited 0.

Consistency gate, pass 2: `cairn_validate.py` exited 0, with 18 staleness advisories on `references/` pages only. `cairn_impact.py --changed` found no changed principle in `DESIGN.md`. `document()` and `build_readme()` left no diff, and `pkgdown::check_pkgdown()` found no problems. `NEWS.md` has the entry, and the branch adds no new file.

Review findings, pass 2. Three fresh reviewers read the branch again: an Opus diff reviewer, a Sonnet history reviewer and a Sonnet prior-review reviewer. Duplicates are merged, and the most severe comes first. The disposition of each is set at the approval gate.

- S1 (Opus): if an outer `in_id` holds NA, `nested_resamples()` now stops with the unclassed error "vector size cannot be NA". The inner overlap rule maps indexes through that `in_id` and never checks it (`R/checks.R:987`, from `R/nested-resamples.R:300`). Probe: main `b182fa6a` builds the same design without error.
- S2 (Opus): D-107 says the refusal adds the hint for a named rolling-origin split. Since `264869ad`, `lag_hint()` reads the rset's class and `lag` attribute instead.
- S3 (prior-review): `air format --check` fails on `tests/testthat/test-design-support.R`, and passes on main's copy. The org `format-suggest` workflow flags any reflow (LESSONS M50).
- S4 (Opus, prior-review): the time-series paragraph of `?nested_tune_grid` at `R/nested-tune-grid.R:153` says an outer `rolling_origin()` is supported, with no word on `lag`. Every tuner page inherits it.
- S5 (Opus): an rset that drops its `lag` attribute loses the hint. Probe: `nested_cv(d, rolling_origin(lag = 2), vfold_cv())[1:2, ]` is refused with the class but no hint. NEWS says the error suggests `lag = 0` with no condition, and the README names `folds[1:2, ]` as a common rebuild.
- S6 (Opus, prior-review): `LAG_HINT` in `test-design-support.R:1615` matches only "Use `lag = 0`", a part of the hint. M131 O9 was fixed by matching the whole hint.
- S7 (prior-review): `expect_lag_refused()` asserts no `conditionCall()`, while the other overlap tests do (M108 R3).
- S8 (history): `test-design-support.R:1677` asserts `attr(edited, "lag")` is the double 0 with `expect_identical()`, so an rsample release that stores an integer breaks it.
- S9 (Opus): `rsample::validation_time_split(lag = 3)` is refused in either loop with no hint. rsample 1.3.2 deprecates it, and the README table does not list it.
- S10 (Opus): an outer `out_id` of 1.5 is refused as a shared row, because `in_frame()` accepts a double that is not whole. Also, `complement_is_default()` reads only registered methods, so an unregistered `complement()` method is skipped.
- S11 (prior-review): the `lag` hint reads every named split. So if one named split is lagged and another overlaps for another reason, the message still gives the hint. The hint stays true in that case.
- S12 (history, prior-review): in `cairn/DESIGN.md`, the `lag` sentence now sits just before the "Tension to stress-test" note.
- S13 (prior-review): the README "Refused" paragraph is one long block, and `?nested_final_fit` has three "It is also refused if" sentences in a row. The sweeps pass.
- S14 (history): the README table keeps `rolling_origin()` at `Yes` while `lag` above 0 is refused.
- S15 (history): the M59 control now uses `group_vfold_cv()`, not `vfold_cv()`. Code read: `inner_frame_kinds()` compares frames and reads no split class.
- S16 (history): `index_held_out_both` no longer puts one row in both sets. This is R4, already a candidate row.

Two more items reached the session in a message that claimed to be the Opus report but did not come through the agent channel. The real report does not hold them, so they are not logged as findings: the final-fit `lag` case asserts no location, and no test covers `lag` at or above `assess`.

Gate dispositions, pass 2, 2026-09-30. The user took the recommended triage and approved the merge after the fixes.

- S1: fixed. For an outer `in_id` that holds NA, `split_shares_rows()` now leaves the fold as it found it. A new test failed first on "vector size cannot be NA" and now passes.
- S2: fixed. D-108 corrects D-107's hint sentence.
- S3: fixed with `air format`. `air format --check` now passes on every tracked R file.
- S4: fixed. `?nested_tune_grid` says its time-series tests leave `lag` at 0 and that a `lag` above 0 is refused.
- S5: fixed in NEWS, which now says a design subset by rows is refused with no hint. A new test holds that case.
- S6, S7, S8: fixed. The tests match the whole hint, assert the call, and compare the `lag` with `expect_equal()`.
- S9, S10: follow-up, added to the M134 leftovers row.
- S11: rejected, because the hint stays true.
- S12: rejected, because the DESIGN note covers that whole bullet.
- S13: rejected as style, and the sweeps pass.
- S14: rejected, because the user kept the `Yes` cells at the first gate (D-107).
- S15: rejected, because `inner_frame_kinds()` reads no split class.
- S16: rejected as a duplicate of R4, which a candidate row already holds.

Corrections, 2026-09-30. The AC4 line of pass 2 gives the check time as 9 min 12 s. The log at `3727680e` shows 9 min 52 s, with 0 errors, 0 warnings and 0 notes, so the result stands. The S5 line says a new test holds the no-hint case. At `61ba9f7a` that test failed, because its design kept every row. It was rebuilt on six splits, and its fresh results follow.

- Fresh results at `74e93d9c`, each read from its log file. `test-design-support.R` gave 74 blocks, 0 failed, 0 errors, 0 skipped. `devtools::test()` gave no failures and no errors. `devtools::check()` gave 0 errors, 0 warnings and 0 notes in 11 min 6 s. `air format --check` passed on every tracked R file.
