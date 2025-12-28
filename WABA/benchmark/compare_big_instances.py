#!/usr/bin/env python3
"""Compare new-enum vs new-opt on bigger instances (>10sec)."""

import json
import os
from collections import defaultdict

def compare_big_instances(results_dir, time_threshold=10.0):
    """Compare new-enum vs new-opt on instances taking >time_threshold seconds."""

    results = defaultdict(lambda: {'new-enum': None, 'new-opt': {}})

    # Load results
    for filename in os.listdir(results_dir):
        if not filename.endswith('.json'):
            continue

        try:
            with open(os.path.join(results_dir, filename)) as f:
                data = json.load(f)

            framework = data.get('framework', '')
            semiring = data.get('semiring', '')
            monoid = data.get('monoid', '')
            mode = data.get('mode', '')
            opt_dir = data.get('optimization_direction', '')

            key = f"{framework}_{semiring}_{monoid}"

            if mode == 'new-enum':
                results[key]['new-enum'] = data
            elif mode == 'new-opt':
                results[key]['new-opt'][opt_dir] = data

        except Exception:
            continue

    print("=" * 80)
    print(f"NEW-ENUM vs NEW-OPT ON BIG INSTANCES (>{time_threshold}s)")
    print("=" * 80)

    big_comparisons = []

    for key, modes in results.items():
        if modes['new-enum'] and modes['new-opt']:
            enum_time = modes['new-enum'].get('elapsed_seconds', 0)
            enum_status = modes['new-enum'].get('status', '')

            for opt_dir, opt_data in modes['new-opt'].items():
                opt_time = opt_data.get('elapsed_seconds', 0)
                opt_status = opt_data.get('status', '')

                # Filter for instances where at least one mode takes >threshold
                if (enum_time > time_threshold or opt_time > time_threshold) and \
                   enum_status != 'TIMEOUT' and opt_status != 'TIMEOUT':

                    ratio = enum_time / opt_time
                    big_comparisons.append({
                        'config': key,
                        'opt_dir': opt_dir,
                        'enum_time': enum_time,
                        'opt_time': opt_time,
                        'ratio': ratio,
                        'enum_models': modes['new-enum'].get('models', 0),
                        'opt_models': opt_data.get('models', 0),
                        'enum_grounding': modes['new-enum'].get('grounding_size', 0),
                        'opt_grounding': opt_data.get('grounding_size', 0)
                    })

    if not big_comparisons:
        print(f"\nNo instances found taking >{time_threshold}s in current results.")
        print("Benchmark may not have reached complex instances yet.")
        return

    print(f"\nFound {len(big_comparisons)} big instance comparisons")

    # Statistics
    avg_ratio = sum(c['ratio'] for c in big_comparisons) / len(big_comparisons)
    median_ratio = sorted(big_comparisons, key=lambda x: x['ratio'])[len(big_comparisons)//2]['ratio']

    print(f"\nTiming ratio (new-enum / new-opt):")
    print(f"  Average: {avg_ratio:.2f}x")
    print(f"  Median: {median_ratio:.2f}x")

    if avg_ratio > 1:
        print(f"  → new-opt is {avg_ratio:.2f}x faster on average for big instances")
    else:
        print(f"  → new-enum is {1/avg_ratio:.2f}x faster on average for big instances")

    # Distribution
    print("\nPerformance breakdown:")
    opt_faster = len([c for c in big_comparisons if c['ratio'] > 1])
    enum_faster = len([c for c in big_comparisons if c['ratio'] <= 1])

    print(f"  new-opt faster: {opt_faster} ({100*opt_faster/len(big_comparisons):.1f}%)")
    print(f"  new-enum faster: {enum_faster} ({100*enum_faster/len(big_comparisons):.1f}%)")

    # Magnitude breakdown
    print("\nSpeedup magnitude:")
    ranges = [
        (float('-inf'), 0.5, "new-enum >2x faster"),
        (0.5, 0.9, "new-enum slightly faster"),
        (0.9, 1.1, "comparable"),
        (1.1, 2.0, "new-opt slightly faster"),
        (2.0, 10.0, "new-opt 2-10x faster"),
        (10.0, float('inf'), "new-opt >10x faster")
    ]

    for low, high, label in ranges:
        count = len([c for c in big_comparisons if low <= c['ratio'] < high])
        if count > 0:
            pct = 100 * count / len(big_comparisons)
            print(f"  {label}: {count} ({pct:.1f}%)")

    # Show all big instances sorted by speedup
    print("\n" + "=" * 80)
    print("ALL BIG INSTANCES (sorted by new-opt speedup)")
    print("=" * 80)
    print(f"\n{'Configuration':<65} {'Dir':<3} {'Enum':<8} {'Opt':<8} {'Ratio':>6} {'Models':<12}")
    print("-" * 120)

    for c in sorted(big_comparisons, key=lambda x: x['ratio'], reverse=True):
        winner = "✓" if c['ratio'] > 1.1 else ("✗" if c['ratio'] < 0.9 else "≈")
        models_str = f"{c['enum_models']}/{c['opt_models']}"

        print(f"{c['config'][:65]:<65} {c['opt_dir'][:3]:<3} "
              f"{c['enum_time']:>7.2f}s {c['opt_time']:>7.2f}s "
              f"{c['ratio']:>5.2f}x {winner} {models_str:<12}")

    # Correlation with model count
    print("\n" + "=" * 80)
    print("CORRELATION WITH MODEL COUNT (big instances)")
    print("=" * 80)

    model_groups = defaultdict(list)
    for c in big_comparisons:
        enum_models = c['enum_models']
        if enum_models == 0:
            group = "0 models"
        elif enum_models <= 10:
            group = "1-10 models"
        elif enum_models <= 50:
            group = "11-50 models"
        else:
            group = ">50 models"

        model_groups[group].append(c)

    for group in ["0 models", "1-10 models", "11-50 models", ">50 models"]:
        if group in model_groups:
            group_comparisons = model_groups[group]
            avg_group_ratio = sum(c['ratio'] for c in group_comparisons) / len(group_comparisons)

            winner = "new-opt" if avg_group_ratio > 1 else "new-enum"
            speedup = avg_group_ratio if avg_group_ratio > 1 else 1/avg_group_ratio

            print(f"{group:>15}: {len(group_comparisons):3} cases, {winner} {speedup:.2f}x faster on average")

    # Time savings
    print("\n" + "=" * 80)
    print("TIME SAVINGS")
    print("=" * 80)

    total_enum_time = sum(c['enum_time'] for c in big_comparisons)
    total_opt_time = sum(c['opt_time'] for c in big_comparisons)
    time_saved = total_enum_time - total_opt_time

    print(f"Total new-enum time: {total_enum_time:.2f}s ({total_enum_time/60:.2f} minutes)")
    print(f"Total new-opt time:  {total_opt_time:.2f}s ({total_opt_time/60:.2f} minutes)")

    if time_saved > 0:
        print(f"Time saved with new-opt: {time_saved:.2f}s ({time_saved/60:.2f} minutes)")
        print(f"Speedup: {total_enum_time/total_opt_time:.2f}x")
    else:
        print(f"Time lost with new-opt: {-time_saved:.2f}s ({-time_saved/60:.2f} minutes)")
        print(f"Slowdown: {total_opt_time/total_enum_time:.2f}x")

    print("\n" + "=" * 80)

if __name__ == '__main__':
    import sys
    results_dir = sys.argv[1] if len(sys.argv) > 1 else 'results/three_mode/20251227_002219'
    threshold = float(sys.argv[2]) if len(sys.argv) > 2 else 10.0
    compare_big_instances(results_dir, threshold)
