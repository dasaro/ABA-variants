#!/usr/bin/env python3
"""Independent finite flat-ABA oracle used by the beta-sigma differential tests.

This module deliberately does not reproduce the implementation's
``undefeated/1`` encoding.  Defence is evaluated from the definition: every
assumption support that derives an attack must be counterattacked on one of its
members.  The finite powerset construction is small enough for the bounded
frameworks in the test suite and, importantly, includes the empty support of a
fact-derived attack.

The implementation removes atom-to-target attacks rather than rules or
individual derivations.  An ``Attack`` is consequently the fixed triple
``(contrary conclusion, target assumption, maximal-context weight)``.
"""

from __future__ import annotations

from dataclasses import dataclass
from functools import lru_cache
import itertools
from typing import Iterable, Iterator, Literal, TypeVar


Atom = str
Attack = tuple[Atom, Atom, int]
Extension = frozenset[Atom]
DiscardSet = frozenset[Attack]
Witness = tuple[Extension, DiscardSet]
T = TypeVar("T")


def powerset(items: Iterable[T]) -> Iterator[frozenset[T]]:
    """Every subset of ``items``, in cardinality order."""

    values = tuple(items)
    for size in range(len(values) + 1):
        for chosen in itertools.combinations(values, size):
            yield frozenset(chosen)


@dataclass(frozen=True, order=True)
class Rule:
    head: Atom
    body: tuple[Atom, ...] = ()


@dataclass(frozen=True)
class Framework:
    """A small, well-founded flat ABA framework with controlled attack weights.

    ``weights`` need only contain contrary conclusions whose attacks can exist.
    The serializer gives assumptions and other derived heads weight zero.  Under
    the Gödel algebra used by the differential suite, an explicitly weighted
    contrary therefore has exactly its declared weight whenever it is derivable:
    every rule-derived alternative has weight zero and ``oplus=max`` selects the
    declared value.
    """

    name: str
    assumptions: tuple[Atom, ...]
    contraries: tuple[tuple[Atom, Atom], ...]
    rules: tuple[Rule, ...]
    weights: tuple[tuple[Atom, int], ...]

    def __post_init__(self) -> None:
        assumptions = set(self.assumptions)
        if len(assumptions) != len(self.assumptions):
            raise ValueError(f"{self.name}: duplicate assumption")
        contrary_map = dict(self.contraries)
        if set(contrary_map) != assumptions or len(contrary_map) != len(self.contraries):
            raise ValueError(f"{self.name}: contrary must be functional and total")
        if any(rule.head in assumptions for rule in self.rules):
            raise ValueError(f"{self.name}: non-flat rule head")
        weight_map = dict(self.weights)
        if len(weight_map) != len(self.weights):
            raise ValueError(f"{self.name}: duplicate explicit weight")
        if any(value < 0 for value in weight_map.values()):
            raise ValueError(f"{self.name}: negative test weight")
        missing = sorted(set(contrary_map.values()) - set(weight_map))
        if missing:
            raise ValueError(f"{self.name}: missing contrary weights: {missing}")

    @property
    def contrary_map(self) -> dict[Atom, Atom]:
        return dict(self.contraries)

    @property
    def weight_map(self) -> dict[Atom, int]:
        return dict(self.weights)

    @property
    def language(self) -> frozenset[Atom]:
        atoms = set(self.assumptions)
        atoms.update(self.contrary_map.values())
        for rule in self.rules:
            atoms.add(rule.head)
            atoms.update(rule.body)
        return frozenset(atoms)

    @property
    def attacks(self) -> tuple[Attack, ...]:
        full_closure = closure(self, frozenset(self.assumptions))
        weights = self.weight_map
        return tuple(
            sorted(
                (conclusion, target, weights[conclusion])
                for target, conclusion in self.contraries
                if conclusion in full_closure
            )
        )

    def to_waba_lp(self) -> str:
        """Serialize a fixture whose maximal Gödel attack weights are known."""

        lines: list[str] = []
        contrary_map = self.contrary_map
        for assumption in self.assumptions:
            lines.append(f"assumption({assumption}).")
            lines.append(f"contrary({assumption},{contrary_map[assumption]}).")

        for index, rule in enumerate(self.rules, start=1):
            rule_id = f"r{index}"
            lines.append(f"head({rule_id},{rule.head}).")
            lines.extend(f"body({rule_id},{atom})." for atom in rule.body)

        # Zero-weight premises make every rule-derived Gödel alternative zero;
        # the positive explicit contrary weight then fixes the attack price.
        explicit = {assumption: 0 for assumption in self.assumptions}
        explicit.update({rule.head: 0 for rule in self.rules})
        explicit.update(self.weight_map)
        lines.extend(f"weight({atom},{value})." for atom, value in sorted(explicit.items()))
        return "\n".join(lines) + "\n"

    def to_bridge_aba_lp(self, discarded: DiscardSet) -> str:
        """Materialize ``F-D`` as ordinary ABA using fresh target bridges.

        Replacing ``contrary(a,c_a)`` with ``contrary(a,hit_a)`` and retaining
        ``hit_a <- c_a`` exactly when ``(c_a,a)`` survives removes only the
        target-specific attack.  It does not delete derivations of ``c_a`` or
        affect another target sharing the same contrary.
        """

        unknown = set(discarded) - set(self.attacks)
        if unknown:
            raise ValueError(f"{self.name}: non-attack in discard set: {sorted(unknown)}")

        occupied = set(self.language)
        hit: dict[Atom, Atom] = {}
        for index, assumption in enumerate(self.assumptions):
            candidate = f"oracle_hit_{index}"
            while candidate in occupied:
                candidate += "_x"
            occupied.add(candidate)
            hit[assumption] = candidate

        lines: list[str] = []
        for assumption in self.assumptions:
            lines.append(f"assumption({assumption}).")
            lines.append(f"contrary({assumption},{hit[assumption]}).")
        for index, rule in enumerate(self.rules, start=1):
            rule_id = f"original_{index}"
            lines.append(f"head({rule_id},{rule.head}).")
            lines.extend(f"body({rule_id},{atom})." for atom in rule.body)
        for index, (conclusion, target, weight) in enumerate(self.attacks, start=1):
            if (conclusion, target, weight) in discarded:
                continue
            rule_id = f"bridge_{index}"
            lines.append(f"head({rule_id},{hit[target]}).")
            lines.append(f"body({rule_id},{conclusion}).")
        return "\n".join(lines) + "\n"


@lru_cache(maxsize=None)
def closure(framework: Framework, seed: Extension) -> frozenset[Atom]:
    """Least Horn closure of ``seed`` under the framework rules."""

    result = set(seed)
    while True:
        additions = {
            rule.head
            for rule in framework.rules
            if set(rule.body) <= result
        }
        if additions <= result:
            return frozenset(result)
        result.update(additions)


def attacks_target(
    framework: Framework,
    discarded: DiscardSet,
    support: Extension,
    target: Atom,
) -> bool:
    conclusion = framework.contrary_map[target]
    attack = (conclusion, target, framework.weight_map[conclusion])
    return (
        attack in framework.attacks
        and attack not in discarded
        and conclusion in closure(framework, support)
    )


def defends(
    framework: Framework,
    discarded: DiscardSet,
    source: Extension,
    target: Atom,
) -> bool:
    """ABA defence by universal enumeration of attacking supports."""

    for attacker in powerset(framework.assumptions):
        if not attacks_target(framework, discarded, attacker, target):
            continue
        if not any(
            attacks_target(framework, discarded, source, member)
            for member in attacker
        ):
            return False
    return True


@lru_cache(maxsize=None)
def ordinary_extensions(
    framework: Framework,
    discarded: DiscardSet,
    semantics: Literal[
        "cf",
        "stable",
        "admissible",
        "complete",
        "preferred",
        "grounded",
        "naive",
        "semi-stable",
        "stage",
        "ideal",
        "eager",
    ],
) -> frozenset[Extension]:
    """Ordinary ``semantics`` extensions of the fixed reduct ``F-D``."""

    groups = frozenset(powerset(framework.assumptions))
    conflict_free = frozenset(
        group
        for group in groups
        if all(
            assumption not in group
            or not attacks_target(framework, discarded, group, assumption)
            for assumption in framework.assumptions
        )
    )
    if semantics == "cf":
        return conflict_free
    if semantics == "naive":
        return frozenset(
            group
            for group in conflict_free
            if not any(group < other for other in conflict_free)
        )
    if semantics == "stable":
        return frozenset(
            group
            for group in conflict_free
            if all(
                assumption in group
                or attacks_target(framework, discarded, group, assumption)
                for assumption in framework.assumptions
            )
        )

    admissible = frozenset(
        group
        for group in conflict_free
        if all(defends(framework, discarded, group, member) for member in group)
    )
    if semantics == "admissible":
        return admissible
    complete = frozenset(
        group
        for group in admissible
        if all(
            assumption in group
            or not defends(framework, discarded, group, assumption)
            for assumption in framework.assumptions
        )
    )
    if semantics == "complete":
        return complete
    if semantics == "grounded":
        return frozenset(
            group
            for group in complete
            if not any(other < group for other in complete)
        )
    if semantics == "preferred":
        preferred = frozenset(
            group
            for group in admissible
            if not any(group < other for other in admissible)
        )
        return preferred
    if semantics == "ideal":
        preferred = ordinary_extensions(framework, discarded, "preferred")
        ideal_sets = frozenset(
            group
            for group in admissible
            if all(group <= preferred_group for preferred_group in preferred)
        )
        return frozenset(
            group
            for group in ideal_sets
            if not any(group < other for other in ideal_sets)
        )

    def assumption_range(group: Extension) -> frozenset[Atom]:
        attacked = {
            assumption
            for assumption in framework.assumptions
            if attacks_target(framework, discarded, group, assumption)
        }
        return group | frozenset(attacked)

    candidates = complete if semantics in {"semi-stable", "eager"} else conflict_free
    if semantics in {"semi-stable", "stage", "eager"}:
        ranges = {group: assumption_range(group) for group in candidates}
        range_maximal = frozenset(
            group
            for group in candidates
            if not any(ranges[group] < ranges[other] for other in candidates)
        )
        if semantics != "eager":
            return range_maximal

        # Keep the oracle in the direct mathematical form: the eager extension
        # is the greatest admissible set contained in every semi-stable set.
        # The implementation starts from complete candidates and is tested
        # against the theorem that this unique greatest set is complete.
        eager_sets = frozenset(
            group
            for group in admissible
            if all(group <= extension for extension in range_maximal)
        )
        return frozenset(
            group
            for group in eager_sets
            if not any(group < other for other in eager_sets)
        )
    raise ValueError(semantics)


@dataclass(frozen=True)
class BudgetProfile:
    monoid: Literal["sum", "max", "min"]
    bound: Literal["ub", "lb"]

    @property
    def name(self) -> str:
        return f"{self.monoid}+{self.bound}"


def affordable(profile: BudgetProfile, beta: int, discarded: DiscardSet) -> bool:
    """Mirror the finite-weight budget modules, including the empty-set gate."""

    if not discarded:
        return True
    values = [weight for _, _, weight in discarded]
    if profile.monoid == "sum":
        aggregate = sum(values)
    elif profile.monoid == "max":
        aggregate = max(values)
    elif profile.monoid == "min":
        aggregate = min(values)
    else:  # pragma: no cover - protected by the Literal and constructor use
        raise ValueError(profile.monoid)
    return aggregate <= beta if profile.bound == "ub" else aggregate >= beta


def beta_sigma_pairs(
    framework: Framework,
    profile: BudgetProfile,
    beta: int,
    semantics: Literal[
        "cf",
        "stable",
        "admissible",
        "complete",
        "preferred",
        "grounded",
        "naive",
        "semi-stable",
        "stage",
        "ideal",
        "eager",
    ],
) -> set[Witness]:
    """Exact witness relation before existentially forgetting ``D``."""

    result: set[Witness] = set()
    for discarded in powerset(framework.attacks):
        if not affordable(profile, beta, discarded):
            continue
        result.update(
            (extension, discarded)
            for extension in ordinary_extensions(framework, discarded, semantics)
        )
    return result


def existential_extensions(witnesses: Iterable[Witness]) -> set[Extension]:
    return {extension for extension, _ in witnesses}


def preferred_from_admissible_extensions(
    admissible: Iterable[Extension],
) -> set[Extension]:
    candidates = set(admissible)
    return {
        extension
        for extension in candidates
        if not any(extension < other for other in candidates)
    }


def direct_graph_framework(
    name: str,
    nodes: tuple[Atom, ...],
    edges: frozenset[tuple[Atom, Atom]],
) -> Framework:
    """Embed a direct Dung graph using one contrary conclusion per target."""

    return Framework(
        name=name,
        assumptions=nodes,
        contraries=tuple((node, f"c_{node}") for node in nodes),
        rules=tuple(
            Rule(f"c_{target}", (source,))
            for source, target in sorted(edges)
        ),
        weights=tuple((f"c_{node}", 1) for node in nodes),
    )


def ranked_two_assumption_frameworks() -> tuple[Framework, ...]:
    """All 172 ranked two-assumption frameworks containing at most two rules."""

    assumptions = ("a0", "a1")
    assumption_bodies = ((), ("a0",), ("a1",), ("a0", "a1"))
    contrary_sources = ("a0", "a1", "p")
    contrary_bodies = (
        (),
        *((source,) for source in contrary_sources),
        *itertools.combinations(contrary_sources, 2),
    )
    pool = tuple(
        [Rule("p", body) for body in assumption_bodies]
        + [
            Rule(contrary, body)
            for contrary in ("c0", "c1")
            for body in contrary_bodies
        ]
    )
    result: list[Framework] = []
    index = 0
    for size in range(3):
        for chosen in itertools.combinations(pool, size):
            result.append(
                Framework(
                    name=f"ranked-{index:03d}",
                    assumptions=assumptions,
                    contraries=(("a0", "c0"), ("a1", "c1")),
                    rules=tuple(chosen),
                    weights=(("c0", 1), ("c1", 2)),
                )
            )
            index += 1
    if len(result) != 172:
        raise AssertionError(f"ranked generator produced {len(result)}, expected 172")
    return tuple(result)


def curated_structured_frameworks() -> tuple[Framework, ...]:
    """Fixtures for phenomena a direct-attack graph cannot express."""

    assumptions = ("a0", "a1", "a2")
    contraries = (("a0", "c0"), ("a1", "c1"), ("a2", "c2"))
    weights = (("c0", 1), ("c1", 2), ("c2", 4))

    def fixture(name: str, *rules: Rule) -> Framework:
        return Framework(name, assumptions, contraries, tuple(rules), weights)

    return (
        fixture("fact-attacker", Rule("c0")),
        fixture(
            "conjunctive-attacker",
            Rule("c0", ("a1", "a2")),
            Rule("c1", ("a0",)),
        ),
        fixture(
            "derived-chain",
            Rule("p", ("a1", "a2")),
            Rule("c0", ("p",)),
            Rule("c1", ("a0",)),
        ),
        fixture(
            "alternative-supports",
            Rule("c0", ("a1",)),
            Rule("c0", ("a2",)),
            Rule("c1", ("a0",)),
        ),
        fixture(
            "contrary-used-downstream",
            Rule("c0", ("a1",)),
            Rule("c1", ("c0",)),
            Rule("c2", ("a0", "a2")),
        ),
        fixture(
            "defence-cycle",
            Rule("c0", ("a1",)),
            Rule("c1", ("a2",)),
            Rule("c2", ("a0",)),
        ),
        fixture(
            "self-and-counterattack",
            Rule("c0", ("a0",)),
            Rule("c1", ("a0",)),
            Rule("c2", ("a1", "a2")),
        ),
        Framework(
            name="shared-contrary-targets",
            assumptions=assumptions,
            contraries=(("a0", "shared"), ("a1", "shared"), ("a2", "c2")),
            rules=(Rule("shared", ("a2",)), Rule("c2", ("a0", "a1"))),
            weights=(("shared", 1), ("c2", 4)),
        ),
    )


def format_extensions(extensions: Iterable[Extension]) -> str:
    return "{" + ", ".join(
        "{" + ",".join(sorted(extension)) + "}"
        for extension in sorted(set(extensions), key=lambda item: (len(item), sorted(item)))
    ) + "}"


def format_witnesses(witnesses: Iterable[Witness]) -> str:
    def key(witness: Witness):
        extension, discarded = witness
        return (sorted(discarded), len(extension), sorted(extension))

    parts = []
    for extension, discarded in sorted(set(witnesses), key=key):
        shown_extension = "{" + ",".join(sorted(extension)) + "}"
        shown_discard = "{" + ",".join(
            f"{source}->{target}@{weight}"
            for source, target, weight in sorted(discarded)
        ) + "}"
        parts.append(f"({shown_extension},D={shown_discard})")
    return "{" + ", ".join(parts) + "}"
