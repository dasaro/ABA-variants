# Grounded Semantics Status

**Implementation**: Fixpoint-based approach
**File**: `semantics/grounded.lp`
**Status**: ✅ **WORKING CORRECTLY**

## Overview

Grounded semantics is implemented using a **least fixpoint computation** that is compatible with WABA's choice-based architecture.

### Definition

The grounded extension is the unique minimal (w.r.t. set inclusion) complete extension, computed as the least fixpoint of the characteristic function:
- An assumption is in the grounded extension if it defeats all its attackers

### Implementation Approach

**NOT based on ASPforABA** - ASPforABA's iterative construction conflicts with WABA's choice-based `core/base.lp`.

**Custom fixpoint approach**:
```prolog
%% Compute grounded extension via fixpoint
g_defeated(X) :- assumption(X), g_in(Y), contrary(X,Y).
g_in(X) :- assumption(X), g_defeated(Y) : contrary(X,Y).

%% Constrain choice-based in/1 to match grounded
:- g_in(X), not in(X).
:- in(X), not g_in(X).
```

### How It Works

1. **Fixpoint Computation**: Computes `g_in/1` predicates via least fixpoint
   - An assumption X is `g_in` if all its attackers (assumptions with X as contrary) are `g_defeated`
   - An assumption X is `g_defeated` if some `g_in` assumption attacks it

2. **Constraint Matching**: Forces the choice-based `in/1` from `core/base.lp` to exactly match `g_in/1`
   - This avoids architectural conflicts with the choice rules
   - Ensures grounded extension is computed correctly

### Test Results

#### 3-cycle (a→b, b→c, c→a)
```bash
clingo -n 1 -c beta=0 core/base.lp semiring/godel.lp constraint/ub_max.lp \
  filter/standard.lp semantics/grounded.lp test/strict_inclusions/stable_staged_3cycle.lp
```
**Result**: 1 model: {∅}
**Expected**: {∅} (no assumption defeats all attackers)
**Status**: ✅ Correct

#### grounded_subset_complete framework
```bash
clingo -n 1 -c beta=0 core/base.lp semiring/godel.lp constraint/ub_max.lp \
  filter/standard.lp semantics/grounded.lp test/strict_inclusions/grounded_subset_complete.lp
```
**Result**: 1 model: {a}
**Complete extensions**: {a}, {a,b}, {a,c,d}
**Verification**: {a} ⊆ {a}, {a,b}, {a,c,d} ✓
**Status**: ✅ Correct - grounded ⊆ complete verified

#### bad_assumption framework
```bash
clingo -n 1 -c beta=0 core/base.lp semiring/godel.lp constraint/ub_max.lp \
  filter/standard.lp semantics/grounded.lp test/strict_inclusions/stable_semistable_bad_assumption.lp
```
**Result**: 1 model: {∅}
**Expected**: {∅} (no unattacked assumptions)
**Status**: ✅ Correct

### Inclusion Relations

Grounded semantics participates in two key inclusion relations:

1. **grounded ⊆ complete**: ✅ Verified
   - Grounded is always complete (by definition: minimal complete)
   - Test: grounded_subset_complete.lp shows {a} ⊂ {{a}, {a,b}, {a,c,d}}

2. **grounded ⊆ ideal ⊆ complete**: ✅ Verified in full test suite
   - Grounded is always a subset of ideal
   - Test: grounded_ideal_selfattack.lp shows grounded ⊂ ideal

### Usage

```bash
# Note: Use -n 1 since grounded extension is unique
clingo -n 1 -c beta=0 \
  core/base.lp \
  semiring/godel.lp \
  constraint/ub_max.lp \
  filter/standard.lp \
  semantics/grounded.lp \
  <framework>.lp
```

### Comparison with Other Approaches

| Approach | Status | Notes |
|----------|--------|-------|
| **Fixpoint (WABA)** | ✅ Working | Custom implementation, compatible with choice rules |
| **ASPforABA iterative** | ❌ Incompatible | Conflicts with WABA's choice-based architecture |
| **Saturation-based** | N/A | Not needed - grounded is unique, no maximality check required |
| **Heuristic-based** | N/A | Not needed - grounded is uniquely defined, no search required |

### Key Advantages

1. **Architecturally compatible**: Works seamlessly with WABA's `core/base.lp`
2. **Elegant**: Simple fixpoint computation with constraint matching
3. **Efficient**: Direct computation, no search or enumeration needed
4. **Correct**: Passes all inclusion relation tests

### Implementation History

- **Initial issue**: ASPforABA-based version conflicted with choice rules
- **Solution**: User-provided fixpoint approach (4 lines of core logic)
- **Status**: Fixed early in development, stable since then

### Conclusion

Grounded semantics is **fully functional and production-ready**. Unlike preferred/semi-stable/staged, it does not require heuristics or saturation approaches because it is **uniquely defined** (not a maximal extension). The fixpoint-based implementation is elegant, efficient, and compatible with WABA's architecture.
