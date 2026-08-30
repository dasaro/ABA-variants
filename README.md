# ABA-variants

This repository hosts some variants of ABA that are being developed by the logic group at UniSalento and collaborators. At the moment, only the *Weighted Assumption Based Argumentation* (*WABA*) framework is being hosted, but other variants are soon to be added.

## Weighted Assumption Based Argumentation

WABA extends flat ABA with numeric weights. Weights may be declared on any atom and are
propagated by a commutative semiring (leaf weights are intrinsic; a derived declaration is
combined with its rule derivations). The attacks an extension concedes are aggregated by a
monoid and bounded by an inconsistency budget `beta`. Conflict-free, stable, admissible,
complete, preferred, grounded, naive, semi-stable, stage, ideal, and eager semantics all use the
same beta-sigma construction: choose one affordable discard set, then apply the ordinary
semantics to the fixed reduct. The explicit no-discard profile recovers classical ABA
exactly. The subset- and range-induced semantics are filtered inside each fixed reduct
before the discard witness is forgotten.

wABA is written from scratch. It uses standard flat-ABA predicates that overlap with
ASPforABA's interface, but it is not derived from ASPforABA or from the separate pABA/ProbLog
implementation. ASPforABA is used only as an external no-discard recovery baseline. The
pABA/ProbLog implementation follows the PABA theory and an ASPforABA-style flat-ABA encoding;
the detailed provenance and external recovery checks are documented in
[WABA/README.md](WABA/README.md#encoding-provenance).

In order to run WABA, you must have `clingo` installed (tested with version 5.8.0 with Python 3.10.17, without Lua, but older versions may be supported).

The `bin/waba` wrapper is the entry point; it composes the modules for you:

```bash
WABA/bin/waba run \
  --framework WABA/examples/reference/aspforaba_journal_example.lp \
  --semantics stable \
  --semiring godel \
  --show projection
```

A budgeted run, conceding at most a total of 20 across the attacks it drops:

```bash
WABA/bin/waba run \
  --framework WABA/examples/practical_deliberation/practical_deliberation.lp \
  --semantics stable \
  --semiring arctic \
  --objective sum-min \
  --budget-mode ub \
  --beta 20
```

The modules can also be loaded directly, one from each layer:

```bash
clingo --warn=no-atom-undefined -n 0 -c beta=0 \
  WABA/core/base.lp \
  WABA/semiring/godel.lp \
  WABA/defaults/neutral.lp \
  WABA/constraint/no_discard.lp \
  WABA/filter/projection.lp \
  WABA/semantics/stable.lp \
  WABA/examples/reference/aspforaba_journal_example.lp
```

See [WABA/README.md](WABA/README.md) for the supported surface (five semirings, eleven
semantics, and the three canonical budget pairings), the split between the layers, and where
weights are allowed to live. The regression suite is `WABA/test/regression.sh`.

## Web Playground

A browser-based playground (Clingo compiled to WebAssembly) is available at
**<https://dasaro.github.io/waba-playground/>**. It runs the same `.lp` modules as
the `bin/waba` CLI, kept in sync by `WABA/bin/sync-playground.mjs`.
