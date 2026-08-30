#!/usr/bin/env python3
"""Symbolic verification of the common beta-sigma semantics layer.

This file checks the mathematical bridge that is specific to the semantics modules.  The
semiring and budget arithmetic have their own checkers; here attack weights are already fixed
and a discard witness simply switches atom-level attacks off before ordinary ABA semantics is
evaluated.

For a flat ABA framework, write ``attacks(S, a)`` when assumptions ``S`` derive the contrary
of ``a``.  This predicate is monotone in ``S``.  The encoding below leaves every value of this
monotone predicate symbolic, so one solver call ranges over all bounded flat-ABA attack
structures rather than over a hand-picked graph.  The implementation's atom-level discard
key for ``a`` turns ``attacks(S, a)`` off for every ``S``.  This is exactly the quotient used
by ``core/base.lp``: one fixed contrary-claim-to-assumption attack is discarded globally.
Targets that share one contrary still have distinct keys, so discarding the unit for one
target never removes the surviving unit for another.

The main obligations are:

* the undefeated-closure rules in ``semantics/admissible.lp`` are equivalent to ordinary ABA
  defence;
* ``complete.lp`` is ordinary completeness on the same reduct;
* ``subset_maximal_filter.lp`` computes ordinary preferred semantics separately inside each
  fixed discard reduct (P1), never global maximality across different witnesses (P2);
* the minimal, range-maximal, ideal and eager filters compute grounded, naive, semi-stable,
  stage, ideal and eager semantics inside that same fixed reduct;
* existential beta-sigma composition, recovery, classical containment, budget monotonicity,
  and the standard semantic inclusions hold for admissible, complete, and preferred semantics.

The symbolic universe is bounded (four assumptions for the pointwise encoding proof and three
for the beta-level laws), but the accompanying natural proofs use only the displayed
monotonicity law and witness reuse.  The bounded check is deliberately mutation-sensitive: it
also requires concrete separations between conflict-free/admissible, admissible/complete, and
P1/P2 preferredness.  Its discard bits range only over discardable atomic units; a hard
``#sup`` unit is absent from that universe, exactly as the common constraint modules require.
"""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from typing import Callable

from z3 import And, Bool, BoolVal, Implies, Not, Or, Solver, sat, unsat


def conjunction(parts):
    parts = list(parts)
    return And(*parts) if parts else BoolVal(True)


def disjunction(parts):
    parts = list(parts)
    return Or(*parts) if parts else BoolVal(False)


def member(mask: int, item: int) -> bool:
    return bool(mask & (1 << item))


def subset(left: int, right: int) -> bool:
    return left & ~right == 0


def proper_subset(left: int, right: int) -> bool:
    return left != right and subset(left, right)


@dataclass
class Result:
    obligation: str
    status: str
    scope: str
    detail: str = ""

    @property
    def ok(self) -> bool:
        return self.status in {"proved", "separated"}


class FlatABA:
    """A symbolic monotone assumption-to-target attack map on ``n`` assumptions."""

    def __init__(self, n: int, prefix: str):
        self.n = n
        self.full = (1 << n) - 1
        self.att = {
            (support, target): Bool(f"{prefix}_att_{support}_{target}")
            for support in range(1 << n)
            for target in range(n)
        }

    def monotonicity(self):
        return conjunction(
            Implies(self.att[left, target], self.att[right, target])
            for target in range(self.n)
            for left in range(1 << self.n)
            for right in range(1 << self.n)
            if subset(left, right)
        )

    def valid_discard(self, discarded: int):
        """Only globally existing contrary attacks may be discarded."""
        return conjunction(
            self.att[self.full, target]
            for target in range(self.n)
            if member(discarded, target)
        )

    def attacks(self, support: int, target: int, discarded: int):
        if member(discarded, target):
            return BoolVal(False)
        return self.att[support, target]

    def counterattacks(self, source: int, attacker_support: int, discarded: int):
        return disjunction(
            self.attacks(source, target, discarded)
            for target in range(self.n)
            if member(attacker_support, target)
        )

    def defends_standard(self, source: int, target: int, discarded: int):
        """Every assumption set attacking ``target`` is counterattacked by ``source``."""
        return conjunction(
            Implies(
                self.attacks(attacker, target, discarded),
                self.counterattacks(source, attacker, discarded),
            )
            for attacker in range(1 << self.n)
        )

    def undefeated_is(self, undefeated: int, source: int, discarded: int):
        """The exact set A \\ {assumptions attacked by ``source``}."""
        return conjunction(
            Not(self.attacks(source, target, discarded))
            if member(undefeated, target)
            else self.attacks(source, target, discarded)
            for target in range(self.n)
        )

    def threatened_by_undefeated(self, source: int, target: int, discarded: int):
        """The predicate ``attacked_by_undefeated/1`` in admissible.lp."""
        return disjunction(
            And(
                self.undefeated_is(undefeated, source, discarded),
                self.attacks(undefeated, target, discarded),
            )
            for undefeated in range(1 << self.n)
        )

    def conflict_free(self, source: int, discarded: int):
        return conjunction(
            Not(self.attacks(source, target, discarded))
            for target in range(self.n)
            if member(source, target)
        )

    def stable(self, source: int, discarded: int):
        return And(
            self.conflict_free(source, discarded),
            conjunction(
                self.attacks(source, target, discarded)
                for target in range(self.n)
                if not member(source, target)
            ),
        )

    def admissible_standard(self, source: int, discarded: int):
        return And(
            self.conflict_free(source, discarded),
            conjunction(
                self.defends_standard(source, target, discarded)
                for target in range(self.n)
                if member(source, target)
            ),
        )

    def admissible_clingo(self, source: int, discarded: int):
        return And(
            self.conflict_free(source, discarded),
            conjunction(
                Not(self.threatened_by_undefeated(source, target, discarded))
                for target in range(self.n)
                if member(source, target)
            ),
        )

    def complete_standard(self, source: int, discarded: int):
        return And(
            self.admissible_standard(source, discarded),
            conjunction(
                self.defends_standard(source, target, discarded)
                if member(source, target)
                else Not(self.defends_standard(source, target, discarded))
                for target in range(self.n)
            ),
        )

    def complete_clingo(self, source: int, discarded: int):
        return And(
            self.admissible_clingo(source, discarded),
            conjunction(
                self.threatened_by_undefeated(source, target, discarded)
                for target in range(self.n)
                if not member(source, target)
            ),
        )

    def preferred_standard(self, source: int, discarded: int):
        return And(
            self.admissible_standard(source, discarded),
            conjunction(
                Not(self.admissible_standard(other, discarded))
                for other in range(1 << self.n)
                if proper_subset(source, other)
            ),
        )

    def preferred_filter(self, source: int, discarded: int):
        """What subset_maximal_filter.lp keeps: strict supersets in the same D only."""
        return And(
            self.admissible_clingo(source, discarded),
            conjunction(
                Not(self.admissible_clingo(other, discarded))
                for other in range(1 << self.n)
                if proper_subset(source, other)
            ),
        )

    def naive_standard(self, source: int, discarded: int):
        return And(
            self.conflict_free(source, discarded),
            conjunction(
                Not(self.conflict_free(other, discarded))
                for other in range(1 << self.n)
                if proper_subset(source, other)
            ),
        )

    def naive_filter(self, source: int, discarded: int):
        """What subset_maximal_filter.lp keeps when its candidates are conflict-free."""
        return self.naive_standard(source, discarded)

    def grounded_standard(self, source: int, discarded: int):
        return And(
            self.complete_standard(source, discarded),
            conjunction(
                Not(self.complete_standard(other, discarded))
                for other in range(1 << self.n)
                if proper_subset(other, source)
            ),
        )

    def grounded_filter(self, source: int, discarded: int):
        """What subset_minimal_filter.lp keeps from complete candidates."""
        return And(
            self.complete_clingo(source, discarded),
            conjunction(
                Not(self.complete_clingo(other, discarded))
                for other in range(1 << self.n)
                if proper_subset(other, source)
            ),
        )

    def in_range(self, source: int, target: int, discarded: int):
        return Or(BoolVal(member(source, target)), self.attacks(source, target, discarded))

    def range_subset(self, left: int, right: int, discarded: int):
        return conjunction(
            Implies(
                self.in_range(left, target, discarded),
                self.in_range(right, target, discarded),
            )
            for target in range(self.n)
        )

    def strict_range_subset(self, left: int, right: int, discarded: int):
        return And(
            self.range_subset(left, right, discarded),
            disjunction(
                And(
                    self.in_range(right, target, discarded),
                    Not(self.in_range(left, target, discarded)),
                )
                for target in range(self.n)
            ),
        )

    def semi_stable_standard(self, source: int, discarded: int):
        return And(
            self.complete_standard(source, discarded),
            conjunction(
                Implies(
                    self.complete_standard(other, discarded),
                    Not(self.strict_range_subset(source, other, discarded)),
                )
                for other in range(1 << self.n)
            ),
        )

    def semi_stable_filter(self, source: int, discarded: int):
        return And(
            self.complete_clingo(source, discarded),
            conjunction(
                Implies(
                    self.complete_clingo(other, discarded),
                    Not(self.strict_range_subset(source, other, discarded)),
                )
                for other in range(1 << self.n)
            ),
        )

    def stage_standard(self, source: int, discarded: int):
        return And(
            self.conflict_free(source, discarded),
            conjunction(
                Implies(
                    self.conflict_free(other, discarded),
                    Not(self.strict_range_subset(source, other, discarded)),
                )
                for other in range(1 << self.n)
            ),
        )

    def stage_filter(self, source: int, discarded: int):
        return self.stage_standard(source, discarded)

    def ideal_set_standard(self, source: int, discarded: int):
        return And(
            self.admissible_standard(source, discarded),
            conjunction(
                Implies(
                    self.preferred_standard(preferred, discarded),
                    BoolVal(subset(source, preferred)),
                )
                for preferred in range(1 << self.n)
            ),
        )

    def ideal_set_filter(self, source: int, discarded: int):
        return And(
            self.admissible_clingo(source, discarded),
            conjunction(
                Implies(
                    self.preferred_filter(preferred, discarded),
                    BoolVal(subset(source, preferred)),
                )
                for preferred in range(1 << self.n)
            ),
        )

    def ideal_standard(self, source: int, discarded: int):
        return And(
            self.ideal_set_standard(source, discarded),
            conjunction(
                Not(self.ideal_set_standard(other, discarded))
                for other in range(1 << self.n)
                if proper_subset(source, other)
            ),
        )

    def ideal_filter(self, source: int, discarded: int):
        return And(
            self.ideal_set_filter(source, discarded),
            conjunction(
                Not(self.ideal_set_filter(other, discarded))
                for other in range(1 << self.n)
                if proper_subset(source, other)
            ),
        )

    def eager_set_standard(self, source: int, discarded: int):
        """Admissible sets contained in every ordinary semi-stable extension."""
        return And(
            self.admissible_standard(source, discarded),
            conjunction(
                Implies(
                    self.semi_stable_standard(semi_stable, discarded),
                    BoolVal(subset(source, semi_stable)),
                )
                for semi_stable in range(1 << self.n)
            ),
        )

    def eager_standard(self, source: int, discarded: int):
        return And(
            self.eager_set_standard(source, discarded),
            conjunction(
                Not(self.eager_set_standard(other, discarded))
                for other in range(1 << self.n)
                if proper_subset(source, other)
            ),
        )

    def eager_set_filter(self, source: int, discarded: int):
        """What eager_filter.lp tests over its complete-candidate table."""
        return And(
            self.complete_clingo(source, discarded),
            conjunction(
                Implies(
                    self.semi_stable_filter(semi_stable, discarded),
                    BoolVal(subset(source, semi_stable)),
                )
                for semi_stable in range(1 << self.n)
            ),
        )

    def eager_filter(self, source: int, discarded: int):
        return And(
            self.eager_set_filter(source, discarded),
            conjunction(
                Not(self.eager_set_filter(other, discarded))
                for other in range(1 << self.n)
                if proper_subset(source, other)
            ),
        )


Semantics = Callable[[FlatABA, int, int], object]


def sem_cf(enc: FlatABA, source: int, discarded: int):
    return enc.conflict_free(source, discarded)


def sem_stable(enc: FlatABA, source: int, discarded: int):
    return enc.stable(source, discarded)


def sem_admissible(enc: FlatABA, source: int, discarded: int):
    return enc.admissible_standard(source, discarded)


def sem_complete(enc: FlatABA, source: int, discarded: int):
    return enc.complete_standard(source, discarded)


def sem_preferred(enc: FlatABA, source: int, discarded: int):
    return enc.preferred_standard(source, discarded)


def sem_grounded(enc: FlatABA, source: int, discarded: int):
    return enc.grounded_standard(source, discarded)


def sem_naive(enc: FlatABA, source: int, discarded: int):
    return enc.naive_standard(source, discarded)


def sem_semi_stable(enc: FlatABA, source: int, discarded: int):
    return enc.semi_stable_standard(source, discarded)


def sem_stage(enc: FlatABA, source: int, discarded: int):
    return enc.stage_standard(source, discarded)


def sem_ideal(enc: FlatABA, source: int, discarded: int):
    return enc.ideal_standard(source, discarded)


def sem_eager(enc: FlatABA, source: int, discarded: int):
    return enc.eager_standard(source, discarded)


SEMANTICS: dict[str, Semantics] = {
    "cf": sem_cf,
    "stable": sem_stable,
    "admissible": sem_admissible,
    "complete": sem_complete,
    "preferred": sem_preferred,
    "grounded": sem_grounded,
    "naive": sem_naive,
    "semi-stable": sem_semi_stable,
    "stage": sem_stage,
    "ideal": sem_ideal,
    "eager": sem_eager,
}


def beta_sigma(enc: FlatABA, semantic: Semantics, source: int, affordable):
    """Existentially choose D, apply ordinary sigma to F \\ D, then forget D."""
    return disjunction(
        And(enc.valid_discard(discarded), affordable[discarded], semantic(enc, source, discarded))
        for discarded in range(1 << enc.n)
    )


def beta_admissible(enc: FlatABA, source: int, affordable):
    return beta_sigma(enc, sem_admissible, source, affordable)


def preferred_p2(enc: FlatABA, source: int, affordable):
    """The rejected alternative: globally maximal among beta-admissible sets."""
    return And(
        beta_admissible(enc, source, affordable),
        conjunction(
            Not(beta_admissible(enc, other, affordable))
            for other in range(1 << enc.n)
            if proper_subset(source, other)
        ),
    )


class Checker:
    def __init__(self, timeout_ms: int = 120_000):
        self.timeout_ms = timeout_ms
        self.results: list[Result] = []

    def prove(self, obligation: str, scope: str, assumptions, claim, detail: str = ""):
        solver = Solver()
        solver.set(timeout=self.timeout_ms)
        solver.add(assumptions, Not(claim))
        verdict = solver.check()
        if verdict == unsat:
            self.results.append(Result(obligation, "proved", scope, detail))
        elif verdict == sat:
            self.results.append(
                Result(obligation, "failed", scope, f"countermodel: {solver.model()}")
            )
        else:
            self.results.append(Result(obligation, "unknown", scope, str(verdict)))

    def separate(self, obligation: str, scope: str, assumptions, witness, detail: str = ""):
        solver = Solver()
        solver.set(timeout=self.timeout_ms)
        solver.add(assumptions, witness)
        verdict = solver.check()
        if verdict == sat:
            self.results.append(Result(obligation, "separated", scope, detail))
        elif verdict == unsat:
            self.results.append(Result(obligation, "failed", scope, "expected witness is unsat"))
        else:
            self.results.append(Result(obligation, "unknown", scope, str(verdict)))


def pointwise_encoding_checks(checker: Checker):
    enc = FlatABA(4, "point")
    base = enc.monotonicity()
    checker.prove(
        "SEM-SHARED-CONTRARY-TARGET-LOCAL",
        "all symbolic monotone attack maps on four assumptions",
        base,
        conjunction(
            And(
                Not(enc.attacks(support, 0, 1 << 0)),
                enc.attacks(support, 1, 1 << 0) == enc.att[support, 1],
            )
            for support in range(1 << enc.n)
        ),
        "discarding one target unit leaves every other target unit intact, even for a shared contrary",
    )
    pairs = [
        (
            "SEM-DEFENCE-CHARACTERISATION",
            enc.defends_standard(source, target, discarded),
            Not(enc.threatened_by_undefeated(source, target, discarded)),
        )
        for source in range(1 << enc.n)
        for discarded in range(1 << enc.n)
        for target in range(enc.n)
    ]
    checker.prove(
        "SEM-DEFENCE-CHARACTERISATION",
        "all symbolic monotone attack maps on four assumptions",
        base,
        conjunction(left == right for _, left, right in pairs),
        "ordinary ABA defence iff no undefeated support attacks the target",
    )

    checker.prove(
        "SEM-ADM-CLINGO",
        "all symbolic monotone attack maps on four assumptions",
        base,
        conjunction(
            enc.admissible_standard(source, discarded)
            == enc.admissible_clingo(source, discarded)
            for source in range(1 << enc.n)
            for discarded in range(1 << enc.n)
        ),
        "semantics/admissible.lp is ordinary admissibility on Att\\D",
    )
    checker.prove(
        "SEM-COMP-CLINGO",
        "all symbolic monotone attack maps on four assumptions",
        base,
        conjunction(
            enc.complete_standard(source, discarded)
            == enc.complete_clingo(source, discarded)
            for source in range(1 << enc.n)
            for discarded in range(1 << enc.n)
        ),
        "semantics/complete.lp is ordinary completeness on Att\\D",
    )
    checker.prove(
        "SEM-PREF-SAME-REDUCT",
        "all symbolic monotone attack maps on four assumptions",
        base,
        conjunction(
            enc.preferred_standard(source, discarded)
            == enc.preferred_filter(source, discarded)
            for source in range(1 << enc.n)
            for discarded in range(1 << enc.n)
        ),
        "subset maximality is applied only among candidates with the same D",
    )


def higher_order_encoding_checks(checker: Checker):
    enc = FlatABA(3, "higher")
    base = enc.monotonicity()
    pairs = {
        "GROUNDED": (enc.grounded_standard, enc.grounded_filter),
        "NAIVE": (enc.naive_standard, enc.naive_filter),
        "SEMI-STABLE": (enc.semi_stable_standard, enc.semi_stable_filter),
        "STAGE": (enc.stage_standard, enc.stage_filter),
        "IDEAL": (enc.ideal_standard, enc.ideal_filter),
    }
    for label, (standard, implementation) in pairs.items():
        checker.prove(
            f"SEM-{label}-SAME-REDUCT",
            "all symbolic monotone attack maps on three assumptions",
            base,
            conjunction(
                standard(source, discarded) == implementation(source, discarded)
                for source in range(1 << enc.n)
                for discarded in range(1 << enc.n)
            ),
            "the relational filter is exactly the ordinary assumption-level semantics on Att\\D",
        )

    checker.prove(
        "SEM-GROUNDED-UNIQUE",
        "all symbolic monotone attack maps on three assumptions",
        base,
        conjunction(
            Not(And(enc.grounded_standard(left, discarded),
                    enc.grounded_standard(right, discarded)))
            for discarded in range(1 << enc.n)
            for left in range(1 << enc.n)
            for right in range(1 << enc.n)
            if left != right
        ),
        "minimal-complete filtering returns the unique least complete extension",
    )
    checker.prove(
        "SEM-IDEAL-UNIQUE",
        "all symbolic monotone attack maps on three assumptions",
        base,
        conjunction(
            Not(And(enc.ideal_standard(left, discarded),
                    enc.ideal_standard(right, discarded)))
            for discarded in range(1 << enc.n)
            for left in range(1 << enc.n)
            for right in range(1 << enc.n)
            if left != right
        ),
        "maximal universally preferred-contained admissibility returns one ideal extension",
    )
    # Eager semantics nests semi-stable maximality inside universal containment
    # and then maximises once more.  Expanding that formula for three assumptions
    # produces a very large Python/Z3 term before the solver even starts.  Keep
    # the exhaustive symbolic check bounded at two assumptions; the executable
    # oracle suite separately exercises three-assumption and structured cases.
    eager_enc = FlatABA(2, "eager")
    eager_base = eager_enc.monotonicity()
    checker.prove(
        "SEM-EAGER-SAME-REDUCT",
        "all symbolic monotone attack maps on two assumptions",
        eager_base,
        conjunction(
            eager_enc.eager_standard(source, discarded)
            == eager_enc.eager_filter(source, discarded)
            for source in range(1 << eager_enc.n)
            for discarded in range(1 << eager_enc.n)
        ),
        "the relational filter is exactly eager semantics on Att\\D",
    )
    checker.prove(
        "SEM-EAGER-UNIQUE",
        "all symbolic monotone attack maps on two assumptions",
        eager_base,
        conjunction(
            Not(And(eager_enc.eager_standard(left, discarded),
                    eager_enc.eager_standard(right, discarded)))
            for discarded in range(1 << eager_enc.n)
            for left in range(1 << eager_enc.n)
            for right in range(1 << eager_enc.n)
            if left != right
        ),
        "maximal universally semi-stable-contained admissibility returns one eager extension",
    )
    checker.prove(
        "SEM-EAGER-COMPLETE",
        "all symbolic monotone attack maps on two assumptions",
        eager_base,
        conjunction(
            Implies(
                eager_enc.eager_standard(source, discarded),
                eager_enc.complete_standard(source, discarded),
            )
            for discarded in range(1 << eager_enc.n)
            for source in range(1 << eager_enc.n)
        ),
        "the eager extension is complete, justifying complete candidates in eager_filter.lp",
    )
    checker.prove(
        "SEM-SETWISE-GROUNDED-IDEAL-EAGER",
        "all symbolic monotone attack maps on two assumptions",
        eager_base,
        conjunction(
            Implies(
                And(
                    eager_enc.grounded_standard(grounded, discarded),
                    eager_enc.ideal_standard(ideal, discarded),
                    eager_enc.eager_standard(eager, discarded),
                ),
                BoolVal(subset(grounded, ideal) and subset(ideal, eager)),
            )
            for discarded in range(1 << eager_enc.n)
            for grounded in range(1 << eager_enc.n)
            for ideal in range(1 << eager_enc.n)
            for eager in range(1 << eager_enc.n)
        ),
        "the unique extensions satisfy grounded subset ideal subset eager",
    )
    checker.prove(
        "SEM-EAGER-IN-SEMI-STABLE",
        "all symbolic monotone attack maps on two assumptions",
        eager_base,
        conjunction(
            Implies(
                And(
                    eager_enc.eager_standard(eager, discarded),
                    eager_enc.semi_stable_standard(semi_stable, discarded),
                ),
                BoolVal(subset(eager, semi_stable)),
            )
            for discarded in range(1 << eager_enc.n)
            for eager in range(1 << eager_enc.n)
            for semi_stable in range(1 << eager_enc.n)
        ),
        "the eager extension is contained in every semi-stable extension",
    )


def beta_composition_checks(checker: Checker):
    enc = FlatABA(3, "beta")
    base = enc.monotonicity()
    affordable = [Bool(f"aff_{discarded}") for discarded in range(1 << enc.n)]

    implementation_semantics: dict[str, Semantics] = {
        "admissible": lambda e, s, d: e.admissible_clingo(s, d),
        "complete": lambda e, s, d: e.complete_clingo(s, d),
        "preferred": lambda e, s, d: e.preferred_filter(s, d),
    }
    for name in ("admissible", "complete", "preferred"):
        checker.prove(
            f"BETA-{name.upper()}-COMPOSITION",
            "all symbolic monotone attack maps and affordability families on three assumptions",
            base,
            conjunction(
                beta_sigma(enc, SEMANTICS[name], source, affordable)
                == beta_sigma(enc, implementation_semantics[name], source, affordable)
                for source in range(1 << enc.n)
            ),
            "choose affordable D, apply ordinary sigma to Att\\D, existentially forget D",
        )

    affordable_small = [Bool(f"aff_small_{d}") for d in range(1 << enc.n)]
    affordable_large = [Bool(f"aff_large_{d}") for d in range(1 << enc.n)]
    grows = conjunction(
        Implies(affordable_small[d], affordable_large[d]) for d in range(1 << enc.n)
    )
    for name in ("admissible", "complete", "preferred"):
        semantic = SEMANTICS[name]
        checker.prove(
            f"MONO-{name.upper()}",
            "every pointwise-growing affordability family",
            And(base, grows),
            conjunction(
                Implies(
                    beta_sigma(enc, semantic, source, affordable_small),
                    beta_sigma(enc, semantic, source, affordable_large),
                )
                for source in range(1 << enc.n)
            ),
            "the same discard witness remains available"
            + ("; preferred is witness-local P1" if name == "preferred" else ""),
        )

    contains_assumptions = And(base, affordable[0])
    recovery_assumptions = And(
        base,
        affordable[0],
        conjunction(Not(affordable[d]) for d in range(1, 1 << enc.n)),
    )
    for name in ("admissible", "complete", "preferred"):
        semantic = SEMANTICS[name]
        checker.prove(
            f"CONTAINS-{name.upper()}",
            "every affordability family containing the empty discard",
            contains_assumptions,
            conjunction(
                Implies(
                    semantic(enc, source, 0),
                    beta_sigma(enc, semantic, source, affordable),
                )
                for source in range(1 << enc.n)
            ),
            "D=empty preserves every classical extension",
        )
        checker.prove(
            f"RECOVERY-{name.upper()}",
            "every profile in which only the empty discard is affordable",
            recovery_assumptions,
            conjunction(
                semantic(enc, source, 0)
                == beta_sigma(enc, semantic, source, affordable)
                for source in range(1 << enc.n)
            ),
            "when D=empty is the only witness, beta-sigma equals classical sigma",
        )

    # The singleton condition for recovery is sufficient, not necessary.  This exact
    # block-respecting framework has a self-attack on a and an attack a -> b.  Only the
    # latter unit is affordable. Removing it changes neither conflict-free nor stable
    # extensions because the surviving self-attack still excludes every set containing a.
    two = FlatABA(2, "recovery_converse")
    exact_attacks = conjunction(
        two.att[support, target] == BoolVal(member(support, 0))
        for support in range(1 << two.n)
        for target in range(two.n)
    )
    only_b_unit_affordable = [BoolVal(discarded in {0, 2}) for discarded in range(1 << two.n)]
    checker.separate(
        "RECOVERY-CONVERSE-COUNTEREXAMPLE",
        "two assumptions; self-attack unit unaffordable, a-to-b unit affordable",
        And(two.monotonicity(), exact_attacks),
        conjunction(
            semantic(two, source, 0)
            == beta_sigma(two, semantic, source, only_b_unit_affordable)
            for semantic in (sem_cf, sem_stable)
            for source in range(1 << two.n)
        ),
        "an affordable atomic unit need not enlarge conflict-free or stable semantics",
    )


def preferred_reading_checks(checker: Checker):
    enc = FlatABA(3, "pref")
    base = enc.monotonicity()
    affordable = [Bool(f"pref_aff_{d}") for d in range(1 << enc.n)]
    checker.prove(
        "P2-SUBSET-P1",
        "all symbolic monotone attack maps and affordability families on three assumptions",
        base,
        conjunction(
            Implies(
                preferred_p2(enc, source, affordable),
                beta_sigma(enc, sem_preferred, source, affordable),
            )
            for source in range(1 << enc.n)
        ),
        "global beta-admissible maximality is always contained in per-reduct preferredness",
    )
    checker.prove(
        "P1-SUBSET-BETA-ADM",
        "all symbolic monotone attack maps and affordability families on three assumptions",
        base,
        conjunction(
            Implies(
                beta_sigma(enc, sem_preferred, source, affordable),
                beta_admissible(enc, source, affordable),
            )
            for source in range(1 << enc.n)
        ),
        "every witness-local preferred extension is beta-admissible",
    )

    # Minimal strict separation: one self-attacking assumption.  With the attack intact,
    # empty is preferred; after the one affordable discard, {a} is preferred.  P1 returns
    # both, while P2 globally removes empty.
    one = FlatABA(1, "strict")
    one_affordable = [Bool("strict_aff_0"), Bool("strict_aff_1")]
    witness_assumptions = And(
        one.monotonicity(),
        Not(one.att[0, 0]),
        one.att[1, 0],
        one_affordable[0],
        one_affordable[1],
    )
    p1_empty = beta_sigma(one, sem_preferred, 0, one_affordable)
    p1_singleton = beta_sigma(one, sem_preferred, 1, one_affordable)
    p2_empty = preferred_p2(one, 0, one_affordable)
    checker.separate(
        "P1-STRICT-P2",
        "one self-attacking assumption with its attack affordable",
        witness_assumptions,
        And(p1_empty, Not(p2_empty)),
        "P1 contains empty while P2 does not",
    )
    checker.separate(
        "P1-NONANTICHAIN",
        "one self-attacking assumption with its attack affordable",
        witness_assumptions,
        And(p1_empty, p1_singleton),
        "P1 legitimately returns both empty and its strict superset {a}",
    )


def hierarchy_and_mutation_checks(checker: Checker):
    enc = FlatABA(3, "hier")
    base = enc.monotonicity()
    affordable = [Bool(f"hier_aff_{d}") for d in range(1 << enc.n)]
    hierarchy = [
        ("STABLE-PREFERRED", sem_stable, sem_preferred),
        ("PREFERRED-COMPLETE", sem_preferred, sem_complete),
        ("COMPLETE-ADMISSIBLE", sem_complete, sem_admissible),
        ("ADMISSIBLE-CF", sem_admissible, sem_cf),
    ]
    for label, stronger, weaker in hierarchy:
        checker.prove(
            f"HIERARCHY-{label}",
            "all symbolic monotone attack maps and affordability families on three assumptions",
            base,
            conjunction(
                Implies(
                    beta_sigma(enc, stronger, source, affordable),
                    beta_sigma(enc, weaker, source, affordable),
                )
                for source in range(1 << enc.n)
            ),
            "the ordinary same-reduct inclusion lifts through the existential D witness",
        )

    # Negative controls: these deliberately false collapses must have a model.  They prevent a
    # vacuous or over-constrained attack encoding from making every positive obligation green.
    checker.separate(
        "MUTANT-CF-NOT-ADM",
        "symbolic monotone attacks on three assumptions",
        base,
        disjunction(
            And(
                enc.conflict_free(source, 0),
                Not(enc.admissible_standard(source, 0)),
            )
            for source in range(1 << enc.n)
        ),
        "conflict-free must not collapse to admissible",
    )
    checker.separate(
        "MUTANT-ADM-NOT-COMP",
        "symbolic monotone attacks on three assumptions",
        base,
        disjunction(
            And(
                enc.admissible_standard(source, 0),
                Not(enc.complete_standard(source, 0)),
            )
            for source in range(1 << enc.n)
        ),
        "admissible must not collapse to complete",
    )
    checker.separate(
        "MUTANT-COMP-NOT-PREF",
        "symbolic monotone attacks on three assumptions",
        base,
        disjunction(
            And(
                enc.complete_standard(source, 0),
                Not(enc.preferred_standard(source, 0)),
            )
            for source in range(1 << enc.n)
        ),
        "complete must not collapse to preferred",
    )
    checker.separate(
        "MUTANT-PREF-NOT-STABLE",
        "symbolic monotone attacks on three assumptions",
        base,
        disjunction(
            And(
                enc.preferred_standard(source, 0),
                Not(enc.stable(source, 0)),
            )
            for source in range(1 << enc.n)
        ),
        "preferred must not collapse to stable",
    )


def run(timeout_ms: int = 120_000) -> list[Result]:
    checker = Checker(timeout_ms)
    pointwise_encoding_checks(checker)
    higher_order_encoding_checks(checker)
    beta_composition_checks(checker)
    preferred_reading_checks(checker)
    hierarchy_and_mutation_checks(checker)
    return checker.results


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true", help="emit the obligation manifest as JSON")
    parser.add_argument("--timeout-ms", type=int, default=120_000)
    args = parser.parse_args()

    results = run(args.timeout_ms)
    if args.json:
        print(
            json.dumps(
                {
                    "results": [result.__dict__ | {"ok": result.ok} for result in results],
                    "passed": sum(result.ok for result in results),
                    "total": len(results),
                },
                indent=2,
                sort_keys=True,
            )
        )
    else:
        print("=" * 78)
        print("wABA beta-sigma semantics -- symbolic proof obligations")
        print("=" * 78)
        for result in results:
            marker = "PROVED" if result.status == "proved" else (
                "WITNESS" if result.status == "separated" else result.status.upper()
            )
            print(f"  {'ok ' if result.ok else 'FAIL'} {result.obligation:<34} {marker}")
            if result.detail:
                print(f"       {result.detail}")
        passed = sum(result.ok for result in results)
        print(f"\n==== {passed}/{len(results)} semantic obligations verified ====")
    return 0 if all(result.ok for result in results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
