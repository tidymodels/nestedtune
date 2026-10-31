# M167: Add second oracles to one-type parts

**Status:** done (2026-10-31, PR #183 https://github.com/tidymodels/nestedtune/pull/183)

**Goal:** Back each of the three parts that the candidate row "Add second oracles to one-type parts" names with oracles of two independent types: the survival branch of `compute_metrics()`, the racing record's rows for eliminated candidates, and the final fit under `event_level`.

**Outcome:** Five tests, no package code change.
- Survival branch, `test-compute-metrics.R`: `srv_kinds_metrics()` (concordance, Brier, Royston) and `srv_kind_sets()` (six mixes, one per branch of `score_fold()`). Tests: `collect_metrics()` equality (U1); yardstick on each fold's rows over every mix, on the run as saved and with `.pred_time` reversed (U2); reversing one column moves only its metric (new `compute-metrics/O1`, invariant). `reverse_pred()` exists because survreg's `.pred_time` rises with `.pred_linear_pred` and both metrics rank, so an unreordered run hides a column swap.
- Racing, `test-nested-tune-race-oracles.R`: each eliminated row equals `nested_tune_grid()` over a `manual_rset()` cut to the resamples the reference race scored it on, on the deterministic fixture (`nested-tune-race-oracles/O5`, invariant). The ranger fixture does not reproduce on a cut design.
- Event level, `test-event-level.R`: sensitivity and specificity counted from the final fit's saved tuning predictions at `"second"` (`event-level/O3`, closed-form).
- `cairn/ORACLES.md`: three rows, two test lines under U1 and U2, three group lines credit each part to two types.

**Decisions:** none promoted. Plan gate: one milestone; a new fixture over a record when no existing fixture can show a defect; closed-form count over a level-swap invariant. Implement: deterministic racing fixture after the cut design failed on ranger seeds.

**Review:** Four-lens fan-out, one pass: 24 findings, 11 fixed, 13 rejected, none to rows. Fixes: single-kind branches unreached, O5 reading its rows from the record, an empty-mask pass, AC2 run only on edited predictions, specificity uncounted, registry wording. Plants re-run with per-test counts. Suite 1169 clean alone; `devtools::check()` 0/0/0; CI 16 pass, 1 skipped. Graduated "Add second oracles to one-type parts". One lesson added; evicted the 2026-07-26 (M04) cli-output lesson by rank; the M12, M101, M152, M163, both M164 and the M166 lessons marked used. The unpushed PR-URL commit went with the deleted branch; this summary records it.
