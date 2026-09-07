# AC4: print names the orchestrator, the workflow count and each workflow's fold counts

    Code
      print(res)
    Message
      
      -- Nested cross-validation results for a workflow set --------------------------
      Orchestrator: `nested_tune_grid()` (grid search)
      Workflows: 2
      v "tuned": 2 of 2 outer folds completed (grid search)
      v "fixed": 2 of 2 outer folds completed (no tuning)
      i Use `collect_metrics()` for every workflow's estimate under its id, and
        `x$result[[i]]` for one workflow's run.

---

    Code
      print(partial)
    Message
      
      -- Nested cross-validation results for a workflow set --------------------------
      Orchestrator: `nested_tune_grid()` (grid search)
      Workflows: 2
      x "tuned": 1 of 2 outer folds completed (grid search)
      x "fixed": 1 of 2 outer folds completed (no tuning)
      i Use `collect_metrics()` for every workflow's estimate under its id, and
        `x$result[[i]]` for one workflow's run.

