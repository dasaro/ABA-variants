# Archive Directory

This directory contains archived code snapshots and old experimental artifacts.

---

## running_snapshot_20251229_032700/

**Purpose**: Snapshot of code currently executing enum + optN benchmarks

**Contents**:
- `benchmark_runner.py` - Running benchmark script (PID 79426, 9719)
- `planner.py` - Plan generator
- `generate_from_plan.py` - Framework generator
- `analyze_results.py` - Results analyzer
- `utils.py` - Shared utilities
- `git_hash.txt` - Git commit: d14e61c

**DO NOT DELETE**: Required for rollback if active runs fail

**Safe to delete after**: enum + optN complete successfully

---

## artifacts_20251229/

**Purpose**: Old experimental runs and deprecated directories

**Contents**:
- `TOPOLOGY_DIAGRAMS/` - Topology visualization diagrams
- `analysis_v4/` - Old analysis results (v4 implementation)
- `frameworks_v4/` - Old framework instances (v4)
- `results_v4/` - Old benchmark results (v4)
- `smoke_results/` - Quick smoke test results
- `test_frameworks/` - Development test instances
- `test_frameworks_run2/` - Development test instances (run 2)

**Why archived**:
- Not referenced by current active runs (grid3_7x7x7_rep3)
- Superseded by newer implementations
- Development/testing artifacts

**Safe to delete**: Yes, after quick review to confirm no valuable data

**Total size**: ~Several MB

---

## Archive Policy

1. **Keep snapshots** until corresponding runs complete successfully
2. **Review artifacts** before permanent deletion
3. **Document** what's archived and why
4. **Never delete** snapshots of actively running code

---

**Last updated**: 2025-12-29
