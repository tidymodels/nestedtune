# RB08: Can a closure's identity be stable across sessions, and what should the check compare if it cannot (M105)

- **Date:** 2026-09-20
- **Output required:** write findings to `cairn/reviews/RR08-closure-identity-stability.md`
- **Binding criteria:** not requested

You are performing an independent expert review. This brief is fully
self-contained — do not assume any conversation context. Read only what this
brief directs you to read, answer the numbered questions, and write your
findings to the output path above using the same numbering.

## Background

`nestedtune` orchestrates nested cross-validation for tidymodels. It drives
the outer loop and delegates inner tuning to `tune`.

Every results object records a **procedure record**. Part of that record is
the **workflow identity**: a deparsed description of the model
specification and the preprocessor the run was given. The workflow object
itself is never stored, for two reasons. Two workflows built from the same
code are never `identical()`, because a recipe step draws its `id` from the
random stream and every quosure captures the frame that built it. And a
recipe holds the training rows in its `template`, so storing the workflow
would copy the user's data onto every record.

`nested_final_fit(object, results)` is the function this exists for. It
re-runs the recorded procedure on the whole dataset to build the model the
user deploys. Before it fits anything, it compares the workflow it is
handed against the identity the record holds, and refuses a workflow that
differs with condition class `nestedtune_workflow_mismatch`. The intended
use is across sessions: a user saves a results object, comes back later,
rebuilds the workflow from the same script, and hands both to
`nested_final_fit()`.

Milestone M105 set out to close one gap in that comparison. Before it, a
setting that is a function was compared by its deparsed text alone, so two
functions with identical text that closed over different values read as one
workflow. M105 makes the identity also record the values the function reads
from outside itself: the names come from `codetools::findGlobals()`, each
name is resolved through the function's enclosing environments, and each
resolved binding is recorded by value.

**M105 has failed review three times.** Every failure was the same
acceptance criterion, and every failure had the same shape: the recorded
identity turned out to depend on something other than what the procedure
computes, so either two workflows built by the same code disagreed (a false
refusal, which is the worst failure this check has), or two workflows that
compute different things agreed (a false pass, which is what the milestone
exists to prevent).

The mechanisms found so far, each reproduced against the current branch:

1. **Enclosure mutation.** A closure that writes to its own enclosure with
   `<<-` (a memo cache, a counter, a lazily computed constant) is recorded
   after the run has mutated it. The stored record holds the post-run value
   and a freshly built workflow holds the pre-run one.
2. **Object identity.** The walk's cycle guard keys on `rlang::obj_address()`.
   A self-referential function that has been through `saveRDS()`/`readRDS()`,
   or through a mirai worker round trip, is no longer the same object as the
   binding it reads, so the walk cuts one level later and the recorded form
   gains a nesting level.
3. **Float printing.** `deparse()` carries 15 significant digits, so
   `0.1 + 0.2` and `0.3` record alike, and so do `-0` and `0`.
4. **Non-standard evaluation.** `codetools::findGlobals()` reports
   data-masked names. `function(dd) subset(dd, x > 1)` records a binding
   `x` read from whatever the session happens to hold.
5. **Locale.** A value holding non-ASCII text deparses as `"café"` under
   `en_US.UTF-8` and `"caf<U+00E9>"` under `C`.
6. **Classed containers.** `deparse_one()` routes a list to the element-wise
   walk only when `is.list(x) && !is.object(x)`, so a function held inside a
   classed list (or any classed container) is deparsed whole and its reads
   are never recorded.
7. **Ambient printing options.** `deparse()` consults `getOption("scipen")`.
   The same unchanged workflow records `1e+05` and then `100000` in one
   session if that option changes in between.

Two attempts to narrow the acceptance criterion to a domain that excludes
these were rejected by independent criteria audits. The first was judged to
be the known failures listed as exceptions, which the next mechanism would
force to grow again. The second was judged to have two fatal properties: to
exclude the known failures it had to define "equal values" as "whatever the
recording procedure produces", which makes under-recording unfalsifiable;
and it had to exclude serialized records, which is the case the feature
exists for.

That is why this question is being escalated rather than answered by
another round of drafting.

## Materials

All paths are relative to the repository root.

Implementation, on branch `m105-identity-closure-values`:

- `R/workflow-identity.R`. The whole file is relevant. In particular:
  `deparse_settings()` at line 147; `deparse_one()` at line 167, whose
  `is.list(x) && !is.object(x)` gate is mechanism 6; `deparse_text()` at
  line 189, which is mechanisms 3, 5 and 7; `read_depth <- 32L` at line
  241; `new_walk()` at line 243 and `closure_identity()` at line 250, whose
  address-keyed `seen` and cache are mechanism 2; `closure_reads()` at line
  293 and `closure_read_names()` at line 308, which is mechanism 4;
  `read_form()` at line 338, which evaluates a binding and is mechanism 1;
  `read_bound <- 2048L` and `bound_read()` at lines 366 and 368;
  `binding_env()` at line 379 and `opaque_env()` at line 400.
- `R/checks.R`: `check_workflow_identity()` at line 1667, which is the
  comparison site, and the difference walk beneath it from line 1700.
- `R/nested-final-fit.R` line 343, where the check runs, and lines 425 and
  477 where the final fit records its own identity.
- `R/nested-tune-grid.R` line 556, where a run records the identity. Note
  that this happens *after* the folds have been dispatched, which is what
  makes mechanism 1 reachable.

Criteria and history:

- `cairn/milestones/M105-identity-closure-values.md`. Read the Goal, Scope,
  Acceptance criteria, and all three `## Review` sections, which record
  every finding and its disposition.
- `cairn/DECISIONS.md`, entry D-066, which chose `codetools::findGlobals()`
  over a hand-rolled `all.vars()` walk and over capturing the whole closure
  environment.
- `cairn/DESIGN.md`, the Architecture paragraph on the identity, and
  principles IP3, GP3 and GP4.

Tests: `tests/testthat/test-workflow-identity.R` and
`tests/testthat/test-nested-final-fit-identity.R`, with fixtures in
`tests/testthat/helper-orchestration.R`.

To run code: `Rscript -e 'pkgload::load_all("."); ...'`. The internal
entry point is `nestedtune:::closure_identity(fn)`, and the public one is
`workflow_identity(wf)`. The suite is `Rscript -e 'devtools::test()'` and
takes about ten minutes.

## Questions

1. Can the identity of a function-valued workflow setting be made stable
   across R sessions and across serialization, while still distinguishing
   two functions that compute different things, and while never capturing
   the training data? If it can, state the construction precisely enough to
   implement, and say which of the seven mechanisms it closes.
2. If it cannot, what should this check compare instead? Consider at least:
   the function's deparsed text alone (the pre-M105 behaviour); a normalized
   abstract syntax tree; a hash of the text plus an explicitly declared set
   of values the user names; or refusing to compare function-valued settings
   at all and saying so.
3. Mechanisms 3, 5 and 7 are all ambient printing state. Is pinning the
   relevant options and encoding inside `deparse_text()` a complete fix for
   that class, or is deparse the wrong serializer for this job? If it is
   wrong, what is the right one, given that the recorded form must stay
   small, human-readable in an error message, and free of training data?
4. Mechanism 1 is reachable because a run records the identity after
   dispatching the folds. Is recording the identity *before* any fold runs
   a sound fix, and what does it break? Note that `nested_final_fit()` also
   records an identity after fitting, at `R/nested-final-fit.R` lines 425
   and 477.
5. Mechanism 4 is a live false-refusal path: a user whose function uses
   non-standard evaluation has session state recorded into their workflow's
   identity. Is there a sound way to tell a data-masked name from a genuine
   free variable, and if not, what should the check do about it?
6. **Should this mechanism be removed?** Weigh reverting M105 entirely:
   the identity compares a function by its text alone, the help page states
   that two functions with one text over different values are not
   distinguished, and the gap goes on the roadmap. Compare that against the
   cost of the alternatives you recommend, and say plainly whether the
   feature earns its complexity.
7. If the feature stays in some form, state an acceptance criterion for it
   whose domain is decided by a procedure over that domain, rather than by
   an enumeration of the failures found so far. If you judge that no such
   criterion exists for this feature, say so, and say what that implies
   about whether it should ship.

## Constraints

These are fixed. Flag disagreement explicitly rather than working around
them silently.

- The identity must never carry the training data, and its size must not
  grow with the data (GP4, and the reason the workflow itself is not
  stored). This is what ruled out capturing the whole closure environment
  at M105's plan gate.
- D-066 put `codetools` in Imports as the reader of the names a function
  uses. You may recommend superseding it, but say so explicitly and give
  the rationale, rather than assuming a different scanner.
- The package is pre-1.0 and D-003 waives the deprecation cycle, so a
  breaking change to what the identity records is permitted. A record saved
  under an older version may be refused.
- A false refusal is worse than a false pass for this check: it blocks a
  user from fitting a model they are entitled to fit, with no workaround
  other than not using the recorded check. D-066 records this ranking.
- `nested_final_fit()` must keep refusing a workflow whose model or
  preprocessor genuinely differs, with class `nestedtune_workflow_mismatch`
  and a message naming the part that differs (M083, M103, unchanged here).

## Output format

In `RR08-closure-identity-stability.md`: answer each question by number
with your reasoning and evidence; list any additional findings separately
under "Beyond the brief"; end with concrete recommendations, each marked
apply / consider / reject-with-reason. Your report is advisory: emit a
`## Binding criteria` section ONLY if this brief's header slot says
`requested`.
