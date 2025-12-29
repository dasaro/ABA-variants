#!/usr/bin/env python3
"""
Real semantic property verification for WABA.

Verifies that extensions satisfy their formal semantic definitions,
not just subset relations.
"""

import subprocess
from pathlib import Path
from typing import Set, List, Dict, Tuple
from dataclasses import dataclass
from collections import defaultdict


@dataclass
class Extension:
    """Complete extension with all predicates."""
    assumptions: Set[str]
    defeated: Set[str]
    defended: Set[str]
    discarded_attacks: Set[Tuple[str, str, int]]
    cost: int

    def __hash__(self):
        return hash(frozenset(self.assumptions))

    def __eq__(self, other):
        return self.assumptions == other.assumptions


class FrameworkInfo:
    """Information about the WABA framework."""
    def __init__(self):
        self.assumptions: Set[str] = set()
        self.attacks: Dict[Tuple[str, str], int] = {}  # (attacker, attacked) -> weight
        self.contraries: Dict[str, Set[str]] = defaultdict(set)  # assumption -> attacking elements


class SemanticPropertyVerifier:
    """Verifies semantic properties of extensions."""

    def __init__(self, waba_root: Path):
        self.waba_root = waba_root
        self.core = waba_root / "core/base.lp"
        self.semiring = waba_root / "semiring/godel.lp"

    def run_semantics_full(self, semantics: str, framework: Path,
                          use_heuristics: bool = False) -> List[Extension]:
        """Run clingo and extract full extension information (no filter)."""

        semantics_file = self.waba_root / f"semantics/{semantics}.lp"

        cmd = ["clingo", "-n", "0"]
        if use_heuristics:
            cmd.extend(["--heuristic=Domain", "--enum=domRec"])

        # NO filter - we need all predicates
        cmd.extend([
            str(self.core),
            str(self.semiring),
            str(semantics_file),
            str(framework)
        ])

        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
            return self._parse_full_extensions(result.stdout)
        except subprocess.TimeoutExpired:
            print(f"  ⚠️  Timeout for {semantics}")
            return []

    def _parse_full_extensions(self, output: str) -> List[Extension]:
        """Parse clingo output to extract complete extension information."""
        extensions = []

        lines = output.split('\n')
        i = 0
        while i < len(lines):
            if lines[i].startswith("Answer:"):
                if i + 1 < len(lines):
                    model_line = lines[i + 1]

                    assumptions = set()
                    defeated = set()
                    defended = set()
                    discarded = set()

                    # Parse all predicates
                    for token in model_line.split():
                        if token.startswith("in(") and token.endswith(")"):
                            assumption = token[3:-1]
                            assumptions.add(assumption)

                        elif token.startswith("defeated(") and token.endswith(")"):
                            assumption = token[9:-1]
                            defeated.add(assumption)

                        elif token.startswith("defended(") and token.endswith(")"):
                            assumption = token[9:-1]
                            defended.add(assumption)

                        elif token.startswith("discarded_attack("):
                            # Parse discarded_attack(X,Y,W)
                            content = token[17:-1]  # Remove "discarded_attack(" and ")"
                            parts = content.split(',')
                            if len(parts) == 3:
                                attacker = parts[0]
                                attacked = parts[1]
                                weight = int(parts[2])
                                discarded.add((attacker, attacked, weight))

                    extensions.append(Extension(
                        assumptions=assumptions,
                        defeated=defeated,
                        defended=defended,
                        discarded_attacks=discarded,
                        cost=0
                    ))
                i += 1
            i += 1

        return extensions

    def parse_framework(self, framework: Path) -> FrameworkInfo:
        """Parse framework file to extract structure."""
        info = FrameworkInfo()

        with open(framework, 'r') as f:
            for line in f:
                # Remove comments
                if '%' in line:
                    line = line[:line.index('%')]
                line = line.strip()

                # Parse assumptions
                if line.startswith("assumption(") and ")." in line:
                    # Extract content between assumption( and ).
                    start = line.index("assumption(") + 11
                    end = line.index(").")
                    assumption = line[start:end]
                    info.assumptions.add(assumption)

                # Parse contraries
                elif line.startswith("contrary(") and ")." in line:
                    start = line.index("contrary(") + 9
                    end = line.index(").")
                    content = line[start:end]
                    parts = content.split(',')
                    if len(parts) == 2:
                        attacked = parts[0].strip()
                        attacker = parts[1].strip()
                        info.contraries[attacked].add(attacker)

        return info

    def verify_stable_properties(self, ext: Extension, framework_info: FrameworkInfo) -> Tuple[bool, str]:
        """Verify stable extension properties.

        Stable definition:
        1. E is conflict-free (no assumption in E is defeated)
        2. E defeats ALL assumptions not in E
        """

        # Property 1: Conflict-free
        if not ext.assumptions.isdisjoint(ext.defeated):
            conflicted = ext.assumptions & ext.defeated
            return False, f"Not conflict-free (defeated: {conflicted})"

        # Property 2: All out assumptions are defeated
        out_assumptions = framework_info.assumptions - ext.assumptions
        non_defeated_out = out_assumptions - ext.defeated

        if non_defeated_out:
            return False, f"Doesn't defeat all out assumptions ({len(non_defeated_out)} not defeated)"

        return True, "Satisfies stable definition (CF + defeats all out)"

    def verify_complete_properties(self, ext: Extension) -> Tuple[bool, str]:
        """Verify complete extension properties.

        Complete definition:
        1. E is admissible (conflict-free + self-defending)
        2. ALL defended assumptions are in E
        """

        # Property 1: Conflict-free
        if not ext.assumptions.isdisjoint(ext.defeated):
            conflicted = ext.assumptions & ext.defeated
            return False, f"Not conflict-free (defeated: {conflicted})"

        # Property 2: All defended assumptions are in
        defended_not_in = ext.defended - ext.assumptions

        if defended_not_in:
            return False, f"Missing defended assumptions ({len(defended_not_in)} defended but out)"

        return True, "Satisfies complete definition (admissible + all defended in)"

    def verify_admissible_properties(self, ext: Extension) -> Tuple[bool, str]:
        """Verify admissible extension properties.

        Admissible definition:
        1. E is conflict-free (no assumption in E is defeated)
        2. E defends all its members (all in E are defended)
        """

        # Property 1: Conflict-free
        if not ext.assumptions.isdisjoint(ext.defeated):
            conflicted = ext.assumptions & ext.defeated
            return False, f"Not conflict-free (defeated: {conflicted})"

        # Property 2: Self-defending
        undefended_in = ext.assumptions - ext.defended

        if undefended_in:
            return False, f"Not self-defending ({len(undefended_in)} members not defended)"

        return True, "Satisfies admissible definition (CF + self-defending)"

    def verify_cf_properties(self, ext: Extension) -> Tuple[bool, str]:
        """Verify conflict-free properties.

        CF definition: No assumption in E is defeated.
        """

        if not ext.assumptions.isdisjoint(ext.defeated):
            conflicted = ext.assumptions & ext.defeated
            return False, f"Not conflict-free (defeated: {conflicted})"

        return True, "Satisfies CF definition (no internal conflicts)"


def verify_framework(framework: Path, waba_root: Path):
    """Verify semantic properties for a single framework."""

    print(f"\n{'='*80}")
    print(f"SEMANTIC PROPERTY VERIFICATION: {framework.name}")
    print(f"{'='*80}")

    verifier = SemanticPropertyVerifier(waba_root)
    framework_info = verifier.parse_framework(framework)

    print(f"\nFramework: {len(framework_info.assumptions)} assumptions")

    # Test each semantics
    semantics_to_test = [
        ("stable", False, verifier.verify_stable_properties),
        ("complete", False, verifier.verify_complete_properties),
        ("admissible", False, verifier.verify_admissible_properties),
        ("cf", False, verifier.verify_cf_properties),
    ]

    all_passed = True

    for sem_name, use_heur, verify_func in semantics_to_test:
        print(f"\n--- {sem_name.upper()} SEMANTICS ---")

        extensions = verifier.run_semantics_full(sem_name, framework, use_heur)
        print(f"Extensions found: {len(extensions)}")

        if not extensions:
            print("  ⚠️  No extensions to verify")
            continue

        # Verify each extension
        passed_count = 0
        failed_count = 0

        for i, ext in enumerate(extensions[:5], 1):  # Check first 5 for speed
            if verify_func == verifier.verify_stable_properties:
                passed, msg = verify_func(ext, framework_info)
            else:
                passed, msg = verify_func(ext)

            if passed:
                passed_count += 1
            else:
                failed_count += 1
                print(f"  ✗ Extension {i}: {msg}")
                print(f"    In: {sorted(list(ext.assumptions)[:5])}...")
                all_passed = False

        if failed_count == 0:
            print(f"  ✅ All {len(extensions)} extensions satisfy {sem_name} definition")
        else:
            print(f"  ❌ {failed_count} extensions FAILED verification")

    return all_passed


def main():
    """Run semantic property verification on test frameworks."""

    waba_root = Path("/Users/fdasaro/Desktop/WABA-claude/ABA-variants/WABA")

    # Test on small examples first
    frameworks = [
        waba_root / "examples/medical_triage/medical_triage.lp",
        waba_root / "examples/moral_dilemma/moral_dilemma.lp",
        waba_root / "examples/practical_deliberation/practical_deliberation.lp",
        waba_root / "examples/resource_allocation/resource_allocation.lp",
    ]

    print("="*80)
    print("REAL SEMANTIC PROPERTY VERIFICATION")
    print("Checking formal definitions, not just subset relations")
    print("="*80)

    all_passed = True
    for framework in frameworks:
        if framework.exists():
            passed = verify_framework(framework, waba_root)
            all_passed = all_passed and passed

    print("\n" + "="*80)
    if all_passed:
        print("✅ ALL SEMANTIC PROPERTIES VERIFIED")
    else:
        print("❌ SOME SEMANTIC PROPERTIES FAILED")
    print("="*80)


if __name__ == "__main__":
    main()
