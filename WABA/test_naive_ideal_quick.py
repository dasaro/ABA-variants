#!/usr/bin/env python3
"""Quick test of naive and ideal semantics"""
import subprocess
import sys

def extract_extensions(output):
    extensions = []
    for line in output.split('\n'):
        if line.startswith('in('):
            extension = set()
            for word in line.split():
                if word.startswith('in(') and word.endswith(')'):
                    extension.add(word[3:-1])
            if extension:
                extensions.append(frozenset(extension))
    return set(extensions)

def test_semantic(semantic, framework_name):
    """Test one semantic on one framework"""
    framework = f"test/strict_inclusions/{framework_name}"
    
    # Enum mode
    cmd = ['clingo', '-n', '0', '--project', '-c', 'beta=0',
           'core/base.lp', 'semiring/godel.lp', 'filter/standard.lp',
           f'semantics/{semantic}.lp', framework]
    
    # For ideal (heuristic-based), add heuristic flags
    if semantic == 'ideal':
        cmd.extend(['--heuristic=Domain', '--enum-mode=domRec'])
    
    r1 = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
    e1 = extract_extensions(r1.stdout)
    
    # OptN mode  
    cmd.insert(3, '--opt-mode=optN')
    r2 = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
    e2 = extract_extensions(r2.stdout)
    
    match = "✓" if e1 == e2 else "✗"
    return match, len(e1), len(e2)

# Test cases
tests = [
    ('naive', 'stable_subset_naive.lp'),
    ('naive', 'NEW_stable_naive.lp'),
    ('naive', 'naive_subset_cf.lp'),
    ('ideal', 'grounded_subset_ideal.lp'),
    ('ideal', 'grounded_ideal_selfattack.lp'),
]

print("Quick Consistency Test - Naive & Ideal")
print("=" * 60)
for semantic, framework in tests:
    try:
        match, n1, n2 = test_semantic(semantic, framework)
        print(f"{match} {semantic:10s} {framework:40s} {n1} == {n2}")
    except Exception as e:
        print(f"✗ {semantic:10s} {framework:40s} ERROR: {e}")

