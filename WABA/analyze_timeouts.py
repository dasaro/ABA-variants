#!/usr/bin/env python3
"""Analyze which frameworks timeout for which semantics"""
import subprocess
from pathlib import Path
import random

def test_semantic(semantic, framework, timeout=5):
    """Test one semantic on one framework, return True if completed"""
    cmd = ['clingo', '-n', '0', '--project', '-c', 'beta=0',
           'core/base.lp', 'semiring/godel.lp', 'filter/standard.lp',
           f'semantics/{semantic}.lp', framework]

    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return r.returncode in [0, 10, 20, 30]
    except subprocess.TimeoutExpired:
        return False
    except Exception:
        return False

# Collect frameworks
frameworks = []
for f in Path('test/strict_inclusions').glob('*.lp'):
    frameworks.append(str(f))

bench_files = list(Path('benchmark/frameworks').rglob('*.lp'))
random.seed(42)
sampled_bench = random.sample(bench_files, min(100, len(bench_files)))
frameworks.extend([str(f) for f in sampled_bench])

print(f"Analyzing {len(frameworks)} frameworks across 5 semantics...")
print("="*80)

semantics = ['grounded', 'semi-stable', 'preferred', 'staged', 'naive']

# Track which frameworks timeout for which semantics
timeout_matrix = {fw: {sem: False for sem in semantics} for fw in frameworks}

for i, fw in enumerate(frameworks):
    if (i+1) % 20 == 0:
        print(f"Progress: {i+1}/{len(frameworks)}")

    for sem in semantics:
        completed = test_semantic(sem, fw)
        timeout_matrix[fw][sem] = not completed

# Analysis
print("\n" + "="*80)
print("TIMEOUT ANALYSIS")
print("="*80)

# Frameworks that timeout for ALL semantics
all_timeout = [fw for fw, results in timeout_matrix.items()
               if all(results.values())]
print(f"\nFrameworks that timeout for ALL semantics: {len(all_timeout)}")
for fw in all_timeout:
    print(f"  - {Path(fw).name}")

# Frameworks that timeout ONLY for staged/naive
staged_naive_only = [fw for fw, results in timeout_matrix.items()
                     if results['staged'] and results['naive']
                     and not results['grounded']
                     and not results['semi-stable']
                     and not results['preferred']]
print(f"\nFrameworks that timeout ONLY for staged/naive: {len(staged_naive_only)}")
for fw in staged_naive_only[:10]:
    print(f"  - {Path(fw).name}")
if len(staged_naive_only) > 10:
    print(f"  ... and {len(staged_naive_only)-10} more")

# Per-semantic timeout counts
print(f"\nTimeout counts by semantic:")
for sem in semantics:
    count = sum(1 for results in timeout_matrix.values() if results[sem])
    print(f"  {sem:15s}: {count:3d}/{len(frameworks)} ({100*count/len(frameworks):.1f}%)")
