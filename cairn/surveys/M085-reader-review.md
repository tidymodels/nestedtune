# M085 review-side reader pass (2026-09-11, review pass 2)

_Owned by M085 (AC3 (iv)). One fresh-context Opus reader, given the standard and the `tools::Rd2txt()` text of the 26 non-internal `man/*.Rd` pages at `af8c6ca`, withheld `M085-survey.md` and `M085-reader-implement.md`, reported each paragraph it would send back with a clause and a reason. Its 68 entries are listed as reported; the disposition of each is recorded by entry number in the milestone file's Review section, pass 2. The pass was taken once and not rerun after its fixes._

Entries: 68. Paragraphs read: 447 (Description, Details, Value, Arguments and custom-section bodies of all 26 pages; bullet items and indented code blocks counted as paragraphs by the stated rule).

## Most sure

1. nested_tune_grid.txt — "Nested designs: 'resamples' is a data frame with one row per outer fold." — (a) — Opens with a storage specification for an object the reader has not yet built; nothing here says why they would care or what they do with it. (Repeated verbatim in nested_tune_bayes.txt, nested_tune_race.txt, nested_tune_sim_anneal.txt, nested_fit_resamples.txt.)
2. nested_tune_grid.txt — "Inside each inner 'rset', every element of 'splits' is an 'rsplit'." — (c) — Four separate structural rules in three sentences, one carrying three ideas. (Repeated on the four sibling pages.)
3. nested_tune_grid.txt — "'param_info' is passed unchanged to the inner tuning call" — (b) — The problem (a data-dependent range can leak held-out rows) arrives in sentence three, after two sentences of plumbing and the term itself. (Repeated on the four sibling pages.)
4. nested_tune_grid.txt — "It is one rule, reached through four doors." — (a) — A metaphor about dispatch internals opens a paragraph answering no question the reader has; two to three ideas per sentence throughout.
5. nested_tune_grid.txt — "The result follows the rules tune states for its own" — (a) — Opens with a conformance claim, not with what the reader wants to do (manipulate the result and keep it valid).
6. nested_tune_grid.txt — "Two records describe the grid, and they answer" — (a) — Leads with an internal bookkeeping distinction; the reader's question (what did each fold actually search) is never put first.
7. nested_tune_grid.txt — "The same outer loop runs with other searches inside." — (a) — Leads with package architecture and introduces "orchestrators" before the reader has any reason to want a second tuner.
8. nested_final_fit.txt — "A workflow other than the one the estimate was built" — (c) — Opening sentence carries the refusal, the condition, and a comparison against tune's timing at once; the paragraph then switches to a different refusal.
9. nested_final_fit.txt — "'results' supplies the inner resampling specification" — (a) — Opens with a four-item inventory of what the function reads; the reader's action is nowhere in the lead.
10. nested_final_fit.txt — "Two things the estimate does not say. It is marginal" — (b) — "Marginal over selection" is asserted before the situation it warns about is stated.
11. nested_final_fit.txt — "A nested design stores its 'inside' argument as an" — (b) — Three sentences of evaluation mechanics before the next paragraph reveals the actual hazard (a stale `k` silently giving a different design).
12. collect_metrics.nested_results.txt — "That is a limit of the statistics, not of this" — (a) — Opens with a disclaimer about blame; the reader's question (can I put an interval on this) is buried.
13. collect_metrics.nested_results.txt — "Both results concern quantities close to this column" — (a) — Opens with scholarly scope-qualification, not with anything the reader does or decides.
14. collect_metrics.nested_results.txt — "A metric measured at several evaluation times ('eval_time'" — (c) — Five distinct facts in four sentences.
15. extract_procedure.txt — "Returns the 'procedure' record a nested result carries" — (b) — Names the record in the first three words; the reader has no reason yet to want one.
16. extract_procedure.txt — "A final fit built from a results object re-runs exactly" — (a) — The reader's use is the second sentence; it should be the first.
17. extract_tune_results.txt — "Returns the tuning result that 'nested_final_fit()' chose" — (b) — Leads with the stored object and the recorded procedure before saying why anyone would open it.
18. extract_scored_candidates.txt — "Returns the candidates, the parameter settings" — (b) — Leads with the object name and cross-refers to `.inner_metrics`, a column the reader has not met.
19. selection_rule.txt — "Builds the object the 'select' argument of" — (a) — Leads with the object it constructs; the reader's want (decide how each fold picks a setting) is never stated.
20. selection_rule.txt — "An ordering is a parameter name, wrapped in" — (b) — Defines the term before saying what goes wrong without one.
21. collect_metrics.nested_results_set.txt — "You read a 'nested_results_set', what" — (c) — First sentence carries an appositive definition, the class name, and the six-function claim; the second adds the binding mechanism.
22. collect_metrics.nested_results_set.txt — "A control reaches each workflow of a set through the" — (a) — Opens with control-propagation plumbing; the reader's situation (a collect call errors) is the consequence, not the lead.
23. nested_workflow_map.txt — "Each row's 'nested_results' describes its own run" — (a) — Opens with a justification for the rule rather than what the reader does.
24. nested_workflow_map.txt — "Anything else comes back a plain tibble without the" — (c) — One sentence lists five failure shapes, the next three more.
25. nested_fit_resamples.txt — "'nested_fit_resamples()' gives you the score of a" — (c) — Good lead, but six sentences each carry two ideas.
26. agreement.txt — "tune's '.config' is not a column here: it labels" — (b) — Names `.config` and denies its presence before saying the reader may come looking for it.
27. autoplot.nested_results.txt — "The subtitle gives how much of the requested design" — (a) — Opens with what the figure prints; the reader's question (why different fold counts per panel) is only implied.

## Fairly sure

28. autoplot.nested_results.txt — "The selected-value axis is numeric when every value" — (a) — Opens with an axis-type rule connected to no reader decision.
29. autoplot.nested_results.txt — "A run in which no fold completed is refused with class" — (b) — Three condition classes named before the situations they correspond to.
30. agreement.txt — "The most frequent combination is not the final model's" — (c) — Second sentence fuses a definition and a claim.
31. agreement.txt — "Every completed fold is counted once, so 'sum(n)' is" — (a) — Opens with an accounting invariant, not the reader's concern about failed folds.
32. agreement.txt — "A completed fold whose selection carries no value for" — (c) — Four unrelated edge cases in four sentences with no separation.
33. collect_selections.txt — "'collect_notes()', 'collect_selections()' and" — (c) — Lead names three functions; following sentences carry record, storage shape, and stacking rule together.
34. collect_selections.txt — "The first columns are the design's fold labels: 'id' on" — (a) — Opens with column provenance; the reader-relevant NA ambiguity is last.
35. collect_selections.txt — "The '.config' of a selection or an inner-metrics row" — (b) — Leads with the term and its storage; the problem (it means nothing across folds) comes third.
36. collect_predictions.nested_results.txt — "'collect_predictions()' and 'collect_extracts()' give" — (c) — Four sentences each combining a control slot, a column name, and what it holds.
37. collect_predictions.nested_results.txt — "They are the outer fit's, on each fold's assessment" — (a) — Opens on a pronoun and a storage fact; the reader's question (will a row appear twice) is second.
38. collect_predictions.nested_results.txt — "An object whose recorded control did not ask for the" — (b) — Two condition classes lead; the reader's actual experience is not stated as such.
39. nested_final_fit.txt — "Three shapes of 'results' are refused before any" — (c) — Each shape carries two or three causes in one sentence.
40. nested_fit_resamples.txt — "A 'nested_results' with one row per outer fold and the" — (c) — Seven distinct facts in six sentences.
41. nested_fit_resamples.txt — "The same '2 * n' seeds are drawn as on a tuned run." — (a) — Opens with an internal consistency claim; the reader's use (pairing a baseline) is not the lead.
42. nested_resamples.txt — "'rsample::analysis()' and 'rsample::assessment()'" — (a) — Opens with two function names; whether existing code keeps working is only the second sentence.
43. nested_tune_grid.txt — "Refused here, ahead of tune: anything that is not" — (a) — Opens with rejected inputs; the reason is buried mid-paragraph. (Repeated on bayes, race, sim_anneal.)
44. nested_tune_grid.txt — "The selection rule is applied without 'eval_time'." — (b) — States an implementation choice first; the reader's possible question is never posed.
45. nested_tune_grid.txt — "tune leaves the choice of candidate to a call you make" — (b) — Contrast with tune comes first; the problem is implied, not stated.
46. nested_tune_grid.txt — "The two diverge routinely. tune expands a size and may" — (c) — Seven facts, several sentences carrying two.
47. nested_tune_grid.txt — "Each fold is sent one copy of the data, not one per" — (c) — Serialization rationale and two design-specific outcomes fused across four sentences.
48. nested_tune_grid.txt — "Stopping a run is not a fold failure." — (c) — Cancellation class, parent class, console-interrupt behavior, RNG restoration and pool cleanup in five dense sentences.
49. nested_tune_bayes.txt — "Each fold generates its own space-filling set of" — (c) — First sentence carries generation, the generator function, scoring, the scoring function, and the seed.
50. nested_tune_race.txt — "Each fold's '.inner_metrics' holds every candidate its" — (c) — Six facts about `n`, the recorded grid, and absent candidates in six packed sentences.
51. nested_tune_sim_anneal.txt — "'iter = 0' is refused. finetune 1.3.0 iterates over" — (a) — Opens with a refusal and a version-specific off-by-one; the reader's concern (stopping early) surfaces halfway down.
52. nested_workflow_map.txt — "For each workflow the merged arguments are narrowed to" — (c) — Argument narrowing, control class rule, routing, and baseline options in one run.
53. summary.nested_results_set.txt — "The performance view's subtitle gives the workflow and" — (a) — Opens with what a subtitle prints, not the reader's question about two shortfall counts.
54. summary.nested_final_fit.txt — "The four counts are 'NULL' on a grid or a racing fit" — (a) — Opens with a NULL-ness rule about components the reader has not needed yet.
55. predict.nested_final_fit.txt — "'augment()' fences them instead." — (a) — Opens on a pronoun and an internal policy word; the reader's takeaway is last.

## Arguments items, judged on (c) only

56. nested_tune_grid.txt — `...`: "A control object from 'tune::control_grid()', passed" — (c) — Accepted class, required name, exclusion, and name-matching rule in one sentence. (Same shape in nested_tune_bayes, nested_tune_race, nested_tune_sim_anneal, nested_fit_resamples.)
57. nested_final_fit.txt — `object`: "The 'workflows::workflow()' the nested run was built" — (c) — Two alternative inputs plus a validation promise in two sentences.
58. nested_final_fit.txt — `...`: "Not used; must be empty. Everything the re-run needs" — (c) — Source of arguments, two examples, and the consequence in one sentence.
59. nested_final_fit.txt — `id`: "For a 'nested_results_set' as 'object', the 'wflow_id'" — (c) — Condition, value, another argument's state, and the default in two sentences.
60. nested_workflow_map.txt — `...`: "The orchestrator's arguments, every one named: the" — (c) — A four-part enumeration and three refusal conditions.
61. nested_fit_resamples.txt — `event_level`: "'\"first\"' (the default) or '\"second\"', naming which" — (c) — Level choice, the call it applies to, and an apposition naming that call, in one sentence.
62. nested_fit_resamples.txt — `object`: "A 'workflows::workflow()' with no parameter marked for" — (c) — Requirement, marker function, comparison, and refusal in two sentences.
63. nested_tune_bayes.txt — `initial`: "The number of candidates each fold scores before the" — (c) — Definition, lower bound, and a refusal of another input type in one sentence.
64. nested_tune_sim_anneal.txt — `iter`: "The number of search iterations, a whole number of at" — (c) — Definition, bound, and a cross-reference to a refusal in one sentence.
65. selection_rule.txt — `...`: "For '\"one_std_err\"' and '\"pct_loss\"', one or more bare" — (c) — Applicability, form, purpose, parity with tune, a requirement, and an exclusion in two sentences.
66. selection_rule.txt — `limit`: "For '\"pct_loss\"' only, the acceptable loss against" — (c) — Scope, meaning, units, type, default, and the other rules' refusal in two sentences.
67. print.nested_results.txt — `n`: "Number of fold rows to show, passed to tibble's" — (c) — Meaning, delegation, default, two option names, and `Inf` in two sentences.
68. predict.nested_final_fit.txt — `type, opts`: "Passed to 'workflows::predict.workflow()' unchanged." — (c) — Second sentence carries what `type` selects, two examples, and the NULL default.
