# M164: Give six one-type results a second oracle

**Status:** done (2026-10-31, PR #180 https://github.com/tidymodels/nestedtune/pull/180)

**Goal:** Back each of the six `cairn/ORACLES.md` groups whose result is its own and that rests on one oracle type with a test of a second, independent type.

**Outcome:** Six tests, no package code change.
- Selection rules, closed-form: `pick()` in `test-nested-tune-grid-oracles.R` writes `select_best()`, one-standard-error and percent-loss from tune 2.1.0's `?select_best` page over one run's `.inner_metrics`. Source note `references/tune-select-best.md`: the page's percent-loss example divides by the candidate's value and tune's code by the best's; both pick alike on this fixture.
- Racing and annealing final fits, invariant: the recorded rule's pick from `extract_tune_results(final)`, finalized and fit by hand, gives the final fit's predictions (`det_workflow()`, seed 33).
- `nested_workflow_map()`, live: the grid element of `wset_two()` matches `reference_nested_loop()` fold by fold.
- Splits, invariant: on a 3-fold outer and 4-fold inner `nested_resamples()` design, inner rows sit in their outer analysis set, each inner split's two sets are disjoint, and the assessment sets cover the outer analysis rows once.
- Outer-fit predictions, invariant: saved `.pred` and `.row` match `predict()` of the saved workflow on the assessment rows.
- `cairn/ORACLES.md`: six rows, six headings at two types, a ride-on line in each of the three table groups, a label rule for added oracles. D-121: a table that restates checked numbers, or holds no number, owes no second type. DESIGN's oracle-records bullet admits later rows.

**Decisions:** milestone-local: stored-run invariant for both final fits over a one-candidate race (plan gate); one milestone, not one per group. D-121 promoted.

**Review:** Four-lens fan-out, one pass: 30 findings, 18 fixed, 12 rejected, none to rows. One review return (AC1 read three runs' inner metrics where it says one run), fixed at review. Plants on a seed and on rsq passed, the fixture cannot show either; a one-candidate grid failed. Full suite clean alone; `devtools::check()` 0/0/0; CI 16 checks green. PR conversation empty. Graduated "Settle oracle types for nine groups"; its finer results live in "Give finer results a second oracle". Two lessons added; the M68, M101, M152 and M163 lessons marked used. The unpushed PR-URL, conversation-read and resume-approval commits went with the deleted branch; this summary records them.
