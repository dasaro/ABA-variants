#!/usr/bin/env python3
"""
WABA Validation Benchmark Runner

Tests old enum mode vs new optimized monoid files with both opt-modes.
Runs comprehensive validation: 105 configurations × 120 frameworks = 12,600 runs.
"""

import json
import argparse
import gc
from pathlib import Path
from datetime import datetime
from concurrent.futures import ProcessPoolExecutor, as_completed
from typing import Dict, List, Optional

from config import (
    get_validation_configurations,
    build_clingo_command,
    discover_frameworks,
    FRAMEWORKS_DIR,
    BENCHMARK_ROOT
)
from executor_robust import execute_benchmark_run


# ================================================================
# Garbage Collection Configuration
# ================================================================

# Configure aggressive garbage collection to prevent memory buildup
gc.set_threshold(700, 10, 10)
gc.enable()


# ================================================================
# Run Metadata
# ================================================================

def create_run_id() -> str:
    """Generate unique run ID based on timestamp."""
    return datetime.now().strftime("%Y%m%d_%H%M%S")


def get_results_dir(run_id: str) -> Path:
    """Get results directory for validation run.

    Args:
        run_id: Run identifier

    Returns:
        Path to results directory
    """
    results_dir = BENCHMARK_ROOT / "results" / "validation" / run_id
    results_dir.mkdir(parents=True, exist_ok=True)
    return results_dir


# ================================================================
# Single Benchmark Execution
# ================================================================

def run_single_benchmark(framework_path: Path, config: Dict[str, str],
                         timeout: int, results_dir: Path) -> Dict:
    """Execute single benchmark run.

    Args:
        framework_path: Path to framework .lp file
        config: Configuration dict (semiring, monoid, semantics)
        timeout: Strict timeout in seconds (enforced via SIGKILL)
        results_dir: Directory to save result JSON

    Returns:
        Dict with benchmark results
    """
    framework_name = framework_path.stem
    config_name = config['name']

    try:
        # Build clingo command
        command = build_clingo_command(framework_path, config, clingo_timeout=timeout)

        # Execute with strict timeout enforcement
        result = execute_benchmark_run(command, timeout=timeout)

        # Add metadata
        result['framework'] = framework_name
        result['framework_path'] = str(framework_path)
        result['config'] = config_name
        result['semiring'] = config['semiring']
        result['monoid'] = config['monoid']
        result['semantics'] = config['semantics']
        result['timeout_limit'] = timeout

        # Add validation-specific metadata
        result['optimized'] = config.get('optimized', False)
        result['optimization_direction'] = config.get('optimization_direction', None)
        result['opt_mode'] = config.get('opt_mode', None)

        # Extract optimal cost if optimization was used
        if config.get('optimized', False) and result['status'] == 'SATISFIABLE':
            if result.get('statistics') and 'optimization_value' in result['statistics']:
                opt_value = result['statistics']['optimization_value']

                # For maximization, clingo outputs negative values (converts #maximize{X} to #minimize{-X})
                # We need to negate to get the true optimal cost
                if config.get('optimization_direction') == 'maximization':
                    if isinstance(opt_value, int):
                        result['optimal_cost'] = -opt_value
                    else:
                        # Special constants (#sup, #inf) - keep as-is
                        result['optimal_cost'] = opt_value
                else:
                    result['optimal_cost'] = opt_value
            else:
                result['optimal_cost'] = None
        else:
            result['optimal_cost'] = None

        # Save result to JSON
        result_filename = f"{framework_name}_{config_name}.json"
        result_path = results_dir / result_filename

        with open(result_path, 'w') as f:
            json.dump(result, f, indent=2)

        # Clear large data structures and force garbage collection
        result_copy = {
            'status': result['status'],
            'elapsed_seconds': result['elapsed_seconds'],
            'framework': result['framework'],
            'config': result['config']
        }
        del result
        gc.collect()

        return result_copy

    except Exception as e:
        # Handle crashed worker processes gracefully
        error_result = {
            'framework': framework_name,
            'framework_path': str(framework_path),
            'config': config_name,
            'semiring': config['semiring'],
            'monoid': config['monoid'],
            'semantics': config['semantics'],
            'timeout_limit': timeout,
            'optimized': config.get('optimized', False),
            'optimization_direction': config.get('optimization_direction', None),
            'opt_mode': config.get('opt_mode', None),
            'status': 'CRASHED',
            'error': str(e),
            'models': 0,
            'first_answer_set': None,
            'extension_cost_distribution': {},
            'assumption_frequency': {},
            'statistics': {},
            'timing': {},
            'elapsed_seconds': 0
        }

        # Save error result
        result_filename = f"{framework_name}_{config_name}.json"
        result_path = results_dir / result_filename

        with open(result_path, 'w') as f:
            json.dump(error_result, f, indent=2)

        gc.collect()
        return error_result


# ================================================================
# Parallel Benchmark Execution
# ================================================================

def run_all_benchmarks(frameworks: List[Path], configs: List[Dict[str, str]],
                       timeout: int = 120, workers: int = 1,
                       run_id: Optional[str] = None,
                       resume: bool = False,
                       verbose: bool = True) -> Dict:
    """Execute all benchmarks in parallel.

    Args:
        frameworks: List of framework file paths
        configs: List of configuration dicts
        timeout: Timeout per run in seconds
        workers: Number of parallel workers
        run_id: Run identifier (auto-generated if None)
        resume: Skip already-completed runs (default: False)
        verbose: Print progress messages

    Returns:
        Dict with summary statistics
    """
    if run_id is None:
        run_id = create_run_id()

    results_dir = get_results_dir(run_id)

    # Create task list with topology cycling
    topology_order = ['linear', 'cycle', 'tree', 'complete', 'mixed', 'isolated']
    frameworks_by_topology = {topo: [] for topo in topology_order}

    for framework in frameworks:
        topology = framework.parent.name
        if topology in frameworks_by_topology:
            frameworks_by_topology[topology].append(framework)

    # Sort frameworks within each topology
    for topology in topology_order:
        frameworks_by_topology[topology].sort()

    # Create tasks by cycling through topologies
    tasks = []
    max_frameworks_per_topology = max(len(fw_list) for fw_list in frameworks_by_topology.values())

    for i in range(max_frameworks_per_topology):
        for topology in topology_order:
            fw_list = frameworks_by_topology[topology]
            if i < len(fw_list):
                framework = fw_list[i]
                for config in configs:
                    tasks.append((framework, config, timeout, results_dir))

    # Resume: filter out already-completed tasks
    if resume:
        existing_results = {f.stem for f in results_dir.glob("*.json") if f.stem != "summary"}
        tasks_before = len(tasks)
        tasks = [
            (fw, cfg, to, rd) for fw, cfg, to, rd in tasks
            if f"{fw.stem}_{cfg['name']}" not in existing_results
        ]
        skipped = tasks_before - len(tasks)
        if verbose and skipped > 0:
            print(f"Resume mode: skipping {skipped} already-completed runs")

    total_runs = len(tasks)
    total_expected = len(frameworks) * len(configs)

    # Count configuration types
    enum_configs = [c for c in configs if not c.get('optimized', False)]
    opt_configs = [c for c in configs if c.get('optimized', False)]

    if verbose:
        print(f"WABA Validation Benchmark Suite")
        print("=" * 60)
        print(f"Run ID: {run_id}")
        print(f"Frameworks: {len(frameworks)}")
        print(f"Configurations: {len(configs)} total")
        print(f"  - Enum mode: {len(enum_configs)}")
        print(f"  - Optimized: {len(opt_configs)}")
        print(f"Total runs: {total_runs}" + (f" (of {total_expected})" if resume else ""))
        print(f"Timeout: {timeout}s per run")
        print(f"Workers: {workers}")
        print(f"Results: {results_dir}")
        print("=" * 60)

    # Execute in parallel
    completed = 0
    timeouts = 0
    errors = 0
    crashed = 0
    satisfiable = 0
    unsatisfiable = 0

    with ProcessPoolExecutor(max_workers=workers) as executor:
        # Submit all tasks
        futures = {
            executor.submit(run_single_benchmark, *task): task
            for task in tasks
        }

        # Process results as they complete
        for future in as_completed(futures):
            completed += 1
            task = futures[future]
            framework_path, config, _, _ = task

            try:
                result = future.result()

                # Update statistics
                if result['status'] == 'TIMEOUT':
                    timeouts += 1
                elif result['status'] == 'ERROR':
                    errors += 1
                elif result['status'] == 'CRASHED':
                    crashed += 1
                elif result['status'] == 'SATISFIABLE':
                    satisfiable += 1
                elif result['status'] == 'UNSATISFIABLE':
                    unsatisfiable += 1

                # Print progress
                if verbose:
                    status_symbol = {
                        'SATISFIABLE': '✓',
                        'UNSATISFIABLE': '∅',
                        'TIMEOUT': '⏱',
                        'ERROR': '✗',
                        'CRASHED': '💥'
                    }.get(result['status'], '?')

                    print(f"[{completed}/{total_runs}] {status_symbol} "
                          f"{framework_path.stem} × {config['name']} "
                          f"({result.get('elapsed_seconds', 0):.2f}s)")

                # Periodic garbage collection every 50 runs
                if completed % 50 == 0:
                    gc.collect()

            except Exception as e:
                errors += 1
                if verbose:
                    print(f"[{completed}/{total_runs}] ✗ "
                          f"{framework_path.stem} × {config['name']} "
                          f"(Exception: {e})")

    # Summary statistics
    summary = {
        'run_id': run_id,
        'benchmark_type': 'validation',
        'total_runs': total_runs,
        'completed': completed,
        'satisfiable': satisfiable,
        'unsatisfiable': unsatisfiable,
        'timeouts': timeouts,
        'crashed': crashed,
        'errors': errors,
        'timeout_limit': timeout,
        'workers': workers,
        'num_frameworks': len(frameworks),
        'num_configurations': len(configs),
        'num_enum_configs': len(enum_configs),
        'num_optimized_configs': len(opt_configs),
        'results_directory': str(results_dir)
    }

    # Save summary
    summary_path = results_dir / "summary.json"
    with open(summary_path, 'w') as f:
        json.dump(summary, f, indent=2)

    # Save metadata
    metadata = {
        'run_id': run_id,
        'start_time': run_id,  # Timestamp is encoded in run_id
        'timeout_seconds': timeout,
        'workers': workers,
        'total_frameworks': len(frameworks),
        'total_configurations': len(configs),
        'enum_configurations': len(enum_configs),
        'optimized_configurations': len(opt_configs),
        'total_expected_runs': total_expected
    }
    metadata_path = results_dir / "metadata.json"
    with open(metadata_path, 'w') as f:
        json.dump(metadata, f, indent=2)

    if verbose:
        print("=" * 60)
        print("Validation Benchmark Complete")
        print(f"Total runs: {completed}/{total_runs}")
        print(f"Satisfiable: {satisfiable} ({100*satisfiable/total_runs:.1f}%)")
        print(f"Unsatisfiable: {unsatisfiable} ({100*unsatisfiable/total_runs:.1f}%)")
        print(f"Timeouts: {timeouts} ({100*timeouts/total_runs:.1f}%)")
        print(f"Crashed: {crashed} ({100*crashed/total_runs:.1f}%)")
        print(f"Errors: {errors} ({100*errors/total_runs:.1f}%)")
        print(f"\nResults saved to: {results_dir}")
        print("=" * 60)

    return summary


# ================================================================
# CLI
# ================================================================

def main():
    parser = argparse.ArgumentParser(
        description="Run WABA validation benchmarks (old enum vs optimized modes)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Full validation benchmark (120s timeout, 1 worker)
  python run_validation_benchmark.py --timeout 120 --workers 1

  # Dry run with 5 frameworks
  python run_validation_benchmark.py --timeout 120 --workers 1 --limit 5

  # Resume interrupted run
  python run_validation_benchmark.py --timeout 120 --workers 1 --resume --run-id 20251226_140000
        """
    )

    parser.add_argument('--timeout', type=int, default=120,
                        help='Timeout per run in seconds (default: 120)')
    parser.add_argument('--workers', type=int, default=1,
                        help='Number of parallel workers (default: 1)')
    parser.add_argument('--limit', type=int, default=None,
                        help='Limit number of frameworks (for testing)')
    parser.add_argument('--run-id', type=str, default=None,
                        help='Custom run ID (default: timestamp)')
    parser.add_argument('--resume', action='store_true',
                        help='Resume from existing run (skips completed runs)')
    parser.add_argument('--quiet', action='store_true',
                        help='Suppress progress output')

    args = parser.parse_args()

    # Discover frameworks
    frameworks = discover_frameworks(FRAMEWORKS_DIR)

    if not frameworks:
        print(f"ERROR: No frameworks found in {FRAMEWORKS_DIR}")
        return 1

    if args.limit:
        frameworks = frameworks[:args.limit]
        print(f"Limited to first {args.limit} frameworks")

    # Get validation configurations (105 total)
    configs = get_validation_configurations()

    print(f"Total configurations: {len(configs)}")
    print(f"Expected total runs: {len(frameworks)} frameworks × {len(configs)} configs = {len(frameworks) * len(configs)}")

    # Run benchmarks
    summary = run_all_benchmarks(
        frameworks=frameworks,
        configs=configs,
        timeout=args.timeout,
        workers=args.workers,
        run_id=args.run_id,
        resume=args.resume,
        verbose=not args.quiet
    )

    return 0


if __name__ == '__main__':
    exit(main())
