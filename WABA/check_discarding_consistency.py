#!/usr/bin/env python3
"""
Check if different semantics use the same attack discarding for fixed beta
"""

import subprocess
import tempfile
from collections import defaultdict

def get_discarded_attacks(semantic, framework, beta):
    """Get all discarded attacks for a semantic"""
    budget_file = tempfile.NamedTemporaryFile(mode='w', suffix='.lp', delete=False)
    budget_file.write(f'budget({beta}).\n')
    budget_file.close()

    # Determine if maximal semantic
    maximal = semantic in ['preferred', 'semi-stable', 'staged', 'naive']

    if maximal:
        cmd = [
            'clingo', '-n', '0', '--opt-mode=optN',
            'core/base.lp', 'semiring/godel.lp', 'monoid/max_minimization.lp',
            'constraint/ub_max.lp', f'semantics/{semantic}.lp', framework,
            budget_file.name, f'-c', f'beta={beta}'
        ]
    else:
        cmd = [
            'clingo', '-n', '0',
            'core/base.lp', 'semiring/godel.lp', 'constraint/ub_max.lp',
            f'semantics/{semantic}.lp', framework,
            budget_file.name, f'-c', f'beta={beta}'
        ]

    if semantic == 'naive':
        cmd.extend(['--heuristic=Domain', '--enum-mode=domRec'])

    result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)

    import os
    os.unlink(budget_file.name)

    # Extract all unique discarded_attack sets across all answer sets
    discarding_sets = []
    lines = result.stdout.split('\n')

    for i, line in enumerate(lines):
        if line.startswith('Answer:'):
            if i + 1 < len(lines):
                next_line = lines[i + 1]
                discarded = set()
                for word in next_line.split():
                    if word.startswith('discarded_attack('):
                        # Extract the attack
                        discarded.add(word.split('discarded_attack(')[1].rstrip(')'))
                discarding_sets.append(frozenset(discarded))

    return set(discarding_sets)  # Unique discarding sets

# Test on problematic framework
framework = 'test/test_beta.lp'
beta = 100

print("="*80)
print(f"CHECKING ATTACK DISCARDING CONSISTENCY")
print(f"Framework: {framework}, Beta: {beta}")
print("="*80)

semantics = ['cf', 'admissible', 'complete', 'grounded', 'stable',
             'preferred', 'semi-stable', 'staged', 'naive']

results = {}
for sem in semantics:
    try:
        discarding_sets = get_discarded_attacks(sem, framework, beta)
        results[sem] = discarding_sets
        print(f"\n{sem.upper()}:")
        print(f"  Found {len(discarding_sets)} different attack discarding patterns")
        for i, ds in enumerate(sorted(discarding_sets, key=lambda x: len(x)), 1):
            if len(ds) == 0:
                print(f"    {i}. No attacks discarded")
            else:
                print(f"    {i}. Discarded: {sorted(list(ds))[:3]}{'...' if len(ds) > 3 else ''} (total: {len(ds)})")
    except Exception as e:
        print(f"\n{sem.upper()}: ERROR - {e}")

# Check consistency
print("\n" + "="*80)
print("CONSISTENCY CHECK")
print("="*80)

all_patterns = set()
for sem, patterns in results.items():
    all_patterns.update(patterns)

print(f"\nTotal unique discarding patterns across all semantics: {len(all_patterns)}")

# Check if all semantics share common patterns
common_patterns = set.intersection(*[results[s] for s in results.keys()])
print(f"Discarding patterns common to ALL semantics: {len(common_patterns)}")

# Find semantics with different patterns
for sem in semantics:
    if sem not in results:
        continue
    unique = results[sem] - set.union(*[results[s] for s in semantics if s != sem and s in results])
    if unique:
        print(f"\n⚠️  {sem} has {len(unique)} UNIQUE discarding patterns not in other semantics!")
        for p in list(unique)[:2]:
            print(f"    {sorted(list(p))[:5]}...")
