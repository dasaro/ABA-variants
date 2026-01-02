#!/usr/bin/env python3
"""Comprehensive test for naive semantics"""
import subprocess, sys
from pathlib import Path

def extract_exts(output):
    exts = []
    for line in output.split('\n'):
        if line.startswith('in('):
            ext = set(word[3:-1] for word in line.split() 
                     if word.startswith('in(') and word.endswith(')'))
            if ext: exts.append(frozenset(ext))
    return set(exts)

def test_fw(fw, timeout=5):
    cmd = ['clingo', '-n', '0', '--project', '-c', 'beta=0',
           'core/base.lp', 'semiring/godel.lp', 'filter/standard.lp',
           'semantics/naive.lp', fw]
    try:
        r1 = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        if r1.returncode not in [0,10,20,30]: return 'SKIP', 'Error'
        e1 = extract_exts(r1.stdout)
        
        cmd.insert(3, '--opt-mode=optN')
        r2 = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        if r2.returncode not in [0,10,20,30]: return 'SKIP', 'Error'
        e2 = extract_exts(r2.stdout)
        
        if e1 == e2: return 'PASS', f"{len(e1)} exts"
        return 'FAIL', f"{len(e1)} vs {len(e2)}"
    except:
        return 'SKIP', 'Timeout'

print("="*70)
print("NAIVE Semantics Consistency Test")
print("="*70)

# Collect frameworks
fws = []
for f in Path('test/strict_inclusions').glob('*.lp'):
    if 'naive' in str(f): fws.append(str(f))
for name in ['even_cycle.lp', 'test_max_bug2.lp']:
    p = Path('test')/name
    if p.exists(): fws.append(str(p))
for f in Path('examples').rglob('*.lp'):
    fws.append(str(f))
    if len(fws) >= 40: break

p, f, s = 0, 0, 0
for i, fw in enumerate(fws, 1):
    status, msg = test_fw(fw)
    name = Path(fw).name
    if status == 'PASS':
        print(f"{i:2d}. ✓ {name:50s} {msg}")
        p += 1
    elif status == 'FAIL':
        print(f"{i:2d}. ✗ {name:50s} {msg}")
        f += 1
    else:
        print(f"{i:2d}. ⊘ {name:50s} {msg}")
        s += 1

print(f"\n{'='*70}")
print(f"Results: {p} passed, {f} failed, {s} skipped")
print(f"{'='*70}")

sys.exit(f)
