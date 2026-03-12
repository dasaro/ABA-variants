%% No Discarding Constraint
%% =========================
%%
%% Enforces classical ABA by forcing the discard set to be empty
%%
%% Use with: Any semantic file for pure ABA/ASPforABA compatibility
%%
%% Semantics: direct no-discard profile, independent of monoid loading
%%
%% Usage:
%%   clingo -n 0 WABA/core/base.lp WABA/semiring/godel.lp \
%%          WABA/constraint/no_discard.lp WABA/filter/standard.lp \
%%          WABA/semantics/<semantic>.lp framework.lp

%% Reject any extension that discards any attack
active_budget_mode(no_discard).
active_constraint(no_discard).
:- discarded_attack(_,_,_).
