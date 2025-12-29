# WABA Examples

This directory contains illustrative examples of Weighted Assumption-Based Argumentation frameworks demonstrating diverse reasoning scenarios and algebraic configurations.

**Last Updated**: 2025-12-29

---

## Design Principles

All examples in this directory adhere to the normative constraints specified in [`DESIGN_PRINCIPLES.md`](DESIGN_PRINCIPLES.md). Key requirements:

- **Defeasible assumptions**: Assumptions represent tentative commitments, not facts
- **Mediated defeat**: Assumptions attacked only via derived contraries
- **Meaningful derivations**: Derived atoms represent logical consequences
- **Flat structure**: Assumptions appear only in rule bodies
- **Explicit justification**: Weight interpretation, semiring, monoid, and optimization direction must be justified
- **Interpretability**: Examples balance complexity with comprehension

---

## Example Index

### Medical & Healthcare

| Example | Domain | Semiring | Monoid | Opt | Weight Interpretation | Description |
|---------|--------|----------|--------|-----|----------------------|-------------|
| `medical_triage.lp` | Medical Ethics | Gödel | Max | Min | Harm severity | Emergency triage with worst-case harm minimization |
| `clinical_diagnosis.lp` | Clinical Reasoning | Tropical | Sum | Min | Diagnostic uncertainty | Evidence-based diagnosis with cumulative uncertainty |

### Legal & Governance

| Example | Domain | Semiring | Monoid | Opt | Weight Interpretation | Description |
|---------|--------|----------|--------|-----|----------------------|-------------|
| `legal_precedent.lp` | Common Law | Tropical | Sum | Max | Legal authority | Precedent-based reasoning with cumulative legal strength |
| `regulatory_compliance.lp` | Policy | Bottleneck | Max | Min | Violation severity | Regulatory compliance with worst-case constraints |

### Ethics & Philosophy

| Example | Domain | Semiring | Monoid | Opt | Weight Interpretation | Description |
|---------|--------|----------|--------|-----|----------------------|-------------|
| `moral_dilemma.lp` | Normative Ethics | Gödel | Max | Min | Moral wrongness | Duty conflicts with worst-single-violation constraint |
| `epistemic_justification.lp` | Epistemology | Łukasiewicz | Sum | Min | Epistemic uncertainty | Belief revision with bounded evidence accumulation |

### AI & Technology

| Example | Domain | Semiring | Monoid | Opt | Weight Interpretation | Description |
|---------|--------|----------|--------|-----|----------------------|-------------|
| `ai_safety_policy.lp` | AI Governance | Bottleneck | Min | Max | Safety assurance | AI deployment with minimum safety threshold maximization |
| `autonomous_vehicle.lp` | AI Safety | Gödel | Max | Min | Risk severity | Autonomous decision-making with worst-case risk minimization |

### Planning & Decision-Making

| Example | Domain | Semiring | Monoid | Opt | Weight Interpretation | Description |
|---------|--------|----------|--------|-----|----------------------|-------------|
| `resource_allocation.lp` | Operations Research | Tropical | Sum | Min | Resource cost | Stakeholder-driven allocation with budget constraints |
| `strategic_planning.lp` | Business Strategy | Arctic | Sum | Max | Strategic value | Goal-driven planning with cumulative reward maximization |

### Everyday Reasoning

| Example | Domain | Semiring | Monoid | Opt | Weight Interpretation | Description |
|---------|--------|----------|--------|-----|----------------------|-------------|
| `practical_deliberation.lp` | Practical Reasoning | Gödel | Count | Min | Revision cost | Action selection minimizing belief revision count |
| `commonsense_reasoning.lp` | Cognitive Science | Tropical | Sum | Min | Cognitive effort | Default reasoning with cumulative effort minimization |

### Science & Inquiry

| Example | Domain | Semiring | Monoid | Opt | Weight Interpretation | Description |
|---------|--------|----------|--------|-----|----------------------|-------------|
| `scientific_theory.lp` | Philosophy of Science | Tropical | Sum | Max | Explanatory power | Theory choice maximizing cumulative explanatory strength |
| `experimental_design.lp` | Methodology | Łukasiewicz | Sum | Min | Experimental cost | Hypothesis testing with bounded cost accumulation |

---

## Coverage Statistics

### Semiring Distribution
- **Gödel**: 4 examples (weakest-link semantics)
- **Tropical**: 5 examples (accumulative semantics)
- **Łukasiewicz**: 2 examples (bounded accumulation)
- **Arctic**: 1 example (dual/reward semantics)
- **Bottleneck**: 2 examples (worst-case semantics)

### Monoid Distribution
- **Max**: 6 examples (worst-case aggregation)
- **Sum**: 7 examples (cumulative aggregation)
- **Min**: 1 example (minimum threshold)
- **Count**: 1 example (cardinality-based)

### Optimization Direction
- **Minimize**: 10 examples (cost/harm/uncertainty minimization)
- **Maximize**: 4 examples (strength/value/reward maximization)

### Structural Features
- **Mixed rule bodies** (assumptions + derived atoms): 9 examples
- **Pure assumption bodies**: 5 examples

---

## Usage Examples

### Running an Example with Stable Semantics

```bash
# Medical triage with Gödel + Max minimization
clingo -n 0 --opt-mode=opt \
  WABA/core/base.lp \
  WABA/semiring/godel.lp \
  WABA/monoid/max_minimization.lp \
  WABA/filter/standard.lp \
  WABA/semantics/stable.lp \
  WABA/examples/medical_triage.lp

# Scientific theory choice with Tropical + Sum maximization
clingo -n 0 --opt-mode=opt \
  WABA/core/base.lp \
  WABA/semiring/tropical.lp \
  WABA/monoid/sum_maximization.lp \
  WABA/filter/standard.lp \
  WABA/semantics/stable.lp \
  WABA/examples/scientific_theory.lp
```

### Enumerating All Extensions

```bash
# Enumerate all extensions for moral dilemma
clingo -n 0 \
  WABA/core/base.lp \
  WABA/semiring/godel.lp \
  WABA/monoid/max_minimization.lp \
  WABA/filter/standard.lp \
  WABA/semantics/stable.lp \
  WABA/examples/moral_dilemma.lp
```

---

## Creating New Examples

To create a new example:

1. **Read** [`DESIGN_PRINCIPLES.md`](DESIGN_PRINCIPLES.md) carefully
2. **Design** your example following the structural and algebraic principles
3. **Document**:
   - Narrative description (1-3 paragraphs)
   - Weight interpretation and justification
   - Semiring, monoid, optimization direction with rationales
   - Element interpretations (inline comments)
4. **Test** with the intended configuration
5. **Update** this README's index table

See [`DESIGN_PRINCIPLES.md`](DESIGN_PRINCIPLES.md) for detailed requirements and the example quality checklist.

---

## Deprecated Examples

Previous examples (prior to 2025-12-29) have been moved to [`_deprecated_20251229/`](_deprecated_20251229/) for historical reference. These examples do not adhere to the current design principles and should not be used for new work.

---

## Contributing

When proposing new examples:
- Ensure adherence to design principles
- Provide full algebraic justification
- Prefer underrepresented domains or semiring/monoid combinations
- Maintain pedagogical clarity

---

**See Also**:
- [DESIGN_PRINCIPLES.md](DESIGN_PRINCIPLES.md) - Normative constraints for examples
- [WABA/docs/QUICK_REFERENCE.md](../docs/QUICK_REFERENCE.md) - Command-line usage
- [WABA/docs/SEMIRING_MONOID_COMPATIBILITY.md](../docs/SEMIRING_MONOID_COMPATIBILITY.md) - Legal combinations
