# M089: The prose sweep reads as prose only what its definition names

- **Status:** in-progress
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

- [ ] AC1: The parser drops a badge line (`^\[!\[`), an indented fence with its body, and every line of a multi-line HTML comment. A fixture page plants all three, its comment running three lines with no `-->` on the opening line. Evidence: `Rscript benchmarks/sweep-prose.R --paragraphs --pages <fixture>` lists no paragraph whose extent holds a planted line. The same command against the branch-point script lists a paragraph for each plant.
- [ ] AC2: The parser drops a list-item line, bulleted or numbered (`^\s*[0-9]+\. `), with the continuation lines belonging to it. The fixture plants a wrapped bulleted item whose continuation line carries a plain-clause marker. It also plants a numbered item whose sentence runs past the 30-word cap. Evidence: over the fixture, `--paragraphs` lists no paragraph holding one of those lines, and `--plain` and the bare sweep report nothing from either plant. Against the branch-point script the same three commands report the continuation line's clause and the numbered item's over-cap sentence.
- [ ] AC3: No paragraph the sweep prints over the six pages holds a badge, comment, fence or list-item line. None begins on the line after a list-item line. Evidence: the output of `Rscript benchmarks/sweep-prose.R --paragraphs` at the head, compared in this file's Review section against `grep -nE '^\[!\[|^\s*<!--|^\s*```|^\s*([-*]|[0-9]+\.) '` over those six pages. From the branch point the same comparison names nine paragraphs, read at `c4bb5f9`: `README.Rmd:20-21`, `estimate.Rmd:57`, `estimate.Rmd:60`, `estimate.Rmd:62-65`, `README.Rmd:79`, `README.Rmd:81`, `README.Rmd:83-84`, `README.Rmd:86` and `README.Rmd:88`.
- [ ] AC4: Six invocations print `clean` and exit 0 at the head. They are `Rscript benchmarks/sweep-prose.R`, the same with `--spans`, the same with `--plain`, and each of those three again with `--roxygen`. Evidence: the six outputs.
- [ ] AC5: `Rscript -e 'devtools::test()'` runs clean. `Rscript -e 'devtools::check()'` reports 0 errors, 0 warnings and 0 notes.

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
- [ ] T6: Run `Rscript -e 'devtools::test()'`, then `Rscript -e 'devtools::check()'`, then `air format --check` on the two touched R files.

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

## Decisions

## Review
