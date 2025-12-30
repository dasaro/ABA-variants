# Saturation vs Heuristic Approach Comparison

**Test Framework**: 3-cycle (a→b, b→c, c→a)
**File**: `test/strict_inclusions/stable_staged_3cycle.lp`
**Date**: 2025-12-30

## Results Summary

| Semantic | Heuristic Approach | Saturation Approach | Expected | Status |
|----------|-------------------|---------------------|----------|--------|
| **Complete** | N/A (non-maximal) | N/A (non-maximal) | 1: {∅} | ✓ Baseline |
| **Admissible** | N/A (non-maximal) | N/A (non-maximal) | 1: {∅} | ✓ Baseline |
| **Conflict-free** | N/A (non-maximal) | N/A (non-maximal) | 4: {∅, {a}, {b}, {c}} | ✓ Baseline |
| **Preferred** | 1 model: {∅} | 1 model: {∅} | 1: {∅} | ✅ **Both work** |
| **Semi-stable** | 1 model: {∅} | **UNSATISFIABLE** | 1: {∅} | ❌ Saturation broken |
| **Staged** | 3 models: {a}, {b}, {c} | **UNSATISFIABLE** | 3: {a}, {b}, {c} | ❌ Saturation broken |

## Detailed Analysis

### Preferred Semantics

**Definition**: Maximal (⊆) complete extensions

**Complete extensions**: {∅} (only one)

**Heuristic approach** (`--heuristic=Domain --enum-mode=domRec`):
```
Models: 1
Extensions: {∅}
```
✅ **Correct** - Returns the only complete extension (which is trivially maximal)

**Saturation approach** (ordering + superset guessing):
```
Models: 1
Extensions: {∅}
```
✅ **Correct** - For S = ∅, guesses S' ⊇ ∅, finds all S' are not complete, spoils (accepts ∅)

**Verdict**: Both approaches work correctly on 3-cycle for preferred semantics.

---

### Semi-Stable Semantics

**Definition**: Admissible extensions with maximal range(S) = S ∪ S⁺

**Admissible extensions**: {∅}

**Ranges**:
- range(∅) = ∅ ∪ ∅ = ∅ (nothing defeated)

**Heuristic approach** (`--heuristic=Domain --enum-mode=domRec`):
```
Models: 1
Extensions: {∅}
```
✅ **Correct** - Returns ∅ as the only admissible extension (trivially range-maximal)

**Saturation approach** (ordering + range comparison):
```
Models: 0
UNSATISFIABLE
```
❌ **BROKEN** - Returns no models despite ∅ being a valid semi-stable extension

**Issue**: Saturation mechanism conflicts with choice-based `in/out` guessing from `core/base.lp`

---

### Staged Semantics

**Definition**: Conflict-free extensions with maximal range(S) = S ∪ S⁺

**Conflict-free extensions**: {∅, {a}, {b}, {c}}

**Ranges**:
- range(∅) = ∅ ∪ ∅ = ∅
- range({a}) = {a} ∪ {b} = {a, b}
- range({b}) = {b} ∪ {c} = {b, c}
- range({c}) = {c} ∪ {a} = {a, c}

**Maximal ranges**: {a,b}, {b,c}, {a,c} are all maximal (incomparable)

**Heuristic approach** (`--heuristic=Domain --enum-mode=domRec`):
```
Models: 3
Extensions: {a}, {b}, {c}
```
✅ **Correct** - Returns all three range-maximal extensions

**Saturation approach** (ordering + range comparison):
```
Models: 0
UNSATISFIABLE
```
❌ **BROKEN** - Returns no models despite {a}, {b}, {c} being valid staged extensions

**Issue**: Same saturation/choice conflict as semi-stable

---

## Root Cause Analysis

### Why Preferred Works But Semi-stable/Staged Fail

**Preferred (subset-maximality)**:
- Checks if S' ⊃ S (strict superset)
- For 3-cycle, ∅ is the ONLY complete extension
- No superset of ∅ is complete (all singletons violate completeness)
- Therefore ∅ is trivially maximal → accepted ✓

**Semi-stable/Staged (range-maximality)**:
- Checks if range(S') ⊃ range(S) (strict range superset)
- For 3-cycle, there ARE conflict-free/admissible extensions with larger ranges
- But the saturation check creates logical conflicts with the choice-based architecture
- The `:- not spoil.` constraint combined with range comparison creates UNSAT

### Fundamental Architectural Issue

The saturation technique from ASPARTIX assumes:
```prolog
in(X) | out(X) :- arg(X).  % Disjunctive guessing
```

But WABA uses:
```prolog
in(X) :- assumption(X), not out(X).  % Choice-based (default negation)
out(X) :- assumption(X), not in(X).
```

The saturation's `:- not spoil.` constraint requires specific combinations of predicates to be true/false that conflict with the stable model semantics of choice rules.

---

## Recommendations

### Production Use

**Use heuristic-based semantics** (`semantics/heuristic/*.lp`):
- ✅ Preferred: Works correctly
- ✅ Semi-stable: Works correctly
- ✅ Staged: Works correctly
- Requires `--heuristic=Domain --enum-mode=domRec` flags
- May not find ALL maximal extensions on complex frameworks (documented limitation)
- Works correctly on all tested standard examples

### Research/Development

**Saturation-based semantics** (`semantics/*.lp`):
- ⚠️ Preferred: Partially working (returns all complete, not just maximal)
- ❌ Semi-stable: Non-functional (UNSATISFIABLE)
- ❌ Staged: Non-functional (UNSATISFIABLE)
- Preserved for future architectural work
- Would require refactoring `core/base.lp` to use disjunctive guessing instead of choice

---

## Test Commands

### Heuristic Approach
```bash
# Preferred
clingo -n 0 --heuristic=Domain --enum-mode=domRec -c beta=0 \
  core/base.lp semiring/godel.lp constraint/ub_max.lp filter/standard.lp \
  semantics/heuristic/preferred.lp test/strict_inclusions/stable_staged_3cycle.lp

# Semi-stable
clingo -n 0 --heuristic=Domain --enum-mode=domRec -c beta=0 \
  core/base.lp semiring/godel.lp constraint/ub_max.lp filter/standard.lp \
  semantics/heuristic/semi-stable.lp test/strict_inclusions/stable_staged_3cycle.lp

# Staged
clingo -n 0 --heuristic=Domain --enum-mode=domRec -c beta=0 \
  core/base.lp semiring/godel.lp constraint/ub_max.lp filter/standard.lp \
  semantics/heuristic/staged.lp test/strict_inclusions/stable_staged_3cycle.lp
```

### Saturation Approach
```bash
# Preferred
clingo -n 0 -c beta=0 \
  core/base.lp semiring/godel.lp constraint/ub_max.lp filter/standard.lp \
  semantics/preferred.lp test/strict_inclusions/stable_staged_3cycle.lp

# Semi-stable
clingo -n 0 -c beta=0 \
  core/base.lp semiring/godel.lp constraint/ub_max.lp filter/standard.lp \
  semantics/semi-stable.lp test/strict_inclusions/stable_staged_3cycle.lp

# Staged
clingo -n 0 -c beta=0 \
  core/base.lp semiring/godel.lp constraint/ub_max.lp filter/standard.lp \
  semantics/staged.lp test/strict_inclusions/stable_staged_3cycle.lp
```

---

## Conclusion

The **heuristic approach is the recommended implementation** for all three semantics (preferred, semi-stable, staged). The saturation approach, while theoretically elegant, has fundamental compatibility issues with WABA's choice-based architecture that prevent it from working correctly for range-maximality semantics and only partially work for subset-maximality (preferred).
