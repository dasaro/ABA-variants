# Scientific Theory Choice Example

**Domain**: Philosophy of Science / Theory Selection
**Last Updated**: 2025-12-29

---

## Story

A scientist must choose between competing **theoretical hypotheses** (Newtonian, relativistic, quantum, auxiliary) to explain experimental data. Each theory generates predictions when combined with observations. Theories conflict when incompatible (theoretical inconsistency). We maximize explanatory power while bounding total theoretical complexity (Ockham's razor).

---

## WABA Configuration

### Weight Interpretation
Theoretical complexity cost (0-100). Higher = more complex theory.

### Semiring: Tropical (sum/min)
**Justification**: Explanatory power accumulates across phenomena (cumulative evidential support).

### Monoid: Sum
**Justification**: Extension cost = total theoretical complexity of accepted conflicts.

### Optimization: Minimize (complexity) = Maximize (explanatory power)
**Justification**: Prefer simpler theories (Ockham's razor). Minimizing complexity cost ≡ maximizing explanatory strength.

### Budget β
Upper bound on total complexity (β = 120: "total complexity ≤ 120").

---

## Running the Example

```bash
clingo -n 0 --opt-mode=opt -c beta=120 \
  WABA/core/base.lp \
  WABA/semiring/tropical.lp \
  WABA/monoid/sum_minimization.lp \
  WABA/filter/standard.lp \
  WABA/semantics/stable.lp \
  WABA/examples/scientific_theory/scientific_theory.lp
```

---

## Design Compliance
✅ All principles satisfied
✅ Specific contraries (incompatible_newtonian_quantum, etc.)
✅ Mixed bodies (predictions from theories + observations)
✅ Tropical accumulation: explanatory power sums across phenomena
