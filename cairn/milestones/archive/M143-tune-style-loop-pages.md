# M143: The other loop pages, the final fit and the design page read like tune's

**Status:** done (2026-10-10, PR #159 https://github.com/tidymodels/nestedtune/pull/159; resolves #91 partial)

**Goal:** Rewrite seven help pages to the target M142 set: `nested_tune_bayes`, `nested_tune_race`, `nested_tune_sim_anneal`, `nested_fit_resamples`, `nested_workflow_map`, `nested_final_fit` and `nested_resamples`.

**Outcome:** The seven pages went from 10,343 to 4,826 prose words (`benchmarks/doc-profile.R`), the largest 858 against `tune_bayes`'s 1,559. Descriptions run 21 to 35 words, and no `nestedtune_*` class name or `orchestrator` is left.
- The loop pages point to `?nested_tune_grid` for what they share, drop the inherited grid sections, and keep their own arguments and the seven-heading Differences lists. `details-param-info.R` is deleted, and the six templates only these pages use are cut short.
- `?nested_final_fit` keeps what it fits, what it returns, a "What to report" section (IP3) and the hand recipe. Its refusal list and citations left, and the workflow-identity gaps D-067 relies on stay in one sentence.
- `?nested_resamples` keeps the D-110 reasons and the D-085/D-115 time-series claims as short lists, and its title is now "Build a nested resampling design".
- `?nested_workflow_map` keeps its routing, seed, error and subsetting rules in Details. DESIGN Known issues now points there (corrected M143).
- `test-help-structure.R` follows one template's new wording. `test-control-slots.R` is unchanged.

**Decisions:** none.

**Review:** a claim audit at implement read 110 claims and corrected 6. Review ran three lenses plus the plan's fresh reader beside tune's pages, which raised 67 findings: 45 fixed on the branch, 19 rejected with reasons, 3 sent on.
- `?extract_procedure`'s wrong section title for the finetune pages went to M144's work log.
- The inherited `metrics` and `eval_time` text went to a new low candidate row.
- The `check()` note was a stray `Rplots.pdf` from a local examples run, which was removed.

All 14 CI checks passed, and the PR had no reviews or comments. At merge, the user chose no comment on #91. No lesson was added or retired.
