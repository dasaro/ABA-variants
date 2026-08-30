#!/usr/bin/env bash
#
# maths.sh — machine-checked verification of the ALGEBRA, as opposed to regression.sh's
# checks of particular runs.
#
# Five layers, using the tool appropriate to each kind of argument:
#
#   semiring_axioms.py   Z3.  The eight commutative-semiring axioms for each algebra, over the
#                        domain core/base.lp actually admits. Quantifies over VALUES, so an SMT
#                        solver settles it universally; testing could only sample.
#   budget_layer.py      Z3.  Monoid laws, both bound directions, the some_discard gate, the
#                        three downward-closed pairings, and semiring/bound polarity.
#   semantics_proofs.py  Z3.  The undefeated-closure characterisation of ABA defence,
#                        admissible/complete encodings, per-reduct preferred filtering, and
#                        the common existential beta-sigma laws.
#   recovery_sweep.py    clingo. "Forbidding discards recovers classical ABA exactly" quantifies
#                        over FRAMEWORKS, which Z3 cannot do, so enumerate every flat framework
#                        over a small signature and compare against ASPforABA's own encodings.
#   beta_sigma_oracle.py Python + clingo. Enumerate structured finite ABA frameworks, compare exact
#                        (extension,D) witnesses, and triangulate reducts against ASPforABA.
#   extended_semantics.py Python + clingo. Independently enumerate grounded, naive, semi-stable,
#                         stage, ideal and eager semantics, including a collective-attack fixture.
#
# Z3 lives in a venv because macOS ships an externally-managed Python:
#   python3 -m venv test/.venv && test/.venv/bin/pip install z3-solver
#
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PY="$ROOT/test/.venv/bin/python"
[ -x "$PY" ] || PY="$(command -v python3)"

fail=0
if ! "$PY" -c 'import z3' 2>/dev/null; then
  echo "  FAIL  z3 not available; run: python3 -m venv $ROOT/test/.venv && $ROOT/test/.venv/bin/pip install z3-solver"
  fail=1
else
  "$PY" "$ROOT/test/semiring_axioms.py" || fail=1
  "$PY" "$ROOT/test/budget_layer.py"    || fail=1
  "$PY" "$ROOT/test/semantics_proofs.py" || fail=1
fi

echo
"$PY" "$ROOT/test/recovery_sweep.py" || fail=1

echo
"$PY" "$ROOT/test/beta_sigma_oracle.py" || fail=1
"$PY" "$ROOT/test/extended_semantics.py" || fail=1

echo
if [ "$fail" = 0 ]; then echo "==== maths checks passed ===="; else echo "==== MATHS CHECKS FAILED ===="; fi
exit "$fail"
