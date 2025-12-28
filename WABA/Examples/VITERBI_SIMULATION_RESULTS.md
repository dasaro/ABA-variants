# Viterbi Semiring Simulation via Tropical Semiring

## Summary

**Yes, we can simulate the Viterbi semiring using Tropical + log transformation!**

The Viterbi semiring (×, max) for probabilities is mathematically equivalent to the Tropical semiring (+, min) for costs under the transformation: **cost = -log(probability)**.

## Mathematical Correspondence

| Viterbi Operation | Tropical Equivalent | Transformation |
|-------------------|---------------------|----------------|
| p₁ × p₂ (multiply probabilities) | cost₁ + cost₂ (add costs) | -log(p₁ × p₂) = -log(p₁) + (-log(p₂)) |
| max(p₁, p₂) (best evidence) | min(cost₁, cost₂) (cheapest path) | -log(max(p₁, p₂)) = min(-log(p₁), -log(p₂)) |
| High probability (p → 1) | Low cost (cost → 0) | -log(1) = 0 |
| Low probability (p → 0) | High cost (cost → ∞) | -log(0) = ∞ |

## Test Example: Medical Diagnosis

**Framework**: `examples/viterbi_simulation.lp`

**Scenario**: Choose between 3 competing diagnoses based on symptom evidence:
- FLU: fever(0.90) × cough(0.85) × fatigue(0.70) = **0.536** → cost=625
- COVID: fever(0.90) × cough(0.85) × headache(0.75) = **0.574** → cost=556
- COLD: cough(0.85) × fatigue(0.70) = **0.595** → cost=520 ✓ **BEST**

## Configuration

**(Tropical, MIN, LB, Stable)**

- **Semiring**: `tropical.lp` - Simulates probability multiplication via cost addition
- **Monoid**: `min.lp` - Not actually used for optimization in this encoding
- **Constraint**: `constraint/lb.lp` - Lower bound constraint
- **Semantics**: `semantics/stable.lp` - Standard stable semantics
- **Optimization**: None needed - inspect diagnosis costs directly

## Command & Results

```bash
clingo -n 0 \
  core/base.lp semiring/tropical.lp monoid/baseline/min.lp constraint/lb.lp \
  filter/standard.lp semantics/stable.lp \
  examples/viterbi_simulation.lp
```

### Output (3 Extensions Found):

```
Answer: 1
in(diagnosis_flu) supported_with_weight(diagnosis_flu,625)
extension_cost(#sup)

Answer: 2
in(diagnosis_cold) supported_with_weight(diagnosis_cold,520)  ← VITERBI OPTIMUM
extension_cost(#sup)

Answer: 3
in(diagnosis_covid) supported_with_weight(diagnosis_covid,556)
extension_cost(#sup)
```

## Interpretation

1. **Tropical semiring** correctly computes log-transformed probabilities
   - Each diagnosis cost = sum of log-transformed symptom probabilities
   - Cost 520 < 556 < 625 corresponds to probability 0.595 > 0.574 > 0.536

2. **Stable semantics** generates all valid extensions
   - Each extension keeps exactly one diagnosis (mutual exclusion)
   - Diagnoses attack each other, only one survives per extension

3. **Viterbi optimum** = extension with minimum diagnosis cost
   - **diagnosis_cold** (cost=520) is the most probable explanation
   - Corresponds to highest combined probability (0.595)

## Key Insight

The Viterbi semiring doesn't require custom implementation - **Tropical semiring with log-transformed weights is mathematically equivalent**. This is a standard technique in:
- Hidden Markov Models (Viterbi algorithm)
- Probabilistic inference
- Speech recognition
- Bioinformatics

## Why This Works

The log transformation preserves ordering:
- p₁ > p₂ ⟺ -log(p₁) < -log(p₂)
- Maximizing probability ⟺ Minimizing cost
- Best explanation = lowest-cost derivation

## Practical Applications

This technique enables probabilistic argumentation in WABA:
- **Medical diagnosis**: Evidence reliability → diagnosis probability
- **Sensor fusion**: Sensor accuracy → combined confidence
- **Legal reasoning**: Witness credibility → case strength
- **Expert systems**: Expert reliability → conclusion confidence

## Limitations

1. **Integer approximation**: We use `round(-log(p) × 1000)` for ASP integers
   - Preserves ordering but loses exact probabilities
   - Sufficient for optimization (order is what matters)

2. **No probabilistic semantics**: WABA doesn't enforce probability axioms
   - Weights are just costs, not true probabilities
   - User must ensure inputs are valid (0 < p ≤ 1)

3. **Extension selection**: User must identify lowest-cost extension
   - Could add optimization to automatically select best
   - Currently requires manual inspection of results

## Conclusion

**Viterbi semiring is fully supported via Tropical + log transformation.**

No new semiring implementation needed - the mathematical equivalence is exact. Users can model probabilistic argumentation by:
1. Transform probabilities: cost = -log(p) × 1000
2. Use Tropical semiring for weight propagation
3. Select extension with minimum total cost

This demonstrates WABA's algebraic generality: the same framework handles both resource optimization (costs) and probabilistic inference (likelihoods) through appropriate transformations.

---

## For Paper Development

**Note**: This transformation can be theoretically enriched using standard semiring theorems:
- Semiring homomorphisms (Gondran & Minoux)
- Log-domain computation (Rabiner, Manning & Schütze)
- Optimization preservation under homomorphic transformations

See `docs/PAPER_NOTES.md` for detailed references and suggested paper sections on:
- Formal proof that -log is a semiring homomorphism
- Connection to HMM literature and probabilistic inference
- Comparison to probabilistic argumentation frameworks
- Theoretical guarantees on optimization preservation
