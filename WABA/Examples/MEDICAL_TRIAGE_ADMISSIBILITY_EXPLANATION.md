# Why Non-Empty Extensions Are Not Admissible (Even With Attack Discarding)

**Date**: 2025-12-31
**Example**: Medical Triage
**Question**: Why can't we discard attacks to make non-empty extensions admissible?

---

## The Surprising Answer

**Even with unlimited attack discarding (no budget), non-empty extensions are NOT admissible** in Medical Triage.

This seems paradoxical: if we can discard any attack, why can't {C} defend itself?

---

## The Key Insight: "Undefeated" ≠ "Not In Extension"

The admissible semantics checks if assumptions are attacked by the **undefeated closure**, not just by the extension itself.

**Critical definition** (from `semantics/admissible.lp`):
```prolog
derived_from_undefeated(X) :- assumption(X), not defeated(X).
```

**This means**: An assumption is in the undefeated closure if it's **not successfully attacked**, regardless of whether it's IN or OUT of the extension!

---

## Tracing Extension {C}

Let's trace what happens for extension E = {assume_respiratory_distress}:

### Step 1: Which assumptions are defeated?

For extension {C}:
- **C is IN** (selected)
- **A and B are OUT** (not selected)

Are any attacked?
- C creates protocol_ventilation → cathlab_occupied
- No attacks fire (would need BOTH protocol AND occupied resource)
- **Result: NO assumptions are defeated!**

### Step 2: Undefeated closure

Since no assumptions are defeated:
```prolog
derived_from_undefeated(assume_severe_trauma)        % A not defeated
derived_from_undefeated(assume_cardiac_event)         % B not defeated
derived_from_undefeated(assume_respiratory_distress)  % C not defeated (even though IN!)
```

**Critical**: C is both IN the extension AND in the undefeated closure!

### Step 3: Protocols derived from undefeated

All three protocols fire from undefeated:
```prolog
triggered_by_undefeated(r1)  % r1: protocol_surgery ← A
triggered_by_undefeated(r2)  % r2: protocol_cardiac_cath ← B
triggered_by_undefeated(r3)  % r3: protocol_ventilation ← C

derived_from_undefeated(protocol_surgery)
derived_from_undefeated(protocol_cardiac_cath)
derived_from_undefeated(protocol_ventilation)
```

### Step 4: Resources occupied from undefeated

All resource conflicts arise:
```prolog
triggered_by_undefeated(r9)  % r9: icu_occupied ← protocol_surgery
triggered_by_undefeated(r7)  % r7: or_occupied ← protocol_cardiac_cath
triggered_by_undefeated(r8)  % r8: cathlab_occupied ← protocol_ventilation

derived_from_undefeated(icu_occupied)
derived_from_undefeated(or_occupied)
derived_from_undefeated(cathlab_occupied)
```

### Step 5: Unavailability attacks from undefeated

Now the attack rules fire **from the undefeated closure**:
```prolog
% r6: no_icu_available ← protocol_ventilation, icu_occupied
% BOTH are derived_from_undefeated!
triggered_by_undefeated(r6)
derived_from_undefeated(no_icu_available)

% Similarly:
derived_from_undefeated(no_or_available)
derived_from_undefeated(no_cathlab_available)
```

### Step 6: Attacked by undefeated

```prolog
% contrary(assume_respiratory_distress, no_icu_available)
attacked_by_undefeated(assume_respiratory_distress)
```

**C is attacked by the undefeated closure!**

### Step 7: Admissibility constraint violated

```prolog
:- in(X), attacked_by_undefeated(X).
```

This constraint fires: C is IN and attacked_by_undefeated.

**Extension {C} is UNSATISFIABLE under admissible semantics.**

---

## Why Attack Discarding Doesn't Help

**Question**: Can't we just discard the `no_icu_available` attack?

**Answer**: No! The admissibility check happens **before** attack discarding.

**Admissible semantics workflow**:
1. Compute which assumptions are in/out
2. Compute undefeated closure (assumptions not defeated by **actual successful attacks**)
3. Check if any IN assumption is attacked by undefeated closure
4. **If yes: REJECT (UNSAT)**
5. If no: Proceed to check attack discarding budget

**The issue**: When computing undefeated closure, we include **all assumptions that aren't successfully attacked**. For {C}, none are attacked, so ALL THREE are in the undefeated closure.

---

## The Paradox Resolved

**Why can't {C} defend itself by discarding attacks?**

Because admissibility requires defending against **potential attacks from undefeated assumptions**, not just actual attacks in the extension.

**For {C}**:
- A and B are OUT (not selected)
- A and B are undefeated (nothing attacks them in extension {C})
- Therefore A and B can derive their protocols "hypothetically"
- These hypothetical derivations create resource conflicts
- These conflicts attack C
- C cannot prevent A and B from being undefeated
- Therefore C cannot defend against this attack path
- **Not admissible**

---

## Why Empty IS Admissible

**For empty extension** ∅:
- All three assumptions are OUT
- All three are undefeated (nothing attacks them)
- All three derive protocols from undefeated
- All three resource conflicts arise
- All three unavailability attacks exist in undefeated closure:
  - `attacked_by_undefeated(assume_severe_trauma)`
  - `attacked_by_undefeated(assume_cardiac_event)`
  - `attacked_by_undefeated(assume_respiratory_distress)`

But the admissibility constraint is:
```prolog
:- in(X), attacked_by_undefeated(X).
```

**None of them are IN!** So the constraint doesn't fire.

Empty extension is admissible because it makes NO CLAIMS (nothing to defend).

---

## Formal Explanation

**Admissibility definition**: E is admissible iff it's conflict-free and defends all its members.

**Defense**: E defends X if every attacker of X is attacked by E.

**In Medical Triage**:
- Extension {C} selects assumption C
- C needs to defend against attackers from the undefeated closure
- Undefeated closure includes A and B (they're undefeated)
- A and B create attack path: A → surgery → icu_occupied + C → ventilation → (no_icu_available attacks C)
- This attack comes from **joint derivation** by A and C in undefeated closure
- {C} cannot attack A or B (they're not selected, so can't be attacked back)
- {C} cannot defend C
- **Not admissible**

---

## Comparison to Classical ABA

**In classical (unweighted) ABA**:
- Empty would also be the only admissible extension (same reasoning)
- Attack discarding doesn't exist
- Same impossibility: resource conflicts create mutual attacks

**WABA with attack discarding**:
- Attack discarding allows conflict-free extensions {C}, {A,C}, etc.
- But admissibility STILL rejects them (undefeated closure check)
- Budget constraints only matter AFTER admissibility check passes
- Medical Triage: admissibility fails regardless of budget

---

## Why This Is Correct Behavior

The admissible semantics correctly models:

1. **Defensive burden**: If you claim C is treatable, you must defend against ALL potential objections from undefeated assumptions

2. **Hypothetical reasoning**: A and B being undefeated means "we haven't ruled them out" - they can still derive consequences

3. **Resource reality**: Even if we don't treat A, its potential treatment creates resource conflicts with C

4. **Collective impossibility**: The problem isn't individual attacks - it's the **collective resource constraint** that makes all non-empty extensions indefensible

---

## Implications for Clingo Trace

The debug output confirms:

**Empty extension**:
```
out(assume_severe_trauma) out(assume_cardiac_event) out(assume_respiratory_distress)
derived_from_undefeated(assume_severe_trauma)
derived_from_undefeated(assume_cardiac_event)
derived_from_undefeated(assume_respiratory_distress)
derived_from_undefeated(protocol_surgery)
derived_from_undefeated(protocol_cardiac_cath)
derived_from_undefeated(protocol_ventilation)
derived_from_undefeated(icu_occupied)
derived_from_undefeated(or_occupied)
derived_from_undefeated(cathlab_occupied)
derived_from_undefeated(no_icu_available)
derived_from_undefeated(no_or_available)
derived_from_undefeated(no_cathlab_available)
attacked_by_undefeated(assume_severe_trauma)
attacked_by_undefeated(assume_cardiac_event)
attacked_by_undefeated(assume_respiratory_distress)
```

**All three are attacked by undefeated, but NONE are in the extension → admissible!**

---

## Answer to Original Question

**Q: How is it possible that even discarding attacks does not allow one to find non-trivial semi-stable extensions? E.g., discarding all attacks should allow any assumption to fire.**

**A: Admissibility checks attacks from the UNDEFEATED CLOSURE, not from the extension itself.**

**For {C}**:
1. C is IN, A and B are OUT
2. A, B, and C are all undefeated (no successful attacks exist)
3. All three derive protocols in the undefeated closure
4. Resource conflicts arise in the undefeated closure
5. C is attacked by undefeated closure (via joint derivation with A)
6. Admissibility constraint `:- in(X), attacked_by_undefeated(X)` rejects {C}
7. **Attack discarding is irrelevant** - the check fails before we even consider discarding

**Discarding attacks allows conflict-free extensions, but cannot make them admissible if they're attacked by undefeated assumptions.**

---

## Why Semi-Stable = Admissible Here

Since only empty is admissible:
- Semi-stable requires admissibility + maximal range
- Empty is the only admissible extension
- Therefore empty is automatically the unique semi-stable extension

**No amount of attack discarding can change this** - the problem is structural, not budgetary.

---

## Conclusion

Medical Triage demonstrates a profound theoretical point:

**Attack discarding (budget) and defensive admissibility are orthogonal concerns:**

- **Budget**: "Can we afford to override this attack?"
- **Admissibility**: "Can we defend our position against undefeated objections?"

In Medical Triage:
- Budget would allow {C} to be conflict-free (discard attacks)
- But admissibility blocks {C} (attacked by undefeated closure)
- **Result**: Only empty is admissible, regardless of budget

**This correctly models the real clinical situation**: Under resource scarcity, no patient selection is defensible because unselected patients create resource conflicts that attack selected ones.

---

**End of Explanation**
