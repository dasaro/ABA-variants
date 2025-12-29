# Strong Inference / Ulam-Rényi Example

**Domain**: Philosophy of Science / Scientific Discovery
**Last Updated**: 2025-12-29

---

## Story

A scientist evaluates four competing hypotheses (Newtonian, relativistic, quantum, string theory) through decisive experiments. Each experiment yields outcomes rejecting specific hypotheses. Discarding a rejection means treating experimental evidence as erroneous—"Nature lied." We minimize the number of experimental errors while maintaining at least one viable hypothesis (epistemic parsimony meets Ulam-Rényi game).

---

## WABA Configuration

### Weight Interpretation
Evidential strength of rejection (0-100). Higher = stronger experimental contradiction (harder to dismiss).

### Semiring: Tropical (sum/min)
**Justification**: Rejection evidence accumulates. When multiple experiments reject a hypothesis, evidential strength combines additively (cumulative disconfirmation).

### Monoid: Count
**Justification**: Extension cost = number of experimental outcomes dismissed as errors. Weight-agnostic counting: "How many times did Nature lie?"

### Optimization: Minimize
**Justification**: Minimize experimental error assumptions (epistemic parsimony).

### Budget β
Upper bound on experimental errors: **β = 2** means "tolerate at most 2 erroneous outcomes."

**Suggested values**:
- **β = 0**: No errors allowed (strictest—likely UNSAT since h1 is rejected by 2 experiments)
- **β = 2**: Allow 2 errors (should give SAT, can dismiss both rejections of h1)

---

## Framework Structure

### Assumptions (Hypotheses)
- **h1**: Newtonian mechanics (simplest)
- **h2**: Relativistic mechanics
- **h3**: Quantum mechanics
- **h4**: String theory (most speculative)

### Derived Atoms
**Experiments**:
- `experiment_e1`: Mercury perihelion precession test
- `experiment_e2`: Photoelectric effect test
- `experiment_e3`: Gravitational wave detection

**Outcomes**:
- `outcome_mercury_precession`: Mercury orbit anomaly observed
- `outcome_photoelectric_effect`: Light-electron energy quantization observed
- `outcome_gravitational_waves`: Spacetime ripples detected

**Rejection Tokens**:
- `rejects_h1_via_e1`: Mercury precession rejects Newtonian (weight 85)
- `rejects_h1_via_e2`: Photoelectric effect rejects Newtonian (weight 80)
- `rejects_h3_via_e3`: Gravitational waves challenge pure quantum (weight 75)

**Aggregate Rejections**:
- `rejected_h1`: Newtonian rejected by e1 + e2 (Tropical sum: 85+80=165)
- `rejected_h3`: Quantum rejected by e3 (weight 75)

**Mixed-Body Example**:
- `confirms_relativistic`: Derived from h2 (assumption) + outcome_mercury_precession (derived)

### Contraries
- `contrary(h1, rejected_h1)`: Newtonian defeated by cumulative experimental rejection
- `contrary(h3, rejected_h3)`: Quantum defeated by gravitational wave evidence
- `contrary(h2, rejected_h2_placeholder)`: Vacuous (relativistic not rejected)
- `contrary(h4, rejected_h4_placeholder)`: Vacuous (string theory not rejected)

---

## Running the Example

### Enumeration Mode (all extensions)
```bash
clingo -n 0 \
  WABA/core/base.lp \
  WABA/semiring/tropical.lp \
  WABA/monoid/count_minimization.lp \
  WABA/filter/standard.lp \
  WABA/semantics/stable.lp \
  WABA/examples/scientific_discovery_strong_inference/strong_inference.lp
```

### Optimization Mode (minimum error count)
```bash
clingo -n 0 --opt-mode=opt -c beta=2 \
  WABA/core/base.lp \
  WABA/semiring/tropical.lp \
  WABA/monoid/count_minimization.lp \
  WABA/filter/standard.lp \
  WABA/semantics/stable.lp \
  WABA/examples/scientific_discovery_strong_inference/strong_inference.lp
```

### Test Strictness (β = 0, no errors allowed)
```bash
clingo -n 0 --opt-mode=opt -c beta=0 \
  WABA/core/base.lp \
  WABA/semiring/tropical.lp \
  WABA/monoid/count_minimization.lp \
  WABA/filter/standard.lp \
  WABA/semantics/stable.lp \
  WABA/examples/scientific_discovery_strong_inference/strong_inference.lp
```
**Expected**: UNSAT (h1 rejected by 2 experiments, h3 rejected by 1; cannot maintain all hypotheses without dismissing rejections)

---

## Design Compliance
✅ All principles satisfied
✅ Specific contraries (rejected_h1, rejected_h3)
✅ Mixed-body rule (confirms_relativistic :- h2, outcome_mercury_precession)
✅ Tropical accumulation: rejection evidence sums across experiments
✅ Count monoid: β = "Nature may lie at most β times"
