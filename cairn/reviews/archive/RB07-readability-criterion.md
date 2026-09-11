# RB07: Can a fresh-reader readability criterion be made decidable? (M084)

- **Date:** 2026-09-11
- **Output required:** write findings to `cairn/reviews/RR07-readability-criterion.md`
- **Binding criteria:** not requested

You are performing an independent expert review. This brief is fully
self-contained — do not assume any conversation context. Read only what this
brief directs you to read, answer the numbered questions, and write your
findings to the output path above using the same numbering.

## Background

nestedtune is an R package that runs nested cross-validation for tidymodels
workflows. Its user-facing prose is four vignettes (`vignettes/nested-cv.Rmd`,
`estimate.Rmd`, `tuners.Rmd`, `results.Rmd`), one site-only article
(`vignettes/articles/parallel.Rmd`) and `README.Rmd`. A maintainer's issue
(GitHub #91) said the docs "read the way that an LLM would document things
for themselves" and were hard to read for their density.

Milestone M084 rewrites those six pages for a reader who has run
`tune::tune_grid()` and never nested. Its standard, per paragraph: (a) leads
with what the reader does or wants, (b) states the problem before the term
for it, (c) one idea per sentence, (d) none of the words `procedure`,
`orchestrator`, `candidate` (and `reader` on results.Rmd) before the page
sets it up, (e) no sentence over 30 words. Clauses (d) and (e) are decided by
a script (`benchmarks/sweep-prose.R`, its `--terms` mode for (d)); both are
clean. The accepted reference text is the intro of `nested-cv.Rmd`, lines
17-33.

The problem is acceptance criterion AC3, which binds (a)-(c). Its original
form required that a fresh reader (a subagent with no authorship of the
text, given the standard and the six pages) report an empty list of
paragraphs it could not follow on one read. It has been through these
rounds, all in the milestone file's work log:

- Implement: nine fresh readers in sequence, each list fixed in full before
  the next; lists of 15, 2, 5, 8, 4, 3, 3, 1, 2 paragraphs. Never empty.
- Review pass 1: a fresh reader listed 10. Defect return 1.
- Review pass 2: a fresh reader listed 17, two of them the pass-1 fixes.
  Defect return 2.
- Amendment (two audits by fresh readers, both spent): AC3 narrowed to
  "no paragraph costs a fresh reader a third read, and none of the survey's
  30 originally failing paragraphs is reported for (a), (b) or (c)"; the
  reader must state per entry whether a third read was needed, a missing
  statement counting as yes; the intro is excepted as the standard itself.
- Under the amended text: reader run 1 returned 10 entries, 0 third reads,
  7 survey paragraphs; after fixing all ten, run 2 returned 22 entries, 5
  third reads, 18 survey paragraphs, with 12 of the 22 flagged paragraphs
  untouched between the runs.

So: thirteen fresh reads of substantially the same pages, no two lists
alike, and the run-to-run spread larger than the effect of any rewrite.
The readers are Claude subagents (Opus tier) each given the same prompt.
The repo's rules say an acceptance criterion must be a bounded promise a
named procedure can settle, and that a third defect return forces the
milestone to be descoped to its verified criteria or parked. The
maintainer chose this brief over a further amendment, over review under the
current text, and over stopping.

## Materials

- `cairn/milestones/M084-guides-plain-prose.md`: the Goal, Scope (the
  standard), AC1-AC6 as they now stand, the work log (every reader run and
  every gate choice, dated 2026-09-10 and 2026-09-11), and the `## Review`
  section with both review passes' reader lists verbatim.
- `cairn/surveys/M084-survey.md`: the 30 paragraphs that failed the standard
  at plan time, each with the clauses it failed, refreshed to current lines.
- The six pages themselves. Read `vignettes/nested-cv.Rmd` lines 17-33
  first as the reference standard, then any page you need. Every page is
  under 1,410 words of prose.
- `benchmarks/sweep-prose.R`: the mechanical checks for (d) and (e); run
  `Rscript benchmarks/sweep-prose.R` and `Rscript benchmarks/sweep-prose.R
  --terms` from the repo root (both print and exit 0 today).
- `cairn/milestones/archive/M082-guides-readme-rewrite.md` and
  `M081-help-pages-rewrite.md`: the two prior prose milestones, whose
  criteria were word caps, banned words and a second-person cap only; the
  M084 plan records that none of those was a readability judgment.
- GitHub issue #91 (`gh issue view 91`): the maintainer's original
  complaint, the thing the standard tries to operationalize.

## Questions

1. Is a criterion of the form "a fresh LLM reader reports no paragraph it
   cannot follow on one read" decidable at all, given thirteen runs with no
   two lists alike? State what you take the reader's list to be measuring
   (a property of the text, of the reader, or of the prompt), and whether
   any prompt change, reader count, or aggregation rule (intersection of k
   readers, majority over k, a fixed severity floor) would give a
   repeatable pass/fail on these pages. If you can, estimate the reader
   count such a rule would need from the numbers above.
2. Of clauses (a), (b) and (c), which can be turned into a check a script
   or a reader can apply repeatably (for example, (c) as a count of finite
   verbs or clauses per sentence; (a) as the grammatical subject of a
   paragraph's first sentence; (b) as term-first-use ordering, which (d)
   already does for four words), and which cannot? For each that can, give
   the operational rule you would write and say what it would miss.
3. AC3's job is to certify the pages against issue #91's complaint. Propose
   the strongest acceptance criterion for that job that a named procedure
   can settle, in the repo's bounded-promise form: a universal claim names
   the procedure that enumerates its domain. Write it as a candidate AC3
   text. If your answer is that the deliverable property is
   best certified by the mechanical criteria already in place (AC1, AC2,
   AC4) plus a triaged reader report with no pass rule, say so and write
   that form instead.
4. Independently of the criterion question: read the six pages yourself
   as the target reader and say whether they now meet issue #91's
   complaint. List the paragraphs you would still send back, if any, with
   the reason, so the maintainer can compare your list with the thirteen
   on record.
5. Two of the thirteen readers flagged the reference intro's own first
   sentence for "procedure" (nested-cv.Rmd:23) as using the word before
   glossing it. The intro is frozen as the standard. Is the standard's
   text itself a fair reference for (b), or should the milestone unfreeze
   that one sentence?

## Constraints

- The standard's clauses (a)-(e) and the six-page scope are the plan's and
  are not relitigated here; the question is how to verify them.
- The mechanical checks in `benchmarks/sweep-prose.R` stay as they are
  (M084 AC1, AC2, AC4); a proposal may add to them, not replace them.
- No milestone number, cairn vocabulary, or record identifier reaches the
  user-facing pages.
- The repo's bounded-promise rule (a universal acceptance claim names the
  procedure that enumerates its domain, never a hand list or an author's
  recall) governs any criterion you propose; the milestone has spent its
  two automatic wording audits, so the maintainer will adopt your text or
  a variant at a gate rather than iterate further.
- D-004: inviolable principles bind the artifact; guiding principles bind
  the process. Nothing here touches an inviolable principle; AC5 (the
  estimate describes the tune-and-fit procedure, the final model has no
  number of its own) is verified separately and stays.

## Output format

In `RR07-readability-criterion.md`: answer each question by number with your
reasoning and evidence; list any additional findings separately under
"Beyond the brief"; end with concrete recommendations, each marked apply /
consider / reject-with-reason. Your report is advisory: emit a `## Binding
criteria` section ONLY if this brief's header slot says `requested`. Where
requested: numbered `BC1…`, each a measurable assertion checkable against
evidence, with any numeric projection stating its tolerance. These are
ingested VERBATIM into the constrained milestone's acceptance criteria and
mechanically diffed against this file; departures are legal only through
that milestone's shown "Deviations from RR07" table.
