#!/bin/bash
# Test WABA semantics against ASPforABA reference implementations
# Expected results documented in test framework files

set -e

CORE="../core/base.lp"
SEMIRING="../semiring/godel.lp"
MONOID="../monoid/max_minimization.lp"
FILTER="../filter/standard.lp"

echo "========================================="
echo "WABA vs ASPforABA Semantics Test Suite"
echo "========================================="
echo ""

# Test 1: Journal Example - Extension Counts
echo "Test 1: Journal Example (Extension Counts)"
echo "-------------------------------------------"

FRAMEWORK="aspforaba_journal_example.lp"

echo "Testing Admissible (expect 7 extensions)..."
clingo -n 0 $CORE $SEMIRING $MONOID $FILTER ../semantics/admissible.lp $FRAMEWORK 2>/dev/null | grep -c "SATISFIABLE" || echo "  Found: $? extensions"

echo "Testing Complete (expect 3 extensions)..."
clingo -n 0 $CORE $SEMIRING $MONOID $FILTER ../semantics/complete.lp $FRAMEWORK 2>/dev/null | grep -c "Answer" || echo "  Found: $? extensions"

echo "Testing Stable (expect 2 extensions)..."
clingo -n 0 $CORE $SEMIRING $MONOID $FILTER ../semantics/stable.lp $FRAMEWORK 2>/dev/null | grep -c "Answer" || echo "  Found: $? extensions"

echo "Testing Preferred (expect 2 extensions)..."
clingo -n 0 $CORE $SEMIRING $MONOID $FILTER ../semantics/preferred.lp $FRAMEWORK 2>/dev/null | grep -c "Answer" || echo "  Found: $? extensions"

echo "Testing Grounded (expect 1 extension)..."
clingo -n 1 $CORE $SEMIRING $MONOID $FILTER ../semantics/grounded.lp $FRAMEWORK 2>/dev/null | grep -c "Answer" || echo "  Found: $? extensions"

echo "Testing Ideal (expect 1 extension)..."
clingo -n 0 $CORE $SEMIRING $MONOID $FILTER ../semantics/ideal.lp $FRAMEWORK 2>/dev/null | grep -c "Answer" || echo "  Found: $? extensions"

echo ""
echo "Test 1: Complete"
echo ""

# Test 2: Simple Example - Credulous/Skeptical Queries
echo "Test 2: Simple Example (Qualitative Tests)"
echo "-------------------------------------------"

FRAMEWORK="aspforaba_simple_example.lp"

echo "Testing Complete semantics..."
clingo -n 0 $CORE $SEMIRING $MONOID $FILTER ../semantics/complete.lp $FRAMEWORK 2>/dev/null | grep "in(b)" && echo "  ✓ b is in some extension" || echo "  ✗ b not found"

echo ""
echo "Test 2: Complete"
echo ""

# Test 3: Ideal Example
echo "Test 3: Ideal Semantics Example"
echo "--------------------------------"

FRAMEWORK="aspforaba_ideal_example.lp"

echo "Testing Ideal (expect {b})..."
clingo -n 0 $CORE $SEMIRING $MONOID $FILTER ../semantics/ideal.lp $FRAMEWORK 2>/dev/null | grep "in(b)" && echo "  ✓ Found b in ideal extension" || echo "  ✗ b not found"

echo "Testing Preferred (expect 2 extensions: {b,d}, {b,c})..."
clingo -n 0 $CORE $SEMIRING $MONOID $FILTER ../semantics/preferred.lp $FRAMEWORK 2>/dev/null | grep -c "Answer" || echo "  Found: $? extensions"

echo ""
echo "Test 3: Complete"
echo ""

echo "========================================="
echo "All tests complete!"
echo "========================================="
