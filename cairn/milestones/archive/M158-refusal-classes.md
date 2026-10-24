# M158: Give the unclassed refusals a class

**Status:** done (2026-10-24, PR #175 https://github.com/tidymodels/nestedtune/pull/175)

**Goal:** Every `cli::cli_abort()` call in `R/` carries a `nestedtune_` condition class, so a user can catch each refusal by class instead of by message.

**Outcome:** A `class` argument on the 26 calls that had none (19 in `R/checks.R`, 6 in `R/nested-resamples.R`, 1 in `R/tuner.R`), grouped by kind. Messages unchanged (parse-tree walk against the merge base).
- New: `nestedtune_bad_workflow` (`check_workflow()`, `abort_bad_object()`), `nestedtune_bad_grid` (`check_grid()` and all four `check_grid_params()` refusals, the final fit's recorded-grid pair included), `nestedtune_bad_data` (`nested_resamples()` data), `nestedtune_bad_param_info`, `nestedtune_bad_eval_time`, `nestedtune_bad_event_level`, `nestedtune_unknown_tuner` (`tuner_entry()`'s internal error).
- Reused: `nestedtune_bad_design` (`eval_inside_spec()`, `eval_spec()`, `inner_resamples_from_split()`, the `outside`/`inside` refusals), `nestedtune_bad_type` (`check_plot_type()`), `nestedtune_bad_metrics` (`check_metrics()`).
- Tests: each refusal asserted by class and a headline fragment unique within its class; `rlang_error` assertions tightened, also through `nested_fit_resamples()` and `compute_metrics()`. One NEWS bullet.
- Not covered: refusals raised by rlang's own helpers (`arg_match()`, `check_required()`, `check_dots_empty()`), and no help page lists condition classes. Neither has a row.

**Decisions:** milestone-local: `bad_grid` over `workflow_mismatch` for the two final-fit refusals that name `object`; a review-time parse walk over a committed source-parsing test. None promoted.

**Review:** Four-lens fan-out, one pass, no return. 23 findings: 7 fixed (class assertions on `nested_fit_resamples()` and `compute_metrics()`, the `eval_spec()` assertion in its own block, a narrating comment, two NEWS sentences), 15 rejected, 1 noted, 0 to rows. Claim audit: 2 NEWS claims corrected. AC1 by mutation: the old `R/` turned every class assertion red. Suite 1153 blocks, 0 failed (run alone; a run beside other R sessions failed daemon blocks). `check()` 0/0/0. CI: `ubuntu-latest (devel)` failed 53 censored tests twice under R-devel r90748 (r90747's bug, fixed in r90749; main fails the same job); merged past it at the user's choice, recorded as an override. The local PR-record, resume and override commits after ba314316 were not pushed, and this summary carries them. Row "Give the unclassed refusals a class" graduated; M152 lesson extended; none retired; none unparked.
