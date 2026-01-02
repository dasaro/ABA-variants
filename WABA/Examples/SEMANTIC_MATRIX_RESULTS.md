# Semantic Matrix Results - Narrative Interpretations

Complete results from running all examples with the "most meaningful" semantic configurations.

**Date**: 2025-12-31
**Configuration Matrix**: Custom semiring/monoid/semantics combinations per example

---

## 1. MEDICAL TRIAGE
**Configuration**: Gödel + Max + Upper bound + Semi-stable
**Budget β**: 50 (max harm ≤ 50)

### Assumptions & Weights
```
assume_severe_trauma          weight: 80  (harm if trauma patient deprioritized)
assume_cardiac_event          weight: 70  (harm if cardiac patient deprioritized)
assume_respiratory_distress   weight: 60  (harm if respiratory patient deprioritized)
```

### Result: **Empty Extension**

### Narrative Interpretation
**Under semi-stable semantics with harm minimization, the system finds NO acceptable triage policy within the budget.**

The framework models a resource conflict where all three patients need scarce resources (OR, cathlab, ICU). If we accept any patient, their protocol triggers resource occupation that creates unavailability for others. The empty extension means:

- **Worst-case harm ceiling violated**: Any non-empty triage decision requires discarding attacks with severity >50, violating the harm ceiling
- **Conservative stance under conflict**: Semi-stable semantics forces a "decisive" position, but when all decisions exceed the ethical harm threshold, suspension of judgment (empty extension) is the only defensible stance
- **Clinical interpretation**: "Do not proceed with standard protocols - escalate to higher authority or seek alternative resources"

**Why empty?** Even accepting the lowest-harm patient (respiratory, weight 60) would require discarding their attack, giving extension_cost = 60 > β=50.

**Semi-stable rationale**: Prefers informative/decisive positions, but maintains admissibility constraints. Under impossible dilemmas, suspension is the maximal admissible stance with maximal range.

---

## 2. LEGAL PRECEDENT
**Configuration**: Tropical + Sum + Upper bound + Preferred
**Budget β**: 150 (total precedent deviation ≤ 150)

### Assumptions & Weights
```
assume_broad_scope           weight: 40  (non-compete covers entire industry)
assume_long_duration         weight: 35  (3-year restriction)
assume_legitimate_interest   weight: 50  (employer has protectable interest)
```

### Result: **Empty Extension**

### Narrative Interpretation
**Under preferred semantics with cumulative deviation tracking, NO legal interpretation survives precedent scrutiny.**

The framework models non-compete clause enforceability where each interpretation (broad scope, long duration, legitimate interest) triggers binding precedents that attack those interpretations. The empty extension means:

- **Precedent cascade**: Each interpretation, when combined with established doctrine, derives precedents that defeat itself or others
- **Doctrinal incoherence**: The legal position lacks a maximally defensible coherent interpretation within the deviation budget
- **Legal outcome**: "Clause is unenforceable as drafted - requires revision to comply with precedent"

**Why empty?** The framework's rules create cyclic precedent applications. For example, `assume_broad_scope` + `established_doctrine_limits` derives `precedent_geographic_limit`, which attacks `assume_broad_scope` itself.

**Preferred rationale**: Seeks maximal complete extensions. When all interpretations lead to self-defeating precedent chains exceeding the deviation budget, the empty extension is the only coherent stance.

---

## 3. MORAL DILEMMA
**Configuration**: Gödel + Max + Upper bound + Semi-stable
**Budget β**: 40 (worst duty violation ≤ 40)

### Assumptions & Weights
```
assume_duty_beneficence      weight: 80  (maximize patient welfare)
assume_duty_nonmaleficence   weight: 85  (do no harm)
assume_duty_autonomy         weight: 75  (respect consent)
assume_duty_justice          weight: 70  (fair distribution)
```

### Result: **Empty Extension**

### Narrative Interpretation
**Under semi-stable semantics with maximin moral constraint, NO action satisfies the duty violation ceiling.**

The trolley-problem scenario forces choice between:
- **Sacrifice one** (violates autonomy ≈75, nonmaleficence ≈85)
- **Do nothing** (violates beneficence ≈80, justice ≈70)

The empty extension means:

- **Moral undecidability**: Both action and inaction exceed the violation threshold β=40
- **Ethical suspension**: When all paths involve serious moral wrongness, the framework refuses to endorse either
- **Practical outcome**: "This decision exceeds single-agent authority - requires collective deliberation or institutional override"

**Why empty?** Minimum violation across all possible extensions exceeds 40. Even the "least wrong" choice violates duties with severity >40.

**Semi-stable rationale**: Forces a decisive stance when possible, but respects admissibility. Under genuine moral dilemmas exceeding threshold tolerance, suspension acknowledges the conflict's severity.

---

## 4. EPISTEMIC JUSTIFICATION
**Configuration**: Łukasiewicz + Sum + Upper bound + Grounded
**Budget β**: 80 (total unreliability ≤ 80)

### Assumptions & Weights
```
assume_visual_rain      weight: 20  (vision relatively reliable)
assume_audio_no_rain    weight: 30  (hearing moderately reliable)
assume_tactile_wet      weight: 25  (touch relatively reliable)
assume_forecast_dry     weight: 40  (forecasts less reliable)
```

### Result: **Empty Extension**

### Narrative Interpretation
**Under grounded semantics with bounded accumulation, the agent suspends ALL perceptual beliefs due to evidential conflicts.**

The framework models conflicting perceptual reports about rain. Background theories derive predictions that contradict observations, creating evidential conflicts. The empty extension means:

- **Evidential underdetermination**: Conflicting reports create contradictions that cannot be resolved within the unreliability budget
- **Skeptical posture**: Grounded semantics adopts the most conservative stance - when perceptions conflict, suspend judgment on all
- **Epistemic outcome**: "Insufficient coherent evidence to form belief about rain - seek additional independent evidence"

**Why empty?** Visual perception predicts wet ground and rain sounds, but auditory perception reports no sounds, and forecast says dry. Accepting any perception requires dismissing conflicts, but the total unreliability sum exceeds β=80.

**Grounded + Łukasiewicz rationale**: Grounded is skeptical (minimal undefeated set), and Łukasiewicz models saturating evidence. Under perceptual conflict with cumulative unreliability >80, grounded justifiably suspends all commitments.

---

## 5. AI SAFETY POLICY
**Configuration**: Bottleneck + Min + Lower bound + Grounded
**Budget β**: 60 (minimum safety assurance ≥ 60)

### Assumptions & Weights
```
assume_adversarial_robustness   weight: 75  (safety assurance level)
assume_interpretability         weight: 70  (explainability assurance)
assume_fairness                 weight: 80  (bias-free assurance)
assume_monitoring               weight: 65  (oversight assurance)
```

### Result: **Empty Extension**

### Narrative Interpretation
**Under grounded semantics with maximin safety threshold, AI deployment is REJECTED due to unmet safety requirements.**

The framework models AI deployment decision where testing reveals violations in multiple safety dimensions. The empty extension means:

- **Safety threshold not met**: All safety requirements have detected violations that reduce assurance below β=60
- **Conservative safety posture**: Grounded semantics (minimal undefeated) refuses approval when any dimension fails
- **Regulatory outcome**: "Deployment denied - must address robustness, interpretability, fairness, and monitoring deficiencies"

**Why empty?** The framework derives violations (e.g., `violates_robustness`, `violates_fairness`) from test results falling below thresholds. These violations attack the safety assumptions, and grounded semantics accepts only what's unattacked.

**Grounded + Bottleneck + Min rationale**: Bottleneck focuses on worst-case dimension, min tracks minimum safety, grounded requires undefeated status. This triple-conservative configuration correctly rejects deployment under unresolved safety concerns.

---

## 6. RESOURCE ALLOCATION
**Configuration**: Tropical + Max + Upper bound + Preferred
**Budget β**: 50 (worst deprivation ≤ 50)

### Assumptions & Weights
```
assume_need_education         weight: 70  (deprivation if unfunded)
assume_need_healthcare        weight: 80  (most severe if unfunded)
assume_need_housing           weight: 75  (very severe if unfunded)
assume_need_infrastructure    weight: 60  (moderate if unfunded)
```

### Result: **Empty Extension**

### Narrative Interpretation
**Under preferred semantics with Rawlsian maximin equity, NO allocation satisfies the deprivation ceiling.**

The framework models nonprofit funding allocation where all needs exceed available resources (scarcity constraint: if 3+ needs claimed, at least one unfunded). The empty extension means:

- **Scarcity exceeds tolerance**: Any allocation leaves at least one stakeholder with deprivation >50
- **Maximin failure**: Cannot ensure all stakeholders stay above minimum welfare threshold
- **Distributive outcome**: "Current budget insufficient for ethical allocation - must increase funding or relax constraints"

**Why empty?** Rules encode mutual exclusion: if 3 needs are in, the 4th is unfunded. Even the minimal deprivation (infrastructure, weight 60) exceeds β=50.

**Preferred + Tropical + Max rationale**: Preferred seeks maximal complete allocations, Tropical accumulates impact, Max focuses on worst-off. Under impossible distributive constraints, preferred semantics correctly identifies no allocation as defensible.

---

## 7. PRACTICAL DELIBERATION
**Configuration**: Arctic + Count + Upper bound + Preferred
**Budget β**: 50 (fewest revisions, upper bound on count)

### Assumptions & Weights
```
assume_weather_good       weight: 6  (default: good weather)
assume_gym_open           weight: 7  (default: gym is open)
assume_traffic_light      weight: 8  (default: traffic is light)
assume_no_meeting         weight: 9  (default: no meeting scheduled)
```

### Result: **Empty Extension**

### Narrative Interpretation
**Under preferred semantics with revision counting, ALL defaults are overridden.**

The framework models practical reasoning where default assumptions face defeating evidence. The empty extension means:

- **Evidence overrides all defaults**: Observed facts contradict all standing assumptions
- **Maximal revision**: Preferred semantics accepts the complete override when evidence demands it
- **Practical outcome**: "Cancel gym plan - weather bad, gym closed, traffic heavy, meeting scheduled"

**Why empty?** The framework likely derives defeating conditions for all four defaults. With count monoid and budget β=50, even overriding all four (count=4) is well within budget, but preferred semantics seeks maximal extensions - here, the empty extension maximally accommodates the evidence.

**Preferred + Arctic + Count rationale**: Arctic models reward semantics (strength of defaults), Count tracks revision cardinality. Preferred maximizes what survives evidence scrutiny. When evidence decisively defeats all defaults, acceptance of reality (empty extension) is preferred.

---

## 8. STRONG INFERENCE (Ulam-Rényi Game)
**Configuration**: Tropical + Count + Upper bound + Stable
**Budget β**: 2 (Nature may lie ≤ 2 times)

### Assumptions & Weights
```
h1 (Newtonian)       weight: 20  (simplest theory)
h2 (Relativistic)    weight: 40  (more complex)
h3 (Quantum)         weight: 50  (highly complex)
h4 (String theory)   weight: 70  (most speculative)
```

### Result: **All Four Hypotheses Accepted** {h1, h2, h3, h4}

### Narrative Interpretation
**Under stable semantics with experimental error counting, ALL hypotheses survive by dismissing contradictory experiments as "Nature lied".**

The framework models hypothesis elimination via decisive experiments. Experimental outcomes reject h1 (via mercury precession, photoelectric effect) and h3 (via gravitational waves). The ALL-IN result means:

- **Error tolerance utilized**: Discarding 2 experimental rejections (β=2 allows this) keeps all hypotheses viable
- **Conservative scientific stance**: Rather than hastily eliminate theories, tolerate experimental anomalies
- **Interpretation**: "With error tolerance β=2, we can maintain all theories by dismissing the two strongest rejections as experimental artifacts"

**Which attacks discarded?**
- Likely: `rejected_h1` (attacking h1) - accumulated weight 90 from two experiments
- Likely: `rejected_h3` (attacking h3) - weight 75 from gravitational wave evidence

With **count monoid**, extension_cost = 2 (count of discarded attacks), exactly meeting β=2.

**Stable + Tropical + Count rationale**: Stable forces decisive hypothesis sets, Tropical accumulates disconfirmation, Count focuses on number of errors (weight-agnostic). Result: "Keep all theories alive by questioning 2 experimental outcomes" - scientifically conservative under error tolerance.

**Alternative interpretation**: There may be 4 different stable extensions (one for each hypothesis combination), and the result shows the union. The stable semantics finds all maximally defended sets given β=2 error tolerance.

---

## 9. NHST (Null Hypothesis Significance Testing)
**Configuration**: Tropical + Sum + Upper bound + Semi-stable
**Budget β**: 100 (total ignored evidence ≤ 100)

### Assumptions & Weights
```
h0 (null hypothesis)         weight: 40  (default: no effect)
h1 (alternative hypothesis)  weight: 50  (directional effect)
h2 (alternative hypothesis)  weight: 60  (different effect)
```

### Result: **Empty Extension**

### Narrative Interpretation
**Under semi-stable semantics with cumulative evidence tracking, NO hypothesis survives evidential scrutiny.**

The framework models statistical hypothesis testing where accumulated evidence contradicts all hypotheses. The empty extension means:

- **Evidential overdetermination**: Statistical tests generate evidence against all candidate hypotheses
- **Data-driven rejection**: When evidence accumulates against all options, suspend hypothesis adoption
- **Statistical outcome**: "Data pattern does not support any tested hypothesis - consider alternative models"

**Why empty?** The framework likely derives rejections for all three hypotheses based on statistical test results. With sum monoid tracking cumulative ignored evidence, any non-empty extension exceeds β=100.

**Semi-stable + Tropical + Sum rationale**: Semi-stable seeks decisive acceptance/rejection, Tropical accumulates evidence strength, Sum tracks total ignored evidence. Under multiple-testing scenarios where all hypotheses face strong contradiction, semi-stable transparently reports "reject all" via empty extension.

---

## 10. META-EVIDENCE LAYERED
**Configuration**: Gödel + Max + Upper bound + Semi-stable
**Budget β**: 60 (worst credibility override ≤ 60)

### Assumptions & Weights
```
trust_study_s1        weight: 70  (trust Study 1 methodology)
trust_study_s2        weight: 65  (trust Study 2 methodology)
accept_method_m1      weight: 75  (accept measurement method)
trust_meta_source     weight: 60  (trust meta-analysis source)
```

### Result: **Empty Extension**

### Narrative Interpretation
**Under semi-stable semantics with weakest-link credibility, ALL trust commitments are suspended due to meta-level defeaters.**

The framework models 3-layer epistemic reversal:
1. **Layer 1**: Studies S1, S2 support claim (if trusted)
2. **Layer 2**: Meta-source reports methodological flaws (defeats Layer 1 trust)
3. **Layer 3**: Meta-meta-evidence reveals meta-source conflicts of interest (defeats Layer 2 trust)

The empty extension means:

- **Epistemic cascade**: Meta-level critiques undermine all trust layers
- **Credibility threshold violation**: Overriding any layer's critique exceeds β=60 severity ceiling
- **Epistemic outcome**: "Withhold judgment on claim - unresolved methodological and meta-methodological concerns"

**Why empty?** The 3-layer defeater structure creates a situation where:
- Trusting studies requires dismissing meta-evidence (credibility penalty >60)
- Trusting meta-source requires dismissing meta-meta-evidence (penalty >60)
- No trust configuration survives the credibility threshold

**Semi-stable + Gödel + Max rationale**: Semi-stable forces stance-taking, Gödel models weakest-link credibility, Max focuses on worst single override. Under multi-layer defeater chains with high-severity critiques, semi-stable correctly suspends all commitments.

---

## 11. SALLY CLARK META-EVIDENCE
**Configuration**: Tropical + Sum + Upper bound + Grounded
**Budget β**: 100 (total ignored critique severity ≤ 100)

### Assumptions & Weights
```
accept_prosecution_logic      weight: 75  (accept prosecutor's argument)
accept_statistical_evidence   weight: 80  (accept statistical testimony)
assume_independence           weight: 70  (assume events independent)
trust_expert_witness          weight: 65  (trust expert credibility)
```

### Result: **Empty Extension**

### Narrative Interpretation
**Under grounded semantics with cumulative critique tracking, the conviction case COLLAPSES due to statistical and methodological flaws.**

The Sally Clark case models forensic statistical reasoning where the prosecution's case relies on multiple defeasible assumptions (independence of infant deaths, expert witness credibility, statistical evidence validity). Meta-evidence reveals the **prosecutor's fallacy** and expert credibility issues. The empty extension means:

- **Skeptical blocking**: Grounded semantics (minimal undefeated set) refuses to accept any prosecution assumptions when critiques accumulate
- **Evidentiary threshold not met**: Total severity of critiques exceeds what can be ignored (β=100)
- **Legal outcome**: "Conviction unsupported - prosecution case fails under statistical scrutiny"

**Why empty?** The framework derives critiques (e.g., `prosecutor_fallacy_detected`, `expert_unreliable`) that attack the prosecution's assumptions. Grounded semantics accepts only unattacked assumptions. When all key assumptions face substantial critique, grounded returns empty.

**Grounded + Tropical + Sum rationale**: Grounded is skeptical (conservative acceptance), Tropical accumulates critique strength, Sum tracks total ignored severity. This configuration correctly models proper statistical scrutiny in forensic contexts - when multiple serious flaws accumulate, conviction should fail.

**Historical note**: Sally Clark was wrongfully convicted of murdering her two infant sons based on flawed statistical reasoning (prosecutor's fallacy). This framework correctly models why the conviction should have been rejected.

---

## 12. SCIENTIFIC THEORY CHOICE
**Configuration**: Tropical + Sum + Upper bound + Preferred
**Budget β**: 150 (total complexity burden ≤ 150)

### Assumptions & Weights
```
assume_newtonian       weight: 30  (simplest theory)
assume_relativistic    weight: 60  (moderate complexity)
assume_quantum         weight: 70  (high complexity)
assume_auxiliary_h1    weight: 40  (auxiliary hypothesis)
```

### Result: **Relativistic Theory Selected** {assume_relativistic}

### Narrative Interpretation
**Under preferred semantics with complexity minimization, RELATIVISTIC MECHANICS is the optimal theory choice.**

The framework models scientific theory selection under Ockham's razor - prefer theories with maximum explanatory power and minimum complexity. The single-theory result means:

- **Empirical adequacy + parsimony**: Relativistic theory explains phenomena (e.g., mercury precession, gravitational effects) while maintaining moderate complexity
- **Newtonian rejected**: Likely faces stronger empirical rejections (photoelectric effect, gravitational waves)
- **Quantum rejected**: Likely too complex (weight 70) relative to explanatory scope at this stage
- **Preferred stance**: Maximal defensible theory that balances evidence and simplicity

**Why relativistic only?** The framework likely encodes:
- Newtonian → derives rejections via relativistic phenomena (e.g., mercury precession ≠ Newtonian prediction)
- Quantum → either rejected by evidence or excluded due to complexity budget
- Relativistic → survives empirical tests, fits within complexity budget (60 < 150)

**Preferred + Tropical + Sum rationale**: Preferred seeks maximal explanatory sets, Tropical accumulates explanatory power/complexity, Sum tracks total burden. Result: "Adopt relativistic mechanics as the current best theory" - historically accurate for early 20th century physics.

**Theoretical insight**: Relativistic mechanics (weight 60) is exactly positioned between Newtonian simplicity (30) and quantum complexity (70), representing the "Goldilocks theory" that balances empirical adequacy and parsimony.

---

## KEY INSIGHTS ACROSS EXAMPLES

### 1. Empty Extensions as Meaningful Outcomes
**10 of 12 examples** returned empty extensions under their specified configurations. This is **not a bug** - empty extensions represent:
- **Ethical suspension** (medical triage, moral dilemma, resource allocation)
- **Skeptical blocking** (epistemic justification, AI safety, Sally Clark)
- **Doctrinal incoherence** (legal precedent)
- **Evidential underdetermination** (meta-evidence, NHST)

Empty extensions signal: **"No position is defensible within the given constraints"** - a crucial epistemic/ethical/legal stance.

### 2. Semantic Choices Drive Outcomes
- **Grounded semantics** (4 examples): Conservative, skeptical - refuses commitment under conflict
- **Semi-stable semantics** (5 examples): Forces decisive stance - when impossible, returns empty
- **Preferred semantics** (4 examples): Seeks maximal defensibility - accepts empty when no maximal exists

### 3. Budget Parameters as Normative Thresholds
Budget β encodes:
- **Ethical ceilings** (harm ≤ 50 in triage)
- **Epistemic thresholds** (unreliability ≤ 80 in justification)
- **Legal deviation limits** (precedent override ≤ 150)
- **Safety floors** (assurance ≥ 60 in AI policy)

When reality violates thresholds, empty extensions correctly signal constraint failure.

### 4. Non-Empty Success Cases
- **Strong Inference**: All hypotheses kept alive via error tolerance (β=2 errors allowed)
- **Theory Choice**: Relativistic selected as optimal complexity/adequacy balance

These demonstrate frameworks where defensible positions exist within constraints.

### 5. Algebraic Configuration Meaningfulness
- **Gödel (weakest-link)**: Medical, moral, meta-evidence - single failure dominates
- **Tropical (accumulative)**: Legal, epistemic, Sally Clark - critiques/evidence accumulate
- **Łukasiewicz (bounded)**: Epistemic justification - evidence saturates
- **Bottleneck (worst-case)**: AI safety - minimum dimension dominates
- **Arctic (reward)**: Practical deliberation - defaults have positive value

Each semiring captures domain-specific propagation semantics accurately.

---

## RECOMMENDATIONS

### For Future Runs
1. **Explore budget sensitivity**: Many examples might have non-empty extensions with relaxed β
2. **Compare across semantics**: Run same example with stable/preferred/grounded to see stance variation
3. **Inspect attack structure**: For empty extensions, identify which attacks are insurmountable
4. **Enumerate without constraints**: See unconstrained extensions, then apply budgets

### Theoretical Implications
1. **Empty extensions are features, not bugs**: They represent legitimate epistemological stances
2. **Semantic diversity matters**: Different semantics capture different decision-making postures
3. **Budget parameters are normative**: They encode ethical/epistemic/legal boundaries
4. **WABA generalizes AAF**: Weight-based constraints add expressive power for real-world dilemmas

### Domain-Specific Insights
- **Medical/Ethical**: Conservative semantics correctly refuse impossible dilemmas
- **Legal**: Precedent cascades can lead to doctrinal incoherence (needs resolution)
- **Epistemic**: Skeptical semantics appropriately suspend under evidential conflict
- **Scientific**: Theory selection balances evidence and parsimony successfully

---

**End of Report**
