# EXPERIMENTAL Semantics Implementations

⚠️ **WARNING**: These implementations are EXPERIMENTAL and not recommended for production use.

**For production**: Use the main `semantics/*.lp` files (standard implementations).

---

## Directory Contents

### `heuristic/` - Heuristic-Based Approach

**Status**: ⚠️ EXPERIMENTAL - Not production-ready

**Files**: `grounded.lp`, `naive.lp`, `preferred.lp`, `semi-stable.lp`, `staged.lp`

**Approach**: Uses `#heuristic` directives to guide Clingo's search space exploration

**Required Flags**: `--heuristic=Domain --enum-mode=domRec`

**Limitations**:
- ❌ Requires obscure command-line flags
- ❌ Completeness not guaranteed (heuristics may miss extensions)
- ❌ Non-deterministic behavior (search order dependent)
- ❌ Poor test results (6/10 passing in initial tests)
- ❌ Not browser-compatible (specific enumeration modes)

**Use Case**: Research on heuristic-guided ASP solving only

---

### `optN/` - Optimization-Based Approach

**Status**: ⚠️ EXPERIMENTAL - Mode-dependent

**Files**: `preferred.lp`, `semi-stable.lp`, `staged.lp`, `ideal.lp`

**Approach**: Uses `#minimize`/`#maximize` with `--opt-mode=optN` to find optimal extensions

**Required Flags**: `--opt-mode=optN --quiet=1`

**Limitations**:
- ❌ Only works with `--opt-mode=optN` (fails in enumeration mode)
- ❌ Returns suboptimal results if flags forgotten
- ❌ User confusion (optimization vs enumeration modes)
- ❌ Less robust than standard implementations
- ⚠️ Testing complexity (need separate mode validation)

**Use Case**: When you specifically need optimization mode features

**Note**: Standard implementations work correctly in BOTH enumeration and optimization modes.

---

## When to Use Experimental Implementations

**Short answer**: Almost never.

**Valid reasons**:
1. **Research**: Comparing different ASP encoding strategies
2. **Optimization-specific**: You need features only available in `--opt-mode=optN`

**Invalid reasons**:
- ❌ "They look simpler" → They're incomplete
- ❌ "Maybe faster?" → Not tested; standard implementations are highly optimized
- ❌ "Different approach" → Standard implementations are battle-tested

---

## Production Recommendation

✅ **Always use**: `semantics/*.lp` (main directory)

These implementations:
- Work in both enumeration and optimization modes
- Require no special flags
- 100% tested (700+ test cases, 0 failures)
- Browser-compatible (Clingo WASM)
- Production-ready

See `../SEMANTICS_IMPLEMENTATION_SUMMARY.md` for details.
