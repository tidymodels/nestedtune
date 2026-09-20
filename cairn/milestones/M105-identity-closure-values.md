# M105: The workflow identity reads what a function-valued setting closes over

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP3, GP3, GP4
- **Resolves:** —
- **Surface tier:** user-facing, because it changes what `nested_final_fit()` refuses and the help page that states it
- **Branch/PR:** —

## Goal

`workflow_identity()` records the values a function-valued setting reads from
outside itself, so `nested_final_fit()` refuses a workflow whose function
computes something other than the one the estimate was built around.

## Scope

**In:** `deparse_one()` (`R/workflow-identity.R:154`) routes a function
through a new `closure_identity()`. One site then covers every setting that is
a function: a recipe step's settings, a step's nested `options`, and a tailor
adjustment's arguments. The names read are the ones
`codetools::findGlobals()` reports. `codetools` joins Imports (D-066). The
refusal message names the binding that differs. The five source sites and the
DESIGN paragraph that say a function is compared by its body are corrected,
and one NEWS bullet states the change. This absorbs the candidate row filed at
M083's gates and narrowed at M103's hygiene to this item.

**Out:**
- A value a function reaches indirectly, through `get()`, `eval()`, `mget()`
  or `...`, is not read. A closed-over environment stays `<environment>`, so
  two functions over different environments read alike. Both go to a
  candidate row.
- Bounding every deparsed leaf, not only a read binding. M103's review logged
  a data-frame step argument deparsing whole as latent. It goes to the same
  row.
- A model argument given as a name stays recorded as written, not by value.
  M083 chose that deliberately, and it is unchanged here.
- Migrating a saved record whose function setting closes over something. It
  refuses its own workflow after this change, as pre-1.0 allows (D-003).

## Acceptance criteria

- [ ] AC1: For a setting that is a function, `workflow_identity()` records a
      two-part entry. The first part is the function in the `deparse_one()`
      form it has today. The second part is each binding that
      `codetools::findGlobals(fn, merge = FALSE)$variables` names and that
      resolves through the function's enclosing environments to an environment
      that is not a namespace, not an attached package environment and not the
      base environment, in name order, each recorded by value through
      `deparse_one()`. Where that procedure names no such binding, the entry is
      the single deparsed string recorded today, and
      `tests/testthat/fixtures/branch-point-results.rds` still matches the
      workflow it was built from.
- [ ] AC2: Two workflows built by the same code that differ only in one read
      binding's value have identities that are not `identical()`, and
      `nested_final_fit()` refuses the second against a record built from the
      first with condition class `nestedtune_workflow_mismatch`. Two workflows
      built by the same code over equal values have identities that are
      `identical()`. Both hold over a family of settings that varies the form
      as well as the value: a number, a character vector, a list, another
      function, a base function named from a namespace (`median`), and a
      function that reads nothing.
- [ ] AC3: Where the difference is one read binding, the refusal message names
      that binding. It shows the recorded and the given forms where both were
      recorded as text. It says the value differs without showing it where
      either was recorded as a fingerprint under AC4. The test asserts on the
      rendered message.
- [ ] AC4: A read binding whose `deparse_one()` form is longer than 2,048
      characters is recorded as `rlang::hash()` of that text instead. The
      entry that binding contributes is then one fixed-length string whatever
      the value's size, and two workflows differing only in such a value still
      have identities that are not `identical()`.
- [ ] AC5: After the change, a repository sweep for the stale claim reports
      nothing. The sweep is
      `grep -rniE "compared (as|by) its body" R man NEWS.md cairn/DESIGN.md`.
      The `nested_final_fit()` help page, the DESIGN.md Architecture paragraph
      on the identity and one NEWS.md bullet each state what is now read. Each
      also names the two limits that remain: a value reached indirectly, and a
      closed-over environment.
- [ ] AC6: The profile's verify slot is clean and so is the fuller pre-review
      check. `devtools::test()` is clean. `devtools::document()` leaves no
      diff. `benchmarks/sweep-prose.R --plain` and `--roxygen --plain` are
      clean. `devtools::check()` reports 0 errors, 0 warnings, 0 notes.

## Coverage

- AC1 → T2, T3, T4
- AC2 → T1, T3, T7
- AC3 → T6
- AC4 → T5
- AC5 → T8
- AC6 → T9

## Tasks

- [ ] T1: Write the regression test and make sure that it fails on main first.
      Two workflows built by the same code whose `step_mutate_at(fn = )`
      closes over different values have `identical()` identities
      (`tests/testthat/test-workflow-identity.R`), and the final fit accepts
      the wrong one (`tests/testthat/test-nested-final-fit-identity.R`).
      Record which failure each one is before any source change.
- [ ] T2: Add `codetools` to `DESCRIPTION` Imports, called as `codetools::`
      with no NAMESPACE import. D-066 is already recorded.
- [ ] T3: Write `closure_identity()` in `R/workflow-identity.R`. It holds the
      primitive short-circuit, the `findGlobals()` names, the resolution walk
      and its three skips, name order, and the two-part entry. `deparse_one()`
      routes any function through it (`R/workflow-identity.R:154`). That is
      what covers step settings, nested `options` and adjustment arguments at
      one site.
- [ ] T4: Make the no-binding case return today's single string. The
      branch-point fixture and the data-size independence assertions
      (`test-workflow-identity.R:132-143`) stay green.
- [ ] T5: Add the 2,048-character bound and the `rlang::hash()` fallback.
- [ ] T6: Make `identity_difference()` and `identity_part()`
      (`R/checks.R:1885`) name the read binding that differs, and show or
      withhold the two forms. Add a test on the rendered message.
- [ ] T7: Add the AC2 family in `test-workflow-identity.R`, and the refusal
      path in `test-nested-final-fit-identity.R`.
- [ ] T8: Correct the prose at every site the AC5 sweep reports, at the
      DESIGN.md Architecture identity paragraph, and in one NEWS.md bullet.
      Then run `document()` and the two prose sweeps.
- [ ] T9: Run the full local gate: test, check, `document()` with no diff,
      `air`, every gating sweep, and `cairn_validate`.

## Work log

- 2026-09-20: created by /milestone-plan.
- 2026-09-20: criteria audit ran in full mode (fresh Opus reader, user-facing tier). It returned eleven findings. Nine were fixed before the gate: the deparsed form is the whole function and not its body, AC2's and AC4's promises were unbounded, the message clause and the size clause contradicted each other, two of three named prose sites do not hold the sentence they were told to delete while two unnamed sites do, no digest procedure was named, one clause duplicated an existing assertion, and the evidence was a single exemplar. Two were posed at the gate.
- 2026-09-20: plan gate chose reading the names a static scan reports over expanding the whole closure environment, because a function built inside another captures that frame and the training data with it, which breaks the data-independence the identity holds today. Falsified by a user report of a false pass whose value is reached only indirectly.
- 2026-09-20: plan gate chose `codetools` over a hand-rolled `all.vars()` walk, because the walk over-collects names also bound locally and can refuse the workflow that is in fact right. Falsified by codetools being unavailable on a platform this package supports.
- 2026-09-20: plan gate chose a fingerprint above the size bound over skipping a large value, because skipping reopens the gap this milestone closes. Falsified by the fingerprint differing between two constructions of one value.
- 2026-09-20: plan gate chose leaving the record unchanged where a function reads nothing over one new shape everywhere, because saved records stay valid. Falsified by the two shapes costing a defect the single shape avoids.
- 2026-09-20: plan chose changing `deparse_one()` once over a change scoped to recipe step settings, because the one site covers nested step options and adjustment arguments too. Falsified by a function-valued part of the identity whose closure must not be read.

## Decisions

## Review
