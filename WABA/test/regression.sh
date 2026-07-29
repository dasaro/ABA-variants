#!/usr/bin/env bash
# Regression tests for the 2026-07 soundness fixes.
#
#   D1/D4  defense semantics are CLASSICAL (weight-blind, no budget) + pin no-discards
#   D2     no_discard is the exact ABA-recovery knob (not ub with beta=0)
#   D3     derivation cycles are rejected (well-foundedness guard)
#   D5     Lukasiewicz aba default = #sup (bare-assumption attacks un-discardable)
#
# Usage:  bash test/regression.sh        (run from the WABA/ root or anywhere)
# Exit code 0 = all pass, 1 = a failure.

set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLINGO="${CLINGO:-clingo}"
REF="$ROOT/examples/reference/aspforaba_journal_example.lp"
WABA="python3 $ROOT/bin/waba"
pass=0; fail=0
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# compose(semiring policy constraint semantics framework [extra...]) -> runs clingo
compose() {
  local sem="$1" pol="$2" con="$3" semantics="$4" fw="$5"; shift 5
  "$CLINGO" --warn=no-atom-undefined -n 0 "$@" \
    "$ROOT/core/base.lp" "$ROOT/semiring/$sem.lp" "$ROOT/defaults/$pol.lp" \
    "$ROOT/constraint/$con.lp" "$ROOT/filter/standard.lp" \
    "$ROOT/semantics/$semantics.lp" "$fw" 2>&1
}
models() { grep -aoE 'Models[ ]*: [0-9]+' | grep -oE '[0-9]+' | head -1; }

check() { # check "desc" expected actual
  if [ "$2" = "$3" ]; then echo "  ok   $1"; pass=$((pass+1));
  else echo "  FAIL $1 — expected [$2] got [$3]"; fail=$((fail+1)); fi
}

echo "== D1: classical defense reproduces the ABA reference =="
check "stable = 2"     2 "$(compose godel aba no_discard stable     "$REF" | models)"
check "admissible = 7" 7 "$(compose godel aba no_discard admissible "$REF" | models)"
check "complete = 3"   3 "$(compose godel aba no_discard complete   "$REF" | models)"

echo "== D1: admissible is weight-blind (identical across all 5 semirings) =="
for s in godel tropical arctic bottleneck_cost lukasiewicz; do
  check "admissible/$s = 7" 7 "$(compose $s aba no_discard admissible "$REF" | models)"
done

echo "== D1: admissible is budget-INVARIANT (an undefended attacker stays out at every beta) =="
printf 'assumption(x). contrary(x,cx). assumption(p). weight(p,5). contrary(p,dp). head(r1,cx). body(r1,p).\n' > "$tmp/aff.lp"
for b in 3 6 1000; do
  n="$("$CLINGO" --warn=no-atom-undefined -n 0 -c beta=$b "$ROOT/core/base.lp" "$ROOT/semiring/godel.lp" "$ROOT/defaults/legacy.lp" "$ROOT/constraint/no_discard.lp" "$ROOT/filter/standard.lp" "$ROOT/semantics/admissible.lp" "$tmp/aff.lp" 2>&1 | grep -c 'in(x)')"
  check "in(x) never admissible at beta=$b" 0 "$n"
done

echo "== D4: defense semantics never discard (pinned no-discards) =="
n="$("$CLINGO" --warn=no-atom-undefined -n 0 -c beta=1000 "$ROOT/core/base.lp" "$ROOT/semiring/tropical.lp" "$ROOT/defaults/legacy.lp" "$ROOT/monoid/sum.lp" "$ROOT/constraint/ub.lp" "$ROOT/filter/standard.lp" "$ROOT/semantics/admissible.lp" "$REF" 2>&1 | grep -c 'discarded_attack(')"
check "no discarded_attack in any admissible model" 0 "$n"

echo "== D1/restrict: bin/waba rejects defense + a budget mode =="
out="$($WABA run --semantics admissible --budget-mode ub --objective sum-min --beta 100 --framework "$REF" 2>&1)"
case "$out" in *"are classical and take no budget"*) echo "  ok   rejected with guidance"; pass=$((pass+1));; *) echo "  FAIL not rejected: $out"; fail=$((fail+1));; esac

echo "== D2: no_discard is the exact ABA recovery (stable = 2) =="
check "no_discard stable = 2" 2 "$(compose godel aba no_discard stable "$REF" | models)"

echo "== D3: derivation cycles are rejected; acyclic frameworks are accepted =="
printf 'budget(100). assumption(a). contrary(a,ca). assumption(b). contrary(b,cb).\nhead(r1,p). body(r1,q). head(r2,q). body(r2,p). head(r3,ca). body(r3,b).\n' > "$tmp/cyc.lp"
printf 'budget(100). assumption(a). contrary(a,ca). assumption(b). contrary(b,cb).\nhead(r1,p). body(r1,a). head(r2,cb). body(r2,p).\n' > "$tmp/acyc.lp"
cyc="$(compose godel aba no_discard stable "$tmp/cyc.lp" | grep -aoE 'UNSATISFIABLE|SATISFIABLE' | head -1)"
acyc="$(compose godel aba no_discard stable "$tmp/acyc.lp" | grep -aoE 'UNSATISFIABLE|SATISFIABLE' | head -1)"
check "cyclic framework rejected"   UNSATISFIABLE "$cyc"
check "acyclic framework accepted"  SATISFIABLE   "$acyc"

echo "== D5: Lukasiewicz bare-assumption attack is un-discardable under aba =="
printf 'budget(100000). assumption(a). contrary(a,b). assumption(b). contrary(b,cb).\n' > "$tmp/luk.lp"
n="$("$CLINGO" --warn=no-atom-undefined -n 0 -c beta=100000 "$ROOT/core/base.lp" "$ROOT/semiring/lukasiewicz.lp" "$ROOT/defaults/aba.lp" "$ROOT/monoid/sum.lp" "$ROOT/constraint/ub.lp" "$ROOT/filter/standard.lp" "$ROOT/semantics/stable.lp" "$tmp/luk.lp" 2>&1 | grep -c 'discarded_attack(b,a')"
check "b->a never discarded at beta=100000" 0 "$n"

echo "== wABA BUDGETED ADMISSIBLE (structured inconsistency budget) =="
budadm() { "$CLINGO" --warn=no-atom-undefined -n 0 -c beta="$1" "$ROOT/core/base.lp" "$ROOT/semiring/$2.lp" "$ROOT/defaults/aba.lp" "$ROOT/filter/standard.lp" "$ROOT/semantics/admissible_budgeted.lp" "$3" 2>&1; }
# A1: beta=0 recovers classical admissible (7 on the reference), across the strength semirings
for s in godel arctic lukasiewicz; do
  check "beta=0 == classical admissible (7) / $s" 7 "$(budadm 0 $s "$REF" | models)"
done
# beta grows => strictly more admissible sets (the budget does real work)
check "reference beta=1000 > classical (budget admits undefended)" 11 "$(budadm 1000 godel "$REF" | models)"
# polarity guard: cost semirings rejected
for s in tropical bottleneck_cost; do
  check "cost semiring $s rejected (UNSAT)" UNSATISFIABLE "$(budadm 0 $s "$REF" | grep -aoE 'UNSATISFIABLE|SATISFIABLE' | head -1)"
done
# A2 monoid-awareness: two strength-4 objections SUM to 8, so {t1,t2} admissible only at beta>=8
printf 'assumption(t1). contrary(t1,o1).\nassumption(t2). contrary(t2,o2).\nassumption(s1). weight(s1,4). contrary(s1,cs1). head(r1,o1). body(r1,s1).\nassumption(s2). weight(s2,4). contrary(s2,cs2). head(r2,o2). body(r2,s2).\n' > "$tmp/agg.lp"
check "both t1,t2 NOT admissible at beta=6 (sum 8, not per-attack 4)" 0 "$(budadm 6 godel "$tmp/agg.lp" | grep -acE 'in\(t1\).*in\(t2\)|in\(t2\).*in\(t1\)')"
check "both t1,t2 admissible at beta=8" 1 "$(budadm 8 godel "$tmp/agg.lp" | grep -acE 'in\(t1\).*in\(t2\)|in\(t2\).*in\(t1\)')"
# A5 faithfulness: an un-counterable maximal (#sup) objection is never overrulable
printf 'assumption(t). contrary(t,obj).\nassumption(o). contrary(o,co). head(r1,obj). body(r1,o).\n' > "$tmp/sup.lp"
check "un-counterable #sup objection never admits t (beta=1e6)" 0 "$(budadm 1000000 godel "$tmp/sup.lp" | grep -c 'in(t)')"

echo "== wABA FULL DUNNE DEF 6 (shared internal+external budget) =="
dun() { "$CLINGO" --warn=no-atom-undefined -n 0 --project -c beta="$1" "$ROOT/core/base.lp" "$ROOT/semiring/$2.lp" "$ROOT/defaults/aba.lp" "$ROOT/filter/standard.lp" "$ROOT/semantics/$3.lp" "$4" 2>&1; }
# A1: beta=0 recovers classical admissible (7) / complete (3)
for s in godel arctic lukasiewicz; do
  check "dunne admissible beta=0 == classical (7) / $s" 7 "$(dun 0 $s admissible_dunne "$REF" | models)"
done
check "dunne complete beta=0 == classical (3)" 3 "$(dun 0 godel complete_dunne "$REF" | models)"
# EXTERNAL defence: m attacked by g from an out-assumption e (strength 7) — admissible at beta>=7
printf 'assumption(m). contrary(m,g).\nassumption(e). weight(e,7). contrary(e,ce). head(r1,g). body(r1,e).\n' > "$tmp/ext.lp"
check "external threat: m NOT admissible at beta=6" no  "$(dun 6 godel admissible_dunne "$tmp/ext.lp" | grep -qa 'in(m)' && echo YES || echo no)"
check "external threat: m admissible at beta=7"     YES "$(dun 7 godel admissible_dunne "$tmp/ext.lp" | grep -qa 'in(m)' && echo YES || echo no)"
# INTERNAL repair: a,b mutually attack (strength 5 each) — {a,b} jointly admissible only at beta>=10
printf 'assumption(a). weight(a,5). contrary(a,ca).\nassumption(b). weight(b,5). contrary(b,cb).\nhead(r1,ca). body(r1,b). head(r2,cb). body(r2,a).\n' > "$tmp/int.lp"
check "internal repair: {a,b} NOT joint at beta=9" 0 "$(dun 9 godel admissible_dunne "$tmp/int.lp" | grep -acE 'in\(a\).*in\(b\)|in\(b\).*in\(a\)')"
check "internal repair: {a,b} joint at beta=10"    1 "$(dun 10 godel admissible_dunne "$tmp/int.lp" | grep -acE 'in\(a\).*in\(b\)|in\(b\).*in\(a\)')"
# cost semirings rejected
check "dunne cost semiring rejected (tropical)" UNSATISFIABLE "$(dun 0 tropical admissible_dunne "$REF" | grep -aoE 'UNSATISFIABLE|SATISFIABLE' | head -1)"
# bin/waba surface: budgeted-admissible deduped + guards
check "bin/waba budgeted-admissible beta=0 = 7" 7 "$(python3 "$ROOT/bin/waba" run --semantics budgeted-admissible --semiring godel --default-policy aba --beta 0 --framework "$REF" 2>/dev/null | grep -cE '^Answer:')"
case "$(python3 "$ROOT/bin/waba" run --semantics budgeted-admissible --semiring tropical --beta 10 --framework "$REF" 2>&1 | tail -1)" in
  *"STRENGTH semiring"*) echo "  ok   bin/waba rejects cost semiring for budgeted-defence"; pass=$((pass+1));;
  *) echo "  FAIL bin/waba did not reject cost semiring"; fail=$((fail+1));;
esac

echo "== exact set-inclusion semantics via the CLI (no duplicate optima) =="
# grounded is the subset-LEAST complete extension: exactly ONE on the reference, reported once.
# (The former cardinality-#minimize encoding printed the unique optimum twice: "Models : 2".)
check "grounded reports exactly 1 extension" 1 \
  "$(python3 "$ROOT/bin/waba" run --semantics grounded --semiring godel --default-policy aba --framework "$REF" 2>/dev/null | grep -acE '^Answer:')"
check "grounded is {a}" "in(a)" \
  "$(python3 "$ROOT/bin/waba" run --semantics grounded --semiring godel --default-policy aba --framework "$REF" 2>/dev/null | grep -aoE '^in\(a\)' | head -1)"
check "preferred still reports 2" 2 \
  "$(python3 "$ROOT/bin/waba" run --semantics preferred --semiring godel --default-policy aba --framework "$REF" 2>/dev/null | grep -acE '^Answer:')"

echo "== every documented semiring is selectable from the CLI =="
for s in godel tropical arctic bottleneck_cost lukasiewicz godel_low tropical_high; do
  check "--semiring $s runs" 2 \
    "$(python3 "$ROOT/bin/waba" run --semantics stable --semiring $s --default-policy aba --framework "$REF" 2>/dev/null | grep -acE '^Answer:')"
done

echo "== Lukasiewicz otimes-identity law (a #sup premise must NOT inflate the derivation) =="
# otimes identity is k: k (x) 300 = max(0, k+300-k) = 300. Under the `aba` policy an
# unweighted assumption is #sup, so this is reachable in ordinary use.
printf 'assumption(u). contrary(u,cu).\nassumption(w). weight(w,300). contrary(w,cw).\nhead(r1,conj). body(r1,u). body(r1,w).\nbudget(0).\n' > "$tmp/luk_id.lp"
check "#sup (x) 300 = 300 (identity preserved)" "supported_with_weight(conj,300)" \
  "$("$CLINGO" --warn=no-atom-undefined -n 1 -c beta=0 "$ROOT/core/base.lp" "$ROOT/semiring/lukasiewicz.lp" "$ROOT/defaults/aba.lp" "$ROOT/constraint/no_discard.lp" "$ROOT/filter/standard.lp" "$ROOT/semantics/cf.lp" "$tmp/luk_id.lp" 2>&1 | grep -aoE 'supported_with_weight\(conj,[^)]*\)' | head -1)"
printf 'assumption(x). contrary(x,cx).\nweight(p,900). head(f1,p). weight(q,900). head(f2,q).\nhead(r,t). body(r,p). body(r,q).\nbudget(0).\n' > "$tmp/luk_er.lp"
check "900 (x) 900 = 800 (erosion intact)" "supported_with_weight(t,800)" \
  "$("$CLINGO" --warn=no-atom-undefined -n 1 -c beta=0 "$ROOT/core/base.lp" "$ROOT/semiring/lukasiewicz.lp" "$ROOT/defaults/legacy.lp" "$ROOT/constraint/no_discard.lp" "$ROOT/filter/standard.lp" "$ROOT/semantics/cf.lp" "$tmp/luk_er.lp" 2>&1 | grep -aoE 'supported_with_weight\(t,[^)]*\)' | head -1)"

echo
echo "==== $pass passed, $fail failed ===="
[ "$fail" -eq 0 ]
