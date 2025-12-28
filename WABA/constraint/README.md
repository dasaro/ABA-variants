# WABA Budget Constraint Modules

This directory contains monoid-specific budget constraint implementations for WABA.

## ⚠️ CRITICAL: Use Monoid-Specific Files

**DO NOT use generic `ub.lp` or `lb.lp`** - they are documentation files only.

**ALWAYS use the monoid-specific files:**

```
constraint/ub_sum.lp     constraint/lb_sum.lp
constraint/ub_max.lp     constraint/lb_max.lp
constraint/ub_min.lp     constraint/lb_min.lp
constraint/ub_count.lp   constraint/lb_count.lp
```

## Why Monoid-Specific Files?

All constraints check `discarded_attack(X,Y,W)` facts directly. If you load a generic file with multiple aggregates, **ALL of them fire simultaneously**, causing constraint interference.

### Problem Example

Using generic `ub.lp` with SUM monoid and `discarded_attack(a,b,10), discarded_attack(c,d,20)`:
- SUM = 30, MAX = 20, MIN = 10, **COUNT = 2**

With `beta=1`: ALL four constraints fire, including COUNT > 1, even though you're using SUM monoid!

**Solution**: Use `ub_sum.lp` which only checks the SUM aggregate.

## Overview

Budget constraints determine whether an extension's cost is acceptable:

- **Upper Bound (UB)**: Accept if `aggregate ≤ β` (cost ceiling)
- **Lower Bound (LB)**: Accept if `aggregate ≥ β` (quality threshold)

**Standard combinations:**
- SUM/MAX/COUNT + UB → Cost minimization (most common)
- MIN + LB → Quality threshold (most common for MIN)

## File Reference

### Upper Bound Files (UB) - Cost Ceiling

Enforce `aggregate ≤ β`

| File | Monoid | Constraint | Common Use |
|------|--------|------------|------------|
| `ub_sum.lp` | SUM | `sum(discards) ≤ β` | **⭐ Standard** - Total cost ceiling |
| `ub_max.lp` | MAX | `max(discards) ≤ β` | **Common** - Worst-case ceiling |
| `ub_min.lp` | MIN | `min(discards) ≤ β` | Rare - Use `lb_min.lp` instead |
| `ub_count.lp` | COUNT | `count(discards) ≤ β` | **Common** - Attack quota |

Default: `beta = #sup` (no limit, permissive)

### Lower Bound Files (LB) - Quality Threshold

Enforce `aggregate ≥ β`

| File | Monoid | Constraint | Common Use |
|------|--------|------------|------------|
| `lb_sum.lp` | SUM | `sum(discards) ≥ β` | Rare - Minimum spending |
| `lb_max.lp` | MAX | `max(discards) ≥ β` | Rare - Require expensive discard |
| `lb_min.lp` | MIN | `min(discards) ≥ β` | **⭐ Standard** - Quality floor |
| `lb_count.lp` | COUNT | `count(discards) ≥ β` | Rare - Require minimum discards |

Default: `beta = #inf` (no minimum, permissive)

### Documentation Files

- `ub.lp` - Usage documentation and examples (NO CONSTRAINTS)
- `lb.lp` - Usage documentation and examples (NO CONSTRAINTS)
- `flat.lp` - Structural constraint (independent of budget)

## Usage Examples

### Sum Monoid with Upper Bound

```bash
# Total cost of discarded attacks ≤ 100
clingo -c beta=100 \
       core/base.lp \
       semiring/tropical.lp \
       monoid/sum_minimization.lp \
       filter/standard.lp \
       constraint/ub_sum.lp \
       semantics/stable.lp \
       framework.lp
```

### Max Monoid with Upper Bound

```bash
# No single discarded attack > 50
clingo -c beta=50 \
       core/base.lp \
       semiring/tropical.lp \
       monoid/max_minimization.lp \
       filter/standard.lp \
       constraint/ub_max.lp \
       semantics/stable.lp \
       framework.lp
```

### Min Monoid with Quality Threshold

```bash
# Weakest discarded attack ≥ 10 (quality floor)
clingo -c beta=10 \
       core/base.lp \
       semiring/tropical.lp \
       monoid/min_minimization.lp \
       filter/standard.lp \
       constraint/lb_min.lp \
       semantics/stable.lp \
       framework.lp
```

### Count Monoid with Attack Quota

```bash
# At most 3 discarded attacks
clingo -c beta=3 \
       core/base.lp \
       semiring/tropical.lp \
       monoid/count_minimization.lp \
       filter/standard.lp \
       constraint/ub_count.lp \
       semantics/stable.lp \
       framework.lp
```

## Quick Reference

**Most common combinations:**
- `SUM + ub_sum.lp` → Total cost ceiling
- `MAX + ub_max.lp` → Worst-case cost ceiling
- `MIN + lb_min.lp` → Quality threshold floor ⭐
- `COUNT + ub_count.lp` → Attack quota

## Implementation Details

All monoid-specific constraint files:
1. Define `#const beta = <default>` (overridable with `-c beta=N`)
2. Define `budget(beta)` predicate
3. Check appropriate aggregate over `discarded_attack(X,Y,W)`
4. Include `#sup` weight rejection for finite budgets
5. Work with both old monoids and new optimized monoids

## Migration from Old System

**Old approach** (WRONG - causes interference):
```bash
clingo ... constraint/ub.lp ...  # Multiple aggregates checked!
```

**New approach** (CORRECT):
```bash
clingo ... monoid/sum_minimization.lp ... constraint/ub_sum.lp ...
clingo ... monoid/max_minimization.lp ... constraint/ub_max.lp ...
clingo ... monoid/min_minimization.lp ... constraint/lb_min.lp ...
clingo ... monoid/count_minimization.lp ... constraint/ub_count.lp ...
```

## Summary

The monoid-specific constraint system provides:
1. ✅ No constraint interference
2. ✅ Clean one-to-one mapping: monoid → constraint file
3. ✅ Clear semantics for each aggregate type
4. ✅ Works with all monoid variants (old, optimized, minimization, maximization)
5. ✅ Self-documenting file names

**Rule of thumb**: Match your constraint file suffix to your monoid file suffix.
