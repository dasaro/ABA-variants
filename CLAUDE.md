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

### 5) Documentation management (CRITICAL)
- **Do not overwhelm the repo with documentation files**. Keep docs minimal, purposeful, and consolidated.
- **Prefer updating existing files** over creating new ones. Add sections to existing docs when relevant.
- **Single source of truth**: Main documentation (like README.md) should be comprehensive; avoid fragmenting info across many files.
- **Remove redundant/obsolete files**: When information becomes outdated or is superseded, remove the file and merge essential content into main docs.
- **Periodic refactoring**: When you notice documentation sprawl, consolidate related files and remove duplicates.

**When to create a new documentation file**:
- Template files (e.g., FINAL_REPORT_TEMPLATE.md) that serve as generation inputs
- Auto-generated reports (e.g., FINAL_BENCHMARK_REPORT.md) that are programmatically created
- Specialized technical documentation that would bloat main README (e.g., verification reports for specific components)
- Subdirectory READMEs when the subdirectory is large/complex (e.g., plots/README.md, test/README.md)

**When to consolidate/remove**:
- Historical reports superseded by newer versions → Remove old, keep latest
- Issue-specific documentation after issue is resolved → Merge key findings into main docs, remove file
- Verification reports after verification is complete → Keep concise summary, remove verbose details
- Multiple files covering similar topics → Consolidate into one comprehensive file
- Preliminary/draft documents after final version exists → Remove drafts

**Documentation best practices**:
- Keep each file focused and purposeful
- Use clear section headers for easy navigation
- Include "Last Updated" dates for time-sensitive content
- Cross-reference related docs (don't duplicate content)
- Prefer tables and bullet points over prose for technical specs
- Keep verification/test reports concise (key findings only, not verbose logs)

### 6) Handling ambiguous or high-risk requests (MUST USE PLAN MODE)
- **Always use plan mode** (EnterPlanMode tool) when:
  - The user's prompt is **underspecified** or ambiguous (multiple valid interpretations exist)
  - The request may **significantly disrupt** the current implementation status
  - Major architectural decisions are needed
  - Multiple files will be affected and the approach isn't obvious
  - You need to ask follow-up questions to clarify requirements
  - The change could break existing functionality

- **Use plan mode to**:
  - Ask clarifying questions about underspecified requirements
  - Present multiple implementation approaches for user selection
  - Explore the codebase to understand impact before making changes
  - Get user sign-off on the approach before implementation
  - Document assumptions and design decisions

- **Examples of when to use plan mode**:
  - "Add authentication" → Which method? Where? What should happen on failure?
  - "Refactor the core logic" → What specifically needs refactoring? What's the target design?
  - "Fix the performance issue" → Which issue? What's causing it? What's the acceptable solution?
  - "Implement feature X" → When multiple valid approaches exist or requirements unclear

- **Do NOT guess or assume** - If underspecified, use plan mode to clarify first

### 7) Git Workflow (MUST FOLLOW)

**WABA/ repository (main codebase):**
- **ALWAYS commit to local git** after every change you make
- Use clear, descriptive commit messages
- **NEVER push to public repository** unless explicitly instructed by the user
- Local commits allow rollback and tracking of changes
- Example workflow:
  ```bash
  # After editing files
  git add <changed-files>
  git commit -m "Clear description of change"
  # Do NOT push unless user says to
  ```

**waba-playground/ repository (web application):**
- **ALWAYS commit AND push to GitHub Pages** after every change
- **CRITICAL**: GitHub Pages deploys from `waba-weak-constraints` branch, NOT `main`
- Changes must be immediately deployed to live site
- Use descriptive commit messages
- Example workflow:
  ```bash
  # IMPORTANT: Work on waba-weak-constraints branch
  cd waba-playground
  git checkout waba-weak-constraints

  # After editing files
  git add <changed-files>
  git commit -m "Description of change"
  git push origin waba-weak-constraints  # ALWAYS push to waba-weak-constraints
  ```

**Summary:**
- WABA/: Commit locally, push only on user request
- waba-playground/: Commit and push to `waba-weak-constraints` branch immediately every time

---

## Repository Overview

This repository hosts **Weighted Assumption Based Argumentation (WABA)**, a framework that extends ABA with weighted arguments and attack resolution based on budget constraints.

## Web Implementation Location (CRITICAL)

**IMPORTANT**: The ONLY web-based WABA implementation in this repository is located at:
```
waba-playground/
```

This directory contains the complete browser-based WABA Playground application:
- **index.html** - Main application HTML structure
- **app.js** - Complete application logic (Clingo WASM integration, **vis.js** graph visualization, WABA framework execution)
- **style.css** - Dark/light theme styling
- **examples.js** - Example WABA frameworks
- **Clingo WASM files** - Browser-compatible Clingo solver

**Graph Visualization Library**:
- **Current**: **vis.js** (Barnes-Hut physics, continuous simulation, native live updates)
- **Migration Date**: 2025-12-26
- **Backup**: Previous Cytoscape.js implementation backed up in `waba-playground/backup-cytoscape/`

**Deployment Branch** (CRITICAL):
- **GitHub Pages deploys from**: `waba-weak-constraints` branch
- **DO NOT make changes to `main` branch** for waba-playground - they will NOT be deployed
- **ALWAYS work on and push to**: `waba-weak-constraints` branch
- To verify deployment source: `gh api repos/dasaro/waba-playground/pages | grep branch`

**DO NOT**:
- Create alternative web implementations in other directories (e.g., WABA/web/)
- Overwrite files in waba-playground/ without explicit user confirmation
- Assume the user wants a new web implementation when they mention web visualization
- Switch graph visualization libraries without explicit request and creating backups first
- Push changes to `main` branch expecting them to deploy (use `waba-weak-constraints` instead)

**When working with web visualization**:
1. Always check if waba-playground/ already contains the needed functionality
2. Ask for clarification if the user's request could be interpreted as modifying existing web code
3. If creating test/prototype visualizations, clearly mark them as temporary and in a separate location
4. **ALWAYS checkout `waba-weak-constraints` branch before making changes**

## Running WABA

### Prerequisites
- **clingo** version 5.8.0+ (tested with Python 3.10.17+)
- Basic understanding of Answer Set Programming (ASP)

### Basic Command Structure

WABA programs compose the core logic at runtime by loading modular components:

```bash
clingo -n 0 WABA/core/base.lp WABA/semiring/<semiring>.lp WABA/monoid/<monoid>.lp \
       WABA/filter/standard.lp WABA/semantics/<semantic>.lp <framework>.lp
```

**Required Components** (loaded in order):
1. `WABA/core/base.lp` - Base argumentation logic (semiring/monoid-independent)
2. `WABA/semiring/<semiring>.lp` - Weight propagation strategy (godel, tropical, lukasiewicz)
3. `WABA/monoid/<monoid>.lp` - Cost aggregation strategy (max, sum, min)
4. `WABA/filter/standard.lp` - Output filtering via #show directives (recommended)
5. `WABA/semantics/<semantic>.lp` - Semantics (stable.lp, cf.lp, or naive.lp)
6. `<framework>.lp` - Your WABA framework instance

**Optional Components**:
- `WABA/optimize/minimize.lp` - Add after filter/standard.lp to find minimum-cost extensions

### Example: Original WABA (Fuzzy + Max)

```bash
clingo -n 0 WABA/core/base.lp WABA/semiring/godel.lp WABA/monoid/max.lp \
       WABA/filter/standard.lp WABA/semantics/stable.lp WABA/examples/medical.lp
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
   clingo -c beta=100 WABA/core/base.lp WABA/semiring/godel.lp WABA/monoid/max.lp ... your_framework.lp
   ```

3. **If you don't set beta AND your framework lacks `budget(...)`**:
   - The default `budget(beta)` in core/base.lp becomes an ungrounded constant
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
- **godel.lp** - Gödel/Fuzzy logic: minimum for conjunction, maximum for disjunction, identity=#sup (original WABA)
- **tropical.lp** - Tropical semiring: addition for conjunction, minimum for disjunction, identity=#sup
- **lukasiewicz.lp** - Łukasiewicz logic: bounded sum for conjunction/disjunction, parametrizable K (default=100)
- **arctic.lp** - Arctic semiring: addition for conjunction, maximum for disjunction, identity=0 (dual of Tropical)
- **bottleneck_cost.lp** - Bottleneck-cost semiring: maximum for conjunction, minimum for disjunction, worst-case optimization

**Available Monoids** (in `WABA/monoid/`):





**Optimized variants** (direct `#minimize`/`#maximize`, 1000x faster):
- **sum_minimization.lp** / **sum_maximization.lp** - Sum minimization/maximization (works in both modes)
- **max_minimization.lp** / **max_maximization.lp** - Max minimization/maximization (works in both modes)
- **min_minimization.lp** / **min_maximization.lp** - Min minimization/maximization (works in both modes)
- **count_minimization.lp** / **count_maximization.lp** - Count minimization/maximization (works in both modes)

**Naming convention:** `{monoid}_{direction}.lp` where:
- `_minimization` = minimize (cost semantics: weights = costs to avoid)
- `_maximization` = maximize (reward semantics: weights = rewards to pursue)

**Common Combinations**:

```bash
# Original WABA (fuzzy + max) - Stable semantics (minimize cost)
clingo -n 0 WABA/core/base.lp WABA/semiring/godel.lp WABA/monoid/max_minimization.lp \
       WABA/filter/standard.lp WABA/semantics/stable.lp WABA/examples/medical.lp

# Tropical + max - Stable semantics (minimize cost)
clingo -n 0 WABA/core/base.lp WABA/semiring/tropical.lp WABA/monoid/max_minimization.lp \
       WABA/filter/standard.lp WABA/semantics/stable.lp WABA/examples/medical.lp

# Gödel + sum - Stable semantics (minimize cost)
clingo -n 0 WABA/core/base.lp WABA/semiring/godel.lp WABA/monoid/sum_minimization.lp \
       WABA/filter/standard.lp WABA/semantics/stable.lp WABA/examples/medical.lp

# Łukasiewicz + max - Stable semantics (minimize cost)
clingo -n 0 WABA/core/base.lp WABA/semiring/lukasiewicz.lp WABA/monoid/max_minimization.lp \
       WABA/filter/standard.lp WABA/semantics/stable.lp WABA/examples/medical.lp

# Arctic + max - Stable semantics (reward maximization)
clingo -n 0 WABA/core/base.lp WABA/semiring/arctic.lp WABA/monoid/max_maximization.lp \
       WABA/filter/standard.lp WABA/semantics/stable.lp WABA/examples/medical.lp

# Bottleneck-cost + min - Stable semantics (worst-case optimization)
clingo -n 0 WABA/core/base.lp WABA/semiring/bottleneck_cost.lp WABA/monoid/min_minimization.lp \
       WABA/filter/standard.lp WABA/semantics/stable.lp WABA/examples/medical.lp

# Tropical + sum - Minimize total cost (1000x faster with --opt-mode=opt)
clingo -n 0 --opt-mode=opt WABA/core/base.lp WABA/semiring/tropical.lp \
       WABA/monoid/sum_minimization.lp WABA/filter/standard.lp \
       WABA/semantics/stable.lp WABA/examples/medical.lp

# Tropical + sum - Maximize total reward (1000x faster with --opt-mode=opt)
clingo -n 0 --opt-mode=opt WABA/core/base.lp WABA/semiring/tropical.lp \
       WABA/monoid/sum_maximization.lp WABA/filter/standard.lp \
       WABA/semantics/stable.lp WABA/examples/medical.lp

# Enumeration mode (works without --opt-mode flag!)
clingo -n 10 WABA/core/base.lp WABA/semiring/tropical.lp \
       WABA/monoid/sum_minimization.lp WABA/filter/standard.lp \
       WABA/semantics/stable.lp WABA/examples/medical.lp
```

### Available Semantics

**Core semantics** (in `WABA/semantics/`):
- **stable.lp** - Stable semantics (conflict-free + all non-defeated assumptions must be out)
- **cf.lp** - Conflict-free semantics only
- **admissible.lp** - Admissible semantics
- **complete.lp** - Complete semantics
- **grounded.lp** - Grounded semantics (unique minimal complete extension)

**Heuristic-based semantics** (in `WABA/semantics/heuristic/`, **PRODUCTION-READY**):
- **preferred.lp** - Maximal complete extensions (requires `--heuristic=Domain --enum-mode=domRec`)
- **semi-stable.lp** - Admissible with maximal range (requires `--heuristic=Domain --enum-mode=domRec`)
- **staged.lp** - Conflict-free with maximal range (requires `--heuristic=Domain --enum-mode=domRec`)
- **naive.lp** - Maximal conflict-free extensions (requires `--heuristic=Domain --enum-mode=domRec`)

**Optimization-based semantics** (in `WABA/semantics/optN/`, **RECOMMENDED**):
- **preferred.lp** - Maximal complete extensions via optimization
- **semi-stable.lp** - Admissible with maximal range via optimization
- **staged.lp** - Conflict-free with maximal range via optimization
- **ideal.lp** - Maximal admissible in ∩Pref (requires two-step workflow)

**Required flags for optN semantics**:
```bash
# Use: 0 --opt-mode=optN --quiet=1 --project
# - 0 (or -n 0): enumerate all models
# - --opt-mode=optN: compute optimum, then enumerate all optimal models
# - --quiet=1: suppress non-optimal models (print only optimal)
# - --project: avoid duplicates by projecting on shown atoms
```

**Saturation-based semantics** (in `WABA/semantics/saturation-based/`, **EXPERIMENTAL**):
- **preferred.lp** - ⚠️ Experimental (may return extra models)
- **semi-stable.lp** - ⚠️ Experimental (may return extra models)
- **staged.lp** - ⚠️ Experimental (may return extra models)
- **naive.lp** - ⚠️ Experimental (saturation approach)
- **ideal.lp** - ⚠️ Experimental (complex but functional two-phase saturation, 161 lines)

**Production use**: Prefer optN-based semantics for preferred/semi-stable/staged. Use heuristic-based for naive. Saturation versions are research/experimental only.

**Example with optN semantics**:
```bash
# Semi-stable (admissible + maximal range)
clingo 0 --opt-mode=optN --quiet=1 --project \
       WABA/core/base.lp WABA/semiring/godel.lp WABA/constraint/ub_max.lp \
       WABA/semantics/admissible.lp WABA/semantics/optN/semi-stable.lp \
       <framework>.lp -c beta=0
```

**Example with heuristic semantics**:
```bash
clingo -n 0 --heuristic=Domain --enum-mode=domRec \
       WABA/core/base.lp WABA/semiring/godel.lp WABA/constraint/ub_max.lp \
       WABA/filter/standard.lp WABA/semantics/heuristic/preferred.lp <framework>.lp
```

### Cost Optimization

**Recommended:** Use optimized monoids with `--opt-mode=opt` for 1000x faster optimization:

**Minimization** (cost semantics):
```bash
clingo -n 0 --opt-mode=opt WABA/core/base.lp WABA/semiring/godel.lp \
       WABA/monoid/max_minimization.lp WABA/filter/standard.lp \
       WABA/semantics/stable.lp <framework>.lp
```

**Maximization** (reward semantics):
```bash
clingo -n 0 --opt-mode=opt WABA/core/base.lp WABA/semiring/tropical.lp \
       WABA/monoid/sum_maximization.lp WABA/filter/standard.lp \
       WABA/semantics/stable.lp <framework>.lp
```

**Note:** The optimized monoids (`*_minimization.lp` / `*_maximization.lp`) work in both enumeration and optimization modes.

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
- **Gödel semiring**: minimum for conjunction, maximum for disjunction (original WABA)
- **Tropical semiring**: addition for conjunction, minimum for disjunction
- **Łukasiewicz semiring**: bounded sum for conjunction (max(0, sum(w_i) - (n-1)*K)) and disjunction (min(K, sum))
- **Arctic semiring**: addition for conjunction, maximum for disjunction (dual of Tropical)
- **Bottleneck-cost semiring**: maximum for conjunction, minimum for disjunction (worst-case path)

**Cost Aggregation** (Monoid-dependent): Extension cost computed from discarded attacks:
- **Max monoid**: maximum discarded attack weight (original WABA)
- **Sum monoid**: sum of all discarded attack weights
- **Min monoid**: minimum discarded attack weight

## File Organization

```
WABA/
├── README.md                    # Quick start guide
├── CLAUDE.md                    # Instructions for Claude Code
├── core/                        # Core argumentation logic
│   └── base.lp                  # Modular semiring/monoid-independent core
├── filter/                      # Output filtering modules
│   ├── standard.lp              # Standard output filtering
│   └── projection.lp            # Projection mode filtering (for stable semantics)
├── semiring/                    # Weight propagation modules
│   ├── godel.lp                 # Gödel/Fuzzy logic (min/max, identity=#sup) - original WABA
│   ├── tropical.lp              # Tropical semiring (+/min, identity=#sup)
│   ├── lukasiewicz.lp           # Łukasiewicz t-norm (bounded sum, parametrizable K)
│   ├── arctic.lp                # Arctic semiring (+/max, identity=0, dual of Tropical)
│   └── bottleneck_cost.lp       # Bottleneck-cost semiring (max/min, worst-case optimization)
├── monoid/                      # Cost aggregation (OPTIMIZED)
│   ├── sum_minimization.lp      # Minimize sum cost - 1000x faster
│   ├── sum_maximization.lp      # Maximize sum reward - 1000x faster
│   ├── max_minimization.lp      # Minimize max cost - 1000x faster
│   ├── max_maximization.lp      # Maximize max reward - 1000x faster
│   ├── min_minimization.lp      # Minimize min cost - 1000x faster
│   ├── min_maximization.lp      # Maximize min reward - 1000x faster
│   ├── count_minimization.lp    # Minimize attack count - 1000x faster
│   ├── count_maximization.lp    # Maximize attack count - 1000x faster
│   ├── lex_minimization.lp      # Lexicographic minimization (max→sum→count)
│   └── lex_maximization.lp      # Lexicographic maximization (max→sum→count)
├── semantics/                   # Argumentation semantics
│   ├── stable.lp                # Stable semantics
│   ├── cf.lp                    # Conflict-free semantics
│   ├── admissible.lp            # Admissible semantics
│   ├── complete.lp              # Complete semantics
│   ├── grounded.lp              # Grounded semantics (fixpoint-based)
│   ├── optN/                    # ✅ RECOMMENDED: Optimization-based (optN mode)
│   │   ├── preferred.lp         # Maximal complete (--opt-mode=optN)
│   │   ├── semi-stable.lp       # Admissible + maximal range (--opt-mode=optN)
│   │   ├── staged.lp            # Conflict-free + maximal range (--opt-mode=optN)
│   │   └── ideal.lp             # Max admissible in ∩Pref (two-step workflow)
│   ├── heuristic/               # Production-ready heuristic implementations
│   │   ├── preferred.lp         # Maximal complete extensions
│   │   ├── semi-stable.lp       # Admissible + maximal range
│   │   ├── staged.lp            # Conflict-free + maximal range
│   │   └── naive.lp             # Maximal conflict-free extensions
│   └── saturation-based/        # ⚠️ EXPERIMENTAL saturation implementations
│       ├── preferred.lp         # Subset-maximality (experimental)
│       ├── semi-stable.lp       # Range-maximality, admissible (experimental)
│       ├── staged.lp            # Range-maximality, conflict-free (experimental)
│       ├── naive.lp             # Subset-maximality (experimental)
│       └── ideal.lp             # Two-phase saturation (experimental, 161 lines)
├── examples/                    # Example frameworks
│   ├── medical.lp               # Medical ethics decision example
│   ├── simple.lp                # Simple test case
│   ├── simple2.lp               # Another simple case
│   ├── simple_medical.lp        # Simplified medical example
│   └── showcase.lp              # Demonstrates semiring/monoid differences
├── test/                        # Test files
│   ├── test_lukasiewicz.lp      # Łukasiewicz semiring smoke test
│   └── test_bottleneck.lp       # Bottleneck-cost semiring smoke test
└── docs/                        # Documentation
    ├── QUICK_REFERENCE.md       # Command quick reference
    ├── clingo_v5_8_0_cheatsheet.md  # Clingo ASP syntax cheat sheet ⭐
    ├── SEMIRING_MONOID_COMPATIBILITY.md  # Legal combinations
    ├── FRAMEWORK_BEST_PRACTICES.md  # Framework creation and validation best practices
    └── CLINGO_USAGE.md          # Testing patterns and clingo commands

WABA_Legacy/                     # Historical reference - Pre-December 2025 aggregate-based implementation
├── README.md                    # Legacy implementation documentation and migration guide
├── core/legacy.lp               # Original monolithic core (aggregate-based)
├── monoid/                      # Old aggregate-based monoids (1000x slower)
│   ├── max.lp, sum.lp, min.lp, count.lp
├── semiring/                    # Same semirings (Gödel, Tropical, Łukasiewicz)
├── filter/standard.lp           # Output filtering
├── semantics/                   # Same semantics (stable, cf)
└── examples/medical.lp          # Example framework

waba-playground/                 # ⚠️ CRITICAL: Web-based WABA implementation (DO NOT DUPLICATE)
├── index.html                   # Main application structure
├── app.js                       # Complete application logic (Clingo WASM + vis.js)
├── style.css                    # Dark theme styling
├── examples.js                  # Example WABA frameworks
├── clingo.wasm                  # Clingo WebAssembly binary
├── clingo.web.js                # Clingo WASM loader
├── clingo.web.worker.js         # Clingo Web Worker
└── README.md                    # Web implementation documentation
```

## Historical Implementation (WABA_Legacy/)

The original aggregate-based implementation (pre-December 2025) has been moved to `WABA_Legacy/` for historical reference.

**Legacy vs Current**:
- **Legacy**: Aggregate-based `extension_cost/1`, monolithic core, 1000x slower optimization
- **Current**: Weak constraint-based, modular core, 53-54% fewer timeouts

**When to use WABA_Legacy/**:
- Backward compatibility with existing workflows
- Performance comparison benchmarking
- Historical research reference

**For production use**: Always use the current WABA/ implementation.

See `WABA_Legacy/README.md` for detailed migration guide and performance comparison.

## Understanding Core Logic

WABA's core logic is now modular, split across three components:

### 1. Base Logic (core/base.lp)

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

**Budget Enforcement**: Use monoid-specific constraint files (see constraint/ directory)
```prolog
%% Example: constraint/ub_max.lp
:- C = #max{ W : discarded_attack(_,_,W) }, C > B, budget(B), B != #sup, C != #inf.
```

### 2. Semiring Modules (semiring/*.lp)

Define `supported_with_weight/2` for weight propagation.

**Gödel semiring** (godel.lp) - Original WABA:
```prolog
supported_with_weight(X,#sup) :- assumption(X), in(X).  % Identity: #sup
supported_with_weight(X,W) :- supported(X), weight(X,W).
supported_with_weight(X,W) :- supported(X), head(R,X),
    W = #min{ V, B : body(R,B), supported_with_weight(B,V) }.  % Conjunction: min
```

**Tropical semiring** (tropical.lp):
```prolog
supported_with_weight(X,#sup) :- assumption(X), in(X).  % Identity: #sup
supported_with_weight(X,W) :- supported(X), weight(X,W).
rule_derivation_weight(R,X,W) :- head(R,X), supported(X), body(R,_),
    W = #sum{ V,B : body(R,B), supported_with_weight(B,V) }.  % Conjunction: + (sum)
supported_with_weight(X,W) :- supported(X), head(_,X),
    W = #min{ V : rule_derivation_weight(_,X,V) }.  % Disjunction: min
```

### 3. Monoid Modules (monoid/*.lp)

Use weak constraints directly for cost aggregation (no `extension_cost/1` predicate).

**Max minimization** (max_minimization.lp):
```prolog
%% Minimize the maximum discarded attack weight
:~ M = #max { W : discarded_attack(_,_,W) }, M != #sup, M != #inf. [M@0]
:~ M = #max { W : discarded_attack(_,_,W) }, M = #inf. [1@1]
:~ M = #max { W : discarded_attack(_,_,W) }, M = #sup. [1@2]
```

**Sum minimization** (sum_minimization.lp):
```prolog
%% Minimize the sum of discarded attack weights
:~ M = #sum { W : discarded_attack(_,_,W) }, M != #sup, M != #inf. [M@0]
:~ M = #sum { W : discarded_attack(_,_,W) }, M = #inf. [1@1]
:~ M = #sum { W : discarded_attack(_,_,W) }, M = #sup. [1@2]
```

## Clingo ASP Guidelines

**IMPORTANT**: When editing `.lp` files, **ALWAYS consult** the comprehensive **[Clingo v5.8.0 Cheat Sheet](docs/clingo_v5_8_0_cheatsheet.md)** ⭐ for proper ASP syntax.

**Quick reference** (see cheat sheet for complete details):

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
clingo -n 0 WABA/core/base.lp WABA/semiring/godel.lp WABA/monoid/max.lp \
       WABA/filter/standard.lp WABA/semantics/stable.lp WABA/examples/simple.lp
```

2. Complex examples to verify behavior:
```bash
clingo -n 0 WABA/core/base.lp WABA/semiring/godel.lp WABA/monoid/max.lp \
       WABA/filter/standard.lp WABA/semantics/stable.lp WABA/examples/medical.lp
```

3. Verify output includes expected predicates:
   - `in/1` - Selected assumptions
   - `supported_with_weight/2` - Supported elements and their weights
   - `attacks_successfully_with_weight/3` - Successful attacks
   - `Optimization: N` - Cost/reward value (from weak constraints)

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
1. Create `WABA/monoid/<name>_minimization.lp` and/or `<name>_maximization.lp`
2. Use weak constraints (`:~`) to minimize/maximize cost
3. Handle edge cases (#sup, #inf) with stratified priorities
4. Test with existing semirings and all semantics

**Testing a new combination**:
```bash
# Test your new combination
clingo -n 0 WABA/core/base.lp WABA/semiring/<new_semiring>.lp WABA/monoid/<new_monoid>.lp \
       WABA/filter/standard.lp WABA/semantics/stable.lp WABA/examples/medical.lp
```


## Budget Constraints (CRITICAL)

### ⚠️ IMPORTANT: Use Monoid-Specific Constraint Files

Budget constraints are in `WABA/constraint/` and are **monoid-specific**.

**DO NOT use generic `ub.lp` or `lb.lp`** - they are documentation files only.

**ALWAYS use:**
- `constraint/ub_sum.lp` with SUM monoid
- `constraint/ub_max.lp` with MAX monoid  
- `constraint/lb_min.lp` with MIN monoid (most common for MIN)
- `constraint/ub_count.lp` with COUNT monoid

### Why Monoid-Specific?

All constraints check `discarded_attack(X,Y,W)` directly. Using a generic file causes **constraint interference** - all aggregates fire simultaneously.

Example: Using `ub.lp` with SUM monoid and `beta=1`:
- SUM check: 30 > 1 → fires
- MAX check: 20 > 1 → fires
- MIN check: 10 > 1 → fires
- **COUNT check: 2 > 1 → FIRES! (even though you're using SUM!)**

**Solution**: Use `ub_sum.lp` which only checks SUM aggregate.

### Strict Boundary Enforcement

**IMPORTANT**: All budget constraints use **strict inequalities** for exact boundary enforcement:

**Upper Bounds (>=)** - Prevent exceeding budget:
- `constraint/ub_max.lp`: Rejects if `max(discarded weights) >= beta`
- `constraint/ub_sum.lp`: Rejects if `sum(discarded weights) >= beta`
- `constraint/ub_count.lp`: Rejects if `count(discarded attacks) >= beta`

**Lower Bounds (<=)** - Require minimum quality:
- `constraint/lb_max.lp`: Rejects if `max(discarded weights) <= beta`
- `constraint/lb_min.lp`: Rejects if `min(discarded weights) <= beta`
- `constraint/lb_sum.lp`: Rejects if `sum(discarded weights) <= beta`
- `constraint/lb_count.lp`: Rejects if `count(discarded attacks) <= beta`

**Consequences**:
- **Upper bound with beta=0**: NO attacks can be discarded (plain ABA/AAF)
- **Lower bound with beta=0**: Requires at least one positive-weight discard
- **Upper bound with beta=N**: Only attacks with cost > N can be discarded
- **Lower bound with beta=N**: Only combinations with cost > N are accepted

**For Plain ABA/AAF Simulation**:
```bash
# Framework must define: #const beta = 0. and budget(beta).
clingo -n 0 core/base.lp semiring/godel.lp \
       constraint/ub_max.lp semantics/admissible_aspartix.lp \
       framework.lp
```

### Usage Examples

```bash
# SUM monoid with upper bound
clingo -c beta=100 core/base.lp semiring/tropical.lp \
       monoid/sum_minimization.lp constraint/ub_sum.lp \
       filter/standard.lp semantics/stable.lp framework.lp

# MIN monoid with quality threshold (lower bound)
clingo -c beta=10 core/base.lp semiring/tropical.lp \
       monoid/min_minimization.lp constraint/lb_min.lp \
       filter/standard.lp semantics/stable.lp framework.lp
```

### Quick Reference

| Monoid | Typical Constraint | File | Meaning |
|--------|-------------------|------|---------|
| SUM | Upper bound | `ub_sum.lp` | Total cost ≤ β |
| MAX | Upper bound | `ub_max.lp` | Worst-case ≤ β |
| MIN | **Lower bound** | `lb_min.lp` | Quality ≥ β |
| COUNT | Upper bound | `ub_count.lp` | # discards ≤ β |

See `WABA/constraint/README.md` for complete documentation.
