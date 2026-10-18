# AC1: verbose = TRUE logs each workflow's start and finish, and the result does not change

    Code
      loud <- nested_workflow_map(wset, verbose = TRUE, resamples = folds, grid = det_grid())
    Message
      i 1 of 2 tuning: tuned
      v 1 of 2 tuning: tuned (<time>)
      i 2 of 2 resampling: fixed
      v 2 of 2 resampling: fixed (<time>)

