# predict() on a nested_results names nested_final_fit()

    Code
      predict(res, new_data = d)
    Condition
      Error in `predict()`:
      ! A <nested_results> has no model to predict with.
      i Its fold models serve the estimate. Fit the model to deploy with `nested_final_fit()`, then call `predict()` on that.

# predict() on a nested_results_set names nested_final_fit()

    Code
      predict(res, new_data = make_reg_data())
    Condition
      Error in `predict()`:
      ! A <nested_results_set> has no model to predict with.
      i Fit one workflow's model with `nested_final_fit()`, naming it with `id`, then call `predict()` on that.

