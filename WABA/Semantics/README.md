# WABA Semantics

## Available Semantics (2 total)

All flawed semantic implementations have been removed. Only the core, correct implementations remain:

| File | Semantic | Definition | Status |
|------|----------|------------|--------|
| `stable.lp` | Stable | Conflict-free + all out assumptions defeated | ✅ Verified |
| `cf.lp` | Conflict-Free | No internal attacks | ✅ Verified |

---

## Implementation

### Conflict-Free (cf.lp)

```prolog
%% conflict freeness
:- in(X), defeated(X).
```

**Semantics**: An extension is conflict-free if no assumption in the extension is defeated by the extension itself.

### Stable (stable.lp)

```prolog
#include "cf.lp".

%% stable
:- not defeated(X), out(X).
```

**Semantics**: An extension is stable if it is conflict-free AND every assumption outside the extension is defeated by the extension.

---

## Usage

### Basic Command

```bash
clingo -n 0 -c beta=0 \
  core/base.lp \
  semiring/godel.lp \
  monoid/sum_minimization.lp \
  constraint/ub_sum.lp \
  filter/standard.lp \
  semantics/stable.lp \
  <framework>.lp
```

### With Optimization

```bash
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

## Removed Semantics

The following semantics have been removed due to implementation flaws:
- `admissible.lp`
- `complete.lp`
- `grounded.lp`
- `preferred.lp`
- `semi-stable.lp`
- `staged.lp`
- `naive.lp`
- `ideal.lp`
- All experimental variants

These can be resurrected from git history (commits before `48902f1`) if needed for reference.

---

## Future Work

Correct implementations of additional semantics will be added based on proper ABA definitions from the literature:
- **Grounded**: Minimal complete extension
- **Preferred**: Maximal complete extension
- **Semi-stable**: Complete extension with maximal range
- **Complete**: Admissible + contains all defended assumptions
- **Admissible**: Conflict-free + defends all members

**Reference**: Caminada, M. "On the Difference between Assumption-Based Argumentation and Abstract Argumentation"

---

## Testing

```bash
# Test stable semantics
clingo -n 0 -c beta=0 \
  core/base.lp semiring/godel.lp monoid/sum_minimization.lp \
  constraint/ub_sum.lp filter/standard.lp \
  semantics/stable.lp \
  test/semantic_diversity/30_classical_aba_no_placeholders.lp

# Test conflict-free semantics
clingo -n 0 --opt-mode=enum -c beta=0 \
  core/base.lp semiring/godel.lp monoid/sum_minimization.lp \
  constraint/ub_sum.lp filter/standard.lp \
  semantics/cf.lp \
  test/semantic_diversity/30_classical_aba_no_placeholders.lp
```
