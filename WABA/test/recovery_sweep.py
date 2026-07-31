"""
Exhaustive check of the paper's second claim: "Forbidding discards altogether recovers classical
ABA exactly."

Z3 cannot do this one -- it quantifies over FRAMEWORKS, not over values. So enumerate every flat
ABA framework over a small signature and compare, extension set by extension set, against an
EXTERNAL oracle (ASPforABA's own encodings), not against another of our modules.

Two things are checked at once:
  1. recovery      wABA + constraint/no_discard.lp == classical ABA, for each semantics
  2. independence  that agreement holds for EVERY algebra. A recovery that worked for godel and
                   not for tropical would be a false generalisation of exactly the kind this
                   sweep exists to find.
"""
import itertools
import os
import re
import subprocess
import sys
from concurrent.futures import ProcessPoolExecutor

import pathlib
ROOT = str(pathlib.Path(__file__).resolve().parent.parent)
ASPFORABA = os.environ.get('ASPFORABA', '/Users/fdasaro/Downloads/aspforaba/encodings')
CLINGO = 'clingo'

ALGEBRAS = {'godel': 'higher', 'arctic': 'higher', 'lukasiewicz': 'higher',
            'tropical': 'lower', 'bottleneck_cost': 'lower'}
DEFENCE = ('admissible', 'complete')
# stable and complete have first-party ASPforABA encodings; admissible is reproduced from
# their encoder.py (COMMON + ADMISSIBLE_ADD), exactly as WABA/test/regression.sh does.
# The ASPforABA admissible encoding, taken VERBATIM from WABA/test/regression.sh, which in
# turn reproduces src/aspforaba/encoder.py (COMMON + ADMISSIBLE_ADD) and cross-validates it
# against their own stb-aba-enum.dl and com-aba-cred.dl. My first attempt reconstructed it from
# memory and admitted sets that are not admissible (e.g. {a0} when a1 attacks a0 undefended),
# which produced dozens of "mismatches" that were the ORACLE's fault, not the implementation's.
ASP_COMMON = """
{ in(X) : assumption(X) }.
out(X) :- not in(X), assumption(X).
supported(X) :- assumption(X), in(X).
supported(X) :- head(R,X), triggered_by_in(R).
triggered_by_in(R) :- head(R,_), supported(X) : body(R,X).
:- in(X), contrary(X,Y), supported(Y).
defeated(X) :- supported(Y), contrary(X,Y).
#show in/1.
"""
ASP_ADM = """
derived_from_undefeated(X) :- assumption(X), not defeated(X).
derived_from_undefeated(X) :- head(R,X), triggered_by_undefeated(R).
triggered_by_undefeated(R) :- head(R,_), derived_from_undefeated(X) : body(R,X).
attacked_by_undefeated(X) :- contrary(X,Y), derived_from_undefeated(Y).
:- in(X), attacked_by_undefeated(X).
"""


def run(args, program):
    # `-` is REQUIRED: clingo ignores stdin as soon as any file argument is present, so without
    # it the framework silently never reached the solver and every wABA call returned nothing.
    p = subprocess.run([CLINGO, '--warn=none', '-n', '0', '--outf=0', *args, '-'],
                       input=program, capture_output=True, text=True)
    return p.stdout


def extensions(output):
    """
    Answer sets as frozensets of the atoms inside in(...).

    Driven by the "Answer: n" marker: the NEXT line is that answer set, and it is BLANK for the
    empty extension. Scanning for lines that merely contain "in(" drops the empty set, which is
    an extension under cf/admissible/complete on every framework -- exactly the case a recovery
    check must not miss.
    """
    sets = set()
    lines = output.split('\n')
    for i, line in enumerate(lines):
        if not line.startswith('Answer:'):
            continue
        payload = lines[i + 1] if i + 1 < len(lines) else ''
        sets.add(frozenset(re.findall(r'(?:^|\s)in\(([^)]*)\)', payload)))
    return sets


# Recovery is NOT universally at beta = 0. semantics/admissible.lp derives its bound from the
# polarity: oplus = max forbids any pay at beta = 0, while oplus = min imposes #min{paid} >= beta,
# for which beta = 0 is VACUOUS and recovery arrives at a beta above every attack weight. Running
# the cost algebras at 0 is what my first sweep did, and it reported them as broken.
COST_RECOVERY_BETA = 1000000


def solve_waba(framework, algebra, semantics, polarity):
    mods = [f'{ROOT}/core/base.lp', f'{ROOT}/semiring/{algebra}.lp',
            f'{ROOT}/defaults/neutral.lp', f'{ROOT}/constraint/no_discard.lp',
            f'{ROOT}/filter/projection.lp', f'{ROOT}/semantics/{semantics}.lp']
    beta = COST_RECOVERY_BETA if (polarity == 'lower' and semantics in DEFENCE) else 0
    args = ['-c', f'beta={beta}', *mods]
    if semantics in DEFENCE:
        args += ['--project']
    return extensions(run(args, framework))


def solve_oracle(framework, semantics):
    if semantics == 'stable':
        return extensions(run([f'{ASPFORABA}/stb-aba-enum.dl'], framework))
    if semantics == 'complete':
        return extensions(run([f'{ASPFORABA}/com-aba-cred.dl', '--project'], framework))
    if semantics == 'admissible':
        return extensions(run(['--project'], framework + ASP_COMMON + ASP_ADM))
    raise ValueError(semantics)


def make_framework(n, rules):
    """Flat ABA: n assumptions, each with its own contrary atom, plus the chosen rules."""
    out = []
    for i in range(n):
        out.append(f'assumption(a{i}). contrary(a{i},c{i}). weight(a{i},{i + 1}).')
    for j, (head, body) in enumerate(rules):
        out.append(f'head(r{j},{head}).' + ''.join(f' body(r{j},{b}).' for b in body))
    return '\n'.join(out) + '\n'


def rule_pool(n):
    heads = [f'c{i}' for i in range(n)]
    assumptions = [f'a{i}' for i in range(n)]
    bodies = [()] + [(x,) for x in assumptions] + list(itertools.combinations(assumptions, 2))
    return [(h, b) for h in heads for b in bodies]


def check_one(job):
    n, rules, semantics = job
    fw = make_framework(n, rules)
    try:
        oracle = solve_oracle(fw, semantics)
    except Exception as exc:                       # noqa: BLE001
        return ('oracle-error', semantics, rules, str(exc), None)
    per_algebra = {}
    for algebra, polarity in ALGEBRAS.items():
        per_algebra[algebra] = solve_waba(fw, algebra, semantics, polarity)
    bad = [a for a, ext in per_algebra.items() if ext != oracle]
    if bad:
        return ('mismatch', semantics, rules, sorted(oracle),
                {a: sorted(per_algebra[a]) for a in bad})
    return None


def main():
    if not os.path.isfile(f'{ASPFORABA}/stb-aba-enum.dl'):
        print(f'ASPforABA not found at {ASPFORABA}; set ASPFORABA=...')
        return 2

    jobs = []
    for n in (2, 3):
        pool = rule_pool(n)
        max_rules = 3 if n == 2 else 2
        for size in range(0, max_rules + 1):
            for rules in itertools.combinations(pool, size):
                for semantics in ('stable', 'admissible', 'complete'):
                    jobs.append((n, rules, semantics))

    print(f'frameworks x semantics to check: {len(jobs)}  '
          f'({len(jobs) * len(ALGEBRAS)} wABA solves + {len(jobs)} oracle solves)')
    failures = []
    done = 0
    with ProcessPoolExecutor() as pool_exec:
        for result in pool_exec.map(check_one, jobs, chunksize=8):
            done += 1
            if done % 500 == 0:
                print(f'  ... {done}/{len(jobs)}')
            if result:
                failures.append(result)
    print()
    if not failures:
        print(f'RECOVERY HOLDS: all {len(jobs)} (framework, semantics) cases agree with the '
              f'external oracle, for all {len(ALGEBRAS)} algebras.')
        return 0
    print(f'{len(failures)} MISMATCHES (showing the first 10):')
    for kind, semantics, rules, oracle, got in failures[:10]:
        print(f'  [{kind}] {semantics}  rules={rules}')
        print(f'      oracle: {oracle}')
        print(f'      wABA  : {got}')
    return 1


if __name__ == '__main__':
    sys.exit(main())
