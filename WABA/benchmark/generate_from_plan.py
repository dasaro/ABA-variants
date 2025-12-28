#!/usr/bin/env python3
"""
Generate WABA frameworks from experimental plan.

This module takes plan entries from planner.py and generates corresponding
.lp framework files with .meta.json sidecar metadata using real topology generators.
"""

import json
import sys
from pathlib import Path
from typing import List, Dict, Any

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))
sys.path.insert(0, str(Path(__file__).parent / 'generator'))

from utils import derive_seed, create_rng, get_git_status, write_framework_metadata

# Import real generators
from generator.framework_templates import FrameworkGenerator
from generator.dimension_config import WEIGHT_SCHEME_MAP, WeightScheme


# Weight scheme name mapping (planner names → dimension_config names)
PLANNER_TO_DIM_CONFIG_NAMES = {
    'uniform': 'medium_uniform',
    'power_law': 'power_law',
    'bimodal': 'bimodal',
    'sparse': 'sparse_uniform',
}


def generate_frameworks_from_plan(plan_entries: List[Dict[str, Any]], output_dir: Path):
    """
    Generate frameworks from plan entries using real topology generators.

    Args:
        plan_entries: List of plan entry dicts from plan.jsonl
        output_dir: Base output directory for frameworks

    Each framework is written to:
        {output_dir}/{topology}/{instance_id}.lp
        {output_dir}/{topology}/{instance_id}.meta.json
    """
    output_dir = Path(output_dir)

    for i, entry in enumerate(plan_entries):
        print(f"[{i+1}/{len(plan_entries)}] Generating {entry['instance_id']}...", end=" ")

        try:
            # Extract parameters from plan entry
            topology = entry['topology']
            instance_id = entry['instance_id']
            A = entry['A']
            R = entry['R']
            D = entry['D']
            body_max = entry['body_max']
            weight_scheme_name = entry['weight_scheme']
            operator = entry['operator']
            budget_level = entry.get('budget_level')  # Optional (None if disabled)
            replicate = entry['replicate']
            instance_seed = entry['instance_seed']
            plan_id = entry['plan_id']

            # Create output paths
            topo_dir = output_dir / topology
            topo_dir.mkdir(parents=True, exist_ok=True)

            lp_path = topo_dir / f"{instance_id}.lp"
            meta_path = topo_dir / f"{instance_id}.meta.json"

            # Map weight scheme name to WeightScheme object
            dim_config_name = PLANNER_TO_DIM_CONFIG_NAMES.get(weight_scheme_name)
            if not dim_config_name:
                raise ValueError(f"Unknown weight scheme: {weight_scheme_name}")

            weight_scheme = WEIGHT_SCHEME_MAP.get(dim_config_name)
            if not weight_scheme:
                raise ValueError(f"Weight scheme not found in map: {dim_config_name}")

            # Create framework generator with instance seed (DETERMINISTIC)
            generator = FrameworkGenerator(seed=instance_seed)

            # Generate framework using real topology generator
            predicates = generate_framework_for_topology(
                generator=generator,
                topology=topology,
                A=A,
                R=R,
                D=D,
                body_max=body_max,
                weight_scheme=weight_scheme,
                budget_level=budget_level or 'medium',  # Default if None
                instance_seed=instance_seed
            )

            # Write .lp file (NO budget/1 predicate - guardrail enforced)
            write_framework_to_file(predicates, lp_path, instance_id)

            # Extract structural stats from generated framework
            metadata_stats = predicates.get('metadata', {})

            # Create comprehensive metadata
            metadata = {
                'plan_id': plan_id,
                'instance_id': instance_id,
                'topology': topology,
                'parameters': {
                    'A': A,
                    'R': R,
                    'D': D,
                    'body_max': body_max,
                    'weight_scheme': weight_scheme_name,
                    'operator': operator,
                    'budget_level': budget_level,  # None if disabled
                    'replicate': replicate
                },
                'seeds': {
                    'master': entry['master_seed'],
                    'instance': instance_seed,
                },
                'structural': metadata_stats,  # Real stats from generation
                'file_path': str(lp_path),
                'timestamp': entry['timestamp'],
                'generator_version': '2.0.0',
                'git': get_git_status(),
                'design_type': entry['design_type'],
            }

            # CRITICAL: budget_level is metadata-only, NOT in .lp file

            # Write .meta.json
            write_framework_metadata(meta_path, metadata)

            print("✓")

        except Exception as e:
            print(f"✗ ERROR: {e}")
            # Log error but continue with other instances
            import traceback
            traceback.print_exc()
            # Don't raise - let other instances continue


def generate_framework_for_topology(
    generator: FrameworkGenerator,
    topology: str,
    A: int,
    R: int,
    D: int,
    body_max: int,
    weight_scheme: WeightScheme,
    budget_level: str,
    instance_seed: int
) -> Dict[str, Any]:
    """
    Generate framework using appropriate topology generator.

    Args:
        generator: FrameworkGenerator instance (initialized with instance_seed)
        topology: Topology type (linear, tree, cycle, complete, mixed, isolated)
        A: Number of assumptions
        R: Number of derivation rules
        D: Maximum derivation depth
        body_max: Maximum rule body size (used for some topologies)
        weight_scheme: WeightScheme object
        budget_level: Budget level ('tight', 'medium', 'loose')
        instance_seed: Seed for topology-specific parameters

    Returns:
        Dict with framework predicates (assumptions, weights, rules, contraries, metadata)
    """
    # Use instance_seed to derive topology-specific parameters deterministically
    param_rng = create_rng(derive_seed(instance_seed, topology, "params"))

    # Call appropriate topology generator
    if topology == 'linear':
        predicates = generator.generate_linear(
            A=A, R=R, D=D,
            weight_scheme=weight_scheme,
            budget_level=budget_level
        )

    elif topology == 'tree':
        # Determine branching factor from body_max
        branching_factor = max(2, body_max)
        predicates = generator.generate_tree(
            A=A, R=R, D=D,
            branching_factor=branching_factor,
            weight_scheme=weight_scheme,
            budget_level=budget_level
        )

    elif topology == 'cycle':
        # Determine cycle length (use 'full' for A-cycle)
        cycle_length = 'full'
        predicates = generator.generate_cycle(
            A=A, R=R,
            cycle_length=cycle_length,
            weight_scheme=weight_scheme,
            budget_level=budget_level
        )

    elif topology == 'complete':
        predicates = generator.generate_complete(
            A=A, R=R, D=D,
            weight_scheme=weight_scheme,
            budget_level=budget_level
        )

    elif topology == 'mixed':
        # Determine number of clusters (2-4 clusters)
        num_clusters = param_rng.randint(2, min(4, A // 3 + 1))
        predicates = generator.generate_mixed(
            A=A, R=R, D=D,
            num_clusters=num_clusters,
            weight_scheme=weight_scheme,
            budget_level=budget_level
        )

    elif topology == 'isolated':
        # Determine number of components (2-3 components)
        num_components = param_rng.randint(2, min(3, A // 4 + 1))
        predicates = generator.generate_isolated(
            A=A, R=R, D=D,
            num_components=num_components,
            weight_scheme=weight_scheme,
            budget_level=budget_level
        )

    else:
        raise ValueError(f"Unknown topology: {topology}")

    return predicates


def write_framework_to_file(predicates: Dict[str, Any], lp_path: Path, instance_id: str):
    """
    Write framework predicates to .lp file, ensuring NO budget/1 predicate.

    Args:
        predicates: Dict from topology generator (has keys: assumptions, weights, rules, contraries, metadata, budget)
        lp_path: Path to output .lp file
        instance_id: Instance identifier for header

    Note: The generators return STRINGS (already formatted ASP code), not lists.
    """
    sections = []

    # Header
    sections.append(f"% WABA Framework Instance: {instance_id}")
    sections.append(f"% Generated by WABA Benchmark Suite v2.0")
    sections.append("")

    # Assumptions (string with compact form: "assumption(a1; a2; a3).")
    if 'assumptions' in predicates and predicates['assumptions']:
        sections.append("% Assumptions")
        sections.append(predicates['assumptions'])
        sections.append("")

    # Weights (multi-line string: "weight(a1, 10).\nweight(a2, 20).")
    if 'weights' in predicates and predicates['weights']:
        sections.append("% Weights")
        sections.append(predicates['weights'])
        sections.append("")

    # Rules (multi-line string with rules and blank lines between them)
    if 'rules' in predicates and predicates['rules']:
        sections.append("% Derivation Rules")
        sections.append(predicates['rules'])
        sections.append("")

    # Contraries (multi-line string: "contrary(a1, attacker).\n...")
    if 'contraries' in predicates and predicates['contraries']:
        sections.append("% Contraries")
        sections.append(predicates['contraries'])
        sections.append("")

    # CRITICAL GUARDRAIL: DO NOT write budget predicate
    # Budget is metadata-only and should NOT be in .lp file
    if 'budget' in predicates:
        sections.append("% CRITICAL: budget/1 predicate is metadata-only (NOT included in .lp)")
        sections.append(f"% Budget value (for reference only): {predicates['budget']}")
        sections.append("")

    # Write to file
    with open(lp_path, 'w') as f:
        f.write('\n'.join(sections))
