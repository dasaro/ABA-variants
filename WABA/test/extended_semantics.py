#!/usr/bin/env python3
"""Differential checks for the higher-order beta-sigma semantics.

The oracle enumerates assumption sets and affordable discard sets directly from
the mathematical definitions.  The CLI independently enumerates candidates and
applies its per-reduct ASP filters.  The fixtures separate grounded from ideal,
ideal from eager, preferred from semi-stable, and naive from stage, and include a genuinely
collective ABA attack that cannot be represented by a binary assumption graph.
"""

from __future__ import annotations

from pathlib import Path
import re
import subprocess
import tempfile

from finite_aba_oracle import (
    BudgetProfile,
    Framework,
    Rule,
    beta_sigma_pairs,
    direct_graph_framework,
    existential_extensions,
    format_extensions,
)


ROOT = Path(__file__).resolve().parents[1]
SEMANTICS = ("grounded", "naive", "semi-stable", "stage", "ideal", "eager")
PROFILE = BudgetProfile("sum", "ub")


def answer_extensions(stdout: str) -> set[frozenset[str]]:
    """Read simple-symbol in/1 atoms from the CLI's answer-set output."""

    lines = stdout.splitlines()
    result: set[frozenset[str]] = set()
    for index, line in enumerate(lines):
        if not line.startswith("Answer:") or index + 1 >= len(lines):
            continue
        result.add(frozenset(re.findall(r"\bin\((a\d+)\)", lines[index + 1])))
    return result


def solve_cli(path: Path, semantics: str, beta: int) -> set[frozenset[str]]:
    completed = subprocess.run(
        [
            "python3",
            str(ROOT / "bin" / "waba"),
            "run",
            "--framework",
            str(path),
            "--semantics",
            semantics,
            "--semiring",
            "godel",
            "--default-policy",
            "neutral",
            "--objective",
            "sum-min",
            "--budget-mode",
            "ub",
            "--beta",
            str(beta),
            "--show",
            "projection",
        ],
        capture_output=True,
        text=True,
        check=False,
    )
    if completed.returncode != 0:
        raise RuntimeError(
            f"CLI failed for {path.name}/{semantics}/beta={beta}\n"
            f"stdout:\n{completed.stdout}\nstderr:\n{completed.stderr}"
        )
    return answer_extensions(completed.stdout)


def fixtures() -> tuple[Framework, ...]:
    return (
        # ideal={a1,a2}, grounded={a2}
        direct_graph_framework(
            "ideal-not-grounded",
            ("a0", "a1", "a2"),
            frozenset({("a0", "a0"), ("a0", "a1"), ("a1", "a0")}),
        ),
        # ideal=empty, eager={a0}; {a0} is the sole semi-stable extension.
        direct_graph_framework(
            "eager-not-ideal",
            ("a0", "a1", "a2"),
            frozenset(
                {
                    ("a0", "a1"),
                    ("a0", "a2"),
                    ("a1", "a1"),
                    ("a2", "a0"),
                }
            ),
        ),
        # semi-stable={a1}, preferred={{a1},{a2}}
        direct_graph_framework(
            "semistable-not-preferred",
            ("a0", "a1", "a2"),
            frozenset(
                {
                    ("a0", "a0"),
                    ("a1", "a0"),
                    ("a1", "a2"),
                    ("a2", "a1"),
                }
            ),
        ),
        # stage={a0,a2}, naive={{a0,a2},{a1,a2}}
        direct_graph_framework(
            "stage-not-naive",
            ("a0", "a1", "a2"),
            frozenset({("a0", "a1")}),
        ),
        # The support {a1,a2} attacks a0 collectively; neither singleton does.
        Framework(
            name="collective-attack",
            assumptions=("a0", "a1", "a2"),
            contraries=(("a0", "c0"), ("a1", "c1"), ("a2", "c2")),
            rules=(Rule("c0", ("a1", "a2")), Rule("c1", ("a0",))),
            weights=(("c0", 1), ("c1", 2), ("c2", 4)),
        ),
    )


def main() -> int:
    comparisons = 0
    with tempfile.TemporaryDirectory(prefix="waba-extended-semantics-") as directory:
        tmp = Path(directory)
        for framework in fixtures():
            path = tmp / f"{framework.name}.lp"
            path.write_text(framework.to_waba_lp())
            for beta in (0, 2):
                for semantics in SEMANTICS:
                    expected = existential_extensions(
                        beta_sigma_pairs(framework, PROFILE, beta, semantics)
                    )
                    actual = solve_cli(path, semantics, beta)
                    comparisons += 1
                    if actual != expected:
                        raise AssertionError(
                            f"{framework.name}, beta={beta}, {semantics}\n"
                            f"expected {format_extensions(expected)}\n"
                            f"actual   {format_extensions(actual)}"
                        )

    print(
        f"extended semantics differential oracle: {comparisons} "
        "beta-sigma comparisons passed"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
