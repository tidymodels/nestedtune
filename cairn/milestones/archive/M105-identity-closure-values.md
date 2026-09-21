# M105: The workflow identity reads what a function-valued setting closes over

**Status:** dropped (2026-09-21, descoped by D-067, never merged)

**Goal:** `workflow_identity()` records the values a function-valued setting reads from outside itself. `nested_final_fit()` then refuses a workflow whose function computes something else.

**Outcome:** Nothing merged. The branch built a closure walk over the names `codetools::findGlobals()` reports, and recorded each read binding by value. It failed review three times, always on the criterion that two builds of one code agree and two over different values differ. Seven mechanisms broke it. They were enclosure mutation, object identity across serialization, 15-digit float printing, data-masked names under non-standard evaluation, locale-dependent deparsing, classed list settings, and `options(scipen)`. RB08 escalated the design question and RR08 answered it. Mutation and non-standard evaluation are not properties of the function, so no recorder of live values decides them. Both refuse a user their own workflow. The default branch already compares a function by its text, and its help page says so. Two byproducts shipped on their own. The `scipen` pin (PR #118) reached every identity leaf and predated this milestone. The macOS CI unblock (PR #119) took P3M binaries on that leg.

**Decisions:** D-067 supersedes D-066. A function stays compared by its text, and `codetools` does not join Imports. RR08's declared-values design is the starting point on the candidate row for any future attempt.

**Review:** three passes, each a full three-lens fan-out, returned 15, 12 and 13 findings. Two criteria audits rejected both attempts to narrow AC2, and the second found the `scipen` mechanism. Three defect returns crossed the thrash threshold. The user chose descope, then escalation, then the drop. The branch `m105-identity-closure-values` holds the full history and was never pushed.
