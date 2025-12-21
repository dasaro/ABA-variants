# WABA Semirings: Current and Potential

## Currently Implemented

| Name | Domain | ⊗ (AND/Conjunction) | ⊕ (OR/Disjunction) | 0_S | 1_S | Use Case |
|------|--------|---------------------|-----------------------|-----|-----|----------|
| **Gödel** | ℤ ∪ {±∞} | min | max | #inf | #sup | Fuzzy logic, weakest-link reasoning |
| **Tropical** | ℤ ∪ {±∞} | + | min | #sup | 0 | Shortest path, additive costs |
| **Łukasiewicz** | ℤ ∪ {±∞} | max(#inf, a+b-K) | min(K, a+b) | #inf | #sup | Bounded fuzzy logic, gradual accumulation |

## Potential New Semirings

### 1. Probabilistic/Algebraic Semirings

| Name | Domain | ⊗ (AND) | ⊕ (OR) | 0_S | 1_S | Use Case |
|------|--------|---------|--------|-----|-----|----------|
| **Viterbi** | [0,1] or ℝ⁺ | × | max | 0 | 1 | Probabilistic reasoning, independent events |
| **Product** | [0,1] or ℝ⁺ | × | + | 0 | 1 | Bayesian inference, probability accumulation |
| **Log-space** | ℝ ∪ {±∞} | + | log(e^a + e^b) | -∞ | 0 | Numerical stability for probabilities |

### 2. Dual/Inverted Semirings

| Name | Domain | ⊗ (AND) | ⊕ (OR) | 0_S | 1_S | Use Case |
|------|--------|---------|--------|-----|-----|----------|
| **Arctic (Max-Plus)** | ℤ ∪ {-∞} | + | max | -∞ | 0 | Longest path, reward maximization |
| **Dual-Gödel** | ℤ ∪ {±∞} | max | min | #sup | #inf | Security levels, access control |
| **Bottleneck** | ℤ ∪ {±∞} | min | max | #sup | #inf | Capacity constraints, quality thresholds |

### 3. Counting/Provenance Semirings

| Name | Domain | ⊗ (AND) | ⊕ (OR) | 0_S | 1_S | Use Case |
|------|--------|---------|--------|-----|-----|----------|
| **Counting** | ℕ ∪ {∞} | × | + | 0 | 1 | Count derivation paths |
| **Tropical-Counting** | ℤ×ℕ | (a₁+b₁, a₂×b₂) | min-lex | (#sup,0) | (0,1) | Cost + count of optimal paths |
| **Provenance-Poly** | Polynomials | × | + | 0 | 1 | Track which facts contributed |

### 4. Multi-Criteria Semirings

| Name | Domain | ⊗ (AND) | ⊕ (OR) | 0_S | 1_S | Use Case |
|------|--------|---------|--------|-----|-----|----------|
| **Lexicographic-SR** | ℤ² | (min(a₁,b₁), a₂+b₂) | lex-max | (#inf,#sup) | (#sup,0) | Primary criterion + tiebreaker |
| **Pareto** | ℤⁿ | component-wise min | Pareto frontier | (#inf,...) | (#sup,...) | Multi-objective optimization |

### 5. Specialized Fuzzy T-norms

| Name | Domain | ⊗ (AND) | ⊕ (OR) | 0_S | 1_S | Use Case |
|------|--------|---------|--------|-----|-----|----------|
| **Hamacher** | [0,1] | ab/(a+b-ab) | (a+b-2ab)/(1-ab) | 0 | 1 | Fuzzy logic variant |
| **Yager** | [0,1] | max(0, 1-((1-a)ᵖ+(1-b)ᵖ)^(1/p)) | min(1, (aᵖ+bᵖ)^(1/p)) | 0 | 1 | Parameterized fuzzy family |
| **Einstein** | [0,1] | ab/(1+(1-a)(1-b)) | (a+b)/(1+ab) | 0 | 1 | Relativistic fuzzy logic |

### 6. Discrete/Qualitative Semirings

| Name | Domain | ⊗ (AND) | ⊕ (OR) | 0_S | 1_S | Use Case |
|------|--------|---------|--------|-----|-----|----------|
| **Ordinal** | {1,2,3,4,5} | min | max | 1 | 5 | Likert scales, qualitative ratings |
| **Boolean** | {0,1} | min (AND) | max (OR) | 0 | 1 | Classical logic (subsumed by Gödel) |

## Compatibility Notes

- **Viterbi vs Tropical**: Dual relationship (× ↔ +, max ↔ min)
- **Arctic vs Tropical**: Dual with negated weights
- **Gödel includes Boolean**: Boolean is just Gödel restricted to {0,1}
- **Fuzzy t-norms**: All satisfy same axioms, differ in interpolation behavior

## Implementation Priorities

### High Priority (Most Useful)
1. **Viterbi**: Probabilistic reasoning is common in AI
2. **Counting**: Provenance tracking valuable for explanation
3. **Arctic**: Natural for reward/benefit maximization scenarios

### Medium Priority (Niche but Interesting)
4. **Dual-Gödel**: Useful for access control, security scenarios
5. **Log-space**: Numerical stability for probability computations
6. **Hamacher**: Alternative fuzzy semantics

### Low Priority (Academic Interest)
7. **Provenance-Poly**: Complex, mainly for database provenance
8. **Pareto**: Multi-objective, but conflicts with linear optimization
9. **Yager/Einstein**: Specialized fuzzy variants

## ASP Implementation Challenges

| Semiring | Challenge | Workaround |
|----------|-----------|------------|
| Viterbi | Multiplication not native in ASP | Use log-space or fixed-precision integers |
| Log-space | Floating-point operations | Approximate with fixed-precision |
| Provenance-Poly | Symbolic manipulation | Represent polynomials as lists |
| Pareto | No total ordering | Use Pareto-optimal filtering |
| Hamacher/Einstein | Division, complex formulas | Precompute tables or approximate |

## Semantic Considerations

### Epistemic (Belief) Semirings
- Gödel, Łukasiewicz, Viterbi, Fuzzy t-norms
- Weights = degrees of certainty/truth

### Ontic (Resource) Semirings  
- Tropical, Arctic, Bottleneck
- Weights = costs, rewards, capacities

### Hybrid Semirings
- Tropical-Counting: Cost + provenance
- Lexicographic-SR: Primary + secondary criteria
