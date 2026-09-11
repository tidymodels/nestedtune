# M085 survey: roxygen paragraphs failing the plain-prose standard (2026-09-10)

_Owned by M085; the AC3 probe set. Line numbers are each block's first `#'` line at `0d8611e`; letters as in `M084-survey.md`. Files with no failing paragraph: `nestedtune-package.R` (5), `man-roxygen/*` (3 prose paragraphs), `reexports.R`, `checks.R`, `parallel.R`, `tuner.R` (no prose)._

## `R/nested-tune-grid.R` — 26 of 53
:4 b d e · :11 d · :46 c d · :50 e · :61 e · :68 e · :76 e · :85 d e · :107 e · :115 e · :122 e · :134 e · :156 d e · :169 d · :185 e · :202 e · :224 e · :235 e · :281 e · :302 e · :328 e · :345 c · :358 e · :374 e · :384 e · :397 d

## `R/nested-final-fit.R` — 9 of 26
:18 c d · :41 e · :65 d e · :93 e · :100 e · :118 e · :142 e · :150 c · :203 e

## `R/nested-results-set.R` — 12 of 38
:12 d · :29 e · :36 c · :227 d e · :231 d e · :238 e · :243 d e · :252 c e · :266 e · :277 e · :288 e · :309 d

## `R/nested-workflow-map.R` — 10 of 14
:12 d · :29 c · :35 e · :59 e · :66 e · :76 c · :84 e · :98 e · :113 e · :127 e

## `R/nested-fit-resamples.R` — 8 of 20
:4 e · :37 c · :49 d e · :56 e · :73 d e · :84 e · :111 e · :123 c

## `R/nested-tune-sim-anneal.R` — 7 of 19
:4 e · :32 d e · :43 e · :50 e · :75 e · :100 e · :124 e

## `R/nested-tune-race.R` — 6 of 17
:4 e · :35 d · :43 e · :54 e · :70 e · :90 c e

## `R/nested-tune-bayes.R` — 5 of 19
:4 e · :32 d · :59 c e · :73 e · :82 e

## Three or fewer
- `R/extract-procedure.R` (3 of 8): :13 d · :25 d · :40 e
- `R/nested-final-fit-extract.R` (3 of 10): :26 d · :90 d e · :96 e
- `R/nested-final-fit-print.R` (3 of 16): :27 e · :106 e · :119 c d
- `R/nested-resamples.R` (3 of 12): :4 d · :29 e · :46 e
- `R/nested-results-collect.R` (3 of 20): :16 d · :29 c · :174 e
- `R/nested-results.R` (2 of 13): :722 c e · :747 e
- `R/nested-results-plot.R` (2 of 11): :43 e · :52 c e
- `R/nested-results-print.R` (2 of 15): :22 d · :40 c
- `R/nested-final-fit-predict.R` (1 of 11): :46 c
- `R/nested-results-agreement.R` (1 of 7): :30 e
- `R/selection-rule.R` (1 of 9): :50 e

Total: 107 of 343. `orchestrator` first appears cold at `nested-resamples.R:4`, `nested-tune-grid.R:156`, `nested-tune-bayes.R:32`, `nested-tune-race.R:35`, `nested-tune-sim-anneal.R:32`, `nested-fit-resamples.R:49`, `nested-workflow-map.R:12`, `nested-results-set.R:227`, `extract-procedure.R:25`.
