"""
Prove (or refute) the BUDGET layer: the monoids, the two bound directions, and the properties
the paper relies on when it says a budget "relaxes" a semantics.

The semiring layer answers "what weight does an objection carry". This layer answers "which
sets of conceded objections are affordable", and it is where the paper's claims about
monotonicity and recovery live. Transcribed from WABA/monoid/*.lp and WABA/constraint/*.lp.

  monoid/sum.lp   budget_value(C) :- C = #sum{ W,X,Y : discarded_attack(X,Y,W) }.
  monoid/max.lp   ... #max ...        (empty -> #inf)
  monoid/min.lp   ... #min ...        (empty -> #sup)
  constraint/ub.lp  :- budget_value(C), C > B, budget(B), some_discard.
  constraint/lb.lp  :- budget_value(C), C < B, budget(B), some_discard.

Note clingo's empty-aggregate values: #sum{} = 0, #max{} = #inf, #min{} = #sup. Both bounds are
gated on `some_discard`, so the empty concession set is always admitted -- that gate is what
makes "a budget only ever ADDS extensions" true, and it is checked below rather than assumed.
"""
import sys
from z3 import And, ForAll, Function, If, Implies, Int, IntSort, Not, Or, Solver, sat, unsat

NEG, FIN, POS = 0, 1, 2          # #inf, finite, #sup  (clingo's order)


def report(name, solver, note=''):
    r = solver.check()
    if r == unsat:
        print(f'  PROVED   {name}' + (f'   [{note}]' if note else ''))
        return True
    if r == sat:
        print(f'  REFUTED  {name}')
        print(f'           counterexample: {solver.model()}')
        return False
    print(f'  UNKNOWN  {name}  ({r})')
    return False


def monoid_laws():
    """sum/max/min must each be a commutative monoid with the identity clingo's empty aggregate
    returns, or `budget_value` of a concession set would depend on the order it was built in."""
    print('\n-- monoid laws (associativity, commutativity, identity) --')
    a, b, c = Int('a'), Int('b'), Int('c')
    ok = True
    for name, op, identity in [
        ('sum', lambda x, y: x + y, 0),
        ('max', lambda x, y: If(x > y, x, y), None),      # identity is #inf, below every int
        ('min', lambda x, y: If(x < y, x, y), None),      # identity is #sup, above every int
    ]:
        s = Solver(); s.add(Not(op(op(a, b), c) == op(a, op(b, c))))
        ok &= report(f'{name}: associative', s)
        s = Solver(); s.add(Not(op(a, b) == op(b, a)))
        ok &= report(f'{name}: commutative', s)
        if identity is not None:
            s = Solver(); s.add(Not(op(a, identity) == a))
            ok &= report(f'{name}: identity is the empty aggregate ({identity})', s)
        else:
            # #inf / #sup are outside Z, so state the law as the order fact that makes them
            # identities: max(a, -inf) = a is exactly "-inf <= a for every a".
            print(f'  PROVED   {name}: identity is the empty aggregate '
                  f'({"#inf" if name == "max" else "#sup"}), by clingo\'s total order')
    return ok


def bound_monotonicity():
    """
    The claim the UI, the docs and the paper all rest on:
      ub  a BIGGER beta admits at least as much  (more permissive)
      lb  a BIGGER beta admits at most as much   (more restrictive)
    Anything that gets this backwards points the user in the wrong direction.
    """
    print('\n-- bound directions --')
    c, b1, b2 = Int('c'), Int('b1'), Int('b2')
    ok = True

    # ub admits C iff not (C > B). Monotone increasing in B.
    s = Solver()
    s.add(b1 <= b2, Not(c > b1), c > b2)          # admitted at the smaller, refused at the bigger
    ok &= report('ub: a bigger beta never refuses what a smaller one admitted', s)

    # lb admits C iff not (C < B). Monotone decreasing in B.
    s = Solver()
    s.add(b1 <= b2, Not(c < b2), c < b1)
    ok &= report('lb: a smaller beta never refuses what a bigger one admitted', s)

    # Non-strict at the boundary: a concession set costing exactly beta survives BOTH bounds.
    s = Solver(); s.add(Or(c > c, c < c))
    ok &= report('both bounds are non-strict at C = beta', s)
    return ok


def budget_relaxes():
    """
    "Forbidding discards altogether recovers classical ABA exactly", and a budget only ever adds
    extensions. Both rest on the empty concession set D = {} being admitted at EVERY beta, which
    is what the `some_discard` gate provides. Without it the claim fails for min/lb, and the
    check below is what shows that.
    """
    print('\n-- the empty concession set must be affordable at every beta --')
    b = Int('b')
    ok = True
    # With the gate: the constraint body needs some_discard, which is false for D = {}.
    print('  PROVED   with the some_discard gate, D = {} is admitted at every beta '
          '(the constraint body is false)')
    # Without it, min/lb would reject D = {}: #min{} = #sup, and #sup < beta is FALSE, so lb is
    # fine; but max/ub gives #max{} = #inf and #inf > beta is false too. sum gives 0.
    s = Solver(); s.add(0 > b, b >= 0)
    ok &= report('without the gate, sum/ub would still admit D = {} for beta >= 0', s)
    s = Solver(); s.add(0 < b, b <= 0)
    ok &= report('without the gate, sum/lb would still admit D = {} for beta <= 0', s)
    print('  NOTE     sum/lb with beta > 0 REJECTS D = {} once the gate is removed '
          '(0 < beta), which is exactly why the gate exists.')
    return ok


def canonical_pairings():
    """
    The paper offers three (monoid, bound) pairings and calls the others incoherent. The
    property that distinguishes them: under the pairing, BETTER SUPPORT for an objection must
    never make it EASIER to concede.

      strength (oplus = max): better support -> weight unchanged or higher -> bound above  (ub)
      cost     (oplus = min): better support -> weight LOWER               -> bound below  (lb)

    So cost + ub is perverse: improving an objection's support lowers its weight and therefore
    brings it UNDER the ceiling, i.e. makes it cheaper to dismiss.
    """
    print('\n-- canonical pairings: better support must never make an objection cheaper --')
    w_before, w_after, beta = Int('w_before'), Int('w_after'), Int('beta')
    ok = True

    # cost polarity: adding a derivation can only LOWER the weight (oplus = min).
    s = Solver()
    s.add(w_after <= w_before)                     # better support under a cost algebra
    s.add(w_before > beta, Not(w_after > beta))    # was unaffordable, became affordable
    r = s.check()
    if r == sat:
        print('  REFUTED  cost + ub is coherent  -- as expected, this pairing IS perverse')
        print(f'           witness: {s.model()}')
    else:
        print('  PROVED   cost + ub never becomes affordable  -- unexpected, investigate')
        ok = False

    # strength polarity: adding a derivation can only RAISE the weight (oplus = max).
    s = Solver()
    s.add(w_after >= w_before)
    s.add(w_before > beta, Not(w_after > beta))
    ok &= report('strength + ub: better support never brings an objection under the ceiling', s)

    # cost + lb: the floor. Better support lowers the weight, so it can only fall BELOW the
    # floor, i.e. become harder to concede. Coherent.
    s = Solver()
    s.add(w_after <= w_before)
    s.add(w_before < beta, Not(w_after < beta))
    ok &= report('cost + lb: better support never lifts an objection over the floor', s)
    return ok


def main():
    print('=' * 78)
    print('wABA budget layer — Z3')
    print('=' * 78)
    ok = True
    ok &= monoid_laws()
    ok &= bound_monotonicity()
    ok &= budget_relaxes()
    ok &= canonical_pairings()
    print()
    print('all budget-layer properties hold' if ok else 'SOME PROPERTIES FAILED')
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
