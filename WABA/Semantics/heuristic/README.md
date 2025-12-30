# Heuristic-Based Semantics (Alternative Implementations)

This directory contains heuristic-based implementations of maximal semantics. These are **alternative implementations** - saturation-based versions are recommended for guaranteed correctness.

## Status: Alternative/Experimental

These implementations use ASP heuristics to guide the solver toward maximal extensions. They work correctly on tested examples but are **not guaranteed** to find all maximal extensions on all frameworks.

## Files

### Subset-Maximality (⊆-maximal)

#### preferred.lp
- **Definition**: Maximal (w.r.t. ⊆) complete extensions
- **Method**: `#heuristic miss(X). [1,false]` to minimize missing assumptions
- **Guarantees**: Works on tested examples, not guaranteed in general
- **Usage**: `clingo -n 0 --heuristic=Domain --enum-mode=domRec <files> semantics/heuristic/preferred.lp framework.lp`
- **Recommended**: Use `semantics/preferred_saturation.lp` for guaranteed correctness

#### naive.lp
- **Definition**: Maximal (w.r.t. ⊆) conflict-free extensions
- **Method**: `#heuristic miss(X). [1,false]` to minimize missing assumptions
- **Guarantees**: Works on tested examples, not guaranteed in general
- **Usage**: `clingo -n 0 --heuristic=Domain --enum-mode=domRec <files> semantics/heuristic/naive.lp framework.lp`
- **Recommended**: Use `semantics/naive_saturation.lp` for guaranteed correctness

### Range-Maximality (range(S) = S ∪ S⁺)

#### semi-stable.lp
- **Status**: ⚠️ EXPERIMENTAL
- **Definition**: Admissible + maximal range(S)
- **Method**: `#heuristic not_in_range(X). [1,false]` to maximize range
- **Guarantees**: Approximate only - may miss maximal extensions or include non-maximal ones
- **Usage**: `clingo -n 0 --heuristic=Domain --enum-mode=domRec <files> semantics/heuristic/semi-stable.lp framework.lp`
- **Recommended**: Use `semantics/semi-stable_saturation.lp` for guaranteed correctness

#### staged.lp
- **Status**: ⚠️ EXPERIMENTAL
- **Definition**: Conflict-free + maximal range(S)
- **Method**: `#heuristic not_in_range(X). [1,false]` to maximize range
- **Guarantees**: Approximate only - may miss maximal extensions or include non-maximal ones
- **Usage**: `clingo -n 0 --heuristic=Domain --enum-mode=domRec <files> semantics/heuristic/staged.lp framework.lp`
- **Recommended**: Use `semantics/staged_saturation.lp` for guaranteed correctness

## Why Use Heuristic Versions?

**Advantages:**
- May be faster on some frameworks (heuristics can guide search efficiently)
- Simpler implementation (fewer rules than saturation)
- Useful for performance comparison and research

**Disadvantages:**
- Not guaranteed to be sound and complete
- Heuristics are **soft preferences**, not hard constraints
- May fail on complex frameworks with intricate attack structures

## Recommendation

**For production use**: Always prefer saturation-based versions in `semantics/` directory.

**For research/testing**: These heuristic versions can be useful for:
- Performance benchmarking
- Understanding the limits of heuristic approaches
- Quick prototyping (when approximate results are acceptable)

## Invocation Pattern

All heuristic-based semantics require domain heuristics:

```bash
clingo -n 0 --heuristic=Domain --enum-mode=domRec \
  core/base.lp \
  semiring/godel.lp \
  constraint/ub_max.lp \
  filter/standard.lp \
  semantics/heuristic/<semantic>.lp \
  framework.lp
```

Compare with saturation-based (simpler invocation):

```bash
clingo -n 0 \
  core/base.lp \
  semiring/godel.lp \
  constraint/ub_max.lp \
  filter/standard.lp \
  semantics/<semantic>_saturation.lp \
  framework.lp
```
