# an unknown type is refused

    Code
      collect_metrics(res, type = "tall")
    Condition
      Error in `collect_metrics()`:
      ! `type` must be "long" or "wide".
      x Got "tall".

# the wide type refuses a metric named like a key column

    Code
      pivot_metrics_wide(long)
    Condition
      Error:
      ! Cannot widen the metrics: a metric is named like a key column: "id".
      i Use `type = "long"` for this run.

