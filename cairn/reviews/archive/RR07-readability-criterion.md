# RR07: Can a fresh-reader readability criterion be made decidable? (M084)

- **Date:** 2026-09-11
- **Brief:** `cairn/reviews/RB07-readability-criterion.md`
- **Binding criteria:** not requested (none emitted)

## Evidence gathered

Read on branch `m084-guides-plain-prose` at `fb85d5b` plus the three T9
commits (`bcf1cc8`, `4b5aa77`, `c14cdcb`), ref-based reads only. Nothing but
this file was written.

- `Rscript benchmarks/sweep-prose.R` prints `clean`, exit 0; `--terms`
  prints twelve first uses, each a glossing sentence, exit 0.
- The script's own `rmd_paragraphs()` splits the six pages into 28 / 25 / 24
  / 31 / 10 / 8 prose paragraphs (the README's 8 include its badge lines and
  the "Learn more:" line) and 90 / 110 / 92 / 95 / 36 / 17 sentences, mean
  length 10.7 to 14.0 words, longest 30.
- The thirteen reader lists on record: 15, 2, 5, 8, 4, 3, 3, 1, 2 (T7, one
  prompt, text edited between runs), 10 and 17 (review passes 1 and 2), 10
  and 22 (amended AC3, runs 1 and 2). Mean 7.85, sd 6.64, a flag rate of
  6.6% per paragraph per read over about 118 paragraphs. The nine T7 runs
  alone: mean 4.8, sd 4.35 against a Poisson sd of 2.2 (dispersion index
  4.0). Of the 22 flags in amended run 2, 12 were paragraphs untouched
  since run 1 and therefore paragraphs run 1's reader had passed; 10 were
  run 1's own fixes. Of review pass 2's 17, 2 were pass 1's fixes.
- Under the amended prompt the readers were handed the survey list and told
  to read its 30 first; 7 of 10 and 18 of 22 flags fell on survey
  paragraphs, against a base rate of 30 in 118 (25%).
- The frozen intro (`nested-cv.Rmd` 17-33) has sentences of four and five
  finite verbs ("You picked the winner because it scored well, so some of
  its score is luck, and the same number will not hold up on new data";
  "Within each outer fold it tunes ..., fits ..., and scores that fit on
  the assessment rows the tuning never saw"). Its third sentence was 31
  words at `0d8611e` and lost "which" to meet AC1 (work log, T3).
- Sentences naming four or more backtick spans, inline `r` values aside:
  `results.Rmd:132` (4), `results.Rmd:304` (8), `results.Rmd:312` (8).
  No sentence of the intro names more than one.
- First prose sentence of each page: nested-cv "When you tune a model ...",
  estimate "This page runs no code.", tuners "The getting-started guide ...
  tunes each outer fold ...", results "Every tuning function in this package
  returns ...", parallel "A nested run fits many models, and you may want it
  to finish sooner.", README "You tune a model ...". Three of six open on
  the page or the package rather than the reader.
- Second person per page: 7 / 9 / 1 / 3 / 1 / 3 uses of `you`/`your` over
  1287 / 1391 / 1354 / 1404 / 562 / 243 words. No `--`, `contract` or
  `invariant` in prose (AC4). Every vignette chunk uses `|>`.
- `git diff --stat 0d8611e HEAD -- vignettes README.Rmd`: 6 files, +380
  −333. `git blame` over each survey paragraph's line range (the script's
  `rmd_paragraphs()` extents): all 30 hold at least one line from a branch
  commit; 7 of the 30 keep their first line from before the branch, so a
  check on the first line alone would miss them.
- Neither `udpipe` nor `spacyr` is installed, so no dependency parse was
  run; the finite-verb counts above are by hand.

## Answers

### 1. Is the empty-list criterion decidable?

No, and the record is enough to show it without appeal to theory.

**What the list measures.** A reader's list is one draw from a
distribution over subsets of the paragraphs. Three things set that
distribution, and only one of them is the text:

1. *The text.* A few paragraphs carry content that is dense whatever the
   wording: the four negations in estimate's "Four things it is not", the
   stability definition, the two function lists in results' failed-fold
   section, the fit-count arithmetic. These recur across readers and
   across rewrites (the four-negations paragraph is in the survey, in T7,
   in pass 1 item 2 and in pass 2's P11; results' failed-fold paragraphs are
   in the survey, pass 1 item 4, O4 and P2). That is the real signal, and
   it is small: perhaps five to eight paragraphs.
2. *The prompt.* A request for "the paragraphs you could not follow"
   produces a list, because a list is the deliverable. The count tracks
   the framing more than the text: the nine implement-side readers with one
   prompt averaged 4.8; the two review-side readers, with a review's
   framing, gave 10 and 17; the amended prompt, which asked for a
   third-read statement per entry, gave 10 and 22, the two largest lists
   on the best-edited text. An LLM has the whole page in context and does
   not read "once" or "three times"; the read count it reports is a
   prediction about a human reader written in the first person, and it
   costs the reader nothing to give a high one.
3. *The draw.* The nine same-prompt counts are four times as dispersed as
   independent per-paragraph flagging would make them, so reader-level
   strictness varies from run to run. And the flags do not land on the
   same paragraphs: of amended run 2's 22 entries, 12 were paragraphs the
   run 1 reader had passed unchanged. The paragraphs one reader passes
   predict nothing about what the next flags.

The rewrites do move the list, but sideways rather than down. A fix is
itself new text, and new text draws flags: 2 of pass 2's 17 and 10 of
amended run 2's 22 were the previous fixes. Under the standard's clauses
(c) and (e), fixing means splitting, and splitting moves the joint out of
the sentence into a cross-sentence pointer ("that condition", "those four
steps", "the control"), which the next reader flags under (b) or (c). The
criterion partly generates its own findings.

**Whether any rule gives a repeatable pass/fail.** Treat each paragraph as
flagged with some probability on one read and ask when "no paragraph
fails" is the same verdict from two independent panels.

- *One reader, empty list.* At the best rate on record (1 flag in 118,
  0.8%) the chance of an empty list is 0.39; at the T7 average (4%) it is
  0.008; at the amended runs' rates (8% to 19%) it is below 0.0001. For a
  90% chance of an empty list the per-paragraph rate would have to be
  0.09%, one flag in about 1,100 paragraph-reads, ten times lower than the
  best run seen. No prompt change on record moved the rate by that factor
  in the right direction; the amendments moved it up.
- *Majority of k.* For a background rate of 8% and 118 paragraphs, the
  chance that no paragraph is flagged by a majority is 0.11 at k = 3,
  0.59 at k = 5, 0.87 at k = 7 and 0.96 at k = 9. At 12% it takes k = 11
  to reach 0.91; at 19%, k = 15 gives 0.70. So nine to eleven readers per
  run make the background quiet. But a paragraph whose own flag rate is
  near one half is flagged by a majority exactly half the time at every
  k, so two panels agree on it with probability 0.5, whatever k is. The
  recurrent paragraphs above look like that kind. Majority voting cannot
  make the verdict on them repeatable; only rewriting them until their
  rate is near 0 or near 1 can, and the record says rewriting moves the
  flags rather than removing them.
- *Unanimity of k.* Three unanimous readers give a quiet background
  (0.94 at 8%, 0.82 at 12%) but catch a paragraph with a one-half rate
  only 12.5% of the time, and one with a 0.3 rate 2.7% of the time. The
  verdict is repeatable because the rule is insensitive; it certifies
  little.
- *A severity floor.* The amended text tried one ("a third read") and the
  floor itself is a free self-report; it raised the count.

So the estimate the brief asks for: about nine readers with a majority rule
would make the *background* pass repeatable at the rates seen, and no
number of readers makes the pass repeatable while any paragraph sits near
a one-half flag rate. On these pages several do. The criterion is not
decidable as an all-clear, at any reader count, under any aggregation. It
can be made decidable only as a rate ("at most n paragraphs flagged by a
majority of k"), and a rate criterion certifies a different thing from
"reads on one pass".

### 2. Which of (a), (b), (c) can be made repeatable checks?

**(b) as term ordering: yes, and it is already done.** AC2 is the
mechanization of (b) for four words: the script enumerates the domain (every
prose sentence), locates the first use, and a human answers one closed
question about one printed sentence. That is repeatable because the
question is closed and local. It extends to any bounded term list. Rule I
would write: keep AC2's form, and add the package's remaining words a
`tune_grid()` user has not met: `daemon`, `race`/`racing`, `finalize`
(the verb), `selection rule`. What it misses is the other half of (b), the
"problem before term" for things that are not terms: a negation of a claim
the page never raised ("a vote over shared candidates", "not about more
rows or other data"). Those were the (b) flags the readers actually gave,
and no locator finds them, because there is no token to locate.

**(c) as a clause count: partly, and the cap must be calibrated on the
standard.** A finite-verb count per sentence is computable (with `udpipe`,
CRAN, pure R plus a model file, on the `VerbForm=Fin` feature) and a
coordination count is a regex. But the frozen intro has sentences of four
and five finite verbs, so any cap under five fails the standard; and at a
cap of five, under a 30-word cap already in force, the check adds almost
nothing. The (c) flags the readers gave were not clause counts. They were
an appositive stacked between subject and verb, a colon list with an
appositive on it, a sentence naming seven functions, two numbers plus an
appositive, and pointers whose referent sits in another paragraph. Of
those, one is mechanical: name density. Rule: no prose sentence names more
than four backtick spans, inline `r` values excluded. The intro's maximum
is one; today's hits are `results.Rmd:304` and `:312` (eight each), which
are the two paragraphs most readers flagged. What it misses: appositive
stacking (no parser separates a gloss from a list reliably), cross-sentence
pointers (a discourse property), and the clipped rhythm that
over-splitting produces, which is the opposite failure and equally a (c)
failure in the reader's ear.

**(a) as the subject of a paragraph's first sentence: not per paragraph;
yes per page.** The standard's own second and third paragraphs open on
"Nested cross-validation" and "That average". So (a) is not a property
every paragraph of the standard has, and a per-paragraph rule would fail
the reference. The readers agreed in practice: their (a) flags were page
openings (parallel:17, README:24) and nothing else. At page level it is
decidable the way AC2 is: the script prints the first prose sentence of
each page, and a human answers whether it names something the reader does
or wants. Today nested-cv, parallel and the README pass; estimate ("This
page runs no code"), tuners and results open on the page or the package.
What it misses: everything below the first sentence, which is most of
(a); and it can be gamed by a "you" that carries no goal. A section-level
version (first sentence after each H2) is computable too, but roughly four
in five of the 33 section openings name a function, an object or a number,
as reference documentation does, and I would not bind it.

**What cannot be turned into a check:** (a) below the page opening, the
non-term half of (b), and the discourse half of (c). Those are the
readability judgment proper, and they are what the thirteen readers were
disagreeing about.

### 3. The strongest AC3 a named procedure can settle

The property issue #91 names is a human reader's experience, and no
procedure this repo can run enumerates human readers. What a procedure can
settle is (i) the mechanical proxies that the reader lists on record point
at, (ii) that the plan's 30 paragraphs were rewritten, and (iii) that a
reader report was taken and every entry dispositioned. I recommend that
form: the mechanical criteria already in place plus two additions, and a
triaged reader report with no pass rule. A pass rule on the report is the
thing Question 1 shows cannot be made repeatable.

Candidate text, in the repo's form:

> AC3: Three checks and one report.
> (i) No prose sentence on the six AC1 pages names more than four backtick
> spans, inline `r` spans excluded (AC1's prose definition). Evidence:
> `Rscript benchmarks/sweep-prose.R --spans` prints every hit as
> `file:line` and exits 0.
> (ii) The first prose sentence of each of the six pages names something
> the reader does or wants. Evidence: `Rscript benchmarks/sweep-prose.R
> --openings` prints the six sentences as `file:line` and each is read.
> (iii) Each of the 30 paragraphs `cairn/surveys/M084-survey.md` lists
> differs from its text at `0d8611e`. A paragraph's extent is the run the
> script's `--paragraphs` mode prints for the survey's line. Evidence:
> `git blame -L <first>,<last> HEAD -- <file>` on each extent shows at
> least one line from a commit not an ancestor of `2fc728f`.
> (iv) One reader with no authorship of the text, given the standard and the
> six pages and not the survey, reads every paragraph the script's
> `--paragraphs` mode enumerates and reports each paragraph it would send
> back with the clause, (a), (b) or (c), and one line of reason. Clauses
> (d) and (e) are AC2's and AC1's. Every entry is triaged at the review
> gate as fixed, rejected with a reason, or deferred to a ROADMAP candidate
> row, and the triage is recorded in this file's Review section. Evidence:
> the report and its triage, with no entry left without a disposition; a
> fixed entry's rewrite passes AC1, AC2 and (i). The report is taken once
> per review pass and is not rerun after its fixes.

Notes on the text. (i) and (ii) are calibrated on the frozen intro, which
passes both; (ii) fails three pages today, so adopting it costs three
opening sentences. (iii) is the only place the survey belongs: as the
plan's own scope list, checked by diff, not as the domain of a universal
claim and not in the reader's hands, since handing it over is what
concentrated 82% of run 2's flags on it. (iv) binds the process, not the
prose, and says so. The "not rerun" clause is what ends the loop: a second
reader after the fixes is a new draw, not a confirmation, and the record
shows it finds a list of its own every time.

If the maintainer wants a pass rule on the reader anyway, the only form
Question 1 leaves open is a rate over a panel: three readers, each scoring
every enumerated paragraph on a closed per-paragraph rubric (three yes/no
items for (a), (b), (c)) rather than an open list, the frozen intro scored
blind as a positive control that voids the run if any of its three
paragraphs is flagged by a majority, and a pass when at most n paragraphs
are flagged by two of three. I cannot set n from the evidence: closed
per-paragraph questions elicit a different flag rate from open lists, and
no run of that shape exists. Setting it would take at least one
calibration run, which the brief says the maintainer will not iterate on.
So I offer that shape as consider, not apply.

### 4. My own read as the target reader

I read the six pages as someone who has run `tune_grid()` and never
nested. They meet issue #91's complaint as it was written. No double
hyphens, no "contract" or "invariant", no vocabulary a page does not set
up, no unrolled recipe calls, second person at one to nine uses per page
and none of them chatty. The sentences are short and the pages say what
each object is for before they say what it contains. A tidymodels user
can follow them.

The paragraphs I would still send back, most to least:

1. `estimate.Rmd:54-62` "Four things it is not." The third item, "not
   about more rows or other data, since it ran on this training set
   alone", does not say which claim it denies (that the number predicts
   what a larger or different training set would give). The last sentence,
   "So this package offers none", has its referent, a test of the
   method-level quantity, two sentences back. Clause (b), then (c).
2. `results.Rmd:304-317`, the partial-run and no-fold-completed paragraphs.
   Fifteen function names in two sentences, and the second list is
   redundant with its own last sentence: "every reader except `summary()`
   and `collect_notes()` refuses it" says the same in eight words. The
   condition class `nestedtune_partial_summary` is the kind of detail #91
   named in `@param object`; it belongs on the help page. Clause (c), and
   density.
3. `nested-cv.Rmd:278-284`. "tune's functions would hand it over without a
   warning, so the results object and the final fit both refuse tune's
   ranking functions" sits directly under a chunk in which
   `show_best()` on the extracted tune result did hand it over. The reader
   has to work out that the refusal is on the two wrapper objects and not
   on what `extract_tune_results()` returns. Clause (b): the contrast is
   asserted before it is drawn.
4. `estimate.Rmd:125-133`. "The best tuned score read 0.384" is followed
   by "an SVM was 2.5 points too good and a tree only 0.2", which leaves
   the reader asking which learner gave the 0.384. One clause naming it
   ("for the nearest-centroid classifier", or whatever the paper's third
   learner was) closes the gap. Low severity; the figures are verified.
5. `estimate.Rmd:34-45`. Two consecutive paragraphs each list the four
   steps and each say the reported number describes the procedure. The
   second is the fixed IP3 paragraph, so the first should lose its
   restatement. Not an (a)/(b)/(c) failure; a repetition the reader
   notices on the first read.
6. `estimate.Rmd:17`, `tuners.Rmd:17`, `results.Rmd:17`: page openings on
   the page or the package rather than the reader. Clause (a) at page
   level only, and only if the maintainer adopts (ii) above; tuners' nine
   sentences of contents before any goal is the one I would rewrite
   regardless.

That is four to six entries against thirteen lists of 1 to 22, and my
first two are the two paragraphs the record flags most often. It is one
more draw, and I say so: my list is evidence for Question 1's answer
before it is a to-do list.

One thing no reader on record flagged and I would raise: the pages now
carry a clipped rhythm in places ("Four things it is not." "One thing is
added." "The print counts the failure." "Anything tune can tune, this can
tune."). It is the sound of (c) and (e) applied hard. A human editor would
rejoin a few of these. It is not a defect under the standard, and #91 did
not name it, so it is a note for M85 rather than a return.

### 5. Is the frozen intro a fair reference for (b)?

Yes, and the sentence should stay as it is. The intro satisfies (b) at the
granularity the standard defines it, the paragraph: the problem (an
optimistic score) is the whole of paragraph one, the term arrives in
paragraph two, and the three sentences after it say what the procedure
does (splits, tunes, fits, scores). "Scoring the whole tuning procedure
rather than the winner alone" also glosses by contrast, procedure against
single setting, which is how the word is meant everywhere on the pages.
The two readers who flagged it were applying AC2's stricter local test,
"the first sentence says what it names", to a sentence that AC2's own
verification passed twice. Editing it to satisfy the stricter reading
would add an appositive to a 15-word sentence, which is the construction
the same readers flag under (c).

The standard has already been edited once for a mechanical clause ("which"
deleted for the 30-word cap). That is worth recording as a calibration
failure rather than repeating: a mechanical clause the reference text
fails is set tighter than the standard, and the fix is the clause, not the
reference. The same holds for any finite-verb cap under five.

## Beyond the brief

- The survey in the reader's hands biased the reads. Told to read the 30
  first, the amended readers put 70% and 82% of their flags there against
  a 25% base rate. Any future reader protocol should withhold it.
- The amended AC3's "third read" floor is an unanchored self-report and
  raised the counts (0 of 10, then 5 of 22 reported third reads on
  better-edited text). Severity floors on LLM readers need a closed
  rubric, not a number the reader chooses.
- Clauses (c) and (e) push toward a failure the standard does not name:
  sentence splitting moves joints into cross-sentence pointers, which the
  next reader flags under (b)/(c), and it produces the clipped rhythm in
  Answer 4. A future prose standard should say what a sentence may point
  back to.
- Neither `udpipe` nor `spacyr` is installed. If a clause count is ever
  wanted, `udpipe` is the CRAN-only route; its model file is a download,
  so the check would need a network step or a vendored model under
  `benchmarks/`.
- `sweep-prose.R` counts the README's badge lines as prose (O13 on record)
  and reports "Learn more:" as the first sentence after two headings; an
  `--openings` mode needs the badge lines excluded (`^\[!\[`) first.
- The pass-2 lens finding P13 (three names for the reading functions across
  pages) is a term-consistency check the `--terms` mode could take on: one
  chosen name, the others located.
- Issue #91's second-person note was about the help pages and the earlier
  vignettes; at 1 to 9 uses per page the current pages are not the text it
  described, and the M082 "you" cap should stay dropped.

## Recommendations

1. **Apply.** Replace AC3 with the four-part text in Answer 3: the span cap
   (i), the page-opening read (ii), the survey diff (iii), and the triaged
   reader report with no pass rule and no rerun (iv). Add `--spans`,
   `--openings` and `--paragraphs` modes to `benchmarks/sweep-prose.R`,
   calibrated so the frozen intro passes (i) and (ii).
2. **Apply.** Fix Answer 4's items 1 to 3 before the next review pass, and
   item 4 if the paper names the learner. Rewrite the three page openings
   only if (ii) is adopted.
3. **Apply.** Keep `nested-cv.Rmd:23` frozen as it stands; drop the NEWS
   claim if it says every page glosses `procedure` in its first use
   sentence, or leave the claim, since AC2's verification passed the
   sentence twice.
4. **Apply.** Withhold the survey from any future reader; it is a scope
   list for the diff check, not a probe set.
5. **Consider.** If a pass rule on the reader is wanted, the panel-rate
   form in Answer 3 (three readers, closed per-paragraph rubric, majority,
   intro as blind control, pass at most n). It needs one calibration run
   to set n and I do not recommend spending it on this milestone.
6. **Consider.** Record a LESSONS entry: a mechanical prose clause is
   calibrated on the reference text before it is bound, and a reference
   that fails the clause means the clause is wrong.
7. **Reject: rerunning a fresh reader after fixes as confirmation.** Each
   run is an independent draw with a 4% to 19% flag rate; a rerun
   produces a list with near certainty and confirms nothing.
8. **Reject: raising the reader count under the current open-list prompt.**
   Nine readers quiet the background but leave the recurrent paragraphs
   at a coin toss; the cost is nine reads per pass for no repeatability
   where it matters.
9. **Reject: a per-paragraph clause (a) or a finite-verb cap under five.**
   Both fail the frozen intro.
