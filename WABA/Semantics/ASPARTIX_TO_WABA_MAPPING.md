# ASPARTIX (AAF) to WABA Predicate Mapping

**Date**: 2025-12-29
**Purpose**: Map ASPARTIX argumentation framework predicates to WABA equivalents

## Core Predicate Mapping

| ASPARTIX (AAF) | WABA | Notes |
|----------------|------|-------|
| `arg(X)` | `assumption(X)` | Domain: X is an argument/assumption |
| `att(X,Y)` | `contrary(Y,X)` | **⚠️ REVERSED PARAMETERS!** X attacks Y |
| `in(X)` | `in(X)` | X is in the extension (same) |
| `out(X)` | `out(X)` | X is out of the extension (same) |
| `defeated(X)` | `defeated(X)` | X is defeated (same) |

## Critical Differences

### 1. Attack Direction (REVERSED!)

**ASPARTIX**:
```prolog
att(X,Y).  % X attacks Y
defeated(X) :- in(Y), att(Y,X).  % X is defeated if Y is in and Y attacks X
```

**WABA**:
```prolog
contrary(Y,X).  % X attacks Y (parameters reversed!)
defeated(X) :- attacks_successfully_with_weight(_,X,_).  % X is defeated (computed in core)
```

### 2. Conflict-Free Definition

**ASPARTIX**:
```prolog
:- in(X), in(Y), att(X,Y).  % Explicit: both in, one attacks the other
```

**WABA**:
```prolog
:- in(X), defeated(X).  % Implicit: X in and defeated (core computes defeated)
```

WABA is cleaner because `defeated(X)` is pre-computed by `core/base.lp`.

### 3. Domain Generation

**ASPARTIX**: Explicitly guesses in/out for each `arg(X)`
```prolog
in(X) :- not out(X), arg(X).
out(X) :- not in(X), arg(X).
```

**WABA**: Core logic already provides in/out choice for `assumption(X)`
```prolog
% In core/base.lp:
in(X) :- assumption(X), not out(X).
out(X) :- assumption(X), not in(X).
```

**Consequence**: WABA semantic files should **NOT** redefine in/out!

## Semantic-Specific Predicates

### Admissible

**ASPARTIX**:
```prolog
not_defended(X) :- att(Y,X), not defeated(Y).  % X attacked by non-defeated Y
:- in(X), not_defended(X).  % All in(X) must be defended
```

**WABA Equivalent**:
```prolog
not_defended(X) :- assumption(X), contrary(X,Y), in(Y), not defeated(Y).
:- in(X), not_defended(X).
```

### Complete

**ASPARTIX**:
```prolog
:- in(X), not_defended(X).  % Admissible
:- out(X), not not_defended(X).  % All defended must be in
```

**WABA Equivalent**:
```prolog
not_defended(X) :- assumption(X), contrary(X,Y), in(Y), not defeated(Y).
:- in(X), not_defended(X).  % Admissible
:- out(X), not not_defended(X).  % All defended must be in
```

### Preferred (Heuristics)

**ASPARTIX**:
```prolog
% Complete labeling with in/out/undec
undec(X) :- ...
#heuristic in(X):arg(X). [1,true]
```

**WABA Equivalent**:
```prolog
% WABA doesn't use undec - only in/out
% Apply same heuristic to complete semantics
#heuristic in(X):assumption(X). [1,true]
```

### Grounded (Iterative)

**ASPARTIX**: Uses ordering with `inf`, `sup`, `succ` for iterative computation

**WABA Equivalent**: Same approach but with `assumption(X)` domain

## Helper Predicates Needed in WABA

Some ASPARTIX helper predicates need WABA equivalents:

| ASPARTIX Helper | Purpose | WABA Equivalent |
|-----------------|---------|-----------------|
| `not_defended(X)` | X has attacker not defeated | `not_defended(X)` |
| `okOut(X)` (naive) | X can be out (defeated or conflicts) | `okOut(X)` |
| `undec(X)` (preferred) | X is undecided | Not needed in WABA (only in/out) |
| `defended_upto(X,Y)` (grounded) | X defended up to level Y | `defended_upto(X,Y)` |

## Attack Translation Rules

When translating ASPARTIX to WABA, reverse attack direction:

```prolog
% ASPARTIX:
att(a,b).  % a attacks b

% WABA:
contrary(b,a).  % a attacks b (parameters reversed!)
```

**Rule**: `att(X,Y)` in ASPARTIX = `contrary(Y,X)` in WABA

## Testing Configuration

To test WABA semantics with plain ABA behavior (no weights):

```bash
clingo -n 0 -c beta=0 \
  core/base.lp \
  semiring/godel.lp \
  monoid/max_minimization.lp \
  constraint/lb_max.lp \  # Lower bound = 0 (allow all)
  filter/standard.lp \
  semantics/<semantic>.lp \
  <framework>.lp
```

**Key**: `beta=0` with `lb_max` means minimum cost ≥ 0, allowing all extensions (plain ABA).

## Implementation Order (Easiest → Hardest)

1. ✅ **Admissible** - Simple defense check
2. ⏳ **Complete** - Admissible + all defended in
3. ⏳ **Grounded** - Iterative construction (complex)
4. ⏳ **Preferred** - Heuristic-based maximal admissible
5. ⏳ **Semi-stable** - Range maximization
6. ⏳ **Staged** - Similar to semi-stable
7. ⏳ **CF2** - Maximal conflict-free with specific constraints

## Notes

- **NEVER modify**: stable.lp, naive.lp, cf.lp (already working)
- **NEVER modify**: core/base.lp, semiring/*, monoid/* (core infrastructure)
- All new semantics should be self-contained in `semantics/<name>.lp`
- Rely on core logic for: in/out choice, defeated computation, attack handling
