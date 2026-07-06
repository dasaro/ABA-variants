# WABA

WABA is a compact CLI-first `clingo` project with one supported logic surface.

## Supported Surface

- primary entrypoint: `bin/waba`
- supported semantics: `cf`, `stable`, `admissible`, `complete`, `grounded`, `preferred`
- exact `preferred` semantics via `semantics/subset_maximal_filter.lp`
- supported budget presets:
  - `sum + ub`
  - `max + ub`
  - `min + lb`
- raw modular `clingo` runs remain available for the same mature files

The tree is intentionally small:

- `core/`: shared WABA attack and discard logic
- `semiring/`: the four clean algebras (`godel`, `tropical`, `arctic`, `bottleneck_cost`) plus `godel_low` / `tropical_high` as thin polarity-dual aliases
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
  --objective sum-min \
  --budget-mode ub \
  --beta 20 \
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

### Interpreting the choices

Two axes generate the **four clean semirings** — how a rule body combines (`⊗` *idempotent*, "an argument is its worst link", vs. *additive*, "accumulate over the body") and the polarity (`⊕ = max` *strength* vs. `⊕ = min` *cost*):

|                | strength (`⊕ = max`)     | cost (`⊕ = min`)               |
|----------------|--------------------------|--------------------------------|
| `⊗` idempotent | `godel` (max, min)       | `bottleneck_cost` (min, max)   |
| `⊗` additive   | `arctic` (max, +)        | `tropical` (min, +)            |

- **`godel`** — fuzzy confidence; an argument is as strong as its weakest premise (original WABA).
- **`tropical`** — additive cost; an argument's cost is the sum of its steps and the cheapest proof wins (shortest path).
- **`arctic`** — accumulated support; heavier/longer evidence chains win (longest path / reward).
- **`bottleneck_cost`** — worst-case cost; an argument costs as much as its single worst step.

Outside the 2×2 there is one further algebra, **`lukasiewicz`** (bounded sum, `a⊗b = max(0, a+b-k)`, `⊕ = max`, grid `{0..k}` via `#const k`): the only ⊗ that is neither `min`, `max`, nor `+`. Unlike Gödel's weakest-link, a chain of weak premises *erodes* certainty toward 0 — natural for stacking independent noisy evidence.

(`godel_low` and `tropical_high` are polarity-dual aliases of `bottleneck_cost` and `arctic`.)

The **monoid** aggregates the *discarded* attacks into the extension's cost, bounded by `beta`:

- **`sum`** (`ub`) — total spending cap.
- **`max`** (`ub`) — worst single concession: dismiss freely, but never an attack stronger than `beta`.
- **`min`** (`lb`) — quality floor: every dismissed attack must be at least `beta`-strong.

`beta = 0` (or `no_discard`) recovers classical ABA. **Weights as probabilities:** encode `w = round(-K ln p)` and run `tropical`; the propagated weight is then the surprisal of an atom's most-probable proof (decode `p = exp(-w/K)`) — see `examples/probabilistic/`.

### Where weights live (leaves vs derived atoms)

WABA weights are intrinsic to the **leaves**: `weight/2` on an assumption (its own strength) or on a fact (an empty-body rule head). A **derived** atom gets its weight by *propagation* — the semiring combines its premises with `⊗` and alternative derivations with `⊕`. **Put the weights on the leaves and let them propagate**; that is the canonical model.

An explicit `weight/2` on a *derived* atom is combined with its own derivation via `⊕`, so in most algebras it is **silently dominated** and never takes effect:

|                  | `⊗`-identity | explicit weight `W` on a derived atom (from unweighted supports) |
|------------------|--------------|-------------------------------------------------------------------|
| `arctic`         | `0`          | **survives** — `max(W, 0) = W`                                    |
| `tropical`       | `0`          | **survives** — `min(W, #sup) = W` (via the legacy `#sup` default) |
| `godel`          | `#sup`       | dominated → `#sup`  (`max(W, #sup)`)                              |
| `bottleneck_cost`| `#inf`       | dominated → `#inf`  (`min(W, #inf)`)                             |
| `lukasiewicz`    | `k`          | dominated → `k`     (`max(W, k)`)                                |

`core/base.lp` flags this as **`weight_on_derived_dominated(X, Declared, Effective)`** (the filter modules `#show` it; it is empty for a well-formed framework). A declared weight that did not take effect almost always means it belongs on a leaf instead. The "a weighted non-assumption atom" requirement is met cleanly by a **weighted fact** — `weight(f, W). head(r, f).` with an empty body — whose weight is intrinsic and always survives.

**`tropical` is the one asymmetric algebra.** Its `⊗`-identity is `0`, but the *legacy* default weight for an unweighted assumption is `#sup` (the `⊕`-identity / `⊗`-annihilator), **not** `0`. So an unweighted assumption *annihilates* a `tropical` conjunction: `c_acc ← t_acc, objection` collapses to `#sup`. Route the objection through an intermediate instead (`objection ← t_acc`; `c_acc ← objection`) — which works because a *weighted* intermediate survives under `tropical`. There is **no free lunch**: the `#sup` default is exactly what makes weighted intermediates survive, while the `neutral` default (`0`) fixes the annihilation but then kills weighted intermediates — choose per model. The other four algebras use their `⊗`-identity as the default, so unweighted assumptions are transparent in a conjunction.

## Web Playground Sync

The browser playground (<https://dasaro.github.io/waba-playground/>) runs the same
`.lp` logic compiled into a single `waba-modules.js`. To keep that bundle from
drifting, `bin/sync-playground.mjs` regenerates it from this canonical tree,
**auto-discovering** the module set (semirings, monoids, semantics, examples) so
there is no hand-maintained manifest to go stale:

```bash
node bin/sync-playground.mjs ../waba-playground/waba-modules.js
# or point at any WABA tree:
WABA_ROOT=/path/to/WABA node bin/sync-playground.mjs out/waba-modules.js
```

The emitted bundle matches the playground's expected schema. Note it only syncs
the `.lp` bundle and its metadata — the playground's JS/UI must independently
expose the same surface (families `godel`/`tropical` plus standalone `lukasiewicz`,
monoids `sum`/`max`/`min`, no `count`).

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
