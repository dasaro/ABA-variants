#!/usr/bin/env python3
"""
Evaluate all case-study examples with production-ready semantics
Tests each case study with all 5 production semantics in enumeration mode
"""

import subprocess
import sys
from pathlib import Path
from collections import defaultdict

def run_semantic(semantic, framework, timeout=10):
    """Run one semantic on one framework"""
    # Create temporary budget file for frameworks that don't define budget()
    import tempfile
    budget_file = tempfile.NamedTemporaryFile(mode='w', suffix='.lp', delete=False)
    budget_file.write('budget(beta).  % Use framework-defined beta value\n')
    budget_file.close()

    cmd = [
        'clingo', '-n', '0', '--project', '--opt-mode=ignore',
        'core/base.lp', 'semiring/godel.lp', 'filter/standard.lp',
        f'semantics/{semantic}.lp', framework, budget_file.name
    ]

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)

        # Clean up temporary budget file
        import os
        try:
            os.unlink(budget_file.name)
        except:
            pass

        if result.returncode not in [0, 10, 20, 30]:
            return None, 'ERROR', result.stderr[:200]

        # Extract extensions
        extensions = []
        lines = result.stdout.split('\n')
        in_answer = False
        for i, line in enumerate(lines):
            if line.startswith('Answer:'):
                in_answer = True
            elif in_answer and 'in(' in line:
                # Extract all in(...) predicates from this answer
                ext = set()
                for word in line.split():
                    if word.startswith('in(') and word.endswith(')'):
                        ext.add(word[3:-1])
                if ext:
                    extensions.append(sorted(ext))
                in_answer = False  # Move to next answer

        return extensions, 'OK', None
    except subprocess.TimeoutExpired:
        # Clean up on timeout
        import os
        try:
            os.unlink(budget_file.name)
        except:
            pass
        return None, 'TIMEOUT', None
    except Exception as e:
        # Clean up on error
        import os
        try:
            os.unlink(budget_file.name)
        except:
            pass
        return None, 'ERROR', str(e)[:200]

# Case study examples (excluding deprecated)
case_studies = [
    ('Medical Triage', 'examples/medical_triage/medical_triage.lp'),
    ('Moral Dilemma', 'examples/moral_dilemma/moral_dilemma.lp'),
    ('Scientific Theory', 'examples/scientific_theory/scientific_theory.lp'),
    ('Legal Precedent', 'examples/legal_precedent/legal_precedent.lp'),
    ('Resource Allocation', 'examples/resource_allocation/resource_allocation.lp'),
    ('Practical Deliberation', 'examples/practical_deliberation/practical_deliberation.lp'),
    ('Epistemic Justification', 'examples/epistemic_justification/epistemic_justification.lp'),
    ('Sally Clark Evidence', 'examples/sally_clark_meta_evidence/sally_clark_meta_evidence.lp'),
    ('Meta Evidence Layered', 'examples/meta_evidence_layered/meta_evidence_layered.lp'),
    ('AI Safety Policy', 'examples/ai_safety_policy/ai_safety_policy.lp'),
    ('NHST Discovery', 'examples/scientific_discovery_nhst/nhst.lp'),
]

# Production semantics
semantics = ['grounded', 'preferred', 'semi-stable', 'staged', 'naive']

print("="*100)
print("CASE STUDY EVALUATION - Production Semantics (Enumeration Mode)")
print("="*100)
print()

# Test each case study
results = {}
for name, framework in case_studies:
    if not Path(framework).exists():
        print(f"⊘ {name:30s} - File not found: {framework}")
        continue

    print(f"\n{'='*100}")
    print(f"Case Study: {name}")
    print(f"Framework: {framework}")
    print(f"{'='*100}")

    results[name] = {}

    for semantic in semantics:
        extensions, status, error = run_semantic(semantic, framework)
        results[name][semantic] = (extensions, status, error)

        if status == 'OK':
            print(f"  {semantic:15s}: {len(extensions):2d} extension(s)")
            for i, ext in enumerate(extensions, 1):
                ext_str = '{' + ', '.join(ext) + '}'
                if len(ext_str) > 80:
                    ext_str = ext_str[:77] + '...'
                print(f"    E{i}: {ext_str}")
        elif status == 'TIMEOUT':
            print(f"  {semantic:15s}: TIMEOUT (>{10}s)")
        else:
            print(f"  {semantic:15s}: ERROR - {error}")

# Summary table
print(f"\n\n{'='*100}")
print("SUMMARY TABLE")
print(f"{'='*100}\n")

print(f"{'Case Study':<30s} {'Grounded':<12s} {'Preferred':<12s} {'Semi-Stable':<12s} {'Staged':<12s} {'Naive':<12s}")
print("-" * 100)

for name in [n for n, _ in case_studies]:
    if name not in results:
        continue

    row = f"{name:<30s}"
    for semantic in semantics:
        if semantic not in results[name]:
            row += f" {'N/A':<12s}"
            continue

        extensions, status, _ = results[name][semantic]
        if status == 'OK':
            row += f" {len(extensions):2d} ext      "
        elif status == 'TIMEOUT':
            row += f" {'TIMEOUT':<12s}"
        else:
            row += f" {'ERROR':<12s}"
    print(row)

# Statistics
print(f"\n{'='*100}")
print("STATISTICS")
print(f"{'='*100}\n")

for semantic in semantics:
    completed = sum(1 for name in results for s in [semantic]
                   if s in results[name] and results[name][s][1] == 'OK')
    timeouts = sum(1 for name in results for s in [semantic]
                  if s in results[name] and results[name][s][1] == 'TIMEOUT')
    errors = sum(1 for name in results for s in [semantic]
                if s in results[name] and results[name][s][1] == 'ERROR')
    total = len(results)

    print(f"{semantic:15s}: {completed:2d}/{total} completed, {timeouts:2d} timeouts, {errors:2d} errors")

print()
