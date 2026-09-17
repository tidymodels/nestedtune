# M104: An exact analytic oracle for the outer loop through the majority rule

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP2, GP4
- **Resolves:** —
- **Surface tier:** internal — a test in the package's own suite, which no external consumer relies on
- **Branch/PR:** m104-null-model-oracle

## Goal

The outer loop's estimate is checked against an exact value from theory: the mean squared error of k-fold CV for the majority rule under Bernoulli(1/2) labels.

## Scope

**In:** One test in `tests/testthat/test-nested-fit-resamples-oracles.R` that runs `nested_fit_resamples()` with `parsnip::null_model(mode = "classification")` once per per-fold count of `"1"` labels, weights each result by its probability, and compares the weighted MSE with the closed form of `nachum2026` (Lemma 4.9, Theorem 4.10). It also covers the oracle record for that test, with page numbers from the source PDF, and the reference page's answers to the two questions the test closes.

**Out:** Monte Carlo replicates, which exact enumeration makes unnecessary (rejected at the plan gate, see the work log). The note's third open question, whether a single-candidate tuning run reduces to flat CV, stays in `references/nachum2026.md`: `null_model()` has no tuning parameter to put in a grid. Also, the O1 test in the same file already pins the untuned loop against `tune::fit_resamples()`. The note's Appendix E and F questions stay in that page.

## Acceptance criteria

- [x] AC1: `tests/testthat/test-nested-fit-resamples-oracles.R` carries a test that runs `nested_fit_resamples()` with `parsnip::null_model(mode = "classification")` on 6 rows with 3 outer `rsample::vfold_cv()` folds. The outcome is binary with levels `c("0", "1")`. The test runs once for each of the 27 rows of the test's own `expand.grid()` of a count of `"1"` labels (0, 1 or 2) per outer fold. It asserts that the mean of (0.5 − accuracy)², where accuracy is the outer estimate `collect_metrics()` reports and each dataset is weighted by the product over folds of the Binomial(2, 1/2) probability of that fold's count, equals ((k − 1)/k)·Cov(n, m) + 1/(4n) with n = 6, k = 3, m = 2, from `nachum2026` (Lemma 4.9, Theorem 4.10), within a tolerance of `1e-12`.
- [x] AC2: The same file's oracle header records this test as O3, of type analytic, naming `nachum2026` with the lemma, the theorem and their page numbers, the majority rule's tie at exactly half the training labels (predict `"0"` unless the count of `"1"` exceeds half), and that `parsnip::null_model()` predicts the first factor level on a tie.
- [x] AC3: The AC1 test's enumeration loop runs in under 10 seconds of elapsed time locally, read from `system.time()` around that loop.
- [x] AC4: `cairn/references/nachum2026.md` records that `parsnip::null_model()` predicts the first factor level on a tie, which matches the `Y > n/2` rule under levels `c("0", "1")`, and that exact enumeration over per-fold counts answers the replicate-count question with no replicates, replacing the 2026-07-31 "not checked" and "unmeasured" lines those findings answer.
- [x] AC5: `Rscript -e 'devtools::test()'` reports no failures.

## Coverage

- AC1 → T2
- AC2 → T1, T3
- AC3 → T2
- AC4 → T4
- AC5 → T2, T3

## Tasks

- [x] T1: Download arXiv 2511.03554v2 to `cairn/references/sources/nachum2026.pdf` (ask the user before the download, naming the file, source and size), read Lemma 4.9, Theorem 4.10 and the majority rule's definition, and record their printed page numbers and the exact tie rule on `references/nachum2026.md`. If the tie rule is not `Y > n/2`, stop and raise an amendment, since AC1's level order rests on it.
- [x] T2: Write the AC1 test. Build the outer splits under a fixed seed as O1 does (`set.seed()` then `rsample::vfold_cv(d, v = 3)`), assign labels by fold membership for each `expand.grid()` row, call `nested_resamples()` under the same seed so the splits agree, and assert that the splits' fold membership matches before scoring. Compute Cov(n, m) with `choose()` in the test. Open with `skip_if_no_engines()` if parsnip or yardstick can be absent on a CI leg. Time the loop with `system.time()` and log the reading.
- [x] T3: Add O3 to the file's oracle header per AC2, and update the header's closing lines that name O1 and O2 as the oracle types for the estimate.
- [x] T4: Update `references/nachum2026.md`'s Oracle status and Open questions per AC4, and mark the oracle candidate there as shipped by M104.

## Work log

- 2026-09-16: created by /milestone-plan from the `[low]` `parsnip::null_model()` oracle candidate row, absorbed.
- 2026-09-16: plan measurements. `null_model()` breaks a tie by `which.max(table(y))`, the first factor level (parsnip 1.6.0). The note's closed form matched a brute-force count over all label vectors at (n, k) = (6, 3), (12, 3), (12, 4), (12, 2), (10, 5). One 6-row `nested_fit_resamples()` run took about 0.12 s.
- 2026-09-16: criteria audit (reduced mode, internal tier) returned three findings, all applied before the gate. AC1 named the Binomial(2, 1/2) weight, AC3 timed the loop instead of a skip-and-subtract run, and AC4 dropped a "shipped" record (moved to T4) and fixed its "unmeasured" line to the replicate question it answers. The gate then added page numbers to AC2, which is still a property of the test file.
- 2026-09-16: plan gate chose exact enumeration over the 27 per-fold counts over all 64 label vectors because it costs about 3.3 s instead of 8 s and O1/O2 already pin per-row behavior; falsified by a nested run whose fold accuracy depends on which rows in a fold hold the `"1"` labels.
- 2026-09-16: plan gate chose exact enumeration over Monte Carlo replicates because the target is an exact number and enumeration reaches it with no tolerance; falsified by a configuration too large to enumerate within GP4's suite time.
- 2026-09-16: implement gate: user approved the arXiv download (814,345 bytes) and chose `inside = rsample::vfold_cv(v = 2)` for the 4-row analysis sets.
- 2026-09-16: T1 done. The PDF's majority rule predicts 1 only for Y > n/2 and 0 otherwise (p. 10). Lemma 4.9 and Theorem 4.10 are on p. 11. Both are recorded on `references/nachum2026.md`. `null_model()` predicted `"0"` on a 2-2 tie (parsnip 1.6.0).
- 2026-09-16: T2 done. The O3 test passes. Its 27-row loop took 2.93 s under `system.time()` locally, and the wrapper was removed after the reading. `devtools::test()`: 0 failures, 10576 passes.
- 2026-09-16: T2 discrimination. A planted leak trained the outer `last_fit()` on all rows. O3 then failed with 0.042 against 0.073. The 0.042 is 1/(4n), which a scratch enumeration predicted. The same enumeration gave 7/96 for a tie broken toward `"1"`: Bernoulli(1/2) labels are symmetric, so O3 does not detect the tie direction.
- 2026-09-16: T3 done. The oracle header records O3 with its source, pages, tie rule, leak plant and tie symmetry. Its closing lines now name O3 beside O1 and O2. The oracle file passes, 131 expectations.
- 2026-09-16: T4 done. `references/nachum2026.md` replaces the tie "not checked" and replicate "unmeasured" lines with the M104 findings and marks the oracle shipped as O3.
- 2026-09-16: claim audit: not owed — internal tier
- 2026-09-16: implement complete. `devtools::test()`: 0 failures, 10576 passes. `cairn_validate` passes, and the nachum2026 staleness advisory reads as it did on main. Status set to review.

## Decisions

## Review

- AC1: verified 2026-09-16. The O3 test in `tests/testthat/test-nested-fit-resamples-oracles.R` uses 6 rows, `vfold_cv(v = 3)` outer folds, levels `c("0", "1")`, a 27-row `expand.grid()` of counts 0 to 2, Binomial(2, 1/2) weights, the closed form with n = 6, k = 3, m = 2, and `tolerance = 1e-12`. `devtools::test(filter = "nested-fit-resamples-oracles")`: 0 failures, 131 passes. A scratch run of the test body gave a weighted MSE of 0.07291667 (7/96), 1.4e-17 from the closed form.
- AC2: verified 2026-09-16. The oracle header records O3 as type "analytic", names `nachum2026` with Lemma 4.9 and Theorem 4.10 (p. 11) and the rule's definition (p. 10), states that a tie predicts "0" unless the count of "1" exceeds half, and states that `parsnip::null_model()` predicts the first factor level on a tie.
- AC3: verified 2026-09-16. `system.time()` around the test's 27-row loop, run from a scratch copy of the test body: 3.84 s elapsed, under the 10 s limit.
- AC4: verified 2026-09-16. `cairn/references/nachum2026.md` records that `null_model()` predicts the first factor level on a tie, matching `Y > n/2` under `c("0", "1")`, and that exact enumeration over per-fold counts needs no replicates. A grep finds no remaining "not checked" or "unmeasured" line.
- AC5: verified 2026-09-16. `Rscript -e 'devtools::test()'`: 0 failures, 0 warnings, 0 skips, 10576 passes.
- Consistency gate 2026-09-16: `cairn_validate` exit 0 (18 references-staleness advisories, as on main). No DESIGN principle changed, so `cairn_impact` was skipped. `devtools::document()` produced no diff. `devtools::check()`: 0 errors, 0 warnings, 0 notes. All six gating prose sweeps are clean. The diff does not touch README, `_pkgdown.yml`, NEWS or top-level files, and it has no user-visible change that needs a NEWS entry.
- Independent review 2026-09-16, three lenses. The blame-history lens found nothing. The prior-review lens found no prior-review evidence. The diff-bug lens confirmed the closed form against a brute force at seven (n, k) pairs and showed that O3 catches four more wrong implementations. It reported six wording findings, ranked:
  - F1 `test-nested-fit-resamples-oracles.R:29-30`: "every labeling of 6 rows" overstates what the test runs. It runs 27 count patterns that stand for the 64 labelings.
  - F2 `test-nested-fit-resamples-oracles.R:38-39`: "a third, analytic type" can mislead, because O2 is already typed "analytic by-hand".
  - F3 `nachum2026.md:124`: the rule row's "Y ≤ n/2" uses n for the training sample, but elsewhere on the page n is the total sample size.
  - F4 `nachum2026.md:212-213`: the tie answer leaves out the `c("0", "1")` level order it depends on.
  - F5 `nachum2026.md:72` (line not changed): Result 3 omits the theorem's conditions on m.
  - F6 `test-nested-fit-resamples-oracles.R:172`: `set.seed(30)` has no effect on `null_model()`.
