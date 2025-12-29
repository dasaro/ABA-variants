#!/usr/bin/env python3
"""
Protect Active Run - Safety tool to detect and prevent modifications to active benchmark runs.

Usage:
    python protect_active_run.py [--list|--check PATH]

Examples:
    # List all protected paths
    python protect_active_run.py --list

    # Check if a path is protected
    python protect_active_run.py --check results/grid3_7x7x7_rep3/enum.jsonl
"""

import argparse
import subprocess
import sys
from pathlib import Path
from typing import List, Set

def get_active_benchmark_processes() -> List[dict]:
    """Detect active benchmark_runner processes."""
    try:
        result = subprocess.run(
            ['ps', 'aux'],
            capture_output=True,
            text=True
        )

        processes = []
        for line in result.stdout.splitlines():
            if 'benchmark_runner.py' in line and 'grep' not in line:
                parts = line.split()
                pid = parts[1]
                cmd = ' '.join(parts[10:])

                # Extract key arguments
                output_path = None
                plan_path = None
                frameworks_dir = None

                args = cmd.split()
                for i, arg in enumerate(args):
                    if arg == '--output' and i + 1 < len(args):
                        output_path = args[i + 1]
                    elif arg == '--plan' and i + 1 < len(args):
                        plan_path = args[i + 1]
                    elif arg == '--frameworks-dir' and i + 1 < len(args):
                        frameworks_dir = args[i + 1]

                processes.append({
                    'pid': pid,
                    'output': output_path,
                    'plan': plan_path,
                    'frameworks': frameworks_dir,
                    'command': cmd
                })

        return processes

    except Exception as e:
        print(f"Error detecting processes: {e}", file=sys.stderr)
        return []

def get_open_files() -> Set[str]:
    """Get all files currently open by benchmark processes."""
    try:
        result = subprocess.run(
            ['lsof'],
            capture_output=True,
            text=True
        )

        open_files = set()
        for line in result.stdout.splitlines():
            if 'grid3_7x7x7_rep3' in line or 'enum.log' in line or 'optN' in line:
                parts = line.split()
                if len(parts) > 8:
                    filepath = parts[8]
                    if Path(filepath).exists():
                        open_files.add(filepath)

        return open_files

    except Exception as e:
        print(f"Error getting open files: {e}", file=sys.stderr)
        return set()

def get_protected_paths() -> Set[str]:
    """Get all paths that should be protected from modification."""
    protected = set()

    # Get active processes
    processes = get_active_benchmark_processes()

    for proc in processes:
        # Add output files
        if proc['output']:
            protected.add(proc['output'])
            # Add parent directories
            protected.add(str(Path(proc['output']).parent))

        # Add plan files
        if proc['plan']:
            protected.add(proc['plan'])

        # Add frameworks directories
        if proc['frameworks']:
            protected.add(proc['frameworks'])

    # Add open files
    protected.update(get_open_files())

    # Add critical running code
    protected.add('benchmark_runner.py')

    # Add WABA module paths (read by clingo)
    protected.add('../WABA/core')
    protected.add('../WABA/semiring')
    protected.add('../WABA/monoid')
    protected.add('../WABA/filter')
    protected.add('../WABA/semantics')

    return protected

def is_protected(path: str) -> bool:
    """Check if a path is protected."""
    path = Path(path).resolve()
    protected_paths = get_protected_paths()

    for protected in protected_paths:
        protected_resolved = Path(protected).resolve()
        try:
            # Check if path is protected or is under a protected directory
            if path == protected_resolved or protected_resolved in path.parents:
                return True
        except Exception:
            continue

    return False

def list_protected_paths():
    """List all currently protected paths."""
    processes = get_active_benchmark_processes()

    if not processes:
        print("No active benchmark processes detected.")
        return

    print("="*70)
    print("PROTECTED PATHS - DO NOT MODIFY")
    print("="*70)
    print()

    for i, proc in enumerate(processes, 1):
        print(f"Process {i} (PID {proc['pid']}):")
        print(f"  Output:     {proc['output']}")
        print(f"  Plan:       {proc['plan']}")
        print(f"  Frameworks: {proc['frameworks']}")
        print()

    print("Additional protected files:")
    print("  - benchmark_runner.py (currently executing)")
    print("  - ../WABA/core/** (clingo modules)")
    print("  - ../WABA/semiring/** (clingo modules)")
    print("  - ../WABA/monoid/** (clingo modules)")
    print("  - ../WABA/filter/** (clingo modules)")
    print("  - ../WABA/semantics/** (clingo modules)")
    print()

    open_files = get_open_files()
    if open_files:
        print(f"Open files ({len(open_files)}):")
        for f in sorted(open_files):
            print(f"  - {f}")
    else:
        print("No open files detected (may require sudo for lsof)")

    print("="*70)

def check_path(path: str):
    """Check if a specific path is protected."""
    if is_protected(path):
        print(f"⚠ WARNING: '{path}' is PROTECTED by an active run")
        print("DO NOT modify, delete, or move this path.")
        sys.exit(1)
    else:
        print(f"✓ '{path}' is safe to modify (not protected)")
        sys.exit(0)

def main():
    parser = argparse.ArgumentParser(
        description='Protect active benchmark runs from accidental modification'
    )
    parser.add_argument('--list', action='store_true',
                       help='List all currently protected paths')
    parser.add_argument('--check', type=str,
                       help='Check if a specific path is protected')

    args = parser.parse_args()

    if args.list:
        list_protected_paths()
    elif args.check:
        check_path(args.check)
    else:
        parser.print_help()

if __name__ == '__main__':
    main()
