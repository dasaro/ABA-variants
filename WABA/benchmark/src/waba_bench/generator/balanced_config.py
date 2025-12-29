#!/usr/bin/env python3
"""
Perfectly Balanced WABA Benchmark Configuration

Generates a systematic grid over key parameters:
- Assumption counts (a): 2, 5, 10, 15, 20
- Rule densities (r): 2, 5
- Derivation depths (d): 1, 2
- Topology classes: linear, tree, cycle, complete, mixed, isolated

This ensures complete factorial coverage for academic rigor.
Target: 120 frameworks (20 per topology × 6 topologies)
"""

from typing import List, Dict
from dimension_config import (
    WEIGHT_DENSE_UNIFORM,
    WEIGHT_POWER_LAW,
    WEIGHT_RANDOM,
    WEIGHT_BIMODAL,
    WEIGHT_MEDIUM_UNIFORM
)


# ================================================================
# BALANCED PARAMETER SPACE
# ================================================================

# Core parameters - chosen for complete coverage
ASSUMPTION_COUNTS = [2, 5, 10, 15, 20]
"""Assumption counts: small (2, 5), medium (10, 15), large (20)"""

RULE_DENSITIES = [2, 5]
"""Rule densities: low (2), high (5)"""

DERIVATION_DEPTHS = [1, 2]
"""Derivation depths: shallow (1), deep (2)"""

# Topology classes (all 6 types for complete coverage)
TOPOLOGY_CLASSES = ['linear', 'tree', 'cycle', 'complete', 'mixed', 'isolated']

# Weight distributions (3 main types)
WEIGHT_DISTRIBUTIONS = [
    WEIGHT_DENSE_UNIFORM,
    WEIGHT_POWER_LAW,
    WEIGHT_RANDOM
]

# Constraint levels (2 types)
CONSTRAINT_LEVELS = ['tight', 'loose']


# Topology-specific parameters
TOPOLOGY_PARAMS = {
    'linear': {},  # No additional params
    'tree': {'branching_factor': 2},  # Binary trees
    'cycle': {'cycle_length': 3},  # Simple 3-cycles
    'complete': {},  # No additional params
    'mixed': {'num_clusters': 2},  # Two clusters
    'isolated': {'num_components': 2}  # Two disconnected components
}


# ================================================================
# BALANCED CONFIGURATION GENERATION
# ================================================================

def generate_balanced_configs_for_topology(topology: str) -> List[Dict]:
    """Generate perfectly balanced configurations for a single topology.

    Systematic grid:
    - All 5 assumption counts: [2, 5, 10, 15, 20]
    - All 2 rule densities: [2, 5]
    - All 2 derivation depths: [1, 2]
    - Weight distributions and constraints cycled

    Total: 5 × 2 × 2 = 20 configurations per topology
    """
    configs = []

    weight_idx = 0
    constraint_idx = 0

    for a in ASSUMPTION_COUNTS:
        for r in RULE_DENSITIES:
            for d in DERIVATION_DEPTHS:
                # Cycle through weight distributions
                weight_scheme = WEIGHT_DISTRIBUTIONS[weight_idx % len(WEIGHT_DISTRIBUTIONS)]
                weight_idx += 1

                # Cycle through constraint levels
                constraint = CONSTRAINT_LEVELS[constraint_idx % len(CONSTRAINT_LEVELS)]
                constraint_idx += 1

                # Base configuration
                config = {
                    'topology': topology,
                    'A': a,
                    'R': r,
                    'D': d,
                    'weight_scheme': weight_scheme,
                    'budget_level': constraint
                }

                # Add topology-specific parameters
                config.update(TOPOLOGY_PARAMS[topology])

                configs.append(config)

    return configs


def get_balanced_framework_configs() -> List[Dict]:
    """Get all balanced framework configurations.

    Returns:
        List of 120 configurations (20 per topology × 6 topologies)
    """
    configs = []

    for topology in TOPOLOGY_CLASSES:
        configs.extend(generate_balanced_configs_for_topology(topology))

    return configs


def print_balance_summary(configs: List[Dict]):
    """Print summary of balanced configuration."""
    print("="*80)
    print("BALANCED CONFIGURATION SUMMARY")
    print("="*80)

    # Count by topology
    topology_counts = {}
    for c in configs:
        t = c['topology']
        topology_counts[t] = topology_counts.get(t, 0) + 1

    print(f"\nTotal configurations: {len(configs)}")
    print("\nBy topology:")
    for t, count in sorted(topology_counts.items()):
        print(f"  {t:12s}: {count:3d} ({count/len(configs)*100:.1f}%)")

    # Count by assumption
    assumption_counts = {}
    for c in configs:
        a = c['A']
        assumption_counts[a] = assumption_counts.get(a, 0) + 1

    print("\nBy assumption count:")
    for a, count in sorted(assumption_counts.items()):
        print(f"  a={a:2d}: {count:3d} ({count/len(configs)*100:.1f}%)")

    # Count by rule density
    rule_counts = {}
    for c in configs:
        r = c['R']
        rule_counts[r] = rule_counts.get(r, 0) + 1

    print("\nBy rule density:")
    for r, count in sorted(rule_counts.items()):
        print(f"  r={r:2d}: {count:3d} ({count/len(configs)*100:.1f}%)")

    # Count by derivation depth
    depth_counts = {}
    for c in configs:
        d = c['D']
        depth_counts[d] = depth_counts.get(d, 0) + 1

    print("\nBy derivation depth:")
    for d, count in sorted(depth_counts.items()):
        print(f"  d={d:2d}: {count:3d} ({count/len(configs)*100:.1f}%)")

    # Parameter coverage matrix (sample - show complete topology as example)
    print("\n" + "="*80)
    print("PARAMETER COVERAGE MATRIX (Sample: Complete Topology)")
    print("="*80)

    topology = 'complete'
    print(f"\n{topology.upper()} topology:")
    print(f"{'':>8} ", end='')
    for d in DERIVATION_DEPTHS:
        print(f"d={d:1d}     ", end='')
    print()

    for a in ASSUMPTION_COUNTS:
        print(f"  a={a:2d}:", end='')
        for d in DERIVATION_DEPTHS:
            # Count configs with this (a, d) combination
            count_r2 = sum(1 for c in configs if c['topology'] == topology and c['A'] == a and c['D'] == d and c['R'] == 2)
            count_r5 = sum(1 for c in configs if c['topology'] == topology and c['A'] == a and c['D'] == d and c['R'] == 5)
            print(f" r2:{count_r2} r5:{count_r5}", end='')
        print()

    print("\n(All topologies have identical factorial coverage)")
    print("="*80)


# ================================================================
# MAIN (for testing)
# ================================================================

if __name__ == '__main__':
    configs = get_balanced_framework_configs()
    print_balance_summary(configs)

    # Verify balance
    print("\nVERIFICATION:")
    print("-" * 80)

    # Check total count
    expected_total = len(TOPOLOGY_CLASSES) * len(ASSUMPTION_COUNTS) * len(RULE_DENSITIES) * len(DERIVATION_DEPTHS)
    print(f"Total configurations: {len(configs)}/{expected_total} {'✓' if len(configs) == expected_total else '✗'}")

    # Check topology balance (all should have exactly 20)
    topology_counts = {}
    for c in configs:
        t = c['topology']
        topology_counts[t] = topology_counts.get(t, 0) + 1

    expected_per_topology = len(ASSUMPTION_COUNTS) * len(RULE_DENSITIES) * len(DERIVATION_DEPTHS)
    all_perfect = all(count == expected_per_topology for count in topology_counts.values())
    print(f"Topology balance: {'✓ PERFECT' if all_perfect else '✗ UNBALANCED'} (all should have {expected_per_topology})")
    for t in sorted(topology_counts.keys()):
        status = "✓" if topology_counts[t] == expected_per_topology else "✗"
        print(f"  {status} {t:12s}: {topology_counts[t]:3d}")

    # Check factorial coverage (each (a, r, d) appears exactly once per topology)
    print(f"\nFactorial coverage:")
    factorial_perfect = True
    for topology in TOPOLOGY_CLASSES:
        topo_configs = [c for c in configs if c['topology'] == topology]
        combinations = set()
        for c in topo_configs:
            combinations.add((c['A'], c['R'], c['D']))

        expected_combinations = len(ASSUMPTION_COUNTS) * len(RULE_DENSITIES) * len(DERIVATION_DEPTHS)
        if len(combinations) == expected_combinations:
            print(f"  ✓ {topology:12s}: {len(combinations)}/{expected_combinations} unique (a,r,d) combinations")
        else:
            print(f"  ✗ {topology:12s}: {len(combinations)}/{expected_combinations} unique (a,r,d) combinations")
            factorial_perfect = False

    # Check assumption coverage
    assumption_counts = set(c['A'] for c in configs)
    complete_coverage = all(a in assumption_counts for a in ASSUMPTION_COUNTS)
    print(f"\nAssumption coverage: {'✓ COMPLETE' if complete_coverage else '✗ INCOMPLETE'}")

    # Check rule density coverage
    rule_counts = set(c['R'] for c in configs)
    complete_rules = all(r in rule_counts for r in RULE_DENSITIES)
    print(f"Rule density coverage: {'✓ COMPLETE' if complete_rules else '✗ INCOMPLETE'}")

    # Check depth coverage
    depth_counts = set(c['D'] for c in configs)
    complete_depths = all(d in depth_counts for d in DERIVATION_DEPTHS)
    print(f"Depth coverage: {'✓ COMPLETE' if complete_depths else '✗ INCOMPLETE'}")

    # Overall result
    print("\n" + "-" * 80)
    if len(configs) == expected_total and all_perfect and factorial_perfect and complete_coverage and complete_rules and complete_depths:
        print("✓ PERFECT BALANCE ACHIEVED - Ready for benchmarking!")
    else:
        print("✗ Balance verification failed - see errors above")
    print("-" * 80)
