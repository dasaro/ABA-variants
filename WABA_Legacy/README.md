# WABA Legacy Implementation (Aggregate-Based)

**Date:** Pre-December 2025 refactoring
**Status:** Historical reference - deprecated for production use
**Maintained For:** Backward compatibility, research comparison, benchmarking

---

## Purpose

This directory contains the **original aggregate-based WABA implementation** prior to the December 2025 refactoring. It serves as:

1. **Historical reference** for understanding the evolution of WABA
2. **Compatibility layer** for projects using the old implementation
3. **Benchmarking baseline** for performance comparisons
4. **Research artifact** for studying alternative implementation approaches

**⚠️ For new projects, use the new implementation in `WABA/` (1000x faster, 53-54% fewer timeouts).**

---

## Key Differences: Old vs New Implementation

### Old Implementation (This Directory)

**Architecture:**
- **Monolithic core** (`core/legacy.lp`) with all logic in one file
- **Aggregate-based** `extension_cost/1` computation
- Direct aggregation over `discarded_attack/3` atoms
- No optimization directives (standard enumeration only)

**Performance:**
- Enumeration-only (no optimization mode)
- Baseline performance (~1000x slower for finding optimal extensions)
- 5.0% timeout rate (113/2,240 runs in benchmark)

**Files:**
```
WABA_Legacy/
├── core/legacy.lp          # Monolithic core with aggregate-based logic
├── monoid/                 # Aggregate-based monoids
│   ├── max.lp              # extension_cost(C) :- C = #max{...}
│   ├── sum.lp              # extension_cost(C) :- C = #sum{...}
│   ├── min.lp              # extension_cost(C) :- C = #min{...}
│   └── count.lp            # extension_cost(C) :- C = #count{...}
├── semiring/               # Same semirings (Gödel, Tropical, Łukasiewicz)
├── filter/standard.lp      # Output filtering
├── semantics/              # Same semantics (stable, cf)
└── examples/medical.lp     # Example framework
```

### New Implementation (WABA/ directory)

**Architecture:**
- **Modular core** (`WABA/core/base.lp`) separated from semiring/monoid logic
- **Weak constraint-based** optimization using `#minimize/@maximize`
- Supports both enumeration (`--opt-mode=ignore`) and optimization (`--opt-mode=optN`)
- Clean separation of concerns (core ⊥ semiring ⊥ monoid)

**Performance:**
- **~1000x faster** for finding optimal extensions (optimization mode)
- **53-54% fewer timeouts** compared to old implementation
- **2.3% timeout rate** (52-57/2,400 runs vs 113/2,240 for old)
- **97.6-97.7% success rate** (vs 95.0% for old)

**Files:**
```
WABA/
├── core/base.lp                # Modular semiring/monoid-independent core
├── monoid/                     # Weak constraint-based monoids
│   ├── max_minimization.lp     # Minimize max discarded weight
│   ├── sum_minimization.lp     # Minimize sum of discarded weights
│   ├── ...                     # Minimization and maximization variants
├── semiring/                   # Same semirings (Gödel, Tropical, Łukasiewicz, Arctic, Bottleneck-cost)
├── filter/standard.lp          # Output filtering
├── semantics/                  # Same semantics (stable, cf, naive)
└── examples/                   # Example frameworks
```

**Key Advantages:**
- 1000x faster optimization via weak constraints
- Modular design (easier to extend with new semirings/monoids)
- Supports both enumeration and optimization modes
- Significantly fewer timeouts on large frameworks

---

## Benchmark Results

Comprehensive three-mode benchmark (9,600 runs, December 27, 2025):

| Mode | Success Rate | Timeouts | Avg Time | Notes |
|------|--------------|----------|----------|-------|
| **old-enum** (this impl) | 95.0% | 113 | ~1.2s | Baseline |
| **new-enum** | 97.7% | 52 | ~0.8s | **-54% timeouts** |
| **new-opt** | 97.6-97.7% | 51-57 | ~0.8s | **1000x faster for optim** |

**Key Findings:**
- ✅ **100% semantic correctness** (old ≡ new on same frameworks)
- ✅ **53-54% timeout reduction** with new implementation
- ✅ **70% of configurations** have smaller groundings in new implementation
- ✅ **Arctic semiring** shows 45% timeout reduction (93% of timeouts eliminated)

**Full report:** `WABA/benchmark/results/three_mode_2025-12-27/FINAL_BENCHMARK_REPORT.md`

---

## Usage Examples

### Basic Usage (Gödel + Max - Original WABA)

```bash
clingo -n 0 WABA_Legacy/core/legacy.lp \
       WABA_Legacy/semiring/godel.lp \
       WABA_Legacy/monoid/max.lp \
       WABA_Legacy/filter/standard.lp \
       WABA_Legacy/semantics/stable.lp \
       WABA_Legacy/examples/medical.lp
```

**Output:** All stable extensions with their `extension_cost/1` values.

### Tropical + Sum

```bash
clingo -n 0 WABA_Legacy/core/legacy.lp \
       WABA_Legacy/semiring/tropical.lp \
       WABA_Legacy/monoid/sum.lp \
       WABA_Legacy/filter/standard.lp \
       WABA_Legacy/semantics/stable.lp \
       <framework>.lp
```

### Łukasiewicz + Min

```bash
clingo -n 0 -c K=100 WABA_Legacy/core/legacy.lp \
       WABA_Legacy/semiring/lukasiewicz.lp \
       WABA_Legacy/monoid/min.lp \
       WABA_Legacy/filter/standard.lp \
       WABA_Legacy/semantics/stable.lp \
       <framework>.lp
```

**Note:** Łukasiewicz requires `-c K=<value>` parameter (default: 100).

---

## Migration Guide: Old → New Implementation

### 1. Simple Migration (Same Behavior)

**Old command:**
```bash
clingo -n 0 WABA_Legacy/core/legacy.lp WABA_Legacy/semiring/godel.lp \
       WABA_Legacy/monoid/max.lp WABA_Legacy/filter/standard.lp \
       WABA_Legacy/semantics/stable.lp <framework>.lp
```

**New command (enumeration mode - semantically equivalent):**
```bash
clingo -n 0 --opt-mode=ignore WABA/core/base.lp WABA/semiring/godel.lp \
       WABA/monoid/max_minimization.lp WABA/filter/standard.lp \
       WABA/semantics/stable.lp <framework>.lp
```

**Changes:**
- `legacy.lp` → `base.lp`
- `monoid/max.lp` → `monoid/max_minimization.lp`
- Add `--opt-mode=ignore` flag

### 2. Recommended Migration (Use Optimization)

**For finding optimal extensions (1000x faster):**
```bash
clingo -n 0 --opt-mode=optN WABA/core/base.lp WABA/semiring/godel.lp \
       WABA/monoid/max_minimization.lp WABA/filter/standard.lp \
       WABA/semantics/stable.lp <framework>.lp
```

**Changes:**
- Use `--opt-mode=optN` instead of `--opt-mode=ignore`
- Returns only optimal extensions (not all extensions)

### 3. Monoid Name Mapping

| Old Monoid | New Monoid (Minimize) | New Monoid (Maximize) |
|------------|----------------------|----------------------|
| `max.lp` | `max_minimization.lp` | `max_maximization.lp` |
| `sum.lp` | `sum_minimization.lp` | `sum_maximization.lp` |
| `min.lp` | `min_minimization.lp` | `min_maximization.lp` |
| `count.lp` | `count_minimization.lp` | `count_maximization.lp` |

**Direction choice:**
- **Minimization**: Costs (weights = penalties to avoid)
- **Maximization**: Rewards (weights = benefits to pursue)

---

## File Descriptions

### Core Logic

**`core/legacy.lp`** - Monolithic core implementing:
- Assumption selection (`in/1`, `out/1`)
- Support computation (`supported/1`, `triggered_by_in/1`)
- Attack computation (`attacks_with_weight/3`)
- Attack discarding (`discarded_attack/3`, `attacks_successfully_with_weight/3`)
- Defeat computation (`defeated/1`)
- Budget enforcement (`:- extension_cost(C), C > B, budget(B)`)

### Monoids (Aggregate-Based)

**`monoid/max.lp`** - Maximum cost aggregation:
```prolog
extension_cost(C) :- C = #max{ W, X, Y : discarded_attack(X,Y,W) }.
extension_cost(0) :- not discarded_attack(_,_,_).
```

**`monoid/sum.lp`** - Sum cost aggregation:
```prolog
extension_cost(C) :- C = #sum{ W, X, Y : discarded_attack(X,Y,W) }.
extension_cost(0) :- not discarded_attack(_,_,_).
```

**`monoid/min.lp`** - Minimum cost aggregation:
```prolog
extension_cost(C) :- C = #min{ W, X, Y : discarded_attack(X,Y,W) }.
extension_cost(#sup) :- not discarded_attack(_,_,_).
```

**`monoid/count.lp`** - Count aggregation (weight-agnostic):
```prolog
extension_cost(C) :- C = #count{ X, Y : discarded_attack(X,Y,_) }.
extension_cost(0) :- not discarded_attack(_,_,_).
```

### Semirings (Baseline Versions)

- **`semiring/godel.lp`**: Gödel/Fuzzy logic (min/max, identity=#sup)
- **`semiring/tropical.lp`**: Tropical semiring (+/min, identity=#sup)
- **`semiring/lukasiewicz.lp`**: Łukasiewicz t-norm (bounded sum, parameter K)
- **`semiring/arctic.lp`**: Arctic semiring (baseline/slower version - new implementation uses optimized version)

### Filter & Semantics (Same as New Implementation)

- **`filter/standard.lp`**: Standard output filtering
- **`semantics/stable.lp`**: Stable semantics
- **`semantics/cf.lp`**: Conflict-free semantics

---

## Limitations of Old Implementation

1. **No optimization support**: Can only enumerate all extensions, not find optimal ones
2. **Slower performance**: ~1000x slower than new implementation for optimization queries
3. **Higher timeout rate**: 5.0% vs 2.3% for new implementation
4. **Monolithic design**: Harder to extend with new semirings/monoids
5. **No maximization**: Only minimization semantics (costs, not rewards)

---

## When to Use Old Implementation

**Use old implementation if:**
- ✅ You need exact backward compatibility with existing results
- ✅ You're comparing performance benchmarks
- ✅ You're studying alternative implementation approaches
- ✅ You have existing scripts/workflows that rely on old file structure

**Use new implementation if:**
- ✅ Starting a new project (recommended)
- ✅ Need optimal extensions quickly (1000x faster)
- ✅ Working with large frameworks (fewer timeouts)
- ✅ Want modular design (easier to extend)

---

## References

**New Implementation:**
- Main directory: `WABA/`
- Documentation: `WABA/README.md`, `CLAUDE.md`
- Quick reference: `WABA/docs/QUICK_REFERENCE.md`

**Benchmark Results:**
- Final report: `WABA/benchmark/results/three_mode_2025-12-27/FINAL_BENCHMARK_REPORT.md`
- New mode analysis: `WABA/benchmark/results/new_mode_analysis/NEW_MODE_ANALYSIS_REPORT.md`

**Papers & Theory:**
- Original WABA paper: [cite if available]
- Semiring theory: See `WABA/docs/POTENTIAL_SEMIRINGS.md`

---

## Maintenance Status

**Status:** ⚠️ **Deprecated - Maintenance Only**

- **No new features** will be added to this implementation
- **Bug fixes** only if critical for backward compatibility
- **Preserved for historical reference** and benchmarking

**Last Updated:** December 2025 (refactoring)
**Deprecated Since:** December 2025
**Replaced By:** `WABA/` (new modular implementation)

---

## License

Same as main WABA project. See top-level LICENSE file.

---

**For questions or issues with the old implementation, please:**
1. Check if the issue exists in the new implementation (`WABA/`)
2. Consider migrating to the new implementation (recommended)
3. Only file issues for critical bugs requiring backward compatibility

**Recommended action:** Migrate to `WABA/` for better performance and maintainability.
