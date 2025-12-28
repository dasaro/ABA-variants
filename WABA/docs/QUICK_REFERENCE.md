# WABA Quick Reference

## Command Template

```bash
clingo -n 0 \
  WABA/core/base.lp \
  WABA/semiring/<semiring>.lp \
  WABA/monoid/<monoid>.lp \
  WABA/constraint/<ub_or_lb>.lp \     # Choose ub.lp or lb.lp
  WABA/filter/standard.lp \
  [WABA/optimize/minimize.lp] \       # Optional: minimize cost
  WABA/semantics/<semantics>.lp \
  <your_framework>.lp
```

**Quick rule**: Use `constraint/ub.lp` for MAX/SUM/COUNT, use `constraint/lb.lp` for MIN.

## Common Combinations

### Original WABA (Fuzzy + Max)
```bash
# Stable semantics
clingo -n 0 WABA/core/base.lp WABA/semiring/godel.lp WABA/monoid/max_minimization.lp \
       WABA/filter/standard.lp WABA/semantics/stable.lp <framework>.lp

# Conflict-free semantics
clingo -n 0 WABA/core/base.lp WABA/semiring/godel.lp WABA/monoid/max_minimization.lp \
       WABA/filter/standard.lp WABA/semantics/cf.lp <framework>.lp

# Naive semantics (requires special flags)
clingo -n 0 --heuristic=Domain --enum=domRec \
       WABA/core/base.lp WABA/semiring/godel.lp WABA/monoid/max_minimization.lp \
       WABA/filter/standard.lp WABA/semantics/naive.lp <framework>.lp
```

### With Cost Minimization
```bash
clingo -n 0 WABA/core/base.lp WABA/semiring/godel.lp WABA/monoid/max_minimization.lp \
       WABA/filter/standard.lp WABA/optimize/minimize.lp WABA/semantics/stable.lp <framework>.lp
```

### Other Semiring/Monoid Combinations

**Tropical + Max** (Addition for conjunction):
```bash
clingo -n 0 WABA/core/base.lp WABA/semiring/tropical.lp WABA/monoid/max_minimization.lp \
       WABA/filter/standard.lp WABA/semantics/stable.lp <framework>.lp
```

**Fuzzy + Sum** (Sum cost aggregation):
```bash
clingo -n 0 WABA/core/base.lp WABA/semiring/godel.lp WABA/monoid/sum_minimization.lp \
       WABA/filter/standard.lp WABA/semantics/stable.lp <framework>.lp
```


**Łukasiewicz + Max** (Bounded sum logic):
```bash
clingo -n 0 WABA/core/base.lp WABA/semiring/lukasiewicz.lp WABA/monoid/max_minimization.lp \
       WABA/filter/standard.lp WABA/semantics/stable.lp <framework>.lp
```

**Arctic + Max** (Reward maximization):
```bash
clingo -n 0 WABA/core/base.lp WABA/semiring/arctic.lp WABA/monoid/max_minimization.lp \
       WABA/filter/standard.lp WABA/semantics/stable.lp <framework>.lp
```

**Bottleneck-cost + Min** (Worst-case minimization):
```bash
clingo -n 0 WABA/core/base.lp WABA/semiring/bottleneck_cost.lp WABA/monoid/min_minimization.lp \
       WABA/filter/standard.lp WABA/semantics/stable.lp <framework>.lp
```

**Fuzzy + Count** (Weight-agnostic counting):
```bash
clingo -n 0 -c beta=2 WABA/core/base.lp WABA/semiring/godel.lp WABA/monoid/count_minimization.lp \
       WABA/filter/standard.lp WABA/semantics/stable.lp <framework>.lp
```

**Fuzzy + Lex with Optimization** (Lexicographic minimization):
```bash
clingo -n 0 WABA/core/base.lp WABA/semiring/godel.lp WABA/monoid/lex_minimization.lp \
       WABA/filter/lexicographic.lp WABA/optimize/lexicographic.lp WABA/semantics/stable.lp <framework>.lp
```

**Tropical + Min with Maximization** (Quality threshold):
```bash
clingo -n 0 -c beta=10 WABA/core/base.lp WABA/semiring/tropical.lp WABA/monoid/min_minimization.lp \
       WABA/filter/standard.lp WABA/optimize/maximize.lp WABA/semantics/stable.lp <framework>.lp
```

## Fast Optimization with Suffix Naming

**Use `{monoid}_{direction}.lp` for 1000x speedup (works in both optimization and enumeration modes):**

### Sum Monoid (CRITICAL for Tropical/Arctic)
```bash
# Minimize total cost (1000x speedup)
clingo -n 0 --opt-mode=opt WABA/core/base.lp WABA/semiring/tropical.lp \
       WABA/monoid/sum_minimization.lp WABA/filter/standard.lp \
       WABA/semantics/stable.lp <framework>.lp

# Maximize total reward (1000x speedup)
clingo -n 0 --opt-mode=opt WABA/core/base.lp WABA/semiring/tropical.lp \
       WABA/monoid/sum_maximization.lp WABA/filter/standard.lp \
       WABA/semantics/stable.lp <framework>.lp

# SLOW (grounding explosion) - Avoid with Tropical/Arctic
clingo ... WABA/monoid/sum_minimization.lp WABA/optimize/minimize.lp ...
```

### Max Monoid
```bash
# Minimize max cost (worst-case minimization)
clingo -n 0 --opt-mode=opt ... WABA/monoid/max_minimization.lp ...

# Maximize max reward (best single reward)
clingo -n 0 --opt-mode=opt ... WABA/monoid/max_maximization.lp ...
```

### Min Monoid
```bash
# Minimize min cost
clingo -n 0 --opt-mode=opt ... WABA/monoid/min_minimization.lp ...

# Maximize min quality (quality threshold)
clingo -n 0 --opt-mode=opt ... WABA/monoid/min_maximization.lp ...
```

### Enumeration Mode

**The `_minimization` and `_maximization` files work in enumeration mode too:**

```bash
# Enumerate with cost minimization display
clingo -n 10 WABA/core/base.lp WABA/semiring/tropical.lp \
       WABA/monoid/sum_minimization.lp WABA/filter/standard.lp \
       WABA/semantics/stable.lp <framework>.lp
# Shows "Optimization: N" after each answer

# Enumerate with reward maximization display
clingo -n 10 ... WABA/monoid/sum_maximization.lp ...
# Shows "Optimization: -N" (negate for actual reward)
```

**Performance Note:**
- `sum_minimization/maximization.lp` achieve 1000x+ speedup with Tropical/Arctic semirings
- `_minimization` = minimize (cost semantics), `_maximization` = maximize (reward semantics)
- All variants work in BOTH optimization and enumeration modes
- All produce identical results to their non-optimized counterparts

**Cost vs Reward:**
- `_minimization` files: Minimize (weights = costs to avoid)
- `_maximization` files: Maximize (weights = rewards to pursue)

## Three Enumeration Modes

WABA supports three distinct enumeration modes, each with different performance characteristics:

### Mode 1: old_enum (Baseline)
Uses explicit `extension_cost/1` predicate. Enumerates all stable extensions.

```bash
clingo -n 0 --stats=2 \
  WABA/core/base.lp \
  WABA/semiring/godel.lp \
  WABA/monoid/sum_minimization.lp \              # Old monoid file
  WABA/filter/standard.lp \
  WABA/constraint/flat.lp \
  WABA/semantics/stable.lp \
  framework.lp
```

**Characteristics:**
- ✓ Compatible with all semirings and monoids
- ✗ Large grounding size (especially arctic/bottleneck)
- ✗ Slower execution

### Mode 2: new_enum (Optimized Enumeration)
No `extension_cost/1` predicate. Enumerates all stable extensions using `--opt-mode=ignore`.

```bash
clingo -n 0 --opt-mode=ignore --stats=2 \
  WABA/core/base.lp \
  WABA/semiring/godel.lp \
  WABA/monoid/sum_minimization.lp \ # New monoid file with #minimize
  WABA/filter/standard.lp \
  WABA/constraint/flat.lp \
  WABA/semantics/stable.lp \
  framework.lp
```

**Characteristics:**
- ✓ **58-78% grounding reduction** (godel/tropical/lukasiewicz)
- ✓ **Essential for arctic/bottleneck** (old_enum times out)
- ✓ Same results as old_enum (all models)
- ✓ Extension cost reconstructible from optimizer output

### Mode 3: new_opt (Optimal Enumeration)
No `extension_cost/1` predicate. Finds all optimal stable extensions using `--opt-mode=optN`.

**Minimization:**
```bash
clingo -n 0 --opt-mode=optN --stats=2 \
  WABA/core/base.lp \
  WABA/semiring/godel.lp \
  WABA/monoid/sum_minimization.lp \ # New monoid with #minimize
  WABA/filter/standard.lp \
  WABA/constraint/flat.lp \
  WABA/semantics/stable.lp \
  framework.lp
```

**Maximization:**
```bash
clingo -n 0 --opt-mode=optN --stats=2 \
  WABA/core/base.lp \
  WABA/semiring/godel.lp \
  WABA/monoid/sum_maximization.lp \ # New monoid with #maximize
  WABA/filter/standard.lp \
  WABA/constraint/flat.lp \
  WABA/semantics/stable.lp \
  framework.lp
```

**Characteristics:**
- ✓ Finds only optimal extensions (subset of all models)
- ✓ Same grounding benefits as new_enum
- ✓ Faster (stops after finding all optimal)
- ✓ Supports both minimization and maximization

### Performance Comparison

| Semiring       | Grounding Reduction | old_enum → new_enum Speedup |
|----------------|---------------------|------------------------------|
| Gödel          | 58%                 | ~3x                          |
| Tropical       | 74%                 | ~400x                        |
| Łukasiewicz    | 78%                 | ~5x                          |
| Arctic         | TIMEOUT → works     | Essential                    |
| Bottleneck     | TIMEOUT → works     | Essential                    |

**Recommendation:** Always use `new_enum` or `new_opt` for production. Use `old_enum` only for validation.

## Available Modules

**Semirings** (in `WABA/semiring/`):
- `godel.lp` - Gödel/Fuzzy logic (min/max, identity=#sup) - **original WABA**
- `tropical.lp` - Tropical semiring (+/min, cost minimization, identity=#sup)
- `arctic.lp` - Arctic semiring (+/max, reward maximization, dual of Tropical)
- `lukasiewicz.lp` - Łukasiewicz logic (bounded sum, identity=#sup, parametrizable K)
- `bottleneck_cost.lp` - Bottleneck-cost (max/min, worst-case optimization)

**Monoids** (in `WABA/monoid/`):
- `max.lp` - Maximum cost (original WABA)
- `sum.lp` - Sum of costs
- `min.lp` - Minimum cost (quality threshold semantics)
- `count.lp` - Count of discarded attacks (weight-agnostic)
- `lex.lp` - Lexicographic cost (max→sum→count priority)

**Optimized Monoids** (direct `#minimize`/`#maximize`, 1000x faster):
- `sum_minimization.lp` / `sum_maximization.lp` - Sum minimization/maximization
- `max_minimization.lp` / `max_maximization.lp` - Max minimization/maximization
- `min_minimization.lp` / `min_maximization.lp` - Min minimization/maximization
- `count_minimization.lp` / `count_maximization.lp` - Count minimization/maximization
- `lex_minimization.lp` / `lex_maximization.lp` - Lexicographic minimization/maximization

**Naming:** `{monoid}_{direction}.lp` where `minimization`=minimize/cost, `maximization`=maximize/reward

**Semantics** (in `WABA/semantics/`):
- `stable.lp` - Stable semantics (use `-n 0`)
- `cf.lp` - Conflict-free semantics (use `-n 0`)
- `naive.lp` - Naive semantics (use `-n 0 --heuristic=Domain --enum=domRec`)

## Semiring/Monoid Combinations

**All semiring/monoid combinations are valid and semantically meaningful!**

Earlier documentation claimed some pairs were "incompatible," but empirical testing proved all 25 combinations work correctly. The key is using appropriate (δ, β) values for ABA recovery.

**For detailed guidance**:
- See `SEMIRING_MONOID_COMPATIBILITY.md` for semantic interpretations of each combination
- See `ABA_RECOVERY_REFERENCE.md` for (δ, β) settings to recover classical ABA

**Common patterns**:
- Most semirings with UB monoids (MAX/SUM/COUNT/LEX): Use δ=#sup, β=0
- Most semirings with LB monoid (MIN): Use δ=#inf, β=0
- Arctic semiring: Use δ=0 with β=#inf (UB) or β=#sup (LB)

## Budget Constraints

**IMPORTANT**: Budget constraints are now **modular** - include the appropriate constraint file!

### Command Structure

```bash
clingo -n 0 \
  WABA/core/base.lp \
  WABA/semiring/<semiring>.lp \
  WABA/monoid/<monoid>.lp \
  WABA/constraint/<ub_or_lb>.lp \    # ← Add this!
  WABA/filter/standard.lp \
  WABA/semantics/<semantics>.lp \
  <framework>.lp
```

### Choosing UB vs LB

| Monoid | Standard Constraint | Semantics |
|--------|-------------------|-----------|
| MAX, SUM, COUNT, LEX | `constraint/ub.lp` | Cost ceiling (cost ≤ β) |
| MIN | `constraint/lb.lp` | Quality threshold (quality ≥ β) |

**Advanced**: MIN can also use UB (forbid strong discards), and MAX/SUM/COUNT can use LB (require minimum cost). See `constraint/README.md` for details.

### Setting Budget Values

**Option 1**: Via command line (recommended)
```bash
clingo -c beta=100 WABA/constraint/ub.lp ...
```

**Option 2**: In your framework file (overrides constraint default)
```prolog
budget(100).  % Can discard attacks up to cost 100
```

### Common Budget Values

**For MAX/SUM/COUNT with UB** (cost ceiling):
- `-c beta=0` - Classical ABA (no discarding)
- `-c beta=50` - Can discard attacks up to total cost 50
- No `-c beta` - Uses default `#sup` (permissive, all allowed)

**For MIN with LB** (quality threshold):
- `-c beta=50` - Require min(discarded) ≥ 50 (strong attacks only)
- `-c beta=0` - Require min(discarded) ≥ 0 (no negative weights)
- No `-c beta` - Uses default `#inf` (permissive, all allowed)

### Examples

```bash
# MAX monoid with cost ceiling (standard)
clingo -c beta=100 WABA/core/base.lp WABA/semiring/godel.lp \
       WABA/monoid/max_minimization.lp WABA/constraint/ub.lp WABA/semantics/stable.lp ...

# MIN monoid with quality threshold (standard)
clingo -c beta=50 WABA/core/base.lp WABA/semiring/tropical.lp \
       WABA/monoid/min_minimization.lp WABA/constraint/lb.lp WABA/semantics/stable.lp ...
```

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
clingo -n 0 WABA/core/base.lp WABA/semiring/godel.lp WABA/monoid/max_minimization.lp \
       WABA/filter/standard.lp WABA/semantics/stable.lp WABA/examples/medical.lp

# Simple example with tropical semiring and cost minimization
clingo -n 0 WABA/core/base.lp WABA/semiring/tropical.lp WABA/monoid/max_minimization.lp \
       WABA/filter/standard.lp WABA/optimize/minimize.lp WABA/semantics/stable.lp WABA/examples/simple.lp

# Łukasiewicz with custom normalization constant K=1 (standard [0,1] scale)
clingo -n 0 -c luk_k=1 WABA/core/base.lp WABA/semiring/lukasiewicz.lp WABA/monoid/max_minimization.lp \
       WABA/filter/standard.lp WABA/semantics/stable.lp <framework_with_weights_0_to_1>.lp
```

## Output Predicates

Expected output (via filter/standard.lp):
- `in(X)` - Assumptions in the extension
- `supported_with_weight(X, W)` - Supported elements with their weights
- `attacks_successfully_with_weight(X, Y, W)` - Successful attacks
- `extension_cost(C)` - Total cost of the extension

## Probabilistic Reasoning (Viterbi via Log Transformation)

**WABA supports probabilistic argumentation** through the Tropical semiring with log-transformed weights.

### The Trick

The **Viterbi semiring** (×, max) for probabilities is mathematically equivalent to the **Tropical semiring** (+, min) for costs:

```
Transformation: cost = round(-log(probability) × 1000)

Viterbi (probabilities)     →  Tropical (costs)
────────────────────────────────────────────────
p₁ × p₂  (multiply)         →  cost₁ + cost₂  (add)
max(p₁, p₂)  (best)         →  min(cost₁, cost₂)  (cheapest)
Higher probability          →  Lower cost
Maximize probability        →  Minimize cost
```

### Example: Medical Diagnosis

```bash
# Run probabilistic diagnosis example
clingo -n 0 core/base.lp semiring/tropical.lp monoid/min_minimization.lp constraint/lb.lp \
       filter/standard.lp semantics/stable.lp examples/viterbi_simulation.lp
```

**Scenario**: Choose between FLU, COVID, COLD based on symptom evidence
- FLU: 0.536 probability → cost 625
- COVID: 0.574 probability → cost 556
- COLD: 0.595 probability → cost 520 ✓ **Winner** (lowest cost)

**Result**: 3 stable extensions (one per diagnosis). Extension with **lowest diagnosis cost** = **highest probability** explanation.

### Applications

- Medical diagnosis with symptom reliability
- Sensor fusion with sensor accuracy
- Legal reasoning with witness credibility
- Expert systems with expert confidence
- Any scenario with independent probabilistic evidence

**See**: `examples/viterbi_simulation.lp` and `examples/VITERBI_SIMULATION_RESULTS.md`

---

## ABA Recovery (Recovering Classical ABA)

**All semiring/monoid combinations can recover classical ABA** (no attack discarding) with appropriate (δ, β) configurations.

**Key parameters:**
- **δ**: Default weight assigned to unweighted assumptions
- **β**: Budget value that controls discarding threshold

**Universal patterns:**

### Pattern 1: #sup-based Semirings
(Gödel, Tropical, Łukasiewicz, Bottleneck-Cost)

- **UB regime** (MAX/SUM/COUNT/LEX): δ=#sup, β=0
- **LB regime** (MIN): δ=#inf, β=0

### Pattern 2: 0-based Semiring
(Arctic)

- **UB regime** (MAX/SUM/COUNT/LEX): δ=0, β=#inf (set in framework file!)
- **LB regime** (MIN): δ=0, β=#sup

---

## Historical Implementation

**Previous implementation:** The original aggregate-based WABA implementation (pre-December 2025) is preserved in `WABA_Legacy/` for backward compatibility.

**Key differences:**
- **Legacy**: Aggregate-based `extension_cost/1`, slower, `monoid/baseline/` directory
- **Current**: Weak constraint-based, 1000x faster, `monoid/*_minimization.lp` / `*_maximization.lp`

See `WABA_Legacy/README.md` for migration guide.
