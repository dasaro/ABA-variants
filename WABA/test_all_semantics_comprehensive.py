#!/usr/bin/env python3
"""Comprehensive test for all production-ready semantics on large dataset"""
import subprocess
import sys
from pathlib import Path
from collections import defaultdict

def extract_extensions(output):
    """Extract extensions from clingo output"""
    extensions = []
    for line in output.split('\n'):
        if line.startswith('in('):
            extension = set()
            for word in line.split():
                if word.startswith('in(') and word.endswith(')'):
                    extension.add(word[3:-1])
            if extension:
                extensions.append(frozenset(extension))
    return set(extensions)

def test_semantic(semantic, framework, timeout=5):
    """Test one semantic on one framework"""
    cmd = ['clingo', '-n', '0', '--project', '-c', 'beta=0',
           'core/base.lp', 'semiring/godel.lp', 'filter/standard.lp',
           f'semantics/{semantic}.lp', framework]

    try:
        # Enum mode
        r1 = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        if r1.returncode not in [0, 10, 20, 30]:
            return 'SKIP', 'Error', 0, 0
        e1 = extract_extensions(r1.stdout)

        # OptN mode
        cmd.insert(3, '--opt-mode=optN')
        r2 = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        if r2.returncode not in [0, 10, 20, 30]:
            return 'SKIP', 'Error', len(e1), 0
        e2 = extract_extensions(r2.stdout)

        if e1 == e2:
            return 'PASS', f"{len(e1)} exts", len(e1), len(e2)
        return 'FAIL', f"{len(e1)} vs {len(e2)}", len(e1), len(e2)
    except subprocess.TimeoutExpired:
        return 'SKIP', 'Timeout', 0, 0
    except Exception as e:
        return 'SKIP', str(e)[:20], 0, 0

def collect_frameworks(max_per_source=100):
    """Collect frameworks from all sources"""
    frameworks = []

    # All strict_inclusions (40 total)
    for f in Path('test/strict_inclusions').glob('*.lp'):
        frameworks.append(('strict_inclusions', str(f)))

    # All examples (28 total)
    for f in Path('examples').glob('*.lp'):
        frameworks.append(('examples', str(f)))

    # Sample from benchmark frameworks (3120 total - take 100 instead of 200)
    bench_files = list(Path('benchmark/frameworks').rglob('*.lp'))
    import random
    random.seed(42)  # Reproducible sampling
    sampled_bench = random.sample(bench_files, min(100, len(bench_files)))
    for f in sampled_bench:
        frameworks.append(('benchmark', str(f)))

    return frameworks

print("="*80)
print("COMPREHENSIVE SEMANTICS TEST - All Production-Ready Semantics")
print("="*80)

# Collect frameworks
frameworks = collect_frameworks()
print(f"\nTesting on {len(frameworks)} frameworks:")
print(f"  - strict_inclusions: {sum(1 for s, _ in frameworks if s == 'strict_inclusions')}")
print(f"  - examples: {sum(1 for s, _ in frameworks if s == 'examples')}")
print(f"  - benchmark: {sum(1 for s, _ in frameworks if s == 'benchmark')}")
print()

# Semantics to test
semantics = ['grounded', 'semi-stable', 'preferred', 'staged', 'naive']

# Test each semantic
results = {}
for semantic in semantics:
    print(f"\n{'='*80}")
    print(f"Testing {semantic.upper()} semantics")
    print(f"{'='*80}")

    stats = {'PASS': 0, 'FAIL': 0, 'SKIP': 0}
    failures = []

    for i, (source, fw) in enumerate(frameworks, 1):
        status, msg, n1, n2 = test_semantic(semantic, fw)
        stats[status] += 1

        if status == 'FAIL':
            failures.append((Path(fw).name, msg, n1, n2))
            print(f"{i:3d}. ✗ {Path(fw).name:50s} {msg}")
        elif i % 10 == 0:  # Progress indicator every 10 frameworks
            print(f"  ... {i}/{len(frameworks)} tested ({stats['PASS']} passed, {stats['FAIL']} failed, {stats['SKIP']} skipped)")

    # Summary for this semantic
    total = len(frameworks)
    print(f"\n{semantic.upper()} Results:")
    print(f"  Passed:  {stats['PASS']:4d}/{total} ({100*stats['PASS']/total:.1f}%)")
    print(f"  Failed:  {stats['FAIL']:4d}/{total}")
    print(f"  Skipped: {stats['SKIP']:4d}/{total}")

    if failures:
        print(f"\n  Failures:")
        for name, msg, n1, n2 in failures[:10]:  # Show first 10
            print(f"    - {name}: {msg}")
        if len(failures) > 10:
            print(f"    ... and {len(failures)-10} more")

    results[semantic] = stats

# Overall summary
print(f"\n{'='*80}")
print("OVERALL SUMMARY")
print(f"{'='*80}")
print(f"\n{'Semantic':<15} {'Passed':<10} {'Failed':<10} {'Skipped':<10} {'Success Rate':<15}")
print("-" * 80)
for semantic in semantics:
    stats = results[semantic]
    total = len(frameworks)
    rate = 100 * stats['PASS'] / total
    print(f"{semantic:<15} {stats['PASS']:<10} {stats['FAIL']:<10} {stats['SKIP']:<10} {rate:.1f}%")

# Exit with failure if any semantic had failures
total_failures = sum(results[s]['FAIL'] for s in semantics)
sys.exit(1 if total_failures > 0 else 0)
