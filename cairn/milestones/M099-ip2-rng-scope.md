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

- [ ] AC1: The IP2 entry in `cairn/DESIGN.md` (line 211 at `bc905a4`) carries one added sentence stating that IP2 binds randomness flowing through R's generator and that engines randomizing outside it (kernlab's SVMs, the deep-learning engines) are outside its reach under any R-side scheme, followed by an italic amendment annotation naming the D-entry, in the form IP1's annotation takes (`cairn/DESIGN.md:208-210`).
- [ ] AC2: One D-entry, appended above the `<!-- Template:` block in `cairn/DECISIONS.md`, records the amendment, cites D-011's Consequences paragraph and RR01 finding B4 as its sources, and supersedes no entry; `git diff main` on the branch touches no line of `cairn/DECISIONS.md` above the new entry.
- [ ] AC3: `python3 cairn_validate.py` is green on the branch.

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
