# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Non-Negotiable Working Rules (MUST FOLLOW)

### 1) Minimal-change policy (default)
- **Make the smallest possible change** that satisfies the request.
- **Do not refactor** unless the user explicitly requests refactoring *or* a refactor is required to fix a correctness bug.
- Prefer **local edits** over broad edits:
  - edit the fewest files possible
  - change the fewest lines possible
  - avoid renaming symbols, predicates, files, or folders unless essential
- Preserve existing behavior unless the task explicitly changes it.
- If there are multiple viable solutions, pick the one with the **smallest diff**.

**Forbidden by default**
- Large-scale reformatting (whitespace churn, rewrapping, reordering blocks)
- “Cleanup” passes unrelated to the requested change
- Renaming files/folders for style
- Moving code across files “for organization”

### 2) Folder-structure hygiene (default)
- **Do not create new folders** unless the user explicitly requests it *or* there is no reasonable alternative.
- **Do not reorganize** existing folders (no moving files to “tidy up”).
- **Keep structure flat and predictable**: avoid deep nesting, avoid new top-level directories.
- When adding files is truly necessary:
  - place them in the **closest existing, semantically correct directory**
  - use consistent naming (no vague names like `tmp`, `misc`, `new`)
  - update this `CLAUDE.md` “File Organization” tree if it changes
  - ensure no duplicates / near-duplicates are created

### 3) Before you touch anything: confirm scope in your head
- What is the **single smallest edit** that meets the requirement?
- What is the **minimum set of files** needed?
- Can I solve it by editing an existing file rather than adding a new one?

### 4) After changes: keep repo tidy
- If you create something new, ensure it is actually used.
- Remove dead code / unused predicates *only if* you introduced them in this change.
- Avoid leaving commented-out experiments in core code paths; prefer a short comment explaining intent.

---

## Repository Overview

This repository hosts **Weighted Assumption Based Argumentation (WABA)**, a framework that extends ABA with weighted arguments and attack resolution based on budget constraints.

## Running WABA

### Prerequisites
- **clingo** version 5.8.0+ (tested with Python 3.10.17+)
- Basic understanding of Answer Set Programming (ASP)

### Basic Command Structure

WABA programs compose the core logic at runtime by loading modular components:

```bash
clingo -n 0 WABA/core_base.lp WABA/semiring/<semiring>.lp WABA/monoid/<monoid>.lp \
       WABA/filter.lp WABA/Semantics/<semantic>.lp <framework>.lp
```

**Required Components** (loaded in order):
1. `WABA/core_base.lp` - Base argumentation logic (semiring/monoid-independent)
2. `WABA/semiring/<semiring>.lp` - Weight propagation strategy (fuzzy, tropical, boolean)
3. `WABA/monoid/<monoid>.lp` - Cost aggregation strategy (max, sum, min)
4. `WABA/filter.lp` - Output filtering via #show directives (recommended)
5. `WABA/Semantics/<semantic>.lp` - Semantics (stable.lp, cf.lp, or naive.lp)
6. `<framework>.lp` - Your WABA framework instance

**Optional Components**:
- `WABA/minimize_cost.lp` - Add after filter.lp to find minimum-cost extensions

### Example: Original WABA (Fuzzy + Max)

```bash
clingo -n 0 WABA/core_base.lp WABA/semiring/fuzzy.lp WABA/monoid/max.lp \
       WABA/filter.lp WABA/Semantics/stable.lp WABA/Examples/medical.lp
```

### ⚠️ CRITICAL: Budget Parameter (beta)

**IMPORTANT**: WABA's budget mechanism is controlled by the `beta` parameter, which MUST be set properly:

1. **If your framework file contains `budget(N)`**: The budget is set to N automatically
   ```prolog
   % In your framework file:
   budget(100).  % Extensions can discard attacks up to cost 100
   ```

2. **If your framework file does NOT contain `budget(...)`**: You MUST set beta via command line
   ```bash
   clingo -c beta=100 WABA/core_base.lp WABA/semiring/fuzzy.lp WABA/monoid/max.lp ... your_framework.lp
   ```

3. **If you don't set beta AND your framework lacks `budget(...)`**:
   - The default `budget(beta)` in core_base.lp becomes an ungrounded constant
   - Budget constraint is effectively disabled (all attacks can be discarded)
   - Results will be **meaningless** (typically one extension with all assumptions)

**Recommended approach**: ALWAYS include `budget(N)` in your framework files, or use budget variants:
- `budget(0)` - Strictest: no attacks can be discarded
- `budget(max_weight)` - Can discard ~1 attack
- `budget(sum_of_weights/2)` - Can discard ~half the attacks
- `budget(sum_of_weights)` - Can discard all attacks

### Choosing Semiring and Monoid

WABA uses a **semiring** for weight propagation and a **monoid** for cost aggregation. Compose them at runtime by selecting one file from each directory.

**Available Semirings** (in `WABA/semiring/`):
- **fuzzy.lp** - Fuzzy/Gödel logic: minimum for conjunction, maximum for disjunction, identity=100 (original WABA)
- **tropical.lp** - Tropical semiring: addition for conjunction, minimum for disjunction, identity=#sup
- **boolean.lp** - Boolean logic: AND for conjunction, OR for disjunction, binary weights {0,1}

**Available Monoids** (in `WABA/monoid/`):
- **max.lp** - Maximum cost: extension_cost = max of discarded attack weights (original WABA)
- **sum.lp** - Sum cost: extension_cost = sum of all discarded attack weights
- **min.lp** - Minimum cost: extension_cost = min of discarded attack weights
- **count.lp** - Count cost: extension_cost = number of discarded attacks (weight-agnostic)
- **lex.lp** - Lexicographic cost: three components (max, sum, count) minimized in priority order

**Common Combinations**:

```bash
# Original WABA (fuzzy + max) - Stable semantics
clingo -n 0 WABA/core_base.lp WABA/semiring/fuzzy.lp WABA/monoid/max.lp \
       WABA/filter.lp WABA/Semantics/stable.lp WABA/Examples/medical.lp

# Tropical + max - Stable semantics
clingo -n 0 WABA/core_base.lp WABA/semiring/tropical.lp WABA/monoid/max.lp \
       WABA/filter.lp WABA/Semantics/stable.lp WABA/Examples/medical.lp

# Fuzzy + sum - Stable semantics
clingo -n 0 WABA/core_base.lp WABA/semiring/fuzzy.lp WABA/monoid/sum.lp \
       WABA/filter.lp WABA/Semantics/stable.lp WABA/Examples/medical.lp


# Boolean + max - Naive semantics (requires special flags)
clingo -n 0 --heuristic=Domain --enum=domRec \
       WABA/core_base.lp WABA/semiring/boolean.lp WABA/monoid/max.lp \
       WABA/filter.lp WABA/Semantics/naive.lp WABA/Examples/medical.lp
```

### Available Semantics

Located in `WABA/Semantics/`:
- **stable.lp** - Stable semantics (conflict-free + all non-defeated assumptions must be out)
- **cf.lp** - Conflict-free semantics only
- **naive.lp** - Naive semantics (requires special heuristics: `--heuristic=Domain --enum=domRec`)

**Example with naive semantics**:
```bash
clingo -n 0 --heuristic=Domain --enum=domRec \
       WABA/core_base.lp WABA/semiring/fuzzy.lp WABA/monoid/max.lp \
       WABA/filter.lp WABA/Semantics/naive.lp <framework>.lp
```

### Cost Optimization

To find optimal extensions, add an optimization file after filter.lp:

**Standard Minimization** (for max, sum, count monoids):
```bash
clingo -n 0 WABA/core_base.lp WABA/semiring/fuzzy.lp WABA/monoid/max.lp \
       WABA/filter.lp WABA/minimize_cost.lp WABA/Semantics/stable.lp <framework>.lp
```

**Maximization** (for min monoid - quality threshold semantics):
```bash
clingo -n 0 WABA/core_base.lp WABA/semiring/tropical.lp WABA/monoid/min.lp \
       WABA/filter.lp WABA/maximize_cost.lp WABA/Semantics/stable.lp <framework>.lp
```

**Lexicographic Optimization** (for lex monoid - use filter_lex.lp to see all components):
```bash
clingo -n 0 WABA/core_base.lp WABA/semiring/fuzzy.lp WABA/monoid/lex.lp \
       WABA/filter_lex.lp WABA/optimize_lex.lp WABA/Semantics/stable.lp <framework>.lp
```

## WABA Framework Structure

WABA frameworks define assumptions, rules, weights, and contrary relations using Answer Set Programming syntax.

### Core Predicates

**Weights** (partial function from atoms to positive integer costs):

```prolog
weight(atom, 50).  % Positive integer weight
```

**Assumptions** (defeasible atoms):

```prolog
assumption(a1).
```

**Rules** (inference):

```prolog
head(r1, conclusion). % r1: conclusion <- premise1, premise2.
body(r1, premise1).
body(r1, premise2).
```

or, in *compact form*:

```prolog
head(r1, conclusion; r1, premise1; r1, premise2). % r1: conclusion <- premise1, premise2.
```

IMPORTANT NOTE: Prefer the *compact* form. Always comment rules with their more legible counterpart, e.g., `r1: conclusion <- premise1, premise2.` as in the example above.

**Contraries** (attack relation):

```prolog
contrary(attacked_assumption, element).
```

INTERPRETATION:  "`element` attacks `attacked_assumption`" (NOT the other way round).
IMPORTANT NOTE: `contrary` is a mandatorily *total* function from the set of assumptions to the set of atoms.

### Key Mechanisms

**Budget Constraint**: Extensions must not exceed the budget when resolving attacks
```prolog
budget(beta).  % Default in core files
```

**Attack Resolution**: Attacks can be discarded at cost equal to attack weight. The extension cost is computed by the chosen monoid.

**Weight Propagation** (Semiring-dependent): Elements inherit weights from supporting rules according to the semiring:
- **Tropical semiring**: minimum of body element weights (original WABA)
- **Fuzzy semiring**: minimum for conjunction
- **Probabilistic semiring**: average of body element weights (simplified)
- **Boolean semiring**: all body elements must be 1

**Cost Aggregation** (Monoid-dependent): Extension cost computed from discarded attacks:
- **Max monoid**: maximum discarded attack weight (original WABA)
- **Sum monoid**: sum of all discarded attack weights
- **Min monoid**: minimum discarded attack weight

## File Organization

```
WABA/
├── core_base.lp                 # Semiring/monoid-independent base logic
├── filter.lp                    # Standard output filtering
├── filter_project.lp            # Projection mode filtering (for stable semantics)
├── filter_lex.lp                # Lexicographic monoid filtering (shows all 3 components)
├── minimize_cost.lp             # Minimize extension_cost (for max/sum/count monoids)
├── maximize_cost.lp             # Maximize extension_cost (for min monoid)
├── optimize_lex.lp              # Lexicographic optimization (for lex monoid)
├── semiring/                    # Weight propagation modules
│   ├── fuzzy.lp                 # Fuzzy/Gödel logic (min/max, identity=100) - original WABA
│   ├── tropical.lp              # Tropical semiring (min/+, identity=#sup)
│   └── boolean.lp               # Boolean logic (and/or, binary weights)
├── monoid/                      # Cost aggregation modules
│   ├── max.lp                   # Maximum cost - original WABA
│   ├── sum.lp                   # Sum of costs
│   ├── min.lp                   # Minimum cost (quality threshold semantics)
│   ├── count.lp                 # Count of discarded attacks (weight-agnostic)
│   └── lex.lp                   # Lexicographic (max→sum→count priority)
├── Semantics/
│   ├── stable.lp                # Stable semantics
│   ├── cf.lp                    # Conflict-free semantics
│   └── naive.lp                 # Naive semantics
└── Examples/
    ├── medical.lp               # Medical ethics decision example
    ├── simple.lp                # Simple test case
    ├── simple2.lp               # Another simple case
    └── simple_medical.lp
```

## Understanding Core Logic

WABA's core logic is now modular, split across three components:

### 1. Base Logic (core_base.lp)

Semiring/monoid-independent logic that all variants share:

**Assumption Selection**: Each assumption is either in or out (choice via default negation)
```prolog
in(X) :- assumption(X), not out(X).
out(X) :- assumption(X), not in(X).
```

**Support**: Elements are supported if they're selected assumptions or derivable via triggered rules
```prolog
supported(X) :- assumption(X), in(X).
supported(X) :- head(R,X), triggered_by_in(R).
triggered_by_in(R) :- head(R,_), supported(X) : body(R,X).
```

**Attacks**: Supported elements attack contrary assumptions with their weight
```prolog
attacks_with_weight(X,Y,W) :- supported(X), supported_with_weight(X,W),
    assumption(Y), contrary(Y,X).
```

**Attack Discarding**: Choose which attacks to discard (requires budget)
```prolog
{ discarded_attack(X,Y,W) : attacks_with_weight(X,Y,W) }.
attacks_successfully_with_weight(X,Y,W) :- attacks_with_weight(X,Y,W),
    not discarded_attack(X,Y,W).
defeated(X) :- attacks_successfully_with_weight(_,X,_).
```

**Budget Enforcement**: Extension cost cannot exceed budget
```prolog
:- extension_cost(C), C > B, budget(B).
```

### 2. Semiring Modules (semiring/*.lp)

Define `supported_with_weight/2` for weight propagation.

**Tropical semiring** (tropical.lp) - Original WABA:
```prolog
supported_with_weight(X,#sup) :- assumption(X), in(X).  % Identity: infinity
supported_with_weight(X,W) :- supported(X), weight(X,W).
supported_with_weight(X,W) :- supported(X), head(R,X),
    W = #min{ V, B : body(R,B), supported_with_weight(B,V) }.  % Conjunction: min
```

**Fuzzy semiring** (fuzzy.lp):
```prolog
supported_with_weight(X,100) :- assumption(X), in(X).  % Identity: 100
supported_with_weight(X,W) :- supported(X), weight(X,W).
supported_with_weight(X,W) :- supported(X), head(R,X),
    W = #min{ V, B : body(R,B), supported_with_weight(B,V) }.  % Conjunction: min
```

### 3. Monoid Modules (monoid/*.lp)

Define `extension_cost/1` for cost aggregation.

**Max monoid** (max.lp) - Original WABA:
```prolog
extension_cost(C) :- C = #max{ W, X, Y : discarded_attack(X,Y,W) }.
```

**Sum monoid** (sum.lp):
```prolog
extension_cost(C) :- C = #sum{ W, X, Y : discarded_attack(X,Y,W) }.
extension_cost(0) :- not discarded_attack(_,_,_).
```

## Clingo ASP Guidelines

When editing `.lp` files, follow Answer Set Programming conventions. Key reference points from `docs/external_tools/clingo_quickref.md`:

- **Rules end with `.`** and comments start with `%`
- **Variables** start with uppercase letters (e.g., `Variable`) and constants start with lowercase letters (e.g., `constant`)
- **Body conjunction**: Use `,` (semicolon `;` also works but prefer comma)
- **Conditional literals**: Use `:` to separate conditions (e.g., `p(X) : q(X)`)
- **Choice rules**: `{ atom : domain }` for non-deterministic selection
- **Safety**: Every variable must appear in a positive body literal
- **Aggregates**: `#sum`, `#count`, `#min`, `#max` with syntax `#agg{ Weight,Terms : Condition }`
- **Constraints**: Rules with empty head `:- body.` reject answer sets where body holds
- **Disjunctive heads**: Use `;` in heads for "at least one must hold"
- **Special constants**: `#sup` for "superior" (similar to "infinity"); `#inf` for "inferior" (similar to "-infinity").

## Testing Changes

After modifying WABA files, test with:

1. Simple examples first (using original behavior - fuzzy + max):
```bash
clingo -n 0 WABA/core_base.lp WABA/semiring/fuzzy.lp WABA/monoid/max.lp \
       WABA/filter.lp WABA/Semantics/stable.lp WABA/Examples/simple.lp
```

2. Complex examples to verify behavior:
```bash
clingo -n 0 WABA/core_base.lp WABA/semiring/fuzzy.lp WABA/monoid/max.lp \
       WABA/filter.lp WABA/Semantics/stable.lp WABA/Examples/medical.lp
```

3. Verify output includes expected predicates:
   - `in/1` - Selected assumptions
   - `supported_with_weight/2` - Supported elements and their weights
   - `attacks_successfully_with_weight/3` - Successful attacks
   - `extension_cost/1` - Cost of the extension

6. Check for errors:
   - Syntax errors from clingo
   - Unsatisfiable (no answer sets when expected)
   - Safety violations (variables not properly grounded)

## Creating New Semiring/Monoid Modules

To add a new semiring or monoid:

**New Semiring** (weight propagation strategy):
1. Create `WABA/semiring/<name>.lp`
2. Define `supported_with_weight(X, W)` predicate
3. Document the conjunction/disjunction operators and identity value
4. Test with existing monoids and all semantics

**New Monoid** (cost aggregation strategy):
1. Create `WABA/monoid/<name>.lp`
2. Define `extension_cost(C)` predicate
3. Document the aggregation function and identity value (usually 0)
4. Test with existing semirings and all semantics

**Testing a new combination**:
```bash
# Test your new combination
clingo -n 0 WABA/core_base.lp WABA/semiring/<new_semiring>.lp WABA/monoid/<new_monoid>.lp \
       WABA/filter.lp WABA/Semantics/stable.lp WABA/Examples/medical.lp
```
