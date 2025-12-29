#!/bin/bash
# Wrapper script for planner.py

cd "$(dirname "$0")/.." || exit 1

python3 -m src.waba_bench.planner "$@"
