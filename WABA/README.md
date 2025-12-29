# WABA: Weighted Assumption-Based Argumentation

A modular Answer Set Programming framework for argumentation with weighted arguments and budget-constrained attack resolution.

## Quick Navigation

- **Getting Started**: See examples below
- **Command Reference**: [docs/QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md)
- **Clingo Syntax Cheat Sheet**: [docs/clingo_v5_8_0_cheatsheet.md](docs/clingo_v5_8_0_cheatsheet.md) ⭐
- **Best Practices**: [docs/FRAMEWORK_BEST_PRACTICES.md](docs/FRAMEWORK_BEST_PRACTICES.md)
- **Semiring/Monoid Compatibility**: [docs/SEMIRING_MONOID_COMPATIBILITY.md](docs/SEMIRING_MONOID_COMPATIBILITY.md)
- **Constraint Usage**: [constraint/README.md](constraint/README.md)
- **Benchmarking**: [benchmark/README.md](benchmark/README.md)
- **Changelog**: [CHANGELOG.md](CHANGELOG.md)

## Quick Start

### Requirements

- **clingo** 5.8.0+ (Answer Set Programming solver)
- Basic understanding of Answer Set Programming (ASP)

### Basic Command Structure

```bash
clingo -n 0 \
  WABA/core/base.lp \
  WABA/semiring/<semiring>.lp \
  WABA/monoid/<monoid>.lp \
  WABA/filter/standard.lp \
  WABA/semantics/<semantics>.lp \
  <your_framework>.lp
```

### Example: Medical Ethics Decision

```bash
clingo -n 0 \
  WABA/core/base.lp \
  WABA/semiring/godel.lp \
  WABA/monoid/max_minimization.lp \
  WABA/filter/standard.lp \
  WABA/semantics/stable.lp \
  WABA/examples/medical.lp
```

This uses:
- **Gödel semiring** (min/max logic) for weight propagation
- **Max monoid** for cost aggregation (original WABA semantics)
- **Stable semantics** for argumentation

## Core Concepts

### Semirings (Weight Propagation)

Choose how weights propagate through rule derivations:

- **godel.lp** - Gödel/Fuzzy logic (min/max, identity=#sup) - *original WABA*
- **lukasiewicz.lp** - Łukasiewicz t-norm (bounded sum, parametrizable K via `-c luk_k=N`)
- **tropical.lp** - Tropical semiring (+/min, cost minimization, identity=#sup)
  - **Also simulates Viterbi semiring** for probabilistic reasoning via log transformation!
- **arctic.lp** - Arctic semiring (+/max, reward maximization, dual of Tropical)
- **bottleneck_cost.lp** - Bottleneck-cost semiring (max/min, worst-case optimization)

### Monoids (Cost Aggregation)

Choose how extension costs are computed from discarded attacks:

- **max.lp** - Maximum discarded attack weight - *original WABA*
- **sum.lp** - Sum of all discarded attack weights
- **min.lp** - Minimum discarded attack weight
- **count.lp** - Number of discarded attacks (weight-agnostic)
- **lex.lp** - Lexicographic (max→sum→count priority)

**Optimized variants** (direct `#minimize`/`#maximize`, 1000x faster):
- **sum_minimization.lp** / **sum_maximization.lp** - Sum minimization/maximization
- **max_minimization.lp** / **max_maximization.lp** - Max minimization/maximization
- **min_minimization.lp** / **min_maximization.lp** - Min minimization/maximization
- **count_minimization.lp** / **count_maximization.lp** - Count minimization/maximization
- **lex_minimization.lp** / **lex_maximization.lp** - Lexicographic minimization/maximization

**Naming convention:** `{monoid}_{direction}.lp` where direction is `minimization` (minimize/cost) or `maximization` (maximize/reward)

### Performance Warning

**When using Tropical/Arctic semirings with Sum monoid:**

| Semantics | File | Speed | Display |
|-----------|------|-------|---------|
| **Minimize cost** ⭐ | `sum_minimization.lp` | **Fast (0.005s)** | `Optimization: N` |
| **Maximize reward** ⭐ | `sum_maximization.lp` | **Fast (0.005s)** | `Optimization: -N` |

All monoids now use optimized weak constraint-based approach (1000x+ faster, works in both optimization and enumeration modes).

### Budget Parameter

**CRITICAL**: Always set a budget to control attack discarding:

```prolog
% In your framework file
budget(100).  % Can discard attacks up to cost 100
```

Or via command line:
```bash
clingo -c beta=100 WABA/core/base.lp ...
```

Common values:
- `budget(0)` - Strictest (classical ABA, no discarding)
- `budget(max_weight)` - Can discard ~1 attack
- `budget(sum_all)` - Can discard all attacks


### Łukasiewicz Normalization Constant

**For Łukasiewicz semiring only**: Control the weight scale with parameter K.

**Default**: K = 100 (weights in [0,100])

**Override via command line**:
```bash
# Standard Łukasiewicz with [0,1] scale
clingo -c luk_k=1 WABA/core/base.lp WABA/semiring/lukasiewicz.lp ...

# Finer granularity with [0,1000] scale
clingo -c luk_k=1000 WABA/core/base.lp WABA/semiring/lukasiewicz.lp ...
```

**Impact**:
- Conjunction formula: `max(0, sum(weights) - K*(n-1))`
- Disjunction formula: `min(K, sum(weights))`

## Directory Structure

```
WABA/
├── README.md                    # This file
├── CLAUDE.md                    # Instructions for Claude Code
├── core/                        # Core argumentation logic
├── filter/                      # Output filtering modules
├── optimize/                    # Cost optimization modules
├── semiring/                    # Weight propagation strategies
├── monoid/                      # Cost aggregation strategies
├── semantics/                   # Argumentation semantics (stable, cf, naive)
├── examples/                    # Example frameworks
├── test/                        # Test files
└── docs/                        # Documentation
    ├── QUICK_REFERENCE.md       # Command patterns
    ├── SEMIRING_MONOID_COMPATIBILITY.md
    └── CLINGO_USAGE.md          # Testing patterns
```

## Documentation

- **[QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md)** - Common command patterns and combinations
- **[SEMIRING_MONOID_COMPATIBILITY.md](docs/SEMIRING_MONOID_COMPATIBILITY.md)** - Understanding semiring/monoid combinations
- **[FRAMEWORK_BEST_PRACTICES.md](docs/FRAMEWORK_BEST_PRACTICES.md)** - Framework creation and validation guide
- **[CLAUDE.md](CLAUDE.md)** - Comprehensive developer guide

## More Examples

```bash
# Minimize max cost
clingo -n 0 --opt-mode=opt WABA/core/base.lp WABA/semiring/godel.lp \
       WABA/monoid/max_minimization.lp WABA/filter/standard.lp \
       WABA/semantics/stable.lp <framework>.lp

# Minimize total cost (1000x speedup with Tropical/Arctic)
clingo -n 0 --opt-mode=opt WABA/core/base.lp WABA/semiring/tropical.lp \
       WABA/monoid/sum_minimization.lp WABA/filter/standard.lp \
       WABA/semantics/stable.lp <framework>.lp

# Maximize total reward (1000x speedup with Tropical/Arctic)
clingo -n 0 --opt-mode=opt WABA/core/base.lp WABA/semiring/tropical.lp \
       WABA/monoid/sum_maximization.lp WABA/filter/standard.lp \
       WABA/semantics/stable.lp <framework>.lp

# Enumerate with cost display (works in enum mode too!)
clingo -n 10 WABA/core/base.lp WABA/semiring/tropical.lp \
       WABA/monoid/sum_minimization.lp WABA/filter/standard.lp \
       WABA/semantics/stable.lp <framework>.lp

# Probabilistic reasoning (Viterbi via Tropical + log transformation)
clingo -n 0 WABA/core/base.lp WABA/semiring/tropical.lp WABA/monoid/min_minimization.lp \
       WABA/constraint/lb.lp WABA/filter/standard.lp \
       WABA/semantics/stable.lp WABA/examples/viterbi_simulation.lp

# Lexicographic minimization (shows all cost components via priorities)
clingo -n 0 WABA/core/base.lp WABA/semiring/godel.lp \
       WABA/monoid/lex_minimization.lp WABA/filter/lexicographic.lp \
       WABA/semantics/stable.lp <framework>.lp

# Naive semantics (requires special flags)
clingo -n 0 --heuristic=Domain --enum=domRec \
       WABA/core/base.lp WABA/semiring/godel.lp WABA/monoid/max_minimization.lp \
       WABA/filter/standard.lp WABA/semantics/naive.lp <framework>.lp
```

## Framework File Format

WABA frameworks use Answer Set Programming syntax:

```prolog
% Assumptions (defeasible atoms)
assumption(a1).
assumption(a2).

% Weights
weight(a1, 50).
weight(a2, 30).

% Rules (compact form recommended)
head(r1, conclusion; r1, premise1; r1, premise2). % r1: conclusion <- premise1, premise2.

% Contraries (attack relation)
contrary(a1, element).  % "element attacks a1"

% Budget
budget(100).
```

## Output

Expected output predicates:
- `in(X)` - Selected assumptions in the extension
- `supported_with_weight(X, W)` - Supported elements with their weights
- `attacks_successfully_with_weight(X, Y, W)` - Successful attacks
- `Optimization: N` - Cost/reward value (shown by weak constraints)

## Historical Reference

**Previous Implementation:** The original aggregate-based WABA implementation (pre-December 2025) is preserved in the `WABA_Legacy/` directory for historical reference.

**Key differences:**
- **Legacy**: Aggregate-based `extension_cost/1` predicate, 1000x slower, supports enumeration of all models
- **Current**: Direct weak constraint optimization, 1000x faster, **backward incompatible** (no `extension_cost/1`)

⚠️ **Breaking change (Dec 2025):** The `extension_cost/1` predicate has been completely removed for efficiency. Old code using `extension_cost/1` will not work. Use weak constraint optimization values instead (shown as `Optimization: N`).

## License

See LICENSE file for details.
