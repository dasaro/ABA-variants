#!/usr/bin/env python3
"""Debug script to investigate semantics failures."""

import subprocess
from pathlib import Path

def run_and_show(semantics, framework, use_heuristics=False):
    """Run semantics and show full output."""
    waba_root = Path("/Users/fdasaro/Desktop/WABA-claude/ABA-variants/WABA")

    cmd = ["clingo", "-n", "0"]
    if use_heuristics:
        cmd.extend(["--heuristic=Domain", "--enum=domRec"])

    cmd.extend([
        str(waba_root / "core/base.lp"),
        str(waba_root / "semiring/godel.lp"),
        str(waba_root / "monoid/max_minimization.lp"),
        str(waba_root / "filter/standard.lp"),
        str(waba_root / f"semantics/{semantics}.lp"),
        str(framework)
    ])

    print(f"\n{'='*80}")
    print(f"Semantics: {semantics}")
    print(f"Framework: {framework.name}")
    print(f"Heuristics: {use_heuristics}")
    print(f"{'='*80}")

    result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)

    # Extract just the Answer lines and in() predicates
    for line in result.stdout.split('\n'):
        if line.startswith("Answer:") or "in(" in line:
            if line.startswith("Answer:"):
                print(f"\n{line}")
            else:
                # Extract in() predicates
                in_atoms = [token for token in line.split() if token.startswith("in(")]
                if in_atoms:
                    print(f"  {' '.join(in_atoms)}")

    # Show model count
    for line in result.stdout.split('\n'):
        if line.startswith("Models"):
            print(f"\n{line}")


# Test the failing relations
framework = Path("/Users/fdasaro/Desktop/WABA-claude/ABA-variants/WABA/examples/medical_triage/medical_triage.lp")

print("INVESTIGATING FAILING SUBSET RELATIONS\n")

print("\n" + "█" * 80)
print("ISSUE 1: complete ⊄ admissible")
print("█" * 80)
run_and_show("complete", framework, False)
run_and_show("admissible", framework, False)

print("\n" + "█" * 80)
print("ISSUE 2: semi-stable ⊄ preferred")
print("█" * 80)
run_and_show("semi-stable", framework, True)
run_and_show("preferred", framework, True)

print("\n" + "█" * 80)
print("ISSUE 3: admissible ⊄ cf")
print("█" * 80)
run_and_show("admissible", framework, False)
run_and_show("cf", framework, False)
