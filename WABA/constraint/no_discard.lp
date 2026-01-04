%% No Discarding Constraint
%% =========================
%%
%% Enforces classical ABA: NO attacks can be discarded
%%
%% Use with: Any semantic file for pure ABA/ASPforABA compatibility
%%
%% Semantics: Equivalent to beta=0 for all monoids, but simpler and faster
%%
%% Usage:
%%   clingo -n 0 WABA/core/base.lp WABA/semiring/godel.lp \
%%          WABA/constraint/no_discard.lp WABA/filter/standard.lp \
%%          WABA/semantics/<semantic>.lp framework.lp

%% Reject any extension that discards any attack
:- discarded_attack(_,_,_).
