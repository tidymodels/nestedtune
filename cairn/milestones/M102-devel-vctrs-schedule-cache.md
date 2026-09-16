# M102: The devel-vctrs leg runs weekly and keeps its own dependency cache

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — CI workflow files
- **Branch/PR:** `m102-devel-vctrs-schedule-cache`

## Goal

`.github/workflows/devel-vctrs.yaml` runs on a weekly schedule beside its push and pull-request triggers, and its dependency cache is keyed apart from every other workflow's so a development vctrs is never restored elsewhere.

## Scope

**In:** a `schedule:` and a `workflow_dispatch:` trigger; a `cache-version` on the leg's `setup-r-dependencies@v2` step; the header comment and `cairn/PROFILE.md`'s test-doctrine line; one dispatched run as evidence.

**Out:** a cache change on `stress-daemon-tests.yaml` (the distinct key on devel-vctrs removes the sharing); a schedule on the stress leg; pricing a cold devel build (the row's other trigger, unfired).

## Acceptance criteria

- [ ] AC1: `.github/workflows/devel-vctrs.yaml` carries a `schedule:` trigger with one weekly cron line and a `workflow_dispatch:` trigger beside its `push` and `pull_request` triggers, and its header comment no longer says the leg carries no schedule.
- [ ] AC2: The `setup-r-dependencies@v2` step in `devel-vctrs.yaml` passes a `cache-version` value that `grep -rn cache-version .github/workflows/` finds in no other workflow file.
- [ ] AC3: One `workflow_dispatch` run of the leg on the milestone branch completes and saves a cache whose key (listed by `gh cache list`) contains that `cache-version` value and matches no key another workflow's run saved.
- [ ] AC4: `cairn/PROFILE.md`'s test-doctrine line describing `devel-vctrs.yaml`'s triggers states the schedule.

## Coverage

- AC1 → T1
- AC2 → T1
- AC3 → T2
- AC4 → T3

## Tasks

- [x] T1: Edit the workflow: `schedule:` (a weekly cron off-peak), `workflow_dispatch:`, `cache-version: devel-vctrs` on the setup step (`devel-vctrs.yaml:88-91`); rewrite the header comment (`:9-13`).
- [x] T2: Push the branch, `gh workflow run devel-vctrs.yaml --ref <branch>` (the workflow is on the default branch, so dispatch on a branch works, M88 lesson), wait per the CI-wait rule, then `gh cache list` and record the key in the work log.
- [x] T3: Update `cairn/PROFILE.md`'s line on `devel-vctrs.yaml` and any DESIGN.md sentence naming its triggers (`grep -n devel-vctrs cairn/DESIGN.md cairn/PROFILE.md`).

## Work log

- 2026-09-16: created by /milestone-plan from two candidate rows added 2026-09-10 (M080 review F1 and F4).
- 2026-09-16: plan gate chose a distinct `cache-version` over `cache: false` on the leg because it keeps warm installs while cutting the shared restore-key prefix; falsified by the leg's run still restoring another workflow's cache in its log.
- 2026-09-16: T1 done. Cron `0 6 * * 1` (Monday 06:00 UTC, the plan's off-peak weekly slot, chosen without a gate since the plan fixed the cadence and the key value), `workflow_dispatch:`, `cache-version: devel-vctrs`; header rewritten. `ci-usage.py`'s `read_paths_ignore()` still returns one agreed list over six workflows; `grep -rn cache-version .github/workflows/` finds only devel-vctrs.yaml. No R code changed, so the verify slot's `devtools::test()` was not owed.
- 2026-09-16: T3 done before T2's run finished. PROFILE.md's devel-vctrs sentence names the four triggers and the cache key; DESIGN.md names no devel-vctrs trigger (`grep -n devel-vctrs cairn/DESIGN.md` empty). The edit put PROFILE.md at 122 lines against the 120 cap; the divergences bullet was compressed in one pass to 119, `cairn_validate` green.
- 2026-09-16: T2 done. `gh workflow run devel-vctrs.yaml --ref m102-devel-vctrs-schedule-cache` gave run 35149168999 (workflow_dispatch), success, 20:52:53Z to 21:29:35Z. Its log reads `Cache not found for input keys: ...-x86_64-devel-vctrs-cb589199..., ...-x86_64-devel-vctrs-` at the restore, so no other workflow's cache was restored (the plan-gate falsifier did not fire), and `Cache saved with key: Ubuntu 24.04.5 LTS-R version 4.6.1 (2026-06-24)-x86_64-devel-vctrs-cb58919972c102555d146ea4b930eefa4daaf04db9bce6a48a86c7da1f9d69a5` at the post step. `gh cache list --limit 100` shows that key once and every other key (57) carrying `-1-` in its place; the same-hash sibling `...-x86_64-1-cb589199...` from the release leg shows the version segment is the whole difference.
- 2026-09-16: claim audit: not owed — internal tier.
- 2026-09-16: all tasks checked, `cairn_validate` green; status to review. The simple-english lint hook flagged pre-existing sentences in ROADMAP.md, PROFILE.md and this file at every edit; the tracking files were not rewritten for it, since cairn records are append-only and the flagged text is prior history.

## Decisions

## Review
