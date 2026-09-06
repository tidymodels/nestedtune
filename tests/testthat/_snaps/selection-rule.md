# the object prints on one line naming the rule, orderings and limit

    Code
      selection_rule()
    Output
      <selection_rule> best
    Code
      selection_rule("one_std_err", desc(df1), df2)
    Output
      <selection_rule> one_std_err by desc(df1), df2
    Code
      selection_rule("pct_loss", df1, limit = 5)
    Output
      <selection_rule> pct_loss by df1 (limit = 5)

