# Solution Plan: Fix Semantic Inclusions

## Root Cause Identified

**The user's hypothesis is CORRECT**: Different semantics use different attack discarding for the same beta, violating semantic inclusions.

### Evidence

Test on `test_beta.lp` with β=100:

| Semantic | Discarding Patterns | Optimization |
|----------|-------------------|--------------|
| cf | 4 patterns | No |
| admissible | 3 patterns | No |
| complete | 3 patterns | No |
| stable | 3 patterns | No |
| grounded | 1 pattern (none) | Yes |
| preferred | 1 pattern (none) | Yes |
| semi-stable | 1 pattern (none) | Yes |

**Problem**: Enumerative semantics explore multiple discarding choices, optimized semantics use minimal cost only.

---

## Solution: Unified Attack Discarding

**Key Principle**: For fixed β, attack discarding must be the SAME across all semantics.

### Approach 1: Use Optimization for ALL Semantics (RECOMMENDED)

Force all semantics to use `--opt-mode=optN` with cost minimization:

**Pros**:
- Simple to implement
- Guarantees same discarding across semantics
- Efficient (minimal cost is a good default)
- Preserves most inclusions

**Cons**:
- Changes semantics of enumerative semantics (cf, admissible, complete, stable)
- May not find ALL extensions, only minimal-cost ones

**Test Result**: With this approach, test_beta.lp shows:
- ✅ grounded ⊆ complete
- ✅ grounded ⊆ preferred
- ✅ complete ⊆ preferred
- ✅ preferred ⊆ semi-stable
- ❌ stable ⊆ semi-stable (needs investigation - might be saturation bug)

### Approach 2: Fix Attack Discarding Before Computing Semantics

Separate attack discarding from semantic computation:

1. **Phase 1**: Determine optimal attack discarding (minimize cost within budget)
2. **Phase 2**: Compute ALL semantics using the FIXED attack graph from Phase 1

**Implementation**:
```prolog
% Phase 1: Fix discarding (via optimization or other criterion)
% This could be a separate program that outputs discarded_attack/3 facts

% Phase 2: Load fixed discarding + compute semantics
% Remove choice over discarded_attack, make it deterministic
```

**Pros**:
- Cleanly separates concerns
- Guarantees same attack graph for all semantics
- Classical inclusions preserved

**Cons**:
- Requires significant refactoring
- Need to define "canonical" discarding strategy

---

## Additional Issues to Fix

### 1. Saturation Bug (staged, naive)

**Status**: Identified but not yet fixed

**Problem**: Witness can equal candidate, making better_witness=FALSE

**Solution**: Add constraint forcing witness ≠ candidate:
```prolog
different :- in(X), not in2(X).
different :- in2(X), not in(X).
:- not different.
```

**Impact**: Will fix staged⊆semi-stable violations

### 2. Output Parsing Bug

**Status**: Partially fixed

**Problem**: Clingo outputs non-optimal answers during search

**Solution**: Only count answers with optimization cost matching final "OPTIMUM FOUND" cost

---

## Implementation Plan

### Phase 1: Quick Fix (Use Optimization Everywhere)

1. ✅ Modify test script to use `--opt-mode=optN` for ALL semantics
2. ✅ Verify inclusions hold (mostly - 4/5 tested pass)
3. ⬜ Fix remaining stable⊆semi-stable violation
4. ⬜ Fix saturation bug in staged/naive
5. ⬜ Run comprehensive tests

### Phase 2: Proper Fix (If Needed)

1. Refactor to separate attack discarding from semantic computation
2. Define canonical discarding strategy
3. Update all semantic files to use fixed attack graph
4. Comprehensive testing

---

## Decision Needed

**Question for user**: Which approach should we use?

**Option A (Recommended)**: Use optimization for all semantics
- Faster implementation
- Good enough for most use cases
- Semantics = "minimal-cost extensions satisfying property X"

**Option B**: Separate attack discarding phase
- More principled
- Preserves classical semantics
- More complex implementation

---

## Expected Results After Fix

With Approach A (optimization everywhere):

**Semantic inclusions** (for fixed β):
- grounded ⊆ complete ⊆ preferred ⊆ semi-stable ✅
- stable ⊆ semi-stable ✅ (after fixing saturation)
- staged ⊆ semi-stable ✅ (after fixing saturation)
- All ⊆ cf ✅

**Test success rate**: Expect >95% (vs current 86%)

Remaining violations will be genuine differences in WABA semantics (e.g., staged may not be ⊆ semi-stable in all cases due to completeness requirement).
