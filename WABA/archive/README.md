# Archive - Incompatible Implementations

❌ **These implementations are INCOMPATIBLE with WABA and should not be used.**

This directory contains code that implements different formalisms or semantics incompatible with standard WABA.

---

## `non-flat/` - Non-Flat ABA Semantics

**Status**: ❌ INCOMPATIBLE with WABA

**Files**: `admissible_closed.lp`, `complete_closed.lp`, `stable_closed.lp`

**Why archived**: These implement a **different formalism** (non-flat ABA with closure constraints) that is fundamentally incompatible with WABA's flat assumption-based argumentation.

**Key differences**:
- **Closure constraint**: Forces `derived(X) ∧ assumption(X) → in(X)`
- **Incompatible semantics**: Rejects valid WABA extensions
- **Different formalism**: Designed for ABA with rules deriving assumptions
- **Not WABA**: Based on ASPforABA IJCAI'24 for non-flat frameworks

**Why not EXPERIMENTAL**: These aren't alternative implementations of WABA semantics - they implement entirely different semantics for a different argumentation formalism.

**Do not use**: Unless you specifically need non-flat ABA (rare), which is NOT what WABA provides.

---

## Purpose of This Archive

Code is archived here when it is:
- ❌ Incompatible with WABA's formalism
- ❌ Implements different semantics than intended
- ❌ Cannot be fixed to work with WABA
- ❌ Fundamentally unsuitable for any WABA use case

**For experimental but potentially usable code**: See `semantics/experimental/`

**For production code**: See `semantics/`
