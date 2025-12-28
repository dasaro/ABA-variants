#!/usr/bin/env python3
"""
Benchmark Runner Configuration

Defines semiring×monoid combinations and clingo command templates.
"""

from pathlib import Path
from typing import List, Dict, Tuple, Any


# ================================================================
# WABA Module Paths
# ================================================================

WABA_ROOT = Path(__file__).parent.parent.parent  # benchmark/runner/ -> WABA/
BENCHMARK_ROOT = Path(__file__).parent.parent  # benchmark/runner/ -> benchmark/

# Core WABA modules (loaded in order)
CORE_BASE = WABA_ROOT / "core" / "base.lp"
FILTER_STANDARD = WABA_ROOT / "filter" / "standard.lp"
FILTER_LEXICOGRAPHIC = WABA_ROOT / "filter" / "lexicographic.lp"
CONSTRAINT_FLAT = WABA_ROOT / "constraint" / "flat.lp"

# Module directories
SEMIRING_DIR = WABA_ROOT / "semiring"
MONOID_DIR = WABA_ROOT / "monoid"
SEMANTICS_DIR = WABA_ROOT / "semantics"
OPTIMIZE_DIR = WABA_ROOT / "optimize"

# Framework directory
FRAMEWORKS_DIR = BENCHMARK_ROOT / "frameworks"


# ================================================================
# Semirings (5 total)
# ================================================================

SEMIRINGS = [
    "godel",           # Gödel (fuzzy): min/max, identity=#sup
    "tropical",        # Tropical: +/min, identity=#sup
    "arctic",          # Arctic: max/+, identity=#inf
    "lukasiewicz",     # Łukasiewicz: bounded sum, identity=K (default K=100)
    "bottleneck_cost"  # Bottleneck-cost: max/min
]


# ================================================================
# Monoids (5 total)
# ================================================================

MONOIDS = [
    "max",    # Maximum discarded attack cost
    "sum",    # Sum of discarded attack costs
    "min",    # Minimum discarded attack cost
    "count",  # Count of discarded attacks (weight-agnostic)
    "lex"     # Lexicographic (max→sum→count priority)
]


# ================================================================
# Semantics
# ================================================================

SEMANTICS = [
    "stable"  # Stable semantics (primary focus for benchmarks)
    # "cf",   # Conflict-free semantics
    # "naive" # Naive semantics (requires special heuristics)
]


# ================================================================
# Semiring×Monoid×Semantics Combinations
# ================================================================

def get_all_configurations(mode: str = "base_only") -> List[Dict[str, str]]:
    """Generate all valid semiring×monoid×semantics combinations.

    Args:
        mode: Configuration mode:
            - "base_only": 20 base configs (no optimization)
            - "opt_only": 20 optimized configs (with optimization)
            - "both": 40 configs (20 base + 20 optimized)

    Returns:
        List of configurations based on mode
    """
    configs = []

    for semiring in SEMIRINGS:
        for monoid in MONOIDS:
            for semantics in SEMANTICS:
                # Base configuration (no optimization)
                if mode in ["base_only", "both"]:
                    base_config = {
                        'semiring': semiring,
                        'monoid': monoid,
                        'semantics': semantics,
                        'optimized': False,
                        'optimization_module': None,
                        'name': f"{semiring}_{monoid}_{semantics}"
                    }
                    configs.append(base_config)

                # Optimized configuration
                if mode in ["opt_only", "both"]:
                    # Select optimization module based on monoid
                    if monoid in ['max', 'sum', 'count']:
                        opt_module = 'minimize'
                    elif monoid == 'min':
                        opt_module = 'maximize'
                    else:
                        opt_module = None

                    if opt_module:
                        opt_config = {
                            'semiring': semiring,
                            'monoid': monoid,
                            'semantics': semantics,
                            'optimized': True,
                            'optimization_module': opt_module,
                            'name': f"{semiring}_{monoid}_{semantics}_opt"
                        }
                        configs.append(opt_config)

    return configs


def get_validation_configurations() -> List[Dict[str, str]]:
    """Generate comprehensive validation configurations.

    Returns 105 configurations:
    - 25 old enum mode (5 semirings × 5 monoids)
    - 40 minimization with opt (5 semirings × 4 monoids, excluding lex)
    - 40 minimization with optN (5 semirings × 4 monoids, excluding lex)
    - 40 maximization with opt (5 semirings × 4 monoids, excluding lex)
    - 40 maximization with optN (5 semirings × 4 monoids, excluding lex)

    Note: Total is actually 185 configs (25 + 4*40), not 105
    """
    configs = []

    # Mode 1: Old enum mode (all 5 monoids including lex)
    for semiring in SEMIRINGS:
        for monoid in MONOIDS:
            for semantics in SEMANTICS:
                configs.append({
                    'semiring': semiring,
                    'monoid': monoid,
                    'semantics': semantics,
                    'optimized': False,
                    'optimization_direction': None,
                    'opt_mode': None,
                    'name': f"{semiring}_{monoid}_{semantics}_enum"
                })

    # Mode 2 & 3: Optimized modes (exclude lex)
    optimized_monoids = ['max', 'sum', 'min', 'count']
    directions = ['minimization', 'maximization']
    opt_modes = ['opt', 'optN']

    for semiring in SEMIRINGS:
        for monoid in optimized_monoids:
            for semantics in SEMANTICS:
                for direction in directions:
                    for opt_mode in opt_modes:
                        configs.append({
                            'semiring': semiring,
                            'monoid': monoid,
                            'semantics': semantics,
                            'optimized': True,
                            'optimization_direction': direction,
                            'opt_mode': opt_mode,
                            'name': f"{semiring}_{monoid}_{semantics}_{direction}_{opt_mode}"
                        })

    return configs


def get_full_validation_configurations() -> List[Dict[str, str]]:
    """Generate full validation configurations for side-by-side comparison.

    Four modes comparing old vs new monoid approaches:
    - old-enum: old monoids (max.lp, etc.) + minimize.lp, enum mode (-n 0, no --opt-mode)
    - new-enum: new monoids (*_minimization.lp), enum mode (-n 0, no --opt-mode)
    - old-opt: old monoids + minimize.lp, opt mode (--opt-mode=optN)
    - new-opt: new monoids (*_minimization.lp), opt mode (--opt-mode=optN)

    Total: 80 configurations (5 semirings × 4 monoids × 4 modes)
    """
    configs = []
    monoids = ['max', 'sum', 'min', 'count']  # Exclude lex

    for semiring in SEMIRINGS:
        for monoid in monoids:
            for semantics in SEMANTICS:
                # Mode 1: old-enum (old monoid + minimize.lp, enum mode)
                configs.append({
                    'semiring': semiring,
                    'monoid': monoid,
                    'semantics': semantics,
                    'mode': 'old-enum',
                    'use_old_monoid': True,
                    'use_optimize_module': True,  # Add minimize.lp
                    'opt_mode': None,
                    'name': f"{semiring}_{monoid}_{semantics}_old-enum"
                })

                # Mode 2: new-enum (new monoid *_minimization.lp, enum mode)
                configs.append({
                    'semiring': semiring,
                    'monoid': monoid,
                    'semantics': semantics,
                    'mode': 'new-enum',
                    'use_old_monoid': False,
                    'use_optimize_module': False,
                    'optimization_direction': 'minimization',
                    'opt_mode': None,
                    'name': f"{semiring}_{monoid}_{semantics}_new-enum"
                })

                # Mode 3: old-opt (old monoid + minimize.lp, opt mode)
                configs.append({
                    'semiring': semiring,
                    'monoid': monoid,
                    'semantics': semantics,
                    'mode': 'old-opt',
                    'use_old_monoid': True,
                    'use_optimize_module': True,  # Add minimize.lp
                    'opt_mode': 'optN',
                    'name': f"{semiring}_{monoid}_{semantics}_old-opt"
                })

                # Mode 4: new-opt (new monoid *_minimization.lp, opt mode)
                configs.append({
                    'semiring': semiring,
                    'monoid': monoid,
                    'semantics': semantics,
                    'mode': 'new-opt',
                    'use_old_monoid': False,
                    'use_optimize_module': False,
                    'optimization_direction': 'minimization',
                    'opt_mode': 'optN',
                    'name': f"{semiring}_{monoid}_{semantics}_new-opt"
                })

    return configs


def get_three_mode_configurations() -> List[Dict[str, str]]:
    """Generate three-mode validation configurations.

    Three distinct enumeration modes for performance and correctness validation:
    - old_enum: Baseline with explicit extension_cost/1 predicate (old monoid files)
    - new_enum: Optimized enumeration with --opt-mode=ignore (new monoid files, all models)
    - new_opt: Optimal enumeration with --opt-mode=optN (new monoid files, optimal models only)

    Total: 80 configurations
    - 20 old_enum: 5 semirings × 4 monoids
    - 20 new_enum: 5 semirings × 4 monoids
    - 40 new_opt: 5 semirings × 4 monoids × 2 directions (min/max)

    Returns:
        List of 80 configuration dicts
    """
    configs = []
    monoids = ['max', 'sum', 'min', 'count']  # Exclude lex

    # Mode 1: old_enum (baseline with extension_cost)
    for semiring in SEMIRINGS:
        for monoid in monoids:
            for semantics in SEMANTICS:
                configs.append({
                    'semiring': semiring,
                    'monoid': monoid,
                    'semantics': semantics,
                    'mode': 'old-enum',
                    'use_old_monoid': True,
                    'use_optimize_module': False,
                    'opt_mode': None,
                    'optimization_direction': None,
                    'name': f"{semiring}_{monoid}_{semantics}_old-enum"
                })

    # Mode 2: new_enum (optimized enumeration, all models)
    for semiring in SEMIRINGS:
        for monoid in monoids:
            for semantics in SEMANTICS:
                configs.append({
                    'semiring': semiring,
                    'monoid': monoid,
                    'semantics': semantics,
                    'mode': 'new-enum',
                    'use_old_monoid': False,
                    'use_optimize_module': False,
                    'opt_mode': 'ignore',  # KEY: ignore #minimize directive
                    'optimization_direction': 'minimization',
                    'name': f"{semiring}_{monoid}_{semantics}_new-enum"
                })

    # Mode 3: new_opt (optimal enumeration, both directions)
    for semiring in SEMIRINGS:
        for monoid in monoids:
            for semantics in SEMANTICS:
                for direction in ['minimization', 'maximization']:
                    configs.append({
                        'semiring': semiring,
                        'monoid': monoid,
                        'semantics': semantics,
                        'mode': 'new-opt',
                        'use_old_monoid': False,
                        'use_optimize_module': False,
                        'opt_mode': 'optN',  # Find all optimal models
                        'optimization_direction': direction,
                        'name': f"{semiring}_{monoid}_{semantics}_new-opt-{direction}"
                    })

    return configs


# ================================================================
# Clingo Command Builder
# ================================================================

def build_clingo_command(framework_path: Path, config: Dict[str, str],
                         clingo_timeout: int = 60, model_limit: int = 0,
                         stats_level: int = 2) -> List[str]:
    """Build clingo command for a framework×config combination.

    Supports both old configurations (from get_all_configurations) and
    new validation configurations (from get_validation_configurations).

    Args:
        framework_path: Path to framework .lp file
        config: Configuration dict
        clingo_timeout: Clingo's internal time limit in seconds (default: 60)
        model_limit: Number of models to find (0 = all, default: 0)
        stats_level: Statistics detail level (default: 2)

    Returns:
        List of command arguments for subprocess
    """
    semiring = config['semiring']
    monoid = config['monoid']
    semantics = config['semantics']

    # Choose filter based on monoid
    if monoid == 'lex':
        filter_file = FILTER_LEXICOGRAPHIC
    else:
        filter_file = FILTER_STANDARD

    # Determine model limit and optimization mode
    mode = config.get('mode')

    if mode == 'old-enum':
        # Old enumeration: find all models, no --opt-mode flag
        n_models = 0
        use_opt_mode = False
    elif mode == 'new-enum':
        # New enumeration: find all models with --opt-mode=ignore
        n_models = 0
        use_opt_mode = True
    elif mode in ['old-opt', 'new-opt']:
        # Optimization modes: find all optimal models
        n_models = 0
        use_opt_mode = True
    elif config.get('optimized', False):
        # Old style validation configs
        if 'optimization_direction' in config:
            n_models = 0
            use_opt_mode = True
        else:
            n_models = 1
            use_opt_mode = True
    else:
        # Standard enum mode
        n_models = model_limit
        use_opt_mode = False

    # Build command with correct module order
    cmd = [
        'clingo',
        '-n', str(n_models),           # Model limit
        f'--stats={stats_level}',      # Statistics level
        # --time-limit removed: Python handles timeout with aggressive SIGKILL
    ]

    # Add optimization mode for optimized configurations
    if use_opt_mode:
        opt_mode = config.get('opt_mode', 'opt')
        cmd.append(f'--opt-mode={opt_mode}')

    # 1. Core base logic (always use current optimized base)
    cmd.append(str(CORE_BASE))

    # 2. Semiring (always use current)
    semiring_file = SEMIRING_DIR / f"{semiring}.lp"
    cmd.append(str(semiring_file))

    # 3. Monoid
    if config.get('use_old_monoid', False):
        # Old monoid files (baseline/max.lp, baseline/sum.lp, etc.)
        monoid_file = MONOID_DIR / "baseline" / f"{monoid}.lp"
    else:
        # New monoid files (*_minimization.lp or *_maximization.lp)
        direction = config.get('optimization_direction', 'minimization')
        monoid_file = MONOID_DIR / f"{monoid}_{direction}.lp"
    cmd.append(str(monoid_file))

    # 4. Filter (standard or lexicographic)
    cmd.append(str(filter_file))

    # 5. Optimization module (for old-enum and old-opt modes)
    # CRITICAL: after filter, before constraint
    if config.get('use_optimize_module', False):
        cmd.append(str(OPTIMIZE_DIR / "minimize.lp"))

    # Legacy support for old style configs
    if config.get('optimized', False) and config.get('optimization_module'):
        cmd.append(str(OPTIMIZE_DIR / f"{config['optimization_module']}.lp"))

    # Continue with remaining modules
    cmd.extend([
        str(CONSTRAINT_FLAT),          # 6. Flat-WABA constraint
        str(SEMANTICS_DIR / f"{semantics}.lp"),  # 7. Semantics
        str(framework_path)            # 8. Framework instance
    ])

    return cmd


# ================================================================
# Framework Discovery
# ================================================================

def discover_frameworks(frameworks_dir: Path = FRAMEWORKS_DIR) -> List[Path]:
    """Discover all framework .lp files in the frameworks directory.

    Args:
        frameworks_dir: Base frameworks directory (default: benchmark/frameworks/)

    Returns:
        List of paths to .lp framework files
    """
    frameworks = []

    # Find all .lp files in topology subdirectories
    for topology_dir in frameworks_dir.iterdir():
        if topology_dir.is_dir():
            for framework_file in topology_dir.glob("*.lp"):
                frameworks.append(framework_file)

    return sorted(frameworks)


# ================================================================
# Benchmark Run Metadata
# ================================================================

def get_benchmark_metadata() -> Dict[str, Any]:
    """Get metadata about the benchmark configuration.

    Returns:
        Dict with benchmark configuration info
    """
    configs = get_all_configurations()
    frameworks = discover_frameworks()

    # Count base vs optimized configs
    base_configs = [c for c in configs if not c.get('optimized', False)]
    opt_configs = [c for c in configs if c.get('optimized', False)]

    return {
        'num_semirings': len(SEMIRINGS),
        'num_monoids': len(MONOIDS),
        'num_semantics': len(SEMANTICS),
        'num_base_configurations': len(base_configs),
        'num_optimized_configurations': len(opt_configs),
        'num_total_configurations': len(configs),
        'num_configurations': len(configs),  # Backward compatibility
        'num_frameworks': len(frameworks),
        'total_base_runs': len(frameworks) * len(base_configs),
        'total_optimized_runs': len(frameworks) * len(opt_configs),
        'total_runs': len(frameworks) * len(configs),
        'semirings': SEMIRINGS,
        'monoids': MONOIDS,
        'semantics': SEMANTICS,
        'optimization_enabled': True,
        'timeout_seconds': 300,
        'stats_level': 2,
        'parallel_workers': 4
    }


# ================================================================
# Main (for testing)
# ================================================================

if __name__ == '__main__':
    print("WABA Benchmark Runner Configuration")
    print("=" * 60)

    # Show configuration
    metadata = get_benchmark_metadata()
    print(f"\nSemirings ({metadata['num_semirings']}): {', '.join(SEMIRINGS)}")
    print(f"Monoids ({metadata['num_monoids']}): {', '.join(MONOIDS)}")
    print(f"Semantics ({metadata['num_semantics']}): {', '.join(SEMANTICS)}")
    print(f"\nTotal configurations: {metadata['num_configurations']}")
    print(f"Total frameworks: {metadata['num_frameworks']}")
    print(f"Total benchmark runs: {metadata['total_runs']}")
    print(f"\nTimeout: {metadata['timeout_seconds']}s per run")
    print(f"Parallel workers: {metadata['parallel_workers']}")

    # Show sample command
    print(f"\n{'=' * 60}")
    print("Sample Clingo Command")
    print("=" * 60)

    configs = get_all_configurations()
    frameworks = discover_frameworks()

    if configs and frameworks:
        sample_cmd = build_clingo_command(frameworks[0], configs[0])
        print("\n" + " ".join(sample_cmd))
        print(f"\nFramework: {frameworks[0].name}")
        print(f"Config: {configs[0]['name']}")

    print(f"\n{'=' * 60}")
