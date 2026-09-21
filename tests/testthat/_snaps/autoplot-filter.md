# a metric or time the run did not score is refused

    Code
      autoplot(res, type = "performance", metric = c("rmse", "brier_survival"))
    Condition
      Error in `autoplot()`:
      ! `metric` names a metric the run did not score: "rmse".
      i It scored "brier_survival" and "concordance_survival".
    Code
      autoplot(res, type = "performance", eval_time = 3)
    Condition
      Error in `autoplot()`:
      ! `eval_time` names a time the run did not score at: 3.
      i It scored at 0.5 and 10.

# either argument with the parameters view is refused

    Code
      autoplot(res, metric = "sens", eval_time = 1)
    Condition
      Error in `autoplot()`:
      ! `metric` and `eval_time` are only used with `type = "performance"`.
      i The parameters view draws what each fold selected, not its metrics.

