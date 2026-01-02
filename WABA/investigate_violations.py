#!/usr/bin/env python3
"""
Deep investigation of semantic inclusion violations
"""

import subprocess
import tempfile

def run_semantic(semantic, framework, beta, show_all=False):
    """Run semantic and return all extensions with full details"""
    # Create budget file
    budget_file = tempfile.NamedTemporaryFile(mode='w', suffix='.lp', delete=False)
    budget_file.write(f'budget({beta}).\n')
    budget_file.close()

    # Determine if maximal semantic
    maximal = semantic in ['preferred', 'semi-stable', 'staged', 'naive']

    # Build command
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

    # Add naive flags
    if semantic == 'naive':
        cmd.extend(['--heuristic=Domain', '--enum-mode=domRec'])

    # Run
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)

    # Clean up
    import os
    os.unlink(budget_file.name)

    # Parse extensions
    extensions = []
    lines = result.stdout.split('\n')

    for i, line in enumerate(lines):
        if line.startswith('Answer:'):
            # Get next line with predicates
            if i + 1 < len(lines):
                next_line = lines[i + 1]
                ext = set()
                discarded = []
                successful = []

                # Extract in(...) predicates
                for word in next_line.split():
                    if word.startswith('in(') and word.endswith(')'):
                        ext.add(word[3:-1])
                    elif 'discarded_attack(' in word:
                        discarded.append(word)
                    elif 'attacks_successfully_with_weight(' in word:
                        successful.append(word)

                if show_all:
                    extensions.append({
                        'assumptions': ext,
                        'discarded': discarded,
                        'successful': successful,
                        'raw': next_line
                    })
                else:
                    extensions.append(ext)

    return extensions

def investigate_case(framework, beta, sem1, sem2):
    """Investigate a specific violation"""
    print(f"\n{'='*80}")
    print(f"INVESTIGATING: {sem1} ⊆ {sem2}")
    print(f"Framework: {framework}")
    print(f"Beta: {beta}")
    print(f"{'='*80}\n")

    # Get extensions
    ext1 = run_semantic(sem1, framework, beta, show_all=True)
    ext2 = run_semantic(sem2, framework, beta, show_all=True)

    print(f"{sem1.upper()} Extensions ({len(ext1)}):")
    for i, e in enumerate(ext1, 1):
        print(f"  {i}. {set(e['assumptions']) if e['assumptions'] else '∅'}")
        if e['discarded']:
            print(f"     Discarded: {len(e['discarded'])} attacks")
        if e['successful']:
            print(f"     Successful: {len(e['successful'])} attacks")

    print(f"\n{sem2.upper()} Extensions ({len(ext2)}):")
    for i, e in enumerate(ext2, 1):
        print(f"  {i}. {set(e['assumptions']) if e['assumptions'] else '∅'}")
        if e['discarded']:
            print(f"     Discarded: {len(e['discarded'])} attacks")
        if e['successful']:
            print(f"     Successful: {len(e['successful'])} attacks")

    # Find violations
    ext1_simple = [frozenset(e['assumptions']) for e in ext1]
    ext2_simple = [frozenset(e['assumptions']) for e in ext2]

    violations = [e for e in ext1_simple if e not in ext2_simple]

    if violations:
        print(f"\n⚠️  VIOLATIONS: {len(violations)} {sem1} extensions NOT in {sem2}")
        for v in violations:
            print(f"  - {set(v) if v else '∅'}")

            # Find the full details for this violation
            for e in ext1:
                if frozenset(e['assumptions']) == v:
                    print(f"    Discarded: {e['discarded'][:3]}...")
                    print(f"    Successful: {e['successful'][:3]}...")
                    break
    else:
        print(f"\n✅ No violations: all {sem1} extensions are in {sem2}")

    return violations


# Investigate specific cases
print("\n" + "="*80)
print("DEEP VIOLATION INVESTIGATION")
print("="*80)

# Case 1: staged ⊆ semi-stable on simple framework
investigate_case('test/no_attacks.lp', 0, 'staged', 'semi-stable')

# Case 2: staged ⊆ semi-stable with attacks
investigate_case('test/simple_aba.lp', 0, 'staged', 'semi-stable')

# Case 3: High-beta violation
investigate_case('test/test_beta.lp', 100, 'grounded', 'preferred')
investigate_case('test/test_beta.lp', 100, 'stable', 'semi-stable')

# Case 4: Check if preferred/semi-stable are computing correctly
investigate_case('test/test_beta.lp', 100, 'complete', 'preferred')
