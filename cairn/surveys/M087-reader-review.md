# M087 reader review (pass 1, 2026-09-11)

## agreement

1. Rule 6.3: "Maximum 25 words per sentence."
   Text: "A tibble with one column per parameter any completed fold selected, then ‘n’, the number of completed folds that chose that combination, and ‘prop’, ‘n’ over the number of completed folds."
   Rewrite: "A tibble with one column per parameter that any completed fold selected. Then comes ‘n’, the number of completed folds that chose that combination. Then comes ‘prop’, which is ‘n’ over the number of completed folds."

2. Rule 4.2: "Do not omit words or use contractions to shorten sentences. Keep articles, keep "that"."
   Text: "Rows run from the largest ‘n’ down, ties in the order the combination first appears."
   Rewrite: "Rows run from the largest ‘n’ down. Ties stay in the order in which the combination first appears."

3. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
   Text: "A run with some folds failed is tabulated over the rest, with a warning saying so."
   Rewrite: "If some folds failed, the function tabulates the rest and warns you that it did so."

4. Rule 6.3: "Maximum 25 words per sentence."
   Text: "A completed fold whose selection carries no value for a parameter is counted under ‘NA’ for it, in the same row as a fold that selected ‘NA’."
   Rewrite: "A completed fold can carry no value for a parameter. The function counts that fold under ‘NA’, in the same row as a fold that selected ‘NA’."

5. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
   Text: "Looking for tune's ‘.config’?"
   Rewrite: "Do you want tune's ‘.config’?"

## autoplot.nested_results

6. Rule 6.3: "Maximum 25 words per sentence."
   Text: "‘autoplot()’ shows you whether the outer folds agreed, and how each scored: two views of a ‘nested_results’, both drawing one point per outer fold, with the folds in design order."
   Rewrite: "‘autoplot()’ shows you whether the outer folds agreed, and how each one scored. It gives two views of a ‘nested_results’. Each view draws one point per outer fold, in design order."

7. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
   Text: "both drawing one point per outer fold, with the folds in design order"
   Rewrite: "Each view draws one point per outer fold, in design order."

8. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
   Text: "Points at different heights mean they disagreed, so the tuning procedure is unstable on this data, which averaging the metrics hides."
   Rewrite: "Points at different heights mean that the folds disagreed. The tuning procedure is then unstable on this data. An average of the metrics hides that."

9. Rule 6.3: "Maximum 25 words per sentence."
   Text: "An outer fold that failed keeps its place on the x axis and draws no point, as does one that completed without recording a value for a parameter."
   Rewrite: "An outer fold that failed keeps its place on the x axis and draws no point. A fold that completed but recorded no value for a parameter does the same."

10. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
    Text: "Nothing is imputed and nothing leaves the axis, so the shortfall shows in the figure."
    Rewrite: "The plot imputes nothing and drops nothing from the axis, so the shortfall shows in the figure."

11. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
    Text: "A run in which no fold completed is refused with class ‘nestedtune_no_completed_folds’, as ‘collect_metrics()’, ‘agreement()’ and ‘nested_final_fit()’ refuse it."
    Rewrite: "If no fold completed, ‘autoplot()’ refuses the run with class ‘nestedtune_no_completed_folds’, as ‘collect_metrics()’, ‘agreement()’ and ‘nested_final_fit()’ do."

12. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
    Text: "A run in which no completed fold selected a parameter, such as a ‘nested_fit_resamples()’ result, is refused under ‘type = "parameters"’ with class ‘nestedtune_no_tuned_parameters’."
    Rewrite: "If no completed fold selected a parameter, as in a ‘nested_fit_resamples()’ result, ‘type = "parameters"’ refuses the run with class ‘nestedtune_no_tuned_parameters’."

13. Rule 6.3: "Maximum 25 words per sentence."
    Text: "Panels can draw on different fold counts, so each panel says how many folds stand behind it, and the subtitle says how much of the requested design ran."
    Rewrite: "Panels can draw on different fold counts. Each panel therefore says how many folds stand behind it, and the subtitle says how much of the requested design ran."

14. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
    Text: "A panel reading mtry (2 of 3 chose) or rmse (from 2 folds) had fewer than the run completed, and an unqualified one had them all."
    Rewrite: "A panel that reads mtry (2 of 3 chose) or rmse (from 2 folds) had fewer folds than the run completed. A panel with no such note had them all."

15. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
    Text: "A requested metric that no completed fold scored keeps an empty panel rather than disappearing."
    Rewrite: "A requested metric that no completed fold scored keeps an empty panel. The plot does not drop it."

## collect_metrics.nested_results

16. Rule 4.2: "Do not omit words or use contractions to shorten sentences. Keep articles, keep "that"."
    Text: "Reports the nested cross-validation estimate from a ‘nested_tune_grid()’ run or one of its siblings: what the tune-and-fit procedure achieves on data it never saw."
    Rewrite: "This method reports the nested cross-validation estimate from a ‘nested_tune_grid()’ run or one of its siblings. The estimate is what the tune-and-fit procedure achieves on data it never saw."

17. Rule 6.3: "Maximum 25 words per sentence."
    Text: "Summarized, there is one row per metric, with the mean across outer folds, the number of folds ‘n’ behind it, and the standard error of that mean."
    Rewrite: "The summarized shape has one row per metric. Each row holds the mean across outer folds, the number of folds ‘n’ behind it, and the standard error of that mean."

18. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
    Text: "Both shapes carry a ‘.eval_time’ column exactly when the run was scored by a dynamic or integrated survival metric, as tune's own ‘collect_metrics()’ does."
    Rewrite: "Both shapes carry a ‘.eval_time’ column exactly when a dynamic or integrated survival metric scored the run, as tune's own ‘collect_metrics()’ does."

19. Rule 6.3: "Maximum 25 words per sentence."
    Text: "Only the outer folds that completed are read, and ‘n’ counts the folds behind each row, so an estimate is never reported as though the whole design had run."
    Rewrite: "This method reads only the outer folds that completed, and ‘n’ counts the folds behind each row. So it never reports an estimate as though the whole design ran."

20. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
    Text: "Failed folds are dropped with a warning naming them."
    Rewrite: "This method drops the failed folds and warns you, and the warning names them."

21. Rule 9.1: "When a word-for-word replacement does not work, restructure the sentence."
    Text: "It is the class autoplot(), ‘agreement()’ and ‘nested_final_fit()’ refuse such an object with."
    Rewrite: "autoplot(), ‘agreement()’ and ‘nested_final_fit()’ refuse such an object with the same class."

22. Rule 6.3: "Maximum 25 words per sentence."
    Text: "‘std_err’ is the standard error of the mean across outer folds: the standard deviation of the per-fold scores over the square root of how many there were."
    Rewrite: "‘std_err’ is the standard error of the mean across outer folds. It is the standard deviation of the per-fold scores, divided by the square root of the fold count."

23. Rule 4.2: "Do not omit words or use contractions to shorten sentences. Keep articles, keep "that"."
    Text: "That limit is the statistics', not this implementation's."
    Rewrite: "That limit comes from the statistics, not from this implementation."

24. Rule 9.4: "Keep one consistent style and terminology through the whole document." (Word Choice: "since (= because) → because")
    Text: "Outer fold scores are not independent, since any two folds share most of their training rows."
    Rewrite: "Outer fold scores are not independent, because any two folds share most of their training rows."

25. Rule 4.2: "Do not omit words or use contractions to shorten sentences. Keep articles, keep "that"."
    Text: "A standard error computed as though they were can misstate the uncertainty, usually downward."
    Rewrite: "A standard error that treats the scores as independent can misstate the uncertainty, and it usually states it too low."

26. Rule 6.3: "Maximum 25 words per sentence."
    Text: "Several of their test statistics with a variance-based denominator rejected a true null far above the nominal 5% they ran at, 36% and 40% in their worst cells."
    Rewrite: "Several of their test statistics used a variance-based denominator. These rejected a true null far above the nominal 5% they ran at, at 36% and 40% in the worst cells."

27. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
    Text: "It is reported because tune reports it, and no inferential claim is made with it."
    Rewrite: "This package reports the column because tune reports it, and it makes no inferential claim with it."

## collect_metrics.nested_results_set

28. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
    Text: "The rows are bound in the set's order over the union of the elements' columns."
    Rewrite: "Each method binds the rows in the set's order, over the union of the elements' columns."

29. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
    Text: "That function's own partial-run warning is raised once for it, with the workflow's id in front of the message."
    Rewrite: "That function raises its own partial-run warning once for the workflow, and puts the workflow's id in front of the message."

30. Rule 4.2: "Do not omit words or use contractions to shorten sentences. Keep articles, keep "that"."
    Text: "A workflow in which no fold completed is left out while another workflow completed one, warned about with class ‘nestedtune_partial_summary’."
    Rewrite: "If no fold of a workflow completed, and another workflow completed one, the method leaves that workflow out. It warns you with class ‘nestedtune_partial_summary’."

31. Rule 9.4: "Keep one consistent style and terminology through the whole document." (Word Choice: "since (= because) → because")
    Text: "since a failed workflow's notes are the reason to ask"
    Rewrite: "because a failed workflow's notes are the reason to ask"

32. Rule 6.3: "Maximum 25 words per sentence."
    Text: "‘collect_notes()’ is the exception: it reads every workflow, including those in which no fold completed, and refuses nothing, since a failed workflow's notes are the reason to ask."
    Rewrite: "‘collect_notes()’ is the exception. It reads every workflow, and a workflow in which no fold completed too. It refuses nothing, because a failed workflow's notes are the reason to ask."

33. Rule 3.4: "No auxiliary verbs for complex constructions. No present perfect, no "is to be installed"."
    Text: "so one workflow can have kept what another did not"
    Rewrite: "so one workflow can keep what another did not keep"

34. Rule 6.3: "Maximum 25 words per sentence."
    Text: "A control reaches each workflow of a set through the call's ‘...’ or through its own ‘option’ entry, so one workflow can have kept what another did not."
    Rewrite: "A control reaches each workflow of a set through the call's ‘...’ or through its own ‘option’ entry. So one workflow can keep what another did not keep."

35. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
    Text: "An element's table that already has a ‘wflow_id’ column, a parameter given that id, is refused with class ‘nestedtune_collect_name_collision’."
    Rewrite: "If an element's table already has a ‘wflow_id’ column, because a parameter carries that id, the method refuses it with class ‘nestedtune_collect_name_collision’."

## collect_predictions.nested_results

36. Rule 4.2: "Do not omit words or use contractions to shorten sentences. Keep articles, keep "that"."
    Text: "‘collect_extracts()’ gives one row per completed fold, the fold's value in an ‘.extracts’ list column."
    Rewrite: "‘collect_extracts()’ gives one row per completed fold. Each row holds the fold's value in an ‘.extracts’ list column."

37. Rule 1.7: "Do not use technical nouns as verbs."
    Text: "A completed fold whose extract function errored holds ‘NULL’ there, and its ‘.notes’ say why."
    Rewrite: "If a fold's extract function raised an error, the completed fold holds ‘NULL’ there, and its ‘.notes’ say why."

38. Rule 1.7: "Do not use technical nouns as verbs."
    Text: "They warn once with class ‘nestedtune_partial_summary’ on a partial run and error with class ‘nestedtune_no_completed_folds’ when no fold completed."
    Rewrite: "On a partial run they warn once with class ‘nestedtune_partial_summary’. If no fold completed, they raise an error with class ‘nestedtune_no_completed_folds’."

39. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
    Text: "An object whose recorded control did not ask for the column, or that no longer carries it, is refused with class ‘nestedtune_column_not_saved’."
    Rewrite: "If the recorded control did not ask for the column, or the object no longer carries it, these methods refuse the object with class ‘nestedtune_column_not_saved’."

40. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
    Text: "A prediction table carrying a column named like a fold label column is refused with class ‘nestedtune_collect_name_collision’."
    Rewrite: "If a prediction table carries a column with the name of a fold label column, the method refuses it with class ‘nestedtune_collect_name_collision’."

41. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
    Text: "The inner tuning run's own predictions and extracts, which the same two control slots save inside tune, are not kept."
    Rewrite: "This package does not keep the inner tuning run's own predictions and extracts, which the same two control slots save inside tune."

## collect_selections

42. Rule 4.2: "Do not omit words or use contractions to shorten sentences. Keep articles, keep "that"."
    Text: "Each function stacks one column across the folds, the design's fold labels first, so every row says which fold it came from."
    Rewrite: "Each function stacks one column across the folds and puts the design's fold labels first. So every row says which fold it came from."

43. Rule 9.4: "Keep one consistent style and terminology through the whole document." (Word Choice: "since (= because) → because")
    Text: "A ‘nested_fit_resamples()’ result gives no rows, since no fold selected anything."
    Rewrite: "A ‘nested_fit_resamples()’ result gives no rows, because no fold selected anything."

44. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
    Text: "read from the object's record rather than recognized by name"
    Rewrite: "The function reads these labels from the object's record. It does not recognize them by name."

45. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
    Text: "A fold lacking one holds ‘NA’ there, exactly as a fold whose recorded value is ‘NA’ does, so the two cannot be told apart."
    Rewrite: "A fold that has no such column holds ‘NA’ there. A fold whose recorded value is ‘NA’ holds the same, so you cannot tell the two apart."

46. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
    Text: "A stacked table carrying a column named like a label column, say a parameter whose id is ‘id’, is refused with class ‘nestedtune_collect_name_collision’."
    Rewrite: "A stacked table can carry a column with the name of a label column, for example a parameter whose id is ‘id’. The function refuses that table with class ‘nestedtune_collect_name_collision’."

47. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
    Text: "A run with some folds failed is stacked over the rest, with one warning of class ‘nestedtune_partial_summary’ naming the missing folds."
    Rewrite: "If some folds failed, the function stacks the rest. It warns once with class ‘nestedtune_partial_summary’, and the warning names the missing folds."

48. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
    Text: "The ‘.config’ of a selection or an inner-metrics row is kept as the fold recorded it."
    Rewrite: "These functions keep the ‘.config’ of a selection or an inner-metrics row as the fold recorded it."

49. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
    Text: "So a selected row's ‘.config’ is found among the same fold's rows in ‘collect_inner_metrics()’."
    Rewrite: "So you find a selected row's ‘.config’ among the same fold's rows in ‘collect_inner_metrics()’."

50. Rule 9.4: "Keep one consistent style and terminology through the whole document." (Word Choice: "since (= because) → because")
    Text: "Since folds can search different candidates, it identifies nothing across them, which is why ‘agreement()’ leaves it out."
    Rewrite: "Because folds can search different candidates, ‘.config’ identifies nothing across them. That is why ‘agreement()’ leaves it out."

## extract_procedure

51. Rule 4.2: "Do not omit words or use contractions to shorten sentences. Keep articles, keep "that"."
    Text: "Returns the ‘procedure’ record a nested result carries, the tune, select and fit steps as they were set."
    Rewrite: "This function returns the ‘procedure’ record that a nested result carries. The record holds the tune, select and fit steps as the call set them."

52. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
    Text: "Passing an argument here raises an error instead of leaving it silently ignored."
    Rewrite: "If you pass an argument here, the function raises an error. It does not ignore the argument in silence."

53. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
    Text: "Reading this record is how you see what a final fit will do before you ask for one."
    Rewrite: "Read this record to see what a final fit will do before you ask for one."

54. Rule 4.2: "Do not omit words or use contractions to shorten sentences. Keep articles, keep "that"."
    Text: "The stored record, unchanged: a named list with ‘tuner’, that tuner's own arguments, the arguments every loop function shares, ‘control’ as it took effect, and the ‘workflow’ identity."
    Rewrite: "The function returns the stored record, unchanged. It is a named list with ‘tuner’, that tuner's own arguments, the arguments every loop function shares, ‘control’ as it took effect, and the ‘workflow’ identity."

55. Rule 4.2: "Do not omit words or use contractions to shorten sentences. Keep articles, keep "that"."
    Text: "‘control’ is the control object the run was given, or tune's default when none was, with the slots this package forces already applied."
    Rewrite: "‘control’ is the control object that you gave the run, or tune's default when you gave none. The slots this package forces are already applied to it."

56. Rule 9.4: "Keep one consistent style and terminology through the whole document." (Word Choice: "since (= because) → because")
    Text: "A ‘"fit_resamples"’ record carries no ‘param_info’ and no ‘select’, since no parameter set was read and no rule applied."
    Rewrite: "A ‘"fit_resamples"’ record carries no ‘param_info’ and no ‘select’, because the run read no parameter set and applied no rule."

57. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
    Text: "On a Bayesian result ‘seed’ is left out."
    Rewrite: "On a Bayesian result the record leaves ‘seed’ out."

58. Rule 6.3: "Maximum 25 words per sentence."
    Text: "‘workflow’ is the identity of the model specification and the preprocessor the run was given: the model's type, engine, mode and arguments, and the preprocessor, each in deparsed form."
    Rewrite: "‘workflow’ is the identity of the model specification and the preprocessor that you gave the run. It holds the model's type, engine, mode and arguments, and the preprocessor, each in deparsed form."

59. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
    Text: "A recipe is held as its steps in order, with each step's selectors and settings, and its random step ids left out."
    Rewrite: "The record holds a recipe as its steps in order, with each step's selectors and settings. It leaves the random step ids out."

60. Rule 4.2: "Do not omit words or use contractions to shorten sentences. Keep articles, keep "that"."
    Text: "The workflow object itself is not stored, and no data rows are."
    Rewrite: "The record does not store the workflow object itself, and it stores no data rows."

## extract_scored_candidates

61. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
    Text: "Passing an argument here raises an error instead of leaving it silently ignored."
    Rewrite: "If you pass an argument here, the function raises an error. It does not ignore the argument in silence."

62. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
    Text: "It is derived the same way, so the two can be compared directly."
    Rewrite: "This function derives it the same way, so you can compare the two directly."

63. Rule 4.2: "Do not omit words or use contractions to shorten sentences. Keep articles, keep "that"."
    Text: "So a candidate has one row here however many evaluation times it was scored at."
    Rewrite: "So a candidate has one row here, whatever the number of evaluation times that scored it."

64. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
    Text: "A fit that ran no tuning scored no candidate and is refused with condition class ‘nestedtune_no_tuning_run’."
    Rewrite: "A fit that ran no tuning scored no candidate. This function refuses it with condition class ‘nestedtune_no_tuning_run’."

65. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
    Text: "A ‘grid’ given as a size is expanded by tune, and the expansion sometimes reaches fewer candidates than the number requested."
    Rewrite: "tune expands a ‘grid’ that you give as a size. The expansion sometimes reaches fewer candidates than you requested."

## extract_tune_results

66. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
    Text: "Passing an argument here raises an error instead of leaving it silently ignored."
    Rewrite: "If you pass an argument here, the function raises an error. It does not ignore the argument in silence."

67. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
    Text: "A fit that ran no tuning is refused with condition class ‘nestedtune_no_tuning_run’."
    Rewrite: "This function refuses a fit that ran no tuning, with condition class ‘nestedtune_no_tuning_run’."

68. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
    Text: "Each of them was computed on the resamples that chose the parameter setting it describes."
    Rewrite: "The run computed each of them on the resamples that chose the parameter setting it describes."

69. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
    Text: "This run is kept because it is the record of what selection saw, not because it describes the model."
    Rewrite: "This package keeps the run because it is the record of what selection saw. The run does not describe the model."

## extract_workflow.nested_results_set

70. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
    Text: "An ‘id’ naming no row of the set is refused with class ‘nestedtune_unknown_id’."
    Rewrite: "If an ‘id’ names no row of the set, this function refuses it with class ‘nestedtune_unknown_id’."

## nested_final_fit

71. Rule 6.3: "Maximum 25 words per sentence."
    Text: "That means it rebuilds the inner resamples on every row, tunes with the recorded tuner, selects by the recorded ‘selection_rule()’, and fits the finalized workflow on all the data."
    Rewrite: "It rebuilds the inner resamples on every row and tunes with the recorded tuner. Then it selects by the recorded ‘selection_rule()’ and fits the finalized workflow on all the data."

72. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
    Text: "A workflow is checked against the record before anything is fitted."
    Rewrite: "This function checks a workflow against the record before it fits anything."

73. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
    Text: "Everything the re-run needs is read from it."
    Rewrite: "The re-run reads everything it needs from this object."

74. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
    Text: "so passing an argument here is an error"
    Rewrite: "so an argument that you pass here is an error"

75. Rule 4.2: "Do not omit words or use contractions to shorten sentences. Keep articles, keep "that"."
    Text: "‘NULL’, the default, for a plain workflow."
    Rewrite: "For a plain workflow, use ‘NULL’, which is the default."

76. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
    Text: "So the final model comes from running it again with nothing held out: the same convention as cross-validating a model and then refitting on everything, one level up."
    Rewrite: "So this function runs the procedure again and holds nothing out. That is the convention one level up, where you cross-validate a model and then refit it on everything."

77. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
    Text: "They are not pooled or voted on to build this model."
    Rewrite: "This function does not pool the selections or vote on them to build the model."

78. Rule 9.4: "Keep one consistent style and terminology through the whole document." (Word Choice: "since (= because) → because")
    Text: "A ‘param_info’ parameter whose range is unknown until the data is seen is finalized here on the full data, since every row is this model's training data."
    Rewrite: "Some ‘param_info’ ranges are unknown until the function reads the data. This function finalizes such a range on the full data, because every row is this model's training data."

79. Rule 6.3: "Maximum 25 words per sentence."
    Text: "Each outer fold of the nested run finalized it on that fold's analysis rows alone, so this model's candidate range can be wider than any fold's."
    Rewrite: "Each outer fold of the nested run finalized it on that fold's analysis rows alone. So this model's candidate range can be wider than any fold's range."

80. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
    Text: "A run in which some folds failed is still fitted."
    Rewrite: "This function still fits a run in which some folds failed."

81. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
    Text: "A workflow whose model or preprocessor differs from the one the estimate was built around is refused here, before anything is fitted."
    Rewrite: "This function refuses a workflow whose model or preprocessor differs from the one the estimate describes. It refuses before it fits anything."

82. Rule 9.4: "Keep one consistent style and terminology through the whole document." (Word Choice: "since (= because) → because")
    Text: "since the argument is recorded as written"
    Rewrite: "because the record holds the argument as written"

83. Rule 6.3: "Maximum 25 words per sentence."
    Text: "A recipe setting that is a function is compared as its body, so two functions with one body that close over different values are not distinguished either."
    Rewrite: "The comparison reads a recipe setting that is a function as its body. So it does not tell apart two functions with one body that close over different values."

84. Rule 6.3: "Maximum 25 words per sentence."
    Text: "One carries no record: it was built by an earlier version of nestedtune, or from a design assembled by hand rather than by ‘nested_resamples()’ or ‘rsample::nested_cv()’."
    Rewrite: "One carries no record. An earlier version of nestedtune built it, or it came from a design that you assembled by hand instead of with ‘nested_resamples()’ or ‘rsample::nested_cv()’."

85. Rule 6.3: "Maximum 25 words per sentence."
    Text: "A set given with ‘results’ supplied, a set given with no ‘id’, and an ‘id’ given beside a plain workflow are each refused with class ‘nestedtune_bad_final_fit_args’."
    Rewrite: "This function refuses three calls with class ‘nestedtune_bad_final_fit_args’: a set with ‘results’ supplied, a set with no ‘id’, and an ‘id’ beside a plain workflow."

86. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
    Text: "Two seeds are drawn on entry and applied with the generator kind pinned: the first builds the inner resamples and tunes, the second fits."
    Rewrite: "The function draws two seeds on entry and applies them with the generator kind pinned. The first seed builds the inner resamples and tunes, and the second fits."

87. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
    Text: "Both are kept on the object, and the caller's generator state is put back on the way out."
    Rewrite: "The function keeps both seeds on the object, and it puts your generator state back on the way out."

88. Rule 9.4: "Keep one consistent style and terminology through the whole document." (Word Choice: "since (= because) → because")
    Text: "Expect the nested estimate to run slightly pessimistic instead, since each outer fold trained on its analysis rows alone."
    Rewrite: "Expect the nested estimate to run slightly pessimistic instead, because each outer fold trained on its analysis rows alone."

89. Rule 6.3: "Maximum 25 words per sentence."
    Text: "Varma and Simon (2006) measured a 4.2-point overshoot at n = 40, and Wilimitis and Walsh (2023) about 1 to 2 percent of AUROC on 41,121 records."
    Rewrite: "Varma and Simon (2006) measured a 4.2-point overshoot at n = 40. Wilimitis and Walsh (2023) measured about 1 to 2 percent of AUROC on 41,121 records."

90. Rule 4.2: "Do not omit words or use contractions to shorten sentences. Keep articles, keep "that"."
    Text: "Two things the estimate does not say."
    Rewrite: "There are two things that the estimate does not say."

91. Rule 6.3: "Maximum 25 words per sentence."
    Text: "If ‘k’ is gone by the time you call this you get an error naming the specification, and if some other ‘k’ is in scope you silently get a different design."
    Rewrite: "If ‘k’ is gone when you call this function, you get an error that names the specification. If some other ‘k’ is in scope, you get a different design with no message."

92. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
    Text: "But the first is consumed by nothing and the inner specification is left unevaluated."
    Rewrite: "But nothing consumes the first seed, and the function does not evaluate the inner specification."

93. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
    Text: "Building the resamples sits inside the first seed's scope rather than before it."
    Rewrite: "The function builds the resamples inside the first seed's scope, not before it."

94. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
    Text: "Building a design inside a function that parameterizes its resampling is the common way to meet this."
    Rewrite: "You meet this most often when you build a design inside a function that parameterizes its resampling."

## nested_fit_resamples

95. Rule 9.4: "Keep one consistent style and terminology through the whole document." (Word Choice: "since (= because) → because")
    Text: "It runs the outer loop of a nested design with the inner stage skipped, since there is nothing to search."
    Rewrite: "It runs the outer loop of a nested design and skips the inner stage, because there is nothing to search."

96. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
    Text: "Use it for the baseline a tuned procedure is compared against."
    Rewrite: "Use it for the baseline that you compare a tuned procedure against."

97. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
    Text: "A workflow carrying a marker is refused at entry."
    Rewrite: "If a workflow carries a marker, this function refuses it at entry."

98. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
    Text: "Anything not numeric, an empty vector, or an element that is missing, negative or not finite is refused at entry."
    Rewrite: "This function refuses at entry anything that is not numeric, an empty vector, and any element that is missing, negative or not finite."

99. Rule 4.2: "Do not omit words or use contractions to shorten sentences. Keep articles, keep "that"."
    Text: "‘.tuning_seed’ holds the seed the loop drew for the fold's tuning step, consumed by nothing."
    Rewrite: "‘.tuning_seed’ holds the seed that the loop drew for the fold's tuning step. Nothing consumes that seed."

100. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
     Text: "there being nothing to draw"
     Rewrite: "because there is nothing to draw"

101. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "The two seeds are kept on the result as ‘.tuning_seed’ and ‘.outer_fit_seed’, and ‘?nested_tune_grid’ shows how to reproduce one fold by hand from them."
     Rewrite: "The function keeps the two seeds on the result as ‘.tuning_seed’ and ‘.outer_fit_seed’. ‘?nested_tune_grid’ shows how to reproduce one fold by hand from them."

102. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "The caller's RNG state and generator kind are restored on exit, including when the call errors, so a seeded script that draws afterwards is unaffected."
     Rewrite: "The function restores your RNG state and generator kind on exit, and it does so when the call raises an error too. A seeded script that draws afterwards gives the same numbers."

103. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
     Text: "A design breaking any of this, or using a bootstrap for the outer loop, is refused before anything is fitted."
     Rewrite: "If a design breaks any of this, or uses a bootstrap for the outer loop, this function refuses it before it fits anything."

104. Rule 6.3: "Maximum 25 words per sentence."
     Text: "The checks exist because ‘rsample::nested_cv()’ builds a design whatever its ‘inside’ argument returned, and because a design assembled by hand can index rows its outer fold never sees."
     Rewrite: "The checks exist for two reasons. ‘rsample::nested_cv()’ builds a design whatever its ‘inside’ argument returned. A design that you assemble by hand can index rows that its outer fold never sees."

## nested_resamples

105. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "It is evaluated once per outer fold, so an existing object is refused."
     Rewrite: "This function evaluates it once per outer fold, so it refuses an object that you built already."

106. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "One behavior differs on purpose: an outer bootstrap is refused rather than warned about."
     Rewrite: "One behavior differs on purpose. This function refuses an outer bootstrap, where rsample only warns about one."

107. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "They were recorded on 2026-07-25 beside the check ‘tests/testthat/test-nested-resamples-memory.R’ makes of them:"
     Rewrite: "We recorded them on 2026-07-25, beside the check that ‘tests/testthat/test-nested-resamples-memory.R’ makes of them:"

## nested_tune_bayes

108. Rule 6.3: "Maximum 25 words per sentence."
     Text: "The grid page is the reference for everything the two share: the design, the seeds, failed folds, parallel execution and what an operation on the result does."
     Rewrite: "The grid page is the reference for everything the two share. That covers the design, the seeds, failed folds, parallel execution, and what an operation on the result does."

109. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "The estimate describes the whole search-and-fit procedure rather than any one model, and is reported for the procedure."
     Rewrite: "The estimate describes the whole search-and-fit procedure rather than any one model. Report it for the procedure."

110. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "A workflow with no marker is refused, and ‘nested_fit_resamples()’ scores one on the same design."
     Rewrite: "This function refuses a workflow with no marker. ‘nested_fit_resamples()’ scores such a workflow on the same design."

111. Rule 6.3: "Maximum 25 words per sentence."
     Text: "A ‘tune_results’ object is refused as ‘initial’ because one tuning run cannot serve every outer fold: its candidates were scored on resamples that can hold a fold's assessment rows."
     Rewrite: "This function refuses a ‘tune_results’ object as ‘initial’, because one tuning run cannot serve every outer fold. Its candidates were scored on resamples that can hold a fold's assessment rows."

112. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "‘param_info’ is passed unchanged to the inner tuning call on every outer fold, so a restricted range restricts what every fold searches."
     Rewrite: "This function passes ‘param_info’ unchanged to the inner tuning call on every outer fold. So a restricted range restricts what every fold searches."

113. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "A design from ‘rsample::nested_cv()’ already carries the analysis set and is passed as it is."
     Rewrite: "A design from ‘rsample::nested_cv()’ already carries the analysis set, and this function passes it as it is."

114. Rule 4.2: "Do not omit words or use contractions to shorten sentences. Keep articles, keep "that"."
     Text: "Refused here, ahead of tune: anything that is not numeric, an empty vector, and any element that is missing, negative or not finite."
     Rewrite: "This function refuses three things ahead of tune: a value that is not numeric, an empty vector, and any element that is missing, negative or not finite."

115. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "The selection rule is applied without ‘eval_time’."
     Rewrite: "Each fold applies the selection rule without ‘eval_time’."

116. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
     Text: "A design breaking any of this, or using a bootstrap for the outer loop, is refused before anything is fitted."
     Rewrite: "If a design breaks any of this, or uses a bootstrap for the outer loop, this function refuses it before it fits anything."

117. Rule 6.3: "Maximum 25 words per sentence."
     Text: "The checks exist because ‘rsample::nested_cv()’ builds a design whatever its ‘inside’ argument returned, and because a design assembled by hand can index rows its outer fold never sees."
     Rewrite: "The checks exist for two reasons. ‘rsample::nested_cv()’ builds a design whatever its ‘inside’ argument returned. A design that you assemble by hand can index rows that its outer fold never sees."

118. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "The caller's RNG state and generator kind are restored on exit, including when the call errors, so a seeded script that draws afterwards is unaffected."
     Rewrite: "The function restores your RNG state and generator kind on exit, and it does so when the call raises an error too. A seeded script that draws afterwards gives the same numbers."

## nested_tune_grid

119. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "No model is returned here."
     Rewrite: "This function returns no model."

120. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
     Text: "‘nested_final_fit()’ builds the model to deploy by running the recorded procedure once more on all the data, and that model has no performance number of its own."
     Rewrite: "‘nested_final_fit()’ runs the recorded procedure once more on all the data and builds the model to deploy. That model has no performance number of its own."

121. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "A workflow with no marker is refused, and ‘nested_fit_resamples()’ scores one on the same design."
     Rewrite: "This function refuses a workflow with no marker. ‘nested_fit_resamples()’ scores such a workflow on the same design."

122. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
     Text: "A design breaking any of this, or using a bootstrap for the outer loop, is refused before anything is fitted."
     Rewrite: "If a design breaks any of this, or uses a bootstrap for the outer loop, this function refuses it before it fits anything."

123. Rule 6.3: "Maximum 25 words per sentence."
     Text: "The checks exist because ‘rsample::nested_cv()’ builds a design whatever its ‘inside’ argument returned, and because a design assembled by hand can index rows its outer fold never sees."
     Rewrite: "The checks exist for two reasons. ‘rsample::nested_cv()’ builds a design whatever its ‘inside’ argument returned. A design that you assemble by hand can index rows that its outer fold never sees."

124. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "‘param_info’ is passed unchanged to the inner tuning call on every outer fold, so a restricted range restricts what every fold searches."
     Rewrite: "This function passes ‘param_info’ unchanged to the inner tuning call on every outer fold. So a restricted range restricts what every fold searches."

125. Rule 4.2: "Do not omit words or use contractions to shorten sentences. Keep articles, keep "that"."
     Text: "Refused here, ahead of tune: anything that is not numeric, an empty vector, and any element that is missing, negative or not finite."
     Rewrite: "This function refuses three things ahead of tune: a value that is not numeric, an empty vector, and any element that is missing, negative or not finite."

126. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "Here the choice is made inside every fold, so the rule is an argument."
     Rewrite: "Here every fold makes the choice, so the rule is an argument."

127. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "‘attr(x, "grid")’ holds the ‘grid’ argument as it was given: a positive whole number, not a table of candidates, whenever a size was passed."
     Rewrite: "‘attr(x, "grid")’ holds the ‘grid’ argument as you gave it. If you passed a size, it holds a positive whole number, not a table of candidates."

128. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
     Text: "Printing says so when it happens."
     Rewrite: "The print method says so when this happens."

129. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "Rows are never added or removed."
     Rewrite: "You must not add or remove rows."

130. Rule 6.3: "Maximum 25 words per sentence."
     Text: "So a column you add afterwards is read as a fold label only when the design itself carries a column of that name: ‘id’, and ‘id2’ for a repeated design."
     Rewrite: "A column that you add afterwards is a fold label only when the design carries a column of that name. Those names are ‘id’, and ‘id2’ for a repeated design."

131. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
     Text: "Adding ‘id2’ to a result from a plain v-fold design leaves the class, the record and the fold labels alone, exactly as adding ‘extra’ does."
     Rewrite: "If you add ‘id2’ to a result from a plain v-fold design, the class, the record and the fold labels stay as they are. A column named ‘extra’ does the same."

132. Rule 6.3: "Maximum 25 words per sentence."
     Text: "Anything else returns a bare tibble, with the record removed along with the class: ‘slice()’, a ‘filter()’ that drops a fold, ‘bind_rows()’, ‘x[1, ]’, or a drop of a column above."
     Rewrite: "Anything else returns a bare tibble and drops the record with the class. That covers ‘slice()’, a ‘filter()’ that drops a fold, ‘bind_rows()’, ‘x[1, ]’, and a drop of a column above."

133. Rule 6.3: "Maximum 25 words per sentence."
     Text: "Inner tuning raises only once every candidate has failed, and the outer fit does not raise at all: it hands back a result with no metrics."
     Rewrite: "Inner tuning raises an error only after every candidate failed. The outer fit raises nothing. It hands back a result with no metrics."

134. Rule 3.4: "No auxiliary verbs for complex constructions. No present perfect, no "is to be installed"."
     Text: "Inner tuning raises only once every candidate has failed"
     Rewrite: "Inner tuning raises an error only after every candidate failed"

135. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "The number of folds attempted and the number completed are stored as the ‘folds_attempted’ and ‘folds_completed’ attributes."
     Rewrite: "The result stores the number of folds attempted and the number completed, as the ‘folds_attempted’ and ‘folds_completed’ attributes."

136. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "Both are recorded as failures here."
     Rewrite: "This package records both as failures."

137. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "No fold is reported as having searched a grid it did not."
     Rewrite: "This package never reports that a fold searched a grid which it did not search."

138. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "Two or more daemons are needed before the loop dispatches."
     Rewrite: "The loop needs two or more daemons before it dispatches."

139. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
     Text: "A resampling split carries the whole frame it indexes, and serializing a fold for a daemon does not preserve the single copy the design shares."
     Rewrite: "A resampling split carries the whole frame that it indexes. When the loop serializes a fold for a daemon, the single copy that the design shares is lost."

140. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "So each fold's splits are emptied before dispatch and refilled on the worker."
     Rewrite: "So the loop empties each fold's splits before dispatch and fills them again on the worker."

141. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
     Text: "Building the workflow at the top level avoids that."
     Rewrite: "Build the workflow at the top level to prevent that."

142. Rule 6.3: "Maximum 25 words per sentence."
     Text: "Calling ‘mirai::daemons(0)’ while folds are outstanding produces exactly what a daemon dying mid-fold produces, so it is recorded as fold failures rather than as a cancellation."
     Rewrite: "A call to ‘mirai::daemons(0)’ while folds are outstanding looks the same as a daemon that dies in mid-fold. So the run records fold failures, not a cancellation."

143. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
     Text: "Stopping a run is not a fold failure."
     Rewrite: "A stop of the run is not a fold failure."

144. Rule 6.3: "Maximum 25 words per sentence."
     Text: "An interrupt at your own console unwinds the blocking wait before any worker's value is classified, so an ordinary interrupt propagates with no nestedtune class attached."
     Rewrite: "An interrupt at your own console unwinds the wait before the loop classifies any worker's value. So an ordinary interrupt carries no nestedtune class."

145. Rule 6.3: "Maximum 25 words per sentence."
     Text: "A pool started with ‘dispatcher = FALSE’ cannot be stopped this way, and you are told so at dispatch by a warning of class ‘nestedtune_pool_not_cancellable’, once per call."
     Rewrite: "You cannot stop a pool that you started with ‘dispatcher = FALSE’ this way. The loop warns you at dispatch with class ‘nestedtune_pool_not_cancellable’, once per call."

146. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
     Text: "Stopping is a request rather than a guarantee: a fold inside a compiled fitting routine is sometimes not interruptible, and one that has nearly finished sometimes runs to the end."
     Rewrite: "A stop is a request, not a guarantee. A fold inside a compiled fit routine is sometimes not interruptible, and a fold that is nearly done sometimes runs to the end."

147. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "What is refused at entry is a control of another class, such as a ‘control_bayes()’ that tune itself accepts here, and the ‘event_level’ conflict above."
     Rewrite: "This function refuses two things at entry: a control of another class, such as a ‘control_bayes()’ that tune itself accepts here, and the ‘event_level’ conflict above."

148. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "‘pkgs’ is required before fitting on the serial path as on the parallel one."
     Rewrite: "The loop loads ‘pkgs’ before it fits, on the serial path as on the parallel one."

149. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "What is kept is the outer fit's, and the inner run's predictions and extracts are still discarded with that run."
     Rewrite: "The result keeps the outer fit's predictions and extracts. It discards the inner run's, with that run."

## nested_tune_race

150. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "The survivors are scored on the remaining resamples, and the fold then selects, finalizes, fits and scores on the outer split as the grid page describes."
     Rewrite: "The race scores the survivors on the remaining resamples. The fold then selects, finalizes, fits and scores on the outer split, as the grid page describes."

151. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "The estimate describes the race-and-fit procedure as a whole and is reported for it."
     Rewrite: "The estimate describes the race-and-fit procedure as a whole. Report it for that procedure."

152. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "A missing package is refused at entry, before any fold runs."
     Rewrite: "These functions refuse a missing package at entry, before any fold runs."

153. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "In that table ‘n’ is the number of inner resamples each candidate was scored on."
     Rewrite: "In that table ‘n’ is the number of inner resamples that scored each candidate."

154. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "The recorded ‘grid’, in the ‘procedure’ record and as ‘attr(x, "grid")’, is the design the race was offered, exactly as given."
     Rewrite: "The recorded ‘grid’, in the ‘procedure’ record and as ‘attr(x, "grid")’, is the design that you offered the race, exactly as you gave it."

155. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "With ‘randomize = TRUE’, finetune's default, the inner resamples are shuffled before the burn-in."
     Rewrite: "With ‘randomize = TRUE’, finetune's default, finetune shuffles the inner resamples before the burn-in."

156. Rule 6.3: "Maximum 25 words per sentence."
     Text: "This package refuses the whole call before any fold runs when finetune refuses any outer fold's inner ‘rset’, and the refusal names the count and the burn-in."
     Rewrite: "If finetune refuses any outer fold's inner ‘rset’, this package refuses the whole call before any fold runs. The refusal names the count and the burn-in."

157. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
     Text: "A design breaking any of this, or using a bootstrap for the outer loop, is refused before anything is fitted."
     Rewrite: "If a design breaks any of this, or uses a bootstrap for the outer loop, these functions refuse it before they fit anything."

158. Rule 4.2: "Do not omit words or use contractions to shorten sentences. Keep articles, keep "that"."
     Text: "Refused here, ahead of tune: anything that is not numeric, an empty vector, and any element that is missing, negative or not finite."
     Rewrite: "These functions refuse three things ahead of tune: a value that is not numeric, an empty vector, and any element that is missing, negative or not finite."

159. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "This classification was read on finetune 1.3.0."
     Rewrite: "We read this classification on finetune 1.3.0."

## nested_tune_sim_anneal

160. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "The estimate describes the annealing-and-fit procedure as a whole and is reported for it."
     Rewrite: "The estimate describes the annealing-and-fit procedure as a whole. Report it for that procedure."

161. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "A missing package is refused at entry, before any fold runs."
     Rewrite: "This function refuses a missing package at entry, before any fold runs."

162. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "A ‘tune_results’ object is refused as ‘initial’ for the reason that page gives."
     Rewrite: "This function refuses a ‘tune_results’ object as ‘initial’, for the reason that page gives."

163. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "‘iter = 0’ is refused."
     Rewrite: "This function refuses ‘iter = 0’."

164. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "The initial candidates are a space-filling design drawn under the fold's tuning seed, and each perturbation is drawn from the stream that seed started."
     Rewrite: "finetune draws the initial candidates as a space-filling design under the fold's tuning seed. It draws each perturbation from the stream that this seed started."

165. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "‘finetune::control_sim_anneal()’ has no seed slot, so nothing is injected into the control."
     Rewrite: "‘finetune::control_sim_anneal()’ has no seed slot, so this package puts nothing into the control."

166. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
     Text: "A design breaking any of this, or using a bootstrap for the outer loop, is refused before anything is fitted."
     Rewrite: "If a design breaks any of this, or uses a bootstrap for the outer loop, this function refuses it before it fits anything."

167. Rule 4.2: "Do not omit words or use contractions to shorten sentences. Keep articles, keep "that"."
     Text: "Refused here, ahead of tune: anything that is not numeric, an empty vector, and any element that is missing, negative or not finite."
     Rewrite: "This function refuses three things ahead of tune: a value that is not numeric, an empty vector, and any element that is missing, negative or not finite."

168. Rule 6.3: "Maximum 25 words per sentence."
     Text: "‘verbose_iter’, ‘TRUE’ in finetune's default, prints the annealing log from every fold of a serial run, one log per fold, and from a mirai daemon where nothing shows it."
     Rewrite: "‘verbose_iter’ is ‘TRUE’ in finetune's default. It prints the annealing log from every fold of a serial run, one log per fold. It also prints from a mirai daemon, where nothing shows it."

169. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "The classification above was read on finetune 1.3.0."
     Rewrite: "We read the classification above on finetune 1.3.0."

## nested_workflow_map

170. Rule 6.3: "Maximum 25 words per sentence."
     Text: "It is shaped like ‘workflowsets::workflow_map()’: the orchestrator's arguments come through ‘...’, and an entry in the set's ‘option’ column overrides the same-named argument for that workflow alone."
     Rewrite: "It is shaped like ‘workflowsets::workflow_map()’. The orchestrator's arguments come through ‘...’. An entry in the set's ‘option’ column overrides the same-named argument for that workflow alone."

171. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "A name the orchestrator ‘fn’ names does not take is refused, as is an unnamed argument or a call with no ‘resamples’."
     Rewrite: "This function refuses a name that the orchestrator ‘fn’ does not take. It also refuses an argument with no name, and a call with no ‘resamples’."

172. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "‘fn’ is kept as an attribute."
     Rewrite: "The object keeps ‘fn’ as an attribute."

173. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "The ‘result’ column of the set given as ‘object’ is not read: this function returns its results as its own object rather than filling that column."
     Rewrite: "This function does not read the ‘result’ column of the set that you give as ‘object’. It returns its results as its own object instead."

174. Rule 9.4: "Keep one consistent style and terminology through the whole document." (Word Choice: "since (= because) → because")
     Text: "A workflow with no parameter marked by ‘tune::tune()’ runs through ‘nested_fit_resamples()’ whatever ‘fn’ names, since the five tuning orchestrators refuse it at entry."
     Rewrite: "A workflow with no parameter marked by ‘tune::tune()’ runs through ‘nested_fit_resamples()’, whatever ‘fn’ names, because the five tuning orchestrators refuse it at entry."

175. Rule 6.3: "Maximum 25 words per sentence."
     Text: "For each workflow the merged arguments are narrowed to what its orchestrator accepts: its formals other than ‘object’, and, for a workflow that runs through ‘fn’, the ‘control’ in ‘...’."
     Rewrite: "For each workflow this function narrows the merged arguments to what its orchestrator accepts. That is the orchestrator's formals other than ‘object’. A workflow that runs through ‘fn’ also takes the ‘control’ in ‘...’."

176. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
     Text: "A name that the orchestrator ‘fn’ names does not take is refused at entry, because narrowing otherwise drops a misspelled name for every workflow without a message."
     Rewrite: "This function refuses at entry a name that the orchestrator ‘fn’ does not take. Otherwise it would drop a misspelled name for every workflow with no message."

177. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
     Text: "A name in a workflow's ‘option’ entry that the orchestrator it routes to does not take is refused naming the workflow."
     Rewrite: "This function refuses a name in a workflow's ‘option’ entry that its orchestrator does not take, and the refusal names the workflow."

178. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "The generator state the call holds once its entry checks have run is reinstated before each workflow."
     Rewrite: "The call reinstates the generator state it holds after its entry checks, before each workflow."

179. Rule 3.4: "No auxiliary verbs for complex constructions. No present perfect, no "is to be installed"."
     Text: "once its entry checks have run"
     Rewrite: "after its entry checks ran"

180. Rule 6.3: "Maximum 25 words per sentence."
     Text: "Each element runs its folds in parallel exactly as its orchestrator does: a running mirai pool is used for every workflow's folds, one round of folds per workflow."
     Rewrite: "Each element runs its folds in parallel exactly as its orchestrator does. A mirai pool that runs serves every workflow's folds, one round of folds per workflow."

181. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "An error an orchestrator raises for one workflow is raised the same way, when that workflow's turn comes."
     Rewrite: "This function raises an orchestrator's error for one workflow the same way, when that workflow's turn comes."

182. Rule 6.3: "Maximum 25 words per sentence."
     Text: "What is raised is the original condition object, with Workflow "<id>": written in front of the first line of its message and this function, or the reading function, as its call."
     Rewrite: "This function raises the original condition object. It writes Workflow "<id>": in front of the first line of the message. The call is this function, or the reading function."

183. Rule 9.4: "Keep one consistent style and terminology through the whole document." (Word Choice: "since (= because) → because")
     Text: "You can take a subset of the set and it still answers for the workflows it holds, since each row's ‘nested_results’ describes its own run whole."
     Rewrite: "You can take a subset of the set, and it still answers for the workflows it holds, because each row's ‘nested_results’ describes its own run whole."

184. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "Replacing a value under the class with $<- or [[<- is not checked, as it is not on a ‘nested_results’."
     Rewrite: "This package does not check a value that you replace under the class with $<- or [[<-. It does not check one on a ‘nested_results’ either."

185. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
     Text: "Replacing a value under the class with $<- or [[<- is not checked"
     Rewrite: "This package does not check a value that you replace under the class with $<- or [[<-."

## nestedtune-package

186. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "The inner tuning on each outer fold is done by tune and finetune."
     Rewrite: "tune and finetune do the inner tuning on each outer fold."

187. Rule 6.3: "Maximum 25 words per sentence."
     Text: "‘collect_metrics()’ gives the estimate, ‘summary()’ and autoplot() describe the run, and ‘agreement()’, ‘collect_selections()’ and ‘extract_procedure()’ say what the folds chose and how they were told to choose."
     Rewrite: "‘collect_metrics()’ gives the estimate, and ‘summary()’ and autoplot() describe the run. ‘agreement()’, ‘collect_selections()’ and ‘extract_procedure()’ say what the folds chose, and which rule they chose by."

188. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "say what the folds chose and how they were told to choose"
     Rewrite: "say what the folds chose, and which rule you gave them to choose by"

## predict.nested_final_fit

189. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "they are the trained workflow's own methods, reached without extracting it first"
     Rewrite: "They are the trained workflow's own methods, and you reach them without an extraction first."

190. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "‘type’ selects the prediction type, such as ‘"numeric"’, ‘"prob"’ or ‘"survival"’, with the workflow's default when left unset."
     Rewrite: "‘type’ selects the prediction type, such as ‘"numeric"’, ‘"prob"’ or ‘"survival"’. If you leave it unset, the workflow uses its default."

191. Rule 6.3: "Maximum 25 words per sentence."
     Text: "‘augment()’ returns the workflow's prediction columns followed by the columns of ‘new_data’, with a ‘.resid’ column where the outcome is present and the model is a regression."
     Rewrite: "‘augment()’ returns the workflow's prediction columns, then the columns of ‘new_data’. It adds a ‘.resid’ column when the outcome is present and the model is a regression."

192. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "A name outside parsnip's own short list of predict arguments is refused by parsnip."
     Rewrite: "parsnip refuses a name outside its own short list of predict arguments."

193. Rule 6.3: "Maximum 25 words per sentence."
     Text: "A listed one the model cannot use for the ‘type’ asked is passed on, and whether it has any effect is parsnip's business, not this method's."
     Rewrite: "This method passes on a listed name that the model cannot use for the ‘type’ you asked for. parsnip decides whether that name has any effect."

194. Rule 6.3: "Maximum 25 words per sentence."
     Text: "‘augment()’ refuses the dots instead, and that refusal is the only one there is: workflows' own ‘augment()’ method passes an unread argument on to parsnip, which ignores it."
     Rewrite: "‘augment()’ refuses the dots instead, and that is the only refusal here. The ‘augment()’ method in workflows passes an argument it does not read on to parsnip, which ignores it."

195. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
     Text: "Augmenting the rows this model was fit on gives in-sample residuals."
     Rewrite: "If you augment the rows that this model was fit on, you get in-sample residuals."

## print.nested_final_fit

196. Rule 4.2: "Do not omit words or use contractions to shorten sentences. Keep articles, keep "that"."
     Text: "Shows what the full-data search was, which parameters it selected, and where this model's performance estimate comes from."
     Rewrite: "This method shows what the full-data search was, which parameters it selected, and where this model's performance estimate comes from."

197. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
     Text: "Passing an argument here raises an error instead of leaving it silently ignored."
     Rewrite: "If you pass an argument here, the method raises an error. It does not ignore the argument in silence."

198. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "See ‘nested_final_fit()’ for why they are not this model's performance and the nested estimate is."
     Rewrite: "See ‘nested_final_fit()’ for the reason: these metrics do not measure this model's performance, and the nested estimate does."

199. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "A grid search or a race is named with the number of candidates, parameter settings, it scored."
     Rewrite: "For a grid search or a race, the line gives the number of candidates, the parameter settings, that it scored."

200. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "An iterating search is named with the initial candidates scored and requested and the iterations completed and requested."
     Rewrite: "For an iterating search, the line gives the initial candidates scored and requested, and the iterations completed and requested."

201. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
     Text: "An iterating search is named with the initial candidates scored and requested"
     Rewrite: "For a search that iterates, the line gives the initial candidates scored and requested"

## print.nested_results

202. Rule 4.2: "Do not omit words or use contractions to shorten sentences. Keep articles, keep "that"."
     Text: "Shows the object: its outer folds as the tibble rows they are, and the outer resampling scheme it came from."
     Rewrite: "This method shows the object. It prints the outer folds as the tibble rows they are, and names the outer resampling scheme they came from."

203. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
     Text: "Number of fold rows to show, passed to tibble's printing."
     Rewrite: "The number of fold rows to show. The method passes it to the print method of tibble."

204. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "‘NULL’, the default, uses the ‘width’ option, and columns that do not fit are named in the footer."
     Rewrite: "‘NULL’, the default, uses the ‘width’ option. The footer names the columns that do not fit."

205. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "It is expanded once per fold, under that fold's own seed, so a continuous parameter leaves every fold with candidates of its own."
     Rewrite: "tune expands it once per fold, under that fold's own seed. So a continuous parameter leaves every fold with candidates of its own."

## print.nested_results_set

206. Rule 4.2: "Do not omit words or use contractions to shorten sentences. Keep articles, keep "that"."
     Text: "Shows which loop function the set ran through, ‘nested_tune_grid()’ or a sibling, and how many workflows it holds."
     Rewrite: "This method shows which loop function the set ran through, ‘nested_tune_grid()’ or a sibling, and how many workflows the set holds."

207. Rule 6.3: "Maximum 25 words per sentence."
     Text: "Then it prints one line per workflow: its id, how many of its outer folds completed, and the label of the tuner that ran for it."
     Rewrite: "Then it prints one line per workflow. The line gives the id, the number of outer folds that completed, and the label of the tuner that ran."

## reexports: no entries

## selection_rule

208. Rule 4.2: "Do not omit words or use contractions to shorten sentences. Keep articles, keep "that"."
     Text: "Builds the object the ‘select’ argument of ‘nested_tune_grid()’ and its siblings takes."
     Rewrite: "This function builds the object that the ‘select’ argument of ‘nested_tune_grid()’ and its siblings takes."

209. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
     Text: "one or more bare expressions ordering the candidates from simplest to most complex, as tune's selectors take them"
     Rewrite: "one or more bare expressions that order the candidates from simplest to most complex, as tune's selectors take them"

210. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "At least one is required for those rules, and ‘"best"’ accepts none."
     Rewrite: "Those rules need at least one expression, and ‘"best"’ accepts none."

211. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
     Text: "Printing shows the three on one line."
     Rewrite: "The print method shows the three on one line."

212. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "An ordering is a parameter name, wrapped in ‘dplyr::desc()’ where a larger value is the simpler model."
     Rewrite: "An ordering is a parameter name. Wrap it in ‘dplyr::desc()’ where a larger value is the simpler model."

213. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "A named one is refused."
     Rewrite: "This function refuses an expression with a name."

214. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "That way a misspelled ‘limit’ is refused instead of read as an ordering."
     Rewrite: "That way the function refuses a misspelled ‘limit’ instead of reading it as an ordering."

## summary.nested_final_fit

215. Rule 6.3: "Maximum 25 words per sentence."
     Text: "Those are the full-data tuning run the selection came from, which search ran it and at what counts, how many parameter settings it scored, and which values it chose."
     Rewrite: "Those facts are the full-data tuning run that the selection came from. They also give which search ran it and at what counts, how many parameter settings it scored, and which values it chose."

216. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
     Text: "Passing an argument here raises an error instead of leaving it silently ignored."
     Rewrite: "If you pass an argument here, the method raises an error. It does not ignore the argument in silence."

217. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
     Text: "Printing it is what most callers want."
     Rewrite: "Most callers only print the object."

218. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "They are carried rather than dropped, for the reason ‘estimate’ is."
     Rewrite: "The object carries them rather than drops them, for the reason it carries ‘estimate’."

219. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "The scored figures are counted from the tuning run's metrics table, and the requested ones are the counts the search was called with."
     Rewrite: "The method counts the scored figures from the tuning run's metrics table. The requested figures are the counts that you called the search with."

## summary.nested_results

220. Rule 4.2: "Do not omit words or use contractions to shorten sentences. Keep articles, keep "that"."
     Text: "Answers what the run means."
     Rewrite: "This method answers what the run means."

221. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
     Text: "Averaging the metrics hides that, so the summary marks it."
     Rewrite: "An average of the metrics hides that, so the summary marks it."

222. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
     Text: "Printing it is what most callers want."
     Rewrite: "Most callers only print the object."

223. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
     Text: "Summarizing a partly completed run warns and still returns the summary: the folds that ran are described, and the warning says the design asked for more."
     Rewrite: "If you summarize a partly completed run, the method warns and still returns the summary. It describes the folds that ran, and the warning says that the design asked for more."

224. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "the folds that ran are described"
     Rewrite: "the summary describes the folds that ran"

## summary.nested_results_set

225. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "Each is keyed by ‘wflow_id’."
     Rewrite: "Each one keys its answer by ‘wflow_id’."

226. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ("logging", "the mounting bracket"), never as a verb."
     Text: "Printing it shows that function's name and the workflow count, then one section per workflow."
     Rewrite: "The print method shows that function's name and the workflow count, then one section per workflow."

227. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "The note on what a nested estimate describes is printed once, at the end."
     Rewrite: "The print method shows the note on what a nested estimate describes once, at the end."

228. Rule 6.3: "Maximum 25 words per sentence."
     Text: "Each panel has one point per completed outer fold's score and a dashed rule at each workflow's nested estimate, the value ‘collect_metrics()’ reports for it on the set."
     Rewrite: "Each panel has one point per completed outer fold's score. It also has a dashed rule at each workflow's nested estimate, the value that ‘collect_metrics()’ reports for it on the set."

229. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "It is labelled by the id and then by that view's label for the parameter, and asks that view's question of one workflow."
     Rewrite: "The plot labels it by the id and then by that view's label for the parameter. The panel asks that view's question of one workflow."

230. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "The selected-value axis is decided over every workflow's values at once: numeric when all are numbers, discrete otherwise."
     Rewrite: "The plot decides the selected-value axis over every workflow's values at once. The axis is numeric when all the values are numbers, and discrete in every other case."

231. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "A tuned parameter whose id is ‘wflow_id’ cannot be tabulated beside the set's own column and is refused with class ‘nestedtune_collect_name_collision’."
     Rewrite: "‘agreement()’ cannot tabulate a tuned parameter whose id is ‘wflow_id’ beside the set's own column. It refuses such a set with class ‘nestedtune_collect_name_collision’."

232. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "A workflow with some folds failed is read over the folds that ran, warned about once with class ‘nestedtune_partial_summary’."
     Rewrite: "If some of a workflow's folds failed, these functions read the folds that ran. They warn once with class ‘nestedtune_partial_summary’."

233. Rule 3.6: "Active voice. In descriptive text, passive is legal only when the agent is unknown."
     Text: "A set in which no workflow completed a fold is refused by the plots and by ‘agreement()’ with class ‘nestedtune_no_completed_folds’."
     Rewrite: "If no workflow of a set completed a fold, the plots and ‘agreement()’ refuse the set with class ‘nestedtune_no_completed_folds’."

234. Rule 9.4: "Keep one consistent style and terminology through the whole document." (Word Choice: "since (= because) → because")
     Text: "A workflow that ran whole can still be named by the second, since a completed fold can score ‘NA’ on one metric while scoring the others."
     Rewrite: "The second count can still name a workflow that ran whole, because a completed fold can score ‘NA’ on one metric and score the others."
