# WABA Framework Best Practices

This document outlines best practices for creating and validating WABA frameworks.

---

## 1. Structural Requirements

### 1.1 Derived Atoms (MANDATORY)

**Requirement 1.1a**: Every WABA framework MUST have **at least one derived atom** (non-assumption, non-contrary).

**Requirement 1.1b** (CRITICAL): **Every derived atom MUST participate in at least one attack chain** (derivation path leading to a contrary atom).

**Requirement 1.1c** (OPTIONAL): Derived atoms MAY appear in multiple attack chains, and MAY appear alongside assumptions in rule bodies.

**Rationale**:
- **Semantic Richness**: Derived atoms represent intermediate reasoning steps
- **Realistic Modeling**: Real argumentation involves multi-step reasoning chains
- **Comprehensive Testing**: Tests weight propagation through derivation rules
- **Full WABA Semantics**: Demonstrates conjunction/disjunction operators in semirings
- **No Dead Weight**: Derived atoms that don't lead to attacks are meaningless (don't affect extensions)
- **Attack Chain Requirement**: If a derived atom doesn't participate in any attack chain, it has zero semantic impact

**Valid Attack Chain Patterns**:
1. **Simple chain**: `a1⊢d1⊢c_a2` (d1 directly derives contrary)
2. **Multi-chain**: `a1⊢d1⊢c_a2` AND `a2,a3⊢d2⊢c_a4` (multiple independent chains)
3. **Mixed bodies**: `d3 ← a1, d2` (derived atom d3 uses assumption a1 and derived atom d2)
4. **Multi-level**: `a1⊢d1⊢d2⊢c_a3` (derived atoms chain into each other)

**⚠️ Current Benchmark Issue**: 83.3% of benchmark frameworks (100/120) violate requirement 1.1b - their derived atoms don't lead to attacks. This is a known quality issue to be fixed in future generations.

**Example - Compliant Framework** ✅:
```prolog
% Parameters: A=5, R=2
assumption(a1; a2; a3; a4; a5).

% Derived atoms that LEAD TO ATTACKS
head(r_d1, d1).  % d1 <- a1, a2
body(r_d1, a1; r_d1, a2).

head(r_d2, d2).  % d2 <- a3, a4
body(r_d2, a3; r_d2, a4).

% d1 and d2 are used to derive contrary (attack chain!)
head(r_atk, c_a5).  % c_a5 <- d1, d2
body(r_atk, d1; r_atk, d2).

% Contraries
contrary(a1, c_a1).
contrary(a5, c_a5).  % c_a5 attacks a5
...
```

**Example - Non-Compliant Framework** ❌:
```prolog
% Parameters: A=3, R=1
assumption(a1; a2; a3).

% USELESS derived atom (doesn't lead to any attack!)
head(r_d1, d1).  % d1 <- a1, a2
body(r_d1, a1; r_d1, a2).

% Attack rules ignore d1 (d1 is dead weight)
head(r_atk_a1_a2, c_a2).  % c_a2 <- a1
body(r_atk_a1_a2, a1).

% Contraries
contrary(a1, c_a1).
contrary(a2, c_a2).
contrary(a3, c_a3).
```
**Why non-compliant**: d1 is derived but never used - it doesn't participate in any attack chain, so it doesn't affect which arguments attack which. It's computationally wasteful and semantically meaningless.

**Example - Non-Compliant Framework** ❌:
```prolog
% Parameters: A=5, R=0 (no derived atoms)
assumption(a1; a2; a3; a4; a5).

% Only attack rules (no intermediate reasoning)
head(r_atk_a1_a2, c_a2).  % c_a2 <- a1
body(r_atk_a1_a2, a1).

% Contraries
contrary(a1, c_a1).
...

% NO derived atoms - oversimplified!
```

**Verification**:
```bash
# Check framework has at least one derived atom
python3 /tmp/check_derived_atoms.py
```

**Known Issue**: Current complete topology frameworks violate this (R=0). See `benchmark/COMPLETE_TOPOLOGY_ISSUE.md` for details.

---

### 1.2 Flat-WABA Constraint (REQUIRED)

**Requirement**: Assumptions can **ONLY** appear in rule **BODIES**, never in rule **HEADS**.

**Rationale**:
- Ensures assumptions are atomic (non-derivable)
- Prevents circular reasoning
- Simplifies weight propagation semantics
- Standard assumption-based argumentation structure

**Example - Compliant** ✅:
```prolog
assumption(a1).

% Assumptions ONLY in bodies
head(r1, d1).    % Derived atom as head ✅
body(r1, a1).    % Assumption in body ✅

head(r2, c_a2).  % Contrary atom as head ✅
body(r2, a1).    % Assumption in body ✅
```

**Example - Non-Compliant** ❌:
```prolog
assumption(a1).

% VIOLATION: Assumption as head
head(r1, a1).    % ❌ Assumption a1 is derived!
body(r1, a2).
```

**Enforcement**:
```prolog
% constraint/flat.lp
:- assumption(X), head(_,X).
```

**Verification**:
```bash
# Verify flat constraint compliance
python3 /tmp/check_flat_constraint_correct.py
```

**Reference**: `docs/FLAT_VS_NONFLAT.md`, `benchmark/FLAT_CONSTRAINT_VERIFICATION.md`

---

## 2. Weight Assignment

### 2.1 Partial Weight Function

**Guideline**: Weights should be a **partial function** - not all atoms need explicit weights.

**Behavior**:
- Atoms without explicit weights use the semiring's **identity element**
- Gödel/Tropical: identity = #sup (infinity)
- Arctic: identity = 0
- Łukasiewicz: identity = K (normalization constant)

**Example**:
```prolog
assumption(a1; a2; a3; a4; a5).

% Partial weight assignment
weight(a1, 50).   % Explicit weight
weight(a3, 75).   % Explicit weight
% a2, a4, a5 have no explicit weight → use identity

% In Gödel semiring:
% supported_with_weight(a1, 50)
% supported_with_weight(a2, #sup)  ← identity
% supported_with_weight(a3, 75)
% supported_with_weight(a4, #sup)  ← identity
% supported_with_weight(a5, #sup)  ← identity
```

### 2.2 Positive Integer Weights

**Requirement**: All explicit weights must be **positive integers**.

```prolog
weight(a1, 50).   ✅ Positive integer
weight(a2, 0).    ❌ Zero not allowed (use absence for identity)
weight(a3, -10).  ❌ Negative not allowed
weight(a4, 3.5).  ❌ Float not allowed
```

---

## 3. Contrary Relation

### 3.1 Total Function (REQUIRED)

**Requirement**: `contrary/2` must be a **total function** from assumptions to atoms.

**Every assumption MUST have exactly one contrary**:
```prolog
assumption(a1; a2; a3).

% Total function: all assumptions mapped
contrary(a1, c_a1).  ✅
contrary(a2, c_a2).  ✅
contrary(a3, c_a3).  ✅
```

**Violation - Missing Contrary** ❌:
```prolog
assumption(a1; a2; a3).

contrary(a1, c_a1).
contrary(a2, c_a2).
% Missing: contrary(a3, ???)  ❌
```

**Rationale**:
- Attack relation requires contrary atoms for all assumptions
- Incomplete contrary relation breaks attack semantics
- WABA core logic assumes totality

---

## 4. Budget Constraints

### 4.1 Budget Specification (REQUIRED)

**Requirement**: Every framework must specify a budget via `budget/1` predicate OR command-line parameter `-c beta=N`.

**Recommended Approach**: Include `budget/1` in framework file:
```prolog
budget(500).  % Extensions can discard attacks up to cost 500
```

**Alternative**: Command-line override:
```bash
clingo -c beta=500 WABA/core/base.lp ... framework.lp
```

**Budget Guidelines**:
```prolog
budget(0).              % Strictest: no attacks can be discarded
budget(max_weight).     % Can discard ~1 attack
budget(sum_weights/2).  % Can discard ~half attacks
budget(sum_weights).    % Can discard all attacks (most permissive)
```

### 4.2 Budget Semantics by Monoid

Different monoids interpret budget differently:

- **MAX monoid**: Budget limits the **maximum weight** of any single discarded attack
- **SUM monoid**: Budget limits the **sum of all** discarded attack weights
- **MIN monoid**: Budget limits the **minimum weight** of discarded attacks (quality threshold)
- **COUNT monoid**: Budget limits the **number** of discarded attacks (weight-agnostic)

---

## 5. Validation Checklist

Before using a framework, verify:

- [ ] **Flat constraint**: No assumptions in rule heads
  ```bash
  python3 /tmp/check_flat_constraint_correct.py
  ```

- [ ] **Derived atoms**: At least one atom beyond assumptions and contraries
  ```bash
  python3 /tmp/check_derived_atoms.py
  ```

- [ ] **Contrary totality**: All assumptions have contraries
  ```bash
  # Manual check or write validator
  ```

- [ ] **Weight validity**: All weights are positive integers
  ```bash
  # Check with: grep "^weight(" framework.lp
  ```

- [ ] **Budget specified**: Framework has `budget/1` or use `-c beta=N`
  ```bash
  grep "^budget(" framework.lp
  ```

- [ ] **Syntax validity**: No clingo parsing errors
  ```bash
  clingo --syntax-check framework.lp
  ```

---

## 6. Benchmark-Specific Best Practices

### 6.1 Parameter Ranges

**Assumption count (A)**:
- Small: A ∈ {2, 5, 10} - Quick execution, basic testing
- Medium: A ∈ {15, 20, 24} - Realistic complexity
- Large: A ∈ {28, 29, 30} - Performance stress testing
- Avoid: A > 30 for complete/mixed topologies (causes timeouts)

**Derived atom count (R)**:
- Minimum: R ≥ 1 (required for best practice)
- Recommended: R ∈ {2, 5, 10, 20} - Scales with A
- Rule of thumb: R ≈ A/2 for balanced complexity

**Rule depth (D)**:
- Shallow: D ∈ {1, 2} - Direct reasoning
- Medium: D ∈ {3, 4} - Multi-step chains
- Deep: D > 4 - Complex derivations (can cause timeouts)

### 6.2 Topology Selection

**Computational Complexity** (from easiest to hardest):
1. **Isolated** - No attacks (fastest)
2. **Linear** - Chain structure (fast)
3. **Tree** - Hierarchical (fast)
4. **Cycle** - Circular reasoning (medium)
5. **Mixed** - Multiple patterns (slow)
6. **Complete** - All-vs-all attacks (slowest)

**Recommendation**: Use diverse topologies for comprehensive benchmarking.

---

## 7. Common Pitfalls

### 7.1 Missing Budget

❌ **Problem**:
```bash
# No budget in framework, no -c beta=N
clingo WABA/core/base.lp ... framework.lp
# Result: Unconstrained - all attacks can be discarded!
```

✅ **Solution**:
```prolog
% In framework.lp
budget(100).
```

### 7.2 Zero Derived Atoms

❌ **Problem**:
```prolog
% R=0 - no derived atoms
assumption(a1; a2; a3).

% Only attack rules, no intermediate reasoning
head(r1, c_a2).
body(r1, a1).
```

✅ **Solution**:
```prolog
% R≥1 - at least one derived atom
assumption(a1; a2; a3).

head(r_d1, d1).   % Derived atom
body(r_d1, a1; r_d1, a2).

head(r_atk, c_a3).  % Attack using derived atom
body(r_atk, d1).
```

### 7.3 Assumptions in Rule Heads (Non-Flat)

❌ **Problem**:
```prolog
assumption(a1; a2).

head(r1, a2).    % ❌ Assumption as head!
body(r1, a1).
% Violates flat constraint
```

✅ **Solution**:
```prolog
assumption(a1; a2).

head(r1, d1).    % Derived atom as head
body(r1, a1; r1, a2).
```

---

## 8. References

**Core Documentation**:
- `docs/FLAT_VS_NONFLAT.md` - Flat vs non-flat semantics
- `docs/QUICK_REFERENCE.md` - Command reference
- `docs/SEMIRING_MONOID_COMPATIBILITY.md` - Legal combinations

**Validation Tools**:
- `/tmp/check_flat_constraint_correct.py` - Flat constraint checker
- `/tmp/check_derived_atoms.py` - Derived atom checker

**Issue Tracking**:
- `benchmark/COMPLETE_TOPOLOGY_ISSUE.md` - Known R=0 issue in complete topology
- `benchmark/FLAT_CONSTRAINT_VERIFICATION.md` - Flat constraint verification report

**Examples**:
- `examples/medical.lp` - Well-formed framework with derived atoms
- `examples/simple.lp` - Minimal compliant example
- `test/test_nonflat.lp` - Non-flat mode demonstration

---

**Summary**: Follow these best practices to create semantically rich, computationally tractable, and theoretically sound WABA frameworks.
