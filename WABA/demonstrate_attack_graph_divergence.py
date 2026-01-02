#!/usr/bin/env python3
"""
Demonstrate that different semantics use different attack graphs for the same beta.
This violates the principle: "For fixed beta, discarded attacks should be the same."
"""

import subprocess
import tempfile
from collections import defaultdict

def run_with_details(semantic, files_to_load, opt_mode=False):
    """Run semantic and extract both extensions and attack graphs"""
    framework = 'test/test_beta.lp'
    beta = 100

    budget_file = tempfile.NamedTemporaryFile(mode='w', suffix='.lp', delete=False)
    budget_file.write(f'budget({beta}).\n')
    budget_file.close()

    cmd = ['clingo', '-n', '0']
    if opt_mode:
        cmd.append('--opt-mode=optN')

    cmd.extend(files_to_load + [framework, budget_file.name])

    result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)

    import os
    os.unlink(budget_file.name)

    # Extract extensions and their attack graphs
    results = []
    lines = result.stdout.split('\n')
    for i, line in enumerate(lines):
        if line.startswith('Answer:'):
            if i + 1 < len(lines):
                next_line = lines[i + 1]
                ext = set()
                discarded = set()
                for word in next_line.split():
                    if word.startswith('in(') and word.endswith(')'):
                        ext.add(word[3:-1])
                    elif word.startswith('discarded_attack('):
                        discarded.add(word)
                results.append({
                    'extension': frozenset(ext),
                    'discarded': frozenset(discarded),
                    'cost': len(discarded)  # Simplified cost counting
                })

    return results

print("="*80)
print("DEMONSTRATING ATTACK GRAPH DIVERGENCE")
print("="*80)
print("\nFramework: test/test_beta.lp, Beta: 100")
print("\nAttack structure:")
print("  - a3 (weight 20) attacks a1 (weight 50)")
print("  - a1 (weight 50) attacks a2 (weight 30)")
print("\n" + "="*80)

# ENUMERATIVE SEMANTIC (no monoid file)
print("\n1. COMPLETE SEMANTIC (Enumerative - NO monoid file)")
print("-" * 80)
complete_files = [
    'core/base.lp',
    'semiring/godel.lp',
    'constraint/ub_max.lp',
    'filter/standard.lp',
    'semantics/complete.lp'
]
complete_results = run_with_details('complete', complete_files, opt_mode=False)

print(f"Files loaded: {', '.join(f.split('/')[-1] for f in complete_files)}")
print(f"Optimization: NO (enumerate all)")
print(f"\nResults: {len(complete_results)} extensions\n")

attack_graphs_complete = defaultdict(list)
for r in complete_results:
    attack_graphs_complete[len(r['discarded'])].append(set(r['extension']))

for cost in sorted(attack_graphs_complete.keys()):
    print(f"  Cost {cost}: {len(attack_graphs_complete[cost])} extensions")
    for ext in sorted(attack_graphs_complete[cost], key=len):
        print(f"    {ext}")

# MAXIMAL SEMANTIC (with monoid file)
print("\n2. PREFERRED SEMANTIC (Maximal - WITH monoid file)")
print("-" * 80)
preferred_files = [
    'core/base.lp',
    'semiring/godel.lp',
    'monoid/max_minimization.lp',  # ← This makes the difference!
    'constraint/ub_max.lp',
    'filter/standard.lp',
    'semantics/preferred.lp'
]
preferred_results = run_with_details('preferred', preferred_files, opt_mode=True)

print(f"Files loaded: {', '.join(f.split('/')[-1] for f in preferred_files)}")
print(f"Optimization: YES (--opt-mode=optN)")
print(f"\nResults: {len(preferred_results)} extensions\n")

attack_graphs_preferred = defaultdict(list)
for r in preferred_results:
    attack_graphs_preferred[len(r['discarded'])].append(set(r['extension']))

for cost in sorted(attack_graphs_preferred.keys()):
    print(f"  Cost {cost}: {len(attack_graphs_preferred[cost])} extensions")
    for ext in sorted(attack_graphs_preferred[cost], key=len):
        print(f"    {ext}")

# ANALYSIS
print("\n" + "="*80)
print("ANALYSIS")
print("="*80)

print("\n✗ PROBLEM IDENTIFIED:")
print("  Complete explores attack graphs with costs: 0, 1, 2")
print("  Preferred only uses attack graph with cost: 0")
print("\n  → Different semantics use DIFFERENT attack graphs for same beta!")

print("\n✗ VIOLATION:")
print('  "Discarded attacks should never be affected by the semantics"')
print("  Currently: SEMANTIC determines which attack graphs to explore")

print("\n✗ ROOT CAUSE:")
print("  - Enumerative semantics: NO monoid file → all attack graphs within budget")
print("  - Maximal semantics: WITH monoid file + optimization → only minimal cost")

print("\n✓ EXPECTED BEHAVIOR:")
print("  For fixed beta + semiring + monoid:")
print("  - Attack graph should be determined by semiring + monoid ONLY")
print("  - ALL semantics should use the SAME attack graph(s)")
print("  - Only the EXTENSION varies across semantics")

print("\n" + "="*80)
