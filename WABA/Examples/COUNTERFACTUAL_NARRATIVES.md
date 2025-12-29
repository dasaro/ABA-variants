# Counterfactual Analysis: What-If Budgets Change?

**Analysis Date**: 2025-12-29

This document analyzes how story conclusions change as budget constraints are relaxed, based on full enumeration of solution spaces.

---

## Methodology

- **Enumeration mode** (no --opt-mode): Find ALL stable extensions
- **Cost ranking**: Sort solutions from optimal to worst
- **Budget thresholds**: Identify what new narratives become available at each cost level

**Sign conventions**:
- **Minimization** (positive costs): Lower cost = better, budget is upper bound (cost ≤ β)
- **Maximization** (negative costs): Higher cost = better, budget is lower bound (cost ≥ β)

---

## Examples with Rich Solution Landscapes

### 7. Practical Deliberation (COUNT minimization, β=2)

**All 4 solutions** (ordered by cost):

| Cost | Narrative | Assumptions Kept |
|------|-----------|------------------|
| **0** | Abandon all Sunday plans | NONE |
| **1** | Keep meeting assumption only | `assume_no_meeting` |
| **2** | Keep weather + meeting | `assume_weather_good`, `assume_no_meeting` |
| **3** | Keep all three plans | `assume_traffic_light`, `assume_weather_good`, `assume_no_meeting` |

**Counterfactual stories**:

**β=0 (strictest)**: "All four disruptions accepted, all plans abandoned. Pure realism - adapt to reality."

**β=1**: "Accept 3 disruptions, keep one assumption (meeting won't conflict). Minimal optimism - protect calendar commitments."

**β=2 (recommended)**: "Accept 2 disruptions. Keep weather assumption and meeting assumption. Moderate optimism - weather might be good, meeting likely won't happen. Can plan outdoor run."

**β≥3 (permissive)**: "Accept only 1 disruption (gym closed). Keep all three planning assumptions. Maximum optimism - assume good weather, light traffic, no meeting. Drive downtown and run outdoors."

**Interpretation**: Budget directly controls **cognitive conservatism**. Tight budgets force accepting reality; loose budgets permit wishful thinking.

---

### 9. Strong Inference / Ulam-Rényi (COUNT minimization, β=0)

**All 3 solutions** (ordered by cost):

| Cost | Narrative | Theories Accepted |
|------|-----------|-------------------|
| **0** | Strict empiricism - Nature never lies | `h2` (Relativistic), `h4` (String Theory) |
| **1** | Tolerate 1 experimental error | `h1` (Newtonian), `h2`, `h4` |
| **2** | Tolerate 2 experimental errors | `h1`, `h2`, `h3` (Quantum), `h4` |

**Counterfactual stories**:

**β=0 (strictest - Ulam-Rényi m=0)**: "Nature never lies. Mercury precession and photoelectric effect experiments are infallible. **Newtonian and quantum mechanics rejected**. Only relativistic and string theory survive experimental scrutiny."

**β=1 (m=1)**: "Nature lies once. Dismiss ONE experimental outcome as measurement error. **Newtonian mechanics reinstated** by dismissing one refuting experiment. Relativistic and string theory still supported. Quantum still rejected."

**β≥2 (m≥2)**: "Nature lies twice or more. Dismiss multiple experimental outcomes. **All four theories coexist**. Newtonian, relativistic, and quantum mechanics all accepted by invoking experimental unreliability. Maximum theoretical pluralism."

**Interpretation**: Budget = **epistemic permissiveness** regarding experimental error. β=0 is strict Popperian falsificationism; β>0 permits Kuhnian resistance to falsification.

---

### 10. NHST Hypothesis Testing (SUM minimization, β=100)

**All 4 solutions** (ordered by cost):

| Cost | Narrative | Hypotheses Accepted | Policy |
|------|----------|---------------------|--------|
| **0** | Side effects only | `h2` (side effects) | NO policy ❌ |
| **100** | Positive effect only | `h1` (positive effect) | Policy accepted ✅ |
| **215** | Both effects | `h1`, `h2` | Policy accepted ✅ |
| **315** | All hypotheses | `h0` (null), `h1`, `h2` | Policy accepted ✅ |

**Counterfactual stories**:

**β=0 (strictest)**: "Accept only the side effects hypothesis (h2). Treatment has **adverse effects**, no positive benefit recognized. Effect size is large but negative. **Policy REJECTED**."

**β=100 (moderate)**: "Accept positive treatment effect (h1), reject side effects. Null hypothesis (h0) defeated by significant p-values. Treatment works. **Policy APPROVED**. Accept practical implementation."

**β=215 (permissive)**: "Accept BOTH positive effect and side effects. Treatment works but has risks. Effect size large. Mutual exclusion between h1/h2 violated by dismissing logical constraint. **Policy still approved** (h1 wins tie-break)."

**β≥315 (maximally permissive)**: "Accept ALL three hypotheses simultaneously - null, positive effect, AND side effects. Logical coherence abandoned. All statistical evidence accommodated. Policy approved."

**Interpretation**: Budget controls **evidential coherence**. Low β forces choosing between competing hypotheses; high β permits contradiction by dismissing mutual exclusion.

---

### 11. Meta-Evidence Layered (MAX minimization, β=60)

**All 2 solutions** (ordered by cost):

| Cost | Narrative | Trust Decisions |
|------|-----------|-----------------|
| **60** | Trust meta-source, reject studies | `trust_meta_source`, `accept_method_m1` |
| **70** | Trust studies, reject meta-critique | ALL 4 assumptions trusted |

**Counterfactual stories**:

**β=60 (strict)**: "**Meta-analysis prevails**. Trust the meta-source's critique. Both original studies (S1, S2) deemed unreliable due to methodological flaws. Meta-meta-evidence (conflicts of interest in meta-source) **discarded** at cost 60. Claim **NOT supported** - original studies rejected."

**β≥70 (permissive)**: "**Original studies prevail**. Trust both S1 and S2. Claim **supported** by convergent evidence. Meta-source critique (unreliable_s1, unreliable_s2) **discarded** at cost 70 (highest single attack). Meta-meta-evidence successfully undermines meta-critique."

**Interpretation**: Budget determines **epistemic authority hierarchy**. β=60 elevates meta-analysis over object-level studies; β≥70 restores trust in original research by dismissing meta-level critique.

---

### 12. Sally Clark Meta-Evidence (SUM minimization, β=150)

**All 2 solutions** (ordered by cost):

| Cost | Narrative | Verdict |
|------|-----------|---------|
| **85** | Statistical evidence rejected | **ACQUITTAL** ✅ |
| **180** | Statistical evidence accepted | **GUILTY** ❌ |

**Counterfactual stories**:

**β=85 (strict - recommended)**: "**Sally Clark acquitted**. Statistical evidence (1 in 73 million) deemed invalid (cost 95 to keep it, exceeds budget). Independence assumption violated (80), expert witness unreliable (75), both attacks succeed. Only prosecution's general logical framework survives (cost 85 to suppress prosecutor's fallacy). Methodological critique defeats probabilistic evidence."

**β≥180 (permissive)**: "**Sally Clark convicted**. Accept statistical testimony at cost 180. Prosecutor's 1-in-73-million argument prevails. Independence violation (80) and expert unreliability (75) dismissed. Statistical evidence outweighs methodological critique. Guilty verdict derived."

**Interpretation**: Budget represents **evidentiary standards in legal reasoning**. β=85 demands rigorous methodological scrutiny (justice); β≥180 permits conviction based on statistical arguments despite known fallacies (miscarriage of justice).

---

### 2. Legal Precedent (SUM minimization, β=150)

**All 2 solutions** (ordered by cost):

| Cost | Narrative | Assumptions Accepted |
|------|-----------|----------------------|
| **150** | Partially enforceable contract | `assume_broad_scope`, `assume_long_duration` |
| **225** | Fully enforceable contract | All 3 assumptions |

**Counterfactual stories**:

**β=150 (moderate - recommended)**: "Non-compete agreement **partially enforceable**. Geographic scope (broad) and temporal duration (long) upheld by distinguishing limiting precedents at total cost 150. However, legitimate business interest assumption **defeated** by precedent showing overbreadth (weight 75). Contract survives but is narrowed by common law doctrine."

**β≥225 (permissive)**: "Non-compete agreement **fully enforceable**. All three contractual interpretations upheld: broad geographic scope, long duration, AND legitimate business interest. Total precedent deviation = 225 (within budget). Court distinguishes all limiting precedents, maximizing contract enforceability."

**Interpretation**: Budget controls **common law flexibility**. β=150 enforces doctrinal constraints (partial enforceability); β≥225 permits maximal distinguishing of precedent (full enforceability).

---

## Examples with Binary Thresholds (Unique Solutions)

These examples show **all-or-nothing behavior** - increasing budget beyond minimum threshold doesn't change outcomes:

### 1. Medical Triage (MAX minimization, β=80)

**Solution landscape**: ONLY 1 stable extension exists!

| Budget β | Satisfiable? | Narrative |
|----------|--------------|-----------|
| β < 80 | ❌ UNSAT | No solution exists - tragic choice unavoidable |
| β ≥ 80 | ✅ SAT | Treat all 3 patients (cost=80) |

**Counterfactual**: No gradual trade-offs. The framework has **only one stable extension** where all three patients are treated. There is no alternative extension where, say, only 2 patients are treated. It's all-or-nothing.

**Interpretation**: Medical resource constraints exhibit **binary regimes**: either the system can accommodate all emergencies (universal care) or it fails entirely. No intermediate "triage protocols" exist in this model.

---

### 3. Epistemic Justification (SUM minimization, β=115)

**Solution landscape**: ONLY 1 stable extension exists!

| Budget β | Satisfiable? | Narrative |
|----------|--------------|-----------|
| β < 115 | ❌ UNSAT | Cognitive collapse - cannot maintain all beliefs |
| β ≥ 115 | ✅ SAT | All 4 contradictory beliefs maintained (cost=115) |

**Counterfactual**: No way to "partially" resolve contradictions. Either the agent accepts ALL four contradictory sensory inputs (visual rain, auditory no-rain, tactile wet, forecast dry) or enters epistemic crisis.

**Interpretation**: Cognitive dissonance has a **breaking point**. Below β=115, the agent cannot sustain contradictory beliefs; at β=115, maximal fragmentation is reached.

---

### 4. Moral Dilemma (MAX minimization, β=75)

**Solution landscape**: ONLY 1 stable extension exists!

| Budget β | Satisfiable? | Narrative |
|----------|--------------|-----------|
| β < 75 | ❌ UNSAT | No morally acceptable action exists |
| β ≥ 75 | ✅ SAT | Sacrifice one to save five (cost=75) |

**Counterfactual**: The trolley problem has no alternative stable extensions. The agent either accepts the utilitarian sacrifice (violating autonomy at severity 75) or enters moral paralysis.

**Interpretation**: **Moral thresholds are discrete**. Below β=75, no action is permissible; at β=75, utilitarianism wins. No gradual moral compromise exists.

---

### 6. Resource Allocation (MAX minimization, β=80)

**Solution landscape**: ONLY 1 stable extension exists!

| Budget β | Satisfiable? | Narrative |
|----------|--------------|-----------|
| β < 80 | ❌ UNSAT | Cannot serve all stakeholders |
| β ≥ 80 | ✅ SAT | Fund all 4 needs (cost=80) |

**Counterfactual**: No prioritization extensions exist. The nonprofit either commits to ALL four stakeholder needs (education, healthcare, housing, infrastructure) or fails to form a coherent policy.

**Interpretation**: **Resource allocation exhibits universalism**. The framework doesn't permit "fund education and healthcare but not housing" - it's all-or-nothing at the threshold.

---

### 8. Scientific Theory Choice (SUM minimization, β=275)

**Solution landscape**: ONLY 1 stable extension exists!

| Budget β | Satisfiable? | Narrative |
|----------|--------------|-----------|
| β < 275 | ❌ UNSAT | Paradigm incompatibility crisis |
| β ≥ 275 | ✅ SAT | Accept all 4 theories (cost=275) |

**Counterfactual**: No intermediate extensions exist. The scientist cannot adopt "Newtonian + Quantum but not Relativistic" - the only stable extension includes ALL four competing paradigms.

**Interpretation**: **Epistemological maximalism at Ockham's limit**. Either accept all theoretical frameworks (pluralism) or reject the entire configuration.

---

## Summary Table: Budget Sensitivity

| Example | Solution Count | Budget Behavior | Counterfactual Richness |
|---------|----------------|-----------------|-------------------------|
| **Practical Deliberation** | 4 | Gradual (β=0,1,2,3) | ⭐⭐⭐ High - smooth cognitive conservatism scale |
| **Strong Inference** | 3 | Gradual (β=0,1,2) | ⭐⭐⭐ High - Ulam-Rényi m parameter |
| **NHST** | 4 | Gradual (β=0,100,215,315) | ⭐⭐⭐ High - evidential coherence trade-offs |
| **Legal Precedent** | 2 | Gradual (β=150/225) | ⭐⭐ Moderate - common law flexibility |
| **Meta-Evidence** | 2 | Gradual (β=60/70) | ⭐⭐ Moderate - authority hierarchy flip |
| **Sally Clark** | 2 | Gradual (β=85/180) | ⭐⭐⭐ High - legal evidentiary standards |
| **Medical Triage** | 1 | Binary (β=80) | ⭐ Low - all-or-nothing universalism |
| **Epistemic Justification** | 1 | Binary (β=115) | ⭐ Low - cognitive fragmentation ceiling |
| **Moral Dilemma** | 1 | Binary (β=75) | ⭐ Low - discrete moral threshold |
| **Resource Allocation** | 1 | Binary (β=80) | ⭐ Low - universal funding threshold |
| **Scientific Theory** | 1 | Binary (β=275) | ⭐ Low - paradigm pluralism threshold |
| **AI Safety** | 1 | Binary (β=30) | ⭐ Low - deployment threshold |

---

## Key Insights

### 1. Two Distinct Narrative Regimes

**Gradual Examples** (rich solution landscapes):
- Multiple stable extensions with increasing costs
- Budget controls **degree** of permissiveness (counting scale)
- Enable nuanced "what-if" storytelling
- Examples: Practical Deliberation, Strong Inference, NHST

**Binary Examples** (single stable extension):
- Sharp satisfiability thresholds
- Budget is **existence condition** (on/off switch)
- Enable "threshold detection" storytelling
- Examples: Medical Triage, Moral Dilemma, Scientific Theory

### 2. Budget as Narrative Dimension

| Domain | Budget Meaning | Low β | High β |
|--------|----------------|-------|--------|
| **Planning** | Cognitive conservatism | Realism, acceptance | Optimism, wishful thinking |
| **Science** | Experimental error tolerance | Strict falsification | Kuhnian resistance |
| **Statistics** | Evidential coherence | Mutual exclusion enforced | Contradictions tolerated |
| **Ethics** | Moral violation severity | Deontology (rigid duties) | Utilitarianism (trade-offs) |
| **Law** | Methodological rigor | Acquittal via critique | Conviction via statistics |
| **Medicine** | Resource strain tolerance | Tragic choice | Universal compassion |

### 3. Why Some Examples are Binary

**Hypothesis**: Binary behavior occurs when:
1. **Attack structure is complete**: Every assumption has exactly one strong contrary
2. **No partial defeats**: Attacks are all-or-nothing (no graded intermediates)
3. **Tight coupling**: Assumptions form rigid dependency clusters

**Evidence**: Medical Triage has 3 patients with 3 independent resource conflicts - yet only 1 extension exists (treat all). The contrary structure doesn't permit "treat 2 of 3" as stable.

---

## Counterfactual Implications for Framework Design

**For storytelling richness**: Design frameworks with:
- Multiple contraries per assumption
- Graded attack strengths
- Overlapping but non-identical attack targets
- Examples: NHST (4 solutions), Practical Deliberation (4 solutions)

**For threshold detection**: Design frameworks with:
- Unary contraries (one attack per assumption)
- Uniform attack strengths
- Coupled dependencies
- Examples: Medical Triage, Moral Dilemma (sharp phase transitions)

Both patterns are valuable! Binary thresholds model **critical decision points**; gradual landscapes model **negotiated trade-offs**.

---

**Analysis completed**: 2025-12-29
**Full enumeration verified**: All 12 examples tested in enum mode
**Constraint enforcement confirmed**: Monoid-specific constraint files working correctly
