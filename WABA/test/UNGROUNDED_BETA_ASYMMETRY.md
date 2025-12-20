# Ungrounded Beta Asymmetry in Clingo

## Discovery

**Ungrounded constants behave asymmetrically in < vs > comparisons!**

```prolog
budget(beta).  % Ungrounded constant
val(0).
val(10).

fail_less :- val(C), C < B, budget(B).     % FIRES (C < beta is TRUE!)
fail_greater :- val(C), C > B, budget(B).  % DOESN'T FIRE (C > beta is FALSE)
```

**Result**: `fail_less` appears in answer set, but `fail_greater` doesn't.

## Interpretation

Clingo treats ungrounded constants in comparisons as if they are "supremum" (∞):
- `C < beta` → TRUE for all finite C (everything is less than ∞)
- `C > beta` → FALSE for all finite C (nothing is greater than ∞)

This means:
- **Ungrounded beta ≡ #sup** for `>` comparisons (UB regime)
- **Ungrounded beta ≠ #inf** for `<` comparisons (LB regime)

## Impact on WABA

### Upper Bound Regime (MAX/SUM/COUNT/LEX)
Constraint: `:- extension_cost(C), C > B, budget(B).`

- ✅ Ungrounded beta: `C > beta` never fires → ALL extensions allowed
- ✅ beta=#sup: `C > #sup` never fires → ALL extensions allowed
- ✅ **Ungrounded beta ≡ beta=#sup** ✓

### Lower Bound Regime (MIN)
Constraint: `:- extension_cost(C), C < B, budget(B).`

- ❌ Ungrounded beta: `C < beta` ALWAYS fires → NO extensions (UNSAT)
- ✅ beta=#inf: `C < #inf` never fires (nothing < -∞) → ALL extensions allowed
- ❌ **Ungrounded beta ≢ beta=#inf** ✗

## Solution

**MIN monoid CANNOT use ungrounded beta as permissive default!**

### Options:

#### Option 1: Require explicit beta for MIN monoid
```bash
# REQUIRED for MIN monoid to work
clingo -c beta=#inf core/base.lp semiring/tropical.lp monoid/min.lp ...
```

#### Option 2: Change MIN monoid to use default beta=#inf
Add to `monoid/min.lp`:
```prolog
budget(#inf) :- not budget(_).  % Default permissive budget for MIN
```

#### Option 3: Document the asymmetry
Update documentation to explain:
- UB monoids: Can omit beta (defaults to permissive)
- LB monoids (MIN): MUST set `beta=#inf` for permissive behavior

## Current Status

- ✅ UB regime (MAX/SUM/COUNT/LEX): Ungrounded beta works as permissive default
- ❌ LB regime (MIN): Ungrounded beta causes UNSAT
- ✅ Workaround: Use `-c beta=#inf` with MIN monoid

## Recommendation

**Implement Option 2**: Add default `budget(#inf)` to MIN monoid to match permissive behavior of other monoids.

This makes MIN monoid behave consistently with the rest of the system while respecting the LB semantics.
