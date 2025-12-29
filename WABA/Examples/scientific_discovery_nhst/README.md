# NHST-Style Hypothesis Testing Example

**Domain**: Philosophy of Science / Statistical Inference
**Last Updated**: 2025-12-29

---

## Story

A researcher tests null hypothesis H0 (no treatment effect) against alternatives H1 (positive effect) and H2 (negative side effects). Statistical tests yield p-values; significant results (p ≤ α = 0.05) attack H0. Discarding an attack means ignoring strong statistical evidence. Practical policy decisions require both statistical significance AND clinical effect size (mixed-body rule). We minimize total ignored evidence strength.

---

## WABA Configuration

### Weight Interpretation
Evidence strength = floor(100 × (1 - p)). Higher p-value (weaker evidence) → lower weight.
- p = 0.001 → weight = 99 (very strong evidence)
- p = 0.05 → weight = 95 (marginally significant)

### Semiring: Tropical (sum/min)
**Justification**: Evidence strength accumulates across independent tests. Multiple significant results combine additively (meta-analytic evidence accumulation).

### Monoid: Sum
**Justification**: Extension cost = total strength of ignored evidence. Each discarded significant result contributes its evidence strength to the ignored evidence budget.

### Optimization: Minimize
**Justification**: Minimize total ignored evidence (evidential conservatism).

### Budget β
Upper bound on total ignored evidence strength: **β = 100** means "can ignore ≤100 units of evidence."

**Suggested values**:
- **β = 0**: No evidence can be ignored (strictest—accept all significant results)
- **β = 100**: Can ignore ~1 very strong result (99) OR ~2 moderate results (95+97=192 exceeds, but 95 alone fits)

---

## Framework Structure

### Assumptions (Hypotheses)
- **h0**: Null hypothesis (no treatment effect)
- **h1**: Alternative (treatment increases performance)
- **h2**: Alternative (treatment has adverse side effects)

### Derived Atoms
**Tests**:
- `test_performance_increase`: Primary efficacy test
- `test_safety_profile`: Safety assessment test
- `test_replication`: Independent replication study

**P-values** (observational outcomes):
- `pval_001_performance`: p = 0.001 (very strong evidence, weight 99)
- `pval_030_safety`: p = 0.030 (moderate evidence, weight 97)
- `pval_045_replication`: p = 0.045 (marginally significant, weight 95)

**Significance Indicators** (p ≤ α):
- `significant_performance`: Performance test significant
- `significant_safety`: Safety test significant
- `significant_replication`: Replication significant

**Rejection Tokens**:
- `rejects_h0_performance`: Performance test rejects H0 (weight 99)
- `rejects_h0_replication`: Replication rejects H0 (weight 95)

**Aggregate Rejection**:
- `rejected_h0`: H0 rejected by multiple tests (Tropical sum: 99+95=194)

**Clinical Significance**:
- `effect_size_large`: Effect is clinically meaningful (beyond statistical significance)

**Mixed-Body Example**:
- `accept_practical_policy`: Requires h1 (assumption) + effect_size_large (derived atom)

**Mutual Exclusion**:
- `rejected_h1_by_h2`: H1 defeated if H2 accepted with strong safety evidence
- `rejected_h2_by_h1`: H2 defeated if H1 accepted with strong efficacy evidence

### Contraries
- `contrary(h0, rejected_h0)`: Null defeated by cumulative significant results
- `contrary(h1, rejected_h1_by_h2)`: Positive effect defeated by safety concerns
- `contrary(h2, rejected_h2_by_h1)`: Side effects defeated by strong efficacy + practical acceptance

---

## Running the Example

### Enumeration Mode (all extensions)
```bash
clingo -n 0 -c alpha=5 \
  WABA/core/base.lp \
  WABA/semiring/tropical.lp \
  WABA/monoid/sum_minimization.lp \
  WABA/constraint/ub_sum.lp \
  WABA/filter/standard.lp \
  WABA/semantics/stable.lp \
  WABA/examples/scientific_discovery_nhst/nhst.lp
```

### Optimization Mode (minimize ignored evidence)
```bash
clingo -n 0 --opt-mode=opt -c beta=100 -c alpha=5 \
  WABA/core/base.lp \
  WABA/semiring/tropical.lp \
  WABA/monoid/sum_minimization.lp \
  WABA/constraint/ub_sum.lp \
  WABA/filter/standard.lp \
  WABA/semantics/stable.lp \
  WABA/examples/scientific_discovery_nhst/nhst.lp
```

### Strict Mode (β = 0, accept all evidence)
```bash
clingo -n 0 --opt-mode=opt -c beta=0 -c alpha=5 \
  WABA/core/base.lp \
  WABA/semiring/tropical.lp \
  WABA/monoid/sum_minimization.lp \
  WABA/constraint/ub_sum.lp \
  WABA/filter/standard.lp \
  WABA/semantics/stable.lp \
  WABA/examples/scientific_discovery_nhst/nhst.lp
```
**Expected**: May be UNSAT or force acceptance of H0 rejection (cannot ignore any significant results)

---

## Design Compliance
✅ All principles satisfied
✅ Specific contraries (rejected_h0, rejected_h1_by_h2, rejected_h2_by_h1)
✅ Mixed-body rule (accept_practical_policy :- h1, effect_size_large)
✅ Tropical accumulation: evidence strength sums across independent tests
✅ Sum monoid: β = "total ignored evidence strength ≤ β"
✅ Alpha parameter: significance threshold (α = 0.05)
