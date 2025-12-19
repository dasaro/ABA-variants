#!/bin/bash
# Test all semiring/monoid combinations with modular composition

set -e

WABA_DIR="."
EXAMPLE="${1:-Examples/simple.lp}"
SEMANTICS="${2:-stable}"

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "============================================================"
echo "Testing WABA Modular Composition"
echo "============================================================"
echo "Example: $EXAMPLE"
echo "Semantics: $SEMANTICS"
echo ""

# Check if example exists
if [ ! -f "$EXAMPLE" ]; then
    echo -e "${RED}Error: Example file not found: $EXAMPLE${NC}"
    exit 1
fi

# Arrays for combinations
SEMIRINGS=("fuzzy" "tropical" "probabilistic" "boolean")
MONOIDS=("max" "sum" "min")

# Counters
TOTAL=0
PASSED=0
FAILED=0

# Test each combination
echo "Testing ${#SEMIRINGS[@]} semirings × ${#MONOIDS[@]} monoids = $((${#SEMIRINGS[@]} * ${#MONOIDS[@]})) combinations"
echo "------------------------------------------------------------"

for semiring in "${SEMIRINGS[@]}"; do
    for monoid in "${MONOIDS[@]}"; do
        TOTAL=$((TOTAL + 1))

        # Build command based on semantics
        if [ "$SEMANTICS" = "naive" ]; then
            CMD="clingo -n 0 --heuristic=Domain --enum=domRec \
                 $WABA_DIR/core_base.lp \
                 $WABA_DIR/semiring/${semiring}.lp \
                 $WABA_DIR/monoid/${monoid}.lp \
                 $WABA_DIR/filter.lp \
                 $WABA_DIR/Semantics/${SEMANTICS}.lp \
                 $EXAMPLE"
        else
            CMD="clingo -n 0 \
                 $WABA_DIR/core_base.lp \
                 $WABA_DIR/semiring/${semiring}.lp \
                 $WABA_DIR/monoid/${monoid}.lp \
                 $WABA_DIR/filter.lp \
                 $WABA_DIR/Semantics/${SEMANTICS}.lp \
                 $EXAMPLE"
        fi

        # Run test (clingo exit codes: 10=SAT, 20=UNSAT, 30=UNKNOWN/SAT with -n, 0=error-free UNSAT)
        printf "%-25s " "[$semiring + $monoid]"

        OUTPUT=$($CMD 2>&1) || true  # Don't fail on non-zero exit (clingo uses 10/20/30 for success)

        # Check if output contains SATISFIABLE or UNSATISFIABLE
        if echo "$OUTPUT" | grep -q "SATISFIABLE\|UNSATISFIABLE"; then
            # Check for errors in output
            if echo "$OUTPUT" | grep -qE "ERROR|error:"; then
                echo -e "${RED}✗ FAIL (clingo error)${NC}"
                FAILED=$((FAILED + 1))
                echo "$OUTPUT" | grep -E "ERROR|error:" | head -2
            else
                # Successful execution
                echo -e "${GREEN}✓ PASS${NC}"
                PASSED=$((PASSED + 1))
            fi
        else
            echo -e "${RED}✗ FAIL (no result)${NC}"
            FAILED=$((FAILED + 1))
            echo "  Output: $OUTPUT" | head -5
        fi
    done
done

echo "------------------------------------------------------------"
echo ""
echo "============================================================"
echo "RESULTS SUMMARY"
echo "============================================================"
echo "Total tests:     $TOTAL"
echo -e "Passed:          ${GREEN}$PASSED${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "Failed:          ${RED}$FAILED${NC}"
else
    echo -e "Failed:          ${GREEN}$FAILED${NC}"
fi
echo "Success rate:    $(echo "scale=1; ($PASSED*100)/$TOTAL" | bc)%"
echo "============================================================"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All combinations work correctly!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some combinations failed${NC}"
    exit 1
fi
