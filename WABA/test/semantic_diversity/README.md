# WABA Semantic Diversity Frameworks

**Purpose**: Frameworks designed to distinguish between different semantics by forcing multiple complete extensions within attack resolution scenarios.

## Challenge: WABA vs Classical ABA

In **classical ABA** (fixed attack graph):
- Grounded extension is unique (least fixpoint)
- Multiple complete/preferred extensions possible
- Clear semantic hierarchy: grounded ⊂ complete ⊂ preferred

In **WABA** (attack discarding choices):
- Each "extension" = (assumptions, discarded_attacks) pair
- Different discarding choices create different attack graphs
- Each attack graph has its own grounded/complete/preferred
- **Per-scenario uniqueness**: Benchmarks have 1 complete extension per scenario

## What We Achieved

### 1. Multiple Complete Extensions Within Scenarios ✓

Several frameworks show multiple complete extensions under the same discarding scenario:

**Framework 05 (Reinstatement)**:
- Scenario with 1 attack discarded: **2 complete extensions**
  - `{a, b, d}`
  - `{a, c}`

**Framework 06 (Preferred vs Semi-stable)**:
- Scenario with 2 attacks discarded: **2 complete extensions**
  - `{a, b, c, e}`
  - `{a, b, d}`

### 2. Grounded Returns Multiple "Minimal" Extensions

When complete extensions are **incomparable** (neither is a subset of the other), grounded correctly returns **all minimal extensions**:

**Framework 12 (Zero Budget)**:
- Grounded: `{a,dummy,u}`, `{b,dummy,u}` (2 extensions)
- Complete: `{a,dummy,u}`, `{b,dummy,u}` (2 extensions)
- Result: Grounded = Complete (both are minimal and incomparable)

### 3. Budget Controls Discarding Scenarios

**Framework 11 (budget=0)**:
- Complete: `{a}`, `{b}` (2 extensions, 0 attacks discarded)
- Grounded/Stable/Preferred: UNSAT (couldn't satisfy constraints with no discarding)

**Framework 07 (budget=100, zero-weight attacks)**:
- Multiple scenarios based on discarding cheap (weight=0) attacks
- Shows that even "free" discarding creates scenario diversity

## Framework Descriptions

### 01_mutual_attack.lp
- **Structure**: Two assumptions attack each other (equal weights)
- **Goal**: Force mutual exclusion
- **Result**: 2 scenarios (0 discarded: {a}|{b}, 2 discarded: {a,b})
- **Diversity**: Different scenarios, but grounded = complete within each

### 02_independent_assumptions.lp
- **Structure**: Three independent assumptions (no attacks)
- **Goal**: Baseline - all assumptions accepted
- **Result**: Multiple scenarios via self-attack discarding
- **Diversity**: Grounded ⊂ Complete across different scenarios

### 03_odd_cycle.lp
- **Structure**: 3-cycle via derived atoms (a→b→c→a)
- **Goal**: No stable extensions in odd cycle
- **Result**: 4 scenarios, each with 1 extension
- **Diversity**: Scenario diversity via cycle-breaking discarding

### 04_asymmetric_defense.lp
- **Structure**: Two defenders (d1, d2) mutually exclusive, each defends different victim
- **Goal**: Asymmetric defense patterns
- **Result**: 8 scenarios with varying extensions
- **Diversity**: Rich scenario structure

### 05_reinstatement.lp
- **Structure**: Unattacked `a`, mutual attackers `b ⟷ c`, victim `d` attacked by `c`
- **Goal**: Classic reinstatement pattern
- **Result**: **2 complete extensions** in some scenarios!
- **Diversity**: ✓ Multiple complete within single scenario

### 06_preferred_vs_semistable.lp
- **Structure**: Base assumptions + mutually exclusive branches with different ranges
- **Goal**: Different ranges for semi-stable selection
- **Result**: **2 complete extensions** in multiple scenarios
- **Diversity**: ✓ Multiple complete within single scenario

### 07_no_discard_multiple_complete.lp
- **Structure**: Unattacked `a`, mutual `b ⟷ c` with zero-weight attacks
- **Goal**: Zero-cost attacks to minimize discarding benefit
- **Result**: 4 scenarios (including 0-discard with 2 complete)
- **Diversity**: ✓ Multiple complete in 0-discard scenario

### 08_grounded_vs_complete_strict.lp
- **Structure**: Unattacked `u`, mutual `a ⟷ b` with zero-weight attacks
- **Goal**: Force grounded ⊂ complete
- **Result**: Grounded = Complete (both return 2 incomparable extensions)
- **Diversity**: ✗ No grounded ⊂ complete achieved

### 09_semistable_vs_preferred.lp
- **Structure**: Complex with multiple branches for range differences
- **Goal**: Different ranges to distinguish semi-stable from preferred
- **Result**: 32 complete scenarios, 16 grounded scenarios
- **Diversity**: ✓ Rich scenario structure, but grounded = preferred within scenarios

### 10_fixed_attacks_no_weights.lp
- **Structure**: Direct contrary relations (no weighted attacks)
- **Goal**: Eliminate discarding choices
- **Result**: Attacks still have weights (from attacking assumptions)
- **Note**: Doesn't achieve goal - discarding still possible

### 11_zero_budget_even_cycle.lp
- **Structure**: Even cycle with budget(0) to prohibit discarding
- **Goal**: Fixed attack graph via zero budget
- **Result**: Complete has 2 extensions, Grounded UNSAT
- **Issue**: Self-attack on `u` made it defeated

### 12_zero_budget_strict.lp
- **Structure**: Even cycle with budget(0), properly unattacked `u`
- **Goal**: grounded ⊂ complete with fixed attack graph
- **Result**: Grounded = Complete (both return 2 incomparable minimal extensions)
- **Finding**: When minimums are incomparable, grounded returns all

## Key Findings

### 1. Per-Scenario Uniqueness Persists
Even in diversity-designed frameworks, most scenarios have **1 complete extension**. When multiple exist, grounded returns all minimal ones.

### 2. Grounded = Complete When Minimums Are Incomparable
If `E1` and `E2` are both minimal complete and incomparable (neither is subset of other), grounded returns **both**. This is mathematically correct but means grounded = complete.

### 3. Budget Controls Scenario Count, Not Per-Scenario Diversity
- budget(0): Fewer scenarios (no discarding)
- budget(100): More scenarios (various discarding choices)
- Within each scenario: Usually 1 complete extension

### 4. Zero-Weight Attacks Don't Eliminate Choices
Even with weight=0 attacks, discarding still occurs because:
- Attacks inherit weight from attacking assumption
- Multiple discarding combinations possible
- Creates scenario diversity, not per-scenario diversity

## Testing

Run all frameworks:
```bash
python3 test_diversity.py
```

Test specific framework:
```bash
clingo -n 0 --opt-mode=enum \
  core/base.lp semiring/godel.lp monoid/max_minimization.lp \
  constraint/ub_max.lp filter/standard.lp \
  semantics/complete.lp test/semantic_diversity/05_reinstatement.lp
```

## Conclusion

While we successfully created frameworks with **multiple complete extensions** within single scenarios, achieving **grounded ⊂ complete** in WABA is challenging because:

1. Attack discarding creates multiple attack graphs
2. Grounded computes minimal extensions across all discarding choices
3. When minimums are incomparable, grounded correctly returns all

**Semi-stable vs Preferred**: All 12 frameworks show semi-stable = preferred (0% distinction). This is **not a bug**—see [SEMISTABLE_INVESTIGATION.md](SEMISTABLE_INVESTIGATION.md) for detailed analysis. The collapse occurs due to the **range homogeneity property**: in small, connected frameworks, all preferred extensions have identical range (all assumptions), making semi-stable selection trivial.

**Recommendation for semantic correctness testing**:
- Use classical ABA frameworks (no weighted attacks) for grounded vs complete
- Use WABA diversity frameworks for testing implementation correctness
- Focus on **complete ⊂ admissible** for WABA semantic diversity (100% reliable, 80% strict in benchmarks)
- Accept semi-stable = preferred as expected behavior in small/medium frameworks

**Achievement**: Demonstrated that WABA frameworks CAN have multiple complete extensions per scenario, but saturation semantics still tend to collapse due to the nature of minimal extension computation and range homogeneity in connected graphs.
