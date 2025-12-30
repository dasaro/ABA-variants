# WABA Semantics

**All semantics based on ASPforABA (Lehtonen et al. 2021) proven-correct encodings, extended with saturation-based maximality checks.**

## Directory Structure

```
semantics/
├── README.md                       # This file
├── admissible.lp                   # Admissible semantics
├── complete.lp                     # Complete semantics
├── stable.lp                       # Stable semantics
├── grounded.lp                     # Grounded semantics
├── cf.lp                           # Conflict-free semantics
├── preferred.lp         # ⭐ Preferred (saturation-based)
├── naive.lp             # ⭐ Naive (saturation-based)
├── semi-stable.lp       # ⭐ Semi-stable (saturation-based)
├── staged.lp            # ⭐ Staged (saturation-based)
├── heuristic/                      # Alternative heuristic-based implementations
│   ├── README.md
│   ├── preferred.lp                # Preferred (heuristic)
│   ├── naive.lp                    # Naive (heuristic)
│   ├── semi-stable.lp              # Semi-stable (experimental)
│   └── staged.lp                   # Staged (experimental)
└── non-flat/                       # Non-flat ABA variants
    ├── README.md
    ├── admissible_closed.lp
    ├── complete_closed.lp
    └── stable_closed.lp
```

## Quick Start

### Basic Usage (Classical ABA)

For classical ABA semantics (no weighted attack discarding):

```bash
clingo -n 0 \
  core/base.lp \
  semiring/godel.lp \
  constraint/ub_max.lp \
  filter/standard.lp \
  semantics/<semantic>.lp \
  framework.lp
```

**CRITICAL**: Do NOT use monoid files for pure enumeration (only for optimization modes).

### Recommended Semantics

| Semantic | File | Invocation |
|----------|------|------------|
| Admissible | `admissible.lp` | `clingo -n 0 ...` |
| Complete | `complete.lp` | `clingo -n 0 ...` |
| Stable | `stable.lp` | `clingo -n 0 ...` |
| Grounded | `grounded.lp` | `clingo -n 1 ...` (unique extension) |
| Conflict-Free | `cf.lp` | `clingo -n 0 ...` |
| **Preferred** | `preferred.lp` ⭐ | `clingo -n 0 ...` |
| **Naive** | `naive.lp` ⭐ | `clingo -n 0 ...` |
| **Semi-Stable** | `semi-stable.lp` ⭐ | `clingo -n 0 ...` |
| **Staged** | `staged.lp` ⭐ | `clingo -n 0 ...` |

## Classical ABA Semantics

### Admissible Semantics
- **File**: `admissible.lp`
- **Definition**: Conflict-free + defends all included assumptions
- **Encoding**: Closure under undefeated assumptions (ASPforABA)
- **Status**: ✅ Fully working, proven correct

### Complete Semantics
- **File**: `complete.lp`
- **Definition**: Admissible + contains all defended assumptions
- **Encoding**: Admissible + completeness constraint (ASPforABA)
- **Status**: ✅ Fully working, proven correct

### Stable Semantics
- **File**: `stable.lp`
- **Definition**: Conflict-free + all non-included assumptions are defeated
- **Encoding**: Original WABA encoding (minimal, 2 lines)
- **Status**: ✅ Fully working

### Grounded Semantics
- **File**: `grounded.lp`
- **Definition**: Unique minimal complete extension (least fixpoint)
- **Encoding**: Iterative timestamped construction (ASPforABA)
- **Invocation**: `clingo -n 1` (only one extension exists)
- **Status**: ✅ Fully working, proven correct

### Conflict-Free Semantics
- **File**: `cf.lp`
- **Definition**: No assumption attacks another in the extension
- **Encoding**: Minimal (1 line: `:- in(X), defeated(X).`)
- **Status**: ✅ Fully working

## Maximal Semantics (Saturation-Based) ⭐

These semantics use **saturation-based maximality checks** via proof by contradiction. They are **sound and complete** - guaranteed to find all and only maximal extensions.

### Preferred Semantics (⊆-maximal Complete)
- **File**: `preferred.lp` ⭐ **RECOMMENDED**
- **Definition**: Maximal (w.r.t. ⊆) complete extensions
- **Method**: Saturation-based subset-maximality check
- **Guarantees**: Sound and complete
- **Invocation**: `clingo -n 0` (no heuristics needed!)

**How it works:**
1. If extension is missing assumptions (not ⊆-maximal), try to witness a strictly larger complete extension
2. If witness succeeds (larger extension is complete), reject current extension
3. If witness fails (all larger extensions violate completeness), accept as maximal

### Naive Semantics (⊆-maximal Conflict-Free)
- **File**: `naive.lp` ⭐ **RECOMMENDED**
- **Definition**: Maximal (w.r.t. ⊆) conflict-free extensions
- **Method**: Saturation-based subset-maximality check
- **Guarantees**: Sound and complete
- **Invocation**: `clingo -n 0` (no heuristics needed!)

### Semi-Stable Semantics (Range-Maximal Admissible)
- **File**: `semi-stable.lp` ⭐ **RECOMMENDED**
- **Definition**: Admissible + maximal range(S) where range(S) = S ∪ S⁺
- **Method**: Saturation-based range-maximality check
- **Guarantees**: Sound and complete
- **Invocation**: `clingo -n 0` (no heuristics needed!)

**Range definition**: range(S) = S ∪ S⁺ where S⁺ = {b ∈ A | ∃a ∈ S: (a,b) ∈ attacks}

### Staged Semantics (Range-Maximal Conflict-Free)
- **File**: `staged.lp` ⭐ **RECOMMENDED**
- **Definition**: Conflict-free + maximal range(S) where range(S) = S ∪ S⁺
- **Method**: Saturation-based range-maximality check
- **Guarantees**: Sound and complete
- **Invocation**: `clingo -n 0` (no heuristics needed!)

## Saturation Approach Explained

The saturation approach uses **proof by contradiction** to enforce maximality as a hard constraint in ASP:

### Subset-Maximality (Preferred & Naive)

```prolog
%% If not ⊆-maximal, try to witness a larger extension
miss(X) :- assumption(X), not in(X).
unstable :- miss(_).

larger_ext(X) : miss(X) :- unstable.           % Guess larger extension
larger_ext(X) :- in(X), unstable.              % Include current extension
:- unstable, { larger_ext(X) : miss(X) } = 0.  % Must be strictly larger

%% Check if larger_ext violates constraints (conflict-free, complete, etc.)
spoil :- <constraint violation>.

%% Saturation: if spoiled, make constraint trivial
larger_ext(X) :- spoil, assumption(X), unstable.

%% Reject if larger valid extension exists
:- unstable, not spoil.
```

**Key insight**: An extension is maximal iff we cannot witness a strictly larger valid extension.

### Range-Maximality (Semi-Stable & Staged)

Similar approach but witnesses larger range(S) = S ∪ S⁺ instead of larger S.

```prolog
out_of_range(X) :- assumption(X), not in_range(X).
unstable :- out_of_range(_).

larger_range(X) : out_of_range(X) :- unstable.
larger_range(X) :- in_range(X), unstable.

witness(X) | witness(Z) : contrary(X,Z) :- larger_range(X), unstable.
spoil :- witness(X), witness(Y), contrary(Y,X), unstable.

:- unstable, not spoil.
```

## Alternative Implementations

See `heuristic/README.md` for heuristic-based alternatives:
- `heuristic/preferred.lp` - Heuristic subset-max (works on tested examples)
- `heuristic/naive.lp` - Heuristic subset-max (works on tested examples)
- `heuristic/semi-stable.lp` - ⚠️ Experimental (approximate only)
- `heuristic/staged.lp` - ⚠️ Experimental (approximate only)

**Recommendation**: Use saturation-based versions in main directory for production. Heuristic versions are useful for performance comparison and research.

## Non-Flat ABA

See `non-flat/README.md` for semantics with closure constraints:
- `non-flat/admissible_closed.lp`
- `non-flat/complete_closed.lp`
- `non-flat/stable_closed.lp`

Use these when assumptions can appear as rule heads (non-flat frameworks).

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

## Testing

Example with journal framework:

```bash
# Test admissible semantics
clingo -n 0 core/base.lp semiring/godel.lp constraint/ub_max.lp \
  filter/standard.lp semantics/admissible.lp \
  test/aspforaba_journal_example.lp

# Test preferred (saturation-based)
clingo -n 0 core/base.lp semiring/godel.lp constraint/ub_max.lp \
  filter/standard.lp semantics/preferred.lp \
  test/aspforaba_journal_example.lp

# Expected: 2 preferred extensions {a,b}, {a,c,d}
```

## Implementation Status

| Semantic | Status | Guarantees | Method |
|----------|--------|------------|--------|
| Admissible | ✅ Working | Proven correct | ASPforABA encoding |
| Complete | ✅ Working | Proven correct | ASPforABA encoding |
| Stable | ✅ Working | Proven correct | WABA encoding |
| Grounded | ✅ Working | Proven correct | ASPforABA encoding |
| Conflict-Free | ✅ Working | Trivial | Single constraint |
| Preferred | ⭐ Saturation | Sound & complete | Proof by contradiction |
| Naive | ⭐ Saturation | Sound & complete | Proof by contradiction |
| Semi-Stable | ⭐ Saturation | Sound & complete | Proof by contradiction |
| Staged | ⭐ Saturation | Sound & complete | Proof by contradiction |

## References

- **ASPforABA**: Lehtonen, T., Wallner, J. P., & Järvisalo, M. (2021). "Declarative Algorithms and Complexity Results for Assumption-Based Argumentation". Journal of Artificial Intelligence Research (JAIR) and Theory and Practice of Logic Programming (TPLP).
- **Repository**: https://github.com/coreo-group/aspforaba
- **Encoder**: `src/aspforaba/encoder.py`
- **Solver**: `src/aspforaba/aba_solver.py`

## Advantages Over ASPforABA

1. **Pure ASP for maximal semantics**: No Python callbacks needed for preferred/naive
2. **Saturation-based maximality**: Sound and complete without heuristics
3. **Modular semiring/monoid system**: Support for weighted WABA
4. **Simpler invocation**: No special heuristic flags for saturation variants
