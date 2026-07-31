#!/usr/bin/env bash
#
# maths.sh — machine-checked verification of the ALGEBRA, as opposed to regression.sh's
# checks of particular runs.
#
# Three layers, three tools, because they need three different kinds of argument:
#
#   semiring_axioms.py   Z3.  The eight commutative-semiring axioms for each algebra, over the
#                        domain core/base.lp actually admits. Quantifies over VALUES, so an SMT
#                        solver settles it universally; testing could only sample.
#   budget_layer.py      Z3.  Monoid laws, both bound directions, the some_discard gate, and
#                        why only three (monoid, bound) pairings are coherent.
#   recovery_sweep.py    clingo. "Forbidding discards recovers classical ABA exactly" quantifies
#                        over FRAMEWORKS, which Z3 cannot do, so enumerate every flat framework
#                        over a small signature and compare against ASPforABA's own encodings.
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
  echo "  SKIP  z3 not available; run: python3 -m venv $ROOT/test/.venv && $ROOT/test/.venv/bin/pip install z3-solver"
else
  "$PY" "$ROOT/test/semiring_axioms.py" || fail=1
  "$PY" "$ROOT/test/budget_layer.py"    || fail=1
fi

echo
"$PY" "$ROOT/test/recovery_sweep.py" || fail=1

echo
if [ "$fail" = 0 ]; then echo "==== maths checks passed ===="; else echo "==== MATHS CHECKS FAILED ===="; fi
exit "$fail"
