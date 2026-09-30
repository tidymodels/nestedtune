# M131: Keep a renamed apparent split out of a bootstrap design

**Status:** done (2026-09-29, PR #146 https://github.com/tidymodels/nestedtune/pull/146)

**Goal:** If an apparent split sits beside bootstrap or permutation splits, it counts as part of that design only if its id is "Apparent" (D-099).

**Outcome:** `split_designs()` in `R/checks.R` joins an apparent split to its bootstrap or permutation host on one condition. `apparent_ids()` must find `as.character()` of its id equal to "Apparent", the comparison tune 2.1.0 makes. An NA id or a missing id column is no match. Any other apparent split is refused as `apparent()` in both loops. The inner refusals in `check_inner_refused()` and `inner_resamples_from_split()` add a hint through `renamed_apparent()`. The hint says that tune leaves out an apparent split whose id is "Apparent". A refusal gets it only for an `apparent()` split beside bootstrap splits. An outer `manual_rset()` rebuild now names such a split as an `apparent()` row. The README Refused paragraph, the shared help text, `?nested_resamples`, NEWS and the DESIGN convention bullet state the rule. `test-design-support.R` gained eight blocks.

**Decisions:** D-099, recorded at plan.

**Review:** All five criteria passed with fresh evidence. Three reviewers reported 13 findings, and the maintainer accepted each proposed disposition. Six were fixed at the gate. The hint no longer follows a bullet naming another design (O1). The README id sentences moved after the rebuilt-design sentence (P1). The NEWS bullet names the `inside` refusal and scopes the outer naming (P2, O8). Tests cover NA ids, a missing id column and the whole hint (O5, O9). Racing on the "Apparent" split and tune dropping any split with that id became one `[low]` candidate row (O3, O4). The outer naming of a separate `apparent()` split became a DESIGN Known issues entry (P3). S1, O2, S2 and O7 were rejected. After the fixes, `devtools::test()` gave 0 failures and `devtools::check()` gave 0 errors, 0 warnings and 0 notes. CI passed 14 checks. No lesson was added or retired.
