# Benchmark Directory Refactor Plan

**Status**: IN PROGRESS
**Created**: 2025-12-29
**Active Runs**: enum (945/60k), optN_min (5/60k)

---

## Objectives

1. **Separate code from artifacts** - Clean code/data distinction
2. **Archive old experiments** - Move deprecated runs to archive/
3. **Protect active runs** - Zero disruption to ongoing benchmarks
4. **Improve maintainability** - Clear structure for future work

---

## Target Layout (Clean Structure)

```
benchmark/
├── README.md                           # Main documentation
├── REFACTOR_PLAN.md                    # This file
├── .gitignore                          # Proper artifact exclusions
│
├── src/                                # SOURCE CODE (tracked in git)
│   └── waba_bench/
│       ├── __init__.py
│       ├── planner.py                  # Plan generator
│       ├── runner.py                   # Benchmark runner (refactored)
│       ├── analyzer.py                 # Results analysis
│       ├── consistency.py              # Consistency checker
│       ├── utils.py                    # Shared utilities
│       └── generator/                  # Framework generators
│           ├── __init__.py
│           ├── framework_templates.py
│           ├── dimension_config.py
│           └── topology.py
│
├── scripts/                            # HELPER SCRIPTS
│   ├── run_planner.sh
│   ├── run_benchmark.sh
│   ├── run_analysis.sh
│   └── protect_active_run.py           # Safety tool
│
├── plans/                              # PLANS (artifacts, gitignored)
│   ├── plan_grid3_7x7x7_rep3.jsonl     # PROTECTED - active run
│   └── *.jsonl
│
├── frameworks/                         # FRAMEWORKS (artifacts, gitignored)
│   ├── grid3_7x7x7_rep3/               # PROTECTED - active run
│   └── */
│
├── results/                            # RESULTS (artifacts, gitignored)
│   ├── grid3_7x7x7_rep3/               # PROTECTED - active run
│   │   ├── enum.jsonl                  # PROTECTED - actively written
│   │   ├── optN_min.jsonl              # PROTECTED - actively written
│   │   ├── opt_min.jsonl               # Complete
│   │   └── opt_max.jsonl               # Complete
│   └── */
│
├── analysis/                           # ANALYSIS (artifacts, gitignored)
│   ├── grid3_7x7x7_rep3/
│   │   └── opt_only/                   # Complete analysis
│   └── */
│
├── logs/                               # LOGS (artifacts, gitignored)
│   ├── enum.log                        # PROTECTED - actively written
│   ├── optN_min.log                    # PROTECTED - actively written
│   ├── opt_min.log                     # Complete
│   └── opt_max.log                     # Complete
│
└── archive/                            # ARCHIVED OLD EXPERIMENTS
    ├── running_snapshot_20251229_032700/   # Snapshot of active code
    │   ├── benchmark_runner.py
    │   ├── planner.py
    │   ├── generate_from_plan.py
    │   └── git_hash.txt
    └── artifacts_20251229/             # Old experiments
        ├── test_frameworks/
        ├── test_frameworks_run2/
        ├── frameworks_v4/
        ├── analysis_v4/
        ├── results_v4/
        ├── smoke_results/
        └── TOPOLOGY_DIAGRAMS/
```

---

## Execution Plan

### Phase 1: Snapshot Active Code (SAFE - READ ONLY)
✅ **DONE** - Created snapshot to preserve running code

### Phase 2: Archive Old Artifacts (SAFE - MOVE NON-ACTIVE)
Move old experiment directories to `archive/artifacts_20251229/`:
- `test_frameworks/` → archive/
- `test_frameworks_run2/` → archive/
- `frameworks_v4/` → archive/
- `analysis_v4/` → archive/
- `results_v4/` → archive/
- `smoke_results/` → archive/
- `TOPOLOGY_DIAGRAMS/` → archive/
- `results/three_mode_test/` → archive/ (if exists)
- `results/new_mode_analysis/` → archive/ (if exists)

### Phase 3: Update .gitignore (SAFE - METADATA ONLY)
Configure proper tracking:
- **Track**: src/, scripts/, README.md, REFACTOR_PLAN.md
- **Ignore**: plans/, frameworks/, results/, analysis/, logs/, archive/

### Phase 4: Create Safety Tool (SAFE - NEW FILE)
Add `scripts/protect_active_run.py` to detect and prevent modifications to active runs.

### Phase 5: Post-Cleanup Validation (SAFE - READ ONLY)
Verify active runs continue without disruption.

### Phase 6: Future Work (AFTER ENUM COMPLETES)
- Refactor benchmark_runner.py → src/waba_bench/runner.py
- Move planner.py → src/waba_bench/planner.py
- Consolidate generator/ → src/waba_bench/generator/
- Move analyze_results.py → src/waba_bench/analyzer.py

---

## Safety Guarantees

1. **benchmark_runner.py** - NOT MODIFIED (running script)
2. **plans/plan_grid3_7x7x7_rep3.jsonl** - NOT TOUCHED
3. **frameworks/grid3_7x7x7_rep3/** - NOT TOUCHED
4. **results/grid3_7x7x7_rep3/** - NOT TOUCHED
5. **logs/enum.log, logs/optN_min.log** - NOT TOUCHED
6. All moves are of OLD, INACTIVE artifacts only

---

## Rollback Plan

If anything breaks:
1. `cp -r archive/running_snapshot_20251229_032700/* .`
2. Resume from existing results/grid3_7x7x7_rep3/ state

---

## Post-Enum Cleanup Checklist

After enum + optN complete:
- [ ] Refactor benchmark_runner.py into modular src/ structure
- [ ] Move all Python scripts to src/waba_bench/
- [ ] Update import paths
- [ ] Add pyproject.toml or requirements.txt
- [ ] Archive completed grid3_7x7x7_rep3 results
- [ ] Clean up old analysis artifacts
