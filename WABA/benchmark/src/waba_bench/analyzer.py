#!/usr/bin/env python3
"""
WABA Benchmark Analysis v4.0

Analyzes results.jsonl and generates:
- summary.csv (grouped statistics)
- plots (runtime, timeout heatmaps, grounding scatter)
- BENCHMARK_REPORT.md (paper-ready tables)

Handles both enum and opt mode results:
- enum mode: reports model counts, SAT rates
- opt mode: reports optimum values, optimization status
"""

import argparse
import json
import sys
from collections import defaultdict
from pathlib import Path
from typing import List, Dict
import csv

# Optional: matplotlib for plots (graceful degradation if not available)
try:
    import matplotlib
    matplotlib.use('Agg')  # Non-interactive backend
    import matplotlib.pyplot as plt
    import numpy as np
    PLOTTING_AVAILABLE = True
except ImportError:
    PLOTTING_AVAILABLE = False
    print("Warning: matplotlib not available, plots will be skipped", file=sys.stderr)


def load_results(results_file: Path) -> List[Dict]:
    """Load all results from results.jsonl."""
    results = []
    with open(results_file, 'r') as f:
        for line in f:
            if line.strip():
                try:
                    results.append(json.loads(line))
                except json.JSONDecodeError as e:
                    print(f"Warning: Skipping malformed line: {e}", file=sys.stderr)
    return results


def compute_summary_stats(results: List[Dict]) -> List[Dict]:
    """Compute grouped statistics for summary.csv."""
    # Group by (semiring, monoid, semantics, mode, opt_direction, topology, A, R, D)
    groups = defaultdict(list)

    for result in results:
        # Extract topology, A, R, D from instance_id
        # Format: topology_aX_rY_dZ_bW_scheme_op_repN
        parts = result['instance_id'].split('_')
        topology = parts[0]
        A = int(parts[1][1:]) if len(parts) > 1 and parts[1].startswith('a') else None
        R = int(parts[2][1:]) if len(parts) > 2 and parts[2].startswith('r') else None
        D = int(parts[3][1:]) if len(parts) > 3 and parts[3].startswith('d') else None

        key = (
            result['semiring'],
            result['monoid'],
            result['semantics'],
            result.get('mode', 'unknown'),
            result.get('opt_direction', None),
            topology,
            A,
            R,
            D
        )

        groups[key].append(result)

    # Compute stats for each group
    summary_rows = []

    for key, group_results in groups.items():
        semiring, monoid, semantics, mode, opt_direction, topology, A, R, D = key

        total = len(group_results)
        timeouts = sum(1 for r in group_results if r['status'] == 'timeout')
        errors = sum(1 for r in group_results if r['status'] == 'error')
        optimal = sum(1 for r in group_results if r['status'] == 'optimal')
        sat = sum(1 for r in group_results if r['status'] == 'sat')
        unsat = sum(1 for r in group_results if r['status'] == 'unsat')

        # Timing stats (exclude timeouts/errors)
        wall_times = [r['wall_time_ms'] for r in group_results
                     if r['wall_time_ms'] is not None and r['status'] not in ['timeout', 'error']]

        if wall_times:
            median_time = sorted(wall_times)[len(wall_times) // 2]
            p95_time = sorted(wall_times)[int(len(wall_times) * 0.95)] if len(wall_times) > 1 else wall_times[0]
            mean_time = sum(wall_times) / len(wall_times)
        else:
            median_time = None
            p95_time = None
            mean_time = None

        # Grounding stats
        atoms_list = [r['atoms'] for r in group_results if r['atoms'] is not None]
        rules_list = [r['rules'] for r in group_results if r['rules'] is not None]

        median_atoms = sorted(atoms_list)[len(atoms_list) // 2] if atoms_list else None
        median_rules = sorted(rules_list)[len(rules_list) // 2] if rules_list else None

        # Mode-specific stats
        if mode == 'enum':
            # For enum mode, compute model count statistics
            model_counts = [r['models_found'] for r in group_results if r['models_found'] is not None]
            median_models = sorted(model_counts)[len(model_counts) // 2] if model_counts else None
            mean_models = sum(model_counts) / len(model_counts) if model_counts else None
        else:
            median_models = None
            mean_models = None

        summary_rows.append({
            'semiring': semiring,
            'monoid': monoid,
            'semantics': semantics,
            'mode': mode,
            'opt_direction': opt_direction if opt_direction else 'N/A',
            'topology': topology,
            'A': A,
            'R': R,
            'D': D,
            'total_runs': total,
            'optimal': optimal,
            'sat': sat,
            'unsat': unsat,
            'timeouts': timeouts,
            'errors': errors,
            'timeout_rate': f'{timeouts/total*100:.1f}%' if total > 0 else '0%',
            'median_time_ms': f'{median_time:.1f}' if median_time else 'N/A',
            'p95_time_ms': f'{p95_time:.1f}' if p95_time else 'N/A',
            'mean_time_ms': f'{mean_time:.1f}' if mean_time else 'N/A',
            'median_atoms': median_atoms if median_atoms else 'N/A',
            'median_rules': median_rules if median_rules else 'N/A',
            'median_models': median_models if median_models is not None else 'N/A',
            'mean_models': f'{mean_models:.1f}' if mean_models is not None else 'N/A'
        })

    return sorted(summary_rows, key=lambda x: (x['semiring'], x['monoid'], x['mode'], x['topology'], x['A']))


def write_summary_csv(summary_stats: List[Dict], output_file: Path):
    """Write summary statistics to CSV."""
    if not summary_stats:
        print("Warning: No summary stats to write", file=sys.stderr)
        return

    with open(output_file, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=summary_stats[0].keys())
        writer.writeheader()
        writer.writerows(summary_stats)

    print(f"✓ Summary written to: {output_file}")


def generate_plots(results: List[Dict], output_dir: Path):
    """Generate analysis plots."""
    if not PLOTTING_AVAILABLE:
        print("⚠ Matplotlib not available, skipping plots")
        return

    output_dir.mkdir(parents=True, exist_ok=True)

    # Plot 1: Timeout rate by semiring
    timeout_by_semiring = defaultdict(lambda: {'total': 0, 'timeouts': 0})
    for result in results:
        key = result['semiring']
        timeout_by_semiring[key]['total'] += 1
        if result['status'] == 'timeout':
            timeout_by_semiring[key]['timeouts'] += 1

    semirings = sorted(timeout_by_semiring.keys())
    timeout_rates = [timeout_by_semiring[s]['timeouts'] / timeout_by_semiring[s]['total'] * 100
                    for s in semirings]

    plt.figure(figsize=(10, 6))
    plt.bar(semirings, timeout_rates, color='coral')
    plt.xlabel('Semiring')
    plt.ylabel('Timeout Rate (%)')
    plt.title('Timeout Rate by Semiring')
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.savefig(output_dir / '1_timeout_by_semiring.png', dpi=150)
    plt.close()
    print(f"✓ Plot saved: {output_dir / '1_timeout_by_semiring.png'}")

    # Plot 2: Runtime distribution (violin plot or histogram)
    wall_times = [r['wall_time_ms'] for r in results
                 if r['wall_time_ms'] is not None and r['status'] not in ['timeout', 'error']]

    if wall_times:
        plt.figure(figsize=(10, 6))
        plt.hist(wall_times, bins=50, color='skyblue', edgecolor='black')
        plt.xlabel('Wall Time (ms)')
        plt.ylabel('Frequency')
        plt.title('Runtime Distribution (Successful Runs)')
        plt.axvline(np.median(wall_times), color='red', linestyle='--', label=f'Median: {np.median(wall_times):.1f}ms')
        plt.axvline(np.percentile(wall_times, 95), color='orange', linestyle='--', label=f'95th: {np.percentile(wall_times, 95):.1f}ms')
        plt.legend()
        plt.tight_layout()
        plt.savefig(output_dir / '2_runtime_distribution.png', dpi=150)
        plt.close()
        print(f"✓ Plot saved: {output_dir / '2_runtime_distribution.png'}")

    # Plot 3: Status distribution (pie chart)
    status_counts = defaultdict(int)
    for result in results:
        status_counts[result['status']] += 1

    plt.figure(figsize=(8, 8))
    plt.pie(status_counts.values(), labels=status_counts.keys(), autopct='%1.1f%%', startangle=90)
    plt.title('Overall Status Distribution')
    plt.tight_layout()
    plt.savefig(output_dir / '3_status_distribution.png', dpi=150)
    plt.close()
    print(f"✓ Plot saved: {output_dir / '3_status_distribution.png'}")

    # Plot 4: Grounding vs Solving time scatter (if available)
    grounding_times = []
    solving_times = []
    for result in results:
        if (result['grounding_time_ms'] is not None and
            result['solving_time_ms'] is not None and
            result['status'] not in ['timeout', 'error']):
            grounding_times.append(result['grounding_time_ms'])
            solving_times.append(result['solving_time_ms'])

    if grounding_times and solving_times:
        plt.figure(figsize=(10, 6))
        plt.scatter(grounding_times, solving_times, alpha=0.5, s=20)
        plt.xlabel('Grounding Time (ms)')
        plt.ylabel('Solving Time (ms)')
        plt.title('Grounding vs Solving Time')
        plt.xscale('log')
        plt.yscale('log')
        plt.grid(True, alpha=0.3)
        plt.tight_layout()
        plt.savefig(output_dir / '4_grounding_vs_solving.png', dpi=150)
        plt.close()
        print(f"✓ Plot saved: {output_dir / '4_grounding_vs_solving.png'}")


def generate_markdown_report(summary_stats: List[Dict], results: List[Dict], output_file: Path):
    """Generate BENCHMARK_REPORT.md with paper-ready tables."""

    with open(output_file, 'w') as f:
        f.write("# WABA Benchmark Report\n\n")
        f.write(f"**Total runs:** {len(results)}\n\n")

        # Detect mode(s) in results
        modes_present = set(r.get('mode', 'unknown') for r in results)
        if len(modes_present) == 1:
            mode = list(modes_present)[0]
            f.write(f"**Mode:** {mode}\n")
            if mode == 'opt':
                opt_directions = set(r.get('opt_direction') for r in results if r.get('opt_direction'))
                if opt_directions:
                    f.write(f"**Optimization direction:** {', '.join(opt_directions)}\n")
            f.write("\n")
        else:
            f.write(f"**Modes:** {', '.join(sorted(modes_present))}\n\n")

        # Overall statistics
        total = len(results)
        timeouts = sum(1 for r in results if r['status'] == 'timeout')
        errors = sum(1 for r in results if r['status'] == 'error')
        optimal = sum(1 for r in results if r['status'] == 'optimal')
        sat = sum(1 for r in results if r['status'] == 'sat')
        unsat = sum(1 for r in results if r['status'] == 'unsat')

        f.write("## Overall Statistics\n\n")
        f.write("| Metric | Count | Percentage |\n")
        f.write("|--------|-------|------------|\n")
        f.write(f"| Total Runs | {total} | 100.0% |\n")
        f.write(f"| Optimal | {optimal} | {optimal/total*100:.1f}% |\n")
        f.write(f"| SAT | {sat} | {sat/total*100:.1f}% |\n")
        f.write(f"| UNSAT | {unsat} | {unsat/total*100:.1f}% |\n")
        f.write(f"| Timeouts | {timeouts} | {timeouts/total*100:.1f}% |\n")
        f.write(f"| Errors | {errors} | {errors/total*100:.1f}% |\n\n")

        # Runtime statistics
        wall_times = [r['wall_time_ms'] for r in results
                     if r['wall_time_ms'] is not None and r['status'] not in ['timeout', 'error']]

        if wall_times:
            import numpy as np
            f.write("## Runtime Statistics (Successful Runs)\n\n")
            f.write("| Statistic | Time (ms) |\n")
            f.write("|-----------|----------|\n")
            f.write(f"| Mean | {np.mean(wall_times):.1f} |\n")
            f.write(f"| Median | {np.median(wall_times):.1f} |\n")
            f.write(f"| 95th Percentile | {np.percentile(wall_times, 95):.1f} |\n")
            f.write(f"| Min | {min(wall_times):.1f} |\n")
            f.write(f"| Max | {max(wall_times):.1f} |\n\n")

        # Summary by configuration (first 20 rows)
        # Detect if we're analyzing enum or opt mode
        has_enum = any(r.get('mode') == 'enum' for r in results)
        has_opt = any(r.get('mode') == 'opt' for r in results)

        f.write("## Performance by Configuration (Top 20)\n\n")

        if has_enum and not has_opt:
            # Enum-specific table with model counts
            f.write("| Semiring | Monoid | Topology | A | R | D | Runs | Timeout Rate | Median Time (ms) | Median Models |\n")
            f.write("|----------|--------|----------|---|---|---|------|--------------|------------------|---------------|\n")

            for row in summary_stats[:20]:
                f.write(f"| {row['semiring']} | {row['monoid']} | {row['topology']} | "
                       f"{row['A']} | {row['R']} | {row['D']} | {row['total_runs']} | "
                       f"{row['timeout_rate']} | {row['median_time_ms']} | {row['median_models']} |\n")
        elif has_opt and not has_enum:
            # Opt-specific table with optimization direction
            f.write("| Semiring | Monoid | Opt Dir | Topology | A | R | D | Runs | Timeout Rate | Median Time (ms) |\n")
            f.write("|----------|--------|---------|----------|---|---|---|------|--------------|------------------|\n")

            for row in summary_stats[:20]:
                f.write(f"| {row['semiring']} | {row['monoid']} | {row['opt_direction']} | {row['topology']} | "
                       f"{row['A']} | {row['R']} | {row['D']} | {row['total_runs']} | "
                       f"{row['timeout_rate']} | {row['median_time_ms']} |\n")
        else:
            # Mixed mode table
            f.write("| Semiring | Monoid | Mode | Opt Dir | Topology | A | R | D | Runs | Timeout Rate | Median Time (ms) |\n")
            f.write("|----------|--------|------|---------|----------|---|---|---|------|--------------|------------------|\n")

            for row in summary_stats[:20]:
                f.write(f"| {row['semiring']} | {row['monoid']} | {row['mode']} | {row['opt_direction']} | {row['topology']} | "
                       f"{row['A']} | {row['R']} | {row['D']} | {row['total_runs']} | "
                       f"{row['timeout_rate']} | {row['median_time_ms']} |\n")

        f.write("\n---\n\n")
        f.write("*Full summary available in summary.csv*\n")

    print(f"✓ Report written to: {output_file}")


def main():
    parser = argparse.ArgumentParser(
        description='WABA Benchmark Analysis v3.0 - Analyze results and generate reports'
    )

    parser.add_argument('--input', type=Path, default=Path('results/results.jsonl'),
                       help='Input results.jsonl file (default: results/results.jsonl)')
    parser.add_argument('--output-dir', type=Path, default=Path('analysis'),
                       help='Output directory for analysis (default: analysis/)')

    args = parser.parse_args()

    # Validate input
    if not args.input.exists():
        print(f"Error: Results file not found: {args.input}", file=sys.stderr)
        return 1

    # Load results
    print(f"Loading results from {args.input}...")
    results = load_results(args.input)
    print(f"✓ Loaded {len(results)} results")

    if len(results) == 0:
        print("Error: No results to analyze", file=sys.stderr)
        return 1

    # Ensure output directory exists
    args.output_dir.mkdir(parents=True, exist_ok=True)

    # Compute summary statistics
    print("Computing summary statistics...")
    summary_stats = compute_summary_stats(results)

    # Write summary CSV
    summary_csv = args.output_dir / 'summary.csv'
    write_summary_csv(summary_stats, summary_csv)

    # Generate plots
    if PLOTTING_AVAILABLE:
        print("Generating plots...")
        plots_dir = args.output_dir / 'plots'
        generate_plots(results, plots_dir)
    else:
        print("⚠ Skipping plots (matplotlib not available)")

    # Generate markdown report
    print("Generating markdown report...")
    report_file = args.output_dir / 'BENCHMARK_REPORT.md'
    generate_markdown_report(summary_stats, results, report_file)

    print(f"\n{'='*60}")
    print(f"Analysis complete!")
    print(f"Output directory: {args.output_dir}")
    print(f"  - summary.csv: {summary_csv}")
    if PLOTTING_AVAILABLE:
        print(f"  - plots/: {plots_dir}")
    print(f"  - BENCHMARK_REPORT.md: {report_file}")

    return 0


if __name__ == '__main__':
    sys.exit(main())
