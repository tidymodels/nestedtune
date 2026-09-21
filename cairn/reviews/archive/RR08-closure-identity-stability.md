# RR08: Closure identity stability across sessions (answers RB08, M105)

- **Date:** 2026-09-20
- **Reviewed at:** branch `m105-identity-closure-values`, commit `176ea6e`
- **Advisory:** binding criteria were not requested and none are given

## Summary

The identity of a function-valued setting cannot be made stable across
sessions for the domain the feature covers. Two of the seven mechanisms
are not properties of the function. Enclosure mutation (1) is a property
of when the closure last ran. Non-standard evaluation (4) is a property
of what the callees do with the names the function writes down. No
recorder of live values decides either one from the function. The other
five mechanisms close under a different serializer and a shallower walk.
Q1 gives that construction. Closing them still leaves a check that
refuses a user their own workflow on the two that remain. The fixed
ranking says a false refusal is the worst failure, and there is no
bypass. So the feature does not earn its complexity. The recommendation
is to revert M105 to the text-only comparison and to keep one help-page
sentence on what that misses. Separately, pin the printing options that
mechanisms 3 and 7 depend on. Those options reach the pre-M105 identity
too (Beyond the brief, B1).

## Q1. Can the identity be made stable across sessions and serialization while still distinguishing values and never capturing data?

Not for the general domain. It can for a narrower one. That narrower
domain is not decidable by a procedure over the function, which is what
Q7 turns on.

The reason is what fixes "what the procedure computes" for a closure.
The recipe evaluates the closure at fit time. Three things fix the
result at that moment: the code, the values in the environment chain,
and what the callees do with the names the code writes down. A recorder
sees the code exactly. It sees the values only as a snapshot at record
time. Record time is not fit time, and it is not rebuild time in the next
session. It does not see the callees' semantics at all.
`codetools::findGlobals()` is a syntactic scan. In `subset(dd, x > 1)`,
`x` looks the same whether it is a column or a free variable. Mechanism 1
lives in the second gap. Mechanism 4 lives in the third. A better
serializer, a better cycle guard or a better record moment closes
neither gap. Both gaps follow from reading live values at all.

The construction that closes the other five is given here so the trade
is concrete.

1. **Names.** Take `codetools::findGlobals(fn)`. A name is kept once it
   resolves through the enclosing chain to an environment that is not
   opaque (as now) and is not the global environment. Excluding the
   global environment makes mechanism 4 rare rather than common. A
   data-masked column name leaks from the session's top level, and a
   builder frame seldom holds a binding with a column's name. The cost
   is large. The most common real use is `k <- 2` at top level followed
   by `function(x) x * k`, and that use is no longer compared by value.
   That cost is most of the feature's benefit. This construction is
   offered for completeness and is not recommended.
2. **Values.** Split the recorded form into a comparison key and a
   display string. Never compare the display string. The key is
   `rlang::hash()` over the value after a canonicalization: strings run
   through `enc2utf8()`, and attributes other than `names` are dropped.
   The display string is `deparse()` under pinned options, cut to a fixed
   width. Verified here: a UTF-8-marked string parsed from a script
   hashes to `af1bdc66...` under both `en_US.UTF-8` and `C`. Its
   `deparse()` reads `"café"` under one and `"caf<U+00E9>"` under the
   other. The hash is over the IEEE bytes and the marked bytes, not over
   a rendering, so this closes 3, 5 and 7 for the comparison. Note that
   `-0` and `0` are `identical()` in R and hash alike. Leaving them as
   one value is correct. `control = "digits17"` tells them apart, which
   is the wrong direction.
3. **Value domain.** Take the key only for plain data: `NULL`, an atomic
   vector, or an unclassed list of plain data. Record anything else as a
   marker naming its class, and never enter it. That covers a function,
   an environment, a classed object, an external pointer, an active
   binding and an unforced promise. Record a function-valued binding as
   its text alone, one level down and no further. This removes
   `read_depth`, `new_walk()`, the address-keyed `seen`, the cache and
   the cut counter. Nothing keys on an address any more, so mechanism 2
   goes with them. Mechanism 6's gate goes too, because a classed
   container is opaque rather than deparsed whole. The walk cost from the
   second pass (24 seconds at sixteen levels) goes with it.
4. **No evaluation.** Record an unforced promise as the marker. Do not
   force it. Recording then runs no user code and leaves `.Random.seed`
   alone. Reproduced here: with a read binding that is a promise over
   `runif(1)`, the current code moves the seed. This reopens the second-pass
   problem. A record taken before the fit and a workflow built after it
   differ. The record must then also be taken before any fit (Q4).

What this closes: 2, 3, 5, 6, 7, and the RNG consumption the third pass
logged as finding 5. What it leaves: 1 and 4. Both are false-refusal
paths. Both survive any recorder of live values.

Nothing in the construction touches the training data. The key is fixed
length and the display string is cut, so the record's size does not grow
with any value. That is stronger than the present 2,048 character bound
on the deparsed form.

## Q2. If it cannot, what does this check compare instead?

**Deparsed text alone** (pre-M105). Stable across sessions once the
printing options are pinned (Q3). Small. Readable. It reads no
environment, so it cannot false-refuse on any of the seven mechanisms.
It misses a function whose text is unchanged over a changed closed-over
value. One sentence on the help page says so. This is the
recommendation.

**A normalized AST.** `deparse()` of a function without `useSource`
already deparses the parsed body, so comments and whitespace are gone.
Verified: `function(x)   x+1` deparses to `function (x)  x + 1`. An AST
adds independence from printing options, and pinning the options gives
that more cheaply. It adds nothing on values. Reject as a separate
option. It is text with the options pinned.

**A hash of the text plus an explicitly declared set of values.** This is
the only value-aware design whose domain is decided rather than
discovered. The user names the bindings to compare. A masked column name
is never named. A memo cache is named only by a user who wants it
compared. The recorder resolves the declared names through the closure's
environment with the Q1 serializer. When a declared name does not
resolve, the recorder refuses to record. The cost is an API surface: a
place to declare, carried on the workflow. That is an attribute on the
function, or a control option keyed by setting. Both the run and the
final fit then read the same declaration. It is sound. When a user asks
for value comparison, this is the right shape. The record so far shows no
user asking. Consider it as a roadmap candidate, not now.

**Refusing to compare function-valued settings at all.** This loses the
text comparison. The text comparison is cheap and sound, and it catches
a rewritten function. Reject.

A variant worth naming: text-only comparison, plus a read-binding
difference demoted from refusal to a warning. Q5 arrives at this for a
feature that stays. GP3 refuses provably invalid designs. A read-binding
difference is not provably anything, since a masked name produces one
too. So a warning is consistent with GP3 where a refusal is not.

## Q3. Is pinning options and encoding inside `deparse_text()` a complete fix for 3, 5 and 7, or is deparse the wrong serializer?

Pinning is a complete fix for 7 and for the number half of 3. It is no
fix for 5. Deparse is the wrong comparator for strings and the right
renderer for messages. Separate the two jobs.

Evidence, run on R 4.6.1 in this tree:

- `deparse(1e5)` is `1e+05` at `scipen = 0` and `100000` at
  `scipen = 100`. `control = "digits17"` does not change that.
  `control = "hexNumeric"` does (`0x1.86ap+16`), at the cost of
  readability. Pinning `scipen` with `options()` around the call fixes 7
  for every setting. `OutDec` does not reach `deparse()`.
- `deparse(0.1 + 0.2)` is `0.3` by default and `0.30000000000000004`
  under `digits17`. So `digits17` fixes mechanism 3 with a readable form.
  But `identical(-0, 0)` is `TRUE`, and `rlang::hash()` agrees. The `-0`
  case in the brief's list is not a genuine difference. A serializer
  that tells them apart introduces a new false refusal.
- No `deparse()` control pins string escaping. The escapes come from
  `encodeString()`, which follows `l10n_info()`. To get one form under
  both locales, compare something other than the rendering.

So: for comparison, hash the canonical value (Q1 item 2). For display,
deparse under `options(scipen = 0)` with the default `control` plus
`digits17`. Record both. Compare only the hash. Print only the display.
The recorded form stays small (32 hex characters plus a cut string),
readable in the message, and data-free by construction.

Two things follow. First, the split is worth doing without M105. Every
leaf of the identity goes through `deparse_text()`. A model argument
written `1e5` already records differently under a `.Rprofile` that sets
`scipen` (B1). Second, the present `deparse()` is fine for the display
string. A rendering that differs across locales is harmless once nothing
compares it.

## Q4. Is recording the identity before any fold runs a sound fix for mechanism 1, and what does it break?

It is necessary and not sufficient. It breaks nothing in the present API.

Necessary: with recording after dispatch, a sequential run mutates the
closure in the main process. The record then holds the post-run state.
The user's fresh workflow holds the pre-run state. Moving the record
ahead of `dispatch_folds()` makes the two moments the same for that run.
`nested_final_fit()` already checks before it fits, so that side is in
the right place.

Not sufficient: the feature promises that a workflow rebuilt in a later
session is accepted. Suppose the user warmed a memo closure before
saving the results object, by calling it or by prepping the recipe by
hand. The record holds the warmed state. The rebuilt closure in the next
session is cold. No moment in the run fixes that, because the divergence
happened before the run. The same holds for a counter or a lazily
computed constant. Mechanism 1 is a property of the closure's history,
not of the run's ordering.

What it interacts with: recording currently forces promises, and so it
can draw from the stream (Q1 item 4). Suppose the record moves ahead of
the seed draw in `nested_tune_grid()`. A run then draws different seeds
than a record taken later, and same-seed reproduction against results
saved under the current branch breaks. Pre-1.0 allows that. It is still
a reason the record must not evaluate anything once it moves.

The final fit's own records at `R/nested-final-fit.R` lines 425 and 477
are taken after fitting. Nothing compares them. The only readers are
`extract_procedure()` and the print method. A grep over `R/` finds no
second comparison site. They are still wrong by the same reasoning. A
user who compares `extract_procedure(fit)$workflow` with
`extract_procedure(results)$workflow` sees them differ after a mutating
closure. When the feature stays, the fix is to take the identity once at
line 343, before the check, and pass it to both `new_procedure()` calls.
Under the recommended revert this goes away, because text does not
change with fitting.

## Q5. Is there a sound way to tell a data-masked name from a genuine free variable?

No. The callee decides masking at run time. `subset()`,
`dplyr::filter()`, `with()`, a formula, `bquote()`, `ggplot2::aes()`, and
any user function that calls `eval()` on a substituted argument all mask.
The callee is a value resolved at run time, so a static scan of the
closure cannot know it. Any list of masking functions is an enumeration
of the kind the criteria audits already rejected. The next tidyeval verb
makes it wrong. The `.data$x` convention lets a user disambiguate. It
cannot be required of a step's `fn`.

What the check can do, in order of soundness:

1. Read no values. This closes it. This is the revert.
2. Refuse only on the function's text. Warn on a read-binding
   difference. The user is told what the check saw and is not blocked.
   This is sound under the ranking and consistent with GP3, as argued
   under Q2.
3. Exclude the global environment from resolution (Q1 item 1). This
   makes it rare. It does not close it, and it gives up the common case.
4. Record a masked name as `<unavailable>` whenever it does not resolve,
   as the code does now. This is the false-refusal path itself. `x`
   resolves in the session that wrote the record and not in the one
   that reads it. Reproduced here: `function(dd) subset(dd, x > 1)`
   records `x = "1:3"` from a top-level `x`.

Option 4 is the current state, and it is the one that cannot stand.

## Q6. Is this mechanism to be removed?

Yes. Revert M105 to the text-only comparison. The feature does not earn
its complexity.

The cost side, from the branch: about 260 lines in
`R/workflow-identity.R` and the difference walk in `R/checks.R`. Add 700
lines of tests, a new import, three review passes, and seven open
mechanisms.
Add a help-page paragraph of ten caveats. A user must read all ten to
predict whether their own workflow is refused. Two of the mechanisms are
closed by no recorder (Q1). Both are false-refusal paths in a check with
no bypass.

The benefit side is narrower than the milestone's goal sentence
suggests. The identity's own header states its rule. It is "a check on
the code the user handed over and not a re-run of it". A model argument
`penalty = p` records `p` deliberately, not the value. M105 makes a
recipe function setting stricter than a model argument. The same user
habit, a name bound outside the workflow, is compared by value in one
place and by name in another. That is an inconsistency, not a closed
gap. A user who rebuilds from the same script over a different
closed-over value changed their script. The text-only check already
tells them the one thing it cannot see, in a sentence.

What the revert costs: the case the milestone opened for goes back to a
documented limit. The candidate row for it carries Q2's declared-values
design as the shape a future implementation takes. The next attempt then
does not start from live-value reading again. `codetools` leaves Imports
and D-066 is superseded. The rationale is that nothing reads names, so no
reader of names is needed. The radix ordering and the
attached-environment opacity added at the second pass are unneeded
without reads. They go with the rest. Keep the test that the
branch-point fixture still matches its workflow.

What the revert does not cost: the three ambient-printing mechanisms are
not M105's. Pin `scipen` regardless (B1).

## Q7. For a feature that stays, an acceptance criterion whose domain is decided by a procedure

A procedure-decided criterion exists for the recorder. None exists for
the property the feature is meant to provide. The difference between the
two is the false-refusal surface. That is why the feature is not to ship
in a refusing form.

The criterion that can be stated. Let `plain(v)` be a total predicate.
It holds for `NULL`, for an atomic vector with no attribute but `names`,
and for an unclassed list whose elements satisfy `plain`. Let `reads(f)`
be the names `codetools::findGlobals(f)` reports that resolve through
`f`'s enclosing chain to a non-opaque, non-global environment. Take any
function `f` and any two sessions S1 and S2. In each, the same source
text is evaluated to produce `f1` and `f2`. Allow any locale, any
`options()`, and a `saveRDS()` round trip of either. Then:

- (a) Suppose that for every name in `reads(f1)` the two resolved values
  are `identical()` after `enc2utf8()`. Then `closure_identity(f1)` is
  `identical()` to `closure_identity(f2)`.
- (b) Suppose some name in `reads(f1)` resolves to values that are not
  `identical()` and both satisfy `plain`. Then the two identities differ.
- (c) A name whose value does not satisfy `plain` is recorded as a marker
  naming its class. Two such values are not told apart.
- (d) Recording calls no function, forces no promise, and leaves
  `.Random.seed` unchanged.
- (e) The recorded form's size is bounded by a constant independent of
  every value.

A procedure decides every clause. `plain` is a type check. `reads` is
the scanner plus resolution. `identical()` is R's. Clauses (d) and (e)
are measurable. It is falsifiable in the direction the second audit
wanted. Under-recording is a violation of (b) on a concrete pair, not a
matter of what the recorder happened to produce.

Why it is not enough. Clause (a) quantifies over "the two resolved values
are `identical()`". That is a fact about the sessions, not about `f`.
Mechanism 1 makes the values differ between a session that ran the
closure and one that did not. Mechanism 4 makes a name resolve in one
session and not the other. In both, the criterion is satisfied. The
recorder did what it says, and the user is refused their own workflow.
The property the user cares about is "a workflow rebuilt from my script
is accepted". The criterion does not imply it. No added clause implies
it without quantifying over the callees' semantics and the closure's
history. No procedure over `f` decides those.

Implication. A refusing check needs the user-facing property. That
property has no procedure-decided criterion for this feature. So the
feature ships only in one of two forms. In the first, a read-binding
difference is demoted to a warning. The criterion above is then
sufficient, because a violation of the user-facing property costs a
warning and not a refusal. In the second, the user's declaration decides
the domain (Q2, option 3). `reads(f)` then becomes the declared set, and
clause (a) becomes a statement about names the user chose. The present
M105 ships in neither form. Given Q6, the recommendation is neither form
now.

## Beyond the brief

**B1. Mechanisms 3, 5 and 7 predate M105 and reach the whole identity.**
Every leaf goes through `deparse_text()`. That includes model arguments,
formula preprocessors and every recipe step setting. Reproduced: the
quosure `penalty * 1e5` deparses to `~penalty * 1e+05` at `scipen = 0`
and `~penalty * 100000` at `scipen = 100`. Suppose a user has
`options(scipen = 999)` in `.Rprofile` on one machine and not on another.
That user is refused a workflow with any such constant, on `main` today.
This is a user-visible bug independent of M105. It is the one concrete
fix this review asks for now. Set `scipen = 0` around the `deparse()`
call in `deparse_text()`, with `options()` and `on.exit()`, since `withr`
is not in Imports. The locale half (mechanism 5) cannot be pinned in
`deparse()`. It stays a documented limit under text-only comparison. The
hash-plus-display split closes it whenever value comparison returns.

**B2. Recording runs user code on the current branch.** `read_form()`
calls `get()`, which forces a promise. A promise over `runif(1)` moves
`.Random.seed` (reproduced). The comment at `R/nested-final-fit.R:336`
says the refusal leaves the generator untouched and then says it does
not. The help page and NEWS do not say the check evaluates anything.
Under the revert this is moot. For a feature that stays, it is a
fix-now, and Q1 item 4 is the fix.

**B3. The final fit's record is taken at a different moment from its
check.** Covered under Q4. Under the revert this is moot.

**B4. D-066's dependency claim.** `codetools` is a recommended package,
not base. It is present on every CRAN binary and on `rocker/r-ver`. It
is absent on `r-minimal` and on some HPC builds compiled without
recommended packages. Under the revert the point is moot. For a feature
that stays, the decision's falsification clause has real instances. That
clause reads "a platform this package supports where codetools is
absent". The decision then needs to say which platforms the package
supports.

**B5. The help page's limits paragraph is an enumeration.** The ten
sentences on `nested_final_fit()`'s page list the mechanisms found so
far. That is the shape the criteria audits rejected for the criterion.
A user cannot use it to predict a refusal. Each sentence names a
mechanism and not a rule. The text-only comparison needs one sentence.

## Recommendations

1. **Apply.** Revert M105 on its branch to the text-only comparison.
   `deparse_one()` returns `deparse_text(fn)` for a function.
   `closure_identity()` through `opaque_env()` are removed with their
   tests. Keep the branch-point fixture test. Restore the one help-page
   sentence: a function is compared by its text, so two functions with
   one text over different closed-over values are not told apart.
   Supersede D-066 and drop `codetools` from Imports. Mark M105
   descoped, not failed. The question it asked has an answer.
2. **Apply.** Pin `scipen = 0` inside `deparse_text()`. Add a test that
   the identity does not change under `options(scipen = 100)`. This is a
   pre-existing user-visible bug (B1). It belongs on its own hotfix, not
   on the M105 branch.
3. **Apply.** Add one roadmap candidate carrying Q2's declared-values
   design and the Q1 serializer split (hash for comparison, deparse for
   display). A future attempt then starts from a decided domain rather
   than from live-value reading.
4. **Consider.** Suppose the user wants some value awareness now. The
   only form this review endorses is a warning, not a refusal, on a
   read-binding difference, over the Q1 construction with the global
   environment excluded. Weigh it against one fact. Excluding the global
   environment removes the common case, so the warning fires rarely and
   the code costs the same.
5. **Consider.** Record the final fit's identity once, before its check,
   in any future version that records something that changes with
   fitting.
6. **Reject, with reason: a normalized AST.** It is deparse with the
   printing state pinned, and recommendation 2 does that directly.
7. **Reject, with reason: refusing to compare function settings at all.**
   The text comparison is sound and cheap, and it catches a rewritten
   function. Dropping it buys nothing.
8. **Reject, with reason: recording before dispatch as the fix for
   mechanism 1.** For a feature that keeps reads it is necessary. It does
   not reach a closure the user warmed before the run, so it cannot be
   the fix the criterion needs.
