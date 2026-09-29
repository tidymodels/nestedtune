# M129: Recognize a refused design by its split classes

**Status:** done (2026-09-29, PR #144 https://github.com/tidymodels/nestedtune/pull/144)

**Goal:** If any split of a nested design carries the class of a refused rsample design, the call refuses the design.

**Outcome:** `split_designs()` in `R/checks.R` maps each split's class to the rsample function that builds it. The map covers `group_boot_split`, `boot_split`, `perm_split`, `loo_split` and `apparent_split`. An apparent split beside bootstrap or permutation splits counts as part of that design. `check_outer_splits()` refuses an outer design with any such split and names the rows. `inner_refused_design()` reads the rset class first and then the split classes. `check_inner_refused()` names the elements. `nested_resamples()` applies both to `outside` and to each rset that `inside` returns, and names the outer fold. `inner_refused_reason()` keeps the tune reason for an rset class. For a design found by its splits, which tune runs, it gives the outer loop's reason. The bootstrap refusals name `bootstraps()` or `group_bootstraps()`, and the entry hint says "nestedtune refuses". Row subsets, `manual_rset()` rebuilds and mixed designs are now refused in either loop. The README Refused paragraph, a NEWS bullet and two help pages say so. `test-design-support.R` gained 20 test blocks.

**Decisions:** D-097, recorded at plan.

**Review:** The claim audit read 52 claims and corrected 5. Three reviewers found 17 items. At the gate, the maintainer chose to fix 8. The main fix was the false "tune refuses" reason for a rebuilt inner design. The others were the constructor headline, untested bootstrap names and the entry hint naming `nested_tune_grid()`. NEWS and help gaps, the DESIGN bullet, a line that did nothing and the README order were fixed too. The apparent-beside-bootstrap gap (O3, O4) went to a candidate row. Seven were rejected or noted. The M126 terminal row was pruned on the branch to keep ROADMAP under 60 lines. `devtools::test()` gave 0 failures and `devtools::check()` gave 0 errors, 0 warnings and 0 notes. CI passed 14 checks. Nothing was graduated or retired.
