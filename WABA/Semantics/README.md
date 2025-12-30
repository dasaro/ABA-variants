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

## Heuristic Approach (Preferred & Naive)

Both preferred and naive use the **miss(X) heuristic** to achieve subset-maximality:

```prolog
miss(X) :- assumption(X), not in(X).
#heuristic miss(X) : assumption(X). [1,false]
```

This guides the solver to prefer models with fewer missing assumptions, achieving subset-maximality without explicit pairwise comparison or Python callbacks.

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
- `cf2.lp`, `semi-stable.lp`, `staged.lp` (non-standard semantics)
