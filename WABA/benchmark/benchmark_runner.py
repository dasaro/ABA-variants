#!/usr/bin/env python3
"""
DEPRECATED: This file has moved to src/waba_bench/runner.py

This wrapper redirects to the new location for backward compatibility.
Please update your scripts to use the new path.
"""

import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent / 'src'))

# Import and run the new module
from waba_bench import runner

if __name__ == '__main__':
    print("⚠ WARNING: benchmark_runner.py is deprecated", file=sys.stderr)
    print("Please use: python3 src/waba_bench/runner.py", file=sys.stderr)
    print("Or: ./scripts/run_benchmark.sh", file=sys.stderr)
    print("", file=sys.stderr)

    # Run the new module
    sys.exit(runner.main())
