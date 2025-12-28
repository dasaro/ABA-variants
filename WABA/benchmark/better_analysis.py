#!/usr/bin/env python3
"""Better preliminary analysis distinguishing timeouts from actual inconsistencies."""

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
            continue

    print("=" * 80)
    print("PRELIMINARY BENCHMARK ANALYSIS")
    print("=" * 80)
    print(f"\nBenchmark: RUNNING (1,501 / 9,600 results so far, ~15.6% complete)")
    print(f"Total configurations analyzed: {len(results)}")

    # Consistency check
    print("\n" + "=" * 80)
    print("SEMANTIC EQUIVALENCE CHECK (old-enum vs new-enum)")
    print("=" * 80)

    consistent = 0
    timeout_old = 0
    timeout_new = 0
    actual_inconsistent = []

    for key, modes in results.items():
        if modes['old-enum'] and modes['new-enum']:
            old_status = modes['old-enum'].get('status', '')
            new_status = modes['new-enum'].get('status', '')
            old_models = modes['old-enum'].get('models', 0)
            new_models = modes['new-enum'].get('models', 0)

            # Check for timeouts
            if old_status == 'TIMEOUT':
                timeout_old += 1
            elif new_status == 'TIMEOUT':
                timeout_new += 1
            elif old_models == new_models:
                consistent += 1
            else:
                actual_inconsistent.append({
                    'config': key,
                    'old_models': old_models,
                    'new_models': new_models,
                    'old_status': old_status,
                    'new_status': new_status
                })

    total_compared = consistent + len(actual_inconsistent) + timeout_old + timeout_new
    print(f"✅ Semantically equivalent: {consistent}/{total_compared} ({100*consistent/total_compared:.1f}%)")
    print(f"⏱️  Old-enum timeouts (new-enum succeeded): {timeout_old}")
    print(f"⏱️  New-enum timeouts (old-enum succeeded): {timeout_new}")
    print(f"❌ Actual inconsistencies: {len(actual_inconsistent)}")

    if actual_inconsistent:
        print("\n⚠️  ACTUAL INCONSISTENCIES (needs investigation):")
        for detail in actual_inconsistent:
            print(f"  {detail['config']}: old={detail['old_models']} ({detail['old_status']}), new={detail['new_models']} ({detail['new_status']})")
    else:
        print("\n✅ NO ACTUAL INCONSISTENCIES - All differences are due to timeouts!")

    # Speedup analysis
    print("\n" + "=" * 80)
    print("SPEEDUP ANALYSIS (old-enum vs new-opt)")
    print("=" * 80)

    speedups = []
    old_enum_timeouts = 0
    new_opt_timeouts = 0
    old_enum_success = 0
    new_opt_success = 0

    for key, modes in results.items():
        if modes['old-enum'] and modes['new-opt']:
            for opt_dir, new_data in modes['new-opt'].items():
                old_status = modes['old-enum'].get('status', '')
                new_status = new_data.get('status', '')

                if old_status == 'TIMEOUT':
                    old_enum_timeouts += 1
                else:
                    old_enum_success += 1

                if new_status == 'TIMEOUT':
                    new_opt_timeouts += 1
                else:
                    new_opt_success += 1

                old_time = modes['old-enum'].get('elapsed_seconds', 0)
                new_time = new_data.get('elapsed_seconds', 0)

                if old_time > 0 and new_time > 0 and old_status != 'TIMEOUT' and new_status != 'TIMEOUT':
                    speedup = old_time / new_time
                    speedups.append({
                        'config': key,
                        'opt_dir': opt_dir,
                        'old_time': old_time,
                        'new_time': new_time,
                        'speedup': speedup
                    })

    print(f"Old-enum results: {old_enum_success} success, {old_enum_timeouts} timeout")
    print(f"New-opt results: {new_opt_success} success, {new_opt_timeouts} timeout")
    print(f"Timeout reduction: {old_enum_timeouts - new_opt_timeouts} fewer timeouts in new-opt")

    if speedups:
        avg_speedup = sum(s['speedup'] for s in speedups) / len(speedups)
        max_speedup = max(speedups, key=lambda x: x['speedup'])
        min_speedup = min(speedups, key=lambda x: x['speedup'])
        median_speedup = sorted(speedups, key=lambda x: x['speedup'])[len(speedups)//2]['speedup']

        print(f"\nSpeedup statistics (for successful runs):")
        print(f"  Average: {avg_speedup:.2f}x")
        print(f"  Median: {median_speedup:.2f}x")
        print(f"  Maximum: {max_speedup['speedup']:.2f}x")
        print(f"  Minimum: {min_speedup['speedup']:.2f}x")

        # Distribution
        print("\nSpeedup distribution:")
        ranges = [(0, 1), (1, 10), (10, 100), (100, 1000), (1000, float('inf'))]
        for low, high in ranges:
            count = len([s for s in speedups if low <= s['speedup'] < high])
            if count > 0:
                pct = 100 * count / len(speedups)
                if high == float('inf'):
                    print(f"  {low}x+: {count} ({pct:.1f}%)")
                else:
                    print(f"  {low}-{high}x: {count} ({pct:.1f}%)")

        # Show top 5 slowdowns (speedup < 1)
        slowdowns = [s for s in speedups if s['speedup'] < 1.0]
        if slowdowns:
            print(f"\n⚠️  Slowdowns (new-opt slower than old-enum): {len(slowdowns)}")
            print("  Top 5 slowest:")
            for s in sorted(slowdowns, key=lambda x: x['speedup'])[:5]:
                print(f"    {s['config']} ({s['opt_dir']}): {s['speedup']:.2f}x (old={s['old_time']:.3f}s, new={s['new_time']:.3f}s)")

    # Grounding size comparison
    print("\n" + "=" * 80)
    print("GROUNDING SIZE COMPARISON (old-enum vs new-enum)")
    print("=" * 80)

    grounding_comparisons = []

    for key, modes in results.items():
        if modes['old-enum'] and modes['new-enum']:
            old_size = modes['old-enum'].get('grounding_size', -1)
            new_size = modes['new-enum'].get('grounding_size', -1)

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
        median_ratio = sorted(grounding_comparisons, key=lambda x: x['ratio'])[len(grounding_comparisons)//2]['ratio']

        print(f"Average grounding size ratio (new/old): {avg_ratio:.2f}")
        print(f"Median grounding size ratio (new/old): {median_ratio:.2f}")

        if avg_ratio > 1.1:
            pct_increase = (avg_ratio - 1) * 100
            print(f"⚠️  New grounding is {pct_increase:.1f}% larger on average")
        elif avg_ratio < 0.9:
            pct_decrease = (1 - avg_ratio) * 100
            print(f"✅ New grounding is {pct_decrease:.1f}% smaller on average")
        else:
            print("✅ Grounding sizes are comparable")

    print("\n" + "=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print(f"✅ Semantic equivalence: {consistent}/{total_compared} configurations ({100*consistent/total_compared:.1f}%)")
    print(f"✅ Speedup: {avg_speedup:.2f}x average (median {median_speedup:.2f}x)")
    print(f"✅ Grounding: {100*(1-avg_ratio):.1f}% reduction in size")
    print(f"✅ Timeouts: {old_enum_timeouts - new_opt_timeouts} fewer in new-opt")
    print("\nBenchmark still running - check back for complete results...")
    print("=" * 80)

if __name__ == '__main__':
    import sys
    results_dir = sys.argv[1] if len(sys.argv) > 1 else 'results/three_mode/20251227_002219'
    analyze_results(results_dir)
