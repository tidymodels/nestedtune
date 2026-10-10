# M145: The other four guides read like the tidymodels.org articles

**Status:** done (2026-10-10, PR #161 https://github.com/tidymodels/nestedtune/pull/161; resolves #91 partial)

**Goal:** Rewrite `vignettes/estimate.Rmd`, `vignettes/tuners.Rmd`, `vignettes/results.Rmd` and `vignettes/articles/parallel.Rmd` to the guide target M142 sets.

**Outcome:** The four pages went from 4,647 to 2,119 prose words (`benchmarks/doc-profile.R`): estimate 1,392 to 973, tuners 1,350 to 589, results 1,395 to 358, parallel 510 to 199. Paragraph means are 25.6 to 36.0, and no page has a coined term, a "You" opener or an `error = TRUE` chunk.
- `estimate.Rmd` keeps the IP3 sentence (what the estimate describes, what to report, and why) and eight cited sources with a reference list. It adds where a held-out test set fits (`initial_split()`, `training()`, `testing()`) and the fold-count advice (Arlot and Celisse 2010). It cites Bengio and Grandvalet (2004) on the standard error. Gauran, Ombao and Yu (2025) stay out, because their result holds for ridge and LASSO designs only.
- `tuners.Rmd` has one short section per search, a fixed baseline and a workflow set. `results.Rmd` reads one run from the estimate to a predicted-against-observed plot. The column tour, the failed-fold run and the dplyr rules left it for `?nested_tune_grid`.
- The parallel article is a short how-to that points to the parallel section of `?nested_tune_grid`.
- `cairn/references/tune-docs-comparison.md` holds the branch-point and head figures.

**Decisions:** none.

**Review:** a claim audit at implement read 96 claims and corrected 6. A probe there showed `nested_tune_sim_anneal()` finalizes `mtry` itself while `nested_tune_bayes()` fails every fold without a range. Review ran three lenses plus the plan's fresh reader beside the tidymodels.org articles.
- The lenses raised 35 findings: 24 fixed, 8 rejected with reasons, 3 sent to candidate rows. The reader's entries came to 24 fixed and 30 rejected.
- The fixes restored Wilimitis and Walsh's sizes, which `?nested_final_fit` cites, and the Tibshirani learner caveat. They restored the number to report on the results page, and the package's no-test, no-interval and no-ranking clauses. They also restored the parallel pointer and the `collect_notes()` mention.
- Two `?nested_tune_grid` gaps (the Bayes `mtry` claim, and overwriting a column) extend its argument-text candidate row. The stale README line on the results guide is a new row. The DESIGN Known issues entry on reporting without nesting was re-read and kept.
- The first CI wait reached its time limit. The resumed review found all 15 checks green, an empty PR conversation, and merged.

At merge, the user chose no comment on #91. No lesson was added or retired.
