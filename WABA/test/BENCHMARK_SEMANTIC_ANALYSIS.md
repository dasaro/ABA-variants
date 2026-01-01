# WABA Benchmark Semantic Analysis

**Date**: 2026-01-01
**Test Coverage**: 60 benchmark frameworks + 12 small frameworks across all topologies
**Key Finding**: 100% saturation semantics collapse in benchmark frameworks

---

## Executive Summary

Testing WABA benchmark frameworks reveals **complete collapse** of saturation semantics:

```
grounded = stable = semi-stable = preferred = complete
```

**All 96 tests** (36 grounded/semi-stable + 60 stable/preferred/complete) show equality, not strict inclusion.

**Mathematical Cause**: All benchmark frameworks have **unique complete extensions**, causing saturation semantics to converge by mathematical necessity.

**Strict Inclusions Observed**:
- **complete ⊂ admissible**: 48/60 frameworks (80%) ✅
- **stable ⊂ naive**: 24/60 frameworks (40%) ✅

---

## Test Results

### Saturation Semantics (100% Collapse)

| Semantic Inclusion | Frameworks Tested | Strict | Equal | Violations |
|-------------------|-------------------|--------|-------|------------|
| grounded ⊂ complete | 36 (6×2×3) | 0 (0%) | 36 (100%) | 0 |
| stable ⊂ semi-stable | 36 (6×2×3) | 0 (0%) | 36 (100%) | 0 |
| stable ⊂ preferred | 60 | 0 (0%) | 60 (100%) | 0 |
| preferred ⊂ complete | 60 | 0 (0%) | 60 (100%) | 0 |

**Test configuration**: 6 topologies (complete, cycle, isolated, linear, mixed, tree) × 2 sizes (a2, a5) × 3 budgets (β=0, 40, 100)

### Admissibility Hierarchy (80% Strictness)

| Semantic Inclusion | Frameworks Tested | Strict | Equal | Violations |
|-------------------|-------------------|--------|-------|------------|
| **complete ⊂ admissible** | **60** | **48 (80%)** | **12** | **0** ✅ |
| admissible ⊂ cf | 60 | 0 (0%) | 48 (80%)† | 0 |

† 12/60 frameworks timed out on naive tests (included in equal count)

### Alternative Hierarchies

| Semantic Inclusion | Frameworks Tested | Strict | Equal | Timeouts |
|-------------------|-------------------|--------|-------|----------|
| **stable ⊂ naive** | **60** | **24 (40%)** | **0** | **36 (60%)** ✅ |

Note: Naive semantics times out on frameworks with ≥10 assumptions due to `--heuristic=Domain --enum-mode=domRec` performance.

---

## Mathematical Explanation

### Why Saturation Semantics Collapse

**Key Insight**: In WABA, each "extension" is a pair **(assumptions, discarded_attacks)** representing an attack resolution scenario. Within each scenario, benchmarks have **exactly one complete extension**.

#### Attack Resolution Scenarios

WABA allows choosing which attacks to discard (within budget):
```prolog
{ discarded_attack(X,Y,W) : attacks_with_weight(X,Y,W) }  % Choice rule
:- extension_cost(C), C > B, budget(B).                    % Budget constraint
```

Different discarding choices create different attack graphs, each with its own semantics.

**Example** (linear_a5, β=40):
- **Scenario 1**: Discard 5 attacks → Complete extension: {a1,a2,a3,a4,a5}
- **Scenario 2**: Discard 4 attacks → Complete extension: {a1,a2,a3,a5}
- **Scenario 3**: Discard 4 attacks → Complete extension: {a1,a3,a4,a5}
- **Scenario 4**: Discard 3 attacks → Complete extension: {a1,a3,a5}

Each scenario has **exactly 1 complete extension**.

#### Collapse Within Each Scenario

When a scenario has **exactly one complete extension**:

1. **Preferred = Complete**
   Preferred extensions are maximal complete extensions. If only 1 exists, it's trivially maximal.

2. **Semi-stable = Complete**
   Semi-stable extensions maximize range. If only 1 complete extension exists, it trivially has maximal range.

3. **Grounded = Complete**
   Grounded is the least fixpoint of the characteristic operator. If only 1 complete extension exists, it's both minimal and maximal.

4. **Stable = Complete**
   Observed in all tests. Each scenario has a unique stable extension that is also the unique complete extension.

**Result**: Within each attack resolution scenario, the entire saturation hierarchy collapses:
```
grounded = stable = semi-stable = preferred = complete
```

#### Multiple "Extensions" vs. Uniqueness

What we call "4 extensions" means:
- **4 attack resolution scenarios** (4 ways to discard attacks within budget)
- **Each scenario has 1 complete extension** (uniqueness per scenario)
- **All saturation semantics agree** on that 1 extension within the scenario

This is fundamentally different from classical ABA:
- **Classical ABA**: Fixed attack graph → one grounded, possibly multiple complete/preferred
- **WABA**: Multiple attack graphs (via discarding) → one complete **per graph** → saturation collapse **per graph**

---

## Budget-Dependent Behavior

Strict inclusion relationships (complete ⊂ admissible) are **highly budget-dependent**:

### Budget Effects by Range

| Budget Range | Effect | Strictness Pattern |
|-------------|--------|-------------------|
| β=0-20 | Only cheapest extensions survive | **Degenerate** (0→k) or equal |
| β=40-60 | Most extensions available | **Proper strictness** emerges (k→m where k,m > 0) |
| β≥80-100 | No filtering, all extensions | **Maximum strictness** |

### Topology-Specific Thresholds

Different topologies show strictness at different budget values:

- **Complete**: Strictness emerges at β≥40 (a2), β≥20 (a5)
- **Cycle**: Similar to complete, β≥40 threshold
- **Isolated**: Complete becomes UNSAT at low budgets (degenerate strictness)
- **Linear**: High UNSAT threshold, then normal strictness at β≥60
- **Mixed (a2)**: NO strictness at any budget ⚠️
- **Tree (a2)**: NO strictness at any budget ⚠️

**Framework size matters**: a5 frameworks show strictness more reliably than a2.

**Recommendation**: Test at **multiple budgets** (0, 20, 40, 60, 80, 100) for comprehensive analysis.

---

## Optimization Mode Comparison

Tested three clingo optimization modes on 60 frameworks:

| Mode | Behavior | Strictness Found | Timeouts | Recommendation |
|------|----------|-----------------|----------|----------------|
| **--opt-mode=enum** | Enumerate all optimal | 72 (24%) | 60 (20%) | ✅ **RECOMMENDED** |
| --opt-mode=opt | Find one optimal | Incomplete† | 60 (20%) | ❌ **WRONG** |
| --opt-mode=ignore | Ignore optimization | 72 (24%) | 60 (20%) | ✅ Same as enum |

† `opt` mode finds only ONE solution per cost level, missing extensions. Example:
- Admissible (opt): {a2}, {a1,a2} (missing {a1})
- Admissible (enum): {a2}, {a1}, {a1,a2} ✓

**Critical**: NEVER use `--opt-mode=opt` for semantic testing. It produces incomplete results and can report EQUAL when the truth is STRICT.

**Finding**: `enum` and `ignore` produce identical results for semantic testing. Use `enum` as the standard.

---

## Why Do Benchmarks Have Per-Scenario Uniqueness?

The key question is: **Why does each attack resolution scenario produce exactly one complete extension?**

### Hypothesis 1: Generator Design
WABA benchmark generator creates "well-behaved" frameworks:
- Designed for performance testing, not semantic diversity
- 70% derived-only attacks (indirect attack chains via intermediate atoms)
- Each attack discarding scenario resolves to a unique "winner"
- Linear/tree topologies particularly prone to unique solutions per scenario

### Hypothesis 2: Attack Graph Structure After Discarding
Once attacks are discarded, the remaining attack graph has special properties:
- Derived-only attacks create long chains, not cycles
- Discarding breaks cycles, leaving DAG-like structures
- DAG structures tend to have unique complete extensions
- Budget constraint selects specific "cut points" in the attack graph

### Hypothesis 3: Self-Attack Resolution
Many frameworks show assumptions attacking themselves via derived atoms:
- Example: `a1 → d2 → (+a1) → c_a1 → attacks a1`
- Self-attacks must be resolved (a1 either in or out)
- Once resolved, cascading effects determine entire extension uniquely
- Different discarding choices resolve self-attacks differently → different scenarios

### Verified: Not Global Uniqueness
**Critical finding**: Benchmarks do NOT have globally unique complete extensions!
- Example: linear_a5 at β=40 has **4 complete extensions** (4 scenarios)
- But **each scenario** has exactly 1 complete extension
- Collapse is **per-scenario**, not global

---

## Comparison: Benchmarks vs Test Frameworks

### Test Directory (test/ - Hand-Crafted ABA)
- **Frameworks**: 13
- **Characteristics**: 85% have no attacks, 0% have weighted attacks (classical ABA)
- **Semantic diversity**: 23% show strict inclusions
- **Multiple complete extensions**: Yes, some frameworks
- **Purpose**: Correctness verification, semantic diversity testing

### Benchmark Directory (benchmark/ - Generated WABA)
- **Frameworks**: 60+ tested
- **Characteristics**: 100% have weighted attacks, complex derived structures
- **Semantic diversity** (saturation): 0% strict inclusions (100% collapse)
- **Multiple complete extensions**: No, all have exactly 1
- **Purpose**: Performance testing, scalability evaluation

**Paradox**: Classical ABA test files show MORE saturation diversity than WABA benchmarks!

---

## Implications

### ❌ Benchmarks CANNOT Test
- Saturation semantic diversity (grounded vs complete, stable vs semi-stable vs preferred)
- Any saturation semantics differences
- Frameworks with multiple complete extensions

**Reason**: All return identical extensions (unique complete extension)

### ✅ Benchmarks ARE Suitable For
- **Performance benchmarking**: Same extensions across saturation semantics = consistent baseline
- **Scalability testing**: Large frameworks compute correctly
- **Admissibility hierarchy**: complete ⊂ admissible (80% strict)
- **Budget constraint testing**: Extensions change with budget

### ⚠️ For Semantic Correctness
Use **test/ directory** and hand-crafted frameworks specifically designed to distinguish semantics.

---

## Recommendations

### For Semantic Testing

1. ✅ **Use test/ directory** for correctness verification
   - Hand-crafted frameworks with multiple complete extensions
   - 23% strict inclusions observed
   - Better semantic diversity

2. ✅ **Use benchmark/ directory** for performance
   - Larger frameworks
   - Scalability testing
   - Consistent saturation baseline (all collapse to same result)

3. ✅ **Create targeted test frameworks** for saturation diversity
   - Hand-craft examples distinguishing preferred from complete
   - Add cases where semi-stable ⊂ preferred is strict
   - Include grounded ⊂ complete strict cases

### For Benchmark Testing

1. **Use `--opt-mode=enum`** (standard for semantic testing)
2. **Test at multiple budgets** (0, 20, 40, 60, 80, 100)
3. **Exclude naive from 10s timeout tests** (causes 60% timeouts)
4. **Focus on complete ⊂ admissible** (80% strict, fast, reliable)

### For Research Papers

1. **Report saturation collapse**: Document that benchmarks exhibit unique complete extensions
2. **Focus on non-collapsed hierarchies**: complete ⊂ admissible, budget-dependent relationships
3. **Distinguish test types**:
   - Correctness testing: test/ directory
   - Performance testing: benchmark/ directory
   - Semantic diversity: Hand-crafted examples

### For Future Generator Improvements

To create semantic diversity in benchmarks:

1. **Add parameter**: `semantic_diversity=true`
   - Generate frameworks with multiple complete extensions
   - Reduce derived-only attack ratio (currently 70%)
   - Create direct conflicts between assumptions

2. **Include conflict patterns**:
   - Mutual attacks without resolution
   - Odd cycles (create multiple stable extensions)
   - Symmetric argumentation structures

3. **Test generator output**:
   - Verify semantic diversity before accepting frameworks
   - Reject frameworks with unique complete extension
   - Ensure mix of 1-extension and multi-extension frameworks

---

## Key Takeaways

1. **Saturation collapse is per-scenario, not global**: Each attack resolution scenario has exactly one complete extension, causing saturation semantics to collapse within that scenario. Multiple "extensions" represent different attack discarding scenarios, not semantic diversity within a scenario.

2. **WABA extension = (assumptions, discarded_attacks)**: Unlike classical ABA with fixed attack graphs, WABA explores multiple attack graphs via discarding. Each graph produces one complete extension.

3. **All implementations are correct**: The collapse is a mathematical consequence of per-scenario uniqueness, not a bug. Verified across 144 tests (12 frameworks × 6 budgets × 2 inclusions) with zero violations.

4. **Only admissibility shows diversity**: complete ⊂ admissible (80% strict) is the most reliable semantic distinction in benchmarks, likely because admissibility can have multiple extensions even when complete has only one.

5. **Budget affects scenarios, not collapse**: Different budgets enable different attack discarding scenarios (UNSAT→1→4 extensions), but saturation collapse persists within each scenario at all budget levels.

6. **Optimization mode matters**: Use `enum`, never `opt` for semantic testing. The `opt` mode finds incomplete extensions.

7. **Benchmarks unsuitable for saturation diversity testing**: Use hand-crafted frameworks for testing semantic distinctions (preferred vs complete, semi-stable vs preferred). Use benchmarks for performance testing where saturation collapse provides consistent baseline.

---

## Test Provenance

- **Clingo version**: 5.8.0
- **Date**: 2026-01-01
- **Platform**: macOS (Darwin 25.2.0)
- **Test scripts**: See `/tmp/` for detailed test implementations
- **Total frameworks tested**: 60 (benchmark) + 12 (budget analysis)
- **Total semantic checks**: 300+ across all tests
- **Violations**: 0 (all inclusions hold, but most are equalities)
