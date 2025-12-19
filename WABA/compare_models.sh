#!/bin/bash
# Compare specific models across key configurations

EXAMPLE="${1:-Examples/medical.lp}"

echo "============================================================"
echo "Model-by-Model Comparison: $EXAMPLE"
echo "============================================================"
echo ""

compare_config() {
    local label=$1
    local semiring=$2
    local monoid=$3
    
    echo "=== $label ==="
    OUTPUT=$(clingo -n 3 core_base.lp semiring/${semiring}.lp monoid/${monoid}.lp \
             filter.lp Semantics/stable.lp $EXAMPLE 2>&1)
    
    echo "$OUTPUT" | grep -A1 "^Answer:" | while read line; do
        if [[ $line =~ ^Answer:.*$ ]]; then
            echo "$line"
        elif [[ ! -z "$line" ]]; then
            # Extract only in() and extension_cost()
            IN=$(echo "$line" | grep -o "in([^)]*)" | sed 's/in(/  • /' | sed 's/)//')
            COST=$(echo "$line" | grep -o "extension_cost([^)]*)" | sed 's/extension_cost(/Cost: /' | sed 's/)//')
            echo "$IN"
            echo "  $COST"
        fi
    done
    echo ""
}

# Compare key differences
compare_config "Fuzzy + MAX (original WABA)" "fuzzy" "max"
compare_config "Fuzzy + SUM (additive costs)" "fuzzy" "sum"
compare_config "Tropical + MAX (different weight prop)" "tropical" "max"
compare_config "Boolean + SUM (binary weights)" "boolean" "sum"

echo "============================================================"
echo "KEY DIFFERENCES:"
echo ""
echo "1. MONOID EFFECT (Fuzzy + MAX vs SUM):"
echo "   • MAX: Same cost across models (max of discarded attacks)"
echo "   • SUM: Different costs (sum of all discarded attacks)"
echo ""
echo "2. SEMIRING EFFECT (Fuzzy vs Tropical):"
echo "   • Fuzzy: Assumptions inherit declared weights (100)"
echo "   • Tropical: Assumptions get weight 0 → cost=0"
echo ""
echo "3. WEIGHT SCALE (Fuzzy vs Boolean):"
echo "   • Fuzzy: Weights in [0,100] → costs like 100,200,300"
echo "   • Boolean: Binary weights {0,1} → costs like 1,2,3"
echo "============================================================"
