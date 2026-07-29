%% ============================================================================
%% wABA BUDGETED ADMISSIBLE — full structured lift of Dunne et al. (AIJ 2011) Def 6.
%% ============================================================================
%% S is beta-admissible iff there is a discard set `pay` of attacks with total
%% propagated strength <= beta such that S is CLASSICALLY admissible in the framework
%% with `pay` removed. ONE shared budget covers BOTH internal conflict repair (paying to
%% un-defeat a member) AND external defence (paying to overrule an undefeated objection),
%% exactly as Dunne Def 6 removes any total-weight-<=beta set of edges. beta = 0 => classical.
%%
%% Faithfulness in the STRUCTURED setting (vs weighted-ABSTRACT AFs): the discard ranges
%% over the abstract attacks whose attacker is derivable in the MAXIMAL argument context,
%% a fixed domain; each attack's cost is the attacker's strength in that context (its
%% intrinsic strongest form, arg_weight). The reduced framework's defeat + undefeated set
%% are recomputed over the surviving (unpaid) attacks. Because the discard domain is fixed
%% (not the removal-dependent undefeated set) the guess-and-check is stratified.
%%
%% The BUDGET DIRECTION follows the algebra's polarity, rather than the algebra being
%% refused. See "budget" below.

budgeted_full.                 %% switches on the maximal-context weight phase in _phase.lp
:- discarded_attack(_,_,_).    %% use our own single discard set `pay`, not base's support discard

%% assumption in/out (base.lp provides supported/attacks; the argumentation choice lives here)
1 { in(X) ; out(X) } 1 :- assumption(X).

%% maximal argument set (derivable from ALL assumptions) — the FIXED attack domain
arg(X) :- assumption(X).
arg(X) :- head(R,X), arg_triggered(R).
arg_triggered(R) :- rule(R), arg(Z) : body(R,Z).

%% abstract attacks + the single shared discard set
att(X,Y) :- contrary(Y,X), arg(X).
{ pay(X,Y) : att(X,Y) }.

%% ---- classical admissibility on the REDUCED framework (attacks minus `pay`) ----
%% conflict-free: no member is defeated by a surviving support attack
rdefeated(Y) :- supported(X), contrary(Y,X), not pay(X,Y).
:- in(Y), rdefeated(Y).

%% defended: no member is attacked by a surviving argument in the reduced undefeated set
runde(X) :- assumption(X), not rdefeated(X).
runde(X) :- head(R,X), runde(Z) : body(R,Z).
:- in(Y), contrary(Y,X), runde(X), not pay(X,Y).

%% ---- BUDGET, applied in the direction the POLARITY dictates ------------------
%% This used to be `:- oplus(min).`, refusing cost algebras outright. That refusal keyed on
%% the algebra's IDENTITY rather than on the weights it produces, so two algebras agreeing on
%% every attack weight could still split SAT/UNSAT, and the beta=0 recovery this file's own
%% header promises returned UNSATISFIABLE for the cost algebras instead of the classical
%% extensions. The direction of the bound is now derived from the polarity, which is what the
%% two readings of a weight require.
haspay :- pay(_,_).

%% STRENGTH polarity (oplus = max): a bigger weight is an objection that is harder to
%% overrule, so the total strength conceded is bounded ABOVE and a maximal-strength (#sup)
%% objection can never be paid for. beta = 0 then forbids every concession, which is exactly
%% classical admissibility.
:- oplus(max), pay(X,Y), arg_weight(X,#sup).
:- oplus(max), haspay, effective_budget(0).
:- oplus(max), haspay, V = #sum{ W,X,Y : pay(X,Y), arg_weight(X,W) },
   effective_budget(B), B != 0, V > B.

%% COST polarity (oplus = min): a SMALLER weight is a more cheaply established, hence better
%% supported, objection. Bounding the aggregate ABOVE would therefore licence dismissing
%% precisely the best-supported objections -- the perversity the old refusal was guarding
%% against. The bound reverses instead: every conceded objection must be at least
%% beta-expensive, so the CHEAPEST concession is bounded BELOW, and a minimal-cost (#inf)
%% objection can never be paid for. Note that the recovery budget is then a beta ABOVE every
%% attack weight, not 0 -- the same asymmetry the lower bound has for conflict-based
%% semantics.
:- oplus(min), pay(X,Y), arg_weight(X,#inf).
:- oplus(min), haspay, V = #min{ W,X,Y : pay(X,Y), arg_weight(X,W) },
   effective_budget(B), V < B.

%% `pay` is the discard-set witness; it is intentionally NOT #shown so that many discard
%% sets realising the SAME extension project to one answer (bin/waba runs these with --project).
