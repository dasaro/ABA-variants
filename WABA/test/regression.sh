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

# ---------------------------------------------------------------------------
# N1-N3: neutral elements and their roles.
#
# A neutral element is neutral FOR AN OPERATION. An element neutral for (x) has
# no reason to be inert with respect to (+) or to a budget comparison, and the
# three guards below exist because of that. These tests pin the three.
# ---------------------------------------------------------------------------

echo "== N1: delta = e_otimes is transparent in a conjunction, for every algebra =="
# probe <- a, d  with w(d)=5 and `a` an unweighted assumption, so wt(probe) = delta (x) 5.
printf 'assumption(a). contrary(a,ca).\nhead(rd,d). weight(d,5).\nhead(r1,probe). body(r1,a). body(r1,d).\n' > "$tmp/mix.lp"
wt() { # wt <semiring> <policy>
  "$CLINGO" --warn=no-atom-undefined -n 0 -c beta=0 "$ROOT/core/base.lp" \
    "$ROOT/semiring/$1.lp" "$ROOT/defaults/$2.lp" "$ROOT/constraint/no_discard.lp" \
    "$ROOT/filter/standard.lp" "$ROOT/semantics/cf.lp" "$tmp/mix.lp" 2>&1 \
    | grep -aoE 'supported_with_weight\(probe,[^)]*\)' | sed 's/.*,//;s/)//' | sort -u | head -1
}
for s in godel tropical arctic bottleneck_cost lukasiewicz; do
  check "neutral: delta (x) 5 = 5 for $s" 5 "$(wt $s neutral)"
done

echo "== N2: delta = top buys recovery by ANNIHILATING declared weights =="
# The aba policy sets delta = #sup, which is the (x)-annihilator of the three
# algebras whose e_otimes is not the top. Recovery is restored, but a derivation
# through any unweighted assumption stops feeling the weights it passes through.
for s in godel lukasiewicz;                       do check "aba: weight survives in $s" 5      "$(wt $s aba)"; done
for s in tropical arctic bottleneck_cost;         do check "aba: weight annihilated in $s" '#sup' "$(wt $s aba)"; done

echo "== N2b: recovery under delta = e_otimes holds iff e_otimes is unaffordable =="
# Two mutually attacking UNWEIGHTED assumptions: classically 2 stable extensions.
# Under `neutral` an all-unweighted derivation weighs e_otimes, which beta=0 already
# affords whenever e_otimes <= 0 -- true for tropical/arctic (0) and bottleneck (-inf).
printf 'assumption(p). contrary(p,cp).\nassumption(q). contrary(q,cq).\nhead(r1,cp). body(r1,q).\nhead(r2,cq). body(r2,p).\n' > "$tmp/pos.lp"
rec() { # rec <semiring> <policy>
  "$CLINGO" --warn=no-atom-undefined -n 0 -c beta=0 "$ROOT/core/base.lp" \
    "$ROOT/semiring/$1.lp" "$ROOT/defaults/$2.lp" "$ROOT/monoid/sum.lp" \
    "$ROOT/constraint/ub.lp" "$ROOT/filter/projection.lp" \
    "$ROOT/semantics/stable.lp" "$tmp/pos.lp" 2>&1 | models
}
check "neutral: godel recovers"        2 "$(rec godel neutral)"
check "neutral: lukasiewicz recovers"  2 "$(rec lukasiewicz neutral)"
for s in tropical arctic bottleneck_cost; do
  check "neutral: $s does NOT recover (documented)" 3 "$(rec $s neutral)"
done
for s in godel tropical arctic bottleneck_cost lukasiewicz; do
  check "aba: $s recovers" 2 "$(rec $s aba)"
done

echo "== N3: canonicity -- the D=empty guard is redundant exactly for (+,<=),(max,<=),(min,>=) =="
# Strip the `some_discard` gate so the budget condition applies to D=empty too.
# Classical extensions must then survive at every beta for the canonical pairings
# and be lost for the other three. If this section starts failing, someone has
# changed which pairings are canonical -- a published characterisation.
# First: the guard must actually BE there. Without this the rest of N3 would pass
# vacuously if someone deleted the gate from the shipped constraint files, since
# there would then be nothing for sed to strip.
for b in ub lb; do
  if grep -q 'budget(B), some_discard\.' "$ROOT/constraint/$b.lp"; then
    echo "  ok   constraint/$b.lp still carries the D=empty guard"; pass=$((pass+1))
  else
    echo "  FAIL constraint/$b.lp has LOST the D=empty guard (Prop. Canonicity relies on it)"; fail=$((fail+1))
  fi
  sed 's/^:- budget_value(C), C \(.\) B, budget(B), some_discard\./:- budget_value(C), C \1 B, budget(B)./' \
      "$ROOT/constraint/$b.lp" > "$tmp/${b}_noguard.lp"
  grep -q 'budget(B), some_discard\.' "$tmp/${b}_noguard.lp" && { echo "  FAIL could not strip the guard from $b.lp"; fail=$((fail+1)); }
done
noguard() { # noguard <monoid> <bound> <beta>
  "$CLINGO" --warn=no-atom-undefined -n 0 -c beta=$3 "$ROOT/core/base.lp" \
    "$ROOT/semiring/godel.lp" "$ROOT/defaults/aba.lp" "$ROOT/monoid/$1.lp" \
    "$tmp/$2_noguard.lp" "$ROOT/filter/projection.lp" \
    "$ROOT/semantics/stable.lp" "$tmp/pos.lp" 2>&1 | models
}
for beta in 0 3 10; do
  check "canonical (+,<=)   keeps the 2 classical extensions at beta=$beta" 2 "$(noguard sum ub  $beta)"
  check "canonical (max,<=) keeps the 2 classical extensions at beta=$beta" 2 "$(noguard max ub  $beta)"
  check "canonical (min,>=) keeps the 2 classical extensions at beta=$beta" 2 "$(noguard min lb  $beta)"
done
# the non-canonical pairings filter rather than relax, so without the guard they lose them
check "non-canonical (max,>=) loses them at beta=0"  0 "$(noguard max lb 0)"
check "non-canonical (min,<=) loses them at beta=0"  0 "$(noguard min ub 0)"
check "non-canonical (+,>=)   loses them at beta=3"  0 "$(noguard sum lb 3)"
check "non-canonical (+,>=)   is fine at beta=0 only" 2 "$(noguard sum lb 0)"

echo "== N4: the framework is a PRODUCT -- semiring x (monoid,bound) with no interference =="
# Enriched Example 3.9: ca has two derivations, so the algebras give different wt(ca)
# (godel 3, arctic 9, tropical 7, bottleneck 5, lukasiewicz 0) while wt(cb)=3 throughout.
# Each canonical pairing must then price those weights independently of which algebra
# produced them. All 15 cells are pinned; a failure means the two layers have started
# to interfere, which would invalidate the product claim in the paper.
cat > "$tmp/prod.lp" <<'FW'
assumption(a). assumption(b).
contrary(a, ca). contrary(b, cb).
head(rd, d). weight(d, 5).
head(re, e). weight(e, 3).
head(rf, f). weight(f, 2).
head(rg, g). weight(g, 6).
head(r1, ca). body(r1, b). body(r1, d). body(r1, f).
head(r2, ca). body(r2, b). body(r2, g). body(r2, e).
head(r3, c).  body(r3, a). body(r3, e).
head(r4, cb). body(r4, a). body(r4, c).
FW
has_ab() { # has_ab <semiring> <monoid> <bound> <beta>
  "$CLINGO" --warn=no-atom-undefined -n 0 -c beta=$4 "$ROOT/core/base.lp" \
    "$ROOT/semiring/$1.lp" "$ROOT/defaults/neutral.lp" "$ROOT/monoid/$2.lp" \
    "$ROOT/constraint/$3.lp" "$ROOT/filter/projection.lp" "$ROOT/semantics/stable.lp" \
    "$tmp/prod.lp" 2>&1 | grep -cE 'in\(a\).*in\(b\)|in\(b\).*in\(a\)'
}
thr() { # thr <semiring> <monoid> <bound> -> least beta at which {a,b} first appears (ub)
  for B in $(seq 0 16); do [ "$(has_ab $1 $2 $3 $B)" != "0" ] && { echo "$B"; return; }; done; echo "-"
}
lastyes() { # lastyes <semiring> min lb -> greatest beta at which {a,b} still appears
  local last="-"; for B in $(seq 0 16); do [ "$(has_ab $1 $2 $3 $B)" != "0" ] && last="$B"; done; echo "$last"
}
# wt(ca) per algebra, then the predicted thresholds: sum = wt(ca)+3, max = max(wt(ca),3)
set -- "godel 3 6 3" "arctic 9 12 9" "tropical 7 10 7" "bottleneck_cost 5 8 5" "lukasiewicz 0 3 3"
for spec in "$@"; do
  a=$(echo $spec | cut -d' ' -f1); wca=$(echo $spec | cut -d' ' -f2)
  esum=$(echo $spec | cut -d' ' -f3); emax=$(echo $spec | cut -d' ' -f4)
  check "$a: wt(ca)=$wca"                "$wca" \
    "$("$CLINGO" --warn=no-atom-undefined -n 0 -c beta=0 "$ROOT/core/base.lp" "$ROOT/semiring/$a.lp" \
        "$ROOT/defaults/neutral.lp" "$ROOT/constraint/no_discard.lp" \
        "$ROOT/semantics/cf.lp" "$tmp/prod.lp" 2>&1 \
        | grep -aoE 'attacks_with_weight\(ca,a,[^)]*\)' | sed 's/.*,//;s/)//' | sort -u | head -1)"
  check "$a x (+,<=)   threshold $esum"  "$esum" "$(thr $a sum ub)"
  check "$a x (max,<=) threshold $emax"  "$emax" "$(thr $a max ub)"
done
# (min,>=) is governed by the EASIER concession, so it collapses onto wt(cb)=3 except for
# lukasiewicz, whose eroded wt(ca)=0 takes over. Pins the weakness reading's character.
for a in godel arctic tropical bottleneck_cost; do
  check "$a x (min,>=) last-yes 3" 3 "$(lastyes $a min lb)"
done
check "lukasiewicz x (min,>=) last-yes 0" 0 "$(lastyes lukasiewicz min lb)"

echo "== N5: polarity must agree with the bound direction (semantic coherence) =="
# Give an objection a SECOND, CHEAPER derivation, i.e. support it better.
# Under a strength algebra (oplus = max) its propagated weight must be UNCHANGED.
# Under a cost algebra (oplus = min) it DROPS, so against an upper bound the
# better-supported objection has become easier to discard -- the perversity that
# makes cost+ub (and, dually, strength+lb) semantically wrong even though both
# compute perfectly well. If a strength algebra ever starts dropping here, the
# polarity argument in the paper has broken.
cat > "$tmp/one_route.lp" <<'FW'
assumption(a). contrary(a, ca).
assumption(b). contrary(b, cb).
head(p1, cheap). weight(cheap, 2).
head(p2, dear).  weight(dear, 9).
head(r1, ca). body(r1, b). body(r1, dear).
head(r3, cb). body(r3, a). body(r3, dear).
FW
cp "$tmp/one_route.lp" "$tmp/two_routes.lp"
printf 'head(r2, ca). body(r2, b). body(r2, cheap).\n' >> "$tmp/two_routes.lp"
wca() { # wca <semiring> <framework>
  "$CLINGO" --warn=no-atom-undefined -n 0 -c beta=0 "$ROOT/core/base.lp" \
    "$ROOT/semiring/$1.lp" "$ROOT/defaults/neutral.lp" "$ROOT/constraint/no_discard.lp" \
    "$ROOT/semantics/cf.lp" "$2" 2>&1 \
    | grep -aoE 'attacks_with_weight\(ca,a,[0-9]+\)' | sed 's/.*,//;s/)//' | sort -u | head -1
}
for a in godel arctic lukasiewicz; do
  check "strength $a: extra cheap route leaves wt(ca)=9" 9 "$(wca $a "$tmp/two_routes.lp")"
done
for a in tropical bottleneck_cost; do
  check "cost $a: extra cheap route drops wt(ca) 9 -> 2" 2 "$(wca $a "$tmp/two_routes.lp")"
done
# and the baseline both start from
for a in godel tropical; do
  check "$a baseline wt(ca)=9 with one route" 9 "$(wca $a "$tmp/one_route.lp")"
done

echo "== N6: recovery is SUFFICIENT on singletons, not characteristic =="
# b is attacked by a (weight 1) and by the unattacked assumption d (weight 50).
# At beta=1 the weight-1 attack IS affordable, so the hypothesis of the singleton
# corollary fails -- yet the extensions do not change, because d is in every
# extension and its attack is never affordable. Pins the counterexample the paper
# gives for why the converse does not hold.
cat > "$tmp/redundant.lp" <<'FW'
assumption(a). contrary(a, ca).
assumption(b). contrary(b, cb).
assumption(d). contrary(d, cd).
head(p1, cheap). weight(cheap, 1).
head(p2, dear).  weight(dear, 50).
head(r1, cb). body(r1, a). body(r1, cheap).
head(r2, cb). body(r2, d). body(r2, dear).
FW
nm() { "$CLINGO" --warn=no-atom-undefined -n 0 -c beta=$1 "$ROOT/core/base.lp" \
        "$ROOT/semiring/godel.lp" "$ROOT/defaults/neutral.lp" "$ROOT/monoid/max.lp" \
        "$ROOT/constraint/ub.lp" "$ROOT/filter/projection.lp" "$ROOT/semantics/stable.lp" \
        "$tmp/redundant.lp" 2>&1 | models; }
check "beta=0 (nothing affordable): 1 extension" 1 "$(nm 0)"
check "beta=1 (a weight-1 attack IS affordable) still 1 extension" 1 "$(nm 1)"
check "beta=2: still 1 extension" 1 "$(nm 2)"
# and the sufficient direction: below the least attack weight, recovery holds exactly
check "beta=0 matches the no_discard baseline" \
  "$("$CLINGO" --warn=no-atom-undefined -n 0 -c beta=0 "$ROOT/core/base.lp" "$ROOT/semiring/godel.lp" \
     "$ROOT/defaults/neutral.lp" "$ROOT/constraint/no_discard.lp" "$ROOT/filter/projection.lp" \
     "$ROOT/semantics/stable.lp" "$tmp/redundant.lp" 2>&1 | models)" "$(nm 0)"

echo
echo "==== $pass passed, $fail failed ===="
[ "$fail" -eq 0 ]
