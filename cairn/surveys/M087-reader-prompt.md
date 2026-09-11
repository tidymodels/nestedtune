# M087 reader prompt

_Owned by M087 (AC3). `/milestone-review` hands the block below, unchanged, to one fresh-context Opus reader at each review pass, and saves the reader's report as `cairn/surveys/M087-reader-review.md` (pass 2 and later overwrite it). The reader is withheld `cairn/milestones/M087-help-pages-plain-sweep.md` and the output of `Rscript benchmarks/sweep-prose.R --roxygen --plain`. The report is triaged once at the gate and never rerun after fixes within a pass._

---

You are checking the rendered help pages of the R package nestedtune in the CHECK mode of the SimpleEnglish skill. Read the skill's rule catalog first, at `references/rule-catalog.md` under the skill's directory (the plugin install is at `~/.claude/plugins/marketplaces/local-desktop-app-uploads/simple-english/skills/simple-english/`); its Plain-mode rules apply, not the Strict-mode ones marked (S).

Render every help page to plain text from the repository root with this command, then read every file it writes, in alphabetical order of the page name:

```bash
mkdir -p /tmp/nestedtune-rd && for f in man/*.Rd; do Rscript -e "tools::Rd2txt('$f', out = '/tmp/nestedtune-rd/$(basename "$f" .Rd).txt', options = list(underline_titles = FALSE))"; done
```

Prose is the text of the Description, Arguments, Value, Details and any named section of a rendered page. Do not read the Usage block, the Examples block, or the See Also list. A heading, a list item and an argument name are prose only for their words. Inline code in a rendered page appears in single quotes or as a bare identifier; do not report code, identifiers, argument names, class names, function names, file paths, product names or facts, and do not propose changing any of them.

Report each violation as one numbered entry with three parts: the rule number quoted from `references/rule-catalog.md` (never a number from memory), the offending text quoted exactly as the rendered page has it, and a compliant rewrite. Group the entries by page in alphabetical order, and within a page by line order. Where one paragraph breaks the same rule several times, one entry per sentence. Do not rank, summarize, count words per page, or add a closing paragraph. A page with no entries gets one line: `<page>: no entries`.

Do not read `cairn/milestones/M087-help-pages-plain-sweep.md`, any file under `cairn/surveys/`, any file under `R/` or `man-roxygen/`, or the output of `benchmarks/sweep-prose.R`; do not edit any file. Write the report to the path you are given.
