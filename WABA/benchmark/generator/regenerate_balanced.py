#!/usr/bin/env python3
"""
Regenerate WABA Benchmark with Perfectly Balanced Configuration

This script:
1. Clears existing frameworks in complete/ and cycle/ directories
2. Generates new balanced frameworks using balanced_config.py
3. Validates the generated frameworks
4. Prints comprehensive statistics

Usage:
    python regenerate_balanced.py [--dry-run] [--keep-old]
"""

import argparse
import shutil
import sys
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from balanced_config import get_balanced_framework_configs, print_balance_summary
from framework_templates import FrameworkGenerator, generate_framework_file


def clear_topology_directories(framework_dir: Path, topologies: list, dry_run: bool = False):
    """Clear existing framework files for specified topologies.

    Args:
        framework_dir: Base frameworks directory
        topologies: List of topology names to clear
        dry_run: If True, only print what would be deleted
    """
    print("="*80)
    print("CLEARING OLD FRAMEWORKS")
    print("="*80)

    for topology in topologies:
        topo_dir = framework_dir / topology
        if not topo_dir.exists():
            print(f"\n{topology}/: Directory doesn't exist, skipping")
            continue

        # Count files
        lp_files = list(topo_dir.glob("*.lp"))

        if dry_run:
            print(f"\n{topology}/: Would delete {len(lp_files)} .lp files")
            if lp_files:
                print(f"  Sample files:")
                for f in lp_files[:5]:
                    print(f"    - {f.name}")
                if len(lp_files) > 5:
                    print(f"    ... and {len(lp_files) - 5} more")
        else:
            print(f"\n{topology}/: Deleting {len(lp_files)} .lp files...", end=' ')
            for f in lp_files:
                f.unlink()
            print("✓ Done")

    if dry_run:
        print("\n⚠️  DRY RUN - No files were actually deleted")

    print("="*80 + "\n")


def generate_balanced_frameworks(output_dir: Path, seed: int = 42) -> list:
    """Generate all balanced frameworks.

    Args:
        output_dir: Base frameworks directory
        seed: Random seed for reproducibility

    Returns:
        List of generated file paths
    """
    print("="*80)
    print("GENERATING BALANCED FRAMEWORKS")
    print("="*80)

    # Get balanced configs
    configs = get_balanced_framework_configs()

    print(f"\nTotal configurations: {len(configs)}")

    # Count by topology
    topology_counts = {}
    for c in configs:
        t = c['topology']
        topology_counts[t] = topology_counts.get(t, 0) + 1

    print("\nBy topology:")
    for t, count in sorted(topology_counts.items()):
        print(f"  {t:12s}: {count:3d} frameworks")

    # Initialize generator
    generator = FrameworkGenerator(seed=seed)

    # Generate files
    generated_files = []
    errors = []

    print(f"\n{'=' * 80}")
    print("Generating files...")
    print(f"{'=' * 80}\n")

    for i, config in enumerate(configs, 1):
        try:
            filepath = generate_framework_file(generator, config, output_dir)
            generated_files.append(filepath)

            # Print progress
            if i % 5 == 0 or i == len(configs):
                print(f"[{i:3d}/{len(configs):3d}] {filepath.relative_to(output_dir.parent)}")

        except Exception as e:
            error_msg = f"Error generating {config.get('topology', 'unknown')}: {e}"
            errors.append(error_msg)
            print(f"✗ {error_msg}")

    # Summary
    print(f"\n{'=' * 80}")
    print("GENERATION SUMMARY")
    print(f"{'=' * 80}")
    print(f"✓ Successfully generated: {len(generated_files)}")
    print(f"✗ Errors: {len(errors)}")

    if errors:
        print("\nErrors:")
        for error in errors[:10]:
            print(f"  - {error}")
        if len(errors) > 10:
            print(f"  ... and {len(errors) - 10} more")

    print(f"{'=' * 80}\n")

    return generated_files


def validate_balance(framework_dir: Path, expected_counts: dict):
    """Validate that generated frameworks match expected balance.

    Args:
        framework_dir: Base frameworks directory
        expected_counts: Dict mapping topology -> expected count
    """
    print("="*80)
    print("VALIDATING BALANCE")
    print("="*80)

    all_balanced = True

    for topology, expected in expected_counts.items():
        topo_dir = framework_dir / topology
        if not topo_dir.exists():
            print(f"\n✗ {topology}/: Directory doesn't exist!")
            all_balanced = False
            continue

        lp_files = list(topo_dir.glob("*.lp"))
        actual = len(lp_files)

        status = "✓" if actual == expected else "✗"
        print(f"\n{status} {topology}/:  {actual}/{expected} frameworks")

        if actual != expected:
            all_balanced = False

    print(f"\n{'=' * 80}")
    if all_balanced:
        print("✓ All topologies are perfectly balanced!")
    else:
        print("✗ Balance validation failed - see errors above")
    print(f"{'=' * 80}\n")

    return all_balanced


def print_parameter_distribution(framework_dir: Path, topologies: list):
    """Print detailed parameter distribution analysis.

    Args:
        framework_dir: Base frameworks directory
        topologies: List of topology names to analyze
    """
    print("="*80)
    print("PARAMETER DISTRIBUTION ANALYSIS")
    print("="*80)

    import re

    for topology in topologies:
        topo_dir = framework_dir / topology
        if not topo_dir.exists():
            continue

        print(f"\n{topology.upper()} TOPOLOGY:")
        print("-" * 80)

        lp_files = list(topo_dir.glob("*.lp"))

        # Extract parameters from filenames
        param_distribution = {
            'a': {},
            'r': {},
            'd': {}
        }

        for f in lp_files:
            # Parse filename: {topology}_a{A}_r{R}_d{D}_...
            a_match = re.search(r'_a(\d+)', f.name)
            r_match = re.search(r'_r(\d+)', f.name)
            d_match = re.search(r'_d(\d+)', f.name)

            if a_match:
                a = int(a_match.group(1))
                param_distribution['a'][a] = param_distribution['a'].get(a, 0) + 1

            if r_match:
                r = int(r_match.group(1))
                param_distribution['r'][r] = param_distribution['r'].get(r, 0) + 1

            if d_match:
                d = int(d_match.group(1))
                param_distribution['d'][d] = param_distribution['d'].get(d, 0) + 1

        # Print distributions
        print(f"\nAssumption counts (a):")
        for a in sorted(param_distribution['a'].keys()):
            count = param_distribution['a'][a]
            print(f"  a={a:2d}: {count:3d} frameworks")

        print(f"\nRule densities (r):")
        for r in sorted(param_distribution['r'].keys()):
            count = param_distribution['r'][r]
            print(f"  r={r:2d}: {count:3d} frameworks")

        print(f"\nDerivation depths (d):")
        for d in sorted(param_distribution['d'].keys()):
            count = param_distribution['d'][d]
            print(f"  d={d:2d}: {count:3d} frameworks")

    print("\n" + "="*80 + "\n")


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description='Regenerate WABA benchmark with balanced configuration',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Show what would be deleted without actually deleting'
    )
    parser.add_argument(
        '--keep-old',
        action='store_true',
        help='Keep old frameworks (do not delete before generating)'
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
        help='Base frameworks directory'
    )

    args = parser.parse_args()

    # Create output directory
    args.output_dir.mkdir(parents=True, exist_ok=True)

    # Topologies to manage (all 6)
    topologies = ['linear', 'tree', 'cycle', 'complete', 'mixed', 'isolated']

    # Step 1: Clear old frameworks (unless --keep-old)
    if not args.keep_old:
        clear_topology_directories(args.output_dir, topologies, dry_run=args.dry_run)

    # Step 2: Generate balanced frameworks (skip if dry-run)
    if not args.dry_run:
        generated_files = generate_balanced_frameworks(args.output_dir, seed=args.seed)

        if not generated_files:
            print("ERROR: No frameworks were generated!")
            sys.exit(1)

        # Step 3: Validate balance
        expected_counts = {
            'linear': 20,
            'tree': 20,
            'cycle': 20,
            'complete': 20,
            'mixed': 20,
            'isolated': 20
        }

        balanced = validate_balance(args.output_dir, expected_counts)

        # Step 4: Print parameter distribution
        print_parameter_distribution(args.output_dir, topologies)

        # Final summary
        print("="*80)
        print("REGENERATION COMPLETE")
        print("="*80)
        print(f"✓ Generated {len(generated_files)} balanced frameworks")
        print(f"✓ Balance validation: {'PASSED' if balanced else 'FAILED'}")
        print(f"\nFrameworks saved to: {args.output_dir}")
        print("="*80 + "\n")

        sys.exit(0 if balanced else 1)
    else:
        print("\n⚠️  DRY RUN COMPLETE - No changes were made")
        print("Run without --dry-run to actually regenerate frameworks\n")
        sys.exit(0)


if __name__ == '__main__':
    main()
