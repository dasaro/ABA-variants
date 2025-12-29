#!/bin/bash
# Wrapper script for analysis

cd "$(dirname "$0")/.." || exit 1

python3 -m src.waba_bench.analyzer "$@"
