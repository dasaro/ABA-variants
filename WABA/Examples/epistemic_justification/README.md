# Epistemic Justification Example

**Domain**: Epistemology / Belief Revision
**Last Updated**: 2025-12-29

---

## Story

An agent receives **conflicting perceptual reports** about the same event (whether it is raining):

- **Visual perception** says it's raining (assume_visual_rain)
- **Auditory perception** says no rain sounds (assume_audio_no_rain)
- **Tactile perception** says ground feels wet (assume_tactile_wet)
- **Weather forecast** (testimony) says it will stay dry (assume_forecast_dry)

These four defeasible sensory observations, combined with background theories (rain wets ground, rain is audible), generate predictions that **contradict each other**. The agent must revise some perceptual beliefs to maintain **epistemic coherence**.

---

## Philosophical Framing

This example models **coherentist belief revision** under perceptual conflict. The framework captures:
- **Defeasible perception**: Sensory observations are prima facie justified but not incorrigible
- **Theory-mediated conflict**: Perceptions conflict through their theoretical implications, not directly
- **Epistemic cost**: Rejecting evidence incurs cost proportional to the source's reliability
- **Bounded evidence accumulation**: Łukasiewicz semiring models diminishing epistemic returns

---

## WABA Configuration

### Weight Interpretation

Weights represent **epistemic unreliability (0-100)** of sensory sources. Higher weights = less reliable source.

**Weight assignments**:
- `assume_visual_rain`: 20 (vision relatively reliable)
- `assume_audio_no_rain`: 30 (hearing moderately reliable)
- `assume_tactile_wet`: 25 (touch relatively reliable)
- `assume_forecast_dry`: 40 (forecasts least reliable - predictions, not observations)

### Semiring: Łukasiewicz (K=100)

**Justification**: Evidence **accumulates but saturates**. Multiple pieces of evidence supporting a belief increase its strength, but with **diminishing returns** (bounded support models epistemic saturation - additional evidence beyond a threshold provides minimal extra justification).

**Łukasiewicz algebra**:
- **Conjunction** (bounded sum): `min(K, sum of weights)` - evidence combines but caps at K
- **Disjunction** (bounded sum): `max(0, sum - (n-1)×K)` - alternative paths
- **Identity**: K (maximum certainty)
- **K parameter**: 100 (default, override via `-c k=N`)

**Philosophical motivation**: Captures foundationalist intuition that evidence has limits - you can't achieve infinite certainty by piling on more evidence.

### Monoid: Sum

**Justification**: Extension cost = **total epistemic unreliability** of discarded conflicts. We sum the unreliability weights of all evidence we reject.

### Optimization Direction: Minimize

**Justification**: Weights represent costs (unreliability). We minimize total unreliability to find the most epistemically secure belief set.

### Budget β: Maximum Acceptable Unreliability

**Meaning**: Upper bound on total unreliability of discarded evidence.
**Default**: β = 80
**Interpretation**: "Total unreliability of rejected evidence ≤ 80"

**Constraint encoding**:
```prolog
:- budget constraint via constraint/ub_*.lp files.
```

---

## Discarded Attack Interpretation

**What does it mean to discard an attack?**

When we discard the attack `contradicts_visual_evidence` → `assume_visual_rain`, we are:
- **Accepting unreliability**: Acknowledging the visual evidence is unreliable
- **Rejecting the conflict**: Maintaining belief in visual rain despite contradiction
- **Incurring epistemic cost**: Cost = weight(contradicts_visual_evidence) = 20

In general: Overriding a conflict = accepting that evidence source is unreliable (cost = unreliability weight).

---

## Structure Details

### Assumptions (Defeasible Perceptual Beliefs)

```prolog
assumption(assume_visual_rain).      % Visual: raining
assumption(assume_audio_no_rain).    % Auditory: no rain sounds
assumption(assume_tactile_wet).      % Tactile: wet ground
assumption(assume_forecast_dry).     % Testimony: forecast dry
```

### Derived Atoms

**Theoretical Predictions**:
- `predict_wet_ground` - Theory: rain → wet ground
- `predict_rain_sounds` - Theory: rain → audible

**Background Theories**:
- `theory_rain_wets_ground` - Standing belief
- `theory_rain_is_audible` - Standing belief

**Evidential Conflicts** (contraries):
- `contradicts_visual_evidence` - Visual perception challenged
- `contradicts_audio_evidence` - Auditory perception challenged
- `contradicts_tactile_evidence` - Tactile perception challenged
- `contradicts_forecast` - Forecast challenged

### Contraries (Evidence-Specific Conflicts)

```prolog
contrary(assume_visual_rain, contradicts_visual_evidence).
contrary(assume_audio_no_rain, contradicts_audio_evidence).
contrary(assume_tactile_wet, contradicts_tactile_evidence).
contrary(assume_forecast_dry, contradicts_forecast).
```

### Rule Structure (Mixed Bodies)

**Example**: Rule r1 derives prediction from perception (assumption) + background theory (derived):

```prolog
head(r1, predict_wet_ground).
body(r1, assume_visual_rain).        % Assumption: visual perception
body(r1, theory_rain_wets_ground).   % Derived: background theory
```

This demonstrates **mixed rule bodies**: predictions from both perceptual beliefs and theoretical commitments.

**Łukasiewicz accumulation example**: If multiple evidence sources support a belief, their strengths combine via bounded sum (saturating at K=100).

---

## Running the Example

### Basic Usage (Stable Semantics, β = 80, K = 100)

```bash
clingo -n 0 --opt-mode=opt -c beta=80 -c k=100 \
  WABA/core/base.lp \
  WABA/semiring/lukasiewicz.lp \
  WABA/monoid/sum_minimization.lp \
  WABA/constraint/ub_sum.lp \
  WABA/filter/standard.lp \
  WABA/semantics/stable.lp \
  WABA/examples/epistemic_justification/epistemic_justification.lp
```

### Enumerate All Coherent Belief Sets

```bash
clingo -n 0 -c beta=80 -c k=100 \
  WABA/core/base.lp \
  WABA/semiring/lukasiewicz.lp \
  WABA/monoid/sum_minimization.lp \
  WABA/constraint/ub_sum.lp \
  WABA/filter/standard.lp \
  WABA/semantics/stable.lp \
  WABA/examples/epistemic_justification/epistemic_justification.lp
```

### Vary Budget (Explore Epistemic Trade-offs)

```bash
# Strict coherence (β = 50): Reject only very unreliable evidence
clingo -n 0 --opt-mode=opt -c beta=50 -c k=100 [... same modules ...]

# Moderate (β = 80): Default balance
clingo -n 0 --opt-mode=opt -c beta=80 -c k=100 [... same modules ...]

# Permissive (β = 120): Allow more unreliable evidence to be rejected
clingo -n 0 --opt-mode=opt -c beta=120 -c k=100 [... same modules ...]
```

### Vary K (Saturation Threshold)

```bash
# Low saturation (K = 50): Evidence saturates quickly
clingo -n 0 --opt-mode=opt -c beta=80 -c k=50 [... same modules ...]

# High saturation (K = 200): Evidence can accumulate more
clingo -n 0 --opt-mode=opt -c beta=80 -c k=200 [... same modules ...]
```

---

## Expected Behavior

### With β = 80, K = 100:
- **SAT** with coherent belief sets
- Likely rejects least reliable sources (forecast, hearing) to maintain coherence
- Extension cost ≤ 80 (total unreliability of rejected evidence)

### With β = 50 (Strict):
- **More constrained**: Can only reject very unreliable evidence
- May force agent to maintain inconsistent beliefs (UNSAT if all coherence requires > 50 unreliability rejection)

### With β = 120 (Permissive):
- **More solutions**: Can reject more evidence to achieve coherence
- Explores trade-offs between different coherence strategies

---

## Design Compliance

This example adheres to all WABA design principles:

✅ **Defeasible assumptions**: Perceptual beliefs are tentative, not incorrigible
✅ **No direct assumption attacks**: Perceptions conflict via theoretical predictions
✅ **Meaningful derived atoms**: Predictions and conflicts are logical consequences
✅ **Flat structure**: Assumptions only in rule bodies
✅ **Explicit weight interpretation**: Epistemic unreliability clearly defined
✅ **Justified semiring**: Łukasiewicz captures bounded evidence accumulation
✅ **Justified monoid**: Sum captures total epistemic cost
✅ **Justified direction**: Minimize unreliability
✅ **Operational β**: Constraint enforces upper bound on total unreliability
✅ **Specific contraries**: Evidence-specific conflicts, not generic "incoherence_detected"
✅ **Mixed rule bodies**: Predictions from perceptions + background theories

---

## Pedagogical Notes

This example illustrates:
- **Coherentism**: Beliefs justified by mutual support and coherence
- **Theory-ladenness of observation**: Perceptual conflicts mediated by theoretical predictions
- **Łukasiewicz logic**: Bounded evidence accumulation (saturation principle)
- **Epistemic conservatism**: Minimize belief revision (minimize rejected evidence)

---

## References

- BonJour, L. (1985). *The Structure of Empirical Knowledge*. Harvard University Press. (Coherentism)
- Quine, W. V. O., & Ullian, J. S. (1978). *The Web of Belief* (2nd ed.). Random House. (Belief revision conservatism)
- Hájek, P. (1998). *Metamathematics of Fuzzy Logic*. Springer. (Łukasiewicz logic)
- Hansson, S. O. (1999). *A Textbook of Belief Dynamics: Theory Change and Database Updating*. Kluwer. (Formal belief revision)
