# M144: The help pages for reading results read like tune's

**Status:** done (2026-10-10, PR #160 https://github.com/tidymodels/nestedtune/pull/160; resolves #91 partial)

**Goal:** Rewrite the 24 help pages that M142 and M143 leave to the target M142 sets.

**Outcome:** The 24 pages for reading a nested run went from 9,116 to 4,385 prose words (`benchmarks/doc-profile.R`), with Descriptions of 15 to 37 words. No page names a `nestedtune_*` class, `orchestrator` or `sibling`.
- The collect, compute and augment pages keep each function's requirement, columns and averaging rules, and drop the refusal lists. `man-roxygen/refusals-saved-run.R` is deleted.
- `?collect_metrics.nested_results` defines the nested estimate and says what to report and when (IP3). It gives `std_err` in three sentences and points to `vignette("estimate")`. The two citations went to M145's work log.
- Each print and summary page says the nested estimate describes the procedure, not a fitted model.
- In-prose pointers between sections became See Also links, and `[collect_metrics()]` links on these pages open the nested method's page.
- One `vignettes/results.Rmd` sentence that named a removed warning class is deleted, under a scope amendment.

**Decisions:** none.

**Review:** a claim audit at implement read 170 claims and corrected 2. Review ran three lenses plus the plan's fresh reader beside tune's pages. They raised 54 findings: 42 fixed on the branch, 11 rejected with reasons, 1 sent to M145's work log.
- The fixes restored facts earlier milestones had added on purpose (M044, M072, M103, M116, M123, M125), now in short form.
- The first CI wait reached its time limit. The resumed review found all 14 checks green and merged.

At merge, the user chose no comment on #91. No lesson was added or retired.
