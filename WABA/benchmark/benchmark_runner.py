#!/usr/bin/env python3
"""
WABA Benchmark Runner v5.0 - Memory-Safe Edition

Executes clingo across framework × semiring × monoid × semantics combinations.

Two modes:
- enum: Enumerate all answer sets (memory-safe: --quiet mode, no model output, stats parsing)
- opt: Find optimal model (--outf=2 JSON output, only optimal model printed)

Features:
- Memory-safe enum mode: --quiet=1,1,2 prevents printing models, avoids OOM
- Chunked execution: recycle workers every N runs to prevent memory leaks
- Reproducible + resumable (run_id hashing, skip existing runs)
- Aggressive timeout handling with process group killing
- Full provenance tracking + detailed progress reporting
"""

import argparse
import gc
import hashlib
import json
import os
import platform
import subprocess
import sys
import time
from concurrent.futures import ProcessPoolExecutor, as_completed
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import List, Dict, Optional, Set, Tuple
import signal

# Add parent directory for imports
sys.path.insert(0, str(Path(__file__).parent))


@dataclass
class RunConfiguration:
    """Configuration for a single benchmark run."""
    instance_id: str
    instance_path: str
    semiring: str
    monoid: str  # Base monoid name (without _minimization/_maximization suffix)
    semantics: str
    mode: str  # 'enum' or 'opt'
    opt_direction: Optional[str]  # 'min' or 'max' (only for mode='opt')

    # Module paths (resolved from repo root)
    core_path: str
    semiring_path: str
    monoid_path: str  # Full path with direction suffix for opt mode
    filter_path: str
    semantics_path: str

    # Clingo configuration
    timeout_seconds: int
    clingo_args: List[str]  # Mode-dependent args (set by runner)

    def compute_run_id(self) -> str:
        """Compute stable hash for resumability."""
        # Include all factors that affect run identity
        components = [
            self.instance_id,
            self.semiring,
            self.monoid,
            self.semantics,
            self.mode,
            self.opt_direction if self.opt_direction else 'null',
            ' '.join(sorted(self.clingo_args))  # Sorted for stability
        ]
        hash_input = '|'.join(components).encode('utf-8')
        return hashlib.sha256(hash_input).hexdigest()[:16]  # 16-char hex


@dataclass
class RunResult:
    """Result of a single benchmark run."""
    # Run identity
    run_id: str
    instance_id: str
    semiring: str
    monoid: str
    semantics: str
    mode: str  # 'enum' or 'opt'
    opt_direction: Optional[str]  # 'min' or 'max' (only for mode='opt')

    # Result
    status: str  # 'optimal', 'sat', 'unsat', 'timeout', 'error', 'unknown'
    wall_time_ms: Optional[float]
    grounding_time_ms: Optional[float]
    solving_time_ms: Optional[float]

    # Solution quality
    # enum mode: optimum is None, models_found is count of answer sets
    # opt mode: optimum is cost vector if found, models_found is typically 1
    optimum: Optional[List[int]]  # Optimization values (if found in opt mode)
    models_found: int  # Count of models (enum mode) or 1 (opt mode if found)

    # Grounding stats (if available)
    atoms: Optional[int]
    rules: Optional[int]

    # Error details (if status == 'error')
    error_message: Optional[str]
    stderr_snippet: Optional[str]

    # Provenance
    clingo_version: str
    git_commit: str
    hostname: str
    os_version: str
    python_version: str
    clingo_command: str
    timestamp_start: str
    timestamp_end: str


def get_provenance() -> Dict[str, str]:
    """Collect provenance information for reproducibility."""
    # Get clingo version
    try:
        result = subprocess.run(['clingo', '--version'], capture_output=True, text=True, timeout=5)
        clingo_version = result.stdout.strip().split('\n')[0] if result.returncode == 0 else 'unknown'
    except Exception:
        clingo_version = 'unknown'

    # Get git commit
    try:
        result = subprocess.run(['git', 'rev-parse', '--short', 'HEAD'],
                              capture_output=True, text=True, timeout=5, cwd=Path(__file__).parent.parent)
        git_commit = result.stdout.strip() if result.returncode == 0 else 'unknown'
    except Exception:
        git_commit = 'unknown'

    return {
        'clingo_version': clingo_version,
        'git_commit': git_commit,
        'hostname': platform.node(),
        'os_version': platform.platform(),
        'python_version': platform.python_version()
    }


def load_existing_run_ids(results_file: Path) -> Set[str]:
    """Load run_ids from existing results.jsonl for resumability."""
    if not results_file.exists():
        return set()

    run_ids = set()
    with open(results_file, 'r') as f:
        for line in f:
            if line.strip():
                try:
                    entry = json.loads(line)
                    run_ids.add(entry['run_id'])
                except json.JSONDecodeError:
                    continue
    return run_ids


def aggressive_kill_process_group(process: subprocess.Popen, max_attempts: int = 10) -> Tuple[bool, Optional[str]]:
    """
    ULTRA-AGGRESSIVE process termination with immediate SIGKILL and multiple fallback strategies.

    Args:
        process: The subprocess.Popen object to kill
        max_attempts: Number of SIGKILL attempts per strategy (default: 10)

    Returns:
        (success: bool, diagnostic: Optional[str])
    """
    if platform.system() == 'Windows':
        # Windows: immediate repeated kills
        for i in range(max_attempts):
            try:
                process.kill()
                process.wait(timeout=0.1)
                return (True, None)
            except subprocess.TimeoutExpired:
                time.sleep(0.1)
            except ProcessLookupError:
                return (True, None)

        diagnostic = f"Windows kill failed after {max_attempts} attempts (pid={process.pid})"
        return (False, diagnostic)

    # Unix: Multi-strategy killing
    pid = process.pid

    # Check if already dead
    try:
        os.kill(pid, 0)  # Signal 0 = check if process exists
    except ProcessLookupError:
        return (True, None)  # Already dead
    except Exception:
        pass

    # Get process group ID
    try:
        pgid = os.getpgid(pid)
    except ProcessLookupError:
        return (True, None)
    except Exception:
        pgid = None  # Fallback if we can't get pgid

    # STRATEGY 1: Immediate SIGKILL to process group (skip SIGTERM - no mercy)
    if pgid is not None:
        for i in range(max_attempts):
            try:
                os.killpg(pgid, signal.SIGKILL)
            except ProcessLookupError:
                return (True, None)
            except Exception:
                pass  # Try other strategies

            time.sleep(0.05)  # Shorter wait

            # Check if dead
            try:
                os.getpgid(pid)
            except ProcessLookupError:
                return (True, None)

    # STRATEGY 2: Direct SIGKILL to main process (bypass process group)
    for i in range(max_attempts):
        try:
            os.kill(pid, signal.SIGKILL)
        except ProcessLookupError:
            return (True, None)
        except Exception:
            pass

        time.sleep(0.05)

        try:
            os.kill(pid, 0)
        except ProcessLookupError:
            return (True, None)

    # STRATEGY 3: Python's process.kill() as last resort
    for i in range(max_attempts):
        try:
            process.kill()
        except ProcessLookupError:
            return (True, None)
        except Exception:
            pass

        time.sleep(0.05)

        try:
            os.kill(pid, 0)
        except ProcessLookupError:
            return (True, None)

    # STRATEGY 4: Nuclear option - kill entire process group with different signals
    if pgid is not None:
        for sig in [signal.SIGKILL, signal.SIGTERM, signal.SIGKILL]:
            try:
                os.killpg(pgid, sig)
                time.sleep(0.1)
            except:
                pass

        try:
            os.getpgid(pid)
        except ProcessLookupError:
            return (True, None)

    # Failed all strategies
    diagnostic = f"ULTRA-KILL FAILED: Process {pid} (pgid={pgid}) survived {max_attempts * 4} kill attempts across 4 strategies"
    return (False, diagnostic)


def truncate_output(text: str, max_bytes: int = 8192) -> str:
    """Truncate text to last N bytes for memory efficiency."""
    if len(text) <= max_bytes:
        return text
    return "...[truncated]...\n" + text[-max_bytes:]


def parse_stats_output(output: str, max_parse_bytes: int = 16384) -> Tuple[Optional[int], Optional[float], Optional[float], Optional[int], Optional[int]]:
    """
    Parse clingo stats from output text (stdout or stderr).
    Only parses last max_parse_bytes to avoid processing huge model outputs.

    Returns: (models_found, grounding_time_ms, solving_time_ms, atoms, rules)
    """
    models_found = None
    grounding_time_ms = None
    solving_time_ms = None
    atoms = None
    rules = None

    # Only parse the tail (stats are at the end)
    if len(output) > max_parse_bytes:
        output = output[-max_parse_bytes:]

    for line in output.split('\n'):
        line = line.strip()
        # Models line: "Models       : 42"
        if line.startswith('Models'):
            try:
                models_found = int(line.split(':')[1].strip().split()[0])
            except (ValueError, IndexError):
                pass
        # Time line: "Time         : 1.234s (Solving: 0.567s 1st Model: 0.123s Unsat: 0.000s)"
        elif line.startswith('Time'):
            try:
                # Extract solving time
                if 'Solving:' in line:
                    solving_part = line.split('Solving:')[1].split('s')[0].strip()
                    solving_time_ms = float(solving_part) * 1000
            except (ValueError, IndexError):
                pass
        # CPU Time line: "CPU Time     : 1.234s (Solving: 0.567s 1st Model: 0.123s)"
        elif line.startswith('CPU Time'):
            try:
                # Extract grounding time from total - solving
                # (This is approximate; real grounding time is printed separately in some versions)
                pass
            except (ValueError, IndexError):
                pass
        # Atoms line: "Atoms    : 12345"
        elif line.startswith('Atoms'):
            try:
                atoms = int(line.split(':')[1].strip().split()[0])
            except (ValueError, IndexError):
                pass
        # Rules line: "Rules    : 67890 (Original: 456)"
        elif line.startswith('Rules'):
            try:
                rules = int(line.split(':')[1].strip().split()[0])
            except (ValueError, IndexError):
                pass

    return models_found, grounding_time_ms, solving_time_ms, atoms, rules


def execute_single_run(config: RunConfiguration, provenance: Dict[str, str]) -> RunResult:
    """Execute a single clingo run with timeout and memory-safe output handling."""
    run_id = config.compute_run_id()
    timestamp_start = time.strftime('%Y-%m-%dT%H:%M:%S')

    # Build clingo command
    cmd = ['clingo']

    # MODE-DEPENDENT OUTPUT CONFIGURATION
    # ENUM MODE: Suppress model printing to avoid OOM (models can be huge)
    # OPT MODE: Use JSON output (only optimal models are printed, small output)
    if config.mode == 'enum':
        # --quiet=1,1,2 prevents printing models even when enumerating
        # --stats=2 enables detailed statistics output
        cmd.extend(['--stats=2', '--quiet=1,1,2'])
    else:  # opt mode
        # JSON output for parsing optimal model
        cmd.extend(['--outf=2', '--stats=2'])

    # Add timeout (clingo's internal timeout)
    cmd.append(f'--time-limit={config.timeout_seconds}')

    # Add user-specified args
    cmd.extend(config.clingo_args)

    # Add module files in correct order
    modules = [
        config.core_path,
        config.semiring_path,
        config.monoid_path,
        config.filter_path,
        config.semantics_path
    ]

    # Add instance file
    modules.append(config.instance_path)

    cmd.extend(modules)

    # Record command for provenance
    clingo_command = ' '.join(cmd)

    # Execute with timeout (hard kill after timeout + grace period)
    wall_start = time.time()
    timeout_with_grace = config.timeout_seconds + 5  # 5s grace for cleanup

    try:
        # MEMORY-SAFE SUBPROCESS HANDLING
        # Both modes capture stdout and stderr, but handle differently
        # Start process in new process group for killability
        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            preexec_fn=os.setsid  # Create new process group
        )

        try:
            stdout, stderr = process.communicate(timeout=timeout_with_grace)
            returncode = process.returncode
            wall_time_ms = (time.time() - wall_start) * 1000

        except subprocess.TimeoutExpired:
            # Aggressive kill with repeated SIGKILL attempts
            kill_success, kill_diagnostic = aggressive_kill_process_group(process)

            # Collect remaining output (may be partial)
            try:
                stdout, stderr = process.communicate(timeout=1)
            except subprocess.TimeoutExpired:
                # Still hanging, force communicate
                process.kill()
                stdout, stderr = process.communicate()

            returncode = -1
            wall_time_ms = (time.time() - wall_start) * 1000

            # Determine status based on kill success
            if kill_success:
                status = 'timeout'
                error_msg = None
                stderr_snippet = truncate_output(stderr) if stderr else None
            else:
                # Kill failed - record special status
                status = 'timeout_kill_failed'
                error_msg = kill_diagnostic
                stderr_snippet = truncate_output(stderr) if stderr else None

            # Free memory immediately
            stdout = None
            stderr = None
            gc.collect()

            # Timeout result
            timestamp_end = time.strftime('%Y-%m-%dT%H:%M:%S')
            return RunResult(
                run_id=run_id,
                instance_id=config.instance_id,
                semiring=config.semiring,
                monoid=config.monoid,
                semantics=config.semantics,
                mode=config.mode,
                opt_direction=config.opt_direction,
                status=status,
                wall_time_ms=wall_time_ms,
                grounding_time_ms=None,
                solving_time_ms=None,
                optimum=None,
                models_found=0,
                atoms=None,
                rules=None,
                error_message=error_msg,
                stderr_snippet=stderr_snippet,
                **provenance,
                clingo_command=clingo_command,
                timestamp_start=timestamp_start,
                timestamp_end=timestamp_end
            )

    except Exception as e:
        # Process error
        timestamp_end = time.strftime('%Y-%m-%dT%H:%M:%S')
        wall_time_ms = (time.time() - wall_start) * 1000 if 'wall_start' in locals() else None

        # Free memory
        gc.collect()

        return RunResult(
            run_id=run_id,
            instance_id=config.instance_id,
            semiring=config.semiring,
            monoid=config.monoid,
            semantics=config.semantics,
            mode=config.mode,
            opt_direction=config.opt_direction,
            status='error',
            wall_time_ms=wall_time_ms,
            grounding_time_ms=None,
            solving_time_ms=None,
            optimum=None,
            models_found=0,
            atoms=None,
            rules=None,
            error_message=str(e),
            stderr_snippet=None,
            **provenance,
            clingo_command=clingo_command,
            timestamp_start=timestamp_start,
            timestamp_end=timestamp_end
        )

    # Parse output based on mode
    timestamp_end = time.strftime('%Y-%m-%dT%H:%M:%S')

    if returncode != 0 and returncode != 10 and returncode != 20 and returncode != 30:
        # Clingo error (not SAT/UNSAT/OPTIMAL)
        # Free memory
        stdout = None
        stderr_tail = truncate_output(stderr) if stderr else None
        stderr = None
        gc.collect()

        return RunResult(
            run_id=run_id,
            instance_id=config.instance_id,
            semiring=config.semiring,
            monoid=config.monoid,
            semantics=config.semantics,
            mode=config.mode,
            opt_direction=config.opt_direction,
            status='error',
            wall_time_ms=wall_time_ms,
            grounding_time_ms=None,
            solving_time_ms=None,
            optimum=None,
            models_found=0,
            atoms=None,
            rules=None,
            error_message=f'clingo returncode {returncode}',
            stderr_snippet=stderr_tail,
            **provenance,
            clingo_command=clingo_command,
            timestamp_start=timestamp_start,
            timestamp_end=timestamp_end
        )

    # MODE-DEPENDENT PARSING
    if config.mode == 'enum':
        # ENUM MODE: Parse stats from stdout (--quiet mode output still goes to stdout)
        try:
            models_found_parsed, grounding_time_ms, solving_time_ms, atoms, rules = parse_stats_output(stdout)

            # Determine status from returncode
            # Note: Clingo returns 30 (OPTIMUM) even with --opt-mode=ignore if weak constraints present
            if returncode == 10 or returncode == 30:  # SAT or OPTIMUM (treat as SAT in enum mode)
                status = 'sat'
            elif returncode == 20:
                status = 'unsat'
            else:
                status = 'unknown'

            # Use parsed model count or default to 0
            models_found = models_found_parsed if models_found_parsed is not None else 0

            # No optimum in enum mode
            optimum = None

            # Free memory
            stdout = None
            stderr = None
            gc.collect()

            return RunResult(
                run_id=run_id,
                instance_id=config.instance_id,
                semiring=config.semiring,
                monoid=config.monoid,
                semantics=config.semantics,
                mode=config.mode,
                opt_direction=config.opt_direction,
                status=status,
                wall_time_ms=wall_time_ms,
                grounding_time_ms=grounding_time_ms,
                solving_time_ms=solving_time_ms,
                optimum=optimum,
                models_found=models_found,
                atoms=atoms,
                rules=rules,
                error_message=None,
                stderr_snippet=None,
                **provenance,
                clingo_command=clingo_command,
                timestamp_start=timestamp_start,
                timestamp_end=timestamp_end
            )

        except Exception as e:
            # Stats parsing failed - return error with truncated stderr
            stderr_tail = truncate_output(stderr) if stderr else None
            stdout = None
            stderr = None
            gc.collect()

            return RunResult(
                run_id=run_id,
                instance_id=config.instance_id,
                semiring=config.semiring,
                monoid=config.monoid,
                semantics=config.semantics,
                mode=config.mode,
                opt_direction=config.opt_direction,
                status='error',
                wall_time_ms=wall_time_ms,
                grounding_time_ms=None,
                solving_time_ms=None,
                optimum=None,
                models_found=0,
                atoms=None,
                rules=None,
                error_message=f'Stats parsing error: {e}',
                stderr_snippet=stderr_tail,
                **provenance,
                clingo_command=clingo_command,
                timestamp_start=timestamp_start,
                timestamp_end=timestamp_end
            )

    else:
        # OPT MODE: Parse JSON from stdout
        try:
            output_data = json.loads(stdout)
        except json.JSONDecodeError as e:
            # JSON parse error - truncate and free
            stdout_tail = truncate_output(stdout) if stdout else None
            stdout = None
            stderr = None
            gc.collect()

            return RunResult(
                run_id=run_id,
                instance_id=config.instance_id,
                semiring=config.semiring,
                monoid=config.monoid,
                semantics=config.semantics,
                mode=config.mode,
                opt_direction=config.opt_direction,
                status='error',
                wall_time_ms=wall_time_ms,
                grounding_time_ms=None,
                solving_time_ms=None,
                optimum=None,
                models_found=0,
                atoms=None,
                rules=None,
                error_message=f'JSON parse error: {e}',
                stderr_snippet=stdout_tail,
                **provenance,
                clingo_command=clingo_command,
                timestamp_start=timestamp_start,
                timestamp_end=timestamp_end
            )

        # Extract result fields
        call_data = output_data.get('Call', [{}])[0] if 'Call' in output_data else {}

        # Status
        result_str = output_data.get('Result', 'UNKNOWN')
        if result_str == 'SATISFIABLE':
            status = 'sat'
        elif result_str == 'UNSATISFIABLE':
            status = 'unsat'
        elif result_str == 'OPTIMUM FOUND':
            status = 'optimal'
        else:
            status = 'unknown'

        # Models found
        models_found = len(call_data.get('Witnesses', []))

        # Optimum (if optimization)
        optimum = None
        if models_found > 0:
            last_witness = call_data.get('Witnesses', [])[-1]
            if 'Costs' in last_witness:
                optimum = last_witness['Costs']

        # Timing (from stats if available)
        stats = output_data.get('Stats', {})
        times = stats.get('Times', {})
        grounding_time_ms = times.get('Grounding', 0.0) * 1000 if 'Grounding' in times else None
        solving_time_ms = times.get('Solving', 0.0) * 1000 if 'Solving' in times else None

        # Grounding stats
        problem_stats = stats.get('Problem', {})
        atoms = problem_stats.get('Atoms', None)
        rules = problem_stats.get('Rules', {}).get('Original', None) if 'Rules' in problem_stats else None

        # Free large output strings from memory
        stdout = None
        stderr = None
        gc.collect()

        return RunResult(
            run_id=run_id,
            instance_id=config.instance_id,
            semiring=config.semiring,
            monoid=config.monoid,
            semantics=config.semantics,
            mode=config.mode,
            opt_direction=config.opt_direction,
            status=status,
            wall_time_ms=wall_time_ms,
            grounding_time_ms=grounding_time_ms,
            solving_time_ms=solving_time_ms,
            optimum=optimum,
            models_found=models_found,
            atoms=atoms,
            rules=rules,
            error_message=None,
            stderr_snippet=None,
            **provenance,
            clingo_command=clingo_command,
            timestamp_start=timestamp_start,
            timestamp_end=timestamp_end
        )


def generate_run_configurations(
    plan_file: Path,
    frameworks_dir: Path,
    semirings: List[str],
    monoids: List[str],
    semantics_list: List[str],
    mode: str,
    opt_direction: Optional[str],
    repo_root: Path,
    timeout_seconds: int
) -> List[RunConfiguration]:
    """Generate all run configurations from plan and module matrix."""

    configurations = []

    # Set clingo args based on mode
    if mode == 'enum':
        clingo_args = ['-n', '0', '--opt-mode=ignore']
    elif mode == 'opt':
        clingo_args = ['-n', '0', '--opt-mode=opt']
    else:
        raise ValueError(f"Invalid mode: {mode}. Must be 'enum' or 'opt'")

    # Validate opt_direction for opt mode
    if mode == 'opt' and opt_direction not in ['min', 'max']:
        raise ValueError(f"opt mode requires --opt-direction to be 'min' or 'max', got: {opt_direction}")
    if mode == 'enum' and opt_direction is not None:
        print(f"⚠ Warning: --opt-direction ignored in enum mode", file=sys.stderr)
        opt_direction = None

    # Load plan
    with open(plan_file, 'r') as f:
        plan_entries = [json.loads(line) for line in f if line.strip()]

    for entry in plan_entries:
        instance_id = entry['instance_id']
        topology = entry['topology']

        # Locate instance file
        instance_path = frameworks_dir / topology / f"{instance_id}.lp"
        if not instance_path.exists():
            print(f"⚠ Warning: Instance file not found: {instance_path}", file=sys.stderr)
            continue

        # Generate configurations for each module combination
        for semiring in semirings:
            for monoid in monoids:
                for sem in semantics_list:
                    # Determine monoid file path based on mode and direction
                    if mode == 'enum':
                        # For enum mode, use base monoid name (without suffix)
                        # Assuming enum uses plain monoid files like max.lp, sum.lp
                        monoid_file = f'{monoid}.lp'
                    elif mode == 'opt':
                        # For opt mode, use direction-based monoid variant
                        if opt_direction == 'min':
                            monoid_file = f'{monoid}_minimization.lp'
                        else:  # max
                            monoid_file = f'{monoid}_maximization.lp'

                    monoid_path = str(repo_root / 'monoid' / monoid_file)

                    config = RunConfiguration(
                        instance_id=instance_id,
                        instance_path=str(instance_path),
                        semiring=semiring,
                        monoid=monoid,
                        semantics=sem,
                        mode=mode,
                        opt_direction=opt_direction,
                        core_path=str(repo_root / 'core' / 'base.lp'),
                        semiring_path=str(repo_root / 'semiring' / f'{semiring}.lp'),
                        monoid_path=monoid_path,
                        filter_path=str(repo_root / 'filter' / 'standard.lp'),
                        semantics_path=str(repo_root / 'semantics' / f'{sem}.lp'),
                        timeout_seconds=timeout_seconds,
                        clingo_args=clingo_args
                    )

                    configurations.append(config)

    return configurations


def run_benchmark(
    configurations: List[RunConfiguration],
    results_file: Path,
    provenance: Dict[str, str],
    max_workers: int,
    force: bool,
    chunk_size: int = 200
) -> None:
    """Execute benchmark runs with parallelism and resumability.

    Args:
        chunk_size: Recycle worker pool every N runs to prevent memory leaks (0=disable).
    """

    # Load existing run_ids for resumability
    existing_run_ids = set() if force else load_existing_run_ids(results_file)

    # Filter configurations (skip existing unless --force)
    configs_to_run = []
    skipped_count = 0

    for config in configurations:
        run_id = config.compute_run_id()
        if run_id in existing_run_ids:
            skipped_count += 1
        else:
            configs_to_run.append(config)

    print(f"Total configurations: {len(configurations)}")
    print(f"Already completed: {skipped_count}")
    print(f"To run: {len(configs_to_run)}")

    if len(configs_to_run) == 0:
        print("✓ All runs already completed (use --force to re-run)")
        return

    # Ensure results directory exists
    results_file.parent.mkdir(parents=True, exist_ok=True)

    # Run in parallel with progress tracking and worker recycling
    completed = 0
    errors = 0
    timeouts = 0
    timeout_kill_failed = 0
    sat_count = 0
    unsat_count = 0
    optimal_count = 0

    # Worker recycling: chunk configs and recreate executor periodically
    if chunk_size > 0 and len(configs_to_run) > chunk_size:
        # Chunked execution with worker recycling
        chunks = [configs_to_run[i:i + chunk_size]
                  for i in range(0, len(configs_to_run), chunk_size)]
        print(f"Memory-safe chunked execution: {len(chunks)} chunks of ~{chunk_size} runs each")
        print(f"(Prevents OOM by recycling workers periodically)\n")
    else:
        # Single chunk (no recycling)
        chunks = [configs_to_run]

    for chunk_idx, chunk in enumerate(chunks):
        if len(chunks) > 1:
            print(f"--- Chunk {chunk_idx + 1}/{len(chunks)} ({len(chunk)} runs) ---")

        with ProcessPoolExecutor(max_workers=max_workers) as executor:
            # Submit all tasks in chunk
            futures = {executor.submit(execute_single_run, config, provenance): config
                      for config in chunk}

            # Process results as they complete
            for future in as_completed(futures):
                config = futures[future]

                try:
                    result = future.result()

                    # Write result to file (append mode)
                    with open(results_file, 'a') as f:
                        f.write(json.dumps(asdict(result)) + '\n')

                    completed += 1

                    # Track status
                    if result.status == 'error':
                        errors += 1
                        print(f"✗ [{completed}/{len(configs_to_run)}] ERROR: {result.instance_id} "
                              f"({result.semiring}/{result.monoid}/{result.semantics} {result.mode})")
                    elif result.status == 'timeout':
                        timeouts += 1
                        print(f"⏱ [{completed}/{len(configs_to_run)}] TIMEOUT: {result.instance_id} "
                              f"({result.semiring}/{result.monoid}/{result.semantics} {result.mode})")
                    elif result.status == 'timeout_kill_failed':
                        timeout_kill_failed += 1
                        timeouts += 1
                        print(f"⚠ [{completed}/{len(configs_to_run)}] TIMEOUT (KILL FAILED - OOM?): {result.instance_id} "
                              f"({result.semiring}/{result.monoid}/{result.semantics} {result.mode}) - {result.error_message}")
                    elif result.status == 'sat':
                        sat_count += 1
                        print(f"✓ [{completed}/{len(configs_to_run)}] SAT: {result.instance_id} "
                              f"({result.semiring}/{result.monoid}/{result.semantics} {result.mode}) "
                              f"in {result.wall_time_ms:.1f}ms ({result.models_found} models)")
                    elif result.status == 'optimal':
                        optimal_count += 1
                        print(f"✓ [{completed}/{len(configs_to_run)}] OPTIMAL: {result.instance_id} "
                              f"({result.semiring}/{result.monoid}/{result.semantics} {result.mode}) "
                              f"in {result.wall_time_ms:.1f}ms (cost={result.optimum})")
                    elif result.status == 'unsat':
                        unsat_count += 1
                        print(f"✓ [{completed}/{len(configs_to_run)}] UNSAT: {result.instance_id} "
                              f"({result.semiring}/{result.monoid}/{result.semantics} {result.mode}) "
                              f"in {result.wall_time_ms:.1f}ms")
                    else:
                        print(f"? [{completed}/{len(configs_to_run)}] {result.status.upper()}: {result.instance_id} "
                              f"({result.semiring}/{result.monoid}/{result.semantics} {result.mode}) "
                              f"in {result.wall_time_ms:.1f}ms")

                    # Periodic progress summary (every 100 runs)
                    if completed % 100 == 0:
                        success_count = sat_count + unsat_count + optimal_count
                        print(f"\n--- Progress: {completed}/{len(configs_to_run)} ({completed/len(configs_to_run)*100:.1f}%) ---")
                        print(f"  ✓ Success: {success_count} (SAT:{sat_count} UNSAT:{unsat_count} OPT:{optimal_count})")
                        print(f"  ⏱ Timeout: {timeouts}" + (f" (OOM/kill-fail: {timeout_kill_failed})" if timeout_kill_failed > 0 else ""))
                        print(f"  ✗ Error: {errors}")
                        print()

                    # Periodic GC in parent process (every 50 runs)
                    if completed % 50 == 0:
                        gc.collect()

                except Exception as e:
                    completed += 1
                    errors += 1
                    print(f"✗ [{completed}/{len(configs_to_run)}] EXCEPTION: {config.instance_id}: {e}")

        # After chunk completes, aggressive GC before starting new worker pool
        if len(chunks) > 1 and chunk_idx < len(chunks) - 1:
            print(f"\n--- Recycling workers (completed {completed}/{len(configs_to_run)}) ---")
            print(f"  Triggering garbage collection and restarting worker pool...")
            gc.collect()
            print()

    # Final summary
    success_count = sat_count + unsat_count + optimal_count
    print(f"\n{'='*60}")
    print(f"Benchmark complete!")
    print(f"{'='*60}")
    print(f"Total runs: {completed}")
    print(f"\n✓ Success: {success_count} ({success_count/completed*100:.1f}%)")
    print(f"  - SAT: {sat_count}")
    print(f"  - UNSAT: {unsat_count}")
    print(f"  - OPTIMAL: {optimal_count}")
    print(f"\n⏱ Timeout: {timeouts} ({timeouts/completed*100:.1f}%)")
    if timeout_kill_failed > 0:
        print(f"  ⚠ Kill-failed (likely OOM): {timeout_kill_failed} ({timeout_kill_failed/completed*100:.1f}%)")
    print(f"\n✗ Error: {errors} ({errors/completed*100:.1f}%)")
    print(f"\nResults written to: {results_file}")
    print(f"{'='*60}")


def main():
    parser = argparse.ArgumentParser(
        description='WABA Benchmark Runner v4.0 - Execute clingo across framework×module combinations',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Enum mode (enumerate all answer sets)
  python3 benchmark_runner.py --plan plan.jsonl --frameworks-dir frameworks \\
      --semirings godel tropical --monoids max sum --mode enum

  # Opt mode with minimization
  python3 benchmark_runner.py --plan plan.jsonl --frameworks-dir frameworks \\
      --semirings godel tropical --monoids max sum --mode opt --opt-direction min

  # Opt mode with maximization
  python3 benchmark_runner.py --plan plan.jsonl --frameworks-dir frameworks \\
      --semirings godel tropical --monoids max sum --mode opt --opt-direction max
        """
    )

    # Required inputs
    parser.add_argument('--plan', type=Path, required=True,
                       help='Path to plan.jsonl (from planner.py)')
    parser.add_argument('--frameworks-dir', type=Path, required=True,
                       help='Directory containing generated frameworks (e.g., frameworks/)')

    # Module matrix
    parser.add_argument('--semirings', nargs='+', required=True,
                       help='Semiring modules (e.g., godel tropical lukasiewicz)')
    parser.add_argument('--monoids', nargs='+', required=True,
                       help='Monoid base names (e.g., max sum min count)')
    parser.add_argument('--semantics', nargs='+', default=['stable'],
                       help='Semantics modules (default: stable)')

    # Runner mode
    parser.add_argument('--mode', type=str, required=True, choices=['enum', 'opt'],
                       help='Runner mode: enum (enumerate all) or opt (find optimal)')
    parser.add_argument('--opt-direction', type=str, choices=['min', 'max'],
                       help='Optimization direction (required for --mode opt): min or max')

    # Execution config
    parser.add_argument('--timeout-seconds', type=int, default=60,
                       help='Timeout per run in seconds (default: 60)')
    parser.add_argument('--max-workers', type=int, default=4,
                       help='Number of parallel workers (default: 4)')
    parser.add_argument('--chunk-size', type=int, default=200,
                       help='Execute runs in chunks of N (recycle workers between chunks to prevent OOM, default: 200, 0=disable)')

    # Resumability
    parser.add_argument('--output', type=Path, default=Path('results/results.jsonl'),
                       help='Output file for results (default: results/results.jsonl)')
    parser.add_argument('--force', action='store_true',
                       help='Re-run all configurations (ignore existing results)')

    # Module paths
    parser.add_argument('--repo-root', type=Path, default=Path(__file__).parent.parent,
                       help='Repository root (default: ../WABA from benchmark/)')

    args = parser.parse_args()

    # Validate mode and opt_direction
    if args.mode == 'opt' and args.opt_direction is None:
        parser.error("--mode opt requires --opt-direction {min,max}")
    if args.mode == 'enum' and args.opt_direction is not None:
        print("⚠ Warning: --opt-direction ignored in enum mode", file=sys.stderr)

    # Validate inputs
    if not args.plan.exists():
        print(f"Error: Plan file not found: {args.plan}", file=sys.stderr)
        return 1

    if not args.frameworks_dir.exists():
        print(f"Error: Frameworks directory not found: {args.frameworks_dir}", file=sys.stderr)
        return 1

    # Get provenance
    provenance = get_provenance()
    print("Provenance:")
    for key, value in provenance.items():
        print(f"  {key}: {value}")
    print()

    # Generate run configurations
    print(f"Generating run configurations (mode={args.mode}" +
          (f", opt_direction={args.opt_direction}" if args.mode == 'opt' else "") + ")...")
    configurations = generate_run_configurations(
        plan_file=args.plan,
        frameworks_dir=args.frameworks_dir,
        semirings=args.semirings,
        monoids=args.monoids,
        semantics_list=args.semantics,
        mode=args.mode,
        opt_direction=args.opt_direction,
        repo_root=args.repo_root,
        timeout_seconds=args.timeout_seconds
    )

    # Run benchmark
    run_benchmark(
        configurations=configurations,
        results_file=args.output,
        provenance=provenance,
        max_workers=args.max_workers,
        force=args.force,
        chunk_size=args.chunk_size
    )

    return 0


if __name__ == '__main__':
    sys.exit(main())
