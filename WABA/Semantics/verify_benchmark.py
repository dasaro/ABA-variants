#!/usr/bin/env python3
"""
Quick verification script for testing semantics on larger benchmark examples.

Tests key subset relations and extension counts on benchmark frameworks.
"""

import subprocess
from pathlib import Path
from typing import Set, List
from dataclasses import dataclass


@dataclass
class Extension:
    """Represents an argumentation extension."""
    assumptions: Set[str]
    cost: int

    def __hash__(self):
        return hash(frozenset(self.assumptions))

    def __eq__(self, other):
        return self.assumptions == other.assumptions

    def __repr__(self):
        return f"{sorted(self.assumptions)}"


def run_semantics(semantics: str, framework: Path, use_heuristics: bool = False, max_models: int = 0) -> List[Extension]:
    """Run clingo with given semantics and extract extensions.

    Args:
        semantics: Name of semantics file
        framework: Path to framework file
        use_heuristics: Whether to use Domain heuristics
        max_models: Maximum number of models to enumerate (0 = all models)
    """

    waba_root = Path("/Users/fdasaro/Desktop/WABA-claude/ABA-variants/WABA")
    semantics_file = waba_root / f"semantics/{semantics}.lp"

    cmd = ["clingo", "-n", str(max_models)]
    if use_heuristics:
        cmd.extend(["--heuristic=Domain", "--enum=domRec"])

    cmd.extend([
        str(waba_root / "core/base.lp"),
        str(waba_root / "semiring/godel.lp"),
        str(waba_root / "filter/standard.lp"),
        str(semantics_file),
        str(framework)
    ])

    try:
        # Increase timeout for larger examples (a10 can take much longer)
        timeout = 300  # 5 minutes per semantics
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        extensions = parse_extensions(result.stdout)

        # Check if we hit the model limit
        if max_models > 0 and len(extensions) == max_models:
            print(f"    ⚠️  {semantics}: Hit model limit ({max_models}), may have more extensions")

        return extensions
    except subprocess.TimeoutExpired:
        print(f"  ⚠️  Timeout for {semantics} (>{timeout}s)")
        return []


def parse_extensions(output: str) -> List[Extension]:
    """Parse clingo output to extract extensions."""
    extensions = []

    lines = output.split('\n')
    i = 0
    while i < len(lines):
        if lines[i].startswith("Answer:"):
            if i + 1 < len(lines):
                model_line = lines[i + 1]
                assumptions = set()

                for token in model_line.split():
                    if token.startswith("in(") and token.endswith(")"):
                        assumption = token[3:-1]
                        assumptions.add(assumption)

                extensions.append(Extension(assumptions, 0))
            i += 1
        i += 1

    return extensions


def test_framework(framework: Path):
    """Test subset relations on a single framework."""
    print(f"\n📁 {framework.name}")
    print("-" * 80)

    # Test all semantics
    semantics_to_test = [
        ("stable", False),
        ("semi-stable", True),
        ("preferred", True),
        ("complete", False),
        ("admissible", False),
        ("grounded", True),
        ("staged", True),
        ("cf", False),
    ]

    results = {}
    for i, (sem, use_heur) in enumerate(semantics_to_test, 1):
        print(f"  [{i}/{len(semantics_to_test)}] Testing {sem}...", end=" ", flush=True)
        exts = run_semantics(sem, framework, use_heur)
        results[sem] = set(exts)
        print(f"{len(exts):4d} extensions")

    # Test subset relations
    print("\n  Subset Relations:")
    relations = [
        ("stable", "semi-stable"),
        ("semi-stable", "preferred"),
        ("semi-stable", "complete"),
        ("preferred", "admissible"),
        ("complete", "admissible"),
        ("admissible", "cf"),
        ("grounded", "complete"),
        ("stable", "staged"),
        ("staged", "cf"),
    ]

    all_passed = True
    for sem1, sem2 in relations:
        if sem1 in results and sem2 in results:
            if results[sem1].issubset(results[sem2]):
                print(f"    ✓ {sem1} ⊆ {sem2} ({len(results[sem1])} ⊆ {len(results[sem2])})")
            else:
                diff = results[sem1] - results[sem2]
                print(f"    ✗ {sem1} ⊄ {sem2} ({len(diff)} extensions in {sem1} not in {sem2})")
                all_passed = False

    return all_passed


def main():
    """Test semantics on benchmark examples."""
    import sys

    waba_root = Path("/Users/fdasaro/Desktop/WABA-claude/ABA-variants/WABA")
    benchmark_root = waba_root / "benchmark/frameworks"

    # Check if user wants a10 examples
    use_a10 = "--a10" in sys.argv or "-a10" in sys.argv

    if use_a10:
        # Test representative frameworks from different topologies (a10 - larger scale)
        frameworks = [
            benchmark_root / "linear/linear_a10_r2_d1_random_tight.lp",
            benchmark_root / "tree/tree_a10_r2_d1_b2_random_tight.lp",
            benchmark_root / "cycle/cycle_a10_r2_d1_c3_random_tight.lp",
        ]
        size_label = "a10"
    else:
        # Test representative frameworks from different topologies (a5 for complete enumeration)
        frameworks = [
            benchmark_root / "linear/linear_a5_r2_d1_power_law_tight.lp",
            benchmark_root / "tree/tree_a5_r2_d1_b2_power_law_tight.lp",
            benchmark_root / "cycle/cycle_a5_r2_d1_c3_power_law_tight.lp",
        ]
        size_label = "a5"

    print("=" * 80)
    print("BENCHMARK SEMANTICS VERIFICATION")
    print(f"Testing with -n 0 (all models) on {size_label} examples")
    print("=" * 80)

    all_passed = True
    for framework in frameworks:
        if framework.exists():
            passed = test_framework(framework)
            all_passed = all_passed and passed
        else:
            print(f"\n⚠️  Framework not found: {framework.name}")

    print("\n" + "=" * 80)
    if all_passed:
        print("✅ ALL TESTS PASSED")
    else:
        print("❌ SOME TESTS FAILED")
    print("=" * 80)


if __name__ == "__main__":
    main()
