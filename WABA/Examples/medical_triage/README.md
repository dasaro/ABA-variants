# Medical Triage Example

**Domain**: Medical Ethics / Emergency Medicine
**Last Updated**: 2025-12-29

---

## Story

Three patients arrive simultaneously at an emergency department:
- **Patient A** exhibits severe trauma indicators (assume_severe_trauma)
- **Patient B** shows cardiac event symptoms (assume_cardiac_event)
- **Patient C** presents respiratory distress signs (assume_respiratory_distress)

Each patient's condition (defeasible diagnostic assumption) warrants a critical treatment protocol:
- Trauma → Surgery (requires Operating Room)
- Cardiac → Catheterization (requires Cathlab)
- Respiratory → Ventilation (requires ICU bed)

**The Dilemma**: Critical resources are limited and cannot serve all patients simultaneously. The triage decision involves prioritizing patients by accepting resource unavailability for some, thereby incurring harm costs for deprioritized patients.

---

## Philosophical Framing

This example models **distributive justice under scarcity** in medical ethics. The framework captures:
- **Defeasible commitments**: Diagnostic assumptions are prima facie warrants for treatment, not absolute claims
- **Mediated defeat**: Patients' treatment assumptions are defeated through derived resource unavailability facts, not by direct patient-vs-patient conflict
- **Moral trade-offs**: The extension cost represents the worst harm we inflict on any single patient (maximin equity principle)

---

## WABA Configuration

### Weight Interpretation
Weights represent **harm severity (0-100)** if a patient's condition is deprioritized (their diagnostic assumption is defeated).

**Weight assignments**:
- `assume_severe_trauma`: 80 (high harm if trauma patient deprioritized)
- `assume_cardiac_event`: 70 (high harm if cardiac patient deprioritized)
- `assume_respiratory_distress`: 60 (moderate-high harm if respiratory patient deprioritized)

### Semiring: Gödel (min/max)

**Justification**: Diagnostic certainty propagates via the **weakest evidence** in the chain. In safety-critical medical decisions, a treatment protocol is only as reliable as the weakest diagnostic indicator (weakest-link principle).

- **Conjunction** (min): Certainty = minimum of all supporting evidence
- **Disjunction** (max): Certainty = maximum across alternative derivations
- **Identity**: #sup (perfect certainty)

### Monoid: Max

**Justification**: Extension cost = **maximum single patient harm**. We adopt an egalitarian harm distribution principle: minimize the worst harm to any individual patient (maximin equity / Rawlsian justice).

### Optimization Direction: Minimize

**Justification**: Weights represent costs (harm severity). We minimize to find the triage policy that minimizes the worst-case patient harm.

### Budget β: Maximum Tolerable Harm

**Meaning**: Upper bound on the worst harm to any single patient.
**Default**: β = 50
**Interpretation**: "No patient suffers harm severity above 50"

**Constraint encoding**:
```prolog
:- extension_cost(C), C > beta.
```

This is an **upper bound** constraint: the maximum discarded attack weight (= worst patient harm) must not exceed β.

---

## Discarded Attack Interpretation

**What does it mean to discard an attack?**

When we discard the attack `no_or_available` → `assume_severe_trauma`, we are:
- **Accepting the risk** of OR unavailability
- **Allowing** the trauma patient to be deprioritized
- **Incurring harm cost** = weight(no_or_available) = 80

In general: Overriding resource unavailability = securing that resource for the patient (at cost = harm severity if we fail to secure it).

---

## Structure Details

### Assumptions (Defeasible Patient Conditions)
```prolog
assumption(assume_severe_trauma).
assumption(assume_cardiac_event).
assumption(assume_respiratory_distress).
```

### Derived Atoms
**Treatment Protocols**:
- `protocol_surgery` - Trauma patient needs surgery
- `protocol_cardiac_cath` - Cardiac patient needs catheterization
- `protocol_ventilation` - Respiratory patient needs ventilation

**Resource Unavailability** (contraries):
- `no_or_available` - Operating Room unavailable
- `no_cathlab_available` - Cathlab unavailable
- `no_icu_available` - ICU bed unavailable

**Resource Occupancy** (resource conflicts):
- `or_occupied`, `cathlab_occupied`, `icu_occupied`

### Contraries (Resource Unavailability Defeats Patient Assumptions)
```prolog
contrary(assume_severe_trauma, no_or_available).
contrary(assume_cardiac_event, no_cathlab_available).
contrary(assume_respiratory_distress, no_icu_available).
```

### Rule Structure (Mixed Bodies)

**Example**: Rule r4 derives resource unavailability from both protocol (derived) and occupancy (derived):
```prolog
head(r4, no_or_available).
body(r4, protocol_surgery).  % Derived from assumption
body(r4, or_occupied).       % Derived from other protocols (conflict)
```

This demonstrates **mixed rule bodies**: derived atoms depending on both assumptions (via protocol) and other derived facts (resource conflicts).

---

## Running the Example

### Basic Usage (Stable Semantics, β = 50)

```bash
clingo -n 0 --opt-mode=opt -c beta=50 \
  WABA/core/base.lp \
  WABA/semiring/godel.lp \
  WABA/monoid/max_minimization.lp \
  WABA/filter/standard.lp \
  WABA/semantics/stable.lp \
  WABA/examples/medical_triage/medical_triage.lp
```

### Enumerate All Extensions (No Optimization)

```bash
clingo -n 0 -c beta=50 \
  WABA/core/base.lp \
  WABA/semiring/godel.lp \
  WABA/monoid/max_minimization.lp \
  WABA/filter/standard.lp \
  WABA/semantics/stable.lp \
  WABA/examples/medical_triage/medical_triage.lp
```

### Vary Budget (Explore Triage Policies)

```bash
# Strict budget (β = 40): May be UNSAT (no feasible triage within harm limit)
clingo -n 0 --opt-mode=opt -c beta=40 [... same modules ...]

# Relaxed budget (β = 80): More triage options available
clingo -n 0 --opt-mode=opt -c beta=80 [... same modules ...]
```

---

## Expected Behavior

### With β = 50:
- **UNSAT** or limited solutions - Harm thresholds are strict
- May require deprioritizing the least critical patient (respiratory, harm = 60)
- Extension cost ≤ 50, so only solutions where max harm ≤ 50 are admissible

### With β = 80:
- **SAT** with multiple extensions
- Can explore trade-offs between different patient prioritizations
- Optimal extension minimizes worst harm within the β = 80 bound

---

## Design Compliance

This example adheres to all WABA design principles:

✅ **Defeasible assumptions**: Patient conditions are tentative diagnoses, not certainties
✅ **No direct assumption attacks**: Patients never attack each other; only resource unavailability defeats assumptions
✅ **Meaningful derived atoms**: Protocols and resource states are logical consequences
✅ **Flat structure**: Assumptions appear only in rule bodies
✅ **Explicit weight interpretation**: Harm severity clearly defined
✅ **Justified semiring**: Gödel captures weakest-link diagnostic reasoning
✅ **Justified monoid**: Max captures egalitarian harm distribution
✅ **Justified direction**: Minimize harm costs
✅ **Operational β**: Constraint enforces upper bound on maximum harm
✅ **Specific contraries**: Resource-specific unavailability atoms, not generic "capacity_exceeded"
✅ **Mixed rule bodies**: Rules derive resource unavailability from protocols + occupancy

---

## Pedagogical Notes

This example illustrates:
- **Maximin equity** (Rawlsian justice): Minimize the worst outcome for any individual
- **Resource allocation under scarcity**: Classic ethical dilemma in emergency medicine
- **Gödel semiring**: Weakest-link reasoning appropriate for safety-critical domains
- **Max monoid**: Worst-case aggregation for egalitarian fairness

---

## References

- Rawls, J. (1971). *A Theory of Justice*. Harvard University Press. (Maximin principle)
- Iserson, K. V., & Moskop, J. C. (2007). "Triage in medicine, part I: Concept, history, and types." *Annals of Emergency Medicine*, 49(3), 275-281.
- Moskop, J. C., & Iserson, K. V. (2007). "Triage in medicine, part II: Underlying values and principles." *Annals of Emergency Medicine*, 49(3), 282-287.
