#!/bin/bash
python3 benchmark_runner.py \
  --plan plan.jsonl \
  --frameworks-dir frameworks_v4 \
  --semirings godel tropical arctic lukasiewicz bottleneck_cost \
  --monoids max sum min count \
  --semantics stable \
  --mode enum \
  --timeout-seconds 120 \
  --max-workers 1 \
  --worker-recycle-interval 200 \
  --output results_v4/enum_results.jsonl
