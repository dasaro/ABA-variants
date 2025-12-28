#!/usr/bin/env python3
"""
Verification script for grounding optimizations.
Compares old vs new implementations on:
- Semantic equivalence (same optimal solutions)
- Grounding size (rules, atoms)
- Execution time
"""

import subprocess
import json
import time
from pathlib import Path
from typing import Dict, List, Tuple

# Test configurations
FRAMEWORKS = [
    "benchmark/frameworks/complete/complete_a10_r2_d1_random_tight.lp",
    "benchmark/frameworks/cycle/cycle_a10_r2_d1_c3_random_tight.lp",
    "benchmark/frameworks/tree/tree_a10_r2_d1_random_tight.lp",
]

SEMIRINGS = ["godel", "tropical", "lukasiewicz", "arctic", "bottleneck_cost"]
MONOIDS = ["max_minimization", "sum_minimization", "count_minimization"]

WABA_ROOT = Path(__file__).parent.parent
SEMANTICS = "semantics/stable.lp"
FILTER = "filter/standard.lp"

def run_clingo(core: str, semiring: str, monoid: str, framework: str) -> Dict:
    """Run clingo and extract metrics."""
    cmd = [
        "clingo",
        "--opt-mode=opt",
        "--stats=2",
        core,
        f"semiring/{semiring}.lp",
        f"monoid/{monoid}.lp",
        FILTER,
        SEMANTICS,
        framework
    ]

    start_time = time.time()
    try:
        result = subprocess.run(
            cmd,
            cwd=WABA_ROOT,
            capture_output=True,
            text=True,
            timeout=10
        )
        elapsed = time.time() - start_time

        # Parse output
        output = result.stdout + result.stderr

        # Extract optimization value
        opt_value = None
        for line in output.split('\n'):
            if line.startswith('Optimization :'):
                opt_value = line.split(':')[1].strip()
                break

        # Extract grounding stats
        rules, atoms = None, None
        for line in output.split('\n'):
            if line.startswith('Rules'):
                rules = int(line.split()[2])
            elif line.startswith('Atoms'):
                atoms = int(line.split()[2])

        # Check if optimum found
        optimum = 'OPTIMUM FOUND' in output
        unsatisfiable = 'UNSATISFIABLE' in output

        return {
            'success': result.returncode == 0 or result.returncode == 30,
            'optimum': optimum,
            'unsatisfiable': unsatisfiable,
            'opt_value': opt_value,
            'rules': rules,
            'atoms': atoms,
            'time': elapsed,
            'timeout': False
        }

    except subprocess.TimeoutExpired:
        return {
            'success': False,
            'optimum': False,
            'unsatisfiable': False,
            'opt_value': None,
            'rules': None,
            'atoms': None,
            'time': 10.0,
            'timeout': True
        }

def compare_results(old: Dict, new: Dict) -> Dict:
    """Compare old vs new results."""
    # Semantic equivalence
    semantic_ok = (
        old['optimum'] == new['optimum'] and
        old['unsatisfiable'] == new['unsatisfiable'] and
        old['opt_value'] == new['opt_value']
    )

    # Grounding improvement
    if old['rules'] and new['rules']:
        rules_delta = new['rules'] - old['rules']
        rules_pct = (rules_delta / old['rules']) * 100
    else:
        rules_delta, rules_pct = None, None

    if old['atoms'] and new['atoms']:
        atoms_delta = new['atoms'] - old['atoms']
        atoms_pct = (atoms_delta / old['atoms']) * 100
    else:
        atoms_delta, atoms_pct = None, None

    # Time improvement
    if old['time'] and new['time']:
        time_delta = new['time'] - old['time']
        speedup = old['time'] / new['time'] if new['time'] > 0 else None
    else:
        time_delta, speedup = None, None

    return {
        'semantic_ok': semantic_ok,
        'rules_delta': rules_delta,
        'rules_pct': rules_pct,
        'atoms_delta': atoms_delta,
        'atoms_pct': atoms_pct,
        'time_delta': time_delta,
        'speedup': speedup
    }

def main():
    """Run verification tests."""
    print("="*80)
    print("GROUNDING OPTIMIZATION VERIFICATION")
    print("="*80)
    print()

    results = []
    total_tests = len(FRAMEWORKS) * len(SEMIRINGS) * len(MONOIDS)
    current = 0

    for framework in FRAMEWORKS:
        fw_name = Path(framework).stem

        for semiring in SEMIRINGS:
            for monoid in MONOIDS:
                current += 1
                print(f"[{current}/{total_tests}] Testing {fw_name[:20]:20} {semiring:15} {monoid:20}... ", end='', flush=True)

                # Run old version (all semirings now have _old backups)
                old = run_clingo("core/baseline/base_old.lp",
                                 semiring + "_old",
                                 monoid, framework)

                # Run new version
                new = run_clingo("core/base.lp", semiring, monoid, framework)

                # Compare
                comparison = compare_results(old, new)

                # Store results
                results.append({
                    'framework': fw_name,
                    'semiring': semiring,
                    'monoid': monoid,
                    'old': old,
                    'new': new,
                    'comparison': comparison
                })

                # Print status
                if comparison['semantic_ok']:
                    if comparison['rules_delta'] and comparison['rules_delta'] < 0:
                        print(f"✓ IMPROVED ({comparison['rules_delta']:+d} rules)")
                    elif comparison['rules_delta'] and comparison['rules_delta'] > 0:
                        print(f"⚠ REGRESSION ({comparison['rules_delta']:+d} rules)")
                    else:
                        print("✓ OK (same size)")
                else:
                    print("✗ SEMANTIC MISMATCH!")

    print()
    print("="*80)
    print("SUMMARY")
    print("="*80)

    # Count results
    semantic_ok = sum(1 for r in results if r['comparison']['semantic_ok'])
    improved = sum(1 for r in results if r['comparison']['rules_delta'] and r['comparison']['rules_delta'] < 0)
    regression = sum(1 for r in results if r['comparison']['rules_delta'] and r['comparison']['rules_delta'] > 0)
    same = sum(1 for r in results if r['comparison']['rules_delta'] == 0)

    print(f"Total tests: {len(results)}")
    print(f"Semantic equivalence: {semantic_ok}/{len(results)} ({semantic_ok/len(results)*100:.1f}%)")
    print(f"Grounding improved: {improved}")
    print(f"Grounding same: {same}")
    print(f"Grounding regressed: {regression}")
    print()

    # Average improvements
    rules_deltas = [r['comparison']['rules_delta'] for r in results if r['comparison']['rules_delta'] is not None]
    atoms_deltas = [r['comparison']['atoms_delta'] for r in results if r['comparison']['atoms_delta'] is not None]
    speedups = [r['comparison']['speedup'] for r in results if r['comparison']['speedup'] is not None]

    if rules_deltas:
        print(f"Average rules change: {sum(rules_deltas)/len(rules_deltas):.1f} ({sum(r['comparison']['rules_pct'] for r in results if r['comparison']['rules_pct'])/len(rules_deltas):.2f}%)")
    if atoms_deltas:
        print(f"Average atoms change: {sum(atoms_deltas)/len(atoms_deltas):.1f} ({sum(r['comparison']['atoms_pct'] for r in results if r['comparison']['atoms_pct'])/len(atoms_deltas):.2f}%)")
    if speedups:
        print(f"Average speedup: {sum(speedups)/len(speedups):.2f}x")
    print()

    # Show any failures
    failures = [r for r in results if not r['comparison']['semantic_ok']]
    if failures:
        print("="*80)
        print("SEMANTIC MISMATCHES:")
        print("="*80)
        for r in failures:
            print(f"{r['framework']} × {r['semiring']} × {r['monoid']}")
            print(f"  Old: opt={r['old']['opt_value']}, optimum={r['old']['optimum']}")
            print(f"  New: opt={r['new']['opt_value']}, optimum={r['new']['optimum']}")
        print()

    # Save detailed results
    output_file = WABA_ROOT / "test" / "verification_results.json"
    with open(output_file, 'w') as f:
        json.dump(results, f, indent=2)

    print(f"Detailed results saved to: {output_file}")

    return 0 if semantic_ok == len(results) else 1

if __name__ == '__main__':
    exit(main())
