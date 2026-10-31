# M163: Keep an oracle registry outside tests

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP2
- **Resolves:** —
- **Surface tier:** internal — a tracking file under `cairn/` and one DESIGN.md convention bullet, which no package user reads
- **Branch/PR:** m163-oracle-registry

## Goal

Record each oracle of the test suite in `cairn/ORACLES.md`, so that a committed record shows the oracle types behind each numeric result.

## Scope

**In:** A new `cairn/ORACLES.md` built from the oracle records in the test-file comments at `576c3d19`, the last commit before M155 removed oracle ids and types from test comments. Each row points at the test's name at the milestone's head, through `benchmarks/test-renames-576c3d19.csv` and any later rename. The rows are grouped by numeric result, with a count of oracle types for each group. The oracle-records bullet in the Conventions section of `cairn/DESIGN.md` points at the registry.

**Out:**
- A test that keeps the registry in step with the test files. The plan gate on 2026-10-31 chose upkeep by hand at review, so no row holds it.
- New oracles for a group with fewer than two types. AC4 writes a candidate row for each one.
- Oracle ids or types in test comments. The test-comment rule forbids them there.
- Oracles in a file that neither grep in AC1 or AC2 lists. The registry claims only what the two greps list. A later milestone that adds an oracle adds its row (AC5).

## Acceptance criteria

- [x] AC1: `cairn/ORACLES.md` holds one row for each typed oracle record that `git grep -E '^# +O[0-9]+[a-z]?( +--)? +type' 576c3d19 -- tests/testthat` lists (71 records in 26 files on 2026-10-31). Each row gives a registry id that no other row uses, and the oracle's type in the doctrine's five-type vocabulary. Where the record's own type word differs, the row also gives that word. Each row gives the oracle's source. Each row names each test that the record names, by file and by its `test_that()` name at the milestone's head. Where that test no longer exists, or the record names no test, the row says so. The untyped `# O5 (Bayesian strand)` record in `test-nested-final-fit-oracles.R` is part of the O5 row of that file.
- [x] AC2: Some files hold a line that `git grep -i -E '^# .*oracle' 576c3d19 -- tests/testthat` lists but no line that matches AC1's pattern (20 files on 2026-10-31). For each such file, the registry holds one line that names the file. The line gives the registry ids of the rows drawn from that file, or it says that the file records no oracle and gives the reason that its comments state.
- [x] AC3: Each pair of a file and a `test_that()` name in the registry exists at the milestone's head. The file is under `tests/testthat/`, and it holds a `test_that()` call whose first argument is that name.
- [x] AC4: The registry groups its rows by the numeric result that they test. Each group states how many distinct doctrine types its rows hold. A group with fewer than two types names a `cairn/ROADMAP.md` candidate row for the missing oracle. Otherwise it names the record (a D-entry or an archived milestone) that accepts the shortfall.
- [x] AC5: The oracle-records bullet in the Conventions section of `cairn/DESIGN.md` names `cairn/ORACLES.md` as the record of oracle ids and types. The bullet says that a milestone that adds or removes an oracle updates the registry. The bullet no longer says that no committed record holds the types.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T1, T2, T4
- AC4 → T3
- AC5 → T4

## Tasks

- [x] T1: List the 71 typed records at `576c3d19` with the AC1 grep, and show the count before you use the list. For each record, map each test it names through `benchmarks/test-renames-576c3d19.csv` and the later block tables in `benchmarks/` to its name at the head. Write one row for each record in `cairn/ORACLES.md`, under a header that states the file's scope, the two greps, and the commit they read.
- [x] T2: Read the comments of the 20 untyped files at `576c3d19` and at the head. Add rows in AC1's form for the oracles that they describe, and one line for each file as AC2 states.
- [x] T3: Group the rows by the numeric result that they test, and count the doctrine types in each group. For each group under two types, cite the D-entry or archived milestone that accepts the shortfall, or search the candidates, the archive and DECISIONS.md for overlap and then add a candidate row.
- [x] T4: Rewrite the oracle-records bullet at `cairn/DESIGN.md:130`. List each pair of a file and a name from the registry and compare it with the `test_that()` calls at the head. Run `cairn_validate`.

## Work log

- 2026-10-31: created by /milestone-plan.
- 2026-10-31: tier check: not run — work named at the question set.
- 2026-10-31: question set: which candidate to plan — "Keep an oracle registry outside tests". How the registry stays current — by hand at review, with no test on it.
- 2026-10-31: plan gate chose upkeep by hand at review over a test that fails when a registry row names a missing test, because the user chose it and the doctrine leaves the registry to review judgment. This choice is false if registry rows go stale between milestones without a review that catches them.
- 2026-10-31: idea vet: gap, the doctrine addresses an asserting test as `test:line`, and line numbers move. Reading taken: file and `test_that()` name. Gap, the row says "rebuilt from the headers at 576c3d19", but M155 and later commits renamed tests. Reading taken: rows point at the names at the head. Gap, the old headers use the type words "analytic" and "analytic by-hand", which the doctrine does not use. Reading taken: rows give the doctrine type and keep the old word beside it. No flaw.
- 2026-10-31: collision check: absorbs the candidate row "Keep an oracle registry outside tests" (from M155's review). M155's archive made the gap, and M104 added one oracle and no registry. No D-entry heading names oracles or a registry. Inbox: 1 open issue (#91, docs pass) and 0 open PRs, none overlapping.
- 2026-10-31: plan decided that a group under two types gets a candidate row or a cited accepting record, and is not fixed here, so the milestone stays a record and adds no test.
- 2026-10-31: lessons used: 2026-09-11 (M86, extended M89), a checker that finds prose by dropping lines can drop its whole domain. It shaped the stated grep counts in AC1 and AC2 and the count step in T1.
- 2026-10-31: criteria audit (reduced mode, fresh Opus reader): 3 findings, all fixed. AC1's grep missed `O3b`, `O4b` and `O3c` and the `#   O1  type` form in two files, so the pattern now admits a letter suffix and an optional `--` (64 to 71 records, 24 to 26 files, 22 to 20 untyped files). AC1 promised every test that asserts an oracle, which no procedure lists, so it now covers the tests each record names. AC2's per-file oracles were left to judgment, so each file now gets one line with its row ids or a no-oracle reason. The untyped O5 strand now joins the O5 row. AC3, AC4, AC5: no finding.
- 2026-10-31: implement started on branch `m163-oracle-registry`. The profile's verify slot runs after code changes, and this milestone changes only `cairn/` files, so no verify run applies.
- 2026-10-31: T1 and T2 done in one pass: `cairn/ORACLES.md` holds 71 typed rows (ids compared with the AC1 grep's 71 records, no difference) and 17 prose rows from 13 of the 20 untyped files. The other 7 files have a line each: 5 record no oracle, and 2 point at typed rows. A one-off parse of `test_that()` calls at the head found 1080 calls, 38 with names built in code. Those names are given as deparsed code. All 123 test pointers matched a call at the head.
- 2026-10-31: implementation choices: ids are file stem plus the record's label, and prose rows take `U<n>`. "Analytic" maps to closed-form, and so does "analytic by-hand", because both are explicit code written from a formula or definition. A row that tests two results is written once and counted by id in the second group.
- 2026-10-31: T3 done: 23 groups. 17 hold two or more types and 6 hold live oracles only. The search of the candidates, the archive and DECISIONS.md found no record that accepts one type (D-079 counts two oracles for the selection rules, but both are live). So one candidate row, "Add second oracle types to six groups", holds all six, because the ROADMAP had room for one row (58 lines, 23,950 bytes after it).
- 2026-10-31: T4 done: the DESIGN.md oracle-records bullet now names `cairn/ORACLES.md`, says a milestone that adds or removes an oracle updates it, and drops the no-record sentence. The pointer comparison re-run read 123 pointers with 0 problems, and `cairn_validate` passed (18 advisory warnings on references staleness, none new).
- 2026-10-31: claim audit: not owed — internal tier.
- 2026-10-31: all tasks done; status set to review.
- 2026-10-31: review checkpoint (in progress): AC1-AC5 evidence recorded and ticked; `cairn_validate` and the six gating prose sweeps clean; `devtools::check()` and the two reviewers still running.

## Decisions

## Review

Evidence at `8f70dc69` (branch head), 2026-10-31. A one-off script read `cairn/ORACLES.md` against the greps at `576c3d19`. A one-off R parse listed the `test_that()` calls at the head (1080 calls, 38 with built names, 105 files).

- AC1: the AC1 grep lists 71 typed records in 26 files. The registry holds 71 typed rows whose ids equal the 71 records, with no duplicate id. Each row's type is one of the five doctrine types. The 5 records whose own word differs ("analytic", "analytic by-hand") carry that word in brackets, and no row carries a needless one. Each row has a source. Each row names its tests or says that the record names none. The `O5` row of `nested-final-fit-oracles` holds the Bayesian strand and its test. 0 problems.
- AC2: the AC2 grep, less the typed files, gives 20 files. The last section holds exactly one line for each, and no line for any other file. 14 lines give row ids, all of which exist in the registry. The other 6 say that the file records no oracle, with the reason its comments state. 0 problems.
- AC3: 123 pairs of a file and a name in the registry, each compared with the `test_that()` calls in that file at the head (a literal name by its string, a built name by its one-line deparsed call). 0 unparsed lines, 0 missing.
- AC4: 23 group headings, each stating its types and count. For each, the stated set equals the set of types of its rows plus the rows it counts by id, and every row sits in a group. 6 groups hold one type, and each names the candidate row "Add second oracle types to six groups", which `cairn/ROADMAP.md` holds. 0 problems.
- AC5: `cairn/DESIGN.md:130-138` names `cairn/ORACLES.md` as the record of each oracle's id and type, and says "A milestone that adds or removes an oracle updates `cairn/ORACLES.md`". `grep -c 'no committed record holds' cairn/DESIGN.md` gives 0.
