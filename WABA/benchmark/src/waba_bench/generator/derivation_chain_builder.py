#!/usr/bin/env python3
"""
Derivation Chain Builder for WABA Frameworks

Ensures every derived atom participates in at least one attack chain.

Attack Chain Pattern:
    assumptions/derived → derived_atom → ... → contrary_atom

Strategy:
1. Generate derived atoms
2. Create derivation rules: assumptions → derived atoms
3. Create attack chains: some derived atoms → contraries (or → other derived → contraries)
4. Ensure ALL derived atoms are reachable and lead to contraries
"""

import random
from typing import List, Tuple, Dict, Set, Optional


def build_attack_chains(
    assumptions: List[str],
    derived_atoms: List[str],
    contraries: Dict[str, str],
    depth: int = 2,
    seed: int = 42,
    required_contraries: List[str] = None,
    topology_constraints: Optional[Dict] = None
) -> List[Tuple[str, str, List[str]]]:
    """
    Build derivation rules ensuring ALL derived atoms participate in attack chains.

    Strategy:
    - Level 1: assumptions → derived atoms
    - Level 2+: derived atoms → other derived atoms
    - Final level: derived atoms → contraries (attacks!)

    Args:
        assumptions: List of assumption atoms
        derived_atoms: List of derived atom names (d1, d2, ...)
        contraries: Dict mapping assumptions to their contrary atoms
        depth: Maximum derivation depth (levels before reaching contrary)
        seed: Random seed
        required_contraries: List of contrary atoms that MUST be targeted (e.g., derived-only contraries)
        topology_constraints: Optional dict specifying topology structure constraints
            Format: {
                'type': 'isolated' | 'mixed' | None,
                'groups': {'a1': 0, 'a2': 0, 'a3': 1, ...},  # assumption -> group_id
                'cross_group_probability': 0.0  # 0.0 for isolated, 0.1 for mixed
            }

    Returns:
        List of (rule_id, head, body_atoms) tuples ensuring attack chain coverage
    """
    random.seed(seed)

    if not derived_atoms:
        return []

    # Helper function: filter assumptions based on topology constraints
    def get_compatible_assumptions(target_assumption: str, all_assumptions: List[str]) -> List[str]:
        """Get assumptions compatible with target based on topology constraints."""
        if not topology_constraints:
            # No constraints - return all assumptions
            return all_assumptions

        groups = topology_constraints.get('groups', {})
        cross_prob = topology_constraints.get('cross_group_probability', 0.0)

        if not groups or target_assumption not in groups:
            # No group info - return all
            return all_assumptions

        target_group = groups[target_assumption]

        # Separate into same-group and cross-group
        same_group = [a for a in all_assumptions if groups.get(a) == target_group]
        cross_group = [a for a in all_assumptions if groups.get(a) != target_group]

        # Decide whether to allow cross-group based on probability
        if cross_prob == 0.0:
            # Strict: only same group (isolated topology)
            return same_group if same_group else all_assumptions
        else:
            # For mixed topology: allow cross-group with given probability
            # To ensure actual cross-cluster rules, we need to be more deliberate
            if random.random() < cross_prob:
                # Force cross-group by preferring assumptions from other groups
                # Return cross_group with higher probability to ensure mixing
                if cross_group:
                    # Mix same and cross group to enable cross-cluster bodies
                    return all_assumptions
                else:
                    return all_assumptions
            else:
                # Prefer same group (90% of the time)
                return same_group if same_group else all_assumptions

    rules = []
    rule_counter = 0

    # Get list of contrary atoms
    contrary_atoms = list(contraries.values())

    # Track required contraries (must be targeted)
    required_set = set(required_contraries) if required_contraries else set()

    # Divide derived atoms into levels
    num_derived = len(derived_atoms)

    levels = []
    if depth == 1 or num_derived == 0:
        # All atoms in one level
        if num_derived > 0:
            levels.append(derived_atoms)
    else:
        # Distribute across depth levels, with last level taking all remaining
        atoms_per_level = max(1, num_derived // depth)

        for d in range(depth):
            start_idx = d * atoms_per_level

            # Last level gets ALL remaining atoms (handles remainder from integer division)
            if d == depth - 1:
                end_idx = num_derived
            else:
                end_idx = (d + 1) * atoms_per_level

            if start_idx < num_derived:
                levels.append(derived_atoms[start_idx:end_idx])

    # Level 1: assumptions → first-level derived atoms
    level1_atoms = levels[0] if levels else []
    for d_atom in level1_atoms:
        rule_id = f"r_d1_{rule_counter + 1}"
        rule_counter += 1

        # Body: 1-3 random assumptions (respecting topology constraints)
        body_size = random.randint(1, min(3, len(assumptions)))

        # Check if we should create a cross-cluster rule (for mixed topology)
        if topology_constraints and topology_constraints.get('cross_group_probability', 0.0) > 0.0:
            cross_prob = topology_constraints['cross_group_probability']
            groups = topology_constraints.get('groups', {})

            # Decide whether this rule should span clusters
            if random.random() < cross_prob and body_size >= 2 and groups:
                # Create a cross-cluster rule by sampling from different clusters
                available_groups = list(set(groups.values()))
                if len(available_groups) >= 2:
                    # Pick 2 different clusters
                    selected_groups = random.sample(available_groups, min(2, len(available_groups)))
                    body = []
                    for group_id in selected_groups:
                        group_assumptions = [a for a in assumptions if groups.get(a) == group_id]
                        if group_assumptions:
                            body.append(random.choice(group_assumptions))
                    # Fill remaining body slots from any cluster if needed
                    while len(body) < body_size and len(body) < len(assumptions):
                        candidate = random.choice(assumptions)
                        if candidate not in body:
                            body.append(candidate)
                else:
                    # Fall back to normal sampling if not enough clusters
                    body = random.sample(assumptions, body_size) if assumptions else []
            else:
                # Normal intra-cluster rule
                reference_assumption = random.choice(assumptions) if assumptions else None
                if reference_assumption:
                    compatible = get_compatible_assumptions(reference_assumption, assumptions)
                else:
                    compatible = assumptions
                actual_body_size = min(body_size, len(compatible)) if compatible else 0
                body = random.sample(compatible, actual_body_size) if actual_body_size > 0 else []
        else:
            # No topology constraints or isolated topology (strict)
            reference_assumption = random.choice(assumptions) if assumptions else None
            if reference_assumption and topology_constraints:
                compatible = get_compatible_assumptions(reference_assumption, assumptions)
            else:
                compatible = assumptions
            actual_body_size = min(body_size, len(compatible)) if compatible else 0
            body = random.sample(compatible, actual_body_size) if actual_body_size > 0 else []

        if body:  # Only add rule if we have a body
            rules.append((rule_id, d_atom, body))

    # Middle levels: derived → derived
    for level_idx in range(1, len(levels)):
        current_level = levels[level_idx]
        prev_level = levels[level_idx - 1]

        for d_atom in current_level:
            rule_id = f"r_d{level_idx + 1}_{rule_counter + 1}"
            rule_counter += 1

            # Body: mix of previous level derived + some assumptions (respecting topology)
            # Use a random assumption as reference for topology constraints
            reference_assumption = random.choice(assumptions) if assumptions else None
            if reference_assumption and topology_constraints:
                compatible_assumptions = get_compatible_assumptions(reference_assumption, assumptions[:len(assumptions)//2])
            else:
                compatible_assumptions = assumptions[:len(assumptions)//2]

            available = prev_level + compatible_assumptions
            body_size = random.randint(1, min(3, len(available)))
            body = random.sample(available, body_size) if available else []

            if body:  # Only add rule if we have a body
                rules.append((rule_id, d_atom, body))

    # CRITICAL: Final level - derived atoms → contraries (ATTACK CHAINS!)
    # Ensure EVERY derived atom eventually leads to a contrary
    # Ensure ALL required contraries (derived-only) get at least one attack rule

    # Strategy:
    # 1. FIRST create attack rules for required contraries (must have coverage)
    # 2. THEN create rules for other contraries using remaining/all derived atoms
    # Each derived atom MUST appear in at least one attack rule

    # Build reverse mapping: contrary → assumption (for topology constraints)
    contrary_to_assumption = {v: k for k, v in contraries.items()}

    # Build derived atom group membership (based on first-level derivation sources)
    # This ensures derived atoms respect topology when attacking
    derived_groups = {}
    if topology_constraints and 'groups' in topology_constraints:
        groups = topology_constraints['groups']
        # For each level-1 derived atom, assign it to the group of its source assumptions
        for rule_id, head, body in rules:
            if head in derived_atoms:
                # Find which groups the body atoms belong to
                body_groups = set()
                for atom in body:
                    if atom in groups:
                        body_groups.add(groups[atom])
                # Assign derived atom to the majority group (or first if tie)
                if body_groups:
                    derived_groups[head] = list(body_groups)[0]

    # Track which derived atoms have been used
    used_derived = set()
    # Track which contraries have been targeted
    targeted_contraries = set()

    # Helper: Check if derived atoms can attack a target assumption (topology compatible)
    def can_attack_target(target_assumption: str, attacking_derived: List[str]) -> bool:
        """Check if derived atoms can attack target based on topology constraints."""
        if not topology_constraints or not derived_groups:
            return True  # No constraints

        target_group = topology_constraints.get('groups', {}).get(target_assumption)
        if target_group is None:
            return True  # Target has no group

        # Check if any of the attacking derived atoms are in compatible group
        for d_atom in attacking_derived:
            d_group = derived_groups.get(d_atom)
            if d_group is None:
                continue  # Derived atom has no group assignment yet

            if topology_constraints.get('cross_group_probability', 0.0) == 0.0:
                # Strict isolation: must be same group
                if d_group == target_group:
                    return True
            else:
                # Mixed: allow cross-group with some probability
                return True  # For mixed, we allow it (probability handled earlier)

        return topology_constraints.get('cross_group_probability', 0.0) > 0.0

    # Step 1: Create attack rules for ALL required contraries (derived-only)
    for contrary in sorted(required_set):
        rule_id = f"r_atk_d_{rule_counter + 1}"
        rule_counter += 1

        # Get target assumption for topology filtering
        target_assumption = contrary_to_assumption.get(contrary)

        # Filter derived atoms that can attack this target
        unused_derived = [d for d in derived_atoms if d not in used_derived]

        # Further filter by topology compatibility if constraints exist
        if target_assumption and derived_groups and unused_derived:
            compatible_unused = [d for d in unused_derived if can_attack_target(target_assumption, [d])]
            if compatible_unused:
                unused_derived = compatible_unused

        if unused_derived:
            # Prioritize unused derived atoms
            body_size = random.randint(1, min(2, len(unused_derived)))
            body = random.sample(unused_derived, body_size)
        else:
            # All derived atoms used or none compatible, can reuse any compatible
            if target_assumption and derived_groups:
                compatible_all = [d for d in derived_atoms if can_attack_target(target_assumption, [d])]
                if compatible_all:
                    body_size = random.randint(1, min(2, len(compatible_all)))
                    body = random.sample(compatible_all, body_size)
                else:
                    # No compatible derived atoms - skip this rule or use any
                    body = random.sample(derived_atoms[:1], 1) if derived_atoms else []
            else:
                body_size = random.randint(1, min(2, len(derived_atoms)))
                body = random.sample(derived_atoms, body_size) if derived_atoms else []

        if not body:
            continue  # Skip if no body

        # Track which derived atoms we've used
        used_derived.update(body)
        targeted_contraries.add(contrary)

        # Optionally add an assumption to the body (mixed rule, respecting topology)
        if random.random() < 0.3 and assumptions:  # 30% chance
            # Get target assumption for this contrary
            target_assumption = contrary_to_assumption.get(contrary)
            if target_assumption and topology_constraints:
                compatible = get_compatible_assumptions(target_assumption, assumptions)
                if compatible:
                    body.append(random.choice(compatible))
            else:
                body.append(random.choice(assumptions))

        rules.append((rule_id, contrary, body))

    # Step 2: Create additional attack rules for other contraries (ensuring all derived atoms are used)
    remaining_contraries = [c for c in contrary_atoms if c not in targeted_contraries]
    num_additional_rules = max(len(derived_atoms) - len(used_derived), len(remaining_contraries) // 2)
    target_contraries = random.sample(remaining_contraries, min(num_additional_rules, len(remaining_contraries))) if remaining_contraries else []

    for i, contrary in enumerate(target_contraries):
        rule_id = f"r_atk_d_{rule_counter + 1}"
        rule_counter += 1

        # Ensure we use derived atoms that haven't been used yet
        unused_derived = [d for d in derived_atoms if d not in used_derived]

        if unused_derived:
            # Prioritize unused derived atoms
            body_size = random.randint(1, min(2, len(unused_derived)))
            body = random.sample(unused_derived, body_size)
        else:
            # All derived atoms used, can reuse any
            body_size = random.randint(1, min(2, len(derived_atoms)))
            body = random.sample(derived_atoms, body_size)

        # Track which derived atoms we've used
        used_derived.update(body)

        # Optionally add an assumption to the body (mixed rule, respecting topology)
        if random.random() < 0.3 and assumptions:  # 30% chance
            # Get target assumption for this contrary
            target_assumption = contrary_to_assumption.get(contrary)
            if target_assumption and topology_constraints:
                compatible = get_compatible_assumptions(target_assumption, assumptions)
                if compatible:
                    body.append(random.choice(compatible))
            else:
                body.append(random.choice(assumptions))

        rules.append((rule_id, contrary, body))

    # CRITICAL: Ensure ALL derived atoms are used
    # If some derived atoms are still unused, create additional attack rules
    still_unused = [d for d in derived_atoms if d not in used_derived]

    for unused in still_unused:
        rule_id = f"r_atk_d_{rule_counter + 1}"
        rule_counter += 1

        # Select a random contrary atom
        contrary = random.choice(contrary_atoms)

        # Body: include the unused derived atom
        body = [unused]

        # Optionally add another atom for variety (respecting topology)
        if random.random() < 0.5:
            target_assumption = contrary_to_assumption.get(contrary)
            if target_assumption and topology_constraints:
                # Prefer assumptions compatible with target
                compatible = get_compatible_assumptions(target_assumption, assumptions)
                candidates = derived_atoms + compatible
            else:
                candidates = derived_atoms + assumptions

            if candidates:
                other_atom = random.choice(candidates)
                if other_atom != unused:
                    body.append(other_atom)

        rules.append((rule_id, contrary, body))

    return rules


def validate_attack_chain_coverage(
    derived_atoms: List[str],
    rules: List[Tuple[str, str, List[str]]],
    contraries: Dict[str, str]
) -> Tuple[bool, Set[str]]:
    """
    Validate that all derived atoms participate in attack chains.

    Args:
        derived_atoms: List of derived atom names
        rules: List of (rule_id, head, body) tuples
        contraries: Dict of assumption -> contrary

    Returns:
        (all_valid, set_of_useless_atoms)
    """
    contrary_set = set(contraries.values())

    # Build derivation graph: atom -> {atoms it helps derive}
    derives = {}
    for _, head, body in rules:
        for body_atom in body:
            if body_atom not in derives:
                derives[body_atom] = set()
            derives[body_atom].add(head)

    # BFS to check if each derived atom leads to a contrary
    useless_atoms = set()

    for d_atom in derived_atoms:
        visited = set()
        queue = [d_atom]
        found_contrary = False

        while queue and not found_contrary:
            current = queue.pop(0)
            if current in visited:
                continue
            visited.add(current)

            # Check if current is a contrary
            if current in contrary_set:
                found_contrary = True
                break

            # Explore what current derives
            if current in derives:
                for next_atom in derives[current]:
                    if next_atom not in visited:
                        queue.append(next_atom)

        if not found_contrary:
            useless_atoms.add(d_atom)

    all_valid = len(useless_atoms) == 0
    return all_valid, useless_atoms
