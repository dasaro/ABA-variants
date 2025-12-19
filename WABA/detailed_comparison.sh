#!/bin/bash
# Detailed comparison of enumeration vs optimization results

EXAMPLE="${1:-Examples/medical.lp}"
echo "============================================================"
echo "Detailed Analysis: $EXAMPLE"
echo "============================================================"
echo ""

analyze_detailed() {
    local semiring=$1
    local monoid=$2
    
    # Enumeration mode
    ENUM_OUT=$(clingo -n 0 core_base.lp semiring/${semiring}.lp monoid/${monoid}.lp \
               filter.lp Semantics/stable.lp $EXAMPLE 2>&1)
    
    MODELS=$(echo "$ENUM_OUT" | grep "^Models" | awk '{print $3}')
    ENUM_COSTS=$(echo "$ENUM_OUT" | grep -o "extension_cost([0-9]*)" | sed 's/extension_cost(\([0-9]*\))/\1/' | sort -nu | tr '\n' ',' | sed 's/,$//')
    
    # Optimization mode
    OPT_OUT=$(clingo -n 0 core_base.lp semiring/${semiring}.lp monoid/${monoid}.lp \
              filter.lp minimize_cost.lp Semantics/stable.lp $EXAMPLE 2>&1)
    
    MIN_COST=$(echo "$OPT_OUT" | grep "^Optimization:" | awk '{print $2}')
    OPT_MODELS=$(echo "$OPT_OUT" | grep "^Models" | awk '{print $3}')
    OPT_IN=$(echo "$OPT_OUT" | grep -A1 "^Answer: 1" | tail -1 | grep -o "in([^)]*)" | sed 's/in(//' | sed 's/)//' | tr '\n' ',' | sed 's/,$//')
    
    printf "%-25s | %6s | %-20s | %-10s | %s\n" \
           "[$semiring + $monoid]" \
           "$MODELS" \
           "$ENUM_COSTS" \
           "$MIN_COST" \
           "$OPT_IN"
}

echo "Configuration              | Models | All Costs (enum)     | Min Cost   | Optimal Extension"
echo "---------------------------|--------|----------------------|------------|----------------------------------"

SEMIRINGS=("fuzzy" "tropical" "probabilistic" "boolean")
MONOIDS=("max" "sum" "min")

for semiring in "${SEMIRINGS[@]}"; do
    for monoid in "${MONOIDS[@]}"; do
        analyze_detailed $semiring $monoid
    done
    echo "---------------------------|--------|----------------------|------------|----------------------------------"
done

echo ""
echo "KEY OBSERVATIONS:"
echo "  • Sum monoid shows multiple costs (e.g., 100,200,300,400) - aggregates all discarded attacks"
echo "  • Max/Min monoids show single costs - take max/min of discarded attacks"
echo "  • Tropical semiring assigns weight 0 to assumptions → different cost structure"
echo "  • Boolean semiring uses binary weights (0,1) → lower costs (1,2,3,4 instead of 100,200,300,400)"
echo ""
