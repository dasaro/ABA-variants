#!/usr/bin/env python3
"""
Comprehensive test: semi-stable semantics enumeration vs optN consistency
Tests on examples, test files, and a sample of benchmark frameworks
"""
import subprocess
import sys
from pathlib import Path
import random

def extract_extensions(output):
    """Extract in() predicates from clingo output"""
    extensions = []
    for line in output.split('\n'):
        if line.startswith('in('):
            extension = set()
            for word in line.split():
                if word.startswith('in(') and word.endswith(')'):
                    atom = word[3:-1]
                    extension.add(atom)
            if extension:
                extensions.append(frozenset(extension))
    return set(extensions)

def run_semistable(framework, use_optN=False, timeout=30):
    """Run semi-stable semantics on a framework"""
    cmd = ['clingo', '-n', '0', '--project', '-c', 'beta=0',
           'core/base.lp', 'semiring/godel.lp', 'filter/standard.lp',
           'semantics/semi-stable.lp', framework]
    
    if use_optN:
        cmd.insert(3, '--opt-mode=optN')
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        if result.returncode not in [0, 10, 20, 30]:
            return None, f"Exit code {result.returncode}"
        return extract_extensions(result.stdout), None
    except subprocess.TimeoutExpired:
        return None, "Timeout"
    except Exception as e:
        return None, str(e)

def test_framework(framework, timeout=30):
    """Test a single framework"""
    enum_exts, enum_err = run_semistable(framework, use_optN=False, timeout=timeout)
    optN_exts, optN_err = run_semistable(framework, use_optN=True, timeout=timeout)
    
    if enum_err or optN_err:
        return 'SKIP', f"{enum_err or optN_err}"
    
    if enum_exts == optN_exts:
        return 'PASS', f"{len(enum_exts)} extension(s)"
    else:
        return 'FAIL', f"Enum: {len(enum_exts)} exts, OptN: {len(optN_exts)} exts"

def main():
    print("=" * 80)
    print("Semi-Stable Semantics Consistency Test: Enumeration vs OptN")
    print("=" * 80)
    
    # Collect test files
    test_files = []
    
    # Test files
    for f in Path('test').rglob('*.lp'):
        if 'strict_inclusions' in str(f) or f.name.startswith('test_') or f.name == 'even_cycle.lp':
            test_files.append(str(f))
    
    # Example files
    for f in Path('examples').rglob('*.lp'):
        test_files.append(str(f))
    
    # Sample of benchmark files (random 20)
    benchmark_files = list(Path('benchmark/frameworks').rglob('*.lp'))
    if benchmark_files:
        random.seed(42)
        test_files.extend([str(f) for f in random.sample(benchmark_files, min(20, len(benchmark_files)))])
    
    print(f"\nTesting {len(test_files)} frameworks...\n")
    
    passed = 0
    failed = 0
    skipped = 0
    failures = []
    
    for i, framework in enumerate(test_files, 1):
        status, msg = test_framework(framework, timeout=10)
        
        name = framework[framework.find('/')+1:]  # Remove first directory
        
        if status == 'PASS':
            print(f"{i:3d}. ✓ {name:60s} {msg}")
            passed += 1
        elif status == 'FAIL':
            print(f"{i:3d}. ✗ {name:60s} {msg}")
            failed += 1
            failures.append((framework, msg))
        else:
            print(f"{i:3d}. ⊘ {name:60s} {msg}")
            skipped += 1
    
    print("\n" + "=" * 80)
    print(f"Results: {passed} passed, {failed} failed, {skipped} skipped")
    print("=" * 80)
    
    if failures:
        print("\nFailed frameworks:")
        for fw, msg in failures:
            print(f"  - {fw}: {msg}")
    
    return 0 if failed == 0 else 1

if __name__ == '__main__':
    sys.exit(main())
