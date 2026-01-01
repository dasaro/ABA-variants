#!/usr/bin/env python3
"""Test semantic diversity frameworks to verify they distinguish between semantics"""

import subprocess
import sys
import os
from pathlib import Path
import re
from collections import defaultdict

os.chdir('/Users/fdasaro/Desktop/WABA-claude/ABA-variants/WABA')

TIMEOUT = 10

def calculate_cost(discarded_attacks):
    if not discarded_attacks:
        return 0
    return max(w for (_, _, w) in discarded_attacks)

def run_clingo(semantic, framework):
    """Run clingo and return list of (assumption_set, discarded_attacks) tuples"""
    base = [
        'clingo', '-n', '0', '--opt-mode=enum',
        'core/base.lp', 'semiring/godel.lp', 'monoid/max_minimization.lp',
        'constraint/ub_max.lp', 'filter/standard.lp'
    ]

    if semantic == 'naive':
        base.extend(['--heuristic=Domain', '--enum-mode=domRec'])

    cmd = base + [f'semantics/{semantic}.lp', framework]

    try:
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                              text=True, timeout=TIMEOUT)

        extensions = []
        in_answer = False
        current_in = set()
        current_discarded = []

        for line in result.stdout.split('\n'):
            if line.startswith('Answer:'):
                if current_in or current_discarded:
                    extensions.append((frozenset(current_in), tuple(sorted(current_discarded))))
                current_in = set()
                current_discarded = []
                in_answer = True
            elif line.startswith(('Optimization:', 'SATISFIABLE', 'UNSATISFIABLE', 'Models')):
                if in_answer and (current_in or current_discarded):
                    extensions.append((frozenset(current_in), tuple(sorted(current_discarded))))
                    current_in = set()
                    current_discarded = []
                in_answer = False
            elif in_answer and line.strip():
                for match in re.finditer(r'in\((\w+)\)', line):
                    current_in.add(match.group(1))
                for match in re.finditer(r'discarded_attack\((\w+),(\w+),(\d+)\)', line):
                    current_discarded.append((match.group(1), match.group(2), int(match.group(3))))

        if current_in or current_discarded:
            extensions.append((frozenset(current_in), tuple(sorted(current_discarded))))

        return extensions

    except subprocess.TimeoutExpired:
        return None
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return []

def group_by_scenario(extensions):
    """Group extensions by discarding scenario, return {scenario: [assumption_sets]}"""
    by_scenario = defaultdict(set)
    for ext_set, disc in extensions:
        by_scenario[disc].add(ext_set)
    return by_scenario

def analyze_framework(framework_path):
    """Analyze a framework across multiple semantics"""
    fw_name = Path(framework_path).name

    print(f"\n{'='*80}")
    print(f"Framework: {fw_name}")
    print('='*80)

    semantics = ['grounded', 'stable', 'semi-stable', 'preferred', 'complete', 'admissible']

    results = {}

    for sem in semantics:
        exts = run_clingo(sem, framework_path)
        if exts is None:
            print(f"{sem:15s}: TIMEOUT")
            results[sem] = None
        else:
            scenarios = group_by_scenario(exts)
            results[sem] = scenarios

            # Count total extensions and scenarios
            total_exts = len(exts)
            num_scenarios = len(scenarios)

            print(f"\n{sem.upper()}:")
            print(f"  Total extensions: {total_exts}")
            print(f"  Attack scenarios: {num_scenarios}")

            if num_scenarios <= 5:  # Only show details for small number of scenarios
                for i, (disc, assumption_sets) in enumerate(sorted(scenarios.items()), 1):
                    print(f"  Scenario {i}: {len(disc)} attacks discarded, {len(assumption_sets)} extension(s)")
                    for s in sorted(assumption_sets, key=lambda x: sorted(x)):
                        print(f"    {sorted(s) if s else '∅'}")

    # Analyze semantic relationships
    print(f"\n{'='*80}")
    print("SEMANTIC ANALYSIS")
    print('='*80)

    # Check for semantic diversity (different extension counts per scenario)
    if results['complete'] and results['grounded']:
        complete_scenarios = results['complete']
        grounded_scenarios = results['grounded']

        # For each scenario, check if grounded and complete differ
        all_scenarios = set(complete_scenarios.keys()) | set(grounded_scenarios.keys())

        diversity_found = False
        for scenario in sorted(all_scenarios):
            c_exts = complete_scenarios.get(scenario, set())
            g_exts = grounded_scenarios.get(scenario, set())

            if len(c_exts) != len(g_exts) or c_exts != g_exts:
                diversity_found = True
                print(f"\n✓ DIVERSITY FOUND (scenario with {len(scenario)} discarded attacks):")
                print(f"  Grounded: {len(g_exts)} extension(s)")
                for s in sorted(g_exts, key=lambda x: sorted(x)):
                    print(f"    {sorted(s) if s else '∅'}")
                print(f"  Complete: {len(c_exts)} extension(s)")
                for s in sorted(c_exts, key=lambda x: sorted(x)):
                    print(f"    {sorted(s) if s else '∅'}")

        if not diversity_found:
            print("\n✗ NO DIVERSITY: Grounded = Complete in all scenarios")

    # Check preferred vs semi-stable
    if results['preferred'] and results['semi-stable']:
        pref_scenarios = results['preferred']
        semi_scenarios = results['semi-stable']

        all_scenarios = set(pref_scenarios.keys()) | set(semi_scenarios.keys())

        diversity_found = False
        for scenario in sorted(all_scenarios):
            p_exts = pref_scenarios.get(scenario, set())
            s_exts = semi_scenarios.get(scenario, set())

            if len(p_exts) != len(s_exts) or p_exts != s_exts:
                diversity_found = True
                print(f"\n✓ DIVERSITY FOUND (scenario with {len(scenario)} discarded attacks):")
                print(f"  Semi-stable: {len(s_exts)} extension(s)")
                for ext in sorted(s_exts, key=lambda x: sorted(x)):
                    print(f"    {sorted(ext) if ext else '∅'}")
                print(f"  Preferred: {len(p_exts)} extension(s)")
                for ext in sorted(p_exts, key=lambda x: sorted(x)):
                    print(f"    {sorted(ext) if ext else '∅'}")

        if not diversity_found:
            print("\n✗ NO DIVERSITY: Semi-stable = Preferred in all scenarios")

# Test all frameworks
frameworks_dir = Path('test/semantic_diversity')
frameworks = sorted(frameworks_dir.glob('*.lp'))

print("="*80)
print("SEMANTIC DIVERSITY FRAMEWORK TESTING")
print("="*80)
print(f"\nTesting {len(frameworks)} frameworks...")

for fw in frameworks:
    analyze_framework(str(fw))

print("\n" + "="*80)
print("TESTING COMPLETE")
print("="*80)
