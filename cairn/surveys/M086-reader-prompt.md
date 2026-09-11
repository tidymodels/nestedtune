# M086 reader prompt

_Owned by M086 (AC5). `/milestone-review` hands the block below, unchanged, to one fresh-context Opus reader at each review pass, and saves the reader's report as `cairn/surveys/M086-reader-review.md` (pass 2 and later overwrite it). The reader is withheld `cairn/milestones/M086-guides-plain-sweep.md` and the output of `Rscript benchmarks/sweep-prose.R --plain`. The report is triaged once at the gate and never rerun after fixes within a pass._

---

You are checking six documentation pages of the R package nestedtune in the CHECK mode of the SimpleEnglish skill. Read the skill's rule catalog first, at `references/rule-catalog.md` under the skill's directory (the plugin install is at `~/.claude/plugins/marketplaces/local-desktop-app-uploads/simple-english/skills/simple-english/`); its Plain-mode rules apply, not the Strict-mode ones marked (S).

Read every prose paragraph of these six files from the repository root, in this order:

1. `vignettes/nested-cv.Rmd`
2. `vignettes/estimate.Rmd`
3. `vignettes/tuners.Rmd`
4. `vignettes/results.Rmd`
5. `vignettes/articles/parallel.Rmd`
6. `README.Rmd`

Prose is the text outside the YAML header, outside fenced code chunks, outside HTML comments, and outside backtick spans; a heading, a list item and a link target are prose only for their words. Do not report code, identifiers, commands, file paths, product names or facts, and do not propose changing any of them.

Report each violation as one numbered entry with three parts: the rule number quoted from `references/rule-catalog.md` (never a number from memory), the offending text quoted exactly as the file has it, and a compliant rewrite. Group the entries by file in the order above, and within a file by line order. Where one paragraph breaks the same rule several times, one entry per sentence. Do not rank, summarize, count words per page, or add a closing paragraph. A page with no entries gets one line: `<path>: no entries`.

Do not read `cairn/milestones/M086-guides-plain-sweep.md`, any file under `cairn/surveys/`, or the output of `benchmarks/sweep-prose.R`; do not edit any file. Write the report to the path you are given.
