# AI Safety Policy Example

**Domain**: AI Governance / Regulatory Decision-Making
**Last Updated**: 2025-12-29

---

## Story

A regulatory body must decide whether to approve an AI system for deployment. Four defeasible **safety requirements** must be satisfied:

- **Adversarial robustness** (assume_adversarial_robustness): System resists adversarial inputs
- **Interpretability** (assume_interpretability): Decisions are explainable
- **Fairness** (assume_fairness): No demographic bias
- **Adequate monitoring** (assume_monitoring): Ongoing oversight is sufficient

Evidence from testing and audits suggests some requirements may be **violated**. The deployment decision balances **minimum safety thresholds** (maximin across dimensions) against deployment benefits. Violations defeat safety requirements, forcing acceptance of residual risk in some dimensions.

---

## Philosophical Framing

This example models **maximin safety policy** under epistemic uncertainty. The framework captures:
- **Safety requirements as defeasible**: Evidence can defeat safety claims
- **Worst-case analysis**: Safety determined by weakest dimension (Bottleneck semiring)
- **Quality thresholds**: Minimum acceptable safety across all dimensions (β as lower bound)
- **Risk acceptance**: Overriding violations = accepting residual risk

---

## WABA Configuration

### Weight Interpretation (**REWARD semantics**)

Weights represent **safety assurance level (0-100)**, where **higher values = MORE safety**.

**This is a REWARD interpretation** (not cost): Weights indicate how much safety assurance we have, and we want to MAXIMIZE the minimum safety.

**Weight assignments**:
- `violates_robustness`: 75 (losing robustness = losing 75 assurance units)
- `violates_interpretability`: 70 (losing explainability = losing 70 assurance units)
- `violates_fairness`: 80 (losing fairness = losing 80 assurance units)
- `violates_monitoring`: 65 (losing oversight = losing 65 assurance units)

### Semiring: Bottleneck (max/min)

**Justification**: System safety is determined by the **weakest link** in the safety chain (worst-case dimension). Bottleneck propagation identifies the limiting safety factor.

- **Conjunction** (max): Worst-case path = maximum (higher = less safe in bottleneck semantics)
- **Disjunction** (min): Best alternative = minimum
- **Identity**: 0 (perfect safety - no bottleneck)

**Philosophical motivation**: Safety analysis focuses on vulnerabilities (weakest dimension), not average safety.

### Monoid: Min

**Justification**: Extension cost = **MINIMUM safety assurance** among discarded violations. When we accept violations, the "cost" is the LOWEST safety level we're willing to tolerate (**maximin safety**: maximize the minimum).

### Optimization Direction: Maximize

**Justification**: Weights represent rewards (safety assurance). We **MAXIMIZE minimum safety** to find the deployment policy with the highest worst-case safety guarantee (maximin principle).

### Budget β: Minimum Safety Threshold

**Meaning**: **Lower bound** on minimum safety assurance.
**Default**: β = 60
**Interpretation**: "All safety dimensions must have ≥ 60 assurance"

**Constraint encoding**:
```prolog
:- extension_cost(C), C < beta.
```

**Note**: This is a **LOWER BOUND** (unlike most examples which use upper bounds). We reject extensions where minimum safety falls below β.

---

## Discarded Attack Interpretation

**What does it mean to discard an attack?**

When we discard the attack `violates_fairness` → `assume_fairness`, we are:
- **Accepting residual risk**: Acknowledging fairness violation exists
- **Maintaining the requirement**: Keeping fairness assumption despite evidence
- **Losing assurance**: Cost = weight(violates_fairness) = 80 (assurance lost)

In general: Overriding a violation = accepting that dimension has lower safety (losing assurance weight).

---

## Running the Example

### Basic Usage (Stable Semantics, β = 60)

```bash
clingo -n 0 --opt-mode=opt -c beta=60 \
  WABA/core/base.lp \
  WABA/semiring/bottleneck_cost.lp \
  WABA/monoid/min_maximization.lp \
  WABA/filter/standard.lp \
  WABA/semantics/stable.lp \
  WABA/examples/ai_safety_policy/ai_safety_policy.lp
```

### Vary Budget (Explore Safety Thresholds)

```bash
# High safety standard (β = 75): Very strict minimum
clingo -n 0 --opt-mode=opt -c beta=75 [... same modules ...]

# Moderate (β = 60): Default balance
clingo -n 0 --opt-mode=opt -c beta=60 [... same modules ...]

# Permissive (β = 50): Lower threshold
clingo -n 0 --opt-mode=opt -c beta=50 [... same modules ...]
```

---

## Expected Behavior

### With β = 60:
- **SAT** if at least one dimension can maintain ≥ 60 assurance
- Optimal extension maximizes minimum safety across all violated dimensions
- May require accepting violations in multiple dimensions to meet threshold

### With β = 75:
- **More constrained**: High minimum threshold
- May force rejection if no configuration meets 75 across all dimensions

### With β = 50:
- **More permissive**: Lower quality threshold
- More deployment options available

---

## Design Compliance

✅ All WABA design principles satisfied
✅ **Specific contraries**: Dimension-specific violations (not generic "safety_violation_detected")
✅ **Operational β**: Lower bound constraint (unusual: quality threshold)
✅ **Mixed rule bodies**: Violations from requirements + test results

---

## Pedagogical Notes

- **Maximin safety**: Rawlsian principle applied to AI governance
- **Bottleneck analysis**: Worst-case dimension determines overall safety
- **Lower bound constraint**: Quality threshold (β enforces minimum acceptable safety)
- **Reward semantics**: Higher weights = better (unusual for WABA, shows flexibility)

---

## References

- Amodei, D., et al. (2016). "Concrete Problems in AI Safety." arXiv:1606.06565.
- Russell, S. (2019). *Human Compatible: Artificial Intelligence and the Problem of Control*. Viking.
- Rawls, J. (1971). *A Theory of Justice*. (Maximin principle)
