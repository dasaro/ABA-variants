# Non-Flat ABA Semantics

This directory contains semantics for **non-flat ABA frameworks** where assumptions can also appear as rule heads (derived assumptions).

## Non-Flat vs Flat ABA

**Flat ABA**: Assumptions and derived atoms are disjoint
- `assumption(X)` → NOT `head(R, X)` for any rule R

**Non-Flat ABA**: Assumptions can be derived by rules
- `assumption(X)` AND `head(R, X)` both possible
- Requires **closure constraint**: derived assumptions must be in the extension

## Files

### admissible_closed.lp
- **Definition**: Admissible + closure constraint
- **Closure**: If X is an assumption and X is derived, then X must be in the extension
- **Usage**: `clingo -n 0 <files> semantics/non-flat/admissible_closed.lp framework.lp`

### complete_closed.lp
- **Definition**: Complete + closure constraint
- **Closure**: If X is an assumption and X is derived, then X must be in the extension
- **Usage**: `clingo -n 0 <files> semantics/non-flat/complete_closed.lp framework.lp`

### stable_closed.lp
- **Definition**: Stable + closure constraint
- **Closure**: If X is an assumption and X is derived, then X must be in the extension
- **Usage**: `clingo -n 0 <files> semantics/non-flat/stable_closed.lp framework.lp`

## When to Use

Use these semantics when your ABA framework has:
- Assumptions that appear as rule heads
- Recursive definitions involving assumptions
- Derived assumptions that must be explicitly included in extensions

## Invocation Pattern

Same as standard semantics, just use the closed variant:

```bash
clingo -n 0 \
  core/base.lp \
  semiring/godel.lp \
  constraint/ub_max.lp \
  filter/standard.lp \
  semantics/non-flat/<semantic>_closed.lp \
  framework.lp
```

## Example

```prolog
%% Non-flat framework example
assumption(a).
assumption(b).

%% a can be derived (non-flat!)
head(r1, a). body(r1, b).

%% With admissible_closed.lp:
%% If b is in extension and r1 triggers, then a must also be in extension
```

## Implementation

The closure constraint is typically implemented as:

```prolog
%% If assumption X is derived (supported via rules), it must be in
:- assumption(X), supported(X), head(_, X), not in(X).
```

This ensures that extensions respect the derivability of assumptions in non-flat frameworks.
