#!/usr/bin/env python3
"""
Test that all semantics are truly distinct by finding frameworks where they disagree.

Strategy:
1. Test all pairs of semantics on all available frameworks
2. Track which pairs disagree (have different extensions)
3. Report which pairs never disagree (might be equivalent)
4. If pairs never disagree, suggest frameworks to test or construct
"""

import subprocess
from pathlib import Path
from typing import Set, List, Dict, Tuple
from dataclasses import dataclass
from itertools import combinations

@dataclass
class Extension:
    assumptions: Set[str]

    def __hash__(self):
        return hash(frozenset(self.assumptions))

    def __eq__(self, other):
        return self.assumptions == other.assumptions


def run_semantics(semantics: str, framework: Path, use_heur: bool = False) -> Set[Extension]:
    """Run semantics and return set of extensions."""
    waba_root = Path("/Users/fdasaro/Desktop/WABA-claude/ABA-variants/WABA")

    cmd = ["clingo", "-n", "0"]
    if use_heur:
        cmd.extend(["--heuristic=Domain", "--enum=domRec"])

    cmd.extend([
        str(waba_root / "core/base.lp"),
        str(waba_root / "semiring/godel.lp"),
        str(waba_root / "filter/standard.lp"),
        str(waba_root / f"semantics/{semantics}.lp"),
        str(framework)
    ])

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        extensions = set()

        for line in result.stdout.split('\n'):
            if line.startswith("Answer:"):
                idx = result.stdout.split('\n').index(line)
                model_line = result.stdout.split('\n')[idx + 1]
                assumptions = set([
                    token[3:-1] for token in model_line.split()
                    if token.startswith("in(") and token.endswith(")")
                ])
                extensions.add(Extension(assumptions))

        return extensions
    except subprocess.TimeoutExpired:
        print(f"      ⚠️  Timeout for {semantics}")
        return set()


def main():
    """Test semantic distinctness."""

    waba_root = Path("/Users/fdasaro/Desktop/WABA-claude/ABA-variants/WABA")

    # All semantics to test
    semantics_list = [
        ("stable", False),
        ("semi-stable", True),
        ("preferred", True),
        ("complete", False),
        ("admissible", False),
        ("grounded", True),
        ("staged", True),
        ("cf2", False),
        ("naive", False),
        ("cf", False),
    ]

    # All available frameworks
    frameworks = []

    # Small examples
    examples_dir = waba_root / "examples"
    if examples_dir.exists():
        frameworks.extend(list(examples_dir.glob("*/*.lp")))

    # Benchmark frameworks (a5 only for speed)
    benchmark_dir = waba_root / "benchmark/frameworks"
    if benchmark_dir.exists():
        for topology in ["linear", "tree", "cycle"]:
            topo_dir = benchmark_dir / topology
            if topo_dir.exists():
                # Just use a5 examples for speed
                frameworks.extend([f for f in topo_dir.glob("*_a5_*.lp")][:2])

    print("=" * 80)
    print("SEMANTIC DISTINCTNESS TEST")
    print("=" * 80)
    print(f"\nTesting {len(semantics_list)} semantics on {len(frameworks)} frameworks")
    print(f"Total pairs to check: {len(list(combinations(range(len(semantics_list)), 2)))}")

    # Track disagreements for each pair
    disagreements = {}
    for i, (sem1, _) in enumerate(semantics_list):
        for j, (sem2, _) in enumerate(semantics_list):
            if i < j:
                disagreements[(sem1, sem2)] = []

    # Test each framework
    print("\n" + "=" * 80)
    print("Testing frameworks...")
    print("=" * 80)

    for fw_idx, framework in enumerate(frameworks, 1):
        print(f"\n[{fw_idx}/{len(frameworks)}] {framework.name}")

        # Run all semantics on this framework
        results = {}
        for sem, use_heur in semantics_list:
            exts = run_semantics(sem, framework, use_heur)
            results[sem] = exts
            print(f"  {sem:15s}: {len(exts):3d} extensions")

        # Check all pairs for disagreement
        for (sem1, sem2) in disagreements.keys():
            if results[sem1] != results[sem2]:
                disagreements[(sem1, sem2)].append(framework.name)

    # Report results
    print("\n" + "=" * 80)
    print("DISTINCTNESS RESULTS")
    print("=" * 80)

    print("\n✅ DISTINCT PAIRS (disagree on at least one framework):")
    print("-" * 80)
    distinct_pairs = [(s1, s2, fws) for (s1, s2), fws in disagreements.items() if fws]
    distinct_pairs.sort(key=lambda x: len(x[2]), reverse=True)

    for sem1, sem2, frameworks_list in distinct_pairs:
        print(f"  {sem1:15s} ≠ {sem2:15s}  (disagree on {len(frameworks_list)} frameworks)")
        if len(frameworks_list) <= 3:
            for fw in frameworks_list:
                print(f"    - {fw}")

    print(f"\nTotal distinct pairs: {len(distinct_pairs)}/{len(disagreements)}")

    # Report equivalent pairs
    equivalent_pairs = [(s1, s2) for (s1, s2), fws in disagreements.items() if not fws]

    if equivalent_pairs:
        print("\n❌ POTENTIALLY EQUIVALENT PAIRS (never disagree):")
        print("-" * 80)
        for sem1, sem2 in equivalent_pairs:
            print(f"  {sem1:15s} ≡ {sem2:15s}  ⚠️  May be identical implementations")

        print(f"\nTotal equivalent pairs: {len(equivalent_pairs)}/{len(disagreements)}")

        print("\n" + "=" * 80)
        print("RECOMMENDATIONS FOR EQUIVALENT PAIRS")
        print("=" * 80)

        for sem1, sem2 in equivalent_pairs:
            print(f"\n{sem1} ≡ {sem2}:")
            print(f"  1. Search literature for frameworks that separate {sem1} and {sem2}")
            print(f"  2. Construct a framework designed to separate them")
            print(f"  3. Verify if they should actually be equivalent in WABA context")
    else:
        print("\n✅ ALL SEMANTICS ARE DISTINCT!")
        print("Every pair disagrees on at least one framework.")

    # Summary matrix
    print("\n" + "=" * 80)
    print("DISAGREEMENT MATRIX")
    print("=" * 80)
    print("\nNumber of frameworks where semantics disagree:")
    print()

    sem_names = [sem for sem, _ in semantics_list]

    # Print header
    print("                ", end="")
    for sem in sem_names:
        print(f"{sem[:6]:>7s}", end="")
    print()
    print("                " + "-" * (7 * len(sem_names)))

    # Print matrix
    for i, sem1 in enumerate(sem_names):
        print(f"{sem1:15s} |", end="")
        for j, sem2 in enumerate(sem_names):
            if i == j:
                print("      -", end="")
            elif i < j:
                count = len(disagreements.get((sem1, sem2), []))
                if count == 0:
                    print(f"      0", end="")
                else:
                    print(f"{count:7d}", end="")
            else:
                print("       ", end="")
        print()

    # Final verdict
    print("\n" + "=" * 80)
    if equivalent_pairs:
        print(f"⚠️  FOUND {len(equivalent_pairs)} POTENTIALLY EQUIVALENT PAIRS")
        print("   Need more diverse frameworks or verification that equivalence is correct")
    else:
        print("✅ ALL SEMANTICS VERIFIED AS DISTINCT")
    print("=" * 80)


if __name__ == "__main__":
    main()
