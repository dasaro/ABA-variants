# Moral Dilemma Example

**Domain**: Normative Ethics / Medical Ethics
**Last Updated**: 2025-12-29

---

## Story

A physician faces a **trolley-problem-like scenario** involving four defeasible moral duties:

- **Beneficence** (assume_duty_beneficence): Maximize patient welfare - save as many lives as possible
- **Nonmaleficence** (assume_duty_nonmaleficence): Do no harm (primum non nocere) - don't actively cause injury
- **Autonomy** (assume_duty_autonomy): Respect patient consent - no treatment without permission
- **Justice** (assume_duty_justice): Fair distribution of care - treat patients equitably

**The Dilemma**: Five patients will die without intervention. An available intervention (sacrifice_one) would save the five but requires **sacrificing one healthy person without consent**. Inaction (do_nothing) respects autonomy and nonmaleficence but allows five to die, violating beneficence and justice.

Each duty generates action recommendations that **violate other duties**, forcing moral trade-offs.

---

## Philosophical Framing

This example models **duty conflicts in deontological ethics**. The framework captures:
- **Prima facie duties**: Moral principles that bind defeasibly (W.D. Ross)
- **Lexical priority**: Minimize the worst moral violation (not utilitarian aggregation)
- **Mediated moral conflict**: Duties conflict through their action implications, not directly
- **Moral cost**: Overriding a duty violation = accepting that moral wrong

---

## WABA Configuration

### Weight Interpretation

Weights represent **moral wrongness severity (0-100)** of violating each duty. Higher weights = more serious moral violation.

**Weight assignments**:
- `violates_beneficence`: 80 (failing to save lives)
- `violates_nonmaleficence`: 85 (actively causing harm - most serious)
- `violates_autonomy`: 75 (violating consent)
- `violates_justice`: 70 (unfair treatment)

### Semiring: Gödel (min/max)

**Justification**: An action's moral permissibility is only as strong as the **weakest duty** in its justification chain (weakest-link deontology). The moral strength of an action is limited by the weakest supporting principle.

- **Conjunction** (min): Justification strength = minimum duty weight
- **Disjunction** (max): Justification strength = maximum across alternatives
- **Identity**: #sup (perfect moral justification)

**Philosophical motivation**: Deontological ethics: a single weak moral foundation undermines the entire justification (unlike utilitarian summing).

### Monoid: Max

**Justification**: Extension cost = **worst single duty violation**. We adopt **lexical priority** (Rawlsian): minimize the worst moral wrongness, not total wrongness (least-unjust action under lexicographic ordering).

### Optimization Direction: Minimize

**Justification**: Weights represent costs (moral wrongness). We minimize to find the action with the least worst moral violation.

### Budget β: Maximum Tolerable Moral Violation

**Meaning**: Upper bound on worst duty violation allowed.
**Default**: β = 40
**Interpretation**: "No duty violation above 40 wrongness severity"

**Constraint encoding**:
```prolog
:- extension_cost(C), C > beta.
```

---

## Discarded Attack Interpretation

**What does it mean to discard an attack?**

When we discard the attack `violates_autonomy` → `assume_duty_autonomy`, we are:
- **Accepting moral cost**: Acknowledging we violate autonomy
- **Committing the wrong**: Proceeding with the action despite the violation
- **Incurring wrongness**: Cost = weight(violates_autonomy) = 75

In general: Overriding a duty violation = accepting that moral cost (committing that moral wrong).

---

## Structure Details

### Assumptions (Defeasible Moral Duties)

```prolog
assumption(assume_duty_beneficence).     % Maximize welfare
assumption(assume_duty_nonmaleficence).  % Do no harm
assumption(assume_duty_autonomy).        % Respect consent
assumption(assume_duty_justice).         % Fair distribution
```

### Derived Atoms

**Action Recommendations**:
- `recommend_sacrifice_one` - Action: sacrifice one to save five
- `recommend_inaction` - Action: do nothing

**Duty Violations** (contraries):
- `violates_beneficence` - Welfare maximization violated
- `violates_nonmaleficence` - Harm principle violated
- `violates_autonomy` - Consent violated
- `violates_justice` - Fairness violated

**Situational Facts**:
- `situational_five_at_risk` - Five patients will die without intervention
- `situational_one_healthy` - One healthy person available

### Contraries (Duty-Specific Violations)

```prolog
contrary(assume_duty_beneficence, violates_beneficence).
contrary(assume_duty_nonmaleficence, violates_nonmaleficence).
contrary(assume_duty_autonomy, violates_autonomy).
contrary(assume_duty_justice, violates_justice).
```

### Rule Structure (Mixed Bodies)

**Example**: Rule r5 derives autonomy violation from action (derived) + duty (assumption):

```prolog
head(r5, violates_autonomy).
body(r5, recommend_sacrifice_one).  % Derived: action recommendation
body(r5, assume_duty_autonomy).     % Assumption: autonomy duty
```

This demonstrates **mixed rule bodies**: violations derived from both action recommendations and moral commitments.

---

## Running the Example

### Basic Usage (Stable Semantics, β = 40)

```bash
clingo -n 0 --opt-mode=opt -c beta=40 \
  WABA/core/base.lp \
  WABA/semiring/godel.lp \
  WABA/monoid/max_minimization.lp \
  WABA/filter/standard.lp \
  WABA/semantics/stable.lp \
  WABA/examples/moral_dilemma/moral_dilemma.lp
```

### Enumerate All Moral Options

```bash
clingo -n 0 -c beta=40 \
  WABA/core/base.lp \
  WABA/semiring/godel.lp \
  WABA/monoid/max_minimization.lp \
  WABA/filter/standard.lp \
  WABA/semantics/stable.lp \
  WABA/examples/moral_dilemma/moral_dilemma.lp
```

### Vary Budget (Explore Moral Thresholds)

```bash
# Strict morality (β = 30): Very limited violations acceptable
clingo -n 0 --opt-mode=opt -c beta=30 [... same modules ...]

# Moderate (β = 40): Default balance
clingo -n 0 --opt-mode=opt -c beta=40 [... same modules ...]

# Permissive (β = 85): Higher violations tolerable (utilitarian-leaning)
clingo -n 0 --opt-mode=opt -c beta=85 [... same modules ...]
```

---

## Expected Behavior

### With β = 40:
- **UNSAT** or very limited solutions
- Both actions (sacrifice_one, inaction) violate serious duties (70-85 severity)
- β = 40 excludes all major violations → likely no admissible action (tragic dilemma)

### With β = 70:
- **SAT**: Can tolerate moderate violations
- May favor inaction (violates justice @ 70) over sacrifice (violates autonomy @ 75, nonmaleficence @ 85)

### With β = 85:
- **Multiple solutions**: Can tolerate even nonmaleficence violations
- Explores full trade-off space between sacrifice and inaction

---

## Design Compliance

This example adheres to all WABA design principles:

✅ **Defeasible assumptions**: Moral duties are prima facie, not absolute
✅ **No direct assumption attacks**: Duties conflict via action implications
✅ **Meaningful derived atoms**: Actions and violations are logical/moral consequences
✅ **Flat structure**: Assumptions only in rule bodies
✅ **Explicit weight interpretation**: Moral wrongness clearly defined
✅ **Justified semiring**: Gödel captures weakest-link deontology
✅ **Justified monoid**: Max captures lexical priority (minimize worst violation)
✅ **Justified direction**: Minimize moral wrongness
✅ **Operational β**: Constraint enforces upper bound on worst violation
✅ **Specific contraries**: Duty-specific violations (not generic "moral_wrong")
✅ **Mixed rule bodies**: Violations from actions + duties

---

## Pedagogical Notes

This example illustrates:
- **Ross's prima facie duties**: Defeasible moral principles that can conflict
- **Deontological constraints**: Some wrongs cannot be traded off (lexical priority)
- **Trolley problem structure**: Sacrifice vs. inaction trade-offs
- **Gödel semiring**: Weakest-link moral reasoning (not utilitarian aggregation)
- **Max monoid**: Worst-case moral evaluation (lexicographic justice)

---

## References

- Ross, W. D. (1930). *The Right and the Good*. Oxford University Press. (Prima facie duties)
- Foot, P. (1967). "The Problem of Abortion and the Doctrine of the Double Effect." *Oxford Review*, 5, 5-15. (Trolley problem)
- Thomson, J. J. (1985). "The Trolley Problem." *Yale Law Journal*, 94(6), 1395-1415.
- Rawls, J. (1971). *A Theory of Justice*. Harvard University Press. (Lexical priority, maximin)
- Beauchamp, T. L., & Childress, J. F. (2019). *Principles of Biomedical Ethics* (8th ed.). Oxford University Press. (Four principles)
