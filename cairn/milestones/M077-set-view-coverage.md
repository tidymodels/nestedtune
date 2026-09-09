# M077: The set's figures say what their averages rest on, and the shapes past `wset_three()` are drawn

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP4
- **Resolves:** —
- **Surface tier:** user-facing — the figures `autoplot()` draws for a reader
- **Branch/PR:** `m077-set-view-coverage`

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

- [x] T1: Add two censored set fixtures to `tests/testthat/helper-orchestration.R`
      beside the existing `srv_*` block (`:861-958`): one `workflow_set` of two
      `survival_reg()` workflows tuning `dist`, run through
      `nested_workflow_map()` at `srv_eval_times()` under
      `metric_set(brier_survival, concordance_survival)`; one mixing a `dist`
      workflow with a workflow tuning a numeric recipe parameter. `force()` every
      default before the seed (M71 lesson). Every reading test guards on both
      `skip_if_no_censored()` (`:1151`) and `skip_if_no_wset_fixture()` (`:2592`)
      — the first does not cover `workflowsets`. Carry fixture provenance per the
      profile's test-doctrine.
- [x] T2: Add `set_short_average_line()` beside `set_shortfall_line()`
      (`R/nested-results-plot.R`), counting a workflow whose metric averaged
      fewer folds than it completed, reading `n` from the per-workflow
      `summarize_folds()` the rules are drawn from against that workflow's
      `sum(.completed)`. The failed-fold sentence and its count stay separate,
      which is why this is a sibling function rather than a widening of that
      one.
- [x] T3: Write AC1's six planted sets and their assertions in
      `tests/testthat/test-nested-results-plot.R`. `break_fold()` (`:471`) mutates
      the shared design, so set (d) builds on `wset_three_results(broken = )`;
      an `NA` score is planted on the results object's `.metrics`, which
      `per_fold_metrics()` (`R/nested-results.R:948`) reads through.
- [x] T4: Write AC2's and AC3's tests on the censored set fixture, deriving the
      expected panels from `collect_metrics()` and the rules from the same
      reader.
- [x] T5: Write AC4's test on the mixed-parameter censored set, matching drawn
      points to `collect_selections(x)`.
- [x] T6: `NEWS.md` entry for the subtitle change; update the set `autoplot()`
      help text where it describes the subtitle (`R/nested-results-set.R:246`);
      redraw the two set `vdiffr` doppelgangers and read the rendered figures
      before approving them (M08 lesson), adding a third for the four-line
      subtitle no existing snapshot carries.
- [ ] T7: Measure AC5's A/B suite medians, three runs each side in one sitting;
      `devtools::document()`, `devtools::test()`, `devtools::check()`.

## Work log

- 2026-09-09: created by /milestone-plan; promoted from the set-view coverage candidate row (M72 review O1, O2, O3, O7, O11).
- 2026-09-09: plan-gate criteria audit ran in full mode ([O] fresh reader, two passes). Pass 1 returned 15 findings over 7 drafted criteria; 10 fixed here (AC1 was wholly a fixture property and became T1; the survival guard missed `workflowsets`; AC3's "named as `summary()` names it" was unsatisfiable, `summary()` always printing the estimator where panels print it only when ambiguous; AC4's planted two-estimator figure is unreachable by any real map run; AC5's discreteness clause could not fail on a fixture whose only tunable is character), 2 posed at the gate. Pass 2 over the two changed criteria returned 12 more; the load-bearing one measured ggplot2 handing both panels identical limits, which made the re-cut tick-mark criterion unsatisfiable and sent it back to the user.
- 2026-09-09: plan gate chose widening the performance view's subtitle sentence over labelling each short average inside its panel, because a set has no per-workflow-and-metric label slot and a figure-level count asserting a per-panel truth is the defect M08 review F1 found, while `summary()` already prints the exact count per workflow and metric; falsified by a reader needing the per-panel number without opening `summary()`.
- 2026-09-09: plan gate chose a real censored set run over planting the `.eval_time` and character-parameter shapes on a regression fixture, because the promoted row's condition names a real fixture and the single-run `srv_*` parts already exist; falsified by AC5's suite-time bar being missed.
- 2026-09-09: plan gate chose dropping the shared tick-mark picker's same-interval tie to a candidate row over rebuilding the parameters figure in this milestone, because the audit measured both panels receiving byte-identical limits so no test can close it and the source records the tie as a deliberate known limit (`R/nested-results-plot.R:198`); falsified by a wrong tick mark reaching a user's figure.
- 2026-09-09: implement gate chose counting a workflow whose metric scored on no completed fold toward the new subtitle count, wording A ("N of K workflows average a metric over fewer folds than they completed; see summary()."), and a spline `deg_free` step as the mixed set's numeric parameter.
- 2026-09-09: plan gate chose one milestone over splitting the figure change from the coverage tests, because every item rests on the same new censored set fixture; falsified by the branch outgrowing one reviewable PR.

- 2026-09-09: T1 — two censored set fixtures in `helper-orchestration.R`: `srv_set_results()` (two `dist` workflows under `brier_survival` + `concordance_survival` at `srv_eval_times()`, giving three metric-and-time keys) and `srv_mixed_results()` (a `dist` workflow beside a spline `deg_free` one). recipes refuses an inline `Surv()` outcome in a formula, so the recipe workflow reads a frame carrying the `Surv` object as its own column (`srv_recipe_data()`).
- 2026-09-09: T2 — `set_short_average_line()` added; the set's performance view now keeps its per-workflow `summarize_folds()` so the rules and the subtitle count read one `n`. Implementation gate chose a sibling function over widening `set_shortfall_line()`, the two counts being separate sentences.
- 2026-09-09: T3 — AC1's six planted sets written. Two planted defects proved them able to fail: a sentence that never fires failed 5 of the 6, and counting metrics rather than workflows failed set (b) alone, which is the case it exists for.
- 2026-09-09: T4, T5 — AC2, AC3 and AC4's tests written on the two censored fixtures. Three planted defects proved them: a changed time label, rules pooled across workflows, and a parameters panel without the workflow id each failed the test written for it. `devtools::test()` on the file: 40 tests, 0 failed, 0 skipped.

- 2026-09-09: T6 — `NEWS.md` entry and the set `autoplot()` help paragraph on the subtitle, both derived from a rendered figure's observed text. The two existing set doppelgangers were unchanged, `wset_three_results()` carrying no shortfall, so a third was added for the four-line subtitle (a discovered sub-task, recorded in T6). All three set figures and the two censored ones were rendered at 7-8 inches and read: no clipping, and the parameters view puts `weibull`/`lognormal` and `1`/`2` on discrete axes in their own panels.

## Decisions

## Review
