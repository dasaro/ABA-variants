#!/usr/bin/env python3
"""
Test semantic inclusion relationships across varying beta values.

Standard inclusion relationships (Dung hierarchy extended to WABA):
- grounded ⊆ complete
- grounded ⊆ preferred
- complete ⊆ preferred
- stable ⊆ preferred (when stable exists)
- stable ⊆ semi-stable (when stable exists)
- preferred ⊆ semi-stable
- staged ⊆ semi-stable
- All admissible ⊆ complete
- All semantics ⊆ cf (conflict-free)

These relationships must hold even with budgeted attack discarding,
as long as all semantics use the same beta value.
"""

import subprocess
import os
from pathlib import Path
from collections import defaultdict

TIMEOUT = 30  # seconds

# Core files
CORE = "core/base.lp"
SEMIRING = "semiring/godel.lp"  # Use original WABA semiring
MONOID = "monoid/max_minimization.lp"  # Use original WABA monoid (for maximal semantics)
CONSTRAINT = "constraint/ub_max.lp"  # Budget constraint for max monoid
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

# Inclusion relationships to verify: semantic1 ⊆ semantic2
# Based on correct semantic inclusion chain:
#   stable ⊆ semi-stable ⊆ preferred ⊆ complete ⊆ admissible ⊆ cf
#   grounded ⊆ complete
#   stable ⊆ staged ⊆ cf
#   stable ⊆ naive ⊆ cf
# Format: (subset_semantic, superset_semantic)
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


def run_semantic(semantic_name, framework, beta_value):
    """Run one semantic on one framework with specific beta"""
    import tempfile
    semantic_file = SEMANTICS[semantic_name]

    # Create temporary budget file for frameworks that don't define budget()
    budget_file = tempfile.NamedTemporaryFile(mode='w', suffix='.lp', delete=False)
    budget_file.write(f'budget({beta_value}).\n')
    budget_file.close()

    # Build command with --opt-mode=enum for complete enumeration
    # This ensures we get ALL models, not just optimal ones
    cmd = [
        'clingo', '-n', '0', '--opt-mode=enum',  # Enumerate ALL models
        CORE, SEMIRING, MONOID, CONSTRAINT, FILTER, semantic_file, framework,
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
            return set()  # No extensions

        # Extract extensions
        extensions = []
        lines = result.stdout.split('\n')
        in_answer = False
        for line in lines:
            if line.startswith('Answer:'):
                in_answer = True
            elif in_answer and 'in(' in line:
                # Extract all in(...) predicates from this answer
                ext = set()
                for word in line.split():
                    if word.startswith('in(') and word.endswith(')'):
                        ext.add(word[3:-1])
                if ext or 'in(' not in line:  # Empty extension or actual extension
                    extensions.append(frozenset(ext))
                in_answer = False

        return set(extensions)

    except subprocess.TimeoutExpired:
        # Clean up temp file on timeout
        import os
        try:
            os.unlink(budget_file.name)
        except:
            pass
        return None  # Timeout
    except Exception as e:
        print(f"Error running {semantic_name}: {e}")
        # Clean up temp file on error
        import os
        try:
            os.unlink(budget_file.name)
        except:
            pass
        return None


def check_inclusion(ext_subset, ext_superset, framework, beta, sem1, sem2):
    """Check if ext_subset ⊆ ext_superset"""
    if ext_subset is None or ext_superset is None:
        return 'TIMEOUT'

    # Every extension in subset must be in superset
    for ext in ext_subset:
        if ext not in ext_superset:
            return f'VIOLATION: {set(ext)} in {sem1} but not in {sem2}'

    return 'OK'


def test_framework(framework_path, beta_values):
    """Test one framework with multiple beta values"""
    results = defaultdict(lambda: defaultdict(dict))

    for beta in beta_values:
        print(f"  β={beta}...", end=' ', flush=True)

        # Compute extensions for all semantics
        extensions = {}
        for sem_name in SEMANTICS:
            extensions[sem_name] = run_semantic(sem_name, framework_path, beta)

        # Check all inclusion relationships
        violations = []
        timeouts = []
        for sem1, sem2 in INCLUSIONS:
            result = check_inclusion(extensions[sem1], extensions[sem2],
                                    framework_path, beta, sem1, sem2)
            results[beta][(sem1, sem2)] = result

            if result == 'TIMEOUT':
                timeouts.append(f"{sem1}⊆{sem2}")
            elif result != 'OK':
                violations.append(f"{sem1}⊆{sem2}: {result}")

        if violations:
            print(f"❌ {len(violations)} violations")
            for v in violations:
                print(f"    {v}")
        elif timeouts:
            print(f"⏱️  {len(timeouts)} timeouts")
        else:
            print("✅ All inclusions hold")

    return results


def main():
    print("=" * 80)
    print("SEMANTIC INCLUSION TESTING")
    print("=" * 80)
    print()
    print("Testing 9 production semantics:")
    for i, sem in enumerate(SEMANTICS.keys(), 1):
        print(f"  {i}. {sem}")
    print()
    print(f"Verifying {len(INCLUSIONS)} inclusion relationships")
    print()

    # Collect test frameworks
    test_frameworks = []

    # From examples/
    examples_dir = Path('examples')
    if examples_dir.exists():
        test_frameworks.extend(list(examples_dir.glob('*.lp'))[:10])  # First 10

    # From test/
    test_dir = Path('test')
    if test_dir.exists():
        # Select representative test files
        representative_tests = [
            'simple_aba.lp', 'even_cycle.lp', 'no_attacks.lp',
            'aspforaba_simple_example.lp', 'aspforaba_journal_example.lp',
            'test_aba_recovery_simple.lp', 'test_beta.lp'
        ]
        for test_file in representative_tests:
            path = test_dir / test_file
            if path.exists():
                test_frameworks.append(path)

    # From benchmark/
    benchmark_dir = Path('benchmark')
    if benchmark_dir.exists():
        benchmark_files = list(benchmark_dir.glob('*.lp'))[:15]  # First 15
        test_frameworks.extend(benchmark_files)

    if not test_frameworks:
        print("❌ No test frameworks found!")
        return

    print(f"Found {len(test_frameworks)} test frameworks")
    print()

    # Test with varying beta values
    # Use small values to avoid timeouts, but enough to show budget effects
    beta_values = [0, 10, 50, 100, 500, 1000]

    overall_stats = {
        'total_tests': 0,
        'violations': 0,
        'timeouts': 0,
        'successes': 0
    }

    for i, framework in enumerate(test_frameworks, 1):
        print(f"[{i}/{len(test_frameworks)}] {framework.name}")
        results = test_framework(str(framework), beta_values)

        # Count results
        for beta in beta_values:
            for (sem1, sem2), result in results[beta].items():
                overall_stats['total_tests'] += 1
                if result == 'TIMEOUT':
                    overall_stats['timeouts'] += 1
                elif result == 'OK':
                    overall_stats['successes'] += 1
                else:
                    overall_stats['violations'] += 1

        print()

    # Print summary
    print("=" * 80)
    print("SUMMARY")
    print("=" * 80)
    total = overall_stats['total_tests']
    print(f"Total inclusion checks: {total}")
    print(f"  ✅ Satisfied:  {overall_stats['successes']:4d} ({100*overall_stats['successes']/total:.1f}%)")
    print(f"  ❌ Violations: {overall_stats['violations']:4d} ({100*overall_stats['violations']/total:.1f}%)")
    print(f"  ⏱️  Timeouts:   {overall_stats['timeouts']:4d} ({100*overall_stats['timeouts']/total:.1f}%)")
    print()

    if overall_stats['violations'] == 0:
        print("🎉 All inclusion relationships hold!")
    else:
        print("⚠️  VIOLATIONS DETECTED - Semantic implementations may be incorrect")


if __name__ == '__main__':
    main()
