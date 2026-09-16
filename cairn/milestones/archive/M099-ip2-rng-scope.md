# M099: IP2's text names the randomness it reaches

**Status:** done (2026-09-16, PR #112 https://github.com/tidymodels/nestedtune/pull/112)

**Goal:** IP2's own text in `cairn/DESIGN.md` states that it binds only randomness flowing through R's generator, the clause D-011's Consequences and the reproducibility help template already carry.

**Outcome:** The IP2 entry in `cairn/DESIGN.md` gained one sentence: IP2 binds randomness that flows through R's generator, and engines that randomize outside it (kernlab's SVMs, the deep-learning engines) are outside its reach under any R-side scheme, here or in tune. An italic annotation in IP1's form names D-064 and the RR01 finding. The bound and the engine examples match the last paragraph of `man-roxygen/section-reproducibility.R`, which was read and left unchanged. The seeding scheme is untouched. The Known-issues entry on `time_limit` now says IP2's promise clause is unchanged rather than its text.

**Decisions:** D-064 records the amendment; it cites D-011's Consequences and RR01 B4 (`cairn/reviews/archive/RR01-rng-streams-outer-folds.md:361-367`) and supersedes nothing.

**Review:** all three criteria verified. `cairn_validate.py` green, `devtools::check()` 0/0/0, six gating sweeps clean, `document()` no diff, `check_pkgdown()` clean. Internal tier, docs-only diff, so one diff-bug lens ran. It ranked nine findings, none failing a criterion. Six were fixed: the stale "IP2's text is unchanged" clause in Known issues, the heading's "Supersedes no entry" moved to D-064's Consequences, "It binds" became "IP2 binds", D-064's Decision gained the "here or in tune" clause, the annotation states the finding rather than its id, and the RR01 citation carries its line range. Three were rejected: the unpadded "M99" matches the file's only other annotation, "git holds the original" is IP1's form and true, and the empty milestone Decisions section holds milestone-local decisions only. The candidate row from RR01 B4 was pruned from ROADMAP. Nothing was graduated or retired.
