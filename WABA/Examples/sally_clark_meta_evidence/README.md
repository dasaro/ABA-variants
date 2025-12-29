# Sally Clark Meta-Evidence Example

**Domain**: Legal Reasoning / Forensic Statistics / Prosecutor's Fallacy
**Last Updated**: 2025-12-29

---

## Story

A legal case involves statistical evidence (1 in 73 million probability of two infant deaths by chance). The prosecution uses this to argue guilt. However, meta-evidence reveals critical flaws: independence assumption violated (genetic/environmental factors), prosecutor's fallacy (P(evidence|innocent) ≠ P(innocent|evidence)), and unreliable expert testimony. We minimize the cost of overriding statistical critiques while determining verdict coherence.

---

## WABA Configuration

### Weight Interpretation
Severity of statistical/logical fallacy (0-100). Higher = more egregious methodological error (harder to justify ignoring).

### Semiring: Tropical (sum/min)
**Justification**: Statistical critiques **accumulate**. Multiple independent flaws (independence violation + prosecutor's fallacy + unreliable expert) compound to undermine evidence. Tropical sum captures cumulative methodological failure.

### Monoid: Sum
**Justification**: Extension cost = **total severity of ignored critiques**. Each dismissed fallacy contributes its severity to the total epistemic burden.

### Optimization: Minimize
**Justification**: Minimize total severity of ignored methodological critiques (evidential conservatism in legal reasoning).

### Budget β
Upper bound on total ignored critique severity: **β = 150** means "can dismiss critiques totaling ≤150 severity units."

**Suggested values**:
- **β = 0**: Strictest (accept all critiques, statistical evidence invalid)
- **β = 100**: Can ignore one major critique (e.g., prosecutor's fallacy alone)
- **β = 200**: Can ignore multiple critiques (accept statistical evidence despite flaws)

---

## Framework Structure

### Assumptions (Defeasible Evidential Commitments)
- **accept_statistical_evidence**: Accept the 1 in 73 million statistic as valid
- **assume_independence**: Assume infant deaths are independent events
- **trust_expert_witness**: Trust the statistical expert's testimony
- **accept_prosecution_logic**: Accept the prosecution's probabilistic reasoning

### Derived Atoms
**Object-level (verdict)**:
- `guilty`: Defendant guilty based on statistical evidence
- `acquit`: Defendant should be acquitted

**Meta-evidence (critiques)**:
- `independence_violated`: Independence assumption fails (genetic/environmental factors)
- `prosecutor_fallacy_detected`: Prosecutor's fallacy identified (P(E|H) ≠ P(H|E))
- `ecological_fallacy`: Ecological fallacy in applying population statistics
- `expert_unreliable`: Expert testimony deemed unreliable
- `evidence_invalid`: Overall statistical evidence deemed invalid

**Supporting evidence**:
- `statistical_testimony`: Expert provides statistical testimony
- `genetic_correlation`: Genetic factors correlate sibling deaths
- `environmental_factors`: Environmental factors present

### Contraries (Derived Defeats Only)
- `contrary(accept_statistical_evidence, evidence_invalid)`: Statistical evidence defeated by cumulative critiques
- `contrary(assume_independence, independence_violated)`: Independence assumption defeated by genetic/environmental factors
- `contrary(trust_expert_witness, expert_unreliable)`: Expert trust defeated by unreliability evidence
- `contrary(accept_prosecution_logic, prosecutor_fallacy_detected)`: Prosecution reasoning defeated by fallacy detection

### Mixed-Body Rules
1. **Conviction requires evidence acceptance** (assumption + derived):
   ```
   guilty :- accept_statistical_evidence, statistical_testimony.
   ```
   Conviction requires accepting the statistical evidence AND having the testimony.

2. **Evidence invalidity from multiple critiques** (assumptions + derived):
   ```
   evidence_invalid :- independence_violated, prosecutor_fallacy_detected.
   ```
   Evidence deemed invalid when multiple critiques combine (Tropical accumulation).

3. **Independence violation from factors** (assumption + derived):
   ```
   independence_violated :- genetic_correlation, environmental_factors.
   ```
   Independence fails when both genetic and environmental correlations present.

---

## Legal Context: The Sally Clark Case

**Real case**: Sally Clark wrongfully convicted of murdering her two infant sons based on flawed statistical evidence (1 in 73 million). Conviction overturned after identifying:
1. **Independence violation**: Genetic/environmental factors make deaths non-independent
2. **Prosecutor's fallacy**: Confused P(evidence|innocent) with P(innocent|evidence)
3. **Unreliable expert**: Sir Roy Meadow's testimony methodologically flawed

This example models how **meta-evidence (methodological critique) defeats object-level statistical evidence** in legal reasoning.

---

## Running the Example

### Enumeration Mode (all extensions)
```bash
clingo -n 0 \
  WABA/core/base.lp \
  WABA/semiring/tropical.lp \
  WABA/monoid/sum_minimization.lp \
  WABA/constraint/ub_sum.lp \
  WABA/filter/standard.lp \
  WABA/semantics/stable.lp \
  WABA/examples/sally_clark_meta_evidence/sally_clark_meta_evidence.lp
```

### Optimization Mode (minimize ignored critique severity)
```bash
clingo -n 0 --opt-mode=opt -c beta=150 \
  WABA/core/base.lp \
  WABA/semiring/tropical.lp \
  WABA/monoid/sum_minimization.lp \
  WABA/constraint/ub_sum.lp \
  WABA/filter/standard.lp \
  WABA/semantics/stable.lp \
  WABA/examples/sally_clark_meta_evidence/sally_clark_meta_evidence.lp
```

### Strict Mode (β = 0, accept all critiques)
```bash
clingo -n 0 --opt-mode=opt -c beta=0 \
  WABA/core/base.lp \
  WABA/semiring/tropical.lp \
  WABA/monoid/sum_minimization.lp \
  WABA/constraint/ub_sum.lp \
  WABA/filter/standard.lp \
  WABA/semantics/stable.lp \
  WABA/examples/sally_clark_meta_evidence/sally_clark_meta_evidence.lp
```

**Expected**: With β=0, statistical evidence invalid → acquittal extension stable

---

## Differentiation from Existing Examples

**vs. strong_inference (Ulam-Rényi)**:
- Strong inference: **hypothesis rejection** via experimental outcomes, COUNT monoid (number of errors)
- Sally Clark: **legal evidence critique** via methodological flaws, SUM monoid (total critique severity)

**vs. nhst**:
- NHST: **p-value significance testing** (p ≤ α), weights = floor(100*(1-p)), research context
- Sally Clark: **prosecutor's fallacy** and independence violations, weights = fallacy severity, **legal** context

**vs. meta_evidence_layered**:
- Layered: **3-tier credibility chains** (study → meta → meta-meta), GÖDEL semiring (weakest link)
- Sally Clark: **legal statistical fallacies**, TROPICAL semiring (cumulative critique accumulation)

---

## Design Compliance
✅ All principles satisfied
✅ Specific contraries (evidence_invalid, independence_violated, expert_unreliable, prosecutor_fallacy_detected)
✅ Mixed-body rules (guilty :- accept_statistical_evidence, statistical_testimony)
✅ Tropical semiring: cumulative critique accumulation
✅ Sum monoid: total ignored critique severity
✅ β operational: threshold on total ignorable fallacy severity
