# WABA Quick Reference

## Command Template

```bash
clingo -n 0 \
  WABA/core/base.lp \
  WABA/semiring/<semiring>.lp \
  WABA/monoid/<monoid>.lp \
  WABA/filter/standard.lp \
  [WABA/optimize/minimize.lp] \
  WABA/semantics/<semantics>.lp \
  <your_framework>.lp
```

## Common Combinations

### Original WABA (Fuzzy + Max)
```bash
# Stable semantics
clingo -n 0 WABA/core/base.lp WABA/semiring/godel.lp WABA/monoid/max.lp \
       WABA/filter/standard.lp WABA/semantics/stable.lp <framework>.lp

# Conflict-free semantics
clingo -n 0 WABA/core/base.lp WABA/semiring/godel.lp WABA/monoid/max.lp \
       WABA/filter/standard.lp WABA/semantics/cf.lp <framework>.lp

# Naive semantics (requires special flags)
clingo -n 0 --heuristic=Domain --enum=domRec \
       WABA/core/base.lp WABA/semiring/godel.lp WABA/monoid/max.lp \
       WABA/filter/standard.lp WABA/semantics/naive.lp <framework>.lp
```

### With Cost Minimization
```bash
clingo -n 0 WABA/core/base.lp WABA/semiring/godel.lp WABA/monoid/max.lp \
       WABA/filter/standard.lp WABA/optimize/minimize.lp WABA/semantics/stable.lp <framework>.lp
```

### Other Semiring/Monoid Combinations

**Tropical + Max** (Addition for conjunction):
```bash
clingo -n 0 WABA/core/base.lp WABA/semiring/tropical.lp WABA/monoid/max.lp \
       WABA/filter/standard.lp WABA/semantics/stable.lp <framework>.lp
```

**Fuzzy + Sum** (Sum cost aggregation):
```bash
clingo -n 0 WABA/core/base.lp WABA/semiring/godel.lp WABA/monoid/sum.lp \
       WABA/filter/standard.lp WABA/semantics/stable.lp <framework>.lp
```


**Łukasiewicz + Max** (Bounded sum logic):
```bash
clingo -n 0 WABA/core/base.lp WABA/semiring/lukasiewicz.lp WABA/monoid/max.lp \
       WABA/filter/standard.lp WABA/semantics/stable.lp <framework>.lp
```

**Fuzzy + Count** (Weight-agnostic counting):
```bash
clingo -n 0 -c beta=2 WABA/core/base.lp WABA/semiring/godel.lp WABA/monoid/count.lp \
       WABA/filter/standard.lp WABA/semantics/stable.lp <framework>.lp
```

**Fuzzy + Lex with Optimization** (Lexicographic minimization):
```bash
clingo -n 0 WABA/core/base.lp WABA/semiring/godel.lp WABA/monoid/lex.lp \
       WABA/filter/lexicographic.lp WABA/optimize/lexicographic.lp WABA/semantics/stable.lp <framework>.lp
```

**Tropical + Min with Maximization** (Quality threshold):
```bash
clingo -n 0 -c beta=10 WABA/core/base.lp WABA/semiring/tropical.lp WABA/monoid/min.lp \
       WABA/filter/standard.lp WABA/optimize/maximize.lp WABA/semantics/stable.lp <framework>.lp
```

## Available Modules

**Semirings** (in `WABA/semiring/`):
- `godel.lp` - Gödel/Fuzzy logic (min/max, identity=#sup) - **original WABA**
- `tropical.lp` - Tropical semiring (min/+, identity=#sup)
- `lukasiewicz.lp` - Łukasiewicz logic (bounded sum, identity=#sup)

**Monoids** (in `WABA/monoid/`):
- `max.lp` - Maximum cost (original WABA)
- `sum.lp` - Sum of costs
- `min.lp` - Minimum cost (quality threshold semantics)
- `count.lp` - Count of discarded attacks (weight-agnostic)
- `lex.lp` - Lexicographic cost (max→sum→count priority)

**Semantics** (in `WABA/semantics/`):
- `stable.lp` - Stable semantics (use `-n 0`)
- `cf.lp` - Conflict-free semantics (use `-n 0`)
- `naive.lp` - Naive semantics (use `-n 0 --heuristic=Domain --enum=domRec`)

## ⚠️ Legal Semiring/Monoid Pairs

**Not all combinations are compatible!** See `SEMIRING_MONOID_COMPATIBILITY.md` for details.

**Legal Combinations (9):**
- ✓ Fuzzy + Max (weight: #sup)
- ✓ Fuzzy + Sum (weight: #sup)
- ✓ Fuzzy + Count/Lex (weight: #sup)
- ✓ Tropical + Min (weight: 0)
- ✓ Tropical + Count/Lex (weight: #sup)
- ✓ Boolean + Max (weight: 1)
- ✓ Boolean + Sum (weight: 1)
- ✓ Boolean + Count/Lex (weight: 1)

**Illegal Combinations (3):**
- ✗ Fuzzy + Min (conflicting requirements)
- ✗ Tropical + Max/Sum (conflicting requirements)
- ✗ Boolean + Min (conflicting requirements)

## Budget Parameter

**IMPORTANT**: Always set a budget!

**Option 1**: In your framework file
```prolog
budget(100).  % Can discard attacks up to cost 100
```

**Option 2**: Via command line
```bash
clingo -c beta=100 WABA/core/base.lp ...
```

**Common budget values**:
- `budget(0)` - Strictest (classical ABA, no discarding)
- `budget(<max_weight>)` - Can discard ~1 attack
- `budget(<sum/2>)` - Can discard ~half the attacks
- `budget(<sum_all>)` - Can discard all attacks

## Łukasiewicz Normalization Constant

**For Łukasiewicz semiring only**: The normalization constant K determines the weight scale.

**Default**: K = 100 (weights in [0,100])

**Override via command line**:
```bash
# Use [0,1] scale (standard Łukasiewicz logic)
clingo -c luk_k=1 WABA/core/base.lp WABA/semiring/lukasiewicz.lp ...

# Use [0,1000] scale (finer granularity)
clingo -c luk_k=1000 WABA/core/base.lp WABA/semiring/lukasiewicz.lp ...
```

**Effect on formulas**:
- Conjunction: `max(0, sum(weights) - K*(n-1))`
- Disjunction: `min(K, sum(weights))`

**When to adjust**:
- K=1: When using weights in [0,1] (standard fuzzy logic)
- K=100: Default for [0,100] integer weights (good balance)
- K=1000: When you need fine-grained distinctions between weights

## Examples

```bash
# Medical ethics example with original WABA
clingo -n 0 WABA/core/base.lp WABA/semiring/godel.lp WABA/monoid/max.lp \
       WABA/filter/standard.lp WABA/semantics/stable.lp WABA/examples/medical.lp

# Simple example with tropical semiring and cost minimization
clingo -n 0 WABA/core/base.lp WABA/semiring/tropical.lp WABA/monoid/max.lp \
       WABA/filter/standard.lp WABA/optimize/minimize.lp WABA/semantics/stable.lp WABA/examples/simple.lp

# Łukasiewicz with custom normalization constant K=1 (standard [0,1] scale)
clingo -n 0 -c luk_k=1 WABA/core/base.lp WABA/semiring/lukasiewicz.lp WABA/monoid/max.lp \
       WABA/filter/standard.lp WABA/semantics/stable.lp <framework_with_weights_0_to_1>.lp
```

## Output Predicates

Expected output (via filter/standard.lp):
- `in(X)` - Assumptions in the extension
- `supported_with_weight(X, W)` - Supported elements with their weights
- `attacks_successfully_with_weight(X, Y, W)` - Successful attacks
- `extension_cost(C)` - Total cost of the extension

## ABA-Compatibility (Semiring–Monoid)

**Definitions:**
- **Semiring** S = (D, ⊕, ⊗, 0_S, 1_S) where ⊕ aggregates disjunction, ⊗ aggregates conjunction
- **Monoid** M = (D, ⊙, e_M, ⪯) where ⊙ aggregates discarded attack costs, ⪯ is the ordering
- **Default weight** δ assigned to atoms without explicit `weight/2` declarations

**Budget Regimes:**
- **Upper Bound (UB)**: Accept extension iff Cost ⪯ β (Max, Sum, Count, Lex monoids)
- **Lower Bound (LB)**: Accept extension iff β ⪯ Cost (Min monoid, flipped constraint)

**Proposition (Sufficient conditions for ABA-compatibility):**

A (semiring, monoid, budget) triple reconstructs classical ABA (no discarding) when:
1. Default weight δ = 1_S (propagation neutrality: x ⊗ δ = x)
2. δ absorbs or dominates under ⊙ (e.g., δ ⊙ x ⪰ δ for all x)
3. Budget excludes one default discard:
   - UB regime: ¬(δ ⪯ β)
   - LB regime: ¬(β ⪯ δ)

**Proof sketch:** Suppose an extension discards ≥1 attack. By (1), unweighted atoms propagate δ through rules, so discarded attacks have weight δ. By (2), the aggregate cost satisfies Cost ⪰ δ (UB) or Cost ⪯ δ (LB). By (3), this violates the budget constraint. Hence no discards are possible, collapsing WABA to ABA on unweighted instances. ∎

**Examples:**
- Fuzzy + Max (UB): δ = #sup, β = 0 → max(#sup, ...) = #sup ⊁ 0 ✓
- Tropical + Min (LB): δ = 0, β = 1 → min(0, ...) = 0 ⊀ 1 ✓
- Boolean + Count (UB): δ = 1, β = 0 → count ≥ 1 ⊁ 0 ✓
