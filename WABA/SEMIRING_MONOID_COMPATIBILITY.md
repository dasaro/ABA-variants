# Semiring-Monoid Compatibility Matrix

## Overview

Not all semiring/monoid combinations are mathematically coherent. Unweighted assumptions must satisfy two requirements:

1. **Propagation Neutrality**: Don't dominate weight propagation through rules
2. **Attack Hardness**: Produce hard-to-discard attacks

These requirements can conflict depending on the semiring's conjunction operation and the monoid's cost aggregation.

## Compatibility Requirements

### For Max/Sum Monoids
- **Hardest to discard** = largest weight = #sup (infinity)
- **Neutral propagation** requires conjunction identity = #sup
- **Compatible** with: min-based conjunctions (fuzzy)
- **Incompatible** with: +-based conjunctions (tropical)

### For Min Monoid
- **Hardest to discard** = smallest weight = 0
- **Neutral propagation** requires conjunction identity = 0
- **Compatible** with: +-based conjunctions (tropical)
- **Incompatible** with: min-based conjunctions (fuzzy)

## Legal Combinations

| Semiring | Conjunction | Identity | Max Monoid | Sum Monoid | Min Monoid |
|----------|-------------|----------|------------|------------|------------|
| **Fuzzy** | min | #sup | ✓ (#sup) | ✓ (#sup) | ✗ (conflict) |
| **Tropical** | + | 0 | ✗ (conflict) | ✗ (conflict) | ✓ (0) |
| **Boolean** | ∧ (min) | 1 | ✓ (1) | ✓ (1) | ✗ (conflict) |

**Legend:**
- ✓ = Compatible (value shown in parentheses)
- ✗ = Incompatible (conflicting requirements)

## Detailed Analysis

### ✓ Fuzzy + Max
- **Default weight**: #sup
- **Propagation**: min(#sup, x) = x (neutral ✓)
- **Attack cost**: max(#sup, ...) = #sup (hardest ✓)
- **Use case**: Original WABA semantics, max single attack cost

### ✓ Fuzzy + Sum
- **Default weight**: #sup
- **Propagation**: min(#sup, x) = x (neutral ✓)
- **Attack cost**: sum(#sup, ...) = #sup (hardest ✓)
- **Use case**: Total cumulative attack cost

### ✗ Fuzzy + Min (INCOMPATIBLE)
- **Needs for neutrality**: #sup (so min(#sup, x) = x)
- **Needs for hardness**: 0 (so min(0, x) = 0 dominates)
- **Conflict**: Cannot satisfy both requirements
- **What happens**: With default=#sup, propagation neutral BUT min(#sup, x) ≠ hardest
- **What happens**: With default=0, min(0, x)=0 dominates propagation (NOT neutral)

### ✗ Tropical + Max (INCOMPATIBLE)
- **Needs for neutrality**: 0 (so +(0, x) = x)
- **Needs for hardness**: #sup (so max(#sup, ...) dominates)
- **Conflict**: Cannot satisfy both requirements
- **What happens**: With default=#sup, +(#sup, x)=#sup dominates propagation (NOT neutral)
- **What happens**: With default=0, max(0, x)=x, 0 is weakest (NOT hardest)

### ✗ Tropical + Sum (INCOMPATIBLE)
- Same analysis as Tropical + Max
- **Conflict**: 0 needed for neutral propagation, #sup needed for hard attacks

### ✓ Tropical + Min
- **Default weight**: 0
- **Propagation**: +(0, x) = x (neutral ✓)
- **Attack cost**: min(0, ...) = 0 (hardest ✓)
- **Use case**: Minimize cheapest discarded attack, neutral assumptions

### ✓ Boolean + Max
- **Default weight**: 1
- **Propagation**: ∧(1, x) = x (neutral ✓)
- **Attack cost**: max(1, x) = 1 for x∈{0,1} (hardest ✓)
- **Use case**: Binary argumentation, count worst attack

### ✓ Boolean + Sum
- **Default weight**: 1
- **Propagation**: ∧(1, x) = x (neutral ✓)
- **Attack cost**: sum(1, ...) = count(attacks) (hardest per attack ✓)
- **Use case**: Binary argumentation, count total attacks

### ✗ Boolean + Min (INCOMPATIBLE)
- **Needs for neutrality**: 1 (so ∧(1, x) = x)
- **Needs for hardness**: 0 (so min(0, x) = 0)
- **Conflict**: Similar to Fuzzy + Min

## Implementation Notes

### Default Weight Assignment

Default weights for unweighted assumptions are now defined in **monoid files** (`monoid/*.lp`), not semiring files. This is because the monoid determines what "hard to discard" means:

- `monoid/max.lp`: Default = #sup (largest is hardest)
- `monoid/sum.lp`: Default = #sup (largest contribution)
- `monoid/min.lp`: Default = 0 (smallest is hardest)

### Semiring Responsibilities

Semirings (`semiring/*.lp`) only handle:
1. Explicit weight propagation through rules
2. Empty body rules (facts) using conjunction identity

Facts use hardcoded identities:
- Fuzzy: 100 (identity for min)
- Tropical: 0 (identity for +)
- Boolean: 1 (identity for ∧)

## Recommendations

### Safe Combinations (Use These)

**For classical weight semantics:**
- Fuzzy + Max (original WABA)
- Fuzzy + Sum (cumulative costs)

**For additive weight semantics:**
- Tropical + Min (unique valid combination)

**For binary decision-making:**
- Boolean + Max (worst attack matters)
- Boolean + Sum (count all attacks)

### Unsafe Combinations (Avoid)

**Mathematically inconsistent:**
- Fuzzy + Min ✗
- Tropical + Max ✗
- Tropical + Sum ✗
- Boolean + Min ✗

These combinations work syntactically but have **conflicting semantics** for unweighted assumptions. They may produce unexpected results.

## Testing Legal Pairs

All legal combinations are tested in `test_combinations.sh`:

```bash
# Test all combinations (includes illegal ones currently)
./test_combinations.sh Examples/medical.lp stable

# Test specific legal pair
clingo -n 0 core_base.lp semiring/fuzzy.lp monoid/max.lp \
       filter.lp Semantics/stable.lp Examples/medical.lp
```

Future work: Add warnings or errors for incompatible pairs.
