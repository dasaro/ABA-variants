#!/usr/bin/env python3
"""Analyze timeout patterns between new-enum and new-opt."""

import json
import os
from collections import defaultdict

def analyze_timeouts(results_dir):
    """Find cases where new-opt times out but new-enum succeeds."""

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
    print("TIMEOUT ANALYSIS: new-enum vs new-opt")
    print("=" * 80)

    # Cases where new-opt times out but new-enum succeeds
    opt_timeout_enum_success = []
    # Cases where new-enum times out but new-opt succeeds
    enum_timeout_opt_success = []
    # Cases where both timeout
    both_timeout = []
    # Cases where both succeed
    both_succeed = []

    for key, modes in results.items():
        if modes['new-enum'] and modes['new-opt']:
            enum_status = modes['new-enum'].get('status', '')

            for opt_dir, opt_data in modes['new-opt'].items():
                opt_status = opt_data.get('status', '')

                if enum_status == 'TIMEOUT' and opt_status == 'TIMEOUT':
                    both_timeout.append({
                        'config': key,
                        'opt_dir': opt_dir,
                        'enum_data': modes['new-enum'],
                        'opt_data': opt_data
                    })
                elif enum_status == 'TIMEOUT' and opt_status != 'TIMEOUT':
                    enum_timeout_opt_success.append({
                        'config': key,
                        'opt_dir': opt_dir,
                        'enum_data': modes['new-enum'],
                        'opt_data': opt_data
                    })
                elif enum_status != 'TIMEOUT' and opt_status == 'TIMEOUT':
                    opt_timeout_enum_success.append({
                        'config': key,
                        'opt_dir': opt_dir,
                        'enum_data': modes['new-enum'],
                        'opt_data': opt_data
                    })
                else:
                    both_succeed.append({
                        'config': key,
                        'opt_dir': opt_dir,
                        'enum_data': modes['new-enum'],
                        'opt_data': opt_data
                    })

    print(f"\nTimeout summary:")
    print(f"  Both succeed: {len(both_succeed)}")
    print(f"  Both timeout: {len(both_timeout)}")
    print(f"  new-enum timeout, new-opt success: {len(enum_timeout_opt_success)}")
    print(f"  new-opt timeout, new-enum success: {len(opt_timeout_enum_success)} ⚠️")

    # Analyze cases where new-opt times out but new-enum succeeds
    if opt_timeout_enum_success:
        print("\n" + "=" * 80)
        print("⚠️  CASES WHERE new-opt TIMES OUT BUT new-enum SUCCEEDS")
        print("=" * 80)

        print(f"\nFound {len(opt_timeout_enum_success)} such cases:\n")

        for case in opt_timeout_enum_success:
            config = case['config']
            opt_dir = case['opt_dir']
            enum_data = case['enum_data']
            opt_data = case['opt_data']

            enum_time = enum_data.get('elapsed_seconds', 0)
            enum_models = enum_data.get('models', 0)
            enum_grounding = enum_data.get('grounding_size', 0)

            opt_grounding = opt_data.get('grounding_size', -1)

            print(f"Config: {config}")
            print(f"  Optimization direction: {opt_dir}")
            print(f"  new-enum: {enum_time:.2f}s, {enum_models} models, grounding={enum_grounding}")
            print(f"  new-opt:  TIMEOUT (120s), grounding={opt_grounding}")
            print(f"  Grounding difference: {opt_grounding - enum_grounding if opt_grounding > 0 else 'N/A'}")
            print()

    # Analyze cases where new-enum times out but new-opt succeeds
    if enum_timeout_opt_success:
        print("\n" + "=" * 80)
        print("✅ CASES WHERE new-enum TIMES OUT BUT new-opt SUCCEEDS")
        print("=" * 80)

        print(f"\nFound {len(enum_timeout_opt_success)} such cases:\n")

        for case in enum_timeout_opt_success:
            config = case['config']
            opt_dir = case['opt_dir']
            enum_data = case['enum_data']
            opt_data = case['opt_data']

            enum_grounding = enum_data.get('grounding_size', -1)

            opt_time = opt_data.get('elapsed_seconds', 0)
            opt_models = opt_data.get('models', 0)
            opt_grounding = opt_data.get('grounding_size', 0)

            print(f"Config: {config}")
            print(f"  Optimization direction: {opt_dir}")
            print(f"  new-enum: TIMEOUT (120s), grounding={enum_grounding}")
            print(f"  new-opt:  {opt_time:.2f}s, {opt_models} models, grounding={opt_grounding}")
            print(f"  Grounding difference: {opt_grounding - enum_grounding if enum_grounding > 0 else 'N/A'}")
            print()

    # Pattern analysis
    if opt_timeout_enum_success:
        print("\n" + "=" * 80)
        print("PATTERN ANALYSIS: Why does new-opt timeout when new-enum succeeds?")
        print("=" * 80)

        # Group by semiring
        by_semiring = defaultdict(list)
        by_monoid = defaultdict(list)
        by_opt_dir = defaultdict(list)

        for case in opt_timeout_enum_success:
            config_parts = case['config'].split('_')
            # Extract semiring (second to last or third to last)
            if len(config_parts) >= 2:
                # Handle bottleneck_cost as single semiring name
                if 'bottleneck' in case['config']:
                    semiring = 'bottleneck_cost'
                    monoid = config_parts[-1]
                else:
                    semiring = config_parts[-2]
                    monoid = config_parts[-1]

                by_semiring[semiring].append(case)
                by_monoid[monoid].append(case)
                by_opt_dir[case['opt_dir']].append(case)

        print("\nBreakdown by semiring:")
        for semiring, cases in sorted(by_semiring.items()):
            print(f"  {semiring}: {len(cases)} cases")

        print("\nBreakdown by monoid:")
        for monoid, cases in sorted(by_monoid.items()):
            print(f"  {monoid}: {len(cases)} cases")

        print("\nBreakdown by optimization direction:")
        for opt_dir, cases in sorted(by_opt_dir.items()):
            print(f"  {opt_dir}: {len(cases)} cases")

    print("\n" + "=" * 80)

if __name__ == '__main__':
    import sys
    results_dir = sys.argv[1] if len(sys.argv) > 1 else 'results/three_mode/20251227_002219'
    analyze_timeouts(results_dir)
