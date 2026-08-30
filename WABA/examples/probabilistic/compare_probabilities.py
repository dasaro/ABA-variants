#!/usr/bin/env python3
"""Reproduce the ProbLog-marginal versus tropical-wABA comparison.

ProbLog is intentionally an optional dependency of WABA.  Install it in a virtual
environment (`python -m pip install problog`) and either put its `problog` command
on PATH or pass its path with `--problog`.
"""

from __future__ import annotations

import argparse
import math
import re
import shutil
import subprocess
from pathlib import Path


EXPECTED_PROBLOG = {"grass_wet": 0.970, "slippery": 0.485}
EXPECTED_WABA_WEIGHTS = {"grass_wet": 105, "slippery": 798}


def run(command: list[str]) -> str:
    completed = subprocess.run(command, capture_output=True, text=True)
    if completed.returncode != 0:
        detail = completed.stderr.strip() or completed.stdout.strip()
        raise SystemExit(f"command failed ({completed.returncode}): {' '.join(command)}\n{detail}")
    return completed.stdout


def parse_problog(output: str) -> dict[str, float]:
    values: dict[str, float] = {}
    for atom in EXPECTED_PROBLOG:
        match = re.search(rf"(?m)^\s*{re.escape(atom)}\s*:\s*([0-9.eE+-]+)\s*$", output)
        if match is None:
            raise SystemExit(f"ProbLog output contains no value for {atom!r}:\n{output}")
        values[atom] = float(match.group(1))
    return values


def parse_waba(output: str) -> dict[str, int]:
    values: dict[str, int] = {}
    for atom in EXPECTED_WABA_WEIGHTS:
        matches = {
            int(value)
            for value in re.findall(
                rf"supported_with_weight\({re.escape(atom)},([0-9]+)\)", output
            )
        }
        if len(matches) != 1:
            raise SystemExit(
                f"expected one propagated weight for {atom!r}, got {sorted(matches)}:\n{output}"
            )
        values[atom] = matches.pop()
    return values


def main() -> int:
    here = Path(__file__).resolve().parent
    root = here.parent.parent

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--problog",
        default=shutil.which("problog"),
        help="path to the ProbLog command (default: search PATH)",
    )
    args = parser.parse_args()
    if args.problog is None:
        raise SystemExit(
            "ProbLog is not installed. Install it in a virtual environment with "
            "`python -m pip install problog`, then pass `<venv>/bin/problog` with --problog."
        )

    problog_values = parse_problog(run([args.problog, str(here / "probabilistic.pl")]))
    waba_output = run(
        [
            str(root / "bin" / "waba"),
            "run",
            "--framework",
            str(here / "probabilistic.lp"),
            "--semiring",
            "tropical",
            "--semantics",
            "stable",
            "--show",
            "standard",
        ]
    )
    waba_weights = parse_waba(waba_output)

    for atom, expected in EXPECTED_PROBLOG.items():
        if not math.isclose(problog_values[atom], expected, rel_tol=0.0, abs_tol=1e-9):
            raise SystemExit(
                f"unexpected ProbLog value for {atom}: {problog_values[atom]} != {expected}"
            )
    if waba_weights != EXPECTED_WABA_WEIGHTS:
        raise SystemExit(f"unexpected wABA weights: {waba_weights} != {EXPECTED_WABA_WEIGHTS}")

    print("query       ProbLog marginal    tropical wABA best proof")
    for atom in ("grass_wet", "slippery"):
        weight = waba_weights[atom]
        decoded = math.exp(-weight / 1000)
        print(f"{atom:11} {problog_values[atom]:.6f}            {decoded:.6f}  (weight {weight})")
    print("\nChecks passed: ProbLog combines overlapping worlds; tropical wABA keeps one best proof.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
