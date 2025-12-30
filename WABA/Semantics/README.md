# WABA Semantics

**All semantics based on ASPforABA (Lehtonen et al. 2021) proven-correct encodings.**

## Classical ABA Semantics

### ✅ Fully Implemented (Pure ASP)

#### Admissible Semantics
- **File**: `admissible.lp`
- **Definition**: Conflict-free + defends all included assumptions
- **Encoding**: Closure under undefeated assumptions
- **Usage**: `clingo -n 0 core/base.lp semiring/godel.lp constraint/ub_max.lp filter/standard.lp semantics/admissible.lp framework.lp`

#### Complete Semantics
- **File**: `complete.lp`
- **Definition**: Admissible + contains all defended assumptions
- **Encoding**: Admissible + completeness constraint
- **Usage**: `clingo -n 0 core/base.lp semiring/godel.lp constraint/ub_max.lp filter/standard.lp semantics/complete.lp framework.lp`

#### Stable Semantics
- **File**: `stable.lp`
- **Definition**: Conflict-free + all non-included assumptions are defeated
- **Encoding**: Original WABA encoding (minimal, 2 lines)
- **Usage**: `clingo -n 0 core/base.lp semiring/godel.lp constraint/ub_max.lp filter/standard.lp semantics/stable.lp framework.lp`

#### Grounded Semantics
- **File**: `grounded.lp`
- **Definition**: Unique minimal complete extension (least fixpoint)
- **Encoding**: Iterative timestamped construction
- **Usage**: `clingo -n 1 core/base.lp semiring/godel.lp constraint/ub_max.lp filter/standard.lp semantics/grounded.lp framework.lp`

#### Preferred Semantics
- **File**: `preferred.lp`
- **Definition**: Maximal (w.r.t. set inclusion) complete extensions
- **Encoding**: Complete + heuristic to minimize missing assumptions
- **Usage**: `clingo -n 0 --heuristic=Domain --enum-mode=domRec core/base.lp semiring/godel.lp constraint/ub_max.lp filter/standard.lp semantics/preferred.lp framework.lp`
- **Key Feature**: Uses domain heuristics to achieve subset-maximality in pure ASP (improvement over ASPforABA's Python approach!)

#### Conflict-Free Semantics
- **File**: `cf.lp`
- **Definition**: No assumption attacks another in the extension
- **Encoding**: Minimal (1 line)
- **Usage**: `clingo -n 0 core/base.lp semiring/godel.lp constraint/ub_max.lp filter/standard.lp semantics/cf.lp framework.lp`

#### Naive Semantics
- **File**: `naive.lp`
- **Definition**: Maximal (w.r.t. set inclusion) conflict-free extensions
- **Encoding**: Conflict-free + heuristic to minimize missing assumptions
- **Usage**: `clingo -n 0 --heuristic=Domain --enum-mode=domRec core/base.lp semiring/godel.lp constraint/ub_max.lp filter/standard.lp semantics/naive.lp framework.lp`

### ✅ Semi-Stable and Staged Semantics

These semantics have two implementations: **saturation-based** (recommended, sound & complete) and **heuristic-based** (experimental, may fail on complex frameworks).

#### Semi-Stable Semantics (Saturation-Based) ⭐ RECOMMENDED
- **File**: `semi-stable_saturation.lp`
- **Definition**: Admissible + maximal range(S) where range(S) = S ∪ S⁺
- **Encoding**: Saturation-based maximality check via proof by contradiction
- **Usage**: `clingo -n 0 core/base.lp semiring/godel.lp constraint/ub_max.lp filter/standard.lp semantics/semi-stable_saturation.lp framework.lp`
- **Guarantees**: Sound and complete - finds all and only range-maximal admissible extensions

#### Staged Semantics (Saturation-Based) ⭐ RECOMMENDED
- **File**: `staged_saturation.lp`
- **Definition**: Conflict-free + maximal range(S) where range(S) = S ∪ S⁺
- **Encoding**: Saturation-based maximality check via proof by contradiction
- **Usage**: `clingo -n 0 core/base.lp semiring/godel.lp constraint/ub_max.lp filter/standard.lp semantics/staged_saturation.lp framework.lp`
- **Guarantees**: Sound and complete - finds all and only range-maximal conflict-free extensions

### ⚠️ EXPERIMENTAL: Heuristic-Based Variants

Alternative implementations using heuristics. Faster but may be incomplete on complex frameworks.

#### Semi-Stable Semantics (Heuristic-Based)
- **File**: `semi-stable.lp`
- **Encoding**: Admissible + heuristic to minimize not_in_range(X)
- **Usage**: `clingo -n 0 --heuristic=Domain --enum-mode=domRec core/base.lp semiring/godel.lp constraint/ub_max.lp filter/standard.lp semantics/semi-stable.lp framework.lp`
- **Limitation**: Heuristics provide soft preferences, not hard constraints. May miss some maximal extensions or include non-maximal ones on complex frameworks.

#### Staged Semantics (Heuristic-Based)
- **File**: `staged.lp`
- **Encoding**: Conflict-free + heuristic to minimize not_in_range(X)
- **Usage**: `clingo -n 0 --heuristic=Domain --enum-mode=domRec core/base.lp semiring/godel.lp constraint/ub_max.lp filter/standard.lp semantics/staged.lp framework.lp`
- **Limitation**: Heuristics provide soft preferences, not hard constraints. May miss some maximal extensions or include non-maximal ones on complex frameworks.

### ⚠️ Partial Implementation

#### Ideal Semantics
- **File**: `ideal.lp`
- **Definition**: Unique maximal admissible extension contained in all preferred extensions
- **Current Behavior**: Returns all admissible extensions
- **Limitation**: Full ideal computation requires Python implementation (see ASPforABA's `_ideal` method)
- **Usage**: `clingo -n 0 core/base.lp semiring/godel.lp constraint/ub_max.lp filter/standard.lp semantics/ideal.lp framework.lp`

## Non-Flat ABA Extensions

Non-flat ABA requires that derived assumptions must also be in the extension (closure constraint).

### ✅ Implemented

- **admissible_closed.lp**: Admissible with closure constraint
- **complete_closed.lp**: Complete with closure constraint
- **stable_closed.lp**: Stable with closure constraint

**Usage**: Same as standard semantics but replace the semantics file.

## Key Configuration

For **classical ABA** (no weighted attack discarding):

```bash
clingo -n 0 \
  core/base.lp \
  semiring/godel.lp \
  constraint/ub_max.lp \  # Enforces budget=0 (no discarding)
  filter/standard.lp \
  semantics/<semantic>.lp \
  framework.lp
```

**CRITICAL**: Do NOT use monoid files for pure enumeration (only for optimization modes).

For **preferred and naive** semantics, add domain heuristics:

```bash
clingo -n 0 --heuristic=Domain --enum-mode=domRec \
  core/base.lp semiring/godel.lp constraint/ub_max.lp \
  filter/standard.lp semantics/preferred.lp framework.lp
```

## Implementation Approaches

### Subset-Maximality (Preferred & Naive) - Heuristic-Based

Both preferred and naive use the **miss(X) heuristic** to achieve subset-maximality:

```prolog
miss(X) :- assumption(X), not in(X).
#heuristic miss(X) : assumption(X). [1,false]
```

This guides the solver to prefer models with fewer missing assumptions, achieving subset-maximality without explicit pairwise comparison or Python callbacks.

### Range-Maximality - Two Approaches

#### 1. Saturation-Based (Semi-Stable & Staged) ⭐ RECOMMENDED

Uses proof by contradiction to enforce range-maximality as a hard constraint:

```prolog
%% If not range-maximal (unstable), try to witness a larger range
out_of_range(X) :- assumption(X), not range(X).
unstable :- out_of_range(_).

%% Guess a larger range when unstable
larger_range(X) : out_of_range(X) :- unstable.
larger_range(X) :- range(X), unstable.

%% Witness attacks to explain the larger range
witness(X) | witness(Z) : contrary(X,Z) :- larger_range(X), unstable.

%% Check if witnessed range is conflict-free/admissible
spoil :- witness(X), witness(Y), contrary(Y,X), unstable.

%% Reject if larger range exists (unstable but not spoiled)
:- unstable, not spoil.
```

**Key idea**: An extension is range-maximal iff we cannot witness a strictly larger conflict-free/admissible range. The saturation rules make spoil=true whenever the witness is invalid, trivializing the final constraint.

**Guarantees**: Sound and complete - finds all and only maximal extensions.

#### 2. Heuristic-Based (Semi-Stable & Staged) - EXPERIMENTAL

Uses heuristics to approximate range-maximality:

```prolog
in_range(X) :- assumption(X), in(X).
in_range(X) :- assumption(X), defeated(X).
not_in_range(X) :- assumption(X), not in_range(X).
#heuristic not_in_range(X). [1,false]
```

**Important**: Heuristics are soft preferences, not hard constraints. While this approach works correctly on tested examples, it may fail to achieve strict maximality on complex frameworks. This is a fundamental limitation of heuristic-based approaches in ASP.

## Testing

See `test/test_aspforaba_corrected.sh` for comprehensive test suite against ASPforABA reference implementations.

## References

- **ASPforABA**: Lehtonen, T., Wallner, J. P., & Järvisalo, M. (2021). JAIR/TPLP.
- **Repository**: https://github.com/coreo-group/aspforaba
- **Encoder**: `src/aspforaba/encoder.py`
- **Solver**: `src/aspforaba/aba_solver.py`

## Removed Files

The following experimental/outdated implementations have been removed (available in git history if needed):
- All `*_aspartix.lp` variants (ASPARTIX-based experiments)
- `cf2.lp` (non-standard semantics)
