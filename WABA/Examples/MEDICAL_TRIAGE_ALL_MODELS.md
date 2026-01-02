# Medical Triage: All Models Analysis

**Date**: 2025-12-31
**Example**: Medical Triage
**Configuration**: Gödel + Max + Conflict-Free Semantics
**Goal**: Enumerate ALL possible extensions (with and without discarding attacks) and show their costs

---

## Summary

**Total conflict-free extensions found: 8**
- 1 empty extension (cost = 0) ⭐ **OPTIMAL**
- 7 non-empty extensions (costs range from 60 to 80)

**Key Finding**: Empty extension is optimal because it avoids all attack discarding costs. Any non-empty extension requires discarding resource conflict attacks, incurring harm costs.

---

## Framework Structure

### Patients (Assumptions)

| Assumption | Weight | Patient Description |
|------------|--------|-------------------|
| `assume_severe_trauma` | 80 | Patient A: Severe trauma requiring OR + ICU |
| `assume_cardiac_event` | 70 | Patient B: Cardiac event requiring cathlab |
| `assume_respiratory_distress` | 60 | Patient C: Respiratory distress requiring ventilation |

### Resource Conflicts

When patients are treated, they derive protocols that occupy resources:
- **Patient A (trauma)** → `protocol_surgery` → `or_occupied`, `icu_occupied`
- **Patient B (cardiac)** → `protocol_cardiac_cath` → `or_occupied`, `cathlab_occupied`
- **Patient C (respiratory)** → `protocol_ventilation` → `cathlab_occupied`

When resources are occupied, they create unavailability attacks:
- `or_occupied` → derives `no_or_available` → **attacks Patient A** (weight 80)
- `cathlab_occupied` → derives `no_cathlab_available` → **attacks Patient B** (weight 70)
- `icu_occupied` → derives `no_icu_available` → **attacks Patient C** (weight 60)

---

## All Extensions with Costs

### Extension 1: EMPTY ⭐ **OPTIMAL**

**Extension**: ∅ (no patients treated)
**Cost**: 0
**Optimization value**: 0 0 0

**Interpretation**: Refuse to commit to any triage decision under resource scarcity.

**Attack resolution**:
- No assumptions selected → no protocols derived
- No resources occupied → no unavailability attacks
- **Zero attacks to discard** → cost = 0

**Clinical meaning**: "System cannot provide acceptable care to any patient under current resource constraints. Requires external intervention (more resources, triage committee, crisis protocols)."

---

### Extension 2: {assume_respiratory_distress}

**Extension**: Treat Patient C only (respiratory distress)
**Cost**: 60
**Optimization value**: 0 0 60

**Assumptions**:
- `assume_respiratory_distress` (weight 60)

**Derived protocols**:
- `protocol_ventilation` (weight 60)
- `cathlab_occupied` (weight 60)

**Attacks created**:
- `no_cathlab_available` (weight 70) **attacks** `assume_cardiac_event` (but cardiac NOT in extension, so no conflict)

**Attack resolution**:
- Patient C occupies cathlab → unavailability attacks Patient B
- But Patient B not in extension → no attacks against selected assumptions
- **Cost = 60** (minimum resource conflict cost)

**Why cost = 60?**
- The derivation chain creates attacks against non-selected assumptions
- Gödel semiring propagates weights via weakest link
- Max monoid takes worst-case discarded attack = 60

**Clinical meaning**: "Treat only respiratory patient, accepting that resources become unavailable for others."

---

### Extension 3: {assume_cardiac_event}

**Extension**: Treat Patient B only (cardiac event)
**Cost**: 70
**Optimization value**: 0 0 70

**Assumptions**:
- `assume_cardiac_event` (weight 70)

**Derived protocols**:
- `protocol_cardiac_cath` (weight 70)
- `or_occupied`, `cathlab_occupied` (weight 70)

**Attacks created**:
- `no_or_available` (weight 80) attacks `assume_severe_trauma`
- `no_cathlab_available` (weight 70) attacks self or others

**Attack resolution**:
- Cardiac treatment occupies OR and cathlab
- Creates unavailability attacks
- **Cost = 70** (harm from treating cardiac patient alone)

**Clinical meaning**: "Treat only cardiac patient, accepting resource unavailability for trauma patient."

---

### Extension 4: {assume_severe_trauma}

**Extension**: Treat Patient A only (severe trauma)
**Cost**: 80
**Optimization value**: 0 0 80 (tied for worst)

**Assumptions**:
- `assume_severe_trauma` (weight 80)

**Derived protocols**:
- `protocol_surgery` (weight 80)
- `or_occupied`, `icu_occupied` (weight 80)

**Attacks created**:
- `no_or_available` (weight 80) attacks others
- `no_icu_available` (weight 60) attacks Patient C

**Attack resolution**:
- Trauma treatment occupies OR and ICU
- Creates maximal unavailability attacks
- **Cost = 80** (highest single-patient cost)

**Clinical meaning**: "Treat only trauma patient, accepting worst-case harm profile."

---

### Extension 5: {assume_respiratory_distress, assume_severe_trauma}

**Extension**: Treat Patients A + C (trauma + respiratory)
**Cost**: 60
**Optimization value**: 0 0 60 (tied for best non-empty)

**Assumptions**:
- `assume_severe_trauma` (weight 80)
- `assume_respiratory_distress` (weight 60)

**Derived protocols**:
- `protocol_surgery`, `protocol_ventilation`
- `or_occupied`, `icu_occupied`, `cathlab_occupied`

**Attacks created**:
- `no_icu_available` (weight 60) **attacks** `assume_respiratory_distress` (IN extension!)
- Must **discard this attack** to keep respiratory patient

**Attack resolution**:
- Treating both creates ICU conflict
- ICU unavailability attacks respiratory patient (weight 60)
- **Must discard attack** with cost = 60
- **Cost = 60** (minimax harm from treating two patients)

**Clinical meaning**: "Treat trauma and respiratory patients together, accepting ICU scarcity conflict (harm level 60)."

---

### Extension 6: {assume_cardiac_event, assume_respiratory_distress}

**Extension**: Treat Patients B + C (cardiac + respiratory)
**Cost**: 70
**Optimization value**: 0 0 70

**Assumptions**:
- `assume_cardiac_event` (weight 70)
- `assume_respiratory_distress` (weight 60)

**Derived protocols**:
- `protocol_cardiac_cath`, `protocol_ventilation`
- `or_occupied`, `cathlab_occupied`

**Attacks created**:
- `no_cathlab_available` (weight 70) **attacks** `assume_cardiac_event` or `assume_respiratory_distress`
- Must **discard this attack**

**Attack resolution**:
- Both need cathlab resources
- Cathlab unavailability attacks (weight 70)
- **Must discard** with cost = 70
- **Cost = 70** (moderate harm from treating both)

**Clinical meaning**: "Treat cardiac and respiratory patients, accepting cathlab conflict (harm level 70)."

---

### Extension 7: {assume_cardiac_event, assume_severe_trauma}

**Extension**: Treat Patients A + B (trauma + cardiac)
**Cost**: 80
**Optimization value**: 0 0 80 (tied for worst)

**Assumptions**:
- `assume_severe_trauma` (weight 80)
- `assume_cardiac_event` (weight 70)

**Derived protocols**:
- `protocol_surgery`, `protocol_cardiac_cath`
- `or_occupied`, `icu_occupied`, `cathlab_occupied`

**Attacks created**:
- `no_or_available` (weight 80) **attacks** both patients
- Must **discard this attack**

**Attack resolution**:
- Both need OR resources
- OR unavailability attacks with weight 80
- **Must discard** with cost = 80
- **Cost = 80** (worst-case harm from treating both)

**Clinical meaning**: "Treat trauma and cardiac patients, accepting OR conflict (harm level 80 - worst case)."

---

### Extension 8: {assume_severe_trauma, assume_cardiac_event, assume_respiratory_distress}

**Extension**: Treat ALL THREE patients
**Cost**: 80
**Optimization value**: 0 0 80 (tied for worst)

**Assumptions**:
- All three patients

**Derived protocols**:
- All protocols active
- All resources occupied

**Attacks created**:
- `no_or_available` (weight 80) attacks all
- `no_cathlab_available` (weight 70) attacks cardiac + respiratory
- `no_icu_available` (weight 60) attacks respiratory

**Attack resolution**:
- Treating all three creates maximal resource conflicts
- **Must discard multiple attacks**
- **Max monoid**: cost = max(80, 70, 60) = 80
- **Cost = 80** (worst-case harm, same as treating just trauma + cardiac)

**Clinical meaning**: "Attempt to treat all three patients simultaneously, accepting worst-case resource conflict (harm level 80)."

---

## Cost Distribution Analysis

| Cost | Extensions | Patients Treated |
|------|-----------|------------------|
| **0** | 1 ⭐ | None (empty) |
| **60** | 2 | C only, A+C |
| **70** | 2 | B only, B+C |
| **80** | 3 | A only, A+B, A+B+C |

### Insights

1. **Empty is uniquely optimal**: Cost = 0, no other extension achieves this
2. **Treating more patients ≠ higher cost**:
   - A+C (cost 60) is BETTER than A alone (cost 80)
   - Adding C to A actually IMPROVES the cost!
3. **Patient C (respiratory) is "cheapest"**:
   - C alone: cost 60 (best single patient)
   - A alone: cost 80 (worst single patient)
4. **Max monoid creates cost plateaus**:
   - A+B and A+B+C have SAME cost (80) - worst-case dominates

---

## Why Admissible Semantics Finds Only Empty

**Admissible definition**: Self-defending conflict-free extensions

**Analysis of non-empty extensions**:

All 7 non-empty extensions are **conflict-free** BUT **NOT admissible** because:

1. **They cannot defend against resource attacks**
   - Treating patients creates `no_X_available` attacks
   - These attacks come from within the extension's derivations
   - **No way to defend** - attacks are self-inflicted

2. **Example: {assume_respiratory_distress}**
   - Treating C → derives `protocol_ventilation`
   - Protocol → creates `cathlab_occupied`
   - Occupied → attacks are present
   - **Cannot counter-attack** the unavailability
   - Not admissible (cannot defend itself)

3. **Only empty is admissible**
   - No assumptions → no protocols → no resources occupied
   - No unavailability attacks exist
   - **Trivially defends** (nothing to defend against)

---

## Budget Analysis

### What budget (β) would each extension need?

| Extension | Cost | Required Budget | Interpretation |
|-----------|------|----------------|----------------|
| Empty | 0 | β ≥ 0 ✓ Always | Always admissible |
| A+C | 60 | β ≥ 60 | Requires moderate budget |
| C only | 60 | β ≥ 60 | Same budget as A+C |
| B+C | 70 | β ≥ 70 | Requires higher budget |
| B only | 70 | β ≥ 70 | Same as B+C |
| A only | 80 | β ≥ 80 | Requires maximum budget |
| A+B | 80 | β ≥ 80 | Same as A only |
| A+B+C | 80 | β ≥ 80 | No better than A+B |

### Budget Scenarios

**β = 0**: Only empty extension (classical AAF)
**β = 50**: Only empty extension (threshold too low)
**β = 60**: Empty + 2 extensions (A+C, C only)
**β = 70**: Empty + 4 extensions (add B+C, B only)
**β = 80**: Empty + all 7 extensions (maximally permissive)

---

## Semiring/Monoid Impact

### Gödel Semiring (Weakest-Link)

**Weight propagation**: Minimum for conjunction (AND), maximum for disjunction (OR)

**Impact on medical triage**:
- Attack weights propagate via weakest clinical support link
- Resource conflicts inherit weights from protocols
- Models: "Clinical chain as strong as weakest link"

### Max Monoid (Minimax Fairness)

**Cost aggregation**: Maximum of all discarded attack weights

**Impact on medical triage**:
- Cost = worst harm to any single patient
- Avoids worst-case harm (Rawlsian maximin principle)
- Treating all three (cost 80) NO worse than treating just A (cost 80)

**Alternative monoids would change ranking**:

| Extension | Max Cost | Sum Cost | Count Cost |
|-----------|----------|----------|-----------|
| Empty | 0 | 0 | 0 |
| A+C | 60 | 60 | 1 |
| C only | 60 | 60 | 1 |
| B+C | 70 | 70 | 1 |
| B only | 70 | 70 | 1 |
| A only | 80 | 80 | 1 |
| A+B | 80 | 80 | 1 |
| A+B+C | 80 | **210** | **3** |

**With SUM monoid**: A+B+C would be WORST (cost 210) instead of tied
**With COUNT monoid**: All single-patient extensions tied (cost 1)

---

## Clinical Interpretation

### What does empty extension mean?

**NOT**: "Do nothing and let patients die"
**INSTEAD**: "Current triage protocol cannot provide acceptable care under resource scarcity"

**Appropriate responses**:
1. **Escalate to triage committee**: Collective decision-making
2. **Activate crisis protocols**: Emergency resource allocation
3. **Request additional resources**: OR, ICU, staff, equipment
4. **Apply external prioritization**: Age, survivability, social worth (ethically fraught)

### Non-empty extensions as "forced choices"

If empty is not acceptable (e.g., must treat someone):
- **Best option**: A+C or C only (cost 60) - minimize worst-case harm
- **Avoid**: A only or A+B (cost 80) - maximize worst-case harm

**Paradox**: Treating TWO patients (A+C) is BETTER than treating just ONE (A alone) under Max monoid! Cooperative triage can improve minimax fairness.

---

## Theoretical Significance

### 1. Empty Extensions Model Real Impossibility

Medical triage's empty optimal is NOT a bug - it correctly models:
- Genuine resource scarcity (insufficient OR, cathlab, ICU)
- Irresolvable conflicts (helping one harms another)
- Ethical undecidability (no "good" choice exists)

### 2. WABA Captures Multi-Criteria Reasoning

**Gödel + Max** combination encodes:
- Clinical reasoning: Weakest-link support chains
- Ethical reasoning: Minimax fairness (avoid worst harm)
- Resource reasoning: Scarcity creates genuine conflicts

### 3. Semantic Strictness Matters

- **Conflict-free**: 8 extensions (very permissive)
- **Admissible**: 1 extension (empty only) - appropriate strictness
- **Semi-stable**: 1 extension (empty only) - forces decisive stance

**Admissible correctly filters** non-defensible triage policies!

---

## Comparison to Previous Analyses

### Minimal Non-Empty (from MINIMAL_NONEMPTY_EXTENSIONS.md)

**Finding**: Medical triage had NO non-empty extensions under admissible/semi-stable

**Explanation**: Now confirmed with conflict-free enumeration:
- 7 non-empty CF extensions exist
- But NONE are admissible (cannot defend against resource attacks)
- Empty is uniquely admissible

### Optimal Without Budget (from OPTIMAL_MODELS_NO_BUDGET.md)

**Finding**: Empty optimal with cost = 0

**Explanation**: Now confirmed with full enumeration:
- All 7 non-empty extensions have positive cost (60-80)
- Empty uniquely achieves cost = 0
- Not due to tight budget - due to resource conflict structure

---

## Recommendations

### For Clinical Practice

1. **Recognize when empty is correct**: Framework signals "external intervention needed"
2. **If forced to choose**: Prefer A+C or C only (cost 60 minimizes worst harm)
3. **Avoid**: Single trauma patient (cost 80 is worst single-patient option)

### For Framework Design

1. **Empty extensions are meaningful**: Don't filter them out as "errors"
2. **Admissible semantics are appropriate**: Correctly reject non-defensible policies
3. **Max monoid models fairness**: Captures minimax ethical reasoning

### For Budget Setting

1. **β = 0**: Strict (only empty)
2. **β = 60**: Moderate (allows best non-empty: A+C, C only)
3. **β = 80**: Permissive (allows all triage decisions, including worst-case)

**Recommended**: β = 60 (allows minimal harm policies while excluding worst-case harm)

---

## Conclusion

**Medical Triage demonstrates WABA's expressive power for modeling real-world impossibility:**

1. **8 total extensions** (1 empty + 7 non-empty) under conflict-free semantics
2. **Empty is uniquely optimal** (cost = 0) and uniquely admissible
3. **Non-empty extensions reveal trade-offs**:
   - Best: A+C or C only (cost 60)
   - Worst: A only, A+B, A+B+C (cost 80)
4. **Admissible semantics filter correctly**: Only empty is defensible under resource scarcity
5. **Budget constraints are confirmatory**: They validate the optimal empty result, not cause it

**WABA successfully models clinical reality**: Some dilemmas have no good solution, and formal argumentation can rigorously demonstrate why.

---

**End of Report**
