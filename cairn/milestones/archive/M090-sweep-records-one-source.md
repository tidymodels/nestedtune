# M090: The sweep's page list and gating modes each have one source

**Status:** done (2026-09-12, PR #103 https://github.com/tidymodels/nestedtune/pull/103)

**Goal:** `benchmarks/sweep-prose.R` holds the only copy of its page list and of its gating invocations, and every other reader takes the list from the script.

**Outcome:** The script gained a `gating` vector and two listing modes. `--list-pages` prints the effective page list, which `--pages` replaces, one path per line. `--list-gating` prints the six gating commands as full command lines. Both exit 0. The real-pages block of `tests/testthat/test-sweep-prose.R` reads both lists through those modes and names no page path. It states their shape on its own: six unique pages that exist, and six unique invocations, one bare and three reading roxygen. The `consistency-gate` slot of `cairn/PROFILE.md` tells the reader to run each command `--list-gating` prints. `.github/workflows/prose-sweep.yaml` keeps its six named steps as the one copy, checked by hand, and its comment says so. `diff` of `--list-gating` against the yaml's `run:` lines was empty. The six gating sweeps print `clean`, `devtools::test()` passed 9862, and `devtools::check()` reported 0/0/0.

**Decisions:** none. The question gate chose full command lines for `--list-gating` and the effective page list for `--list-pages`.

**Review:** three-lens fan-out, 13 findings, none returning status. Fixed at the gate: a duplicated gating line or page passed the shape checks, so the test now asserts no duplicates. Each planted duplicate turned it red. Also fixed: the profile slot said the yaml reads the list from the script, and the header said `--list-pages` prints what a `--roxygen` run sweeps. Rejected as minor or deliberate: listing-flag precedence, `--pages` parsed before a listing, no path-exists check, space-split flags, and "six" in a test name. Follow-up: the existing candidate row on the workflow steps drifting from the script. The prior-review lens found the diff closes M088's review point on the copied lists. No lesson was added or retired. CI green on fourteen checks.
