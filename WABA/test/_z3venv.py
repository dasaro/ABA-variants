"""Re-exec into test/.venv when z3 is missing from the invoking interpreter.

maths.sh already prefers test/.venv; this makes DIRECT invocation
(`python3 test/semiring_axioms.py`) behave the same way instead of dying with a raw
ModuleNotFoundError. Import it before the first `from z3 import ...`:

    import _z3venv  # noqa: F401  (re-execs via test/.venv if z3 is absent)

If the venv is missing too, fail with the same instruction maths.sh prints.
"""
import importlib.util
import os
import sys

if importlib.util.find_spec("z3") is None:
    _venv_py = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".venv", "bin", "python")
    if os.path.exists(_venv_py) and os.environ.get("WABA_Z3_REEXEC") != "1":
        os.environ["WABA_Z3_REEXEC"] = "1"
        os.execv(_venv_py, [_venv_py, *sys.argv])
    sys.exit(
        "z3 not available; run: python3 -m venv test/.venv && test/.venv/bin/pip install z3-solver"
    )
