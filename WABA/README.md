# WABA: Weighted Assumption-Based Argumentation

A modular Answer Set Programming framework for argumentation with weighted arguments and budget-constrained attack resolution.

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
  WABA/monoid/max.lp \
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

- **godel.lp** - Gödel/Fuzzy logic (min/max, identity=100) - *original WABA*
- **lukasiewicz.lp** - Łukasiewicz t-norm (bounded sum)
- **tropical.lp** - Tropical semiring (addition, identity=#sup)
- **bottleneck_cost.lp** - Bottleneck semiring (max/min)

### Monoids (Cost Aggregation)

Choose how extension costs are computed from discarded attacks:

- **max.lp** - Maximum discarded attack weight - *original WABA*
- **sum.lp** - Sum of all discarded attack weights
- **min.lp** - Minimum discarded attack weight
- **count.lp** - Number of discarded attacks (weight-agnostic)
- **lex.lp** - Lexicographic (max→sum→count priority)

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
- **[SEMIRING_MONOID_COMPATIBILITY.md](docs/SEMIRING_MONOID_COMPATIBILITY.md)** - Legal semiring/monoid pairs
- **[CLINGO_USAGE.md](docs/CLINGO_USAGE.md)** - Testing patterns and batch commands
- **[CLAUDE.md](CLAUDE.md)** - Comprehensive developer guide

## More Examples

```bash
# Cost optimization (minimize extension cost)
clingo -n 0 WABA/core/base.lp WABA/semiring/godel.lp WABA/monoid/max.lp \
       WABA/filter/standard.lp WABA/optimize/minimize.lp \
       WABA/semantics/stable.lp <framework>.lp

# Lexicographic optimization (shows all cost components)
clingo -n 0 WABA/core/base.lp WABA/semiring/godel.lp WABA/monoid/lex.lp \
       WABA/filter/lexicographic.lp WABA/optimize/lexicographic.lp \
       WABA/semantics/stable.lp <framework>.lp

# Naive semantics (requires special flags)
clingo -n 0 --heuristic=Domain --enum=domRec \
       WABA/core/base.lp WABA/semiring/godel.lp WABA/monoid/max.lp \
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
- `extension_cost(C)` - Total cost of the extension

## License

See LICENSE file for details.
