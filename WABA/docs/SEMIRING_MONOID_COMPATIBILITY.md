# Semiring-Monoid Compatibility: Theory and Practice

## Executive Summary

**All semiring/monoid combinations in WABA are computationally well-defined and semantically meaningful.** Earlier documentation suggested certain combinations were "incompatible," but empirical testing has proven this false.

The notion of "compatibility" refers to a **narrow theoretical property**: whether a (semiring, monoid, budget) configuration can recover classical ABA behavior (no attack discarding) with specific default weights. This does NOT mean "incompatible" combinations are broken or useless—they simply require different (δ, β) configurations to achieve ABA recovery.

## Key Findings

### What Changed

**Old theory claimed:**
- Only 9 semiring/monoid pairs were "legal"
- Gödel + MIN, Tropical + MAX, Tropical + SUM were "incompatible"
- Some combinations had "conflicting semantics"

**Empirical testing proved:**
- ✓ All 25 semiring×monoid combinations work correctly
- ✓ All combinations produce semantically meaningful results
- ✓ All combinations can recover classical ABA with appropriate (δ, β) settings
- ✓ "Incompatibility" only referred to one narrow ABA recovery path

### What "Compatibility" Actually Means

A (semiring, monoid, budget) triple is "ABA-compatible" if it prevents all attack discarding on unweighted frameworks. This requires:

1. **Default weight (δ)** assigned to unweighted assumptions
2. **Budget constraint (β)** that rejects discarding attacks with weight δ
3. **Mechanism** (explicit constraint rules or mathematical properties) that enforces the rejection

**Example** (Gödel + MAX + UB):
- δ = #sup (unweighted assumptions get infinite weight)
- β = 0 (budget is zero)
- Mechanism: `constraint/ub.lp` explicitly rejects discarding #sup-weighted attacks
- Result: No attacks can be discarded → classical ABA recovered

## All Semiring-Monoid Combinations Work

Here are examples demonstrating that ALL combinations are valid:

### Gödel Semiring (min/max)

| Monoid | Status | Default δ | Budget β | Mechanism |
|--------|--------|-----------|----------|-----------|
| MAX (UB) | ✓ Works | #sup | 0 | UB constraint rejects #sup discards |
| SUM (UB) | ✓ Works | #sup | 0 | UB constraint rejects #sup discards |
| MIN (LB) | ✓ Works | #inf | 0 | MIN(#inf) = #inf < 0, rejected |
| COUNT (UB) | ✓ Works | #sup | 0 | UB constraint rejects #sup discards |
| LEX (UB) | ✓ Works | #sup | 0 | UB constraint rejects #sup discards |

### Tropical Semiring (+/min)

| Monoid | Status | Default δ | Budget β | Mechanism |
|--------|--------|-----------|----------|-----------|
| MAX (UB) | ✓ Works | #sup | 0 | UB constraint rejects #sup discards |
| SUM (UB) | ✓ Works | #sup | 0 | UB constraint rejects #sup discards |
| MIN (LB) | ✓ Works | #inf | 0 | MIN(#inf) = #inf < 0, rejected |
| COUNT (UB) | ✓ Works | #sup | 0 | UB constraint rejects #sup discards |
| LEX (UB) | ✓ Works | #sup | 0 | UB constraint rejects #sup discards |

### Łukasiewicz Semiring (bounded-sum/bounded-sum)

| Monoid | Status | Default δ | Budget β | Mechanism |
|--------|--------|-----------|----------|-----------|
| MAX (UB) | ✓ Works | #sup | 0 | UB constraint rejects #sup discards |
| SUM (UB) | ✓ Works | #sup | 0 | UB constraint rejects #sup discards |
| MIN (LB) | ✓ Works | #inf | 0 | MIN(#inf) = #inf < 0, rejected |
| COUNT (UB) | ✓ Works | #sup | 0 | UB constraint rejects #sup discards |
| LEX (UB) | ✓ Works | #sup | 0 | UB constraint rejects #sup discards |

### Arctic Semiring (+/max)

| Monoid | Status | Default δ | Budget β | Mechanism |
|--------|--------|-----------|----------|-----------|
| MAX (UB) | ✓ Works | 0 | #inf* | Any discard cost ≥ 0 > #inf |
| SUM (UB) | ✓ Works | 0 | #inf* | Sum ≥ 0 > #inf |
| MIN (LB) | ✓ Works | 0 | #sup | MIN(0) = 0 < #sup |
| COUNT (UB) | ✓ Works | 0 | #inf* | Count ≥ 1 > #inf |
| LEX (UB) | ✓ Works | 0 | #inf* | First component > #inf |

*Note: β = #inf must be set in framework file (not via CLI)

### Bottleneck-Cost Semiring (max/min)

| Monoid | Status | Default δ | Budget β | Mechanism |
|--------|--------|-----------|----------|-----------|
| MAX (UB) | ✓ Works | #sup | 0 | UB constraint rejects #sup discards |
| SUM (UB) | ✓ Works | #sup | 0 | UB constraint rejects #sup discards |
| MIN (LB) | ✓ Works | #inf | 0 | MIN(#inf) = #inf < 0, rejected |
| COUNT (UB) | ✓ Works | #sup | 0 | UB constraint rejects #sup discards |
| LEX (UB) | ✓ Works | #sup | 0 | UB constraint rejects #sup discards |

## Budget Regimes

WABA has two budget constraint modes:

### Upper Bound (UB) Regime
- **Constraint**: `extension_cost ≤ β`
- **File**: `constraint/ub.lp`
- **Monoids**: MAX, SUM, COUNT, LEX
- **Interpretation**: "Don't exceed budget β"

### Lower Bound (LB) Regime
- **Constraint**: `extension_cost ≥ β`
- **File**: `constraint/lb.lp`
- **Monoids**: MIN
- **Interpretation**: "Meet minimum quality threshold β"

**Important**: You must explicitly load the constraint file for budget enforcement to work.

## Universal ABA Recovery Patterns

Despite semiring diversity, two universal patterns emerge:

### Pattern 1: #sup-based Semirings
(Gödel, Tropical, Łukasiewicz, Bottleneck-Cost)

**For UB regime** (MAX/SUM/COUNT/LEX):
```prolog
δ = #sup  % Default weight
β = 0     % Budget
```
- Mechanism: `constraint/ub.lp` line 41 explicitly rejects #sup discards
- Formula: `:- discarded_attack(_,_,#sup), budget(B), B != #sup.`

**For LB regime** (MIN):
```prolog
δ = #inf  % Default weight
β = 0     % Budget
```
- Mechanism: `constraint/lb.lp` computes MIN(#inf) = #inf < 0, rejects
- Alternative: δ = #sup with special LB constraint (line 43)

### Pattern 2: 0-based Semiring
(Arctic)

**For UB regime** (MAX/SUM/COUNT/LEX):
```prolog
δ = 0      % Default weight
β = #inf   % Budget (must be set in framework file!)
```
- Mechanism: Any discard gives cost ≥ 0 > #inf
- Cannot use `-c beta=#inf` (clingo limitation)

**For LB regime** (MIN):
```prolog
δ = 0      % Default weight
β = #sup   % Budget
```
- Mechanism: MIN(0) = 0 < #sup, rejected

**Alternative uniform approach for Arctic**:
```prolog
δ = #sup, β = 0  % Works for all monoids (but less natural)
```

## Semantic Interpretation Guide

Each combination has clear semantics for weighted argumentation:

### Gödel + MAX (UB)
- **Propagation**: Weakest-link (min for AND)
- **Aggregation**: Worst single attack matters (max)
- **Use case**: "We're only as strong as our weakest argument, reject if worst discarded attack exceeds budget"

### Tropical + SUM (UB)
- **Propagation**: Additive costs (+ for AND)
- **Aggregation**: Total cost matters (sum)
- **Use case**: "Arguments accumulate costs, reject if total discarded cost exceeds budget"

### Tropical + MIN (LB)
- **Propagation**: Additive costs (+ for AND)
- **Aggregation**: Best discarded attack matters (min)
- **Use case**: "Arguments accumulate costs, require minimum quality threshold"

### Arctic + MAX (UB)
- **Propagation**: Additive rewards (+ for AND)
- **Aggregation**: Best single benefit matters (max)
- **Use case**: "Arguments accumulate benefits, maximize best gained reward"

### Bottleneck-Cost + MIN (LB)
- **Propagation**: Worst-case penalty (max for AND)
- **Aggregation**: Best bottleneck matters (min)
- **Use case**: "Chains limited by worst component, optimize best worst-case"

## Implementation Notes

### Default Weight Assignment

**Current design**: Semiring files assign default weights based on mathematical identities:
- Gödel, Tropical, Łukasiewicz, Bottleneck: δ = #sup (or #inf for Bottleneck conjunction identity)
- Arctic: δ = 0

**To override**: Add explicit `weight/2` declarations in your framework file:
```prolog
assumption(a).
weight(a, #inf).  % Override default for LB regime
```

### Budget Setting

**Method 1**: In framework file (recommended)
```prolog
budget(0).      % Most common for ABA recovery
budget(#inf).   % For Arctic UB (CLI can't handle #inf)
budget(#sup).   % For Arctic LB
```

**Method 2**: Via CLI (for finite values only)
```bash
clingo -c beta=100 ...
```

### Constraint Loading

**Critical**: Budget constraints are NOT automatic. You must load them:

```bash
# For MAX/SUM/COUNT/LEX (UB regime)
clingo ... constraint/ub.lp ...

# For MIN (LB regime)
clingo ... constraint/lb.lp ...
```

Without constraints, budget enforcement is disabled and results will be meaningless.

## Complete Examples

### Gödel + MAX (original WABA)
```bash
clingo -n 0 -c beta=0 \
  core/base.lp semiring/godel.lp monoid/baseline/max.lp constraint/ub.lp \
  filter/standard.lp semantics/stable.lp framework.lp
```

### Tropical + MIN (quality threshold)
```bash
# Framework must have: weight(a, #inf). for all assumptions
clingo -n 0 -c beta=0 \
  core/base.lp semiring/tropical.lp monoid/baseline/min.lp constraint/lb.lp \
  filter/standard.lp semantics/stable.lp framework_with_inf_weights.lp
```

### Arctic + MAX (reward maximization)
```bash
# Framework must have: budget(#inf).
clingo -n 0 \
  core/base.lp semiring/arctic.lp monoid/baseline/max.lp constraint/ub.lp \
  filter/standard.lp semantics/stable.lp framework_with_inf_budget.lp
```

## Further Reading

- **[ABA_RECOVERY_REFERENCE.md](ABA_RECOVERY_REFERENCE.md)** - Complete table of (δ, β) pairs for all combinations
- **[COMPATIBILITY_INVESTIGATION.md](../test/COMPATIBILITY_INVESTIGATION.md)** - Empirical testing that disproved old theory
- **[ABA_RECOVERY_RESULTS.md](../test/ABA_RECOVERY_RESULTS.md)** - Detailed analysis and proofs
- Individual semiring files (`semiring/*.lp`) - Inline ABA recovery documentation

## Conclusion

**Every semiring/monoid combination is valid and useful.** Choose based on your application's semantics, not on outdated "compatibility" restrictions. All combinations can recover classical ABA with appropriate configuration—see [ABA_RECOVERY_REFERENCE.md](ABA_RECOVERY_REFERENCE.md) for the exact settings.
