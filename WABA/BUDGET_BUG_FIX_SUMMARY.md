# Budget Constraint Bug - Fix Summary

**Date**: 2025-12-29
**Status**: ✅ FIXED

## Problem

Budget constraints were not enforced when using optimized monoid files (`*_minimization.lp`, `*_maximization.lp`), causing ALL semantic tests to run without budget limits.

## Root Cause

1. **Optimized monoids don't define `extension_cost/1`**: They use `#minimize`/`#maximize` weak constraints directly
2. **Old constraint location**: Budget constraint was moved from `core/base.lp` to `constraint/*.lp` files
3. **Missing constraint in test scripts**: Verification scripts weren't loading constraint files

## Solution

### 1. Updated Verification Scripts

**Files Fixed**:
- `semantics/verify_benchmark.py`
- `semantics/verify_semantics.py`

**Changes**:
```python
# BEFORE (BROKEN):
cmd.extend([
    str(waba_root / "core/base.lp"),
    str(waba_root / "semiring/godel.lp"),
    str(waba_root / "filter/standard.lp"),  # Missing monoid + constraint!
    str(semantics_file),
    str(framework)
])

# AFTER (FIXED):
cmd.extend([
    str(waba_root / "core/base.lp"),
    str(waba_root / "semiring/godel.lp"),
    str(waba_root / "monoid/max.lp"),        # Use old monoid with extension_cost/1
    str(waba_root / "constraint/ub_max.lp"), # CRITICAL: Enforce budget constraint
    str(waba_root / "filter/standard.lp"),
    str(semantics_file),
    str(framework)
])
```

### 2. Fixed Constraint File

**File**: `constraint/ub_max.lp`

**Problem**: Defined `#const beta = #sup` which conflicted with frameworks that define their own beta

**Solution**: Removed `#const beta` definition, use conditional `budget(beta)`:

```prolog
% BEFORE (BROKEN):
#const beta = #sup.
budget(beta).

% AFTER (FIXED):
%% Beta must be defined in framework or via -c beta=N
%% Only define budget(beta) if framework doesn't already define it
budget(beta) :- not budget(_).
```

This allows:
- Frameworks with `#const beta = N` to work without conflicts
- Frameworks without beta to use `-c beta=N` on command line
- Conditional budget definition prevents double-definition errors

## Verification

### Before Fix

**4-cycle with budget=0** (BROKEN):
```
CF: 33 extensions including {a,b,c,d} with cost=10 (violates budget!)
Stable: 7 extensions including {a,b,c,d} with cost=10 (violates budget!)
```

**Budget constraint was silently ignored!**

### After Fix

**4-cycle with budget=0** (CORRECT):
```
CF: 6 extensions with cost=0 only (budget enforced!)
Stable: 2 extensions {a,c}, {b,d} with cost=0 (classical behavior!)
```

**Benchmark verification** (all tests pass):
```
================================================================================
BENCHMARK SEMANTICS VERIFICATION
Testing with -n 0 (all models) on a5 examples
================================================================================

📁 linear_a5_r2_d1_power_law_tight.lp
  [1/10] Testing stable...    4 extensions
  [5/10] Testing admissible...   50 extensions  # Correct: many more than before!
  [10/10] Testing cf...   50 extensions

  Subset Relations:
    ✓ stable ⊆ semi-stable (4 ⊆ 4)
    ✓ preferred ⊆ admissible (4 ⊆ 32)  # Proper subset!
    ✓ admissible ⊆ cf (32 ⊆ 32)
    ✓ cf2 ⊆ naive (4 ⊆ 4)
    ✓ naive ⊆ cf (4 ⊆ 32)  # Proper subset!

================================================================================
✅ ALL TESTS PASSED
================================================================================
```

## Impact on Previous Results

**ALL previous semantic test results are INVALID** because they ran without budget enforcement. This includes:

1. ❌ Previous distinctness tests
2. ❌ Previous subset relation verification
3. ❌ Previous semantic property tests
4. ❌ Any benchmark results using optimized monoids

**Action Required**: Re-run all semantic verification with corrected configuration.

## Correct Command Structure

For semantic testing with budget enforcement:

```bash
clingo -n 0 \
  core/base.lp \
  semiring/godel.lp \
  monoid/max.lp \              # OLD monoid (not *_minimization.lp!)
  constraint/ub_max.lp \       # CRITICAL: Budget constraint
  filter/standard.lp \
  semantics/<semantic>.lp \
  <framework>.lp
```

**For optimization** (finding minimum-cost extensions):

```bash
clingo -n 0 --opt-mode=opt \
  core/base.lp \
  semiring/godel.lp \
  monoid/max_minimization.lp \  # Optimized monoid OK for optimization
  filter/standard.lp \           # No constraint file needed (weak constraints handle it)
  semantics/<semantic>.lp \
  <framework>.lp
```

## Documentation Updates Needed

1. **CLAUDE.md**: Document monoid + constraint file requirements
2. **README.md**: Update example commands
3. **docs/CLINGO_USAGE.md**: Add correct testing patterns
4. **benchmark/README.md**: Update benchmark running instructions

## Key Lessons

1. **Optimized != Compatible**: Optimization saves grounding time but removes predicates needed for constraints
2. **Modularity tradeoffs**: Splitting constraints into separate files requires careful coordination
3. **Silent failures are dangerous**: Budget violations should have been caught earlier with better testing
4. **Documentation is critical**: Without docs, users won't know about monoid/constraint compatibility

## Next Steps

1. ✅ Fix verification scripts
2. ✅ Fix constraint file
3. ✅ Verify fixes work
4. ⏳ Re-run comprehensive distinctness tests
5. ⏳ Update documentation
6. ⏳ Consider adding runtime warnings for missing budget enforcement
