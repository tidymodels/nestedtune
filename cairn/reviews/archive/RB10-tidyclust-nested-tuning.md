# RB10: Nested tuning of tidyclust models (candidate row, no milestone)

- **Date:** 2026-10-18
- **Output required:** write findings to `cairn/reviews/RR10-tidyclust-nested-tuning.md`
- **Binding criteria:** not requested

You are performing an independent expert review. This brief is fully
self-contained — do not assume any conversation context. Read only what this
brief directs you to read, answer the numbered questions, and write your
findings to the output path above using the same numbering.

## Background

`nestedtune` is an R package that runs nested cross-validation for the
tidymodels ecosystem. It drives the outer loop and delegates inner tuning to
tune and finetune. For each outer fold it calls a tuner (`tune::tune_grid()`
and six others) on that fold's inner `rset`, selects one candidate from the
inner results with a selection rule (`tune::select_best()` by default), fits
the finalized workflow on the outer analysis set with `tune::last_fit()`, and
scores it on the outer assessment set. The nested estimate is the average of
the outer scores. It describes the whole tune-and-fit procedure, never the
shipped model (IP3 below).

The README has a "Supported tuning functions" table. Seven rows read `Yes`.
One row, `tidyclust::tune_cluster()`, reads `No`, with the sentence "nothing
yet settles what a nested estimate of a clustering metric means."

The project's ROADMAP holds this candidate row, parked:

> Nested tuning of tidyclust models: Nested tuning of a tidyclust model
> through `tune_cluster()` — added 2026-09-21 at the M106-M109 plan gate.
> Nothing settles what a nested estimate of a clustering metric means, and no
> oracle exists (RB tripwire: no-oracle), so the next step is a
> `/milestone-brief` escalation on that question. Adding tidyclust to
> Suggests takes a D-entry. Promote when an RR answers the question

This brief is that escalation. The maintainer wants to know whether the row
is worth promoting to a milestone, worth keeping parked under a sharper
condition, or should be dropped as rejected on principle. No user has asked
for the feature. The row came from a plan gate that listed the tuners in the
ecosystem, not from demand.

## Materials

Read these in the repository:

- `cairn/DESIGN.md`, lines 6-56 (Purpose & Scope, the contract boundary) and
  lines 199-292 (the principles IP1-IP4 and GP1-GP5).
- `R/nested-tune-grid.R`, lines 1-140: the roxygen block, which states the
  per-fold procedure in code (`tune_grid()`, `select_best()`,
  `finalize_workflow()`, `last_fit()`).
- `R/tuner.R` and `R/selection-rule.R`: how a tuner and a selection rule are
  plugged into the outer loop.
- `README.Rmd`, lines 110-140: the tuning-function table and its prose.
- `cairn/references/INDEX.md`, and any source note it lists that you find
  relevant. `cairn/references/arlot2010.md` and `cairn/references/krstajic2014.md`
  define the estimand the package targets. `cairn/references/varma2006.md`
  shows the oracle design the package uses for supervised models (a known
  null where the truth is fixed by construction).

tidyclust is not installed in this checkout. Read its source and
documentation on the web: the CRAN package page, the GitHub repository
`tidymodels/tidyclust`, and its reference pages for `tune_cluster()`,
`cluster_metric_set()`, `sse_within_total()`, `sse_total()`, `sse_ratio()`,
`silhouette_avg()`, `predict()` on a cluster fit, and any `last_fit()` or
`finalize_*()` support. If you need to run code, you may install tidyclust
into a temporary library (`install.packages("tidyclust", lib = tempfile())`
after creating that directory) and load it with `lib.loc`. Never install
into the project's default library, and never edit `DESCRIPTION`.

You may also search the literature on choosing the number of clusters by
cross-validation or by stability (for example prediction strength, Tibshirani
and Walther 2005; Wang 2010; Fu and Perry 2020; Lange et al. 2004; Ben-Hur et
al. 2002). Cite what you rely on with enough detail to find it.

## Questions

1. **The estimand.** For each tidyclust metric that `tune_cluster()` can
   tune on (`sse_within_total`, `sse_total`, `sse_ratio`, `silhouette_avg`,
   and any others it ships), what quantity would the outer-fold average
   estimate if nestedtune ran the per-fold procedure above? Say whether that
   quantity is a property of the tune-and-fit procedure that a user could
   report and act on, in the sense IP3 requires, or whether it is not well
   defined. Address directly that within-cluster SSE falls as the number of
   clusters rises, so selecting the best SSE on inner folds may only pick the
   largest candidate.

2. **The mechanics.** Does tidyclust give the outer loop what it needs:
   a tuning result that `select_best()` (or a tidyclust counterpart) reads,
   a way to finalize and fit on the outer analysis set, and a way to score
   the fitted model on held-out rows (`predict()` to assign clusters, metrics
   computed with `new_data`)? Name each piece that exists, each that is
   missing, and whether `tune::last_fit()` accepts a cluster workflow. Say
   how `tune_cluster()` itself scores its assessment sets.

3. **The oracle.** The project's GP2 asks for at least two independent
   oracle types before a numeric result ships. What oracle could verify a
   nested clustering estimate: for example simulated mixtures with a known
   number of clusters and known within-cluster variance, a closed-form
   expected SSE, or a stability-based reference? Say whether any of these
   gives a known answer for the nested estimate itself, as opposed to the
   selected number of clusters.

4. **Fit with the principles.** Does shipping nested clustering estimates
   conflict with GP5 ("Don't ship inference the literature hasn't
   settled"), IP3, or IP4? If the honest answer is that cross-validated
   choice of k is itself contested, say so and say which side, if any, the
   literature favors.

5. **The disposition.** Recommend one of three outcomes for the candidate
   row, with reasons:
   (a) promote: state the smallest milestone scope that would be defensible
   (which metrics, which tuner, which oracle), and the dependency it adds;
   (b) keep parked: state a promotion condition as the class of evidence
   that would change your answer, not as a count of requests;
   (c) drop as rejected on principle: state the principle in one or two
   sentences that a decision record could carry, and what evidence would
   later reopen it.

6. **The README row.** Whatever the disposition, is the README's sentence
   "nothing yet settles what a nested estimate of a clustering metric means"
   accurate? If not, give a replacement of one or two plain sentences.

## Constraints

- The contract boundary is fixed: nestedtune drives the outer loop and
  delegates the inner search to tidymodels packages (D-002). Owning a
  clustering engine or a new tuner is out of scope.
- IP1-IP4 are inviolable and are not to be relitigated here. GP1-GP5 are
  defaults that a milestone can trade only with stated justification.
- Adding tidyclust to `Suggests` is a dependency change and takes its own
  decision record at a plan gate. Do not treat it as free.
- The README table's `Yes` rule is fixed by D-110: a row reads `Yes` only
  when a nested counterpart exists and a test runs it with `vfold_cv()` in
  both loops with every outer fold completing.
- If you disagree with a constraint, say so explicitly under "Beyond the
  brief" rather than working around it.

## Output format

In `RR10-tidyclust-nested-tuning.md`: answer each question by number with
your reasoning and evidence; list any additional findings separately under
"Beyond the brief"; end with concrete recommendations, each marked apply /
consider / reject-with-reason. Your report is advisory: do not emit a
`## Binding criteria` section, because this brief's header slot says
`not requested`.
