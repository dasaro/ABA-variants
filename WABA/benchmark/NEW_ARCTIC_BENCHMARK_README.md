# Arctic Semiring Optimization Benchmark

**Date:** December 27, 2025
**Purpose:** Validate that arctic_fast.lp provides 5× speedup over baseline arctic.lp

---

## What Was Done

### 1. Arctic Semiring Consolidation ✅

**Files reorganized:**
- `arctic_fast.lp` → **`arctic.lp`** (now the default, 3.5K, optimized)
- `arctic.lp` → **`arctic_slow.lp`** (kept for reference, 7.0K, baseline)
- Old `arctic.lp` → **`WABA_Legacy/semiring/arctic.lp`** (backup in legacy, 7.0K)

**Key optimization:**
- **Before (slow):** 3 rules with explicit `body_has_sup_weight(R)` helper → 7,940 ground rules
- **After (fast):** 2 rules leveraging Clingo's automatic #sup propagation → ~1,500 ground rules
- **Speedup:** 5× grounding reduction (79% faster estimated)

**Algebraic insight:**
```prolog
%% Clingo automatically handles #sup in aggregates!
W = #sum{ V,B : body(R,B), supported_with_weight(B,V) }
%% If any V = #sup, then W = #sup automatically (no explicit check needed)
```

### 2. Timing Infrastructure Verified ✅

**Already implemented and working:**
- Grounding time: `timing.grounding` (calculated as `total - solving`)
- Solving time: `timing.solving` (from Clingo stats)
- CPU time: `timing.cpu` (from Clingo stats)
- Total time: `timing.total` (from Clingo stats)
- First model time: `timing.first_model` (from Clingo stats)

**Verified in existing results:**
```json
"timing": {
  "total": 0.05,
  "cpu": 0.05,
  "solving": 0.05,
  "grounding": 0.0,
  "first_model": 0.0,
  "unsat": 0.0
}
```

### 3. New Benchmark Script Created ✅

**Script:** `WABA/benchmark/runner/run_new_modes_benchmark.py`

**Modes tested:**
- `new-enum` - Enumeration with `--opt-mode=ignore` (all models)
- `new-opt-minimization` - Optimization with `--opt-mode=optN` (minimize cost)
- `new-opt-maximization` - Optimization with `--opt-mode=optN` (maximize reward)

**Configurations:**
- 60 configurations (20 semiring×monoid pairs × 3 modes)
- 120 frameworks
- **Total: 7,200 runs**

**Parameters:**
- Timeout: 120 seconds (default)
- Workers: 1 (sequential, default)
- Stats level: 2 (captures full timing breakdown)

---

## Expected Results

### Previous Benchmark (Old arctic.lp - Slower)
**Arctic semiring performance:**
- 147 timeouts out of 1,920 Arctic runs (7.7% failure rate)
- 93% of all timeouts across all semirings
- 10-100× slower than other semirings
- Average time: 15-30s for successful runs

**Overall performance:**
- Total timeouts: 158 (new modes combined)
- Success rate: 97.6-97.7%

### Expected New Benchmark (arctic.lp - Fast)
**Arctic semiring performance (predicted):**
- 50-70 timeouts out of 1,920 Arctic runs (2.6-3.6% failure rate)
- **50-66% reduction in Arctic timeouts**
- 3-5× faster than old Arctic implementation
- Average time: 3-6s for successful runs (estimated)

**Overall performance (predicted):**
- Total timeouts: 60-80 (new modes combined)
- Success rate: **98.3-98.8%** (vs 97.6% before)
- **0.6-1.2% improvement** in overall success rate

---

## Running the Benchmark

### Quick Start (Default Settings)

```bash
cd WABA/benchmark/runner
python3 run_new_modes_benchmark.py
```

**Default configuration:**
- Timeout: 120 seconds
- Workers: 1 (sequential)
- Run ID: timestamp (e.g., `20251227_185500`)

**Expected duration:** ~12-15 hours (vs 19 hours with old arctic.lp)

### Custom Settings

**Custom timeout:**
```bash
python3 run_new_modes_benchmark.py --timeout 180
```

**Parallel execution (2 workers):**
```bash
python3 run_new_modes_benchmark.py --workers 2
```

**Custom run ID:**
```bash
python3 run_new_modes_benchmark.py --run-id arctic_fast_validation
```

### Full Command Example

```bash
cd WABA/benchmark/runner
python3 run_new_modes_benchmark.py --timeout 120 --workers 1 --run-id arctic_fast_2025
```

---

## Output Files

**Results directory:**
```
WABA/benchmark/results/new_modes_arctic_fast/<run_id>/
```

**Files generated:**
- `benchmark_metadata.json` - Run configuration and purpose
- `benchmark_summary.json` - Overall statistics (timeouts, success rate, elapsed time)
- `<framework>_<config>.json` - Individual run results (7,200 files)

**Each result JSON includes:**
```json
{
  "framework": "tree_a20_r2_d1_b2_power_law_tight",
  "config": "new-enum_godel_max_minimization_stable_flat",
  "status": "SATISFIABLE",
  "models": 3,
  "timing": {
    "total": 0.05,
    "cpu": 0.05,
    "solving": 0.05,
    "grounding": 0.0,
    "first_model": 0.0,
    "unsat": 0.0
  },
  "statistics": {
    "choices": 0,
    "conflicts": 0,
    "restarts": 0,
    "rules": 1356,
    "atoms": 487,
    "bodies": 869
  },
  "elapsed_seconds": 0.068,
  "grounding_size": 1356,
  "extension_cost_distribution": {...},
  "assumption_frequency": {...}
}
```

---

## Validation Checklist

After the benchmark completes, verify:

1. **Arctic timeout reduction:**
   - Compare Arctic timeouts: old (147) vs new (target: 50-70)
   - Calculate reduction percentage: `(147 - new) / 147 * 100%`

2. **Grounding size reduction:**
   - Check Arctic grounding sizes in results
   - Verify ~5× reduction for Arctic configurations

3. **Overall improvement:**
   - Compare total timeouts: old (158) vs new (target: 60-80)
   - Verify success rate improvement: old (97.6%) vs new (target: 98.3-98.8%)

4. **Timing breakdown:**
   - Verify `timing.grounding` and `timing.solving` are populated
   - Analyze where time is spent (grounding vs solving)

5. **Semantic correctness:**
   - Verify answer sets match expected results
   - Check extension costs are consistent

---

## Comparison Analysis

After completion, use the analysis scripts to generate reports:

```bash
# Compare new Arctic results with old benchmark
cd WABA/benchmark/analysis
python3 compare_arctic_versions.py \
  --old ../results/three_mode/20251227_002219 \
  --new ../results/new_modes_arctic_fast/<run_id>
```

**Expected outputs:**
- Arctic performance comparison (timeouts, grounding sizes, execution times)
- Timeout reduction percentage
- Grounding size reduction verification
- Overall benchmark improvement statistics

---

## Troubleshooting

**Issue:** Benchmark crashes or hangs
- **Check:** Timeout enforcement is ultra-robust with SIGKILL
- **Solution:** Verify no zombie processes with `ps aux | grep clingo`

**Issue:** Out of memory
- **Check:** Aggressive garbage collection enabled
- **Solution:** Reduce `--workers` to 1 (default)

**Issue:** Missing timing data
- **Check:** Clingo version supports `--stats=2`
- **Solution:** Verify with `clingo --version` (requires 5.8.0+)

**Issue:** Incorrect Arctic version used
- **Verify:** `grep -c "body_has_sup_weight" WABA/semiring/arctic.lp` should return 1 (comment only)
- **Check:** File size should be ~3.5K (not 7.0K)

---

## Next Steps

1. **Run the benchmark** (12-15 hours estimated)
2. **Analyze results** using comparison scripts
3. **Generate report** comparing old vs new Arctic performance
4. **Update documentation** with validated performance gains
5. **Remove arctic_slow.lp** if optimization confirmed (or keep for reference)

---

## References

**Previous benchmark:**
- `WABA/benchmark/results/three_mode/20251227_002219/` - Used old (slow) arctic.lp
- `WABA/benchmark/results/three_mode_2025-12-27/FINAL_BENCHMARK_REPORT.md` - Full analysis

**Implementation comparison:**
- `WABA/semiring/arctic.lp` - New (fast) implementation, 3.5K, 97 lines
- `WABA/semiring/arctic_slow.lp` - Old (slow) implementation, 7.0K, 158 lines
- `WABA_Legacy/semiring/arctic.lp` - Backup in legacy directory

**Related documentation:**
- `WABA/docs/SEMIRING_MONOID_COMPATIBILITY.md` - Semiring theory
- `WABA/benchmark/results/new_mode_analysis/NEW_MODE_ANALYSIS_REPORT.md` - Previous analysis

---

**Ready to run!** 🚀

Execute with:
```bash
cd WABA/benchmark/runner
python3 run_new_modes_benchmark.py --timeout 120 --workers 1
```
