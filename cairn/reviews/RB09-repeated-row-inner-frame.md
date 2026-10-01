# RB09: The inner frame under an outer split that repeats a row (M139)

- **Date:** 2026-10-01
- **Output required:** write findings to `cairn/reviews/RR09-repeated-row-inner-frame.md`
- **Binding criteria:** not requested

You are performing an independent expert review. This brief is fully
self-contained. Do not assume any conversation context. Read only what this
brief directs you to read, answer the numbered questions, and write your
findings to the output path above using the same numbering. The work is
read-only: do not edit any file except the output file.

## Background

`nestedtune` is an R package that runs nested cross-validation for the
tidymodels ecosystem. An outer loop splits the data. For each outer fold, an
inner loop tunes a workflow with `tune` on the outer analysis set only, and
the selected candidate is then scored on the outer assessment set. The
package's first inviolable principle (IP1) says that the outer assessment set
never influences anything upstream of its own scoring, inner tuning included.

A design from `nested_resamples()` stores inner splits that index the whole
data frame. tune finalizes an unknown parameter range, for example a `min_n`
upper bound set from the row count, on the frame that the first inner split
carries. Read over the whole frame, that range comes from rows that the outer
fold holds out. Milestone M54 (2026-09-03) fixed this with
`analysis_framed_inner()`. Before each inner tune call, it rebuilds the inner
splits on `rsample::analysis(split)` and maps each index through `match()`
against the outer `in_id`.

M54 left one shape out. When the outer split's `in_id` repeats a row, the
outer analysis set holds that row more than once, and `match()` sends every
mention to the first copy. So the function returns early and the inner
splits stay on the whole frame, and the leak stays open for that shape. Such
an outer split comes from an evaluated `rsample::manual_rset()` or a split
rebuilt with `rsample::make_splits()`. Outer bootstrap designs are refused. A
hotfix on 2026-10-01 (commit `25975e9`) closed one part of the leak. Over
the whole frame, a logical `NA` inner `out_id` meant every row outside the
inner `in_id`, the outer held-out rows among them. The hotfix sets each such
`out_id` to the complement's rows that the outer split holds, each row once.

Milestone M139 (planned, blocked on this brief) removes the early return.
The plan gate chose three rules:

1. **Occurrence map.** Within one inner split's `in_id`, and separately
   within its explicit `out_id`, the r-th mention of a data row maps to the
   r-th position of that row in the outer `in_id`. Past the last copy, the
   map starts again at the first copy.
2. **By-row complement.** A logical `NA` inner `out_id` becomes every
   position of the analysis frame whose data row the inner `in_id` does not
   hold. So a row that the outer split holds twice and that the inner
   analysis set does not use is assessed twice. This replaces the hotfix
   rule of each row once.
3. **No deprecation period.** The change ships before version 1.0, named in
   NEWS.

The milestone touches IP1, and the plan gate chose this review before it set
the test bar.

## Materials

- `cairn/milestones/M139-repeated-row-inner-frame.md`: the drafted plan, its
  acceptance criteria AC1 to AC7, and the tasks.
- `R/nested-resamples.R`: `inner_resamples_from_split()` from line 293. Its
  forward map at lines 404-418 builds the stored inner splits.
  `analysis_framed_inner()` and its comment are at lines 431-517, and
  `complement_within_outer()` is at lines 519-545.
- `R/nested-tune-grid.R`: the single call site at lines 770-800, which every
  tuning function shares. The help section "Finalizing a parameter range" is
  at lines 193-206.
- `R/checks.R`: `split_shares_rows()` from about line 940, the overlap rule,
  and `check_inner_splits()` (search for it), the containment rule.
- `tests/testthat/test-nested-tune-finalize.R`: the oracle header (O1, O2)
  at lines 1-22, the fixtures and `frac_min_n()` at lines 24-95, the AC4
  test at lines 327-372, and the hotfix test at lines 375-417.
- `cairn/DESIGN.md`: IP1 at line 217, and the Architecture paragraph at
  lines 335-355.
- `cairn/DECISIONS.md`: read D-049, D-103, D-104, D-109 and D-111 whole.
  Find them with `grep -n '^### D-' cairn/DECISIONS.md`.
- `cairn/milestones/archive/M54-inner-finalize-analysis-frame.md`.
- To run code: in the repo root, `Rscript -e 'pkgload::load_all(); ...'`.
  For a test file, `Rscript -e 'devtools::test(filter = "nested-tune-finalize")'`.
  An R string that carries a backslash goes in a script file, because
  `Rscript -e` strips one level of escaping.

## Questions

1. Is the occurrence map correct? Show whether, for every inner split that
   the entry checks accept, it maps each index to a position whose data row
   is that index's row, and so preserves the content, order and multiplicity
   of each inner analysis set and explicit assessment set. Is it the exact
   inverse of the forward map at `R/nested-resamples.R:404-418` for designs
   that `nested_resamples()` builds? Name any accepted design where it is
   not.
2. Is the by-row complement correct and free of leaks? Check that it never
   assesses an outer held-out row, never assesses a row of the inner
   `in_id`, and agrees with the overlap rule, the containment rule, the
   apparent-split exemption, and the `NA` rule (D-103, D-104, D-109, D-111).
   Compare it with the two alternatives: each row once (the hotfix rule),
   and rsample's own complement over the analysis frame. Which one should
   ship, and why?
3. Is the wrap clause sound? Can an inner bootstrap design, or any other
   design that mentions a row more often than the outer split holds it,
   pass the entry checks under a repeated outer row? If such a design can
   pass, does the wrap clause give the right sets? If no such design can
   pass, recommend one of two options: keep the clause as a defined
   fallback, or refuse that case in the code.
4. Does tune 2.1.0 or finetune 1.3.0 read anything from an inner split
   beyond its analysis set, its assessment set, and the frame used to
   finalize, such that the choice of copy matters? Consider the `.row`
   values in saved predictions, the racers' per-resample reads, and
   `tune_sim_anneal()`'s own parameter check. Say where you read each answer.
5. Is the test bar sufficient for an IP1 change? The plan tests with
   `nested_tune_grid()` only. It records the `resamples` that each fold's
   `run_tuner()` gets, and it adds two oracles: O1, the analytic range
   `floor(65 * c(0.1, 0.5))` on a 65-row analysis frame, and O2, a design
   holding inner rsets built directly on the analysis set. Or must the
   repeated-row shape run under every tuning function (`nested_tune_bayes()`,
   the two racers, the annealer, `nested_workflow_map()`)? Weigh the M54
   evidence that each tuner finalizes on the frame it gets.
6. Do AC1 to AC7 in the milestone file state the right promises for this
   change? Name any criterion that is wrong, missing, or unsatisfiable.

## Constraints

- IP1 is fixed. Rule 3 (no deprecation period) is the maintainer's choice and
  is not for review.
- The entry checks of D-049, D-103, D-104, D-109 and D-111 stand. If a
  question's answer needs one of them changed, say so explicitly rather than
  work around it.
- The final fit finalizes on the full data, its own training data, and is
  out of scope (IP1's final-fit clause).
- Rules 1 and 2 are the plan gate's choices. If you disagree, say so
  explicitly and give the evidence.

## Output format

In `RR09-repeated-row-inner-frame.md`: answer each question by number with
your reasoning and evidence; list any additional findings separately under
"Beyond the brief"; end with concrete recommendations, each marked apply /
consider / reject-with-reason. Your report is advisory: emit a `## Binding
criteria` section ONLY if this brief's header slot says `requested`. Where
requested: numbered `BC1…`, each a measurable assertion checkable against
evidence, with any numeric projection stating its tolerance. These are
ingested VERBATIM into the constrained milestone's acceptance criteria and
mechanically diffed against this file; departures are legal only through
that milestone's shown "Deviations from RR09" table.
