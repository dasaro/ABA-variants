# Legal Precedent Reasoning Example

**Domain**: Common Law / Contract Law
**Last Updated**: 2025-12-29

---

## Story

A court must decide whether to enforce a **non-compete clause** in an employment contract. The decision turns on three defeasible legal interpretations of the contract terms:

- **Broad geographic scope** (assume_broad_scope): The clause restricts employment across the entire industry nationally
- **Long duration** (assume_long_duration): The 3-year restriction period is reasonable
- **Legitimate business interest** (assume_legitimate_interest): The employer has protectable trade secrets justifying the restriction

Each interpretation, when combined with **established binding precedents**, yields legal conclusions. Precedents can defeat interpretations by establishing contrary legal principles (e.g., non-competes must be geographically/temporally limited, or they become void for overreach).

**The Legal Challenge**: The court must navigate binding precedents that constrain these interpretations. To adopt a broader interpretation, the court must "distinguish" (override) limiting precedents, incurring a legal burden proportional to the precedent's authority.

---

## Philosophical Framing

This example models **precedent-based legal reasoning** in common law systems. The framework captures:
- **Defeasible interpretations**: Contract terms admit multiple plausible readings (assumptions), not just one correct interpretation
- **Stare decisis**: Precedents defeat interpretations through mediated defeat (not direct conflict between interpretations)
- **Legal authority accumulation**: Stronger arguments cite multiple precedents (Tropical semiring: authority sums)
- **Distinguishing precedents**: Overriding precedent attacks = arguing this case differs from cited precedent (at cost = precedent authority)

---

## WABA Configuration

### Weight Interpretation

Weights represent **precedent authority strength (0-100)**, where higher values indicate more binding authority:
- **Supreme Court precedent**: ~90
- **Circuit Court precedent**: ~70-80
- **District Court precedent**: ~40-60

**Weight assignments**:
- `precedent_geographic_limit`: 80 (strong authority: scope must be limited)
- `precedent_temporal_limit`: 70 (strong authority: duration must be limited)
- `conclusion_void_overbroad`: 90 (very strong: void if overreaching)

### Semiring: Tropical (sum/min)

**Justification**: Legal authority **accumulates through citation chains**. When multiple precedents support a legal conclusion, their authority combines additively (cumulative legal support).

- **Conjunction** (sum): Authority = sum of supporting precedents' weights
- **Disjunction** (min): Authority = minimum across alternative legal paths
- **Identity**: #sup (maximum authority)

**Example**: If a conclusion is supported by two precedents (weights 80 and 70), the total authority = 80 + 70 = 150.

### Monoid: Sum

**Justification**: Extension cost = **total deviation from binding precedent**. Each time we override (distinguish) a precedent, we incur a deviation cost equal to its authority weight. The sum represents the total legal burden of the argument's departures from established law.

### Optimization Direction: Minimize

**Justification**: Weights represent costs (precedent deviation). Minimizing total deviation is equivalent to **maximizing legal strength** (since lower deviation = more legally defensible position).

**Note**: Though the conceptual goal is "maximize legal strength," we achieve this by minimizing deviation costs using `sum_minimization.lp`.

### Budget β: Maximum Precedent Deviation

**Meaning**: Upper bound on total precedent deviation allowed.
**Default**: β = 150
**Interpretation**: "Total deviation from binding precedent ≤ 150 authority units"

**Constraint encoding**:
```prolog
:- extension_cost(C), C > beta.
```

This is an **upper bound** constraint: the sum of discarded attack weights (= total precedent deviations) must not exceed β.

---

## Discarded Attack Interpretation

**What does it mean to discard an attack?**

When we discard the attack `precedent_geographic_limit` → `assume_broad_scope`, we are:
- **Distinguishing the precedent**: Arguing this case differs from the limiting precedent
- **Accepting legal burden**: Incurring cost = weight(precedent_geographic_limit) = 80
- **Maintaining the interpretation**: Keeping `assume_broad_scope` in the extension

In general: Overriding a precedent = distinguishing the case (at cost = precedent authority).

---

## Structure Details

### Assumptions (Defeasible Legal Interpretations)

```prolog
assumption(assume_broad_scope).       % Industry-wide scope
assumption(assume_long_duration).     % 3-year term
assumption(assume_legitimate_interest). % Protectable interest exists
```

### Derived Atoms

**Binding Precedents**:
- `precedent_geographic_limit` - Precedent requiring geographic limits
- `precedent_temporal_limit` - Precedent requiring temporal limits

**Legal Conclusions**:
- `conclusion_enforceable` - Clause is enforceable
- `conclusion_void_overbroad` - Clause is void for overreach

**Legal Doctrine** (background law):
- `established_doctrine_limits` - Legal doctrine requires limits (always holds)

**Limiting Conditions**:
- `geographic_limited` - Scope is geographically limited
- `temporal_limited` - Duration is temporally limited

### Contraries (Precedent-Based Defeats)

```prolog
contrary(assume_broad_scope, precedent_geographic_limit).
contrary(assume_long_duration, precedent_temporal_limit).
contrary(assume_legitimate_interest, conclusion_void_overbroad).
```

### Rule Structure (Mixed Bodies)

**Example**: Rule r1 derives precedent from both legal interpretation (assumption) and established doctrine (derived):

```prolog
head(r1, precedent_geographic_limit).
body(r1, assume_broad_scope).          % Assumption: interpretation of scope
body(r1, established_doctrine_limits).  % Derived: background legal doctrine
```

This demonstrates **mixed rule bodies**: precedents derived from both defeasible interpretations and established legal principles.

**Tropical accumulation example**: Rule r4 shows how legal authority accumulates:

```prolog
head(r4, conclusion_enforceable).
body(r4, assume_legitimate_interest).  % Authority weight: 50
body(r4, geographic_limited).          % Derived from precedent (80)
body(r4, temporal_limited).            % Derived from precedent (70)
```

If all body elements are supported, the **total authority for conclusion_enforceable** = 50 + 80 + 70 = 200 (Tropical sum).

---

## Running the Example

### Basic Usage (Stable Semantics, β = 150)

```bash
clingo -n 0 --opt-mode=opt -c beta=150 \
  WABA/core/base.lp \
  WABA/semiring/tropical.lp \
  WABA/monoid/sum_minimization.lp \
  WABA/filter/standard.lp \
  WABA/semantics/stable.lp \
  WABA/examples/legal_precedent/legal_precedent.lp
```

### Enumerate All Extensions

```bash
clingo -n 0 -c beta=150 \
  WABA/core/base.lp \
  WABA/semiring/tropical.lp \
  WABA/monoid/sum_minimization.lp \
  WABA/filter/standard.lp \
  WABA/semantics/stable.lp \
  WABA/examples/legal_precedent/legal_precedent.lp
```

### Vary Budget (Explore Legal Arguments)

```bash
# Strict precedent adherence (β = 80): Limited deviation allowed
clingo -n 0 --opt-mode=opt -c beta=80 [... same modules ...]

# Moderate deviation (β = 150): Default, balanced approach
clingo -n 0 --opt-mode=opt -c beta=150 [... same modules ...]

# High deviation tolerance (β = 250): More aggressive distinguishing allowed
clingo -n 0 --opt-mode=opt -c beta=250 [... same modules ...]
```

---

## Expected Behavior

### With β = 80 (Strict):
- **Limited solutions**: Can only distinguish low-authority precedents
- Must adhere closely to binding precedent
- Likely forces narrow interpretations (geographic_limited, temporal_limited)

### With β = 150 (Moderate):
- **SAT** with multiple legal arguments
- Can distinguish 1-2 moderate-authority precedents
- Balance between broad interpretations and precedent adherence

### With β = 250 (Permissive):
- **Many solutions**: Can distinguish multiple precedents
- Broader interpretations feasible
- Higher legal burden but more flexible arguments

---

## Design Compliance

This example adheres to all WABA design principles:

✅ **Defeasible assumptions**: Legal interpretations are plausible readings, not facts
✅ **No direct assumption attacks**: Interpretations don't conflict directly; only through precedents
✅ **Meaningful derived atoms**: Precedents and legal conclusions are logical/legal consequences
✅ **Flat structure**: Assumptions appear only in rule bodies
✅ **Explicit weight interpretation**: Precedent authority clearly defined
✅ **Justified semiring**: Tropical captures cumulative legal authority
✅ **Justified monoid**: Sum captures total precedent deviation burden
✅ **Justified direction**: Minimize deviation = maximize legal strength
✅ **Operational β**: Constraint enforces upper bound on total deviation
✅ **Specific contraries**: Precedent-specific limiting principles, not generic "inconsistency"
✅ **Mixed rule bodies**: Precedents derived from interpretations + established doctrine

---

## Pedagogical Notes

This example illustrates:
- **Stare decisis** (precedent-binding principle): Courts follow prior decisions
- **Case distinguishing**: Overcoming precedent by showing factual differences
- **Tropical semiring**: Authority accumulation through citation chains (sum of authorities)
- **Sum monoid**: Total legal burden of departing from precedent
- **Legal reasoning as argumentation**: Interpretations justified through precedent navigation

---

## References

- Dworkin, R. (1986). *Law's Empire*. Harvard University Press. (Chain novel analogy, legal integrity)
- Levi, E. H. (1949). *An Introduction to Legal Reasoning*. University of Chicago Press. (Reasoning by analogy)
- Schauer, F. (1987). "Precedent." *Stanford Law Review*, 39(3), 571-605.
- Prakken, H., & Sartor, G. (1998). "Modelling reasoning with precedents in a formal dialogue game." *Artificial Intelligence and Law*, 6(2-4), 231-287.
