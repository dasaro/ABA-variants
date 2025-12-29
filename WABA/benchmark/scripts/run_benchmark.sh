#!/bin/bash
# Wrapper script for benchmark runner

cd "$(dirname "$0")/.." || exit 1

python3 -m src.waba_bench.runner "$@"
