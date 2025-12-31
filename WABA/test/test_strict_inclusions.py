#!/usr/bin/env python3
"""
Test that all semantic inclusion relations are STRICT (not equal)
Finds frameworks where A ⊂ B (strict subset, not equality)
"""
import sys
import subprocess
import re
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

    # Determine semantic file path
    if semantic in heuristic_semantics:
        semantic_file = f"semantics/heuristic/{semantic}.lp"
    else:
        semantic_file = f"semantics/{semantic}.lp"

    cmd.extend([
        "core/base.lp",
        "semiring/godel.lp",
        "constraint/ub_max.lp",
        "filter/standard.lp",
        semantic_file,
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
            # Extract from same line if present
            in_preds = re.findall(r'in\(([^)]+)\)', line)
            current_answer.extend(in_preds)
        elif in_answer and (line.strip() == '' or line.startswith('SATISFIABLE') or line.startswith('UNSATISFIABLE') or line.startswith('OPTIMUM')):
            in_answer = False
            if current_answer:
                extensions.append(frozenset(current_answer))
                current_answer = []
        elif in_answer:
            in_preds = re.findall(r'in\(([^)]+)\)', line)
            current_answer.extend(in_preds)

    if current_answer:
        extensions.append(frozenset(current_answer))

    return extensions

def is_strict_subset(set_a: List[FrozenSet[str]], set_b: List[FrozenSet[str]]) -> bool:
    """Check if A ⊂ B (strict: A ⊆ B and A ≠ B)"""
    # A ⊆ B: every element of A is in B
    for ext_a in set_a:
        if ext_a not in set_b:
            return False

    # A ≠ B: B has at least one element not in A
    for ext_b in set_b:
        if ext_b not in set_a:
            return True

    return False  # A = B

def test_strict_inclusion(sem_a: str, sem_b: str, framework: str, relation: str) -> bool:
    """Test if sem_a ⊂ sem_b (strict) on given framework"""

    print(f"\nTesting: {relation}")
    print(f"Framework: {framework}")

    exts_a = extract_extensions(sem_a, framework)
    exts_b = extract_extensions(sem_b, framework)

    print(f"  {sem_a}: {len(exts_a)} extension(s)")
    for ext in sorted(exts_a, key=lambda e: sorted(e)):
        atoms = ", ".join(sorted(ext)) if ext else "∅"
        print(f"    {{{atoms}}}")

    print(f"  {sem_b}: {len(exts_b)} extension(s)")
    for ext in sorted(exts_b, key=lambda e: sorted(e)):
        atoms = ", ".join(sorted(ext)) if ext else "∅"
        print(f"    {{{atoms}}}")

    # Check subset
    if not all(ext in exts_b for ext in exts_a):
        print(f"  ✗ FAIL: {sem_a} ⊈ {sem_b}")
        return False

    # Check strict (not equal)
    if is_strict_subset(exts_a, exts_b):
        print(f"  ✓ STRICT: {sem_a} ⊂ {sem_b}")
        return True
    else:
        print(f"  ✗ EQUAL: {sem_a} = {sem_b} (not strict)")
        return False

def main():
    print("=" * 70)
    print("Testing STRICT Semantic Inclusions")
    print("=" * 70)

    test_cases = [
        ("stable", "semi-stable", "test/strict_inclusions/stable_semistable_bad_assumption.lp", "stable ⊂ semi-stable"),
        ("semi-stable", "preferred", "test/strict_inclusions/semistable_preferred_asym.lp", "semi-stable ⊂ preferred"),
        ("preferred", "complete", "test/strict_inclusions/grounded_subset_complete.lp", "preferred ⊂ complete"),
        ("complete", "admissible", "test/strict_inclusions/complete_subset_admissible.lp", "complete ⊂ admissible"),
        ("admissible", "cf", "test/strict_inclusions/admissible_subset_cf.lp", "admissible ⊂ cf"),
        ("grounded", "complete", "test/strict_inclusions/grounded_subset_complete.lp", "grounded ⊂ complete"),
        ("stable", "staged", "test/strict_inclusions/stable_staged_3cycle.lp", "stable ⊂ staged"),
        ("staged", "cf", "test/strict_inclusions/staged_subset_cf.lp", "staged ⊂ cf"),
        ("stable", "naive", "test/strict_inclusions/stable_subset_naive.lp", "stable ⊂ naive"),
        ("naive", "cf", "test/strict_inclusions/naive_subset_cf.lp", "naive ⊂ cf"),
        # Ideal semantics not implemented yet
        # ("grounded", "ideal", "test/strict_inclusions/grounded_ideal_selfattack.lp", "grounded ⊂ ideal"),
        # ("ideal", "complete", "test/strict_inclusions/ideal_subset_complete.lp", "ideal ⊂ complete"),
    ]

    passed = 0
    failed = 0

    for sem_a, sem_b, framework, relation in test_cases:
        if test_strict_inclusion(sem_a, sem_b, framework, relation):
            passed += 1
        else:
            failed += 1

    print("\n" + "=" * 70)
    print(f"Results: {passed} strict inclusions verified, {failed} failed")
    print("=" * 70)

    sys.exit(0 if failed == 0 else 1)

if __name__ == "__main__":
    main()
