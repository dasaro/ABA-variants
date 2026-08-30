#!/usr/bin/env bash
# Focused CLI contract for the common beta-sigma pipeline.

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WABA=(python3 "$ROOT/bin/waba" run)
pass=0
fail=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

check() {
  if [ "$2" = "$3" ]; then
    echo "  ok   $1"
    pass=$((pass + 1))
  else
    echo "  FAIL $1 -- expected [$2], got [$3]"
    fail=$((fail + 1))
  fi
}

models() { grep -ac '^Answer:'; }

# a attacks b with cost 1. At beta=1, D={} and D={a->b} are both affordable.
# In particular P1 preferred must retain {a} from the first reduct and {a,b}
# from the second; global maximality across reducts would incorrectly drop {a}.
cat > "$tmp/one_attack.lp" <<'EOF'
assumption(a). weight(a,1). contrary(a,ca).
assumption(b). contrary(b,cb).
head(r1,cb). body(r1,a).
EOF

run_budgeted() {
  "${WABA[@]}" --framework "$tmp/one_attack.lp" --semantics "$1" \
    --semiring godel --default-policy neutral --objective sum-min \
    --budget-mode ub --beta 1 --opt-mode ignore 2>/dev/null
}

echo "== every semantics uses the same external beta-sigma modules =="
for spec in \
  "cf 4" "stable 2" "admissible 4" "complete 2" "preferred 2" \
  "grounded 2" "naive 3" "semi-stable 2" "stage 2" "ideal 2" "eager 2"; do
  semantics="${spec% *}"
  expected="${spec#* }"
  check "$semantics accepts the shared budget and deduplicates D witnesses" \
    "$expected" "$(run_budgeted "$semantics" | models)"

  command="$("${WABA[@]}" --framework "$tmp/one_attack.lp" --semantics "$semantics" \
    --objective sum-min --budget-mode ub --beta 1 --print-command 2>/dev/null)"
  case "$command" in
    *"monoid/sum.lp"*"optimize/minimize.lp"*"constraint/ub.lp"*)
      echo "  ok   $semantics composes the common monoid/objective/bound"
      pass=$((pass + 1)) ;;
    *)
      echo "  FAIL $semantics did not compose the common budget modules"
      fail=$((fail + 1)) ;;
  esac
done

preferred="$(run_budgeted preferred)"
check "preferred keeps the D={} preferred extension {a}" 1 \
  "$(printf '%s\n' "$preferred" | grep -ac 'in(a) out(b)')"
check "preferred keeps the D={a->b} preferred extension {a,b}" 1 \
  "$(printf '%s\n' "$preferred" | grep -acE 'in\(a\) in\(b\)|in\(b\) in\(a\)')"

echo "== enumeration is semantic; objective optimisation is explicit =="
for spec in \
  "cf 4 3" "stable 2 1" "admissible 4 2" "complete 2 1" "preferred 2 1" \
  "grounded 2 1" "naive 3 2" "semi-stable 2 1" "stage 2 1" "ideal 2 1" \
  "eager 2 1"; do
  semantics="$(printf '%s\n' "$spec" | cut -d' ' -f1)"
  full="$(printf '%s\n' "$spec" | cut -d' ' -f2)"
  optimal="$(printf '%s\n' "$spec" | cut -d' ' -f3)"

  default_run="$("${WABA[@]}" --framework "$tmp/one_attack.lp" \
    --semantics "$semantics" --semiring godel --default-policy neutral \
    --objective sum-min --budget-mode ub --beta 1 2>/dev/null)"
  optimal_run="$("${WABA[@]}" --framework "$tmp/one_attack.lp" \
    --semantics "$semantics" --semiring godel --default-policy neutral \
    --objective sum-min --budget-mode ub --beta 1 --opt-mode optN 2>/dev/null)"

  check "$semantics defaults to the full existential beta-sigma union" \
    "$full" "$(printf '%s\n' "$default_run" | models)"
  check "$semantics optimises only after explicit --opt-mode optN" \
    "$optimal" "$(printf '%s\n' "$optimal_run" | models)"
done

echo "== the same semantics pipeline works under the canonical lower bound =="
for spec in \
  "cf 4" "stable 2" "admissible 4" "complete 2" "preferred 2" \
  "grounded 2" "naive 3" "semi-stable 2" "stage 2" "ideal 2" "eager 2"; do
  semantics="${spec% *}"
  expected="${spec#* }"
  actual="$("${WABA[@]}" --framework "$tmp/one_attack.lp" --semantics "$semantics" \
    --semiring godel --default-policy neutral --objective min-min \
    --budget-mode lb --beta 1 --opt-mode ignore 2>/dev/null | models)"
  check "$semantics uses the shared min+lb profile" "$expected" "$actual"
done

echo "== no budget and --aba-recovery both mean no_discard =="
for semantics in cf stable admissible complete preferred grounded naive semi-stable stage ideal eager; do
  plain="$("${WABA[@]}" --framework "$tmp/one_attack.lp" --semantics "$semantics" \
    --print-command 2>/dev/null)"
  recovery="$("${WABA[@]}" --framework "$tmp/one_attack.lp" --semantics "$semantics" \
    --aba-recovery --print-command 2>/dev/null)"
  case "$plain" in
    *"constraint/no_discard.lp"*) pass=$((pass + 1)); echo "  ok   $semantics/no-budget uses no_discard" ;;
    *) fail=$((fail + 1)); echo "  FAIL $semantics/no-budget did not use no_discard" ;;
  esac
  case "$recovery" in
    *"constraint/no_discard.lp"*) pass=$((pass + 1)); echo "  ok   $semantics/recovery uses no_discard" ;;
    *) fail=$((fail + 1)); echo "  FAIL $semantics/recovery did not use no_discard" ;;
  esac
done

echo "== preferred parsing preserves structured ASP terms and discard witnesses =="
cat > "$tmp/structured.lp" <<'EOF'
assumption(a(1)). weight(a(1),1). contrary(a(1),ca(1)).
assumption(b(f(2))). contrary(b(f(2)),cb(f(2))).
head(r1,cb(f(2))). body(r1,a(1)).
EOF
structured="$("${WABA[@]}" --framework "$tmp/structured.lp" --semantics preferred \
  --objective sum-min --budget-mode ub --beta 1 --opt-mode ignore 2>/dev/null)"
check "structured preferred still has two P1 extensions" 2 \
  "$(printf '%s\n' "$structured" | models)"
check "structured discard receipt survives pass 2" 1 \
  "$(printf '%s\n' "$structured" | grep -ac 'discarded_attack(cb(f(2)),b(f(2)),1)')"

echo "== the discard relation is fixed before sigma is evaluated =="
cat > "$tmp/fixed_context.lp" <<'EOF'
assumption(a;g).
contrary(a,ca). contrary(g,cg).
head(f2,f2). weight(f2,2).
head(f9,f9). weight(f9,9).
head(r_base,ca). body(r_base,f2).
head(r_gate,ca). body(r_gate,g). body(r_gate,f9).
EOF
fixed_cf() {
  "${WABA[@]}" --framework "$tmp/fixed_context.lp" --semantics cf \
    --semiring arctic --default-policy neutral --objective max-min \
    --budget-mode ub --beta "$1" --opt-mode ignore 2>/dev/null
}
check "beta=2 cannot discard ca->a even in candidates with g out" 0 \
  "$(fixed_cf 2 | grep -ac 'in(a)')"
check "beta=9 can discard the maximal-context attack at its fixed weight" YES \
  "$(fixed_cf 9 | grep -aq 'discarded_attack(ca,a,9)' && echo YES || echo no)"

echo
echo "Passed: $pass"
echo "Failed: $fail"
test "$fail" -eq 0
