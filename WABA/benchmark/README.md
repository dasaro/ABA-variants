# WABA Benchmark Suite v4.0

**Scientifically rigorous benchmark generation for Weighted Assumption-Based Argumentation**

This suite generates balanced experimental designs for evaluating WABA across multiple semirings, monoids, and semantics. All results are **fully reproducible** from a single master seed.

---

## Quick Start

\`\`\`bash
cd benchmark

# 1. Generate a plan (dry-run mode - no .lp files yet)
python3 planner.py --seed 42 --design factorial --dry-run

# 2. Generate frameworks from plan
python3 planner.py --generate-from-plan plan.jsonl --output-dir frameworks

# 3. Run benchmark (enum mode - enumerate all answer sets)
python3 benchmark_runner.py \
  --plan plan.jsonl \
  --frameworks-dir frameworks \
  --semirings godel tropical \
  --monoids max sum \
  --semantics stable \
  --mode enum \
  --max-workers 8 \
  --output results/enum_results.jsonl

# 4. Run benchmark (opt mode - find optimal models)
python3 benchmark_runner.py \
  --plan plan.jsonl \
  --frameworks-dir frameworks \
  --semirings godel tropical \
  --monoids max sum \
  --semantics stable \
  --mode opt \
  --opt-direction min \
  --max-workers 8 \
  --output results/opt_results.jsonl

# 5. Analyze results
python3 analyze_results.py \
  --input results/enum_results.jsonl \
  --output-dir analysis/enum

python3 analyze_results.py \
  --input results/opt_results.jsonl \
  --output-dir analysis/opt
\`\`\`

---

## Phase 3 Complete

✅ **Phase 2:** Planner, generator, unit tests, balance validation, determinism
✅ **Phase 3:** Benchmark runner with enum/opt modes, analysis pipeline, smoke tests

**Key Features:**
- **Two runner modes:** enum (enumerate all) and opt (find optimal with min/max direction)
- **Reproducible + Resumable:** Run_id hashing, skip existing runs
- **Robust JSON parsing:** Clingo --outf=2 with detailed stats
- **Parallel execution:** ProcessPoolExecutor with configurable workers
- **Full provenance tracking:** Clingo version, git commit, timestamps
- **Analysis pipeline:** Summary CSV, plots, paper-ready reports

See SMOKE_TEST.md for quick end-to-end verification (<2 minutes).

---

## Runner Modes

### Enum Mode (Enumerate All Answer Sets)

Enumerates all answer sets using `clingo -n 0 --opt-mode=ignore`:

\`\`\`bash
python3 benchmark_runner.py \
  --plan plan.jsonl \
  --frameworks-dir frameworks \
  --semirings godel \
  --monoids max \
  --semantics stable \
  --mode enum \
  --output results/enum_results.jsonl
\`\`\`

Reports model counts, SAT rates, runtime statistics.

### Opt Mode (Find Optimal Model)

Finds optimal model using `clingo -n 0 --opt-mode=opt` with direction-based monoid selection:

\`\`\`bash
# Minimization (cost semantics)
python3 benchmark_runner.py \
  --plan plan.jsonl \
  --frameworks-dir frameworks \
  --semirings godel \
  --monoids max sum \
  --semantics stable \
  --mode opt \
  --opt-direction min \
  --output results/opt_min_results.jsonl

# Maximization (reward semantics)
python3 benchmark_runner.py \
  --plan plan.jsonl \
  --frameworks-dir frameworks \
  --semirings godel \
  --monoids max sum \
  --semantics stable \
  --mode opt \
  --opt-direction max \
  --output results/opt_max_results.jsonl
\`\`\`

Automatically selects `<monoid>_minimization.lp` or `<monoid>_maximization.lp` based on direction.

---

## Semantic Properties of Benchmark Frameworks

**IMPORTANT**: Benchmark frameworks exhibit **100% saturation semantics collapse**:

```
grounded = stable = semi-stable = preferred = complete
```

**Why**: In WABA, each "extension" is a pair (assumptions, discarded_attacks) representing an attack resolution scenario. Benchmark frameworks have **exactly one complete extension per scenario**, causing saturation semantics to collapse within each scenario by mathematical necessity.

**Example**: A framework may have 4 "extensions" representing 4 different ways to discard attacks (within budget), but each scenario produces exactly 1 complete extension where all saturation semantics agree.

**What benchmarks CAN test**:
- ✅ Performance and scalability
- ✅ Admissibility hierarchy (complete ⊂ admissible: 80% strict)
- ✅ Budget constraint effects

**What benchmarks CANNOT test**:
- ❌ Saturation semantic diversity (all collapse to same extension)
- ❌ Multiple complete extension scenarios

For semantic correctness testing, use **test/ directory** with hand-crafted frameworks.

**Detailed Analysis**: See `test/BENCHMARK_SEMANTIC_ANALYSIS.md` for comprehensive findings on:
- Budget-dependent strictness
- Optimization mode comparison
- Topology-specific patterns
- Recommendations for semantic vs. performance testing

---

For complete documentation including:
- Experimental design (factors, levels, sampling strategies)
- Seeding policy & reproducibility guarantees
- File layout & metadata schema
- Runner modes and CLI reference
- Advanced options & troubleshooting

Refer to SMOKE_TEST.md or run:
\`\`\`bash
python3 benchmark_runner.py --help
python3 planner.py --help
\`\`\`
