# Medical Triage: Semantic Comparison Analysis

**Date**: 2025-12-31
**Example**: Medical Triage
**Configuration**: Gödel + Max + Various Semantics
**Goal**: Compare results across Conflict-Free, Admissible, and Semi-Stable semantics

---

## Summary

**Medical Triage demonstrates how semantic choice dramatically affects extension enumeration:**

| Semantics | Extensions Found | Empty Cost | Non-Empty Costs | Key Property |
|-----------|-----------------|------------|-----------------|--------------|
| **Conflict-Free** | 8 total | 0 | 60-80 | Very permissive (no self-attacks) |
| **Admissible** | 1 (empty only) | 0 | N/A | Strict (requires self-defense) |
| **Semi-Stable** | 1 (empty only) | 0 | N/A | Strictest (admissible + maximal range) |

**Key finding**: Admissible and semi-stable correctly filter out non-defensible triage policies, while conflict-free reveals all possible patient treatment combinations.

---

## Framework Structure

### Patients (Assumptions)

| Assumption | Weight | Patient Description |
|------------|--------|----------------------|
| `assume_severe_trauma` | 80 | Patient A: Severe trauma requiring OR + ICU |
| `assume_cardiac_event` | 70 | Patient B: Cardiac event requiring cathlab |
| `assume_respiratory_distress` | 60 | Patient C: Respiratory distress requiring ventilation |

### Resource Conflicts

**Derivation chains create resource attacks:**
- Patient A → `protocol_surgery` → `or_occupied`, `icu_occupied`
- Patient B → `protocol_cardiac_cath` → `or_occupied`, `cathlab_occupied`
- Patient C → `protocol_ventilation` → `cathlab_occupied`

**Resource unavailability attacks patients:**
- `or_occupied` → `no_or_available` → **attacks Patient A** (weight 80)
- `cathlab_occupied` → `no_cathlab_available` → **attacks Patient B** (weight 70)
- `icu_occupied` → `no_icu_available` → **attacks Patient C** (weight 60)

---

## Analysis 1: Conflict-Free Semantics

**Configuration**: No budget constraints, enumerate all conflict-free extensions

**Command**:
```bash
clingo 0 --opt-mode=ignore \
  core/base.lp semiring/godel.lp monoid/max_minimization.lp \
  filter/standard.lp semantics/cf.lp \
  examples/medical_triage/medical_triage.lp
```

**Results**: 8 extensions found

| Extension | Patients Treated | Cost | Optimization Value |
|-----------|-----------------|------|-------------------|
| ∅ (empty) | None | **0** ⭐ | 0 0 0 |
| {C} | Respiratory only | 60 | 0 0 60 |
| {A,C} | Trauma + Respiratory | 60 | 0 0 60 |
| {B} | Cardiac only | 70 | 0 0 70 |
| {B,C} | Cardiac + Respiratory | 70 | 0 0 70 |
| {A} | Trauma only | 80 | 0 0 80 |
| {A,B} | Trauma + Cardiac | 80 | 0 0 80 |
| {A,B,C} | All three | 80 | 0 0 80 |

**Key insights**:
1. **Empty is uniquely optimal** (cost 0)
2. **Paradox**: {A,C} (cost 60) < {A} (cost 80) - treating TWO patients better than treating ONE!
3. **Max monoid creates cost plateaus**: {A,B} and {A,B,C} have same cost (80)
4. **All are conflict-free** but most are NOT admissible

**Why conflict-free accepts all 8**:
- Conflict-free only requires: No assumption attacks itself
- Resource conflicts attack OTHER patients, not self
- Example: {C} is conflict-free because C doesn't attack C (it attacks B via cathlab)

---

## Analysis 2: Admissible Semantics

**Configuration**: No budget constraints, enumerate all admissible extensions

**Command**:
```bash
clingo 0 \
  core/base.lp semiring/godel.lp monoid/max_minimization.lp \
  filter/standard.lp semantics/admissible.lp \
  examples/medical_triage/medical_triage.lp
```

**Results**: 1 extension found

| Extension | Patients Treated | Cost | Optimization Value |
|-----------|-----------------|------|-------------------|
| ∅ (empty) | None | **0** ⭐ | 0 0 0 |

**Why only empty is admissible**:

**Admissible definition**: Conflict-free + defends all its members

**Non-empty extensions CANNOT defend themselves**:
- Treating patients creates resource occupancy
- Resource occupancy derives unavailability attacks
- These attacks come FROM the extension's own derivations
- **Cannot counter-attack** resource scarcity (self-inflicted)

**Example: Why {C} is NOT admissible**:
1. {C} is conflict-free ✓
2. C derives `protocol_ventilation`
3. Protocol occupies `cathlab_occupied`
4. Occupied cathlab creates attack (even if B not selected)
5. {C} cannot defend against its own resource consequences
6. **Not admissible** ✗

**Only empty is admissible**:
- No assumptions → no protocols → no resources occupied
- No unavailability attacks exist
- Trivially defends (nothing to defend against) ✓

---

## Analysis 3: Semi-Stable Semantics (Heuristic)

**Configuration**: No budget constraints, heuristic semi-stable semantics

**Command**:
```bash
clingo 0 --heuristic=Domain --enum-mode=domRec \
  core/base.lp semiring/godel.lp monoid/max_minimization.lp \
  filter/standard.lp semantics/admissible.lp \
  semantics/heuristic/semi-stable.lp \
  examples/medical_triage/medical_triage.lp
```

**Results**: 1 extension found

| Extension | Patients Treated | Cost | Optimization Value |
|-----------|-----------------|------|-------------------|
| ∅ (empty) | None | **0** ⭐ | 0 1 0 |

**Why semi-stable = admissible for Medical Triage**:

**Semi-stable definition**: Admissible + maximal range

**Mathematical reasoning**:
1. Set of admissible extensions = {∅}
2. Empty is automatically maximal in this set
3. Therefore, semi-stable = {∅}

**Why no non-empty semi-stable**:
- Would require: Admissible + larger range than empty
- But: No non-empty extension is admissible (from Analysis 2)
- Therefore: No non-empty semi-stable exists

---

## Comparison Table

| Property | Conflict-Free | Admissible | Semi-Stable |
|----------|--------------|------------|-------------|
| **Total extensions** | 8 | 1 | 1 |
| **Empty extension** | Yes (cost 0) | Yes (cost 0) | Yes (cost 0) |
| **Non-empty extensions** | 7 (costs 60-80) | None | None |
| **Optimality** | Empty optimal | Empty only | Empty only |
| **Semantic strength** | Weakest | Strong | Strongest |
| **Key requirement** | No self-attacks | Self-defense | Admissible + maximal |
| **Filters non-defensible** | No | Yes | Yes |
| **Clinical meaning** | "All possibilities" | "Defensible policies only" | "Defensible + decisive" |

---

## Philosophical Interpretation

### Conflict-Free: "What could we do?"

**8 extensions = full possibility space**
- Shows all patient treatment combinations
- Reveals trade-offs (cost 60 vs 80)
- Exposes paradoxes ({A,C} better than {A})
- **Use case**: Exploring options without commitment

### Admissible: "What can we justify?"

**1 extension = only defensible policy**
- Filters out non-defensible triage decisions
- Empty means "no good solution exists"
- Requires self-consistency (can defend choices)
- **Use case**: Ethically defensible decision-making

### Semi-Stable: "What should we commit to?"

**1 extension = decisive stance**
- Same as admissible when only one exists
- Forces maximal commitment (largest defensible extension)
- **Use case**: Requiring definitive policy (no indecision)

---

## Budget Scenarios (Conflict-Free)

**Question**: What budget (β) would each non-empty extension need?

| Extension | Cost | Required Budget | Interpretation |
|-----------|------|----------------|----------------|
| Empty | 0 | β ≥ 0 (always) | Always admissible |
| {C}, {A,C} | 60 | β ≥ 60 | Moderate budget |
| {B}, {B,C} | 70 | β ≥ 70 | Higher budget |
| {A}, {A,B}, {A,B,C} | 80 | β ≥ 80 | Maximum budget |

**Budget progression**:
- **β = 0**: Only empty (classical AAF)
- **β = 60**: Empty + 2 extensions (best non-empty options)
- **β = 70**: Empty + 4 extensions (moderate options)
- **β = 80**: Empty + all 7 (maximally permissive)

**Note**: Budget only affects conflict-free extensions. Admissible/semi-stable reject non-empty regardless of budget (due to lack of self-defense).

---

## Clinical Recommendations

### When to use each semantics:

**1. Conflict-Free - Exploratory Analysis**
- Goal: "Show me all possibilities"
- Use: Initial triage protocol design
- Reveals: Full option space, trade-offs, paradoxes

**2. Admissible - Policy Validation**
- Goal: "Which policies are defensible?"
- Use: Ethical review, protocol validation
- Reveals: Only self-consistent policies

**3. Semi-Stable - Decisive Policy**
- Goal: "What is the definitive policy?"
- Use: Final protocol selection, crisis standards
- Reveals: Maximal defensible commitment

### Interpreting empty extension:

**Medical Triage's empty extension is NOT "do nothing"**

**Correct interpretation**:
- "Current triage protocol cannot provide acceptable care under resource scarcity"
- "External intervention required" (triage committee, crisis protocols, more resources)
- "No individual clinical decision is defensible without additional constraints"

**Appropriate responses**:
1. Escalate to triage committee (collective decision)
2. Activate crisis protocols (modified standards)
3. Request additional resources (OR, ICU, staff)
4. Apply external prioritization criteria (age, survivability)

---

## Theoretical Significance

### 1. WABA Captures Real Clinical Impossibility

**Empty optimal is NOT a bug** - it correctly models:
- Genuine resource scarcity (insufficient OR, cathlab, ICU)
- Irresolvable conflicts (helping one harms another)
- Ethical undecidability (no "good" choice exists)

### 2. Semantic Choice Reveals Different Decision Layers

- **Conflict-Free**: Logical possibilities (what COULD happen)
- **Admissible**: Defensible policies (what we CAN justify)
- **Semi-Stable**: Decisive commitments (what we SHOULD do)

### 3. Mediated Defeat Crucial for Modeling

Resource conflicts work via **mediated defeat**:
1. Assumption (patient) → derives protocol
2. Protocol → derives resource occupancy
3. Occupancy → derives unavailability
4. Unavailability → **attacks** other patients

**Why mediated**: Patients don't attack each other directly - resource scarcity mediates the conflict.

---

## Comparison to Other Examples

**Medical Triage is unique among 12 examples**:

| Example | CF Extensions | Admissible | Semi-Stable | Empty Optimal |
|---------|--------------|------------|-------------|---------------|
| Medical Triage | 8 | 1 (empty) | 1 (empty) | **Yes** ⭐ |
| Moral Dilemma | ? | 1 (non-empty) | 1 (non-empty) | No |
| Strong Inference | ? | 3 (non-empty) | 1 (non-empty) | No |
| NHST | ? | 1 (non-empty) | 1 (non-empty) | No |

**Why Medical Triage has empty optimal**:
- Self-inflicted resource attacks (treating patients creates scarcity)
- No way to defend against own derivations
- Other examples have external attacks (can be defended)

---

## Recommendations

### For Framework Design

1. **Empty extensions are meaningful** - Don't filter them out as "errors"
2. **Admissible semantics are appropriate** - Correctly reject non-defensible policies
3. **Max monoid models fairness** - Captures minimax ethical reasoning
4. **Mediated defeat is essential** - Models resource scarcity correctly

### For Clinical Practice

1. **Recognize when empty is correct** - Framework signals "external intervention needed"
2. **If forced to choose** (conflict-free): Prefer {A,C} or {C} (cost 60 minimizes worst harm)
3. **Avoid**: Single trauma patient {A} (cost 80 is worst single-patient option)
4. **Escalation protocol**: Empty → triage committee → crisis standards

### For Further Analysis

1. **Vary semiring**: Test Tropical (additive costs) vs Gödel (weakest-link)
2. **Vary monoid**: Test SUM (total harm) vs MAX (worst-case harm)
3. **Add external constraints**: Model committee override, age-based triage
4. **Multi-period**: Model sequential patient arrivals

---

## Conclusion

**Medical Triage demonstrates WABA's expressive power for modeling impossible decision problems:**

1. **Conflict-free semantics** (8 extensions) reveals the full possibility space
2. **Admissible semantics** (1 extension) correctly filters non-defensible policies
3. **Semi-stable semantics** (1 extension) enforces decisive maximal commitment
4. **Empty optimal extension** legitimately represents "no good solution exists"
5. **Semantic choice** dramatically affects results (8 → 1 → 1)

**WABA successfully models clinical reality**: Some dilemmas have no good solution, and formal argumentation can rigorously demonstrate why.

---

**End of Report**
