#!/usr/bin/env python3
"""
WABA Benchmark Design Planner

Generates scientifically defensible experimental designs for WABA benchmarks.
Supports full factorial and stratified sampling with balance validation.

Usage:
    python planner.py --dry-run --design factorial --seed 42 --replicates 3
    python planner.py --dry-run --design stratified --seed 42 --max-instances 1000
    python planner.py --seed 42 --output-dir frameworks_v2  # Actually generate
"""

import argparse
import json
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass, asdict
from datetime import datetime
from itertools import product
from pathlib import Path
from typing import List, Dict, Any, Tuple, Optional

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))
from utils import derive_seed, create_rng, get_git_status


# =============================================================================
# EXPERIMENTAL FACTORS (following EXPERIMENTAL_DESIGN.md)
# =============================================================================

@dataclass
class ExperimentalFactors:
    """Definition of experimental factors and their levels."""

    # Topology types
    TOPOLOGIES: List[str] = None

    # Framework size parameters
    A_VALUES: List[int] = None  # Number of assumptions
    R_VALUES: List[int] = None  # Rules per assumption
    D_VALUES: List[int] = None  # Derivation depth
    BODY_MAX_VALUES: List[int] = None  # Max rule body size

    # Weight schemes (must be same across ALL topologies to avoid confounding)
    WEIGHT_SCHEMES: List[str] = None

    # Constraint operators
    OPERATORS: List[str] = None  # ['<=', '>=']

    # Budget levels (OPTIONAL - metadata only, never emitted to .lp files)
    # Default: None (disabled) unless --include-budget-level flag is set
    BUDGET_LEVELS: List[str] = None  # ['tight', 'loose'] or None

    def __post_init__(self):
        """Set defaults following EXPERIMENTAL_DESIGN.md v2.0."""
        if self.TOPOLOGIES is None:
            self.TOPOLOGIES = ['linear', 'tree', 'cycle', 'complete', 'mixed', 'isolated']

        if self.A_VALUES is None:
            self.A_VALUES = [6, 10, 15, 25]

        if self.R_VALUES is None:
            self.R_VALUES = [1, 3, 5, 7]

        if self.D_VALUES is None:
            self.D_VALUES = [1, 2, 3, 4]

        if self.BODY_MAX_VALUES is None:
            self.BODY_MAX_VALUES = [3]  # Fixed per EXPERIMENTAL_DESIGN.md

        if self.WEIGHT_SCHEMES is None:
            # Single weight scheme for simplified benchmark
            self.WEIGHT_SCHEMES = ['sparse']

        if self.OPERATORS is None:
            # Both operators for full benchmark
            self.OPERATORS = ['<=', '>=']

        # BUDGET_LEVELS remains None by default (must be explicitly enabled)

    def get_factor_levels(self) -> Dict[str, List]:
        """Return dict mapping factor name to list of levels."""
        levels = {
            'topology': self.TOPOLOGIES,
            'A': self.A_VALUES,
            'R': self.R_VALUES,
            'D': self.D_VALUES,
            'body_max': self.BODY_MAX_VALUES,
            'weight_scheme': self.WEIGHT_SCHEMES,
            'operator': self.OPERATORS,
        }

        # Only include budget_level if explicitly set
        if self.BUDGET_LEVELS is not None:
            levels['budget_level'] = self.BUDGET_LEVELS

        return levels

    def total_factorial_size(self, replicates: int = 1) -> int:
        """Calculate total size of full factorial design."""
        size = (
            len(self.TOPOLOGIES) *
            len(self.A_VALUES) *
            len(self.R_VALUES) *
            len(self.D_VALUES) *
            len(self.BODY_MAX_VALUES) *
            len(self.WEIGHT_SCHEMES) *
            len(self.OPERATORS) *
            replicates
        )

        # Multiply by budget levels if enabled
        if self.BUDGET_LEVELS is not None:
            size *= len(self.BUDGET_LEVELS)

        return size


# =============================================================================
# PLAN ENTRY (one row per framework instance)
# =============================================================================

@dataclass
class PlanEntry:
    """Single framework instance in the experimental plan."""

    plan_id: str              # Unique plan identifier (e.g., "plan_seed42_v1")
    instance_id: str          # Unique instance ID (e.g., "linear_a10_r3_d1_uniform_ub_rep1")
    topology: str
    A: int
    R: int
    D: int
    body_max: int
    weight_scheme: str
    operator: str             # '<=' or '>='
    budget_level: Optional[str]  # 'tight', 'loose', or None (METADATA ONLY - never in .lp)
    replicate: int            # Replicate index (1, 2, 3, ...)

    # Seeds for reproducibility
    master_seed: int
    instance_seed: int        # Derived from master_seed + instance params

    # Metadata
    design_type: str          # 'factorial' or 'stratified'
    timestamp: str

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON serialization."""
        return asdict(self)

    @staticmethod
    def create_instance_id(topology: str, A: int, R: int, D: int, body_max: int,
                          weight_scheme: str, operator: str, budget_level: Optional[str],
                          replicate: int) -> str:
        """Create unique instance ID from parameters."""
        op_abbrev = 'ub' if operator == '<=' else 'lb'

        # Budget is optional - omit from ID if not present
        if budget_level:
            return (f"{topology}_a{A}_r{R}_d{D}_b{body_max}_"
                    f"{weight_scheme}_{op_abbrev}_{budget_level}_rep{replicate}")
        else:
            return (f"{topology}_a{A}_r{R}_d{D}_b{body_max}_"
                    f"{weight_scheme}_{op_abbrev}_rep{replicate}")


# =============================================================================
# BALANCE VALIDATOR
# =============================================================================

class BalanceValidator:
    """Validates experimental design balance (no confounding)."""

    def __init__(self, plan: List[PlanEntry], design_type: str):
        """
        Initialize validator.

        Args:
            plan: List of plan entries
            design_type: 'factorial' or 'stratified'
        """
        self.plan = plan
        self.design_type = design_type
        self.errors = []
        self.warnings = []

    def validate(self) -> Tuple[bool, List[str], List[str]]:
        """
        Validate balance.

        Returns:
            (is_valid, errors, warnings) tuple
        """
        self.errors = []
        self.warnings = []

        # Check marginal balance (each factor level appears equally often)
        self._check_marginal_balance()

        # Check key pairwise balance (topology × weight_scheme, etc.)
        self._check_pairwise_balance()

        is_valid = len(self.errors) == 0
        return is_valid, self.errors, self.warnings

    def _check_marginal_balance(self):
        """Check that each factor level appears equally often."""
        factors = ['topology', 'A', 'R', 'D', 'body_max', 'weight_scheme',
                   'operator', 'replicate']

        # Include budget_level only if it's used in the plan
        if len(self.plan) > 0 and self.plan[0].budget_level is not None:
            factors.append('budget_level')

        for factor in factors:
            counts = Counter(getattr(entry, factor) for entry in self.plan)

            if len(counts) == 0:
                continue

            min_count = min(counts.values())
            max_count = max(counts.values())

            if self.design_type == 'factorial':
                # Factorial: must be exact equality
                if min_count != max_count:
                    self.errors.append(
                        f"Factor '{factor}' not balanced (factorial requires exact equality): "
                        f"min={min_count}, max={max_count}, counts={dict(counts)}"
                    )
            else:
                # Stratified: allow reasonable deviation (≤ 20% of mean)
                mean_count = sum(counts.values()) / len(counts)
                max_deviation = max_count - min_count
                relative_deviation = max_deviation / mean_count if mean_count > 0 else 0

                if relative_deviation > 0.20:  # More than 20% deviation
                    self.errors.append(
                        f"Factor '{factor}' imbalanced (deviation {relative_deviation:.1%} > 20%): "
                        f"min={min_count}, max={max_count}, mean={mean_count:.1f}, counts={dict(counts)}"
                    )
                elif relative_deviation > 0.10:  # 10-20% deviation
                    self.warnings.append(
                        f"Factor '{factor}' has moderate imbalance ({relative_deviation:.1%}): "
                        f"min={min_count}, max={max_count}, counts={dict(counts)}"
                    )

    def _check_pairwise_balance(self):
        """Check balance of key pairwise factor combinations."""
        # Key pairs to check (to prevent confounding)
        pairs = [
            ('topology', 'weight_scheme'),  # CRITICAL: no confounding
            ('topology', 'operator'),
            ('A', 'weight_scheme'),
            ('weight_scheme', 'operator'),
        ]

        for factor1, factor2 in pairs:
            contingency = defaultdict(lambda: defaultdict(int))

            for entry in self.plan:
                val1 = getattr(entry, factor1)
                val2 = getattr(entry, factor2)
                contingency[val1][val2] += 1

            # Check if all cells have same count
            all_counts = []
            for val1 in contingency:
                for val2 in contingency[val1]:
                    all_counts.append(contingency[val1][val2])

            if len(all_counts) == 0:
                continue

            min_count = min(all_counts)
            max_count = max(all_counts)

            if self.design_type == 'factorial':
                if min_count != max_count:
                    self.warnings.append(
                        f"Pairwise ({factor1} × {factor2}) not perfectly balanced: "
                        f"min={min_count}, max={max_count}"
                    )
            else:
                if max_count - min_count > 1:
                    self.warnings.append(
                        f"Pairwise ({factor1} × {factor2}) has imbalance > 1: "
                        f"min={min_count}, max={max_count}"
                    )

    def get_summary_report(self) -> str:
        """Generate human-readable balance summary."""
        lines = []
        lines.append("=" * 70)
        lines.append("BALANCE VALIDATION REPORT")
        lines.append("=" * 70)
        lines.append(f"Design type: {self.design_type}")
        lines.append(f"Total instances: {len(self.plan)}")
        lines.append("")

        # Marginal counts
        lines.append("MARGINAL COUNTS (per factor level):")
        lines.append("-" * 70)

        factors = ['topology', 'A', 'R', 'D', 'body_max', 'weight_scheme',
                   'operator', 'replicate']

        # Include budget_level only if it's used
        if len(self.plan) > 0 and self.plan[0].budget_level is not None:
            factors.insert(-1, 'budget_level')  # Insert before 'replicate'

        for factor in factors:
            counts = Counter(getattr(entry, factor) for entry in self.plan)
            lines.append(f"\n{factor}:")
            for level, count in sorted(counts.items()):
                lines.append(f"  {level}: {count}")

        # Pairwise contingency table (topology × weight_scheme)
        lines.append("\n")
        lines.append("KEY PAIRWISE CONTINGENCY TABLE (topology × weight_scheme):")
        lines.append("-" * 70)

        contingency = defaultdict(lambda: defaultdict(int))
        for entry in self.plan:
            contingency[entry.topology][entry.weight_scheme] += 1

        # Header
        weight_schemes = sorted(set(entry.weight_scheme for entry in self.plan))
        header = f"{'Topology':<15}" + "".join(f"{ws:<15}" for ws in weight_schemes)
        lines.append(header)

        # Rows
        topologies = sorted(set(entry.topology for entry in self.plan))
        for topo in topologies:
            row = f"{topo:<15}"
            for ws in weight_schemes:
                count = contingency[topo][ws]
                row += f"{count:<15}"
            lines.append(row)

        # Validation results
        lines.append("\n")
        lines.append("VALIDATION RESULTS:")
        lines.append("-" * 70)

        if len(self.errors) == 0 and len(self.warnings) == 0:
            lines.append("✓ PASS: Design is perfectly balanced")
        else:
            if self.errors:
                lines.append(f"✗ ERRORS ({len(self.errors)}):")
                for err in self.errors:
                    lines.append(f"  - {err}")

            if self.warnings:
                lines.append(f"\n⚠ WARNINGS ({len(self.warnings)}):")
                for warn in self.warnings:
                    lines.append(f"  - {warn}")

        lines.append("=" * 70)

        return "\n".join(lines)


# =============================================================================
# DESIGN SAMPLERS
# =============================================================================

class FactorialSampler:
    """Full factorial design sampler."""

    def __init__(self, factors: ExperimentalFactors, seed: int, replicates: int):
        self.factors = factors
        self.seed = seed
        self.replicates = replicates

    def sample(self, max_instances: Optional[int] = None,
               max_per_topology: Optional[int] = None) -> List[PlanEntry]:
        """
        Generate full factorial design.

        Args:
            max_instances: Hard cap on total instances (None = no cap)
            max_per_topology: Hard cap per topology (None = no cap)

        Returns:
            List of plan entries
        """
        plan = []
        plan_id = f"plan_seed{self.seed}_factorial"
        timestamp = datetime.utcnow().isoformat() + 'Z'

        # Generate all combinations
        factor_levels = self.factors.get_factor_levels()

        per_topology_count = defaultdict(int)

        # Build product() arguments based on enabled factors
        product_args = [
            factor_levels['topology'],
            factor_levels['A'],
            factor_levels['R'],
            factor_levels['D'],
            factor_levels['body_max'],
            factor_levels['weight_scheme'],
            factor_levels['operator'],
        ]

        # Include budget_level only if enabled
        budget_enabled = 'budget_level' in factor_levels
        if budget_enabled:
            product_args.append(factor_levels['budget_level'])

        # Replicates always included
        product_args.append(range(1, self.replicates + 1))

        for combo in product(*product_args):
            # Unpack based on whether budget is enabled
            if budget_enabled:
                topology, A, R, D, body_max, weight_scheme, operator, budget_level, replicate = combo
            else:
                topology, A, R, D, body_max, weight_scheme, operator, replicate = combo
                budget_level = None  # Not enabled

            # Check max_per_topology cap
            if max_per_topology and per_topology_count[topology] >= max_per_topology:
                continue

            # Create instance
            instance_id = PlanEntry.create_instance_id(
                topology, A, R, D, body_max, weight_scheme, operator, budget_level, replicate
            )

            # Derive instance-specific seed
            instance_seed = derive_seed(
                self.seed, topology, str(A), str(R), str(D), str(body_max),
                weight_scheme, operator, budget_level, str(replicate)
            )

            entry = PlanEntry(
                plan_id=plan_id,
                instance_id=instance_id,
                topology=topology,
                A=A,
                R=R,
                D=D,
                body_max=body_max,
                weight_scheme=weight_scheme,
                operator=operator,
                budget_level=budget_level,
                replicate=replicate,
                master_seed=self.seed,
                instance_seed=instance_seed,
                design_type='factorial',
                timestamp=timestamp
            )

            plan.append(entry)
            per_topology_count[topology] += 1

            # Check max_instances cap
            if max_instances and len(plan) >= max_instances:
                break

        return plan


class StratifiedSampler:
    """Stratified sampling with balanced marginals using greedy balancing."""

    def __init__(self, factors: ExperimentalFactors, seed: int, replicates: int):
        self.factors = factors
        self.seed = seed
        self.replicates = replicates
        self.rng = create_rng(seed)

    def sample(self, target_instances: int,
               max_per_topology: Optional[int] = None) -> List[PlanEntry]:
        """
        Generate stratified sample with balanced marginals using blocked sampling.

        Strategy: Divide the full factorial into blocks (one per topology), then
        sample systematically from each block to ensure all factor levels appear.

        Args:
            target_instances: Target number of instances
            max_per_topology: Hard cap per topology (None = no cap)

        Returns:
            List of plan entries
        """
        plan = []
        plan_id = f"plan_seed{self.seed}_stratified"
        timestamp = datetime.utcnow().isoformat() + 'Z'

        factor_levels = self.factors.get_factor_levels()

        # Calculate target per topology (balanced)
        num_topologies = len(factor_levels['topology'])
        target_per_topology = target_instances // num_topologies

        if max_per_topology:
            target_per_topology = min(target_per_topology, max_per_topology)

        # Check if budget is enabled
        budget_enabled = 'budget_level' in factor_levels

        # For each topology, generate a balanced sample
        for topology in sorted(factor_levels['topology']):  # Sort for determinism

            # Build product() arguments for this topology
            product_args = [
                [topology],  # Fixed topology for this block
                factor_levels['A'],
                factor_levels['R'],
                factor_levels['D'],
                factor_levels['body_max'],
                factor_levels['weight_scheme'],
                factor_levels['operator'],
            ]

            # Include budget_level only if enabled
            if budget_enabled:
                product_args.append(factor_levels['budget_level'])

            # Replicates always included
            product_args.append(range(1, self.replicates + 1))

            # Generate all combinations for this topology
            topo_combos = list(product(*product_args))

            total_topo_combos = len(topo_combos)

            # Calculate sampling indices for this topology block
            if target_per_topology >= total_topo_combos:
                # Take all
                selected_indices = list(range(total_topo_combos))
            else:
                sampling_interval = total_topo_combos / target_per_topology
                selected_indices = [int(i * sampling_interval) for i in range(target_per_topology)]

            # Add topology-specific seed offset for variation
            topo_offset = derive_seed(self.seed, topology) % total_topo_combos
            selected_indices = [(idx + topo_offset) % total_topo_combos for idx in selected_indices]

            # Select combinations
            for index in selected_indices:
                if index >= total_topo_combos:
                    continue

                combo = topo_combos[index]

                # Unpack based on whether budget is enabled
                if budget_enabled:
                    topology, A, R, D, body_max, weight_scheme, operator, budget_level, replicate = combo
                else:
                    topology, A, R, D, body_max, weight_scheme, operator, replicate = combo
                    budget_level = None  # Not enabled

                instance_id = PlanEntry.create_instance_id(
                    topology, A, R, D, body_max, weight_scheme, operator, budget_level, replicate
                )

                instance_seed = derive_seed(
                    self.seed, topology, str(A), str(R), str(D), str(body_max),
                    weight_scheme, operator, budget_level, str(replicate)
                )

                entry = PlanEntry(
                    plan_id=plan_id,
                    instance_id=instance_id,
                    topology=topology,
                    A=A,
                    R=R,
                    D=D,
                    body_max=body_max,
                    weight_scheme=weight_scheme,
                    operator=operator,
                    budget_level=budget_level,
                    replicate=replicate,
                    master_seed=self.seed,
                    instance_seed=instance_seed,
                    design_type='stratified',
                    timestamp=timestamp
                )

                plan.append(entry)

        return plan


# =============================================================================
# PLAN OUTPUT
# =============================================================================

def write_plan_jsonl(plan: List[PlanEntry], output_path: Path):
    """Write plan to JSONL file (one JSON object per line)."""
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with open(output_path, 'w') as f:
        for entry in plan:
            json.dump(entry.to_dict(), f, sort_keys=True)
            f.write('\n')


def write_plan_csv(plan: List[PlanEntry], output_path: Path):
    """Write plan to CSV file."""
    import csv

    output_path.parent.mkdir(parents=True, exist_ok=True)

    if len(plan) == 0:
        return

    fieldnames = list(plan[0].to_dict().keys())

    with open(output_path, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for entry in plan:
            writer.writerow(entry.to_dict())


# =============================================================================
# CLI
# =============================================================================

def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description='WABA Benchmark Design Planner',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    # Design parameters
    parser.add_argument(
        '--design',
        type=str,
        choices=['factorial', 'stratified'],
        default='factorial',
        help='Experimental design type'
    )
    parser.add_argument(
        '--seed',
        type=int,
        required=False,  # Not required in --generate-from-plan mode
        help='Master seed for reproducibility (required for planning, not for --generate-from-plan)'
    )
    parser.add_argument(
        '--replicates',
        type=int,
        default=3,
        help='Number of replicates per configuration'
    )
    parser.add_argument(
        '--include-budget-level',
        action='store_true',
        help='Include budget_level as experimental factor (default: disabled, metadata-only)'
    )

    # Termination controls
    parser.add_argument(
        '--max-instances',
        type=int,
        default=None,
        help='Hard cap on total instances'
    )
    parser.add_argument(
        '--max-per-topology',
        type=int,
        default=None,
        help='Hard cap per topology'
    )
    parser.add_argument(
        '--time-budget-hours',
        type=float,
        default=None,
        help='Time budget in hours (triggers downsampling)'
    )

    # Output control
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Plan only (do not generate frameworks)'
    )
    parser.add_argument(
        '--generate-from-plan',
        type=Path,
        default=None,
        help='Generate frameworks from existing plan.jsonl file'
    )
    parser.add_argument(
        '--output-dir',
        type=Path,
        default=Path('frameworks_v2'),
        help='Output directory for generated frameworks'
    )
    parser.add_argument(
        '--plan-output',
        type=Path,
        default=Path('plan.jsonl'),
        help='Path to write plan file (JSONL format)'
    )

    # Balance validation
    parser.add_argument(
        '--no-validate',
        action='store_true',
        help='Skip balance validation'
    )

    args = parser.parse_args()

    # Handle generate-from-plan mode (bypass planning)
    if args.generate_from_plan:
        print("=" * 70)
        print("WABA FRAMEWORK GENERATION FROM PLAN")
        print("=" * 70)
        print(f"Loading plan from {args.generate_from_plan}...")

        # Load plan entries
        plan = []
        with open(args.generate_from_plan, 'r') as f:
            for line in f:
                entry_dict = json.loads(line)  # loads (not load) for string
                # Note: We'll reconstruct PlanEntry from dict in generate_from_plan.py
                plan.append(entry_dict)

        print(f"✓ Loaded {len(plan)} entries")
        print()

        # Generate frameworks
        from generate_from_plan import generate_frameworks_from_plan

        try:
            generate_frameworks_from_plan(plan, args.output_dir)
            print()
            print(f"✓ Successfully generated {len(plan)} frameworks in {args.output_dir}")
            return 0
        except Exception as e:
            print(f"\n✗ ERROR during generation: {e}")
            import traceback
            traceback.print_exc()
            return 2

    # Validate arguments for planning mode
    if not args.seed:
        print("ERROR: --seed is required for planning mode")
        return 1

    # Initialize factors
    factors = ExperimentalFactors()

    # Enable budget_level factor if requested
    if args.include_budget_level:
        factors.BUDGET_LEVELS = ['tight', 'loose']

    print("=" * 70)
    print("WABA BENCHMARK DESIGN PLANNER")
    print("=" * 70)
    print(f"Design type: {args.design}")
    print(f"Master seed: {args.seed}")
    print(f"Replicates: {args.replicates}")
    print(f"Budget levels: {'enabled' if args.include_budget_level else 'disabled (metadata-only)'}")
    print(f"Max instances: {args.max_instances or 'unlimited'}")
    print(f"Max per topology: {args.max_per_topology or 'unlimited'}")
    print()

    # Calculate total factorial size
    total_factorial = factors.total_factorial_size(args.replicates)
    print(f"Full factorial size: {total_factorial:,} instances")
    print()

    # Generate plan
    print("Generating experimental plan...")

    if args.design == 'factorial':
        sampler = FactorialSampler(factors, args.seed, args.replicates)
        plan = sampler.sample(
            max_instances=args.max_instances,
            max_per_topology=args.max_per_topology
        )
    else:  # stratified
        if not args.max_instances:
            print("ERROR: --max-instances required for stratified design")
            return 1

        sampler = StratifiedSampler(factors, args.seed, args.replicates)
        plan = sampler.sample(
            target_instances=args.max_instances,
            max_per_topology=args.max_per_topology
        )

    print(f"✓ Generated plan with {len(plan):,} instances")
    print()

    # Validate balance
    if not args.no_validate:
        print("Validating balance...")
        validator = BalanceValidator(plan, args.design)
        is_valid, errors, warnings = validator.validate()

        print(validator.get_summary_report())
        print()

        if not is_valid:
            print("✗ FAIL: Design is not balanced")
            return 1

    # Write plan file
    if args.dry_run or not args.dry_run:
        print(f"Writing plan to {args.plan_output}...")
        write_plan_jsonl(plan, args.plan_output)

        # Also write CSV for easy inspection
        csv_path = args.plan_output.with_suffix('.csv')
        write_plan_csv(plan, csv_path)

        print(f"✓ Plan written to {args.plan_output}")
        print(f"✓ CSV written to {csv_path}")
        print()

    # If dry-run, stop here
    if args.dry_run:
        print("✓ DRY RUN COMPLETE (no frameworks generated)")
        print()
        print("To actually generate frameworks from this plan, run:")
        print(f"  python planner.py --generate-from-plan {args.plan_output} "
              f"--output-dir {args.output_dir}")
        return 0

    # Actually generate frameworks
    print("=" * 70)
    print("FRAMEWORK GENERATION FROM PLAN")
    print("=" * 70)
    print(f"Generating {len(plan)} frameworks from plan...")
    print()

    # Generate frameworks
    from generate_from_plan import generate_frameworks_from_plan

    try:
        generate_frameworks_from_plan(plan, args.output_dir)
        print()
        print(f"✓ Successfully generated {len(plan)} frameworks in {args.output_dir}")
        return 0
    except Exception as e:
        print(f"\n✗ ERROR during generation: {e}")
        import traceback
        traceback.print_exc()
        return 2


if __name__ == '__main__':
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\n\nInterrupted by user")
        sys.exit(130)
    except Exception as e:
        print(f"\n✗ ERROR: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(2)
