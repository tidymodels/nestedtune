# M086 reader review (pass 1, 2026-09-11)

## vignettes/nested-cv.Rmd

1. Rule 6.3: "Maximum 25 words per sentence."
   Text: "You picked the winner because it scored well, so some of its score is luck, and the same number will not hold up on new data."
   Rewrite: "You picked the winner because it scored well. Some of its score is luck, so the same number does not hold on new data."

2. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ... never as a verb."
   Text: "Nested cross-validation fixes this by scoring the whole tuning procedure rather than the winner alone."
   Rewrite: "Nested cross-validation fixes this. It scores the whole tuning procedure, not the winner alone."

3. Rule 6.3: "Maximum 25 words per sentence."
   Text: "Within each outer fold it tunes using only the analysis rows, fits the winning setting on those rows, and scores that fit on the assessment rows the tuning never saw."
   Rewrite: "Within each outer fold it tunes on the analysis rows alone. It then fits the winning setting on those rows. It scores that fit on the assessment rows the tuning never saw."

4. Rule 3.6: "Active voice."
   Text: "It has no score of its own, because every row it was trained on was already used to choose and fit it."
   Rewrite: "It has no score of its own, because the procedure already used every one of its training rows to choose and fit it."

5. Rule GR-4: "this + noun"
   Text: "Anything tune can tune, this can tune."
   Rewrite: "This package can tune anything tune can tune."

6. Rule 9.3: "Prefer the one-word verb over the phrasal verb"
   Text: "That multiplies out to `r nrow(folds) * nrow(folds$inner_resamples[[1]]) * nrow(grid)` models for tuning, plus one per outer fold for scoring."
   Rewrite: "The product is `r nrow(folds) * nrow(folds$inner_resamples[[1]]) * nrow(grid)` models for tuning, plus one model per outer fold for scoring."

7. Rule 6.3: "Maximum 25 words per sentence."
   Text: "For each outer fold it calls `tune::tune_grid()` on that fold's inner resamples, the same call you make by hand, with parallelism off and the fold's seed set."
   Rewrite: "For each outer fold it calls `tune::tune_grid()` on that fold's inner resamples. This is the same call you make by hand, with parallelism off and the fold's seed set."

8. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ... never as a verb."
   Text: "To pick by another of tune's selectors, pass a `selection_rule()` naming it as the `select` argument."
   Rewrite: "To pick by another of tune's selectors, pass a `selection_rule()` that names it as the `select` argument."

9. Rule 3.6: "Active voice."
   Text: "Two of these numbers from two workflows cannot be subtracted to compare them, and `vignette("estimate")` says why."
   Rewrite: "You cannot subtract two of these numbers from two workflows to compare them, and `vignette("estimate")` says why."

10. Rule 9.3: "Prefer the one-word verb over the phrasal verb"
    Text: "Most tools throw this away."
    Rewrite: "Most tools discard this record."

11. Rule GR-3: "clear pronoun referents"
    Text: "nestedtune keeps it, because it is information about the procedure rather than noise in it."
    Rewrite: "nestedtune keeps the record, because the disagreement is information about the procedure rather than noise in the procedure."

12. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ... never as a verb."
    Text: "Quoting the second as though it described the folds understates their disagreement."
    Rewrite: "If you quote the second as though it described the folds, you understate their disagreement."

13. Rule 3.6: "Active voice."
    Text: "A tuned procedure is usually compared with something simpler, such as the same model with its parameters fixed."
    Rewrite: "You usually compare a tuned procedure with something simpler, such as the same model with its parameters fixed."

14. Rule 3.6: "Active voice."
    Text: "The model is built by running the same procedure once more with the whole dataset in hand."
    Rewrite: "You build the model when you run the same procedure once more on the whole dataset."

15. Rule 3.6: "Active voice."
    Text: "The procedure is read from `res` (the inner resampling specification, the grid, the metrics, the selection rule), so the model and the estimate come from one search."
    Rewrite: "The function reads the procedure from `res` (the inner resampling specification, the grid, the metrics, the selection rule), so the model and the estimate come from one search."

16. Rule 3.6: "Active voice."
    Text: "Their selections are not pooled or voted on."
    Rewrite: "This package does not pool their selections and does not vote on them."

17. Rule 3.6: "Active voice."
    Text: "`show_best()` handed it over above because it was given tune's own object, which does not warn."
    Rewrite: "`show_best()` gave the number above because you passed it tune's own object, which does not warn."

18. Rule 3.6: "Active voice."
    Text: "Both are stored on the result."
    Rewrite: "The function stores both seeds on the result."

19. Rule 3.6: "Active voice."
    Text: "The estimate is attributed to the procedure and not to the model."
    Rewrite: "The report attributes the estimate to the procedure and not to the model."

20. Rule 3.6: "Active voice."
    Text: "The instability is reported rather than hidden."
    Rewrite: "The report gives the instability and hides nothing."

21. Rule 3.6: "Active voice."
    Text: "The deployed model is described as what it is: the same procedure applied to all the data, with no performance claim of its own."
    Rewrite: "The report describes the deployed model as what it is: the same procedure on all the data, with no performance claim of its own."

## vignettes/estimate.Rmd

1. Rule 3.6: "Active voice."
   Text: "It says why a tuned model's own score cannot be trusted, which quantity the nested number describes, and how to read its standard error."
   Rewrite: "It says why you cannot trust a tuned model's own score, which quantity the nested number describes, and how to read its standard error."

2. Rule 9.3: "Prefer the one-word verb over the phrasal verb"
   Text: "At a small sample size the noise is large, so the winner's score can come out no better than an honest one."
   Rewrite: "At a small sample size the noise is large, so the winner's score can end no better than an honest one."

3. Rule 3.6: "Active voice."
   Text: "Distrust it for how it was chosen, whether it came out high or low."
   Rewrite: "Distrust the score for how you chose it, whether it is high or low."

4. Rule 6.3: "Maximum 25 words per sentence."
   Text: "Each outer fold tunes from scratch on its own analysis rows, fits the chosen setting there, and scores that fit once on assessment rows the tuning never saw."
   Rewrite: "Each outer fold tunes from scratch on its own analysis rows and fits the chosen setting there. It then scores that fit once on assessment rows the tuning never saw."

5. Rule 3.6: "Active voice."
   Text: "Everything computable from its training data was used up in selecting and fitting it."
   Rewrite: "Selection and fitting consumed everything you can compute from its training data."

6. Rule 3.6: "Active voice."
   Text: "The number `collect_metrics()` reports is that procedure's error when run on each fold's training rows and scored on fresh data."
   Rewrite: "The number `collect_metrics()` reports is that procedure's error when it runs on each fold's training rows and scores fresh data."

7. Rule 4.3: "Use a vertical list for complex text: colon on the lead-in, uppercase start, a period only on full-sentence items."
   Text: "Four things it is not."
   Rewrite: "The number is not these four things:"

8. Rule 3.6: "Active voice."
   Text: "It is not the error of the deployed model, which is built afterwards on all the rows and estimated by nothing here."
   Rewrite: "It is not the error of the deployed model. You build that model afterwards on all the rows, and nothing here estimates its error."

9. Rule 9.4: "Keep one consistent style and terminology through the whole document." (Word choice: since to because)
   Text: "It does not say what a larger or a different training set gives, since it ran on this one alone."
   Rewrite: "It does not say what a larger or a different training set gives, because it ran on this one alone."

10. Rule 3.6: "Active voice."
    Text: "Every outer fold trains on its analysis rows only, so every model scored is built on less data than the model you finally deploy."
    Rewrite: "Every outer fold trains on its analysis rows only. So every model it scores has less data than the model you finally deploy."

11. Rule 1.14: "Use American English spelling."
    Text: "It is never a licence to adjust the reported figure upward."
    Rewrite: "It is never a license to adjust the reported figure upward."

12. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ... never as a verb."
    Text: "Stable means that changing one training row shifts its errors by little, compared with how spread out those errors are."
    Rewrite: "A procedure is stable when a change to one training row shifts its errors by little, compared with the spread of those errors."

13. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ... never as a verb."
    Text: "Choosing the workflow with the best estimate is itself a selection, made on the same scores, and no outer loop scored that choice."
    Rewrite: "When you choose the workflow with the best estimate, you make another selection on the same scores. No outer loop scored that choice."

14. Rule 9.4: "Keep one consistent style and terminology through the whole document." (Word choice: since to because)
    Text: "The estimate is fine, since it already averages over this variability."
    Rewrite: "The estimate is fine, because it already averages over this variability."

15. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ... never as a verb."
    Text: "What suffers is any story about the selected parameters being the right ones."
    Rewrite: "What suffers is any story that the selected parameters are the right ones."

16. Rule 5.4: "Put a required condition before the command, divided by a comma."
    Text: "Their advice, and this package's: nest when there are many features for the sample size and the search is wide, if you can afford the compute."
    Rewrite: "Their advice, and this package's: if you can afford the compute, nest when there are many features for the sample size and the search is wide."

17. Rule 3.6: "Active voice."
    Text: "Anything done to the data before the call is not re-estimated."
    Rewrite: "The loop does not re-estimate anything you did to the data before the call."

18. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ... never as a verb."
    Text: "Vabalas et al. (2019) compared two mistakes: leaving feature selection outside the loop, and leaving parameter tuning outside it."
    Rewrite: "Vabalas et al. (2019) compared two mistakes. The first mistake keeps feature selection outside the loop. The second keeps parameter tuning outside it."

## vignettes/tuners.Rmd

1. Rule 3.6: "Active voice."
   Text: "The grid tuner and the racers score the candidates they are given, the settings in the grid."
   Rewrite: "The grid tuner and the racers score the candidates you give them, the settings in the grid."

2. Rule 3.6: "Active voice."
   Text: "The default range of `mtry` is not known until the data is seen, so a search over it fails at inner tuning in every fold."
   Rewrite: "The default range of `mtry` depends on the data, so a search over it fails at inner tuning in every fold."

3. Rule 3.6: "Active voice."
   Text: "After each further resample, a candidate that is clearly worse than the current best is dropped."
   Rewrite: "After each further resample, the race drops a candidate that is clearly worse than the current best."

4. Rule 3.6: "Active voice."
   Text: "The `n` column says how many inner resamples each candidate was scored on before it was dropped or the race ended."
   Rewrite: "The `n` column says how many inner resamples scored each candidate before the race dropped it or the race ended."

5. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ... never as a verb."
   Text: "So summing `n` over one metric's rows counts the fits each fold spent on tuning."
   Rewrite: "So the sum of `n` over one metric's rows counts the fits each fold spent on tuning."

6. Rule 3.6: "Active voice."
   Text: "A tuned procedure, the whole resample-tune-select-fit sequence, is usually compared with something simpler, such as the same model with its parameters fixed."
   Rewrite: "You usually compare a tuned procedure, the whole resample-tune-select-fit sequence, with something simpler, such as the same model with fixed parameters."

7. Rule 9.4: "Keep one consistent style and terminology through the whole document." (Word choice: since to because)
   Text: "The baseline's `.selected` column holds an empty table on every fold, since nothing was chosen, so `collect_selections()` and `agreement()` return zero rows."
   Rewrite: "The baseline's `.selected` column holds an empty table on every fold, because the run chose nothing. So `collect_selections()` and `agreement()` return zero rows."

8. Rule 3.6: "Active voice."
   Text: "Two nested estimates cannot be subtracted to compare procedures, for the reasons `vignette("estimate")` gives."
   Rewrite: "You cannot subtract two nested estimates to compare procedures, for the reasons `vignette("estimate")` gives."

9. Rule 6.3: "Maximum 25 words per sentence."
   Text: "They are the random forest above, a linear model on the same predictors with nothing to tune, and a linear model on principal components whose count is tuned."
   Rewrite: "They are the random forest above and two linear models. The first linear model uses the same predictors and has nothing to tune. The second uses principal components and tunes their count."

10. Rule 6.6: "Maximum six sentences per paragraph."
    Text: "A comparison across model families needs every family scored on the same outer folds. ... The components workflow cannot use that grid, so its own grid goes in the set's `option` column with `option_add()`."
    Rewrite: Split the paragraph after "Here the set holds three workflows." and start a new paragraph with the description of the three workflows.

11. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ... never as a verb."
    Text: "Calling that function by hand, with the same arguments and the same seed, gives the same object."
    Rewrite: "If you call that function by hand with the same arguments and the same seed, you get the same object."

12. Rule 3.6: "Active voice."
    Text: "So each row can be read exactly as the earlier sections read a single result."
    Rewrite: "So you can read each row exactly as the earlier sections read a single result."

13. Rule 1.14: "Use American English spelling."
    Text: "The parameters view keeps the outer folds on the x axis and gives each workflow's tuned parameter its own panel, labelled by the id."
    Rewrite: "The parameters view keeps the outer folds on the x axis and gives each workflow's tuned parameter its own panel, labeled by the id."

14. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ... never as a verb."
    Text: "Choosing among them by these estimates is a selection the outer loop did not nest, as `vignette("estimate")` says."
    Rewrite: "If you choose among them by these estimates, you make a selection the outer loop did not nest, as `vignette("estimate")` says."

## vignettes/results.Rmd

1. Rule 3.6: "Active voice."
   Text: "One thing is added."
   Rewrite: "This page adds one thing."

2. Rule 6.3: "Maximum 25 words per sentence."
   Text: "A `control_grid()` with `save_pred = TRUE` asks each fold's outer fit to keep its predictions, so this page can show that column and the function that stacks it."
   Rewrite: "A `control_grid()` with `save_pred = TRUE` asks each fold's outer fit to keep its predictions. This page can then show that column and the function that stacks it."

3. Rule 3.6: "Active voice."
   Text: "It is what the fold's selection was made from."
   Rewrite: "The fold made its selection from this table."

4. Rule 6.3: "Maximum 25 words per sentence."
   Text: "`.tuning_seed` and `.outer_fit_seed` are the two seeds each fold ran under, drawn at entry and fixed by the fold's position in the design, as `vignette("nested-cv")` explains under Reproducibility."
   Rewrite: "`.tuning_seed` and `.outer_fit_seed` are the two seeds each fold ran under. The call draws them at entry and fixes them by the fold's position in the design, as `vignette("nested-cv")` explains under Reproducibility."

5. Rule 3.6: "Active voice."
   Text: "That description is stored on the object as attributes rather than columns."
   Rewrite: "The call stores that description on the object as attributes rather than columns."

6. Rule GR-3: "clear pronoun referents"
   Text: "It is not the final model's parameters, which come from `nested_final_fit()` running the procedure once more on the whole dataset."
   Rewrite: "That row is not the final model's parameters. Those come from `nested_final_fit()`, which runs the procedure once more on the whole dataset."

7. Rule 3.6: "Active voice."
   Text: "The other folds keep their results, and the fold that failed is recorded rather than dropped."
   Rewrite: "The other folds keep their results, and the object records the fold that failed rather than drops it."

8. Rule 6.6: "Maximum six sentences per paragraph."
   Text: "A fold that fails does not end the run. ... The chunk mutes tune's progress messages and keeps its warnings."
   Rewrite: Split the paragraph after "To show that, the workflow below adds a range check on horsepower." so each paragraph holds six sentences or fewer.

9. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ... never as a verb."
   Text: "Adding a column, as below, keeps the class."
   Rewrite: "A verb that adds a column, as below, keeps the class."

10. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ... never as a verb."
    Text: "Dropping a fold sheds it."
    Rewrite: "A verb that drops a fold sheds the class."

11. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ... never as a verb."
    Text: "The natural case is keeping only the folds that completed on the run above, which removes one row."
    Rewrite: "The natural case keeps only the folds that completed on the run above, which removes one row."

12. Rule 9.4: "Keep one consistent style and terminology through the whole document." (Word choice: since to because)
    Text: "Dropping the columns the run wrote sheds it too, here through base `[` rather than a dplyr verb, since the same rule governs it."
    Rewrite: "A verb that drops the columns the run wrote sheds the class too. The example below uses base `[` rather than a dplyr verb, because the same rule governs it."

13. Rule 3.4: "No present perfect."
    Text: "A table that has lost a fold, or lost the columns the run wrote, cannot describe itself as a five-fold design, so it stops describing itself."
    Rewrite: "A table that lost a fold, or lost the columns the run wrote, cannot describe itself as a five-fold design. So it stops."

14. Rule 3.6: "Active voice."
    Text: "Both are described on `?nested_tune_grid`."
    Rewrite: "`?nested_tune_grid` describes both arguments."

## vignettes/articles/parallel.Rmd

1. Rule 3.6: "Active voice."
   Text: "`nested_tune_grid()` and its siblings run them on [mirai](https://mirai.r-lib.org/) daemons, separate R processes, when a pool of daemons is connected."
   Rewrite: "`nested_tune_grid()` and its siblings run them on [mirai](https://mirai.r-lib.org/) daemons, separate R processes, when you connect a pool of daemons."

2. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ... never as a verb."
   Text: "You switch parallelism on by connecting daemons and off by disconnecting them."
   Rewrite: "Connect daemons to switch parallelism on. Disconnect them to switch it off."

3. Rule 9.4: "Keep one consistent style and terminology through the whole document." (Word choice: since to because)
   Text: "So the first parallel call after starting a pool is the slow one, since it makes each daemon load the tidymodels stack."
   Rewrite: "So the first parallel call after you start a pool is the slow one, because it makes each daemon load the tidymodels stack."

4. Rule 3.6: "Active voice."
   Text: "With a pool connected, the outer folds are sent to the daemons."
   Rewrite: "When you connect a pool, the call sends the outer folds to the daemons."

5. Rule 3.6: "Active voice."
   Text: "Each outer fold's seeds are drawn from the session state at entry, before anything is dispatched."
   Rewrite: "The call draws each outer fold's seeds from the session state at entry, before it dispatches anything."

6. Rule 6.3: "Maximum 25 words per sentence."
   Text: "Neither result records whether daemons were used, so a script gives the same answer on a laptop with no daemons and on a workstation with many."
   Rewrite: "Neither result records whether the run used daemons. So a script gives the same answer on a laptop with no daemons and on a workstation with many."

7. Rule 3.5: "Use an "-ing" form only as a technical noun or inside one ... never as a verb."
   Text: "This page shows the parallel path working and its result matching the serial one, not a speedup."
   Rewrite: "This page shows that the parallel path works and that its result matches the serial one. It does not show a speedup."

## README.Rmd

1. Rule 9.4: "Keep one consistent style and terminology through the whole document." (Word choice: since to because)
   Text: "That score is optimistic, since you picked the winner for scoring well."
   Rewrite: "That score is optimistic, because you picked the winner for its good score."

2. Rule 6.6: "Maximum six sentences per paragraph."
   Text: "You tune a model with cross-validation and keep the setting with the best score. ... It keeps what every fold chose."
   Rewrite: Split the paragraph after "nestedtune gives you an honest number instead." so each paragraph holds six sentences or fewer.

3. Rule 3.6: "Active voice."
   Text: "The model to deploy is fitted afterwards by the same procedure on all the data."
   Rewrite: "You fit the model to deploy afterwards, with the same procedure on all the data."

4. Rule 4.3: "Use a vertical list for complex text: colon on the lead-in, uppercase start, a period only on full-sentence items."
   Text: "- [Nested cross-validation](https://nestedtune.tidymodels.org/articles/nested-cv.html),
  the path from a design to a write-up."
   Rewrite: "- [Nested cross-validation](https://nestedtune.tidymodels.org/articles/nested-cv.html) walks the path from a design to a write-up." Give every item of the list the same full-sentence form with an uppercase start.
