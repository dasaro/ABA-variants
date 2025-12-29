"""
Utility functions for WABA benchmark suite.

This module provides reproducibility utilities (deterministic seed derivation),
metadata tracking, and git integration.
"""

import hashlib
import json
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple


# ====================
# SEED DERIVATION
# ====================

def derive_seed(master_seed: int, *components: str) -> int:
    """
    Derive a deterministic seed from a master seed and components.

    Uses SHA256 hashing with length-prefixed encoding to ensure:
    - Deterministic: same inputs → same output
    - Independent: different components → uncorrelated seeds
    - Unambiguous: ("ab","c") ≠ ("a","bc") due to length prefixing
    - Uniform: output space evenly distributed

    Args:
        master_seed: Master seed (typically from CLI --seed flag)
        *components: Variable-length tuple of strings to hash
                     (e.g., topology, config_id, replicate)

    Returns:
        Derived seed as 64-bit unsigned integer (0 to 2^64-1)

    Examples:
        >>> derive_seed(42, "linear", "config_0")
        12345678901234567890  # Example uint64
        >>> derive_seed(42, "ab", "c")  # Different from ("a", "bc")
        98765432109876543210
        >>> derive_seed(42, "a", "bc")
        11223344556677889900
    """
    h = hashlib.sha256()
    # Hash master seed with separator
    h.update(str(master_seed).encode('utf-8'))
    h.update(b'\x1f')  # ASCII Unit Separator

    # Hash each component with length prefix to prevent ambiguity
    for component in components:
        component_bytes = str(component).encode('utf-8')
        # Length prefix (4 bytes, big-endian) prevents collision
        h.update(len(component_bytes).to_bytes(4, byteorder='big'))
        h.update(component_bytes)
        h.update(b'\x1f')  # Separator between components

    # Take first 8 bytes as uint64 (0 to 2^64-1)
    return int.from_bytes(h.digest()[:8], byteorder='big')


def create_rng(seed: int):
    """
    Create a Random Number Generator with explicit seed.

    Returns a random.Random object (not the global random module)
    to avoid side effects and ensure explicit seeding.

    Args:
        seed: Seed value

    Returns:
        random.Random instance
    """
    import random
    rng = random.Random(seed)
    return rng


# ====================
# GIT INTEGRATION
# ====================

def get_git_commit_hash() -> str:
    """
    Get current git commit hash for provenance tracking.

    Returns:
        Short commit hash (8 chars) or "unknown" if not in git repo
    """
    try:
        result = subprocess.run(
            ['git', 'rev-parse', '--short=8', 'HEAD'],
            capture_output=True,
            text=True,
            timeout=2,
            check=True
        )
        return result.stdout.strip()
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired, FileNotFoundError):
        return "unknown"


def get_git_status() -> Dict[str, Any]:
    """
    Get git repository status for provenance.

    Returns:
        Dict with keys: commit_hash, branch, dirty (bool), uncommitted_changes (list)
    """
    try:
        # Get commit hash
        commit_hash = get_git_commit_hash()

        # Get branch name
        result = subprocess.run(
            ['git', 'rev-parse', '--abbrev-ref', 'HEAD'],
            capture_output=True,
            text=True,
            timeout=2,
            check=True
        )
        branch = result.stdout.strip()

        # Check if dirty (uncommitted changes)
        result = subprocess.run(
            ['git', 'status', '--porcelain'],
            capture_output=True,
            text=True,
            timeout=2,
            check=True
        )
        dirty = bool(result.stdout.strip())
        uncommitted = result.stdout.strip().split('\n') if dirty else []

        return {
            'commit_hash': commit_hash,
            'branch': branch,
            'dirty': dirty,
            'uncommitted_changes': uncommitted
        }
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired, FileNotFoundError):
        return {
            'commit_hash': 'unknown',
            'branch': 'unknown',
            'dirty': False,
            'uncommitted_changes': []
        }


# ====================
# METADATA TRACKING
# ====================

GENERATOR_VERSION = "2.0.0"


def create_framework_metadata(
    framework_id: str,
    topology: str,
    parameters: Dict[str, Any],
    seeds: Dict[str, int],
    generated_stats: Dict[str, Any],
    budget_metadata: Dict[str, Any],
    file_path: str
) -> Dict[str, Any]:
    """
    Create comprehensive metadata for a generated framework instance.

    Args:
        framework_id: Unique framework identifier
        topology: Topology type (linear, tree, etc.)
        parameters: Dict with A, R, D, weight_scheme, budget_level, replicate
        seeds: Dict with master, framework, topology, weights seeds
        generated_stats: Dict with assumptions, rules, derived_atoms, etc.
        budget_metadata: Dict with max_cost, thresholds, selected_level
        file_path: Path to .lp file

    Returns:
        Complete metadata dict ready for JSON serialization
    """
    git_info = get_git_status()

    metadata = {
        'framework_id': framework_id,
        'topology': topology,
        'parameters': parameters,
        'seeds': seeds,
        'generated': generated_stats,
        'budget_metadata': budget_metadata,
        'file_path': file_path,
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'generator_version': GENERATOR_VERSION,
        'git': git_info
    }

    return metadata


def write_framework_metadata(output_path: Path, metadata: Dict[str, Any]):
    """
    Atomically write framework metadata to JSON sidecar file.

    Uses write-temp-then-rename to ensure atomic writes (no partial files).

    Args:
        output_path: Path to .meta.json file (e.g., framework_a10_r5.meta.json)
        metadata: Metadata dict from create_framework_metadata()
    """
    import tempfile
    import os

    output_path.parent.mkdir(parents=True, exist_ok=True)

    # Write to temp file in same directory (ensures same filesystem for atomic rename)
    fd, temp_path = tempfile.mkstemp(
        dir=output_path.parent,
        prefix='.tmp_meta_',
        suffix='.json'
    )
    try:
        with os.fdopen(fd, 'w') as f:
            json.dump(metadata, f, indent=2, sort_keys=True)
            f.flush()
            os.fsync(f.fileno())  # Ensure data written to disk

        # Atomic rename (POSIX guarantees atomicity)
        os.replace(temp_path, output_path)
    except Exception:
        # Clean up temp file on error
        try:
            os.unlink(temp_path)
        except OSError:
            pass
        raise


def create_solver_run_metadata(
    run_id: str,
    framework_id: str,
    solver_config: Dict[str, str],
    clingo_command: str,
    status: str,
    timing: Dict[str, float],
    grounding_stats: Dict[str, int],
    models: int
) -> Dict[str, Any]:
    """
    Create metadata for a single solver run.

    Args:
        run_id: Unique run identifier (framework_id + solver_config)
        framework_id: ID of framework being solved
        solver_config: Dict with semiring, monoid, operator, semantics
        clingo_command: Full clingo command executed
        status: SATISFIABLE / UNSATISFIABLE / TIMEOUT / ERROR
        timing: Dict with total, grounding, solving, first_model times
        grounding_stats: Dict with atoms, rules, bodies, variables, constraints
        models: Number of models found

    Returns:
        Complete run metadata dict ready for JSONL serialization
    """
    return {
        'run_id': run_id,
        'framework_id': framework_id,
        'solver_config': solver_config,
        'clingo_command': clingo_command,
        'status': status,
        'timing': timing,
        'grounding_stats': grounding_stats,
        'models': models,
        'timestamp': datetime.utcnow().isoformat() + 'Z'
    }


def append_solver_run_jsonl(jsonl_path: Path, run_metadata: Dict[str, Any]):
    """
    Append a solver run result to JSONL file (one JSON per line).

    Uses fsync for durability (ensures data written to disk before returning).

    Args:
        jsonl_path: Path to .jsonl file (created if doesn't exist)
        run_metadata: Run metadata from create_solver_run_metadata()
    """
    import os

    jsonl_path.parent.mkdir(parents=True, exist_ok=True)

    # Append with fsync for durability
    with open(jsonl_path, 'a') as f:
        # Sort keys for deterministic output
        json.dump(run_metadata, f, separators=(',', ':'), sort_keys=True)
        f.write('\n')
        f.flush()
        os.fsync(f.fileno())  # Ensure data written to disk


# ====================
# CONFIGURATION VALIDATION
# ====================

def validate_balanced_design(configurations: List[Dict[str, Any]]) -> Tuple[bool, str]:
    """
    Validate that experimental design is balanced (no confounding).

    Checks that each factor level appears equally often.

    Args:
        configurations: List of config dicts

    Returns:
        (is_balanced, message) tuple
    """
    from collections import Counter

    if not configurations:
        return False, "No configurations provided"

    # Count occurrences of each factor level
    topology_counts = Counter(c['topology'] for c in configurations)
    a_counts = Counter(c['A'] for c in configurations)
    r_counts = Counter(c['R'] for c in configurations)
    d_counts = Counter(c['D'] for c in configurations)
    weight_counts = Counter(c['weight_scheme'] for c in configurations)
    budget_counts = Counter(c['budget_level'] for c in configurations)

    # Check if all counts are equal within each factor
    def all_equal(counts: Counter) -> bool:
        values = list(counts.values())
        return len(set(values)) == 1

    checks = [
        (topology_counts, "Topology"),
        (a_counts, "Assumption count"),
        (r_counts, "Rule count"),
        (d_counts, "Derivation depth"),
        (weight_counts, "Weight scheme"),
        (budget_counts, "Budget level")
    ]

    for counts, name in checks:
        if not all_equal(counts):
            return False, f"{name} not balanced: {dict(counts)}"

    return True, "Design is balanced"


# ====================
# STRUCTURAL VALIDATION
# ====================

def validate_framework_structure(
    assumptions: List[str],
    rules: List[Dict],
    contraries: Dict[str, str],
    derived_atoms: List[str],
    max_derivation_depth: int
) -> Tuple[bool, List[str]]:
    """
    Validate framework structure for sanity checks.

    Args:
        assumptions: List of assumption IDs
        rules: List of rule dicts with 'head', 'body' keys
        contraries: Dict mapping assumption → contrary
        derived_atoms: List of derived atom IDs
        max_derivation_depth: Expected max depth

    Returns:
        (is_valid, error_messages) tuple
    """
    errors = []

    # Check assumptions
    if len(assumptions) == 0:
        errors.append("No assumptions defined")

    # Check all contraries reference existing assumptions
    for assumption, contrary in contraries.items():
        if assumption not in assumptions:
            errors.append(f"Contrary references non-existent assumption: {assumption}")

    # Check all rule bodies reference existing atoms
    all_atoms = set(assumptions) | set(derived_atoms)
    for rule in rules:
        for body_atom in rule.get('body', []):
            if body_atom not in all_atoms:
                errors.append(f"Rule {rule.get('id')} references non-existent atom: {body_atom}")

    # Check derivation depth
    if max_derivation_depth <= 0:
        errors.append(f"Invalid derivation depth: {max_derivation_depth}")

    is_valid = len(errors) == 0
    return is_valid, errors
