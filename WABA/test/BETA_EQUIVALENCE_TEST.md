# Beta Parameter Equivalence Test

## Question
Is NOT setting beta equivalent to setting beta=#sup?

## Answer
**YES** - They produce identical results.

## Test Setup

**Framework**: test/test_beta.lp
- 3 assumptions: a1 (weight 50), a2 (weight 30), a3 (weight 20)
- a1 attacks a2 (attack cost 50)
- a3 attacks a1 (attack cost 20)
- NO budget() defined in framework file

**Configuration**: Gödel + Max + Stable semantics

## Test Results

### Test 1: NO beta parameter (ungrounded)
```bash
clingo -n 0 core/base.lp semiring/godel.lp monoid/max.lp \
       filter/standard.lp semantics/stable.lp test/test_beta.lp
```

**Result**:
- Budget value: `budget(beta)` (ungrounded constant)
- Models: **3**
- Extension costs: **0, 20, 50**

### Test 2: beta=#sup
```bash
clingo -n 0 -c beta=#sup core/base.lp semiring/godel.lp monoid/max.lp \
       filter/standard.lp semantics/stable.lp test/test_beta.lp
```

**Result**:
- Budget value: `budget(#sup)`
- Models: **3**
- Extension costs: **0, 20, 50**

### Test 3: beta=100 (high value)
```bash
clingo -n 0 -c beta=100 core/base.lp semiring/godel.lp monoid/max.lp \
       filter/standard.lp semantics/stable.lp test/test_beta.lp
```

**Result**:
- Budget value: `budget(100)`
- Models: **3**
- Extension costs: **0, 20, 50**

### Test 4: beta=0 (strictest - for comparison)
```bash
clingo -n 0 -c beta=0 core/base.lp semiring/godel.lp monoid/max.lp \
       filter/standard.lp semantics/stable.lp test/test_beta.lp
```

**Result**:
- Budget value: `budget(0)`
- Models: **1**
- Extension costs: **0** (only no-discard extension allowed)

## Detailed Extension Analysis

### All three permissive settings (no beta, beta=#sup, beta=100) produce:

**Answer 1** (extension_cost=0):
- in: {a3, a2}
- Discarded: none
- Successful attacks: a3→a1

**Answer 2** (extension_cost=20):
- in: {a3, a1}
- Discarded: a3→a1 (cost 20)
- Successful attacks: a1→a2

**Answer 3** (extension_cost=50):
- in: {a3, a1, a2}
- Discarded: a1→a2 (cost 50)
- Successful attacks: none

### Strict setting (beta=0) produces only:

**Answer 1** (extension_cost=0):
- in: {a3, a2}
- Discarded: none
- Successful attacks: a3→a1

## Conclusion

**NOT setting beta IS equivalent to beta=#sup** in terms of constraint behavior.

### Why this happens:

In `core/base.lp`, the budget constraint is:
```prolog
budget(beta).
:- extension_cost(C), C > B, budget(B).
```

When beta is ungrounded:
- ASP comparison `C > beta` with ungrounded `beta` never fires
- No extensions are rejected by the budget constraint
- This is exactly the same behavior as `C > #sup` (nothing is greater than #sup)

### Practical implications:

1. **Both are equally permissive**: Allow all possible extensions regardless of cost
2. **Different representations**:
   - No beta → `budget(beta)` in answer set
   - beta=#sup → `budget(#sup)` in answer set
3. **Same semantics**: Both effectively disable the budget constraint
4. **Warning still applies**: As documented in README.md, NOT setting beta leads to "meaningless results" because the budget mechanism is effectively disabled

### Recommendation:

Always explicitly set a finite budget value to ensure meaningful WABA semantics. Use beta=#sup or no beta ONLY when you intentionally want to disable budget constraints entirely.
