#!/usr/bin/env python3
"""
Extract extensions from clingo output (only in/1 predicates)
"""
import sys
import re
import subprocess

def extract_extensions(semantic, framework, n_models=0):
    """Run clingo and extract extensions (sets of in/1 atoms)"""

    if semantic in ["grounded", "ideal"]:
        n_models = 1

    cmd = [
        "clingo", f"-n {n_models}",
        "core/base.lp",
        "semiring/godel.lp",
        "constraint/ub_max.lp",
        "filter/standard.lp",
        f"semantics/{semantic}.lp",
        framework
    ]

    result = subprocess.run(cmd, capture_output=True, text=True)

    extensions = []
    current_answer = []
    in_answer = False

    for line in result.stdout.split('\n'):
        if line.startswith('Answer:'):
            in_answer = True
            if current_answer:
                extensions.append(frozenset(current_answer))
            current_answer = []
        elif in_answer and line.strip() == '':
            in_answer = False
            if current_answer:
                extensions.append(frozenset(current_answer))
                current_answer = []
        elif in_answer:
            # Extract only in(...) predicates
            in_preds = re.findall(r'in\(([^)]+)\)', line)
            current_answer.extend(in_preds)

    # Handle last answer
    if current_answer:
        extensions.append(frozenset(current_answer))

    return extensions

def main():
    if len(sys.argv) != 3:
        print("Usage: extract_extensions.py <semantic> <framework.lp>")
        sys.exit(1)

    semantic = sys.argv[1]
    framework = sys.argv[2]

    extensions = extract_extensions(semantic, framework)

    for ext in extensions:
        print("{" + ", ".join(sorted(ext)) + "}")

if __name__ == "__main__":
    main()
