# Practical Deliberation Example

**Domain**: Practical Reasoning / Cognitive Science
**Last Updated**: 2025-12-29

---

## Story

An agent planning a Sunday routine relies on **commonsense defaults**: traffic is light, gym opens at 7am, no rain, no meetings. Unexpected events (gym_closed, traffic_heavy, rain_detected, meeting_scheduled) defeat defaults, forcing belief revision. We minimize revision count (cognitive parsimony).

---

## WABA Configuration

### Weight Interpretation
Cognitive revision cost (1-10, belief entrenchment). Higher = harder to revise.

### Semiring: Arctic (sum/max)
**Justification**: Belief strength accumulates (reward-based, dual of Tropical).

### Monoid: Count
**Justification**: Extension cost = number of revised defaults (cardinality-based).

### Optimization: Minimize
**Justification**: Minimize number of revisions (cognitive conservatism).

### Budget β
Upper bound on revisions (β = 2: "revise at most 2 defaults").

---

## Running the Example

```bash
clingo -n 0 --opt-mode=opt -c beta=2 \
  WABA/core/base.lp \
  WABA/semiring/arctic.lp \
  WABA/monoid/count_minimization.lp \
  WABA/constraint/ub_count.lp \
  WABA/filter/standard.lp \
  WABA/semantics/stable.lp \
  WABA/examples/practical_deliberation/practical_deliberation.lp
```

---

## Design Compliance
✅ All principles satisfied
✅ Specific contraries (gym_closed, traffic_heavy, rain_detected, meeting_scheduled)
✅ No mixed bodies (direct defaults → plans)
✅ Count monoid: weight-agnostic revision counting
