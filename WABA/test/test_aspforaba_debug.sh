#!/bin/bash
# Debug test script for WABA semantics - proper extension counting
# Shows actual extensions and counts them correctly

set -e

CORE="../core/base.lp"
SEMIRING="../semiring/godel.lp"
MONOID="../monoid/max_minimization.lp"
FILTER="../filter/standard.lp"

echo "========================================="
echo "WABA Semantics Debug Test"
echo "========================================="
echo ""

# Helper function to count and display extensions
count_extensions() {
    local output="$1"
    local count=$(echo "$output" | grep -c "^Answer:" || true)
    echo "$count"
}

# Test 1: Journal Example - Extension Counts
echo "Test 1: Journal Example (Extension Counts)"
echo "-------------------------------------------"

FRAMEWORK="aspforaba_journal_example.lp"

echo ""
echo "1. Admissible (expect 7 extensions)"
echo "------------------------------------"
OUTPUT=$(clingo -n 0 $CORE $SEMIRING $MONOID $FILTER ../semantics/admissible.lp $FRAMEWORK 2>/dev/null)
COUNT=$(count_extensions "$OUTPUT")
echo "Found: $COUNT extensions"
echo ""
echo "$OUTPUT" | grep "Answer:" | head -7
echo ""

echo "2. Complete (expect 3 extensions)"
echo "-----------------------------------"
OUTPUT=$(clingo -n 0 $CORE $SEMIRING $MONOID $FILTER ../semantics/complete.lp $FRAMEWORK 2>/dev/null)
COUNT=$(count_extensions "$OUTPUT")
echo "Found: $COUNT extensions"
echo ""
echo "$OUTPUT" | grep -A 1 "Answer:" | grep "in("
echo ""

echo "3. Stable (expect 2 extensions)"
echo "---------------------------------"
OUTPUT=$(clingo -n 0 $CORE $SEMIRING $MONOID $FILTER ../semantics/stable.lp $FRAMEWORK 2>/dev/null)
COUNT=$(count_extensions "$OUTPUT")
echo "Found: $COUNT extensions"
echo ""
echo "$OUTPUT" | grep -A 1 "Answer:" | grep "in("
echo ""

echo "4. Preferred (expect 2 extensions)"
echo "------------------------------------"
OUTPUT=$(clingo -n 0 $CORE $SEMIRING $MONOID $FILTER ../semantics/preferred.lp $FRAMEWORK 2>/dev/null)
COUNT=$(count_extensions "$OUTPUT")
echo "Found: $COUNT extensions"
echo ""
echo "$OUTPUT" | grep -A 1 "Answer:" | grep "in("
echo ""

echo "5. Grounded (expect 1 extension: {a})"
echo "---------------------------------------"
OUTPUT=$(clingo -n 1 $CORE $SEMIRING $MONOID $FILTER ../semantics/grounded.lp $FRAMEWORK 2>/dev/null)
COUNT=$(count_extensions "$OUTPUT")
echo "Found: $COUNT extensions"
echo ""
echo "$OUTPUT" | grep -A 1 "Answer:" | grep "in("
echo ""

echo "6. Ideal (expect 1 extension: {a})"
echo "------------------------------------"
OUTPUT=$(clingo -n 0 $CORE $SEMIRING $MONOID $FILTER ../semantics/ideal.lp $FRAMEWORK 2>/dev/null)
COUNT=$(count_extensions "$OUTPUT")
echo "Found: $COUNT extensions"
echo ""
echo "$OUTPUT" | grep -A 1 "Answer:" | grep "in("
echo ""

# Test 2: Ideal Example
echo "========================================"
echo "Test 2: Ideal Semantics Specific Test"
echo "========================================"
echo ""

FRAMEWORK="aspforaba_ideal_example.lp"

echo "Ideal (expect 1 extension: {b})"
echo "---------------------------------"
OUTPUT=$(clingo -n 0 $CORE $SEMIRING $MONOID $FILTER ../semantics/ideal.lp $FRAMEWORK 2>/dev/null)
COUNT=$(count_extensions "$OUTPUT")
echo "Found: $COUNT extensions"
echo ""
echo "$OUTPUT" | grep -A 1 "Answer:" | grep "in("
echo ""

echo "Preferred (expect 2 extensions: {b,d}, {b,c})"
echo "-----------------------------------------------"
OUTPUT=$(clingo -n 0 $CORE $SEMIRING $MONOID $FILTER ../semantics/preferred.lp $FRAMEWORK 2>/dev/null)
COUNT=$(count_extensions "$OUTPUT")
echo "Found: $COUNT extensions"
echo ""
echo "$OUTPUT" | grep -A 1 "Answer:" | grep "in("
echo ""

echo "========================================="
echo "Debug test complete!"
echo "========================================="
