# M142: The grid help page, the main guide and the README read like tune's

**Status:** done (2026-10-10, PR #158 https://github.com/tidymodels/nestedtune/pull/158; resolves #91 partial)

**Goal:** Rewrite `?nested_tune_grid`, `vignettes/nested-cv.Rmd` and the README opening to the length, structure and voice of tune's help pages and the tidymodels.org articles. This pilot sets the target for M143, M144 and M145.

**Outcome:** `?nested_tune_grid` went from 4,960 to 1,542 prose words (`tune_grid` has 1,515), with a 39-word Description. Refusal lists, condition class names, parallel internals, the Stone aside and the time-series test inventory left the page.
- The page keeps short text that decisions require: the verb rules for keeping the class (D-032, D-035), a "Reproducing one fold" section and the RNG restore (D-011, D-016), the `load_all()` and stale-daemon note (D-018), and the IP2 scope sentence (D-064).
- The shortened `man-roxygen/` templates also cut the bayes, race, sim-anneal and fit-resamples pages by about half.
- `nested-cv.Rmd` went from 1,350 to 714 words. It is one worked example narrated with "we", and it drops the refusal chunks and the Reproducibility section.
- The README opening is 76 words, and both support tables are unchanged.
- `benchmarks/doc-profile.R` measures help pages and guides, reusing the `sweep-prose.R` reader. `test-doc-profile.R` pins it on hand-counted fixtures.
- `cairn/references/tune-docs-comparison.md` holds the comparison and the figures. The comparator copies come from tidymodels.org at `ed3cb150` and tune at `d047fc3a`.

**Decisions:** D-115: the grid page states its own time-series claim and points to `?nested_resamples` for the other functions. The plan gate recorded four choices: the tune shape over trimming in place, caps relative to tune and the branch point, a report-only script, and no optimism demonstration.

**Review:** a claim audit at implement read 133 claims and corrected 8. Review ran three lenses plus the plan's fresh reader. They raised 55 items: 38 fixed on the branch, 9 rejected with reasons, 8 split or handed on.
- M143 takes the sibling Descriptions and the `orchestrator` wording.
- M145 takes where a test set fits around nested resampling, and how to choose v.
- One review fix pushed the README over AC5's cap. It was fixed before evidence was recorded.

All 15 CI checks passed, and the PR had no reviews or comments. At merge, the user dropped the planned #91 comment. No lesson was added or retired.
