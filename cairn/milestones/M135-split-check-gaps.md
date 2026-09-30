# M135: Close the split-check gaps M134's review left

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, GP3, GP4
- **Resolves:** —
- **Surface tier:** user-facing — the refusals and check time of every exported orchestrator and `nested_resamples()`
- **Branch/PR:** —

## Goal

The split checks give the right refusal on each shape M134's review logged, in a fraction of their present time on large inner designs.

## Scope

**In:** items (1), (2), (3) and the second half of (5) of the M134 leftovers row. Each was probed at this plan's gate on main `91c54eb6`.

- (3) An integer or character vector with class `rsplit` crashes `check_nested()` in `check_inner_splits()` (`R/checks.R:1513`). An outer one crashes it at `split[["data"]]`. The same outer element crashes `nested_resamples()` with "$ operator is invalid for atomic vectors". So does such an element in the rset of an `inside` call (`R/nested-resamples.R:359`).
- (1) An outer held-out row in both sets of an inner split gets the shared-rows message. `check_inner_overlap()` (`R/checks.R:1102`) runs before the containment rule that names the leak.
- (5b) `complement_is_default()` (`R/checks.R:997`) reads only the rsample registration table. So it skips a `complement()` method defined in the global environment. In the probe, a split whose method returns analysis rows passed.
- (2) The design had 10^5 rows, 10 outer v-folds and 50 inner bootstraps. On an `rsample::nested_cv()` design, `check_nested()` took 0.97 s, nearly all in the overlap rule. On a `nested_resamples()` design it took 10.2 s. Of that, 94% was `%in%` in the containment loop of `check_inner_splits()` (`R/checks.R:1570`, M59).

D-109 records the message change of item (1) as a narrowing of D-103.

**Out:**
- Item (4), the missing `lag` hint for the deprecated `rsample::validation_time_split()`, and the first half of item (5), a non-whole index. D-109 drops both, with reasons. No row.
- The rules still run twice on a `nested_resamples()` design. Once both rules are fast, the second run costs little. No row.
- Every other malformed split shape stays with the checks that judge it now. No row.

## Acceptance criteria

- [ ] AC1: Take an integer vector or a character vector with class `rsplit`. `check_nested()` refuses a design that holds one in its outer `splits` column or in an inner `splits` column. `nested_resamples()` refuses an `outside` that holds one in its `splits` column, and an `inside` call whose rset holds one. Each refusal has class `nestedtune_bad_design`. Its message names the position of the element and says that the element is not a list. On main, none of the eight cases gives an error of that class. In a design with no other defect, a test covers each of the eight cases (four sites by two vector types). It asserts the class, the position and the not-a-list wording. One more case puts two such elements in one column and asserts both positions.
- [ ] AC2: In a design with no other defect, take an inner split built on the frame of its outer split. Its analysis and assessment sets share only rows that the outer split holds out. `check_nested()` refuses it with the containment headline, which says that the inner split indexes rows its outer fold does not hold. It does not give the shared-rows headline. Two tests plant a held-out row in both sets. One puts it in an explicit `out_id`. The other gives an `NA` `out_id` and a `complement()` method in the global environment that returns the row. A third test plants a row that the outer split holds in both sets, and asserts the shared-rows headline.
- [ ] AC3: Take a split whose class has a `complement()` method that rsample did not register. The method is defined in the global environment or in an environment attached to the search path. The overlap rule reads the rows that method returns. With a method that returns a row of the analysis set of the split, `check_nested()` refuses the design with the shared-rows headline. This holds for an outer split and for an inner split. Main runs each of these designs. One test covers each of the four cases (two places by two loops).
- [ ] AC4: Two designs have 10^5 rows, 10 outer v-folds and 50 inner bootstraps. `rsample::nested_cv()` builds one and `nested_resamples()` builds the other. On each design, the median of 5 runs of `check_nested()` falls by at least 80% against the code at the plan commit. Both code versions are timed in the same R session.
- [ ] AC5: `NEWS.md` names the three changed refusals and the faster check under the development heading. `devtools::test()` gives 0 failures. `devtools::check()` gives 0 errors and 0 warnings. Every gating prose sweep exits 0.

## Coverage

- AC1 → T1
- AC2 → T3
- AC3 → T2
- AC4 → T4, T5
- AC5 → T6

## Tasks

- [ ] T1: In the first rule of `check_inner_splits()` and in the outer `splits` class check of `check_nested()`, count an element that is not a list as not an `rsplit`. The message says that the element is not a list, not that it lacks the class. In `nested_resamples()`, check the splits of `outside` the same way before any split is read. Check the splits of each `inside` rset before the remap in `R/nested-resamples.R:359`. Write the AC1 tests first, and see each fail on main.
- [ ] T2: Make `complement_is_default()` also look for a `complement.<class>` method in the environments that S3 dispatch searches from the calling namespace. Use base R only, with no `utils` import. Write the four AC3 tests first. Assign each method into `globalenv()` or an attached environment, and remove it on exit.
- [ ] T3: In `fold_overlap_rows()`, take a fold whose inner splits carry the outer frame. Count only the shared rows that the outer `in_id` holds, so the containment rule gets a held-out row. Write the three AC2 tests first. The second one needs T2.
- [ ] T4: Write `benchmarks/split-check-speed.R`. It exports the plan commit with `git archive` and loads that tree and the working tree in turn with `pkgload::load_all()`. For each tree, it builds the two AC4 designs with a fixed seed, times `check_nested()` 5 times on each, and prints the medians. Run it on the plan commit alone and record the medians in the work log.
- [ ] T5: Make the two slow parts faster with no change to any refusal. In `split_shares_rows()`, if `rows` repeats no value, return FALSE for a default-complement split. Check that once per fold, not once per split. In the containment loop of `check_inner_splits()`, mark the outer `in_id` once per fold in a logical vector, in place of `%in%` for each split. Run the T4 script and record the four medians.
- [ ] T6: Add the NEWS bullet. Then run the full verify slot and `devtools::check()`.

## Work log

- 2026-09-30: created by /milestone-plan.
- 2026-09-30: user override: the user chose the M134 leftovers row at the scope question, though its promotion condition (a user report) has not fired.
- 2026-09-30: criteria audit (full mode, fresh Opus reader) found no unreachable criterion and seven findings. Fixed before the gate: AC1 gains the `inside` site, the not-a-list wording and a two-element case, and says "no error of that class" in place of "unclassed". AC2 gains "no other defect" and an `NA` `out_id` plant, and T3 lost a clause on a plant that cannot reach the rule. AC3 gains the inner loop. AC4's script clause moved to T4, which now times both trees in one session. The D-103 narrowing went to the gate and D-109.
- 2026-09-30: plan gate chose the containment message for a held-out row in both sets over keeping the shared-rows message, because the containment message names the leak IP1 forbids; falsified by a user who reads the shared-rows message as the more useful one.
- 2026-09-30: plan gate chose a base-R walk of the dispatch environments in `complement_is_default()` over `utils::getS3method()`, because `utils` is not in Imports and a dependency change needs its own gate; falsified by a dispatch path the walk misses that `getS3method()` finds.
- 2026-09-30: plan gate chose timing both code versions in one session over two separate runs, because laptop throttling spread one tree's serial runs from 898 to 1329 s (LESSONS, M113); falsified by the two methods giving drops that differ by more than 10 points.
