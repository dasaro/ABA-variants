#!/usr/bin/env python3
"""Finite-framework differential oracle for the unified beta-sigma pipeline.

The suite has three independent layers:

* ``finite_aba_oracle.py`` evaluates the mathematical ABA definitions by
  enumerating assumption supports and affordable atom-level discard sets;
* the WABA modules enumerate exact ``(extension, D)`` witnesses before any
  projection, and the shipped preferred filter is exercised on those witnesses;
* when ASPforABA is installed, every reduct of the curated structured fixtures
  is translated back to ordinary ABA with fresh target bridges and checked
  against its encodings.

The original direct-graph fixtures and their all-five-semantics projected-union
checks are retained, while admissible, complete, and P1 preferred now also have
exact witness-level correspondence checks.
"""

from __future__ import annotations

from dataclasses import dataclass
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time
from typing import Iterable

from finite_aba_oracle import (
    Attack,
    BudgetProfile,
    DiscardSet,
    Extension,
    Framework,
    Witness,
    beta_sigma_pairs,
    curated_structured_frameworks,
    direct_graph_framework,
    existential_extensions,
    format_extensions,
    format_witnesses,
    powerset,
    preferred_from_admissible_extensions,
    ranked_two_assumption_frameworks,
)


ROOT = Path(__file__).resolve().parents[1]
CLINGO = os.environ.get("CLINGO", "clingo")
ASPFORABA = Path(
    os.environ.get("ASPFORABA", "/Users/fdasaro/Downloads/aspforaba/encodings")
)
SUM_UB = BudgetProfile("sum", "ub")
MAX_UB = BudgetProfile("max", "ub")
NODES = ("a", "b", "c")


# Reproduced from ASPforABA's encoder.py, as in recovery_sweep.py.  The installed
# encodings directory has first-party stable/complete files but no standalone
# admissible enumeration file.
ASPFORABA_COMMON = """
{ in(X) : assumption(X) }.
out(X) :- not in(X), assumption(X).
supported(X) :- assumption(X), in(X).
supported(X) :- head(R,X), triggered_by_in(R).
triggered_by_in(R) :- head(R,_), supported(X) : body(R,X).
:- in(X), contrary(X,Y), supported(Y).
defeated(X) :- supported(Y), contrary(X,Y).
#show in/1.
"""

ASPFORABA_ADMISSIBLE = """
derived_from_undefeated(X) :- assumption(X), not defeated(X).
derived_from_undefeated(X) :- head(R,X), triggered_by_undefeated(R).
triggered_by_undefeated(R) :- head(R,_), derived_from_undefeated(X) : body(R,X).
attacked_by_undefeated(X) :- contrary(X,Y), derived_from_undefeated(Y).
:- in(X), attacked_by_undefeated(X).
"""


@dataclass
class Stats:
    comparisons: int = 0
    witness_comparisons: int = 0
    projection_comparisons: int = 0
    pin_checks: int = 0
    direct_beta_cases: int = 0
    ranked_frameworks: int = 0
    curated_beta_cases: int = 0
    cross_algebra_cases: int = 0
    filter_meta_tables: int = 0
    external_frameworks: int = 0
    external_reducts: int = 0
    clingo_calls: int = 0
    waba_calls: int = 0
    filter_calls: int = 0
    external_calls: int = 0


def run_json(
    command: list[str],
    stats: Stats,
    *,
    stdin: str | None = None,
    kind: str,
) -> dict:
    stats.clingo_calls += 1
    if kind == "waba":
        stats.waba_calls += 1
    elif kind == "filter":
        stats.filter_calls += 1
    elif kind == "external":
        stats.external_calls += 1
    else:  # pragma: no cover - all callers use a literal category
        raise ValueError(kind)

    try:
        completed = subprocess.run(
            command,
            input=stdin,
            text=True,
            capture_output=True,
            check=False,
        )
    except OSError as exc:
        raise RuntimeError(f"could not execute {' '.join(command)}: {exc}") from exc
    if completed.returncode not in {0, 10, 20, 30}:
        raise RuntimeError(
            f"clingo failed ({completed.returncode}): {' '.join(command)}\n"
            f"stdout:\n{completed.stdout}\nstderr:\n{completed.stderr}"
        )
    try:
        return json.loads(completed.stdout)
    except json.JSONDecodeError as exc:
        raise RuntimeError(
            f"clingo returned invalid JSON: {' '.join(command)}\n"
            f"stdout:\n{completed.stdout}\nstderr:\n{completed.stderr}"
        ) from exc


def witness_atoms(payload: dict) -> list[list[str]]:
    return [
        witness.get("Value", [])
        for call in payload.get("Call", [])
        for witness in call.get("Witnesses", [])
    ]


def split_arguments(text: str) -> list[str]:
    """Split a Clingo argument list without breaking nested or quoted terms."""

    arguments: list[str] = []
    start = 0
    depth = 0
    quote: str | None = None
    escaped = False
    for index, char in enumerate(text):
        if quote is not None:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
            continue
        if char in {'"', "'"}:
            quote = char
        elif char in "([{":
            depth += 1
        elif char in ")]}" and depth > 0:
            depth -= 1
        elif char == "," and depth == 0:
            arguments.append(text[start:index].strip())
            start = index + 1
    arguments.append(text[start:].strip())
    return arguments


def predicate_arguments(atom: str, predicate: str) -> list[str] | None:
    prefix = f"{predicate}("
    if not atom.startswith(prefix) or not atom.endswith(")"):
        return None
    return split_arguments(atom[len(prefix):-1])


def parse_extensions(payload: dict) -> set[Extension]:
    result: set[Extension] = set()
    for atoms in witness_atoms(payload):
        extension: set[str] = set()
        for atom in atoms:
            arguments = predicate_arguments(atom, "in")
            if arguments is not None:
                if len(arguments) != 1:
                    raise RuntimeError(f"malformed in/1 atom: {atom}")
                extension.add(arguments[0])
        result.add(frozenset(extension))
    return result


def parse_waba_pairs(payload: dict) -> set[Witness]:
    result: set[Witness] = set()
    for atoms in witness_atoms(payload):
        extension: set[str] = set()
        discarded: set[Attack] = set()
        for atom in atoms:
            arguments = predicate_arguments(atom, "in")
            if arguments is not None:
                if len(arguments) != 1:
                    raise RuntimeError(f"malformed in/1 atom: {atom}")
                extension.add(arguments[0])
                continue
            arguments = predicate_arguments(atom, "discarded_attack")
            if arguments is not None:
                if len(arguments) != 3:
                    raise RuntimeError(f"malformed discarded_attack/3 atom: {atom}")
                try:
                    weight = int(arguments[2])
                except ValueError as exc:
                    raise RuntimeError(f"non-finite test attack weight: {atom}") from exc
                discarded.add((arguments[0], arguments[1], weight))
        result.add((frozenset(extension), frozenset(discarded)))
    return result


def run_waba(
    framework_path: Path,
    semantics: str,
    beta: int,
    profile: BudgetProfile,
    stats: Stats,
    *,
    project: bool,
    semiring: str = "godel",
) -> set[Witness]:
    command = [
        CLINGO,
        "--warn=none",
        "--outf=2",
        "--opt-mode=ignore",
        "-n",
        "0",
        "-c",
        f"beta={beta}",
    ]
    if project:
        command.append("--project")
    command.extend(
        (
            str(ROOT / "core" / "base.lp"),
            str(ROOT / "semiring" / f"{semiring}.lp"),
            str(ROOT / "defaults" / "neutral.lp"),
            str(ROOT / "monoid" / f"{profile.monoid}.lp"),
            str(ROOT / "constraint" / f"{profile.bound}.lp"),
            str(ROOT / "filter" / "projection.lp"),
            str(ROOT / "semantics" / f"{semantics}.lp"),
            str(framework_path),
        )
    )
    return parse_waba_pairs(run_json(command, stats, kind="waba"))


def preferred_from_admissible(
    models: Iterable[Witness], stats: Stats
) -> set[Witness]:
    """Exercise the shipped exact subset filter and retain its ``(S,D)`` pairs."""

    unique = sorted(
        set(models),
        key=lambda model: (sorted(model[1]), len(model[0]), sorted(model[0])),
    )
    if not unique:
        return set()

    facts: list[str] = []
    by_id: dict[int, Witness] = {}
    for model_id, (extension, discarded) in enumerate(unique, start=1):
        facts.append(f"candidate({model_id}).")
        by_id[model_id] = (extension, discarded)
        facts.extend(f"member({model_id},{member})." for member in sorted(extension))
        facts.extend(
            f"discarded_member({model_id},{source},{target},{weight})."
            for source, target, weight in sorted(discarded)
        )

    payload = run_json(
        [
            CLINGO,
            "--warn=none",
            "--outf=2",
            "-n",
            "1",
            str(ROOT / "semantics" / "subset_maximal_filter.lp"),
            "-",
        ],
        stats,
        stdin="\n".join(facts) + "\n",
        kind="filter",
    )
    kept: set[int] = set()
    for atoms in witness_atoms(payload):
        for atom in atoms:
            arguments = predicate_arguments(atom, "keep")
            if arguments is not None:
                if len(arguments) != 1:
                    raise RuntimeError(f"malformed keep/1 atom: {atom}")
                kept.add(int(arguments[0]))
    return {by_id[model_id] for model_id in kept}


def preferred_filter_meta_check(stats: Stats) -> None:
    """Exhaust every candidate table over two assumptions and two reducts.

    Natural ABA fixtures exercise the preferred filter through reachable candidate
    families.  This independent meta-test supplies all 2^8 possible tables made from
    four assumption subsets in each of two reducts, and compares ``keep/1`` directly
    with the definition of same-reduct subset maximality.
    """

    extensions = tuple(powerset(("a", "b")))
    rows = tuple(
        (extension, reduct)
        for reduct in (0, 1)
        for extension in extensions
    )
    facts: list[str] = []
    expected: set[int] = set()
    next_id = 1

    for table_mask in range(1 << len(rows)):
        selected = [
            row for index, row in enumerate(rows)
            if table_mask & (1 << index)
        ]
        ids: dict[tuple[Extension, int], int] = {}
        for extension, reduct in selected:
            model_id = next_id
            next_id += 1
            ids[(extension, reduct)] = model_id
            facts.append(f"candidate({model_id}).")
            # A common scenario marker prevents candidates from different tables from
            # being comparable while preserving every within-table subset relation.
            facts.append(f"member({model_id},scope({table_mask})).")
            facts.extend(
                f"member({model_id},{member})." for member in sorted(extension)
            )
            if reduct:
                facts.append(
                    f"discarded_member({model_id},attack({table_mask}),target,1)."
                )

        for extension, reduct in selected:
            if not any(
                reduct == other_reduct and extension < other_extension
                for other_extension, other_reduct in selected
            ):
                expected.add(ids[(extension, reduct)])

    payload = run_json(
        [
            CLINGO,
            "--warn=none",
            "--outf=2",
            "-n",
            "1",
            str(ROOT / "semantics" / "subset_maximal_filter.lp"),
            "-",
        ],
        stats,
        stdin="\n".join(facts) + "\n",
        kind="filter",
    )
    actual = {
        int(arguments[0])
        for atoms in witness_atoms(payload)
        for atom in atoms
        if (arguments := predicate_arguments(atom, "keep")) is not None
    }
    stats.comparisons += 1
    stats.filter_meta_tables = 1 << len(rows)
    if actual != expected:
        raise AssertionError(
            "preferred-filter arbitrary-table mismatch\n"
            f"missing ids: {sorted(expected - actual)[:20]}\n"
            f"extra ids: {sorted(actual - expected)[:20]}"
        )


def assert_witnesses(
    label: str,
    actual: set[Witness],
    expected: set[Witness],
    stats: Stats,
) -> None:
    stats.comparisons += 1
    stats.witness_comparisons += 1
    if actual == expected:
        return
    raise AssertionError(
        f"{label}: exact witness mismatch\n"
        f"missing {format_witnesses(expected - actual)}\n"
        f"extra   {format_witnesses(actual - expected)}"
    )


def assert_extensions(
    label: str,
    actual: set[Extension],
    expected: set[Extension],
    stats: Stats,
) -> None:
    stats.comparisons += 1
    stats.projection_comparisons += 1
    if actual == expected:
        return
    raise AssertionError(
        f"{label}: existential projection mismatch\n"
        f"expected {format_extensions(expected)}\n"
        f"actual   {format_extensions(actual)}"
    )


def assert_count(label: str, actual: int, expected: int, stats: Stats) -> None:
    stats.comparisons += 1
    stats.pin_checks += 1
    if actual != expected:
        raise AssertionError(f"{label}: expected {expected}, got {actual}")


def compare_exact_defence_semantics(
    framework: Framework,
    framework_path: Path,
    beta: int,
    profile: BudgetProfile,
    stats: Stats,
    scope: str,
) -> dict[str, set[Witness]]:
    expected = {
        semantics: beta_sigma_pairs(framework, profile, beta, semantics)
        for semantics in ("admissible", "complete", "preferred")
    }
    admissible = run_waba(
        framework_path, "admissible", beta, profile, stats, project=False
    )
    complete = run_waba(
        framework_path, "complete", beta, profile, stats, project=False
    )
    preferred = preferred_from_admissible(admissible, stats)

    actual = {
        "admissible": admissible,
        "complete": complete,
        "preferred": preferred,
    }
    for semantics in actual:
        assert_witnesses(
            f"{scope}, beta={beta}, {semantics}",
            actual[semantics],
            expected[semantics],
            stats,
        )
    return actual


def direct_graph_checks(temp: Path, stats: Stats) -> None:
    fixtures = {
        "one-way": (("a", "b"), frozenset({("a", "b")})),
        "mutual": (("a", "b"), frozenset({("a", "b"), ("b", "a")})),
        "chain": (NODES, frozenset({("a", "b"), ("b", "c")})),
        "three-cycle": (
            NODES,
            frozenset({("a", "b"), ("b", "c"), ("c", "a")}),
        ),
        "shared-target": (
            NODES,
            frozenset({("a", "c"), ("b", "c"), ("c", "a")}),
        ),
        "self-and-cycle": (
            NODES,
            frozenset({("a", "a"), ("a", "b"), ("b", "c"), ("c", "b")}),
        ),
    }
    frameworks: dict[str, Framework] = {}
    for name, (nodes, edges) in fixtures.items():
        framework = direct_graph_framework(name, nodes, edges)
        frameworks[name] = framework
        framework_path = temp / f"direct-{name}.lp"
        framework_path.write_text(framework.to_waba_lp(), encoding="utf-8")
        total_weight = sum(weight for _, _, weight in framework.attacks)
        for beta in range(total_weight + 1):
            stats.direct_beta_cases += 1
            actual_exact = compare_exact_defence_semantics(
                framework,
                framework_path,
                beta,
                SUM_UB,
                stats,
                f"direct/{name}",
            )
            for semantics in ("cf", "stable", "admissible", "complete"):
                projected_models = run_waba(
                    framework_path,
                    semantics,
                    beta,
                    SUM_UB,
                    stats,
                    project=True,
                )
                actual_extensions = existential_extensions(projected_models)
                expected_extensions = existential_extensions(
                    beta_sigma_pairs(framework, SUM_UB, beta, semantics)
                )
                assert_extensions(
                    f"direct/{name}, beta={beta}, {semantics}",
                    actual_extensions,
                    expected_extensions,
                    stats,
                )
            assert_extensions(
                f"direct/{name}, beta={beta}, preferred",
                existential_extensions(actual_exact["preferred"]),
                existential_extensions(
                    beta_sigma_pairs(framework, SUM_UB, beta, "preferred")
                ),
                stats,
            )

    # The smallest P1/P2 separator: D={} contributes {a}; deleting a->b
    # contributes {a,b}.  Global beta-admissible maximality would lose {a}.
    p1 = frameworks["one-way"]
    expected_counts = {
        "cf": 4,
        "stable": 2,
        "admissible": 4,
        "complete": 2,
        "preferred": 2,
    }
    for semantics, count in expected_counts.items():
        actual = len(
            existential_extensions(beta_sigma_pairs(p1, SUM_UB, 1, semantics))
        )
        assert_count(f"one-way beta=1 {semantics}", actual, count, stats)


def structured_waba_checks(temp: Path, stats: Stats) -> tuple[Framework, ...]:
    ranked = ranked_two_assumption_frameworks()
    for framework in ranked:
        stats.ranked_frameworks += 1
        path = temp / f"{framework.name}.lp"
        path.write_text(framework.to_waba_lp(), encoding="utf-8")
        beta = sum(weight for _, _, weight in framework.attacks)
        compare_exact_defence_semantics(
            framework,
            path,
            beta,
            SUM_UB,
            stats,
            f"ranked/{framework.name}",
        )

    curated = curated_structured_frameworks()
    for framework in curated:
        path = temp / f"curated-{framework.name}.lp"
        path.write_text(framework.to_waba_lp(), encoding="utf-8")
        total_weight = sum(weight for _, _, weight in framework.attacks)
        for beta in range(total_weight + 1):
            stats.curated_beta_cases += 1
            compare_exact_defence_semantics(
                framework,
                path,
                beta,
                SUM_UB,
                stats,
                f"curated/{framework.name}",
            )
    return curated


def cross_algebra_profile_checks(
    temp: Path, frameworks: Iterable[Framework], stats: Stats
) -> None:
    """Exercise defence semantics beyond the Gödel/sum/ub reference profile.

    The curated serializer fixes every premise at zero and gives each contrary an
    explicit positive weight.  Gödel, arctic and Lukasiewicz therefore retain the
    oracle's declared attack prices exactly, allowing witness-level comparison for
    max/ub at every relevant threshold.  Tropical and bottleneck-cost may select a
    cheaper rule-derived value; for them a deliberately generous max/ub budget makes
    every finite discard set affordable, so the existential extension family is still
    independent of those numeric differences and can be checked exactly after D is
    forgotten.
    """

    exact_algebras = ("godel", "arctic", "lukasiewicz")
    projected_algebras = ("tropical", "bottleneck_cost")
    for framework in frameworks:
        path = temp / f"cross-{framework.name}.lp"
        path.write_text(framework.to_waba_lp(), encoding="utf-8")
        max_weight = max((weight for _, _, weight in framework.attacks), default=0)

        for semiring in exact_algebras:
            for beta in range(max_weight + 1):
                stats.cross_algebra_cases += 1
                expected = {
                    semantics: beta_sigma_pairs(framework, MAX_UB, beta, semantics)
                    for semantics in ("admissible", "complete", "preferred")
                }
                admissible = run_waba(
                    path, "admissible", beta, MAX_UB, stats,
                    project=False, semiring=semiring,
                )
                complete = run_waba(
                    path, "complete", beta, MAX_UB, stats,
                    project=False, semiring=semiring,
                )
                actual = {
                    "admissible": admissible,
                    "complete": complete,
                    "preferred": preferred_from_admissible(admissible, stats),
                }
                for semantics in actual:
                    assert_witnesses(
                        f"cross/{framework.name}, {semiring}, max+ub, "
                        f"beta={beta}, {semantics}",
                        actual[semantics],
                        expected[semantics],
                        stats,
                    )

        # Every propagated price in these finite fixtures is far below this beta.
        # Comparing the projected family therefore checks sigma and existential D
        # composition without pretending that cost-algebra propagation preserves the
        # serializer's Gödel-specific declared attack prices.
        beta = 1_000_000
        fully_affordable = sum(weight for _, _, weight in framework.attacks)
        for semiring in projected_algebras:
            stats.cross_algebra_cases += 1
            admissible = run_waba(
                path, "admissible", beta, MAX_UB, stats,
                project=False, semiring=semiring,
            )
            complete = run_waba(
                path, "complete", beta, MAX_UB, stats,
                project=False, semiring=semiring,
            )
            actual = {
                "admissible": existential_extensions(admissible),
                "complete": existential_extensions(complete),
                "preferred": existential_extensions(
                    preferred_from_admissible(admissible, stats)
                ),
            }
            for semantics in actual:
                expected = existential_extensions(
                    beta_sigma_pairs(
                        framework, SUM_UB, fully_affordable, semantics
                    )
                )
                assert_extensions(
                    f"cross/{framework.name}, {semiring}, all D, {semantics}",
                    actual[semantics],
                    expected,
                    stats,
                )


def external_extensions(program: str, semantics: str, stats: Stats) -> set[Extension]:
    if semantics == "admissible":
        command = [CLINGO, "--warn=none", "--outf=2", "-n", "0", "-"]
        stdin = program + ASPFORABA_COMMON + ASPFORABA_ADMISSIBLE
    elif semantics == "complete":
        command = [
            CLINGO,
            "--warn=none",
            "--outf=2",
            "-n",
            "0",
            str(ASPFORABA / "com-aba-cred.dl"),
            "-",
        ]
        stdin = program
    else:  # pragma: no cover - fixed caller set
        raise ValueError(semantics)
    return parse_extensions(run_json(command, stats, stdin=stdin, kind="external"))


def external_bridge_checks(frameworks: Iterable[Framework], stats: Stats) -> bool:
    complete_encoding = ASPFORABA / "com-aba-cred.dl"
    if not complete_encoding.is_file():
        print(
            f"SKIP: ASPforABA not found at {ASPFORABA}; "
            "set ASPFORABA to enable bridge correspondence"
        )
        return False

    for framework in frameworks:
        stats.external_frameworks += 1
        actual: dict[str, set[Witness]] = {
            "admissible": set(),
            "complete": set(),
            "preferred": set(),
        }
        for discarded in powerset(framework.attacks):
            stats.external_reducts += 1
            bridge = framework.to_bridge_aba_lp(discarded)
            admissible = external_extensions(bridge, "admissible", stats)
            complete = external_extensions(bridge, "complete", stats)
            preferred = preferred_from_admissible_extensions(admissible)
            actual["admissible"].update((extension, discarded) for extension in admissible)
            actual["complete"].update((extension, discarded) for extension in complete)
            actual["preferred"].update((extension, discarded) for extension in preferred)

        full_beta = sum(weight for _, _, weight in framework.attacks)
        for semantics in ("admissible", "complete", "preferred"):
            expected = beta_sigma_pairs(framework, SUM_UB, full_beta, semantics)
            assert_witnesses(
                f"ASPforABA bridge/{framework.name}, {semantics}",
                actual[semantics],
                expected,
                stats,
            )
    return True


def main() -> int:
    started = time.perf_counter()
    stats = Stats()
    with tempfile.TemporaryDirectory(prefix="waba-finite-beta-sigma-") as temp_dir:
        temp = Path(temp_dir)
        direct_graph_checks(temp, stats)
        curated = structured_waba_checks(temp, stats)
        cross_algebra_profile_checks(temp, curated, stats)
        preferred_filter_meta_check(stats)
        external_enabled = external_bridge_checks(curated, stats)

    elapsed = time.perf_counter() - started
    print(
        f"ok: {stats.comparisons} finite beta-sigma comparisons "
        f"({stats.witness_comparisons} exact (S,D), "
        f"{stats.projection_comparisons} existential projections, "
        f"{stats.pin_checks} discriminator pins, "
        f"{1 if stats.filter_meta_tables else 0} preferred-filter meta-check)"
    )
    print(
        f"coverage: {stats.direct_beta_cases} direct-graph/beta cases; "
        f"{stats.ranked_frameworks} exhaustive ranked frameworks; "
        f"{stats.curated_beta_cases} curated structured/beta cases; "
        f"{stats.cross_algebra_cases} cross-algebra/profile cases; "
        f"{stats.filter_meta_tables} arbitrary preferred-filter tables"
    )
    if external_enabled:
        print(
            f"external: {stats.external_frameworks} structured frameworks, "
            f"{stats.external_reducts} bridge reducts checked against ASPforABA"
        )
    print(
        f"clingo: {stats.clingo_calls} calls "
        f"({stats.waba_calls} WABA, {stats.filter_calls} preferred filter, "
        f"{stats.external_calls} external); runtime {elapsed:.3f}s"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
