#!/usr/bin/env python3
"""
Dimension Configuration for WABA Benchmark Generation

Defines parameter spaces for the 4 complexity dimensions:
1. Assumption count
2. Rule count & depth
3. Attack connectivity (topology types)
4. Weight distribution

Used by framework_templates.py to systematically generate diverse benchmarks.
"""

from typing import List, Dict, Tuple
from dataclasses import dataclass
import sys
from pathlib import Path

# Add benchmark directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from utils import derive_seed, create_rng


# ================================================================
# DIMENSION 1: Assumption Count
# ================================================================

ASSUMPTION_COUNTS = [2, 10, 15, 20, 24, 28, 29, 30]
"""Assumption counts to test. Impact: exponential search space (2^A extensions).
Updated to remove a=5 and a=50, add gentler scaling in a=24-30 range."""


# ================================================================
# DIMENSION 2: Rule Count & Depth
# ================================================================

RULE_COUNTS = [0, 2, 5, 10, 20, 30]
"""Rule counts to test. Impact: weight propagation complexity."""

RULE_DEPTHS = [1, 2, 3, 4]
"""Maximum derivation depths to test. Impact: rule chain length."""


# ================================================================
# Complexity Scaling Helpers
# ================================================================

def select_rule_depth(assumption_count: int, rng) -> int:
    """Select rule depth based on assumption count for scaled complexity.

    Args:
        assumption_count: Number of assumptions in framework
        rng: random.Random instance for reproducibility

    Returns:
        Rule depth appropriate for the complexity level
    """
    if assumption_count <= 5:
        return rng.choice([1, 2])
    elif assumption_count <= 15:
        return rng.choice([1, 2, 2, 3])  # Weighted toward 2-3
    else:  # assumption_count >= 20
        return rng.choice([2, 3, 3, 4])  # Weighted toward 3-4


def select_rule_counts(assumption_count: int) -> List[int]:
    """Select rule counts based on assumption count for scaled complexity.

    Args:
        assumption_count: Number of assumptions in framework

    Returns:
        List of appropriate rule counts for this complexity level
    """
    if assumption_count <= 5:
        return [0, 2, 5]
    elif assumption_count <= 15:
        return [2, 5, 10, 20]
    else:  # assumption_count >= 20
        return [5, 10, 20, 30]


def select_budget_level(rng) -> str:
    """Select budget level with bias toward tighter budgets.

    Args:
        rng: random.Random instance for reproducibility

    Returns:
        Budget level: 'tight', 'medium', or 'loose'

    Distribution: 50% tight, 30% medium, 20% loose
    """
    return rng.choices(
        ['tight', 'medium', 'loose'],
        weights=[0.5, 0.3, 0.2],
        k=1
    )[0]


# ================================================================
# DIMENSION 3: Attack Connectivity (Topology Types)
# ================================================================

TOPOLOGY_TYPES = ['linear', 'tree', 'cycle', 'complete', 'mixed', 'isolated']
"""Available topology types for attack graph structure."""

BRANCHING_FACTORS = [2, 3]
"""Branching factors for tree topologies."""

CYCLE_LENGTHS = [3, 5, 'full']  # 'full' means cycle length = A
"""Cycle lengths for cyclic topologies."""

NUM_CLUSTERS = [2, 3, 5]
"""Number of clusters for mixed topologies."""

NUM_COMPONENTS = [2, 3, 5]
"""Number of disconnected components for isolated topologies."""

# Attack density categories
DENSITY_SPARSE = 0.20   # <20% of possible edges
DENSITY_MEDIUM = 0.50   # 20-50% of possible edges
DENSITY_DENSE = 0.80    # >50% of possible edges


# ================================================================
# DIMENSION 4: Weight Distribution
# ================================================================

@dataclass
class WeightScheme:
    """Configuration for weight distribution in a framework."""

    name: str
    """Scheme name (e.g., 'sparse_uniform', 'dense_varied')."""

    coverage: float
    """Fraction of atoms with explicit weights (0.0-1.0)."""

    range_min: int
    """Minimum weight value."""

    range_max: int
    """Maximum weight value."""

    distribution: str
    """Distribution type: 'uniform', 'bimodal', 'power_law', 'random'."""

    def __repr__(self):
        return self.name


# Predefined weight schemes

WEIGHT_SPARSE_UNIFORM = WeightScheme(
    name='sparse_uniform',
    coverage=0.15,  # 15% atoms have weights
    range_min=10,
    range_max=20,
    distribution='uniform'
)

WEIGHT_SPARSE_NARROW = WeightScheme(
    name='sparse_narrow',
    coverage=0.15,
    range_min=10,
    range_max=20,
    distribution='uniform'
)

WEIGHT_DENSE_UNIFORM = WeightScheme(
    name='dense_uniform',
    coverage=0.85,  # 85% atoms have weights
    range_min=10,
    range_max=90,
    distribution='uniform'
)

WEIGHT_DENSE_VARIED = WeightScheme(
    name='dense_varied',
    coverage=0.85,
    range_min=5,
    range_max=95,
    distribution='uniform'
)

WEIGHT_MEDIUM_UNIFORM = WeightScheme(
    name='medium_uniform',
    coverage=0.50,  # 50% atoms have weights
    range_min=10,
    range_max=50,
    distribution='uniform'
)

WEIGHT_BIMODAL = WeightScheme(
    name='bimodal',
    coverage=0.80,
    range_min=5,
    range_max=95,
    distribution='bimodal'  # Two clusters: [5,15] and [80,95]
)

WEIGHT_POWER_LAW = WeightScheme(
    name='power_law',
    coverage=0.70,
    range_min=1,
    range_max=100,
    distribution='power_law'  # Few high, many low
)

WEIGHT_RANDOM = WeightScheme(
    name='random',
    coverage=0.60,
    range_min=1,
    range_max=100,
    distribution='random'
)

# Collection of all weight schemes
WEIGHT_SCHEMES = [
    WEIGHT_SPARSE_UNIFORM,
    WEIGHT_SPARSE_NARROW,
    WEIGHT_DENSE_UNIFORM,
    WEIGHT_DENSE_VARIED,
    WEIGHT_MEDIUM_UNIFORM,
    WEIGHT_BIMODAL,
    WEIGHT_POWER_LAW,
    WEIGHT_RANDOM
]

# Map scheme names to objects
WEIGHT_SCHEME_MAP = {scheme.name: scheme for scheme in WEIGHT_SCHEMES}


# ================================================================
# Budget Calculation Strategy
# ================================================================

def compute_budget(total_weight_sum: int, max_weight: int, level: str = 'medium') -> int:
    """Compute budget based on framework weights.

    Args:
        total_weight_sum: Sum of all explicit weights in framework
        max_weight: Maximum single weight value
        level: 'tight', 'medium', or 'loose'

    Returns:
        Budget value appropriate for the framework

    Strategy:
        - tight: Can discard ~1 attack (max_weight)
        - medium: Can discard ~half attacks (total_sum // 2)
        - loose: Can discard all attacks (total_sum)
    """
    if level == 'tight':
        return max_weight if max_weight > 0 else 10
    elif level == 'loose':
        return total_weight_sum if total_weight_sum > 0 else 100
    else:  # medium
        return (total_weight_sum // 2) if total_weight_sum > 0 else 50


# ================================================================
# Framework Distribution Target
# ================================================================

# Target distribution across topologies (percentages sum to 100)
TOPOLOGY_DISTRIBUTION = {
    'linear': 1/6,       # 16.67% - Even distribution for academic rigor
    'tree': 1/6,         # 16.67% - Even distribution for academic rigor
    'cycle': 1/6,        # 16.67% - Even distribution for academic rigor
    'complete': 1/6,     # 16.67% - Even distribution for academic rigor
    'mixed': 1/6,        # 16.67% - Even distribution for academic rigor
    'isolated': 1/6      # 16.67% - Even distribution for academic rigor
}

# Target total framework count
TARGET_FRAMEWORK_COUNT = 120  # 20 per topology × 6 topologies for balanced academic evaluation


# ================================================================
# Parameter Combination Generation
# ================================================================

def get_linear_configs(rng) -> List[Dict]:
    """Generate parameter configurations for linear topology frameworks.

    Args:
        rng: random.Random instance for reproducibility
    """
    configs = []

    for A in ASSUMPTION_COUNTS:
        # Use scaled rule counts for this assumption level
        rule_counts = select_rule_counts(A)

        for R in rule_counts[:3]:  # Take first 3 rule counts
            # Select appropriate depth for this assumption count
            D = select_rule_depth(A, rng)

            for scheme in [WEIGHT_SPARSE_UNIFORM, WEIGHT_DENSE_VARIED]:
                # Skip redundant configurations
                if R == 0 and D > 1:
                    continue  # No rules means depth is irrelevant

                configs.append({
                    'topology': 'linear',
                    'A': A,
                    'R': R,
                    'D': D,
                    'weight_scheme': scheme,
                    'budget_level': select_budget_level(rng)
                })

    return configs


def get_tree_configs(rng) -> List[Dict]:
    """Generate parameter configurations for tree topology frameworks.

    Args:
        rng: random.Random instance for reproducibility
    """
    configs = []

    for A in [a for a in ASSUMPTION_COUNTS if a >= 10]:  # Trees need sufficient assumptions
        # Use scaled rule counts for this assumption level
        rule_counts = select_rule_counts(A)

        for R in rule_counts[1:3]:  # Take middle rule counts (not 0)
            for branch in BRANCHING_FACTORS:
                # Select appropriate depth for this assumption count
                D = select_rule_depth(A, rng)

                for scheme in [WEIGHT_SPARSE_NARROW, WEIGHT_DENSE_UNIFORM]:
                    configs.append({
                        'topology': 'tree',
                        'A': A,
                        'R': R,
                        'branching_factor': branch,
                        'D': D,
                        'weight_scheme': scheme,
                        'budget_level': select_budget_level(rng)
                    })

    return configs


def get_cycle_configs(rng) -> List[Dict]:
    """Generate parameter configurations for cycle topology frameworks.

    Args:
        rng: random.Random instance for reproducibility
    """
    configs = []

    for A in [a for a in ASSUMPTION_COUNTS if a >= 10]:  # Cycles need sufficient assumptions
        # Use scaled rule counts for this assumption level
        rule_counts = select_rule_counts(A)

        for cycle_len in [3, 5, 'full']:
            for R in rule_counts[:2]:  # Take first 2 rule counts
                for scheme in [WEIGHT_MEDIUM_UNIFORM, WEIGHT_BIMODAL]:
                    # Skip invalid cycle lengths
                    if isinstance(cycle_len, int) and cycle_len > A:
                        continue

                    configs.append({
                        'topology': 'cycle',
                        'A': A,
                        'R': R,
                        'cycle_length': cycle_len,
                        'weight_scheme': scheme,
                        'budget_level': select_budget_level(rng)
                    })

    return configs


def get_complete_configs(rng) -> List[Dict]:
    """Generate parameter configurations for complete graph frameworks.

    Expanded to generate ~20 frameworks for academic balance:
    - a≤15: 3 values × 3 schemes = 9 base configs
    - a=20: 2 schemes = 2 configs
    - With rules (R>0): 6 configs (varied)
    - Budget variations: 3 configs
    Total: 20 configurations

    Args:
        rng: random.Random instance for reproducibility
    """
    configs = []

    # Base configs: small assumption counts with 3 weight schemes
    # IMPORTANT: R≥1 required (requirement 1.1a - all frameworks must have derived atoms)
    # CRITICAL: R must be >= D to achieve the requested depth (need R atoms for depth D)
    for A in [a for a in ASSUMPTION_COUNTS if a <= 15]:  # a=2,10,15
        for scheme in [WEIGHT_DENSE_UNIFORM, WEIGHT_POWER_LAW, WEIGHT_RANDOM]:
            configs.append({
                'topology': 'complete',
                'A': A,
                'R': 2,  # R=2 to achieve D=2 (was 1)
                'D': 2,  # Default depth
                'weight_scheme': scheme,
                'budget_level': select_budget_level(rng)
            })

    # Add a=20 with limited schemes (computationally more expensive)
    for scheme in [WEIGHT_DENSE_UNIFORM, WEIGHT_RANDOM]:
        configs.append({
            'topology': 'complete',
            'A': 20,
            'R': 2,  # R=2 to achieve D=2 (was 1)
            'D': 2,  # Default depth
            'weight_scheme': scheme,
            'budget_level': select_budget_level(rng)
        })

    # Add variants with small number of rules for diversity
    # These add derived atoms on top of complete attack graph
    for A in [10, 15]:
        for R in [2, 5]:
            configs.append({
                'topology': 'complete',
                'A': A,
                'R': R,
                'D': 1,  # Shallow rules
                'weight_scheme': WEIGHT_RANDOM,
                'budget_level': select_budget_level(rng)
            })

    # Add tight budget variants for challenging cases (with R >= 2 for derived attacks)
    for A in [10, 15, 20]:
        configs.append({
            'topology': 'complete',
            'A': A,
            'R': 2,
            'D': 1,
            'weight_scheme': WEIGHT_POWER_LAW,
            'budget_level': 'tight'  # Force tight budget
        })

    # Add 2 more variants with a=2 for small-scale edge cases
    configs.append({
        'topology': 'complete',
        'A': 2,
        'R': 2,
        'D': 1,
        'weight_scheme': WEIGHT_DENSE_UNIFORM,
        'budget_level': 'loose'
    })
    configs.append({
        'topology': 'complete',
        'A': 2,
        'R': 5,
        'D': 2,
        'weight_scheme': WEIGHT_RANDOM,
        'budget_level': 'medium'
    })

    return configs


def get_mixed_configs(rng) -> List[Dict]:
    """Generate parameter configurations for mixed topology frameworks.

    Args:
        rng: random.Random instance for reproducibility
    """
    configs = []

    for A in [a for a in ASSUMPTION_COUNTS if a >= 10]:  # Mixed needs sufficient assumptions
        rule_counts = select_rule_counts(A)

        for R in rule_counts[1:3]:  # Take middle rule counts (not 0)
            for clusters in [2, 3]:
                D = select_rule_depth(A, rng)

                for scheme in [WEIGHT_DENSE_VARIED, WEIGHT_RANDOM]:
                    configs.append({
                        'topology': 'mixed',
                        'A': A,
                        'R': R,
                        'D': D,
                        'num_clusters': clusters,
                        'weight_scheme': scheme,
                        'budget_level': select_budget_level(rng)
                    })

    return configs


def get_isolated_configs(rng) -> List[Dict]:
    """Generate parameter configurations for isolated component frameworks.

    Args:
        rng: random.Random instance for reproducibility
    """
    configs = []

    for A in [a for a in ASSUMPTION_COUNTS if a >= 10]:  # Isolated needs sufficient assumptions
        rule_counts = select_rule_counts(A)

        for R in rule_counts[:2]:  # Take first 2 rule counts
            D = select_rule_depth(A, rng)

            for num_comp in [2, 3, 5]:
                for scheme in [WEIGHT_SPARSE_UNIFORM, WEIGHT_RANDOM]:
                    configs.append({
                        'topology': 'isolated',
                        'A': A,
                        'R': R,
                        'D': D,
                        'num_components': num_comp,
                        'weight_scheme': scheme,
                        'budget_level': select_budget_level(rng)
                    })

    return configs


def get_all_framework_configs(rng) -> List[Dict]:
    """Get all framework configurations across all topologies.

    Args:
        rng: random.Random instance for reproducibility

    Returns:
        List of configuration dicts, each specifying parameters for one framework
    """
    all_configs = []

    all_configs.extend(get_linear_configs(rng))
    all_configs.extend(get_tree_configs(rng))
    all_configs.extend(get_cycle_configs(rng))
    all_configs.extend(get_complete_configs(rng))
    all_configs.extend(get_mixed_configs(rng))
    all_configs.extend(get_isolated_configs(rng))

    return all_configs


def sample_configs_by_distribution(target_count: int, seed: int) -> List[Dict]:
    """Sample configurations to match target distribution.

    Args:
        target_count: Desired total number of frameworks
        seed: Master seed for deterministic sampling (default: 42)

    Returns:
        List of sampled configuration dicts matching distribution targets
    """
    # Create RNG for sampling
    sampling_seed = derive_seed(seed, "sample_configs")
    rng = create_rng(sampling_seed)

    # Get all configs by topology (each with their own RNG derived from seed)
    topology_configs = {
        'linear': get_linear_configs(create_rng(derive_seed(seed, "linear"))),
        'tree': get_tree_configs(create_rng(derive_seed(seed, "tree"))),
        'cycle': get_cycle_configs(create_rng(derive_seed(seed, "cycle"))),
        'complete': get_complete_configs(create_rng(derive_seed(seed, "complete"))),
        'mixed': get_mixed_configs(create_rng(derive_seed(seed, "mixed"))),
        'isolated': get_isolated_configs(create_rng(derive_seed(seed, "isolated")))
    }

    sampled = []

    for topology, fraction in TOPOLOGY_DISTRIBUTION.items():
        target_n = int(target_count * fraction)
        available = topology_configs[topology]

        # Always sample exactly target_n to ensure balanced distribution
        # If not enough configs available, use all; otherwise sample target_n
        actual_n = min(len(available), target_n)
        sampled.extend(rng.sample(available, actual_n) if len(available) > actual_n else available)

    print(f"Sampled {len(sampled)} framework configurations:")
    for topology in TOPOLOGY_TYPES:
        count = sum(1 for c in sampled if c['topology'] == topology)
        print(f"  {topology}: {count} frameworks")

    return sampled


# ================================================================
# Main (for testing)
# ================================================================

if __name__ == '__main__':
    print("WABA Benchmark Dimension Configuration")
    print("=" * 60)

    print("\nDimension 1: Assumption Counts")
    print(f"  Values: {ASSUMPTION_COUNTS}")

    print("\nDimension 2: Rule Counts & Depths")
    print(f"  Rule counts: {RULE_COUNTS}")
    print(f"  Max depths: {RULE_DEPTHS}")

    print("\nDimension 3: Topology Types")
    print(f"  Types: {TOPOLOGY_TYPES}")

    print("\nDimension 4: Weight Schemes")
    for scheme in WEIGHT_SCHEMES:
        print(f"  {scheme.name}: coverage={scheme.coverage}, "
              f"range=[{scheme.range_min}, {scheme.range_max}], "
              f"dist={scheme.distribution}")

    print("\n" + "=" * 60)
    print("Framework Configuration Sampling")
    print("=" * 60)

    configs = sample_configs_by_distribution()
    print(f"\nTotal configurations: {len(configs)}")
