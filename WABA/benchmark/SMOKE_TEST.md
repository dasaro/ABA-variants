# Phase 3 Smoke Test

**Quick end-to-end test (<2 minutes) to verify benchmark runner + analysis pipeline**

## Setup

```bash
cd benchmark

# Use existing test_frameworks (6 instances already generated)
ls test_frameworks/*/  # Should show 6 .lp + 6 .meta.json files
```

## Step 1: Run Benchmark (Enum Mode)

```bash
# Enum mode: enumerate all answer sets
python3 benchmark_runner.py \
  --plan smoke_plan.jsonl \
  --frameworks-dir test_frameworks \
  --semirings godel \
  --monoids max \
  --semantics stable \
  --mode enum \
  --timeout-seconds 10 \
  --max-workers 2 \
  --output smoke_results/enum_results.jsonl
```

**Expected:** 6 runs complete in <1 minute, enum_results.jsonl created

## Step 1b: Run Benchmark (Opt Mode)

```bash
# Opt mode: find optimal model (minimization)
python3 benchmark_runner.py \
  --plan smoke_plan.jsonl \
  --frameworks-dir test_frameworks \
  --semirings godel \
  --monoids max \
  --semantics stable \
  --mode opt \
  --opt-direction min \
  --timeout-seconds 10 \
  --max-workers 2 \
  --output smoke_results/opt_results.jsonl
```

**Expected:** 6 runs complete in <1 minute, opt_results.jsonl created

## Step 2: Analyze Results

```bash
# Analyze enum mode results
python3 analyze_results.py \
  --input smoke_results/enum_results.jsonl \
  --output-dir smoke_analysis_enum

# Analyze opt mode results
python3 analyze_results.py \
  --input smoke_results/opt_results.jsonl \
  --output-dir smoke_analysis_opt
```

**Expected outputs (each directory):**
- `summary.csv` - Grouped statistics
- `plots/` - Runtime, timeout, status plots (if matplotlib available)
- `BENCHMARK_REPORT.md` - Paper-ready report

## Step 3: Verify Results

```bash
# Check results files
wc -l smoke_results/enum_results.jsonl  # Should be 6 lines
wc -l smoke_results/opt_results.jsonl   # Should be 6 lines

# View first enum result
head -1 smoke_results/enum_results.jsonl | python3 -m json.tool | head -30

# View first opt result
head -1 smoke_results/opt_results.jsonl | python3 -m json.tool | head -30

# View enum summary
cat smoke_analysis_enum/summary.csv

# View opt summary
cat smoke_analysis_opt/summary.csv

# View reports
cat smoke_analysis_enum/BENCHMARK_REPORT.md
cat smoke_analysis_opt/BENCHMARK_REPORT.md
```

## Step 4: Test Resumability

```bash
# Run enum mode again (should skip all runs)
python3 benchmark_runner.py \
  --plan smoke_plan.jsonl \
  --frameworks-dir test_frameworks \
  --semirings godel \
  --monoids max \
  --semantics stable \
  --mode enum \
  --timeout-seconds 10 \
  --max-workers 2 \
  --output smoke_results/enum_results.jsonl

# Should output:
#   Total configurations: 6
#   Already completed: 6
#   To run: 0
#   ✓ All runs already completed (use --force to re-run)

# Run opt mode again (should also skip all runs)
python3 benchmark_runner.py \
  --plan smoke_plan.jsonl \
  --frameworks-dir test_frameworks \
  --semirings godel \
  --monoids max \
  --semantics stable \
  --mode opt \
  --opt-direction min \
  --timeout-seconds 10 \
  --max-workers 2 \
  --output smoke_results/opt_results.jsonl

# Should output:
#   Total configurations: 6
#   Already completed: 6
#   To run: 0
#   ✓ All runs already completed (use --force to re-run)
```

## Step 5: Verify NO budget/1 Predicates

```bash
# Check that instances have NO budget/1 predicates (critical guardrail)
grep -r "^budget(" test_frameworks/ || echo "✓ No budget/1 predicates found (correct!)"

# Check metadata has budget values
grep -r "budget" test_frameworks/*.meta.json | head -3  # Should find budget in metadata only
```

## Full Run Example (Scaled Up)

For a medium-scale benchmark (480 instances × 2 semirings × 2 monoids = 1,920 runs):

```bash
# Generate balanced plan
python3 planner.py --seed 42 --design stratified --max-instances 480 --replicates 1 --dry-run

# Generate frameworks
python3 planner.py --generate-from-plan plan.jsonl --output-dir frameworks

# Run benchmark in enum mode (enumerate all answer sets)
python3 benchmark_runner.py \
  --plan plan.jsonl \
  --frameworks-dir frameworks \
  --semirings godel tropical \
  --monoids max sum \
  --semantics stable \
  --mode enum \
  --timeout-seconds 60 \
  --max-workers 8 \
  --output results/enum_results.jsonl

# Run benchmark in opt mode with minimization
python3 benchmark_runner.py \
  --plan plan.jsonl \
  --frameworks-dir frameworks \
  --semirings godel tropical \
  --monoids max sum \
  --semantics stable \
  --mode opt \
  --opt-direction min \
  --timeout-seconds 60 \
  --max-workers 8 \
  --output results/opt_min_results.jsonl

# Run benchmark in opt mode with maximization
python3 benchmark_runner.py \
  --plan plan.jsonl \
  --frameworks-dir frameworks \
  --semirings godel tropical \
  --monoids max sum \
  --semantics stable \
  --mode opt \
  --opt-direction max \
  --timeout-seconds 60 \
  --max-workers 8 \
  --output results/opt_max_results.jsonl

# Analyze
python3 analyze_results.py \
  --input results/enum_results.jsonl \
  --output-dir analysis/enum

python3 analyze_results.py \
  --input results/opt_min_results.jsonl \
  --output-dir analysis/opt_min

python3 analyze_results.py \
  --input results/opt_max_results.jsonl \
  --output-dir analysis/opt_max
```

---

## Troubleshooting

**"clingo: command not found"**
- Install clingo 5.8.0+: `conda install -c potassco clingo` or download from potassco.org

**"Module paths not found"**
- Check --repo-root points to WABA/ directory (default: ../WABA from benchmark/)
- Verify semiring/godel.lp, monoid/max_minimization.lp exist

**Timeouts on all runs**
- Increase --timeout-seconds (default: 60s may be too short for large instances)
- Check clingo works: `clingo --version`

**Empty results.jsonl**
- Check instance files exist: `ls test_frameworks/*/*.lp`
- Check plan.jsonl format: `head -1 smoke_plan.jsonl | python3 -m json.tool`

---

**Success Criteria:**
✅ 6 enum runs complete successfully (<1 min)
✅ 6 opt runs complete successfully (<1 min)
✅ enum_results.jsonl has 6 JSONL records with mode='enum'
✅ opt_results.jsonl has 6 JSONL records with mode='opt'
✅ Both analyses generate summary.csv, plots, and BENCHMARK_REPORT.md
✅ Resumability works (second run skips all for both modes)
✅ NO budget/1 predicates in .lp files

## Memory Pressure Mitigations

The benchmark runner includes two mitigations for long-running benchmarks with memory pressure:

### 1. Aggressive Timeout Termination

When a clingo process times out, the runner now performs aggressive multi-SIGKILL termination:

- Sends SIGTERM first (graceful)
- Follows with 5 repeated SIGKILL attempts (200ms intervals)
- Checks if process group is gone after each attempt
- Records `timeout_kill_failed` status if process survives all attempts

**Platform support:**
- Unix/Linux/macOS: Full process group killing with `killpg()`
- Windows: Best-effort repeated `process.kill()`

### 2. Frequent Garbage Collection + Worker Recycling

Memory is aggressively freed to prevent accumulation:

- `gc.collect()` after every run (success/timeout/error)
- `gc.collect()` every 50 runs in parent process
- stdout/stderr truncated to last 8KB for timeouts/errors
- Large output strings explicitly set to `None` before returning

**Worker recycling** (default: every 200 runs):
- ProcessPoolExecutor is shut down and recreated periodically
- Prevents long-running worker memory leaks
- Configurable via `--worker-recycle-interval N` (0 to disable)

**Example with recycling:**
```bash
python3 benchmark_runner.py \
  --plan plan.jsonl \
  --frameworks-dir frameworks_v4 \
  --semirings godel tropical \
  --monoids max sum \
  --mode enum \
  --timeout-seconds 120 \
  --max-workers 1 \
  --worker-recycle-interval 100 \
  --output results/enum_results.jsonl
```

This will recycle the worker pool every 100 runs, reducing memory pressure in long benchmarks.

