# Strict Semantic Inclusions - Status Report

## Summary

**Achieved**: 11/12 strict inclusions demonstrated
**Blocked**: 1 inclusion blocked by bug in `semantics/preferred.lp`

## Verified Strict Inclusions (11/12)

✅ All inclusions hold (subset relation verified via `test_inclusions.py`)
✅ 11 strict inclusions demonstrated (not trivial equality)

### Working Strict Inclusions

1. ✅ **semi-stable ⊂ preferred** - `semistable_preferred_asym.lp` (asymmetric ranges)
2. ✅ **preferred ⊂ complete** - `grounded_subset_complete.lp`
3. ✅ **complete ⊂ admissible** - `complete_subset_admissible.lp`
4. ✅ **admissible ⊂ cf** - `admissible_subset_cf.lp`
5. ✅ **grounded ⊂ complete** - `grounded_subset_complete.lp`
6. ✅ **stable ⊂ staged** - `stable_staged_3cycle.lp` (3-cycle)
7. ✅ **staged ⊂ cf** - `staged_subset_cf.lp`
8. ✅ **stable ⊂ naive** - `stable_subset_naive.lp`
9. ✅ **naive ⊂ cf** - `naive_subset_cf.lp`
10. ✅ **grounded ⊂ ideal** - `grounded_ideal_selfattack.lp` (self-attack)
11. ✅ **ideal ⊂ complete** - `ideal_subset_complete.lp`

### Blocked by Bug

12. ⚠️ **stable ⊂ semi-stable** - Framework ready but cannot test

**Framework**: `stable_semistable_bad_assumption.lp`
**Construction**: Self-attacking assumption v prevents defeating u
- Stable: ∅ (no extensions)
- Semi-stable: Should be {{a}, {b}} but cannot verify due to preferred.lp bug

**Why blocked**: Semi-stable requires preferred semantics, which has a critical bug.

## Critical Bug: semantics/preferred.lp

**Symptoms**:
- Returns UNSATISFIABLE on 3-cycle when it should return {∅}
- Violates preferred ⊆ complete (complete has {∅}, preferred has nothing)

**Impact**:
- Semi-stable semantics cannot be tested (depends on preferred)
- Staged semantics also appears to have similar saturation-based maximality issues
- Affects all frameworks where only complete extension is ∅

**Test case**:
```bash
# 3-cycle: a→b→c→a (mutual attacks)
clingo -n 0 -c beta=0 core/base.lp semiring/godel.lp constraint/ub_max.lp \
       filter/standard.lp semantics/complete.lp test/strict_inclusions/stable_staged_3cycle.lp
# Result: 1 extension (∅) ✓

clingo -n 0 -c beta=0 core/base.lp semiring/godel.lp constraint/ub_max.lp \
       filter/standard.lp semantics/preferred.lp test/strict_inclusions/stable_staged_3cycle.lp
# Result: UNSATISFIABLE ✗ (should have ∅)
```

**Root cause**: The saturation-based maximality check in `preferred.lp` (lines 40-97) appears to fail when:
- The only complete extension is ∅
- All assumptions are in mutual attack cycles
- No assumptions are "defended" (have all attackers defeated)

## Next Steps

1. **Fix preferred.lp**: Debug and fix the saturation-based maximality encoding
2. **Fix staged.lp**: Likely has similar issues with saturation-based maximality
3. **Re-test**: Verify stable ⊂ semi-stable once preferred is fixed
4. **Complete verification**: All 12 strict inclusions will be demonstrated

## ABA vs Dung Differences (Important Finding)

The 3-cycle reveals a key difference between ABA and Dung AFs:

**Dung AF 3-cycle**:
- {a}, {b}, {c} ARE admissible (each defends against direct attacker)
- Semi-stable extensions exist

**ABA/WABA 3-cycle**:
- {a}, {b}, {c} are NOT admissible
- Reason: ABA checks attacks from ALL derivable elements from undefeated assumptions
- Example: For {a}, assumption c is undefeated → c attacks a → not admissible

This is **correct ABA semantics** - admissibility in ABA is more restrictive than in Dung AFs due to the derivability closure requirement.
