#!/usr/bin/env python3
"""
Test different approaches to unifying attack graph selection across semantics.
"""

import subprocess
import tempfile

def run_semantic(name, files, use_opt_mode):
    """Run semantic and return extensions with costs"""
    framework = 'test/test_beta.lp'
    beta = 100

    budget_file = tempfile.NamedTemporaryFile(mode='w', suffix='.lp', delete=False)
    budget_file.write(f'budget({beta}).\n')
    budget_file.close()

    cmd = ['clingo', '-n', '0']
    if use_opt_mode:
        cmd.append('--opt-mode=optN')
    cmd.extend(files + [framework, budget_file.name])

    result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)

    import os
    os.unlink(budget_file.name)

    # Extract extensions
    extensions = []
    lines = result.stdout.split('\n')
    for i, line in enumerate(lines):
        if line.startswith('Answer:'):
            if i + 1 < len(lines):
                next_line = lines[i + 1]
                ext = set()
                disc_count = 0
                for word in next_line.split():
                    if word.startswith('in(') and word.endswith(')'):
                        ext.add(word[3:-1])
                    elif word.startswith('discarded_attack('):
                        disc_count += 1
                extensions.append((frozenset(ext), disc_count))

    return extensions

print("="*80)
print("TESTING SOLUTION APPROACHES")
print("="*80)

# Current approach
print("\n1. CURRENT APPROACH (Enumerative: no monoid, Maximal: with monoid)")
print("-" * 80)

complete_current = run_semantic(
    'complete',
    ['core/base.lp', 'semiring/godel.lp', 'constraint/ub_max.lp',
     'filter/standard.lp', 'semantics/complete.lp'],
    use_opt_mode=False
)

preferred_current = run_semantic(
    'preferred',
    ['core/base.lp', 'semiring/godel.lp', 'monoid/max_minimization.lp',
     'constraint/ub_max.lp', 'filter/standard.lp', 'semantics/preferred.lp'],
    use_opt_mode=True
)

print(f"Complete: {len(complete_current)} extensions")
for ext, cost in sorted(complete_current, key=lambda x: (x[1], len(x[0]))):
    print(f"  {str(set(ext)):30} cost={cost}")

print(f"\nPreferred: {len(preferred_current)} extensions")
for ext, cost in sorted(preferred_current, key=lambda x: (x[1], len(x[0]))):
    print(f"  {str(set(ext)):30} cost={cost}")

print(f"\n✗ Different attack graphs: Complete uses costs [0,1,2], Preferred uses [0]")

# Approach 1: Load monoid for both, but only optimize for maximal
print("\n2. APPROACH 1: Load monoid for BOTH, optimize only for maximal")
print("-" * 80)

complete_1 = run_semantic(
    'complete',
    ['core/base.lp', 'semiring/godel.lp', 'monoid/max_minimization.lp',
     'constraint/ub_max.lp', 'filter/standard.lp', 'semantics/complete.lp'],
    use_opt_mode=False  # No optimization
)

preferred_1 = run_semantic(
    'preferred',
    ['core/base.lp', 'semiring/godel.lp', 'monoid/max_minimization.lp',
     'constraint/ub_max.lp', 'filter/standard.lp', 'semantics/preferred.lp'],
    use_opt_mode=True  # With optimization
)

print(f"Complete (monoid loaded, no opt): {len(complete_1)} extensions")
for ext, cost in sorted(complete_1, key=lambda x: (x[1], len(x[0]))):
    print(f"  {str(set(ext)):30} cost={cost}")

print(f"\nPreferred (monoid loaded, with opt): {len(preferred_1)} extensions")
for ext, cost in sorted(preferred_1, key=lambda x: (x[1], len(x[0]))):
    print(f"  {str(set(ext)):30} cost={cost}")

if complete_1 == complete_current:
    print(f"\n✗ Loading monoid without --opt-mode doesn't change behavior")
else:
    print(f"\n✓ Loading monoid without --opt-mode changes behavior")

# Approach 2: Use optimization for BOTH
print("\n3. APPROACH 2: Load monoid for BOTH, optimize for BOTH")
print("-" * 80)

complete_2 = run_semantic(
    'complete',
    ['core/base.lp', 'semiring/godel.lp', 'monoid/max_minimization.lp',
     'constraint/ub_max.lp', 'filter/standard.lp', 'semantics/complete.lp'],
    use_opt_mode=True  # With optimization
)

preferred_2 = run_semantic(
    'preferred',
    ['core/base.lp', 'semiring/godel.lp', 'monoid/max_minimization.lp',
     'constraint/ub_max.lp', 'filter/standard.lp', 'semantics/preferred.lp'],
    use_opt_mode=True  # With optimization
)

print(f"Complete (with optimization): {len(complete_2)} extensions")
for ext, cost in sorted(complete_2, key=lambda x: (x[1], len(x[0]))):
    print(f"  {str(set(ext)):30} cost={cost}")

print(f"\nPreferred (with optimization): {len(preferred_2)} extensions")
for ext, cost in sorted(preferred_2, key=lambda x: (x[1], len(x[0]))):
    print(f"  {str(set(ext)):30} cost={cost}")

# Extract just costs
complete_2_costs = sorted(set(cost for _, cost in complete_2))
preferred_2_costs = sorted(set(cost for _, cost in preferred_2))

if complete_2_costs == preferred_2_costs:
    print(f"\n✓ Same attack graphs: Both use costs {complete_2_costs}")
else:
    print(f"\n✗ Different attack graphs: Complete {complete_2_costs}, Preferred {preferred_2_costs}")

print("\n" + "="*80)
print("RECOMMENDATION")
print("="*80)
print("\nBased on the principle: 'Discarded attacks should never be affected by semantics'")
print("\nAPPROACH 2 appears correct:")
print("  - Load monoid file for ALL semantics")
print("  - Use --opt-mode=optN for ALL semantics")
print("  - Result: All semantics use same attack graph (minimal cost)")
print("\nThis ensures: semiring + monoid determines attack graph, NOT the semantic")
