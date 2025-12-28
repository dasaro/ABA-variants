#!/usr/bin/env python3
"""
WABA Benchmark Suite Generator - Main Orchestrator

Generates 100+ diverse flat-WABA frameworks across 4 complexity dimensions:
1. Assumption count (2 → 50)
2. Rule count & depth (0 → 30, depth 1-4)
3. Attack connectivity (6 topology types)
4. Weight distribution (8 weight schemes)

Usage:
    python generate_all.py [--count N] [--seed S] [--output-dir DIR]

Output:
    benchmark/frameworks/<topology>/<framework>.lp files
"""

import argparse
import sys
from pathlib import Path
from typing import List, Dict

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from dimension_config import (
    sample_configs_by_distribution,
    TARGET_FRAMEWORK_COUNT,
    TOPOLOGY_DISTRIBUTION
)
from framework_templates import FrameworkGenerator, generate_framework_file


def generate_all_frameworks(output_dir: Path, target_count: int = TARGET_FRAMEWORK_COUNT,
                           seed: int = 42, verbose: bool = True) -> List[Path]:
    """Generate all benchmark frameworks.

    Args:
        output_dir: Base output directory (e.g., benchmark/frameworks/)
        target_count: Desired number of frameworks
        seed: Random seed for reproducibility
        verbose: Print progress messages

    Returns:
        List of paths to generated .lp files
    """
    if verbose:
        print("=" * 70)
        print("WABA Benchmark Suite Generator")
        print("=" * 70)
        print(f"\nTarget framework count: {target_count}")
        print(f"Random seed: {seed}")
        print(f"Output directory: {output_dir}")
        print()

    # Sample configurations according to target distribution
    configs = sample_configs_by_distribution(target_count=target_count)

    if verbose:
        print(f"\nGenerated {len(configs)} framework configurations:")
        topology_counts = {}
        for config in configs:
            topology = config['topology']
            topology_counts[topology] = topology_counts.get(topology, 0) + 1

        for topology, count in sorted(topology_counts.items()):
            target_pct = TOPOLOGY_DISTRIBUTION.get(topology, 0) * 100
            actual_pct = (count / len(configs)) * 100
            print(f"  {topology:12s}: {count:3d} frameworks ({actual_pct:5.1f}% | target: {target_pct:5.1f}%)")

    # Initialize generator
    generator = FrameworkGenerator(seed=seed)

    # Generate framework files
    generated_files = []
    errors = []

    if verbose:
        print(f"\n{'=' * 70}")
        print("Generating framework files...")
        print(f"{'=' * 70}\n")

    for i, config in enumerate(configs, 1):
        try:
            # Generate framework file
            filepath = generate_framework_file(generator, config, output_dir)
            generated_files.append(filepath)

            if verbose:
                # Print progress every 10 frameworks
                if i % 10 == 0 or i == len(configs):
                    print(f"[{i:3d}/{len(configs):3d}] Generated: {filepath.relative_to(output_dir.parent)}")

        except Exception as e:
            error_msg = f"Error generating {config.get('topology', 'unknown')}: {e}"
            errors.append(error_msg)
            if verbose:
                print(f"✗ {error_msg}")

    # Summary
    if verbose:
        print(f"\n{'=' * 70}")
        print("Generation Summary")
        print(f"{'=' * 70}")
        print(f"✓ Successfully generated: {len(generated_files)} frameworks")
        print(f"✗ Errors encountered: {len(errors)}")

        if errors:
            print("\nErrors:")
            for error in errors:
                print(f"  - {error}")

        print(f"\nFrameworks saved to: {output_dir}")
        print(f"{'=' * 70}\n")

    return generated_files


def validate_framework_semantics(filepath: Path, verbose: bool = False) -> tuple:
    """Validate semantic properties of a framework.

    Checks:
    1. All derived atoms are reachable via attack chains
    2. Graph connectivity (except isolated topology)
    3. Rules can be triggered (premises are supportable)

    Args:
        filepath: Path to .lp file
        verbose: Print detailed messages

    Returns:
        (is_valid, list_of_issues)
    """
    issues = []

    try:
        with open(filepath, 'r') as f:
            content = f.read()

        # Parse framework
        assumptions = set()
        derived_atoms = set()
        rules = {}  # rule_id -> (head, bodies)
        contraries = {}  # assumption -> contrary_atom
        attacks = []  # List of (attacker, target)

        # Extract assumptions
        for line in content.split('\n'):
            if line.strip().startswith('assumption('):
                # Parse: assumption(a1; a2; a3).
                atoms = line.split('assumption(')[1].split(')')[0]
                for atom in atoms.split(';'):
                    assumptions.add(atom.strip())

        # Extract derived atoms and rules
        for line in content.split('\n'):
            if 'head(' in line and not line.strip().startswith('%'):
                # Parse: head(rule_id, atom).
                parts = line.split('head(')[1].split(')')[0].split(',')
                if len(parts) >= 2:
                    rule_id = parts[0].strip()
                    head_atom = parts[1].strip()
                    if head_atom not in assumptions and not head_atom.startswith('c_'):
                        derived_atoms.add(head_atom)

                    if rule_id not in rules:
                        rules[rule_id] = (head_atom, [])

            if 'body(' in line and not line.strip().startswith('%'):
                # Parse: body(rule_id, atom).
                parts = line.split('body(')[1].split(')')[0].split(',')
                if len(parts) >= 2:
                    rule_id = parts[0].strip()
                    body_atom = parts[1].strip()
                    if rule_id in rules:
                        rules[rule_id][1].append(body_atom)

        # Extract contraries
        for line in content.split('\n'):
            if 'contrary(' in line and not line.strip().startswith('%'):
                parts = line.split('contrary(')[1].split(')')[0].split(',')
                if len(parts) >= 2:
                    contraries[parts[0].strip()] = parts[1].strip()

        # Build attack graph: a attacks b if rule derives c_b from a
        for rule_id, (head, bodies) in rules.items():
            # Check if head is a contrary atom (c_X)
            for assumption, contrary_atom in contraries.items():
                if head == contrary_atom:
                    # This rule derives contrary(assumption)
                    # All atoms in bodies attack assumption
                    for body_atom in bodies:
                        if body_atom in assumptions:
                            attacks.append((body_atom, assumption))

        # VALIDATION 1: Check derived atom reachability
        attackable_atoms = set()
        for head, _ in rules.values():
            if head.startswith('c_'):
                attackable_atoms.add(head)

        # Calculate reachability percentage
        if derived_atoms:
            attacked_derived = sum(1 for d in derived_atoms if any(
                head.startswith('c_') or d in bodies
                for head, bodies in rules.values()
            ))
            reachability = attacked_derived / len(derived_atoms)

            if reachability < 0.5:  # At least 50% should be reachable
                issues.append(f"Low derived atom reachability: {reachability:.0%}")

        # VALIDATION 2: Check connectivity (except isolated topology)
        is_isolated = 'isolated' in filepath.name
        if not is_isolated and len(assumptions) > 1:
            # Build adjacency for assumptions only
            adjacency = {a: set() for a in assumptions}
            for attacker, target in attacks:
                if attacker in assumptions and target in assumptions:
                    adjacency[attacker].add(target)

            # Simple connectivity check: at least A-1 edges for A assumptions
            total_edges = sum(len(targets) for targets in adjacency.values())
            min_edges = len(assumptions) - 1

            if total_edges < min_edges:
                issues.append(f"Sparse connectivity: {total_edges} edges for {len(assumptions)} assumptions")

        # VALIDATION 3: Check rule triggerability
        for rule_id, (head, bodies) in rules.items():
            # Check if all body atoms can potentially be supported
            unsupportable = [b for b in bodies if b not in assumptions and b not in derived_atoms]
            if unsupportable:
                issues.append(f"Rule {rule_id} has unsupportable premises: {unsupportable}")

        is_valid = len(issues) == 0

        if verbose and not is_valid:
            print(f"  {filepath.name}: {len(issues)} issues found")
            for issue in issues:
                print(f"    - {issue}")

        return is_valid, issues

    except Exception as e:
        issues.append(f"Parse error: {e}")
        return False, issues


def validate_framework_files(framework_files: List[Path], verbose: bool = True,
                            semantic: bool = False) -> Dict[str, any]:
    """Validate generated framework files for correctness.

    Args:
        framework_files: List of paths to .lp files
        verbose: Print validation messages
        semantic: Perform semantic validation (reachability, connectivity)

    Returns:
        Dict with validation results
    """
    if verbose:
        print("=" * 70)
        print("Framework Validation")
        print("=" * 70)

    results = {
        'total': len(framework_files),
        'valid': 0,
        'invalid': 0,
        'errors': []
    }

    required_predicates = ['assumption', 'weight', 'contrary', 'budget']

    for filepath in framework_files:
        try:
            with open(filepath, 'r') as f:
                content = f.read()

            # Check for required predicates
            missing = []
            for predicate in required_predicates:
                if f"{predicate}(" not in content:
                    missing.append(predicate)

            if missing:
                results['invalid'] += 1
                error = f"{filepath.name}: Missing predicates: {', '.join(missing)}"
                results['errors'].append(error)
                if verbose:
                    print(f"✗ {error}")
            else:
                results['valid'] += 1

        except Exception as e:
            results['invalid'] += 1
            error = f"{filepath.name}: Validation error: {e}"
            results['errors'].append(error)
            if verbose:
                print(f"✗ {error}")

    # Semantic validation (if requested)
    if semantic:
        semantic_results = {
            'valid': 0,
            'issues': []
        }

        if verbose:
            print(f"\n{'=' * 70}")
            print("Semantic Validation")
            print(f"{'=' * 70}")

        for filepath in framework_files:
            is_valid, issues = validate_framework_semantics(filepath, verbose=False)
            if is_valid:
                semantic_results['valid'] += 1
            else:
                semantic_results['issues'].append((filepath.name, issues))

        if verbose:
            print(f"✓ Semantically valid: {semantic_results['valid']}/{len(framework_files)}")
            if semantic_results['issues']:
                print(f"⚠ Frameworks with issues: {len(semantic_results['issues'])}")
                # Show first 5 issues
                for name, issues in semantic_results['issues'][:5]:
                    print(f"  {name}: {issues[0] if issues else 'unknown'}")
                if len(semantic_results['issues']) > 5:
                    print(f"  ... and {len(semantic_results['issues']) - 5} more")

        results['semantic'] = semantic_results

    if verbose:
        print(f"\n{'=' * 70}")
        print("Validation Summary")
        print(f"{'=' * 70}")
        print(f"✓ Valid frameworks: {results['valid']}/{results['total']}")
        print(f"✗ Invalid frameworks: {results['invalid']}/{results['total']}")

        if results['invalid'] == 0:
            print("\nAll frameworks passed validation! ✓")
        else:
            print(f"\n{results['invalid']} frameworks have issues (see errors above)")

        print(f"{'=' * 70}\n")

    return results


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description='Generate WABA benchmark suite frameworks',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument(
        '--count',
        type=int,
        default=TARGET_FRAMEWORK_COUNT,
        help='Target number of frameworks to generate'
    )
    parser.add_argument(
        '--seed',
        type=int,
        default=42,
        help='Random seed for reproducibility'
    )
    parser.add_argument(
        '--output-dir',
        type=Path,
        default=Path(__file__).parent.parent / 'frameworks',
        help='Output directory for generated frameworks'
    )
    parser.add_argument(
        '--validate',
        action='store_true',
        help='Validate generated frameworks after creation'
    )
    parser.add_argument(
        '--semantic-validation',
        action='store_true',
        help='Enable semantic validation (reachability, connectivity)'
    )
    parser.add_argument(
        '--quiet',
        action='store_true',
        help='Suppress progress messages'
    )

    args = parser.parse_args()

    # Create output directory
    args.output_dir.mkdir(parents=True, exist_ok=True)

    # Generate frameworks
    generated_files = generate_all_frameworks(
        output_dir=args.output_dir,
        target_count=args.count,
        seed=args.seed,
        verbose=not args.quiet
    )

    # Validate if requested
    if args.validate and generated_files:
        validate_framework_files(
            generated_files,
            verbose=not args.quiet,
            semantic=args.semantic_validation
        )

    # Exit code
    if not generated_files:
        if not args.quiet:
            print("ERROR: No frameworks were generated!")
        sys.exit(1)

    if not args.quiet:
        print(f"✓ Successfully generated {len(generated_files)} frameworks")

    sys.exit(0)


if __name__ == '__main__':
    main()
