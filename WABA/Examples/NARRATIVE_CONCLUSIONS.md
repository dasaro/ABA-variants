# WABA Example Narrative Conclusions

**Last Updated**: 2025-12-29
**Status**: Budget constraints properly enforced via `constraint/*.lp` files

---

## Overview

This document presents the **narrative conclusions** for all 12 WABA examples when run with their recommended budget parameters. Each story shows how budget constraints shape argumentation outcomes, demonstrating WABA's capacity to model bounded rationality, resource limitations, and pragmatic reasoning.

**Key Insight**: Budget parameter β directly controls narrative outcomes. Tighter budgets force harsher choices; looser budgets permit pluralism and compassion.

---

## 1. Medical Triage (Gödel + Max, β=80)

**Configuration**:
- Semiring: Gödel (min/max, weakest-link)
- Monoid: Max (worst-case harm)
- Optimization: Minimize
- Budget: β=80 (maximum single harm severity tolerated)

**Optimal Extension**: ✅ UNIQUE
```
in(assume_severe_trauma) in(assume_cardiac_event) in(assume_respiratory_distress)
Cost: 80 (worst single override)
```

**Narrative**: The hospital **treats all three emergency patients** despite resource conflicts (OR occupied, cathlab occupied, ICU occupied). By accepting worst-case resource overrun of 80 (within β=80 budget), all lives are saved. This represents **maximum compassion emergency medicine** where the system stretches to save everyone rather than making tragic choices.

**Interpretation**: Resource scarcity attacks all patient assumptions, but the budget permits discarding all attacks up to severity 80. The hospital prioritizes universal care over resource efficiency.

---

## 2. Legal Precedent (Tropical + Sum Max, β=150)

**Configuration**:
- Semiring: Tropical (sum/min, cumulative)
- Monoid: Sum (total authority)
- Optimization: Maximize
- Budget: β=150 (maximum total precedent deviation)

**Optimal Extension**: ✅ UNIQUE
```
in(assume_broad_scope) in(assume_long_duration)
assume_legitimate_interest DEFEATED by conclusion_void_overbroad
Cost: -150 (maximization, total legal authority accumulated)
```

**Narrative**: The non-compete agreement is **partially enforceable**. Geographic and temporal scope assumptions are upheld, but the legitimate interest assumption is **defeated** by precedent showing overbreadth (weight 75). The contract survives but is narrowed by common law doctrine. Maximum legal authority (-150) achieved by accepting some precedent limits while maintaining core provisions.

**Interpretation**: The sum monoid accumulates legal authority across precedents. Maximization seeks strongest enforceable contract within doctrinal constraints.

---

## 3. Epistemic Justification (Łukasiewicz + Sum, β=115)

**Configuration**:
- Semiring: Łukasiewicz (bounded sum, K=100)
- Monoid: Sum (total incoherence)
- Optimization: Minimize
- Budget: β=115 (maximum total epistemic unreliability)

**Optimal Extension**: ✅ UNIQUE
```
in(assume_visual_rain) in(assume_audio_no_rain) in(assume_tactile_wet) in(assume_forecast_dry)
Cost: 115 (total incoherence at ceiling)
```

**Narrative**: The agent **maintains all four contradictory beliefs** (seeing rain, hearing no rain, feeling wetness, forecast says dry). Total epistemic incoherence of 115 equals β=115 exactly. All sensory modalities contradict each other, but the agent accepts maximum tolerable contradiction to preserve all evidence.

**Interpretation**: This represents **epistemic fragmentation at the breaking point** - the maximum cognitive dissonance before belief collapse. The agent values retaining all evidence over coherence.

---

## 4. Moral Dilemma (Gödel + Max, β=75)

**Configuration**:
- Semiring: Gödel (min/max, weakest-link)
- Monoid: Max (worst single duty violation)
- Optimization: Minimize
- Budget: β=75 (maximum single duty violation tolerated)

**Optimal Extension**: ✅ UNIQUE
```
in(assume_duty_beneficence) in(assume_duty_autonomy) in(assume_duty_justice)
assume_duty_nonmaleficence DEFEATED by violates_nonmaleficence (weight 85)
recommend_sacrifice_one derived
Cost: 75 (violates_autonomy successfully attacks, weight 75)
```

**Narrative**: **Sacrifice the one to save the five** (trolley problem utilitarian resolution). The duty of non-maleficence ("do no harm") is **rejected** because its violation severity (85) exceeds β=75. The system retains beneficence, autonomy, and justice, accepting maximum violation severity of 75 (autonomy violation when sacrificing the one).

**Interpretation**: **Bounded utilitarianism** - accepting harm to maximize lives saved, but only when duty violation severity stays within moral tolerance threshold. Non-maleficence is too costly to maintain.

---

## 5. AI Safety Policy (Bottleneck + Min Max, β=30)

**Configuration**:
- Semiring: Bottleneck-cost (max/min, worst-case paths)
- Monoid: Min (minimum quality threshold)
- Optimization: Maximize
- Budget: β=30 (minimum safety threshold, lower bound)

**Optimal Extension**: ✅ UNIQUE
```
in(assume_adversarial_robustness) in(assume_interpretability) in(assume_fairness) in(assume_monitoring)
approval_granted derived
Cost: -65 (maximization, minimum discarded attack quality)
```

**Narrative**: The AI system is **approved for deployment** despite all four safety dimensions (robustness, interpretability, fairness, monitoring) showing threshold violations. By maximizing the minimum discarded attack severity (-65, negative for maximization), the system maintains minimum safety assurance above β=30.

**Interpretation**: **Permissive regulatory deployment** where approval is granted by accepting bounded safety violations. The min monoid ensures all dimensions meet minimum threshold, but violations are tolerated to enable deployment.

---

## 6. Resource Allocation (Tropical + Max, β=80)

**Configuration**:
- Semiring: Tropical (sum/min, cumulative)
- Monoid: Max (worst-case deprivation)
- Optimization: Minimize
- Budget: β=80 (maximum single deprivation severity tolerated)

**Optimal Extension**: ✅ UNIQUE
```
in(assume_need_education) in(assume_need_healthcare) in(assume_need_housing) in(assume_need_infrastructure)
Cost: 80 (worst single deprivation override = unfunded_healthcare)
```

**Narrative**: The nonprofit **commits to all four competing stakeholder needs** (education, healthcare, housing, infrastructure). All needs show unfunded contraries with varying deprivation severities (60, 70, 75, 80). Worst-case deprivation override is exactly β=80 (healthcare unfunding).

**Interpretation**: **Aspirational comprehensive service** where the organization promises to address all needs by accepting maximum single-deprivation risk at the budget ceiling. Rawlsian maximin equity: minimize worst-case suffering.

---

## 7. Practical Deliberation (Arctic + Count, β=2)

**Configuration**:
- Semiring: Arctic (sum/max, dual of Tropical)
- Monoid: Count (number of revisions)
- Optimization: Minimize
- Budget: β=2 (maximum 2 belief revisions)

**Optimal Extensions**: ⚠️ MULTIPLE OPTIMA (3 alternatives)

**Option A** (Cost 1):
```
in(assume_weather_good)
3 disruptions successfully attack (gym_closed, traffic_heavy, meeting_scheduled)
```

**Option B & C** (Cost 0):
```
NO assumptions accepted
All 4 disruptions successfully attack
```

**Narrative**: With β=2 (can revise at most 2 defaults), the optimal strategy is **abandon all plans** (cost 0) and accept all four Sunday disruptions (gym closed, traffic heavy, rain detected, meeting scheduled). Alternatively, one plan (outdoor run, based on weather) can partially survive by discarding 1 disruption.

**Interpretation**: **Adaptive planning under uncertainty** - better to accept reality than cling to unrealistic defaults. When multiple disruptions occur, cognitive conservatism (minimizing revisions) favors abandoning expectations over maintaining fragile optimism.

---

## 8. Scientific Theory Choice (Tropical + Sum, β=275)

**Configuration**:
- Semiring: Tropical (sum/min, cumulative)
- Monoid: Sum (total complexity)
- Optimization: Minimize
- Budget: β=275 (maximum total theoretical complexity)

**Optimal Extension**: ✅ UNIQUE
```
in(assume_newtonian) in(assume_relativistic) in(assume_quantum) in(assume_auxiliary_h1)
Cost: 275 (total complexity at ceiling)
```

**Narrative**: The scientist **accepts all four competing theories** (Newtonian mechanics, relativistic mechanics, quantum mechanics, string theory) despite theoretical incompatibilities (Newtonian/quantum conflict = 80, classical/relativistic conflict = 65, excessive complexity = 50). Total complexity (80 + 65 + 50 + 80 = 275) equals β=275 exactly.

**Interpretation**: **Epistemological maximalism at Ockham's limit** - accepting maximum theoretical diversity before violating parsimony constraints. **Paradigm pluralism** rather than paradigm choice. The scientist refuses to prune theories, accepting maximum complexity burden within the budget.

---

## 9. Strong Inference / Ulam-Rényi (Tropical + Count, β=0)

**Configuration**:
- Semiring: Tropical (sum/min, cumulative rejection)
- Monoid: Count (number of experimental errors assumed)
- Optimization: Minimize
- Budget: β=0 ("Nature never lies" - no experimental errors tolerated)

**Optimal Extension**: ✅ UNIQUE
```
in(h2) in(h4)  [Relativistic + String Theory survive]
h1 (Newtonian), h3 (Quantum) DEFEATED by experimental rejections
Cost: 0 (zero experimental errors assumed)
```

**Narrative**: **Newtonian and quantum mechanics rejected**; relativistic and string theory survive. With β=0 ("Nature never lies"), all experimental evidence is treated as authoritative. Mercury perihelion precession and photoelectric effect experiments decisively refute classical and quantum theories without invoking experimental error or measurement unreliability.

**Interpretation**: **Strict empiricism** - data is infallible, theories are expendable. The Ulam-Rényi game with m=0 means no outcomes can be dismissed as "Nature lying." Experimental evidence has absolute epistemic priority over theoretical commitments.

---

## 10. NHST Hypothesis Testing (Tropical + Sum, β=100)

**Configuration**:
- Semiring: Tropical (sum/min, cumulative evidence)
- Monoid: Sum (total ignored statistical evidence)
- Optimization: Minimize
- Budget: β=100 (maximum total ignorable evidence strength)

**Optimal Extensions**: ⚠️ MULTIPLE OPTIMA (2 distinct solutions)

**Option A** (Cost 0):
```
in(h1)  [Positive treatment effect accepted]
H0 (null) defeated by rejected_h0 (weight 100)
H2 (side effects) defeated by mutual exclusion
accept_practical_policy derived
```

**Option B** (Cost 0):
```
in(h2)  [Side effects hypothesis accepted]
H0 (null) defeated by rejected_h0 (weight 100)
H1 (positive effect) defeated by mutual exclusion
effect_size_large derived but policy NOT accepted
```

**Narrative**: **Multiple optimal interpretations exist!** Both cost 0 (all statistical evidence accepted within β=100 budget). Statistical tests reject the null hypothesis (H0) with high significance. However, either **positive treatment effect** (H1) OR **adverse side effects** (H2) can be endorsed depending on mutual exclusion logic.

**Interpretation**: **Evidential underdetermination in statistical inference** - data supports multiple incompatible conclusions. The significance tests provide evidence against H0, but underdetermine the choice between H1 and H2. This reflects real-world challenges in hypothesis testing where rejecting the null doesn't uniquely determine the alternative.

---

## 11. Meta-Evidence Layered (Gödel + Max, β=60)

**Configuration**:
- Semiring: Gödel (min/max, weakest-link credibility)
- Monoid: Max (worst single credibility override)
- Optimization: Minimize
- Budget: β=60 (maximum single credibility flaw severity tolerated)

**Optimal Extension**: ✅ UNIQUE
```
in(accept_method_m1) in(trust_meta_source)
trust_study_s1, trust_study_s2 DEFEATED by meta-evidence (unreliable_s1, unreliable_s2)
meta_unreliable attack DISCARDED (cost 60, within budget)
Cost: 60 (meta-unreliable attack on trust_meta_source)
```

**Narrative**: The researcher **trusts the meta-analysis source** and **rejects both original studies** (S1, S2) as unreliable based on meta-evidence (methodological flaws, bias reports). However, the meta-meta-evidence revealing the meta-source's conflicts of interest is **discarded** at cost 60 (within β=60 budget).

**Interpretation**: **Partial non-monotonic flip** - Layer 2 (meta-evidence) defeats Layer 1 (original studies), but Layer 3 (meta-meta-evidence) is suppressed. Meta-critique prevails, but **critique of the critics is ignored** within credibility tolerance. The researcher sides with methodological oversight but doesn't pursue infinite regress of credibility assessment.

---

## 12. Sally Clark Meta-Evidence (Tropical + Sum, β=150)

**Configuration**:
- Semiring: Tropical (sum/min, cumulative critique)
- Monoid: Sum (total ignored fallacy severity)
- Optimization: Minimize
- Budget: β=150 (maximum total ignorable critique severity)

**Optimal Extension**: ✅ UNIQUE
```
in(accept_prosecution_logic)
accept_statistical_evidence DEFEATED by evidence_invalid (weight 95)
assume_independence DEFEATED by independence_violated (weight 80)
trust_expert_witness DEFEATED by expert_unreliable (weight 75)
acquit derived
Cost: 85 (prosecutor_fallacy_detected discarded to keep accept_prosecution_logic)
```

**Narrative**: **Sally Clark is acquitted**. The statistical evidence (1 in 73 million probability) is **deemed invalid** due to cumulative methodological critiques: independence assumption violated (genetic/environmental factors correlate sibling deaths), expert testimony unreliable, and overall statistical reasoning flawed. Only the prosecution's general logical framework survives (cost 85 to suppress prosecutor's fallacy critique, within β=150 budget).

**Interpretation**: **Justice through methodological critique** - wrongful conviction overturned by recognizing statistical fallacies (prosecutor's fallacy, independence violation, ecological fallacy). The real-world Sally Clark case outcome vindicated: meta-evidence about statistical methodology defeats object-level statistical evidence. Legal reasoning recognizes limits of probabilistic arguments.

---

## Meta-Patterns Across All Stories

### Unique vs Multiple Optima
- **10 examples**: Single optimal extension (deterministic resolution)
- **2 examples**: Multiple optimal extensions (Practical Deliberation, NHST) - evidential underdetermination

### Budget Enforcement Impact
**Before fix**: Budget constraints ignored → permissive behavior
**After fix**: Budget constraints enforced → 5 examples became UNSAT at original budgets

**Satisfiability thresholds** (minimum viable β):
| Example | Original β | Min Satisfiable β | Slack |
|---------|-----------|-------------------|-------|
| Medical Triage | 50 | 80 | +30 (60% increase) |
| Epistemic Justification | 80 | 115 | +35 (44% increase) |
| Moral Dilemma | 70 | 75 | +5 (7% increase) |
| Resource Allocation | 50 | 80 | +30 (60% increase) |
| Scientific Theory | 120 | 275 | +155 (129% increase) |

### Narrative Themes

**Compassion & Inclusion** (keep all despite constraints):
- Medical Triage: treat all patients
- Resource Allocation: fund all needs
- Scientific Theory: accept all theories

**Pragmatic Realism** (accept harsh truths):
- Practical Deliberation: abandon plans under disruption
- Strong Inference: reject falsified theories
- Sally Clark: reject flawed evidence

**Pluralism & Underdetermination** (multiple truths coexist):
- NHST: multiple hypothesis interpretations equally optimal
- Legal Precedent: balance competing precedents

**Justice & Critique** (meta-reasoning prevails):
- Sally Clark: methodological critique defeats statistical evidence
- Meta-Evidence Layered: meta-analysis defeats original studies

**Bounded Rationality** (pragmatic violations):
- Moral Dilemma: utilitarian sacrifice within moral bounds
- AI Safety: permissive deployment within safety thresholds
- Epistemic Justification: contradiction at cognitive ceiling

---

## Budget as Narrative Control Parameter

**Key Insight**: The budget parameter β directly controls story outcomes:

1. **Tight budgets** (β near minimum) → Harsh choices, pruning, realism
   - Strong Inference (β=0): strict empiricism, reject theories
   - Practical Deliberation (β=2): abandon plans

2. **Moderate budgets** (β at sweet spot) → Balanced trade-offs
   - Moral Dilemma (β=75): utilitarian resolution with bounds
   - Sally Clark (β=150): justice via measured critique

3. **Loose budgets** (β at ceiling) → Pluralism, compassion, inclusion
   - Medical Triage (β=80): save everyone
   - Scientific Theory (β=275): keep all paradigms
   - Epistemic Justification (β=115): maintain all contradictions

**For counterfactual analysis**: Varying β enables "what-if" reasoning about how constraints shape decisions.

---

## Technical Notes

**Budget Enforcement Mechanism**:
- Monoid-specific constraint files from `WABA/constraint/`
- Direct aggregate checks on `discarded_attack/3`
- No inline `extension_cost/1` predicates (performance optimization)

**Run Commands**: See individual example READMEs for exact clingo invocations.

**Last Verified**: 2025-12-29 with clingo 5.8.0

---

**See Also**:
- [COUNTERFACTUAL_NARRATIVES.md](COUNTERFACTUAL_NARRATIVES.md) - What-if budget analysis and alternative narratives
- [DESIGN_PRINCIPLES.md](DESIGN_PRINCIPLES.md) - Framework design constraints
- [README.md](README.md) - Example index and coverage statistics
- Individual example READMEs for detailed analysis
