#!/usr/bin/env python3
"""
Test if using same discarding strategy (optimization) for ALL semantics fixes inclusions
"""

import subprocess
import tempfile

def run_semantic_with_opt(semantic, framework, beta):
    """Run semantic with optimization (forces minimal-cost discarding)"""
    budget_file = tempfile.NamedTemporaryFile(mode='w', suffix='.lp', delete=False)
    budget_file.write(f'budget({beta}).\n')
    budget_file.close()

    # ALL semantics use optimization now
    cmd = [
        'clingo', '-n', '0', '--opt-mode=optN',
        'core/base.lp', 'semiring/godel.lp', 'monoid/max_minimization.lp',
        'constraint/ub_max.lp', f'semantics/{semantic}.lp', framework,
        budget_file.name, f'-c', f'beta={beta}'
    ]

    if semantic == 'naive':
        cmd.extend(['--heuristic=Domain', '--enum-mode=domRec'])

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
                for word in next_line.split():
                    if word.startswith('in(') and word.endswith(')'):
                        ext.add(word[3:-1])
                extensions.append(frozenset(ext))

    return set(extensions)

# Test on problematic framework
framework = 'test/test_beta.lp'
beta = 100

print("Testing with UNIFIED discarding (all semantics use optimization)")
print(f"Framework: {framework}, Beta: {beta}\n")

# Get extensions
grounded = run_semantic_with_opt('grounded', framework, beta)
complete = run_semantic_with_opt('complete', framework, beta)
preferred = run_semantic_with_opt('preferred', framework, beta)
stable = run_semantic_with_opt('stable', framework, beta)
semi_stable = run_semantic_with_opt('semi-stable', framework, beta)

print(f"Grounded:    {[set(e) for e in sorted(grounded, key=len)]}")
print(f"Complete:    {[set(e) for e in sorted(complete, key=len)]}")
print(f"Preferred:   {[set(e) for e in sorted(preferred, key=len)]}")
print(f"Stable:      {[set(e) for e in sorted(stable, key=len)]}")
print(f"Semi-stable: {[set(e) for e in sorted(semi_stable, key=len)]}")

# Check inclusions
print("\nInclusion checks:")
violations = []

if not grounded.issubset(complete):
    violations.append("grounded ⊆ complete")
    print("❌ grounded ⊆ complete VIOLATED")
    print(f"   {grounded - complete} in grounded but not in complete")
else:
    print("✅ grounded ⊆ complete")

if not grounded.issubset(preferred):
    violations.append("grounded ⊆ preferred")
    print("❌ grounded ⊆ preferred VIOLATED")
    print(f"   {grounded - preferred} in grounded but not in preferred")
else:
    print("✅ grounded ⊆ preferred")

if not complete.issubset(preferred):
    violations.append("complete ⊆ preferred")
    print("❌ complete ⊆ preferred VIOLATED")
    print(f"   {complete - preferred} in complete but not in preferred")
else:
    print("✅ complete ⊆ preferred")

if not stable.issubset(semi_stable):
    violations.append("stable ⊆ semi-stable")
    print("❌ stable ⊆ semi-stable VIOLATED")
    print(f"   {stable - semi_stable} in stable but not in semi-stable")
else:
    print("✅ stable ⊆ semi-stable")

if not preferred.issubset(semi_stable):
    violations.append("preferred ⊆ semi-stable")
    print("❌ preferred ⊆ semi-stable VIOLATED")
    print(f"   {preferred - semi_stable} in preferred but not in semi-stable")
else:
    print("✅ preferred ⊆ semi-stable")

print(f"\nResult: {len(violations)} violations")
