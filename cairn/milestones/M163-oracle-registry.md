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

**In:** A new `cairn/ORACLES.md` built from the oracle records in the test-file comments at `576c3d19`, the last commit before M155 removed oracle ids and types from test comments. Each row points at the test's name at the milestone's head, through `benchmarks/test-renames-576c3d19.csv` and any later rename. The rows are put in named groups, with a count of oracle types for each group. The oracle-records bullet in the Conventions section of `cairn/DESIGN.md` points at the registry.

**Out:**
- A test that keeps the registry in step with the test files. The plan gate on 2026-10-31 chose upkeep by hand at review, so no row holds it.
- New oracles for a group with fewer than two types. AC4 writes a candidate row for each one.
- Oracle ids or types in test comments. The test-comment rule forbids them there.
- Oracles in a file that neither grep in AC1 or AC2 lists. The registry claims only what the two greps list. A later milestone that adds an oracle adds its row (AC5).

## Acceptance criteria

- [ ] AC1: `cairn/ORACLES.md` holds one row for each typed oracle record that `git grep -E '^# +O[0-9]+[a-z]?( +--)? +type' 576c3d19 -- tests/testthat` lists (71 records in 26 files on 2026-10-31). Each row gives a registry id that no other row uses, and the oracle's type in the doctrine's five-type vocabulary. Where the record's own type word differs, the row also gives that word. Each row gives the oracle's source. Each row lists tests at the milestone's head by file and `test_that()` name, or says that it lists none. A typed record's text is its grep line and the comment lines after it, up to a line that is `#` alone, a non-comment line, or the next record, with the `#` and leading spaces stripped and the lines joined by single spaces. A typed record names a test in its own file, or in a file its text names, when its text quotes, in double quotes or backticks, a string that matches that test's name at the head or the `576c3d19` name that `benchmarks/test-renames-576c3d19.csv` maps to it. In a quoted string, `...` or text in angle brackets is a wildcard. In a name built in code, each argument that is not a string literal is a wildcard. A string matches a name when some text fits both. A string inside another quoted string, or made only of wildcards, names no test. A prose row's (AC2) record names no test. A row lists each test that its record names, unmarked, and marks every other test it lists as found by reading. Where a string quoted right after "Pinned by" or "Pinned by the" and one word, in any letter case, names no test in this sense, the row says so. The untyped `# O5 (Bayesian strand)` record in `test-nested-final-fit-oracles.R` is part of the O5 row of that file.
- [x] AC2: Some files hold a line that `git grep -i -E '^# .*oracle' 576c3d19 -- tests/testthat` lists but no line that matches AC1's pattern (20 files on 2026-10-31). For each such file, the registry holds one line that names the file. The line gives the registry ids of the rows drawn from that file, or it says that the file records no oracle and gives the reason that its comments state.
- [x] AC3: Each pair of a file and a `test_that()` name in the registry exists at the milestone's head. The file is under `tests/testthat/`, and it holds a `test_that()` call whose first argument is that name.
- [x] AC4: The registry puts each row in one or more named groups. Each group states how many distinct doctrine types are carried by the rows it lists and the rows it counts by id. A group with fewer than two types names a `cairn/ROADMAP.md` candidate row for the missing oracle, or names the record (a D-entry or an archived milestone) that accepts the shortfall. The registry says that its groups are one cut of the results, and that a finer cut can find more results backed by one type.
- [x] AC5: The oracle-records bullet in the Conventions section of `cairn/DESIGN.md` names `cairn/ORACLES.md` as the record of oracle ids and types. The bullet says that a milestone that adds or removes an oracle updates the registry. The bullet no longer says that no committed record holds the types.

## Coverage

- AC1 → T1, T5, T6, T7
- AC2 → T2, T6
- AC3 → T1, T2, T4
- AC4 → T3, T5, T6
- AC5 → T4, T7

## Tasks

- [x] T1: List the 71 typed records at `576c3d19` with the AC1 grep, and show the count before you use the list. For each record, map each test it names through `benchmarks/test-renames-576c3d19.csv` and the later block tables in `benchmarks/` to its name at the head. Write one row for each record in `cairn/ORACLES.md`, under a header that states the file's scope, the two greps, and the commit they read.
- [x] T2: Read the comments of the 20 untyped files at `576c3d19` and at the head. Add rows in AC1's form for the oracles that they describe, and one line for each file as AC2 states.
- [x] T3: Group the rows by the numeric result that they test, and count the doctrine types in each group. For each group under two types, cite the D-entry or archived milestone that accepts the shortfall, or search the candidates, the archive and DECISIONS.md for overlap and then add a candidate row.
- [x] T4: Rewrite the oracle-records bullet at `cairn/DESIGN.md:130`. List each pair of a file and a name from the registry and compare it with the `test_that()` calls at the head. Run `cairn_validate`.
- [x] T5: Fix review return 1: the AC1 rows for `eval-time/O2`, `eval-time/O3` and `time-series-pairs-other/O5`/`O6`; split the reader-tables group (AC4); and the other fix-now findings the Review section lists. Rename the candidate row to the new count.
- [x] T6: Fix review return 2: the AC1 rows for `nested-workflow-map-oracles/O1` and the `O5` Bayesian strand, the AC2 line for `helper-orchestration.R`, and fix-now findings #8, #13, #14, #15 and #16 from the second pass. Carry out the AC4 amendment: the registry's note on its groups, and the finer splits in the candidate row.
- [x] T7: Carry out the AC1 amendment (the user's choice at the re-audit stop): mark each listed test that its record does not quote as found by reading, and say so on each row whose "Pinned by" quote names no test. Fix third-pass findings #3, #7, #9 and #10.

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
- 2026-10-31: review return 1: diff-bug #4 and #6 show AC1 failing (a row that does not say its named test never existed; two rows that say the record names no test when it names one), and #1 shows AC4 failing (one group merging four results). Fix those and the other fix-now findings #2, #3, #5, #7, #8 and #9 listed in the Review section, then rename the candidate row to the new count of one-type groups.
- 2026-10-31: T5 added for review return 1 (minor amendment; Coverage AC1 and AC4 now also map to T5).
- 2026-10-31: T5 done. `eval-time/O2` says its first named test matches no test even at `576c3d19` and gives the test found in its place, and `eval-time/O3` notes its name's wording. `time-series-pairs-other/O5`/`O6` name the test the record's lead-in names. The reader-tables group became four groups (stacked readers, wide tables, fold labels, `augment()` joins). Found-by-reading tests were added to four prose rows, and the M92 set test to the workflow-map readers row. `nested-fit-resamples-oracles/O2` is now live, which supersedes the T1 choice for that row. The Bayesian and annealing groups note the records' stage split, and the mode-independence rows note the parallel-identity file's disclaimer. The D-079 citation now covers outer designs only, and the grid-results file line lists O4. The candidate row is now "Add second oracle types to ten groups". The registry checks give 71 typed rows, 20 file lines, 26 groups (10 of one type), 146 pointers, 0 problems. ROADMAP is 58 lines and 23,899 bytes.
- 2026-10-31: status set to review.
- 2026-10-31: review return 2: second-pass diff-bug #6 and #7 show AC1 failing (two rows list tests their records do not name, without saying so), and #12 shows AC2 failing (the helper-orchestration line gives a reason its comments do not state). Fix those and fix-now findings #8, #13, #14, #15 and #16 from the Review section.
- 2026-10-31: amendment routed: AC4 — second-pass diff-bug #1-#5, #9 and #10 each split a group into finer results on one type; AC4's "groups its rows by the numeric result that they test" names no procedure that decides a result's grain, so each pass can find a finer split (widening test). Narrow AC4 to what the file can show, and carry the finer splits in the candidate row.
- 2026-10-31: T6 added for review return 2 and the AC4 amendment (minor amendment; Coverage AC1, AC2 and AC4 now also map to T6).
- 2026-10-31: re-audit: AC4 (reduced) — nothing. The fresh Opus reader judged the amended wording bounded (rows and `##` groups a reader lists), proportionate, deliverable-bound and narrower than before. It noted that a single all-rows group would pass, and suggested an optional heading clause. That clause was not taken, because adding a property after defect returns would widen the criterion. It also noted the Goal's and Scope's old wording.
- 2026-10-31: amendment return: AC4 — "The registry puts each row in one or more named groups. Each group states how many distinct doctrine types are carried by the rows it lists and the rows it counts by id. A group with fewer than two types names a `cairn/ROADMAP.md` candidate row for the missing oracle, or names the record (a D-entry or an archived milestone) that accepts the shortfall. The registry says that its groups are one cut of the results, and that a finer cut can find more results backed by one type."
- 2026-10-31: Scope In now says "The rows are put in named groups", to match AC4. The Goal keeps "each numeric result", because a Goal changes only through a re-plan, and the AC4 wording binds what review checks.
- 2026-10-31: T6 done. `nested-workflow-map-oracles/O1` and the `O5` Bayesian strand now say that their records name no test, and give the tests found by reading. The `helper-orchestration.R` line rests on its header's own words. The registry header states the "analytic by-hand" mapping rule. `nested-resamples-identity/U1` gains its fourth test. The selection group notes the Bayesian desirability test beside the racing one. The registry header and the DESIGN bullet now say the test file names the pinning test "for most oracles". The registry says its groups are one cut. The candidate row is retitled "Settle oracle types for ten groups" and lists the finer one-type results from the second pass. Checks: 71 typed rows, 20 file lines, 26 groups (10 of one type), 147 pointers, 0 problems; `cairn_validate` passes; ROADMAP is 58 lines and 23,990 bytes.
- 2026-10-31: status set to review.
- 2026-10-31: amendment routed: AC1 — third-pass diff-bug #1, #2, #5 and #6: rows list tests their records describe in prose ("the test below", "stochastic variants", "AC2's tests") with no mark. Which tests a record "names" is decided by reading prose, and the first and second passes each found other rows of this shape. Narrow AC1 so that only a name the record quotes counts as named, and mark every other listed test as found by reading. Also fix third-pass #3, #7, #9 and #10. AC1 has no earlier amendment return. The defect-return count stays at 2.
- 2026-10-31: checkpoint (half done): third-pass fixes #3, #7, #9 and #10 are in `cairn/ORACLES.md` and `cairn/DESIGN.md`. The AC1 amendment awaits its fresh reader. The quoted-name marking is not yet written.
- 2026-10-31: re-audit: AC1 (reduced) — four findings in the matching rule, all taken: a record's text had no stated bounds; wildcard quotes matched tests in other files (wider than before); edge cases (a backtick span that is only `...`, `paste0()` names with no `%s`, `<that element>` as two words); and "Pinned by" said "matches" where the naming rule says "names". Clauses on boundedness, proportion and instrument pass once these are fixed. The fixed wording goes to its own fresh reader.
- 2026-10-31: re-audit: AC1 (reduced) — four findings on the fixed wording: the CSV gives no `576c3d19` name for a test renamed later, so map from the head name; "equal" is undefined when a quote with wildcards meets a name built in code; prose rows in a file with two rows would share every comment run, which is wider, so a prose row's record names no test; and the "Pinned by" match needs a case and word rule. It judged the wording deliverable-bound, earned in length, narrower in practice, and satisfiable. This is AC1's second re-audit line, so further churn goes to the user (the repeated review-failure stop).
- 2026-10-31: proposed AC1 wording at the stop: "AC1: `cairn/ORACLES.md` holds one row for each typed oracle record that `git grep -E '^# +O[0-9]+[a-z]?( +--)? +type' 576c3d19 -- tests/testthat` lists (71 records in 26 files on 2026-10-31). Each row gives a registry id that no other row uses, and the oracle's type in the doctrine's five-type vocabulary. Where the record's own type word differs, the row also gives that word. Each row gives the oracle's source. Each row lists tests at the milestone's head by file and `test_that()` name, or says that it lists none. A typed record's text is its grep line and the comment lines after it, up to a line that is `#` alone, a non-comment line, or the next record, with the `#` and leading spaces stripped and the lines joined by single spaces. A typed record names a test in its own file, or in a file its text names, when its text quotes, in double quotes or backticks, a string that matches that test's name at the head or the `576c3d19` name that `benchmarks/test-renames-576c3d19.csv` maps to it. In a quoted string, `...` or text in angle brackets is a wildcard. In a name built in code, each argument that is not a string literal is a wildcard. A string matches a name when some text fits both. A string inside another quoted string, or made only of wildcards, names no test. A prose row's (AC2) record names no test. A row lists each test that its record names, unmarked, and marks every other test it lists as found by reading. Where a string quoted right after "Pinned by" or "Pinned by the" and one word, in any letter case, names no test in this sense, the row says so. The untyped `# O5 (Bayesian strand)` record in `test-nested-final-fit-oracles.R` is part of the O5 row of that file."
- 2026-10-31: user decision at the AC1 re-audit stop: "Adopt the quoted rule (Recommended)". The other options were a shorter "Pinned by"-only rule and parking M163.
- 2026-10-31: amendment return: AC1 — "Each row lists tests at the milestone's head by file and `test_that()` name, or says that it lists none. A typed record's text is its grep line and the comment lines after it, up to a line that is `#` alone, a non-comment line, or the next record, with the `#` and leading spaces stripped and the lines joined by single spaces. A typed record names a test in its own file, or in a file its text names, when its text quotes, in double quotes or backticks, a string that matches that test's name at the head or the `576c3d19` name that `benchmarks/test-renames-576c3d19.csv` maps to it. In a quoted string, `...` or text in angle brackets is a wildcard. In a name built in code, each argument that is not a string literal is a wildcard. A string matches a name when some text fits both. A string inside another quoted string, or made only of wildcards, names no test. A prose row's (AC2) record names no test. A row lists each test that its record names, unmarked, and marks every other test it lists as found by reading. Where a string quoted right after "Pinned by" or "Pinned by the" and one word, in any letter case, names no test in this sense, the row says so."
- 2026-10-31: T7 added (minor amendment; Coverage AC1 and AC5 also map to T7) and done. A one-off script read each record's text by the AC1 bounds and decided, per listed test, whether the record names it. It appended " (found by reading)" to 87 of 147 test lines, and a second run changes none. The script edit to `cairn/ORACLES.md` bypassed the Edit tool because of the line count. The row prose that claimed which tests a record names was removed, since the marks now carry that. Six rows say that their "Pinned by" quote names no test: `eval-time/O2` and `O3`, race and anneal `O1`, and `time-series-designs/O1` and `O2`. Third-pass fixes: the registry header and the DESIGN bullet now cover the oracles the `576c3d19` comments recorded and say the header names those left out (#3); `fold-labels/U1` is invariant (#7); the splits group is out of D-079's reason (#9); and the `helper-orchestration.R` line gives only its header's words (#10). Checks: 71 typed rows, 20 file lines, 26 groups (10 of one type), 147 pointers, 0 problems; `cairn_validate` passes. A Replace-all Edit had joined 22 row lines to their first test line; they were split back, and the test-line count stayed 147.
- 2026-10-31: status set to review.

## Decisions

## Review

Evidence at `8f70dc69` (branch head), 2026-10-31. A one-off script read `cairn/ORACLES.md` against the greps at `576c3d19`. A one-off R parse listed the `test_that()` calls at the head (1080 calls, 38 with built names, 105 files).

- AC1: the AC1 grep lists 71 typed records in 26 files. The registry holds 71 typed rows whose ids equal the 71 records, with no duplicate id. Each row's type is one of the five doctrine types. The 5 records whose own word differs ("analytic", "analytic by-hand") carry that word in brackets, and no row carries a needless one. Each row has a source. Each row names its tests or says that the record names none. The `O5` row of `nested-final-fit-oracles` holds the Bayesian strand and its test. 0 problems.
- AC2: the AC2 grep, less the typed files, gives 20 files. The last section holds exactly one line for each, and no line for any other file. 14 lines give row ids, all of which exist in the registry. The other 6 say that the file records no oracle, with the reason its comments state. 0 problems.
- AC3: 123 pairs of a file and a name in the registry, each compared with the `test_that()` calls in that file at the head (a literal name by its string, a built name by its one-line deparsed call). 0 unparsed lines, 0 missing.
- AC4: 23 group headings, each stating its types and count. For each, the stated set equals the set of types of its rows plus the rows it counts by id, and every row sits in a group. 6 groups hold one type, and each names the candidate row "Add second oracle types to six groups", which `cairn/ROADMAP.md` holds. 0 problems.
- AC5: `cairn/DESIGN.md:130-138` names `cairn/ORACLES.md` as the record of each oracle's id and type, and says "A milestone that adds or removes an oracle updates `cairn/ORACLES.md`". `grep -c 'no committed record holds' cairn/DESIGN.md` gives 0.

Consistency gate: `cairn_validate` passed (18 advisory staleness warnings, none new). The six gating prose sweeps exit 0. The diff touches only `cairn/` (no `principle` changed, so no `cairn_impact` run). `devtools::check()` was still running at this pass.

spawned: diff-bug, ripple (internal tier, docs-only diff)

- diff-bug #1: the "Reader tables" group merges four results (stacked readers, wide tables, fold labels, `augment()` joins), each on one type, so its "3 types" hides four shortfalls and fails AC4's one group per result — fix now (split, each named in the candidate row).
- diff-bug #2: the BC10/BC12/BC13 rows count serial-against-parallel identity as invariant, while BC14 and BC17 go unregistered, and the parallel-identity file calls these mode-independence checks — reject in part (false: no record at `576c3d19` names BC14 or BC17 as an oracle, so a row would invent one); fix now in part (note the file's disclaimer on the three rows and the records' own initial-stage and iteration-stage split on the Bayesian and annealing groups).
- diff-bug #3: four prose rows list no test though their tests exist — fix now (found by reading).
- diff-bug #4: `eval-time/O2`'s first named test did not exist even at `576c3d19`, and the row says nothing, which fails AC1; `eval-time/O3`'s record writes "evaluation time" for `eval_time` — fix now.
- diff-bug #5: `nested-fit-resamples-oracles/O2`, a by-hand fit, predict and score, is an independent implementation, so live, not closed-form — fix now; `resample-weights/O1` stays closed-form (written-out weighted-mean formulas).
- diff-bug #6: `time-series-pairs-other/O5` and `O6` say the record names no test, but the record's lead-in names one, which fails AC1 — fix now.
- diff-bug #7: the racing selector test that D-079 counts is absent, and the M92 set test that `nested-workflow-map-readers` comments tie to its oracle is missing — fix now (note the racing test, which no record at `576c3d19` describes as an oracle; add the M92 test to the readers row).
- diff-bug #8: the `test-nested-tune-grid-results.R` file line omits `nested-tune-grid-oracles/O4`, whose test is there, while the parallel-identity line lists by test location — fix now.
- diff-bug #9: D-079's reason (the outer design never reaches tuner code) is cited for inner-design and pair rows it does not cover — fix now (narrow the citation).
- diff-bug #10: no provenance field — reject (false: each id names the record's file and label, and the header names the commit read).
- diff-bug #11: a literal name holds unescaped inner quotes; `test-nested-results-agreement.R` gives an oracle source — reject (style: the parse reads it; planned: the line gives the reason the file's own comment states, as AC2 asks).
- ripple #1: 21 test headers quote "oracles are recorded in the test file that asserts them" — reject (false: the new bullet still places each oracle's source and pinning test in that file).
- ripple #2: `test-parallel-payload.R:10-11` says the records live beside the asserting test — reject (false, same reason).
- ripple #3: the source candidate row still says no record holds the types — reject (planned: it graduates at hygiene).
- ripple #4: `test-parallel-metrics.R` and `test-parallel-identity.R` cite DESIGN "Oracle records" — reject (false: the reviewer finds no conflict, and the bullet keeps that title).

Second pass, after review return 1. Evidence at `606a3d44`, 2026-10-31, with the same one-off scripts. The default branch has not moved.

- AC1 (re-verified): 71 typed records and 71 typed rows with equal ids, doctrine types, the 5 differing record words in brackets, a source on each. Each row names its tests or says why not. `eval-time/O2` now says that its first named test matches no test even at `576c3d19`, and gives the test found in its place. `time-series-pairs-other/O5` and `O6` now name the test that the record's lead-in names. A sweep of every quoted name in the 71 records against the names at `576c3d19` found no other named test missing, apart from descriptions and rendered instances of names built in code. 0 problems.
- AC2 (re-checked): 20 files, one line each, no extra line, every id known. 0 problems.
- AC3 (re-checked): 146 pairs of a file and a name, each matched to a `test_that()` call at the head. 0 missing.
- AC4 (re-verified): 26 groups, each stating its types and count, each count equal to its rows' types, every row in a group. The four reader tables are now four groups (stacked readers, wide tables, fold labels, `augment()` joins). 10 groups hold one type, and each names "Add second oracle types to ten groups", which `cairn/ROADMAP.md` holds. 0 problems.
- Gate: `devtools::check()` (started at `d9b097a4`; the branch since changed only `cairn/`, which `.Rbuildignore` leaves out) gave 0 errors, 0 warnings, 0 notes in 11m 10s. `devtools::document()` changed only `Config/roxygen2/version` (8.1.0 to the local 8.1.1), reverted, as at M161. No README, pkgdown, NEWS or new top-level file change is owed: the diff is under `cairn/` alone. `cairn_validate` passes at `606a3d44`.

spawned: diff-bug, ripple (second pass)

- ripple #1: the source row "Keep an oracle registry outside tests" says no record holds the types — reject (planned: it graduates at hygiene).
- ripple #2: test headers cite "oracles are recorded in the test file that asserts them" — reject (false: the bullet still places each oracle's source and pinning test there).
- ripple #3: `test-parallel-payload.R:10-11` says the records live beside the test — reject (false, same reason).
- ripple #4: `test-nested-resamples-memory.R:2-3` says the records sit beside the test — reject (false, same reason).
- ripple #5: `benchmarks/sweep-test-comments.R:24` names the `-- type "` header label — reject (false: it names a pattern the sweep forbids in test comments, which stays true).
- ripple #6: two files cite DESIGN "Oracle records" — reject (false: the reviewer finds the citation resolves).
- diff-bug #1: `compute_metrics()` U1 covers the run's own metric set and U2 a new one, each on one type — amendment return (AC4 names no procedure that decides how fine a "numeric result" is, so this split widens an author-recall enumeration; the follow-up goes to the candidate row).
- diff-bug #2: event level and eval-time groups merge the outer-fold metric with the final fit's tuning, each on one type — amendment return (same reason).
- diff-bug #3: the weights group's failed-fold and NA-fold cases rest on O1 alone, since O2 is every-fold only — amendment return (same reason).
- diff-bug #4: the race fold record sits in the race estimate group, while grid's fold record has its own — amendment return (same reason).
- diff-bug #5: the Bayesian and annealing iteration stage rests on live plus a mode-independence identity, and the plan gate the records cite is no D-entry or archived milestone — amendment return (same reason).
- diff-bug #6: `nested-workflow-map-oracles/O1`'s record names no test ("One block per `fn`"), and the row does not say so, which fails AC1 — fix now (review return 2).
- diff-bug #7: the `O5` Bayesian strand's record names no test, and the row lists one without saying so, which fails AC1 — fix now (review return 2).
- diff-bug #8: "analytic by-hand" maps to live for one row and closed-form for another, with no stated rule — fix now (state the rule: an independent run of the pipeline is live, written-out formulas are closed-form).
- diff-bug #9: the memory group merges a slope comparison with an absolute size — amendment return (same reason as #1).
- diff-bug #10: the `hand_average()`-only cases rest on one type — amendment return (same reason as #1).
- diff-bug #11: `test-nested-results-agreement.R` gives oracle provenance, yet the registry says it records no oracle — reject (planned: AC2 accepts the reason the file's comments give, and they say no statistic there needs an oracle).
- diff-bug #12: the `helper-orchestration.R` line gives a reason of the registry's own, not its comments', which fails AC2 — fix now (review return 2).
- diff-bug #13: `nested-resamples-identity/U1` omits "an already-evaluated outer rset is accepted and matches" — fix now.
- diff-bug #14: the Bayesian desirability rule's prose oracle in a typed file goes unmentioned — fix now (note it beside the racing one).
- diff-bug #15: the candidate row's title asks for second types for ten groups, then says four can owe none; fold labels are not tested numbers — fix now (retitle and reword).
- diff-bug #16: the DESIGN bullet and the registry header say each test file's header names the pinning test, but many records name none and some sit mid-file — fix now.
- diff-bug #17: three file lines list ids of rows from other files — reject (style: each line says why the id is there, which AC2's form allows).

Third pass, after review return 2 and the AC4 amendment. Evidence at `42a9cf66`, 2026-10-31, same one-off scripts; the default branch has not moved.

- AC1 (re-verified): 71 typed rows equal to the 71 records, doctrine types, the 5 differing words in brackets, a source each. `nested-workflow-map-oracles/O1` and the `O5` Bayesian strand now say that their records name no test before the tests found by reading. 0 problems.
- AC2 (re-verified): 20 files, one line each, every id known. The `helper-orchestration.R` line now gives the reason in its header's own words. 0 problems.
- AC3 (re-checked): 147 pairs, each matched to a `test_that()` call at the head. 0 missing.
- AC4 (verified against the amended wording): every row sits in one of 26 named groups. Each group states its types and count, and each count equals the types of the rows it lists plus the rows it counts by id. The 10 groups of one type each name "Settle oracle types for ten groups", which `cairn/ROADMAP.md` holds. The header holds "The groups are one cut, and a finer cut can find more results backed by one type". 0 problems.

spawned: diff-bug, ripple (third pass)

- ripple #1: `test-parallel-payload.R:10-11` cites DESIGN for records that live beside the test — follow-up, row "Point test oracle headers at the registry" (parked, promote on the next change to those headers). The third pass raised it again. The headers still hold each oracle's source, but they no longer say where its id and type live. The row is written at hygiene, after the source row graduates, because the ROADMAP is at 23,985 of its 24,000 bytes.
- ripple #2: `test-nested-resamples-memory.R:2-3`, same — follow-up, same row.
- ripple #3: 18 headers cite "oracles are recorded in the test file that asserts them" — follow-up, same row.
- ripple #4: the source row "Keep an oracle registry outside tests" still states the gap — reject (planned: it graduates at hygiene).
- diff-bug #1: `nested-tune-grid-oracles/O6`'s record names no test, and the row does not say so — amendment return (AC1's "each test that the record names" is decided by reading prose, and each pass finds another row; the narrowing repair names quoted names as the procedure).
- diff-bug #2: `augment/U2` says its record names "the tests below it", but the comment names none — amendment return (same reason).
- diff-bug #3: the registry header says it records each oracle the suite asserts, and the DESIGN bullet says it records each oracle's id and type, yet two asserted oracles have no row — fix now (bound both to the records the greps list and the ones added since).
- diff-bug #4: BC10, BC12 and BC13 count as invariant while BC14, BC16 and BC17 get no rows — reject (false: rows follow the records at `576c3d19`, which name only the first three as oracles, as settled at the first pass).
- diff-bug #5: second tests on the grid, race and anneal `O1` rows are described but not quoted by their records, and carry no mark — amendment return (same reason as #1).
- diff-bug #6: "the record names AC2's tests" reads an AC citation as naming tests — amendment return (same reason as #1).
- diff-bug #7: `fold-labels/U1` copies labels from the input design, which is no formula — fix now (invariant).
- diff-bug #8: `collect-predictions-summarize/U2` is written from the help page's rules, not a published formula — reject (false: the doctrine's closed-form covers a definitional rule recomputed with explicit code).
- diff-bug #9: D-079's outer-design reason does not cover the splits group — fix now.
- diff-bug #10: the `helper-orchestration.R` line adds a gloss its header does not state — fix now (header words only).
- diff-bug #11: the `helper-payload-size.R` line lists ids of rows from another file — reject (style, as settled at the second pass).
- diff-bug #12: `test-nested-results-agreement.R` may hold an invariant — reject (planned: the line gives the reason the file's comments state).
- diff-bug #13: unescaped inner quotes in a literal name — reject (style).
