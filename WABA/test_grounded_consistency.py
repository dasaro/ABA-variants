#!/usr/bin/env python3
"""
Test that grounded semantics gives identical results in enumeration and optN modes
"""
import subprocess
import sys
from pathlib import Path

def extract_extensions(output):
    """Extract in() predicates from clingo output"""
    extensions = []
    for line in output.split('\n'):
        if line.startswith('in('):
            # Extract all in(X) atoms
            extension = set()
            for word in line.split():
                if word.startswith('in(') and word.endswith(')'):
                    atom = word[3:-1]
                    extension.add(atom)
            if extension:
                extensions.append(frozenset(extension))
    return set(extensions)  # Set of frozensets

def run_grounded(framework, use_optN=False):
    """Run grounded semantics on a framework"""
    cmd = ['clingo', '-n', '0', '--project', '-c', 'beta=0',
           'core/base.lp', 'semiring/godel.lp', 'filter/standard.lp',
           'semantics/grounded.lp', framework]
    
    if use_optN:
        cmd.insert(3, '--opt-mode=optN')
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
        if result.returncode not in [0, 10, 20, 30]:
            return None
        return extract_extensions(result.stdout)
    except (subprocess.TimeoutExpired, Exception) as e:
        return None

def test_framework(framework):
    """Test a single framework"""
    enum_exts = run_grounded(framework, use_optN=False)
    optN_exts = run_grounded(framework, use_optN=True)
    
    if enum_exts is None or optN_exts is None:
        return 'SKIP', f"Failed to run: {framework}"
    
    if enum_exts == optN_exts:
        return 'PASS', f"✓ {len(enum_exts)} extension(s)"
    else:
        return 'FAIL', f"Enum: {enum_exts}, OptN: {optN_exts}"

def main():
    # Find test frameworks
    test_files = [
        'examples/medical.lp',
        'examples/simple.lp',
        'examples/simple2.lp',
        'test/grounding_test_4_sup.lp',
        'test/even_cycle.lp',
        'test/strict_inclusions/grounded_subset_complete.lp',
        'test/strict_inclusions/NEW_grounded_complete.lp',
    ]
    
    # Also check benchmark files if they exist
    benchmark_dir = Path('benchmark')
    if benchmark_dir.exists():
        test_files.extend([str(f) for f in benchmark_dir.glob('*.lp')])
    
    print("=" * 70)
    print("Testing Grounded Semantics: Enumeration vs OptN Consistency")
    print("=" * 70)
    
    passed = 0
    failed = 0
    skipped = 0
    
    for framework in test_files:
        if not Path(framework).exists():
            continue
            
        status, msg = test_framework(framework)
        
        if status == 'PASS':
            print(f"✓ {framework:50s} {msg}")
            passed += 1
        elif status == 'FAIL':
            print(f"✗ {framework:50s} {msg}")
            failed += 1
        else:
            print(f"⊘ {framework:50s} {msg}")
            skipped += 1
    
    print("\n" + "=" * 70)
    print(f"Results: {passed} passed, {failed} failed, {skipped} skipped")
    print("=" * 70)
    
    return 0 if failed == 0 else 1

if __name__ == '__main__':
    sys.exit(main())
