# M084 survey: paragraphs failing the plain-prose standard (2026-09-10)

_A plan-time survey, owned by M084 and read by its AC3; `cairn/surveys/` holds such per-milestone survey lists and nothing else. Line numbers are each paragraph's first line at `0d8611e`. Letters are the standard's clauses (a) reader first, (b) problem before term, (c) one idea per sentence, (d) package word unset, (e) sentence over 30 words._

## §1 `vignettes/estimate.Rmd` — 8 of 18
- :24 "Tuning by cross-validation scores every candidate" — c d e
- :47 "The estimate is of the k-fold test error" — a b e
- :52 "Two quantities it is not." — c e
- :62 "The number tends to look a little worse" — e
- :68 "Varma and Simon (2006) found a nested estimate of 54.2%" — c e
- :91 "If the loop is run on two workflows" — b e
- :100 "The same covers a set of workflows run through one design" — d
- :119 "What decides whether nesting pays" — c e

## §2 `vignettes/results.Rmd` — 9 of 28
- :17 "Every tuning function in this package returns the same kind of object" — d e
- :59 "The design, the workflow and the grid are the guide's, unchanged" — d
- :167 "`.predictions` is there because the control asked for it" — c e
- :179 "The description of the run itself rides on the object as attributes" — b d
- :201 "`collect_selections()` and `collect_inner_metrics()` stack" — e
- :213 "`collect_predictions()` stacks `.predictions` the same way" — d e
- :291 "A fold can also complete and carry notes" — c e
- :303 "The object is a tibble, so dplyr's verbs work on it" — e
- :340 "Two arguments the runs on this page did not use" — c e

## §3 `vignettes/tuners.Rmd` — 9 of 22
- :17 "The getting-started guide tunes each outer fold" — c e
- :94 "The grid tuner and the racers score the candidates they are given." — e
- :152 "The `.iter` column says which stage each candidate came from" — c e
- :199 "A fold's `.inner_metrics` from a race is the whole grid" — e
- :299 "A tuned procedure is usually compared with something simpler" — d
- :336 "Read the table fold by fold rather than as one difference" — b d
- :349 "A comparison across model families needs every family scored" — d e
- :380 "The baseline has nothing to tune" — b
- :413 "The parameters view keeps the outer folds on the x axis" — c

## §4 `vignettes/nested-cv.Rmd` (from line 35) — 3 of 25
- :129 "`nested_tune_grid()` drives the outer loop." — e
- :271 "The selection-time score is not an estimate of performance on anything" — c e
- :289 "Seed the session before the call, as elsewhere in tidymodels" — c e

## §5 `vignettes/articles/parallel.Rmd` — 1 of 9, and `README.Rmd`
- :17 "Nested cross-validation fits many models" — c e
- `README.Rmd:23` "nestedtune runs nested cross-validation for tidymodels workflows." — c e (a four-verb 35-word sentence)

Package words used cold across pages: `procedure` (estimate:34, results:179, nested-cv:232), `record` (results:326, tuners:305), `orchestrator` (tuners:351, estimate:148), `reader` (results, throughout).
