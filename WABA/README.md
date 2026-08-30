# WABA

WABA is a compact CLI-first `clingo` project with one supported logic surface.

## Supported Surface

- primary entrypoint: `bin/waba`
- supported semantics: `cf`, `stable`, `admissible`, `complete`, `preferred`,
  `grounded`, `naive`, `semi-stable`, `stage`, `ideal`, and `eager` (one common
  beta-sigma construction)
- exact per-reduct filters for subset- and range-induced semantics
- supported budget presets:
  - `sum + ub`
  - `max + ub`
  - `min + lb`
- `--luk-k K` sets Lukasiewicz's bound (`#const k`, default 1000). Its conjunction is
  `max(0, a+b-k)`, so at the default an ordinary small-integer derivation erodes to 0; keep
  `k` near the scale of the declared weights. The wrapper always passes the effective value;
  an authored `#const k=...` remains syntactically legal but is overridden.
- raw modular `clingo` runs remain available for the same mature files

The tree is intentionally small:

- `core/`: shared WABA attack and discard logic
- `semiring/`: the four algebras of the 2x2 (`godel`, `tropical`, `arctic`, `bottleneck_cost`) plus `lukasiewicz` (the Lukasiewicz t-norm, outside the 2x2), with `godel_low` / `tropical_high` as thin polarity-dual aliases
- `defaults/`: `aba` and `neutral` policies for unweighted assumptions (`neutral` is the default)
- `monoid/` and `optimize/`: aggregate family and optimization direction
- `constraint/`: generic `ub`, generic `lb`, and `no_discard`
- `semantics/`: the four candidate kernels plus exact per-reduct subset/range filters
- `examples/`: the curated example set

## Encoding provenance

wABA is written from scratch. It uses standard flat-ABA predicates that overlap with
[ASPforABA](https://bitbucket.org/coreo-group/aspforaba/)'s interface, but it is not derived
from ASPforABA or from the separate pABA/ProbLog implementation. ASPforABA is used only as an
external no-discard recovery baseline where their supported semantics overlap. The separate
pABA/ProbLog implementation follows the PABA theory and an ASPforABA-style flat-ABA encoding;
the wABA additions are semiring propagation, fixed priced attack units, the affordable reduct,
reduct-local semantic filters, and discard receipts.

## Quick Start

Classical smoke run:

```bash
./bin/waba run \
  --framework examples/aspartix_test/simple_attack.lp \
  --semantics stable \
  --show projection
```

Exact classical preferred extensions on the read-only reference framework:

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
  defaults/neutral.lp \
  constraint/no_discard.lp \
  filter/projection.lp \
  semantics/stable.lp \
  examples/aspartix_test/simple_attack.lp
```

## Mathematical Split

- semiring modules define local support propagation
- default-policy modules define the injected value for unweighted assumptions
- monoid modules define the aggregate over `discarded_attack/3`
- optimize modules provide a minimization or maximization direction when explicit ranking is requested
- constraint modules decide whether the aggregate must stay below or above `beta`
- semantics modules apply ordinary ABA semantics to the surviving attack relation

**One beta-sigma mechanism.** The maximal assumption context fixes the weighted
atom-level attack relation before any candidate extension is evaluated. A run chooses one
discard set `D`, the selected monoid aggregates the weights in `D`, and `ub` or `lb` checks
that aggregate against `beta`. The selected ordinary semantics sigma is then evaluated on
the single reduced relation `Att − D`. This is the same pipeline for all eleven supported
semantics; there is no defence-specific `pay` relation or second interpretation of `beta`.

Consequently all eleven semantics use the same CLI profile. A budgeted run supplies
`--objective`, `--budget-mode`, and `--beta`; a run with no budget mode loads
`constraint/no_discard.lp`. `--aba-recovery` is an explicit alias for that exact no-discard
profile. For example, changing `--semantics stable` in the budgeted command above to
`admissible` or `complete` changes only sigma, not how attacks are discarded or priced.

The option remains named `--objective` because its family (`sum`, `max`, or `min`) selects the
aggregation monoid as well as a possible ranking direction. Supplying it does **not** filter
the semantics by default: with no `--opt-mode`, the CLI enumerates the full existential union
over all affordable `D`. Add `--opt-mode optN` only when the desired result is the globally
objective-optimal subset. The budgeted example above requests that filtering explicitly;
omit its final line to enumerate the pure beta-sigma semantics.

### Higher-order semantics

Four kernels are evaluated directly on each fixed reduct: conflict-free, stable,
admissible and complete.  The remaining semantics are exact relational filters over one
of those candidate families.  Write `S+` for the assumptions attacked by `S` in the
current reduct and `range(S) = S union S+`:

| semantics | candidate family | per-reduct selection |
|-----------|------------------|-----------------------|
| `preferred` | admissible | subset-maximal `S` |
| `grounded` | complete | the unique least `S` |
| `naive` | conflict-free | subset-maximal `S` |
| `semi-stable` | complete | subset-maximal `range(S)` |
| `stage` | conflict-free | subset-maximal `range(S)` |
| `ideal` | admissible | the largest `S` contained in every preferred extension |
| `eager` | complete | the largest `S` contained in every semi-stable extension |

Every comparison is made **between candidates with the same `D`**.  Only afterwards does
the wrapper existentially forget `D` and merge equal extensions.  Comparing candidates
from different affordable reducts would silently define another semantics.  Equal maximal
ranges may have several witnessing extensions, so the range filter keeps all of them.
If several discard sets witness the same extension, the supported CLI displays one solver
representative; that receipt is neither canonical nor implicitly cheapest. Direct-semantics
runs enumerate all `(S,D)` witnesses when the raw modules are composed without `--project`.

The price of this deliberately simple reference architecture is materialisation: if pass 1
produces `m` `(S,D)` witnesses, pass 2 can compare quadratically many pairs.  The affordable
discard choices can already be exponential in the number of weighted attack units.  This is
an exact enumeration interface, not a claim that the higher-order decision problems have
become easy.  Grounded semantics in particular admits more specialised fixed-point
algorithms; it is implemented as least-complete filtering here to keep one auditable
beta-sigma architecture.

This is a multi-shot implementation in the same spirit as the higher-order
[ASPARTIX encodings](https://www.dbai.tuwien.ac.at/research/argumentation/aspartix/dung.html),
but the candidate kernels are ABA encodings over derivability, not copied Dung-AF graph
encodings.  The assumption-level definitions of grounded, preferred, ideal and
semi-stable used here agree with the correspondences established by
[Schulz and Toni (2017)](https://doi.org/10.1016/j.ijar.2017.02.005).  `stage` is the
parallel assumption-level range construction starting from conflict-free rather than
complete candidates. Eager semantics is the unique greatest admissible subset common to
all semi-stable extensions; the implementation may start from complete candidates because
the eager extension is complete, following
[Caminada (2007)](https://users.cs.cf.ac.uk/CaminadaM/publications/ideal-eager.pdf).
Naive/maximal-conflict-free ABA goes back to the foundational
[Bondarenko et al. framework](https://doi.org/10.1016/S0004-3702(97)00015-5), while the
ABA ideal semantics is treated directly by
[Dung, Mancarella and Toni (2007)](https://doi.org/10.1016/j.artint.2007.05.003).

`CF2` and `stage2` are deliberately **not** exposed.  Their ASPARTIX encodings implement
the SCC-recursive semantics of a binary Dung graph.  A flat ABA framework instead has
collective attacks: a set of assumptions may derive a contrary even though no member can
do so alone.  Reusing `cf2.lp` on a singleton attack graph would therefore change the
framework, while instantiating every ABA argument would change both the representation and
the intended assumption-level semantics. Supporting CF2 needs an explicit choice of an
argument-graph or direct assumption-level lift and a separate correctness result; the
original recursive schema is due to
[Baroni, Giacomin and Guida (2005)](https://doi.org/10.1016/j.artint.2005.05.006).
[Blümel, Rapberger, Thimm and Toni (2025)](https://doi.org/10.24963/ijcai.2025/488)
subsequently gave a native SCC-recursive schema for flat ABA. That result supplies the right
framework for a direct implementation, but it does not itself choose a CF2 base case or show
that the recursion remains local to each affordable budget reduct.

### Interpreting the choices

Two axes generate the **four clean semirings** — how a rule body combines (`⊗` *idempotent*, "an argument is its worst link", vs. *additive*, "accumulate over the body") and the polarity (`⊕ = max` *strength* vs. `⊕ = min` *cost*):

|                | strength (`⊕ = max`)     | cost (`⊕ = min`)               |
|----------------|--------------------------|--------------------------------|
| `⊗` idempotent | `godel` (max, min)       | `bottleneck_cost` (min, max)   |
| `⊗` additive   | `arctic` (max, +)        | `tropical` (min, +)            |

- **`godel`** — fuzzy confidence; an argument is as strong as its weakest premise (original WABA).
- **`tropical`** — additive cost; an argument's cost is the sum of its weighted proof leaves and the cheapest proof wins.
- **`arctic`** — accumulated support; the proof with the greatest total leaf support wins.
- **`bottleneck_cost`** — worst-case cost; an argument costs as much as its costliest weighted proof leaf.

Outside the 2×2 there is one further algebra, **`lukasiewicz`** (`a⊗b = max(0, a+b-k)`, `⊕ = max`, grid `{0..k}` via `#const k`): its conjunction is the Lukasiewicz t-norm, the only supported ⊗ that is neither `min`, `max`, nor `+`. Unlike Gödel's weakest-link, combining several proof leaves can *erode* certainty toward 0. A unary rule chain does not erode merely because it is long.

(`godel_low` and `tropical_high` are polarity-dual aliases of `bottleneck_cost` and `arctic`.)

The **monoid** aggregates the *discarded* attacks into the extension's cost, bounded by `beta`:

- **`sum`** (`ub`) — total spending cap.
- **`max`** (`ub`) — worst single concession: dismiss freely, but never an attack stronger than `beta`.
- **`min`** (`lb`) — weakness floor: every dismissed attack has cost/weakness at least `beta`.

On the raw lifted domain, `#inf` is absorbing for `sum`: if any discarded unit has that
price, the aggregate is `#inf`. This is stated explicitly because clingo's native `#sum`
would otherwise omit the sentinel tuple.

**`no_discard` recovers classical ABA exactly** — it forbids *every* discard, for any
weight. Prefer it (or `--aba-recovery`) to `ub` with `beta = 0`: a budget of 0 is a genuine
budget, and a propagated price equal to `0` or `#inf` is affordable under an upper bound at
zero. In the four unbounded algebras, the `aba` policy makes direct unweighted attacks
`#sup` (un-droppable). Łukasiewicz instead uses its carrier top `k` under both policies;
`#sup` is outside its carrier. No local default guarantees recovery when other discardable
attacks remain; use
`no_discard` for the unconditional classical profile. **Frameworks must be well formed:**
the supported entry points first accept only ground facts over `assumption/1`, `contrary/2`,
`head/2`, `body/2`, and `weight/2` (plus comments, non-reserved `#const` declarations, and
recursively checked `#include` files). The caller-authoritative `beta` and `k` constants remain
legal; declarations such as `#const max=min` are rejected because they would rewrite terms in
the selected modules. General ASP rules, constraints, solver directives, unknown fact
predicates, and authored runtime predicates are refused before composition. A second preflight checks
flatness, acyclicity, one head per rule identifier, no orphan body identifier, a total
functional `contrary/2` map, functional finite nonnegative authored weights, and the selected
numeric carrier. A derivation cycle
(`p ← q`, `q ← p`) has no well-defined
propagated weight, while missing or multiple contraries do not define an ABA framework;
either case is refused with the offending atom rather than passed to the bare semantic core.
**Weights as probabilities:** encode `w = round(-K ln p)` and run `tropical`; the propagated
weight is then the surprisal of an atom's most-probable proof (decode `p = exp(-w/K)`) — see
`examples/probabilistic/`. **This is exact only where no derivation reuses a leaf:** `⊗`
folds a derivation *tree*, so a leaf reached by two branches contributes `p²`, i.e. is treated
as independent of itself. `validate.lp` reports `advisory(leaf_reuse, X)` when that can
happen. For the narrower tropical fragment in which all priced leaves are assumptions and
derived atoms have no direct `weight/2` declaration, the optional `setsupport.lp` instead
searches for a proof DAG and charges each distinct assumption leaf once. That provenance-aware
calculation is no longer a semiring fold and does not cover arbitrary weighted facts or
directly weighted conclusions. The idempotent algebras (`godel`, `bottleneck_cost`) are
unaffected by repeated leaves, because `min`/`max` ignore multiplicity.

### Where weights live (leaves and derived atoms)

`weight/2` may be declared on **any** atom. On a **leaf** — an assumption, or a fact (an
empty-body rule head) — the declared weight is intrinsic and always effective, since there
is no derivation to compete with it. On a **derived** atom the declared weight is combined
with the atom's derivations by `⊕`, one more summand in the same fold: an independent
assessment of the conclusion, merged with what its premises provide. This is well defined
and legitimate; the paper's running example carries one deliberately (`wt(n) = 1 ⊕ 6`).

What deserves awareness is that **which side prevails is the algebra's call**, through a
comparison the modeller cannot see locally. On that example the three strength algebras
(`⊕ = max`) retain the declared 6, while tropical and bottleneck-cost (`⊕ = min`) retain the
derivation's 1. One declaration is decisive in three algebras and absorbed in two.

The degenerate special case is a derived atom whose supports are all **unweighted**: the
derivation then folds to the `⊗`-identity, which under `godel`/`bottleneck_cost`/`lukasiewicz`
is also `⊕`-dominant, so the declared weight silently never takes effect there. Arctic keeps
the declaration under `neutral`; tropical and bottleneck-cost keep it under `aba` but lose it
under `neutral`. If a declared weight must always survive verbatim, put it on a leaf.

There is **no advisory predicate for a dominated weight**: an earlier
`weight_on_derived_dominated/3` was removed when the guards were cut from the core
(`core/base.lp` is the mathematics alone; validation lives at the boundaries). Whether a
declaration took effect is visible by comparing `weight/2` with `supported_with_weight/2`.

The two policies coincide for Gödel (`#sup`) and Łukasiewicz (`k`). They differ for arctic,
tropical and bottleneck-cost. Under `neutral`, an unweighted assumption carries the
`⊗`-identity and is transparent. Under `aba` it carries `#sup`, the hard-price marker; in
those three algebras it is also the `⊗`-annihilator, so a mixed conjunction such as
`c_acc ← t_acc, objection` collapses to `#sup`. There is **no free lunch** — choose per model,
or route the objection through an intermediate (`objection ← t_acc`; `c_acc ← objection`) so
the conjunction never mixes a declared weight with the recovery default. Saved configurations
using the retired `legacy` name are mapped onto the corresponding reachable policy.

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
expose the same five concrete algebras and the `sum`/`max`/`min` monoids (with no `count`).

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
