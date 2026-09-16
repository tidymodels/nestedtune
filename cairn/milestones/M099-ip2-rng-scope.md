# M099: IP2's text names the randomness it reaches

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2
- **Resolves:** —
- **Surface tier:** internal — a DESIGN.md principle sentence and a D-entry
- **Branch/PR:** `m099-ip2-rng-scope`

## Goal

IP2's own text in `cairn/DESIGN.md` states that it binds only randomness flowing through R's generator, the clause D-011's Consequences and the reproducibility help template already carry.

## Scope

**In:** one added sentence in the IP2 entry with an amendment annotation; one D-entry recording the amendment; a read of `man-roxygen/section-reproducibility.R` to confirm the template's last paragraph and the new sentence name the same bound.

**Out:** any change to the seeding scheme or to the help template's wording (none needed; a divergence found at T1 returns to plan); a test on an engine that bypasses R's RNG (untestable by construction, RR01 B4).

## Acceptance criteria

- [x] AC1: The IP2 entry in `cairn/DESIGN.md` (line 211 at `bc905a4`) carries one added sentence stating that IP2 binds randomness flowing through R's generator and that engines randomizing outside it (kernlab's SVMs, the deep-learning engines) are outside its reach under any R-side scheme, followed by an italic amendment annotation naming the D-entry, in the form IP1's annotation takes (`cairn/DESIGN.md:208-210`).
- [x] AC2: One D-entry, appended above the `<!-- Template:` block in `cairn/DECISIONS.md`, records the amendment, cites D-011's Consequences paragraph and RR01 finding B4 as its sources, and supersedes no entry; `git diff main` on the branch touches no line of `cairn/DECISIONS.md` above the new entry.
- [x] AC3: `python3 cairn_validate.py` is green on the branch.

## Coverage

- AC1 → T2
- AC2 → T1
- AC3 → T3

## Tasks

- [x] T1: Draft the D-entry (next id after the last `### D-` heading; append above `<!-- Template:`, the M33 lesson) citing `cairn/DECISIONS.md` D-011 Consequences and `cairn/reviews/archive/RR01-rng-streams-outer-folds.md:361-367`; re-read the heading in place. (RB tripwire: ip-touching)
- [x] T2: Add the sentence and the annotation to the IP2 entry; compare its bound and engine examples with `man-roxygen/section-reproducibility.R`'s last paragraph and record the read in the work log.
- [x] T3: Run `cairn_validate.py`; open the PR per the git model (a `cairn/`-only change on a milestone branch still merges through the PR gate, since it amends a principle).

## Work log

- 2026-09-16: created by /milestone-plan from the candidate row added 2026-07-25 (RR01 B4), promoted at the 2026-09-16 triage pass.
- 2026-09-16: plan gate chose amending IP2's text with an annotation over leaving the clause in D-011 and the template because the row's trigger fired at triage and DESIGN.md's principle preamble says an IP changes only by a D-entry; falsified by a reader of DESIGN.md still asking which randomness IP2 covers.
- 2026-09-16: implement gate adopted the drafted IP2 sentence and D-064 as shown; the ip-touching escalation offer was declined.
- 2026-09-16: T1 done: D-064 appended above the template block, heading re-read in place; cites D-011 Consequences and RR01 B4, supersedes nothing.
- 2026-09-16: T2 done: IP2 sentence and annotation added in IP1's annotation form. Read `man-roxygen/section-reproducibility.R` last paragraph: same bound (randomness through R's generator), same engine examples (kernlab's SVMs, the deep-learning engines), same "here or in tune" clause; no divergence, template untouched.
- 2026-09-16: T3 done: `cairn_validate.py` all checks passed on the branch (18 advisory warnings, all pre-existing references staleness). Minor amendment: T3's "open the PR" clause is executed by `/milestone-review` at its merge step, where the git model places `gh pr create` (D-138); implement opens no PR.
- 2026-09-16: claim audit: not owed — internal tier.
- 2026-09-16: all tasks done; status set to review.

## Decisions

## Review

- 2026-09-16 AC1: `cairn/DESIGN.md:216-220` on the branch carries the added sentence (binds randomness through R's generator; kernlab's SVMs and the deep-learning engines outside its reach under any R-side scheme, here or in tune) followed by an italic annotation naming D-064, in the shape of IP1's annotation at lines 206-208. Verified by reading the diff hunk and the two entries side by side. Pass.
- 2026-09-16 AC2: D-064 sits at `cairn/DECISIONS.md:1790-1794`, directly above `<!-- Template:` at 1796; it cites D-011's Consequences paragraph and RR01 B4 by file, and supersedes nothing. `git diff origin/main...HEAD -U0 -- cairn/DECISIONS.md` shows one hunk, `@@ -1789,0 +1790,6 @@`, a pure insertion: no line above the entry changed. Pass.
- 2026-09-16 AC3: `cairn_validate.py` on the branch: all checks passed, exit 0, 18 advisory warnings (references staleness, pre-existing). Pass.
- 2026-09-16 sync: branch level with `origin/main` (no commits behind), so no merge-in was needed.
- 2026-09-16 impact (IP2 changed): `cairn_impact.py IP2` lists 35 references. All live citations read; the amendment is additive, and none contradicts it except `cairn/DESIGN.md:524-525` ("IP2's text is unchanged"), raised by the reviewer as finding 1 below. The promoted candidate row at `cairn/ROADMAP.md:47` is the row this milestone fulfills; pruned at hygiene.
- 2026-09-16 review lens: internal tier, docs-only diff, one [O] diff-bug reviewer spawned (fresh context, Opus). It confirmed AC1-AC3 and the new text's fidelity to D-011, RR01 B4 and the roxygen template, and ranked nine findings, most severe first:
  1. `cairn/DESIGN.md:524-525` Known-issues entry says "IP2's text is unchanged", which this branch falsifies. Proposed: fix now.
  2. `cairn/DECISIONS.md:1790` heading ends ". Supersedes no entry", a form no other heading uses (the template puts supersession in Consequences, only if any). Proposed: fix now, trim the clause from the heading.
  3. `cairn/DESIGN.md:216` the sentence opens "It binds", where the previous sentence's subject is the disclaimed identity; the template says "This binds". Proposed: fix now, "IP2 binds".
  4. `cairn/DECISIONS.md:1793` D-064's Decision omits the "here or in tune" clause the DESIGN sentence carries. Proposed: fix now.
  5. `cairn/DESIGN.md:219` annotation says "M99" not "M099". Proposed: reject; DESIGN.md's only other annotation uses the unpadded "M05", so the branch matches the file's annotation form.
  6. `cairn/DESIGN.md:219-220` "git holds the original" is boilerplate for an addition. Proposed: reject; AC1 asks for IP1's form and the phrase is true.
  7. `cairn/DESIGN.md:220` "on RR01's finding B4" names the id where IP1's form states the finding. Proposed: fix now, state the finding.
  8. `cairn/DECISIONS.md:1792` RR01 cited by path without the `:361-367` range T1 named. Proposed: fix now.
  9. Milestone file: AC boxes unticked and Decisions section empty. Proposed: reject; AC ticks are review's, and D-entries live in DECISIONS.md, the Decisions section holding milestone-local ones.
- 2026-09-16 consistency gate: `cairn_validate.py` green; `devtools::document()` no diff; README.md in sync with README.Rmd; `pkgdown::check_pkgdown()` no problems; all six gating prose sweeps clean; `devtools::check()` 0 errors, 0 warnings, 0 notes (7m 13s). NEWS.md needs no entry (no user-visible change). No new top-level files.
