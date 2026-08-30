#!/usr/bin/env bash
# Regression tests for the 2026-07 soundness fixes.
#
#   D1/D4  exact no-discard recovery and the common beta-sigma pipeline
#   D2     no_discard is the exact ABA-recovery knob (not ub with beta=0)
#   D3     derivation cycles are rejected (well-foundedness guard)
#   D5     Lukasiewicz defaults stay inside [0,k]; no_discard provides exact recovery
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

echo "== D1: the reference framework under the supported semantics =="
# These two direct checks pin the reference graph. Defence semantics are exercised below
# through the same discard layer and compared with the independent ABA oracle in GT.
check "stable = 2" 2 "$(compose godel aba no_discard stable "$REF" | models)"
check "cf = 11"    11 "$(compose godel aba no_discard cf     "$REF" | models)"

echo "== D2: no_discard is the exact ABA recovery (stable = 2) =="
check "no_discard stable = 2" 2 "$(compose godel aba no_discard stable "$REF" | models)"

echo "== D3: derivation cycles are rejected; acyclic frameworks are accepted =="
printf 'assumption(a). contrary(a,ca). assumption(b). contrary(b,cb).\nhead(r1,p). body(r1,q). head(r2,q). body(r2,p). head(r3,ca). body(r3,b).\n' > "$tmp/cyc.lp"
printf 'assumption(a). contrary(a,ca). assumption(b). contrary(b,cb).\nhead(r1,p). body(r1,a). head(r2,cb). body(r2,p).\n' > "$tmp/acyc.lp"
# NOTE: the framework PRECONDITIONS (flat, well-founded, w a function into the carrier) moved
# out of core/base.lp on 2026-07-31. They are hypotheses of the definition, not part of the
# semantics, so a paper states them once and the BOUNDARIES enforce them: bin/waba for the CLI,
# the bundled validate.lp pre-flight in the web playground. These checks therefore assert that
# the boundary refuses the framework and NAMES the offender -- which an ASP constraint could
# never do; it could only return an unexplained UNSATISFIABLE.
cyc="$(python3 "$ROOT/bin/waba" run --framework "$tmp/cyc.lp" --semantics stable 2>&1 | grep -c 'WELL-FOUNDED')"
acyc="$(compose godel aba no_discard stable "$tmp/acyc.lp" | grep -aoE 'UNSATISFIABLE|SATISFIABLE' | head -1)"
check "cyclic framework rejected at the boundary" 1 "$cyc"
check "acyclic framework accepted"  SATISFIABLE   "$acyc"

echo "== D5: Lukasiewicz aba default is the carrier top k =="
printf 'budget(100000). assumption(a). contrary(a,b). assumption(b). contrary(b,cb).\n' > "$tmp/luk.lp"
luk_discard() {
  "$CLINGO" --warn=no-atom-undefined -n 0 -c beta="$1" "$ROOT/core/base.lp" \
    "$ROOT/semiring/lukasiewicz.lp" "$ROOT/defaults/aba.lp" "$ROOT/monoid/sum.lp" \
    "$ROOT/constraint/ub.lp" "$ROOT/filter/standard.lp" "$ROOT/semantics/stable.lp" \
    "$tmp/luk.lp" 2>&1 | grep -c 'discarded_attack(b,a,1000)'
}
check "k-priced attack is not affordable below k" 0 "$(luk_discard 999)"
check "k-priced attack is affordable at k"       1 "$(luk_discard 1000)"

echo "== one beta-sigma pipeline for all direct semantics =="
bs() { # bs <beta> <semiring> <semantics> <framework> [constraint] [monoid] [policy]
  "$CLINGO" --warn=no-atom-undefined -n 0 --project -c beta="$1" \
    "$ROOT/core/base.lp" "$ROOT/semiring/$2.lp" "$ROOT/defaults/${7:-neutral}.lp" \
    "$ROOT/monoid/${6:-sum}.lp" "$ROOT/constraint/${5:-ub}.lp" \
    "$ROOT/filter/projection.lp" "$ROOT/semantics/$3.lp" "$4" 2>&1
}

check "reference admissible recovery = 7" 7 \
  "$(compose godel aba no_discard admissible "$REF" | models)"
check "reference complete recovery = 3" 3 \
  "$(compose godel aba no_discard complete "$REF" | models)"

# Smallest P1 fixture: a -> b has weight 1. beta=1 existentially unions the
# ordinary extensions of the intact and attack-free reducts.
cat > "$tmp/p1.lp" <<'FW'
assumption(a). weight(a,1). contrary(a,ca).
assumption(b). weight(b,1). contrary(b,cb).
head(r1,cb). body(r1,a).
FW
for spec in "cf 3 4" "stable 1 2" "admissible 2 4" "complete 1 2"; do
  sem=$(echo "$spec" | cut -d' ' -f1)
  at0=$(echo "$spec" | cut -d' ' -f2)
  at1=$(echo "$spec" | cut -d' ' -f3)
  check "$sem: beta=0 intact reduct" "$at0" "$(bs 0 godel "$sem" "$tmp/p1.lp" | models)"
  check "$sem: beta=1 union of reducts" "$at1" "$(bs 1 godel "$sem" "$tmp/p1.lp" | models)"
done

# A SUM budget is global: both weight-5 attacks can be removed only at beta=10.
cat > "$tmp/internal.lp" <<'FW'
assumption(a). weight(a,5). contrary(a,ca).
assumption(b). weight(b,5). contrary(b,cb).
head(r1,ca). body(r1,b). head(r2,cb). body(r2,a).
FW
check "two attacks cannot both be removed at beta=9" 0 \
  "$(bs 9 godel admissible "$tmp/internal.lp" | grep -acE 'in\(a\).*in\(b\)|in\(b\).*in\(a\)')"
check "two attacks can both be removed at beta=10" 1 \
  "$(bs 10 godel admissible "$tmp/internal.lp" | grep -acE 'in\(a\).*in\(b\)|in\(b\).*in\(a\)')"

# Pricing is fixed in Cl(A), not recomputed in the candidate.  With g out the
# candidate derives ca only through the weight-2 path, while the maximal context
# also enables the weight-9 path.  The unique ca->a discard therefore costs 9.
cat > "$tmp/fixed_weight.lp" <<'FW'
assumption(a). contrary(a,ca).
assumption(g). contrary(g,cg).
head(f2,l2). weight(l2,2).
head(f9,l9). weight(l9,9).
head(r1,ca). body(r1,l2).
head(r2,ca). body(r2,g). body(r2,l9).
:- not in(a). :- in(g).
#show supported_with_weight/2.
FW
check "candidate trace still sees ca at weight 2" "supported_with_weight(ca,2)" \
  "$(bs 9 arctic cf "$tmp/fixed_weight.lp" ub max \
      | grep -aoE 'supported_with_weight\(ca,[0-9]+\)' | sort -u | head -1)"
check "fixed ca->a attack is priced at 9" "discarded_attack(ca,a,9)" \
  "$(bs 9 arctic cf "$tmp/fixed_weight.lp" ub max \
      | grep -aoE 'discarded_attack\(ca,a,[0-9]+\)' | sort -u | head -1)"
check "beta=2 cannot buy the globally weight-9 attack" 0 \
  "$(bs 2 arctic cf "$tmp/fixed_weight.lp" ub max | models)"
check "beta=9 can buy the globally weight-9 attack" 1 \
  "$(bs 9 arctic cf "$tmp/fixed_weight.lp" ub max | models)"

echo "== preferred maximality is local to one fixed discard witness =="
cat > "$tmp/pref_filter.lp" <<'FW'
candidate(1). member(1,a).
candidate(2).
candidate(3). member(3,a). discarded_member(3,cb,b,1).
candidate(4). member(4,a). member(4,b). discarded_member(4,cb,b,1).
FW
check "intact {a} and reduced {a,b} are both preferred" "keep(1) keep(4)" \
  "$("$CLINGO" --warn=none -n 1 "$ROOT/semantics/subset_maximal_filter.lp" \
      "$tmp/pref_filter.lp" 2>/dev/null | grep -aoE 'keep\([0-9]+\)' | sort | tr '\n' ' ' | sed 's/ $//')"

echo "== every documented semiring is selectable from the CLI =="
for s in godel tropical arctic bottleneck_cost lukasiewicz godel_low tropical_high; do
  check "--semiring $s runs" 2 \
    "$(python3 "$ROOT/bin/waba" run --semantics stable --semiring $s --default-policy aba --framework "$REF" 2>/dev/null | grep -acE '^Answer:')"
done

echo "== Lukasiewicz otimes-identity law (the aba default is k) =="
# The aba default is the in-carrier identity k: k (x) 300 = max(0, k+300-k) = 300.
printf 'assumption(u). contrary(u,cu).\nassumption(w). weight(w,300). contrary(w,cw).\nhead(r1,conj). body(r1,u). body(r1,w).\nbudget(0).\n' > "$tmp/luk_id.lp"
check "k (x) 300 = 300 (identity preserved)" "supported_with_weight(conj,300)" \
  "$("$CLINGO" --warn=no-atom-undefined -n 1 -c beta=0 "$ROOT/core/base.lp" "$ROOT/semiring/lukasiewicz.lp" "$ROOT/defaults/aba.lp" "$ROOT/constraint/no_discard.lp" "$ROOT/filter/standard.lp" "$ROOT/semantics/cf.lp" "$tmp/luk_id.lp" 2>&1 | grep -aoE 'supported_with_weight\(conj,[^)]*\)' | head -1)"
printf 'assumption(x). contrary(x,cx).\nweight(p,900). head(f1,p). weight(q,900). head(f2,q).\nhead(r,t). body(r,p). body(r,q).\nbudget(0).\n' > "$tmp/luk_er.lp"
check "900 (x) 900 = 800 (erosion intact)" "supported_with_weight(t,800)" \
  "$("$CLINGO" --warn=no-atom-undefined -n 1 -c beta=0 "$ROOT/core/base.lp" "$ROOT/semiring/lukasiewicz.lp" "$ROOT/defaults/neutral.lp" "$ROOT/constraint/no_discard.lp" "$ROOT/filter/standard.lp" "$ROOT/semantics/cf.lp" "$tmp/luk_er.lp" 2>&1 | grep -aoE 'supported_with_weight\(t,[^)]*\)' | head -1)"

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
  "$CLINGO" --warn=no-atom-undefined -n 0 --project -c beta=0 "$ROOT/core/base.lp" \
    "$ROOT/semiring/$1.lp" "$ROOT/defaults/$2.lp" "$ROOT/constraint/no_discard.lp" \
    "$ROOT/filter/standard.lp" "$ROOT/semantics/cf.lp" "$tmp/mix.lp" 2>&1 \
    | grep -aoE 'supported_with_weight\(probe,[^)]*\)' | sed 's/.*,//;s/)//' | sort -u | head -1
}
for s in godel tropical arctic bottleneck_cost lukasiewicz; do
  check "neutral: delta (x) 5 = 5 for $s" 5 "$(wt $s neutral)"
done

echo "== N2: aba defaults remain algebra-specific =="
# Gödel uses its identity #sup and Lukasiewicz uses its in-carrier identity k, so a
# declared co-premise survives. Tropical, arctic and bottleneck-cost use #sup as an
# annihilator, so a derivation through an unweighted assumption stops feeling that weight.
for s in godel lukasiewicz;                       do check "aba: weight survives in $s" 5      "$(wt $s aba)"; done
for s in tropical arctic bottleneck_cost;         do check "aba: weight annihilated in $s" '#sup' "$(wt $s aba)"; done

echo "== N2b: on the direct mutual-attack fixture, recovery tracks e_otimes affordability =="
# Two mutually attacking UNWEIGHTED assumptions: classically 2 stable extensions.
# Under `neutral` an all-unweighted derivation weighs e_otimes, which beta=0 already
# affords whenever e_otimes <= 0 -- true for tropical/arctic (0) and bottleneck (-inf).
printf 'assumption(p). contrary(p,cp).\nassumption(q). contrary(q,cq).\nhead(r1,cp). body(r1,q).\nhead(r2,cq). body(r2,p).\n' > "$tmp/pos.lp"
rec() { # rec <semiring> <policy>
  "$CLINGO" --warn=no-atom-undefined -n 0 --project -c beta=0 "$ROOT/core/base.lp" \
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
  if grep -qE ':- budget_value\(C\).*some_discard\.' "$ROOT/constraint/$b.lp"; then
    echo "  ok   constraint/$b.lp still carries the D=empty guard"; pass=$((pass+1))
  else
    echo "  FAIL constraint/$b.lp has LOST the D=empty guard (Prop. Canonicity relies on it)"; fail=$((fail+1))
  fi
  sed 's/\(^:- budget_value(C).*\), some_discard\./\1./' \
      "$ROOT/constraint/$b.lp" > "$tmp/${b}_noguard.lp"
  grep -qE ':- budget_value\(C\).*some_discard\.' "$tmp/${b}_noguard.lp" && { echo "  FAIL could not strip the guard from $b.lp"; fail=$((fail+1)); }
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

echo "== N7: defence uses the same algebra-independent discard layer =="
cat > "$tmp/leak.lp" <<'FW'
assumption(a). contrary(a,ca).
assumption(b). contrary(b,cb).
head(w1,l1). weight(l1,20).
head(w2,l2). weight(l2,30).
head(r1,ca). body(r1,b). body(r1,l1).
head(r2,cb). body(r2,a). body(r2,l2).
FW
for algebra in godel arctic lukasiewicz tropical bottleneck_cost; do
  check "$algebra: identical weights give 3 admissible extensions at beta=30" 3 \
    "$(bs 30 "$algebra" admissible "$tmp/leak.lp" | models)"
  check "$algebra: both attacks removable at beta=50" 4 \
    "$(bs 50 "$algebra" admissible "$tmp/leak.lp" | models)"
done

echo "== N8: recoverability is a property of (delta, bound), and of the SEMANTICS =="
# Two mutually attacking UNWEIGHTED assumptions, so delta drives every attack weight.
printf 'assumption(p). contrary(p,cp).\nassumption(q). contrary(q,cq).\nhead(r1,cp). body(r1,q).\nhead(r2,cq). body(r2,p).\n' > "$tmp/unw.lp"
nmod() { # nmod <semiring> <policy> <semantics> <constraint> <beta> [monoid]
  local extra=""; [ -n "${6:-}" ] && extra="$ROOT/monoid/$6.lp"
  "$CLINGO" --warn=no-atom-undefined -n 0 --project -c beta=$5 "$ROOT/core/base.lp" \
    "$ROOT/semiring/$1.lp" "$ROOT/defaults/$2.lp" $extra "$ROOT/constraint/$4.lp" \
    "$ROOT/filter/projection.lp" "$ROOT/semantics/$3.lp" "$tmp/unw.lp" 2>&1 | models
}
check "classical stable = 2" 2 "$(nmod godel aba stable no_discard 0)"
# (a) delta at 0 or the order bottom: NO beta >= 0 recovers under an upper bound
for spec in "arctic neutral" "tropical neutral" "bottleneck_cost neutral"; do
  a=$(echo $spec | cut -d' ' -f1); pol=$(echo $spec | cut -d' ' -f2)
  for b in 0 1 100 1000000; do
    n="$(nmod $a $pol stable ub $b sum)"
    if [ "$n" = "2" ]; then echo "  FAIL $a/$pol recovered at beta=$b under ub (expected never)"; fail=$((fail+1));
    else pass=$((pass+1)); fi
  done
  echo "  ok   $a/$pol never recovers under (sum,ub), beta in {0,1,100,1e6}"
done
# (b) but the SAME configurations recover under a lower bound
for spec in "arctic neutral" "tropical neutral"; do
  a=$(echo $spec | cut -d' ' -f1); pol=$(echo $spec | cut -d' ' -f2)
  check "$a/$pol recovers under (min,lb) at beta=1" 2 "$(nmod $a $pol stable lb 1 min)"
done
check "bottleneck_cost/neutral recovers under (min,lb) at beta=0" 2 \
  "$(nmod bottleneck_cost neutral stable lb 0 min)"
# (c) cf and stable DO feel it (the weight-blind semantics that did not were removed)
for sem in cf stable; do
  base="$(nmod bottleneck_cost neutral $sem no_discard 0)"
  got="$(nmod bottleneck_cost neutral $sem ub 0 sum)"
  if [ "$base" = "$got" ]; then echo "  FAIL $sem unexpectedly matched classical ($base)"; fail=$((fail+1));
  else echo "  ok   $sem diverges from classical under the pathological config ($base vs $got)"; pass=$((pass+1)); fi
done

echo "== S1: tree vs set support -- idempotence decides whether they differ =="
# The core defines a weight as the (+)-best over derivation TREES, so (x) folds each leaf
# OCCURRENCE. setsupport.lp folds the DISTINCT leaves of a chosen tree instead. The two must
# coincide exactly when (x) is idempotent (godel, bottleneck_cost) and may differ otherwise.
printf 'assumption(f0). contrary(f0,n0). weight(f0,105).\nassumption(f1). contrary(f1,n1). weight(f1,223).\nassumption(f2). contrary(f2,n2). weight(f2,357).\nhead(r0,m0). body(r0,f0). body(r0,f1).\nhead(r1,m1). body(r1,f1). body(r1,f2).\nhead(r2,q). body(r2,m0). body(r2,m1).\nquery_atom(q).\n:- assumption(X), not in(X).\n' > "$tmp/share.lp"
treew() { "$CLINGO" --warn=none -n 1 --outf=0 -c beta=0 "$ROOT/core/base.lp" "$ROOT/semiring/$1.lp" \
    "$ROOT/defaults/neutral.lp" "$ROOT/constraint/no_discard.lp" "$ROOT/semantics/cf.lp" \
    "$tmp/share.lp" 2>/dev/null | tr ' ' '\n' | grep -oE 'supported_with_weight\(q,[-0-9]+\)' | head -1; }
setw() { "$CLINGO" --warn=none --opt-mode=opt -n 0 --outf=0 -c beta=0 "$ROOT/core/base.lp" \
    "$ROOT/semiring/$1.lp" "$ROOT/defaults/neutral.lp" "$ROOT/constraint/no_discard.lp" \
    "$ROOT/semantics/cf.lp" "$ROOT/setsupport.lp" "$tmp/share.lp" 2>/dev/null \
    | tr ' ' '\n' | grep -oE 'set_weight\([-0-9]+\)' | tail -1; }
# additive algebras emit no set_weight atom: the sum lives only in the objective (subset-sum
# grounding measured 10.5s -> 0.04s on 120 facts), so their value is the LAST Optimization line
setopt() { "$CLINGO" --warn=none --opt-mode=opt -n 0 --outf=0 -c beta=0 "$ROOT/core/base.lp" \
    "$ROOT/semiring/$1.lp" "$ROOT/defaults/neutral.lp" "$ROOT/constraint/no_discard.lp" \
    "$ROOT/semantics/cf.lp" "$ROOT/setsupport.lp" "$tmp/$2" 2>/dev/null \
    | grep -oE 'Optimization ?: ?-?[0-9]+' | tail -1 | grep -oE '[-0-9]+$'; }
# f1 is shared: the tree counts it twice (105+223+223+357), the set once (105+223+357).
check "tropical tree counts the shared leaf twice" "supported_with_weight(q,908)" "$(treew tropical)"
check "tropical set counts it once"                "685"               "$(setopt tropical share.lp)"
# idempotent (x): duplicates collapse, so the two agree by construction.
check "godel tree == set"            "supported_with_weight(q,105)" "$(treew godel)"
check "godel set"                    "set_weight(105)"              "$(setw godel)"
check "bottleneck tree == set"       "supported_with_weight(q,357)" "$(treew bottleneck_cost)"
check "bottleneck set"               "set_weight(357)"              "$(setw bottleneck_cost)"
# A SECOND fixture with two alternative proofs. The one above has a single derivation tree, so
# the (+) step is vacuous and the run passes even with `-n 1` -- which is how a real bug hid:
# set_weight comes from an OPTIMISATION, and `-n 1` reports the first model, not the best.
# Here proof B is better (3+17=20) than proof A (32+17+3=52), so a non-optimal run reads 52.
printf 'assumption(a1). contrary(a1,x1). weight(a1,3).\nassumption(a2). contrary(a2,x2). weight(a2,17).\nassumption(a4). contrary(a4,x4). weight(a4,32).\nhead(p0,m0). body(p0,a2). body(p0,a1).\nhead(p1,m1). body(p1,a2).\nhead(p2,m2). body(p2,a4).\nhead(qa,q). body(qa,m2). body(qa,m0).\nhead(qb,q). body(qb,m1). body(qb,m0).\nquery_atom(q).\n:- assumption(X), not in(X).\n' > "$tmp/share2.lp"
check "set support optimises over proofs, not first-model" "20" "$(setopt tropical share2.lp)"
# and the run must actually PROVE optimality, not merely print a value
check "the set-support run reaches OPTIMUM FOUND" 1 \
  "$("$CLINGO" --warn=none --opt-mode=opt -n 0 --outf=0 -c beta=0 "$ROOT/core/base.lp" \
      "$ROOT/semiring/tropical.lp" "$ROOT/defaults/neutral.lp" "$ROOT/constraint/no_discard.lp" \
      "$ROOT/semantics/cf.lp" "$ROOT/setsupport.lp" "$tmp/share2.lp" 2>/dev/null \
     | grep -c 'OPTIMUM FOUND')"
# dedup can only REMOVE (x)-summands, so under a cost polarity the set value never exceeds the tree
check "set <= tree on the two-proof fixture" ok \
  "$(t=$("$CLINGO" --warn=none -n 1 --outf=0 -c beta=0 "$ROOT/core/base.lp" \
        "$ROOT/semiring/tropical.lp" "$ROOT/defaults/neutral.lp" "$ROOT/constraint/no_discard.lp" \
        "$ROOT/semantics/cf.lp" "$tmp/share2.lp" 2>/dev/null \
        | tr ' ' '\n' | grep -oE 'supported_with_weight\(q,[-0-9]+\)' | head -1 \
        | tr -dc '0-9'); \
     [ "$t" -ge 20 ] && echo ok || echo "tree=$t < set=20")"

# the advisory names the atom whose derivation reuses a leaf
# validate.lp is run on the FRAMEWORK ALONE: share.lp carries a `:- assumption(X), not in(X).`
# for the solver runs above, and in/1 does not exist under the validator, so that constraint
# would fire and make the check UNSAT.
grep -v '^:-' "$tmp/share.lp" > "$tmp/share_facts.lp"
check "validate flags the leaf reuse" "advisory(leaf_reuse,q)" \
  "$("$CLINGO" --warn=none -n 1 --outf=0 "$ROOT/validate.lp" "$tmp/share_facts.lp" 2>/dev/null \
     | tr ' ' '\n' | grep -oE 'advisory\(leaf_reuse,q\)' | head -1)"
# and an UNSAT validation must NOT read as "well formed"
check "a framework carrying an ASP constraint is refused, not passed" 1 \
  "$(python3 "$ROOT/bin/waba" run --framework "$tmp/share.lp" --semantics cf 2>&1 \
     | grep -c 'unsafe framework source')"

echo "== N9: boundary checks enforce the formal wABA signature =="
# (a) weight/2 must be a partial FUNCTION. Two weight facts for one atom split a single
#     conflict into several independently discardable attacks: the budget double-charges
#     and the same (attacker,target) pair can be discarded AND successful in one model.
printf 'assumption(a). contrary(a,b).\nassumption(b). contrary(b,cb).\nweight(b,3). weight(b,40). weight(a,5).\n' > "$tmp/dupw.lp"
out="$(python3 "$ROOT/bin/waba" run --framework "$tmp/dupw.lp" --semantics cf 2>&1)"
case "$out" in *"partial FUNCTION"*) echo "  ok   duplicate weight/2 is rejected, naming the atom"; pass=$((pass+1));;
               *) echo "  FAIL duplicate weight/2 was accepted"; fail=$((fail+1));; esac
# a single weight on the same shape must still solve
printf 'assumption(a). contrary(a,b).\nassumption(b). contrary(b,cb).\nweight(b,3). weight(a,5).\n' > "$tmp/onew.lp"
check "a single weight/2 still solves (4 projected extensions)" 4 \
  "$("$CLINGO" --warn=no-atom-undefined -n 0 --project -c beta=1000 "$ROOT/core/base.lp" "$ROOT/semiring/godel.lp" \
      "$ROOT/defaults/neutral.lp" "$ROOT/monoid/sum.lp" "$ROOT/constraint/ub.lp" \
      "$ROOT/filter/projection.lp" "$ROOT/semantics/cf.lp" "$tmp/onew.lp" 2>&1 | models)"

# One rule identifier joins exactly one head to its body. A reused identifier changes the
# conjunction represented by the facts; an orphan body is silently inert without this check.
printf 'head(r,p). head(r,q).\n' > "$tmp/multi_head.lp"
out="$(python3 "$ROOT/bin/waba" run --framework "$tmp/multi_head.lp" --semantics cf 2>&1)"
case "$out" in *"exactly ONE head"*) echo "  ok   multi-head rule identifier rejected"; pass=$((pass+1));;
               *) echo "  FAIL multi-head rule identifier accepted"; fail=$((fail+1));; esac
printf 'body(orphan,p).\n' > "$tmp/orphan_body.lp"
out="$(python3 "$ROOT/bin/waba" run --framework "$tmp/orphan_body.lp" --semantics cf 2>&1)"
case "$out" in *"declared by head/2"*) echo "  ok   orphan body identifier rejected"; pass=$((pass+1));;
               *) echo "  FAIL orphan body identifier accepted"; fail=$((fail+1));; esac

# (b) contrary/2 is a total function on assumptions, as required by the ABA definition.
printf 'assumption(a).\n' > "$tmp/missing_contrary.lp"
out="$(python3 "$ROOT/bin/waba" run --framework "$tmp/missing_contrary.lp" --semantics cf 2>&1)"
case "$out" in *"TOTAL on assumptions"*) echo "  ok   missing contrary/2 is rejected"; pass=$((pass+1));;
               *) echo "  FAIL missing contrary/2 was accepted"; fail=$((fail+1));; esac
printf 'assumption(a). contrary(a,ca). contrary(a,other_ca).\n' > "$tmp/multi_contrary.lp"
out="$(python3 "$ROOT/bin/waba" run --framework "$tmp/multi_contrary.lp" --semantics cf 2>&1)"
case "$out" in *"must be FUNCTIONAL"*) echo "  ok   multiple contraries are rejected"; pass=$((pass+1));;
               *) echo "  FAIL multiple contraries were accepted"; fail=$((fail+1));; esac

# (c) an UNBOUND beta is rejected under ub/lb. clingo orders every integer strictly BELOW
#     a symbolic constant, so `C > beta` never fires (ub silently unbounded) and `C < beta`
#     always fires (lb silently collapses to no_discard) -- silent, and in OPPOSITE
#     directions. no_discard must remain usable without beta, since it ignores the budget.
printf 'assumption(p). contrary(p,cp).\nassumption(q). contrary(q,cq).\nhead(r1,cp). body(r1,q).\nhead(r2,cq). body(r2,p).\n' > "$tmp/nb.lp"
# An unbound beta is now unreachable through the wrapper rather than rejected inside it:
# --beta is an argparse int and buildSolverArgs always emits -c beta=N, so the symbolic-constant
# hazard (clingo orders every integer BELOW a symbolic constant, so ub goes silently unbounded
# and lb silently collapses to no_discard) cannot arise from a supported invocation.
for con in ub lb; do
  mon=sum; [ "$con" = lb ] && mon=min
  out="$(python3 "$ROOT/bin/waba" run --framework "$tmp/nb.lp" --semantics cf \
          --budget-mode $con --objective ${mon}-min --opt-mode ignore 2>&1)"
  case "$out" in *"require --beta"*|*"requires --beta"*)
      echo "  ok   a budgeted run without --beta is refused under $con"; pass=$((pass+1));;
    *) echo "  FAIL beta was left symbolic under $con"; fail=$((fail+1));; esac
  # ...and when it IS given, it is always grounded with -c.
  out="$(python3 "$ROOT/bin/waba" run --framework "$tmp/nb.lp" --semantics cf \
          --budget-mode $con --objective ${mon}-min --opt-mode ignore --beta 3 --print-command 2>&1)"
  case "$out" in *"-c beta=3"*) echo "  ok   --beta is grounded with -c under $con"; pass=$((pass+1));;
                 *) echo "  FAIL beta not grounded under $con"; fail=$((fail+1));; esac
done
check "no_discard still runs without beta" 3 \
  "$("$CLINGO" --warn=no-atom-undefined -n 0 "$ROOT/core/base.lp" "$ROOT/semiring/godel.lp" \
      "$ROOT/defaults/neutral.lp" "$ROOT/constraint/no_discard.lp" "$ROOT/filter/projection.lp" \
      "$ROOT/semantics/cf.lp" "$tmp/nb.lp" 2>&1 | models)"

# (d) no shipped example trips the weight-on-derived advisory
for ex in "$ROOT"/examples/*/*.lp; do
  n="$("$CLINGO" --warn=no-atom-undefined -n 0 -c beta=1000 "$ROOT/core/base.lp" "$ROOT/semiring/godel.lp" \
       "$ROOT/defaults/neutral.lp" "$ROOT/monoid/sum.lp" "$ROOT/constraint/ub.lp" \
       "$ROOT/filter/standard.lp" "$ROOT/semantics/stable.lp" "$ex" 2>&1 | grep -ac 'weight_on_derived_dominated')"
  check "$(basename "$ex") trips no advisory" 0 "$n"
done

echo "== GT: ground truth against ASPforABA (external ABA oracle) =="
# This block checks the recovery theorem (beta-sigma = sigma(F-)) against an INDEPENDENT
# solver instead of against in-tree constants. ASPforABA's encodings take the same assumption/contrary/
# head/body facts we do, and com-aba-cred.dl is the complete-extension encoding whose
# query filter (`:- not supported(X), query(X).`) is vacuous when no query/1 is given,
# so it enumerates. Run with clingo directly, not the python driver.
ASPFORABA="${ASPFORABA:-/Users/fdasaro/Downloads/aspforaba/encodings}"
if [ ! -f "$ASPFORABA/stb-aba-enum.dl" ]; then
  echo "  SKIP  ASPforABA not found at $ASPFORABA (set ASPFORABA=... to enable)"
else
  # ASPforABA ships no ADMISSIBLE encoding in encodings/ (the ICCMA'23 track needs only
  # CO/ST/PR), but src/aspforaba/encoder.py on the master branch does. Reproduced verbatim
  # below so the admissible check is against THEIR encoding, not one of ours. Cross-checked:
  # COMMON+STABLE_ADD and COMMON+ADMISSIBLE_ADD+COMPLETE_ADD reproduce the counts that
  # encodings/stb-aba-enum.dl and encodings/com-aba-cred.dl give.
  cat > "$tmp/asp_common.lp" <<'ASPEOF'
{ in(X) : assumption(X) }.
out(X) :- not in(X), assumption(X).
supported(X) :- assumption(X), in(X).
supported(X) :- head(R,X), triggered_by_in(R).
triggered_by_in(R) :- head(R,_), supported(X) : body(R,X).
:- in(X), contrary(X,Y), supported(Y).
defeated(X) :- supported(Y), contrary(X,Y).
#show in/1.
ASPEOF
  cat > "$tmp/asp_adm.lp" <<'ASPEOF'
derived_from_undefeated(X) :- assumption(X), not defeated(X).
derived_from_undefeated(X) :- head(R,X), triggered_by_undefeated(R).
triggered_by_undefeated(R) :- head(R,_), derived_from_undefeated(X) : body(R,X).
attacked_by_undefeated(X) :- contrary(X,Y), derived_from_undefeated(Y).
:- in(X), attacked_by_undefeated(X).
ASPEOF
  # canonical extension set: one sorted, comma-joined line per extension, deduplicated
  norm() { awk '/^Answer/{getline; s=""; for(i=1;i<=NF;i++) if($i ~ /^in\(/){gsub(/in\(|\)/,"",$i); s=s $i" "} print s}' \
           | while read -r l; do echo "$l" | tr ' ' '\n' | grep . | sort | tr '\n' ',' ; echo; done | sort -u; }
  gt()  { "$CLINGO" --warn=none -n 0 $1 "$2" 2>/dev/null | norm; }
  ours(){ "$CLINGO" --warn=no-atom-undefined -n 0 --project -c beta=0 "$ROOT/core/base.lp" \
            "$ROOT/semiring/godel.lp" "$ROOT/defaults/aba.lp" $4 "$ROOT/filter/projection.lp" \
            "$ROOT/semantics/$1.lp" "$2" 2>/dev/null | norm; }
  for fw in "$REF" "$ROOT"/examples/*/*.lp; do
    b="$(basename "$fw")"
    gt "$ASPFORABA/stb-aba-enum.dl" "$fw" > "$tmp/gt_stb"
    ours stable "$fw" 0 "$ROOT/constraint/no_discard.lp" > "$tmp/ou_stb"
    if diff -q "$tmp/gt_stb" "$tmp/ou_stb" >/dev/null; then
      echo "  ok   stable == ASPforABA on $b ($(wc -l < "$tmp/gt_stb" | tr -d " ") ext)"; pass=$((pass+1))
    else
      echo "  FAIL stable != ASPforABA on $b"; diff "$tmp/gt_stb" "$tmp/ou_stb" | head -4; fail=$((fail+1))
    fi
    gt "$ASPFORABA/com-aba-cred.dl" "$fw" > "$tmp/gt_com"
    ours complete "$fw" 0 "$ROOT/constraint/no_discard.lp" > "$tmp/ou_com"
    if diff -q "$tmp/gt_com" "$tmp/ou_com" >/dev/null; then
      echo "  ok   complete beta=0 == ASPforABA on $b ($(wc -l < "$tmp/gt_com" | tr -d " ") ext)"; pass=$((pass+1))
    else
      echo "  FAIL complete beta=0 != ASPforABA on $b"; diff "$tmp/gt_com" "$tmp/ou_com" | head -4; fail=$((fail+1))
    fi
    gt "$tmp/asp_common.lp $tmp/asp_adm.lp" "$fw" > "$tmp/gt_adm"
    ours admissible "$fw" 0 "$ROOT/constraint/no_discard.lp" > "$tmp/ou_adm"
    if diff -q "$tmp/gt_adm" "$tmp/ou_adm" >/dev/null; then
      echo "  ok   admissible beta=0 == ASPforABA on $b ($(wc -l < "$tmp/gt_adm" | tr -d ' ') ext)"; pass=$((pass+1))
    else
      echo "  FAIL admissible beta=0 != ASPforABA on $b"; diff "$tmp/gt_adm" "$tmp/ou_adm" | head -4; fail=$((fail+1))
    fi
  done
fi

echo "== N10: CLI surface defects found by the 2026-07 exploration =="
# (a) weight/2 validation was anchored to the start of a line, so a weight sharing a line
#     with another fact escaped every check and a NEGATIVE weight reached the solver.
printf 'assumption(a). weight(a, -5).\nassumption(b).\nweight(b,4).\ncontrary(b,a).\ncontrary(a,nope).\n' > "$tmp/oneline.lp"
out="$(python3 "$ROOT/bin/waba" run --framework "$tmp/oneline.lp" --show standard 2>&1)"
case "$out" in *"must be nonnegative"*) echo "  ok   negative weight rejected even when sharing a line"; pass=$((pass+1));;
               *) echo "  FAIL negative weight slipped through a shared line"; fail=$((fail+1));; esac
printf 'assumption(a). weight(a,#sup).\nassumption(b). contrary(b,a). contrary(a,z).\n' > "$tmp/onesup.lp"
out="$(python3 "$ROOT/bin/waba" run --framework "$tmp/onesup.lp" 2>&1)"
case "$out" in *"normalises authored weights to finite integers"*) echo "  ok   #sup weight rejected on a shared line"; pass=$((pass+1));;
               *) echo "  FAIL #sup weight slipped through"; fail=$((fail+1));; esac
check "a well-formed framework still runs" 2 \
  "$(python3 "$ROOT/bin/waba" run --framework "$REF" --semantics stable 2>/dev/null | grep -acE '^Answer:')"

# (a2) The five input predicates are DATA. Before this boundary check, a framework could
#      derive weight/2 from in/1, pin in/1 directly, pre-author discarded_attack/3, or add a
#      candidate-dependent integrity constraint. validate.lp sees the framework alone, so all
#      four attacks could pass that semantic pre-flight and alter the later composed program.
printf 'assumption(a). contrary(a,ca). weight(a,1) :- in(a).\n' > "$tmp/candidate_weight.lp"
out="$(python3 "$ROOT/bin/waba" run --framework "$tmp/candidate_weight.lp" --semantics cf 2>&1)"
case "$out" in *"ASP rules and constraints are not accepted"*) echo "  ok   candidate-dependent weight rule rejected"; pass=$((pass+1));;
               *) echo "  FAIL candidate-dependent weight rule reached the solver"; fail=$((fail+1));; esac
printf 'assumption(a). contrary(a,ca). in(a).\n' > "$tmp/runtime_fact.lp"
out="$(python3 "$ROOT/bin/waba" run --framework "$tmp/runtime_fact.lp" --semantics cf 2>&1)"
case "$out" in *"reserved implementation predicate"*) echo "  ok   authored in/1 rejected"; pass=$((pass+1));;
               *) echo "  FAIL authored in/1 reached the solver"; fail=$((fail+1));; esac
printf 'assumption(a). contrary(a,ca). discarded_attack(ca,a,0).\n' > "$tmp/discard_fact.lp"
out="$(python3 "$ROOT/bin/waba" run --framework "$tmp/discard_fact.lp" --semantics cf 2>&1)"
case "$out" in *"reserved implementation predicate"*) echo "  ok   authored discard receipt rejected"; pass=$((pass+1));;
               *) echo "  FAIL authored discard receipt reached the solver"; fail=$((fail+1));; esac
printf 'assumption(a). contrary(a,ca). :- out(a).\n' > "$tmp/runtime_constraint.lp"
out="$(python3 "$ROOT/bin/waba" run --framework "$tmp/runtime_constraint.lp" --semantics cf 2>&1)"
case "$out" in *"ASP rules and constraints are not accepted"*) echo "  ok   runtime-dependent constraint rejected"; pass=$((pass+1));;
               *) echo "  FAIL runtime-dependent constraint reached the solver"; fail=$((fail+1));; esac
printf 'assumption(a). contrary(a,ca). #show in/1.\n' > "$tmp/authored_show.lp"
out="$(python3 "$ROOT/bin/waba" run --framework "$tmp/authored_show.lp" --semantics cf 2>&1)"
case "$out" in *"directive '#show' is not accepted"*) echo "  ok   authored solver directive rejected"; pass=$((pass+1));;
               *) echo "  FAIL authored solver directive reached the solver"; fail=$((fail+1));; esac

cat > "$tmp/pure_facts.lp" <<'EOF'
%* in(a). weight(a,999). *%
assumption(a;f(2,"quoted.value")).
contrary(a,ca;f(2,"quoted.value"),cf).
head(r(1),ca). body(r(1),f(2,"quoted.value")).
weight(a,scale;f(2,"quoted.value"),2).
EOF
cat > "$tmp/pure_root.lp" <<'EOF'
#const scale=1.
#include "pure_facts.lp".
EOF
check "ground pooled/structured/quoted facts and includes remain accepted" 1 \
  "$(python3 "$ROOT/bin/waba" run --framework "$tmp/pure_root.lp" --semantics cf 2>/dev/null | grep -acE '^SATISFIABLE$')"

if python3 "$ROOT/test/input_boundary.py" >/dev/null; then
  echo "  ok   source-boundary unit and policy-coverage tests"; pass=$((pass+1))
else
  echo "  FAIL source-boundary unit and policy-coverage tests"; fail=$((fail+1))
fi

# (b) Lukasiewicz's bound k was unreachable from the CLI: with the default 1000 every
#     ordinary small-integer derivation erodes to 0, and a framework cannot set the
#     constant (clingo rejects redefinition). --luk-k plumbs it through.
printf 'assumption(c). contrary(c,p).\nassumption(d). contrary(d,cd).\nhead(w1,x). weight(x,3).\nhead(w2,y). weight(y,5).\nhead(r1,p). body(r1,d). body(r1,x). body(r1,y).\n' > "$tmp/luk_k.lp"
lukw() { python3 "$ROOT/bin/waba" run --framework "$tmp/luk_k.lp" --semiring lukasiewicz \
           --semantics cf --default-policy neutral --show standard ${1:+--luk-k $1} 2>&1 \
         | grep -aoE 'supported_with_weight\(p,[0-9]+\)' | sort -u | head -1; }
# k=4 was dropped: it puts the weight-5 leaf OFF the grid [0,k], where Z3 shows the algebra is
# not a semiring (0 stops annihilating, and otimes stops being associative), and the carrier
# guard in semiring/lukasiewicz.lp now rejects it. The three surviving rows keep both leaves on
# the grid, which is where the Lukasiewicz t-norm is actually defined.
check "luk k=5  -> max(0,3+5-5)=3" "supported_with_weight(p,3)" "$(lukw 5)"
check "luk k=6  -> max(0,3+5-6)=2" "supported_with_weight(p,2)" "$(lukw 6)"
check "luk k=8  -> max(0,3+5-8)=0" "supported_with_weight(p,0)" "$(lukw 8)"
check "luk default k=1000 -> 0"    "supported_with_weight(p,0)" "$(lukw '')"
# The guard itself: a leaf above k is refused rather than silently computed off-carrier.
check "luk k=4 rejects the off-grid leaf" "" "$(lukw 4)"
out="$(python3 "$ROOT/bin/waba" run --framework "$tmp/luk_k.lp" --semiring lukasiewicz \
        --semantics cf --luk-k 0 2>&1)"
case "$out" in *"must be a positive integer"*) echo "  ok   non-positive --luk-k is rejected"; pass=$((pass+1));;
               *) echo "  FAIL non-positive --luk-k was accepted"; fail=$((fail+1));; esac
check "--luk-k does not affect godel" "supported_with_weight(p,3)" \
  "$(python3 "$ROOT/bin/waba" run --framework "$tmp/luk_k.lp" --semiring godel --semantics cf \
     --default-policy neutral --show standard --luk-k 6 2>&1 | grep -aoE 'supported_with_weight\(p,[0-9]+\)' | sort -u | head -1)"

# (c) --print-command must not hand back a command that answers a different question.
#     preferred needs two solver passes; pass 1 alone returns the CANDIDATES.
out="$(python3 "$ROOT/bin/waba" run --framework "$REF" --semantics preferred \
        --budget-mode ub --objective sum-min --beta 200 --print-command 2>/dev/null)"
case "$out" in *"two passes"*) echo "  ok   --print-command flags the two-pass semantics"; pass=$((pass+1));;
               *) echo "  FAIL --print-command silently printed only pass 1"; fail=$((fail+1));; esac

# (d) --objective selects the aggregation monoid and a possible ranking direction, but pure
#     beta-sigma semantics is the existential union over every affordable reduct. Enumeration
#     is therefore the default, and optimisation is applied only after explicit optN.
opt() { python3 "$ROOT/bin/waba" run --framework "$REF" --semantics stable --budget-mode ub \
          --beta 20 --objective "$1" ${2:+--opt-mode $2} 2>&1; }
n="$(opt sum-min | grep -ac 'Optimization')"
check "--objective alone enumerates without optimising" 0 "$n"
case "$(opt sum-min optN | grep -a 'OPTIMUM')" in *"OPTIMUM FOUND"*) echo "  ok   explicit optN reports OPTIMUM FOUND"; pass=$((pass+1));;
  *) echo "  FAIL no OPTIMUM FOUND"; fail=$((fail+1));; esac
if [ "$(opt sum-min optN | grep -ac 'Optimization')" -gt 0 ]; then
  echo "  ok   explicit optN applies the objective"; pass=$((pass+1))
else
  echo "  FAIL explicit optN did not apply the objective"; fail=$((fail+1))
fi

echo "== N12: a non-integer weight is REJECTED, not silently un-priced =="
# #sum/#max/#min drop a tuple whose weight term is not integral, so a non-numeric weight made its
# attack cost nothing and become discardable at ANY budget. Measured before the guard: the string
# framework admitted 2 models at beta=0 under (sum,ub) where the integer one admitted 1.
printf 'assumption(a). assumption(b).\ncontrary(a,ca). contrary(b,cb).\nweight(wa,"heavy"). head(rwa,wa).\nhead(r1,ca). body(r1,wa).\nhead(r2,cb). body(r2,a).\n' > "$tmp/w_str.lp"
printf 'assumption(a). assumption(b).\ncontrary(a,ca). contrary(b,cb).\nweight(wa,7). head(rwa,wa).\nhead(r1,ca). body(r1,wa).\nhead(r2,cb). body(r2,a).\n' > "$tmp/w_int.lp"
printf 'assumption(a). assumption(b).\ncontrary(a,ca). contrary(b,cb).\nweight(wa,#sup). head(rwa,wa).\nhead(r1,ca). body(r1,wa).\nhead(r2,cb). body(r2,a).\n' > "$tmp/w_sup.lp"
wguard() {
  "$CLINGO" --warn=no-atom-undefined -n 0 -c beta=0 "$ROOT/core/base.lp" "$ROOT/semiring/godel.lp" \
    "$ROOT/defaults/neutral.lp" "$ROOT/monoid/sum.lp" "$ROOT/constraint/ub.lp" \
    "$ROOT/filter/projection.lp" "$ROOT/semantics/stable.lp" "$1" 2>&1
}
if python3 "$ROOT/bin/waba" run --framework "$tmp/w_str.lp" --semantics stable 2>&1 \
     | grep -aq 'non-integral weight'; then
  echo "  ok   a non-integer weight is rejected at the boundary"; pass=$((pass+1))
else
  echo "  FAIL a non-integer weight was accepted (its attack is discardable for free)"; fail=$((fail+1))
fi
check "an integer weight still solves" 1 "$(wguard "$tmp/w_int.lp" | grep -ac '^Answer:')"
# the two infinity sentinels stay legal: semiring identities are #sup/#inf and arg_weight can be
# infinite by design (see N11)
check "a #sup sentinel weight stays legal" 1 "$(wguard "$tmp/w_sup.lp" | grep -ac '^Answer:')"

echo "== N11: infinity handling in the monoid and common constraint module =="
cat > "$tmp/infleaf.lp" <<'FW'
assumption(t). contrary(t,obj).
assumption(u). contrary(u,cu).
head(f1,l). weight(l,#inf).
head(r1,obj). body(r1,u). body(r1,l).
:- not discarded_attack(obj,t,#inf).
FW
cat > "$tmp/supleaf.lp" <<'FW'
assumption(t). contrary(t,obj).
assumption(u). contrary(u,cu).
head(f1,l). weight(l,#sup).
head(r1,obj). body(r1,u). body(r1,l).
:- not discarded_attack(obj,t,#sup).
FW
for algebra in godel arctic tropical bottleneck_cost; do
  check "$algebra: #inf discard is priced by sum+ub" 4 \
    "$(bs 0 "$algebra" cf "$tmp/infleaf.lp" | models)"
  check "$algebra: #sup remains un-discardable under ub" 0 \
    "$(bs 1000 "$algebra" cf "$tmp/supleaf.lp" | models)"
done

cat > "$tmp/sum_inf.lp" <<'FW'
discarded_attack(a,b,#inf).
discarded_attack(c,d,7).
#show budget_value/1.
FW
check "sum is absorbing at #inf instead of dropping that tuple" "budget_value(#inf)" \
  "$("$CLINGO" --warn=none -n 1 "$ROOT/monoid/sum.lp" "$tmp/sum_inf.lp" 2>/dev/null \
      | grep -aoE 'budget_value\([^)]*\)' | sort -u)"

cat > "$tmp/sum_rank.lp" <<'FW'
1 { pick_inf; pick_fin } 1.
discarded_attack(a,b,#inf) :- pick_inf.
discarded_attack(c,d,7) :- pick_fin.
#show pick_inf/0.
#show pick_fin/0.
FW
sum_rank() {
  "$CLINGO" --warn=none --opt-mode=optN --quiet=1 -n 0 "$ROOT/monoid/sum.lp" \
    "$ROOT/optimize/$1.lp" "$tmp/sum_rank.lp" 2>/dev/null \
    | grep -aoE 'pick_(inf|fin)' | sort -u
}
check "sum minimization ranks #inf below a finite sum" pick_inf "$(sum_rank minimize)"
check "sum maximization ranks a finite sum above #inf" pick_fin "$(sum_rank maximize)"

echo
echo "== N12: ub/lb REJECT an unbound beta (the failure is silent and bidirectional) =="
# Documented in CLAUDE.md but unimplemented until 2026-08-01: with `beta` left an
# uninterpreted constant, clingo orders it strictly ABOVE every integer, so the comparison
# grounds and simply never fires -- ub goes silently UNBOUNDED (admits every discard) while
# lb silently collapses onto no_discard. Measured before the guard: ub returned 3 extensions
# without `-c beta` where `-c beta=0` returned 2.
cat > "$tmp/cyc.lp" <<'EOF'
assumption(a). assumption(b). contrary(a,ca). contrary(b,cb).
head(r1,ca). body(r1,b). weight(b,5).
head(r2,cb). body(r2,a). weight(a,5).
EOF
nb() { # $1=constraint $2=monoid ; no -c beta at all
  "$CLINGO" --warn=none -n 0 --outf=0 --project "$ROOT/core/base.lp" "$ROOT/semiring/godel.lp" \
    "$ROOT/defaults/neutral.lp" "$ROOT/monoid/$2.lp" "$ROOT/constraint/$1.lp" \
    "$ROOT/filter/projection.lp" "$ROOT/semantics/stable.lp" "$tmp/cyc.lp" 2>&1 \
    | grep -ac '^Answer:'; }
wb() { # $1=constraint $2=monoid $3=beta
  "$CLINGO" --warn=none -n 0 --outf=0 --project -c beta="$3" "$ROOT/core/base.lp" \
    "$ROOT/semiring/godel.lp" "$ROOT/defaults/neutral.lp" "$ROOT/monoid/$2.lp" \
    "$ROOT/constraint/$1.lp" "$ROOT/filter/projection.lp" "$ROOT/semantics/stable.lp" \
    "$tmp/cyc.lp" 2>&1 | grep -ac '^Answer:'; }
check "ub with no -c beta is REJECTED"  0 "$(nb ub sum)"
check "lb with no -c beta is REJECTED"  0 "$(nb lb min)"
check "ub with -c beta=0 still works"   2 "$(wb ub sum 0)"
check "ub with -c beta=9 still works"   2 "$(wb ub sum 9)"
check "ub with -c beta=10 admits both"  3 "$(wb ub sum 10)"
check "a symbolic beta is REJECTED too" 0 "$(wb ub sum foo)"

echo
echo "== beta-sigma differential oracle (five direct/preferred semantics) =="
if python3 "$ROOT/test/beta_sigma_oracle.py"; then
  pass=$((pass+1))
else
  echo "  FAIL beta-sigma differential oracle"
  fail=$((fail+1))
fi

echo
echo "== higher-order semantics differential oracle =="
if python3 "$ROOT/test/extended_semantics.py"; then
  pass=$((pass+1))
else
  echo "  FAIL higher-order semantics differential oracle"
  fail=$((fail+1))
fi

echo
echo "==== $pass passed, $fail failed ===="
[ "$fail" -eq 0 ]
