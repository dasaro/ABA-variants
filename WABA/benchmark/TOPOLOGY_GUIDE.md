# WABA Benchmark Topologies Guide

**What are topologies?** Graph structures defining the **base attack enablement pattern** between assumptions and contraries.

**Key Distinction**:
- **Attacks flow**: `non-assumption → assumption` (contraries/derived atoms attack assumptions)
- **Topology defines**: Which assumptions, when selected, enable contraries that attack which other assumptions
- **Indirect attack graph**: Assumptions enable contraries (via attack rules), contraries attack assumptions (via contrary predicates)

**Important**: Topologies describe the **base attack structure** only. Derived atoms create **additional attack paths** that overlay on the topology.

---

## The 6 Topology Types

### 1. **LINEAR** - Pure Chain (No Wraparound)

**Structure**: `a1 → a2 → a3 → ... → an`

**Properties**:
- Pure directed chain (acyclic)
- Source: `a1` (in-degree 0, starts the chain)
- Sink: `an` (out-degree 0, ends the chain)
- Each assumption attacks exactly one other (except `an`)

**Attack Edges**: `E = {(a_i, a_{i+1}) | i = 1..n-1}`

**Example** (A=5):
```
a1 → a2 → a3 → a4 → a5
```

**Contrary predicates**:
```prolog
contrary(a2, c_a2).  % a1 attacks a2
contrary(a3, c_a3).  % a2 attacks a3
contrary(a4, c_a4).  % a3 attacks a4
contrary(a5, c_a5).  % a4 attacks a5
```

**Complexity**: Low (simple sequential dependencies)

---

### 2. **CYCLE** - Directed Cycle with Wraparound

**Structure**: `a1 → a2 → ... → an → a1` (closes the loop!)

**Properties**:
- Circular dependency (strongly connected)
- Each assumption has in-degree 1 and out-degree 1
- No source or sink (all nodes equivalent)
- Can have partial cycles (`cycle_length < A`)

**Attack Edges**: `E = {(a_i, a_{(i+1) mod n}) | i = 0..n-1}`

**Example** (A=5, full cycle):
```
a1 → a2 → a3 → a4 → a5 → a1
 ↑__________________________|
```

**Contrary predicates**:
```prolog
contrary(a2, c_a2).  % a1 attacks a2
contrary(a3, c_a3).  % a2 attacks a3
contrary(a4, c_a4).  % a3 attacks a4
contrary(a5, c_a5).  % a4 attacks a5
contrary(a1, c_a1).  % a5 attacks a1 (cycle closes!)
```

**Complexity**: High (circular dependencies create larger search spaces)

**Benchmark Performance**:
- Average: 71.16s (7.5x slower than Complete!)
- Timeout: 29.5%
- Causes 68% of all timeouts

---

### 3. **TREE** - Hierarchical Branching

**Structure**: Parent attacks children in tree formation

**Properties**:
- Root has in-degree 0
- Leaves have out-degree 0
- Branching factor: 2 (binary) or 3 (ternary)
- Acyclic (no loops)

**Attack Edges**: `E = {(a_i, a_{i*b+j}) | j=1..b, i*b+j < A}`
where `b` = branching factor

**Example** (A=7, branching=2):
```
         a1
        /  \
      a2    a3
     / \   / \
   a4  a5 a6 a7
```

**Contrary predicates**:
```prolog
contrary(a2, c_a2).  % a1 attacks a2
contrary(a3, c_a3).  % a1 attacks a3
contrary(a4, c_a4).  % a2 attacks a4
contrary(a5, c_a5).  % a2 attacks a5
contrary(a6, c_a6).  % a3 attacks a6
contrary(a7, c_a7).  % a3 attacks a7
```

**Complexity**: Moderate (hierarchical, but acyclic)

---

### 4. **COMPLETE** - All-vs-All Attacks

**Structure**: Every assumption attacks every other assumption

**Properties**:
- Complete directed graph (clique)
- Each assumption has in-degree `A-1` and out-degree `A-1`
- Maximum attack density: `|E| = A * (A-1)`
- Highly symmetric

**Attack Edges**: `E = {(a_i, a_j) | i,j ∈ [1,A], i ≠ j}`

**Example** (A=4):
```
    ↗ a2 ↘
  a1 ⇄ a3
    ↘ a4 ↗
(Every node attacks every other node)
```

**Contrary predicates** (A=4):
```prolog
% a1 attacks everyone else
contrary(a2, c_a2). contrary(a3, c_a3). contrary(a4, c_a4).

% a2 attacks everyone else
contrary(a1, c_a1). contrary(a3, c_a3). contrary(a4, c_a4).

% a3 attacks everyone else
contrary(a1, c_a1). contrary(a2, c_a2). contrary(a4, c_a4).

% a4 attacks everyone else
contrary(a1, c_a1). contrary(a2, c_a2). contrary(a3, c_a3).
```

**Number of attack edges**: For A=10, this creates 90 attack edges!

**Complexity**: Should be high (dense), but actually **LOW** in practice

**Benchmark Performance** (Surprising!):
- Average: 9.44s (very fast!)
- Timeout: 3.0% (very reliable)
- Despite having the most edges (90 for A=10), it's 7.5x FASTER than Cycle

**Why?** Highly symmetric structure → ASP solver finds solutions quickly

---

### 5. **MIXED** - Clustered with Bridges

**Structure**: Dense local clusters connected by sparse inter-cluster edges

**Properties**:
- Multiple dense subgraphs (clusters)
- Sparse connections between clusters (bridges)
- Mimics real-world modular structures
- Heterogeneous edge density

**Attack Edges**: Dense within clusters, sparse between clusters

**Example** (A=9, 3 clusters):
```
Cluster 1:       Cluster 2:       Cluster 3:
a1 ⇄ a2 ⇄ a3    a4 ⇄ a5 ⇄ a6    a7 ⇄ a8 ⇄ a9
   (dense)         (dense)          (dense)
    |               |                |
    └─── bridge ────┴──── bridge ───┘
         (sparse)         (sparse)
```

**Complexity**: Moderate (combines dense and sparse regions)

---

### 6. **ISOLATED** - Disconnected Components

**Structure**: Multiple independent subgraphs with **NO inter-component attacks**

**Properties**:
- Completely disconnected components
- Each component is internally connected
- No edges between components
- Solvable independently (parallelizable!)

**Attack Edges**: `E = ∪ E_i` where `E_i` are disjoint edge sets

**Example** (A=9, 3 components):
```
Component 1:    Component 2:    Component 3:
a1 → a2 → a3   a4 ⇄ a5 ⇄ a6   a7 → a8 → a9

(NO connections between components)
```

**Complexity**: Low (can solve each component independently)

---

## Attack Topology vs Derivation Rules

### Attack Topology (Contrary Relations)
**Defined by**: `contrary(X, element)` predicates
**Meaning**: `element` attacks assumption `X`
**Graph**: Nodes = assumptions, Edges = attack relations
**Property**: This is what the **topology** describes

**Example**:
```prolog
% Cycle topology for A=3
contrary(a2, c_a2).  % a1 attacks a2
contrary(a3, c_a3).  % a2 attacks a3
contrary(a1, c_a1).  % a3 attacks a1 (cycle!)
```

### Derivation Rules (Non-Topology)
**Defined by**: `head(R, X), body(R, Y)` predicates
**Meaning**: Inference rules `R: X ← Y1, ..., Yn`
**Purpose**: Create derived atoms that participate in attacks
**Property**: NOT part of the topology (but must integrate with it)

**Example**:
```prolog
% Derivation rule creating derived atom d1
head(r1, d1).    % r1: d1 ← a1, a2
body(r1, a1).
body(r1, a2).

% d1 must attack something (via contrary relation)
contrary(a3, d1).  % d1 attacks a3
```

---

## Benchmark Framework Composition

Each framework file contains:

1. **Assumptions**: `assumption(a1; a2; ...; an).`
2. **Weights**: `weight(ai, wi).` - costs for assumptions and derived atoms
3. **Attack Rules**: `head(r_atk_X_Y, c_Y). body(r_atk_X_Y, X).` - implements attack topology
4. **Derivation Rules**: `head(rD, dD). body(rD, X).` - creates derived atoms
5. **Contraries**: Implied by attack rules via `c_X` naming convention
6. **Budget**: `budget(B).` - maximum discardable attack cost

**The topology determines steps 3 and implicitly 5.**

---

## Topology Impact on Computational Complexity

### Why Cycle is Harder than Complete

**Cycle** (71s avg, 29.5% timeout):
- Circular dependencies force solver to consider all assumptions together
- Cannot prune search space early
- Every assumption depends on every other (transitively)
- Breaks solver's conflict-driven learning

**Complete** (9.44s avg, 3% timeout):
- Highly symmetric (all assumptions equivalent)
- Solver recognizes symmetry and exploits it
- Many equivalent solutions → finds one quickly
- Dense constraints prune search space early

### Edge Count vs Complexity

| Topology | A=10 Edges | Avg Time | Timeout |
|----------|-----------|----------|---------|
| **Linear** | 9 | ~15s* | ~5%* |
| **Cycle** | 10 | 71s | 29.5% |
| **Complete** | 90 | 9.44s | 3.0% |

*Estimated (not yet benchmarked)

**Observation**: More edges ≠ harder! Structure matters more than density.

---

## Topology Distribution in Benchmark

**Total frameworks**: 60
**Frameworks per topology**: 10

| Topology | Count | Benchmarked So Far | Status |
|----------|-------|-------------------|--------|
| Complete | 10 | 200/200 runs (100%) | ✓ Complete |
| Cycle | 10 | 44/200 runs (22%) | In progress |
| Linear | 10 | 0/200 runs (0%) | Not started |
| Tree | 10 | 0/200 runs (0%) | Not started |
| Mixed | 10 | 0/200 runs (0%) | Not started |
| Isolated | 10 | 0/200 runs (0%) | Not started |

**Current benchmark progress**: 244/1,200 runs (20.3%)

---

## Real-World Analogies

### Linear
**Example**: Sequential approval process
- Manager approves → Director approves → VP approves → CEO approves

### Cycle
**Example**: Rock-paper-scissors, circular causation
- Rock beats Scissors beats Paper beats Rock

### Tree
**Example**: Organizational hierarchy
- CEO → (VP1, VP2) → (Manager1, Manager2, ...)

### Complete
**Example**: Political debate (everyone attacks everyone)
- Each candidate criticizes all other candidates

### Mixed
**Example**: Social networks with communities
- Dense friend groups, sparse connections between groups

### Isolated
**Example**: Independent projects
- Project A, Project B, Project C (no dependencies)

---

## Key Takeaways

1. **Topology = Attack Graph Structure** (who attacks whom)
2. **NOT about derivation rules** (those are separate)
3. **Cycle is hardest** (29.5% timeout despite only 10 edges)
4. **Complete is easiest** (3% timeout despite 90 edges!)
5. **Symmetry helps** (complete graph is highly symmetric)
6. **Circular dependencies hurt** (cycle creates interdependencies)

---

## Complete Attack Mechanism (Topology + Derived Atoms)

### The Precise Attack Flow

**CRITICAL**: Attacks flow from **non-assumptions** (contraries, derived atoms) **TO** assumptions.

**Attack structure in framework files**:

1. **Contrary declarations**: `contrary(aX, c_aX)` - "c_aX attacks assumption aX"
2. **Topology attack rules**: `head(r_atk_aX_aY, c_aY). body(r_atk_aX_aY, aX).`
   - Meaning: "If aX is in the extension, then c_aY is supported"
   - Effect: c_aY attacks aY (via contrary declaration)
3. **Derivation rules**: `head(rD, dD). body(rD, a1; rD, a2; ...).`
   - Meaning: "If a1, a2, ... are supported, then dD is supported"
   - Creates intermediate derived atoms
4. **Derived atom attack rules**: `head(r_atk_dN_aY, c_aY). body(r_atk_dN_aY, dN; r_atk_dN_aY, aX).`
   - Meaning: "If dN is supported AND aX is in, then c_aY is supported"
   - Creates conditional, multi-step attacks

### Example: Cycle Topology with Derived Atoms

**Framework**: cycle_a10_r2_cfull_bimodal.lp

#### Topology Attacks (Base Structure)
```prolog
% Direct attack enablement (10 edges forming cycle)
head(r_atk_a1_a2, c_a2). body(r_atk_a1_a2, a1).  % a1 enables c_a2 → attacks a2
head(r_atk_a2_a3, c_a3). body(r_atk_a2_a3, a2).  % a2 enables c_a3 → attacks a3
...
head(r_atk_a10_a1, c_a1). body(r_atk_a10_a1, a10). % a10 enables c_a1 → attacks a1 (cycle!)

% Contrary declarations
contrary(a1, c_a1). contrary(a2, c_a2). ... contrary(a10, c_a10).
```

**Attack flow**: `a1 ∈ extension → c_a2 supported → c_a2 attacks a2`

#### Derivation Rules (Create Intermediate Atoms)
```prolog
head(r_d1_1, d1). body(r_d1_1, a2; r_d1_1, a8; r_d1_1, a3).  % d1 ← a2, a8, a3
head(r_d2_2, d2). body(r_d2_2, d1; r_d2_2, a2; r_d2_2, a3).  % d2 ← d1, a2, a3
```

**Derivation flow**: `(a2, a8, a3) ∈ extension → d1 supported → (d1, a2, a3) ∈ supported → d2 supported`

#### Derived Atom Attacks (Overlay Paths)
```prolog
head(r_atk_d_3, c_a10). body(r_atk_d_3, d1; r_atk_d_3, a4).  % c_a10 ← d1, a4
head(r_atk_d_4, c_a4).  body(r_atk_d_4, d2).                  % c_a4 ← d2
head(r_atk_d_5, c_a2).  body(r_atk_d_5, d1).                  % c_a2 ← d1
head(r_atk_d_6, c_a9).  body(r_atk_d_6, d1; r_atk_d_6, a4).  % c_a9 ← d1, a4
head(r_atk_d_7, c_a7).  body(r_atk_d_7, d2; r_atk_d_7, d1).  % c_a7 ← d2, d1
```

**Multi-step attack chains**:

**Chain A** (depth 2):
```
(a2, a8, a3) ∈ extension → d1 supported → c_a2 supported → c_a2 attacks a2
└──────────┘               └──┘           └────┘
assumptions               derived        contrary
```

**Chain B** (depth 3):
```
(a2, a8, a3) ∈ extension → d1 supported → (d1, a4) ∈ supported → c_a10 supported → c_a10 attacks a10
└──────────┘               └──┘           └─────────────┘         └─────┘
step 1                    step 2         step 3                  attack
```

**Chain C** (depth 4):
```
(a2, a8, a3) ∈ extension → d1 supported → (d1, a2, a3) ∈ supported → d2 supported → c_a4 supported → c_a4 attacks a4
└──────────┘               └──┘           └─────────────────┘        └──┘           └────┘
assumptions               d1             derive d2                 d2             contrary
```

### Total Attack Space

**Cycle topology (A=10, R=2)**:
- **Topology attacks**: 10 rules (base cycle structure)
- **Derived atom attacks**: 5 rules (overlay paths)
- **Total attack rules**: 15

**Complete attack graph includes**:
1. **Direct attacks**: Topology-defined (assumption → contrary → attack)
2. **Conditional attacks**: Derived atom-mediated (multi-step chains)
3. **Layered dependencies**: Derived atoms depend on assumptions, create new attack paths

### Why This Matters for Computational Complexity

**Topology alone** (10 edges):
- Defines basic conflict structure
- Creates circular dependencies (cycle) or symmetric structure (complete)

**Derived atoms** (+5 edges):
- Add conditional attack paths
- Increase search space (more rules to ground)
- Create deeper attack chains (2-4 step paths)
- Compound with semiring operations (Arctic/Tropical especially affected)

**Result**: Even simple topologies become complex when:
1. More derived atoms (larger R parameter)
2. Deeper derivation chains (d2 depends on d1)
3. Complex semirings (Arctic/Tropical create large ground programs)

**This explains why**:
- **Cycle with R=10** is much harder than **Cycle with R=2**
- **Arctic semiring** amplifies this (80-90% grounding time!)
- **SUM monoid** makes it worse (53% grounding time due to aggregation constraints)

---

## Topology Definition (Revised)

**Topology** = Base attack enablement pattern defined by topology-specific attack rules

**Formally**:
- **Nodes**: Assumptions A = {a1, a2, ..., an}
- **Edges**: E ⊆ A × A where (ai, aj) ∈ E means "if ai ∈ extension, then a contrary attacking aj is enabled"
- **Implementation**: Attack rules `c_aj ← ai` for each (ai, aj) ∈ E

**Complete attack structure** = Topology + Derived atom attack paths

**Properties**:
- Topology defines **base conflict pattern** (assumption-level)
- Derived atoms **overlay** additional attack paths (multi-step)
- Both contribute to **computational complexity**
- Topology determines **graph-theoretic properties** (cycle, tree, complete, etc.)

---

**CONCLUSION**: Topologies define the base indirect attack graph (assumptions enable contraries that attack other assumptions). Derived atoms create additional, multi-step attack chains that overlay on this base structure. The complete attack space is the combination of both, and both contribute significantly to computational complexity.
