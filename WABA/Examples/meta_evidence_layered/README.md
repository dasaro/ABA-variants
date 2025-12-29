# Meta-Evidence Layered Argumentation Example

**Domain**: Epistemology / Meta-Science / Evidence Hierarchies
**Last Updated**: 2025-12-29

---

## Story

A researcher evaluates scientific claims supported by two studies (S1, S2). Initially, both studies support the claim. However, meta-evidence reveals methodological flaws undermining study reliability. Then, meta-meta-evidence challenges the meta-evidence source itself, creating non-monotonic reversal: claim supported → claim rejected → claim reinstated. We minimize the cost of overriding credibility assessments while maintaining epistemic coherence.

---

## WABA Configuration

### Weight Interpretation
Credibility penalty (0-100). Higher = more severe methodological flaw or source unreliability (harder to dismiss).

### Semiring: Gödel (min/max)
**Justification**: Credibility operates via **weakest-link semantics**. A claim's strength is limited by the least reliable component in its support chain. One decisive flaw defeats the entire argument (min for conjunction captures this).

### Monoid: Max
**Justification**: Extension cost = **worst single credibility override**. We enforce a threshold on the maximum severity of any dismissed flaw (maximin epistemic conservatism).

### Optimization: Minimize
**Justification**: Minimize worst-case credibility penalty ignored.

### Budget β
Upper bound on worst single credibility override: **β = 60** means "can dismiss flaws with severity ≤60, but not worse."

**Suggested values**:
- **β = 40**: Strict (cannot dismiss major methodological flaws)
- **β = 60**: Moderate (can dismiss one moderate flaw)
- **β = 80**: Permissive (can dismiss severe flaws, accept most claims)

---

## Framework Structure

### Assumptions (Defeasible Trust Commitments)
- **trust_study_s1**: Trust that Study 1 is methodologically sound
- **trust_study_s2**: Trust that Study 2 is methodologically sound
- **accept_method_m1**: Accept the underlying measurement methodology
- **trust_meta_source**: Trust the meta-analysis / critique source

### Derived Atoms
**Layer 1 (Object-level evidence)**:
- `supports_claim`: Scientific claim supported by studies
- `data_s1_positive`: Study 1 data collected
- `data_s2_positive`: Study 2 data collected

**Layer 2 (Meta-evidence - undermines studies)**:
- `unreliable_s1`: Study 1 deemed unreliable (meta-evidence conclusion)
- `unreliable_s2`: Study 2 deemed unreliable (meta-evidence conclusion)
- `method_flaw_detected`: Methodological flaw identified
- `meta_report_bias`: Meta-analysis reports bias in original studies

**Layer 3 (Meta-meta-evidence - undermines meta-source)**:
- `meta_unreliable`: Meta-source itself is unreliable
- `meta_conflict_of_interest`: Meta-source has conflicts of interest

### Contraries (Derived Defeats Only)
- `contrary(trust_study_s1, unreliable_s1)`: Study 1 trust defeated by derived unreliability
- `contrary(trust_study_s2, unreliable_s2)`: Study 2 trust defeated by derived unreliability
- `contrary(trust_meta_source, meta_unreliable)`: Meta-source trust defeated by derived meta-unreliability
- `contrary(accept_method_m1, method_flaw_detected)`: Methodological assumption defeated by detected flaw

### Mixed-Body Rules
1. **Meta-evidence derivation** (assumption + derived atom):
   ```
   unreliable_s1 :- trust_meta_source, meta_report_bias.
   ```
   Study deemed unreliable only if we trust the meta-source AND it reports bias.

2. **Claim support** (assumptions + derived):
   ```
   supports_claim :- trust_study_s1, trust_study_s2, data_s1_positive.
   ```
   Claim supported requires trusting both studies AND having positive data.

---

## Non-Monotonic Behavior

**Scenario progression**:
1. **Base case**: Trust both studies → claim supported
2. **Add meta-evidence**: Meta-source reports bias → studies unreliable → claim defeated
3. **Add meta-meta-evidence**: Meta-source has conflicts → meta-source unreliable → original studies reinstated → claim supported again

This demonstrates **epistemic flip** via layered defeaters.

---

## Running the Example

### Enumeration Mode (all extensions)
```bash
clingo -n 0 \
  WABA/core/base.lp \
  WABA/semiring/godel.lp \
  WABA/monoid/max_minimization.lp \
  WABA/filter/standard.lp \
  WABA/semantics/stable.lp \
  WABA/examples/meta_evidence_layered/meta_evidence_layered.lp
```

### Optimization Mode (minimize worst credibility override)
```bash
clingo -n 0 --opt-mode=opt -c beta=60 \
  WABA/core/base.lp \
  WABA/semiring/godel.lp \
  WABA/monoid/max_minimization.lp \
  WABA/filter/standard.lp \
  WABA/semantics/stable.lp \
  WABA/examples/meta_evidence_layered/meta_evidence_layered.lp
```

### Strict Mode (β = 40, cannot dismiss major flaws)
```bash
clingo -n 0 --opt-mode=opt -c beta=40 \
  WABA/core/base.lp \
  WABA/semiring/godel.lp \
  WABA/monoid/max_minimization.lp \
  WABA/filter/standard.lp \
  WABA/semantics/stable.lp \
  WABA/examples/meta_evidence_layered/meta_evidence_layered.lp
```

---

## Differentiation from Existing Examples

**vs. strong_inference (Ulam-Rényi)**:
- Strong inference: hypothesis **pruning** via experimental outcomes, COUNT monoid ("Nature lies m times")
- Meta-evidence: **credibility chains** with layered defeaters, MAX monoid (worst-case flaw threshold)

**vs. nhst**:
- NHST: **p-value thresholds** and statistical significance, SUM monoid (total ignored evidence)
- Meta-evidence: **methodological critique** across evidence layers, GÖDEL semiring (weakest-link credibility)

---

## Design Compliance
✅ All principles satisfied
✅ Specific contraries (unreliable_s1, unreliable_s2, meta_unreliable, method_flaw_detected)
✅ Mixed-body rules (unreliable_s1 :- trust_meta_source, meta_report_bias)
✅ Gödel semiring: weakest-link credibility semantics
✅ Max monoid: worst-case credibility override threshold
✅ β operational: threshold on maximum flaw severity dismissed
