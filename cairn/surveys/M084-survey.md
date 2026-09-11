# M084 survey: paragraphs failing the plain-prose standard (2026-09-10)

_A plan-time survey, owned by M084 and read by its AC3; `cairn/surveys/` holds such per-milestone survey lists and nothing else. Each entry is one paragraph, identified by its current first line and quoted opening words, refreshed in place after each rewrite (last refreshed 2026-09-11 after the T9 third rewrite; the original entries at `0d8611e` are in git). Letters are the clauses the paragraph failed at survey time: (a) reader first, (b) problem before term, (c) one idea per sentence, (d) package word unset, (e) sentence over 30 words._

## §1 `vignettes/estimate.Rmd` — 8 of 18
- :24 "When you tune with cross-validation, you try several settings" — c d e
- :49 "Take the four steps, resample, tune, select, fit, as one procedure" — a b e
- :54 "Four things it is not." — c e
- :66 "The number tends to look a little worse" — e
- :73 "Varma and Simon (2006) ran nested cross-validation on null data" — c e
- :95 "Suppose you run the loop on two workflows" — b e
- :106 "The same holds for a set of workflows run through one design" — d
- :125 "Whether nesting pays depends on how much room" — c e

## §2 `vignettes/results.Rmd` — 9 of 28
- :17 "Every tuning function in this package returns the same kind of object" — d e
- :60 "The design, the workflow and the grid are the guide's, unchanged" — d
- :171 "`.predictions` is there because the control above set" — c e
- :184 "You will sometimes want to know exactly what ran" — b d
- :210 "`collect_selections()` stacks `.selected` over the folds that completed" — e
- :222 "`collect_predictions()` stacks `.predictions` the same way" — d e
- :300 "A fold can also complete and still carry notes" — c e
- :321 "The object is a tibble, so dplyr's verbs work on it" — e
- :357 "If your outcome has two classes, or your model is scored at censoring times" — c e

## §3 `vignettes/tuners.Rmd` — 9 of 22
- :17 "The getting-started guide, `vignette(\"nested-cv\")`, tunes each outer fold" — c e
- :94 "The grid tuner and the racers score the candidates they are given" — e
- :156 "The `.iter` column says which stage each candidate came from" — c e
- :203 "A race's `.inner_metrics` looks complete but is not" — e
- :304 "A tuned procedure, the whole resample-tune-select-fit sequence" — d
- :342 "Read the table fold by fold rather than as one difference" — b d
- :357 "A comparison across model families needs every family scored" — d e
- :390 "The baseline has nothing to tune" — b
- :425 "The parameters view keeps the outer folds on the x axis" — c

## §4 `vignettes/nested-cv.Rmd` (from line 35) — 3 of 25
- :133 "`nested_tune_grid()` drives the outer loop." — e
- :278 "The selection-time score is not an estimate of performance on anything" — c e
- :296 "Seed the session before the call, as elsewhere in tidymodels" — c e

## §5 `vignettes/articles/parallel.Rmd` — 1 of 9, and `README.Rmd`
- :17 "A nested run fits many models, and you may want it to finish sooner" — c e
- `README.Rmd:24` "You tune a model with cross-validation and keep the setting with the best score" — c e (was a four-verb 35-word sentence)

Package words used cold across pages at survey time: `procedure` (estimate, results, nested-cv), `record` (results, tuners), `orchestrator` (tuners, estimate), `reader` (results, throughout).
