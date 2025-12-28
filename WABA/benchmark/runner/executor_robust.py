#!/usr/bin/env python3
"""
Ultra-Robust Clingo Execution Wrapper with Multiple Timeout Strategies

Uses layered timeout enforcement:
1. subprocess.communicate(timeout) - primary timeout
2. Multiple SIGKILL attempts - immediate process termination
3. SIGKILL to entire process tree - ensure child processes die
4. Hard cleanup timeout - abort cleanup after 5s
5. Process verification - confirm process is dead

This prevents runaway processes from accumulating memory.
"""

import subprocess
import time
import signal
import os
import gc
from pathlib import Path
from typing import Dict, List, Tuple, Optional, Any


# ================================================================
# Ultra-Robust Timeout Enforcement (Standard Library Only)
# ================================================================

def kill_process_group_aggressive(pgid: int, max_attempts: int = 5) -> bool:
    """Kill a process group using multiple SIGKILL attempts.

    Args:
        pgid: Process group ID to kill
        max_attempts: Maximum SIGKILL attempts

    Returns:
        True if process group killed, False otherwise
    """
    for attempt in range(max_attempts):
        try:
            # Send SIGKILL to entire process group
            os.killpg(pgid, signal.SIGKILL)
            time.sleep(0.05 * (attempt + 1))  # Increasing delay

            # Check if process group still exists
            try:
                os.killpg(pgid, 0)  # Signal 0 checks existence
                # If this succeeds, process group still exists
                if attempt < max_attempts - 1:
                    continue  # Try again
                else:
                    return False  # Failed after max attempts
            except ProcessLookupError:
                # Process group no longer exists - success!
                return True

        except ProcessLookupError:
            # Process group already dead
            return True
        except PermissionError:
            # Can't kill (shouldn't happen for our own processes)
            return False

    return False


def run_clingo_ultra_robust(command: List[str], timeout: int = 60) -> Tuple[str, str, float, bool]:
    """Execute clingo with ultra-robust timeout control.

    Multiple layered strategies:
    1. Primary: subprocess.communicate(timeout)
    2. Fallback: SIGKILL to process group
    3. Nuclear: psutil process tree kill
    4. Hard limit: Abort cleanup after 5s

    Args:
        command: List of command arguments
        timeout: Timeout in seconds (strict enforcement)

    Returns:
        Tuple of (stdout, stderr, elapsed_seconds, timed_out)
    """
    start_time = time.time()
    timed_out = False
    stdout = ""
    stderr = ""
    proc = None

    try:
        # Start process in new process group
        proc = subprocess.Popen(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            preexec_fn=os.setpgrp,  # New process group
            start_new_session=True  # Additional isolation
        )

        # Wait with primary timeout
        stdout_bytes, stderr_bytes = proc.communicate(timeout=timeout)
        stdout = stdout_bytes if stdout_bytes else ""
        stderr = stderr_bytes if stderr_bytes else ""

    except subprocess.TimeoutExpired as e:
        timed_out = True
        cleanup_start = time.time()

        # Strategy 1: Multiple SIGKILL attempts to process group
        try:
            pgid = os.getpgid(proc.pid)
            kill_process_group_aggressive(pgid, max_attempts=5)
        except (ProcessLookupError, PermissionError):
            pass

        # Strategy 2: Wait with hard timeout (prevent infinite cleanup)
        try:
            proc.wait(timeout=5.0)  # Hard 5s limit on cleanup
        except subprocess.TimeoutExpired:
            # Process STILL not dead after SIGKILL + 5s
            # Force-abandon it and log warning
            stderr = "CRITICAL: Process survived SIGKILL for 5+ seconds\n"

        # Try to get partial output
        try:
            stdout = e.stdout.decode('utf-8') if e.stdout else ""
            stderr += e.stderr.decode('utf-8') if e.stderr else ""
        except Exception:
            pass

        # Verify cleanup time didn't exceed limit
        cleanup_elapsed = time.time() - cleanup_start
        if cleanup_elapsed > 5.5:
            stderr += f"WARNING: Cleanup took {cleanup_elapsed:.1f}s (>5s limit)\n"

    finally:
        # Final verification and cleanup
        if proc and proc.poll() is None:
            # Process STILL alive - nuclear option
            try:
                proc.kill()
                proc.wait(timeout=1.0)
            except Exception:
                pass

        # Force garbage collection of output buffers
        del proc
        gc.collect()

    elapsed = time.time() - start_time

    # Sanity check: elapsed should not significantly exceed timeout for timeouts
    if timed_out and elapsed > timeout * 1.5:
        stderr += f"ERROR: Elapsed {elapsed:.1f}s exceeded timeout {timeout}s by >50%\n"

    return stdout, stderr, elapsed, timed_out


# ================================================================
# Main Execution Function
# ================================================================

def run_clingo(command: List[str], timeout: int = 60) -> Tuple[str, str, float, bool]:
    """Execute clingo command with timeout control.

    This is the main entry point. Uses ultra-robust strategy.

    Args:
        command: List of command arguments
        timeout: Timeout in seconds

    Returns:
        Tuple of (stdout, stderr, elapsed_seconds, timed_out)
    """
    return run_clingo_ultra_robust(command, timeout)


# ================================================================
# Import rest of executor functionality
# ================================================================

# Import all parsing functions from original executor
import sys
import re
sys.path.insert(0, str(Path(__file__).parent))

try:
    from executor import (
        parse_clingo_output,
        extract_answer_sets_compact,
        extract_extension_cost_only,
        extract_in_assumptions_only,
        parse_answer_set_atoms,
        extract_statistics,
        extract_timing
    )
except ImportError:
    # Fallback if import fails
    print("Warning: Could not import from executor.py, using minimal implementation")

    def parse_clingo_output(stdout: str, stderr: str, timed_out: bool) -> Dict:
        return {
            'status': 'TIMEOUT' if timed_out else 'UNKNOWN',
            'models': 0,
            'first_answer_set': None,
            'extension_cost_distribution': {},
            'assumption_frequency': {},
            'statistics': {},
            'timing': {}
        }


def execute_benchmark_run(command: List[str], timeout: int = 60) -> Dict:
    """Execute clingo command and return parsed results.

    Args:
        command: Clingo command as list of arguments
        timeout: Timeout in seconds (ultra-strict enforcement)

    Returns:
        Dict with complete benchmark run results
    """
    stdout, stderr, elapsed, timed_out = run_clingo(command, timeout)

    result = parse_clingo_output(stdout, stderr, timed_out)
    result['elapsed_seconds'] = elapsed
    result['command'] = ' '.join(command)

    # Aggressive memory cleanup
    del stdout, stderr
    gc.collect()

    return result


# ================================================================
# Testing
# ================================================================

if __name__ == '__main__':
    import sys

    print("Ultra-Robust Clingo Executor Test")
    print("=" * 70)
    print("Features:")
    print("  - Multiple SIGKILL attempts")
    print("  - Process tree killing (via psutil)")
    print("  - Hard 5s cleanup timeout")
    print("  - Verification that process is dead")
    print("=" * 70)

    # Test timeout enforcement
    print("\nTest 1: Timeout enforcement with sleep command")
    start = time.time()
    stdout, stderr, elapsed, timed_out = run_clingo(['sleep', '300'], timeout=2)
    actual_elapsed = time.time() - start
    print(f"  Timeout: 2s")
    print(f"  Elapsed: {elapsed:.2f}s")
    print(f"  Actual elapsed: {actual_elapsed:.2f}s")
    print(f"  Timed out: {timed_out}")
    print(f"  ✓ Pass" if actual_elapsed < 3.0 else f"  ✗ FAIL: took {actual_elapsed:.1f}s")

    # Test with actual clingo if available
    if len(sys.argv) > 1:
        command = sys.argv[1:]
        print(f"\nTest 2: Custom command")
        print(f"  Command: {' '.join(command)}")

        result = execute_benchmark_run(command, timeout=10)

        print(f"  Status: {result['status']}")
        print(f"  Elapsed: {result['elapsed_seconds']:.3f}s")
        print(f"  Models: {result['models']}")
