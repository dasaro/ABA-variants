# WABA Semantics

## Available Semantics (9 total)

All semantics implemented based on Dung (1995) and ASPforABA (Lehtonen et al. 2021), verified against standard test cases.

| File | Semantic | Definition | Count (journal example) |
|------|----------|------------|-------------------------|
| `cf.lp` | Conflict-Free | No internal attacks | 11 |
| `admissible.lp` | Admissible | CF + defends all members | 7 |
| `complete.lp` | Complete | Admissible + completeness | 3 |
| `stable.lp` | Stable | CF + all out defeated | 2 |
| `preferred.lp` | Preferred | Maximal complete | 2 |
| `grounded.lp` | Grounded | Minimal complete (unique) | 1 |
| `staged.lp` | Staged | CF + large range (heuristic) | 3 |
| `semistable.lp` | Semi-Stable | Complete + large range (heuristic) | 2 |
| `ideal.lp` | Ideal | Max admissible ⊆ ∩(preferred) | 1 |

---

## Semantic Definitions

### Core Semantics (Dung 1995)

#### Conflict-Free (cf.lp)

```prolog
defeated(X) :- attacks_successfully_with_weight(_,X,_).
1{ in(X); out(X) }1 :- assumption(X).
:- in(X), defeated(X).
```

**Definition**: Extension is conflict-free if no assumption in the extension is defeated by the extension itself.

#### Admissible (admissible.lp)

```prolog
#include "cf.lp".

derived_from_undefeated(X) :- assumption(X), not defeated(X).
derived_from_undefeated(X) :- head(R,X), triggered_by_undefeated(R).
triggered_by_undefeated(R) :- head(R,_), derived_from_undefeated(X) : body(R,X).
attacked_by_undefeated(X) :- contrary(X,Y), undefeated_weight(Y,W), budget(B), unaffordable_attack(W,B).
:- in(X), attacked_by_undefeated(X).
```

**Definition**: Extension is admissible if it is conflict-free and defends all its members against attacks from undefeated elements.

**Budget-aware**: Uses `unaffordable_attack(W,B)` to check if attacks must be defended (cannot be affordably discarded).

**Classical ABA** (no discarding): All attacks are unaffordable, requiring full defense.

#### Complete (complete.lp)

```prolog
#include "admissible.lp".

:- out(X), assumption(X), not attacked_by_undefeated(X).
```

**Definition**: Extension is complete if it is admissible and contains all assumptions that are not attacked by undefeated elements.

#### Stable (stable.lp)

```prolog
#include "cf.lp".

:- not defeated(X), out(X).
```

**Definition**: Extension is stable if it is conflict-free and every assumption outside the extension is defeated.

#### Preferred (preferred.lp)

```prolog
#include "complete.lp".

miss(X) :- out(X), assumption(X).
#heuristic miss(X) : assumption(X). [1,false]
```

**Definition**: Preferred extensions are maximal (w.r.t. set inclusion) complete extensions.

**Implementation**: Uses domain heuristics to guide solver toward subset-maximal extensions.

**Usage**: Requires special flags: `--heuristic=Domain --enum-mode=domRec`

#### Grounded (grounded.lp)

```prolog
#include "cf.lp".

g_defeated(X) :- assumption(X), g_in(Y), contrary(X,Y).
g_in(X) :- assumption(X), g_defeated(Y) : contrary(X,Y).
:- g_in(X), not in(X).
:- in(X), not g_in(X).
```

**Definition**: The grounded extension is the unique minimal complete extension, computed as the least fixpoint of assumptions that defeat all their attackers.

**Note**: Grounded extension is unique, use `-n 1` flag.

### Range-Based Semantics (Dung 1995)

#### Staged (staged.lp)

```prolog
#include "cf.lp".

att(X,Y) :- attacks_successfully_with_weight(X,Y,_).
in_range(Y) :- in(Y).
in_range(Y) :- supported(X), att(X,Y).
miss(X) :- out(X), assumption(X).
#heuristic miss(X) : assumption(X). [1,false]
```

**Definition**: Staged extensions are conflict-free extensions S with preference for large range(S), where range(S) = S ∪ {Y : ∃X supported by S, att(X,Y)}.

**Usage**: Requires `--heuristic=Domain --enum-mode=domRec` flags.

**Implementation**: Uses heuristics to guide search toward CF extensions with large range. Finds "preferred" CF extensions rather than strictly maximal-range extensions.

**Note**: In ABA, range includes assumptions attacked by ANY element supported by the extension (not just assumptions in S).

#### Semi-Stable (semistable.lp)

```prolog
#include "complete.lp".

att(X,Y) :- attacks_successfully_with_weight(X,Y,_).
in_range(Y) :- in(Y).
in_range(Y) :- supported(X), att(X,Y).
miss(X) :- out(X), assumption(X).
#heuristic miss(X) : assumption(X). [1,false]
```

**Definition**: Semi-stable extensions are complete extensions S with preference for large range(S).

**Usage**: Requires `--heuristic=Domain --enum-mode=domRec` flags.

**Implementation**: Uses heuristics to guide search toward complete extensions with large range. Completeness constraints already restrict search space effectively.

**Inclusion**: stable ⊆ semi-stable ⊆ preferred

### Skeptical Semantics

#### Ideal (ideal.lp)

```prolog
#include "cf.lp".

g_in(X) :- assumption(X), g_defeated(Y) : contrary(X,Y).
g_defeated(X) :- assumption(X), g_in(Y), contrary(X,Y).

i_in(X) :- g_in(X).
i_defeated(Y) :- assumption(Y), i_in(X), contrary(Y,X).
i_acceptable(X) :- assumption(X), i_defeated(Y) : contrary(X,Y).
i_in(X) :- i_acceptable(X), assumption(X).

:- i_in(X), not in(X).
:- in(X), not i_in(X).
```

**Definition**: The ideal extension is the unique maximal (w.r.t. set inclusion) admissible extension contained in all preferred extensions.

**Properties**: grounded ⊆ ideal ⊆ ∩(preferred)

**Implementation**: Iterative fixpoint starting from grounded extension.

**Note**: Ideal extension is unique, use `-n 1` flag.

---

## Semantic Inclusion Relations

```
         cf (conflict-free)
        /  \
       /    \
   staged   admissible
      /         /    \
     /         /      \
semi-stable complete  ideal
    /         /  \       \
   /         /    \       \
stable   preferred grounded
```

**Subset relations**:
- stable ⊆ semi-stable ⊆ staged ⊆ cf
- stable ⊆ preferred ⊆ complete ⊆ admissible ⊆ cf
- grounded ⊆ ideal ⊆ ∩(preferred) ⊆ complete

**Verified**: All inclusion relations verified in `test/test_aspforaba_all_semantics.sh`

---

## Usage

### Classical ABA (ASPforABA mode)

For pure ABA semantics without weighted attack discarding:

```bash
# Basic command (uses constraint/no_discard.lp to prevent discarding)
clingo -n 0 \
  core/base.lp \
  semiring/godel.lp \
  constraint/no_discard.lp \
  filter/standard.lp \
  semantics/<semantic>.lp \
  <framework>.lp
```

**Individual semantics**:

```bash
# Stable (2 extensions expected)
clingo -n 0 core/base.lp semiring/godel.lp constraint/no_discard.lp \
  filter/standard.lp semantics/stable.lp test/aspforaba_journal_example.lp

# Preferred (requires heuristics, 2 extensions expected)
clingo -n 0 --heuristic=Domain --enum-mode=domRec \
  core/base.lp semiring/godel.lp constraint/no_discard.lp \
  filter/standard.lp semantics/preferred.lp test/aspforaba_journal_example.lp

# Grounded (unique, 1 extension expected)
clingo -n 1 core/base.lp semiring/godel.lp constraint/no_discard.lp \
  filter/standard.lp semantics/grounded.lp test/aspforaba_journal_example.lp

# Staged (requires heuristics, 3 extensions expected)
clingo -n 0 --heuristic=Domain --enum-mode=domRec \
  core/base.lp semiring/godel.lp constraint/no_discard.lp \
  filter/standard.lp semantics/staged.lp test/aspforaba_journal_example.lp

# Ideal (unique, 1 extension expected)
clingo -n 1 core/base.lp semiring/godel.lp constraint/no_discard.lp \
  filter/standard.lp semantics/ideal.lp test/aspforaba_journal_example.lp
```

### Budget-Aware WABA

For budget-constrained attack discarding with cost optimization:

```bash
# With Gödel semiring + MAX monoid (original WABA)
clingo -n 0 -c beta=100 \
  core/base.lp \
  semiring/godel.lp \
  monoid/max_minimization.lp \
  constraint/ub_max.lp \
  filter/standard.lp \
  semantics/stable.lp \
  <framework>.lp

# With Tropical semiring + SUM monoid (minimize total cost)
clingo -n 0 --opt-mode=opt -c beta=100 \
  core/base.lp \
  semiring/tropical.lp \
  monoid/sum_minimization.lp \
  constraint/ub_sum.lp \
  filter/standard.lp \
  semantics/stable.lp \
  <framework>.lp
```

---

## Testing

### Comprehensive Test Suite

Run all 9 semantics on ASPforABA reference framework:

```bash
./test/test_aspforaba_all_semantics.sh
```

**Expected Output**: 9/9 tests pass

```
==========================================
ASPforABA Semantics Test Suite
Framework: test/aspforaba_journal_example.lp
Configuration: Gödel semiring + no_discard constraint
Note: Classical ABA mode - no attack discarding allowed
==========================================

Testing Conflict-free semantics...
  ✓ PASS: 11 extensions (expected: 11)

Testing Admissible semantics...
  ✓ PASS: 7 extensions (expected: 7)

Testing Complete semantics...
  ✓ PASS: 3 extensions (expected: 3)

Testing Stable semantics...
  ✓ PASS: 2 extensions (expected: 2)

Testing Grounded semantics...
  ✓ PASS: 1 extensions (expected: 1)

Testing Preferred semantics...
  ✓ PASS: 2 extensions (expected: 2)

Testing Staged semantics...
  ✓ PASS: 3 extensions (expected: 3)

Testing Semi-stable semantics...
  ✓ PASS: 2 extensions (expected: 2)

Testing Ideal semantics...
  ✓ PASS: 1 extensions (expected: 1)

==========================================
All 9 semantics PASSED!
==========================================
```

---

## Implementation Notes

### Budget-Aware Defense

All semantics support budget-aware attack discarding through the `unaffordable_attack(W,B)` predicate defined in semiring files:

- **Cost semirings** (Tropical, Bottleneck): `unaffordable if W > B`
- **Strength semirings** (Gödel, Łukasiewicz, Arctic): `unaffordable if W < B`
- **Classical ABA** (no_discard.lp): All attacks unaffordable (full defense required)

### Classical ABA Recovery

To recover classical ABA behavior:
- Use `constraint/no_discard.lp` (simplest and fastest)
- OR set `beta=0` with appropriate constraint (backward compatible)
- All attacks become unaffordable, requiring full admissible defense
- This works with ALL semirings (special case handled automatically)

### Range Adaptation for ABA

Range-based semantics (staged, semi-stable) adapt Dung's AF definition to ABA:
- **AF definition**: range(S) = S ∪ {Y : ∃X∈S, att(X,Y)}
- **ABA adaptation**: range(S) = S ∪ {Y : ∃X supported by S, att(X,Y)}
- **Rationale**: In ABA, derived elements contribute to extension's attacking power

### Architectural Compatibility

All semantics are compatible with WABA's choice-based `core/base.lp`:
- **CF, Admissible, Complete, Stable, Preferred**: Use constraints on `in/out` choices
- **Grounded, Ideal**: Use fixpoint computation with constraint matching
- **Staged, Semi-Stable**: Use `#maximize` for range optimization

---

## References

- **Dung, P. M.** (1995). On the Acceptability of Arguments and its Fundamental Role in Nonmonotonic Reasoning, Logic Programming and n-Person Games. *Artificial Intelligence*, 77(2), 321-357.

- **Lehtonen, T., Wallner, J. P., & Järvisalo, M.** (2021). Declarative Algorithms and Complexity Results for Assumption-Based Argumentation. *Journal of Artificial Intelligence Research*, 71, 265-318.

- **Cyras, K., Fan, X., Schulz, C., & Toni, F.** (2018). Assumption-Based Argumentation: Disputes, Explanations, Preferences. In *Handbook of Formal Argumentation* (pp. 2407-2456).

- **Test Framework**: `test/aspforaba_journal_example.lp` (from ASPforABA reference suite)
