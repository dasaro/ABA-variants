# WABA Quick Reference

## Command Template

```bash
clingo -n 0 \
  WABA/core_base.lp \
  WABA/semiring/<semiring>.lp \
  WABA/monoid/<monoid>.lp \
  WABA/filter.lp \
  [WABA/minimize_cost.lp] \
  WABA/Semantics/<semantics>.lp \
  <your_framework>.lp
```

## Common Combinations

### Original WABA (Fuzzy + Max)
```bash
# Stable semantics
clingo -n 0 WABA/core_base.lp WABA/semiring/fuzzy.lp WABA/monoid/max.lp \
       WABA/filter.lp WABA/Semantics/stable.lp <framework>.lp

# Conflict-free semantics
clingo -n 0 WABA/core_base.lp WABA/semiring/fuzzy.lp WABA/monoid/max.lp \
       WABA/filter.lp WABA/Semantics/cf.lp <framework>.lp

# Naive semantics (requires special flags)
clingo -n 0 --heuristic=Domain --enum=domRec \
       WABA/core_base.lp WABA/semiring/fuzzy.lp WABA/monoid/max.lp \
       WABA/filter.lp WABA/Semantics/naive.lp <framework>.lp
```

### With Cost Minimization
```bash
clingo -n 0 WABA/core_base.lp WABA/semiring/fuzzy.lp WABA/monoid/max.lp \
       WABA/filter.lp WABA/minimize_cost.lp WABA/Semantics/stable.lp <framework>.lp
```

### Other Semiring/Monoid Combinations

**Tropical + Max** (Addition for conjunction):
```bash
clingo -n 0 WABA/core_base.lp WABA/semiring/tropical.lp WABA/monoid/max.lp \
       WABA/filter.lp WABA/Semantics/stable.lp <framework>.lp
```

**Fuzzy + Sum** (Sum cost aggregation):
```bash
clingo -n 0 WABA/core_base.lp WABA/semiring/fuzzy.lp WABA/monoid/sum.lp \
       WABA/filter.lp WABA/Semantics/stable.lp <framework>.lp
```


**Boolean + Max** (Binary weights):
```bash
clingo -n 0 WABA/core_base.lp WABA/semiring/boolean.lp WABA/monoid/max.lp \
       WABA/filter.lp WABA/Semantics/stable.lp <framework>.lp
```

**Fuzzy + Count** (Weight-agnostic counting):
```bash
clingo -n 0 -c beta=2 WABA/core_base.lp WABA/semiring/fuzzy.lp WABA/monoid/count.lp \
       WABA/filter.lp WABA/Semantics/stable.lp <framework>.lp
```

**Fuzzy + Lex with Optimization** (Lexicographic minimization):
```bash
clingo -n 0 WABA/core_base.lp WABA/semiring/fuzzy.lp WABA/monoid/lex.lp \
       WABA/filter_lex.lp WABA/optimize_lex.lp WABA/Semantics/stable.lp <framework>.lp
```

**Tropical + Min with Maximization** (Quality threshold):
```bash
clingo -n 0 -c beta=10 WABA/core_base.lp WABA/semiring/tropical.lp WABA/monoid/min.lp \
       WABA/filter.lp WABA/maximize_cost.lp WABA/Semantics/stable.lp <framework>.lp
```

## Available Modules

**Semirings** (in `WABA/semiring/`):
- `fuzzy.lp` - Fuzzy/Gödel logic (min/max, identity=100) - **original WABA**
- `tropical.lp` - Tropical semiring (min/+, identity=#sup)
- `boolean.lp` - Boolean logic (and/or, binary weights {0,1})

**Monoids** (in `WABA/monoid/`):
- `max.lp` - Maximum cost (original WABA)
- `sum.lp` - Sum of costs
- `min.lp` - Minimum cost (quality threshold semantics)
- `count.lp` - Count of discarded attacks (weight-agnostic)
- `lex.lp` - Lexicographic cost (max→sum→count priority)

**Semantics** (in `WABA/Semantics/`):
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
clingo -c beta=100 WABA/core_base.lp ...
```

**Common budget values**:
- `budget(0)` - Strictest (classical ABA, no discarding)
- `budget(<max_weight>)` - Can discard ~1 attack
- `budget(<sum/2>)` - Can discard ~half the attacks
- `budget(<sum_all>)` - Can discard all attacks

## Examples

```bash
# Medical ethics example with original WABA
clingo -n 0 WABA/core_base.lp WABA/semiring/fuzzy.lp WABA/monoid/max.lp \
       WABA/filter.lp WABA/Semantics/stable.lp WABA/Examples/medical.lp

# Simple example with tropical semiring and cost minimization
clingo -n 0 WABA/core_base.lp WABA/semiring/tropical.lp WABA/monoid/max.lp \
       WABA/filter.lp WABA/minimize_cost.lp WABA/Semantics/stable.lp WABA/Examples/simple.lp
```

## Output Predicates

Expected output (via filter.lp):
- `in(X)` - Assumptions in the extension
- `supported_with_weight(X, W)` - Supported elements with their weights
- `attacks_successfully_with_weight(X, Y, W)` - Successful attacks
- `extension_cost(C)` - Total cost of the extension
