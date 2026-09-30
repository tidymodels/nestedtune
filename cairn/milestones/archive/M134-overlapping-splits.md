# M134: Refuse a split that assesses rows it trains on

**Status:** done (2026-09-30, PR #149 https://github.com/tidymodels/nestedtune/pull/149)

**Goal:** A split that assesses rows it also trains on is refused in both loops, whatever class it carries (D-103).

**Outcome:** `R/checks.R` gained `split_shares_rows()`, `overlap_rows()`, `check_outer_overlap()` and `check_inner_overlap()`. It also gained `fold_overlap_rows()`, `inner_frame_kinds()` and `lag_hint()`. A split whose assessment set holds a row of its analysis set is refused with class `nestedtune_bad_design`. The rule reads rows, so it catches a `make_splits()` rebuild that no class names. The outer rule runs in `check_nested()` and `nested_resamples()`. The inner rule runs at entry, for each `inside` design, and in `check_final_inner()`. An index into an outer analysis set counts as the data row it copies. `bootstrap_apparent()` exempts the bootstrap's own apparent split under every tuner (D-104). `rolling_origin()` with `lag` above 0 is refused too. If the rset keeps its `lag`, the error suggests `lag = 0` (D-107, D-108). An NA in an outer `in_id` is left to the later checks. The README, four help pages, NEWS and DESIGN state the rules.

**Decisions:** D-103 at plan, D-104 at the plan re-audit, D-107 at the first review gate, D-108 at the second.

**Review:** Pass 1 returned the milestone (one defect return), because `rolling_origin(lag = k)` was refused and undocumented. T7 to T10 fixed that and six other findings. Pass 2 verified all four criteria at `3727680e` and logged S1 to S16. The user chose to fix S1 to S8. The main one was a new unclassed crash on an NA outer `in_id`. S9 and S10 joined the M134 leftovers row, and S11 to S16 were rejected with reasons. One fix-now test kept every row of a two-split design, and CI's hard check failed on it. It was rebuilt on six splits. Two recorded local results had come from completion notices that disagreed with the logs, and the milestone file corrects both. At `fa0a5b12` all 15 CI checks passed, and local `devtools::check()` gave 0 errors, 0 warnings and 0 notes. No lesson was added, since that test's comment holds the subset rule. None was retired.
