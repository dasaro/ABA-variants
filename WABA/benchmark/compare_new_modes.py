#!/usr/bin/env python3
"""Compare new-enum vs new-opt performance."""

import json
import os
from collections import defaultdict

def compare_new_modes(results_dir):
    """Compare new-enum vs new-opt timing."""

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
    print("NEW-ENUM vs NEW-OPT PERFORMANCE COMPARISON")
    print("=" * 80)

    comparisons = []
    enum_timeouts = 0
    opt_timeouts = 0

    for key, modes in results.items():
        if modes['new-enum'] and modes['new-opt']:
            enum_time = modes['new-enum'].get('elapsed_seconds', 0)
            enum_status = modes['new-enum'].get('status', '')

            for opt_dir, opt_data in modes['new-opt'].items():
                opt_time = opt_data.get('elapsed_seconds', 0)
                opt_status = opt_data.get('status', '')

                if enum_status == 'TIMEOUT':
                    enum_timeouts += 1
                if opt_status == 'TIMEOUT':
                    opt_timeouts += 1

                if enum_time > 0 and opt_time > 0 and enum_status != 'TIMEOUT' and opt_status != 'TIMEOUT':
                    ratio = enum_time / opt_time
                    comparisons.append({
                        'config': key,
                        'opt_dir': opt_dir,
                        'enum_time': enum_time,
                        'opt_time': opt_time,
                        'ratio': ratio,  # >1 means opt is faster, <1 means enum is faster
                        'enum_models': modes['new-enum'].get('models', 0),
                        'opt_models': opt_data.get('models', 0)
                    })

    print(f"\nTotal comparisons: {len(comparisons)}")
    print(f"new-enum timeouts: {enum_timeouts}")
    print(f"new-opt timeouts: {opt_timeouts}")

    if comparisons:
        avg_ratio = sum(c['ratio'] for c in comparisons) / len(comparisons)
        median_ratio = sorted(comparisons, key=lambda x: x['ratio'])[len(comparisons)//2]['ratio']

        print(f"\nTiming ratio (new-enum / new-opt):")
        print(f"  Average: {avg_ratio:.2f}x")
        print(f"  Median: {median_ratio:.2f}x")

        if avg_ratio > 1:
            print(f"  → new-opt is {avg_ratio:.2f}x faster on average")
        else:
            print(f"  → new-enum is {1/avg_ratio:.2f}x faster on average")

        # Distribution
        print("\nDistribution:")
        opt_faster = len([c for c in comparisons if c['ratio'] > 1])
        enum_faster = len([c for c in comparisons if c['ratio'] <= 1])

        print(f"  new-opt faster: {opt_faster} ({100*opt_faster/len(comparisons):.1f}%)")
        print(f"  new-enum faster: {enum_faster} ({100*enum_faster/len(comparisons):.1f}%)")

        # Breakdown by speedup magnitude
        print("\nSpeedup breakdown:")
        ranges = [
            (float('-inf'), 0.5, "new-enum >2x faster"),
            (0.5, 0.9, "new-enum slightly faster"),
            (0.9, 1.1, "comparable"),
            (1.1, 2.0, "new-opt slightly faster"),
            (2.0, 10.0, "new-opt 2-10x faster"),
            (10.0, float('inf'), "new-opt >10x faster")
        ]

        for low, high, label in ranges:
            count = len([c for c in comparisons if low <= c['ratio'] < high])
            if count > 0:
                pct = 100 * count / len(comparisons)
                print(f"  {label}: {count} ({pct:.1f}%)")

        # Correlation with model count
        print("\n" + "=" * 80)
        print("CORRELATION WITH MODEL COUNT")
        print("=" * 80)

        # Group by model count ranges
        model_groups = defaultdict(list)
        for c in comparisons:
            enum_models = c['enum_models']
            if enum_models == 0:
                group = "0 models"
            elif enum_models <= 10:
                group = "1-10 models"
            elif enum_models <= 50:
                group = "11-50 models"
            elif enum_models <= 100:
                group = "51-100 models"
            else:
                group = ">100 models"

            model_groups[group].append(c)

        for group in ["0 models", "1-10 models", "11-50 models", "51-100 models", ">100 models"]:
            if group in model_groups:
                group_comparisons = model_groups[group]
                avg_group_ratio = sum(c['ratio'] for c in group_comparisons) / len(group_comparisons)

                winner = "new-opt" if avg_group_ratio > 1 else "new-enum"
                speedup = avg_group_ratio if avg_group_ratio > 1 else 1/avg_group_ratio

                print(f"{group:>15}: {len(group_comparisons):3} cases, {winner} {speedup:.2f}x faster on average")

        # Show extreme cases
        print("\n" + "=" * 80)
        print("EXTREME CASES")
        print("=" * 80)

        print("\nTop 5 where new-opt is fastest:")
        for c in sorted(comparisons, key=lambda x: x['ratio'], reverse=True)[:5]:
            print(f"  {c['config'][:60]:60} ({c['opt_dir'][:3]}): {c['ratio']:.2f}x faster")
            print(f"    enum: {c['enum_time']:.3f}s ({c['enum_models']} models), opt: {c['opt_time']:.3f}s ({c['opt_models']} models)")

        print("\nTop 5 where new-enum is fastest:")
        for c in sorted(comparisons, key=lambda x: x['ratio'])[:5]:
            print(f"  {c['config'][:60]:60} ({c['opt_dir'][:3]}): {1/c['ratio']:.2f}x faster")
            print(f"    enum: {c['enum_time']:.3f}s ({c['enum_models']} models), opt: {c['opt_time']:.3f}s ({c['opt_models']} models)")

    print("\n" + "=" * 80)

if __name__ == '__main__':
    import sys
    results_dir = sys.argv[1] if len(sys.argv) > 1 else 'results/three_mode/20251227_002219'
    compare_new_modes(results_dir)
