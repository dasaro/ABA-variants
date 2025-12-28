#!/usr/bin/env python3
"""Quick preliminary analysis of benchmark results."""

import json
import os
from pathlib import Path
from collections import defaultdict

def analyze_results(results_dir):
    """Analyze benchmark results for speedup and consistency."""

    results = defaultdict(lambda: {'old-enum': None, 'new-enum': None, 'new-opt': {}})

    # Load all JSON files
    for filename in os.listdir(results_dir):
        if not filename.endswith('.json'):
            continue

        filepath = Path(results_dir) / filename
        try:
            with open(filepath) as f:
                data = json.load(f)

            # Extract framework, config, and mode
            framework = data.get('framework', '')
            semiring = data.get('semiring', '')
            monoid = data.get('monoid', '')
            mode = data.get('mode', '')
            opt_dir = data.get('optimization_direction', '')

            key = f"{framework}_{semiring}_{monoid}"

            if mode == 'old-enum':
                results[key]['old-enum'] = data
            elif mode == 'new-enum':
                results[key]['new-enum'] = data
            elif mode == 'new-opt':
                results[key]['new-opt'][opt_dir] = data

        except Exception as e:
            print(f"Error reading {filename}: {e}")
            continue

    # Analyze results
    print("=" * 80)
    print("PRELIMINARY BENCHMARK ANALYSIS")
    print("=" * 80)
    print(f"\nTotal configurations analyzed: {len(results)}")
    print(f"Total result files: {len([f for f in os.listdir(results_dir) if f.endswith('.json')])}")

    # Consistency check: old-enum vs new-enum
    print("\n" + "=" * 80)
    print("SEMANTIC EQUIVALENCE CHECK (old-enum vs new-enum)")
    print("=" * 80)

    consistent = 0
    inconsistent = 0
    inconsistent_details = []

    for key, modes in results.items():
        if modes['old-enum'] and modes['new-enum']:
            old_models = modes['old-enum'].get('models', 0)
            new_models = modes['new-enum'].get('models', 0)

            if old_models == new_models:
                consistent += 1
            else:
                inconsistent += 1
                inconsistent_details.append({
                    'config': key,
                    'old_models': old_models,
                    'new_models': new_models
                })

    print(f"✅ Consistent (same model count): {consistent}")
    print(f"❌ Inconsistent (different model count): {inconsistent}")

    if inconsistent > 0:
        print("\nInconsistent configurations:")
        for detail in inconsistent_details[:10]:  # Show first 10
            print(f"  {detail['config']}: old={detail['old_models']}, new={detail['new_models']}")

    # Speedup analysis: old-enum vs new-opt
    print("\n" + "=" * 80)
    print("SPEEDUP ANALYSIS (old-enum vs new-opt)")
    print("=" * 80)

    speedups = []
    timeouts_old = 0
    timeouts_new = 0

    for key, modes in results.items():
        if modes['old-enum'] and modes['new-opt']:
            old_time = modes['old-enum'].get('elapsed_seconds', 0)

            # Check all optimization directions
            for opt_dir, new_data in modes['new-opt'].items():
                new_time = new_data.get('elapsed_seconds', 0)

                # Check for timeouts
                if modes['old-enum'].get('status') == 'TIMEOUT':
                    timeouts_old += 1
                if new_data.get('status') == 'TIMEOUT':
                    timeouts_new += 1

                if old_time > 0 and new_time > 0:
                    speedup = old_time / new_time
                    speedups.append({
                        'config': key,
                        'opt_dir': opt_dir,
                        'old_time': old_time,
                        'new_time': new_time,
                        'speedup': speedup
                    })

    if speedups:
        avg_speedup = sum(s['speedup'] for s in speedups) / len(speedups)
        max_speedup = max(speedups, key=lambda x: x['speedup'])
        min_speedup = min(speedups, key=lambda x: x['speedup'])

        print(f"Average speedup: {avg_speedup:.2f}x")
        print(f"Maximum speedup: {max_speedup['speedup']:.2f}x ({max_speedup['config']})")
        print(f"Minimum speedup: {min_speedup['speedup']:.2f}x ({min_speedup['config']})")
        print(f"\nTimeouts in old-enum: {timeouts_old}")
        print(f"Timeouts in new-opt: {timeouts_new}")

        # Show distribution
        print("\nSpeedup distribution:")
        ranges = [(0, 10), (10, 100), (100, 1000), (1000, float('inf'))]
        for low, high in ranges:
            count = len([s for s in speedups if low <= s['speedup'] < high])
            if count > 0:
                print(f"  {low}-{high if high != float('inf') else '∞'}x: {count} configurations")
    else:
        print("No speedup data available yet")

    # Grounding size comparison
    print("\n" + "=" * 80)
    print("GROUNDING SIZE COMPARISON (old-enum vs new-enum)")
    print("=" * 80)

    grounding_comparisons = []

    for key, modes in results.items():
        if modes['old-enum'] and modes['new-enum']:
            old_size = modes['old-enum'].get('grounding_size', 0)
            new_size = modes['new-enum'].get('grounding_size', 0)

            if old_size > 0 and new_size > 0:
                ratio = new_size / old_size
                grounding_comparisons.append({
                    'config': key,
                    'old_size': old_size,
                    'new_size': new_size,
                    'ratio': ratio
                })

    if grounding_comparisons:
        avg_ratio = sum(g['ratio'] for g in grounding_comparisons) / len(grounding_comparisons)
        print(f"Average grounding size ratio (new/old): {avg_ratio:.2f}")

        if avg_ratio > 1.1:
            print("⚠️  New grounding is larger (may indicate optimization overhead)")
        elif avg_ratio < 0.9:
            print("✅ New grounding is smaller (optimization reducing grounding)")
        else:
            print("✅ Grounding sizes are comparable (expected)")

    print("\n" + "=" * 80)

if __name__ == '__main__':
    import sys
    results_dir = sys.argv[1] if len(sys.argv) > 1 else 'results/three_mode/20251227_002219'
    analyze_results(results_dir)
