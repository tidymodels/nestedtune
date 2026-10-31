# M166: Give finer results a second oracle

**Status:** done (2026-10-31, PR #182 https://github.com/tidymodels/nestedtune/pull/182)

**Goal:** Back each result that the candidate row "Give finer results a second oracle" names with a second oracle type, or record why it owes none.

**Outcome:** Five tests and one assertion, no package code change.
- Final fit under `eval_time`, invariant: a two-element run's final fit equals the first element's, both orders (`test-eval-time.R`).
- Resample weights, invariant: a new weight on a failed or NA fold leaves that summary row identical; the new total doubles the old, so tune's divided weights halve exactly (`test-resample-weights.R`).
- Desirability rule, closed-form: desirability2 0.2.0's terms over each fold's observed range and their geometric mean (`test-nested-tune-grid-oracles.R`); source note `references/desirability2-select-best.md` records the page's minimization typo.
- Averages: renormalized probabilities sum to one (invariant), and a censored design held out three times matches tune's median `.pred_time` and `hand_average()` (`test-collect-predictions-summarize.R`, `repeated_pair()` takes `repeats`).
- Selection metric: the final fit's first metric against the set's first name (`test-selection-metric.R`).
- `cairn/ORACLES.md`: six rows; group lines credit rows part by part. Parts left on one type or none (compute_metrics survival branch, racing eliminated rows, final fit under `event_level`) went to the new row "Add second oracles to one-type parts". The Bayesian and annealing search steps are credited to no row, with no independent oracle.

**Decisions:** D-123 (credit a part only to rows whose input can show a defect there; one-type parts held by a candidate row; iteration stage exempt from GP2's second type). Plan gate: one milestone; records over tests for same-code parts, which review found false.

**Review:** Two four-lens passes. Pass 1: 35 findings, four records found false; stop answer built two averaging tests (AC5, AC6 amended, AC7 added); AC6 wording settled by the user after two re-audits. Pass 2: 30 findings, 15 fixed (registry credits narrowed), 15 rejected. Suite 1164 tests clean alone; `devtools::check()` 0/0/0; CI 16 checks green; PR conversation empty. Graduated "Give finer results a second oracle". One lesson added; the M12, M101, M152, M163 and both M164 lessons marked used. The unpushed PR-URL and resume-record commits went with the deleted branch; this summary records them.
