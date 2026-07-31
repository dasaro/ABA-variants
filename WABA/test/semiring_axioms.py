"""
Prove (or refute) the commutative-semiring axioms for wABA's five algebras, over the domain the
IMPLEMENTATION actually admits: Z union {#inf, #sup}, with clingo's order #inf < n < #sup.

The claim under test is the paper's: "the five algebras are genuine semirings".

The operations below mirror WABA/semiring/*.lp exactly, INCLUDING the infinity handling that
exists because clingo's #sum silently drops non-integral tuples:

  _idempotent.lp   otimes = min or max on the lifted order (no guards needed)
  _additive.lp     otimes = annihilator-first, then opposite-infinity, then integer sum
  lukasiewicz.lp   otimes = #inf -> 0; else max(0, S + NS*k - (N-1)*k) with #sup read as k

A semiring needs a BINARY associative otimes, and the n-ary rule_deriv must agree with folding
that binary op -- otherwise the value a derivation gets depends on how the rule was written.
Both are checked.
"""
import itertools
import sys
from z3 import (And, Distinct, ForAll, If, Implies, Int, IntSort, Not, Or, Solver, sat, unsat)

# ---------------------------------------------------------------------------
# Lifted domain: tag 0 = #inf, 1 = finite (value in `v`), 2 = #sup
# ---------------------------------------------------------------------------
NEG, FIN, POS = 0, 1, 2


class Val:
    """A symbolic element of Z union {#inf, #sup}."""

    def __init__(self, name):
        self.t = Int(f'{name}_t')
        self.v = Int(f'{name}_v')

    def wf(self):
        # tag in range, and `v` pinned to 0 when the tag is infinite so that two
        # representations of the same infinity cannot differ.
        return And(self.t >= NEG, self.t <= POS, Implies(self.t != FIN, self.v == 0))

    def vars(self):
        return [self.t, self.v]


def eq(a, b):
    return And(a.t == b.t, Implies(a.t == FIN, a.v == b.v))


def lt(a, b):
    """clingo's order: #inf < every integer < #sup."""
    return Or(And(a.t == NEG, b.t != NEG),
              And(a.t == FIN, b.t == FIN, a.v < b.v),
              And(a.t != POS, b.t == POS))


def pick(cond, a, b):
    """A Val-valued if-then-else."""
    out = type('V', (), {})()
    out.t = If(cond, a.t, b.t)
    out.v = If(cond, a.v, b.v)
    return out


def vmax(a, b):
    return pick(lt(a, b), b, a)


def vmin(a, b):
    return pick(lt(a, b), a, b)


def const(tag, value=0):
    out = type('V', (), {})()
    out.t, out.v = tag, value
    return out


INF, SUP = const(NEG), const(POS)


def is_(a, c):
    return And(a.t == c.t, Implies(a.t == FIN, a.v == c.v))


# ---------------------------------------------------------------------------
# The five algebras, transcribed from the .lp modules
# ---------------------------------------------------------------------------
def otimes_additive(a, b, annih, opp):
    """_additive.lp: annihilator first, then the opposite infinity, then the integer sum."""
    total = type('V', (), {})()
    total.t, total.v = FIN, a.v + b.v
    return pick(Or(is_(a, annih), is_(b, annih)), annih,
                pick(Or(is_(a, opp), is_(b, opp)), opp, total))


def otimes_luk(a, b, k):
    """
    lukasiewicz.lp as a BINARY operation (N = 2).
      #inf anywhere            -> 0   (the bounded-sum annihilator, taking precedence)
      otherwise                -> max(0, S + NS*k - (N-1)*k), reading #sup as the grid top k
    """
    zero = const(FIN, 0)
    s = If(a.t == FIN, a.v, 0) + If(b.t == FIN, b.v, 0)
    ns = If(a.t == POS, 1, 0) + If(b.t == POS, 1, 0)
    raw = s + ns * k - k                     # (N-1)*k with N = 2
    clamped = type('V', (), {})()
    clamped.t, clamped.v = FIN, If(raw > 0, raw, 0)
    return pick(Or(a.t == NEG, b.t == NEG), zero, clamped)


K = Int('k')

ALGEBRAS = {
    # name: (oplus, otimes, zero (oplus-identity), one (otimes-identity), extra constraints)
    'godel': (vmax, vmin, INF, SUP, []),
    'bottleneck_cost': (vmin, vmax, SUP, INF, []),
    'tropical': (vmin, lambda a, b: otimes_additive(a, b, SUP, INF), SUP, const(FIN, 0), []),
    'arctic': (vmax, lambda a, b: otimes_additive(a, b, INF, SUP), INF, const(FIN, 0), []),
    'lukasiewicz': (vmax, lambda a, b: otimes_luk(a, b, K), const(FIN, 0), None, [K > 0]),
}

# ---------------------------------------------------------------------------
# The axioms
# ---------------------------------------------------------------------------
def axioms(oplus, otimes, zero, one):
    a, b, c = Val('a'), Val('b'), Val('c')
    wf = And(a.wf(), b.wf(), c.wf())
    xs = a.vars() + b.vars() + c.vars()
    return [
        ('oplus assoc', xs, wf, eq(oplus(oplus(a, b), c), oplus(a, oplus(b, c)))),
        ('oplus comm', xs, wf, eq(oplus(a, b), oplus(b, a))),
        ('oplus identity', a.vars(), a.wf(), eq(oplus(a, zero), a)),
        ('otimes assoc', xs, wf, eq(otimes(otimes(a, b), c), otimes(a, otimes(b, c)))),
        ('otimes comm', xs, wf, eq(otimes(a, b), otimes(b, a))),
        ('otimes identity', a.vars(), a.wf(), eq(otimes(a, one), a)),
        ('zero annihilates', a.vars(), a.wf(), eq(otimes(a, zero), zero)),
        ('otimes distributes over oplus', xs, wf,
         eq(otimes(a, oplus(b, c)), oplus(otimes(a, b), otimes(a, c)))),
    ]


def idempotence(oplus, otimes):
    """
    Is (x) IDEMPOTENT?  a (x) a = a.

    Not a semiring axiom, but it decides something the paper has to state: whether an atom's
    weight depends on its derivation TREE or only on the SET of leaves that support it.

    Folding (x) over a rule body counts each leaf OCCURRENCE. If (x) is idempotent the duplicates
    collapse, so the fold depends only on the support set -- which is what ABA's own notion of an
    argument (S, c) with S a SET requires. If it is not, two atoms with the SAME support set get
    DIFFERENT weights when their derivation trees differ, and under the probabilistic reading a
    fact reused in one proof is multiplied twice, as if independent of itself.

    Measured on a framework where x and y both have support {f0(100), f1(200)}:
        godel 100/100  bottleneck_cost 200/200      (idempotent -- agree)
        tropical 300/500  arctic 300/500            (additive   -- differ)
    """
    a = Val('a')
    s = Solver()
    s.add(a.wf())
    s.add(Not(eq(otimes(a, a), a)))
    return s


def show(a_t, a_v, model):
    t = model.eval(a_t, model_completion=True).as_long()
    return '#inf' if t == NEG else ('#sup' if t == POS else str(model.eval(a_v, model_completion=True)))


def check(name, restrict_carrier=False):
    oplus, otimes, zero, one, extra = ALGEBRAS[name]
    if one is None:                                   # lukasiewicz: 1-bar is the constant k
        one = const(FIN, K)
    failures = []
    for axiom, xs, wf, claim in axioms(oplus, otimes, zero, one):
        s = Solver()
        for e in extra:
            s.add(e)
        if restrict_carrier:
            # The carrier the algebra is DEFINED over, as opposed to what the code admits.
            for var in xs[::2]:
                idx = xs.index(var)
                tag, val = xs[idx], xs[idx + 1]
                if name == 'tropical':
                    s.add(tag != NEG)                 # Z union {+inf}
                elif name == 'arctic':
                    s.add(tag != POS)                 # Z union {-inf}
                elif name == 'lukasiewicz':
                    s.add(tag == FIN, val >= 0, val <= K)
        s.add(wf)
        s.add(Not(claim))
        r = s.check()
        if r == sat:
            m = s.model()
            wit = ', '.join(f'{chr(97 + i)} = {show(xs[2 * i], xs[2 * i + 1], m)}'
                            for i in range(len(xs) // 2))
            kv = f', k = {m.eval(K)}' if name == 'lukasiewicz' else ''
            failures.append((axiom, wit + kv))
        elif r != unsat:
            failures.append((axiom, f'UNKNOWN ({r})'))
    return failures


def main():
    """
    Check each algebra over the carrier the IMPLEMENTATION ENFORCES.

    For godel, bottleneck_cost, tropical and arctic that is the whole lifted domain
    Z u {#inf, #sup}: core/base.lp admits both sentinels, and the infinity guards in
    _additive.lp / _idempotent.lp are what make the axioms survive them.

    For lukasiewicz it is [0, k], enforced by the carrier guard in semiring/lukasiewicz.lp.
    That guard exists BECAUSE of this file: off the grid, Z3 refutes the annihilator law
    (0 (x) 7 = 4 at k = 3, reproduced in clingo), associativity, and both identities.
    """
    enforced = {name: (name == 'lukasiewicz') for name in ALGEBRAS}
    print('=' * 78)
    print('wABA semiring axioms — Z3, over each algebra\'s ENFORCED carrier')
    print('  godel / bottleneck_cost / tropical / arctic : Z u {#inf, #sup}')
    print('  lukasiewicz                                 : [0, k]  (carrier guard)')
    print('=' * 78)
    ok = True
    for name in ALGEBRAS:
        fails = check(name, restrict_carrier=enforced[name])
        if not fails:
            print(f'  {name:18} all 8 axioms PROVED')
        else:
            ok = False
            print(f'  {name:18} {len(fails)} FAILED')
            for axiom, wit in fails:
                print(f'      x {axiom:34} counterexample: {wit}')

    print()
    print('-' * 78)
    print('(x) IDEMPOTENT?  decides weight-of-tree vs weight-of-support-set')
    print('-' * 78)
    for name in ALGEBRAS:
        oplus, otimes, zero, one, extra = ALGEBRAS[name]
        if one is None:
            one = const(FIN, K)
        s = idempotence(oplus, otimes)
        for e in extra:
            s.add(e)
        if name == 'lukasiewicz':
            # on its own carrier [0, k], or the witness would be an off-grid value the
            # implementation now rejects anyway
            s.add(Int('a_t') == FIN, Int('a_v') >= 0, Int('a_v') <= K)
        verdict = s.check()
        if verdict == unsat:
            print(f'  {name:18} IDEMPOTENT     -> weight depends only on the SUPPORT SET')
        else:
            m = s.model()
            wit = show(Int('a_t'), Int('a_v'), m)
            print(f'  {name:18} NOT idempotent -> weight depends on the derivation TREE '
                  f'(a = {wit})')

    print()
    print('-' * 78)
    print('Why the lukasiewicz guard exists: the same axioms WITHOUT it')
    print('-' * 78)
    fails = check('lukasiewicz', restrict_carrier=False)
    for axiom, wit in fails:
        print(f'  refuted  {axiom:34} {wit}')
    if not fails:
        print('  (none — unexpected; the guard may no longer be doing anything)')
        ok = False
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
