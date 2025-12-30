#!/usr/bin/env python3
"""
Test semantic inclusion relations for WABA/ABA
Tests: stable ⊆ semi-stable ⊆ preferred ⊆ complete ⊆ admissible ⊆ conflict-free
       grounded ⊆ complete
       stable ⊆ staged ⊆ conflict-free
       stable ⊆ naive ⊆ conflict-free
       grounded ⊆ ideal ⊆ complete
"""
import sys
import re
import subprocess
from typing import Set, FrozenSet, List

def extract_extensions(semantic: str, framework: str) -> List[FrozenSet[str]]:
    """Run clingo and extract extensions (sets of in/1 atoms)"""

    n_models = 1 if semantic in ["grounded", "ideal"] else 0

    # Semantics that require heuristics for maximality
    heuristic_semantics = ["preferred", "semi-stable", "staged", "naive"]

    cmd = ["clingo", "-n", str(n_models), "-c", "beta=0"]

    # Add heuristic flags for semantics that need them
    if semantic in heuristic_semantics:
        cmd.extend(["--heuristic=Domain", "--enum-mode=domRec"])

    cmd.extend([
        "core/base.lp",
        "semiring/godel.lp",
        "constraint/ub_max.lp",
        "filter/standard.lp",
        f"semantics/{semantic}.lp",
        framework
    ])

    result = subprocess.run(cmd, capture_output=True, text=True)

    # Clingo return codes: 10 = SAT, 20 = UNSAT, 30 = OPTIMUM
    if result.returncode not in [0, 10, 20, 30]:
        print(f"Error running {semantic}: unexpected return code {result.returncode}", file=sys.stderr)
        print(result.stderr, file=sys.stderr)
        return []

    extensions = []
    current_answer = []
    in_answer = False

    for line in result.stdout.split('\n'):
        if line.startswith('Answer:'):
            in_answer = True
            if current_answer:
                extensions.append(frozenset(current_answer))
            current_answer = []
            # Extract from same line if present (e.g., "Answer: 1 in(a) in(b)")
            in_preds = re.findall(r'in\(([^)]+)\)', line)
            current_answer.extend(in_preds)
        elif in_answer and (line.strip() == '' or line.startswith('SATISFIABLE') or line.startswith('UNSATISFIABLE') or line.startswith('OPTIMUM')):
            in_answer = False
            if current_answer:
                extensions.append(frozenset(current_answer))
                current_answer = []
        elif in_answer:
            # Extract only in(...) predicates
            in_preds = re.findall(r'in\(([^)]+)\)', line)
            current_answer.extend(in_preds)

    # Handle last answer
    if current_answer:
        extensions.append(frozenset(current_answer))

    return extensions

def check_subset(sem_a: str, sem_b: str, exts_a: List[FrozenSet[str]], exts_b: List[FrozenSet[str]]) -> bool:
    """Check if every extension in A is also in B"""
    violations = []

    for ext_a in exts_a:
        if ext_a not in exts_b:
            violations.append(ext_a)

    if violations:
        print(f"  ✗ VIOLATION: {sem_a} ⊈ {sem_b}")
        for v in violations[:3]:  # Show first 3 violations
            atoms = ", ".join(sorted(v)) if v else "∅"
            print(f"    {{{atoms}}} ∈ {sem_a} but ∉ {sem_b}")
        if len(violations) > 3:
            print(f"    ... and {len(violations) - 3} more")
        return False
    else:
        print(f"  ✓ {sem_a} ⊆ {sem_b}")
        return True

def main():
    if len(sys.argv) != 2:
        print("Usage: test_inclusions.py <framework.lp>")
        sys.exit(1)

    framework = sys.argv[1]

    print("=" * 60)
    print(f"Testing semantic inclusions on: {framework}")
    print("=" * 60)
    print()

    # Collect extensions for all semantics
    print("Collecting extensions...")
    print()

    semantics = {
        "cf": "Conflict-Free",
        "admissible": "Admissible",
        "complete": "Complete",
        "grounded": "Grounded",
        "preferred": "Preferred",
        "semi-stable": "Semi-Stable",
        "stable": "Stable",
        "naive": "Naive",
        "staged": "Staged",
        "ideal": "Ideal"
    }

    extensions = {}
    for sem, name in semantics.items():
        print(f"  {name:15s} ...", end=" ", flush=True)
        exts = extract_extensions(sem, framework)
        extensions[sem] = exts
        print(f"{len(exts)} extension(s)")

    print()
    print("Extensions found:")
    print()

    for sem, name in semantics.items():
        exts = extensions[sem]
        print(f"{name}:")
        for ext in exts:
            atoms = ", ".join(sorted(ext)) if ext else "∅"
            print(f"  {{{atoms}}}")
        print()

    # Check inclusion relations
    print("=" * 60)
    print("Checking inclusion relations...")
    print("=" * 60)
    print()

    violations = 0

    # Chain: stable ⊆ semi-stable ⊆ preferred ⊆ complete ⊆ admissible ⊆ conflict-free
    print("Chain: stable ⊆ semi-stable ⊆ preferred ⊆ complete ⊆ admissible ⊆ cf")
    print("-" * 60)
    if not check_subset("stable", "semi-stable", extensions["stable"], extensions["semi-stable"]):
        violations += 1
    if not check_subset("semi-stable", "preferred", extensions["semi-stable"], extensions["preferred"]):
        violations += 1
    if not check_subset("preferred", "complete", extensions["preferred"], extensions["complete"]):
        violations += 1
    if not check_subset("complete", "admissible", extensions["complete"], extensions["admissible"]):
        violations += 1
    if not check_subset("admissible", "cf", extensions["admissible"], extensions["cf"]):
        violations += 1
    print()

    # grounded ⊆ complete
    print("Grounded relation:")
    print("-" * 60)
    if not check_subset("grounded", "complete", extensions["grounded"], extensions["complete"]):
        violations += 1
    print()

    # stable ⊆ staged ⊆ conflict-free
    print("Staged chain: stable ⊆ staged ⊆ cf")
    print("-" * 60)
    if not check_subset("stable", "staged", extensions["stable"], extensions["staged"]):
        violations += 1
    if not check_subset("staged", "cf", extensions["staged"], extensions["cf"]):
        violations += 1
    print()

    # stable ⊆ naive ⊆ conflict-free
    print("Naive chain: stable ⊆ naive ⊆ cf")
    print("-" * 60)
    if not check_subset("stable", "naive", extensions["stable"], extensions["naive"]):
        violations += 1
    if not check_subset("naive", "cf", extensions["naive"], extensions["cf"]):
        violations += 1
    print()

    # grounded ⊆ ideal ⊆ complete
    print("Ideal chain: grounded ⊆ ideal ⊆ complete")
    print("-" * 60)
    if not check_subset("grounded", "ideal", extensions["grounded"], extensions["ideal"]):
        violations += 1
    if not check_subset("ideal", "complete", extensions["ideal"], extensions["complete"]):
        violations += 1
    print()

    print("=" * 60)
    if violations == 0:
        print("✓ ALL INCLUSION RELATIONS VERIFIED")
    else:
        print(f"✗ FOUND {violations} VIOLATIONS")
    print("=" * 60)

    sys.exit(violations)

if __name__ == "__main__":
    main()
