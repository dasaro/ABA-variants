# WABA Budget Constraint Modules

This directory contains modular budget constraint implementations for WABA.

## Overview

Budget constraints determine whether an extension's cost is acceptable. Different monoids require different constraint regimes:

- **Upper Bound (UB)**: Accept if `cost ≤ β` (used by MAX, SUM, COUNT, LEX)
- **Lower Bound (LB)**: Accept if `cost ≥ β` (used by MIN)

## Files

### `ub.lp` - Upper Bound Constraint

**For monoids**: MAX, SUM, COUNT, LEX

**Semantics**: Reject extensions where cost exceeds budget

**Constraint**: `:- extension_cost(C), C > B, budget(B).`

**Default**: `#const beta = #sup.` (permissive - all extensions allowed)

**Usage**:
```bash
# Permissive (default, no -c beta needed)
clingo core/base.lp semiring/godel.lp monoid/max.lp constraint/ub.lp ...

# Classical ABA (no discarding)
clingo -c beta=0 core/base.lp semiring/godel.lp monoid/max.lp constraint/ub.lp ...

# Cost limit
clingo -c beta=100 core/base.lp semiring/godel.lp monoid/sum.lp constraint/ub.lp ...
```

### `lb.lp` - Lower Bound Constraint

**For monoids**: MIN

**Semantics**: Reject extensions where quality is too low (min discarded cost < β)

**Constraint**: `:- extension_cost(C), C < B, budget(B).`

**Default**: `#const beta = #inf.` (permissive - all extensions allowed)

**Usage**:
```bash
# Permissive (default, no -c beta needed)
clingo core/base.lp semiring/tropical.lp monoid/min.lp constraint/lb.lp ...

# Quality threshold
clingo -c beta=10 core/base.lp semiring/tropical.lp monoid/min.lp constraint/lb.lp ...
```

## How Defaults Work

The `#const beta = <value>.` directive sets a default value that can be overridden:

```prolog
#const beta = #sup.   % Default value
budget(beta).         % Creates budget(#sup) fact
```

When you use `-c beta=N`:
- The constant `beta` is bound to `N`
- The fact becomes `budget(N)` instead of `budget(#sup)`
- **The -c option OVERRIDES the default**

### Example

```bash
# File: constraint/ub.lp contains:
#const beta = #sup.
budget(beta).

# Command with no -c beta:
clingo constraint/ub.lp ...
# Result: budget(#sup) in answer set

# Command with -c beta=42:
clingo -c beta=42 constraint/ub.lp ...
# Result: budget(42) in answer set
```

## Why Two Files?

Different monoids have opposite optimization goals:

### Upper Bound Monoids (MAX/SUM/COUNT/LEX)
- **Goal**: Minimize cost (lower is better)
- **Budget**: Upper limit on cost
- **Permissive default**: #sup (+∞) allows all costs
- **Example**: With SUM monoid, beta=100 means "total discarded attack cost ≤ 100"

### Lower Bound Monoid (MIN)
- **Goal**: Maximize quality (higher min is better)
- **Budget**: Lower limit on quality
- **Permissive default**: #inf (-∞) allows all qualities
- **Example**: With MIN monoid, beta=10 means "minimum discarded attack cost ≥ 10"

## Clingo Constant Ordering

Important to understand:
- `#inf` = -∞ (smallest value, negative infinity)
- `#sup` = +∞ (largest value, positive infinity)
- Finite numbers: `#inf < ... < -100 < 0 < 100 < ... < #sup`

## Migration from Previous Version

**Old system**: Budget constraint was in `core/base.lp` with `budget(beta).`

**New system**: Budget constraint is modular - choose `constraint/ub.lp` or `constraint/lb.lp`

**Command structure change**:
```bash
# OLD (broken for MIN monoid):
clingo core/base.lp semiring/X.lp monoid/Y.lp filter/standard.lp semantics/stable.lp ...

# NEW (works for all monoids):
clingo core/base.lp semiring/X.lp monoid/Y.lp constraint/ub_or_lb.lp filter/standard.lp semantics/stable.lp ...
```

**Quick reference**:
- MAX, SUM, COUNT, LEX monoids → Use `constraint/ub.lp`
- MIN monoid → Use `constraint/lb.lp`

## Testing

All tests pass with the modular system:

```bash
# UB with defaults (permissive)
clingo core/base.lp semiring/godel.lp monoid/max.lp constraint/ub.lp ...
# → 3 models (all allowed)

# UB with override
clingo -c beta=0 core/base.lp semiring/godel.lp monoid/max.lp constraint/ub.lp ...
# → 1 model (only cost=0 allowed)

# LB with default (permissive)
clingo core/base.lp semiring/tropical.lp monoid/min.lp constraint/lb.lp ...
# → 3 models (all allowed)

# LB with override
clingo -c beta=10 core/base.lp semiring/tropical.lp monoid/min.lp constraint/lb.lp ...
# → 2 models (only min(discarded) ≥ 10 allowed)
```

## Summary

The modular constraint system provides:
1. ✅ Proper defaults for both UB and LB regimes
2. ✅ Clean override mechanism via `-c beta=N`
3. ✅ Clear separation of concerns
4. ✅ Self-documenting file names (ub.lp vs lb.lp)
5. ✅ No more ungrounded beta issues

Choose the constraint file that matches your monoid's semantics!
