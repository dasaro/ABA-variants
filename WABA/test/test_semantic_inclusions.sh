#!/bin/bash

# Test script to verify semantic inclusion relations
# Tests that: stable ⊆ semi-stable ⊆ preferred ⊆ complete ⊆ admissible ⊆ conflict-free
#             grounded ⊆ complete
#             stable ⊆ staged ⊆ conflict-free
#             stable ⊆ naive ⊆ conflict-free
#             grounded ⊆ ideal ⊆ complete

set -e

FRAMEWORK="$1"
if [ -z "$FRAMEWORK" ]; then
    echo "Usage: $0 <framework.lp>"
    exit 1
fi

echo "========================================="
echo "Testing semantic inclusions on: $FRAMEWORK"
echo "========================================="
echo ""

BASE_CMD="clingo -n 0 core/base.lp semiring/godel.lp constraint/ub_max.lp filter/standard.lp"

# Function to extract extensions (sets of in/1 predicates)
extract_extensions() {
    local semantic=$1
    local n_flag=$2

    if [ "$semantic" = "grounded" ] || [ "$semantic" = "ideal" ]; then
        n_flag="-n 1"
    else
        n_flag="-n 0"
    fi

    clingo $n_flag core/base.lp semiring/godel.lp constraint/ub_max.lp \
        filter/standard.lp semantics/${semantic}.lp "$FRAMEWORK" 2>/dev/null | \
        grep "^in(" | sort | tr '\n' ' ' | sed 's/in(/\n/g' | sed 's/)//g' | \
        grep -v "^$" | sort | uniq
}

# Function to normalize extension (sort atoms)
normalize_ext() {
    echo "$1" | tr ' ' '\n' | sort | tr '\n' ' ' | sed 's/ *$//'
}

# Function to check if extension set A ⊆ extension set B
check_subset() {
    local sem_a=$1
    local sem_b=$2
    local exts_a=$3
    local exts_b=$4

    echo "Checking: $sem_a ⊆ $sem_b"

    if [ -z "$exts_a" ]; then
        echo "  ✓ $sem_a is empty, trivially ⊆ $sem_b"
        return 0
    fi

    local violation=0
    while IFS= read -r ext_a; do
        [ -z "$ext_a" ] && continue
        local norm_a=$(normalize_ext "$ext_a")
        local found=0

        while IFS= read -r ext_b; do
            [ -z "$ext_b" ] && continue
            local norm_b=$(normalize_ext "$ext_b")

            if [ "$norm_a" = "$norm_b" ]; then
                found=1
                break
            fi
        done <<< "$exts_b"

        if [ $found -eq 0 ]; then
            echo "  ✗ VIOLATION: {$norm_a} ∈ $sem_a but ∉ $sem_b"
            violation=1
        fi
    done <<< "$exts_a"

    if [ $violation -eq 0 ]; then
        echo "  ✓ All $sem_a extensions are in $sem_b"
    fi

    return $violation
}

# Collect extensions for all semantics
echo "Collecting extensions for all semantics..."
echo ""

echo "--- Conflict-Free ---"
CF_EXTS=$(extract_extensions "cf")
CF_COUNT=$(echo "$CF_EXTS" | grep -c "." || echo "0")
echo "Found $CF_COUNT extensions"
echo "$CF_EXTS" | head -5
[ $CF_COUNT -gt 5 ] && echo "..."
echo ""

echo "--- Admissible ---"
ADM_EXTS=$(extract_extensions "admissible")
ADM_COUNT=$(echo "$ADM_EXTS" | grep -c "." || echo "0")
echo "Found $ADM_COUNT extensions"
echo "$ADM_EXTS" | head -5
[ $ADM_COUNT -gt 5 ] && echo "..."
echo ""

echo "--- Complete ---"
COM_EXTS=$(extract_extensions "complete")
COM_COUNT=$(echo "$COM_EXTS" | grep -c "." || echo "0")
echo "Found $COM_COUNT extensions"
echo "$COM_EXTS"
echo ""

echo "--- Grounded ---"
GRD_EXTS=$(extract_extensions "grounded")
GRD_COUNT=$(echo "$GRD_EXTS" | grep -c "." || echo "0")
echo "Found $GRD_COUNT extension(s)"
echo "$GRD_EXTS"
echo ""

echo "--- Preferred ---"
PRF_EXTS=$(extract_extensions "preferred")
PRF_COUNT=$(echo "$PRF_EXTS" | grep -c "." || echo "0")
echo "Found $PRF_COUNT extensions"
echo "$PRF_EXTS"
echo ""

echo "--- Semi-Stable ---"
SS_EXTS=$(extract_extensions "semi-stable")
SS_COUNT=$(echo "$SS_EXTS" | grep -c "." || echo "0")
echo "Found $SS_COUNT extensions"
echo "$SS_EXTS"
echo ""

echo "--- Stable ---"
STB_EXTS=$(extract_extensions "stable")
STB_COUNT=$(echo "$STB_EXTS" | grep -c "." || echo "0")
echo "Found $STB_COUNT extensions"
echo "$STB_EXTS"
echo ""

echo "--- Naive ---"
NAV_EXTS=$(extract_extensions "naive")
NAV_COUNT=$(echo "$NAV_EXTS" | grep -c "." || echo "0")
echo "Found $NAV_COUNT extensions"
echo "$NAV_EXTS"
echo ""

echo "--- Staged ---"
STG_EXTS=$(extract_extensions "staged")
STG_COUNT=$(echo "$STG_EXTS" | grep -c "." || echo "0")
echo "Found $STG_COUNT extensions"
echo "$STG_EXTS"
echo ""

echo "--- Ideal ---"
IDL_EXTS=$(extract_extensions "ideal")
IDL_COUNT=$(echo "$IDL_EXTS" | grep -c "." || echo "0")
echo "Found $IDL_COUNT extension(s)"
echo "$IDL_EXTS"
echo ""

echo "========================================="
echo "Checking inclusion relations..."
echo "========================================="
echo ""

VIOLATIONS=0

# Chain: stable ⊆ semi-stable ⊆ preferred ⊆ complete ⊆ admissible ⊆ conflict-free
check_subset "stable" "semi-stable" "$STB_EXTS" "$SS_EXTS" || VIOLATIONS=$((VIOLATIONS+1))
echo ""
check_subset "semi-stable" "preferred" "$SS_EXTS" "$PRF_EXTS" || VIOLATIONS=$((VIOLATIONS+1))
echo ""
check_subset "preferred" "complete" "$PRF_EXTS" "$COM_EXTS" || VIOLATIONS=$((VIOLATIONS+1))
echo ""
check_subset "complete" "admissible" "$COM_EXTS" "$ADM_EXTS" || VIOLATIONS=$((VIOLATIONS+1))
echo ""
check_subset "admissible" "conflict-free" "$ADM_EXTS" "$CF_EXTS" || VIOLATIONS=$((VIOLATIONS+1))
echo ""

# grounded ⊆ complete
check_subset "grounded" "complete" "$GRD_EXTS" "$COM_EXTS" || VIOLATIONS=$((VIOLATIONS+1))
echo ""

# stable ⊆ staged ⊆ conflict-free
check_subset "stable" "staged" "$STB_EXTS" "$STG_EXTS" || VIOLATIONS=$((VIOLATIONS+1))
echo ""
check_subset "staged" "conflict-free" "$STG_EXTS" "$CF_EXTS" || VIOLATIONS=$((VIOLATIONS+1))
echo ""

# stable ⊆ naive ⊆ conflict-free
check_subset "stable" "naive" "$STB_EXTS" "$NAV_EXTS" || VIOLATIONS=$((VIOLATIONS+1))
echo ""
check_subset "naive" "conflict-free" "$NAV_EXTS" "$CF_EXTS" || VIOLATIONS=$((VIOLATIONS+1))
echo ""

# grounded ⊆ ideal ⊆ complete
check_subset "grounded" "ideal" "$GRD_EXTS" "$IDL_EXTS" || VIOLATIONS=$((VIOLATIONS+1))
echo ""
check_subset "ideal" "complete" "$IDL_EXTS" "$COM_EXTS" || VIOLATIONS=$((VIOLATIONS+1))
echo ""

echo "========================================="
if [ $VIOLATIONS -eq 0 ]; then
    echo "✓ ALL INCLUSION RELATIONS VERIFIED"
else
    echo "✗ FOUND $VIOLATIONS VIOLATIONS"
fi
echo "========================================="

exit $VIOLATIONS
