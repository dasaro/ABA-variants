# WABA Testing with Clingo

This document provides comprehensive clingo command patterns for testing WABA. It replaces the previous shell scripts with documented, reproducible commands.

## Table of Contents

1. [Basic Testing](#basic-testing)
2. [Legal Semiring-Monoid Combinations](#legal-semiring-monoid-combinations)
3. [Testing Different Semantics](#testing-different-semantics)
4. [Optimization Comparison](#optimization-comparison)
5. [Result Analysis Patterns](#result-analysis-patterns)
6. [Common Pitfalls](#common-pitfalls)
7. [Batch Testing](#batch-testing)

---

## Basic Testing

### Test Original WABA (Gödel + Max + Stable)

```bash
clingo -n 0 core/base.lp semiring/godel.lp monoid/max.lp \
       filter/standard.lp semantics/stable.lp examples/medical.lp
```

### Test with Simple Example

```bash
clingo -n 0 core/base.lp semiring/godel.lp monoid/max.lp \
       filter/standard.lp semantics/stable.lp examples/simple.lp
```

### Test Semiring Differences (Showcase)

```bash
clingo -n 0 core/base.lp semiring/godel.lp monoid/sum.lp \
       filter/standard.lp semantics/cf.lp examples/showcase.lp
```

---

## Legal Semiring-Monoid Combinations

See [SEMIRING_MONOID_COMPATIBILITY.md](SEMIRING_MONOID_COMPATIBILITY.md) for detailed compatibility matrix.

### ✓ Gödel/Fuzzy Combinations

**Gödel + Max** (Original WABA):
```bash
clingo -n 0 core/base.lp semiring/godel.lp monoid/max.lp \
       filter/standard.lp semantics/stable.lp examples/medical.lp
```

**Gödel + Sum** (Cumulative cost):
```bash
clingo -n 0 core/base.lp semiring/godel.lp monoid/sum.lp \
       filter/standard.lp semantics/stable.lp examples/medical.lp
```

**Gödel + Count** (Weight-agnostic counting):
```bash
clingo -n 0 -c beta=2 core/base.lp semiring/godel.lp monoid/count.lp \
       filter/standard.lp semantics/stable.lp examples/medical.lp
```

**Gödel + Lex** (Lexicographic priority):
```bash
clingo -n 0 core/base.lp semiring/godel.lp monoid/lex.lp \
       filter/lexicographic.lp optimize/lexicographic.lp \
       semantics/stable.lp examples/medical.lp
```

### ✓ Tropical Combinations

**Tropical + Min** (Only legal tropical combination):
```bash
clingo -n 0 -c beta=10 core/base.lp semiring/tropical.lp monoid/min.lp \
       filter/standard.lp optimize/maximize.lp semantics/stable.lp examples/medical.lp
```

**Tropical + Count**:
```bash
clingo -n 0 -c beta=2 core/base.lp semiring/tropical.lp monoid/count.lp \
       filter/standard.lp semantics/stable.lp examples/medical.lp
```

**Tropical + Lex**:
```bash
clingo -n 0 core/base.lp semiring/tropical.lp monoid/lex.lp \
       filter/lexicographic.lp optimize/lexicographic.lp \
       semantics/stable.lp examples/medical.lp
```

### ✓ Łukasiewicz Combinations

**Łukasiewicz + Max**:
```bash
clingo -n 0 core/base.lp semiring/lukasiewicz.lp monoid/max.lp \
       filter/standard.lp semantics/stable.lp test/test_lukasiewicz.lp
```

**Łukasiewicz + Sum**:
```bash
clingo -n 0 core/base.lp semiring/lukasiewicz.lp monoid/sum.lp \
       filter/standard.lp semantics/stable.lp test/test_lukasiewicz.lp
```

**Łukasiewicz + Count**:
```bash
clingo -n 0 -c beta=2 core/base.lp semiring/lukasiewicz.lp monoid/count.lp \
       filter/standard.lp semantics/stable.lp test/test_lukasiewicz.lp
```

### ✓ Bottleneck-Cost Combinations

**Bottleneck-Cost + Min** (Quality threshold):
```bash
clingo -n 0 -c beta=0 core/base.lp semiring/bottleneck_cost.lp monoid/min.lp \
       filter/standard.lp optimize/maximize.lp semantics/stable.lp test/test_bottleneck.lp
```

---

## Testing Different Semantics

### Stable Semantics (Default)

```bash
clingo -n 0 core/base.lp semiring/godel.lp monoid/max.lp \
       filter/standard.lp semantics/stable.lp examples/medical.lp
```

### Conflict-Free Semantics

```bash
clingo -n 0 core/base.lp semiring/godel.lp monoid/max.lp \
       filter/standard.lp semantics/cf.lp examples/medical.lp
```

### Naive Semantics (Requires Special Flags)

```bash
clingo -n 0 --heuristic=Domain --enum=domRec \
       core/base.lp semiring/godel.lp monoid/max.lp \
       filter/standard.lp semantics/naive.lp examples/medical.lp
```

**Important**: Naive semantics MUST use `--heuristic=Domain --enum=domRec` flags.

---

## Optimization Comparison

### Without Optimization (All Extensions)

```bash
clingo -n 0 core/base.lp semiring/godel.lp monoid/max.lp \
       filter/standard.lp semantics/stable.lp examples/medical.lp
```

### With Cost Minimization (Optimal Extensions Only)

```bash
clingo -n 0 core/base.lp semiring/godel.lp monoid/max.lp \
       filter/standard.lp optimize/minimize.lp semantics/stable.lp examples/medical.lp
```

### With Cost Maximization (For MIN Monoid)

```bash
clingo -n 0 -c beta=10 core/base.lp semiring/tropical.lp monoid/min.lp \
       filter/standard.lp optimize/maximize.lp semantics/stable.lp examples/medical.lp
```

### Lexicographic Optimization

```bash
clingo -n 0 core/base.lp semiring/godel.lp monoid/lex.lp \
       filter/lexicographic.lp optimize/lexicographic.lp \
       semantics/stable.lp examples/simple.lp
```

**Note**: Use `filter/lexicographic.lp` with `monoid/lex.lp` to see all three cost components (max, sum, count).

---

## Result Analysis Patterns

### Check Expected Output Predicates

```bash
# Filter output to see specific predicates
clingo -n 0 core/base.lp semiring/godel.lp monoid/max.lp \
       filter/standard.lp semantics/stable.lp examples/medical.lp \
       | grep "in("
```

### Count Answer Sets

```bash
clingo -n 0 core/base.lp semiring/godel.lp monoid/max.lp \
       filter/standard.lp semantics/stable.lp examples/medical.lp \
       | grep "Answer:" | wc -l
```

### Compare Costs Across Different Monoids

```bash
# Test with MAX monoid
echo "=== MAX Monoid ==="
clingo -n 0 core/base.lp semiring/godel.lp monoid/max.lp \
       filter/standard.lp semantics/stable.lp examples/showcase.lp \
       | grep "extension_cost"

# Test with SUM monoid
echo "=== SUM Monoid ==="
clingo -n 0 core/base.lp semiring/godel.lp monoid/sum.lp \
       filter/standard.lp semantics/stable.lp examples/showcase.lp \
       | grep "extension_cost"

# Test with COUNT monoid
echo "=== COUNT Monoid ==="
clingo -n 0 -c beta=4 core/base.lp semiring/godel.lp monoid/count.lp \
       filter/standard.lp semantics/stable.lp examples/showcase.lp \
       | grep "extension_cost"
```

### Compare Optimization vs Non-Optimization

```bash
# Without optimization
echo "=== Without Optimization (All Extensions) ==="
clingo -n 0 core/base.lp semiring/godel.lp monoid/max.lp \
       filter/standard.lp semantics/stable.lp examples/simple.lp \
       | grep -E "(Answer:|extension_cost)"

# With optimization
echo "=== With Optimization (Optimal Only) ==="
clingo -n 0 core/base.lp semiring/godel.lp monoid/max.lp \
       filter/standard.lp optimize/minimize.lp semantics/stable.lp examples/simple.lp \
       | grep -E "(Answer:|extension_cost|Optimization)"
```

---

## Common Pitfalls

### 1. Missing Budget Parameter

**Problem**: No `budget(N)` in framework file and no `-c beta=N` on command line.

**Symptom**: Budget constraint effectively disabled, all attacks can be discarded, meaningless results.

**Fix**:
```bash
# Add -c beta=N to command
clingo -n 0 -c beta=100 core/base.lp semiring/godel.lp monoid/max.lp \
       filter/standard.lp semantics/stable.lp your_framework.lp

# OR add budget(100). to your framework file
```

### 2. Wrong Optimization for MIN Monoid

**Problem**: Using `optimize/minimize.lp` with `monoid/min.lp`.

**Fix**: MIN monoid uses **maximize.lp** (quality threshold semantics):
```bash
clingo -n 0 -c beta=10 core/base.lp semiring/tropical.lp monoid/min.lp \
       filter/standard.lp optimize/maximize.lp semantics/stable.lp examples/medical.lp
```

### 3. Incompatible Semiring-Monoid Pairs

**Problem**: Using illegal combinations (e.g., Gödel + Min, Tropical + Max).

**Symptom**: Conflicting semantics for unweighted assumptions, unexpected results.

**Fix**: See [SEMIRING_MONOID_COMPATIBILITY.md](SEMIRING_MONOID_COMPATIBILITY.md) for legal pairs.

### 4. Naive Semantics Without Special Flags

**Problem**: Running naive semantics without `--heuristic=Domain --enum=domRec`.

**Fix**:
```bash
clingo -n 0 --heuristic=Domain --enum=domRec \
       core/base.lp semiring/godel.lp monoid/max.lp \
       filter/standard.lp semantics/naive.lp examples/medical.lp
```

### 5. No Answer Sets (UNSATISFIABLE)

**Problem**: clingo reports "UNSATISFIABLE" (0 answer sets).

**Possible causes**:
- Budget too strict (try increasing with `-c beta=<higher_value>`)
- Framework has no valid extensions
- Conflicting constraints in framework

**Debug**:
```bash
# Try conflict-free semantics instead of stable
clingo -n 0 core/base.lp semiring/godel.lp monoid/max.lp \
       filter/standard.lp semantics/cf.lp examples/medical.lp

# Increase budget
clingo -n 0 -c beta=1000 core/base.lp semiring/godel.lp monoid/max.lp \
       filter/standard.lp semantics/stable.lp examples/medical.lp
```

---

## Batch Testing

### Test All Legal Gödel Combinations

```bash
#!/bin/bash
# Test all legal Gödel semiring combinations

CORE="core/base.lp"
SEMIRING="semiring/godel.lp"
FILTER="filter/standard.lp"
SEMANTICS="semantics/stable.lp"
EXAMPLE="examples/simple.lp"

for MONOID in max sum count lex; do
  echo "=== Testing Gödel + ${MONOID} ==="
  if [ "$MONOID" = "lex" ]; then
    clingo -n 0 $CORE $SEMIRING monoid/$MONOID.lp \
           filter/lexicographic.lp optimize/lexicographic.lp $SEMANTICS $EXAMPLE
  elif [ "$MONOID" = "count" ]; then
    clingo -n 0 -c beta=2 $CORE $SEMIRING monoid/$MONOID.lp $FILTER $SEMANTICS $EXAMPLE
  else
    clingo -n 0 $CORE $SEMIRING monoid/$MONOID.lp $FILTER $SEMANTICS $EXAMPLE
  fi
  echo ""
done
```

### Test All Semantics with Gödel + Max

```bash
#!/bin/bash
# Test all semantics with original WABA configuration

CORE="core/base.lp"
SEMIRING="semiring/godel.lp"
MONOID="monoid/max.lp"
FILTER="filter/standard.lp"
EXAMPLE="examples/simple.lp"

for SEM in stable cf naive; do
  echo "=== Testing ${SEM} semantics ==="
  if [ "$SEM" = "naive" ]; then
    clingo -n 0 --heuristic=Domain --enum=domRec \
           $CORE $SEMIRING $MONOID $FILTER semantics/$SEM.lp $EXAMPLE
  else
    clingo -n 0 $CORE $SEMIRING $MONOID $FILTER semantics/$SEM.lp $EXAMPLE
  fi
  echo ""
done
```

### Compare Optimization Impact

```bash
#!/bin/bash
# Compare results with and without optimization

CORE="core/base.lp"
SEMIRING="semiring/godel.lp"
MONOID="monoid/max.lp"
FILTER="filter/standard.lp"
SEMANTICS="semantics/stable.lp"
EXAMPLE="examples/simple.lp"

echo "=== Without Optimization ==="
clingo -n 0 $CORE $SEMIRING $MONOID $FILTER $SEMANTICS $EXAMPLE \
       | grep -E "(Answer:|extension_cost)"

echo ""
echo "=== With Optimization ==="
clingo -n 0 $CORE $SEMIRING $MONOID $FILTER optimize/minimize.lp $SEMANTICS $EXAMPLE \
       | grep -E "(Answer:|extension_cost|Optimization)"
```

### Test All Legal Combinations (Comprehensive)

```bash
#!/bin/bash
# Comprehensive test of all 9 legal semiring-monoid combinations

test_combination() {
  local sem=$1
  local mon=$2
  local extra_flags=$3

  echo "=== Testing $sem + $mon ==="

  if [ "$mon" = "lex" ]; then
    clingo -n 0 $extra_flags core/base.lp semiring/$sem.lp monoid/$mon.lp \
           filter/lexicographic.lp optimize/lexicographic.lp \
           semantics/stable.lp examples/simple.lp
  elif [ "$mon" = "min" ]; then
    clingo -n 0 $extra_flags core/base.lp semiring/$sem.lp monoid/$mon.lp \
           filter/standard.lp optimize/maximize.lp semantics/stable.lp examples/simple.lp
  elif [ "$mon" = "count" ]; then
    clingo -n 0 -c beta=2 $extra_flags core/base.lp semiring/$sem.lp monoid/$mon.lp \
           filter/standard.lp semantics/stable.lp examples/simple.lp
  else
    clingo -n 0 $extra_flags core/base.lp semiring/$sem.lp monoid/$mon.lp \
           filter/standard.lp semantics/stable.lp examples/simple.lp
  fi
  echo ""
}

# Gödel combinations (4)
test_combination "godel" "max"
test_combination "godel" "sum"
test_combination "godel" "count"
test_combination "godel" "lex"

# Tropical combinations (3)
test_combination "tropical" "min" "-c beta=10"
test_combination "tropical" "count"
test_combination "tropical" "lex"

# Łukasiewicz combinations (3)
# Note: Would need appropriate example files
echo "=== Łukasiewicz combinations require specific test files ==="

# Bottleneck combinations (1)
echo "=== Bottleneck-cost combinations require specific test files ==="
```

---

## Advanced Usage

### Saving Results to File

```bash
# Save all output
clingo -n 0 core/base.lp semiring/godel.lp monoid/max.lp \
       filter/standard.lp semantics/stable.lp examples/medical.lp \
       > results_medical.txt 2>&1

# Save only answer sets
clingo -n 0 core/base.lp semiring/godel.lp monoid/max.lp \
       filter/standard.lp semantics/stable.lp examples/medical.lp \
       | grep -A 20 "Answer:" > answers_only.txt
```

### Parallel Testing (if you have multiple frameworks)

```bash
#!/bin/bash
# Test multiple frameworks in parallel

for fw in examples/*.lp; do
  echo "Testing $fw"
  clingo -n 0 core/base.lp semiring/godel.lp monoid/max.lp \
         filter/standard.lp semantics/stable.lp "$fw" \
         > "results_$(basename $fw .lp).txt" 2>&1 &
done

wait
echo "All tests complete"
```

---

## Summary

This guide replaces the previous shell scripts with documented, reproducible clingo commands. Key takeaways:

1. **Always set a budget** (either in framework file or via `-c beta=N`)
2. **Check compatibility** before combining semiring and monoid
3. **Use correct optimization** (minimize for MAX/SUM/COUNT, maximize for MIN)
4. **Use special flags** for naive semantics (`--heuristic=Domain --enum=domRec`)
5. **Test incrementally** (start with CF semantics, then stable, then naive)

For more details, see:
- [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - Common command patterns
- [SEMIRING_MONOID_COMPATIBILITY.md](SEMIRING_MONOID_COMPATIBILITY.md) - Legal combinations
