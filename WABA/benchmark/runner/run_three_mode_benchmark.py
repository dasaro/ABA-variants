#!/usr/bin/env python3
"""
WABA Three-Mode Validation Benchmark Runner

Compares three distinct enumeration modes:
- old_enum: Baseline with explicit extension_cost/1 predicate
- new_enum: Optimized enumeration with --opt-mode=ignore (all models)
- new_opt: Optimal enumeration with --opt-mode=optN (optimal models only)

Total: 80 configurations × 120 frameworks = 9,600 runs
Expected time: ~13-14 hours with 1 worker at 120s timeout
"""

import json
import argparse
import gc
import sys
import multiprocessing
from pathlib import Path
from datetime import datetime
from concurrent.futures import ProcessPoolExecutor, as_completed
from typing import Dict, List, Optional

from config import (
    get_three_mode_configurations,
    build_clingo_command,
    discover_frameworks,
    FRAMEWORKS_DIR,
    BENCHMARK_ROOT
)
from executor import execute_benchmark_run


# ================================================================
# Garbage Collection Configuration
# ================================================================

gc.set_threshold(700, 10, 10)
gc.enable()


# ================================================================
# Run Metadata
# ================================================================

def create_run_id() -> str:
    """Generate unique run ID based on timestamp."""
    return datetime.now().strftime("%Y%m%d_%H%M%S")


def get_results_dir(run_id: str) -> Path:
    """Get results directory for three-mode validation run."""
    results_dir = BENCHMARK_ROOT / "results" / "three_mode" / run_id
    results_dir.mkdir(parents=True, exist_ok=True)
    return results_dir


# ================================================================
# Single Benchmark Execution
# ================================================================

def run_single_benchmark(framework_path: Path, config: Dict[str, str],
                         timeout: int, results_dir: Path) -> Dict:
    """Execute single benchmark run.

    Args:
        framework_path: Path to framework file
        config: Configuration dict
        timeout: Timeout in seconds
        results_dir: Directory to save results
    """
    framework_name = framework_path.stem
    config_name = config['name']

    try:
        # Build clingo command
        command = build_clingo_command(framework_path, config, clingo_timeout=timeout)

        # Execute with strict timeout
        # Grounding size is extracted from stats (rules count)
        result = execute_benchmark_run(command, timeout=timeout)

        # Add metadata
        result['framework'] = framework_name
        result['framework_path'] = str(framework_path)
        result['config'] = config_name
        result['semiring'] = config['semiring']
        result['monoid'] = config['monoid']
        result['semantics'] = config['semantics']
        result['timeout_limit'] = timeout
        result['mode'] = config.get('mode', 'unknown')
        result['optimization_direction'] = config.get('optimization_direction')

        # Save result JSON
        result_file = results_dir / f"{framework_name}_{config_name}.json"
        with open(result_file, 'w') as f:
            json.dump(result, f, indent=2)

        return result

    except Exception as e:
        error_result = {
            'framework': framework_name,
            'framework_path': str(framework_path),
            'config': config_name,
            'semiring': config['semiring'],
            'monoid': config['monoid'],
            'semantics': config['semantics'],
            'timeout_limit': timeout,
            'mode': config.get('mode', 'unknown'),
            'error': True,
            'error_message': str(e),
            'status': 'ERROR'
        }

        # Save error result
        result_file = results_dir / f"{framework_name}_{config_name}.json"
        with open(result_file, 'w') as f:
            json.dump(error_result, f, indent=2)

        return error_result


# ================================================================
# Benchmark Scheduling with Topology Cycling
# ================================================================

def schedule_benchmarks(frameworks: List[Path], configs: List[Dict],
                        timeout: int, results_dir: Path, workers: int = 1,
                        limit: Optional[int] = None, resume_run: bool = False) -> None:
    """Schedule benchmarks with topology cycling.

    Args:
        frameworks: List of framework paths
        configs: List of configurations
        timeout: Timeout per run in seconds
        results_dir: Results directory
        workers: Number of parallel workers
        limit: Limit number of frameworks (for testing)
        resume_run: Whether this is resuming a previous run
    """
    # Group frameworks by topology
    topologies = {}
    for fw in frameworks:
        topology = fw.parent.name
        if topology not in topologies:
            topologies[topology] = []
        topologies[topology].append(fw)

    # Limit frameworks if requested
    if limit:
        limited_topologies = {}
        for topo, fws in topologies.items():
            limited_topologies[topo] = fws[:limit]
        topologies = limited_topologies

    # Create task list cycling through topologies
    tasks = []
    topology_keys = sorted(topologies.keys())
    max_fw_per_topo = max(len(fws) for fws in topologies.values())

    for fw_idx in range(max_fw_per_topo):
        for topo in topology_keys:
            if fw_idx < len(topologies[topo]):
                fw = topologies[topo][fw_idx]
                for config in configs:
                    # Skip if already completed (for resume)
                    result_file = results_dir / f"{fw.stem}_{config['name']}.json"
                    if resume_run and result_file.exists():
                        continue
                    tasks.append((fw, config))

    total_tasks = len(tasks)

    if total_tasks == 0:
        print("No tasks to run (all completed or limit=0)")
        return

    print(f"\n{'='*80}")
    print(f"THREE-MODE VALIDATION BENCHMARK")
    print(f"{'='*80}")
    print(f"Total tasks: {total_tasks}")
    print(f"Workers: {workers}")
    print(f"Timeout: {timeout}s per run")
    print(f"Estimated time: {total_tasks * timeout / 3600 / workers:.1f} hours")
    if resume_run:
        print("RESUME MODE: Skipping completed runs")
    print(f"{'='*80}\n")

    # Execute tasks
    completed = 0
    timeouts = 0
    errors = 0
    unsatisfiable = 0
    grounding_timeouts = 0

    with ProcessPoolExecutor(max_workers=workers) as executor:
        # Submit all tasks
        # Grounding size is extracted from clingo stats (rules count), no subprocess needed
        future_to_task = {
            executor.submit(run_single_benchmark, fw, cfg, timeout, results_dir): (fw, cfg)
            for fw, cfg in tasks
        }

        # Process results as they complete
        for future in as_completed(future_to_task):
            fw, cfg = future_to_task[future]
            completed += 1

            try:
                result = future.result()

                # Count outcomes
                if result.get('grounding_timeout', False):
                    grounding_timeouts += 1
                    outcome = "⏱ GROUNDING TIMEOUT"
                elif result.get('status') == 'TIMEOUT':
                    timeouts += 1
                    outcome = "⏱ TIMEOUT"
                elif result.get('status') == 'ERROR':
                    errors += 1
                    outcome = "✗ ERROR"
                elif result.get('status') == 'UNSATISFIABLE':
                    unsatisfiable += 1
                    outcome = "∅ UNSAT"
                elif result.get('models', 0) > 0:
                    grounding_size = result.get('grounding_size', -1)
                    outcome = f"✓ {result['models']} models (ground: {grounding_size})"
                else:
                    outcome = "? UNKNOWN"

                print(f"[{completed}/{total_tasks}] {fw.stem:30} {cfg['name']:50} {outcome}")

            except Exception as e:
                errors += 1
                print(f"[{completed}/{total_tasks}] {fw.stem:30} {cfg['name']:50} ✗ EXCEPTION: {e}")

            # Periodic summary
            if completed % 100 == 0:
                print(f"\n--- Progress Summary ({completed}/{total_tasks}) ---")
                print(f"Timeouts: {timeouts}, Grounding Timeouts: {grounding_timeouts}, Errors: {errors}, Unsatisfiable: {unsatisfiable}")
                print()

    # Final summary
    print(f"\n{'='*80}")
    print(f"BENCHMARK COMPLETE")
    print(f"{'='*80}")
    print(f"Total runs: {completed}")
    print(f"Timeouts: {timeouts} ({timeouts/completed*100:.1f}%)")
    print(f"Grounding Timeouts: {grounding_timeouts} ({grounding_timeouts/completed*100:.1f}%)")
    print(f"Errors: {errors} ({errors/completed*100:.1f}%)")
    print(f"Unsatisfiable: {unsatisfiable} ({unsatisfiable/completed*100:.1f}%)")
    print(f"{'='*80}\n")


# ================================================================
# Main
# ================================================================

def main():
    # CRITICAL: Set multiprocessing start method for macOS compatibility
    # Must be inside main() to avoid issues when module is imported
    try:
        multiprocessing.set_start_method('fork')
    except RuntimeError:
        pass  # Already set

    parser = argparse.ArgumentParser(
        description='WABA Three-Mode Validation Benchmark Runner',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Run three-mode validation benchmark (1 worker, 120s timeout)
  python3 run_three_mode_benchmark.py --timeout 120 --workers 1

  # Test on 5 frameworks per topology
  python3 run_three_mode_benchmark.py --timeout 120 --workers 1 --limit 5

  # Resume interrupted run
  python3 run_three_mode_benchmark.py --timeout 120 --workers 1 --resume --run-id 20231201_120000
        """
    )

    parser.add_argument('--timeout', type=int, default=120,
                        help='Timeout per run in seconds (default: 120)')
    parser.add_argument('--workers', type=int, default=1,
                        help='Number of parallel workers (default: 1)')
    parser.add_argument('--limit', type=int, default=None,
                        help='Limit frameworks per topology (for testing)')
    parser.add_argument('--resume', action='store_true',
                        help='Resume interrupted run')
    parser.add_argument('--run-id', type=str, default=None,
                        help='Run ID for resume (default: create new)')

    args = parser.parse_args()

    # Get or create run ID
    if args.resume and args.run_id:
        run_id = args.run_id
        print(f"Resuming run: {run_id}")
    else:
        run_id = create_run_id()
        print(f"Starting new run: {run_id}")

    # Setup results directory
    results_dir = get_results_dir(run_id)
    print(f"Results directory: {results_dir}")

    # Discover frameworks and configurations
    frameworks = discover_frameworks()
    configs = get_three_mode_configurations()

    print(f"\nFrameworks discovered: {len(frameworks)}")
    print(f"Configurations: {len(configs)}")
    print(f"  - old_enum: {len([c for c in configs if c['mode'] == 'old-enum'])}")
    print(f"  - new_enum: {len([c for c in configs if c['mode'] == 'new-enum'])}")
    print(f"  - new_opt: {len([c for c in configs if c['mode'] == 'new-opt'])}")

    # Save run metadata
    metadata = {
        'run_id': run_id,
        'timestamp': datetime.now().isoformat(),
        'num_frameworks': len(frameworks),
        'num_configurations': len(configs),
        'timeout_seconds': args.timeout,
        'workers': args.workers,
        'limit': args.limit,
        'resumed': args.resume,
        'modes': {
            'old_enum': len([c for c in configs if c['mode'] == 'old-enum']),
            'new_enum': len([c for c in configs if c['mode'] == 'new-enum']),
            'new_opt': len([c for c in configs if c['mode'] == 'new-opt'])
        }
    }

    metadata_file = results_dir / 'metadata.json'
    with open(metadata_file, 'w') as f:
        json.dump(metadata, f, indent=2)

    # Run benchmarks
    schedule_benchmarks(
        frameworks=frameworks,
        configs=configs,
        timeout=args.timeout,
        results_dir=results_dir,
        workers=args.workers,
        limit=args.limit,
        resume_run=args.resume
    )

    print(f"\nResults saved to: {results_dir}")
    print(f"Metadata: {metadata_file}")


if __name__ == '__main__':
    main()
