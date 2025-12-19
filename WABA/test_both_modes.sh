#!/bin/bash
# Test both enumeration and optimization modes

WABA_DIR="."
EXAMPLE="${1:-Examples/simple.lp}"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "============================================================"
echo "Testing Enumeration vs Optimization Modes"
echo "============================================================"
echo "Example: $EXAMPLE"
echo ""

SEMIRINGS=("fuzzy" "tropical" "probabilistic" "boolean")
MONOIDS=("max" "sum" "min")

ENUM_PASS=0
OPT_PASS=0
TOTAL=0

for semiring in "${SEMIRINGS[@]}"; do
    for monoid in "${MONOIDS[@]}"; do
        TOTAL=$((TOTAL + 1))
        printf "%-25s " "[$semiring + $monoid]"
        
        # Test enumeration mode
        ENUM_OUT=$(clingo -n 0 \
                   $WABA_DIR/core_base.lp \
                   $WABA_DIR/semiring/${semiring}.lp \
                   $WABA_DIR/monoid/${monoid}.lp \
                   $WABA_DIR/filter.lp \
                   $WABA_DIR/Semantics/stable.lp \
                   $EXAMPLE 2>&1)
        
        if echo "$ENUM_OUT" | grep -q "SATISFIABLE\|UNSATISFIABLE"; then
            printf "${GREEN}ENUM:✓${NC} "
            ENUM_PASS=$((ENUM_PASS + 1))
        else
            printf "${RED}ENUM:✗${NC} "
        fi
        
        # Test optimization mode
        OPT_OUT=$(clingo -n 0 \
                  $WABA_DIR/core_base.lp \
                  $WABA_DIR/semiring/${semiring}.lp \
                  $WABA_DIR/monoid/${monoid}.lp \
                  $WABA_DIR/filter.lp \
                  $WABA_DIR/minimize_cost.lp \
                  $WABA_DIR/Semantics/stable.lp \
                  $EXAMPLE 2>&1)
        
        if echo "$OPT_OUT" | grep -q "OPTIMUM FOUND\|UNSATISFIABLE"; then
            printf "${GREEN}OPT:✓${NC}\n"
            OPT_PASS=$((OPT_PASS + 1))
        else
            printf "${RED}OPT:✗${NC}\n"
            echo "  Output: $OPT_OUT" | grep -E "ERROR|error:" | head -2
        fi
    done
done

echo ""
echo "============================================================"
echo "RESULTS"
echo "============================================================"
echo "Total combinations:  $TOTAL"
echo -e "Enumeration passed:  ${GREEN}$ENUM_PASS/$TOTAL${NC}"
echo -e "Optimization passed: ${GREEN}$OPT_PASS/$TOTAL${NC}"
echo ""

if [ $ENUM_PASS -eq $TOTAL ] && [ $OPT_PASS -eq $TOTAL ]; then
    echo -e "${GREEN}✓ Both modes work for all combinations!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
