#!/usr/bin/env python3
"""
Strict validation for derived atoms in WABA frameworks.

Requirements:
1. Every framework MUST have at least one derived atom
2. Every derived atom MUST participate in at least one attack chain
3. Flat-WABA: No assumptions in rule heads
"""

import re
from pathlib import Path
from collections import defaultdict, deque
from typing import Set, Dict, List, Tuple


def validate_derived_atoms_strict(filepath: Path) -> Tuple[bool, List[str]]:
    """
    Strictly validate derived atoms according to requirements.

    Returns:
        (is_valid, list_of_issues)
    """
    issues = []

    with open(filepath) as f:
        content = f.read()

    # Parse framework
    assumptions = set()
    contraries = {}  # assumption -> contrary_atom
    rules = {}  # rule_id -> (head, [body_atoms])

    # Extract assumptions
    for line in content.split('\n'):
        if 'assumption(' in line and not line.strip().startswith('%'):
            atoms = line.split('assumption(')[1].split(')')[0]
            for atom in atoms.split(';'):
                atom = atom.strip()
                if atom:  # Skip empty strings
                    assumptions.add(atom)

    # Extract contraries
    for line in content.split('\n'):
        if 'contrary(' in line and not line.strip().startswith('%'):
            match = re.search(r'contrary\((\w+),\s*(\w+)\)', line)
            if match:
                contraries[match.group(1)] = match.group(2)

    # Extract rules
    for line in content.split('\n'):
        if 'head(' in line and not line.strip().startswith('%'):
            match = re.search(r'head\(([^,]+),\s*(\w+)\)', line)
            if match:
                rule_id = match.group(1).strip()
                head = match.group(2).strip()
                if rule_id not in rules:
                    rules[rule_id] = (head, [])

    for line in content.split('\n'):
        if 'body(' in line and not line.strip().startswith('%'):
            # Handle semicolon-separated facts: body(r1, a1; r1, a2)
            # Split on semicolon and parse each fact
            parts = line.split('body(')[1].split(')')[0]
            for fact in parts.split(';'):
                match = re.search(r'([^,]+),\s*(\w+)', fact.strip())
                if match:
                    rule_id = match.group(1).strip()
                    body_atom = match.group(2).strip()
                    if rule_id in rules:
                        rules[rule_id][1].append(body_atom)

    # Identify derived atoms (non-assumptions, non-contraries)
    all_heads = {head for head, _ in rules.values()}
    contrary_atoms = set(contraries.values())
    derived_atoms = all_heads - assumptions - contrary_atoms

    # REQUIREMENT 1: At least one derived atom
    if not derived_atoms:
        issues.append("MANDATORY: Framework must have at least one derived atom")
        return False, issues

    # REQUIREMENT 2: Flat-WABA - no assumptions in heads
    assumptions_in_heads = all_heads & assumptions
    if assumptions_in_heads:
        issues.append(f"FLAT-WABA VIOLATION: Assumptions appear in rule heads: {assumptions_in_heads}")

    # REQUIREMENT 3: Every derived atom must lead to a contrary
    # Build derivation graph: atom -> set of atoms it can derive
    derives = defaultdict(set)
    for head, body in rules.values():
        for body_atom in body:
            derives[body_atom].add(head)

    def leads_to_contrary(atom: str, visited: Set[str] = None) -> bool:
        """Check if atom leads to any contrary (BFS)."""
        if visited is None:
            visited = set()

        queue = deque([atom])
        visited.add(atom)

        while queue:
            current = queue.popleft()

            # Check if current is a contrary
            if current in contrary_atoms:
                return True

            # Explore what current can derive
            for derived in derives[current]:
                if derived not in visited:
                    visited.add(derived)
                    queue.append(derived)

        return False

    useless_derived = []
    for d_atom in derived_atoms:
        if not leads_to_contrary(d_atom):
            useless_derived.append(d_atom)

    if useless_derived:
        issues.append(f"CRITICAL: Derived atoms don't lead to attacks: {sorted(useless_derived)}")

    is_valid = len(issues) == 0
    return is_valid, issues


def validate_framework_file(filepath: Path, verbose: bool = False) -> bool:
    """
    Validate a single framework file.

    Returns:
        True if valid, False otherwise
    """
    is_valid, issues = validate_derived_atoms_strict(filepath)

    if verbose:
        if is_valid:
            print(f"✅ {filepath.name}: VALID")
        else:
            print(f"❌ {filepath.name}: INVALID")
            for issue in issues:
                print(f"   - {issue}")

    return is_valid


def main():
    """Validate all frameworks in benchmark/frameworks/."""
    import sys

    benchmark_dir = Path(__file__).parent.parent / 'frameworks'

    if not benchmark_dir.exists():
        print(f"Error: {benchmark_dir} not found")
        sys.exit(1)

    all_frameworks = list(benchmark_dir.glob('*/*.lp'))
    valid_count = 0
    invalid_count = 0

    print("=" * 80)
    print("STRICT DERIVED ATOM VALIDATION")
    print("=" * 80)
    print()

    for fw_file in sorted(all_frameworks):
        is_valid = validate_framework_file(fw_file, verbose=True)
        if is_valid:
            valid_count += 1
        else:
            invalid_count += 1

    print()
    print("=" * 80)
    print(f"Results: {valid_count} valid, {invalid_count} invalid out of {len(all_frameworks)} total")
    print("=" * 80)

    if invalid_count > 0:
        sys.exit(1)


if __name__ == '__main__':
    main()
