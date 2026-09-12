# M089: The prose sweep reads as prose only what its definition names

- **Status:** review
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — a development checker over the repo's own page sources, kept out of the built package by `.Rbuildignore`
- **Branch/PR:** `m089-prose-sweep-parse`

## Goal

`benchmarks/sweep-prose.R` reads as prose only what its stated definition names, so no badge, fence, comment or list-item line reaches a sweep.

## Scope

**In:** `rmd_paragraphs()` in `benchmarks/sweep-prose.R`, the prose definition in the script header, a fixture page planting each leak, and one test block over that fixture.

**Out:**
- Sweeping list items. A sentence over the word cap or failing a plain clause inside a list item stays uncatchable. That remainder goes to the candidate row this plan writes.
- The duplicated page list and gating-mode list, which go to M090.
- A passive-voice or `-ing` clause on `--plain`. The `DESIGN.md` Known issues entry owns that limitation.
- Rewriting page prose. Measured at this plan gate, a repaired parser leaves `sweep-prose.R`, `--spans` and `--plain` printing `clean` over the six pages.

## Acceptance criteria

- [x] AC1: The parser drops a badge line (`^\[!\[`), an indented fence with its body, and every line of a multi-line HTML comment. A fixture page plants all three, its comment running three lines with no `-->` on the opening line. Evidence: `Rscript benchmarks/sweep-prose.R --paragraphs --pages <fixture>` lists no paragraph whose extent holds a planted line. The same command against the branch-point script lists a paragraph for each plant.
- [x] AC2: The parser drops a list-item line, bulleted or numbered (`^\s*[0-9]+\. `), with the continuation lines belonging to it. The fixture plants a wrapped bulleted item whose continuation line carries a plain-clause marker. It also plants a numbered item whose sentence runs past the 30-word cap. Evidence: over the fixture, `--paragraphs` lists no paragraph holding one of those lines, and `--plain` and the bare sweep report nothing from either plant. Against the branch-point script the same three commands report the continuation line's clause and the numbered item's over-cap sentence.
- [x] AC3: No paragraph the sweep prints over the six pages holds a badge, comment, fence or list-item line. None begins on the line after a list-item line. Evidence: the output of `Rscript benchmarks/sweep-prose.R --paragraphs` at the head, compared in this file's Review section against `grep -nE '^\[!\[|^\s*<!--|^\s*```|^\s*([-*]|[0-9]+\.) '` over those six pages. From the branch point the same comparison names nine paragraphs, read at `c4bb5f9`: `README.Rmd:20-21`, `estimate.Rmd:57`, `estimate.Rmd:60`, `estimate.Rmd:62-65`, `README.Rmd:79`, `README.Rmd:81`, `README.Rmd:83-84`, `README.Rmd:86` and `README.Rmd:88`.
- [x] AC4: Six invocations print `clean` and exit 0 at the head. They are `Rscript benchmarks/sweep-prose.R`, the same with `--spans`, the same with `--plain`, and each of those three again with `--roxygen`. Evidence: the six outputs.
- [x] AC5: `Rscript -e 'devtools::test()'` runs clean. `Rscript -e 'devtools::check()'` reports 0 errors, 0 warnings and 0 notes.

## Coverage

- AC1 → T1, T2, T4
- AC2 → T1, T2, T4
- AC3 → T2, T5
- AC4 → T2, T5
- AC5 → T6

## Tasks

- [x] T1: Write `tests/testthat/fixtures/sweep-prose-parse.Rmd`. It carries a badge line and an indented fence whose body holds a plain-clause marker. It carries a three-line HTML comment with a marker on its middle line. It carries a wrapped bulleted item whose continuation line holds a marker. It carries a numbered item whose sentence runs past the 30-word cap. It carries one marker straddling a backtick span, which must still be reported. Run the branch-point script over the fixture and record each plant's output in the work log.
- [x] T2: Rewrite `rmd_paragraphs()` in `benchmarks/sweep-prose.R`. Drop a badge line in every mode. Match a fence line that carries leading whitespace. Drop every line of an HTML comment from its opening line through the line holding `-->`. Drop a bulleted or numbered list-item line together with the continuation lines up to the next blank line.
- [x] T3: Rewrite the script header's prose definition and its `--openings` and `--paragraphs` mode entries, so that they state the partition T2 implements. Read each sentence against T1's fixture output.
- [x] T4: Add one `test_that()` block over the fixture. Each expectation names the plant it covers, the straddling marker included.
- [x] T5: Run `--paragraphs` and AC3's grep over the six pages, and run the six gating sweeps. Record every output.
- [x] T6: Run `Rscript -e 'devtools::test()'`, then `Rscript -e 'devtools::check()'`, then `air format --check` on the two touched R files.

## Work log

- 2026-09-11: created by /milestone-plan. Promoted from the standing `benchmarks/sweep-prose.R` candidate row, which the M084 and M088 review gates both wrote into.
- 2026-09-11: measured at the plan gate against `c4bb5f9`, on a planted page. A wrapped bulleted item's 31-word sentence is not reported. Its continuation line is reported as free prose. A numbered item's 31-word sentence is reported as ordinary prose. A three-line comment's body is swept. A badge line is swept in every mode but `--openings`. An indented fence's lines form a prose paragraph. Its text reached no plain clause in the four shapes tried, because backtick-span stripping swallowed the fence body.
- 2026-09-11: the plan-gate criteria audit ran in reduced mode and returned four findings over both milestones. A list-item promise quantifying over every input narrowed to the fixture's planted cases. A cross-commit comparison of nine invocations carrying a hand-written exemption became AC3's single-commit promise. A criterion binding the script's own header prose was dropped, and the header rewrite became T3. For M090, one `grep` widened to read a profile slot whole.
- 2026-09-11: plan gate chose repairing the parse leaks over also sweeping list items, because the checker then keeps the promise it already makes. Falsified by a sentence over the cap, or failing a plain clause, shipping inside a list item on a page.
- 2026-09-11: plan gate chose dropping numbered list items from prose over leaving them swept as they are today. A numbered and a bulleted item are one construct, and the stated definition excludes both. Falsified by a page that wants its numbered steps swept while its bullets are not.

- 2026-09-11: implement gate settled two parser rules. An HTML comment drops only from a line that starts with the opener, so prose before a trailing comment stays swept. A list item's continuation run ends at the next blank line whatever the indent, the rule T2 states.
- 2026-09-11: T1 fixture written, branch-point output recorded over it. `--paragraphs` lists eight paragraphs, one per plant. They sit at lines 2-3, 5, 8-9, 11, 13-16, 19, 21-23 and 25. `--plain` reports three modal clauses, at lines 8, 11 and 19, and exits 1. The bare sweep reports the numbered item's 37-word sentence at line 21 and exits 1. The indented fence's own modal is not reported, backtick-span stripping swallowing the fence body as the plan gate measured. `devtools::test()` clean, 9826 pass.
- 2026-09-11: T2 rewrote `rmd_paragraphs()`, and the `badges` argument went with it. Over the fixture `--paragraphs` now lists two paragraphs, at lines 11 and 25, so no planted line sits in a printed extent. `--plain` reports the straddling modal at line 11 alone and the bare sweep prints `clean`. Over the six pages `--paragraphs` lists 122 paragraphs. None holds a badge, comment, fence or list-item line. None opens on the line after an item. The nine paragraphs the branch point named are gone. The six gating sweeps print `clean` and exit 0. `devtools::test()` clean, 9826 pass. `air format --check` clean.
- 2026-09-11: T3 restated the header's prose definition as the partition T2 implements, and dropped the badge clause from the `--openings` entry. Each clause was read against an execution. The fixture covers the comment, badge, fence, bulleted and numbered clauses. A scratch page covered the YAML, heading and indented-item clauses, its only paragraph the closing prose line. `devtools::test()` clean, 9826 pass. `air format --check` clean.
- 2026-09-11: T4 added one `test_that()` block over the parse fixture, naming each plant by a string only that plant carries. No paragraph extent holds the badge, comment-body, indented-fence, bulleted-wrap or numbered-item line. The straddling modal is the one clause reported, at the right line. The bare sweep prints `clean`. The block is shown able to fail. Over the same fixture the branch-point script at `584f41d` lists 8 paragraphs rather than 2. It prints 4 `--plain` lines rather than 2, and ends the bare sweep on `1 hit(s)`. Suite 9849 pass, up 23 from 9826. `air format --check` clean.
- 2026-09-11: T5 re-ran AC3's comparison and the six gating sweeps at the head. `--paragraphs` lists 122 paragraphs over the six pages, and a script crossing every extent with AC3's grep finds 0 violations. Counts per page: README 3, parallel 10, estimate 25, nested-cv 29, results 31, tuners 24, so no page's domain is empty. All six gating sweeps print `clean` and exit 0.
- 2026-09-11: T6 ran the full checks. `devtools::test()` clean at 9849 pass. `devtools::check()` returns status OK in 9m 36s, 0 errors, 0 warnings, 0 notes, its own test run 836s OK. `air format --check` clean on `benchmarks/sweep-prose.R` and `tests/testthat/test-sweep-prose.R`.
- 2026-09-11: claim audit: not owed — internal tier.
- 2026-09-11: no plan amendment was needed. Every task landed as planned, and no acceptance criterion changed.
- 2026-09-12: review checkpoint, partial. AC1-AC4 verified with fresh evidence and ticked. AC5's `devtools::test()` and `devtools::check()` run is still in flight, and the diff-bug lens is still reading; the blame-history and prior-review lenses each reported no findings. `cairn_validate` green, `air format --check` clean on the two touched R files.
- 2026-09-12: every acceptance criterion verified with fresh evidence and ticked. Consistency gate green. Three lenses ran; two reported no findings and the diff-bug lens returned eleven, all reproduced or read against the implementation, none failing a criterion inside its named procedure's domain. Pre-gate checkpoint.
- 2026-09-12: gate triage applied. Findings 1, 2 and 7 fixed in `rmd_paragraphs()` and its header, with one further `test_that()` block guarding the two parse fixes, shown able to fail by reverting each in turn. Findings 3-6, 9 and 10 went to one candidate row; 8 rejected as pre-existing; 11 no action. The fixture, AC3's comparison and the six gating sweeps are unchanged by the fixes.

## Decisions

## Review

_Evidence gathered 2026-09-12 at `830c836`, against the branch point `584f41d`. `main` had not moved since the branch was cut (`git rev-list --left-right --count origin/main...HEAD` reads `0	6`), so no merge was needed before gathering it._

### Acceptance-criterion evidence

- **AC1 — pass.** `Rscript benchmarks/sweep-prose.R --paragraphs --pages tests/testthat/fixtures/sweep-prose-parse.Rmd` prints two paragraphs, `11-11` and `25-25`, and exits 0. Neither extent holds the badge line (5), the indented fence (13-16), or any line of the three-line HTML comment (7-9, whose opening line carries no `-->`). The branch-point script over the same fixture prints eight paragraphs, one per plant: `2-3` and `8-9` (comment bodies), `5-5` (badge), `13-16` (fence), `19-19` and `21-23` (the two list plants), plus the two prose paragraphs.
- **AC2 — pass.** Over the fixture at the head, `--paragraphs` prints no paragraph holding the wrapped bulleted item (18-19) or the numbered item (21-23); `--plain` reports one clause, the straddling modal at line 11, and the bare sweep prints `clean` and exits 0, so neither list plant is reported. The branch-point script reports the continuation line's modal at `19` under `--plain` and the numbered item's 37-word sentence at `21` under the bare sweep, each exiting 1.
- **AC3 — pass.** `Rscript benchmarks/sweep-prose.R --paragraphs` prints 122 paragraphs over the six pages (README 3, parallel 10, estimate 25, nested-cv 29, results 31, tuners 24), exit 0. Crossing every printed extent against the 202 lines AC3's grep returns over those pages finds 0 paragraphs holding a badge, comment, fence or list-item line, and 0 paragraphs opening on the line after one of the 9 list-item lines. The nine paragraphs the branch point named are gone.
- **AC4 — pass.** Six invocations, each printing `clean` and exiting 0: `sweep-prose.R`, `--spans`, `--plain`, `--roxygen`, `--roxygen --spans`, `--roxygen --plain`.
- **AC5 — pass.** `Rscript -e 'devtools::test()'` ends `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 9849 ]`. `Rscript -e 'devtools::check()'` returns `Status: OK` in 10m 7s, 0 errors, 0 warnings, 0 notes, its own test run `[887s/476s] OK`.

### Consistency gate

`cairn_validate.py` exits 0, every check PASS or OK, 18 advisory warnings on `references/` extraction staleness that predate this branch. No principle changed, so `cairn_impact.py` was not run. Toolchain slot: `devtools::document()` leaves the tree clean; `pkgdown::check_pkgdown()` reports no problems; README.md and README.Rmd are untouched by the diff; the change is a development checker under `benchmarks/`, which `.Rbuildignore` strips, so no `NEWS.md` entry is owed; the one added file sits under `tests/testthat/fixtures/` and needs no ignore entry, and `check()` reports 0 notes; the six gating sweeps are AC4's evidence. `air format --check` clean on `benchmarks/sweep-prose.R` and `tests/testthat/test-sweep-prose.R`.

### Independent review

Three fresh-context lenses, the diff touching executable surface. The blame-history lens reported no findings: the `badges` removal and the whole-list-item drop are the tracked resolution of a gap M084 and M086 named and deferred, and nothing in `DECISIONS.md` bears on the script. The prior-review lens reported no regression against archived `## Review` findings, and its GitHub probe found one real inline comment, on an unrelated file, so no thread walk was warranted. The diff-bug lens returned eleven findings, ranked; each was reproduced or read against the implementation before disposition.

Findings in the lens's own rank order, each with the verification run here and the disposition recommended at the gate. Scratch pages used for reproduction live under the session scratchpad, not the repo.

1. **[fixed at the gate]** **An unclosed `<!--` drops every line to EOF, and the sweep still reports `clean`.** `benchmarks/sweep-prose.R:329-344`: `open` is set on `^\s*<!--` and cleared only by a line holding `-->`. Reproduced: a page whose line 3 opens a comment with no closer prints one paragraph (`1-1`) under `--paragraphs`, and both the bare sweep and `--plain` print `clean` and exit 0, though lines 5 and 7 carry a 38-word sentence and a modal. The branch-point parser dropped the opener line alone. The failure removes the gate's domain rather than leaking into it. Recommended: fix now.
2. **[fixed at the gate]** **The list-item loop reads lines the parser already dropped, so a `- ` line inside the YAML header or a fenced chunk takes the prose that follows.** `benchmarks/sweep-prose.R:347-360` has no `if (!keep[i]) next` guard, unlike the fence and comment loops, and the run ends only at a blank line, which neither `---` nor a closing fence is. Reproduced twice: a YAML `author:` list followed by `---` and an immediate prose line drops that line; a ```` ```yaml ```` chunk holding `- a list looking line` followed by a closing fence and an immediate prose line drops it too. Latent on the six pages, which carry neither shape. Recommended: fix now.
3. **A loose list's continuation paragraph is swept as prose.** The blank line inside a loose list clears `item`, so an indented continuation paragraph prints as a paragraph and its `may` is reported by `--plain`. Reproduced. The Goal and AC3 speak of a list-item *line*, and Scope Out puts sweeping list items outside this milestone, so this is the standing remainder. Recommended: follow-up, folded into the list-item candidate row.
4. **A multi-line HTML comment opened partway through a line leaks its body into prose.** `benchmarks/sweep-prose.R:336` requires `^\s*<!--`. Reproduced: `Trailing prose here <!-- a comment opened partway` and the two lines under it print as one paragraph `1-3`, and `--plain` reports a modal from the comment body. The implement gate chose the opener-at-line-start rule deliberately (work log, 2026-09-11), and the rewritten header states it, so code and header agree; AC1's first sentence is the wider wording, and its second and third sentences scope the promise to the fixture's own comment. Read that way the criterion holds. Recommended: follow-up.
5. **A prose line opening with digits and a period is dropped as a numbered item, with the non-blank lines under it.** `^\s*([-*]|[0-9]+\.) ` at line 355. Reproduced: `2020. The year a numbered-looking prose line opens with, and it may matter.` and the line under it both vanish, and `--plain` prints `clean`. The header states the rule literally, so this is the rule's cost, not a divergence. Recommended: follow-up.
6. **Prose after a closer on a one-line comment's own line is dropped.** Header-consistent, the same shape as finding 4. Recommended: follow-up.
7. **[fixed at the gate]** **A new code comment states a reason that does not hold.** `benchmarks/sweep-prose.R:313-314` says the YAML drop means a `---` inside the header never opens a fence, but the fence test is `^\s*``` `, which `---` cannot match with or without that drop. The guard on line 316 is real and does other work; the sentence misexplains it. Recommended: fix now.
8. **Setext headings are prose, and the YAML rule is the first two `^---$` lines anywhere in the file.** Pre-existing at the branch point, restated rather than introduced by this diff. Recommended: reject, out-of-scope taxonomy (a pre-existing issue the diff did not introduce).
9. **The widened fence regex can close a fence early**, on an indented fence inside a chunk that demonstrates markdown. No current page has an indented fence at all. This is the price of AC1's indented-fence rule. Recommended: follow-up.
10. **Test quality.** `tests/testthat/test-sweep-prose.R:84-90`: a `--paragraphs` line that failed the extent regex would error in `seq.int(NA, NA)` rather than fail an expectation, and the plant assertions are all negative, so a parser that drops too much is ruled out only by the two positive checks and `expect_length(paragraphs$lines, 2L)`. Recommended: follow-up.
11. **Bookkeeping.** The lens read the milestone file mid-review, when this pass had ticked AC1-AC4 and not yet AC5; no defect. It also notes `cairn/reviews/archive/RR07-readability-criterion.md:15` now carries stale per-page paragraph counts — an archive, so IP4 leaves it. Recommended: no action.

No finding demonstrates an acceptance criterion failing inside the domain of the procedure that criterion names, so the return floor is not reached on the evidence alone.

### Triage at the gate

The maintainer directed fix-now on findings 1, 2 and 7, follow-up on 3, 4, 5, 6, 9 and 10, rejection of 8 as pre-existing at the branch point, and no action on 11.

Findings 1 and 2 are fixed in `rmd_paragraphs()`. An opener with no `-->` under it now closes nothing and drops its own line alone, so a typo can no longer empty a page of the prose a sweep would read; the list-item loop now skips lines the parser already dropped, matching the fence and comment loops, so an item-shaped line inside the YAML header or a fenced chunk opens no run. The header's prose definition states the unclosed-comment rule. Finding 7's comment is rewritten to say what the guard under it does.

One further `test_that()` block guards both, on pages written in the test rather than on the committed fixture, whose paragraph count the block above asserts. Each of the two fixes was reverted in turn and the block failed: reverting the list-loop guard fails two expectations, reverting the comment lookahead fails one.

Re-verification after the fixes: the fixture's `--paragraphs`, `--plain` and bare-sweep outputs are unchanged, so AC1 and AC2 stand. AC3's comparison still gives 122 paragraphs over the six pages with 0 holding an excluded line and 0 opening after a list item. The six gating sweeps still print `clean` and exit 0. `air format --check` clean on both touched files.

