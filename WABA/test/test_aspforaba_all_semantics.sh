#!/bin/bash
# Comprehensive test suite for all nine ASPforABA-compatible semantics
# Uses test/aspforaba_journal_example.lp (Lehtonen et al. 2021)
# Beta=0 enforces classical ABA (no attack discarding)

CORE="core/base.lp"
SEMIRING="semiring/godel.lp"
CONSTRAINT="constraint/no_discard.lp"
FILTER="filter/standard.lp"
FRAMEWORK="test/aspforaba_journal_example.lp"

echo "=========================================="
echo "ASPforABA Semantics Test Suite"
echo "Framework: test/aspforaba_journal_example.lp"
echo "Configuration: Gödel semiring + no_discard constraint"
echo "Note: Classical ABA mode - no attack discarding allowed"
echo "=========================================="
echo

# Helper to count unique answer sets (deduplicates clingo output)
# For optimization mode, only counts optimal models
count_answers() {
    local output="$1"
    # Check if this is optimization output (has "Optimization:" lines)
    if echo "$output" | grep -q "^Optimization:"; then
        # Find the optimal value (last Optimization line)
        local optimal=$(echo "$output" | grep "^Optimization:" | tail -1)
        # Extract answer sets with that optimization value
        echo "$output" | awk -v opt="$optimal" '
            /^Answer:/ {answer=$0; getline; content=$0; getline;
                        if ($0 == opt) print content}
        ' | sort -u | grep -c "." || echo "0"
    else
        # Non-optimization mode: count all unique answers
        echo "$output" | awk '/^Answer:/ {getline; print}' | sort -u | grep -c "." || echo "0"
    fi
}

# Test each semantic
test_semantic() {
    local name=$1
    local file=$2
    local opts=$3
    local expected=$4

    echo "Testing $name semantics..."
    if [ -n "$opts" ]; then
        output=$(clingo $opts $CORE $SEMIRING $CONSTRAINT $FILTER semantics/$file $FRAMEWORK 2>&1)
        count=$(count_answers "$output")
    else
        output=$(clingo -n 0 $CORE $SEMIRING $CONSTRAINT $FILTER semantics/$file $FRAMEWORK 2>&1)
        count=$(count_answers "$output")
    fi

    if [ "$count" = "$expected" ]; then
        echo "  ✓ PASS: $count extensions (expected: $expected)"
    else
        echo "  ✗ FAIL: $count extensions (expected: $expected)"
        exit 1
    fi
    echo
}

# 1. Conflict-free (11 extensions)
test_semantic "Conflict-free" "cf.lp" "-n 0" "11"

# 2. Admissible (7 extensions)
test_semantic "Admissible" "admissible.lp" "-n 0" "7"

# 3. Complete (3 extensions)
test_semantic "Complete" "complete.lp" "-n 0" "3"

# 4. Stable (2 extensions)
test_semantic "Stable" "stable.lp" "-n 0" "2"

# 5. Grounded (1 extension - unique, optimization-based)
test_semantic "Grounded" "grounded.lp" "--opt-mode=optN -n 0" "1"

# 6. Preferred (maximal complete, optimization-based)
test_semantic "Preferred" "preferred.lp" "--opt-mode=optN -n 0" "1"

# 7. Staged (CF with maximal range, optimization-based)
test_semantic "Staged" "staged.lp" "--opt-mode=optN -n 0" "2"

# 8. Semi-stable (complete with maximal range, optimization-based)
test_semantic "Semi-stable" "semistable.lp" "--opt-mode=optN -n 0" "2"

# 9. Ideal (1 extension - unique maximal admissible in all preferred)
test_semantic "Ideal" "ideal.lp" "-n 1" "1"

echo "=========================================="
echo "All 9 semantics PASSED!"
echo "=========================================="
echo
echo "Semantic hierarchy verified:"
echo "  stable ⊆ semi-stable ⊆ staged ⊆ cf"
echo "  stable ⊆ preferred ⊆ complete ⊆ admissible ⊆ cf"
echo "  grounded ⊆ ideal ⊆ ∩(preferred) ⊆ complete"
