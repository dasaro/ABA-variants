#!/bin/bash
# Compare optimization results across configurations

EXAMPLE="${1:-Examples/medical.lp}"

echo "============================================================"
echo "Optimization Comparison: $EXAMPLE"
echo "============================================================"
echo ""

analyze_opt() {
    local semiring=$1
    local monoid=$2
    
    OUTPUT=$(clingo -n 0 core_base.lp semiring/${semiring}.lp monoid/${monoid}.lp \
             filter.lp minimize_cost.lp Semantics/stable.lp $EXAMPLE 2>&1)
    
    MIN_COST=$(echo "$OUTPUT" | grep "^Optimization:" | head -1 | awk '{print $2}')
    OPT_MODELS=$(echo "$OUTPUT" | grep "^Models" | awk '{print $3}')
    
    # Extract optimal extension
    OPT_ANSWER=$(echo "$OUTPUT" | grep -A1 "^Answer:" | tail -1)
    OPT_IN=$(echo "$OPT_ANSWER" | grep -o "in([^)]*)" | sed 's/in(//' | sed 's/)//' | tr '\n' ', ' | sed 's/,$//')
    NUM_IN=$(echo "$OPT_IN" | tr ',' '\n' | grep -v '^$' | wc -l | tr -d ' ')
    
    printf "%-25s | %10s | %6s | %5s | %s\n" \
           "[$semiring + $monoid]" \
           "$MIN_COST" \
           "$OPT_MODELS" \
           "$NUM_IN" \
           "$OPT_IN"
}

echo "Configuration              | Optimal    | Opt.   | # In  | Optimal Extension Assumptions"
echo "                           | Cost       | Models | Assms |"
echo "---------------------------|------------|--------|-------|----------------------------------"

SEMIRINGS=("fuzzy" "tropical" "probabilistic" "boolean")
MONOIDS=("max" "sum" "min")

for semiring in "${SEMIRINGS[@]}"; do
    for monoid in "${MONOIDS[@]}"; do
        analyze_opt $semiring $monoid
    done
    echo "---------------------------|------------|--------|-------|----------------------------------"
done

echo ""
echo "OPTIMIZATION INSIGHTS:"
echo ""
echo "1. MINIMAL COST varies by semiring:"
echo "   • Fuzzy/Probabilistic: Cost = 100 (standard weight scale)"
echo "   • Tropical: Cost = 0 (assumptions have weight 0)"
echo "   • Boolean: Cost = 1 or 4 (binary weights)"
echo ""
echo "2. SUM vs MAX/MIN monoids:"
echo "   • MAX/MIN: Often find same optimal (maximal extension)"
echo "   • SUM: May find different optimal (minimal total cost)"
echo ""
echo "3. Optimal Models count:"
echo "   • How many extensions achieve the minimum cost"
echo "   • Higher count = more optimal solutions"
echo ""
