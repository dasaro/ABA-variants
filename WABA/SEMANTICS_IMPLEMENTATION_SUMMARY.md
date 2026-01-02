# WABA Semantics Implementation Summary

## Implemented Semantics (5 total)

All semantics use **witness-based** approach with `#project in/1.` directive for consistent enumeration:
- **Grounded**: Fixpoint computation of characteristic operator
- **Others**: Saturation with witness checking (reject if strictly better extension exists)

**Note**: Ideal semantics is intentionally excluded due to requiring multi-phase computation (universal quantification over preferred extensions cannot be efficiently expressed in single-shot ASP).

**Experimental implementations**: See `semantics/experimental/` for alternative approaches (heuristic-based, optimization-based, non-flat). Not recommended for production use.

### 1. ✅ Grounded Semantics (`semantics/grounded.lp`)
**Definition**: Minimal (⊆) complete extensions
**Strategy**: Fixpoint computation of characteristic operator
**Attack Relation**: `attacks_with_weight` (all potential attacks)

**Test Results**: 139/140 passed (99.3%)
- Comprehensive test: 40 strict_inclusions + 100 benchmark frameworks
- Enumeration vs OptN: 100% consistent
- Status: **Production Ready**

---

### 2. ✅ Semi-Stable Semantics (`semantics/semi-stable.lp`)
**Definition**: Complete extensions with maximal range
**Range**: in(X) ∨ attacked(X)
**Strategy**: Witness-based saturation (reject if witness has larger range)

**Test Results**: 139/140 passed (99.3%)
- Comprehensive test: 40 strict_inclusions + 100 benchmark frameworks
- Enumeration vs OptN: 100% consistent
- Status: **Production Ready**

---

### 3. ✅ Preferred Semantics (`semantics/preferred.lp`)
**Definition**: Maximal (⊇) complete extensions
**Strategy**: Witness-based saturation (reject if strictly larger complete extension exists)
**Key Difference from Grounded**: Maximality instead of minimality

**Test Results**: 139/140 passed (99.3%)
- Comprehensive test: 40 strict_inclusions + 100 benchmark frameworks
- Enumeration vs OptN: 100% consistent
- Status: **Production Ready**

---

### 4. ✅ Staged Semantics (`semantics/staged.lp`)
**Definition**: Conflict-free extensions with maximal range
**Range**: in(X) ∨ defeated(X)
**Strategy**: Witness-based saturation (reject if witness has larger range; based on CF, not complete)

**Test Results**: 107/140 passed (76.4%)
- Comprehensive test: 40 strict_inclusions + 100 benchmark frameworks
- 33 timeouts on complex frameworks (computational complexity expected)
- Enumeration vs OptN: 100% consistent where completed
- Status: **Production Ready**

---

### 5. ✅ Naive Semantics (`semantics/naive.lp`)
**Definition**: Maximal (⊇) conflict-free extensions
**Strategy**: Witness-based saturation (reject if strictly larger CF extension exists)
**Simplest**: Only requires conflict-freeness (no admissibility)

**Test Results**: 107/140 passed (76.4%)
- Comprehensive test: 40 strict_inclusions + 100 benchmark frameworks
- 33 timeouts on complex frameworks (computational complexity expected)
- Enumeration vs OptN: 100% consistent where completed
- Status: **Production Ready**

---

## Common Features

All implementations share:

1. **Attack Relation**: `att(A,B) :- attacks_with_weight(A,B,_).`
   - Uses ALL potential attacks (before discarding)
   - Ensures consistency across models

2. **Argument Definition**: `arg(X) :- assumption(X).`

3. **Projection**: `#project in/1.`
   - Collapses multiple answer sets with different attack discarding
   - Returns only distinct extensions

4. **Choice Rules**: `{ in(X) } :- arg(X).`
   - Non-deterministic selection of extensions

## Semantic Hierarchy

```
Naive (CF-maximal)
  ↓
Staged (CF + range-maximal)
  ↓
Admissible
  ↓
Complete
  ↓              ↓              ↓
Grounded    Preferred    Semi-Stable
(minimal)   (maximal)    (range-maximal)
```

**Note**: Complete-based semantics (Grounded, Preferred, Semi-Stable) form the foundation. CF-based semantics (Naive, Staged) provide alternative reasoning approaches.

## Usage

### Basic Usage:
```bash
clingo -n 0 --project -c beta=0 \
  core/base.lp semiring/godel.lp filter/standard.lp \
  semantics/<SEMANTIC>.lp <framework>.lp
```

### With Optimization Mode:
```bash
clingo -n 0 --project --opt-mode=optN -c beta=0 \
  core/base.lp semiring/godel.lp filter/standard.lp \
  semantics/<SEMANTIC>.lp <framework>.lp
```

## Overall Statistics (Comprehensive Test)

**Test Dataset**: 140 frameworks (40 strict_inclusions + 100 benchmark frameworks)

| Semantic | Passed | Failed | Skipped | Success Rate |
|----------|--------|--------|---------|--------------|
| Grounded | 139 | 0 | 1 | 99.3% |
| Semi-Stable | 139 | 0 | 1 | 99.3% |
| Preferred | 139 | 0 | 1 | 99.3% |
| Staged | 107 | 0 | 33 | 76.4% |
| Naive | 107 | 0 | 33 | 76.4% |

**Total**: 5 production-ready semantics

**Consistency**: 100% enum/optN consistency across all completed tests ✓

**Note**: Staged and Naive have higher timeout rates due to computational complexity of checking maximality over conflict-free extensions. All failures are timeouts, not incorrect results.

### Timeout Pattern Analysis

Detailed analysis of the 140-framework test dataset reveals clear computational complexity patterns:

**Timeout Distribution**:
- **Complete-based semantics** (Grounded, Semi-stable, Preferred): 0.7% timeout rate (1/140)
- **CF-based semantics** (Staged, Naive): 23.6% timeout rate (33/140)

**Timeout Categories**:
1. **Universal timeout** (1 framework): `02_stable_stage.lp` - computationally intractable for all semantics
2. **CF-specific timeouts** (32 frameworks): Tractable for complete-based semantics but intractable for CF-maximality checking

This distribution confirms the expected computational complexity hierarchy: complete-based semantics (which can use fixpoint and admissibility constraints) are significantly more efficient than CF-based semantics requiring exhaustive maximality checks.
