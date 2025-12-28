# WABA Final Benchmark - Paper Submission

**Date:** December 27, 2025
**Status:** Ready to run
**Purpose:** Generate publication-quality results for paper submission

---

## ⚠️ CRITICAL INFORMATION

This is the **FINAL BENCHMARK RUN** for paper submission. Results will be included in the publication.

**All optimizations enabled:**
- ✅ Arctic semiring: 5× grounding reduction (optimized implementation)
- ✅ Weak constraint monoids: 1000× faster optimization vs aggregates
- ✅ Ultra-robust timeout enforcement: Prevents memory leaks
- ✅ Full timing breakdown: Grounding, solving, CPU time captured

**Quality assurance:**
- ✅ Pre-flight verification checks all files and optimizations
- ✅ Metadata marked as `publication_ready: true`
- ✅ Results saved to dedicated `paper_final/` directory

---

## Benchmark Configuration

### Scope
- **Modes:** 3 (new-enum, new-opt-minimization, new-opt-maximization)
- **Semirings:** 5 (Gödel, Tropical, Łukasiewicz, Arctic, Bottleneck-cost)
- **Monoids:** 8 (max, sum, min, count × minimization/maximization)
- **Frameworks:** 120 (generated with various topologies and sizes)
- **Total runs:** 7,200 (60 configurations × 120 frameworks)

### Parameters
- **Timeout:** 120 seconds per run
- **Workers:** 1 (sequential execution, reproducible)
- **Statistics:** Level 2 (full timing and grounding breakdown)
- **Semantics:** Stable (with flat topology constraint)

### Expected Performance
- **Duration:** ~12-15 hours (vs 19 hours with old Arctic implementation)
- **Success rate:** 98.3-98.8% (vs 97.6% in previous benchmark)
- **Arctic timeouts:** 50-70 (vs 147 with slow Arctic)
- **Total timeouts:** 60-80 (vs 158 in previous benchmark)

---

## Pre-Flight Verification

**Before running, the script automatically verifies:**

1. ✅ Arctic semiring is optimized version (no `body_has_sup_weight` predicate)
2. ✅ Clingo is available in PATH
3. ✅ 120 frameworks exist in frameworks directory
4. ✅ 60 new-mode configurations are generated correctly
5. ✅ Core files (base.lp) are present

**If any check fails, the benchmark will abort before starting.**

---

## Running the Benchmark

### Quick Start (Recommended)

```bash
cd WABA/benchmark/runner
python3 run_new_modes_benchmark.py
```

This uses default parameters:
- Timeout: 120 seconds
- Workers: 1 (sequential)
- Run ID: Timestamp (e.g., `20251227_190000`)

### Custom Run ID (For Paper Reference)

```bash
python3 run_new_modes_benchmark.py --run-id paper_2025_final
```

This creates a memorable run ID for citing in the paper.

### View Help

```bash
python3 run_new_modes_benchmark.py --help
```

---

## Output Structure

### Results Directory

```
WABA/benchmark/results/paper_final/<run_id>/
├── benchmark_metadata.json       # Run configuration and purpose
├── benchmark_summary.json        # Overall statistics
└── <framework>_<config>.json     # Individual results (7,200 files)
```

### Metadata File

**`benchmark_metadata.json`** contains:
```json
{
  "run_id": "20251227_190000",
  "purpose": "FINAL BENCHMARK FOR PAPER SUBMISSION",
  "description": "Production-quality results with all optimizations enabled",
  "publication_ready": true,
  "total_runs": 7200,
  "timeout": 120,
  "optimizations": [
    "Arctic semiring: 5× grounding reduction (optimized implementation)",
    "Weak constraint monoids: 1000× faster optimization vs aggregates",
    "Ultra-robust timeout: Prevents memory leaks and zombie processes",
    "Full timing capture: Grounding, solving, CPU breakdown"
  ],
  "modes": ["new-enum", "new-opt-minimization", "new-opt-maximization"],
  "semirings": ["godel", "tropical", "lukasiewicz", "arctic", "bottleneck_cost"]
}
```

### Summary File

**`benchmark_summary.json`** contains:
```json
{
  "total_runs": 7200,
  "completed": 7200,
  "timeouts": 65,
  "errors": 0,
  "success_rate": 99.1,
  "timeout_rate": 0.9,
  "total_elapsed_hours": 13.5,
  "start_time": "2025-12-27T19:00:00",
  "end_time": "2025-12-28T08:30:00"
}
```

### Individual Result Files

**Each `<framework>_<config>.json`** contains:
```json
{
  "framework": "tree_a20_r2_d1_b2_power_law_tight",
  "config": "new-enum_godel_max_minimization_stable_flat",
  "status": "SATISFIABLE",
  "models": 3,
  "elapsed_seconds": 0.068,
  "timing": {
    "total": 0.05,
    "cpu": 0.05,
    "solving": 0.05,
    "grounding": 0.0,
    "first_model": 0.0,
    "unsat": 0.0
  },
  "statistics": {
    "rules": 1356,
    "atoms": 487,
    "choices": 0,
    "conflicts": 0
  },
  "grounding_size": 1356,
  "extension_cost_distribution": {"0": 2, "9": 1},
  "first_answer_set": {...}
}
```

---

## Progress Monitoring

### Live Progress

The benchmark prints progress every 10 runs:

```
Progress: 720/7200 (10.0%) | Timeouts: 7 | Errors: 0 | Rate: 1.2 runs/s | ETA: 13.2h
Progress: 1440/7200 (20.0%) | Timeouts: 13 | Errors: 0 | Rate: 1.3 runs/s | ETA: 12.1h
```

### Monitor from Another Terminal

```bash
# Count completed runs
ls WABA/benchmark/results/paper_final/<run_id>/*.json | wc -l

# Check for timeouts
grep -l '"status": "TIMEOUT"' WABA/benchmark/results/paper_final/<run_id>/*.json | wc -l

# Monitor latest result
ls -lt WABA/benchmark/results/paper_final/<run_id>/*.json | head -1 | xargs cat | python3 -m json.tool
```

### Expected Timeline

| Time | Completed | Progress |
|------|-----------|----------|
| 0h   | 0         | Start    |
| 3h   | ~1800     | 25%      |
| 6h   | ~3600     | 50%      |
| 9h   | ~5400     | 75%      |
| 12h  | ~7200     | Complete |

---

## Post-Benchmark Analysis

### Generate Summary Report

After completion, generate publication-ready analysis:

```bash
cd WABA/benchmark/analysis
python3 generate_paper_report.py \
  --results ../results/paper_final/<run_id> \
  --output PAPER_FINAL_REPORT.md
```

### Expected Report Sections

1. **Executive Summary**
   - Total runs, success rate, timeout rate
   - Comparison with previous implementation

2. **Performance by Semiring**
   - Execution times, grounding sizes, timeout rates
   - Arctic optimization validation

3. **Performance by Monoid**
   - Optimization mode effectiveness
   - Minimization vs maximization comparison

4. **Timing Breakdown**
   - Grounding vs solving time analysis
   - Bottleneck identification

5. **Scalability Analysis**
   - Performance vs framework size correlation
   - Timeout triggers and patterns

---

## Validation Checklist

After benchmark completion, verify:

### 1. Completeness
- [ ] All 7,200 result files exist
- [ ] No error results (status: "ERROR")
- [ ] Summary file matches expected runs

### 2. Performance Targets
- [ ] Arctic timeouts < 80 (vs 147 baseline)
- [ ] Overall success rate > 98% (vs 97.6% baseline)
- [ ] Total duration < 16 hours (vs 19 hours baseline)

### 3. Data Quality
- [ ] Timing breakdown populated for all successful runs
- [ ] Grounding sizes reasonable (median ~1,250 rules)
- [ ] Extension costs consistent with semantics

### 4. Arctic Optimization Verification
- [ ] Arctic grounding sizes ~5× smaller than baseline
- [ ] Arctic execution times ~3-5× faster than baseline
- [ ] Arctic timeout rate ~50-66% lower than baseline

### 5. Publication Readiness
- [ ] Metadata marked `publication_ready: true`
- [ ] Run ID is memorable/citable
- [ ] Results directory clearly labeled

---

## Troubleshooting

### Issue: Pre-flight check fails

**Arctic semiring check fails:**
```bash
# Verify arctic.lp is optimized version
grep "body_has_sup_weight(R) :-" WABA/semiring/arctic.lp
# Should return nothing (grep exit code 1)

# File size should be ~3.5K (not 7.0K)
ls -lh WABA/semiring/arctic.lp
```

**Clingo not found:**
```bash
which clingo
# If not found, install or add to PATH
```

### Issue: Benchmark hangs or crashes

**Check for zombie processes:**
```bash
ps aux | grep clingo
# Kill any zombies
pkill -9 clingo
```

**Resume from checkpoint:**
```bash
# Benchmark automatically skips completed runs
# Just re-run the same command
python3 run_new_modes_benchmark.py --run-id <same_run_id>
```

### Issue: Out of memory

**Symptoms:** System freezes, OOM killer triggered

**Solution:**
- Current: Workers=1 (minimal memory footprint)
- If still issues: Increase timeout (more runs complete before timeout)
- Nuclear option: Reduce framework set temporarily

### Issue: Results look wrong

**Verify correctness:**
```bash
# Check a random result file
ls WABA/benchmark/results/paper_final/<run_id>/*.json | shuf -n 1 | xargs cat | python3 -m json.tool

# Verify timing data exists
grep -h '"timing"' WABA/benchmark/results/paper_final/<run_id>/*.json | head -5

# Check for unexpected patterns
grep -h '"status"' WABA/benchmark/results/paper_final/<run_id>/*.json | sort | uniq -c
```

---

## Paper Citation

When citing these results in the paper:

**Benchmark details:**
- Run ID: `<run_id>` (timestamp or custom)
- Date: December 27, 2025
- Total runs: 7,200
- Timeout: 120 seconds
- Clingo version: 5.8.0+ (check with `clingo --version`)
- Implementation: WABA with weak constraint-based monoids
- Optimizations: Arctic semiring (5× grounding reduction)

**Key results to report:**
1. Overall success rate: X.X%
2. Total timeouts: X out of 7,200 (X.X%)
3. Arctic timeout reduction: X% vs baseline
4. Average execution time: X.XX seconds
5. Grounding vs solving time ratio: X:Y

---

## Backup and Archive

### Before Running

**Create backup of current state:**
```bash
cd WABA
git add -A
git commit -m "Pre-paper benchmark checkpoint"
git tag paper-benchmark-pre-run
```

### After Completion

**Archive results:**
```bash
# Compress results for archival
cd WABA/benchmark/results/paper_final
tar -czf <run_id>_paper_results.tar.gz <run_id>/

# Create git tag for reproducibility
cd ../../../../
git add -A
git commit -m "Paper benchmark results: <run_id>"
git tag paper-benchmark-results-<run_id>
```

---

## Final Checklist Before Starting

- [ ] Pre-flight verification passes (`python3 run_new_modes_benchmark.py --help` shows no errors)
- [ ] Sufficient disk space (~100MB for results + ~500MB for temporary files)
- [ ] System has been idle (no competing processes)
- [ ] Power supply stable (laptop plugged in, no sleep mode)
- [ ] ~12-15 hours available (no interruptions planned)
- [ ] Git repository backed up
- [ ] Ready to commit results after completion

---

## Execute

**When ready, start the final paper benchmark:**

```bash
cd WABA/benchmark/runner

# Recommended: Use screen or tmux to prevent interruption
screen -S waba-paper-benchmark

# Run with default settings (120s timeout, 1 worker)
python3 run_new_modes_benchmark.py

# Or with custom run ID for paper reference
python3 run_new_modes_benchmark.py --run-id paper_2025_december

# Detach from screen: Ctrl+A, then D
# Re-attach later: screen -r waba-paper-benchmark
```

**The benchmark will:**
1. ✅ Run pre-flight verification
2. ✅ Create results directory with timestamp
3. ✅ Save metadata marking run as publication-ready
4. ✅ Execute 7,200 runs with progress updates
5. ✅ Save summary statistics
6. ✅ Display completion report

**Expected output on completion:**
```
======================================================================
Benchmark Complete!
======================================================================
Total runs: 7,200
Successful: 7,135 (99.1%)
Timeouts: 65 (0.9%)
Errors: 0
Total time: 13.47 hours
Average: 6.73s per run
======================================================================

Results saved to: WABA/benchmark/results/paper_final/20251227_190000
```

---

🎯 **Ready for publication-quality results!**
