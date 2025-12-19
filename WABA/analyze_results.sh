#!/bin/bash
# Analyze and compare results across different configurations

EXAMPLE="${1:-Examples/simple.lp}"
echo "============================================================"
echo "Results Analysis: $EXAMPLE"
echo "============================================================"
echo ""

# Function to extract results
analyze_combination() {
    local semiring=$1
    local monoid=$2
    
    OUTPUT=$(clingo -n 0 core_base.lp semiring/${semiring}.lp monoid/${monoid}.lp \
             filter.lp Semantics/stable.lp $EXAMPLE 2>&1)
    
    # Extract number of models
    MODELS=$(echo "$OUTPUT" | grep "^Models" | awk '{print $3}')
    
    # Extract all unique extension costs
    COSTS=$(echo "$OUTPUT" | grep -o "extension_cost([0-9]*)" | sed 's/extension_cost(\([0-9]*\))/\1/' | sort -u | tr '\n' ',' | sed 's/,$//')
    
    # Extract first answer set's in() assumptions
    FIRST_IN=$(echo "$OUTPUT" | grep -A1 "^Answer: 1" | tail -1 | grep -o "in([^)]*)" | sed 's/in(//' | sed 's/)//' | tr '\n' ',' | sed 's/,$//')
    
    # Count successful attacks in first answer
    ATTACKS=$(echo "$OUTPUT" | grep -A1 "^Answer: 1" | tail -1 | grep -o "attacks_successfully_with_weight" | wc -l | tr -d ' ')
    
    printf "%-25s | %6s | %-15s | %-8s | %s\n" \
           "[$semiring + $monoid]" \
           "$MODELS" \
           "$COSTS" \
           "$ATTACKS" \
           "$FIRST_IN"
}

echo "Configuration              | Models | Extension Costs | Attacks  | In-Assumptions (1st model)"
echo "---------------------------|--------|-----------------|----------|----------------------------------"

SEMIRINGS=("fuzzy" "tropical" "probabilistic" "boolean")
MONOIDS=("max" "sum" "min")

for semiring in "${SEMIRINGS[@]}"; do
    for monoid in "${MONOIDS[@]}"; do
        analyze_combination $semiring $monoid
    done
done

echo ""
echo "============================================================"
echo "Legend:"
echo "  Models        : Total number of stable extensions found"
echo "  Extension Costs: Unique cost values across all extensions"
echo "  Attacks      : Successful attacks in first extension"
echo "  In-Assumptions: Assumptions included in first extension"
echo "============================================================"
