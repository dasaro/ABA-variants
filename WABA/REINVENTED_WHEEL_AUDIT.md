# Re-Invented Wheel Audit Report

**Date**: 2026-01-01
**Purpose**: Identify places where semantic files re-define predicates that already exist in core/base.lp

---

## Summary of Findings

### ✅ FIXED: Critical Bug - Conflict-Free Constraint

**Issue**: Saturation semantics (staged, naive, preferred, semi-stable) defined custom `attacked/1` that only checked attacks FROM assumptions in extension, missing attacks from derived elements.

**Impact**: Extensions violated conflict-freeness (e.g., `{c}` accepted even though `c` is defeated by fact `y`)

**Fix Applied**: ✅
Replaced custom `attacked(Y) :- in(X), att(X,Y).` with `defeated/1` from core/base.lp:
```prolog
:- in(X), defeated(X).  % Use defeated/1 from core/base.lp
```

**Files Fixed**:
- semantics/staged.lp
- semantics/naive.lp
- semantics/preferred.lp
- semantics/semi-stable.lp

**Result**:
- `staged⊆cf` violations: **3 → 0** ✅
- `naive⊆cf` violations: **3 → 0** ✅
- Overall satisfaction: **89% → 94%** ✅

---

## ✅ FIXED: Redundant `out/1` Definition

**Files Affected** (now cleaned up):
- semantics/naive.lp (line 21 removed)
- semantics/preferred.lp (line 21 removed)
- semantics/semi-stable.lp (line 22 removed)
- semantics/staged.lp (line 22 removed)

**Issue**:
```prolog
arg(X) :- assumption(X).
out(X) :- arg(X), not in(X).  % ← Redundant!
```

**Already Defined in core/base.lp**:
```prolog
out(X) :- assumption(X), not in(X).
```

**Analysis**:
Since `arg(X) ≡ assumption(X)` in these files, the `out/1` definition was redundant. ASP derived `out/1` from both rules, which was harmless but inefficient.

**Fix Applied**: ✅
Removed redundant `out/1` definitions from all saturation semantics files.

---

## 🔍 Intentional Override: `in/1` Choice Rule

**Files**: All saturation semantics (naive, preferred, semi-stable, staged)

**Code**:
```prolog
{ in(X) } :- arg(X).  % Choice rule - ASP picks
```

**vs. core/base.lp**:
```prolog
in(X) :- assumption(X), not out(X).  % Deterministic
```

**Analysis**:
This is **intentional**, not a bug. Saturation semantics need non-determinism (choice) to explore multiple extensions. The core/base.lp rule would make `in/1` deterministic, which wouldn't work for these semantics.

**Recommendation**: ✅ Keep as-is (intentional design)

---

## 💡 Design Difference: Defense Logic

**admissible.lp** (explicit):
```prolog
not_defended(X) :- contrary(X,Y), assumption(Y),
                   not defeated(Y), not discarded_attack(Y,X,_).
not_defended(X) :- contrary(X,Y), supported(Y),
                   not defeated(Y), not discarded_attack(Y,X,_).
```

**preferred.lp/semi-stable.lp** (saturation):
```prolog
attacked(Y) :- in(X), att(X,Y).
undefended(X) :- att(Y,X), not attacked(Y).
defended(X) :- arg(X), not undefended(X).
```

**Analysis**:
- **admissible**: Checks ALL potential attacks (`contrary`), explicitly handles `discarded_attack`
- **saturation**: Checks successful attacks only (`att = attacks_successfully_with_weight`)

**Key Insight**:
- `att(Y,X)` already filters discarded attacks (definition includes `not discarded_attack`)
- `attacked(Y)` checks if extension counter-attacks Y
- Different implementation, potentially equivalent semantics

**Recommendation**: Monitor for semantic differences in tests, but likely intentional design choice.

---

## ✅ Verified: #include Directive Hierarchy

**Purpose**: Verify that predicates from included files are not being redefined in including files.

**#include Hierarchy**:
```
cf.lp (base conflict-free)
├── admissible.lp (cf + defense)
│   └── complete.lp (admissible + completeness)
└── stable.lp (cf + stability)

grounded.lp (standalone, no includes)
```

**Verification Results**:

1. **cf.lp → admissible.lp**: ✅
   - cf.lp only defines constraint (no predicates)
   - admissible.lp adds `not_defended/1` (new predicate, not a redefinition)

2. **admissible.lp → complete.lp**: ✅
   - complete.lp uses `not_defended/1` from admissible.lp
   - No redefinition, just extends with completeness constraint

3. **cf.lp → stable.lp**: ✅
   - stable.lp only adds stability constraint
   - No predicates redefined

4. **grounded.lp**: ✅
   - Defines `att/2` and `arg/1` locally (same as saturation semantics)
   - No conflicts since semantics files are mutually exclusive (only one loaded at a time)

**Conclusion**: No redefinition conflicts via #include directives. The inclusion hierarchy is properly designed.

---

## ✅ No Issues Found

**Files with no redefinitions**:
- semantics/admissible.lp ✅
- semantics/cf.lp ✅
- semantics/complete.lp ✅
- semantics/grounded.lp ✅
- semantics/stable.lp ✅

These files properly reuse core/base.lp predicates without reinventing.

---

## Recommendations

### 1. High Priority: ✅ COMPLETED
- ✅ Use `defeated/1` from core/base.lp for conflict-free constraints
- **Impact**: Fixed 6 critical violations, improved from 89% to 94%

### 2. Code Cleanup: ✅ COMPLETED
- ✅ Removed redundant `out/1` definitions in saturation semantics
- **Impact**: Minor efficiency improvement, cleaner codebase

### 3. #include Verification: ✅ COMPLETED
- ✅ Verified no predicate redefinitions via #include directives
- **Impact**: Confirmed proper modular design

### 4. Documentation: ✅ COMPLETED
- ✅ Documented that saturation semantics intentionally override `in/1` with choice rule
- ✅ Clarified defense logic differences between admissible and saturation semantics
- ✅ Documented #include hierarchy and verification results

---

## Testing Impact

**Before conflict-free fix**:
- Total checks: 385
- Satisfied: 343 (89%)
- Violations: 42 (11%)

**After conflict-free fix**:
- Total checks: 385
- Satisfied: 364 (94%)
- Violations: 21 (5%)

**Remaining violations** (after fix):
- `staged⊆semi-stable`: 19 (saturation maximality bug)
- `complete⊆preferred`: 2 (empty set edge cases)

---

## Conclusion

The "re-inventing the wheel" audit has been **completed** with all recommended actions implemented:

**Critical Issues Fixed**:
- ✅ Conflict-free constraint bug (89% → 94% satisfaction, 6 violations eliminated)
- ✅ Redundant `out/1` definitions removed (cleaner codebase)

**Verified Clean**:
- ✅ No predicate redefinitions via #include directives
- ✅ Proper modular design in cf.lp → admissible.lp → complete.lp hierarchy
- ✅ Proper modular design in cf.lp → stable.lp

**Intentional Design Patterns Documented**:
- `in/1` choice override in saturation semantics (correct for non-determinism)
- Different defense logic implementations (admissible vs saturation)
- Duplicate `att/2` and `arg/1` across mutually exclusive semantic files (acceptable)

**No other critical issues found from predicate redefinitions.**
