# WABA Benchmark Suite v2.0

A modular benchmarking framework for Weighted Assumption-Based Argumentation.

**Status**: Refactored 2025-12-29
**Python**: 3.10+
**Clingo**: 5.8.0+

---

## Quick Start

### 1. Generate a Plan
```bash
python3 src/waba_bench/planner.py \
  --design grid3 \
  --A 6 8 10 \
  --R 1 2 3 \
  --D 1 2 3 \
  --replicates 3 \
  --output plans/my_plan.jsonl
```

### 2. Generate Frameworks
```bash
python3 src/waba_bench/generator.py \
  --plan plans/my_plan.jsonl \
  --output-dir frameworks/my_experiment
```

### 3. Run Benchmark
```bash
python3 src/waba_bench/runner.py \
  --plan plans/my_plan.jsonl \
  --frameworks-dir frameworks/my_experiment \
  --semirings godel tropical arctic \
  --monoids max sum min \
  --mode opt \
  --opt-direction min \
  --output results/my_experiment/opt_min.jsonl
```

### 4. Analyze Results
```bash
python3 src/waba_bench/analyzer.py \
  --input results/my_experiment/opt_min.jsonl \
  --output-dir analysis/my_experiment
```

---

## Directory Structure

```
benchmark/
├── src/                        # SOURCE CODE
│   └── waba_bench/
│       ├── planner.py          # Plan generator
│       ├── runner.py           # Benchmark runner
│       ├── generator.py        # Framework generator
│       ├── analyzer.py         # Results analyzer
│       ├── consistency.py      # Consistency checker
│       ├── utils.py            # Shared utilities
│       └── generator/          # Generator modules
│
├── scripts/                    # HELPER SCRIPTS
│   ├── run_planner.sh
│   ├── run_benchmark.sh
│   ├── run_analysis.sh
│   └── protect_active_run.py  # Safety tool
│
├── plans/                      # Experimental plans (gitignored)
├── frameworks/                 # Generated frameworks (gitignored)
├── results/                    # Benchmark results (gitignored)
├── analysis/                   # Analysis outputs (gitignored)
├── logs/                       # Execution logs (gitignored)
└── archive/                    # Archived experiments (gitignored)
```

---

## Module Reference

### planner.py
Generate experimental plans with factorial or grid designs.

**Designs**:
- `factorial`: Full factorial design
- `grid3`: 3D grid over (A, R, D) space with balanced downsampling

**Example**:
```bash
python3 src/waba_bench/planner.py \
  --design grid3 \
  --A 6 8 10 14 20 30 45 \
  --R 1 2 3 4 5 7 10 \
  --D 1 2 3 4 5 6 7 \
  --replicates 3 \
  --max-instances 3000 \
  --max-per-topology 500 \
  --output plans/grid3_7x7x7.jsonl
```

### runner.py
Execute benchmarks across semiring/monoid combinations.

**Modes**:
- `opt`: Find one optimal model (--opt-direction required)
- `optN`: Find all optimal models (--opt-direction required)
- `enum`: Enumerate all models

**Example**:
```bash
python3 src/waba_bench/runner.py \
  --plan plans/my_plan.jsonl \
  --frameworks-dir frameworks/my_exp \
  --semirings godel tropical arctic bottleneck_cost lukasiewicz \
  --monoids max sum min count \
  --mode opt \
  --opt-direction min \
  --max-workers 2 \
  --timeout-seconds 120 \
  --output results/my_exp/opt_min.jsonl
```

### analyzer.py
Analyze benchmark results and generate reports.

**Outputs**:
- `summary.csv`: Grouped statistics
- `BENCHMARK_REPORT.md`: Markdown report
- `plots/`: Visualization plots

**Example**:
```bash
python3 src/waba_bench/analyzer.py \
  --input results/my_exp/opt_min.jsonl \
  --output-dir analysis/my_exp
```

### consistency.py
Verify consistency between opt, optN, and enum modes.

**Checks**:
- opt ⊆ optN (single optimal in all optimal)
- optN ⊆ enum_best (all optimal in enum best)
- Cost consistency across modes

---

## Experimental Design

### Parameters

- **A**: Number of assumptions (e.g., 6, 8, 10, 14, 20, 30, 45)
- **R**: Number of rules (e.g., 1, 2, 3, 4, 5, 7, 10)
- **D**: Derivation depth (e.g., 1, 2, 3, 4, 5, 6, 7)
- **Topology**: linear, tree, cycle, complete, mixed, isolated
- **Weight scheme**: sparse, uniform
- **Replicates**: Independent random seeds (e.g., 1, 2, 3)

### Semirings

- **godel**: Gödel/Fuzzy logic (min/max, identity=#sup)
- **tropical**: Tropical semiring (+/min, identity=#sup)
- **arctic**: Arctic semiring (+/max, identity=0)
- **bottleneck_cost**: Bottleneck-cost (max/min)
- **lukasiewicz**: Łukasiewicz t-norm (bounded sum)

### Monoids

- **max**: Maximum cost aggregation
- **sum**: Sum cost aggregation
- **min**: Minimum cost aggregation
- **count**: Count cost aggregation

---

## Safety Tools

### protect_active_run.py

Detect and prevent modification of active benchmark runs.

```bash
# List protected paths
python3 scripts/protect_active_run.py --list

# Check if a path is protected
python3 scripts/protect_active_run.py --check results/my_exp/enum.jsonl
```

---

## Git Workflow

### Tracked (in git)
- `src/` - Source code
- `scripts/` - Helper scripts
- `README.md`, `*.md` - Documentation
- `.gitignore`

### Ignored (not in git)
- `plans/` - Experimental plans
- `frameworks/` - Generated instances
- `results/` - Benchmark outputs
- `analysis/` - Analysis outputs
- `logs/` - Execution logs
- `archive/` - Old experiments

---

## Legacy Files

Old Python scripts in benchmark root:
- `benchmark_runner.py` → `src/waba_bench/runner.py`
- `planner.py` → `src/waba_bench/planner.py`
- `generate_from_plan.py` → `src/waba_bench/generator.py`
- `analyze_results.py` → `src/waba_bench/analyzer.py`

**To use new structure**:
```bash
# Old way
python3 benchmark_runner.py --plan ...

# New way
python3 src/waba_bench/runner.py --plan ...
# OR
./scripts/run_benchmark.sh --plan ...
```

---

## Documentation

- `REFACTOR_PLAN.md` - Refactoring strategy
- `REFACTOR_SUMMARY.md` - What was changed
- `CLEANUP_COMPLETE.md` - Final cleanup report
- `archive/README.md` - Archived artifacts

---

## Version History

- **v2.0.0** (2025-12-29): Modular refactor, src/ structure
- **v1.0.0** (2024): Initial implementation

---

**Maintained by**: WABA Research Team
**License**: See ../LICENSE
