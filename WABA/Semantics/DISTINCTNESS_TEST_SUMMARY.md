# Semantic Distinctness Testing Summary

**Date**: 2025-12-29
**Task**: Verify that all 10 WABA semantics are truly distinct

## Test Results

### Initial Comprehensive Test (145 frameworks, BROKEN CONFIG)

**Configuration Used** (INCORRECT):
- Monoid: `max_minimization.lp` (optimized, no `extension_cost/1`)
- Constraint: None (budget constraint silently broken!)

**Results**: 39/45 pairs distinct, 6 pairs equivalent:
1. stable ≡ cf2
2. stable ≡ naive
3. semi-stable ≡ preferred
4. semi-stable ≡ complete
5. preferred ≡ complete
6. **cf2 ≡ naive** (EXPECTED - both use same maximality constraint)

**Problem**: Budget constraints were not enforced, allowing unlimited attack discarding!

### Corrected Configuration

**Configuration** (CORRECT):
```bash
clingo -n 0 \
  core/base.lp \
  semiring/godel.lp \
  monoid/max.lp \              # OLD monoid with extension_cost/1
  constraint/ub_max.lp \       # CRITICAL: Enforce budget
  filter/standard.lp \
  semantics/<semantic>.lp \
  <framework>.lp
```

### Classical Separation Frameworks Tested

#### 1. Self-Attacking Argument (`examples/semantic_separation/self_attack.lp`)

**Structure**: `{a}`, `a → a`
**Budget**: 0 (no attack discarding)

**Classical Expected**:
- Preferred: {∅}
- Stable: none

**WABA Results** (all semantics):
- 0 extensions

**Analysis**: Empty set might not satisfy all WABA semantics. Need to investigate why.

#### 2. 4-Cycle (`examples/semantic_separation/four_cycle.lp`)

**Structure**: `a → b → c → d → a`
**Budget**: 0 (no attack discarding)

**Classical Expected**:
- Stable: {a,c}, {b,d}
- Complete: {∅}, {a,c}, {b,d}
- Preferred: {a,c}, {b,d}

**WABA Results** (all semantics):
- stable, semi-stable, preferred, complete, naive: {a,c}, {b,d}

**Analysis**: All semantics agree on the same 2 extensions. **No pairs separated** yet.

## Key Findings

### 1. CF2 ≡ Naive (By Design)

Our implementation uses the same explicit maximality constraint for both:

```prolog
% semantics/cf2.lp and semantics/naive.lp
blocks_maximality(X) :- assumption(X),
                        out(X),
                        not defeated(X),
                        not has_contrary_in_extension(X).
:- blocks_maximality(X).
```

This makes CF2 ≡ Naive in WABA. This is **acceptable** - they are equivalent maximal conflict-free semantics.

### 2. Budget Mechanism Affects Semantic Collapse

With unrestricted budgets (budget >> attack costs):
- Many semantics collapse to equivalence
- Extensions can discard any attacks to become conflict-free
- Stable ≡ CF2 ≡ Naive (all maximal CF)

With restricted budgets (budget < min attack cost, e.g., budget=0):
- WABA behaves like classical ABA
- But still no separation observed in tested frameworks

### 3. Critical Bug Discovered

Budget constraints were silently broken when using optimized monoids!
- See `CRITICAL_BUDGET_BUG_REPORT.md` for details
- All previous semantic tests may have invalid results

## Next Steps

### Immediate Actions

1. **Update all semantic verification scripts** to use correct configuration:
   - `semantics/verify_benchmark.py`
   - `semantics/verify_semantics.py`
   - Any other test scripts

2. **Re-run comprehensive distinctness test** with:
   - Old monoid files (max.lp, sum.lp, etc.)
   - Constraint files (constraint/ub_max.lp, etc.)
   - Timeout handling for complex frameworks

3. **Investigate why empty set is not found** in self-attack framework

### Framework Construction Strategy

Need to construct or find frameworks that separate the remaining pairs:

1. **stable ≠ cf2** / **stable ≠ naive**
   - Need framework where maximal CF is not stable
   - Classical: Self-attack should work, but WABA gives 0 extensions

2. **semi-stable ≠ preferred**
   - Need framework where maximal admissible differs from maximal range
   - Classical examples exist in literature

3. **semi-stable ≠ complete** / **preferred ≠ complete**
   - Need framework with non-maximal complete extensions
   - Classical examples exist in literature

### Literature Search

Search for classical ABA frameworks known to separate:
- Complete vs Preferred
- Preferred vs Semi-stable
- Stable vs Maximal CF (Naive)

Adapt these to WABA with appropriate budget constraints.

## Open Questions

1. Why does self-attack framework give 0 extensions instead of {∅}?
2. Do WABA semantics require non-empty extensions?
3. Should we accept that some semantics are equivalent in WABA?
4. Is CF2 ≡ Naive acceptable, or should they be made distinct?

## Conclusion

**Progress**: Discovered critical budget bug affecting all semantic tests
**Status**: 39/45 pairs distinct (with broken config), need retest with correct config
**Blocker**: Need frameworks that separate the remaining ~5 pairs
**Priority**: Fix bug in all test scripts, then rerun comprehensive tests

Sources:
- [Argumentation framework - Wikipedia](https://en.wikipedia.org/wiki/Argumentation_framework)
- [An introduction to argumentation semantics (PDF)](https://www.researchgate.net/publication/220254331_An_introduction_to_argumentation_semantics)
- [Abstract Argumentation Frameworks and Their Semantics (PDF)](https://users.cs.cf.ac.uk/CaminadaM/publications/HOFA_semantics.pdf)
