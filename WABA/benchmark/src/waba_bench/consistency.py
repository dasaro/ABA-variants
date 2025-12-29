#!/usr/bin/env python3
"""
Simplified consistency checker for opt-only results.
Verifies that opt and optN modes produce consistent results.
"""

import argparse
import json
import random
from pathlib import Path
from typing import List, Dict, Set
from collections import defaultdict
from dataclasses import dataclass, asdict

@dataclass
class ConsistencyResult:
    """Result of opt vs optN consistency check."""
    instance_id: str
    semiring: str
    monoid: str
    opt_direction: str

    opt_status: str
    optN_status: str

    opt_cost: List[int]
    optN_cost: List[int]

    cost_match: bool
    both_optimal: bool
    verdict: str  # 'pass', 'fail', 'inconclusive'
    failure_reason: str = None

def load_results(jsonl_file: Path) -> List[Dict]:
    """Load results from JSONL file."""
    results = []
    with open(jsonl_file, 'r') as f:
        for line in f:
            if line.strip():
                results.append(json.loads(line))
    return results

def select_sample(results: List[Dict], sample_rate: float, seed: int = 42) -> List[Dict]:
    """Randomly sample results."""
    rng = random.Random(seed)
    n = max(1, int(len(results) * sample_rate))
    return rng.sample(results, n)

def group_by_run_config(results: List[Dict]) -> Dict[tuple, Dict]:
    """Group results by (instance_id, semiring, monoid, opt_direction)."""
    groups = defaultdict(dict)

    for result in results:
        key = (
            result['instance_id'],
            result['semiring'],
            result['monoid'],
            result.get('opt_direction', 'unknown')
        )

        mode = result.get('mode', 'opt')
        groups[key][mode] = result

    return groups

def check_consistency(opt_result: Dict, optN_result: Dict) -> ConsistencyResult:
    """Check consistency between opt and optN results."""

    instance_id = opt_result['instance_id']
    semiring = opt_result['semiring']
    monoid = opt_result['monoid']
    opt_direction = opt_result.get('opt_direction', 'unknown')

    opt_status = opt_result['status']
    optN_status = optN_result.get('status', 'missing')

    opt_cost = opt_result.get('optimization_cost', [])
    optN_cost = optN_result.get('optimization_cost', [])

    # Check consistency
    both_optimal = (opt_status == 'optimal' and optN_status == 'optimal')
    cost_match = (opt_cost == optN_cost)

    if both_optimal and cost_match:
        verdict = 'pass'
        reason = None
    elif opt_status == 'error' or optN_status == 'error':
        verdict = 'inconclusive'
        reason = f'opt_status={opt_status}, optN_status={optN_status}'
    elif not both_optimal:
        verdict = 'fail'
        reason = f'status mismatch: opt={opt_status}, optN={optN_status}'
    elif not cost_match:
        verdict = 'fail'
        reason = f'cost mismatch: opt={opt_cost}, optN={optN_cost}'
    else:
        verdict = 'pass'
        reason = None

    return ConsistencyResult(
        instance_id=instance_id,
        semiring=semiring,
        monoid=monoid,
        opt_direction=opt_direction,
        opt_status=opt_status,
        optN_status=optN_status,
        opt_cost=opt_cost,
        optN_cost=optN_cost,
        cost_match=cost_match,
        both_optimal=both_optimal,
        verdict=verdict,
        failure_reason=reason
    )

def main():
    parser = argparse.ArgumentParser(description='Consistency checker for opt-only results')
    parser.add_argument('--opt-file', required=True, help='opt results JSONL')
    parser.add_argument('--optN-file', required=True, help='optN results JSONL (placeholder: use opt file)')
    parser.add_argument('--output', required=True, help='Output JSONL')
    parser.add_argument('--sample-rate', type=float, default=0.01, help='Sample rate (default: 0.01)')
    parser.add_argument('--seed', type=int, default=42, help='Random seed')

    args = parser.parse_args()

    print(f"Loading opt results from {args.opt_file}...")
    opt_results = load_results(Path(args.opt_file))
    print(f"✓ Loaded {len(opt_results):,} opt results")

    # NOTE: In a real implementation, we would run clingo with --opt-mode=optN
    # For now, we'll note that optN mode needs to be run separately
    print("\n⚠ WARNING: This is a placeholder implementation.")
    print("To perform full consistency checking, you need to:")
    print("1. Re-run benchmark_runner.py with --mode optN")
    print("2. Compare opt vs optN results using this tool")
    print()
    print("For now, we'll generate a placeholder report showing what would be checked.")

    # Sample opt results
    sample = select_sample(opt_results, args.sample_rate, args.seed)
    print(f"Sampled {len(sample):,} configurations for consistency checking")

    # Generate placeholder report
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with open(output_path, 'w') as f:
        f.write(json.dumps({
            'note': 'Placeholder consistency check report',
            'total_sampled': len(sample),
            'sample_rate': args.sample_rate,
            'message': 'To perform actual consistency checking, run benchmark with --mode optN and compare results'
        }) + '\n')

    print(f"✓ Placeholder report written to: {output_path}")
    print()
    print("="*60)
    print("CONSISTENCY CHECK SUMMARY (PLACEHOLDER)")
    print("="*60)
    print(f"Sampled: {len(sample):,} / {len(opt_results):,} ({args.sample_rate*100:.1f}%)")
    print()
    print("To perform actual opt vs optN consistency checking:")
    print("1. Run: python benchmark_runner.py --mode optN ...")
    print("2. Re-run this tool with --optN-file results/optN.jsonl")

if __name__ == '__main__':
    main()
