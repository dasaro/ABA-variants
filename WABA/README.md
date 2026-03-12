# WABA

WABA is a compact CLI-first `clingo` project with one supported logic surface.

## Supported Surface

- primary entrypoint: `bin/waba`
- supported semantics: `cf`, `stable`, `admissible`, `complete`, `grounded`, `preferred`
- exact `preferred` semantics via `semantics/subset_maximal_filter.lp`
- supported budget presets:
  - `sum + ub`
  - `max + ub`
  - `count + ub`
  - `min + lb`
- raw modular `clingo` runs remain available for the same mature files

The tree is intentionally small:

- `core/`: shared WABA attack and discard logic
- `semiring/`: the six ordered-semiring variants plus the `arctic` and `bottleneck_cost` aliases
- `defaults/`: `legacy`, `aba`, and `neutral` policies for unweighted assumptions
- `monoid/` and `optimize/`: aggregate family and optimization direction
- `constraint/`: generic `ub`, generic `lb`, and `no_discard`
- `semantics/`: supported raw semantics plus the exact subset-maximal filter used by `preferred`
- `examples/`: the curated example set

## Quick Start

Classical smoke run:

```bash
./bin/waba run \
  --framework examples/aspartix_test/simple_attack.lp \
  --semantics stable \
  --show projection
```

Exact preferred extensions on the read-only reference framework:

```bash
./bin/waba run \
  --framework examples/reference/aspforaba_journal_example.lp \
  --semantics preferred \
  --show projection
```

Budgeted stable reasoning on the curated planning example:

```bash
./bin/waba run \
  --framework examples/practical_deliberation/practical_deliberation.lp \
  --semiring arctic \
  --semantics stable \
  --objective count-min \
  --budget-mode ub \
  --beta 2 \
  --show projection \
  --opt-mode optN
```

Raw modular usage remains available:

```bash
clingo --warn=no-atom-undefined -n 0 -c beta=0 \
  core/base.lp \
  semiring/godel.lp \
  constraint/no_discard.lp \
  filter/projection.lp \
  semantics/stable.lp \
  examples/aspartix_test/simple_attack.lp
```

## Mathematical Split

- semiring modules define local support propagation
- default-policy modules define the injected value for unweighted assumptions
- monoid modules define the aggregate over `discarded_attack/3`
- optimize modules decide whether that aggregate is minimized or maximized
- constraint modules decide whether the aggregate must stay below or above `beta`
- semantics modules decide which extensions survive once successful attacks are fixed

`preferred` is the one supported higher-order semantics that is not a single raw `.lp` file. The wrapper generates `complete` candidates and keeps only the subset-maximal ones with `semantics/subset_maximal_filter.lp`.

## Public Reference

- [examples/README.md](examples/README.md)

## Git Usage

The repository now treats the WABA public surface as:

- `bin/waba`
- `README.md`
- `examples/README.md`
- the mature runtime `.lp` files under `core/`, `defaults/`, `filter/`, `constraint/`, `monoid/`, `optimize/`, `semantics/`, and `semiring/`
- the curated example `.lp` files under `examples/`
- `WABA/.gitignore`

Everything else in `WABA/` is considered private local material and is ignored by the WABA-local `.gitignore`.

The tracked tree also uses the lowercase live paths:

- `WABA/examples/`
- `WABA/semantics/`

From the `ABA-variants/` repo root:

```bash
git status --ignored --short WABA
```

Use that to see the public/private split.

To stage only the public WABA surface:

```bash
printf '%s\n' WABA/.gitignore WABA/README.md WABA/examples/README.md WABA/bin/waba \
  | git add --pathspec-from-file=-
find WABA/core WABA/defaults WABA/filter WABA/constraint WABA/monoid WABA/optimize WABA/semantics WABA/semiring WABA/examples \
  -type f -name '*.lp' -print | git add --pathspec-from-file=-
```

If an already tracked private file needs to be removed from git while kept locally, enforce the policy with:

```bash
git ls-files -ci --exclude-standard WABA | git rm --cached --pathspec-from-file=- --ignore-unmatch
```

After that, `git add WABA` is safe: ignored private files stay local, while the public wrapper and `.lp` surface remain stageable.
