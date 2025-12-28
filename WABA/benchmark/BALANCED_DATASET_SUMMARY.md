# Balanced WABA Benchmark Dataset (120 Frameworks)

**Generated:** 2024-12-24
**Total Frameworks:** 120 (20 per topology × 6 topologies)

## Perfect Factorial Balance Achieved ✓

### Complete Coverage: 6 Topology Classes
**Perfect factorial coverage:** 5 assumptions × 2 rule densities × 2 depths × 6 topologies = 120

| Topology | Frameworks | Coverage |
|----------|------------|----------|
| Linear   | 20 | ✓ Perfect factorial |
| Tree     | 20 | ✓ Perfect factorial |
| Cycle    | 20 | ✓ Perfect factorial |
| Complete | 20 | ✓ Perfect factorial |
| Mixed    | 20 | ✓ Perfect factorial |
| Isolated | 20 | ✓ Perfect factorial |

**Result:** Every (a, r, d) combination covered exactly once per topology

## Parameter Space

### Core Parameters (Perfectly Balanced)

**Assumption counts (a):**
- 2 (trivial): 24 frameworks (20.0%)
- 5 (small): 24 frameworks (20.0%)
- 10 (small-medium): 24 frameworks (20.0%)
- 15 (medium): 24 frameworks (20.0%)
- 20 (large): 24 frameworks (20.0%)

**Exponential growth pattern:** 2.5x scaling (2→5→10→15→20)

**Rule densities (r):**
- 2 (low): 60 frameworks (50.0%)
- 5 (high): 60 frameworks (50.0%)

**Derivation depths (d):**
- 1 (shallow): 60 frameworks (50.0%)
- 2 (deep): 60 frameworks (50.0%)

### Topology Classes (Perfectly Balanced)

- **Linear:** 20 frameworks (16.7%) - Sequential chain topology
- **Tree:** 20 frameworks (16.7%) - Binary branching (branching_factor=2)
- **Cycle:** 20 frameworks (16.7%) - Simple 3-cycles (cycle_length=3)
- **Complete:** 20 frameworks (16.7%) - All-vs-all attack graph
- **Mixed:** 20 frameworks (16.7%) - Dense clusters + bridges (num_clusters=2)
- **Isolated:** 20 frameworks (16.7%) - Disconnected components (num_components=2)

### Weight Distributions (Systematically Cycled)

- Dense Uniform
- Power Law
- Random

### Constraint Levels (Systematically Alternated)

- Tight: 50%
- Loose: 50%

### Attack Constraint (Enforced)

- **75% derived-only attacks:** 75% of contrary atoms have no direct topology attack and are attacked ONLY via derived atoms
- Implemented via `derived_only_ratio=0.75` in `framework_templates.py`

## Improvements Over Previous Dataset

### Before (Unbalanced - 30 frameworks):
- 30 frameworks total
- 16 complete (53%), 14 cycle (47%) - **Only 2 topologies**
- a values: [2, 10, 15, 20] - **Missing a=5**
- r values: [2, 5]
- d values: [1, 2]
- **Missing 4 topologies:** linear, tree, mixed, isolated

### After (Balanced - 120 frameworks):
- 120 frameworks total
- **All 6 topologies** perfectly balanced (20 each, 16.7%)
- a values: [2, 5, 10, 15, 20] - **Complete coverage with exponential scaling**
- r values: [2, 5]
- d values: [1, 2]
- **Perfect factorial:** Each (a, r, d) appears exactly once per topology
- **4x more data** for comprehensive evaluation

## Factorial Coverage Matrix

Each topology has identical factorial coverage:

```
         d=1     d=2
  a= 2: r2:1 r5:1 r2:1 r5:1
  a= 5: r2:1 r5:1 r2:1 r5:1
  a=10: r2:1 r5:1 r2:1 r5:1
  a=15: r2:1 r5:1 r2:1 r5:1
  a=20: r2:1 r5:1 r2:1 r5:1
```

**Every cell = exactly 1 framework** → Perfect balance ✓

## Generation Method

```bash
python3 generator/regenerate_balanced.py
```

Uses `balanced_config.py` for systematic parameter grid generation:
- Perfect factorial grid: 5×2×2 = 20 per topology
- Topology-specific parameters automatically added
- Weight schemes: Systematically cycled (dense_uniform → power_law → random)
- Constraints: Alternated between tight/loose

## Verification

Run balance verification:
```bash
python3 generator/balanced_config.py
```

Expected output:
- ✓ Total configurations: 120/120
- ✓ Topology balance: PERFECT (all have 20)
- ✓ Factorial coverage: PERFECT (all topologies have 20/20 unique combinations)
- ✓ Assumption coverage: COMPLETE
- ✓ Rule density coverage: COMPLETE
- ✓ Depth coverage: COMPLETE

## Files Generated

**Linear topology (20 files):**
```
frameworks/linear/linear_a{2,5,10,15,20}_r{2,5}_d{1,2}_*.lp
```

**Tree topology (20 files):**
```
frameworks/tree/tree_a{2,5,10,15,20}_r{2,5}_d{1,2}_b2_*.lp
```

**Cycle topology (20 files):**
```
frameworks/cycle/cycle_a{2,5,10,15,20}_r{2,5}_d{1,2}_c3_*.lp
```

**Complete topology (20 files):**
```
frameworks/complete/complete_a{2,5,10,15,20}_r{2,5}_d{1,2}_*.lp
```

**Mixed topology (20 files):**
```
frameworks/mixed/mixed_a{2,5,10,15,20}_r{2,5}_d{1,2}_cl2_*.lp
```

**Isolated topology (20 files):**
```
frameworks/isolated/isolated_a{2,5,10,15,20}_r{2,5}_d{1,2}_co2_*.lp
```

## Ready for Benchmarking

This balanced dataset is now ready for systematic evaluation across:
- 5 semirings × 4 monoids = 20 configurations per framework
- Total benchmark runs: 120 frameworks × 20 configs = **2,400 test cases**

Expected balanced results across:
- All 6 topology types
- Full range of assumption counts (2-20)
- Low and high rule densities
- Shallow and deep derivation chains

## Key Features

✓ **Perfect factorial balance** - Every (a, r, d) combination appears exactly once per topology
✓ **Complete topology coverage** - All 6 topology classes represented equally
✓ **Exponential scaling visibility** - Assumption counts [2, 5, 10, 15, 20] show ~2.5x growth
✓ **75% derived-only attacks** - Consistent constraint enforcement across all frameworks
✓ **Systematic variation** - Weight schemes and budget levels cycled deterministically
✓ **4x larger dataset** - From 30 to 120 frameworks for robust evaluation

## Statistics Summary

| Metric | Value |
|--------|-------|
| Total frameworks | 120 |
| Topologies | 6 (all balanced) |
| Assumption counts | 5 values [2, 5, 10, 15, 20] |
| Rule densities | 2 values [2, 5] |
| Derivation depths | 2 values [1, 2] |
| Weight schemes | 3 types (cycled) |
| Budget levels | 2 types (alternated) |
| Unique (a,r,d) combinations | 20 per topology |
| Total test cases (with 20 configs) | 2,400 |

---

**Status:** ✓ READY FOR BENCHMARKING
