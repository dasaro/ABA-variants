#!/usr/bin/env python3
"""Focused checks for the data-only framework source boundary."""

from __future__ import annotations

import json
import sys
import tempfile
from pathlib import Path

from clingo import SymbolType, ast

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "bin"))

from framework_source import FrameworkSourceError, validate_framework_sources  # noqa: E402


def write(path: Path, source: str) -> Path:
    path.write_text(source, encoding="utf-8")
    return path


def expect_ok(path: Path) -> None:
    validate_framework_sources(path, ROOT)


def expect_rejected(path: Path, fragment: str) -> None:
    try:
        validate_framework_sources(path, ROOT)
    except FrameworkSourceError as exc:
        if fragment not in str(exc):
            raise AssertionError(f"{path.name}: expected {fragment!r}, got {exc!s}") from exc
    else:
        raise AssertionError(f"{path.name}: unsafe source was accepted")


def policy_covers_solver_predicates() -> None:
    policy = json.loads((ROOT / "input-policy.json").read_text(encoding="utf-8"))
    public = set(policy["frameworkPredicates"])
    reserved = set(policy["reservedPredicates"])
    reserved_constants = set(policy["reservedConstants"])
    authoritative_constants = set(policy["authoritativeConstants"])
    assert policy["frameworkPredicates"] == {
        "assumption": 1,
        "contrary": 2,
        "head": 2,
        "body": 2,
        "weight": 2,
    }

    observed: set[str] = set()
    observed_constants: set[str] = set()

    def visit(node: ast.AST) -> None:
        if node.ast_type == ast.ASTType.SymbolicAtom:
            symbol = node.symbol
            if symbol.ast_type == ast.ASTType.Function:
                observed.add(symbol.name)
            elif symbol.ast_type == ast.ASTType.Pool:
                observed.update(
                    item.name for item in symbol.arguments
                    if item.ast_type == ast.ASTType.Function
                )
        elif node.ast_type in (ast.ASTType.ShowSignature, ast.ASTType.ProjectSignature):
            observed.add(node.name)
        elif (
            node.ast_type == ast.ASTType.SymbolicTerm
            and node.symbol.type == SymbolType.Function
            and not node.symbol.arguments
        ):
            observed_constants.add(node.symbol.name)
        for key in node.keys():
            value = getattr(node, key)
            if isinstance(value, ast.AST):
                visit(value)
            elif isinstance(value, ast.ASTSequence):
                for item in value:
                    visit(item)

    files = [ROOT / "validate.lp"]
    for directory in (
        "core", "semiring", "defaults", "monoid", "optimize", "constraint", "filter", "semantics"
    ):
        files.extend((ROOT / directory).glob("*.lp"))
    for path in files:
        ast.parse_files([str(path)], visit)

    missing = sorted(observed - public - reserved)
    assert not missing, f"input-policy.json does not reserve solver predicates: {missing}"
    missing_constants = sorted(
        observed_constants - reserved_constants - authoritative_constants
    )
    assert not missing_constants, (
        f"input-policy.json does not reserve solver constants: {missing_constants}"
    )


def main() -> int:
    policy_covers_solver_predicates()
    with tempfile.TemporaryDirectory(prefix="waba-input-boundary-") as raw:
        temp = Path(raw)
        included = write(
            temp / "included.lp",
            '%* in(a). weight(a,999). *%\n'
            'assumption(a;f(2,"quoted.value")).\n'
            'contrary(a,ca;f(2,"quoted.value"),cf).\n'
            'head(r(1),ca; r(2),cf). body(r(1),f(2,"quoted.value")).\n'
            'weight(a,scale; f(2,"quoted.value"),2).\n',
        )
        root = write(temp / "legal.lp", '#const scale=1.\n#include "included.lp".\n')
        expect_ok(root)
        expect_ok(included)

        rejected = {
            "candidate-weight.lp": (
                "assumption(a). contrary(a,ca). weight(a,1) :- in(a).", "rules and constraints"
            ),
            "derived-input.lp": (
                "seed(a). assumption(a) :- seed(a).", "not a framework predicate"
            ),
            "runtime-fact.lp": ("assumption(a). contrary(a,ca). in(a).", "reserved"),
            "discard-fact.lp": (
                "assumption(a). contrary(a,ca). discarded_attack(ca,a,0).", "reserved"
            ),
            "constraint.lp": ("assumption(a). contrary(a,ca). :- out(a).", "rules and constraints"),
            "show.lp": ("assumption(a). contrary(a,ca). #show in/1.", "directive"),
            "project.lp": ("assumption(a). contrary(a,ca). #project in/1.", "directive"),
            "minimize.lp": ("assumption(a). contrary(a,ca). #minimize { 1@1,a : in(a) }.", "directive"),
            "program.lp": ("#program injected. assumption(a). contrary(a,ca).", "directive"),
            "external.lp": ("#external in(a). assumption(a). contrary(a,ca).", "directive"),
            "constant-injection.lp": (
                "#const max=min. assumption(a). contrary(a,ca).", "implementation term"
            ),
            "variable.lp": ("assumption(X).", "must be ground"),
            "old-budget.lp": ("assumption(a). contrary(a,ca). budget(0).", "not a framework predicate"),
            "wrong-arity.lp": ("assumption(a,b).", "expects arity 1"),
        }
        for name, (source, fragment) in rejected.items():
            expect_rejected(write(temp / name, source), fragment)

        write(temp / "bad-include.lp", "assumption(a). contrary(a,ca). in(a).")
        expect_rejected(
            write(temp / "include-root.lp", '#include "bad-include.lp".'),
            "reserved",
        )

    print("input boundary tests passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
