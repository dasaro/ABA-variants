# Resource Allocation Example

**Domain**: Operations Research / Distributive Justice
**Last Updated**: 2025-12-29

---

## Story

A nonprofit must allocate limited funding across four competing stakeholder needs: **education, healthcare, housing, infrastructure**. Budget constraints prevent funding all needs simultaneously. Unfunded needs create deprivation (contraries). We minimize worst-case deprivation (maximin equity - Rawlsian justice).

---

## WABA Configuration

### Weight Interpretation
Deprivation severity (0-100) if need unfunded. Higher = more severe.

### Semiring: Tropical
**Justification**: Funding impacts accumulate (cumulative welfare).

### Monoid: Max
**Justification**: Extension cost = worst single deprivation (maximin equity).

### Optimization: Minimize
**Justification**: Minimize worst-case deprivation.

### Budget β
Upper bound on worst deprivation (β = 50: "no deprivation > 50").

---

## Running the Example

```bash
clingo -n 0 --opt-mode=opt -c beta=50 \
  WABA/core/base.lp \
  WABA/semiring/tropical.lp \
  WABA/monoid/max_minimization.lp \
  WABA/filter/standard.lp \
  WABA/semantics/stable.lp \
  WABA/examples/resource_allocation/resource_allocation.lp
```

---

## Design Compliance
✅ All principles satisfied
✅ Specific contraries (unfunded_education, etc.)
✅ No mixed bodies (direct needs → allocations)
