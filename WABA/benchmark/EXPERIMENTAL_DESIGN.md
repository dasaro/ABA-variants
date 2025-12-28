# WABA Benchmark Suite - Experimental Design

**Version:** 2.0
**Date:** 2025-12-28
**Status:** DRAFT - Awaiting Implementation

---

## Executive Summary

This document defines a scientifically rigorous, reproducible benchmark suite for WABA (Weighted Assumption-Based Argumentation) that eliminates confounding variables and ensures balanced coverage of the experimental space.

**Key Improvements over v1.0:**
- ✓ Full factorial design with balanced coverage
- ✓ Deterministic reproducibility (master seed → per-instance seeds)
- ✓ Comprehensive metadata tracking (JSONL + CSV)
- ✓ Support for both ≤ and ≥ constraint operators
- ✓ Eliminated topology × weight scheme confounding
- ✓ NO budget/1 predicates in .lp files (metadata only)
- ✓ Configurable via CLI (no hardcoded parameters)
- ✓ Parallelized execution with timeouts

---

## 1. Experimental Design Choice: **Stratified Factorial Sampling**

### Rationale

**Full Factorial is Prohibitive:**
- 6 topologies × 8 A-values × 6 R-values × 4 D-values × 8 weight schemes × 3 budgets × 5 semirings × 4 monoids × 2 operators = **1,105,920 configurations**
- At 1s/config (optimistic), this would take **307 hours** (12.8 days)
- With replicates (K=3): **921 hours** (38 days)

**Chosen Design: Stratified Factorial Sampling**
- **Within each topology**: Full factorial over (A, R, D, weight_scheme) with K replicates
- **Across topologies**: Same A/R/D/weight grids ensure balanced comparisons
- **Sampling strategy**: Latin Hypercube Sampling (LHS) to ensure even coverage
- **Budget levels**: Systematic (not random) - test each level equally

**Estimated Runtime:**
- 6 topologies × 5 A × 3 R × 2 D × 4 weights × 2 budgets × 3 replicates = **4,320 frameworks**
- 4,320 frameworks × (5 semirings × 4 monoids × 2 operators) = **172,800 solver runs**
- At 0.5s/run (median): **24 hours**
- At 2s/run (pessimistic): **96 hours** (4 days)

---

## 2. Experimental Factors

### Independent Variables (Factors)

| Factor | Levels | Type | Notes |
|--------|--------|------|-------|
| **Topology** | 6 | Categorical | linear, tree, cycle, complete, mixed, isolated |
| **A (assumptions)** | 5 | Discrete | [5, 10, 15, 20, 25] |
| **R (rules per assumption)** | 3 | Discrete | [1, 3, 5] |
| **D (derivation depth)** | 2 | Discrete | [1, 2] |
| **Weight scheme** | 4 | Categorical | uniform, power_law, bimodal, sparse |
| **Budget level** | 2 | Categorical | tight (50% of max), loose (100% of max) |
| **Constraint operator** | 2 | Categorical | ≤ (upper bound), ≥ (lower bound) |
| **Semiring** | 5 | Categorical | godel, tropical, arctic, lukasiewicz, bottleneck_cost |
| **Monoid** | 4 | Categorical | sum, max, min, count |
| **Replicate** | 3 | Discrete | [1, 2, 3] for statistical robustness |

**Total Framework Instances:** 6 × 5 × 3 × 2 × 4 × 2 × 3 = **4,320 unique .lp files**
**Total Solver Runs:** 4,320 × 5 × 4 × 2 = **172,800 runs**

### Dependent Variables (Measurements)

- **Solver status**: SATISFIABLE / UNSATISFIABLE / TIMEOUT / ERROR
- **Total time**: Wall-clock seconds
- **Grounding time**: Seconds in grounding phase
- **Solving time**: Seconds in solving phase
- **Models found**: Count
- **Grounding size**: Atoms, rules, bodies, variables, constraints
- **First model time**: Seconds to first solution
- **Optimization time**: Seconds to prove optimality (if applicable)

---

## 3. Balanced Design Constraints

### Eliminate Confounding

**OLD CONFOUNDING (v1.0):**
- Linear topology used `[sparse_uniform, dense_varied]` weights
- Tree topology used `[sparse_narrow, dense_uniform]` weights
- → **Cannot separate weight effect from topology effect**

**NEW DESIGN (v2.0):**
- ALL topologies use the SAME 4 weight schemes: `[uniform, power_law, bimodal, sparse]`
- ALL topologies use the SAME A/R/D grids
- Budget is SYSTEMATIC (not random): [tight, loose] tested equally

### Orthogonal Factor Assignment

**Principle:** Every level of factor X appears equally often with every level of factor Y.

**Example Check (Topology × Weight):**
```
                  uniform  power_law  bimodal  sparse
linear                N         N        N       N
tree                  N         N        N       N
cycle                 N         N        N       N
complete              N         N        N       N
mixed                 N         N        N       N
isolated              N         N        N       N

where N = (5 A × 3 R × 2 D × 2 budgets × 3 reps) = 180
```

All cells have the same count (180) → **Perfectly balanced**.

---

## 4. Reproducibility Protocol

### Master Seed System

**Seeding Hierarchy:**
```
CLI: --seed MASTER_SEED (default: 42)
  ├─ Framework generation seed: hash(MASTER_SEED, topology, config_index)
  │   ├─ Topology structure seed: hash(gen_seed, "topology")
  │   ├─ Weight assignment seed: hash(gen_seed, "weights")
  │   └─ Budget selection seed: hash(gen_seed, "budget")
  └─ Replicate seed: hash(MASTER_SEED, topology, config, replicate_id)
```

**Implementation:**
```python
def derive_seed(master_seed: int, *components: str) -> int:
    """Deterministic seed derivation via SHA256."""
    import hashlib
    h = hashlib.sha256()
    h.update(str(master_seed).encode())
    for c in components:
        h.update(str(c).encode())
    return int.from_bytes(h.digest()[:4], 'big')
```

**NO random.seed() calls in helper functions** - all randomness via explicit RNG objects:
```python
rng = random.Random(derived_seed)
value = rng.choice([...])
```

### Metadata Tracking

**Per-Framework Metadata (JSON sidecar):**
```json
{
  "framework_id": "linear_a10_r3_d1_uniform_tight_rep1",
  "topology": "linear",
  "parameters": {
    "A": 10,
    "R": 3,
    "D": 1,
    "weight_scheme": "uniform",
    "budget_level": "tight",
    "replicate": 1
  },
  "seeds": {
    "master": 42,
    "framework": 2847561938,
    "topology": 3928475612,
    "weights": 1928374651
  },
  "generated": {
    "assumptions": 10,
    "rules": 30,
    "derived_atoms": 15,
    "contraries": 10,
    "max_body_size": 3,
    "attack_edges": 42
  },
  "budget_metadata": {
    "max_cost": 1000,
    "tight_threshold": 500,
    "loose_threshold": 1000,
    "selected_level": "tight"
  },
  "file_path": "benchmark/frameworks/linear/linear_a10_r3_d1_uniform_tight_rep1.lp",
  "timestamp": "2025-12-28T12:30:00Z",
  "generator_version": "2.0.0",
  "git_commit": "a1b2c3d4"
}
```

**Per-Solver-Run Metadata (JSONL):**
```json
{
  "run_id": "linear_a10_r3_d1_uniform_tight_rep1_godel_sum_ub",
  "framework_id": "linear_a10_r3_d1_uniform_tight_rep1",
  "solver_config": {
    "semiring": "godel",
    "monoid": "sum",
    "operator": "≤",
    "semantics": "stable"
  },
  "clingo_command": "clingo -n 0 --time-limit=120 ...",
  "status": "SATISFIABLE",
  "timing": {
    "total": 1.234,
    "grounding": 0.456,
    "solving": 0.778,
    "first_model": 0.100
  },
  "grounding_stats": {
    "atoms": 1024,
    "rules": 512,
    "bodies": 256,
    "variables": 128,
    "constraints": 64
  },
  "models": 42,
  "timestamp": "2025-12-28T12:31:00Z"
}
```

---

## 5. Implementation Phases

### Phase 1: Seed Plumbing & Metadata (Week 1)
- [ ] Implement `derive_seed()` function
- [ ] Refactor generators to use RNG objects (not global `random.seed()`)
- [ ] Add `--seed` CLI flag to all scripts
- [ ] Create metadata JSON writers
- [ ] Add git commit hash to metadata

### Phase 2: Balanced Configuration Generator (Week 1)
- [ ] Implement stratified factorial sampler
- [ ] Add `--dry-run` mode to print configuration matrix
- [ ] Validate balance (equal counts per factor level)
- [ ] Add CLI flags: `--A-list`, `--R-list`, `--D-list`, etc.

### Phase 3: Instance Generation Updates (Week 2)
- [ ] Remove budget/1 predicate emission from `lp_writer.py`
- [ ] Add budget metadata to JSON sidecar
- [ ] Implement systematic budget selection (no randomness)
- [ ] Add structural sanity checks (SCC count, attack density)
- [ ] Generate metadata JSON alongside each .lp file

### Phase 4: Benchmark Runner (Week 2)
- [ ] Create `benchmark_runner.py` with parallelization
- [ ] Implement timeout handling (kill clingo after timeout)
- [ ] Support both ≤ and ≥ constraint operators
- [ ] Write results to `results.jsonl` + `summary.csv`
- [ ] Add progress bar and ETA

### Phase 5: Smoke Tests & Validation (Week 2)
- [ ] Create `smoke_test.sh` (tiny subset, <2 min)
- [ ] Run full benchmark on dev machine (estimate runtime)
- [ ] Validate reproducibility (same seed → same outputs)
- [ ] Generate summary statistics and plots

---

## 6. CLI Interface

### Framework Generation

```bash
python benchmark_runner.py generate \
  --seed 42 \
  --topologies linear,tree,cycle,complete,mixed,isolated \
  --A-list 5,10,15,20,25 \
  --R-list 1,3,5 \
  --D-list 1,2 \
  --weight-schemes uniform,power_law,bimodal,sparse \
  --budget-levels tight,loose \
  --replicates 3 \
  --output-dir benchmark/frameworks_v2 \
  --dry-run  # Print matrix, don't generate
```

### Solver Execution

```bash
python benchmark_runner.py run \
  --frameworks benchmark/frameworks_v2 \
  --semirings godel,tropical,arctic,lukasiewicz,bottleneck_cost \
  --monoids sum,max,min,count \
  --operators ub,lb  # ≤ and ≥
  --semantics stable \
  --timeout 120 \
  --max-workers 8 \
  --output results_v2.jsonl \
  --summary summary_v2.csv \
  --early-stop-timeout-rate 0.5  # Stop if 50% timeout
```

### Smoke Test

```bash
python benchmark_runner.py smoke-test \
  --seed 42 \
  --timeout 10 \
  # Runs 2 topologies × 2 A × 1 R × 1 D × 2 weights × 2 semirings × 2 monoids = 32 runs
```

---

## 7. Quality Assurance

### Structural Sanity Checks

**Per-Framework Validation:**
- Assumptions > 0
- Rules ≥ 0
- All rule bodies reference existing atoms
- All contraries reference existing assumptions
- No isolated assumptions (unless topology = "isolated")
- Attack graph is connected (unless topology allows disconnection)
- Derivation depth ≤ D

**Statistical Checks (across all frameworks):**
- Topology distribution: each appears 720 times (4320 / 6)
- A distribution: each appears 864 times (4320 / 5)
- Weight scheme distribution: each appears 1080 times (4320 / 4)
- No (topology, weight) cell is empty
- Replicate variance < 10% (sanity check for determinism)

### Reproducibility Validation

```bash
# Generate with seed 42
python benchmark_runner.py generate --seed 42 --output-dir run1

# Generate with seed 42 again
python benchmark_runner.py generate --seed 42 --output-dir run2

# Check exact file match
diff -r run1 run2  # Should be identical
```

---

## 8. Expected Outputs

### Directory Structure

```
benchmark/
├── frameworks_v2/
│   ├── linear/
│   │   ├── linear_a5_r1_d1_uniform_tight_rep1.lp
│   │   ├── linear_a5_r1_d1_uniform_tight_rep1.json  # metadata
│   │   ├── linear_a5_r1_d1_uniform_tight_rep2.lp
│   │   ├── linear_a5_r1_d1_uniform_tight_rep2.json
│   │   └── ...
│   ├── tree/ ...
│   └── ...
├── results_v2/
│   ├── results.jsonl  # One JSON per solver run
│   ├── summary.csv    # Tabular summary
│   ├── timeout_analysis.csv
│   └── performance_by_monoid.csv
└── EXPERIMENTAL_DESIGN.md  # This file
```

### Summary Statistics

```csv
topology,semiring,monoid,operator,total_runs,satisfiable,timeout,avg_time_s,median_time_s
linear,godel,sum,ub,720,680,40,1.23,0.45
linear,godel,sum,lb,720,690,30,1.15,0.42
...
```

---

## 9. Deviations from Full Factorial

**Justification for Sampling:**

1. **Body Size Max**: Fixed at 3 (representative of typical ABA)
   - Full factorial would add ×4 configurations
   - Prior analysis shows minimal impact beyond D=2

2. **Semantics**: Fixed at "stable"
   - Focus on most widely-used semantics
   - CF/naive can be added in future extensions

3. **Replicate Count**: K=3 (not K=10)
   - Balances statistical power vs. runtime
   - Standard in computational experiments

4. **Weight Schemes**: 4 (not 8)
   - Selected representative schemes: uniform (baseline), power_law (skewed), bimodal (mixed), sparse (extreme)
   - Eliminates redundant schemes (sparse_uniform ≈ uniform + sparse)

---

## 10. Success Criteria

**Benchmark is valid if:**
- ✓ All 4,320 frameworks generated with unique IDs
- ✓ All frameworks have metadata JSON sidecar
- ✓ NO budget/1 predicates in .lp files
- ✓ Balanced design: χ² test p > 0.05 for all factor pairs
- ✓ Reproducibility: diff(seed=42 run1, seed=42 run2) = ∅
- ✓ Completeness: All 172,800 solver runs logged (or timed out)
- ✓ Runtime: < 120 hours on 8-core machine
- ✓ Timeout rate: < 30% overall

---

## Changelog

- **2025-12-28**: Initial draft (v2.0)
- **v1.0** (implicit): Ad-hoc sampling with confounding issues

---

**Next Step**: Implement Phase 1 (seed plumbing & metadata)
