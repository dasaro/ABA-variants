#!/usr/bin/env python3
"""
Debug UNSAT case studies by analyzing their structure and testing with different configurations
"""

import subprocess
from pathlib import Path

def run_clingo(files, extra_args=[]):
    """Run clingo and return full output"""
    cmd = ['clingo'] + extra_args + files
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
    return result.stdout, result.stderr, result.returncode

def analyze_framework(fw_path):
    """Analyze why a framework is UNSAT"""
    print(f"\n{'='*80}")
    print(f"Analyzing: {fw_path}")
    print(f"{'='*80}")

    # Count basic predicates
    with open(fw_path) as f:
        content = f.read()
        n_assumptions = content.count('assumption(')
        n_contraries = content.count('contrary(')
        n_weights = content.count('weight(')
        n_rules = content.count('head(')

    print(f"\nFramework Structure:")
    print(f"  Assumptions: {n_assumptions}")
    print(f"  Contraries:  {n_contraries}")
    print(f"  Weights:     {n_weights}")
    print(f"  Rules:       {n_rules}")

    # Check for budget declaration
    if 'budget(' in content:
        import re
        budgets = re.findall(r'budget\(([^)]+)\)', content)
        print(f"  Budget:      {budgets}")
    else:
        print(f"  Budget:      NONE (no budget() fact)")

    # Check for #const beta
    if '#const beta' in content:
        import re
        beta = re.findall(r'#const beta\s*=\s*(\d+)', content)
        print(f"  #const beta: {beta}")
    else:
        print(f"  #const beta: NONE")

    base_files = ['core/base.lp', 'semiring/godel.lp', 'filter/standard.lp']

    # Test 1: Grounded with infinite budget
    print(f"\n--- Test 1: Grounded with budget(10000) ---")
    budget_file = '/tmp/debug_budget.lp'
    with open(budget_file, 'w') as f:
        f.write('budget(10000).\n')

    out, err, code = run_clingo(base_files + ['semantics/grounded.lp', fw_path, budget_file],
                                ['-n', '1', '--project'])

    if 'UNSATISFIABLE' in out:
        print("  Result: UNSAT")

        # Try without any budget to see if core is broken
        print(f"\n--- Test 2: Core only (no budget constraint) ---")
        out2, err2, code2 = run_clingo(['core/base.lp', 'semiring/godel.lp', fw_path],
                                       ['-n', '1'])
        if 'Answer:' in out2:
            print("  Result: SAT (core works, issue is with grounded semantics)")
            # Extract what's in the answer
            for line in out2.split('\n'):
                if line.startswith('in('):
                    print(f"    Found in: {line[:100]}")
        else:
            print("  Result: UNSAT (core itself is broken)")
            if err2:
                print(f"    Error: {err2[:200]}")

        # Try with stable semantics
        print(f"\n--- Test 3: Stable semantics with budget(10000) ---")
        out3, err3, code3 = run_clingo(base_files + ['semantics/stable.lp', fw_path, budget_file],
                                       ['-n', '1', '--project'])
        if 'Answer:' in out3:
            print("  Result: SAT (stable works)")
            # Count extensions
            n_in = out3.count('in(')
            print(f"    Found {n_in} in(...) predicates")
        else:
            print("  Result: UNSAT (stable also fails)")

    else:
        print("  Result: SAT")
        # Count extensions
        lines = [l for l in out.split('\n') if l.startswith('in(')]
        if lines:
            print(f"    Extensions found: {len(lines)}")
            for line in lines[:3]:
                print(f"      {line[:80]}")

# UNSAT case studies
unsat_studies = [
    'examples/moral_dilemma/moral_dilemma.lp',
    'examples/legal_precedent/legal_precedent.lp',
    'examples/practical_deliberation/practical_deliberation.lp',
    'examples/epistemic_justification/epistemic_justification.lp',
    'examples/sally_clark_meta_evidence/sally_clark_meta_evidence.lp',
    'examples/meta_evidence_layered/meta_evidence_layered.lp',
    'examples/ai_safety_policy/ai_safety_policy.lp',
    'examples/scientific_discovery_nhst/nhst.lp',
]

print("="*80)
print("DEBUGGING UNSAT CASE STUDIES")
print("="*80)

for fw in unsat_studies:
    if Path(fw).exists():
        try:
            analyze_framework(fw)
        except Exception as e:
            print(f"\nERROR analyzing {fw}: {e}")
    else:
        print(f"\nSkipping {fw} (not found)")

print(f"\n{'='*80}")
print("ANALYSIS COMPLETE")
print(f"{'='*80}\n")
