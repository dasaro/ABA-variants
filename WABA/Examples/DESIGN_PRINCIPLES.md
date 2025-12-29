# Design Principles for WABA Examples

**Last Updated**: 2025-12-29

This document establishes normative constraints for WABA framework examples. All examples in this directory **must** adhere to these principles to ensure philosophical coherence, pedagogical clarity, and computational interpretability.

---

## 1. Structural Principles

### 1.1 Defeasibility of Assumptions

**Principle**: Assumptions represent *defeasible epistemic commitments* or *prima facie warrants* that can be retracted in light of contrary evidence.

- **Must not**: Treat assumptions as immutable facts or axiomatic truths
- **Must**: Interpret assumptions as tentative beliefs subject to defeat
- **Rationale**: Captures the essence of non-monotonic reasoning under uncertainty

### 1.2 Mediated Defeat Structure

**Principle**: Assumptions are defeated only through *derived contraries*, never directly by other assumptions.

- **Must**: Define contraries as `contrary(assumption, derived_element)` where `derived_element` is derivable via rules
- **Must not**: Allow direct assumption-to-assumption attacks `contrary(assumption1, assumption2)`
- **Rationale**: Models realistic defeat where commitments conflict through their consequences, not by fiat

### 1.3 Derived Atoms as Logical Consequences

**Principle**: Derived atoms represent *meaningful entailments* of assumptions—practical conclusions, normative judgments, evidential implications, or causal consequences.

- **Must**: Ensure derived atoms have clear interpretations (actions, legal consequences, theoretical predictions, etc.)
- **Must not**: Use arbitrary or meaningless labels for derived atoms
- **Rationale**: Grounds abstract argumentation in concrete reasoning scenarios

### 1.4 Flat Architecture

**Principle**: WABA examples follow a *flat structure* where assumptions appear only in rule bodies, never in rule heads.

- **Must**: Use `body(rule, assumption)` only; assumptions never appear in `head(rule, assumption)`
- **May**: Include both assumptions and derived atoms in the same rule body
- **Rationale**: Maintains clear separation between defeasible commitments and their consequences

**Example of mixed rule bodies** (encouraged):
```prolog
% Rule mixing assumptions and derived atoms
head(r1, action_x).
body(r1, assumption_duty).       % Defeasible commitment
body(r1, derived_circumstance).  % Previously derived fact
```

This models realistic inference where conclusions depend on both commitments and established facts.

---

## 2. Algebraic Design Principles

### 2.1 Semiring Choice: Weight Propagation Semantics

**Principle**: Semiring selection encodes *how weights flow through inference chains*. Each example **must** explicitly state the intended weight interpretation and justify the semiring choice.

**Semiring Catalog**:

| Semiring | Conjunction | Disjunction | Philosophical Interpretation |
|----------|-------------|-------------|------------------------------|
| **Gödel** | min | max | "Weakest link": Strength = weakest premise in chain |
| **Tropical** | sum | min | "Accumulative": Strength compounds through derivation |
| **Łukasiewicz** | bounded sum | bounded sum | "Saturating evidence": Accumulation with upper bound |
| **Arctic** | sum | max | "Dual accumulation": Reward-based (dual of Tropical) |
| **Bottleneck** | max | min | "Worst-case": Bottleneck determines strength |

**Must**:
- State what weights represent (e.g., "epistemic certainty", "harm severity", "legal strength")
- Justify why the chosen semiring fits the weight interpretation
- Ensure consistency between weight semantics and semiring algebra

**Example justification**:
> *Weights represent diagnostic certainty (0-100 scale). We use Gödel semiring because a diagnosis is only as certain as the weakest evidence in the chain (weakest link principle).*

### 2.2 Monoid Choice: Cost Aggregation Semantics

**Principle**: Monoid selection encodes *how we measure the burden of attack resolution*. Each example **must** justify the aggregation strategy.

**Monoid Catalog**:

| Monoid | Aggregation | Budget Interpretation |
|--------|-------------|----------------------|
| **Max** | maximum | Threshold on worst single attack |
| **Sum** | sum | Threshold on cumulative cost |
| **Min** | minimum | Threshold on minimum quality |
| **Count** | count | Threshold on number of attacks |

**Must**:
- State what the budget β represents (e.g., "maximum tolerable harm", "total available resources")
- Justify why the monoid matches the budget interpretation
- Ensure normative coherence (e.g., max for "worst-case harm", sum for "total cost")

**Example justification**:
> *Budget β=50 represents maximum tolerable harm in a single dimension. We use Max monoid because we must ensure no single attack exceeds this threshold (worst-case constraint).*

### 2.3 Optimization Direction: Minimize vs Maximize

**Principle**: Optimization direction depends on whether weights represent *costs* (minimize) or *rewards* (maximize).

- **Minimize**: Weights = costs, harms, uncertainties, weaknesses → find least costly extension
- **Maximize**: Weights = strengths, utilities, rewards, probabilities → find most valuable extension

**Must**:
- Explicitly state whether weights are cost-oriented or reward-oriented
- Use `*_minimization.lp` monoids for cost semantics
- Use `*_maximization.lp` monoids for reward semantics

**Example**:
> *Weights represent harm severity (cost). We minimize to find the extension with least total harm (sum_minimization).*

---

## 3. Example Quality Principles

### 3.1 Interpretability

**Principle**: Examples must be *pedagogically balanced*—complex enough to demonstrate the framework's expressiveness, simple enough to remain comprehensible.

- **Must**: Keep examples small (typically 3-8 assumptions, 4-12 rules)
- **Must**: Provide clear narrative context and element interpretations
- **May**: Include interdependencies and cycles if they serve the intended reading
- **Must not**: Create opacity through excessive size or arbitrary structure

### 3.2 Philosophical Grounding

**Principle**: Examples should draw inspiration from established argumentation literature and realistic reasoning scenarios.

- **Should**: Reference philosophical debates, ethical dilemmas, legal cases, scientific controversies, or practical deliberation scenarios
- **Must**: Have meaningful interpretations that withstand critical examination
- **Should**: Cite relevant literature when adapting known examples

### 3.3 Contraries as Total Function

**Principle**: The contrary relation is defined on all assumptions (total function), but not all contraries need be derivable.

- **Must**: Define `contrary(assumption, contrary_atom)` for every assumption
- **May**: Have some assumptions remain unattacked if their contraries are underivable
- **Rationale**: Totality ensures every commitment has a potential defeater; derivability determines actual defeat

---

## 4. Implementation Requirements

### 4.1 Documentation

Each example **must** include:
1. **Narrative description** (1-3 paragraphs)
2. **Weight interpretation** (what do weights represent?)
3. **Semiring choice + justification**
4. **Monoid choice + justification**
5. **Optimization direction + justification**
6. **Intended usage** (enum mode, opt mode, or both)
7. **Element interpretations** (what each assumption/derived atom means)

### 4.2 Code Structure

Examples **must**:
- Use clear, meaningful predicate names (avoid `a1`, `b2`; use `assume_duty_of_care`, `derived_treatment_x`)
- Include inline comments explaining rules
- Group related predicates (assumptions together, rules together, etc.)
- Specify budget and provide rationale

### 4.3 Testing

Examples **should**:
- Be tested with the intended semiring-monoid-direction combination
- Have documented expected outputs (at minimum: number of extensions, representative extension)
- Include usage examples in comments

---

## 5. Example Suite Coverage Requirements

Across the full example suite (15-20 examples), we **must** ensure:

1. **Diversity of domains**: Law, medicine, ethics, epistemology, AI policy, planning, everyday reasoning, science
2. **Semiring coverage**: All semirings represented (Gödel, Tropical, Łukasiewicz, Arctic, Bottleneck)
3. **Monoid coverage**: All main monoids represented (Max, Sum, Min, Count)
4. **Optimization balance**: Both minimization and maximization well-represented
5. **Mixed rule bodies**: At least 5 examples with rules containing both assumptions and derived atoms
6. **Mode diversity**: Examples suitable for both enum and opt modes

---

## 6. Anti-Patterns to Avoid

**Must not**:
- Create examples where assumptions attack each other directly
- Use weights without clear interpretation
- Choose semirings/monoids arbitrarily without justification
- Make examples trivially small (single assumption) or excessively large (>15 assumptions)
- Use opaque naming (`a1`, `r1` without semantic labels)
- Ignore the philosophical significance of algebraic choices

---

## Summary: Checklist for New Examples

Before adding an example, verify:

- [ ] Assumptions are defeasible commitments (not facts)
- [ ] Attacks are mediated through derived contraries
- [ ] Derived atoms have clear interpretations
- [ ] Flat structure (assumptions only in bodies)
- [ ] Weight interpretation stated explicitly
- [ ] Semiring choice justified
- [ ] Monoid choice justified
- [ ] Optimization direction justified
- [ ] Contrary relation is total on assumptions
- [ ] Narrative description provided
- [ ] Code is well-documented with comments
- [ ] Element names are semantically meaningful

---

**Enforcement**: Examples violating these principles will be rejected or moved to deprecated examples. These principles ensure WABA examples serve as both technical demonstrations and philosophical illustrations of resource-bounded argumentation.
