# CI usage — tidymodels/nestedtune

Window `[2026-08-11T00:00:00Z, 2026-09-10T00:00:00Z)`, runs with status `completed`. Default branch `main`.

Path filter read from R-CMD-check-hard.yaml, R-CMD-check.yaml, devel-vctrs.yaml, pkgdown.yaml, test-coverage.yaml: `cairn/**`, `CLAUDE.md`, `.claude/**`

| category | runs | machine-min | reclaimable |
|---|---|---|---|
| total | 2067 | 31133 | — |
| on skipped commits | 192 | 1427 | 1427 |
| superseded (all) | 688 | 10665 | 2339 |
| superseded off `main` | 562 | 9477 | 1448 |
| **removed by the filter + off-branch cancel** | **754** | — | **2875** |

Jobs in window: 3893.

`machine-min` is what those runs cost; `reclaimable` is what removing them saves, and only the second is a saving. A skipped commit fires no run at all, so the two are equal for it. Cancelling a superseded run reclaims only the tail still to come when its successor was created — which is why the superseded rows differ. The two waste categories overlap (a tracking commit on the default branch can be both) and are never summed; the last row is their union, counted once.

## Default-branch commits (119 of 177 skipped)

Enumerated from `git log`, not from the runs they fired — a commit the filter skips fires no run, and a run-derived list would lose it.

| commit | verdict | files | runs | first packaged paths |
|---|---|---|---|---|
| `04985f724` Merge branch 'main' into 2026-08-gha-upd | run | 10 | 0 | `.github/ci-usage-baseline.md`, `DESCRIPTION`, `NAMESPACE` |
| `07711b746` The inner tuning call finalizes an unkno | run | 17 | 4 | `NEWS.md`, `R/nested-final-fit.R`, `R/nested-resamples.R` |
| `082b2be69` print() shows the object, summary() says | run | 14 | 4 | `NAMESPACE`, `NEWS.md`, `R/nested-results-print.R` |
| `10d90535a` M61: vignette running the four alternati | run | 5 | 4 | `NEWS.md`, `_pkgdown.yml`, `vignettes/tuners.Rmd` |
| `142aac30e` M30: Every address the package shows nam | run | 10 | 3 | `.github/ci-usage-baseline.md`, `DESCRIPTION`, `NAMESPACE` |
| `149037b9c` M076: bring the R-devel check leg back t | run | 6 | 4 | `.github/workflows/R-CMD-check.yaml`, `benchmarks/profile-tests-parallel.R`, `benchmarks/test-timing-parallel.md` |
| `1d432c1ae` more openmp madness | run | 1 | 0 | `.github/workflows/R-CMD-check.yaml` |
| `20392e5d3` M67: extract_procedure() accessor on bot | run | 40 | 4 | `NAMESPACE`, `NEWS.md`, `R/extract-procedure.R` |
| `210da65ad` M35: the factor level a caller can name  | run | 24 | 4 | `.Rbuildignore`, `NEWS.md`, `R/checks.R` |
| `236ee6505` M56: the results class, the extract defa | run | 16 | 4 | `NEWS.md`, `R/nested-final-fit-extract.R`, `R/nested-final-fit.R` |
| `2530aa0b6` Merge pull request #30 from tidymodels/2 | run | 13 | 4 | `.Rbuildignore`, `.github/workflows/R-CMD-check-hard.yaml`, `.github/workflows/R-CMD-check.yaml` |
| `28c3b1474` Add package hex logo via usethis::use_lo | run | 6 | 4 | `.Rbuildignore`, `README.Rmd`, `README.md` |
| `2aac24a3d` M60: the guide splits into a getting-sta | run | 10 | 4 | `.Rbuildignore`, `NEWS.md`, `README.Rmd` |
| `2c9162b83` M42: the fixture key's separation test,  | run | 4 | 4 | `tests/testthat/helper-orchestration.R`, `tests/testthat/test-fixture-cache.R` |
| `353814665` M28: an inventory of what nestedtune kee | run | 5 | 3 | `benchmarks/upstream-asks.md` |
| `35421b8f3` M64: site-only article on tuned-CV optim | run | 10 | 4 | `NEWS.md`, `_pkgdown.yml`, `vignettes/articles/why-nest-sim.R` |
| `422f939b3` M72: summary(), autoplot() and agreement | run | 27 | 4 | `.github/workflows/R-CMD-check.yaml`, `NAMESPACE`, `NEWS.md` |
| `494037cf6` M32: the tidymodels organization's commu | run | 9 | 3 | `.github/CODE_OF_CONDUCT.md`, `.github/CONTRIBUTING.md`, `DESCRIPTION` |
| `4d960a3b5` M69: a select argument on the five orche | run | 52 | 4 | `NAMESPACE`, `NEWS.md`, `R/checks.R` |
| `507240a64` M75: prune the test suite to one check p | run | 18 | 4 | `tests/testthat/helper-drift-manifest.R`, `tests/testthat/helper-orchestration.R`, `tests/testthat/helper-time-budget.R` |
| `53910f167` M62: results vignette (#72) | run | 5 | 4 | `NEWS.md`, `_pkgdown.yml`, `vignettes/results.Rmd` |
| `595ee75ff` M68: save_pred and extract reach the out | run | 34 | 4 | `NAMESPACE`, `NEWS.md`, `R/nested-results-collect.R` |
| `5a8f782a6` M36: dplyr invariants on nested_results  | run | 16 | 4 | `.gitignore`, `DESCRIPTION`, `NAMESPACE` |
| `5d7eb2700` M41: eval_time reaches the metrics that  | run | 26 | 4 | `DESCRIPTION`, `NEWS.md`, `R/checks.R` |
| `601cff7ea` M33: the organization's shared CI workfl | run | 74 | 3 | `.Rbuildignore`, `.github/workflows/format-suggest.yaml`, `.github/workflows/lock.yaml` |
| `6526c7bf8` attach the workflow's packages in every  | run | 5 | 4 | `NEWS.md`, `R/parallel.R`, `tests/testthat/helper-time-budget.R` |
| `66bdae296` M43: print and summary follow-ups (#52) | run | 8 | 4 | `NEWS.md`, `R/nested-results-print.R`, `man/print.nested_results.Rd` |
| `72c3be2c8` update gha, readme, and pkgdown | run | 13 | 0 | `.Rbuildignore`, `.github/workflows/R-CMD-check-hard.yaml`, `.github/workflows/format-suggest.yaml` |
| `74f814d2c` M44: agreement() tabulates what the oute | run | 10 | 4 | `NAMESPACE`, `NEWS.md`, `R/nested-results-agreement.R` |
| `75ad92f6f` M66: the six vignette pages read results | run | 12 | 4 | `DESCRIPTION`, `NEWS.md`, `benchmarks/sweep-vignette-idioms.R` |
| `79e8858c4` M31: Both red CI jobs go green, so a mer | run | 7 | 3 | `.github/workflows/R-CMD-check.yaml`, `.github/workflows/pkgdown.yaml`, `.github/workflows/stress-daemon-tests.yaml` |
| `7bdabaacf` M55: every driver refuses a design whose | run | 15 | 4 | `NEWS.md`, `R/checks.R`, `R/nested-tune-grid.R` |
| `7ce4de965` M34: the arguments a caller can hand thr | run | 33 | 3 | `DESCRIPTION`, `NEWS.md`, `R/checks.R` |
| `7e7055426` M40: a nested_final_fit answers summary( | run | 10 | 4 | `NAMESPACE`, `NEWS.md`, `R/nested-final-fit-print.R` |
| `7f5752add` M73: a nested_results_set keeps its clas | run | 13 | 4 | `NAMESPACE`, `NEWS.md`, `R/nested-results-set.R` |
| `8231a2d64` nested_final_fit() refuses a results obj | run | 18 | 4 | `NEWS.md`, `R/checks.R`, `R/nested-final-fit.R` |
| `8addd37e2` M70: nested_fit_resamples() scores a fix | run | 50 | 4 | `NAMESPACE`, `NEWS.md`, `R/checks.R` |
| `9601cc562` Update hex logo and add pkgdown favicons | run | 12 | 4 | `logo/nestedtune-favicon.png`, `logo/nestedtune-favicon.svg`, `logo/nestedtune-hex.png` |
| `984e12d17` M63: site-only article runs the outer lo | run | 5 | 4 | `NEWS.md`, `_pkgdown.yml`, `vignettes/articles/parallel.Rmd` |
| `a253d99e3` M48: `...` reaches the inner tuning call | run | 32 | 4 | `.github/workflows/R-CMD-check.yaml`, `NEWS.md`, `R/checks.R` |
| `aa3e2b799` M45: the inner loop takes its tuner as a | run | 38 | 4 | `NAMESPACE`, `NEWS.md`, `R/checks.R` |
| `b1a0f9df7` M52: the test suite runs its files in pa | run | 10 | 4 | `.github/workflows/R-CMD-check.yaml`, `.github/workflows/test-coverage.yaml`, `DESCRIPTION` |
| `bb09fd6ef` M71: nested_workflow_map() runs a workfl | run | 35 | 4 | `DESCRIPTION`, `NAMESPACE`, `NEWS.md` |
| `bba4d5c08` M46: nested_final_fit() re-runs the proc | run | 43 | 4 | `NEWS.md`, `R/checks.R`, `R/nested-final-fit-extract.R` |
| `bbe66e8ca` A results object's own fold-label column | run | 10 | 4 | `NEWS.md`, `R/nested-results.R`, `R/nested-tune-grid.R` |
| `bbf51da02` M47: predict() and augment() on a nested | run | 17 | 4 | `NAMESPACE`, `NEWS.md`, `R/nested-final-fit-predict.R` |
| `bcc62e68a` M51: nested_tune_sim_anneal() runs finet | run | 26 | 4 | `NAMESPACE`, `NEWS.md`, `R/checks.R` |
| `c136674d8` M49: each outer fold keeps its inner sea | run | 33 | 4 | `NEWS.md`, `R/nested-final-fit-extract.R`, `R/nested-results-print.R` |
| `c859003d0` ci: update stale GitHub Actions pins | run | 7 | 4 | `.github/workflows/R-CMD-check-hard.yaml`, `.github/workflows/R-CMD-check.yaml`, `.github/workflows/lock.yaml` |
| `d2a815ed2` M50: nested_tune_race_anova() and nested | run | 33 | 4 | `DESCRIPTION`, `NAMESPACE`, `NEWS.md` |
| `e248d5ac7` Merge branch 'main' into 2026-08-gha-upd | run | 85 | 0 | `.github/CODE_OF_CONDUCT.md`, `.github/CONTRIBUTING.md`, `.github/workflows/R-CMD-check.yaml` |
| `e50a31e20` M74: the check suite and the help-page e | run | 63 | 4 | `.github/workflows/R-CMD-check.yaml`, `NEWS.md`, `R/extract-procedure.R` |
| `e64117470` M59: every driver refuses inner splits t | run | 20 | 4 | `NEWS.md`, `R/checks.R`, `R/nested-tune-grid.R` |
| `eb2c1ac8a` The vctrs half, so rbind() stops claimin | run | 14 | 4 | `DESCRIPTION`, `NAMESPACE`, `NEWS.md` |
| `ef23c86ea` M58: the startup check asks every daemon | run | 13 | 4 | `NEWS.md`, `R/checks.R`, `R/nested-tune-grid.R` |
| `f91d1ab37` M65: collect_notes(), collect_selections | run | 14 | 4 | `NAMESPACE`, `NEWS.md`, `R/nested-results-collect.R` |
| `f96ca6f66` add tidytemplate | run | 1 | 0 | `DESCRIPTION` |
| `fbe77949b` M57: the hang trace, the parallel-files  | run | 13 | 4 | `.github/workflows/R-CMD-check-hard.yaml`, `tests/testthat/helper-hang-trace.R`, `tests/testthat/helper-orchestration.R` |
| `00605155f` review M065: done | skipped | 4 | 2 | — |
| `06fc2b1f5` review M31: done | skipped | 4 | 0 | — |
| `07e651106` plan M70: `nested_fit_resamples()` score | skipped | 3 | 2 | — |
| `089ff9409` triage: 41 items, 2 merges, 1 route, 19  | skipped | 2 | 2 | — |
| `09d76a746` plan M69: a `select` argument on the fiv | skipped | 2 | 2 | — |
| `11ce38299` plan M39, M40: print() shows the object, | skipped | 4 | 2 | — |
| `136785a9d` plan M71: `nested_workflow_map()` runs a | skipped | 3 | 2 | — |
| `15c07d9d8` M49: in-progress | skipped | 2 | 2 | — |
| `168ceaf03` M60: status in-progress | skipped | 2 | 2 | — |
| `187645ab2` tracking: D-026, the organization transf | skipped | 3 | 0 | — |
| `19f14a34c` plan M67: extract_procedure() reaches th | skipped | 2 | 2 | — |
| `1a77fcdc6` review M51: done | skipped | 4 | 2 | — |
| `213972216` review M36: done | skipped | 4 | 2 | — |
| `2443d74fe` plan M41: `eval_time` reaches the metric | skipped | 2 | 2 | — |
| `2993ba546` review M75: done | skipped | 3 | 2 | — |
| `2a1498f35` review M47: done | skipped | 4 | 2 | — |
| `2c847566f` hygiene: retire and compress LESSONS und | skipped | 2 | 2 | — |
| `2d21a5e2f` M53 review: approval on resume, PR #63 a | skipped | 1 | 0 | — |
| `2d61b3ab4` triage: drop the p > n vignette re-cut r | skipped | 1 | 2 | — |
| `2f6c0e605` plan M74, M75: the check suite runs fast | skipped | 3 | 2 | — |
| `3198a34d3` status: hygiene stamp for the 2026-09-06 | skipped | 1 | 2 | — |
| `32ef81ad1` review M56: done | skipped | 5 | 2 | — |
| `33ac0c774` review M41: archive summary back to the  | skipped | 2 | 2 | — |
| `354f39701` plan M31: both red CI jobs go green, so  | skipped | 2 | 0 | — |
| `3913cb4c2` review M50: done | skipped | 4 | 2 | — |
| `3d402c9ab` review M076: done | skipped | 4 | 2 | — |
| `404e0837c` plan M47: `predict()` and `augment()` on | skipped | 2 | 2 | — |
| `412442bc7` M54 review: second CI wait stopped at th | skipped | 1 | 0 | — |
| `4374ec887` plan M48, M49: `...` reaches the inner t | skipped | 4 | 2 | — |
| `43f23cc7d` review M066: done | skipped | 4 | 2 | — |
| `44ec8acdc` roadmap: the mori row keeps the phrase t | skipped | 1 | 2 | — |
| `4833f55fe` review M61: done | skipped | 4 | 2 | — |
| `486240852` review M62: done | skipped | 4 | 2 | — |
| `500fd7561` plan M36: removing an outer fold's row s | skipped | 2 | 2 | — |
| `50b641355` M51 review: CI watch stopped at the ceil | skipped | 1 | 0 | — |
| `50d134c79` plan M58: the startup check asks every d | skipped | 2 | 2 | — |
| `50e7fa137` plan M50, M51: finetune's racing tuners  | skipped | 3 | 2 | — |
| `514627896` review M53: done | skipped | 5 | 2 | — |
| `544feb66e` review M71: done | skipped | 4 | 2 | — |
| `570a76ef4` tracking: hygiene stamp 2026-08-28 | skipped | 1 | 0 | — |
| `5a6e9a034` review M38: done | skipped | 4 | 2 | — |
| `5d0727f41` M59: status in-progress | skipped | 2 | 2 | — |
| `5eba21153` plan M59: every driver refuses a design  | skipped | 2 | 2 | — |
| `5fc677cce` review M40: done | skipped | 3 | 2 | — |
| `60866ab04` plan M32, M33: the tidymodels organizati | skipped | 3 | 0 | — |
| `6185c4e50` review M48: CI watch stopped at the ceil | skipped | 1 | 0 | — |
| `622758213` review M43: done | skipped | 4 | 2 | — |
| `67c9aae90` plan M53: `nested_final_fit()` refuses a | skipped | 2 | 2 | — |
| `6826442ba` review M59: done | skipped | 4 | 2 | — |
| `69db83016` review M063: done | skipped | 4 | 2 | — |
| `6a1e6a128` review M35: done | skipped | 4 | 2 | — |
| `6ab4def57` M58: status in-progress | skipped | 2 | 2 | — |
| `6cfccb1cc` review M73: done | skipped | 4 | 2 | — |
| `6f189ffb6` roadmap: restore the two wire figures th | skipped | 1 | 2 | — |
| `6fc12e0f8` review M67: done | skipped | 4 | 2 | — |
| `6ff8983d9` plan M43: the print and summary follow-u | skipped | 2 | 2 | — |
| `70cf5f91d` plan M72: `summary()`, `autoplot()` and  | skipped | 2 | 2 | — |
| `7278ea8a7` review M44: done | skipped | 4 | 2 | — |
| `737a77d5d` plan M74: re-cut row — the check suite a | skipped | 1 | 2 | — |
| `793ed4346` review M37: done | skipped | 4 | 2 | — |
| `7d8a3bdbc` hygiene: status audit after M57 | skipped | 1 | 0 | — |
| `8028dbba4` review M67: LESSONS under its byte budge | skipped | 1 | 2 | — |
| `80dbc5304` review M60: done | skipped | 4 | 2 | — |
| `830b3685a` plan M28: What we keep, what is only glu | skipped | 6 | 0 | — |
| `83362cd7f` review M72: LESSONS under its byte budge | skipped | 1 | 2 | — |
| `8577f2b0a` review M74: carry the review-side record | skipped | 2 | 0 | — |
| `89d8418ca` review M30: done | skipped | 4 | 0 | — |
| `8ded001a6` review M57: done | skipped | 4 | 2 | — |
| `8ea5e7521` plan M60, M61, M62, M63, M64: the vignet | skipped | 7 | 2 | — |
| `92ba8a33d` review M72: done | skipped | 4 | 2 | — |
| `933b13baf` review M71: LESSONS under its byte budge | skipped | 1 | 2 | — |
| `9382ce009` review M34: done | skipped | 4 | 0 | — |
| `9b0c177e8` review M32: done | skipped | 4 | 0 | — |
| `9b91e18e7` plan M076: the two slow check legs run t | skipped | 2 | 2 | — |
| `9d221725e` review M54: done | skipped | 4 | 2 | — |
| `9d84882a9` review M45: done | skipped | 4 | 2 | — |
| `a0fb8ebb1` status: hygiene stamp 2026-09-03, audit  | skipped | 1 | 2 | — |
| `a143c1989` review M46: done | skipped | 4 | 2 | — |
| `a31c8b166` review M42: done | skipped | 4 | 2 | — |
| `a370b1e48` review M49: done | skipped | 5 | 2 | — |
| `a5397a630` plan M56, M57: the results class, the ex | skipped | 3 | 2 | — |
| `accfbe22f` review M74: done | skipped | 4 | 2 | — |
| `ad7bd83e3` review M064: done | skipped | 4 | 2 | — |
| `b0d76a43f` plan M52: The test suite runs its files  | skipped | 2 | 2 | — |
| `b26eb77d5` tracking: D-030 was inside the template  | skipped | 1 | 2 | — |
| `b29d8a74f` plan M73: a nested_results_set keeps its | skipped | 3 | 2 | — |
| `b3c1d1b72` plan M37: the vctrs half, so rbind() sto | skipped | 2 | 2 | — |
| `bd3e105da` plan M55: every driver refuses a design  | skipped | 3 | 2 | — |
| `bfa580928` review M065: LESSONS trimmed under its b | skipped | 1 | 2 | — |
| `c0450a44d` review M58: done | skipped | 4 | 2 | — |
| `c31b50bc1` M54 review: resume, PR #64 re-approved a | skipped | 1 | 0 | — |
| `c5c94806c` plan M30: Every address the package show | skipped | 2 | 0 | — |
| `c9a7bfee9` lesson: tune attaches required_pkgs only | skipped | 1 | 2 | — |
| `cb4c21d82` M54 review: third resume, PR #64 re-appr | skipped | 1 | 0 | — |
| `cc516ea49` review M48: done | skipped | 5 | 2 | — |
| `ccf581dba` M53 review: third CI ceiling stop logged | skipped | 1 | 0 | — |
| `cf89a1da9` plan M42: the fixture key's separation t | skipped | 2 | 2 | — |
| `d280f82d8` review M69: done | skipped | 3 | 2 | — |
| `d2ba92fbe` review M28: done | skipped | 4 | 0 | — |
| `d64e4e17f` review M42: hygiene stamp carries the me | skipped | 1 | 2 | — |
| `d6ff85f70` review M39: done | skipped | 3 | 2 | — |
| `d997a3017` review M55: done | skipped | 4 | 2 | — |
| `da62474a7` review M41: done | skipped | 4 | 2 | — |
| `ddf61f037` plan M34: the arguments a caller can han | skipped | 2 | 0 | — |
| `de5937f7d` plan M68: save_pred and extract reach th | skipped | 2 | 2 | — |
| `e068c0cb0` review M52: done | skipped | 4 | 2 | — |
| `e10a8e597` plan M35: the factor level a caller can  | skipped | 2 | 0 | — |
| `e6284341a` review M070: done | skipped | 3 | 2 | — |
| `e92c08d98` review M33: done | skipped | 5 | 0 | — |
| `eb1af8446` candidate: fold the workflow's packages  | skipped | 1 | 2 | — |
| `eb915b016` M62: status in-progress | skipped | 2 | 2 | — |
| `ed2ac4146` plan M077: the set's figures say what th | skipped | 2 | 2 | — |
| `eebb80f77` review M68: done | skipped | 4 | 2 | — |
| `f0535aa57` plan M54: the inner tuning call finalize | skipped | 2 | 2 | — |
| `f4b408a60` triage: stamp carries the ROADMAP byte c | skipped | 1 | 2 | — |
| `f4db8f423` plan M38: a results object's own fold-la | skipped | 2 | 2 | — |
| `f54788684` plan M45, M46: the inner loop takes its  | skipped | 4 | 2 | — |
| `fc022a8fb` plan M44: agreement() tabulates what the | skipped | 3 | 2 | — |
| `ff4fe6d12` plan M65, M66: collect readers on the re | skipped | 4 | 2 | — |
