#!/usr/bin/env python3
"""
Test semantic inclusions with COST STRATIFICATION.

Key insight: Semantic inclusions should hold WITHIN each cost stratum.
For each cost C, verify: semanticA_extensions(cost=C) ⊆ semanticB_extensions(cost=C)

This approach respects that different attack graphs (different costs) are independent.
"""

import subprocess
import os
from pathlib import Path
from collections import defaultdict

TIMEOUT = 30  # seconds

# Core files
CORE = "core/base.lp"
SEMIRING = "semiring/godel.lp"  # Determines graph structure
MONOID_TYPE = "max"  # For cost calculation: max, sum, count, min
CONSTRAINT = "constraint/ub_max.lp"  # Budget constraint
FILTER = "filter/standard.lp"

# Semantics that require optimization (maximal semantics)
MAXIMAL_SEMANTICS = {'preferred', 'semi-stable', 'staged', 'naive'}

# Semantics that enumerate all extensions (no optimization)
ENUMERATIVE_SEMANTICS = {'cf', 'admissible', 'complete', 'stable', 'grounded'}

# All 9 production semantics
SEMANTICS = {
    'cf': 'semantics/cf.lp',
    'admissible': 'semantics/admissible.lp',
    'complete': 'semantics/complete.lp',
    'grounded': 'semantics/grounded.lp',
    'preferred': 'semantics/preferred.lp',
    'stable': 'semantics/stable.lp',
    'semi-stable': 'semantics/semi-stable.lp',
    'staged': 'semantics/staged.lp',
    'naive': 'semantics/naive.lp'
}

# Inclusion relationships to verify (within each cost stratum)
# Based on correct semantic inclusion chain:
#   stable ⊆ semi-stable ⊆ preferred ⊆ complete ⊆ admissible ⊆ cf
#   grounded ⊆ complete
#   stable ⊆ staged ⊆ cf
#   stable ⊆ naive ⊆ cf
INCLUSIONS = [
    # Main chain: stable → semi-stable → preferred → complete → admissible → cf
    ('stable', 'semi-stable'),
    ('semi-stable', 'preferred'),
    ('preferred', 'complete'),
    ('complete', 'admissible'),
    ('admissible', 'cf'),

    # Grounded branch
    ('grounded', 'complete'),

    # Staged branch
    ('stable', 'staged'),
    ('staged', 'cf'),

    # Naive branch
    ('stable', 'naive'),
    ('naive', 'cf'),

    # Useful transitive inclusions for verification
    ('stable', 'preferred'),
    ('stable', 'complete'),
    ('stable', 'admissible'),
    ('stable', 'cf'),
    ('semi-stable', 'admissible'),
    ('semi-stable', 'cf'),
    ('preferred', 'admissible'),
    ('preferred', 'cf'),
    ('complete', 'cf'),
    ('grounded', 'admissible'),
    ('grounded', 'cf'),
]


def calculate_cost(discarded_attacks, monoid_type='max'):
    """Calculate extension cost using monoid operation"""
    if not discarded_attacks:
        return 0

    weights = [w for (_, _, w) in discarded_attacks]

    if monoid_type == 'max':
        return max(weights)
    elif monoid_type == 'sum':
        return sum(weights)
    elif monoid_type == 'count':
        return len(weights)
    elif monoid_type == 'min':
        return min(weights)
    else:
        raise ValueError(f"Unknown monoid type: {monoid_type}")


def run_semantic(semantic_name, framework, beta_value):
    """
    Run one semantic on one framework with specific beta.
    Returns dict: cost → set of extensions at that cost
    """
    import tempfile
    semantic_file = SEMANTICS[semantic_name]

    # Create temporary budget file
    budget_file = tempfile.NamedTemporaryFile(mode='w', suffix='.lp', delete=False)
    budget_file.write(f'budget({beta_value}).\n')
    budget_file.close()

    # Build command with --opt-mode=enum for complete enumeration
    # This ensures we get ALL models, not just optimal ones
    cmd = [
        'clingo', '-n', '0', '--opt-mode=enum',  # Enumerate ALL models
        CORE, SEMIRING, CONSTRAINT, FILTER, semantic_file, framework,
        budget_file.name,
        f'-c', f'beta={beta_value}'
    ]

    # Add special flags for naive
    if semantic_name == 'naive':
        cmd.extend(['--heuristic=Domain', '--enum-mode=domRec'])

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=TIMEOUT)

        # Clean up temp file
        import os
        os.unlink(budget_file.name)

        # Check for UNSAT
        if 'UNSATISFIABLE' in result.stdout:
            return {}  # No extensions at any cost

        # Extract extensions with their discarded attacks
        extensions_by_cost = defaultdict(set)
        lines = result.stdout.split('\n')

        for i, line in enumerate(lines):
            if line.startswith('Answer:'):
                if i + 1 < len(lines):
                    next_line = lines[i + 1]

                    # Extract extension
                    ext = set()
                    for word in next_line.split():
                        if word.startswith('in(') and word.endswith(')'):
                            ext.add(word[3:-1])

                    # Extract discarded attacks
                    discarded = set()
                    for word in next_line.split():
                        if word.startswith('discarded_attack('):
                            # Parse: discarded_attack(a,b,10)
                            content = word[len('discarded_attack('):-1]
                            parts = content.split(',')
                            if len(parts) == 3:
                                attacker = parts[0]
                                target = parts[1]
                                weight = int(parts[2])
                                discarded.add((attacker, target, weight))

                    # Calculate cost
                    cost = calculate_cost(discarded, MONOID_TYPE)

                    # Store extension at this cost
                    extensions_by_cost[cost].add(frozenset(ext))

        return dict(extensions_by_cost)

    except subprocess.TimeoutExpired:
        import os
        os.unlink(budget_file.name)
        return None  # Timeout
    except Exception as e:
        import os
        if os.path.exists(budget_file.name):
            os.unlink(budget_file.name)
        print(f"Error running {semantic_name}: {e}")
        return {}


def test_inclusions(frameworks, beta_values):
    """Test stratified inclusions across frameworks and beta values"""
    print("="*80)
    print("STRATIFIED SEMANTIC INCLUSION TESTING")
    print("="*80)
    print(f"\nMonoid type: {MONOID_TYPE} (for cost calculation)")
    print(f"Testing {len(SEMANTICS)} semantics")
    print(f"Verifying {len(INCLUSIONS)} inclusion relationships")
    print(f"Found {len(frameworks)} test frameworks")
    print()

    total_checks = 0
    satisfied = 0
    violations = 0
    timeouts = 0

    violation_details = []

    for fw_idx, framework in enumerate(frameworks, 1):
        print(f"[{fw_idx}/{len(frameworks)}] {framework}")

        for beta in beta_values:
            # Run all semantics for this framework and beta
            results = {}
            for sem in SEMANTICS.keys():
                results[sem] = run_semantic(sem, framework, beta)
                if results[sem] is None:
                    print(f"  β={beta}... ⏱️ TIMEOUT in {sem}")
                    timeouts += 1
                    results[sem] = {}

            # Check stratified inclusions
            beta_violations = []
            beta_checks = 0

            for sem1, sem2 in INCLUSIONS:
                exts1_by_cost = results[sem1]
                exts2_by_cost = results[sem2]

                # Get all costs that appear in either semantic
                all_costs = set(exts1_by_cost.keys()) | set(exts2_by_cost.keys())

                for cost in all_costs:
                    exts1_at_cost = exts1_by_cost.get(cost, set())
                    exts2_at_cost = exts2_by_cost.get(cost, set())

                    # Check inclusion within this cost stratum
                    beta_checks += 1
                    total_checks += 1

                    if not exts1_at_cost.issubset(exts2_at_cost):
                        # Violation!
                        violating_exts = exts1_at_cost - exts2_at_cost
                        beta_violations.append((sem1, sem2, cost, violating_exts))
                        violations += 1
                        violation_details.append({
                            'framework': framework,
                            'beta': beta,
                            'sem1': sem1,
                            'sem2': sem2,
                            'cost': cost,
                            'violating': violating_exts
                        })
                    else:
                        satisfied += 1

            # Report for this beta
            if beta_violations:
                print(f"  β={beta}... ❌ {len(beta_violations)} violations")
                for sem1, sem2, cost, violating in beta_violations[:3]:  # Show first 3
                    viol_list = list(violating)[:2]  # Show first 2
                    viol_str = ', '.join(str(set(e)) for e in viol_list)
                    if len(violating) > 2:
                        viol_str += f" (+ {len(violating)-2} more)"
                    print(f"    {sem1}⊆{sem2} at cost={cost}: {viol_str}")
            else:
                print(f"  β={beta}... ✅ All inclusions hold ({beta_checks} checks)")

    # Summary
    print("\n" + "="*80)
    print("SUMMARY")
    print("="*80)
    print(f"Total inclusion checks: {total_checks}")
    print(f"  ✅ Satisfied:   {satisfied} ({100*satisfied//total_checks if total_checks else 0}%)")
    print(f"  ❌ Violations:   {violations} ({100*violations//total_checks if total_checks else 0}%)")
    print(f"  ⏱️  Timeouts:      {timeouts}")

    if violations == 0:
        print("\n🎉 ALL SEMANTIC INCLUSIONS SATISFIED!")
    else:
        print(f"\n⚠️  VIOLATIONS DETECTED")

        # Group violations by type
        violation_types = defaultdict(int)
        for v in violation_details:
            key = f"{v['sem1']}⊆{v['sem2']}"
            violation_types[key] += 1

        print("\nViolations by type:")
        for vtype, count in sorted(violation_types.items(), key=lambda x: -x[1])[:10]:
            print(f"  {vtype}: {count} violations")


if __name__ == '__main__':
    # Test frameworks
    test_dir = Path('test')
    frameworks = sorted([
        str(f) for f in test_dir.glob('*.lp')
        if f.name not in ['test_lukasiewicz.lp', 'test_bottleneck.lp']  # Skip semiring tests
    ])

    # Beta values to test
    beta_values = [0, 10, 50, 100, 500, 1000]

    test_inclusions(frameworks, beta_values)
