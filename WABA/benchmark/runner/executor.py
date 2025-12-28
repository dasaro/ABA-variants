#!/usr/bin/env python3
"""
Improved Clingo Execution Wrapper with Aggressive Timeout Control

Uses process group + SIGKILL for strict timeout enforcement.
This prevents clingo cleanup from taking 10+ minutes on large model sets.
"""

import subprocess
import time
import signal
import os
import re
from pathlib import Path
from typing import Dict, List, Tuple, Optional, Any


# ================================================================
# Clingo Execution with Aggressive Timeout
# ================================================================

def run_clingo_aggressive(command: List[str], timeout: int = 60) -> Tuple[str, str, float, bool]:
    """Execute clingo command with aggressive timeout control using SIGKILL.

    Strategy: Remove clingo's --time-limit and use Python subprocess timeout
    with process group SIGKILL. This prevents clingo's cleanup phase from
    exceeding the timeout (which can take 10+ minutes for 3M+ models).

    Args:
        command: List of command arguments (e.g., ['clingo', '-n', '0', ...])
        timeout: Timeout in seconds (strict enforcement via SIGKILL)

    Returns:
        Tuple of (stdout, stderr, elapsed_seconds, timed_out)
    """
    start_time = time.time()
    timed_out = False
    stdout = ""
    stderr = ""

    try:
        # Start process in new process group
        # This allows killing entire process tree including any child processes
        proc = subprocess.Popen(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            preexec_fn=os.setpgrp  # Create new process group
        )

        # Wait with timeout
        stdout_bytes, stderr_bytes = proc.communicate(timeout=timeout)
        stdout = stdout_bytes if stdout_bytes else ""
        stderr = stderr_bytes if stderr_bytes else ""

    except subprocess.TimeoutExpired as e:
        timed_out = True

        # Immediately send SIGKILL to entire process group
        try:
            pgid = os.getpgid(proc.pid)
            os.killpg(pgid, signal.SIGKILL)
            proc.wait(timeout=2)  # Wait briefly for process to die
        except ProcessLookupError:
            # Process already dead
            pass
        except Exception as kill_error:
            # Log but don't fail - we still consider this a timeout
            stderr = f"Warning: Failed to kill process group: {kill_error}\n"

        # Try to get partial output
        try:
            stdout = e.stdout.decode('utf-8') if e.stdout else ""
            stderr += e.stderr.decode('utf-8') if e.stderr else ""
        except:
            pass

    elapsed = time.time() - start_time

    return stdout, stderr, elapsed, timed_out


def run_clingo(command: List[str], timeout: int = 60) -> Tuple[str, str, float, bool]:
    """Execute clingo command with timeout control.

    This is the main entry point. Defaults to aggressive strategy.

    Args:
        command: List of command arguments (e.g., ['clingo', '-n', '0', ...])
        timeout: Timeout in seconds (default: 60)

    Returns:
        Tuple of (stdout, stderr, elapsed_seconds, timed_out)
    """
    return run_clingo_aggressive(command, timeout)


# ================================================================
# Clingo Output Parsing
# ================================================================

def parse_clingo_output(stdout: str, stderr: str, timed_out: bool) -> Dict:
    """Parse clingo output into structured result dictionary with COMPACT representation.

    Args:
        stdout: Standard output from clingo
        stderr: Standard error from clingo
        timed_out: Whether the execution timed out

    Returns:
        Dict with keys:
            - status: 'SATISFIABLE', 'UNSATISFIABLE', 'TIMEOUT', 'ERROR'
            - models: Number of answer sets found
            - first_answer_set: First answer set (sample), or None
            - extension_cost_distribution: Histogram of extension costs
            - assumption_frequency: Count of models where each assumption is 'in'
            - statistics: Dict of solver statistics
            - timing: Dict of timing information
    """
    result = {
        'status': 'TIMEOUT' if timed_out else 'UNKNOWN',
        'models': 0,
        'first_answer_set': None,
        'extension_cost_distribution': {},
        'assumption_frequency': {},
        'statistics': {},
        'timing': {}
    }

    # Handle timeout
    if timed_out:
        result['status'] = 'TIMEOUT'
        # Try to extract partial statistics if available
        result['statistics'] = extract_statistics(stdout)
        result['timing'] = extract_timing(stdout)
        return result

    # Extract status from clingo output
    if 'UNSATISFIABLE' in stdout:
        result['status'] = 'UNSATISFIABLE'
    elif 'SATISFIABLE' in stdout or 'Answer:' in stdout:
        result['status'] = 'SATISFIABLE'
    elif stderr and ('error' in stderr.lower() or 'exception' in stderr.lower()):
        result['status'] = 'ERROR'
        result['error_message'] = stderr
        return result

    # Extract answer sets with COMPACT representation
    compact_summary = extract_answer_sets_compact(stdout)
    result['models'] = compact_summary['total_models']
    result['first_answer_set'] = compact_summary['first_answer_set']
    result['extension_cost_distribution'] = compact_summary['extension_cost_distribution']
    result['assumption_frequency'] = compact_summary['assumption_frequency']

    # Extract statistics and timing
    result['statistics'] = extract_statistics(stdout)
    result['timing'] = extract_timing(stdout)

    return result


def extract_answer_sets_compact(stdout: str) -> Dict:
    """Extract answer sets with COMPACT representation (summaries only).

    Instead of storing all answer sets, compute:
    - Total model count
    - First answer set (as sample)
    - Extension cost histogram
    - Assumption frequency across all models

    Returns:
        Dict with compact summary statistics
    """
    summary = {
        'total_models': 0,
        'first_answer_set': None,
        'extension_cost_distribution': {},
        'assumption_frequency': {}
    }

    # Pattern: "Answer: N (optional timing)" followed by atoms
    answer_pattern = re.compile(r'Answer:\s*\d+[^\n]*\n(.*?)(?=(?:Answer:|Optimization:|SATISFIABLE|UNSATISFIABLE|\Z))', re.DOTALL)

    for i, match in enumerate(answer_pattern.finditer(stdout)):
        atoms_str = match.group(1).strip()
        if not atoms_str:
            continue

        summary['total_models'] += 1

        # Parse ONLY the first answer set fully (as sample)
        if i == 0:
            summary['first_answer_set'] = parse_answer_set_atoms(atoms_str)

        # For all answer sets: extract ONLY extension cost and in/1 atoms
        # (lightweight parsing, no full atom storage)
        extension_cost = extract_extension_cost_only(atoms_str)
        in_assumptions = extract_in_assumptions_only(atoms_str)

        # Update extension cost distribution
        cost_key = str(extension_cost) if extension_cost is not None else 'unknown'
        summary['extension_cost_distribution'][cost_key] = \
            summary['extension_cost_distribution'].get(cost_key, 0) + 1

        # Update assumption frequency
        for assumption in in_assumptions:
            summary['assumption_frequency'][assumption] = \
                summary['assumption_frequency'].get(assumption, 0) + 1

    return summary


def extract_extension_cost_only(atoms_str: str) -> Any:
    """Extract ONLY extension_cost from answer set (lightweight)."""
    cost_match = re.search(r'extension_cost\((\d+|#\w+)\)', atoms_str)
    if cost_match:
        cost_str = cost_match.group(1)
        return cost_str if cost_str.startswith('#') else int(cost_str)
    return None


def extract_in_assumptions_only(atoms_str: str) -> List[str]:
    """Extract ONLY in/1 assumptions from answer set (lightweight)."""
    in_atoms = []
    for match in re.finditer(r'in\((\w+)\)', atoms_str):
        in_atoms.append(match.group(1))
    return in_atoms


def parse_answer_set_atoms(atoms_str: str) -> Dict:
    """Parse atoms from a single answer set.

    Extracts:
        - in/1: Selected assumptions
        - extension_cost/1: Extension cost value
        - supported_with_weight/2: Supported elements with weights
        - attacks_successfully_with_weight/3: Successful attacks

    Returns:
        Dict with lists of parsed atoms
    """
    parsed = {
        'in': [],
        'extension_cost': None,
        'supported_with_weight': [],
        'attacks_successfully': [],
        'discarded_attacks': []
    }

    # Split atoms by whitespace
    atoms = atoms_str.split()

    for atom in atoms:
        # in(X)
        in_match = re.match(r'in\((\w+)\)', atom)
        if in_match:
            parsed['in'].append(in_match.group(1))
            continue

        # extension_cost(N)
        cost_match = re.match(r'extension_cost\((\d+|#\w+)\)', atom)
        if cost_match:
            cost_str = cost_match.group(1)
            parsed['extension_cost'] = cost_str if cost_str.startswith('#') else int(cost_str)
            continue

        # supported_with_weight(X, W)
        sww_match = re.match(r'supported_with_weight\((\w+),(\d+|#\w+)\)', atom)
        if sww_match:
            elem = sww_match.group(1)
            weight_str = sww_match.group(2)
            weight = weight_str if weight_str.startswith('#') else int(weight_str)
            parsed['supported_with_weight'].append({'element': elem, 'weight': weight})
            continue

        # attacks_successfully_with_weight(X, Y, W)
        attack_match = re.match(r'attacks_successfully_with_weight\((\w+),(\w+),(\d+|#\w+)\)', atom)
        if attack_match:
            attacker = attack_match.group(1)
            target = attack_match.group(2)
            weight_str = attack_match.group(3)
            weight = weight_str if weight_str.startswith('#') else int(weight_str)
            parsed['attacks_successfully'].append({
                'attacker': attacker,
                'target': target,
                'weight': weight
            })
            continue

        # discarded_attack(X, Y, W)
        discard_match = re.match(r'discarded_attack\((\w+),(\w+),(\d+|#\w+)\)', atom)
        if discard_match:
            attacker = discard_match.group(1)
            target = discard_match.group(2)
            weight_str = discard_match.group(3)
            weight = weight_str if weight_str.startswith('#') else int(weight_str)
            parsed['discarded_attacks'].append({
                'attacker': attacker,
                'target': target,
                'weight': weight
            })
            continue

    return parsed


def extract_statistics(stdout: str) -> Dict:
    """Extract solver statistics from clingo output.

    Returns:
        Dict with statistics like choices, conflicts, restarts, etc.
    """
    stats = {}

    # Common statistics patterns from --stats=2
    stat_patterns = {
        'choices': r'Choices\s+:\s+(\d+)',
        'conflicts': r'Conflicts\s+:\s+(\d+)',
        'restarts': r'Restarts\s+:\s+(\d+)',
        'rules': r'Rules\s+:\s+(\d+)',
        'atoms': r'Atoms\s+:\s+(\d+)',
        'bodies': r'Bodies\s+:\s+(\d+)',
        'variables': r'Variables\s+:\s+(\d+)',
        'constraints': r'Constraints\s+:\s+(\d+)'
    }

    for key, pattern in stat_patterns.items():
        match = re.search(pattern, stdout)
        if match:
            stats[key] = int(match.group(1))

    # Extract optimization value (from summary section)
    # Pattern: "Optimization : N" or "Optimization : -N" or "Optimization : #sup/#inf"
    # Note: #maximize directives output negative values (clingo converts to #minimize{-X})
    opt_match = re.search(r'^Optimization\s+:\s+(-?\d+|#\w+)\s*$', stdout, re.MULTILINE)
    if opt_match:
        opt_str = opt_match.group(1)
        if opt_str == '#sup':
            stats['optimization_value'] = '#sup'
        elif opt_str == '#inf':
            stats['optimization_value'] = '#inf'
        else:
            stats['optimization_value'] = int(opt_str)

    return stats


def extract_timing(stdout: str) -> Dict:
    """Extract timing information from clingo output.

    Extracts detailed timing breakdown from clingo --stats output:
    - total: Total wall-clock time
    - cpu: Total CPU time
    - solving: Time spent in solving phase
    - grounding: Time spent in grounding phase (calculated as total - solving)
    - first_model: Time to first model
    - unsat: Time spent proving unsatisfiability

    Returns:
        Dict with timing values in seconds
    """
    timing = {}

    # Timing patterns from clingo --stats output
    # Example: "Time         : 0.097s (Solving: 0.03s 1st Model: 0.00s Unsat: 0.00s)"
    timing_patterns = {
        'total': r'Time\s+:\s+([\d.]+)s',
        'cpu': r'CPU Time\s+:\s+([\d.]+)s',
        'solving': r'Solving:\s+([\d.]+)s',
        'first_model': r'1st Model:\s+([\d.]+)s',
        'unsat': r'Unsat:\s+([\d.]+)s'
    }

    for key, pattern in timing_patterns.items():
        match = re.search(pattern, stdout)
        if match:
            timing[key] = float(match.group(1))

    # Calculate grounding time as total - solving
    # Grounding includes parsing, instantiation, and program transformation
    if 'total' in timing and 'solving' in timing:
        timing['grounding'] = round(timing['total'] - timing['solving'], 3)

    return timing


# ================================================================
# Convenience Function
# ================================================================

def execute_benchmark_run(command: List[str], timeout: int = 60) -> Dict:
    """Execute clingo command and return parsed results.

    Args:
        command: Clingo command as list of arguments
        timeout: Timeout in seconds (strict enforcement via SIGKILL)

    Returns:
        Dict with complete benchmark run results including grounding size
    """
    # Execute main clingo command
    stdout, stderr, elapsed, timed_out = run_clingo(command, timeout)

    result = parse_clingo_output(stdout, stderr, timed_out)
    result['elapsed_seconds'] = elapsed
    result['command'] = ' '.join(command)

    # Extract grounding size from statistics (rules count)
    # This is available from --stats=2 output, no subprocess needed
    grounding_size = result.get('statistics', {}).get('rules', -1)
    result['grounding_size'] = grounding_size if grounding_size > 0 else -1
    result['grounding_timeout'] = False  # No separate grounding, so no timeout
    result['grounding_error'] = (grounding_size < 0)

    # Explicitly clear large output buffers to free memory
    del stdout, stderr

    return result


# ================================================================
# Main (for testing)
# ================================================================

if __name__ == '__main__':
    import sys

    print("Improved Clingo Executor Test (Aggressive SIGKILL)")
    print("=" * 60)

    # Test with a simple command
    if len(sys.argv) > 1:
        # Run custom command
        command = sys.argv[1:]
        print(f"\nExecuting: {' '.join(command)}\n")

        result = execute_benchmark_run(command, timeout=10)

        print(f"Status: {result['status']}")
        print(f"Models: {result['models']}")
        print(f"Elapsed: {result['elapsed_seconds']:.3f}s")
        print(f"\nStatistics: {result['statistics']}")
        print(f"Timing: {result['timing']}")

        if result['first_answer_set']:
            print(f"\nFirst answer set:")
            print(f"  in: {result['first_answer_set']['in']}")
            print(f"  extension_cost: {result['first_answer_set']['extension_cost']}")
    else:
        print("\nUsage: python executor_improved.py <clingo command>")
        print("Example: python executor_improved.py clingo -n 0 WABA/core/base.lp ...")
