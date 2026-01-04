#!/bin/bash
# Comprehensive test suite for WABA semantics vs ASPforABA
# Tests all implemented semantics on the ASPforABA journal example

CORE="../core/base.lp"
SEMIRING="../semiring/godel.lp"
CONSTRAINT="../constraint/ub_max.lp"
FILTER="../filter/standard.lp"
FRAMEWORK="aspforaba_journal_example.lp"

echo "========================================"
echo "WABA ASPforABA Semantics Test Suite"
echo "Framework: Journal Example (Lehtonen et al. 2021)"
echo "========================================"
echo ""

# Test results tracker
PASS=0
FAIL=0

# Helper to count extensions
count_ext() {
    echo "$1" | grep -c "Answer:" || echo "0"
}

# Test 1: Conflict-Free
echo "[1/6] Conflict-Free Semantics"
OUT=$(clingo -n 0 --opt-mode=optN -c beta=0 $CORE $SEMIRING $CONSTRAINT $FILTER ../semantics/cf.lp $FRAMEWORK 2>/dev/null)
COUNT=$(count_ext "$OUT")
echo "      Found: $COUNT extensions"
if [ "$COUNT" -ge 7 ]; then echo "      ✓ PASS (≥7, includes all admissible)"; ((PASS++)); else echo "      ✗ FAIL"; ((FAIL++)); fi
echo ""

# Test 2: Admissible
echo "[2/6] Admissible Semantics"
OUT=$(clingo -n 0 -c beta=0 $CORE $SEMIRING $CONSTRAINT $FILTER ../semantics/admissible.lp $FRAMEWORK 2>/dev/null)
COUNT=$(count_ext "$OUT")
EXPECTED=7
echo "      Found: $COUNT extensions (expected $EXPECTED)"
if [ "$COUNT" -eq $EXPECTED ]; then echo "      ✓ PASS"; ((PASS++)); else echo "      ✗ FAIL"; ((FAIL++)); fi
echo ""

# Test 3: Complete
echo "[3/6] Complete Semantics"
OUT=$(clingo -n 0 -c beta=0 $CORE $SEMIRING $CONSTRAINT $FILTER ../semantics/complete.lp $FRAMEWORK 2>/dev/null)
COUNT=$(count_ext "$OUT")
EXPECTED=3
echo "      Found: $COUNT extensions (expected $EXPECTED)"
echo "      Expected: {a}, {a,b}, {a,c,d}"
if [ "$COUNT" -eq $EXPECTED ]; then echo "      ✓ PASS"; ((PASS++)); else echo "      ✗ FAIL"; ((FAIL++)); fi
echo ""

# Test 4: Stable
echo "[4/6] Stable Semantics"
OUT=$(clingo -n 0 -c beta=0 $CORE $SEMIRING $CONSTRAINT $FILTER ../semantics/stable.lp $FRAMEWORK 2>/dev/null)
COUNT=$(count_ext "$OUT")
EXPECTED=2
echo "      Found: $COUNT extensions (expected $EXPECTED)"
echo "      Expected: {a,b}, {a,c,d}"
if [ "$COUNT" -eq $EXPECTED ]; then echo "      ✓ PASS"; ((PASS++)); else echo "      ✗ FAIL"; ((FAIL++)); fi
echo ""

# Test 5: Grounded
echo "[5/6] Grounded Semantics"
OUT=$(clingo -n 1 -c beta=0 $CORE $SEMIRING $CONSTRAINT $FILTER ../semantics/grounded.lp $FRAMEWORK 2>/dev/null)
COUNT=$(count_ext "$OUT")
EXPECTED=1
echo "      Found: $COUNT extension (expected $EXPECTED)"
echo "      Expected: {a}"
if [ "$COUNT" -eq $EXPECTED ]; then echo "      ✓ PASS"; ((PASS++)); else echo "      ✗ FAIL"; ((FAIL++)); fi
echo ""

# Test 6: Preferred
echo "[6/6] Preferred Semantics"
OUT=$(clingo -n 0 --heuristic=Domain --enum-mode=domRec -c beta=0 $CORE $SEMIRING $CONSTRAINT $FILTER ../semantics/preferred.lp $FRAMEWORK 2>/dev/null)
COUNT=$(count_ext "$OUT")
EXPECTED=2
echo "      Found: $COUNT extensions (expected $EXPECTED)"
echo "      Expected: {a,b}, {a,c,d}"
if [ "$COUNT" -eq $EXPECTED ]; then echo "      ✓ PASS"; ((PASS++)); else echo "      ✗ FAIL"; ((FAIL++)); fi
echo ""

# Summary
echo "========================================"
echo "Test Summary"
echo "========================================"
echo "PASS: $PASS/6"
echo "FAIL: $FAIL/6"
echo ""
if [ $FAIL -eq 0 ]; then
    echo "✓ ALL TESTS PASSED"
    exit 0
else
    echo "✗ SOME TESTS FAILED"
    exit 1
fi
