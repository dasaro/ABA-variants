#!/usr/bin/env python3
import subprocess
import re

semantic = "grounded"
framework = "test/aspforaba_journal_example.lp"

cmd = [
    "clingo", "-n", "1",
    "core/base.lp",
    "semiring/godel.lp",
    "constraint/ub_max.lp",
    "filter/standard.lp",
    f"semantics/{semantic}.lp",
    framework
]

result = subprocess.run(cmd, capture_output=True, text=True)

print("STDOUT:")
print(result.stdout)
print("\nSTDERR:")
print(result.stderr)
print("\nReturn code:", result.returncode)

extensions = []
current_answer = []
in_answer = False

for i, line in enumerate(result.stdout.split('\n')):
    print(f"Line {i}: {repr(line)}")
    if line.startswith('Answer:'):
        print(f"  -> Found Answer line")
        in_answer = True
        if current_answer:
            extensions.append(frozenset(current_answer))
        current_answer = []
        in_preds = re.findall(r'in\(([^)]+)\)', line)
        print(f"  -> Extracted from Answer line: {in_preds}")
        current_answer.extend(in_preds)
    elif in_answer and (line.strip() == '' or line.startswith('SATISFIABLE') or line.startswith('UNSATISFIABLE') or line.startswith('OPTIMUM')):
        print(f"  -> End of answer (current_answer={current_answer})")
        in_answer = False
        if current_answer:
            extensions.append(frozenset(current_answer))
            current_answer = []
    elif in_answer:
        in_preds = re.findall(r'in\(([^)]+)\)', line)
        print(f"  -> Extracted: {in_preds}")
        current_answer.extend(in_preds)

if current_answer:
    extensions.append(frozenset(current_answer))

print("\nExtensions:", extensions)
