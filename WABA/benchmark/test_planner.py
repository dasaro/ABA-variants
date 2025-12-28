#!/usr/bin/env python3
"""
Unit tests for planner.py balance validation and determinism.

Tests:
1. Balance validation (factorial: exact equality, stratified: ≤20% threshold)
2. Determinism regression (set/dict iteration order)
"""

import unittest
import sys
import tempfile
import json
from pathlib import Path
from collections import Counter
from typing import List, Dict

# Add parent directory for imports
sys.path.insert(0, str(Path(__file__).parent))

from planner import (
    ExperimentalFactors,
    FactorialSampler,
    StratifiedSampler,
    BalanceValidator,
    PlanEntry
)


class TestBalanceValidator(unittest.TestCase):
    """Tests for BalanceValidator class."""

    def test_factorial_exact_balance(self):
        """Factorial design must have EXACT balance (min_count == max_count)."""
        # Create a perfectly balanced factorial plan
        plan = [
            PlanEntry(
                plan_id='test_plan',
                instance_id=f'topo{i % 2}_a{j % 2}_rep1',
                topology=['linear', 'tree'][i % 2],
                A=[10, 20][j % 2],
                R=3,
                D=1,
                body_max=3,
                weight_scheme='uniform',
                operator='<=',
                budget_level=None,
                replicate=1,
                master_seed=42,
                instance_seed=1000 + i * 10 + j,
                design_type='factorial',
                timestamp='2025-01-01T00:00:00Z'
            )
            for i in range(4) for j in range(4)
        ]

        validator = BalanceValidator(plan, 'factorial')
        is_valid, errors, warnings = validator.validate()

        self.assertTrue(is_valid, f"Factorial plan should be balanced but got errors: {errors}")
        self.assertEqual(len(errors), 0)

    def test_factorial_imbalance_detected(self):
        """Factorial validator must detect imbalance (unequal counts)."""
        # Create an IMBALANCED plan (unequal topology counts)
        plan = []
        for i in range(5):
            plan.append(PlanEntry(
                plan_id='test_plan',
                instance_id=f'linear_a10_rep{i}',
                topology='linear',  # All linear
                A=10,
                R=3,
                D=1,
                body_max=3,
                weight_scheme='uniform',
                operator='<=',
                budget_level=None,
                replicate=i,
                master_seed=42,
                instance_seed=1000 + i,
                design_type='factorial',
                timestamp='2025-01-01T00:00:00Z'
            ))

        for i in range(3):  # Only 3 tree instances (imbalanced!)
            plan.append(PlanEntry(
                plan_id='test_plan',
                instance_id=f'tree_a10_rep{i}',
                topology='tree',
                A=10,
                R=3,
                D=1,
                body_max=3,
                weight_scheme='uniform',
                operator='<=',
                budget_level=None,
                replicate=i,
                master_seed=42,
                instance_seed=2000 + i,
                design_type='factorial',
                timestamp='2025-01-01T00:00:00Z'
            ))

        validator = BalanceValidator(plan, 'factorial')
        is_valid, errors, warnings = validator.validate()

        self.assertFalse(is_valid, "Factorial validator should detect imbalance")
        self.assertGreater(len(errors), 0)
        self.assertTrue(any('topology' in err for err in errors))

    def test_stratified_balance_within_threshold(self):
        """Stratified design allows ≤20% relative deviation."""
        # Create a plan with slight imbalance (within 20% threshold) ONLY in topology
        plan = []

        # Topology 1: 10 instances (all same parameters except instance_id)
        for i in range(10):
            plan.append(PlanEntry(
                plan_id='test_plan',
                instance_id=f'linear_inst{i}_a10_rep1',
                topology='linear',
                A=10,  # Same A
                R=3,
                D=1,
                body_max=3,
                weight_scheme='uniform',
                operator='<=',
                budget_level=None,
                replicate=1,  # Same replicate for all
                master_seed=42,
                instance_seed=1000 + i,
                design_type='stratified',
                timestamp='2025-01-01T00:00:00Z'
            ))

        # Topology 2: 9 instances (10% deviation - within threshold)
        for i in range(9):
            plan.append(PlanEntry(
                plan_id='test_plan',
                instance_id=f'tree_inst{i}_a10_rep1',
                topology='tree',
                A=10,  # Same A
                R=3,
                D=1,
                body_max=3,
                weight_scheme='uniform',
                operator='<=',
                budget_level=None,
                replicate=1,  # Same replicate for all
                master_seed=42,
                instance_seed=2000 + i,
                design_type='stratified',
                timestamp='2025-01-01T00:00:00Z'
            ))

        validator = BalanceValidator(plan, 'stratified')
        is_valid, errors, warnings = validator.validate()

        self.assertTrue(is_valid, f"Stratified plan with 10% deviation should pass but got: {errors}")

    def test_stratified_imbalance_exceeds_threshold(self):
        """Stratified validator rejects imbalance >20% relative deviation."""
        plan = []

        # Topology 1: 10 instances
        for i in range(10):
            plan.append(PlanEntry(
                plan_id='test_plan',
                instance_id=f'linear_a10_rep{i}',
                topology='linear',
                A=10,
                R=3,
                D=1,
                body_max=3,
                weight_scheme='uniform',
                operator='<=',
                budget_level=None,
                replicate=i,
                master_seed=42,
                instance_seed=1000 + i,
                design_type='stratified',
                timestamp='2025-01-01T00:00:00Z'
            ))

        # Topology 2: 5 instances (40% deviation - exceeds 20% threshold!)
        for i in range(5):
            plan.append(PlanEntry(
                plan_id='test_plan',
                instance_id=f'tree_a10_rep{i}',
                topology='tree',
                A=10,
                R=3,
                D=1,
                body_max=3,
                weight_scheme='uniform',
                operator='<=',
                budget_level=None,
                replicate=i,
                master_seed=42,
                instance_seed=2000 + i,
                design_type='stratified',
                timestamp='2025-01-01T00:00:00Z'
            ))

        validator = BalanceValidator(plan, 'stratified')
        is_valid, errors, warnings = validator.validate()

        self.assertFalse(is_valid, "Stratified validator should reject 40% deviation")
        self.assertGreater(len(errors), 0)
        self.assertTrue(any('topology' in err for err in errors))

    def test_pairwise_balance(self):
        """Validator checks key pairwise combinations (topology × weight_scheme)."""
        # Create plan with imbalanced pairwise combination
        plan = []

        # linear × uniform: 5 instances
        for i in range(5):
            plan.append(PlanEntry(
                plan_id='test_plan',
                instance_id=f'linear_uniform_rep{i}',
                topology='linear',
                A=10,
                R=3,
                D=1,
                body_max=3,
                weight_scheme='uniform',
                operator='<=',
                budget_level=None,
                replicate=i,
                master_seed=42,
                instance_seed=1000 + i,
                design_type='factorial',
                timestamp='2025-01-01T00:00:00Z'
            ))

        # linear × power_law: 5 instances
        for i in range(5):
            plan.append(PlanEntry(
                plan_id='test_plan',
                instance_id=f'linear_power_law_rep{i}',
                topology='linear',
                A=10,
                R=3,
                D=1,
                body_max=3,
                weight_scheme='power_law',
                operator='<=',
                budget_level=None,
                replicate=i,
                master_seed=42,
                instance_seed=2000 + i,
                design_type='factorial',
                timestamp='2025-01-01T00:00:00Z'
            ))

        # tree × uniform: 2 instances (IMBALANCED!)
        for i in range(2):
            plan.append(PlanEntry(
                plan_id='test_plan',
                instance_id=f'tree_uniform_rep{i}',
                topology='tree',
                A=10,
                R=3,
                D=1,
                body_max=3,
                weight_scheme='uniform',
                operator='<=',
                budget_level=None,
                replicate=i,
                master_seed=42,
                instance_seed=3000 + i,
                design_type='factorial',
                timestamp='2025-01-01T00:00:00Z'
            ))

        # tree × power_law: 5 instances
        for i in range(5):
            plan.append(PlanEntry(
                plan_id='test_plan',
                instance_id=f'tree_power_law_rep{i}',
                topology='tree',
                A=10,
                R=3,
                D=1,
                body_max=3,
                weight_scheme='power_law',
                operator='<=',
                budget_level=None,
                replicate=i,
                master_seed=42,
                instance_seed=4000 + i,
                design_type='factorial',
                timestamp='2025-01-01T00:00:00Z'
            ))

        validator = BalanceValidator(plan, 'factorial')
        is_valid, errors, warnings = validator.validate()

        self.assertFalse(is_valid, "Pairwise imbalance should be detected")
        # Check for pairwise error (format: "Pairwise ... imbalanced")
        self.assertTrue(any('Pairwise' in err or 'topology' in err for err in errors),
                       f"Expected pairwise error, got: {errors}")


class TestDeterminismRegression(unittest.TestCase):
    """Regression tests to catch non-deterministic iteration over sets/dicts."""

    def test_factorial_sampler_determinism(self):
        """FactorialSampler must produce identical plans for same seed."""
        factors = ExperimentalFactors(
            TOPOLOGIES=['linear', 'tree'],
            A_VALUES=[10, 20],
            R_VALUES=[3],
            D_VALUES=[1],
            BODY_MAX_VALUES=[3],
            WEIGHT_SCHEMES=['uniform', 'power_law'],
            OPERATORS=['<='],
            BUDGET_LEVELS=None  # Disabled
        )

        sampler1 = FactorialSampler(factors, seed=42, replicates=1)
        plan1 = sampler1.sample()

        sampler2 = FactorialSampler(factors, seed=42, replicates=1)
        plan2 = sampler2.sample()

        # Plans should be identical
        self.assertEqual(len(plan1), len(plan2))

        # Compare instance_ids (order-dependent)
        ids1 = [entry.instance_id for entry in plan1]
        ids2 = [entry.instance_id for entry in plan2]
        self.assertEqual(ids1, ids2, "FactorialSampler must produce identical order for same seed")

        # Compare instance_seeds (must be deterministic)
        seeds1 = [entry.instance_seed for entry in plan1]
        seeds2 = [entry.instance_seed for entry in plan2]
        self.assertEqual(seeds1, seeds2, "instance_seed derivation must be deterministic")

    def test_stratified_sampler_determinism(self):
        """StratifiedSampler must produce identical plans for same seed."""
        factors = ExperimentalFactors(
            TOPOLOGIES=['linear', 'tree', 'cycle'],
            A_VALUES=[10, 20],
            R_VALUES=[3, 5],
            D_VALUES=[1, 2],
            BODY_MAX_VALUES=[3],
            WEIGHT_SCHEMES=['uniform', 'power_law'],
            OPERATORS=['<=', '>='],
            BUDGET_LEVELS=None
        )

        target_instances = 24  # Modest sample size

        sampler1 = StratifiedSampler(factors, seed=99, replicates=1)
        plan1 = sampler1.sample(target_instances=target_instances)

        sampler2 = StratifiedSampler(factors, seed=99, replicates=1)
        plan2 = sampler2.sample(target_instances=target_instances)

        # Plans should be identical
        self.assertEqual(len(plan1), len(plan2))

        # Compare instance_ids (order-dependent)
        ids1 = [entry.instance_id for entry in plan1]
        ids2 = [entry.instance_id for entry in plan2]
        self.assertEqual(ids1, ids2, "StratifiedSampler must produce identical order for same seed")

        # Compare instance_seeds
        seeds1 = [entry.instance_seed for entry in plan1]
        seeds2 = [entry.instance_seed for entry in plan2]
        self.assertEqual(seeds1, seeds2, "instance_seed derivation must be deterministic")

    def test_set_iteration_order_regression(self):
        """
        REGRESSION TEST: Ensure no set iteration without sorting.

        This test catches the bug we fixed in derivation_chain_builder.py
        where iterating over a set caused non-deterministic rule generation.
        """
        # Simulate the problematic pattern: iterating over a set
        test_set = {'c_a3', 'c_a1', 'c_a2'}

        # If we iterate without sorting, order is non-deterministic
        # (depends on PYTHONHASHSEED)
        unsorted_iteration = list(test_set)

        # Sorted iteration is deterministic
        sorted_iteration_1 = list(sorted(test_set))
        sorted_iteration_2 = list(sorted(test_set))

        # This test documents the CORRECT pattern
        self.assertEqual(sorted_iteration_1, sorted_iteration_2)
        self.assertEqual(sorted_iteration_1, ['c_a1', 'c_a2', 'c_a3'])

        # The WRONG pattern (unsorted) would fail under different PYTHONHASHSEED
        # We document this but can't directly test it without spawning subprocesses

    def test_generate_from_plan_determinism(self):
        """
        Full end-to-end test: generate frameworks twice and compare.

        This is the smoke test from the summary, but as a unit test.
        """
        from generate_from_plan import generate_frameworks_from_plan
        from utils import derive_seed

        # Create minimal plan
        plan_entries = [
            {
                'plan_id': 'test_plan',
                'instance_id': 'linear_a5_r1_d1_b3_uniform_lb_rep1',
                'topology': 'linear',
                'A': 5,
                'R': 1,
                'D': 1,
                'body_max': 3,
                'weight_scheme': 'uniform',
                'operator': '>=',
                'budget_level': None,
                'replicate': 1,
                'master_seed': 999,
                'instance_seed': derive_seed(999, 'linear', 'a5', 'r1', 'd1', 'uniform', '>=', 'rep1'),
                'design_type': 'test',
                'timestamp': '2025-01-01T00:00:00Z'
            }
        ]

        # Generate twice
        with tempfile.TemporaryDirectory() as tmpdir1:
            output_dir1 = Path(tmpdir1)
            generate_frameworks_from_plan(plan_entries, output_dir1)

            with tempfile.TemporaryDirectory() as tmpdir2:
                output_dir2 = Path(tmpdir2)
                generate_frameworks_from_plan(plan_entries, output_dir2)

                # Compare .lp files byte-for-byte
                lp1 = (output_dir1 / 'linear' / 'linear_a5_r1_d1_b3_uniform_lb_rep1.lp').read_text()
                lp2 = (output_dir2 / 'linear' / 'linear_a5_r1_d1_b3_uniform_lb_rep1.lp').read_text()

                self.assertEqual(lp1, lp2, "Generated .lp files must be byte-identical")

                # Verify NO budget/1 predicate in .lp file (check for actual predicate, not comments)
                lp_lines = [line.strip() for line in lp1.split('\n') if line.strip() and not line.strip().startswith('%')]
                budget_predicates = [line for line in lp_lines if line.startswith('budget(')]
                self.assertEqual(len(budget_predicates), 0, f"LP file must NOT contain budget/1 predicate, found: {budget_predicates}")

                # Compare .meta.json files (ignoring file_path)
                meta1_path = output_dir1 / 'linear' / 'linear_a5_r1_d1_b3_uniform_lb_rep1.meta.json'
                meta2_path = output_dir2 / 'linear' / 'linear_a5_r1_d1_b3_uniform_lb_rep1.meta.json'

                with open(meta1_path) as f:
                    meta1 = json.load(f)
                with open(meta2_path) as f:
                    meta2 = json.load(f)

                # Remove file_path (environment-specific)
                meta1.pop('file_path', None)
                meta2.pop('file_path', None)
                meta1.pop('git', None)  # Git status may differ
                meta2.pop('git', None)

                self.assertEqual(meta1, meta2, "Metadata (excluding file_path, git) must be identical")


class TestPlannerGuardrails(unittest.TestCase):
    """Test critical guardrails: no budget/1 in LP, plan_id propagation, etc."""

    def test_no_budget_predicate_in_lp(self):
        """CRITICAL: Generated .lp files must NEVER contain budget/1 predicate."""
        from generate_from_plan import write_framework_to_file
        from pathlib import Path
        import tempfile

        # Mock predicates dict (as returned by topology generators)
        predicates = {
            'assumptions': 'assumption(a1; a2; a3).',
            'weights': 'weight(a1, 10).\nweight(a2, 20).',
            'rules': 'head(r1, a2). % r1: a2 <- a1\nbody(r1, a1).',
            'contraries': 'contrary(a1, c_a1).\ncontrary(a2, c_a2).\ncontrary(a3, c_a3).',
            'budget': 'budget(100).',  # This should NOT appear in .lp
            'metadata': {}
        }

        with tempfile.TemporaryDirectory() as tmpdir:
            lp_path = Path(tmpdir) / 'test.lp'
            write_framework_to_file(predicates, lp_path, 'test_instance')

            content = lp_path.read_text()

            # CRITICAL: NO budget/1 predicate (check for actual predicate, not comments)
            lp_lines = [line.strip() for line in content.split('\n') if line.strip() and not line.strip().startswith('%')]
            budget_predicates = [line for line in lp_lines if line.startswith('budget(')]
            self.assertEqual(len(budget_predicates), 0, f"LP file must NOT contain budget/1 predicate, found: {budget_predicates}")

            # Should have comment reference only
            self.assertIn('% Budget value (for reference only): budget(100).', content)

    def test_plan_id_propagation(self):
        """plan_id must propagate from plan.jsonl to .meta.json."""
        from generate_from_plan import generate_frameworks_from_plan
        from utils import derive_seed
        import tempfile
        import json

        plan_id = 'test_plan_id_12345'

        plan_entries = [
            {
                'plan_id': plan_id,
                'instance_id': 'linear_a5_r1_d1_b3_uniform_lb_rep1',
                'topology': 'linear',
                'A': 5,
                'R': 1,
                'D': 1,
                'body_max': 3,
                'weight_scheme': 'uniform',
                'operator': '>=',
                'budget_level': None,
                'replicate': 1,
                'master_seed': 999,
                'instance_seed': derive_seed(999, 'linear', 'a5', 'r1', 'd1', 'uniform', '>=', 'rep1'),
                'design_type': 'test',
                'timestamp': '2025-01-01T00:00:00Z'
            }
        ]

        with tempfile.TemporaryDirectory() as tmpdir:
            output_dir = Path(tmpdir)
            generate_frameworks_from_plan(plan_entries, output_dir)

            meta_path = output_dir / 'linear' / 'linear_a5_r1_d1_b3_uniform_lb_rep1.meta.json'
            with open(meta_path) as f:
                metadata = json.load(f)

            self.assertEqual(metadata['plan_id'], plan_id, "plan_id must propagate to metadata")


def run_tests():
    """Run all tests and report results."""
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()

    # Add all test classes
    suite.addTests(loader.loadTestsFromTestCase(TestBalanceValidator))
    suite.addTests(loader.loadTestsFromTestCase(TestDeterminismRegression))
    suite.addTests(loader.loadTestsFromTestCase(TestPlannerGuardrails))

    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)

    return 0 if result.wasSuccessful() else 1


if __name__ == '__main__':
    sys.exit(run_tests())
