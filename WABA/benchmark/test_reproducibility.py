#!/usr/bin/env python3
"""
Reproducibility Test for WABA Benchmark Generator

Tests that running generation twice with the same --seed produces:
1. Byte-for-byte identical .lp files
2. Identical .meta.json files (ignoring timestamps and file_path)

Usage:
    python test_reproducibility.py [--seed SEED] [--count N]

Exit codes:
    0: PASS - All files identical
    1: FAIL - Files differ
    2: Error during test execution
"""

import argparse
import filecmp
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Tuple, List


def generate_frameworks(output_dir: Path, seed: int, count: int) -> int:
    """
    Generate frameworks using the benchmark generator.

    Args:
        output_dir: Directory to write frameworks
        seed: Master seed for generation
        count: Number of frameworks to generate

    Returns:
        Exit code (0 for success)
    """
    # Import generator modules
    sys.path.insert(0, str(Path(__file__).parent / 'generator'))

    from dimension_config import sample_configs_by_distribution
    from framework_templates import FrameworkGenerator, generate_framework_file

    # Generate configurations
    configs = sample_configs_by_distribution(target_count=count, seed=seed)

    # Initialize generator
    generator = FrameworkGenerator(seed=seed)

    # Generate frameworks
    for config in configs:
        try:
            generate_framework_file(generator, config, output_dir)
        except Exception as e:
            print(f"✗ Error generating framework: {e}")
            return 2

    return 0


def compare_lp_files(dir1: Path, dir2: Path) -> Tuple[bool, List[str]]:
    """
    Compare .lp files byte-for-byte between two directories.

    Args:
        dir1: First directory
        dir2: Second directory

    Returns:
        (all_match, differences) tuple
    """
    differences = []

    # Get all .lp files from both directories
    lp_files_1 = sorted(dir1.rglob('*.lp'))
    lp_files_2 = sorted(dir2.rglob('*.lp'))

    # Convert to relative paths for comparison
    rel_files_1 = {f.relative_to(dir1) for f in lp_files_1}
    rel_files_2 = {f.relative_to(dir2) for f in lp_files_2}

    # Check for missing files
    missing_in_2 = rel_files_1 - rel_files_2
    missing_in_1 = rel_files_2 - rel_files_1

    if missing_in_2:
        differences.append(f"Files in run1 but not run2: {missing_in_2}")
    if missing_in_1:
        differences.append(f"Files in run2 but not run1: {missing_in_1}")

    # Compare byte-for-byte
    for rel_path in sorted(rel_files_1 & rel_files_2):
        file1 = dir1 / rel_path
        file2 = dir2 / rel_path

        if not filecmp.cmp(file1, file2, shallow=False):
            # Files differ - show first difference
            with open(file1, 'rb') as f1, open(file2, 'rb') as f2:
                content1 = f1.read()
                content2 = f2.read()

                # Find first differing byte
                for i, (b1, b2) in enumerate(zip(content1, content2)):
                    if b1 != b2:
                        differences.append(
                            f"{rel_path}: Byte {i} differs (0x{b1:02x} vs 0x{b2:02x})"
                        )
                        break
                else:
                    # Length differs
                    differences.append(
                        f"{rel_path}: Length differs ({len(content1)} vs {len(content2)})"
                    )

    return len(differences) == 0, differences


def compare_meta_files(dir1: Path, dir2: Path) -> Tuple[bool, List[str]]:
    """
    Compare .meta.json files between two directories (ignoring timestamps and file_path).

    Args:
        dir1: First directory
        dir2: Second directory

    Returns:
        (all_match, differences) tuple
    """
    differences = []

    # Get all .meta.json files from both directories
    meta_files_1 = sorted(dir1.rglob('*.meta.json'))
    meta_files_2 = sorted(dir2.rglob('*.meta.json'))

    # Convert to relative paths for comparison
    rel_files_1 = {f.relative_to(dir1) for f in meta_files_1}
    rel_files_2 = {f.relative_to(dir2) for f in meta_files_2}

    # Check for missing files
    missing_in_2 = rel_files_1 - rel_files_2
    missing_in_1 = rel_files_2 - rel_files_1

    if missing_in_2:
        differences.append(f"Metadata in run1 but not run2: {missing_in_2}")
    if missing_in_1:
        differences.append(f"Metadata in run2 but not run1: {missing_in_1}")

    # Compare JSON content (ignoring timestamps)
    for rel_path in sorted(rel_files_1 & rel_files_2):
        file1 = dir1 / rel_path
        file2 = dir2 / rel_path

        with open(file1, 'r') as f1, open(file2, 'r') as f2:
            meta1 = json.load(f1)
            meta2 = json.load(f2)

            # Remove timestamps and file_path before comparison
            # (file_path is environment-specific, not deterministic content)
            meta1_normalized = {k: v for k, v in meta1.items() if k not in ('timestamp', 'file_path')}
            meta2_normalized = {k: v for k, v in meta2.items() if k not in ('timestamp', 'file_path')}

            if meta1_normalized != meta2_normalized:
                # Find specific differences
                all_keys = set(meta1_normalized.keys()) | set(meta2_normalized.keys())
                for key in sorted(all_keys):
                    val1 = meta1_normalized.get(key, '<missing>')
                    val2 = meta2_normalized.get(key, '<missing>')
                    if val1 != val2:
                        differences.append(
                            f"{rel_path}: Field '{key}' differs:\n"
                            f"  run1: {val1}\n"
                            f"  run2: {val2}"
                        )

    return len(differences) == 0, differences


def main():
    """Main test entry point."""
    parser = argparse.ArgumentParser(
        description='Test reproducibility of WABA benchmark generator',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument(
        '--seed',
        type=int,
        default=42,
        help='Master seed for generation'
    )
    parser.add_argument(
        '--count',
        type=int,
        default=6,
        help='Number of frameworks to generate (keep small for quick test)'
    )

    args = parser.parse_args()

    print("=" * 70)
    print("WABA Benchmark Generator - Reproducibility Test")
    print("=" * 70)
    print(f"Seed: {args.seed}")
    print(f"Framework count: {args.count}")
    print()

    # Create temporary directories for two runs
    with tempfile.TemporaryDirectory(prefix='waba_repro_run1_') as tmpdir1, \
         tempfile.TemporaryDirectory(prefix='waba_repro_run2_') as tmpdir2:

        dir1 = Path(tmpdir1)
        dir2 = Path(tmpdir2)

        # Run 1
        print(f"[1/2] Generating frameworks (run 1) in {dir1}...")
        exit_code = generate_frameworks(dir1, args.seed, args.count)
        if exit_code != 0:
            print(f"✗ FAIL: Run 1 failed with exit code {exit_code}")
            return 2

        # Run 2
        print(f"[2/2] Generating frameworks (run 2) in {dir2}...")
        exit_code = generate_frameworks(dir2, args.seed, args.count)
        if exit_code != 0:
            print(f"✗ FAIL: Run 2 failed with exit code {exit_code}")
            return 2

        print()
        print("Comparing outputs...")
        print("-" * 70)

        # Compare .lp files
        print("[1/2] Comparing .lp files (byte-for-byte)...")
        lp_match, lp_diffs = compare_lp_files(dir1, dir2)

        if lp_match:
            lp_count = len(list(dir1.rglob('*.lp')))
            print(f"  ✓ All {lp_count} .lp files identical")
        else:
            print(f"  ✗ Found {len(lp_diffs)} differences in .lp files:")
            for diff in lp_diffs[:5]:  # Show first 5 differences
                print(f"    - {diff}")
            if len(lp_diffs) > 5:
                print(f"    ... and {len(lp_diffs) - 5} more")

        # Compare .meta.json files
        print("[2/2] Comparing .meta.json files (ignoring timestamps and file_path)...")
        meta_match, meta_diffs = compare_meta_files(dir1, dir2)

        if meta_match:
            meta_count = len(list(dir1.rglob('*.meta.json')))
            print(f"  ✓ All {meta_count} .meta.json files identical (ignoring timestamps and file_path)")
        else:
            print(f"  ✗ Found {len(meta_diffs)} differences in .meta.json files:")
            for diff in meta_diffs[:5]:  # Show first 5 differences
                print(f"    - {diff}")
            if len(meta_diffs) > 5:
                print(f"    ... and {len(meta_diffs) - 5} more")

        print("-" * 70)

        # Final verdict
        if lp_match and meta_match:
            print()
            print("✓ PASS: All files identical across two runs")
            print("  Reproducibility verified!")
            print()
            return 0
        else:
            print()
            print("✗ FAIL: Files differ between runs")
            print("  Reproducibility check failed!")
            print()
            if lp_diffs:
                print(f"First differing .lp file:")
                print(f"  {lp_diffs[0]}")
            if meta_diffs:
                print(f"First differing .meta.json file:")
                print(f"  {meta_diffs[0]}")
            print()
            return 1


if __name__ == '__main__':
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\n\nInterrupted by user")
        sys.exit(130)
    except Exception as e:
        print(f"\n✗ ERROR: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(2)
