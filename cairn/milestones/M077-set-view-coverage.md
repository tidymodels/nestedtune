# M077: The set's figures say what their averages rest on, and the shapes past `wset_three()` are drawn

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP4
- **Resolves:** —
- **Surface tier:** user-facing — the figures `autoplot()` draws for a reader
- **Branch/PR:** —

## Goal

Bring the multi-workflow figures up to the single view's standard on what an
average rests on, and draw them over the metric and parameter shapes
`wset_three()` cannot produce.

## Scope

**In:** a subtitle sentence on the set's performance view naming how many
workflows rest an average on fewer outer folds than they completed; a
censored-regression set fixture whose metric set mixes one dynamic and one
static survival metric, and a second whose two workflows tune a character-valued
and a numeric parameter; tests drawing both set views over those fixtures.

**Out:** the shared tick-mark picker's same-interval tie → ROADMAP candidate row
(the panels are indistinguishable on limits alone, so closing it needs the
figure rebuilt, not a test). The single-workflow view's own subtitle, which
already qualifies per panel (`R/nested-results-plot.R:249`) → unchanged. A
`vec_ptype2`/`vec_cast` lattice on the set → its existing candidate row.

## Acceptance criteria

- [ ] AC1: `autoplot(x, type = "performance")` gains a subtitle sentence naming
      how many of a set's workflows rest an average on fewer outer folds than
      they completed and pointing the reader at `summary()`, beside the existing
      sentence for workflows that failed a fold. Six planted sets assert the
      subtitle's exact text: (a) one metric short in one workflow; (b) two
      metrics short in the same workflow, reporting the same count as (a); (c)
      one metric short in two workflows, reporting a larger count; (d) one
      metric short in a set that also holds a workflow failing a fold, both
      sentences present with their own counts; (e) one metric scoring `NA` on
      every completed fold of a workflow, where no rule is drawn for it in that
      panel and no average is reported for it; (f) a set every completed fold of
      which scored, carrying neither sentence. (RB tripwire: ip-touching)
- [ ] AC2: On the censored set fixture, each panel of
      `autoplot(x, type = "performance")` carries the name the single view gives
      that metric-and-time key on the same element, every rule drawn equals the
      `mean` `collect_metrics(x)` reports for that workflow and key, and every
      non-`NA` mean it reports has a rule. One test asserts all three by
      enumerating the figure's panels and rules against `autoplot()` on each
      element and against `collect_metrics(x)`.
- [ ] AC3: On the censored set fixture, whose metric set holds one dynamic and
      one static survival metric evaluated at `srv_eval_times()`,
      `autoplot(x, type = "performance")` draws one panel per distinct
      metric-and-time key of `collect_metrics(x)`: two for the dynamic metric,
      each naming its time, and one for the static metric, naming no time. The
      test derives the expected panel set from `collect_metrics(x)` rather than
      from a written list.
- [ ] AC4: On a censored set mixing one workflow whose tuned parameter is the
      character-valued `dist` with one whose tuned parameter is numeric,
      `autoplot(x, type = "parameters")` draws every panel on a discrete axis and
      places each fold's point at the value `collect_selections(x)` records for
      that workflow, fold and parameter. The test enumerates the figure's points
      and matches them to that reader's rows.
- [ ] AC5: `Rscript -e 'devtools::document()'` produces no diff;
      `Rscript -e 'devtools::test()'` passes with no failure; `devtools::check()`
      reports 0 errors and 0 warnings, every NOTE named in the Review section
      with its reason; `NEWS.md` carries an entry for the subtitle change AC1
      makes; and the full test suite, run three times on the branch and three
      times on the default branch in one sitting on one machine with the same
      Suggests installed, has a branch median no more than 10% above the
      default-branch median, both figures and the machine recorded in the work
      log.

## Coverage

- AC1 → T2, T3
- AC2 → T1, T4
- AC3 → T1, T4
- AC4 → T1, T5
- AC5 → T6, T7

## Tasks

- [ ] T1: Add two censored set fixtures to `tests/testthat/helper-orchestration.R`
      beside the existing `srv_*` block (`:861-958`): one `workflow_set` of two
      `survival_reg()` workflows tuning `dist`, run through
      `nested_workflow_map()` at `srv_eval_times()` under
      `metric_set(brier_survival, concordance_survival)`; one mixing a `dist`
      workflow with a workflow tuning a numeric recipe parameter. `force()` every
      default before the seed (M71 lesson). Every reading test guards on both
      `skip_if_no_censored()` (`:1151`) and `skip_if_no_wset_fixture()` (`:2592`)
      — the first does not cover `workflowsets`. Carry fixture provenance per the
      profile's test-doctrine.
- [ ] T2: Widen `set_shortfall_line()` (`R/nested-results-plot.R:661`) to also
      count a workflow whose completed fold scored `NA`, reading `n` from the
      per-workflow `summarize_folds()` already computed at `:588` against that
      workflow's `sum(.completed)`. Keep the failed-fold sentence and its count
      separate.
- [ ] T3: Write AC1's six planted sets and their assertions in
      `tests/testthat/test-nested-results-plot.R`. `break_fold()` (`:471`) mutates
      the shared design, so set (d) builds on `wset_three_results(broken = )`;
      an `NA` score is planted on the results object's `.metrics`, which
      `per_fold_metrics()` (`R/nested-results.R:948`) reads through.
- [ ] T4: Write AC2's and AC3's tests on the censored set fixture, deriving the
      expected panels from `collect_metrics()` and the rules from the same
      reader.
- [ ] T5: Write AC4's test on the mixed-parameter censored set, matching drawn
      points to `collect_selections(x)`.
- [ ] T6: `NEWS.md` entry for the subtitle change; update the set `autoplot()`
      help text where it describes the subtitle (`R/nested-results-set.R:246`);
      redraw the two set `vdiffr` doppelgangers and read the rendered figures
      before approving them (M08 lesson).
- [ ] T7: Measure AC5's A/B suite medians, three runs each side in one sitting;
      `devtools::document()`, `devtools::test()`, `devtools::check()`.

## Work log

- 2026-09-09: created by /milestone-plan; promoted from the set-view coverage candidate row (M72 review O1, O2, O3, O7, O11).
- 2026-09-09: plan-gate criteria audit ran in full mode ([O] fresh reader, two passes). Pass 1 returned 15 findings over 7 drafted criteria; 10 fixed here (AC1 was wholly a fixture property and became T1; the survival guard missed `workflowsets`; AC3's "named as `summary()` names it" was unsatisfiable, `summary()` always printing the estimator where panels print it only when ambiguous; AC4's planted two-estimator figure is unreachable by any real map run; AC5's discreteness clause could not fail on a fixture whose only tunable is character), 2 posed at the gate. Pass 2 over the two changed criteria returned 12 more; the load-bearing one measured ggplot2 handing both panels identical limits, which made the re-cut tick-mark criterion unsatisfiable and sent it back to the user.
- 2026-09-09: plan gate chose widening the performance view's subtitle sentence over labelling each short average inside its panel, because a set has no per-workflow-and-metric label slot and a figure-level count asserting a per-panel truth is the defect M08 review F1 found, while `summary()` already prints the exact count per workflow and metric; falsified by a reader needing the per-panel number without opening `summary()`.
- 2026-09-09: plan gate chose a real censored set run over planting the `.eval_time` and character-parameter shapes on a regression fixture, because the promoted row's condition names a real fixture and the single-run `srv_*` parts already exist; falsified by AC5's suite-time bar being missed.
- 2026-09-09: plan gate chose dropping the shared tick-mark picker's same-interval tie to a candidate row over rebuilding the parameters figure in this milestone, because the audit measured both panels receiving byte-identical limits so no test can close it and the source records the tie as a deliberate known limit (`R/nested-results-plot.R:198`); falsified by a wrong tick mark reaching a user's figure.
- 2026-09-09: plan gate chose one milestone over splitting the figure change from the coverage tests, because every item rests on the same new censored set fixture; falsified by the branch outgrowing one reviewable PR.

## Decisions

## Review
